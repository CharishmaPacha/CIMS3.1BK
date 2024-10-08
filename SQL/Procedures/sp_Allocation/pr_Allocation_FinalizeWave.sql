/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/14  VS      pr_Allocation_FinalizeWave: Passed EntityStatus Parameter (BK-910)
  2021/08/26  TK      pr_Allocation_FinalizeWave: Changes to log AT when allocation is completed (BK-536)
  2020/08/27  TK      pr_Allocation_FinalizeWave: Changes to auto Release tasks (HA-1211)
  2019/10/07  TK      pr_Allocation_AllocateWave: Changes to Cubing execute proc signature
                      pr_Allocation_FinalizeWave: Changes to resequence packageseqno (CID-883)
  2018/05/11  OK      pr_PickBatch_ReAllocateBatches: Enhanced to reallocate the inventory based on control var (S2G-581)
              AY      pr_Allocation_FinalizeWave: Consolidated updates that need to be done at the end of allocation (S2G-581)
  2018/04/26  TK      pr_Allocation_FinalizeWave: Changes to release tasks based upon control variable
                      pr_Allocation_CreatePickTasks: Removed code to release tasks after creation
  2018/04/12  OK      pr_Allocation_FinalizeWave: Changes to call new procedure pr_OrderHeader_ComputePickZone to update the PickZone on the orders (S2G-697)
  2018/04/17  AY      pr_Allocation_FinalizeWave: Set status of wave at end of allocation.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_FinalizeWave') is not null
  drop Procedure pr_Allocation_FinalizeWave;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_FinalizeWave: After Wave allocation is complete, do the
    necessary finalization steps i.e. RecalcCounts, revert allocation flag,
    email if there are shorts etc.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_FinalizeWave
  (@WaveId        TRecordId,
   @WaveNo        TWaveNo,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TMessage,

          @vWaveId                   TRecordId,
          @vWaveNo                   TWaveNo,
          @vWaveType                 TTypeCode,

          @vEmailWaveShortsSummary   TControlValue,
          @vAutoReleaseTasks         TControlValue;

  declare @ttOrders                  TEntityKeysTable,
          @ttTasksToRelease          TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* capture wave info */
  select @vWaveId   = WaveId,
         @vWaveNo   = WaveNo,
         @vWaveType = WaveType
  from Waves
  where (WaveId = @WaveId);

  /* Get the orders to recompute status and counts */
  insert into @ttOrders(EntityId)
    select distinct OrderId
    from OrderHeaders
    where (PickBatchId = @vWaveId);

  /* Get the control value whether to send email alerts for wave short summary or not */
  select @vEmailWaveShortsSummary = dbo.fn_Controls_GetAsString('WaveShortsSummary', 'Email', 'N' /* No */, @BusinessUnit, @UserId),
         @vAutoReleaseTasks       = dbo.fn_Controls_GetAsString('Allocation', 'AutoReleaseTasks', 'N' /* No */, @BusinessUnit, @UserId);

  /* Update the pickzone on the Orders */
  exec pr_OrderHeaders_ComputePickZone default /* Orders */, null /* OrderId */, @vWaveId, @BusinessUnit, @UserId;

  /* Resequence package seq No */
  exec pr_OrderHeaders_PackageNoResequence @vWaveId, null /* OrderId */;

  /* For Replenish waves, if nothing is allocated then update UnitsAuthorizedToShip with UnitsAssigned */
  if (@vWaveType in ('R', 'RU', 'RP'/* Replenish */))
    update OD
    set OD.UnitsAuthorizedToShip = OD.UnitsAssigned
    from OrderDetails OD
      join OrderHeaders OH on (OD.OrderId = OH.OrderId)
    where (OH.PickBatchId = @vWaveId);

  /* Email Wave Shorts report */
  if (@vEmailWaveShortsSummary = 'Y'/* Yes */)
    exec pr_Alerts_WaveShortsSummary @vWaveNo, @BusinessUnit, @UserId;

  /* Allocation is done, so turn off the allocate flags */
  update Waves set AllocateFlags = 'D'/* Done */ where WaveId = @vWaveId;

  /* If the tasks are to be auto released then release them */
  if (@vAutoReleaseTasks = 'Y' /* Yes */)
    begin
      insert into @ttTasksToRelease (EntityId)
        select TaskId
        from Tasks
        where (WaveId = @vWaveId) and
              (Status = 'O'/* OnHold */) and
              (coalesce(DependencyFlags, '') not in ('R', 'S'/* Replenish, Short */))

      /* Invoke proc to release tasks */
      exec pr_Tasks_Release @ttTasksToRelease, @BusinessUnit = @BusinessUnit, @UserId = @UserId;
    end

  /* Compute Order status and counts */
  exec pr_OrderHeaders_Recalculate @ttOrders, 'S'/* Status & Recount */, @UserId, @BusinessUnit;

  /* Update counts on Wave */
  exec pr_PickBatch_UpdateCounts @vWaveNo, 'OTL'/* Orders, Tasks, LPNs */;

  /* On reallocation, the Wave status may change, so recompute after allocation */
  exec pr_PickBatch_SetStatus @vWaveNo, '$*' /* Wavestatus recalc */, @ModifiedBy = @UserId;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'WaveAllocationCompleted', @UserId, null, @WaveId = @vWaveId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_FinalizeWave */

Go
