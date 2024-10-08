/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/26  TK      pr_Wave_UpdateDependencies: If wave is not dependent on replenishment then clear replenish dependency from WCSDependency flag (S2G-103)
  2018/05/02  TK      pr_Wave_UpdateDependencies: Changes to release tasks (S2G-673)
  2018/04/03  TK      pr_Wave_UpdateDependencies: Update color code on Wave (S2G-Support)
  2018/03/28  TK      pr_Wave_ReleaseForPicking & pr_Wave_UpdateDependencies:
                        Ignore cancelled tasks
                      pr_Wave_UpdateDependencies: Update WCS dependency if wave is dependent on Replenishments (S2G-499)
  2018/02/23  TK      pr_Wave_UpdateDependencies: Initial Revision (S2G-179)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_UpdateDependencies') is not null
  drop Procedure pr_Wave_UpdateDependencies;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_UpdateDependencies: Updates dependency on Wave
     by evaluating the dependencies on all the tasks
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_UpdateDependencies
  (@WavesToCompute  TEntityKeysTable ReadOnly,
   @WaveId          TRecordId,
   @WaveNo          TWaveNo,
   @ComputeTDs      TFlags        = 'N')
as
  /* declarations */
  declare @vRecordId           TRecordId,
          @vWaveId             TRecordId,
          @vWaveNo             TWaveNo,
          @vDependencyFlags    TFlags,
          @vUpdateTaskDetails  TFlags,
          @vWCSDependencyFlags TFlags,

          @vControlCategory    TCategory,
          @vReleaseTasks       TFlags,
          @vBusinessUnit       TBusinessUnit,
          @vUserId             TUserId,
          @vMessage            TMessage;
  declare @ttWaves             TEntityKeysTable,
          @ttTasks             TEntityKeysTable,
          @ttDependencies      TDependencies;
begin
  /* Initialize */
  set @vRecordId = 0;

  /* Get all the Waves which needs to Processed */
  if exists(select * from @WavesToCompute)
    insert into @ttWaves(EntityId)
      select EntityId
      from @WavesToCompute;
  else
  if (@WaveId is not null)
    insert into @ttWaves(EntityId)
      select WaveId
      from Waves
      where (WaveId = @WaveId);
  else
  if (@WaveNo is not null)
    insert into @ttWaves(EntityId)
      select RecordId
      from PickBatches
      where (BatchNo = @WaveNo);

  /* Loop thru each task and evaulate dependency */
  while exists (select * from @ttWaves where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId        = RecordId,
                   @vWaveId          = EntityId,
                   @vDependencyFlags = null
      from @ttWaves
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Wave Info */
      select @vWaveNo          = WaveNo,
             @vBusinessUnit    = BusinessUnit,
             @vControlCategory = 'PickBatch_' + WaveType,
             @vUserId          = 'cIMSAgent'
      from Waves
      where (WaveId = @vWaveId);

      /* Initialize */
      delete from @ttDependencies;

      /* Update dependency on all the task details */
      if (@ComputeTDs = 'Y'/* Yes */)
        begin
          insert into @ttDependencies (DependencyFlags, Count)
            exec pr_TaskDetails_ComputeDependencies default, @vWaveId, null, 'Y'/* Yes, compute task details */;

          /* computing TD dependency may result in nullifying the dependency on its tasks so recompute Task dependency */
          insert into @ttTasks(EntityId)
            select TaskId
            from Tasks
            where (WaveId = @vWaveId) and
                  (DependencyFlags is null) and
                  (Status not in ('X', 'C'/* Canceled, Completed */));

          /* If there are tasks to update dependency then update */
          if (@@rowcount > 0)
            exec pr_Tasks_UpdateDependencies @ttTasks, null, 'N'/* No, don't compute TD dependency */, 'N'/* No, don't compute Wave dependency */;
        end
      else
        insert into @ttDependencies (DependencyFlags, Count)
          select DependencyFlags, count(*)
          from Tasks
          where (WaveId = @vWaveId) and
                (Status not in ('X', 'C'))
          group by DependencyFlags;

      /* Evaluate dependency flags based on the input dependencies */
      select @vDependencyFlags = dbo.fn_Tasks_EvaluateDependencies (@ttDependencies);

      /* If task detail dependency is not evaluated and dependency is 'M' then we need to
         recompute task details dependency as wave may have multiple tasks and the dependency may change */
      if (@ComputeTDs = 'N'/* No */) and (@vDependencyFlags = 'M'/* May be Available */)
        begin
          /* Initialize */
          set @vDependencyFlags = null;
          delete from @ttDependencies;

          /* compute dependency on all the task details on wave */
          insert into @ttDependencies (DependencyFlags, Count)
            exec pr_TaskDetails_ComputeDependencies default, @vWaveId, null, 'N'/* No, don't comput TD dependency */;

          /* Evaluate dependency flags based on the input dependencies */
          select @vDependencyFlags = dbo.fn_Tasks_EvaluateDependencies (@ttDependencies);
        end

      /* Update dependency on Wave */
      update PickBatches
      set DependencyFlags = @vDependencyFlags,
          @vWCSDependencyFlags =
          --- VM_20180613: Doesn't seem right to me here on why we need to update WCSDependency for all waves here (other than automation waves)
          WCSDependency   = case when @vDependencyFlags in ('S', 'R') and (charindex('R', WCSDependency) = 0) then 'R' + WCSDependency
                                 when @vDependencyFlags in ('N', 'M') and (charindex('R', WCSDependency) > 0) then replace(WCSDependency, 'R', '')
                                 else WCSDependency
                            end,
          ColorCode       = case
                              when coalesce(@vWCSDependencyFlags, WCSDependency) = ''  then 'G' -- Dependency resolved, so show in green
                              when coalesce(@vWCSDependencyFlags, WCSDependency) <> '' then 'R' -- Still there is dependency, show in red
                              else null -- default color
                            end
      where (RecordId = @vWaveId);

      /* If Wave Dependency is cleared then check and release the tasks of that wave */
      if (@vDependencyFlags in ('N', 'M'/* No Dependency, May be Available */))
        begin
          /* get Controls */
          select @vReleaseTasks = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'AutoReleaseTasks',  'N' /* No */, @vBusinessUnit, null/* UserId */);

          /* Invoke procedure to release created tasks */
          if (@vReleaseTasks = 'Y'/* Yes */)
            exec pr_Tasks_Release default, null /* TaskId */, @vWaveNo, default /* Force Release */,
                                  @vBusinessUnit, @vUserId, @vMessage output;
        end
    end
end /* pr_Wave_UpdateDependencies */

Go
