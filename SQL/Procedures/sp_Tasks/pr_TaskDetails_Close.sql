/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/22  RKC     pr_TaskDetails_Close: Changes to update the modified date on the taskDetails (OBV3-1091)
              AY      pr_TaskDetails_Close: Cleanup and defer Wave Status calculation. Only recalc Wave Task counts when TaskDetail Closed
  2018/08/15  PK      pr_TaskDetails_Close, pr_Tasks_SetStatus: Updating the DepdendencyFlags as '-' if the task or task detail
  2017/04/06  CK      Migrated From HPI: pr_TaskDetails_Close: Made changes to update the counts properly on PickBatches while unallocate the LPN (HPI-1465)
  2016/10/14  SV      pr_TaskDetails_Close: Setting the status of the Batch when even a unallocating LPN(s) from a Paused Pick wave (HPI-862)
  2015/07/18  AY      pr_TaskDetails_Close: Update Task counts on Wave
  2014/07/04  TD      pr_TaskDetails_Close:update temp labels as voided while short picking.
  2014/03/19  PK      pr_TaskDetails_Close: Calling Batch update Count on task line cancel.
  2014/01/09  TD      pr_TaskDetails_Close: Calling Batch Status Porcedure to calculate Batch Status when task/Detail
  2013/12/21  AY      pr_TaskDetails_Close: Update the NumPicksCompleted on the Batch.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_Close') is not null
  drop Procedure pr_TaskDetails_Close;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_Close: This procedure would mark the TaskDetail as Completed
    or canceled based upon the UnitsCompleted.
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_Close
  (@TaskDetailId         TRecordId,
   @LPNDetailId          TRecordId,
   @UserId               TUserId,
   @Operation            TOperation = null)
As
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vTaskId            TRecordId,
          @vTaskType          TTypeCode,
          @vTDStatus          TStatus,
          @vTaskSubType       TTypeCode,
          @vTaskBatchNo       TTaskBatchNo,
          @vTaskIdksCompleted TCount,
          @vNumPicksCompleted TCount;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  if (@TaskDetailId is null) and (@LPNDetailId is null)
    set @vMessageName = 'TaskDetailClose_InvalidInput';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Delete from the task and task detail here */
  update TaskDetails
  set @vTaskId        = TaskId,
      @TaskDetailId   = coalesce(@TaskDetailId, TaskDetailId),
      @vTDStatus      = Status
                      = case when UnitsCompleted > 0 then 'C' /* Completed */ else 'X' /* Canceled */ end,
      DependencyFlags = case when (DependencyFlags in ('R', 'S' /* Replenish, Short */)) and
                                  (@vTDStatus in ('C', 'X' /* Completed, Cancelled */)) then '-'
                             else DependencyFlags
                        end,
      DependentOn     = case when (@vTDStatus in ('C', 'X' /* Completed, Cancelled */)) then null else DependentOn end
  where ((TaskDetailId = @TaskDetailId) or (LPNDetailId  = @LPNDetailId)) and
        (Status not in ('C', 'X' /* Completed/Canceled */));

  select @vNumPicksCompleted = @@rowcount;

  select @vTaskType    = TaskType,
         @vTaskBatchNo = BatchNo,
         @vTaskSubType = TaskSubType
  from Tasks
  where (TaskId = @vTaskId);

  /* Update the counts here for the Task*/
  exec pr_Tasks_SetStatus @vTaskId, @UserId, null /* Status */, 'Y' /* recount */;

  /* If it is Pick Batch Task, then update the Pick batch */
  if (@vTaskType = 'PB') and (@TaskDetailId is not null)
    begin
      /* Calculate the batch counts as some picks have been Completed/Canceled */
      exec pr_PickBatch_UpdateCounts @vTaskBatchNo, 'LTO' /* Recount LPN, Task and Order info */

      /* Calling pr_TaskDetails_Close while unallocating LPNs,Pallets and ConfirmBatchPalletPick.
         During all these cases, we are passing @Operation as null and hence below stmt always fails
         Hence used coalesce */
      if (coalesce(@Operation, '') not in ('TaskCancel'))
        begin
          /* Calculate the batch status as some picks have been completed */
          exec pr_PickBatch_SetStatus @vTaskBatchNo, null /* Status */, @UserId, null /* PBId */ ;
        end

      if (@vTaskSubType in ('L', 'CS' /* LPN Pick, Case Pick */))
        begin
          /* Update templabels as voided for the task details when user did shortpicking */
          update L
          set Status      = 'V' /* void */,
              OrderId     = null,
              PickBatchId = null,
              PickBatchNo = null
          from LPNs L join LPNTasks LT on (LT.LPNId = L.LPNId)
          where (LT.TaskDetailId = @TaskDetailId) and
                (L.Status = 'F' /* New Temp Label */);
        end
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_TaskDetails_Close */

Go
