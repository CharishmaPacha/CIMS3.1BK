/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/28  VS      pr_Wave_GetSummary, pr_Wave_InventorySummary: Show UnitsRequiredtoActivate for Activate remainig ShipCartons (HA-2714)
  2021/04/23  RV      pr_Wave_GetSummary: Show wave summary by label code
                        pr_Wave_InventorySummary: Included inventory classes in the key value (HA-2699)
  2021/04/20  TK      pr_Wave_InventorySummary & pr_PickBatch_SetStatus:
                        Transfer waves use units shipped from order details (HA-GoLive)
  2021/03/13  PK      pr_Wave_InventorySummary: Include Bulk Order Unitsassigned (HA GoLive)
  2021/02/24  PK      pr_Wave_InventorySummary: Ported changes done by Pavan (HA-2050)
  2020/12/11  SJ      pr_Wave_InventorySummary: Added NewSKU & InventoryClasses1, 2, 3 & NewInventoryClasses1, 2, 3 (HA-1693)
  2020/11/29  PK      pr_PickBatch_RemoveOrders: Void the labels when order is removed from the wave (HA-1723).
                      pr_Wave_GetSummary, pr_Wave_InventorySummary: Displaying the InventoryClass values and showing the wave summary page (HA-1723)
  2020/11/13  AY      pr_Wave_InventorySummary: Show UnitsPreallocated (HA-Onsite)
  2020/08/28  RKC     pr_Wave_InventorySummary: Removed the CustSKU field (HA-1353)
  2018/03/30  AY      pr_Wave_InventorySummary, pr_Wave_GetSummary: New versions of existing procs
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_InventorySummary') is not null
  drop Procedure pr_Wave_InventorySummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_InventorySummary:  This procedure will returns the inventory
    summary for the given Wave by SKU-WH-Ownership. If #WaveSummary was created
    by caller, then data is returned by that, else it is returned as a dataset
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_InventorySummary
  (@WaveId  TRecordId,
   @WaveNo  TWaveNo)
as
  declare @ttWaveSummary    TWaveSummary;
  declare @ttOrderDtls      TWaveSummary;
  declare @ttAvailInventory TWaveSummary; -- will use only required fields to gather inventory details
  declare @ttSKULPNCounts   TWaveSummary;

  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vBusinessUnit               TBusinessUnit,
          @vReturnDataSet              TFlag = 'N',
          @vValidateUnitsPerCarton     TFlag,
          @vWaveId                     TRecordId,
          @vCustPO                     TCustPO,
          @vCount                      TCount,
          @vWaveType                   TTypeCode,
          @vLocationTypesToConsider    TDescription,
          @vStorageTypesToDisregard    TDescription,
          @vCaseStorageZonesToConsider TDescription,
          @vUnitStorageZonesToConsider TDescription,
          @vControlCategory            TCategory;

begin /* pr_Wave_InventorySummary */
  /* Get the CustPO and Business Unit from the Batch */
  select @vWaveId          = WaveId,
         @vCustPO          = UDF1,
         @vBusinessUnit    = BusinessUnit,
         @vWaveType        = BatchType,
         @vControlCategory = 'Wave_' + BatchType
  from Waves
  where (WaveNo = @WaveNo);

  /* Create Temp Table, if not already created by caller */
  if (object_id('tempdb..#WaveSummary') is null)
    begin
      select * into #WaveSummary from @ttWaveSummary;
      select @vReturnDataSet = 'Y';
    end

  /* Get the control variable to validate if the LPN Quantity is not equal to the UnitsPerCarton on Order */
  select @vValidateUnitsPerCarton     = dbo.fn_Controls_GetAsBoolean('Picking', 'ValidateUnitsperCarton', 'Y' /* Yes */, @vBusinessUnit, null /* UserId */);
  select @vCaseStorageZonesToConsider = dbo.fn_Controls_GetAsString(@vControlCategory, 'CaseStorageZonesToConsider', '', @vBusinessUnit, null /* UserId */),
         @vUnitStorageZonesToConsider = dbo.fn_Controls_GetAsString(@vControlCategory, 'UnitStorageZonesToConsider', '', @vBusinessUnit, null /* UserId */);

  /* select all the info from orderdetails based on the WaveNo */
  insert into @ttOrderDtls
      (WaveNo, SKUId, CustSKU, CustPO, UnitsOrdered, UnitsAuthorizedToShip,
       UnitsPreallocated, UnitsAssigned, UnitsNeeded, UnitsShipped, UnitsPerInnerPack,
       SKU, NewSKU, InventoryClass1, InventoryClass2, InventoryClass3,
       NewInventoryClass1, NewInventoryClass2, NewInventoryClass3, UnitsReservedForWave,
       Warehouse, Ownership, RecordId)
    select @WaveNo, OD.SKUId, min(OD.CustSKU), @vCustPO,
           sum(case when OH.OrderType <> 'B' then OD.UnitsOrdered else 0 end),
           sum(case when OH.OrderType <> 'B' then OD.UnitsAuthorizedToShip else 0 end),
           sum(case when OH.OrderType <> 'B' then OD.UnitsPreallocated else 0 end),
           sum(dbo.fn_MaxInt(OD.UnitsAssigned, 0)),
           sum(case when OH.OrderType <> 'B' then dbo.fn_MaxInt(OD.UnitsToAllocate, 0) else 0 end),
           sum(OD.UnitsShipped),
           min(S.UnitsPerInnerPack),
           min(S.SKU),
           min(OD.NewSKU),
           OD.InventoryClass1,
           OD.InventoryClass2,
           OD.InventoryClass3,
           min(OD.NewInventoryClass1),
           min(OD.NewInventoryClass2),
           min(OD.NewInventoryClass3),
           sum(case when OH.OrderType = 'B' then (OD.UnitsAssigned) else 0 end),   /* Units Reserved For Wave */
           OH.Warehouse, OH.Ownership, row_number() over (order by OD.SKUId)
    from OrderDetails OD
         join PickBatchDetails        PBD on (PBD.OrderDetailId = OD.OrderDetailId)
         left outer join OrderHeaders  OH on (OD.OrderId        = OH.OrderId)
         left outer join SKUs           S on (OD.SKUId          = S.SKUId)
    where (PBD.PickBatchNo = @WaveNo) and
          (OH.Status       <> 'H' /* hold */) -- why?
    group by OD.SKUId, OH.Warehouse, OH.Ownership, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3;

  select @vLocationTypesToConsider = case when (@vWaveType not in ('R', 'RU', 'RP')) then 'RBK'
                                          when (@vWaveType in ('RP', 'R')) then 'RB'
                                          when (@vWaveType = 'RU') then 'RBK'
                                     end,
        @vStorageTypesToDisregard  = case when (@vWaveType = 'RU') then 'U' else '' end;

  /* For all SKUs in the wave, get the available inventory
     - For replenish Wave, consider inventory in RB Locations only
     - For other waves, consider RBK Locations only
     - For Unit Storage Replenish, do not consider inventory in other Unit storage Locations */
  insert into @ttAvailInventory (SKUId, InventoryClass1, InventoryClass2, InventoryClass3, Warehouse, Ownership,
                                 UnitsPerInnerPack, LPNsAvailable, CasesAvailable, CasesAvailable_PPicklane,
                                 CasesAvailable_Reserve, CasesAvailable_Bulk, CasesAvailable_RB, CasesAvailable_Other,
                                 UnitsAvailable, UnitsAvailable_UPicklane, UnitsAvailable_PPicklane,
                                 UnitsAvailable_Reserve, UnitsAvailable_Bulk, UnitsAvailable_RB, UnitsAvailable_Other,
                                 PrimaryLocation, SecondaryLocation, RecordId)
    select LD.SKUId, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, L.DestWarehouse, L.Ownership,
           Max(LD.UnitsPerPackage), count(distinct LD.LPNId),
           /*** Cases ***/
           sum(dbo.fn_MaxInt(LD.AllocableInnerPacks, 0)),                                                          -- Cases Available
           sum(case when Loc.LocationType = 'K' and Loc.StorageType = 'P' and
                         ((@vCaseStorageZonesToConsider is null) or
                          (dbo.fn_IsInList(Loc.PickingZone, @vCaseStorageZonesToConsider) > 0))
                                                then LD.AllocableInnerPacks else 0 end),                           -- CA_PPicklane
           sum(case when Loc.LocationType = 'R' then LD.AllocableInnerPacks else 0 end),                           -- CA_Reserve
           sum(case when Loc.LocationType = 'B' then LD.AllocableInnerPacks else 0 end),                           -- CA_Bulk
           sum(case when charindex(Loc.LocationType, 'RB') > 0 then LD.AllocableInnerPacks else 0 end),            -- CA_RB
           sum(case when charindex(Loc.LocationType, 'RBK') = 0 then LD.AllocableInnerPacks else 0 end),           -- CA_other
           /*** Units ***/
           sum(dbo.fn_MaxInt(LD.AllocableQty, 0)),                                                                 -- Units Available
           sum(case when Loc.LocationType = 'K' and Loc.StorageType = 'U' and
                          ((@vUnitStorageZonesToConsider is null) or
                           (dbo.fn_IsInList(Loc.PickingZone, @vUnitStorageZonesToConsider) > 0))                   -- CA_PPicklane
                                                then LD.AllocableQty else 0 end),
           sum(case when Loc.LocationType = 'K' and Loc.StorageType = 'P' and
                          ((@vCaseStorageZonesToConsider is null) or
                           (dbo.fn_IsInList(Loc.PickingZone, @vCaseStorageZonesToConsider) > 0))
                                                then LD.AllocableInnerPacks else 0 end),                           -- CA_PPicklane
           sum(case when Loc.LocationType = 'R' then LD.AllocableQty else 0 end),                                  -- UA_Reserve
           sum(case when Loc.LocationType = 'B' then LD.AllocableQty else 0 end),                                  -- UA_Bulk
           sum(case when charindex(Loc.LocationType, 'RB') > 0 then LD.AllocableQty else 0 end),                   -- UA_RB
           sum(case when charindex(Loc.LocationType, 'RBK') = 0 then LD.AllocableQty else 0 end),                  -- UA_other
           min(case when ((@vUnitStorageZonesToConsider is null) or
                          (dbo.fn_IsInList(Loc.PickingZone, @vUnitStorageZonesToConsider) > 0)) and
                         (Loc.StorageType = 'U' /* Units */)
                    then Loc.Location else null end),                                                              -- PrimaryLocation
           min(case when ((@vCaseStorageZonesToConsider is null) or
                          (dbo.fn_IsInList(Loc.PickingZone, @vCaseStorageZonesToConsider) > 0)) and
                         (Loc.StorageType = 'P' /* Package */)
                    then Loc.Location else null end),                                                              -- SecondaryLocation
           row_number() over (order by LD.SKUId)
    from LPNDetails LD join LPNs L on LD.LPNId = L.LPNId
                       join Locations LOC on (L.LocationId = LOC.LocationId)
                       join @ttOrderDtls OD on (LD.SKUId = OD.SKUId) and (OD.Warehouse = L.DestWarehouse) and
                                               (OD.Ownership = L.Ownership) and (LD.OnhandStatus = 'A') and
                                               (OD.InventoryClass1 = L.InventoryClass1) and
                                               (OD.InventoryClass2 = L.InventoryClass2) and
                                               (OD.InventoryClass3 = L.InventoryClass3)
    where (charindex(Loc.LocationType, @vLocationTypesToConsider) > 0) and
          (charindex(Loc.StorageType, @vStorageTypesToDisregard) = 0)
    group by LD.SKUId, L.DestWarehouse, L.Ownership, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3;

  /* Get LPNs count based on the SKU */
  insert into @ttSKULPNCounts(OrderDetailId, SKUId, InventoryClass1, InventoryClass2, InventoryClass3,
               UnitsPicked, UnitsPacked, UnitsLabeled, UnitsShipped,
               LPNsAssigned, LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped, Warehouse, Ownership,
               ToActivateShipCartonQty, RecordId)
    select 0,
           LD.SKUId, /* U-Picking, K-Picked, L-Loaded, G-Packing, E-Staged, D-Packed, S-Shipped */
           L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
           sum(case when (charindex(L.Status, 'UKGDELS') <> 0) and (LD.OnhandStatus <> 'U') then LD.Quantity else 0 end) as UnitsPicked,
           sum(case when (charindex(L.Status, 'DELS' ) <> 0) then LD.Quantity else 0 end) as UnitsPacked,
           sum(case when (charindex(L.Status, 'DELS'  ) <> 0) and
                         ((L.UCCBarcode is not null) or (L.TrackingNo is not null))
                                                              then LD.Quantity else 0 end) as UnitsLabeled,
           sum(case when (charindex(L.Status, 'S'     ) <> 0) then LD.Quantity else 0 end) as UnitsShipped,
           count(distinct L.LPNId),
           count(distinct (case when (charindex(L.Status, 'KGDELS') <> 0) then L.LPNId else null end)) as LPNsPicked,
           count(distinct (case when (charindex(L.Status, 'GDELS')  <> 0) then L.LPNId else null end)) as LPNsPacked,
           count(distinct (case when (charindex(L.Status, 'DELS')   <> 0) and
                         ((L.UCCBarcode is not null) or (L.TrackingNo is not null))
                                                                          then L.LPNId else null end)) as LPNsLabeled,
           count(distinct (case when (charindex(L.Status, 'S')      <> 0) then L.LPNId else null end)) as LPNsShipped,
           L.DestWarehouse, L.Ownership,
           sum(case when L.LPNType = 'S' and L.OnhandStatus = 'U' then LD.Quantity else 0 end) as ToActivateShipCartonQty,
           row_number() over (order by LD.SKUId)
    from LPNDetails         LD
      join LPNs             L  on (L.LPNId          = LD.LPNId  )
    where (L.PickBatchId = @vWaveId)
    group by LD.SKUId, L.DestWarehouse, L.Ownership, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3;

  /* Insert data into temptable
     LPNs Assigned can be computed based on real count of LPNs, need not be estimated based upon UnitsAssigned */
  insert into #WaveSummary(RecordId, HostOrderLine, OrderDetailId, CustSKU, CustPO, ShipToStore,
                             WaveNo, Warehouse, Ownership,
                             SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, Description,
                             PrimaryLocation, SecondaryLocation,
                             /* Units Available */
                             UnitsAvailable_UPicklane, UnitsAvailable_PPicklane,
                             UnitsAvailable_Reserve, UnitsAvailable_Bulk, UnitsAvailable_RB, UnitsAvailable_Other,
                             UnitsShort_UPicklane, UnitsShort_PPicklane,
                             /* Cases Available */
                             CasesAvailable_PPicklane, CasesAvailable_Reserve, CasesAvailable_Bulk,
                             CasesAvailable_RB, CasesAvailable_Other,
                             /* Computed */
                             UnitsShort,
                             /* OD */
                             NewSKU, InventoryClass1, InventoryClass2, InventoryClass3,
                             NewInventoryClass1, NewInventoryClass2, NewInventoryClass3,
                             UnitsPerCarton, UnitsPerInnerPack, UnitsOrdered, UnitsAuthorizedToShip,
                             UnitsPreallocated, UnitsAssigned, UnitsNeeded, UnitsAvailable,
                             UnitsPicked, UnitsPacked, UnitsLabeled, UnitsShipped,
                             LPNsOrdered, LPNsToShip, LPNsAssigned, LPNsNeeded,
                             LPNsAvailable, LPNsShort, LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped,
                             UnitsReservedForWave, ToActivateShipCartonQty, UnitsRequiredtoActivate, KeyValue)
    select OD.RecordId, OD.HostOrderLine, OD.OrderDetailId, OD.CustSKU, OD.CustPO, OD.ShipToStore,
           OD.WaveNo, OD.Warehouse, OD.Ownership,
           OD.SKUId, S.SKU, S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5, S.UPC, S.Description,
           I.PrimaryLocation, I.SecondaryLocation,
           /* Units Available */
           coalesce(I.UnitsAvailable_UPickLane, 0), coalesce(I.UnitsAvailable_PPickLane, 0),
           coalesce(I.UnitsAvailable_Reserve, 0), coalesce(I.UnitsAvailable_Bulk, 0),
           coalesce(I.UnitsAvailable_RB, 0), coalesce(I.UnitsAvailable_Other, 0),
           case when (OD.UnitsNeeded > coalesce(I.UnitsAvailable_UPickLane, 0)) then
                  OD.UnitsNeeded - coalesce(I.UnitsAvailable_UPickLane, 0)
                else 0
           end/* UnitsShort_UPickLane */,
           case when (OD.UnitsNeeded > coalesce(I.UnitsAvailable_PPickLane, 0)) then
                  OD.UnitsNeeded - coalesce(I.UnitsAvailable_PPickLane, 0)
                else 0
           end/* UnitsShort_PPickLane */,
           /* Cases available */
           coalesce(I.CasesAvailable_PPicklane, 0), coalesce(I.CasesAvailable_Reserve, 0),
           coalesce(I.CasesAvailable_Bulk, 0), coalesce(I.CasesAvailable_RB, 0),
           coalesce(I.CasesAvailable_Other, 0),
           /* Computed fields */
           case when (OD.UnitsNeeded > coalesce(nullif(I.UnitsAvailable, ''),0)) then
             coalesce(OD.UnitsNeeded, 0) - coalesce(nullif(I.UnitsAvailable, ''),0)
           else 0 end, /* Units Short */
           /* OD */
           OD.NewSKU, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3,
           OD.NewInventoryClass1, OD.NewInventoryClass2, OD.NewInventoryClass3,
           coalesce(OD.UnitsPerCarton, 0), OD.UnitsPerInnerPack, OD.UnitsOrdered, OD.UnitsAuthorizedToShip,
           OD.UnitsPreallocated, OD.UnitsAssigned, OD.UnitsNeeded, coalesce(I.UnitsAvailable, 0),
           SC.UnitsPicked, SC.UnitsPacked, SC.UnitsLabeled,
           /* For transfer orders when shipped we will clear order info on the LPNs, so use UnitsShipped from order details */
           case when @vWaveType = 'XFER' then OD.UnitsShipped else SC.UnitsShipped end /* UnitsShipped */,
           coalesce(OD.LPNsOrdered, 0), coalesce(OD.LPNsToShip, 0),coalesce(SC.LPNsAssigned, 0), OD.LPNsNeeded,
           coalesce(I.LPNsAvailable, 0), case when (OD.LPNsNeeded <= coalesce(I.LPNsAvailable, 0)) then 0 else coalesce(OD.LPNsNeeded, 0) - coalesce(I.LPNsAvailable, 0) end,
           coalesce(SC.LPNsPicked, 0), coalesce(SC.LPNsPacked, 0), coalesce(SC.LPNsLabeled, 0), coalesce(SC.LPNsShipped, 0),
           coalesce(OD.UnitsReservedForWave, 0), coalesce(SC.ToActivateShipCartonQty, 0),
           coalesce(SC.ToActivateShipCartonQty, 0) - coalesce(OD.UnitsReservedForWave, 0),
           concat_ws('-', cast(OD.SKUId as varchar), OD.Warehouse, OD.Ownership, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3)
    from @ttOrderDtls OD
    left outer join SKUs              S  on OD.SKUId = S.SKUId
    left outer join @ttAvailInventory I  on OD.KeyValue = I.KeyValue and
                                            ((@vValidateUnitsPerCarton = 'N') or (S.UoM = 'PP') or (OD.UnitsPerCarton = I.UnitsPerInnerPack))
    left outer join @ttSKULPNCounts   SC on OD.KeyValue = SC.KeyValue
    order by S.SKU;

  /* Returning Inventory Summary Dataset */
  if (@vReturnDataSet = 'Y') select * from #WaveSummary;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Wave_InventorySummary */

Go
