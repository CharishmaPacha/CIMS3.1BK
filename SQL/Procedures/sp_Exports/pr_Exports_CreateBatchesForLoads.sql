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
  2017/12/19  DK      pr_Exports_CreateBatchesForLoads: Introduced new procedure to create batches for export records which are on load (FB-1050)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CreateBatchesForLoads') is not null
  drop Procedure pr_Exports_CreateBatchesForLoads;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CreateBatchesForLoads:
    This procedure is used to identify and create  batches for Loads,
    which has unprocessed ship records.

  ExportByLoad - Y: Each Load would be a separate batch
                 N: Multiple Loads can be in one batch
  CanSplitLoad - Y: If load is larger than MaxRecordsPerBatch, then we split it into multiple batches by Order
                 N: Create an individual batch for the Load.

  If CanSplitLoad = Y and there are Loads which are larger than BatchSize, this
  procedure does not batch those Loads. Those would be handled by CreateBatchesForOrders.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CreateBatchesForLoads
  (@SourceSystem       TName,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,

          @vLoadId                TRecordId,
          @vBatchNo               TBatch,
          @vExportByLoad          TControlValue,
          @vCanSplitLoad          TControlValue,
          @vMaxRecordsPerBatch    TControlValue,
          @vRecordsInLoad         TInteger,
          @vCurrentRecordsInBatch TInteger;

  declare @ttLoads table (LoadId      TLoadId,
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
         @vExportByLoad       = dbo.fn_Controls_GetAsString('ExportData', 'ExportByLoad', 'N',
                                                             @BusinessUnit, @UserId),
         @vCanSplitLoad       = dbo.fn_Controls_GetAsString('ExportData', 'CanSplitLoad', 'N',
                                                             @BusinessUnit, @UserId);

  /* Identify the Loads which exist in Exports that have unprocessed records */
  insert into @ttLoads(LoadId, NumRecords)
    select LoadId, count(*)
    from Exports
    where (LoadId <> 0) and (ExportBatch = 0) and (Status = 'N') and
          (TransType = 'Ship') and (BusinessUnit = @BusinessUnit) and
          (SourceSystem = @SourceSystem)
    group by LoadId;

  while (exists(select * from @ttLoads where RecordId > @vRecordId))
    begin
      /* Get the details of first record from temp table */
      select top 1
             @vLoadId        = LoadId,
             @vRecordId      = RecordId,
             @vRecordsInLoad = NumRecords
      from @ttLoads
      where RecordId > @vRecordId
      order by RecordId;

      /* If Load is larger than MaxRecordsPerBatch and we can split Load, then skip it.
         such Loads will be split into multiple batches by pr_Exports_CreateBatchesForOrders
         where we build batches by Order */
      if (@vRecordsInLoad > @vMaxRecordsPerBatch) and (@vCanSplitLoad = 'Y') and (@vExportByLoad = 'N')
        continue;

      /* Calculate the number of records in current batch and load if count is
         larger than max RecordsPerBatch threshold, lets generate new batch */
      if (@vCurrentRecordsInBatch + @vRecordsinLoad > @vMaxRecordsPerBatch)
        select @vBatchNo               = null,
               @vCurrentRecordsInBatch = 0;

      /* Get next Export BatchNo to use */
      if (@vBatchNo is null)
        exec pr_Controls_GetNextSeqNo 'ExportBatch', 1, @UserId, @BusinessUnit,
                                      @vBatchNo output;

      update @ttLoads
      set ExportBatch = @vBatchNo
      where LoadId = @vLoadId

      select @vCurrentRecordsInBatch += @vRecordsInLoad;

      /* If ExportByLoad is Y then clear BatchNo so that subsequent Loads
         will be generated as separate batches */
      if (@vExportByLoad = 'Y')
        select @vBatchNo               = null,
               @vCurrentRecordsInBatch = 0;
    end

  /* Update Export BatchNo on all of the Load unprocessed ship records */
  update E
  set E.ExportBatch  = coalesce(L.ExportBatch, 0),
      E.ModifiedBy   = @UserId,
      E.ModifiedDate = current_timestamp
  from Exports E
    join @ttLoads L on L.LoadId = E.LoadId
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
end /* pr_Exports_CreateBatchesForLoads */

Go
