/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/13  VS      pr_Tasks_UpdateDependencies: Passed EntityStatus Parameter (BK-910)
  2018/03/28  TK      pr_Tasks_UpdateDependencies, pr_TaskDetails_ComputeDependencies:
  2018/03/20  VM/AY   pr_Tasks_UpdateDependencies, pr_TaskDetails_ComputeDependencies: Included activity logging (S2G-455)
  2018/03/17  TK      pr_Tasks_UpdateDependencies: Changed pr_PickBatch_UpdateDependencies to pr_Wave_UpdateDependencies
                      pr_Tasks_UpdateDependencies: Initial Revision
  2017/06/02  DK      pr_Tasks_UpdateDependencies: Bug fix to exculde canceled tasks as dependent tasks (HPI-1540).
  2017/01/12  AY      pr_Tasks_UpdateDependencies/TaskDetails_Dependencies: Performance enhancements (HPI-GoLive)
  2016/10/15  AY      pr_Tasks_UpdateDependencies: Revisions to not show completed tasks or consumed LPNs(HPI-GoLive)
  2016/10/06  TK      pr_Tasks_UpdateDependencies: Initial Revision (HPI-832)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_UpdateDependencies') is not null
  drop Procedure pr_Tasks_UpdateDependencies;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_UpdateDependencies: This procedure would calculate and update the
   dependency on the Task. If requested, TDs would be recomputed and then Task
   dependency calculated, or else we can assume TDs are right and just calculate
   Task dependency.
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_UpdateDependencies
  (@Tasks         TEntityKeysTable  ReadOnly,
   @TaskId        TRecordId         = null,
   @ComputeTDs    TFlags            = 'N'/* No */,
   @ComputeWaves  TFlags            = 'D'/* Defer */)
as
  /* Variable declaration */
  declare @vRecordId           TRecordId,
          @vTaskId             TRecordId,
          @vBusinessUnit       TBusinessUnit,
          @vDependencyFlags    TFlags,
          @vDebug              TFlag,
          @vActivityLogMessage TDescription,
          @vActivityLogId      TRecordId;

  declare @ttDependencies      TDependencies,
          @ttWavesToEvaulate   TEntityKeysTable,
          @ttWavesUpdated      TRecountKeysTable,
          @ttLogTasks          TEntityKeysTable;

  declare @ttTasks       table (TaskId           TRecordId,
                                DependencyFlags  TFlags,

                                RecordId         TRecordId identity(1,1));
begin
  /* Initialize */
  select @vRecordId           = 0,
         @vActivityLogMessage = 'ComputeTDs: ' + @ComputeTDs + ', ComputeWaves: ' + @ComputeWaves;

  /* Get all the tasks which needs to Processed */
  if exists(select * from @Tasks)
    insert into @ttTasks(TaskId)
      select EntityId
      from @Tasks;
  else
  if (@TaskId is not null)
    insert into @ttTasks(TaskId)
      select TaskId
      from Tasks
      where (TaskId = @TaskId) and
            (Status not in ('X', 'C'/* Canceled, Completed */));
  else
    insert into @ttTasks(TaskId)
      select TaskId
      from Tasks
      where (DependencyFlags is null) and
            (Status not in ('X', 'C'/* Canceled, Completed */));

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  /*----------------------------Activity Log---------------------------------*/
  if (charindex('L', @vDebug) > 0)
    begin
      insert into @ttLogTasks (EntityId) select TaskId from @ttTasks;

      exec pr_ActivityLog_Task 'Tasks_UpdateDependencies', @TaskId, @ttLogTasks, 'Tasks', @@ProcId,
                               @vActivityLogMessage, @ActivityLogId = @vActivityLogId output;
    end

  /* Loop thru each task and evaulate dependency */
  while exists (select * from @ttTasks where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId        = RecordId,
                   @vTaskId          = TaskId,
                   @vDependencyFlags = null
      from @ttTasks
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Initialize */
      delete from @ttDependencies;

      /* update dependency on all the task details. If any of the task detail dependency changes,
         then Task dependency is reset so that it would be evaluated here */
      if (@ComputeTDs = 'Y')
        insert into @ttDependencies (DependencyFlags, Count)
          exec pr_TaskDetails_ComputeDependencies default, null, @vTaskId, 'Y'/* Yes, update task detail dependencies */;
      else
        /* This is to allow computing task dependency without re-calculating TD dependencies */
        insert into @ttDependencies (DependencyFlags, Count)
          select DependencyFlags, count(*)
          from TaskDetails
          where (TaskId = @vTaskId) and
                (Status not in ('X', 'C'/* Canceled, Completed */))
          group by DependencyFlags;

      /* update dependency on Tasks */
      update @ttTasks
      set DependencyFlags = dbo.fn_Tasks_EvaluateDependencies(@ttDependencies)
      where (TaskId = @vTaskId);
    end

  /* update Dependencies on Tasks, only if there is any change */
  update T
  set @vBusinessUnit    = T.BusinessUnit,
      T.DependencyFlags = ttT.DependencyFlags
  output Inserted.WaveId, Inserted.BatchNo into @ttWavesUpdated(EntityId, EntityKey)
  from @ttTasks ttT
    join Tasks T on (T.TaskId = ttT.TaskId)
  where (ttT.DependencyFlags <> coalesce(T.DependencyFlags, ''));

  /* Get the distinct Waves to evaulate dependencies */
  insert into @ttWavesToEvaulate(EntityId, EntityKey)
    select distinct EntityId, EntityKey
    from @ttWavesUpdated;

  /* Defer Dependency flag computation on Waves */
  if (@ComputeWaves = 'D'/* Defer */)
    /* invoke RequestRecalcCounts to defer Wave Dependency updates */
    exec pr_Entities_RequestRecalcCounts 'Wave', null, null, 'D'/* RecalcOption - Dependency Flags */,
                                         @@ProcId, 'UpdateWaveDependencies'/* Operation */, @vBusinessUnit, null /* EntityStatus */,
                                         @ttWavesUpdated;
  else
  if (@ComputeWaves = 'Y'/* Yes */)
    exec pr_Wave_UpdateDependencies @ttWavesToEvaulate, null, null, 'N'/* No, don't compute task details */;

  /*----------------------------Activity Log---------------------------------*/
  if (charindex('L', @vDebug) > 0)
    exec pr_ActivityLog_Task 'Tasks_UpdateDependencies', @TaskId, @ttLogTasks, 'Tasks', @@ProcId,
                             @vActivityLogMessage, @ActivityLogId = @vActivityLogId output;

end /* pr_Tasks_UpdateDependencies */

Go
