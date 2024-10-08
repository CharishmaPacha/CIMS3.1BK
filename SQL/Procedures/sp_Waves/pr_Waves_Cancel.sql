/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Cancel') is not null
  drop Procedure pr_Waves_Cancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_Cancel: Cancels the given wave after the tasks are canceled. It
    cancels the Replenish Order and the Bulk Orders on the Wave too.

  We have made changes to cancel multiple Replenish or BPT Orders on a Wave
  which are not necessary now as there should be only one. Since it is not an
  issue and changes are tested, taking them to trunk.
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Cancel
  (@WaveId       TRecordId,
   @Operation    TOperation = null,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode                   TInteger,
          @vMessageName                  TMessageName,
          @vRecordId                     TRecordId,

          @vWaveId                       TRecordId,
          @vWaveNo                       TWaveNo,
          @vWaveType                     TTypeCode,
          @vWaveStatus                   TStatus,
          @vBatchingLevel                TDescription,
          @vEnforceBatchingLevel         TDescription,
          @vValidCancelWaveStatuses      TControlValue,
          @vAuditActivity                TActivityType,
          @vOrderIdToCancel              TRecordId,
          @vControlCategory              TCategory,
          @vAllocateFlags                TFlags,

          @vNewOrderStatus               TStatus,
          @vNewWaveStatus                TStatus,
          @vModifiedDate                 TDateTime,
          @ttTaskInfo                    TTaskInfoTable,
          @ttOrderIdToCancel             TEntityKeysTable;

  declare @ttOrdersToUnWave              TOrderDetails;

begin /* pr_Waves_Cancel */
  /* Initialize */
  select @vRecordId     = 0;

  select @vWaveId          = RecordId,
         @vWaveNo          = WaveNo,
         @vWaveType        = WaveType,
         @vWaveStatus      = WaveStatus,
         @vAllocateFlags   = AllocateFlags,
         @vControlCategory = 'CancelBatch_' + WaveType
  from Waves
  where (WaveId = @WaveId);

  /* Create required hash tables */
  select * into #OrdersToUnWave from @ttOrdersToUnWave;
  select * into #TaskDetailsToCancel from @ttTaskInfo;

  /* Get BPT or Replenish OrderId here for the given batch */
  insert into @ttOrderIdToCancel (EntityId)
    select OrderId
    from OrderHeaders
    where (PickBatchNo  = @vWaveNo)  and
          (BusinessUnit = @BusinessUnit) and
          (OrderType    in ('B' /* BPT */, 'R', 'RU', 'RP'));

  /* Fetch the valid cancel batch status */
  select @vValidCancelWaveStatuses = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidStatuses', 'NBLERPUKACX' /* we can cancel the Wave anytime ecxept when it is shipped/completed */,
                                                                 @BusinessUnit, @UserId),
         /* Get batching level from controls here */
         @vBatchingLevel        = dbo.fn_Controls_GetAsString('GenerateBatches', 'BatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */),
         @vEnforceBatchingLevel = dbo.fn_Controls_GetAsString('GenerateBatches', 'EnforceBatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */);

  if (@vWaveNo is null)
    set @vMessageName = 'InvalidWave';
  else
  if (charindex(@vWaveStatus, @vValidCancelWaveStatuses) = 0)
    set @vMessageName = 'CancelWave_InvalidStatus';
  else
  /* check whether user have permission to cancel released Wave */
  if (@vWaveStatus = 'R' /* Ready To Pick */) and
     (coalesce(@Operation, 'CancelBatch') <> 'UnWaveDisQualifiedOrders') and
     (dbo.fn_Permissions_IsAllowed(@UserId, 'Waves.Pri.CancelReleasedWave') <> '1')
    set @vMessageName = 'CancelWave_AlreadyReleased';
  else
  /* avoiding the cancellation of wave when allocation in the process */
  if (@vAllocateFlags = 'I' /* InProcess */) and (coalesce(@Operation, 'CancelWave') <> 'UnWaveDisQualifiedOrders')
    set @vMessageName = 'CancelWave_AllocationInProcess';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If EnforceBatchingLevel is defined, it should be the final BatchingLevel */
  if (coalesce(@vEnforceBatchingLevel, '') <> '')
    select @vBatchingLevel = @vEnforceBatchingLevel;

  /* Get Order and Wave info for selected entities for validation */
  insert into #OrdersToUnWave(OrderId, WaveId, WaveNo)
    select distinct OrderId, WaveId, WaveNo
    from WaveDetails
    where (WaveId = @vWaveId);

  /* Insert all the tasks and details for the Wave, and the LPNs which are not picked yet */
  insert into #TaskDetailsToCancel (TaskId, TaskDetailId, TaskSubType, TDRemainingCount, TDCount, TDStatus, ProcessFlag,
                                    WaveId, WaveNo, OrderId, OrderDetailId, SKUId, PalletId,
                                    LPNId, LPNDetailId, TDQuantity, TempLabelId, TempLabel, TempLabelDetailId,
                                    IsLabelGenerated, IsTaskAllocated)
    select TD.TaskId, TD.TaskDetailId, T.TaskSubType, T.DetailCount - T.CompletedCount, T.DetailCount, TD.Status, 'Y',
           TD.WaveId, TD.PickBatchNo, TD.OrderId, TD.OrderDetailId, TD.SKUId, TD.PalletId,
           TD.LPNId, TD.LPNDetailId, TD.Quantity, TD.TempLabelId, TD.TempLabel, TD.TempLabelDetailId,
           TD.IsLabelGenerated, T.IsTaskAllocated
    from TaskDetails TD join Tasks T on T.TaskId = TD.TaskId
    where (TD.WaveId = @vWaveId) and
          (TD.Status not in ('C', 'X' /* Not already canceled or completed */))
    order by TD.TaskId, TD.TaskDetailId;

  /* Cancel the PickTasks immediately after unallocating the inventory */
  exec pr_TaskDetails_CancelMultiple 'WaveCancel', @BusinessUnit, @UserId, 'Y' /* Recount */;

  /* Remove orders from the batch, this will cancel the Batch as well */
  exec pr_Waves_RemoveOrders 'Y' /* CancelBatchIfEmpty */, @vBatchingLevel, @BusinessUnit, @UserId, @Operation;

  /* If the Wave is cancelled then we need to update the Wave Attributes */
  exec pr_Waves_DeleteAttributes @vWaveId, @BusinessUnit, @UserId;

  /* Update status of the wave */
  exec pr_PickBatch_SetStatus @vWaveNo, @vNewWaveStatus output, @UserId, @vWaveId;

  /* If Wave is not canceled for any reason, then exit */
  if (@vNewWaveStatus not in ('X', 'S', 'D' /* Canceled, Shipped, Completed */)) return;

  /* Add the Audit Trail as Wave is completely canceled */
  exec pr_AuditTrail_Insert 'WaveCancelled', @UserId, @vModifiedDate, @WaveId = @vWaveId;

  /* Cancel the Bulk/Replenish Order except when the wave was shipped/completed - which could happen
     if some orders were already shipped/completed and rest of the wave cancelled */
  select @vNewOrderStatus = case when @vNewWaveStatus not in ('S', 'D' /* Shipped, Completed */) then 'X' /* Cancelled */
                                 else 'D' end

  /* Cancel the Bulk Order on the Wave if there is one,
     For Replenish Wave, cancel the orders when the Wave is canceled */
  while (exists(select * from @ttOrderIdToCancel where RecordId > @vRecordId))
    begin
      select top 1  @vRecordId        = RecordId,
                    @vOrderIdToCancel = EntityId
      from @ttOrderIdToCancel
      where (RecordId > @vRecordId)
      order by RecordId;

      exec pr_OrderHeaders_SetStatus @vOrderIdToCancel, @vNewOrderStatus, @UserId;
    end

  /* Cancel the Wave level PrintJob */
  update PrintJobs
  set PrintJobStatus = 'X' /* Canceled */
  where (EntityId = @vWaveId) and
        (EntityType = 'Wave') and
        (PrintJobStatus not in ('C'/* Completed */, 'X'/* Canceled */));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Cancel */

Go
