/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/06  OK      pr_Allocation_UpdateWaveDependencies: Changes to use new proc pr_PrintJobs_EvaluatePrintStatus
  2020/11/21  VS      pr_Allocation_InsertShipLabels, pr_Allocation_UpdateWaveDependencies: Made changes to update Wave.PrintStatus and Task.Printstatus in Waveupdates
                         to update the PrintJob status (S2GCA-1386)
  2020/08/05  TK      pr_Allocation_CartCubing_FindPositionToAddCarton, pr_Allocation_CreatePickTasks_PTS,
                      pr_Allocation_ProcessTaskDetails & pr_Allocation_AddDetailsToExistingTask:
                        Changes to use CartType that is defined in rules (HA-1137)
                      pr_Allocation_FinalizeTasks: Removed unnecessary code as updating dependices is being
                        done in pr_Allocation_UpdateWaveDependencies (HA-1211)
  2018/08/29  TK      pr_Allocation_UpdateWaveDependencies: Compute Wave dependency for replenish waves as well (S2GCA-158)
  2018/04/13  TK      pr_Allocation_UpdateWaveDependencies: Initial revision (S2G-568)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_UpdateWaveDependencies') is not null
  drop Procedure pr_Allocation_UpdateWaveDependencies;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_UpdateWaveDependencies: Updates dependency on given Wave
    at the end of allocation. It also updates dependency on all the Waves, Task
    and Task Details related to allocated LPNs.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_UpdateWaveDependencies
  (@WaveId        TRecordId,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessage,

          @vLPNRecId         TRecordId,
          @vLPNId            TRecordId,
          @vLPNQuantity      TQuantity,
          @vWaveId           TRecordId,
          @vWaveType         TTypeCode,
          @vOperation        TOperation;

  declare @ttLPNs            TEntityKeysTable,
          @ttPrintEntitiesToEvaluate
                             TPrintEntities;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vLPNRecId    = 0;

  /* Get Wave info  */
  select @vWaveId    = WaveId,
         @vWaveType  = WaveType,
         @vOperation = case when WaveType in ('R', 'RU', 'RP') then 'ReplWaveAllocation' else 'WaveAllocation' end
  from Waves
  where (WaveId = @WaveId);

  /* Prepare hash table to evaluate Print status */
  select * into #ttEntitiesToEvaluate from @ttPrintEntitiesToEvaluate;
  insert into #ttEntitiesToEvaluate(EntityId, EntityType) select @vWaveId, 'Wave';

  /* Evaluate the dependencies of the print jobs related to the Wave */
  exec pr_PrintJobs_EvaluatePrintStatus @BusinessUnit, @UserId;

  /* Compute Wave & Task Dependencies */
  exec pr_Wave_UpdateDependencies default, @vWaveId, null,'Y'/* Yes, Compute Task Details */;

  /* Update wave dependencies on the given wave */
  if (@vWaveType not in ('R', 'RU', 'RP'/* Replenish */))
    begin
      /* There may be chance that the dependency on waves allocated earlier may change i,e.
         Wave with Dependency 'N' may go to 'M'
         Wave with Dependency 'M' may go to 'R'

         So recomupte dependency on all the Waves, Task and Task Details related to allocated LPNs */
      insert into @ttLPNs(EntityId)
      select distinct LPNId
      from TaskDetails TD
        join Tasks T on (TD.TaskId = T.TaskId)
      where (T.WaveId          = @vWaveId    ) and
            (TD.DependencyFlags in ('N', 'M')) and
            (T.IsTaskConfirmed = 'N'/* No */) and
            (TD.Status in ('O', 'N' /* OnHold, ReadyToStart */));
    end
  else
    /* For replenish waves directed quantity would be added to location, so get the Dest Location or LPNs to evaluate dependencies */
    begin
      /* When a directed quantity is added to location then,Waves with Dependency 'S' may go to 'R' */
      insert into @ttLPNs(EntityId)
        select distinct L.LPNId
        from LPNs L
          join Locations   LOC on (L.LocationId     = LOC.LocationId  ) and
                                  (LOC.BusinessUnit = @BusinessUnit   )
          join TaskDetails RTD on (LOC.Location     = RTD.DestLocation) and -- To get the Dest Locations for which Directed Qty is added
                                  (RTD.BusinessUnit = @BusinessUnit   ) and
                                  (L.SKUId          = RTD.SKUId       )
          join TaskDetails TD  on (L.LPNId   = TD.LPNId) and
                                  (L.SKUId   = TD.SKUId) -- To eliminate unecessary picklanes
          join Tasks       T   on (TD.TaskId = T.TaskId)
        where (RTD.WaveId = @vWaveId) and
              (TD.DependencyFlags in ('S')) and
              (T.IsTaskConfirmed = 'N'/* No */) and
              (TD.Status in ('O', 'N' /* OnHold, ReadyToStart */));
    end

  /* Loop thru each LPN and recompute dependencies */
  while exists (select * from @ttLPNs where RecordId > @vLPNRecId)
    begin
      select top 1 @vLPNRecId = RecordId,
                   @vLPNId    = EntityId
      from @ttLPNs
      where (RecordId > @vLPNRecId)
      order by RecordId;

      /* Get current LPN quantity */
      select @vLPNQuantity = Quantity
      from LPNs
      where (LPNId = @vLPNId);

      /* Update dependencies of the Tasks */
      if (exists (select * from LPNDetails where LPNId = @vLPNId and Onhandstatus = 'PR'))
        exec pr_LPNs_RecomputeWaveAndTaskDependencies @vLPNId, null /* Current Qty*/, @vLPNQuantity, @vOperation;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_UpdateWaveDependencies */

Go
