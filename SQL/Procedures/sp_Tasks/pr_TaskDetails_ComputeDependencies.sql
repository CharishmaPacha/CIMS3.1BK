/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/13  TK      pr_TaskDetails_ComputeDependencies: Consider wave un-reserve quantity while evaulating dependencies (OB2-Support)
  2018/04/16  TK      pr_TaskDetails_ComputeDependencies: Bug fixes to update Dependencies properly (S2G-568)
  2018/04/12  AY      pr_TaskDetails_ComputeDependencies: Only consider LPNs with PR Lines for dependency (S2G-623)
  2018/04/03  TK      pr_TaskDetails_ComputeDependencies: Bug fix to get counts groupping by TaskId (S2G-Support)
  2018/03/28  TK      pr_Tasks_UpdateDependencies, pr_TaskDetails_ComputeDependencies:
  2018/03/20  VM/AY   pr_Tasks_UpdateDependencies, pr_TaskDetails_ComputeDependencies: Included activity logging (S2G-455)
                      pr_TaskDetails_ComputeDependencies: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_ComputeDependencies') is not null
  drop Procedure pr_TaskDetails_ComputeDependencies;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_ComputeDependencies: Evaluates dependency on Task Details and
    updates Task Detail Dependency if needed and returns the count of each Dependency.

  If TaskDetail dependency has changed, it clears the Task.DependencyFlags so that
  we know those tasks have to be computed again.

    'S': Short, if task qty is greater than avaiable & directed qty
    'R': Waiting on Replenishment, if task qty is greater than available qty and task qty
           is less than available & directed qty
    'N': No Dependency, if available qty in the LPN is greater than task qty and reserved qty
    'M': May be Available, if none of the above

  Picks from Reserve/Bulk are reserved immediately and do not have PR Lines, so do not
  need to compute the dependency on those, so ignoring the LPNs with no PR Lines
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_ComputeDependencies
  (@TaskDetailsToEvaluate  TEntityKeysTable ReadOnly,
   @WaveId                 TRecordId      = null,
   @TaskId                 TRecordId      = null,
   @UpdateTaskDetails      TFlags         = 'Y'/* Yes */)
as
  /* Variable declaration */
  declare @ttTasksUpdated      TRecountKeysTable,
          @vDebug              TFlag,
          @vActivityLogMessage TDescription,
          @vActivityLogId      TRecordId,
          @ttLogTaskDetails    TEntityKeysTable;

  declare @ttTDsToEvaluate  table (WaveId           TRecordId,
                                   TaskId           TRecordId,
                                   TaskDetailId     TRecordId,
                                   LPNId            TRecordId,
                                   LPNDetailId      TRecordId,
                                   TDQty            TQuantity,
                                   RecordId         TRecordId identity(1,1));

  declare @ttLPNsToEvaluate table (LPNId            TRecordId,
                                   LPN              TLPN,

                                   AvailableQty     TQuantity,
                                   ReservedQty      TQuantity,
                                   DirectedQty      TQuantity,
                                   WaveId           TRecordId,
                                   WaveQty          TQuantity,
                                   WaveResQty       TQuantity,
                                   WaveUnResQty     TQuantity,

                                   TaskId           TRecordId,
                                   TaskQty          TQuantity,
                                   NumPRLines       TCount Default 0,

                                   DependencyFlags  As case
                                                         when (NumPRLines = 0) then 'N' /* No Dependency */
                                                         when (AvailableQty >= WaveUnResQty) and (AvailableQty >= ReservedQty)
                                                           then 'N' /* No Dependency */
                                                         when (WaveUnResQty > AvailableQty) and (WaveUnResQty <= AvailableQty + DirectedQty)
                                                           then 'R' /* Waiting on Replenishment*/
                                                         when (WaveUnResQty > AvailableQty + DirectedQty)
                                                           then 'S' /* Short */
                                                         else
                                                           'M' /* May be Available */
                                                       end,

                                   RecordId         TRecordId    identity(1,1));
begin
  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, null /* @vBusinessUnit */, @vDebug output;

  /* Get all the task details from temp table */
  if exists(select * from @TaskDetailsToEvaluate)
    insert into @ttTDsToEvaluate(WaveId, TaskId, TaskDetailId, LPNId, LPNDetailId, TDQty)
      select TD.WaveId, TD.TaskId, TD.TaskDetailId, TD.LPNId, TD.LPNDetailId, TD.UnitsToPick
      from @TaskDetailsToEvaluate TDE join TaskDetails TD on TDE.EntityId = TD.TaskDetailId
      where (TD.Status not in ('X', 'C' /* Cancelled, Completed */));
  else
  /* Get all the task details for the given task */
  if (@TaskId is not null)
    insert into @ttTDsToEvaluate(WaveId, TaskId, TaskDetailId, LPNId, LPNDetailId, TDQty)
      select WaveId, TaskId, TaskDetailId, LPNId, LPNDetailId, UnitsToPick
      from TaskDetails
      where ((TaskId = @TaskId) and (Status not in ('X', 'C' /* Cancelled, Completed */)));
  else
  /* Get all the task details for the given wave */
  if (@WaveId is not null)
    insert into @ttTDsToEvaluate(WaveId, TaskId, TaskDetailId, LPNId, LPNDetailId, TDQty)
      select WaveId, TaskId, TaskDetailId, LPNId, LPNDetailId, UnitsToPick
      from TaskDetails
      where (WaveId = @WaveId) and
            (Status not in ('X', 'C' /* Cancelled, Completed */));

  /* get all the LPNs required to evaluate dependency on task details */
  insert into @ttLPNsToEvaluate(LPNId, LPN, WaveId, WaveQty, WaveResQty, WaveUnResQty)
    select TDE.LPNId, L.LPN, TDE.WaveId,
           sum(TDE.TDQty),
           sum(case when LD.OnhandStatus in ('R'/* Reserved */)      then LD.Quantity    else 0 end),
           sum(case when LD.Onhandstatus in ('PR'/* Pending Resv */) then LD.Quantity    else 0 end)
    from @ttTDsToEvaluate TDE
      join LPNs L on (TDE.LPNId = L.LPNId)
      join LPNDetails LD on (TDE.LPNDetailId = LD.LPNDetailId)
    group by TDE.WaveId, TDE.LPNId, L.LPN;

  /*----------------------------Activity Log---------------------------------*/
  if (charindex('L', @vDebug) > 0)
    begin
      insert into @ttLogTaskDetails (EntityId) select TaskDetailId from @ttTDsToEvaluate;

      exec pr_ActivityLog_Task 'TaskDetails_ComputeDependencies', null, @ttLogTaskDetails, 'TaskDetails', @@ProcId,
                               @ActivityLogId = @vActivityLogId output;
    end

  /* Update the LPN info, Dependency flags is computed column */
  ;with LPNQuantities(LPNId, Quantity, ReservedQty, DirectedQty, NumPRLines) as
  (
    select LD.LPNId,
           sum(case when OnhandStatus in ('A'/* Available */      ) then LD.Quantity    else 0 end),
           sum(case when OnhandStatus in ('A', 'D'/* Avail, Dir */) then LD.ReservedQty else 0 end),
           sum(case when OnhandStatus in ('D'/* Directed */       ) then LD.Quantity    else 0 end),
           sum(case when Onhandstatus in ('PR')                     then 1              else 0 end)
    from LPNDetails LD
      join (select distinct LPNId from @ttLPNsToEvaluate) LE on (LD.LPNId = LE.LPNId)
    group by LD.LPNId
  )
  update @ttLPNsToEvaluate
  set AvailableQty = LQ.Quantity,
      ReservedQty  = LQ.ReservedQty,
      DirectedQty  = LQ.DirectedQty,
      NumPRLines   = LQ.NumPRLines
  from @ttLPNsToEvaluate LE join LPNQuantities LQ on LE.LPNId = LQ.LPNId;

  if (charindex('D', @vDebug) > 0) select * from @ttLPNsToEvaluate;

  /* Update Task details if there is any change in existing Dependency */
  if (@UpdateTaskDetails = 'Y'/* Yes */)
    update TD
    set TD.DependencyFlags = LTE.DependencyFlags
    output Inserted.TaskId into @ttTasksUpdated(EntityId)
    from @ttTDsToEvaluate TDE
      join TaskDetails TD on (TDE.TaskDetailId = TD.TaskDetailId) and
                             (TD.Status not in ('X', 'C'/* Canceled/Completed */))
      join @ttLPNsToEvaluate LTE on (TD.WaveId = LTE.WaveId) and
                                    (TD.LPNId  = LTE.LPNId)
    where (coalesce(TD.DependencyFlags, '') <> LTE.DependencyFlags);

  /* If TD Dependency changed, then have to recompute the Task Dependency,
     update the Task.Dependency = null so caller will recompute those */
  update T
  set DependencyFlags = null
  from Tasks T
    join @ttTasksUpdated ttTU on (T.TaskId = ttTU.EntityId);

  /*----------------------------Activity Log---------------------------------*/
  if (charindex('L', @vDebug) > 0)
    exec pr_ActivityLog_Task 'TaskDetails_ComputeDependencies', null, @ttLogTaskDetails, 'TaskDetails', @@ProcId,
                             @ActivityLogId = @vActivityLogId output;

  /* Return count of each dependency */
  select DependencyFlags, count(*) as Count
  from @ttLPNsToEvaluate
  group by DependencyFlags;
end /* pr_TaskDetails_ComputeDependencies */

Go
