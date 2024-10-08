/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/04  YJ      pr_LPNs_RecomputeWaveAndTaskDependencies: Back ported from Prod (FBV3-1181)
              TK      pr_LPNs_RecomputeWaveAndTaskDependencies: Auto Release tasks when dependency is cleared (HA-1211)
  2018/05/07  TK      pr_LPNs_RecomputeWaveAndTaskDependencies: Changes to eliminate tasks detailscomputation considering wave quantity
  2018/04/12  TK      pr_LPNs_RecomputeWaveAndTaskDependencies: Changes to recompute task details for Operation 'WaveAllocation'(S2G-568)
  2018/04/10  AY      pr_LPNs_RecomputeWaveAndTaskDependencies: Update wave dependency immediately on confirm reservation (S2G-568)
                      pr_LPNs_RecomputeWaveAndTaskDependencies: Changes to recompute task details if there is no change in Location or LPN Quantity
  2018/03/20  VM/AY   pr_LPNs_RecomputeWaveAndTaskDependencies: Included activity logging (S2G-455)
                      pr_LPNs_RecomputeWaveAndTaskDependencies: Initial Revision (S2G-253)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_RecomputeWaveAndTaskDependencies') is not null
  drop Procedure pr_LPNs_RecomputeWaveAndTaskDependencies;
Go
/*------------------------------------------------------------------------------
  pr_LPNs_RecomputeWaveAndTaskDependencies: This proc update dependencies on the TaskDetails,
    Tasks and Waves which are allocated from the given LPN. This needs to be done
    when there is a change in Qty in the LPN. Just because qty changed, we wouldn't need
    to recompute all task details associated with the PR lines. For performance reasons
    we have to recompute only when needed and not unnecessarily. However, when in doubt
    we should recompute. Review the comments in code for the various scenarios we wil
    skip the recomputation.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_RecomputeWaveAndTaskDependencies
  (@LPNId           TRecordId,
   @CurrentQty      TQuantity,
   @PreviousQty     TQuantity,
   @Operation       TOperation = null)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vDebug                 TFlag,
          @vMessage               TDescription,
          @vActivityLogMessage    TDescription,
          @vxmlLogData            TXML,
          @vActivityLogId         TRecordId,
          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId,
          @vLPN                   TLPN,
          @vAvailableQty          TInteger,
          @vReservedQty           TInteger,
          @vDirectedQty           TInteger,
          @vQtyChange             TFlags,
          @vDependenciesToRecalc  TFlags,
          @vUpdateWaveDependency  TFlags,
          @vAutoReleaseTasks      TControlValue;

  declare @ttTasksToEvaluate       TEntityKeysTable,
          @ttTasksToRelease        TRecountKeysTable,
          @ttTaskDetailsToEvaluate TEntityKeysTable,
          @ttDependencies          TDependencies;

  declare @ttTDsToCheckDependencies table (WaveId            TRecordId,
                                           WaveQty           TQuantity,

                                           TaskId            TRecordId,
                                           TaskDetailId      TRecordId,
                                           TDQty             TQuantity,
                                           DependencyFlags   TFlags,

                                           LPNId             TRecordId);
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode = 0,
         @vUserId     = system_user,
         @vUpdateWaveDependency = case when @Operation in ('ConfirmReservation', 'WaveAllocation', 'ReplWaveAllocation') then 'Y' else 'D' /* Defer */ end;

  /* Get LPN info */
  select @vLPN          = LPN,
         @vBusinessUnit = BusinessUnit
  from LPNs
  where (LPNId = @LPNId);

  /* Get Controls */
  select @vAutoReleaseTasks = dbo.fn_Controls_GetAsString('Allocation', 'AutoReleaseTasks', 'N' /* No */, @vBusinessUnit, @vUserId);

  /* Compute available, directed and reserved quantities */
  select @vAvailableQty = sum(case when OnhandStatus in ('A'/* Available */      ) then Quantity    else 0 end),
         @vReservedQty  = sum(case when OnhandStatus in ('A', 'D'/* Avail, Dir */) then ReservedQty else 0 end),
         @vDirectedQty  = sum(case when OnhandStatus in ('D'/* Directed */       ) then Quantity    else 0 end)
  from LPNDetails
  where (LPNId = @LPNId);

  /* Evaluate Qty Change */
  select @vQtyChange = case when (@vAvailableQty > @PreviousQty) or (@Operation = 'UnallocatePRLine') then 'Increase'
                            when (@vAvailableQty < @PreviousQty) then 'Decrease'
                            else 'NoChange'
                       end; -- for code readability

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  /* If Qty increases, but still ReservedQty > AvailableQty then M lines don't need to recomputed
     as they can only become N if ReservedQty <= AvailableQty */
  if (@vQtyChange = 'Increase')
    select @vDependenciesToRecalc = case when (@vReservedQty > @vAvailableQty) then 'RS' else 'MRS' end;

  /* If Qty decreases, but still there is enough AvailableQty to cover ReservedQty then there
     would be no change in N lines */
  if (@vQtyChange = 'Decrease')
    select @vDependenciesToRecalc = case when (@vReservedQty <= @vAvailableQty) then 'MR' else 'MNR' end;

  /* If there is no change in Quantity, this usually happens when a PR line is unallocated or Directed Qty
     is added to Location or when the reservation is confirmed there would be no change in N lines
     If Reserved Qty on the location is greater then Available qty then Recalc S lines which may be converted to R lines
     If inventory is reserved then we need to reclac M lines as they may convert into R lines and Recalc N lines which may convert to M or R lines */
  if (@vQtyChange = 'NoChange')
    select @vDependenciesToRecalc = case when @Operation in ('AddDirectedQty', 'ReplWaveAllocation') then 'S'
                                         when @Operation in ('ConfirmReservation', 'WaveAllocation') then 'NM'
                                         else 'M'
                                    end;

  select @vMessage = @vQtyChange + '-' + @vDependenciesToRecalc;

  /*----------------------------Activity Log---------------------------------*/
  if (charindex('L', @vDebug) > 0)
    begin
      select @vxmlLogData = (select TD.TaskDetailId, T.TaskId, TD.DependencyFlags, TD.Quantity,
                                    @vAvailableQty AvailQty, @vReservedQty ResvQty, @vDirectedQty DirQty
                             from TaskDetails TD join Tasks T on (TD.TaskId = T.TaskId)
                             where (TD.LPNId = @LPNId) and (TD.Status in ('N', 'O')) and
                                   (T.Status in ('O', 'N')) and (T.IsTaskConfirmed = 'N')
                             for XML raw('TDs_Before'), elements);

      exec pr_ActivityLog_AddMessage @Operation, @LPNId, @vLPN, 'LPN', @vMessage,
                                     @@ProcId, @vxmlLogData, @ActivityLogId = @vActivityLogId output;
    end

  /* If there is increase in the Quantity then recoumpute dependencies of Task Details
     whose dependencies are Short, Waiting on Repl & May Be Available */
  if (@vQtyChange = 'Increase')
    begin
      insert into @ttTDsToCheckDependencies(WaveId, TaskId, TaskDetailId, TDQty, DependencyFlags, LPNId)
      select distinct TD.WaveId,  TD.TaskId, TD.TaskDetailId, TD.Quantity, TD.DependencyFlags, TD.LPNId
      from TaskDetails TD
        join Tasks      T on (TD.TaskId    = T.TaskId)
      where (TD.LPNId = @LPNId) and
            (TD.Status in ('N', 'O')) and
            (charindex(TD.DependencyFlags, @vDependenciesToRecalc) > 0) and
            (T.Status in ('O', 'N' /* OnHold, ReadyToStart */)) and
            (T.IsTaskConfirmed = 'N'/* No */);
    end
  else
  /* If there is decrease in the Quantity then recompute dependencies of Task Details
     as necessary */
  if (@vQtyChange = 'Decrease')
    begin
      insert into @ttTDsToCheckDependencies(WaveId, TaskId, TaskDetailId, TDQty, DependencyFlags, LPNId)
      select distinct TD.WaveId,  TD.TaskId, TD.TaskDetailId, TD.Quantity, TD.DependencyFlags, TD.LPNId
      from LPNs          L
        join TaskDetails TD on (L.LPNId      = TD.LPNId ) and
                               (TD.Status in ('N', 'O'))
                               -- (TD.Quantity >= L.Quantity)  this is wrong
        join Tasks       T  on (TD.TaskId    = T.TaskId)
      where (charindex(TD.DependencyFlags, @vDependenciesToRecalc) > 0) and
            (T.Status in ('O', 'N' /* OnHold, ReadyToStart */)) and
            (T.IsTaskConfirmed = 'N'/* No */) and
            (L.LPNId = @LPNId);
    end
  else
  /* If there is no change in the Quantity then recompute dependencies Task Details
     whose dependencies are Short, Waiting on Repl */
  if (@vQtyChange = 'NoChange')
    begin
      insert into @ttTDsToCheckDependencies(WaveId, TaskId, TaskDetailId, TDQty, DependencyFlags, LPNId)
      select distinct TD.WaveId,  TD.TaskId, TD.TaskDetailId, TD.Quantity, TD.DependencyFlags, TD.LPNId
      from LPNs          L
        join TaskDetails TD on (L.LPNId      = TD.LPNId ) and
                               (TD.Status in ('N', 'O'))
                               -- (TD.Quantity >= L.Quantity)  this is wrong
        join Tasks       T  on (TD.TaskId    = T.TaskId)
      where (charindex(TD.DependencyFlags, @vDependenciesToRecalc) > 0) and
            (T.Status in ('O', 'N' /* OnHold, ReadyToStart */)) and
            (T.IsTaskConfirmed = 'N'/* No */) and
            (L.LPNId = @LPNId);
    end

  /* If there are no tasks details to compute then exit */
  if (@@rowcount = 0)
    goto ExitHandler;

  /* Compute total quantity required for the wave from the particular LPN */
  ;with WaveQuantities(WaveId, LPNId, WaveQty) as
  (
    select WaveId, LPNId, sum(TDQty)
    from  @ttTDsToCheckDependencies
    group by WaveId, LPNId
  )
  update ttCD
  set ttCD.WaveQty = WQ.WaveQty
  from @ttTDsToCheckDependencies ttCD join WaveQuantities WQ on ttCD.WaveId = WQ.WaveId and ttCD.LPNId = WQ.LPNId;

  /* delete the TDs that are not required to compute */
  delete ttCD
  from @ttTDsToCheckDependencies ttCD
                                 -- exclude M Lines if the pick qty is still less than or equal to AvailableQty even
                                 -- after decrease in qty
  where DependencyFlags in (case when (@vQtyChange = 'Decrease') and (WaveQty <= @vAvailableQty) then 'M'
                                 -- exclude R Lines if the pick qty is still less than or equal to AvailableQty + Directedqty
                                 -- even after decrease in qty
                                 when (@vQtyChange = 'Decrease') and (WaveQty <= @vAvailableQty + @vDirectedQty) then 'R'
                                 -- exclude R Lines if the pick qty is still more than AvailableQty even after increase in qty
                                 when (@vQtyChange = 'Increase') and (WaveQty > @vAvailableQty) then 'R'
                                 -- exclude S Lines if the pick qty is still greater than AvailableQty + DirectedQty even after increase in qty
                                 when (@vQtyChange = 'Increase') and (WaveQty > @vAvailableQty + @vDirectedQty) then 'S'
                            end);

  /* Get all the Task Details to evaulate dependencies */
  insert into @ttTaskDetailsToEvaluate (EntityId, EntityKey)
    select TaskDetailId, TaskId
    from @ttTDsToCheckDependencies;

  /*----------------------------Activity Log---------------------------------*/
  if (charindex('L', @vDebug) > 0)
    begin
      select @vxmlLogData = (select * from @ttTaskDetailsToEvaluate
                             for XML raw('TDs_Recalc'), elements);

      exec pr_ActivityLog_AddMessage @Operation, @LPNId, @vLPN, 'LPN',
                                     @vMessage, @@ProcId, @vxmlLogData, @ActivityLogId = @vActivityLogId;
    end

  if (charindex('D', @vDebug) > 0) select 'TDsToEvaluate', * from @ttTaskDetailsToEvaluate;

  /* Compute Dependencies all the task details */
  insert into @ttDependencies (DependencyFlags, Count) -- results not used
    exec pr_TaskDetails_ComputeDependencies @ttTaskDetailsToEvaluate, @UpdateTaskDetails = 'Y'/* Yes */;

  if (charindex('D', @vDebug) > 0) select 'TDsAfterEvaluate', TD.TaskId, TD.DependencyFlags, TD.*
                                   from @ttTaskDetailsToEvaluate TDE join TaskDetails TD on TDE.EntityId = TD.TaskDetailId;

  /* Recomputing tasks details may result a change in Task dependency, if yes then re-compute Tasks dependency */
  insert into @ttTasksToEvaluate (EntityId)
    select distinct T.TaskId
    from @ttTaskDetailsToEvaluate ttTDE
      join Tasks T on (ttTDE.EntityKey = T.TaskId)
    where (T.DependencyFlags is null);

  /* Compute Dependencies all the tasks that may change */
  if (@@rowcount > 0)
    exec pr_Tasks_UpdateDependencies @ttTasksToEvaluate, null, 'N'/* No */, @vUpdateWaveDependency;

  /* If the dependency on the tasks updated above are not waiting on Replenishment or
     inventory isn't short then release those tasks */
  if (@vAutoReleaseTasks = 'Y' /* Yes */)
    begin
      insert into @ttTasksToRelease (EntityId)
        select TaskId
        from Tasks T join @ttTasksToEvaluate TE on (T.TaskId = TE.EntityId)
        where (T.Status = 'O'/* OnHold */) and
              (DependencyFlags not in ('R', 'S'/* Replenish, Short */))

      /* invoke ExecuteInBackGroup to defer to defer Task Release */
      exec pr_Entities_ExecuteInBackGround 'Task', null, null, 'TR'/* ProcessCode - Task Release */,
                                           @@ProcId, 'TaskRelease', @vBusinessUnit, @ttTasksToRelease;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_RecomputeWaveAndTaskDependencies */

Go
