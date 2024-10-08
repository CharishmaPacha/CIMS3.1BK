/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/14  VS      pr_PickBatch_SetStatus, pr_Wave_ReleaseToWSS: Passed EntityStatus Parameter (BK-910)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_ReleaseToWSS') is not null
  drop Procedure pr_Wave_ReleaseToWSS;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_ReleaseToWSS:
    This procedure insert the wave sorter details to pick the inventory to the WSS if the all the validations
    are passed.
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_ReleaseToWSS
  (@WaveId           TRecordId,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,

          @vConfirmWCSPicks         TControlValue;

  declare @ttWavesToConfirm         TEntityKeysTable,
          @ttTaskPicksInfo          TTaskDetailsInfoTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null;

  select @vConfirmWCSPicks = dbo.fn_Controls_GetAsString('WaveReleaseForPicking', 'ConfirmWCSPicks', 'D' /* Defer */, @BusinessUnit, @UserId);

  /* Insert Wave Details into Sorter table */
  exec pr_Sorter_InsertWaveDetails @WaveId, null /* SorterName */, @BusinessUnit, @UserId;

  /* update WCS status */
  update Waves
  set WCSStatus = 'Released To WSS'
  where (WaveId = @WaveId);

  /* Mark corresponding tasks as completed */
  if (@vConfirmWCSPicks = 'O'/* OnRelease */)
    begin
      /* Get all the picks to be confirmed */
      insert into @ttTaskPicksInfo(PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, FromLPNId, FromLPNDetailId,
                                   FromLocationId, TempLabelId, TempLabelDtlId, QtyPicked)
        select TD.PickBatchNo, TD.TaskDetailId, TD.OrderId, TD.OrderDetailId, TD.SKUId, TD.LPNId, TD.LPNDetailId,
               TD.LocationId, TD.TempLabelId, TD.TempLabelDetailId, TD.Quantity
        from TaskDetails TD
        where (TD.Status not in ('C', 'X'/* Completed, Canceled */)) and
              (TD.WaveId = @WaveId);

      /* Invoke procedure to confirm picks */
      exec pr_Picking_ConfirmPicks @ttTaskPicksInfo, 'ConfirmTaskPick', @BusinessUnit, @UserId, default/* Debug */;
    end
  else
  if (@vConfirmWCSPicks = 'D'/* Defer */)
    begin
      insert into @ttWavesToConfirm(EntityId)
        select @WaveId;

      /* invoke RequestRecalcCounts to defer confirm picks */
      exec pr_Entities_RequestRecalcCounts 'Wave', null, null/* WaveNo */, 'CP'/* RecalcOption - Confirm Picks */,
                                           @@ProcId, 'ConfirmWCSPicks'/* Operation */, @BusinessUnit, null /* EntityStatus */, @ttWavesToConfirm;
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end /* pr_Wave_ReleaseToWSS */

Go
