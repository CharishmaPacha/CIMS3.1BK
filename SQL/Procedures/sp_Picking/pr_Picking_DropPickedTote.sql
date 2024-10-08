/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/30  TD      Added pr_Picking_DropPickedTote.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_DropPickedTote') is not null
  drop Procedure pr_Picking_DropPickedTote;
Go

Create Procedure pr_Picking_DropPickedTote
  (@LPNToDrop     TLPN,
   @DropLocation  TLocation,
   @TaskId        TRecordId = null,
   @TaskDetailId  TRecordId = null,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vLocationId            TRecordId,
          @vLPNId                 TRecordId,
          @ReturnCode             TInteger,
          @vMarkTempLabelOnPicked TControlValue,
          @vTaskId                TRecordId,
          @vTaskDetailId          TRecordId,
          @vOrderId               TRecordId,
          @vSorterId              TZoneId,
          @vDestZone              TZoneId,
          @vDestLocation          TLocation,
          @vWorkId                TWorkId,
          @ttOrderDetails         TToteOrderDetails;
begin /* pr_Picking_DropPickedTote */

  /* Get LPN details here */
  select @vLPNId       = LPNId,
         @vOrderId     = OrderId,
         @vSorterId    = UDF3
  from LPNs
  where (LPN          = @LPNToDrop) and
        (BusinessUnit = @BUsinessUnit);

  /* get LocationId */
  select @vLocationId   = LocationId
  from Locations
  where (Location     = @DropLocation) and
        (BusinessUnit = @BUsinessUnit)

  /* Call procedure here to get DestLocation and Zone */
  exec pr_OrderHeaders_GetDestination @vOrderId, @vLPNId, 'PackedAtSorter' /* Operation */, 'Y' /* IsLastCarton */,
                                      @vDestZone output, @vDestLocation output, @vWorkId output;

  /* Update LPN here with DestZone */
  update LPNs
  set DestZone     = @vDestZone,
      DestLocation = @vDestLocation,
      Status       = 'K' /* Picked */
  where (LPNId = @vLPNId);

  /* call procedure here to update */
  exec @ReturnCode = pr_LPNs_SetLocation @vLPNId, @vLocationId, null /* Location */;

  /* we need to route this LPN to appropriate zone */
  --exec pr_Router_SendRouteInstruction @vLPNId, @LPNToDrop, default, null /* Destination */,
  --                                    null /* WorkId */, 'N' /* Export */,
  --                                    @BusinessUnit, @UserId;

  /* TODO On Error, return Error Code/Error Message */
  return;
end /* pr_Picking_DropPickedTote */

Go
