/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/27  VS      pr_PickBatch_ReleaseBatches, pr_PickBatch_GenerateBatches, pr_Wave_ReleaseForAllocation: Need to InventoryAllocationModel When we create wave with Released status (HA-668)
  2020/05/22  KBB     pr_Wave_ReleaseForAllocation/pr_PickBatch_ReleaseBatches:Changed the  entity type PickTicket (HA-384)
  2017/10/12  TK      pr_PickBatch_ReleaseBatches: Update ReleaseDateTime on Wave release
  2017/07/28  RV      pr_PickBatch_GenerateBatches, pr_PickBatch_ReleaseBatches: BusinessUnit and UserId passed to activity log procedure
  2015/09/11  TK      pr_PickBatch_ReleaseBatches: Enhanced to genrate Load for the Orders on the Wave on Release(ACME-328).
                      pr_PickBatch_ReleaseBatches: Changes to allocate inventory based on the control value.
  2014/01/22  NY      pr_PickBatch_ReleaseBatches: If there is no inventory to be picked (available), Batch status should be in new.
                      pr_PickBatch_ReleaseBatches:Allowing to release the batch if it is in readytopick
  2012/08/29  AY      pr_PickBatch_ReleaseBatches: Reset UDF10 to reallocate Pallets.
                      pr_PickBatch_ReleaseBatches: Update UDF10 to allocate pallets to batches.
  2012/08/17  PK      pr_PickBatch_ReleaseBatches: Calling pr_Picking_FindPallet procedure on releasing of a
  2012/05/19  AY      pr_PickBatch_ReleaseBatches: New procedure to release batches.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_ReleaseBatches') is not null
  drop Procedure pr_PickBatch_ReleaseBatches;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_ReleaseBatches: Releases the batches specified in the
    input table param.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_ReleaseBatches
  (@PickBatches      TEntityKeysTable ReadOnly,
   @UserId           TUserId,
   @BusinessUnit     TBusinessUnit,
   @BatchesUpdated   TCount = null output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vActivityLogId       TRecordId,

          @vRecordId            TRecordId,
          @vPickBatchId         TRecordId,
          @vBatchNo             TPickBatchNo,
          @vBatchType           TTypeCode,
          @vBatchStatus         TStatus,
          @ttPickBatches        TEntityKeysTable,
          @vBusinessUnit        TBusinessUnit,
          @vTasksCreated        TCount,
          @vModifiedDate        TDateTime,
          @vAuditRecordId       TRecordId,
          @vExportSrtrDetails   TControlValue,
          @vCreateBPT           TFlag,
          @vGenerateLoadForWave TFlag,
          @vOrdersToLoad        TXML,
          @vAllocateInventory   TControlValue,
          @ttPickBatchOrders    TEntityKeysTable;

  declare @ttBatchControls table (BatchType    TTypeCode,
                                  CreateBPT    TFlag)
begin
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @BatchesUpdated = 0;

  /* Fetch the control values */
  select @vGenerateLoadForWave  = dbo.fn_Controls_GetAsString('Wave', 'GenerateLoadForWave', 'N' /* No */, @BusinessUnit, null /* UserId */);

  /* insert controls into temp table */
  insert into @ttBatchControls(BatchType, CreateBPT)
    select ControlCode, ControlValue
    from dbo.fn_Controls_GetControls('PB_CreateBPT', @BusinessUnit);

  /* Loop the batches and perform OnRelease, Allocation and AfterRelease on each Batch */
  while (exists (select * from @PickBatches where RecordId > @vRecordId))
    begin
      /* select Top 1 BatchNo from temp table */
      select Top 1 @vPickBatchId = EntityId,
                   @vBatchNo     = EntityKey,
                   @vRecordId    = RecordId,
                   @vCreateBPT   = 'N' /* No */
      from @PickBatches
      where (RecordId > @vRecordId)
      order by RecordId;

      /* select BatchType to eliminate other than Bulk Batches */
      select @vBatchType    = PB.BatchType,
             @vPickBatchId  = PB.RecordId,
             @vBusinessUnit = PB.BusinessUnit,
             @vCreateBPT    = BC.CreateBPT
      from PickBatches PB
        left outer join @ttBatchControls BC on (BC.BatchType = PB.BatchType)
      where (PB.BatchNo   = @vBatchNo) and
            (BusinessUnit = @BusinessUnit);

      /* get control values that depend upon the Batch Type */
      select @vExportSrtrDetails = dbo.fn_Controls_GetAsString('Sorter',     'ExportWaveDetails_' +@vBatchType, 'Y', @BusinessUnit, null /* UserId */),
             @vAllocateInventory = dbo.fn_Controls_GetAsString('PB_Allocate', @vBatchType, 'J' /* By Job */, @BusinessUnit, null /* UserId */);

      /* Update Batch status to indicate it is released, set allocate flag */
      update W
      set @vBatchStatus      =
          Status             = case
                                 when Status = 'P' /* Picking */  then
                                   Status
                                 when BatchType = 'U' then
                                   'L' /* Ready to pull */
                                 else
                                   'R' /* Ready To pick */
                               end,
          AllocateFlags      = 'Y',
          InvAllocationModel = 'SR',
          ReleaseDateTime    = current_timestamp,
          @vModifiedDate     =
          ModifiedDate       = current_timestamp,
          ModifiedBy         = @UserId
      from Waves W
      where (W.WaveId = @vPickbatchId) and
            (W.Status    in ('N' /* New */, 'B' /* Planned */, 'R' /* ReadyToPick */, 'P' /* Picking */)) and
            (W.NumOrders > 0);

      /* Update the count */
      select @BatchesUpdated += 1;

      /* Insert Audit trail for the Batch */
      exec pr_AuditTrail_Insert 'PickBatchReleased', @UserId, @vModifiedDate,
                                @PickBatchId   = @vPickBatchId,
                                @AuditRecordId = @vAuditRecordId output;

      /* On release of a batch there may be some updates to be done. For example, to allocate the orders
         on the batch, these are all performed in the Onrelease procedure or like setting of DestZone
         on OrderDetails for GNC */
      exec pr_PickBatch_OnRelease @vPickBatchId, @vBatchNo, @BusinessUnit, @UserId;

      if (@vAllocateInventory in ('O' /* OnRelease */))
        begin
          /* insert into activitylog details */
          exec pr_ActivityLog_AddOrUpdate 'PickBatch', @vPickBatchId, @vBatchNo, 'BatchAllocation',
                                          'StartOrderAllocation', Default /* xmldata */,  Default /* xmlresult */, Default /* DeviceId */,
                                          @UserId, @vActivityLogId output;

          /* Allocate Inventory for Orders on the Pickbatch */
          exec pr_Allocation_AllocateWave @vPickBatchId, null /* Operation */, @vBusinessUnit, @UserId;

          /* insert into activitylog details */
          exec pr_ActivityLog_AddOrUpdate 'PickBatch', @vPickBatchId, @vBatchNo, 'BatchAllocation',
                                          'EndOrderAllocation', Default /* xmldata */,  Default /* xmlresult */, Default /* DeviceId */,
                                          @UserId, @vActivityLogId output;
        end;

      exec pr_PickBatch_AfterRelease @vPickBatchId,  @vBatchNo, @vExportSrtrDetails,
                                     @vBusinessUnit, @UserId;

      /* If desired, Generate Loads for the Waves which are released */
      if (@vGenerateLoadForWave = 'O' /* On Release */)
        exec pr_Load_GenerateLoadForWavedOrders @vPickBatchId, @BusinessUnit, @UserId;

      insert into @ttPickBatchOrders(EntityId, EntityKey)
        select OrderId, PickTicket
        from vwOrderHeaders
        where (PickBatchId = @vPickBatchId);

      /* Now insert all the batches released into Audit Entities i.e link above Audit Record
         to all the batches */
      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'PickTicket', @ttPickBatchOrders, @vBusinessUnit;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_ReleaseBatches */

Go
