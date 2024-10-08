/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/05/20  TD      Added pr_Picking_BuildPickResponseForLPN, pr_Picking_FindNextTaskForLPN.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_FindNextTaskForLPN') is not null
  drop Procedure pr_Picking_FindNextTaskForLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_FindNextTaskForLPN:
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_FindNextTaskForLPN
  (@OrderId           TRecordId,
   @PickZone          TZoneId,
   @OrderDetailId     TRecordId output,
   @LPNIdToPick       TRecordId output,
   @LPNToPick         TLPN      output,
   @LPNDetailIdToPick TRecordId output,
   @TaskSKUId         TRecordId output,
   @LocationToPick    TLocation output,
   @TaskId            TRecordId output,
   @TaskDetailId      TRecordId output,
   @TaskUnitsToPick   TQuantity output)
as
  declare @ToLPN                      TLPN,
          @vLPNType                   TTypeCode,
          @PickPalletId               TRecordId,
          @PalletToPickFrom           TPallet;

  declare @TaskDetailsToPick table
           (TaskId         TRecordId,
            TaskDetailId   TRecordId,
            OrderId        TRecordId,
            OrderDetailId  TRecordId,
            UnitsToPick    TQuantity,
            LPN            TLPN,
            Location       TLocation,
            PickPath       TLocation,
            PickZone       TZoneId,
            RecordId       TRecordId  identity(1,1))

begin /* pr_Picking_FindNextTaskForLPN */

  /* Insert available picks into temp table  */
 /* insert into @TaskDetailsToPick(TaskId, TaskDetailId, OrderId, OrderDetailId,
                                 UnitsToPick, LPN, Location, PickPath, PickZone)
    select TaskId, TaskDetailId, OrderId, OrderDetailId,
           UnitsToPick, LPN, Location, PickPath, PickZone
    from vwPickTasks
    where (OrderId = @OrderId) and
          coalesce(PickZone, '') = coalesce(@PickZone, PickZone, '') and
          (UnitsToPick > 0) and
          (TaskDetailStatus not in ('C', 'X' /* Completed, Cancelled */))
   -- order by PickPath;  */

  /* select top 1 pick details here */
  select top 1 @OrderDetailId     = OrderDetailId,
               @LPNIdToPick       = LPNId,
               @LPNToPick         = LPN,
               @LPNDetailIdToPick = LPNDetailId,
               @LocationToPick    = Location,
               @TaskId            = TaskId,
               @TaskDetailId      = TaskDetailId,
               @TaskSKUId         = SKUId,
               @TaskUnitsToPick   = UnitsToPick
  from vwPickTasks
  where (OrderId = @OrderId) and
        (coalesce(PickZone, '') = coalesce(@PickZone, PickZone, '')) and
        (UnitsToPick > 0) and
        (TaskDetailStatus not in ('C', 'X' /* Completed, Cancelled */))
  order by PickPath;

end /* pr_Picking_FindNextTaskForLPN */

Go
