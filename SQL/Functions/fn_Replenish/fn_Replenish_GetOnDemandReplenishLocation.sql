/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/16  TK      pr_Replenish_GenerateOrders: Changes to return UniqueId & InventoryClasses
                      fn_Replenish_GetOnDemandReplenishLocation, pr_Replenish_OnDemandLocationsToReplenish &
                      pr_Replenish_GenerateOndemandOrders:  Changes to return LocationId & SKUId (HA-938)
  2020/06/08  TK      pr_Replenish_GenerateOndemandOrders, pr_Replenish_GenerateOrders, pr_Replenish_OnDemandLocationsToReplenish,
                      fn_Replenish_GetOnDemandReplenishLocation: Several changes to consider inventory class (HA-871)
  2019/05/07  YJ      pr_Replenish_OnDemandLocationsToReplenish, fn_Replenish_GetOnDemandReplenishLocation: Changes to get Ownership on the Location (S2GCA-98)(Ported from Prod)
  2019/03/28  TK      fn_Replenish_GetOnDemandReplenishLocation: If caller didn't specify replenish zones then replenish to any zone where the SKU is set up (CID-230)
  2018/12/12  TK      fn_Replenish_GetOnDemandReplenishLocation: Max quantity that can be replenished should be driven by control variable (HPI-2245)
  2018/07/13  AY/PK   fn_Replenish_GetOnDemandReplenishLocation: Used ceiling for UnitsToAllocate : Migrated from Prod (S2G-727)
  2018/05/03  TK      fn_Replenish_GetOnDemandReplenishLocation: Changes to consider UnitsPerInnerpack on SKU if in case UnitsPerPackage is '0' (S2G-Support)
  2018/03/31  TK      fn_Replenish_GetOnDemandReplenishLocation: select top 1 location if multiple locations are set up for same SKU (S2G-499)
  2018/03/12  TK      pr_Replenish_GenerateOndemandOrders: Changes to create OnDemand order for case storage Locations as well
                      pr_Replenish_FindLocationsToReplenish & fn_Replenish_GetOnDemandReplenishLocation: Initial Revision (S2G-364)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Replenish_GetOnDemandReplenishLocation') is not null
  drop Function fn_Replenish_GetOnDemandReplenishLocation;
Go
/*------------------------------------------------------------------------------
  Proc fn_Replenish_GetOnDemandReplenishLocation: Returns the location that needs to be
    replenished for given SKU and the QtyToReplenish along with the ReplenishUoM
------------------------------------------------------------------------------*/
Create Function fn_Replenish_GetOnDemandReplenishLocation
  (@SKUId              TRecordId,
   @CasesToAllocate    TQuantity,
   @UnitsToAllocate    TQuantity,
   @StorageType        TStorageType,
   @InventoryClass1    TInventoryClass,
   @InventoryClass2    TInventoryClass,
   @InventoryClass3    TInventoryClass,
   @Ownership          TOwnership,
   @Warehouse          TWarehouse,
   @ZonesToReplenish   TVarchar)
returns
  /* temp table  to return data */
  @LocationsToReplenish table (LocationId          TRecordId,
                               Location            TLocation,
                               StorageType         TTypeCode,
                               SKUId               TRecordId,
                               SKU                 TSKU,
                               ReplenishUoM        TUoM,
                               QtyToReplenish      TQuantity,
                               InventoryClass1     TInventoryClass,
                               InventoryClass2     TInventoryClass,
                               InventoryClass3     TInventoryClass,
                               Ownership           TOwnership,
                               Warehouse           TWarehouse)
as
begin
  /* Declarations */
  declare @vLPNId              TRecordId,
          @vLocationId         TRecordId,
          @vLocation           TLocation,
          @vLocStorageType     TStorageType,
          @vReplenishUoM       TUoM,
          @vMaxReplenishLevel  TQuantity,
          @vSKUId              TRecordId,
          @vSKU                TSKU,
          @vOwnership          TOwnership,
          @vWarehouse          TWarehouse,
          @vUnitsPerCase       TQuantity,
          @vUnitsPerLPN        TQuantity,
          @vLPNInnerPacks      TQuantity,
          @vLPNQuantity        TQuantity,
          @vLPNAvailableQty    TQuantity,
          @vAllocableQty       TQuantity,
          @vAllocableCases     TQuantity,
          @vUnitsToAllocate    TQuantity,
          @vReplenishQty       TQuantity,
          @vMaxQtyToReplenish  TControlValue;

  /* Get Controls */
  select @vMaxQtyToReplenish = dbo.fn_Controls_GetAsString('OnDemandReplenish', 'MaxQtyToReplenish', 'L'/* LocationCapacity */, null, null);

  /* We need to select the Location, associated for the SKU.
     if there are two Locations then we need to replenish the location which has
     less qty  */
  select top 1 @vLPNId             = L.LPNId,
               @vLocationId        = LOC.LocationId,
               @vLocation          = LOC.Location,
               @vLocStorageType    = LOC.StorageType,
               @vReplenishUoM      = LOC.ReplenishUoM,
               @vMaxReplenishLevel = LOC.MaxReplenishLevel,
               @vSKUId             = S.SKUId,
               @vSKU               = S.SKU,
               @vUnitsPerCase      = case when LOC.StorageType = 'P' then
                                            coalesce(nullif(LD.UnitsPerPackage, 0), S.UnitsPerInnerpack, 0)
                                          else
                                            coalesce(S.UnitsPerInnerPack, 0)
                                     end,
               @vUnitsPerLPN       = S.UnitsPerLPN,
               @vLPNInnerPacks     = L.InnerPacks,
               @vLPNQuantity       = L.Quantity,
               @vLPNAvailableQty   = (L.Quantity - L.ReservedQty - L.DirectedQty),
               @vOwnership         = L.Ownership,
               @vWarehouse         = L.DestWarehouse
  from LPNs L
    left outer join LPNDetails LD  on (LD.LPNId     = L.LPNId)
    join SKUs                  S   on (S.SKUId      = L.SKUId)
    join Locations             LOC on (L.LocationId = LOC.LocationId)
  where (L.SKUId             = @SKUId               ) and
        (L.InventoryClass1   = @InventoryClass1     ) and
        (L.InventoryClass2   = @InventoryClass2     ) and
        (L.InventoryClass3   = @InventoryClass3     ) and
        (L.Ownership         = @Ownership           ) and
        (LOC.Warehouse       = @Warehouse           ) and
        (L.LPNType           = 'L' /* Logical */    ) and
        (LOC.LocationType    = 'K'/* PickLane */    ) and
        (LOC.StorageType     = @StorageType         ) and
        (LOC.StorageType not like '%-' /* Neg Inv */) and
        (LOC.LocationSubType = 'S'/* Static */      ) and
        (LOC.Status <> 'I' /* Inactive */           ) and
        ((@ZonesToReplenish is null) or
         (dbo.fn_IsInList(LOC.PickingZone, @ZonesToReplenish) > 0))
  order by L.Quantity desc;

  /* get the Available Quantity & Cases in the Picklane Location i.e. Logical LPN */
  select @vAllocableQty   = sum(LD.AllocableQty),
         @vAllocableCases = sum(case when (UnitsPerPackage > 0) then LD.AllocableQty/UnitsPerPackage else 0 end)
  from LPNDetails LD
  where (LD.LPNId = @vLPNId);

  /* Initialize */
  select @vUnitsPerCase   = coalesce(@vUnitsPerCase,   0),
         @vUnitsPerLPN    = coalesce(@vUnitsPerLPN,    0),
         @CasesToAllocate = coalesce(@CasesToAllocate, 0),
         @UnitsToAllocate = coalesce(@UnitsToAllocate, 0),
         @vAllocableCases = coalesce(@vAllocableCases, 0);

  /* we have to generate the ondemand replenish order if the allocable inventory in the location
     is less the units required on the wave. However, if this SKU does not have a picklane to
     replenish to, then ignore it */
  /* If input is Cases then AllocableCases should be less than CasesToAllocate
     If input is Units then AllocableUnits should be less than UnitsToAllocate */
  if (@vLocationId is not null) and
     ((@CasesToAllocate = 0) or (@vAllocableCases < @CasesToAllocate)) and
     ((@UnitsToAllocate = 0) or (@vAllocableQty < @UnitsToAllocate))
    begin
      /* Evaluate units to allocate */
      select @vUnitsToAllocate = case when (@CasesToAllocate > 0) then @CasesToAllocate * @vUnitsPerCase else @UnitsToAllocate end;

      /* compute replenish quantity based upon replenish levels and replenish UoM.
         Even if we need few units, currently we replenish upto the MaxReplenishLevel.
         If it is desired to replenish only to demand qty, we could set the MaxReplenishLevel to 1 which
         would work fine for locations that are not to be replenished via Min/Max either.
         We may enhance this later for other options to ReplenishQty.

         NOTE: ReplenishQty is in terms of ReplenishUoM not eaches */
      select @vReplenishQty = case
                                when (@vReplenishUoM = 'EA'/* Eaches */) and (@vMaxQtyToReplenish = 'L'/* Loc. Capacity */) then
                                  dbo.fn_MaxInt((@vMaxReplenishLevel - @vLPNQuantity), @vUnitsToAllocate)
                                when (@vReplenishUoM = 'EA'/* Eaches */) and (@vMaxQtyToReplenish = 'D'/* OnDemand Qty */)then
                                  @vUnitsToAllocate
                                /* We can only determine how many cases to replenish if we know
                                   the UnitsPerInnerPack */
                                when (@vReplenishUoM = 'CS'/* Cases */) and (@vMaxQtyToReplenish = 'L'/* Loc. Capacity */) and
                                     (@vUnitsPerCase >= 1) then
                                  dbo.fn_MaxInt((@vMaxReplenishLevel - @vLPNInnerPacks), ceiling(@vUnitsToAllocate * 1.0/@vUnitsPerCase))
                                when (@vReplenishUoM = 'CS'/* Cases */) and (@vMaxQtyToReplenish = 'D'/* OnDemand Qty */) and
                                     (@vUnitsPerCase >= 1) then
                                  ceiling(@vUnitsToAllocate * 1.0/@vUnitsPerCase)
                                /* if Replenish levels are in LPNs, then estimate how many LPNs worth
                                   are in the location and attempt to fill up only */
                                 when (@vReplenishUoM = 'LPN'/* LPN */) and (@vUnitsPerLPN >= 1) then
                                   dbo.fn_MaxInt((@vMaxReplenishLevel - floor(@vLPNQuantity/@vUnitsPerLPN)), ceiling(@vUnitsToAllocate * 1.0/@vUnitsPerLPN))
                               end


      /* if the replenish qty is 0, which will be so only for Replenish UoM of CS/LPN then we couldn't determine
         how many cases/LPNs to replenish because of missing SKU Standards, therefore, change the ReplenishUoM
         to be eaches */
      if (coalesce(@vReplenishQty, 0) <= 0)
        begin
          select @vReplenishQty = @vUnitsToAllocate - @vLPNAvailableQty,
                 @vReplenishUoM = 'EA';
        end

      /* insert the location that needs to be replenished along with the ReplenishQty and Uom */
      if (@vReplenishQty > 0)
        insert into @LocationsToReplenish(LocationId, Location, StorageType, SKUId, SKU, ReplenishUoM, QtyToReplenish, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse)
          select @vLocationId, @vLocation, @vLocStorageType, @vSKUId, @vSKU, @vReplenishUoM, @vReplenishQty, @InventoryClass1, @InventoryClass2, @InventoryClass3, @vOwnership, @vWarehouse;
    end

  return;
end /* fn_Replenish_GetOnDemandReplenishLocation */

Go
