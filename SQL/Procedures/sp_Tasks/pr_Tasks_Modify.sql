/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/13  TK      pr_Tasks_Modify: Changes to execute Confirm Tasks for Picking action
  2015/07/13  VM      pr_Tasks_Modify: Due an internal transaction started in pr_Tasks_Cancel, commit transaction if exists (FB-250)
  2014/09/09  PKS     pr_Tasks_Modify: Made small bug fix at calling pr_Tasks_Release.
  2014/04/30  TD      pr_Tasks_Modify:Reading tasks from xml by default.
  2014/04/22  PV      pr_Tasks_Modify: Added AssignTaskToUser action.
  2014/04/18  TD      pr_Tasks_GenerateTempLabels:Changes to generate temp labels.
                      Added new proc pr_Tasks_Release.
                      pr_Tasks_Modify: Changes to release tasks.
  2014/01/03  NY      pr_Tasks_Modify: Added condition to get count of assigned tasks while clearing the tasks.
  2013/11/28  TD      pr_Tasks_Cancel and pr_Tasks_Modify: Changes to Cancel Task Line.
  2013/11/18  NY      pr_Tasks_Modify:Implemented PickTask AssignToUser.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Modify') is not null
  drop Procedure pr_Tasks_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Modify
  XML Sturcture

<ModifyTasks>
  <Action>CancelTask</Action>
  <Data>

  </Data>
  <Tasks>
    <TaskId>1</TaskId>
    <TaskId>12</TaskId>
    <TaskId>3</TaskId>
  </Tasks>

  <TaskDetails>
    <TaskDetailId>1</TaskDetailId>
    <TaskDetailId>12</TaskDetailId>
    <TaskDetailId>3</TaskDetailId>
  </Tasks>
</ModifyTasks>
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Modify
  (@BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @TaskContents      TXML,
   @Message           TMessage output)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,

          @vAction             TAction,
          @vRecordId           TRecordId,
          @vBatches            TNVarChar,
          @vForceRelease       TFlag,
          @vAssignToUserId     TUserId,
          @vUserName           TUserId,
          @xmlData             xml,
          @vPriority           TPriority,
          @vAuditActivity      TActivityType,
          @vAuditRecordId      TRecordId,
          @vAuditNote1         TDescription,
          @vTasksCount         TCount,
          @vTasksUpdated       TCount,
          @vClearAssignedCount TCount,
          @vModifiedDate       TDateTime;

  /* Temp table to hold all the Tasks to be updated */
  declare @ttTasks          TEntityKeysTable,
          @ttTasksToModify  TEntityKeysTable,
          @ttTaskDetails    TEntityKeysTable;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @xmlData     = convert(xml, @TaskContents),
         @vAuditNote1 = '';

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/ModifyTasks') as Record(Col);

  /* Load all the tasks into the temp table which are to be updated in tasks table */
  if (@vAction = 'CancelTaskDetail')
    insert into @ttTasks (EntityId, EntityKey)
      select Record.Col.value('.', 'TRecordId'), 'TaskDetail'
      from @xmlData.nodes('/ModifyTasks/TaskDetails/TaskDetailId') as Record(Col);
  else
  if (@vAction = 'AssignTaskToUser')
    insert into @ttTasks (EntityId)
      select Record.Col.value('.', 'TRecordId')
      from @xmlData.nodes('/ModifyTasks/Tasks/TaskId') as Record(Col);
  else
  if (@vAction = 'AssignTaskDetailToUser')
    begin
      insert into @ttTaskDetails (EntityId)
        select Record.Col.value('.', 'TRecordId')
        from @xmlData.nodes('/ModifyTasks/Tasks/TaskId') as Record(Col);

      insert into @ttTasks(EntityId)
        select distinct TD.TaskId
        from @ttTaskDetails TTD join TaskDetails TD on TTD.EntityId = TD.TaskDetailId;
    end
  else
    begin
      insert into @ttTasks (EntityId)
      select Record.Col.value('.', 'TRecordId')
      from @xmlData.nodes('/ModifyTasks/Tasks/TaskId') as Record(Col);
    end

  /* get count here from the temp table  */
  select @vTasksCount = @@rowcount;

  if (@vAction = 'CancelTask')
    begin
      exec pr_Tasks_Cancel @ttTasks, null /* TaskId */, null /* Batch No */,
                           @BusinessUnit, @UserId, @Message output;

      select @vAuditActivity = @vAction,
             @vAction        = 'Cancel',
             @vModifiedDate  = current_timestamp;
    end
  else
  if (@vAction = 'CancelTaskDetail')
    begin
      exec pr_Tasks_Cancel @ttTasks, null /* TaskId */, null /* Batch No */,
                           @BusinessUnit, @UserId, @Message output;

      select @vAction        = 'CancelTaskDetail',
             @vAuditActivity = @vAction,
             @vModifiedDate  = current_timestamp;
    end
  else if (@vAction = 'ConfirmTaskForPicking')
    begin
      exec pr_Tasks_ConfirmTasksForPicking @ttTasks, null /* TaskId */, null /* Batch No */,
                                           @BusinessUnit, @UserId, @Message output;

      select @vAuditActivity = @vAction,
             @vModifiedDate  = current_timestamp;
    end
  else
  if (@vAction in ('AssignTaskToUser', 'AssignTaskDetailToUser'))
    begin
      select @vAssignToUserId = Record.Col.value('AssignUser[1]', 'varchar(50)')
      from @xmlData.nodes('/ModifyTasks/Data') as Record(Col);

      /* Check if the UserName is passed or not */
      if (@vAssignToUserId is null)
        set @MessageName = 'UserIsRequired';
      else
      if ((@vAssignToUserId <> '-1') and
          (not exists (select UserName
                       from vwPickBatchUsers
                       where (UserId = @vAssignToUserId))))
        set @MessageName = 'UserIsInactive';

      if (@MessageName is not null)
        goto ErrorHandler;

      /* Passing User Name instead of userId*/
      select @vUserName = UserName
      from Users
      where UserId = @vAssignToUserId;

      /* Get the valid task count to clear assigned user */
      if (coalesce(@vUserName,'') = '')
        begin
          select @vClearAssignedCount = count(*)
          from Tasks T
            join @ttTasks TT on (T.TaskId = TT.EntityId)
          where (T.Status in ('O' /* onhold */, 'N' /* New */, 'I' /* In progress */)) and
                (T.BusinessUnit = @BusinessUnit) and
                (coalesce(T.AssignedTo,'') <> '');
        end

      /* Update all tasks in the temp table */
      update Tasks
      set AssignedTo     = nullif(@vUserName, '-1' /* Clear Assignment */),
          @vModifiedDate =
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output Deleted.TaskId into @ttTasksToModify (EntityId)
      from Tasks T
          join @ttTasks TT on (T.TaskId = TT.EntityId)
      where (T.Status in ('O'/* Onhold */, 'N' /* New */, 'I' /* In progress */)) and
            (T.BusinessUnit = @BusinessUnit);

      select @vTasksUpdated = case
                                when @vAssignToUserId = '-1' then @vClearAssignedCount
                                else @@rowcount
                              end;

      if (@vAssignToUserId = '-1')
        begin
          select @vAction        = 'ClearUser',
                 @vAuditActivity = 'TaskUnassigned';
        end
      else
        begin
          select @vAction        = 'AssignUser',
                 @vAuditActivity = 'TaskAssigned',
                 @vAuditNote1    = @vUserName;
        end;
    end
  else
  if (@vAction = 'ReleaseTask')
    begin
      select @vForceRelease = Record.Col.value('ForceRelease[1]', 'TFlag')
      from @xmlData.nodes('/ModifyTasks/Data') as Record(Col);

      /* Call procedure here to update status as released */
      exec pr_Tasks_Release @ttTasks, null /* TaskId */ , null /* Batch No */, @vForceRelease,
                            @BusinessUnit, @UserId, @Message output;
      /* # tasks released? */
    end
  else
    /* If the action is other then 'listed', send a message to UI saying Unsupported Action*/
    set @MessageName = 'UnsupportedAction';

  if (@Message is null)
    exec @Message = dbo.fn_Messages_BuildActionResponse 'PickTask', @vAction, @vTasksUpdated, @vTasksCount;

  /* Audit trail */
  if (@vAuditActivity is not null)
    begin
      /* Multiple Batches would have been updated, we will generate one Audit Record
         and link all the updated batches to it */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, @vModifiedDate,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vAuditNote1,
                                @AuditRecordId = @vAuditRecordId output;

      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Task', @ttTasksToModify, @BusinessUnit;
    end;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  if (@@trancount > 0)
    commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Tasks_Modify */

Go
