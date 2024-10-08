/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_PickBatch_Cancel: #OrdersToUnWave changed to use TOrderDetails
  2021/12/14  SAK     pr_PickBatch_Cancel, pr_Waves_RemoveOrders: made changesto update the wave status to Cancel (BK-682)
  2021/08/18  VS      pr_PickBatch_Cancel, pr_PickBatch_Modify, pr_PickBatch_RemoveOrder, pr_PickBatch_RemoveOrders,
  2021/02/04  VS      pr_PickBatch_Cancel: Return the validation message in UI (BK-126)
  2020/12/17  MS      pr_PickBatch_Cancel: Renamed cancelWave Privileges (CIMSV3-1078)
  2020/12/14  VS      pr_PickBatch_Cancel: When Wave is canceled cancel the respective PrintJob (HA-1776)
  2020/05/21  TK      pr_PickBatch_Cancel: Changed permission name (HA-608)
  2020/01/30  RBV     pr_PickBatch_Cancel: Added validation code for avoiding the cancellation of wave allocation in progress (HPI-2692)
  2018/06/07  VM      pr_PickBatch_Cancel, pr_PickBatch_RemoveOrders: set BatchingLevel to be EnforceBatchingLevel when retreived from controls (S2G-914)
  2016/05/27  KL      pr_PickBatch_Cancel: Get the all orders on wave and loop all the orders to cancel (NBD-529)
  2015/05/11  TD      pr_PickBatch_Cancel:Enhanced procedure to cancel BPT when user try to cancel the wave.
  2014/09/18  TK      pr_PickBatch_Cancel: Updated to cancel released Wave with user permission as a constraint
  2014/08/06  TK      pr_PickBatch_Cancel: Updated to change Task status on cancelling the Wave.
  2013/02/27  YA      pr_PickBatch_Cancel: Modified procedure to handle as signature changes in pr_LPNs_Unallocate.
  2012/11/27  YA      Added pr_PickBatch_Cancel.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_Cancel') is not null
  drop Procedure pr_PickBatch_Cancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_Cancel:

  We have made changes to cancel multiple Replenish or BPT Orders on a Wave
  which are not necessary now as there should be only one. Since it is not an
  issue and changes are tested, taking them to trunk.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_Cancel
  (@PickBatchNo  TPickBatchNo,
   @UserId       TUserId,
   @BusinessUnit TBusinessUnit,
   @Operation    TOperation = null,
   @MessageName  TMessageName  output)
as
  declare @ReturnCode                    TInteger,
          @vMessageName                  TMessageName,

          @vPickBatchId                  TRecordId,
          @vRecordId                     TRecordId,
          @vPickBatchNo                  TPickBatchNo,
          @vPickBatchType                TTypeCode,
          @vBatchStatus                  TStatus,
          @vBatchingLevel                TDescription,
          @vEnforceBatchingLevel         TDescription,
          @vPickBatchStatuses            TFlags,
          @vValidCancelBatchStatuses     TStatus,
          @vAuditActivity                TActivityType,
          @vOrdersXML                    TXML,
          @vOrderIdToCancel              TRecordId,
          @vControlCategory              TCategory,
          @vAllocateFlags                TFlags,

          @vNewOrderStatus               TStatus,
          @vModifiedDate                 TDateTime,
          @ttTasks                       TEntityKeysTable,
          @ttOrderIdToCancel             TEntityKeysTable;

  declare @ttOrdersToUnWave              TOrderDetails;

begin
begin try
  /* Local variable assignment */
  select @vRecordId     = 0;

  select @vPickBatchId     = RecordId,
         @vPickBatchType   = BatchType,
         @vPickBatchNo     = BatchNo,
         @vBatchStatus     = Status,
         @vAllocateFlags   = AllocateFlags,
         @vControlCategory = 'CancelBatch_' + BatchType
  from PickBatches
  where (BatchNo      = @PickBatchNo) and
        (BusinessUnit = @BusinessUnit);

  /* Create required hash tables */
  select * into #OrdersToUnWave from @ttOrdersToUnWave;

  /* Get BPT or Replenish OrderId here for the given batch */
  insert into @ttOrderIdToCancel (EntityId)
    select OrderId
    from OrderHeaders
    where (PickBatchNo  = @PickBatchNo)  and
          (BusinessUnit = @BusinessUnit) and
          (OrderType    in ('B' /* BPT */, 'R', 'RU', 'RP'));

  /* Fetch the valid cancel batch status */
  select @vValidCancelBatchStatuses = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidStatuses', 'NBLERPUKACX' /* we can cancel the Wave anytime ecxept when it is shipped/completed */,
                                                                  @BusinessUnit, @UserId),
         /* Get batching level from controls here */
         @vBatchingLevel        = dbo.fn_Controls_GetAsString('GenerateBatches', 'BatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */),
         @vEnforceBatchingLevel = dbo.fn_Controls_GetAsString('GenerateBatches', 'EnforceBatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */);

  if (@vPickBatchNo is null)
    set @vMessageName = 'InvalidBatch';
  else
  if (charindex(@vBatchStatus, @vValidCancelBatchStatuses) = 0)
    set @vMessageName = 'CancelWave_InvalidStatus';
  else
  /* check whether user have permission to cancel released Wave */
  if (@vBatchStatus = 'R' /* Ready To Pick */) and
     (coalesce(@Operation, 'CancelBatch') <> 'UnWaveDisQualifiedOrders') and
     (dbo.fn_Permissions_IsAllowed(@UserId, 'Waves.Pri.CancelReleasedWave') <> '1')
    set @vMessageName = 'CancelWave_AlreadyReleased';
  else
  /* avoiding the cancellation of wave when allocation in the process */
  if (@vAllocateFlags = 'I' /* InProcess */) and (coalesce(@Operation,'CancelBatch') <> 'UnWaveDisQualifiedOrders')
    set @vMessageName = 'CancelWave_AllocationInProcess';

  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If EnforceBatchingLevel is defined, it should be the final BatchingLevel */
  if (coalesce(@vEnforceBatchingLevel, '') <> '')
    select @vBatchingLevel = @vEnforceBatchingLevel;

  if (@vBatchingLevel = 'OH')
    begin
      /* Get Order and Wave info for selected entities for validation */
      insert into #OrdersToUnWave(OrderId, WaveId, WaveNo)
        select OrderId, WaveId, WaveNo
        from PickBatchDetails
        where (PickBatchNo = @vPickBatchNo);
    end
  else
    begin
      insert into #OrdersToUnWave(OrderId, OrderDetailId, WaveId, WaveNo)
        select OrderId, OrderDetailId, WaveId, WaveNo
        from PickBatchDetails
        where (PickBatchNo = @vPickBatchNo);
    end

  /* Cancel all the tasks associated with the Wave */
  insert into @ttTasks (EntityId, EntityKey)
    select TaskId, 'Tasks'
    from Tasks
    where (BatchNo      = @PickBatchNo ) and
          (BusinessUnit = @BusinessUnit) and
          (Status not in ('C', 'X' /* Not already canceled or completed */))

  if (@@rowcount > 0)
    exec pr_Tasks_Cancel @ttTasks, null /* TaskId */, null /* Batch No */,
                         @BusinessUnit, @UserId, @MessageName output;

  /* Remove orders from the batch, this will cancel the Batch as well */
  exec pr_Waves_RemoveOrders 'Y' /* CancelBatchIfEmpty */, @vBatchingLevel, @BusinessUnit, @UserId, @Operation;

  /* If the Wave is cancelled then we need to update the Wave Attributes */
  exec pr_PickBatch_DeleteAttributes @vPickBatchId, @BusinessUnit, @UserId;

  /* Cancel the Bulk Order on the Wave if there is one,
     For Replenish Wave, cancel the orders when the Wave is canceled */
  while (exists(select * from @ttOrderIdToCancel where RecordId > @vRecordId))
    begin
      select top 1  @vRecordId        = RecordId,
                    @vOrderIdToCancel = EntityId
      from @ttOrderIdToCancel
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Calculate Order status */
      select @vNewOrderStatus = case when @vBatchStatus not in ('S', 'D' /* Shipped, Completed */) then 'X' /* Cancelled */
                                     else 'D' end

      exec pr_OrderHeaders_SetStatus @vOrderIdToCancel, @vNewOrderStatus, @UserId;
    end

  /* Cancel the Wave level PrintJob */
  update PrintJobs
  set PrintJobStatus = 'X' /* Canceled */
  where (EntityId = @vPickBatchId) and
        (EntityType = 'Wave') and
        (PrintJobStatus not in ('C'/* Completed */, 'X'/* Canceled */));

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'PickBatchCancelled', @UserId, @vModifiedDate,
                            @PickBatchId = @vPickBatchId;

  set @MessageName = 'BatchCancelled';

end try
begin catch
  exec @ReturnCode = pr_ReRaiseError;

  /* Show the validations messages in UI */
  if object_id('tempdb..#ResultMessages') is not null
    insert into #ResultMessages (MessageType, MessageText)
      select 'E', ERROR_MESSAGE();

end catch
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_Cancel */

Go
