/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/06/28  SV      fn_PickBatches_InventorySummary: Reduced the response time by using the concept of Parameter Sniffing (FB-963)
  2016/08/03  AY      fn_PickBatches_InventorySummary: Fix to not include unavailable lines in calculations (CIMS-1003).
  2016/07/16  TD      fn_PickBatches_InventorySummary:Changes to show picklane location for SKU.(HPI-294)
  2016/07/04  YJ      fn_PickBatches_InventorySummary: Added to show UnitsPreAllocated (HPI-219)
  2016/05/25  DK      fn_PickBatches_InventorySummary: Use THostOrderLine as data type for Line field in temp table as it is inserting Hostline only (FB-702).
  2016/04/07  SV      pr_PickBatch_BatchSummary, fn_PickBatches_InventorySummary: Changes to the Units avaialble and shorts over the batch summary (SRI-481)
  2015/10/30  RV      fn_PickBatches_InventorySummary : Exclude the Replenish inventory (FB-474)
  2015/10/05  AY      fn_PickBatches_InventorySummary: Bug fix (FB-408)
  2015/08/18  OK      pr_PickBatch_BatchSummary, fn_PickBatches_InventorySummary: Migrated from GNC and fixed bugs (FB-311).
  2015/06/26  RV      fn_PickBatches_InventorySummary: Remove the condition for BP for Units Assigned as now we are reducing them while packing in Bulk PT.
  2015/04/22  RV      fn_PickBatches_InventorySummary: Show proper Pick Batch Summary, even for Bulk Pull orders
  2015/03/04  DK      fn_PickBatches_InventorySummary: Excluded Bulk Order calculation.
  2014/12/26  PKS     fn_PickBatches_InventorySummary: Replenish Units included as InStock units
  2014/09/01  PKS     fn_PickBatches_InventorySummary: Units Reserved against Replenishment Order shown as Units Available
  2014/06/14  PKS     fn_PickBatches_InventorySummary: RecordId (Identity Column) added and implemented in pr_PickBatch_BatchSummary
  2014/04/01  TD      fn_PickBatches_InventorySummary:Changes to avoid duplicate records.
  2014/04/01  TD      fn_PickBatches_InventorySummary:Changes to avoid duplicate records.
  2013/12/04  NY      fn_PickBatches_InventorySummary:Added UnitsPerInnerPack(Taking from SKUs instead OrderDetails).
  2103/10/01  TD      fn_PickBatches_InventorySummary:Get details from the PickBatchDetails instead of OrderHeaders Batch.
  2103/04/23  TD      fn_PickBatches_InventorySummary,fn_PickBatches_BatchSummary -Added Description of SKU, UPC.
  2012/11/29  PKS     fn_PickBatches_InventorySummary & fn_PickBatches_BatchSummary: CustPO added.
  2012/10/31  PK      fn_PickBatches_InventorySummary: Retrieve LPNs which are matching with UnitsPerCarton,
  2012/10/09  TD      Added new function fn_PickBatches_InventorySummary.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_PickBatches_InventorySummary') is not null
  drop Function fn_PickBatches_InventorySummary;
Go
/*------------------------------------------------------------------------------
  Proc fn_PickBatches_InventorySummary:  This Function will returns the inventory
    summary for the given PickBatch
------------------------------------------------------------------------------*/
Create Function fn_PickBatches_InventorySummary
  (@PickBatchNo  TPickBatchNo)
returns
/* temp table  to return data */
  @PickBatchInvSummary       table
    (RecordId                TRecordId Identity(1,1),
     BatchNo                 TPickBatchNo,
     Line                    THostOrderLine,
     ShipToStore             TShipToStore,
     CustSKU                 TCustSKU,
     CustPO                  TCustPO,

     UnitsOrdered            TQuantity,
     UnitsAuthorizedToShip   TQuantity,
     UnitsAssigned           TQuantity,
     UnitsPreAllocated       TQuantity,
     UnitsNeeded             TQuantity,
     UnitsAvailable          TQuantity,
     UnitsAvailablePicklane  TQuantity,
     UnitsShortPickLane      TQuantity,
     UnitsAvailableReserve   TQuantity,
     UnitsShortReserve       TQuantity,
     UnitsShort              TQuantity,
     UnitsPicked             TQuantity,
     UnitsPacked             TQuantity,
     UnitsLabeled            TQuantity,
     UnitsShipped            TQuantity,

     LPNsOrdered             TCount,
     LPNsToShip              TCount,
     LPNsAssigned            TCount,
     LPNsNeeded              TCount,
     LPNsAvailable           TCount,
     LPNsShort               TCount,
     LPNsPicked              TCount,
     LPNsPacked              TCount,
     LPNsLabeled             TCount,
     LPNsShipped             TCount,

     UnitsPerInnerPack       TQuantity,
     UnitsPercarton          TQuantity,

     SKUId                   TRecordId,
     SKU                     TSKU,
     SKU1                    TSKU,
     SKU2                    TSKU,
     SKU3                    TSKU,
     SKU4                    TSKU,
     SKU5                    TSKU,
     UPC                     TUPC,
     Description             TDescription,

     UDF1                    TUDF)
as
begin /* fn_PickBatches_InventorySummary */
  declare @vPickBatchId            TRecordId,
          @vPickBatchNo            TPickBatchNo,
          @vBatchType              TTypeCode,
          @vCustPO                 TCustPO,
          @vBusinessUnit           TBusinessUnit,
          @vValidateUnitsPerCarton TFlag,
          @vCount                  TCount;

  /* Get the CustPO and Business Unit from the Batch */
  select @vPickBatchId  = RecordId,
         @vPickBatchNo  = BatchNo,
         @vCustPO       = UDF1,
         @vBusinessUnit = BusinessUnit,
         @vBatchType    = BatchType
  from PickBatches
  where (BatchNo = @PickBatchNo);

  /* Get the control variable to validate if the LPN Quantity is not equal to the UnitsPerCarton on Order */
  select @vValidateUnitsPerCarton  = dbo.fn_Controls_GetAsBoolean('Picking', 'ValidateUnitsperCarton', 'Y' /* Yes */, @vBusinessUnit, null /* UserId */);

  /* select all the info from orderdetails based on the PickBatchno */
  with OrderDtls (Line, OrdDetailId, ShipToStore, SKUId, CustSKU, UnitsOrdered,
                  UnitsAuthorizedToShip, UnitsAssigned, UnitsPreAllocated, UnitsNeeded, UnitsPerInnerPack,
                  LPNsOrdered, LPNsToShip, LPNsAssigned, LPNsNeeded, UnitsPercarton, Warehouse, Ownership)
  as
  (
    select OD.HostOrderLine, OD.OrderDetailId, OH.ShipToStore, OD.SKUId, OD.CustSKU,
           case when OH.OrderType <> 'B' then OD.UnitsOrdered else 0 end,
           case when OH.OrderType <> 'B' then OD.UnitsAuthorizedToShip else 0 end,
           OD.UnitsAssigned,
           case when OrderType <> 'B' then OD.UnitsPreAllocated else 0 end,
           Case
             when (dbo.fn_Controls_GetAsString('PB_CreateBPT', PB.BatchType, 'N' /* No */, @vBusinessUnit, null /* UserId */)= 'Y' /* Yes */) and
                  (OH.OrderType <> 'B' /* Bulk */) then
               0
           else
             OD.UnitsToAllocate
           end /* UnitsToAllocate */,
           S.UnitsPerInnerPack,
           case
             when S.UoM = 'EA' /* non-prepack */ and OD.UnitsPerCarton > 0 then
               (OD.UnitsOrdered/OD.UnitsPerCarton)
             when S.UoM = 'PP' /* Prepack */ then
               (OD.UnitsOrdered)
           end LPNsOrdered,
           case
             when S.UoM = 'EA' /* non-prepack */ and OD.UnitsPerCarton > 0 then
               (OD.UnitsAuthorizedToShip/OD.UnitsPerCarton)
             when S.UoM = 'PP' /* Prepack */ then
               (OD.UnitsAuthorizedToShip)
           end LPNsToShip,
           case
             when S.UoM = 'EA' /* non-prepack */ and OD.UnitsPerCarton > 0 then
               (OD.UnitsAssigned/OD.UnitsPerCarton)
             when S.UoM = 'PP' /* Prepack */ then
               (OD.UnitsAssigned)
           end  LPNsAssigned,
           case
             when S.UoM = 'EA' /* non-prepack */  and OD.UnitsPerCarton > 0 then
               (OD.UnitsToAllocate/OD.UnitsPerCarton)
             when S.UoM = 'PP' /* Prepack */ then
               (OD.UnitsToAllocate)
           end LPNsNeeded,
           OD.UnitsPercarton, OH.Warehouse, OH.Ownership
    from OrderDetails OD
         join PickBatchDetails PBD on (PBD.OrderDetailId = OD.OrderDetailId)
         join PickBatches      PB  on (PB.BatchNo = PBD.PickBatchNo)
         join OrderHeaders     OH  on (OD.OrderId = OH.OrderId)
         join SKUs             S   on (OD.SKUId = S.SKUId)
    where (PBD.PickBatchNo = @vPickBatchNo) and
          (OH.Status <> 'H' /* hold */)
  ),
  /* select LPN Inventory from the lpndetails based on the SKU */
  Inven (SKUId, Ownership, Warehouse, UnitsPerCarton, AvailLPNs, AvailIPs, AvailUnits,
         UnitsAvailablePicklane, UnitsAvailableReserve)
  as
  (
    select LD.SKUId, L.Ownership, L.DestWarehouse, Max(LD.UnitsPerPackage), count(distinct LD.LPNId), sum(LD.InnerPacks), sum(LD.Quantity),
           sum(case when LOC.LocationType = 'K' then LD.Quantity else 0 end) /* Units AvailablePicklane */,
           sum(case when LOC.LocationType = 'R' then LD.Quantity else 0 end) /* Units AvailableReserve */
    from LPNDetails LD join LPNs L on LD.LPNId = L.LPNId
                       join Locations LOC on (L.LocationId = LOC.LocationId) and
                                             (LOC.LocationType in ('R','B', 'K'))
--                       join OrderDtls OD on (LD.SKUId = OD.SKUId) and (LD.OnhandStatus = 'A' /* Available */) and
--                                            (coalesce(OD.Ownership, '') = coalesce(L.Ownership, '')) and (OD.Warehouse = L.DestWarehouse)
                       /* R- Reserve, B- Bulk, K- Picklane */
    where LD.SKUId in (select distinct SKUId from OrderDtls) and (LD.OnhandStatus = 'A' /* Available */) and
          (((@vBatchType not in ('RU', 'RP', 'R' /* Replenish */)) and (LOC.LocationType in ('R','B', 'K'))) or
           ((@vBatchType in ('RP', 'R')) and (LOC.LocationType in ('R', 'B'))) or
           ((@vBatchType = 'RU') and (LOC.LocationType in ('R', 'B', 'K')) and (LOC.StorageType <> 'U' /* units */)))
    group by LD.SKUId, L.Ownership, L.DestWarehouse
  ),  /* Get LPNs count based on the SKU */
  SKULPNCounts(OrdDetailId, SKUId, LPNsAssigned, UnitsPicked, UnitsPacked, UnitsLabeled, UnitsShipped,
               LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped) as
  (
    select 0,
           LD.SKUId, /* U-Picking, K-Picked, L-Loaded, G-Packing, E-Staged, D-Packed, S-Shipped */
           count(distinct L.LPNId),
           sum(case when (charindex(L.Status, 'UKGDELS') <> 0) then LD.Quantity else 0 end) as UnitsPicked,
           sum(case when (charindex(L.Status, 'DELS' ) <> 0) then LD.Quantity else 0 end) as UnitsPacked,
           sum(case when (charindex(L.Status, 'DELS'  ) <> 0) and
                         ((L.UCCBarcode is not null) or (L.TrackingNo is not null))
                                                              then LD.Quantity else 0 end) as UnitsLabeled,
           sum(case when (charindex(L.Status, 'S'     ) <> 0) then LD.Quantity else 0 end) as UnitsShipped,
           count(distinct (case when (charindex(L.Status, 'KGDELS') <> 0) then L.LPNId else null end)) as LPNsPicked,
           count(distinct (case when (charindex(L.Status, 'GDELS')  <> 0) then L.LPNId else null end)) as LPNsPacked,
           count(distinct (case when (charindex(L.Status, 'DELS')   <> 0) and
                         ((L.UCCBarcode is not null) or (L.TrackingNo is not null))
                                                                          then L.LPNId else null end)) as LPNsLabeled,
           count(distinct (case when (charindex(L.Status, 'S')      <> 0) then L.LPNId else null end)) as LPNsShipped
    from LPNDetails         LD
      join LPNs             L  on (L.LPNId          = LD.LPNId  ) and (LD.OnhandStatus <> 'U') /* and (L.LPNType <> 'A') - if users doesnt want to see Picked in summary while picking, just uncomment this */
      --join PickBatchDetails PB on (PB.OrderDetailId = LD.OrderDetailId)
      --join OrderHeaders     OH on (PB.OrderId       = OH.OrderId)
    where (L.PickBatchId = @vPickBatchId)
    group by LD.SKUId
  )
  /* Insert data into temptable
     LPNs Assigned can be computed based on real count of LPNs, need not be estimated based upon UnitsAssigned */
  insert into @PickBatchInvSummary(BatchNo, Line, ShipToStore, SKUId, CustSKU, CustPO, UnitsOrdered,
                                   UnitsAuthorizedToShip, UnitsAssigned, UnitsPreAllocated, UnitsNeeded, UnitsAvailable,
                                   UnitsAvailablePicklane, UnitsAvailableReserve,
                                   UnitsPicked, UnitsPacked, UnitsLabeled, UnitsShipped, UnitsPerInnerPack,
                                   LPNsOrdered, LPNsToShip, LPNsAssigned, LPNsNeeded,
                                   UnitsPercarton, LPNsAvailable, LPNsShort,
                                   LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped,
                                   SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, Description,
                                   UDF1)
    select  @vPickBatchNo, OD.Line, OD.ShipToStore, OD.SKUId, OD.CustSKU, @vCustPO, OD.UnitsOrdered,
            OD.UnitsAuthorizedToShip, OD.UnitsAssigned, OD.UnitsPreAllocated, OD.UnitsNeeded, coalesce(I.AvailUnits, 0),
            I.UnitsAvailablePicklane, I.UnitsAvailableReserve,
            SC.UnitsPicked, SC.UnitsPacked, SC.UnitsLabeled, SC.UnitsShipped, OD.UnitsPerInnerPack,
            coalesce(OD.LPNsOrdered, 0), coalesce(OD.LPNsToShip, 0),coalesce(SC.LPNsAssigned, 0), OD.LPNsNeeded,
            coalesce(OD.UnitsPercarton, 0), coalesce(I.AvailLPNs, 0),
            case when (OD.LPNsNeeded <= coalesce(I.AvailLPNs, 0)) then 0 else coalesce(OD.LPNsNeeded, 0) - coalesce(I.AvailLPNs, 0) end,
            coalesce(SC.LPNsPicked, 0), coalesce(SC.LPNsPacked, 0), coalesce(SC.LPNsLabeled, 0), coalesce(SC.LPNsShipped, 0),
            S.SKU, S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5, S.UPC, S.Description,
            S.PrimaryLocation
    from OrderDtls OD
    left outer join SKUs         S  on OD.SKUId = S.SKUId
    left outer join Inven        I  on (OD.SKUId = I.SKUId) and
                                       ((@vValidateUnitsPerCarton = 'N') or (S.UoM = 'PP') or (OD.UnitsPerCarton = I.UnitsPerCarton)) and
                                       (coalesce(OD.Ownership, '') = coalesce(I.Ownership, '')) and
                                       (OD.Warehouse = I.Warehouse)
    left outer join SKULPNCounts SC on OD.SKUId = SC.SKUId --and (OD.OrdDetailId = SC.OrdDetailId)
    --where LPNsNeeded > AvailLPNs
    order by S.SKU;

  return;
end /* fn_PickBatches_InventorySummary */

Go
