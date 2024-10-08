/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_ConfirmReservation') is not null
  drop Procedure pr_Tasks_ConfirmReservation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_ConfirmReservation:
    This Procedure validates whether the given Tasks are qualified to confirm for Picking or not,
    if given Tasks are qualified for picking then all the Pending Reservation lines associated
    with the Tasks would be marked as Reserved and there by reducing the quantity and
    reserved qty on the available line.
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_ConfirmReservation
  (@TasksToConfirm   TEntityKeysTable readonly,
   @TaskId           TRecordId    = null,
   @WaveNo           TWaveNo      = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Message          TDescription = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vTranCount         TCount,

          @vTotalTasks        TCount,
          @vTasksConfirmed    TCount,
          @vTaskRecordId      TRecordId,
          @vTDRecordId        TRecordId,

          @vTaskId            TRecordId,
          @vTaskStatus        TStatus,
          @vTDQuantity        TQuantity,
          @vPreviousTaskId    TRecordId,

          @vPRLPNId           TRecordId,
          @vPRLPNDetailId     TRecordId,
          @vAvailLPNDetailId  TRecordId,
          @vAvailLineQty      TQuantity,
          @vAvailLineResQty   TQuantity,
          @vNumPRLines        TCount,
          @vDependencyFlags   TFlags,

          @vLPNRecId          TRecordId,
          @vLPNId             TRecordId,
          @vLPNQuantity       TQuantity;

  declare @ttTasksConfirmed          TEntityKeysTable,
          @ttTaskDetailsToEvaluate   TEntityKeysTable,
          @ttTasksToEvaluate         TEntityKeysTable,
          @ttLPNs                    TEntityKeysTable;
  declare @ttTaskDetails table (TaskId          TRecordId,
                                TaskDetailId    TRecordId,
                                LPNId           TRecordId,
                                LPNDetailId     TRecordId,
                                OrderId         TRecordId,
                                OrderDetailId   TRecordId,
                                Quantity        TQuantity,

                                DependencyFlags TFlags,

                                RecordId        TRecordId identity(1,1));
  declare @ttTasks       table (TaskId          TRecordId,
                                TaskStatus      TStatus,
                                DependencyFlags TFlags,
                                Priority        TPriority,

                                RecordId        TRecordId identity(1,1));
begin /* pr_Tasks_ConfirmReservation */
  SET NOCOUNT ON;

  /* set default values here */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vTaskRecordId   = 0,
         @vTasksConfirmed = 0,
         @vTranCount      = @@trancount;

  /* Get all the tasks that needs to be confirmed */
  /* Caller may pass Temp Table with TaskIds or Task or Wave, get all the tasks from them */
  if exists(select * from @TasksToConfirm)
    insert into @ttTasks(TaskId, TaskStatus, DependencyFlags, Priority)
      select distinct T.TaskId, T.Status, T.DependencyFlags, T.Priority
      from @TasksToConfirm TC
        join Tasks T on (TC.EntityId = T.TaskId)
      order by T.Priority, T.TaskId;
  else
  if (@TaskId is not null)
    insert into @ttTasks(TaskId, TaskStatus, DependencyFlags, Priority)
      select distinct T.TaskId, T.Status, T.DependencyFlags, T.Priority
      from Tasks T
      where (TaskId = @TaskId);
  else
  if (@WaveNo is not null)
    insert into @ttTasks(TaskId, TaskStatus, DependencyFlags, Priority)
      select distinct T.TaskId, T.Status, T.DependencyFlags, T.Priority
      from Tasks T
      where (BatchNo      = @WaveNo) and
            (BusinessUnit = @BusinessUnit);

  /* Get the total count of selected Tasks */
  select @vTotalTasks = @@rowcount;

begin try
  if (@vTranCount = 0)
    begin transaction;

  /* Loop thru each task, evaluate & reserve inventory */
  while exists(select * from @ttTasks where RecordId > @vTaskRecordId)
    begin
      select top 1 @vTaskRecordId    = RecordId,
                   @vTaskId          = TaskId,
                   @vTaskStatus      = TaskStatus,
                   @vDependencyFlags = DependencyFlags,
                   @vNumPRLines      = 0
      from @ttTasks
      where (RecordId > @vTaskRecordId)
      order by RecordId;

      /* Check whether task is qualified to Confirm for Picking or not, if not continue with next task */
      if (@vDependencyFlags not in ('M', 'N'/* May be Available, No Dependency */))
        continue;

      /* Initialize */
      delete from @ttLPNs;
      delete from @ttTaskDetails;
      delete from @ttTasksToEvaluate;
      delete from @ttTaskDetailsToEvaluate;

      select @vTDRecordId = 0,
             @vReturnCode = 0;

      /* if Task is qualified to Confirm for Picking get all Task Details */
      insert into @ttTaskDetails(TaskId, TaskDetailId, LPNId, LPNDetailId, OrderId, OrderDetailId, Quantity, DependencyFlags)
        select distinct TaskId, TaskDetailId, TD.LPNId, TD.LPNDetailId, TD.OrderId, TD.OrderDetailId, TD.Quantity, TD.DependencyFlags
        from TaskDetails TD
          join LPNDetails LD on (TD.LPNDetailId = LD.LPNDetailId)
        where (TD.TaskId       = @vTaskId) and
              (TD.Status not in ('X', 'C')) and
              (LD.OnHandStatus = 'PR'/* Pending Reservation */)
        order by LPNId;

      /* If there are no PR lines to process with current task then continue with next task */
      if (@@rowcount = 0)
        begin
          /* If there are no Pending Resv lines, then mark task as confirmed if Task is not confirmed */
          update Tasks
          set IsTaskConfirmed = 'Y'/* Yes */
          where (TaskId          = @vTaskId   ) and
                (IsTaskConfirmed = 'N'/* No */) and
                (IsTaskAllocated in ('Y', 'NR')); -- Confirm only tasks that are allocated or allocation is not required

          continue;
        end

      begin try
        /* save the transaction at this point so that if there is an error with the
           confirming the reservation for that LPN details, then only that is rolled back and
           we continue with other LPN Details */
        Save Transaction LPNDetailConfirmResv;

      /* Loop thru each detail and mark Pending Reservation lines as Reserved */
      while exists (select * from @ttTaskDetails where RecordId > @vTDRecordId)
        begin
          select top 1 @vTDRecordId    = RecordId,
                       @vPRLPNId       = LPNId,
                       @vPRLPNDetailId = LPNDetailId,
                       @vTDQuantity    = Quantity
          from @ttTaskDetails
          where (RecordId > @vTDRecordId)
          order by RecordId;

          /* Confirm each LPN detail reservation but reducing corresponding quantities on the available line */
          exec @vReturnCode = pr_LPNDetails_ConfirmReservation @vPRLPNId, @vPRLPNDetailId, @vTDQuantity;

          /* If there is any error, break the loop */
          if (@vReturnCode <> 0)
            break;
        end

      end try
      begin catch
        /* Unless it is sn irrecoverable error, then rollback for this task only. However
           if it is an error that cannot be recovered, then exit */
        if (XAct_State() <> -1)
          rollback transaction LPNDetailConfirmResv;
        else
          exec @vReturnCode = pr_ReRaiseError;
      end catch

      /* Get the PR line count for the task */
      select @vNumPRLines = count(*)
      from LPNDetails LD
        join TaskDetails TD on (LD.LPNDetailId = TD.LPNDetailId)
      where (TD.TaskId = @vTaskId) and
            (LD.OnhandStatus = 'PR'/* Pending Resv. */);

      /* update Task dependency flag to 'N', as all Details have been successfully confirmed above */
      if (@vNumPRLines = 0)
        begin
          update Tasks
          set IsTaskConfirmed = 'Y' /* Yes */,
              DependencyFlags = 'N' /* No Dependency */,
              ModifiedDate    = current_timestamp
          where (TaskId = @vTaskId) and
                (IsTaskAllocated in ('Y', 'NR'));

          /* update dependency flag to 'N' on task details that are confirmed */
          if (@@rowcount > 0)
            update TD
            set DependencyFlags = 'N' /* No Dependency */,
                ModifiedDate    = current_timestamp
            from TaskDetails TD join @ttTaskDetails TTD on (TD.TaskDetailId = TTD.TaskDetailId);
        end

      /* If current task dependency is may be available, then confirming this task might push other task to at risk and,
         If current task dependency is No Dependency, then confirming this task might push other task to may be available

         recompute dependecies on all dependent tasks */

      /* Get the LPNs to recompute, we need to get the LPNs whose dependency is may be available */
      insert into @ttLPNs(EntityId)
        select distinct LPNId
        from TaskDetails TD
          join Tasks T on (TD.TaskId = T.TaskId)
        where (T.TaskId = @vTaskId) and
              (TD.DependencyFlags in ('N', 'M'));

       /* Initialize */
       set @vLPNRecId = 0;

       /* Loop thru each LPN and recompute task dependencies */
       while exists (select * from @ttLPNs where RecordId > @vLPNRecId)
         begin
           select top 1 @vLPNRecId = RecordId,
                        @vLPNId    = EntityId
           from @ttLPNs
           where (RecordId > @vLPNRecId)
           order by RecordId;

           /* Recount the LPN to update status after Reservations done earlier */
           exec pr_LPNs_Recount @vLPNId;

           /* Get current LPN quantity */
           select @vLPNQuantity = Quantity
           from LPNs
           where (LPNId = @vLPNId);

           /* update dependencies of the Tasks - Needs to be done after LPN Recount above */
           if (exists (select * from LPNDetails where LPNId = @vLPNId and Onhandstatus = 'PR'))
             exec pr_LPNs_RecomputeWaveAndTaskDependencies @vLPNId, null /* Current Qty*/, @vLPNQuantity, 'ConfirmReservation';
         end

      /* count the tasks that are Confirmed */
      set @vTasksConfirmed = @vTasksConfirmed + 1;
    end

  /* Build output message */
  exec @Message = dbo.fn_Messages_BuildActionResponse 'PickTask', 'ConfirmTasksForPicking', @vTasksConfirmed, @vTotalTasks;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If we have started the transaction then commit */
  if (@vTranCount = 0)
    commit transaction;
end try
begin catch
  /* If we have started the transaction then rollback, else let caller do it */
  if (@vTranCount = 0) rollback transaction;

  exec pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_ConfirmReservation */

Go
