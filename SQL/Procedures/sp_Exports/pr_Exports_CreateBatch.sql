/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/21  VS      pr_Exports_CreateBatchesForLargeOrders, pr_Exports_CreateBatchesForLoads,
                      pr_Exports_CreateBatchesForOrders : Made changes to update the BatchNo out of the loop (FB-2194)
                      pr_Exports_CreateBatch: Handle previous and existing null values (HA-1896)
  2018/05/08  SV      pr_Exports_CreateBatchesForLargeOrders, pr_Exports_CreateBatchesForLoads, pr_Exports_CreateBatchesForOrders,
                      pr_Exports_CreateBatch: Rearraged the parameters
  2018/03/13  DK      pr_Exports_CaptureData, pr_Exports_GetNextBatchCriteria, pr_Exports_GetData, pr_Exports_GenerateBatches, pr_Exports_CreateBatchesForOrders
                      pr_Exports_CreateBatchesForLoads, pr_Exports_CreateBatchesForLargeOrders, pr_Exports_CreateBatch: Enhanced Procedures to create seperate batches
  2018/01/03  OK      pr_Exports_CreateBatchesForOrders: Added the coalesce in where clause to consider the ship records with loadid as null (FB-1065)
  2017/12/26  OK      pr_Exports_CreateBatch: removed the obselete code (FB-1060)
  2017/12/25  OK      pr_Exports_CreateBatchesForOrders, pr_Exports_CreateBatchesForLargeOrders: Enhanced to do not split the Order data in different batches based on control var (FB-1065)
  2017/12/22  DK      pr_Exports_CreateBatchesForOrders: Bugfix to do not create batch for large order as we are already handling this in some other procedure (FB-1060)
  2017/12/22  AY      pr_Exports_CreateBatchesForOrders: Added to generate Export batches for Orders which are not on Load (FB-1060)
  2017/12/19  DK      pr_Exports_CreateBatchesForLoads: Introduced new procedure to create batches for export records which are on load (FB-1050)
                      pr_Exports_CreateBatch: Default value of @BatchNo is set to null.(FB-1048)
                      pr_Exports_CreateBatch: Corrected logic to work for ExportByReceiver
  2017/07/20  VM      pr_Exports_CreateBatchesForLargeOrders: Consider ExportByLoad control var (FB-968)
                      pr_Exports_RemoveOrdersFromBatch,pr_Exports_CreateBatchesForLargeOrders: Introduced
                      pr_Exports_CreateBatch: Plugged-in above two newly introduced procedures
  2017/07/15  VM      pr_Exports_CreateBatch: Corrected the logic to work exactly as per the control vars (CIMS-1486)
  2017/06/28  VM      pr_Exports_CreateBatch: Made changes to handle separate transactions based control vars even though caller sends null in TransType (FB-947))
  2016/08/28  AY      pr_Exports_CreateBatch: Generate exports by Loads (HPI-521)
  2016/05/05  DK      pr_Exports_CreateBatch: Made changes to generate a new batch for each Receiver (NBD-435).
  2016/01/21  TK      pr_Exports_GetData & pr_Exports_CreateBatch: The Export Batch creation should create batches
  2015/12/04  RV      pr_Exports_CreateBatch: Split the records with respect to the records per batch control variable (FB-560)
  2015/01/21  TK      pr_Exports_CreateBatch: Do not generate exports while Creating Load
  2014/06/12  AY      pr_Exports_CreateBatch: Do not use up sequence numbers if there are no
  2013/11/27  AY      pr_Exports_CreateBatch: Split Ship transactions into separate batches and new
  2012/08/29  YA      pr_Exports_CreateBatch: Modified to create a set of records per batch.
  2011/08/17  YA      pr_Exports_CreateBatch, pr_Exports_GetData: New procs
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CreateBatch') is not null
  drop Procedure pr_Exports_CreateBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CreateBatch:

  SeparateShipTrans: i.e. to export all transactions in on batch and ship trans
    in another batch is not an option anymore. We can split each TransType into
    a separate Batch or we can club them all together.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CreateBatch
  (@TransType     TTypecode  = null,
   @Ownership     TOwnership = null,
   @SourceSystem  TName,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @BatchNo       TBatch = null output)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @vRecordsPerBatch     TInteger,
          @vRecordId            TRecordId,
          @vNextBatch           TBatch,

          @vSeparateShipTrans   TControlValue,
          @vExportByLoad        TControlValue,
          @vExportByReceiver    TControlValue,
          @vShipRecordId        TRecordId,
          @vRecvRecordId        TRecordId,
          @vLoadIdToExport      TLoadId,
          @vReceiverToExport    TReceiverNumber;
begin
  select @ReturnCode    = 0,
         @MessageName   = null,
         @TransType     = nullif(@TransType, ''),
         @BatchNo       = null,
         @vRecordId     = 0;

  /* Fetch the max number of records, a batch could create to export */
  select @vRecordsPerBatch = dbo.fn_Controls_GetAsInteger('ExportBatch', 'RecordsPerBatch', '1000',
                                                          @BusinessUnit, @UserId);

  /* If the host would like to get ShipTrans in individual batches and by Load then we would do that,
     so check the preferences */
  select @vExportByLoad = dbo.fn_Controls_GetAsString('ExportData', 'ExportByLoad', 'N', @BusinessUnit, @UserId);

  /* If TransType is Ship, verify if there are any Loads, which has unprocessed ship records,
     lets generate batches for each of them */
  if (coalesce(@TransType, 'Ship') = 'Ship')
    exec pr_Exports_CreateBatchesForLoads @SourceSystem, @BusinessUnit, @UserId;

  /* If TransType is Ship, verify if there are any Orders, which has unprocessed ship records,
       lets generate batches for them. */
  if (coalesce(@TransType, 'Ship') = 'Ship')
    exec pr_Exports_CreateBatchesForOrders @SourceSystem, @BusinessUnit, @UserId;

  /* If TransType is Ship/null, verify if there are any orders, which has unprocessed ship records count is
     larger than max RecordsPerBatch threshold, lets generate separate batches for each of them */
  if (coalesce(@TransType, 'Ship') = 'Ship')
    exec pr_Exports_CreateBatchesForLargeOrders @SourceSystem, @BusinessUnit, @UserId;

  /* select the RecordId from the exports until which the batch needs to be created */
  select top (@vRecordsPerBatch) @vRecordId = RecordId
  from Exports
  where (TransType    = coalesce(@TransType, TransType)) and
        (Ownership    = coalesce(@Ownership, Ownership)) and
        (TransType    <> 'Ship') and
        (SourceSystem = @SourceSystem) and
        (BusinessUnit = @BusinessUnit) and
        (Status       = 'N' /* Not yet processed */) and
        (ExportBatch  = 0)
  order by RecordId;

  /* If there are no records to process, then exit */
  if (@vRecordId = 0) goto ExitHandler;

  /* Now create a batch of the other transactions and update them with batch, if they exists. Avoids skipping of ExportBatch numbers */
  exec pr_Controls_GetNextSeqNo 'ExportBatch', 1, @UserId, @BusinessUnit,
                                @BatchNo output;

  /* The next batch is also created so that we don't end up continously exporting Ship records only
     without this, there is a chance that every time export runs, we export ship records and
     others are just queued up */
  update Exports
  set ExportBatch  = @BatchNo,
      ModifiedBy   = @UserId,
      ModifiedDate = current_timestamp
  where (TransType    = coalesce(@TransType, TransType)) and
        (TransType    <> 'Ship') and -- always exclude Ship Trans which should have been processed earlier anyway.
        (Ownership    = coalesce(@Ownership, Ownership)) and
        (SourceSystem = @SourceSystem) and
        (BusinessUnit = @BusinessUnit) and
        (Status       = 'N' /* Not yet processed */) and
        (ExportBatch  = 0) and
        (RecordId     <= @vRecordId);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ShipTransHandler:
  /* Evaluate removing orders, ONLY when TransType is Ship/null and the main batch @BatchNo (not @vNextBatch)
     is not generated by Load */
  if (coalesce(@TransType, 'Ship') = 'Ship') and ((@vExportByLoad = 'N') or (@vLoadIdToExport is null))
    exec pr_Exports_AvoidSplitEntities @BatchNo, @BusinessUnit, @UserId;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_CreateBatch */

Go
