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

if object_id('dbo.pr_Picking_GetNextPickForWaveOrTask') is not null
  drop Procedure pr_Picking_GetNextPickForWaveOrTask;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_GetNextPickForWaveOrTask: This procedure will take input as Zone,
    Pickbacth and gives the task for that Zone
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_GetNextPickForWaveOrTask
  (@DeviceId        TDeviceId,
   @UserId          TUserId,
   @BusinessUnit    TBusinessUnit,
   @PickingPallet   TPallet,
   @PickZone        TTypeCode,
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

          @vDeviceId            TDeviceId,
          @vIsTaskAllocated     TFlag,
          @IsWaveAllocated      TFlag;
begin /* pr_Picking_GetNextBatchAndTaskToPick */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Clear output params */
  select @OrderDetailId  = null,
         @LPNToPick      = null,
         @LPNIdToPick    = null,
         @LPNDetailId    = null,
         @LocToPick      = null,
         @UnitsToPick    = null,
         @PickType       = null,
         @TaskDetailId   = null;

  /* Save the input params */
  set @vDeviceId = @DeviceId + '@' + @UserId;     /* Build the device id */

  /* check whether Task is Allocated or not */
  select @vIsTaskAllocated = IsTaskAllocated
  from Tasks
  where (TaskId = @TaskId);

  if (@vIsTaskAllocated = 'Y')
    exec pr_Picking_GetNextAllocatedPickForTask @vDeviceId,
                                                @UserId,
                                                @BusinessUnit,
                                                @PickingPallet,
                                                @PickZone,
                                                @PickBatchNo    output,
                                                @TaskId         output,
                                                @TaskDetailId   output,
                                                @LPNToPick      output,
                                                @LPNIdToPick    output,
                                                @LPNDetailId    output,
                                                @OrderDetailId  output,
                                                @UnitsToPick    output,
                                                @LocToPick      output,
                                                @PickType       output;


  if (@vIsTaskAllocated = 'N')
    exec pr_Picking_GetNextPsuedoPickForTask @vDeviceId,
                                             @UserId,
                                             @BusinessUnit,
                                             @PickingPallet,
                                             @PickZone,
                                             @PickBatchNo    output,
                                             @TaskId         output,
                                             @LPNToPick      output,
                                             @LPNIdToPick    output,
                                             @LPNDetailId    output,
                                             @OrderDetailId  output,
                                             @UnitsToPick    output,
                                             @LocToPick      output,
                                             @PickType       output;

  /* If there the wave does not have any tasks (like in OB), then get the next pick for the wave */
  --if (@IsWaveAllocated = 'N')
  --  exec pr_Picking_FindNextPickFromBatch   -- Returns TaskDetails To Start Picking

  -- After referring to the code written in pr_Picking_FindNextTaskToPickFromBatch above procedure is not required

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_GetNextPickForWaveOrTask */

Go
