/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/17  VS      pr_Wave_UpdatePrintDependencies: Do not change Newly created PrintJob Status to OnHold (HA-1375)
  2020/12/17  VS/RV   pr_Wave_UpdatePrintDependencies: Excluded completed and cancled tasks (S2GCA-1386)
  2020/07/30  RV      pr_Wave_UpdatePrintDependencies: Initial version (S2GCA-1199)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_UpdatePrintDependencies') is not null
  drop Procedure pr_Wave_UpdatePrintDependencies;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_UpdatePrintDependencies: Updates print dependency on Wave
     by evaluating the dependencies on all the tasks
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_UpdatePrintDependencies
  (@ttTasksToUpdate TEntityKeysTable readonly,
   @TaskId          TRecordId     = null,
   @WaveId          TRecordId     = null,
   @BusinessUnit    TBusinessUnit = null)
as
  /* declarations */
  declare @vReturnCode            TInteger,
          @vRecordId              TRecordId,
          @vWaveId                TRecordId,

          @vOnHoldTasksCount      TInteger;

  declare @ttTasksToEvaluate table(TaskId TRecordId,
                                   WaveId TRecordId);

  declare @ttWavesToEvaluate  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Get all the Tasks against the wave to evaluate print dependencies */
  if (@WaveId is not null)
    insert into @ttTasksToEvaluate(TaskId, WaveId)
      select TaskId, WaveId
      from Tasks
      where (WaveId = @WaveId) and
            (Status <> 'X' /* Cancelled */);
  else
  if (@TaskId is not null)
    insert into @ttTasksToEvaluate(TaskId, WaveId)
      select TaskId, WaveId
      from Tasks
      where (TaskId = @TaskId) and
            (Status <> 'X' /* Cancelled */);
  else
  if exists(select * from @ttTasksToUpdate)
    insert into @ttTasksToEvaluate(TaskId, WaveId)
      select T.TaskId, T.WaveId
      from Tasks T
        join @ttTasksToUpdate ttT on (ttT.EntityId = T.TaskId)
      where (T.Status <> 'X' /* Cancelled */);

  /* Evaluate the print status based upon the small package labels generation, OnHold the tasks if all labels are not generated */
  update T
  set T.PrintStatus = case when (dbo.fn_ShipLabel_AreSPGLabelsGenerated( null /* ProcessBatch */, null /* WaveId */, T.TaskId, null /* OrderId */, null /* LPNId */, T.BusinessUnit) = 'N')
                             then 'OnHold'
                           else 'ReadyToPrint' end
  from Tasks T
    join @ttTasksToEvaluate ttT on (ttT.TaskId = T.TaskId);

  /* Get all the Task's Waves to evaluate the print dependencies */
  if exists( select * from @ttTasksToEvaluate)
    insert into @ttWavesToEvaluate(EntityId)
      select distinct WaveId
      from @ttTasksToEvaluate

  /* Update the Wave PrintStatus based upon the Tasks' print status */
  ;with OnholdTasks as
  (
    select W.EntityId WaveId, sum(case when (T.PrintStatus = 'OnHold') then 1 else 0 end) OnholdTasksCount
    from @ttWavesToEvaluate W left outer join Tasks T on (T.WaveId = W.EntityId)
    group by W.EntityId
  )
  update W
  set PrintStatus = case when (coalesce(OT.OnHoldTasksCount, 0) > 0) then 'OnHold' else 'ReadyToPrint' end
  from Waves W join OnholdTasks OT on W.WaveId = OT.WaveId;

  /* Update print job's status after evaluating the Waves/Tasks to release print jobs */
  update PJ
  set PrintJobStatus = case when (W.PrintStatus = 'ReadyToPrint') and (PrintJobStatus = 'O' /* Onhold */)
                              then 'R' /* Ready To Process */
                            when (W.PrintStatus = 'OnHold') and (PrintJobStatus = 'O' /* Onhold */)
                              then 'O' /* Onhold */
                            else PrintJobStatus
                       end
  from PrintJobs PJ
    join @ttWavesToEvaluate ttW on (PJ.EntityId = ttW.EntityId) and (PJ.EntityType = 'Wave') and (PJ.Archived = 'N')
    join Waves W on (W.WaveId = ttW.EntityId)
  where (PJ.PrintJobStatus not in ('X', 'C'));

  /* Update print job's status after evaluating the Waves/Tasks to release print jobs */
  update PJ
  set PrintJobStatus = case when (T.PrintStatus = 'ReadyToPrint') and (PrintJobStatus = 'O' /* Onhold */)
                              then 'R'
                            when (T.PrintStatus = 'OnHold') and (PrintJobStatus = 'O' /* Onhold */)
                              then 'O' /* Onhold */
                            else PrintJobStatus
                       end
  from PrintJobs PJ
    join @ttTasksToEvaluate ttT on (PJ.EntityId = ttT.TaskId) and (PJ.EntityType = 'Task') and (PJ.Archived = 'N' /* No */)
    join Tasks T on (T.TaskId = ttT.TaskId)
  where (PJ.PrintJobStatus not in ('X' /* Cancelled */, 'C' /* Completed */));

end /* pr_Wave_UpdatePrintDependencies */

Go
