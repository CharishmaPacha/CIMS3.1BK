/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/04/05  TK      pr_Picking_FindAllocableLPNs: Changes to return NumLines in the LPN (FB-648)
  2015/10/08  VM      pr_Picking_FindAllocableLPNs: Include PickPath and few UDFs (UDFs to use if any values required in quick time)
  2015/10/07  AY      pr_Picking_FindAllocableLPNs: Added additional condition of LPNPickingClass
  2015/09/24  AY      pr_Picking_FindAllocableLPNs: Return AllocableInnerPacks (FB-409)
  2014/04/06  TD      Added new procedure pr_Picking_FindAllocableLPNs.
  2014/01/21  TD      pr_Picking_FindAllocableLPN: Ignore Lost Location while allocating inventory.
  2013/11/15  PK      pr_Picking_FindAllocableLPN: Added Warehouse to filter data based on Warehouse,
                      pr_Picking_FindLPN: changed the callers of pr_Picking_FindAllocableLPN to pass in Warehouse.
  2013/11/08  AY      pr_Picking_FindAllocableLPN: Restrict to Bulk/Reserve/Picklanes when no LocationType is specified.
  2013/10/04  AY      pr_Picking_FindAllocableLPN: Allocate in multiples of InnerPacks only.
  2011/09/26  PK      pr_Picking_FindLPN/pr_Picking_FindAllocableLPN: Modified to find LPN from both Bulk & Reserve.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_FindAllocableLPN') is not null
  drop Procedure pr_Picking_FindAllocableLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_FindAllocableLPN:

  This procedure searches thru the temp table of Allocable LPNs and find THE
  LPN to allocate based upon the input criteria.

  - @SearchType
    'F' - Default - Search for Allocable Full LPNs
    'P' - Search for Allocable Inventory in Picklanes or LPNs to allocate partially
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_FindAllocableLPN
  (@SKU              TSKU,
   @SearchType       TFlag         = 'F',        /* Refer to Notes above, for valid values and their usage */
   @UnitsNeeded      TInteger,
   @OrderId          TRecordId     = null,
   @PickZone         TLookUpCode   = null,       /* TZoneId */
   @LocationType     TLocationType = null,
   @Warehouse        TWarehouse    = null,
   @AllocationRuleId TRecordId     = null,
   @LPNToAssign      TLPN         output,
   @LPNIdToAssign    TRecordId    output,
   @LocToAssign      TLocation    output,
   @SKUToAssign      TSKU         output,
   @UnitsToAssign    TInteger     output)
as
  declare  @curValidPickTicket        TPickTicket,
           @curOrderId                TRecordId,
           @curOrderDetailId          TRecordId,
           @curSKU                    TSKU,
           @curUnitsAuthorizedToShip  TInteger,
           @curUnitsAssigned          TInteger,
           @curUnitsToAssign          TInteger,
           @vUnitsPerInnerPack        TInteger,
           @vOrderType                TTypeCode,
           @OrderByField              TDescription,
           @QtyCondition              TDescription,
           @StorageType               TTypeCode;
begin /* pr_Picking_FindAllocableLPN */
  select @LPNToAssign   = null,
         @LPNIdToAssign = null,
         @SKUToAssign   = null,
         @UnitsToAssign = null,
         @LocationType  = coalesce(@LocationType, 'BRK' /* Bulk/Reserve/Picklane */);

  /* Get OrderType here */
  select @vOrderType = OrderType
  from OrderHeaders
  where (OrderId = @OrderId)

  /* if Order type is Replenish then we will find LPNs from bulk/Reserver Locations */
  if (@vOrderType in ('R', 'RP', 'RU' /* Replenish, Replenish Cases, Replenish Units */))
    begin
          select Top 1
             @LPNToAssign   = LPN,
             @LPNIdToAssign = LPNId,
             @LocToAssign   = Location,
             @SKUToAssign   = SKU,
             @UnitsToAssign = Case
                                when ((LPN is not null) and (AllocableQuantity <= @UnitsNeeded)) then
                                  AllocableQuantity
                                when ((LPN is not null) and (AllocableQuantity > @UnitsNeeded)) then
                                  @UnitsNeeded
                                when ((LPN is null) and (AllocableQuantity > @UnitsNeeded)) then
                                  @UnitsNeeded
                                when ((LPN is null) and (AllocableQuantity <= @UnitsNeeded)) then
                                  AllocableQuantity
                                else
                                  @UnitsNeeded
                              end
          from vwLPNOnhandInventory
          where (SKU          = @SKU)     and
                (coalesce(PickingZone, '') = coalesce(@PickZone, coalesce(PickingZone, ''))) and
                (LocationType   in  ('B', 'R') /* Bulk, Reserve */) and
                (Location is not null) and (rtrim(Location) <> '') and
                (TotalQuantity <= @UnitsNeeded) and
                (coalesce(LPN, '') <> '')  and
                (Location <> 'LOST')
          order by ExpiryDate, Location;
      end
    else
      begin
        /* if the caller passes the Allocation ruleid then we need use the info in Allocation rules
           and find an LPN that matches the criteria */
        if (coalesce(@AllocationRuleId, 0) > 0)
          begin
            select @SearchType   = SearchType,
                   @PickZone     = PickingZone,
                   @StorageType  = StorageType,
                   @OrderByField = OrderByField,
                   @QtyCondition = QuantityCondition
            from AllocationRules
            where RecordId = @AllocationRuleId;
          end

        /*
        With the temp table, search for the LPNtoAssign based upon the given
        criteria and return the first LPN that matches the criteria.

        ToDo: Ensure that the LPN is not suggested already for another device.
        */
        select Top 1
          @LPNToAssign        = LPN,
          @LPNIdToAssign      = LPNId,
          @LocToAssign        = Location,
          @SKUToAssign        = SKU,
          @vUnitsPerInnerPack = UnitsPerInnerPack,
          @UnitsToAssign      = Case
                                  when (@SearchType = 'F' /* Full LPN Search */) then
                                    AllocableQuantity
                                  when (@SearchType = 'P' /* Partially Allocable LPN Search */) then
                                    dbo.fn_MinInt(AllocableQuantity, @UnitsNeeded)
                                  else
                                    @UnitsNeeded
                                end
        from vwLPNOnhandInventory
        where (SKU          = @SKU) and
              (PickingZone  = coalesce(@PickZone, PickingZone)) and
              (charindex(LocationType, (coalesce(@LocationType, LocationType))) > 0) and
              (charindex(StorageType,  (coalesce(@StorageType, StorageType)))   > 0) and
              (Location is not null) and (rtrim(Location) <> '') and
              (Location <> 'LOST')                               and
              (
               ((AllocableQuantity >= UnitsPerInnerPack         ) and /* Ensure there is at least one pack to pick */
                ((LocationType = 'K') and (StorageType = 'P' /* Packages */)))
                or
                (LocationType <> 'K')
              ) and
              (Warehouse          = @Warehouse                 ) and
              ( /* for Fully Allocable LPNs only */
                ((@SearchType       = 'F' /* Full LPN Search */) and
                 (AllocableQuantity = TotalQuantity            ) and
                 (AllocableQuantity  <= @UnitsNeeded           ) and
                 (coalesce(LPN, '') <> '')
                 )
                 or
                ((@SearchType = 'P' /* Partially Allocable LPN Search */))
              )
        order by
               case when @OrderByField = 'ExpiryDate' then ExpiryDate end,
               case when @SearchType = 'F' then AllocableQuantity end desc,
               case when @SearchType = 'P' then AllocableQuantity end,
               Location;
      end
end /* pr_Picking_FindAllocableLPN */

Go
