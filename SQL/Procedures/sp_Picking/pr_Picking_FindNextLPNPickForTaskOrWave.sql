/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/15  TD      Added pr_Picking_FindNextLPNPickForTaskOrWave (S2G-422)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_FindNextLPNPickForTaskOrWave') is not null
  drop Procedure pr_Picking_FindNextLPNPickForTaskOrWave;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_FindNextLPNPickForTaskOrWave: Identify the next LPN to pick
    for the user for the given criteria. If there is already a Task and there
    are more LPNs to pick, we need to be able to continue that. If not, we would
    issue a new task.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_FindNextLPNPickForTaskOrWave
  (@PickGroup         TPickGroup,
   @DestZone          TZoneId,
   @Warehouse         TWarehouse,
   @DeviceId          TDeviceId,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @WaveNo            TWaveNo      output,
   @TaskId            TRecordId    output,
   @TaskDetailId      TRecordId    output,
   @LPNIdToPick       TRecordId    output,
   @LPNToPick         TLPN         output,
   @LocationToPick    TLocation    output,
   @PickZone          TZoneId      output,
   @SKUToPick         TRecordId    output,
   @UnitsToPick       TLocation    output,
   @OrderId           TRecordId    output,
   @OrderDetailId     TRecordId    output)
as
  declare @vEnforceScanLPNTask  TControlValue,
          @vTaskId              TRecordId;
begin /* pr_Picking_FindNextLPNPickForTaskOrWave */

 /* initialize vaues here */
  select @vTaskId             = @TaskId,
         @TaskId              = null,
         @vEnforceScanLPNTask = dbo.fn_Controls_GetAsBoolean('Picking', 'EnforceScanLPNTask', 'Y' /* Yes */, @BusinessUnit, @UserId);

  /* if the user did not send any input then we try to find out the task */
  select top 1 @WaveNo         = PickBatchNo,
               @TaskId         = TaskId,
               @TaskDetailId   = TaskDetailId,
               @LPNIdToPick    = LPNId,
               @LPNToPick      = LPN,
               @LocationToPick = Location,
               @PickZone       = PickZone,
               @SKUToPick      = SKU,
               @UnitsToPick    = UnitsToPick,
               @OrderId        = OrderId,
               @OrderDetailId  = OrderDetailId
  from vwPickTasks
  where (TaskId      = coalesce(@vTaskId, TaskId)) and
        (PickBatchNo = coalesce(@WaveNo, PickBatchNo)) and
        (PickGroup   like @PickGroup + '%') and
        (OrderId     = coalesce(@OrderId, OrderId)) and
        (PickZone like coalesce(@PickZone, PickZone) + '%') and
        (coalesce(DestZone, '') = coalesce(@DestZone, DestZone, '')) and
        (((AssignedTo = @UserId) and (TaskStatus in ('I'/* Inprogress */, 'N' /* new */))) or
          ((AssignedTo is null) and (TaskStatus = 'N'/* New */))) and
        (TaskSubType = 'L' /* LPN */) and
        (Warehouse   = @Warehouse) and
        (UnitsToPick > 0) and                   --Need to consider lines which quantity needs to pick
        (charindex(TaskDetailStatus, 'CX') = 0) --No need to consider completed/canclled lines
  order by TaskStatus, TaskDetailStatus;
end /* pr_Picking_FindNextLPNPickForTaskOrWave */

Go
