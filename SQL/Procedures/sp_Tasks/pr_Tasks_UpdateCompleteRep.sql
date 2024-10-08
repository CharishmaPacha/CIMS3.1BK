/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/29  DK      pr_Tasks_UpdateCompleteRep: Bug fix to clear Dependenton field while updating DependencyFlags as Completed (HPI-1540)
  2016/08/05  AY      pr_Tasks_UpdateCompleteRep: Bug fix - dependency flag clearing on partial PA of Directed Qty.
  2016/07/27  OK      pr_Tasks_UpdateCompleteRep: Enhance to use the DependencyFlags instead of using UDF1 field (HPI-371)
  2016/06/05  PK      Added new procedure pr_Tasks_UpdateCompleteRep
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_UpdateCompleteRep') is not null
  drop Procedure pr_Tasks_UpdateCompleteRep;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_UpdateCompleteRep: Review all Tasks which have a dependency flag
   of R i.e. Waiting to be replenished and check if all LPNDetails have now been
   changed to R (they would have been DR earlier) - if so, then the dependency
   is complete and the Dependency flag is to be updated accordingly.
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_UpdateCompleteRep
as
  /* Variable declaration */
  declare @ttTasks   TEntityKeysTable,
          @vRecordId TRecordId,
          @vTaskId   TRecordId;

begin
  select @vRecordId = 0;

  /* Check all tasks which have dependency of R and if there are no LPN Details with DR anymore
     if so, Update them */
  with NoDependencyTasks(TaskId) as
  (
    select T.TaskId
    from Tasks T
      join TaskDetails TD on (T.TaskId = TD.TaskId)
      --left outer join LPNDetails LD on (LD.LPNDetailId = TD.LPNDetailId) and (LD.OnhandStatus = 'DR')
      left outer join LPNDetails LD on (TD.LPNId = LD.LPNId) and (TD.OrderDetailId = LD.OrderDetailId) and (LD.OnhandStatus = 'D')
    where (T.DependencyFlags = 'R')
    group by T.TaskId
    having Max(LD.LPNId) is null
  )
  update T
  set DependencyFlags = 'C' /* Completed */,
      DependentOn     = ''
  from Tasks T join NoDependencyTasks NDT on (T.TaskId = NDT.TaskId);

  /* Update dependencies on the Tasks and Task Details*/
  exec pr_Tasks_UpdateDependencies;
  exec pr_TaskDetails_UpdateDependentOn;

end /* pr_Tasks_UpdateCompleteRep */

Go
