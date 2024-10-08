/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/21  VS      pr_Exports_CreateBatchesForLargeOrders, pr_Exports_CreateBatchesForLoads,
                         pr_Exports_CreateBatchesForOrders : Made changes to update the BatchNo out of the loop (FB-2194)
  2018/05/08  SV      pr_Exports_CreateBatchesForLargeOrders, pr_Exports_CreateBatchesForLoads, pr_Exports_CreateBatchesForOrders,
                      pr_Exports_CreateBatch: Rearraged the parameters
                      pr_Exports_CIMSDE_ExportOnhandInventory:Added Ownership and Warehouse as parameters as we do have
                        in pr_Exports_OnhandInventory (S2G-470)
  2017/12/25  OK      pr_Exports_CreateBatchesForOrders, pr_Exports_CreateBatchesForLargeOrders: Enhanced to do not split the Order data in different batches based on control var (FB-1065)
  2017/07/20  VM      pr_Exports_CreateBatchesForLargeOrders: Consider ExportByLoad control var (FB-968)
  2017/07/18  VM      (FB-968)
                      pr_Exports_RemoveOrdersFromBatch,pr_Exports_CreateBatchesForLargeOrders: Introduced
                      pr_Exports_CreateBatch: Plugged-in above two newly introduced procedures
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CreateBatchesForLargeOrders') is not null
  drop Procedure pr_Exports_CreateBatchesForLargeOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CreateBatchesForLargeOrders:
    This procedure is used to identify and create separate batches for each order,
    which has unprocessed ship records count larger than MaxRecordsPerBatch threshold.

  Since it is a large order, it may be split into multiple batches - ensuring that each
  LPN would be in one batch and ShipOD-ShipOH would be in another batch
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CreateBatchesForLargeOrders
  (@SourceSystem       TName,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @ReturnCode             TInteger,
          @MessageName            TMessageName,
          @vRecordId              TRecordId,
          @vOrderId               TRecordId,
          @vLPNId                 TRecordId,
          @vTransEntityGroup      TDescription,
          @vNumRecords            TCount,
          @vBatchNo               TBatch,
          @vExportByLoad          TControlValue,
          @vCanSplitLoad          TControlValue,
          @vCanSplitOrder         TControlValue,
          @vMaxRecordsPerBatch    TControlValue,
          @vCurrentRecordsInBatch TInteger;

  declare @ttLargeOrders table (OrderId    TLoadId,
                                LPNId      TRecordId,
                                NumRecords TCount,
                                RecordId   TInteger identity(1,1));

  declare @ttOrderRecords table (OrderId          TLoadId,
                                 LPNId            TRecordId,
                                 NumRecords       TCount,
                                 TransEntityGroup TDescription,
                                 ExportBatch      TBatch,
                                 RecordId         TInteger identity(1,1));
begin
  select @ReturnCode             = 0,
         @MessageName            = null,
         @vRecordId              = 0,
         @vBatchNo               = null,
         @vCurrentRecordsInBatch = 0;

  /* Fetch the max noof records a batch could create to export and if the host would like to get ShipTrans by Load then
     we would do that, so check the preferences */
  select @vMaxRecordsPerBatch = dbo.fn_Controls_GetAsInteger('ExportBatch', 'RecordsPerBatch', '1000',
                                                             @BusinessUnit, @UserId),
         @vExportByLoad       = dbo.fn_Controls_GetAsString('ExportData', 'ExportByLoad', 'N',
                                                            @BusinessUnit, @UserId),
         @vCanSplitOrder      = dbo.fn_Controls_GetAsString('ExportData', 'CanSplitOrder', 'N',
                                                             @BusinessUnit, @UserId);

  /* This procedure is for splitting large orders. If CanSplitOrders = N, then there is nothing to be done, exit */
  if (@vCanSplitOrder = 'N') return;

  /* Exclude orders with load, if ExportByLoad is Y as they will be generated as separate batches anyway */
  insert into @ttLargeOrders(OrderId)
    select OrderId
    from Exports
    where ((@vExportByLoad = 'N') or (nullif(LoadId, 0) is null)) and
           (ExportBatch  = 0) and
           (Status       = 'N') and
           (TransType    = 'Ship') and
           (BusinessUnit = @BusinessUnit) and
           (SourceSystem = @SourceSystem)
    group by OrderId
    having count(*) > @vMaxRecordsPerBatch;

  /* TransEntityGroup = L for LPN/LPND Records, O for OH/OD records.
     For all the Large orders, break them up into groups of LPN and ShipOH/OD records
     so we can add them to the export batches */
  insert into @ttOrderRecords (OrderId, TransEntityGroup, LPNId, NumRecords)
    select E.OrderId, left(E.TransEntity, 1), E.LPNId, count(*)
    from Exports E join @ttLargeOrders LO on E.OrderId = LO.OrderId
    group by E.OrderId, left(E.TransEntity, 1), E.LPNId
    order by Min (E.RecordId);

  while (exists(select * from @ttOrderRecords where RecordId > @vRecordId))
    begin
      select top 1
             @vOrderId          = OrderId,
             @vLPNId            = LPNId,
             @vRecordId         = RecordId,
             @vTransEntityGroup = TransEntityGroup,
             @vNumRecords       = NumRecords
      from @ttOrderRecords
      where RecordId > @vRecordId
      order by RecordId;

      /* Calculate the number of records in current batch and load if count is
         larger than max RecordsPerBatch threshold, lets generate new batches */
      if (@vCurrentRecordsInBatch + @vNumRecords > @vMaxRecordsPerBatch) and (@vBatchNo is not null)
        select @vBatchNo               = null,
               @vCurrentRecordsInBatch = 0;

      /* Get next Export BatchNo to use */
      if (@vBatchNo is null)
        exec pr_Controls_GetNextSeqNo 'ExportBatch', 1, @UserId, @BusinessUnit,
                                      @vBatchNo output;

      update @ttOrderRecords
      set ExportBatch  = @vBatchNo
      where (OrderId = @vOrderId) and
            ((@vTransEntityGroup <> 'L') or (LPNId = @vLPNId))

      select @vCurrentRecordsInBatch += @vNumRecords;
    end

  /* Update Export BatchNo on the unprocessed ship records.
     if it is LPN, then add all of LPN/LPND to the batch
     if it is Order, then add all of ShipOH/OD to the batch */
  update E
  set E.ExportBatch   = coalesce(OH.ExportBatch, 0),
      E.ModifiedBy    = @UserId,
      E.ModifiedDate  = current_timestamp
  from Exports E
    join @ttOrderRecords OH on E.OrderId = OH.OrderId
  where (E.TransType    = 'Ship') and
        (E.SourceSystem = @SourceSystem) and
        ((E.LPNId = OH.LPNId) or (OH.TransEntityGroup <> 'L')) and
        (left(E.TransEntity, 1) = OH.TransEntityGroup) and
        (E.Status       = 'N' /* Not yet processed */) and
        (E.ExportBatch  = 0) and
        (E.BusinessUnit = @BusinessUnit);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_CreateBatchesForLargeOrders */

Go
