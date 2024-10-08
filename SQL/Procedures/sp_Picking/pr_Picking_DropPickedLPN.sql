/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/02/27  DK      pr_Picking_DropPickedLPN: Modified to update location on all the LPNs related to batch picked by user in that cycle.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_DropPickedLPN') is not null
  drop Procedure pr_Picking_DropPickedLPN;
Go

Create Procedure pr_Picking_DropPickedLPN
  (@LPNToDrop     TLPN,
   @DropLocation  TLocation,
   @TaskId        TRecordId = null,
   @TaskDetailId  TRecordId = null,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vRecordId              TRecordId,
          @vLocationId            TRecordId,
          @vLPNId                 TRecordId,
          @ReturnCode             TInteger,
          @vMarkTempLabelOnPicked TControlValue,
          @vTaskId                TRecordId,
          @vTaskDetailId          TRecordId,
          @vPickBatchId           TRecordId,
          @vOrderId               TRecordId,
          @vSorterId              TZoneId,
          @vDestZone              TZoneId,
          @vDestLocation          TLocation,
          @vWorkId                TWorkId,
          @ttOrderDetails         TToteOrderDetails;

 declare  @ttLPNs                 TEntityKeysTable;

begin /* pr_Picking_DropPickedLPN */
  /* TODO Locate LPN to the Drop Location */
  /* TODO Reset Counts of Previous Location of LPN and Newly updated Location */
  /* TODO Reset Counts of PickTicket - Staged Count etc.,. and PickTicket Status */

   /* Temp table to hold all the LPNs to be updated */
  declare @ttPickedLPNs TEntityKeysTable;

  /* select control value here */
  select @vMarkTempLabelOnPicked = dbo.fn_Controls_GetAsString('Picking', 'MarkTempLabelOnDrop',  'Y' /* No */  , @BusinessUnit, @UserId);

  /* Get LPN details here */
  select @vLPNId       = LPNId,
         @vOrderId     = OrderId,
         @vPickBatchId = PickBatchId
  from LPNs
  where (LPN          = @LPNToDrop) and
        (BusinessUnit = @BUsinessUnit);

  /* get LocationId */
  select @vLocationId   = LocationId
  from Locations
  where (Location     = @DropLocation) and
        (BusinessUnit = @BUsinessUnit);

  /* Get all the LPNs of picked status related to batch which are Picked by the user  */
  insert into @ttLPNs(EntityId)
    select LPNId
    from LPNs
    where (PickBatchId = @vPickBatchId) and
          (Status      = 'K' /* Picked */) and
          (Location    = null) and
          (ModifiedBy  = coalesce(@UserId, System_User))

  select @vRecordId = 0;

  while exists (select * from @ttLPNs where RecordId > @vRecordId)
    begin
      select top 1
        @vRecordId = RecordId,
        @vLPNId    = EntityId
      from @ttLPNs
      where (RecordId > @vRecordId)
      order by RecordId;

      /* call procedure here to update */
      exec @ReturnCode = pr_LPNs_SetLocation @vLPNId, @vLocationId, null /* Location */;
    end

  if (coalesce(@ReturnCode, 0) = 0) and (@vMarkTempLabelOnPicked = 'Y' /* Yes */) and (@TaskId is not null)
    begin
      /* call procedure here to update templables as marked */
      exec pr_Tasks_MarkTempLabelAsPicked @TaskId, @TaskDetailId, 'Picking', 'LPN', 'K', 'R', null, @BusinessUnit, @UserId;
    end

  /* TODO On Error, return Error Code/Error Message */
  return;
end /* pr_Picking_DropPickedLPN */

Go
