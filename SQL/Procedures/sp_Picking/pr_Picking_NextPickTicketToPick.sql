/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_NextPickTicketToPick') is not null
  drop Procedure pr_Picking_NextPickTicketToPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_NextPickTicketToPick:

  This procedure identifies the next PT to pick for the user requesting it by
  following the below criteria:

  It is currently for the Replenish Order Type.

   a. When the user does not enter any PT, then it will returns the Order of type 'Replenish'
      Which has the heighst Priority.

     Specs to find Next PT to Pick.
      -- Matching the BusinessUnit of the give UserId
     -- Matching the given OrderType - If null, find the Customer Orders only
     -- Matchiing the given WarehouseId - If null, Get Warehouse from the given Device, use the same
     -- Matching the PickZone given - If null, across all PickZones
     -- Order Status should be in Initial or To Pick
     -- PickBatchNo is null or 0

------------------------------------------------------------------------------*/
Create Procedure pr_Picking_NextPickTicketToPick
  (@DeviceId      TDeviceId,
   @UserId        TUserId,
   @PickZone      TZoneId  = null,
   @OrderType     TTypeCode,
   @WarehouseId   TWarehouseId,
   @OrderId       TRecordId   output,
   @PickTicket    TPickTicket output)
as
  declare @BusinessUnit  TBusinessUnit,
          @vWarehouseId  TWarehouseId;
begin /* pr_Picking_NextPickTicketToPick */

  /* TODO
     Identify the Last Operation on the Device for this User
     If the User performed Picking for a Replenish Order lastly, then send the same

     This is not getting recorded as of now, so this will be done later
     */
  select @OrderType  = nullif(@OrderType, '');

  /* Get the  BusinessUnit from the Users */
  select @BusinessUnit = BusinessUnit
  from Users
  where (UserName = @UserId);

  /* Get WarehouseID here based on the Device Id */
  select @vWarehouseId = Warehouse
  from Devices
  where (DeviceId = @DeviceId);

  /* Find if there are any PickTicket in Picking status for the User */
  select top 1 @PickTicket = OD.PickTicket
  from OrderHeaders OH join vwOrderDetails OD on OH.OrderId  = OD.OrderId
  where ((OH.Status in ('C' /* Picking*/, 'I' /* Inprogress */ )) and
         (OH.OrderType = coalesce(@OrderType, 'C'/* Customer or Sales Orders */)) and
         (coalesce(OD.OD_UDF2, OH.Warehouse) = coalesce(@WarehouseId, @vWarehouseId)) and
         (OH.NumLines > 0) and
         (coalesce(OH.PickBatchId, 0) = 0) and
         (OD.BusinessUnit = @BusinessUnit) and
         (OH.ModifiedBy = @UserId))
  order by OH.Priority asc, OH.CreatedDate asc;

if (@PickTicket is null)
  select top 1 @PickTicket = OD.PickTicket
  from OrderHeaders OH join vwOrderDetails OD on OH.OrderId  = OD.OrderId
  where ((OH.Status in ('I' /* Inprogress */, 'A' /* ToPick */)) and
         (OH.OrderType = coalesce(@OrderType, 'C'/* Customer or Sales Orders */)) and
         (coalesce(OD.OD_UDF2, OH.Warehouse) = coalesce(@WarehouseId, @vWarehouseId)) and
         (OH.NumLines > 0) and
         --(OD.UnitsTOAllocate > 0) and
         --(OH.PickZone  = coalesce(@PickZone, OH.PickZone)) and
         (coalesce(OH.PickBatchId, 0) = 0) and
         (OD.BusinessUnit = @BusinessUnit) and
         (OH.ModifiedBy is null))
  order by OH.Priority asc, OH.CreatedDate asc;

end /* pr_Picking_NextPickTicketToPick */

Go
