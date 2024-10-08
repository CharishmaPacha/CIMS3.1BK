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

if object_id('dbo.pr_Picking_GetNextAllocatedPickForTask') is not null
  drop Procedure pr_Picking_GetNextAllocatedPickForTask;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_GetNextAllocatedPickForTask: This procedure is used to find
    the next pick from the Task, when the Batch is allocated and inventory reserved
    for the tasks. The selection does consider the criteria of Zone.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_GetNextAllocatedPickForTask
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
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMessage             TDescription,

          @vTaskId              TRecordId,
          @vTaskDetailId        TRecordId,
          @vPickSequence        TPickSequence;
begin /* pr_Picking_GetNextAllocatedPickForTask */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Save the input params */
  select @vTaskId       = @TaskId,
         @vTaskDetailId = @TaskDetailId;

  /* get pickpath position from devices table */
  select @vPickSequence = PickSequence
  from Devices
  where (DeviceId = @DeviceId);

  /* We know user requested a task, so we have to find the next task detail to pick from the task.
        First, we need to find the next pick in the pick path. */
  select Top 1
     @OrderDetailId  = OrderDetailId,
     @LPNToPick      = LPN,
     @LPNIdToPick    = LPNId,
     @LPNDetailId    = LPNDetailId,
     @LocToPick      = Location,
     @UnitsToPick    = UnitsToPick,
     @PickType       = case when ((UnitsToPick = LPNQuantity) and (LPNType <> 'L' /* picklane */)) then 'L' /* LPN Pick */
                           else 'U' /*Unit Pick*/
                       end,
     @TaskId         = TaskId,
     @TaskDetailId   = TaskDetailId
  from vwTasksToPick
  where (TaskId = @vTaskId) and
        (PickZone = coalesce(@PickZone, PickZone)) and
        (PickSequence > coalesce(@vPickSequence, ''))
  order by TaskDetailStatus, PickSequence, TaskDetailId;

  /* if there are no picks found above, and if we were looking past the previous pick path position
     only, then we need to give the first one again, so that users can do
     shortpick, or they can do drop pallet. */
  if (@vPickSequence is not null) and (@TaskId is null) and (@vTaskId is not null)
    select Top 1
       @OrderDetailId  = OrderDetailId,
       @LPNToPick      = LPN,
       @LPNIdToPick    = LPNId,
       @LPNDetailId    = LPNDetailId,
       @LocToPick      = Location,
       @UnitsToPick    = UnitsToPick,
       @PickType       = case when ((UnitsToPick = LPNQuantity) and (LPNType <> 'L' /* picklane */)) then 'L' /* LPN Pick */
                           else 'U' /*Unit Pick*/
                         end,
       @TaskId         = TaskId,
       @TaskDetailId   = TaskDetailId
    from vwTasksToPick
    where (TaskId = @vTaskId) and
          (PickZone = coalesce(@PickZone, PickZone))
    order by PickSequence, TaskDetailId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_GetNextAllocatedPickForTask */

Go
