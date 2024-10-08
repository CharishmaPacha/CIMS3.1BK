/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/05  TK      pr_Tasks_Release: Changes to show appropriate message if task is dependent on Replenishment (HA-1211)
  2018/10/05  VM      pr_Tasks_Release: Included Activity log (S2G-353)
  2018/09/24  TK      pr_Tasks_ConfirmTasksForPicking: Confirm tasks that are allocated or the ones that doesn't need to be allocated
                      pr_Tasks_Release: Exclude the tasks which are canceled or completed (S2GCA-298)
  2018/08/16  TK      pr_Tasks_Release: Bug Fix (OB2-562)
  2018/08/13  TK      pr_Tasks_ConfirmTasksForPicking: Changes to get tasks if Task Id is provided
                      pr_Tasks_Release: Compute TD dependencies while releasing tasks (OB2-562)
  2018/08/12  TK      pr_Tasks_Release: Changed to confirm Tasks for picking before they are released (OB2-557)
  2018/04/30  TK      pr_Tasks_Release: Resolved issue with object reference error while releasing tasks (S2G-758)
  2018/04/26  TK      pr_Tasks_Release: Changes to retrieve tasks if user passes WaveNo (S2G-673)
  2018/03/12  TK      pr_Tasks_Release: Tasks Dependent on Replenishments should not be released (S2G-151)
  2014/09/09  PKS     pr_Tasks_Modify: Made small bug fix at calling pr_Tasks_Release.
  2014/09/05  AK      pr_Tasks_Release:set not to release the tasks which have DestZone as Non-Sort.
  2014/04/18  TD      pr_Tasks_GenerateTempLabels:Changes to generate temp labels.
                      Added new proc pr_Tasks_Release.
                      pr_Tasks_Modify: Changes to release tasks.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Release') is not null
  drop Procedure pr_Tasks_Release;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Release: This will update status of task from OnHold to New and
         will generate temp labels.
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Release
  (@Tasks            TEntityKeysTable readonly,
   @TaskId           TRecordId    = null, --Future Use
   @BatchNo          TPickBatchNo = null, --Future Use
   @ForceRelease     TFlag        = 'N',
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Message          TDescription = null output)
As
  declare @vReturnCode         TInteger,
          @vRecordId           TRecordId,
          @vMessageName        TMessageName,
          @vDebug              TFlag,
          @vActivityLogId      TRecordId,

          @vTaskId             TRecordId,
          @vTasksCount         TCount,
          @vTasksUpdated       TCount,
          @vBatchType          TTypeCode,
          @vTaskSubType        TTypeCode,
          @vGenerateLabel      TControlvalue,
          @vTaskDependency     TFlags,
          @vOldTaskDependency  TFlags,
          @vIsTaskConfirmed    TFlags,
          @vControlCategory    TCategory;

  declare @ttTasks                  TEntityKeysTable,
          @ttTasksToRelease         TEntityKeysTable,
          @ttDependencies           TDependencies,
          @ttTasksToGenerateLabels  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vTasksUpdated   = 0,
         @vTasksCount     = 0,
         @vRecordId       = 0,
         @vMessageName    = null;

  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  /* If User given the TaskId then we need insert that */
  if exists (select * from @Tasks)
    insert into @ttTasks(EntityId) select EntityId from @Tasks;
  else
  if (@TaskId is not null)
    insert into @ttTasks(EntityId) select @TaskId;
  else
    insert into @ttTasks(EntityId)
      select TaskId
      from Tasks
      where (BatchNo      = @BatchNo     ) and
            (BusinessUnit = @BusinessUnit);

  /* select total tasks count here  */
  select @vTasksCount = @@rowcount;

  /* Delete Tasks from temp table which have DestZone as Non-Sort */
  if (@ForceRelease = 'N' /* No */)
    delete from ttT
    from @ttTasks ttT
      join Tasks T on (ttT.EntityId = T.TaskId)
    where T.DestZone = 'Non-Sort';

  /* Add validations prior to this, if needed */
  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Sort Tasks by Dependency Flags */
  insert into @ttTasksToRelease(EntityId, EntityKey)
    select TaskId, DependencyFlags
    from Tasks T
      join @ttTasks ttT on (T.TaskId = ttT.EntityId)
    where Status not in ('X', 'C')
    order by case
               when (T.DependencyFlags = 'N') then 1
               when (T.DependencyFlags = 'M') then 2
               when (T.DependencyFlags = 'R') then 3
               when (T.DependencyFlags = 'S') then 4
               else 9
             end;

  /* Loop thru each task and release them */
  while exists(select * from @ttTasksToRelease where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId          = RecordId,
                   @vTaskId            = EntityId,
                   @vOldTaskDependency = EntityKey
      from @ttTasksToRelease
      where (RecordId > @vRecordId)
      order by RecordId;

      if (charindex('L', @vDebug) > 0)   /* Log activity log */
        exec pr_ActivityLog_Task 'Tasks_Release', @vTaskId, default /* Entity Keys Table */, 'Task', @@ProcId,
                                 @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vActivityLogId out;

      /* Task dependencies are usually computed at the Wave level, but if user would like to
         release the tasks at the Task level, then we have to recompute the dependencies. So,
         for Dependency = RS, we have to re-evaluate. While all tasks together on the Wave may
         depend upon Replenish, some individual tasks could be released, so here we check
         dependency at Task level if it can be released, we release it */
      if (@vOldTaskDependency in ('R', 'S'/* Replenish, Short */))
        begin
          /* Initialize */
          delete from @ttDependencies;

          /* Evaluate Task Dependency again */
          insert into @ttDependencies (DependencyFlags, Count)
            exec pr_TaskDetails_ComputeDependencies default, null, @vTaskId, 'N'/* No, Don't update TD dependencies */;

          select @vTaskDependency = dbo.fn_Tasks_EvaluateDependencies(@ttDependencies)

          /* If the task is short or waiting on replenishment then continue with next task */
          if (@vTaskDependency in ('R', 'S'/* Replenish, Short */))
            begin
              insert into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
                select 'E', @vTaskId, @vTaskId, 'TasksRelease_Dependency_' + @vTaskDependency

              continue;
            end

          /* Evaluate Task dependency */
          update Tasks
          set DependencyFlags = @vTaskDependency
          where (TaskId = @vTaskId);
        end

      /* Comfirm Inventory reservation for the tasks which are released */
      exec pr_Tasks_ConfirmTasksForPicking default, @vTaskId, null/* Batch No */,
                                           @BusinessUnit, @UserId;

      /* Check whether task is confirmed or not */
      select @vIsTaskConfirmed = IsTaskConfirmed
      from Tasks
      where (TaskId = @vTaskId);

      /* If Task not confirmed then continue with next task */
      if (@vIsTaskConfirmed = 'N'/* No */)
        continue;

      /* Update task Details */
      update TaskDetails
      set Status = 'N'/* Ready To Start */
      where (TaskId = @vTaskId) and
            (Status = 'O'/* OnHold */);

      /* Update Tasks here to New */
      update Tasks
      set Status = 'N'/* Ready To Start */
      where (TaskId = @vTaskId) and
            (Status = 'O'/* OnHold */);

      select @vTasksUpdated += 1;

      /* Log TaskDetails info - after release */
      if (charindex('L', @vDebug) > 0)   /* Log activity log */
        exec pr_ActivityLog_Task 'Tasks_Release', @vTaskId, default /* Entity Keys Table */, 'Task', @@ProcId,
                                 @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vActivityLogId out;
    end

  if (@TaskId is not null)
    begin
      select @vTaskSubType = TaskSubType,
             @vBatchType   = BatchType
      from vwPickTasks
      where (TaskId = @TaskId);
    end

  select @vControlCategory = 'Tasks_'+ @vBatchType + '_' + @vTaskSubType,
         @vGenerateLabel   = dbo.fn_Controls_GetAsString(@vControlCategory, 'GenerateTempLabel', 'X',
                                                         @BusinessUnit, @UserId);

  /* Once the tasks have been released then we need to generate temp labels */
  if (@vGenerateLabel = 'R' /* on Release */)
    exec pr_Tasks_GenerateTempLabels null /* BatchNo */, @ttTasksToGenerateLabels,
                                     null /* TaskId */, @BusinessUnit, @UserId;

  exec pr_Messages_BuildActionResponse 'Tasks', 'Release', @vTasksUpdated, @vTasksCount;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_Release */

Go
