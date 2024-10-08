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
  2018/03/13  DK      pr_Exports_CaptureData, pr_Exports_GetNextBatchCriteria, pr_Exports_GetData, pr_Exports_GenerateBatches, pr_Exports_CreateBatchesForOrders
                        pr_Exports_CreateBatchesForLoads, pr_Exports_CreateBatchesForLargeOrders, pr_Exports_CreateBatch: Enhanced Procedures to create seperate batches
                        based on SourceSystem (FB-1109)
  2018/01/03  OK      pr_Exports_CreateBatchesForOrders: Added the coalesce in where clause to consider the ship records with loadid as null (FB-1065)
  2017/12/25  OK      pr_Exports_CreateBatchesForOrders, pr_Exports_CreateBatchesForLargeOrders: Enhanced to do not split the Order data in different batches based on control var (FB-1065)
  2017/12/22  DK      pr_Exports_CreateBatchesForOrders: Bugfix to do not create batch for large order as we are already handling this in some other procedure (FB-1060)
  2017/12/22  AY      pr_Exports_CreateBatchesForOrders: Added to generate Export batches for Orders which are not on Load (FB-1060)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CreateBatchesForOrders') is not null
  drop Procedure pr_Exports_CreateBatchesForOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CreateBatchesForOrders:
    This procedure is used to identify and create  batches for Shipped Orders
    with each Order being in only one Batch.

  If Order is on a Load, then this procedure processes those orders only if
  CanSplitLoad option is true. i.e. it may put the Orders on the Load into
  different batches.

  Note: This procedure does not take care of splitting a large order i.e. where
  the num export records of the order > RecordPerBatch. That is taken care of by
  pr_Exports_CreateBatchesForLargeOrders
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CreateBatchesForOrders
  (@SourceSystem       TName,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,

          @vOrderId               TRecordId,
          @vBatchNo               TBatch,
          @vCanSplitLoad          TControlValue,
          @vCanSplitOrder         TControlValue,
          @vMaxRecordsPerBatch    TControlValue,
          @vRecordsInOrder        TInteger,
          @vCurrentRecordsInBatch TInteger;

  declare @ttOrders table (OrderId     TLoadId,
                           NumRecords  TCount,
                           ExportBatch TBatch,
                           RecordId    TInteger identity(1,1));
begin
  select @vReturnCode            = 0,
         @vMessageName           = null,
         @vRecordId              = 0,
         @vBatchNo               = null,
         @vCurrentRecordsInBatch = 0;

   /* Fetch the max noof records a batch could create to export and if the host would like to get ShipTrans by Load then
      we would do that, so check the preferences */
  select @vMaxRecordsPerBatch = dbo.fn_Controls_GetAsInteger('ExportBatch', 'RecordsPerBatch', '1000',
                                                              @BusinessUnit, @UserId),
         @vCanSplitLoad       = dbo.fn_Controls_GetAsString('ExportData', 'CanSplitLoad', 'N',
                                                             @BusinessUnit, @UserId),
         @vCanSplitOrder      = dbo.fn_Controls_GetAsString('ExportData', 'CanSplitOrder', 'N',
                                                             @BusinessUnit, @UserId);

  /* Identify the Orders which exist in Exports that have unprocessed records.
     We only want to process orders not on Loads or Orders that are on Loads
     if a Load can be split i.e. Order on a Large Load */
  insert into @ttOrders(OrderId, NumRecords)
    select OrderId, count(*)
    from Exports
    where (ExportBatch = 0) and (Status = 'N') and
          (TransType = 'Ship') and (BusinessUnit = @BusinessUnit) and
          (SourceSystem = @SourceSystem) and
          ((@vCanSplitLoad = 'Y') or (coalesce(LoadId, 0) = 0))
    group by OrderId;

  while (exists(select * from @ttOrders where RecordId > @vRecordId))
    begin
      /* Get the details of first record from temp table */
      select top 1
             @vOrderId        = OrderId,
             @vRecordId       = RecordId,
             @vRecordsInOrder = NumRecords
      from @ttOrders
      where RecordId > @vRecordId
      order by RecordId;

      /* If Order is larger than MaxRecordsPerBatch and we can split Order, then skip it.
         such Orders will be split into multiple batches by pr_Exports_CreateBatchesForLargeOrders
         where we build batches for large Orders */
      if (@vRecordsInOrder > @vMaxRecordsPerBatch) and (@vCanSplitOrder = 'Y')
        continue;

      /* Calculate the number of records in current batch and Order if count is
         larger than max RecordsPerBatch threshold, lets generate new batches */
      if (@vCurrentRecordsInBatch + @vRecordsinOrder > @vMaxRecordsPerBatch)
        select @vBatchNo               = null,
               @vCurrentRecordsInBatch = 0;

      /* Get next Export BatchNo to use */
      if (@vBatchNo is null)
        exec pr_Controls_GetNextSeqNo 'ExportBatch', 1, @UserId, @BusinessUnit,
                                      @vBatchNo output;

      update @ttOrders
      set ExportBatch = @vBatchNo
      where OrderId = @vOrderId

      select @vCurrentRecordsInBatch += @vRecordsinOrder;
    end

  /* Update Export BatchNo on all of the Order unprocessed ship records. This would include
     SHIP-OH/OD/LPN/LPND records */
  update E
  set E.ExportBatch  = coalesce(OH.ExportBatch, 0),
      E.ModifiedBy   = @UserId,
      E.ModifiedDate = current_timestamp
  from Exports E
    join  @ttOrders OH on E.OrderId = OH.OrderId
  where (E.SourceSystem = @SourceSystem) and
        (E.TransType    = 'Ship') and
        (E.Status       = 'N' /* Not yet processed */) and
        (E.ExportBatch  = 0) and
        (E.BusinessUnit = @BusinessUnit);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_CreateBatchesForOrders */

Go
