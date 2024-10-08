/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/21  TK      pr_Picking_GetNextWaveAndTaskToPick: Initial Revision
                      pr_Picking_GetNextPickForWaveOrTask: Initial Revision
                      pr_Picking_GetNextAllocatedPickForTask: Initial Revision
                      pr_Picking_GetNextPsuedoPickForTask: Initial Revision (CIMS-895)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_GetNextPsuedoPickForTask') is not null
  drop Procedure pr_Picking_GetNextPsuedoPickForTask;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_GetNextPsuedoPickForTask: This procedure is used to find
    the next pick from the Task, when the Batch is allocated but the task are only
    created for picking and no inventory is reserved for the tasks. The selection
    does consider the criteria of Zone.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_GetNextPsuedoPickForTask
  (@DeviceId        TDeviceId,
   @UserId          TUserId,
   @BusinessUnit    TBusinessUnit,
   @PickingPallet   TPallet,
   @PickZone        TLookUpCode,
   @PickBatchNo     TPickBatchNo        output,
   @TaskId          TRecordId           output,
   @TaskDetailId    TRecordId           output,
   @LPNToPick       TLPN                output,
   @LPNIdToPick     TRecordId           output,
   @LPNDetailId     TRecordId           output,
   @OrderDetailId   TRecordId           output,
   @UnitsToPick     TInteger            output,
   @LocToPick       TLocation           output,
   @PickType        TFlag               output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @vTaskId            TRecordId,
          @vTaskDetailId      TRecordId,
          @vPickSequence      TPickSequence;
begin /* pr_Picking_GetNextPsuedoPickForTask */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Save the input params */
  select @vTaskId       = @TaskId,
         @vTaskDetailId = @TaskDetailId;

  /* get pickpath position from devices table */
  select @vPickSequence = PickSequence
  from Devices
  where (DeviceId = @DeviceId);

  select Top 1
    @OrderDetailId  = PT.OrderDetailId,
    @LPNToPick      = L.LPN,
    @LPNIdToPick    = LD.LPNId,
    @LPNDetailId    = LD.LPNDetailId,
    @LocToPick      = PT.Location,
    @UnitsToPick    = dbo.fn_MinInt(PT.UnitsToPick, LD.Quantity),
    @PickType       = case when ((PT.UnitsToPick = L.Quantity) and (L.LPNType <> 'L' /* picklane */)) then 'L' /* LPN Pick */
                        else 'U' /*Unit Pick*/
                      end,
    @TaskId         = PT.TaskId,
    @TaskDetailId   = PT.TaskDetailId
  from vwTasksToPick  PT
    left outer join LPNDetails LD  on (LD.SKUId       = PT.SKUId    )
    left outer join LPNs       L   on (LD.LPNId       = L.LPNId     )
    left outer join LPNs       TL  on (PT.TempLabelId = TL.LPNId    )
  where (PT.TaskId      = @vTaskId) and
        (PT.LocPickZone = @PickZone) and
        (PickSequence > coalesce(@vPickSequence, '')) and
         (LD.OnHandStatus = 'A' /* Available */) and
        (LD.Quantity > 0)
  order by PT.TaskDetailStatus, PT.PickSequence, TL.AlternateLPN, PT.TaskDetailId;

  /* if there are no picks found, then we need to give the first one again, so that users can do
     shortpick, or they can do drop pallet. */
  if (@vPickSequence is not null) and (@TaskId is null) and (@vTaskId is not null)
    select Top 1
      @OrderDetailId  = PT.OrderDetailId,
      @LPNToPick      = L.LPN,
      @LPNIdToPick    = LD.LPNId,
      @LPNDetailId    = LD.LPNDetailId,
      @LocToPick      = LOC.Location,
      @UnitsToPick    = dbo.fn_MinInt(PT.UnitsToPick, LD.Quantity),
      @PickType       = case when ((PT.UnitsToPick = L.Quantity) and (L.LPNType <> 'L' /* picklane */)) then 'L' /* LPN Pick */
                          else 'U' /*Unit Pick*/
                        end,
      @TaskId         = PT.TaskId,
      @TaskDetailId   = PT.TaskDetailId
    from vwTasksToPick  PT
      left outer join LPNDetails LD  on (LD.SKUId       = PT.SKUId    )
      left outer join LPNs       L   on (LD.LPNId       = L.LPNId     )
      left outer join LPNs       TL  on (PT.TempLabelId = TL.LPNId    )
      left outer join Locations  LOC on (LOC.LocationId = L.LocationId)
    where (PT.TaskId       = @vTaskId) and
          (LOC.PickingZone = @PickZone) and
          (LD.OnHandStatus = 'A' /* Available */) and
          (LD.Quantity > 0)
    order by PT.TaskDetailStatus, PT.PickSequence, TL.AlternateLPN, PT.TaskDetailId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_GetNextPsuedoPickForTask */

Go
