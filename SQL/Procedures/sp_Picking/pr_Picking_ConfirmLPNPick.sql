/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/16  VS      pr_Picking_ConfirmLPNPick: Made changes to improve the performance (S2GCA-1146)
  2018/10/25  TK      pr_Picking_AllocatePallet & pr_Picking_ConfirmLPNPick: Changes to Allocation_AllocateLPN proc signature (S2GCA-390)
              RV      pr_Picking_ConfirmLPNPick: Update Putaway class with 'RC' , while picking replenish orders (FB-474)
  2015/06/17  DK      pr_Picking_ConfirmLPNPick: Migrated changes from GNC related to updating DestLocation on LPN.
                      pr_Picking_ConfirmLPNPick, pr_Picking_ConfirmUnitPick: Moved the logic to the new procedure pr_Picking_OnPicked.
  2013/12/09  TD      pr_Picking_ConfirmUnitPick: pr_Picking_ConfirmLPNPick: Changes to update PickBatchId, PickBatchNo on LPNs.
              PK      pr_Picking_ConfirmLPNPick: Fix to update Pallet on Picking LPN and Loging AuditTrail.
  2012/09/06  VM      pr_Picking_ConfirmUnitPick/pr_Picking_ConfirmLPNPick:
  2012/08/30  AY      pr_Picking_ConfirmLPNPick: Add LPN to Load if not already on one.
  2012/07/19  AY      pr_Picking_ConfirmUnitPick, pr_Picking_ConfirmLPNPick : Modified to
  2012/07/05  VM/NY   pr_Picking_ConfirmLPNPick: Do not retreive OrderDetailId, if already passed.
  2012/07/04  VM      pr_Picking_ConfirmLPNPick: Get OrderType as caller is not passing
  2012/05/24  PK      pr_Picking_ConfirmLPNPick: Added Paramter PalletId to update the Picked LPNs with the Picked pallet.
  2011/11/10  TD      pr_Picking_ConfirmLPNPick and pr_Picking_ConfirmUnitPick:
  2011/04/08  VM      pr_Picking_ConfirmUnitPick, pr_Picking_ConfirmLPNPick:
  2011/01/27  VM      pr_Picking_ConfirmLPNPick, pr_Picking_ConfirmUnitsPick:
                      pr_Picking_ConfirmLPNPick: Clear Location of Picked LPN.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ConfirmLPNPick') is not null
  drop Procedure pr_Picking_ConfirmLPNPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ConfirmLPNPick:
    Procedure marks the LPNId as Picked
    Invokes Status recalculation on Order Header
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ConfirmLPNPick
  (@OrderId         TRecordId,
   @OrderDetailId   TRecordId,
   @LPNId           TRecordId,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @PickingPalletId TRecordId  = null,
   @Operation       TOperation = null)
as
  declare @vOrderType              TTypeCode,
          @vNewOrderStatus         TStatus,
          @vOrderStatus            TStatus,
          @vPickBatchId            TRecordId,
          @vPickBatchNo            TPickBatchNo,
          @SKUId                   TRecordId,
          @vLPN                    TLPN,
          @vLPNPalletId            TRecordId,
          @vLPNOrderId             TRecordId,
          @vLPNQuantity            TQuantity,
          @vLocationId             TRecordId,
          @vLPNShipmentId          TRecordId,
          @vLPNLoadId              TRecordId,
          @vDefaultDropLocationId  TRecordId,
          @vDefaultDropLocation    TLocation,
          @vLocation               TLocation,
          @vDestLocationId         TRecordId,
          @vDestLocation           TLocation,
          @vDestZone               TZoneId,
          @vActivityType           TActivityType;

begin /* pr_Picking_ConfirmLPNPick */
  select @vActivityType = 'LPNPick';

  /* Assuming that the LPN has only one SKU - should be true when we are
     doing an LPN Pick, Ideally, we should pass in OrderDetailId as well - AY
     For an LPN default value for LoadId and ShipmentId are 0, Our condition
     might fail to update the load in below, So that we are making it null if
     the values of LoadId and ShipmentId on the LPN is 0 */
  select @vLPN           = LPN,
         @SKUId          = SKUId,
         @vLPNOrderId    = OrderId,
         @vLocationId    = LocationId,
         @vLocation      = Location,
         @vLPNPalletId   = PalletId,
         @vLPNQuantity   = Quantity,
         @vLPNShipmentId = nullif(ShipmentId, 0),
         @vLPNLoadId     = nullif(LoadId, 0)
  from vwLPNs
  where (LPNId = @LPNId);

  /* If OrderDetail is not known, identify it using OrderId and SKUId */
  if (@OrderDetailId is null)
    select @OrderDetailId = OrderDetailId
    from OrderDetails
    where (OrderId = @OrderId) and (SKUId = @SKUId);

  /* Get Order detail info */
  select @OrderDetailId   = OrderDetailId,
         @OrderId         = OrderId,
         @vDestLocationId = LocationId
  from OrderDetails
  where (OrderDetailId = @OrderDetailId);

  /* Get Order info */
  select @vOrderType   = OrderType,
         @vOrderStatus = Status
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get the PickbatchNo from PickBatchDetails for the order */
  select @vPickBatchId = PickBatchId,
         @vPickBatchNo = PickBatchNo
  from PickBatchDetails
  where (OrderDetailId = @OrderDetailId);

  /* if it is replensihment pick then we need to update the destLocation and
     DestZone on the LPN */
  if (@vOrderType in ('RU', 'RP', 'R'))
    begin
      select @vDestZone     = PutawayZone,
             @vDestLocation = Location
      from Locations
      where LocationId = @vDestLocationId;
    end

  /* First allocate the LPN against the Order, if it already isn't allocated */
  if (@vLPNOrderId is null)
    exec pr_Allocation_AllocateLPN @LPNId, @OrderId, @OrderDetailId, 0 /* TaskDetailId */, @SKUId, @vLPNQuantity,
                                   @UserId, @Operation;

  /* Update LPNs with PickBatchId, PickBatchNo here, may be we can update while allocating, but some times
    we may go with unallocation. so its better to update here only */
  if (@vPickBatchId is not null)
    update LPNs
    set PickBatchId  = @vPickBatchId,
        PickBatchNo  = @vPickBatchNo,
        DestZone     = @vDestZone,
        DestLocation = @vDestLocation,
        PutawayClass = case when (@vOrderType in ('RU', 'RP', 'R' /* Replenish Units, Cases, Replenish Orders */)) then
                         'RC' /* Replenish Cases */
                       else
                         PutawayClass
                       end
    where (LPNId = @LPNId);

  /* Here we are updating the Ref location (Picked from location) for future ref.. if the batch is picked incorrectly. */
  update LPNDetails
  set ReferenceLocation = @vLocation,
      PickedBy          = @UserId,
      PickedDate        = current_timestamp
  where (LPNId = @LPNId);

  /* On LPN Pick */
  exec pr_Picking_OnPicked @vPickBatchNo, @OrderId, @PickingPalletId, @LPNId,
                           'L'/* PickType - LPNPick */, 'K' /* LPNStatus - Picked */,
                           @vLPNQuantity, null /* taskdetailid */, 'LPNPick' /* ActivityType */,
                           @BusinessUnit, @UserId;
end /* pr_Picking_ConfirmLPNPick */

Go
