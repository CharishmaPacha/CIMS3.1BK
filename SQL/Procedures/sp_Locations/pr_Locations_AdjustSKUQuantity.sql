/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/15  VS      pr_Locations_AdjustSKUQuantity: Pass the ToLPNDetailId to merge the existing LPNDetail lines while drop the Pallet (BK-829)
  2020/08/20  VS      pr_Locations_AdjustSKUQuantity: Made changes to Improve the performance (S2GCA-1204)
  2020/07/29  TK      pr_Locations_AddSKUToPicklane & pr_Locations_AdjustSKUQuantity: Changes to consider InventoryClasses (HA-1246)
  2018/09/14  TK      pr_Locations_AddSKUToPicklane & pr_Locations_AdjustSKUQuantity:
  2018/08/16  PK      pr_Locations_AdjustSKUQuantity: Made changes by adding output parameter LPNDetailId (S2G-1080)
  2016/12/08  VM      pr_Locations_AdjustSKUQuantity: Added (HPI-1113)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_AdjustSKUQuantity') is not null
  drop Procedure pr_Locations_AdjustSKUQuantity;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_AdjustSKUQuantity:
    This is procedure is used when inventory is *ADDING UP* into a picklane by using functions like
      Putaway, Transfers, or CC adjust up etc.

    This procedure identifies if there are any pending replenishments on a picklane,
      it tries to relieve replenish lines first rather than adding new line or
      adding qty to an existing available line first.

    If replenish lines do not exist, it just calls pr_Locations_AddSKUToPicklane to add inventory as earlier

    Operation details:
      TransferInventory -> call pr_Locations_SplitReplenishQuantity / pr_Locations_AddSKUToPicklane
      CompleteSKUCC     -> call pr_Locations_SplitReplenishQuantity / pr_RFC_AdjustLocation
      ...in future, operations can be expanded later like PALPNContentsToPicklane etc.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_AdjustSKUQuantity
  (@Operation         TOperation = 'TransferInventory',
   @LocationId        TRecordId,
   @SKUId             TRecordId,
   @InnerPacks        TInnerPacks,
   @Quantity          TQuantity,
   @Lot               TLot       = null,
   @Ownership         TOwnership = null,
   @InventoryClass1   TInventoryClass = '',
   @InventoryClass2   TInventoryClass = '',
   @InventoryClass3   TInventoryClass = '',
   @ReplenishOrderId  TRecordId,
   @ReasonCode        TReasonCode,
   @Export            TFlag = 'Y' /* Yes */,
   @ToLPNId           TRecordId = null output,
   @ToLPNDetailId     TRecordId = null output,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId)
as
  declare @vDirectedQty        TQuantity,
          @vReservedQty        TQuantity,
          @vLocationQty        TQuantity,
          @vDirectedIPs        TInnerPacks,
          @vReservedIPs        TInnerPacks,
          @vLocationIPs        TInnerPacks,

          @vQuantityToUpdate   TQuantity,
          @vInnerPacksToUpdate TInnerPacks,
          @vSKUOwner           TOwnership;
begin /* pr_Locations_AdjustSKUQuantity */

  /* Get SKU info */
  select @vSKUOwner = Ownership
  from SKUs
  where (SKUId = @SKUId);

  /* Get available and Directed (D & DR), Reserved & Location Quantities & InnerPacks
     of the LPN which matching the Ownership and Lot if provided */
  select /* Quantities */
         @vDirectedQty = sum(case when LD.onhandstatus in ('D' /* Directed */,  'DR' /* DirectedReserved */) then LD.Quantity   else 0 end),
         @vReservedQty = sum(case when LD.onhandstatus in ('R' /* Reserved */                              ) then LD.Quantity   else 0 end),
         @vLocationQty = sum(case when LD.onhandstatus in ('A' /* Available */, 'R'  /* Reserved */        ) then LD.Quantity   else 0 end),
         /* InnerPacks */
         @vDirectedIPs = sum(case when LD.onhandstatus in ('D' /* Directed */,  'DR' /* DirectedReserved */) then LD.InnerPacks else 0 end),
         @vReservedIPs = sum(case when LD.onhandstatus in ('R' /* Reserved */                              ) then LD.InnerPacks else 0 end),
         @vLocationIPs = sum(case when LD.onhandstatus in ('A' /* Available */, 'R'  /* Reserved */        ) then LD.InnerPacks else 0 end)
  from LPNDetails LD
    join LPNs L on  L.LPNId = LD.LPNId
  where (L.LocationId = @LocationId) and
        (LD.SKUId     = @SKUId) and
        (L.Ownership  = coalesce(@Ownership, @vSKUOwner)) and
        (coalesce(L.Lot, '') = coalesce(@Lot, ''));

  select @vDirectedQty = coalesce(@vDirectedQty, 0),
         @vReservedQty = coalesce(@vReservedQty, 0),
         @vLocationQty = coalesce(@vLocationQty, 0),
         @vDirectedIPs = coalesce(@vDirectedIPs, 0),
         @vReservedIPs = coalesce(@vReservedIPs, 0),
         @vLocationIPs = coalesce(@vLocationIPs, 0);

  /* Any adjustment other than CC should be UP adjustment and hence relieve replenishments, if there are */
  if (@Operation in ('TransferInventory')) and (@vDirectedQty > 0)
    begin
      exec pr_Locations_SplitReplenishQuantity @SKUId, @LocationId, @InnerPacks, @Quantity, @ReplenishOrderId,
                                               @BusinessUnit, @UserId;

      /* Get the LPNDetailId to generate the correct exports for Warehouse transfers */
      select top 1 @ToLPNDetailId = LPNDetailId
      from LPNDetails LD
        join LPNs L on  L.LPNId = LD.LPNId
      where (L.LocationId = @LocationId) and
            (LD.SKUId     = @SKUId) and
            (L.Quantity   > 0) and
            (LD.OnhandStatus in ('A', 'D' /* Available, Directed */))
      order by LD.OnhandStatus;

    end
  else
  /* If it is from CC adjustment, make sure Qty/IPs are more than Reserved Qty/IPs. Relieve replenishments, if there are */
  if (@Operation in ('CompleteSKUCC')) and (@vDirectedQty > 0) and ((@Quantity > @vReservedQty) or (@InnerPacks > @vReservedIPs))
    begin
      select @vQuantityToUpdate   = (@Quantity   - @vReservedQty),
             @vInnerPacksToUpdate = (@InnerPacks - @vReservedIPs)

      exec pr_Locations_SplitReplenishQuantity @SKUId, @LocationId, @vInnerPacksToUpdate, @vQuantityToUpdate, @ReplenishOrderId,
                                               @BusinessUnit, @UserId;
    end
  else
  /* If it is from CC adjustment which is lesser than Reserved Qty/IPs, have it normal adjustment */
  if (@Operation in ('CompleteSKUCC'))
    /* pr_RFC_AdjustLocation takes care of many things when CC qty adjustment down done below to the location qty */
    exec pr_RFC_AdjustLocation @LocationId,
                               null /* @vLocation - not required to pass */,
                               @SKUId,
                               null /* @vSKU - not required to pass */,
                               @InnerPacks,
                               @Quantity,
                               @ReasonCode,
                               @BusinessUnit, @UserId;
  else
    /* Other than CC adjustment and no replenishment requirement on Location, just make normal adjustment */
    exec pr_Locations_AddSKUToPicklane @SKUId,
                                       @LocationId,
                                       @InnerPacks,
                                       @Quantity,
                                       @Lot,
                                       @Ownership,
                                       @InventoryClass1,
                                       @InventoryClass2,
                                       @InventoryClass3,
                                       '+' /* UpdateOption */,
                                       @Export,
                                       @UserId,
                                       @ReasonCode,
                                       @ToLPNId output,
                                       @ToLPNDetailId output;
end /* pr_Locations_AdjustSKUQuantity */

Go
