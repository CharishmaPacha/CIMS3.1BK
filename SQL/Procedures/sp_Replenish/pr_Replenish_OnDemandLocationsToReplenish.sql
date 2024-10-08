/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/08  SK      pr_Replenish_OnDemandLocationsToReplenish: Consider ODLot as empty string (OBV3-371)
                      pr_Replenish_OnDemandLocationsToReplenish: Replenish to dynamic locations if no static location found
                      pr_Replenish_GenerateOndemandOrders, pr_Replenish_OnDemandLocationsToReplenish & fn_Replenish_GetOnDemandReplenishLocation:
                      fn_Replenish_GetOnDemandReplenishLocation, pr_Replenish_OnDemandLocationsToReplenish &
  2020/06/08  TK      pr_Replenish_GenerateOndemandOrders, pr_Replenish_GenerateOrders, pr_Replenish_OnDemandLocationsToReplenish,
  2019/05/07  YJ      pr_Replenish_OnDemandLocationsToReplenish, fn_Replenish_GetOnDemandReplenishLocation: Changes to get Ownership on the Location (S2GCA-98)(Ported from Prod)
  2019/02/18  TK      pr_Replenish_OnDemandLocationsToReplenish: Changes to fn_Batching_IsBulkPullBatch signature (S2GCA-465)
  2018/09/10  TK      pr_Replenish_OnDemandLocationsToReplenish: Changed RuleSet Type ZonesToReplenish -> ReplenishToZones (S2GCA-239)
  2018/03/28  TK      pr_Replenish_OnDemandLocationsToReplenish: If case storage locations are not set up then replenish all required units to
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_OnDemandLocationsToReplenish') is not null
  drop Procedure pr_Replenish_OnDemandLocationsToReplenish;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_OnDemandLocationsToReplenish: This procedure find the locations that needs
    to be replenished for a given wave
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_OnDemandLocationsToReplenish
  (@WaveId       TRecordId)
as
  declare @vMessageName       TMessageName,
          @vReturnCode        TInteger,
          @vCSRecordId        TRecordId,
          @vUnitsRecordId     TRecordId,

          @vSKUId             TRecordId,
          @vStorageType       TStorageType,
          @vInventoryClass1   TInventoryClass,
          @vInventoryClass2   TInventoryClass,
          @vInventoryClass3   TInventoryClass,
          @vOwnership         TOwnership,
          @vWarehouse         TWarehouse,
          @vWaveType          TTypeCode,
          @vBusinessUnit      TBusinessUnit,

          @vCasesToAllocate   TQuantity,
          @vUnitsToAllocate   TQuantity,
          @vCasePickZonesToReplenish
                              TVarchar,
          @vUnitPickZonesToReplenish
                              TVarchar,


          @xmlRulesData       TXML,
          @vIsBulkPullBatch   TFlag;

  declare @ttWaveDetailsToReplenish    TWaveDetailsToReplenish,
          @ttCasesToAllocate           TWaveDetailsToReplenish,
          @ttUnitsToAllocate           TWaveDetailsToReplenish,
          @ttLocationsToReplenish      TLocationsToReplenish;

begin /* pr_Replenish_FindLocationsToReplenish */
  /* Get Wave info */
  select @vWaveType        = BatchType,
         @vBusinessUnit    = BusinessUnit,
         @vIsBulkPullBatch = dbo.fn_Pickbatch_IsBulkBatch(RecordId)
  from PickBatches
  where (RecordId = @WaveId);

  /* Build rules xml */
  select @xmlRulesData = '<RootNode>' +
                            dbo.fn_XMLNode('WaveType',     @vWaveType) +
                            dbo.fn_XMLNode('StorageType',  @vStorageType) +
                         '</RootNode>';

  /* Determine PickZonesToReplenish */
  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'StorageType', 'P');
  exec pr_RuleSets_Evaluate 'ReplenishToZones', @xmlRulesData, @vCasePickZonesToReplenish output;

  /* Get all the wave details to replenish */
  insert into @ttWaveDetailsToReplenish(OrderId, SKUId, DestZone, InventoryClass1, InventoryClass2, InventoryClass3,  Ownership, Warehouse,
                                        TotalQtyToAllocate, CasesToAllocate, UnitsToAllocate)
    select OrderId, SKUId, DestZone, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse, sum(UnitsToAllocate),
           sum(case when (UnitsPerInnerPack > 0) then floor(UnitsToAllocate/UnitsPerInnerPack) else 0 end)/* CasesToAllocate */,
           sum(case when (UnitsPerInnerPack > 0) then (UnitsToAllocate % UnitsPerInnerPack)    else UnitsToAllocate end)/* UnitsToAllocate */
    from vwPickBatchDetails
    where (PickBatchId = @WaveId) and
          (UnitsToAllocate > 0) and
          (coalesce(ODLot, '') = '') and  -- If Lot No is present on OrderDetail then it would be expecting specific LPN Detail which matches with the OD.Lot so exclude while creating Replenish Orders
          ((@vIsBulkPullBatch = 'N'/* No */) or (OrderType = 'B' /* Bulk PT */))
    group by OrderId, SKUId, DestZone, Warehouse, Ownership, InventoryClass1, InventoryClass2, InventoryClass3;

  /* If case storage locations are not set up then replenish all required units to
     Unit Storage Locations */
  update ttWD
  set ttWD.CasesToAllocate = 0,
      ttWD.UnitsToAllocate = TotalQtyToAllocate
  from @ttWaveDetailsToReplenish ttWD
    left outer join vwLPNs L on (ttWD.SKUId     = L.SKUId        ) and
                                (ttWD.Ownership = L.Ownership    ) and
                                (ttWD.Warehouse = L.DestWarehouse) and
                                (ttWD.InventoryClass1 = L.InventoryClass1) and
                                (ttWD.InventoryClass2 = L.InventoryClass2) and
                                (ttWD.InventoryClass3 = L.InventoryClass3) and
                                (L.StorageType = 'P'/* Cases */  ) and
                                (charindex(',' + L.PickingZone + ',', @vCasePickZonesToReplenish) > 0)
  where (L.LPNId is null);

  /* First let's find if there are any cases needed to ship for customer order */
  insert into @ttCasesToAllocate(SKUId, TotalQtyToAllocate, CasesToAllocate, UnitsToAllocate, DestZone,
                                 InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse)
    select SKUId, TotalQtyToAllocate, CasesToAllocate, UnitsToAllocate, DestZone,
           InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse
    from @ttWaveDetailsToReplenish
    where (CasesToAllocate > 0);

  /* Initialize */
  select @vCSRecordId    = 0,
         @vUnitsRecordId = 0;

  /*************  Find Case Storage Locations To Replenish **************/
  while exists (select *
                from @ttCasesToAllocate
                where (CasesToAllocate > 0) and
                      (RecordId > @vCSRecordId))
    begin
      select top 1 @vCSRecordId      = RecordId,
                   @vSKUId           = SKUId,
                   @vCasesToAllocate = CasesToAllocate,
                   @vInventoryClass1 = InventoryClass1,
                   @vInventoryClass2 = InventoryClass2,
                   @vInventoryClass3 = InventoryClass3,
                   @vOwnership       = Ownership,
                   @vWarehouse       = Warehouse,
                   @vStorageType     = 'P'/* Cases */
      from @ttCasesToAllocate
      where (RecordId > @vCSRecordId)
      order by RecordId;

      /* Save the location to create a Replenish Order and Wave later */
      insert into @ttLocationsToReplenish(LocationId, Location, StorageType, SKUId, SKU, ReplenishUoM, QtyToReplenish, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse)
        select * from dbo.fn_Replenish_GetOnDemandReplenishLocation(@vSKUId, @vCasesToAllocate, 0/* UnitsToAllocate */, @vStorageType, @vInventoryClass1, @vInventoryClass2, @vInventoryClass3, @vOwnership,  @vWarehouse, @vCasePickZonesToReplenish)
    end

  /* Find out there are any units needed to ship for original order */
  insert into @ttUnitsToAllocate(SKUId, DestZone, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse,
                                 TotalQtyToAllocate, CasesToAllocate, UnitsToAllocate)
    select SKUId, DestZone, InventoryClass1, InventoryClass2, InventoryClass3,
           Ownership, Warehouse, sum(TotalQtyToAllocate), sum(CasesToAllocate), sum(UnitsToAllocate)
    from @ttWaveDetailsToReplenish
    where (UnitsToAllocate > 0)
    group by SKUId, DestZone, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse;

  /* Determine PickZonesToRepleish */
  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'StorageType', 'U');
  exec pr_RuleSets_Evaluate 'ReplenishToZones', @xmlRulesData, @vUnitPickZonesToReplenish output;

  /*************  Find Unit Storage Locations To Replenish **************/
  while exists (select *
                from @ttUnitsToAllocate
                where (UnitsToAllocate > 0) and
                      (RecordId > @vUnitsRecordId))
    begin
      select top 1 @vUnitsRecordId   = RecordId,
                   @vSKUId           = SKUId,
                   @vUnitsToAllocate = UnitsToAllocate,
                   @vInventoryClass1 = InventoryClass1,
                   @vInventoryClass2 = InventoryClass2,
                   @vInventoryClass3 = InventoryClass3,
                   @vOwnership       = Ownership,
                   @vWarehouse       = Warehouse,
                   @vStorageType     = 'U'/* Units */
      from @ttUnitsToAllocate
      where (RecordId > @vUnitsRecordId)
      order by RecordId;

      /* Save the location to create a Replenish Order and Wave later */
      insert into @ttLocationsToReplenish(LocationId, Location, StorageType, SKUId, SKU, ReplenishUoM, QtyToReplenish, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse)
        select * from dbo.fn_Replenish_GetOnDemandReplenishLocation(@vSKUId, 0/* CasesToAllocate */, @vUnitsToAllocate, @vStorageType, @vInventoryClass1, @vInventoryClass2, @vInventoryClass3, @vOwnership, @vWarehouse, @vUnitPickZonesToReplenish)
    end

  /* Return Locations to be replenished */
  select LocationId, Location, StorageType, SKUId, SKU, ReplenishUoM, QtyToReplenish, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse
  from @ttLocationsToReplenish;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_OnDemandLocationsToReplenish */

Go
