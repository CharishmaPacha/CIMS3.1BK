/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/09  TK      pr_TaskDetails_CancelMultiple: Initial Revision
                      pr_Tasks_Cancel: Code Revamp (CIMSV3-1490)
  2020/12/17  VS      pr_Tasks_Cancel: When Task is canceled cancel the respective PrintJobs (HA-1776)
  2020/08/20  AY      pr_Tasks_Cancel: Return result messages in V3 method (HA-1306)
  2018/08/23  TK      pr_Tasks_Cancel: Bug fix in cancelling partially allocated task (S2GCA-184)
  2018/06/07  AJ      pr_Tasks_Cancel: Made changes to count taskdetails to display appropriate message for cancel task detail (S2G-647)
  2018/03/21  OK      pr_Tasks_Cancel: Changes to allow the cancelling tasks if TaskDetails are endedup with NotCategorized (S2G-357)
  2017/03/14  VM      pr_Tasks_Cancel: Bugfix - Do not try to cancel the same task pick twice as it may lead to delete other task picks (HPI-1447)
  2016/07/13  TK      pr_Tasks_Cancel: Bug fix to unallocate allocated LPN/Pallet
  2016/07/12  OK      pr_Tasks_Cancel: Enhanced to clear the temp labels if task has been cancelled (HPI-249)
  2015/10/13  OK      pr_Tasks_Cancel: Refactor the code as pr_LPNDetails_UnallocateMultiple (FB-412)
  2015/10/08  OK      pr_Tasks_Cancel: Updated to cancel Pallet Picks (FB-412).
  2015/10/07  OB/AY   pr_Tasks_Cancel: Swapped fields, cancellation of Pallet pick issue - WIP
  2015/08/17  AY      pr_Tasks_Cancel: Use save points to roll back only the particular LPN
  2015/07/13  VM      pr_Tasks_Modify: Due an internal transaction started in pr_Tasks_Cancel, commit transaction if exists (FB-250)
  2015/06/24  TK      pr_Tasks_Cancel: Enhanced to cancel tasks which are un-allocated, added missing argument.
  2014/09/11  TK      pr_Tasks_Cancel: Updated to Cancel Tasks of On-Hold Status.
  2014/07/17  TD      pr_Tasks_Cancel:Issue fixed to show proper messages based on action.
  2013/11/28  TD      pr_Tasks_Cancel and pr_Tasks_Modify: Changes to Cancel Task Line.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Cancel') is not null
  drop Procedure pr_Tasks_Cancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Cancel cancel the given task details or task details of the given tasks
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Cancel
  (@Tasks            TEntityKeysTable readonly,
   @TaskId           TRecordId    = null, --Future Use
   @BatchNo          TPickBatchNo = null, --Future USe
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Message          TDescription = null output)
As
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vTaskId            TRecordId,
          @vPreviousTaskId    TRecordId,
          @vPreviousTaskDetailId
                              TRecordId,
          @vTaskDetailId      TRecordId,
          @vTaskSubType       TTypeCode,
          @vRecordId          TRecordId,

          @vLPNDetailQty      TQuantity,
          @vLPNQuantity       TQuantity,
          @vLPNId             TRecordId,
          @vPalletId          TRecordId,
          @vLPNDetailId       TRecordId,
          @vTempLabelId       TRecordId,
          @vTempLabelDetailId TRecordId,
          @vOrderId           TRecordId,
          @vOrderDetailId     TRecordId,
          @vPickBatchNo       TPickBatchNo,
          @vTasksCount        TCount,
          @vTaskDetailsCount  TCount,
          @vTasksUpdated      TCount,
          @vTaskDetailsUpdated
                              TCount,
          @vIsTaskAllocated   TFlag,
          @vIsLabelGenerated  TFlag,

          @vAction            TDescription,
          @vErrMsg            TMessage,
          @vEntityKey         TEntity,

          @vActivityLogId     TRecordId;

  declare @LPNsToUpdate       TEntityKeysTable,
          @ttOrdersToRecount  TEntityKeysTable,
          @ttBatchesToRecount TEntityKeysTable;

  declare @ttTaskDetails table
          (RecordId          TRecordId identity (1,1),
           TaskId            TRecordId,
           TaskDetailId      TRecordId,
           TaskSubType       TTypeCode,
           PickBatchNo       TPickBatchNo,
           OrderId           TRecordId,
           OrderDetailId     TRecordId,
           LPNId             TRecordId,
           LPNDetailId       TRecordId,
           PalletId          TRecordId,
           Quantity          TQuantity,
           LPNQuantity       TQuantity,
           TempLabelId       TRecordId,
           TempLabelDetailId TRecordId,
           IsTaskAllocated   TFlag,
           IsLabelGenerated  TFlag,
           Primary Key       (RecordId));

begin
  SET NOCOUNT ON;

  select @vReturnCode           = 0,
         @vPreviousTaskId       = 0,
         @vPreviousTaskDetailId = 0,
         @vTasksUpdated         = 0,
         @vTaskDetailsUpdated   = 0,
         @vTasksCount           = 0,
         @vTaskDetailsCount     = 0,
         @vMessageName          = null,
         @vRecordId             = 0;

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Insert all the tasks and details for the pickbatch, and the LPNs which are not picked yet */
  insert into @ttTaskDetails(TaskId, TaskDetailId, TaskSubType, PickBatchNo, OrderId, OrderDetailId,
                             LPNId, LPNDetailId, PalletId, Quantity, IsTaskAllocated, IsLabelGenerated)
    select TD.TaskId, TD.TaskDetailId, Task.TaskSubType, Task.BatchNo, TD.OrderId, TD.OrderDetailId,
           TD.LPNId, TD.LPNDetailId, TD.PalletId, TD.Quantity, Task.IsTaskAllocated, TD.IsLabelGenerated
    from @Tasks T
         join TaskDetails TD on (T.EntityId = case when T.EntityKey = 'TaskDetail' then TD.TaskDetailId
                                                   else TD.TaskId end) and
                                (TD.Status  in ('O' /* On Hold */, 'N' /* Ready To Start */, 'I' /* In progress */, 'NC' /* Not Categorized */))
         join Tasks       Task on (Task.TaskId = TD.TaskId)
    order by TD.TaskId, TD.TaskDetailId;

  /* get the selected tasks/task details count */
  select @vTasksCount       = count(distinct TaskId),
         @vTaskDetailsCount = count(TaskDetailId)
  from @ttTaskDetails;

  /* update LPN Quantity here - for what? No explanation? */
  update TTD
  set LPNQuantity = L.Quantity
  from @ttTaskDetails TTD
    join LPNs L on (L.LPNId = TTD.LPNId)

  /* Loop here for all the tasks and cancel each one, one after the other */
  while (exists (select * from @ttTaskDetails where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId          = RecordId,
                   @vTaskId            = TaskId,
                   @vTaskDetailId      = TaskDetailId,
                   @vTaskSubType       = TaskSubType,
                   @vPickBatchNo       = PickBatchNo,
                   @vOrderId           = OrderId,
                   @vLPNDetailQty      = Quantity,
                   @vLPNQuantity       = LPNQuantity,
                   @vLPNDetailId       = LPNDetailId,
                   @vLPNId             = LPNId,
                   @vPalletId          = PalletId,
                   @vIsTaskAllocated   = IsTaskAllocated,
                   @vIsLabelGenerated  = IsLabelGenerated
      from @ttTaskDetails
      where RecordId > @vRecordId
      order by RecordId;

      /* Log the ActivityLog for all TaskDetails before cancel */
      exec pr_ActivityLog_Task 'TaskDetails_Cancel', @vTaskId, default, 'TaskDetails', @@ProcId,
                                @ActivityLogId = @vActivityLogId output;

      /* Earlier we use to depend upon IsTaskAllocated flag which is not realistic as
         there are instances where task will have some picks allocated and some are pseudo picks
         so consider LPNDetailId and PalletId to unallocate */

      /* If it is an Pallet pick, then unallocate allocated Pallet */
      if (@vTaskSubType = 'P'/* PalletPick */) and (@vPalletId is not null)
        exec pr_Pallets_Unallocate @vPalletId, @BusinessUnit, @UserId;
      else
      /* If not a pallet pick and pick is allocated then unallocate LPNDetail */
      if (@vLPNDetailId is not null)
        exec pr_LPNDetails_UnallocateMultiple 'TaskCancel' /* @Operation */,
                                              default /* LPNsToUnallocate */,
                                              @vLPNId /* @LPNId */,
                                              @vLPNDetailId /* @LPNDetailId */, @UserId, @BusinessUnit

      /* For Allocated Picks, above block takes care of canceling/closing task details / tasks.
         However, for Psuedo Pick Tasks, we have to cancel the Task Details directly and
         then Void the Templabel generated */
      exec pr_TaskDetails_Cancel @vTaskId, @vTaskDetailId, @UserId;

      if (@vOrderId is not null) and (not exists (select * from @ttOrdersToRecount where EntityId = @vOrderId))
        insert into @ttOrdersToRecount (EntityId) select @vOrderId;

      if (not exists (select * from @ttBatchesToRecount where EntityKey = @vPickBatchNo))
        insert into @ttBatchesToRecount (EntityKey) select @vPickBatchNo;

      /* count the no of tasks cancelled here to build message */
      if (@vTaskId <> @vPreviousTaskId)
        begin
          select @vPreviousTaskId = @vTaskId,
                 @vTasksUpdated   = @vTasksUpdated + 1;
        end

      /* count the no of task details cancelled here to build message */
      if (@vTaskDetailId <> @vPreviousTaskDetailId)
        begin
          select @vPreviousTaskDetailId = @vTaskDetailId,
                 @vTaskDetailsUpdated   = @vTaskDetailsUpdated + 1;
        end

      /* Log the ActivityLog for all TaskDetails After cancel */
      exec pr_ActivityLog_Task 'TaskDetails_Cancel', @vTaskId, default, 'TaskDetails', @@ProcId,
                                @ActivityLogId = @vActivityLogId output;

    end

  /* Get action here based on the entity */
  select top 1 @vEntityKey = EntityKey
  from @Tasks;

  /* Updating orders count and status. */
  exec pr_OrderHeaders_Recalculate @ttOrdersToRecount, 'C' /* Count */, @UserId;

  /* Updating PickBatch count and status */
  exec pr_PickBatch_Recalculate @ttBatchesToRecount, 'SC' /* Status, Counts */, @UserId;

  /* Cancel the Tasks PrintJobs */
  update P
  set PrintJobStatus = 'X' /* Canceled */
  from PrintJobs P
    join @ttTaskDetails TS on P.EntityId = TS.TaskId
    join Tasks T on T.TaskId = TS.TaskId
  where (P.EntityType = 'Task') and
        (T.Status = 'X' /* Canceled */) and
        (P.PrintJobStatus not in ('C'/* Completed */, 'X'/* Canceled */));

  /* User can either select tasks or task details, based on the selection message should be displayed appropriately */
  if (@vEntityKey='TaskDetail')
    begin
      set @vAction ='CancelTaskDetail';
      exec @Message = dbo.fn_Messages_BuildActionResponse 'PickTask', @vAction, @vTaskDetailsUpdated, @vTaskDetailsCount;
    end
  else
    begin
      set @vAction = 'CancelTask';
      exec @Message = dbo.fn_Messages_BuildActionResponse 'PickTask', @vAction, @vTasksUpdated, @vTasksCount;
    end

  /* Inserted the message information to display in V3 application */
  if (object_id('tempdb..#ResultMessages') is not null)
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @Message;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_Cancel */

Go
