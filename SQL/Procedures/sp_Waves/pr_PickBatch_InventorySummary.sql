/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/10/30  RV      fn_PickBatches_InventorySummary : Exclude the Replenish inventory (FB-474)
                      pr_PickBatch_InventorySummary: Exclude the Replenish inventory (FB-474)
  2015/08/04  RV      pr_PickBatch_BatchSummary : Migrated changes from GNC.
                      pr_PickBatch_InventorySummary : Added from GNC (FB-272).
                      pr_PickBatch_InventorySummary: Changed Batch Summary to show Warehouse related inventory only
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_InventorySummary') is not null
  drop Procedure pr_PickBatch_InventorySummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatches_InventorySummary:  This Function will returns the inventory
    summary for the given PickBatch
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_InventorySummary
  (@PickBatchNo  TPickBatchNo)
as
  declare @PickBatchInvSummary TPickBatchSummary;

  declare @ttOrderDtls table
    (Line                  THostOrderLine,
     HostOrderLine         THostOrderLine,
     OrderDetailId         TRecordId,
     ShipToStore           TShipToStore,
     SKUId                 TRecordId,
     CustSKU               TCustSKU,
     UnitsOrdered          TQuantity,
     UnitsAuthorizedToShip TQuantity,
     UnitsAssigned         TQuantity,
     UnitsNeeded           TQuantity,
     UnitsPerInnerPack     TInteger,
     LPNsOrdered           TCount,
     LPNsToShip            TCount,
     LPNsAssigned          TCount,
     LPNsNeeded            TCount,
     UnitsPerCarton        TCount,
     Warehouse             TWarehouse,
     Ownership             TOwnership,
     UDF1                  TUDF,
     UDF2                  TUDF,
     UDF3                  TUDF,
     UDF4                  TUDF,
     UDF5                  TUDF,
     SKU                   TSKU,
     SKU1                  TSKU,
     SKU2                  TSKU,
     SKU3                  TSKU,
     SKU4                  TSKU,
     SKU5                  TSKU,
     UPC                   TUPC,
     Description           TDescription,
     RecordId              TRecordid Identity(1,1),
     Primary Key           (RecordId));

  declare @ttAvailInventory table
    (SKUId          TRecordId,
     UnitsPerCarton TInteger,
     AvailLPNs      TCount,
     AvailIPs       TCount,
     AvailUnits     TCount
     Primary Key    (SKUId));

  declare @ttSKULPNCounts table
    (OrderDetailId TRecordId,
     SKUId       TRecordId,
     LPNsAssigned TCount,
     UnitsPicked  TCount,
     UnitsPacked  TCount,
     UnitsLabeled TCount,
     UnitsShipped TCount,
     LPNsPicked   TCount,
     LPNsPacked   TCount,
     LPNsLabeled  TCount,
     LPNsShipped  TCount,
     Warehouse    TWarehouse,
     Ownership    TOwnership,
     Primary Key (OrderDetailId, SKUId));

  declare @vBusinessUnit           TBusinessUnit,
          @vValidateUnitsPerCarton TFlag,
          @vPickBatchId            TRecordId,
          @vCustPO                 TCustPO,
          @vCount                  TCount,
          @vBatchType              TTypeCode,

          @MessageName             TMessageName,
          @ReturnCode              TInteger;

begin /* pr_PickBatches_InventorySummary */
  /* Get the CustPO and Business Unit from the Batch */
  select @vPickBatchId  = RecordId,
         @vCustPO       = UDF1,
         @vBusinessUnit = BusinessUnit,
         @vBatchType    = BatchType
  from PickBatches
  where (BatchNo = @PickBatchNo);

  /* Get the control variable to validate if the LPN Quantity is not equal to the UnitsPerCarton on Order */
  select @vValidateUnitsPerCarton  = dbo.fn_Controls_GetAsBoolean('Picking', 'ValidateUnitsperCarton', 'Y' /* Yes */, @vBusinessUnit, null /* UserId */);

  /* select all the info from orderdetails based on the PickBatchno */
  insert into @ttOrderDtls (SKUId, CustSKU, UnitsOrdered,
                  UnitsAuthorizedToShip, UnitsAssigned, UnitsNeeded, UnitsPerInnerPack,
                  SKU, Warehouse, Ownership)
   select OD.SKUId, OD.CustSKU,
           sum(case when OH.OrderType <> 'B' then OD.UnitsOrdered else 0 end),
           sum(case when OH.OrderType <> 'B' then OD.UnitsAuthorizedToShip else 0 end),
           sum(case when @vBatchType like 'ECOM-S' and OH.OrderType = 'B' then 0 else dbo.fn_MaxInt(OD.UnitsAssigned, 0) end),
           sum(case when OH.OrderType <> 'B' then OD.UnitsToAllocate else 0 end),
           Min(S.UnitsPerInnerPack),
           S.SKU, OH.Warehouse, OH.Ownership
    from OrderDetails OD
         join PickBatchDetails PBD on (PBD.OrderDetailId = OD.OrderDetailId)
         join OrderHeaders     OH  on (OD.OrderId        = OH.OrderId)
         join SKUs             S   on (OD.SKUId          = S.SKUId)
    where (PBD.PickBatchNo = @PickBatchNo) and
          (OH.Status       <> 'H' /* hold */)
    group by OD.SKUId, OD.CustSKU, S.SKU, OH.Warehouse, OH.Ownership

  /* select LPN Inventory from the lpndetails based on the SKU */
  insert into @ttAvailInventory (SKUId, UnitsPerCarton, AvailLPNs, AvailIPs, AvailUnits)
    select LD.SKUId, Max(LD.UnitsPerPackage), count(distinct LD.LPNId), sum(LD.InnerPacks), sum(LD.Quantity)
    from LPNDetails LD join LPNs L on LD.LPNId = L.LPNId
                       join Locations LOC on (L.LocationId = LOC.LocationId)-- and
                                          -- (LOC.LocationType in ('R','B', 'K'))
                       join @ttOrderDtls OD on (LD.SKUId = OD.SKUId) and (OD.Warehouse = L.DestWarehouse) and
                                               ( OD.Ownership = L.Ownership) and LD.OnhandStatus = 'A'
                       /* R- Reserve, B- Bulk, K- Picklane */
    where --LD.SKUId in (select distinct SKUId from @PickBatchInvSummary) and (LD.OnhandStatus = 'A' /* Available */) and
          (((@vBatchType not in ('RU', 'RP', 'R' /* Replenish */)) and (LOC.LocationType in ('R','B', 'K'))) or
           ((@vBatchType in ('RP', 'R')) and (LOC.LocationType in ('R', 'B'))) or
           ((@vBatchType = 'RU') and (LOC.LocationType in ('R', 'B', 'K')) and (LOC.StorageType <> 'U' /* units */)))
    group by LD.SKUId

  /* Get LPNs count based on the SKU */
  insert into @ttSKULPNCounts(OrderDetailId, SKUId, LPNsAssigned, UnitsPicked, UnitsPacked, UnitsLabeled, UnitsShipped,
               LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped, Warehouse, Ownership)
    select 0,
           LD.SKUId, /* U-Picking, K-Picked, L-Loaded, G-Packing, E-Staged, D-Packed, S-Shipped */
           count(distinct L.LPNId),
           sum(case when (charindex(L.Status, 'UKGDELS') <> 0) and (LD.OnhandStatus <> 'U') then LD.Quantity else 0 end) as UnitsPicked,
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
           count(distinct (case when (charindex(L.Status, 'S')      <> 0) then L.LPNId else null end)) as LPNsShipped,
           L.DestWarehouse, L.Ownership
    from LPNDetails         LD
      join LPNs             L  on (L.LPNId          = LD.LPNId  )
    where (L.PickBatchId = @vPickBatchId)
    group by LD.SKUId, L.DestWarehouse, L.Ownership;

  /* Insert data into temptable
     LPNs Assigned can be computed based on real count of LPNs, need not be estimated based upon UnitsAssigned */
  insert into @PickBatchInvSummary(Line, HostOrderLine, OrderDetailId, CustSKU, CustPO, ShipToStore,
                                   SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, Description,
                                   UnitsPerCarton, UnitsPerInnerPack, UnitsOrdered, UnitsAuthorizedToShip,
                                   UnitsAssigned, UnitsNeeded, UnitsAvailable,
                                   UnitsPicked, UnitsPacked, UnitsLabeled, UnitsShipped,
                                   LPNsOrdered, LPNsToShip, LPNsAssigned, LPNsNeeded,
                                   LPNsAvailable, LPNsShort, LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped)
    select OD.Line, OD.HostOrderLine, OD.OrderDetailId, OD.CustSKU, @vCustPO, ShipToStore,
           OD.SKUId, S.SKU, S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5, S.UPC, S.Description,
           coalesce(OD.UnitsPerCarton, 0), OD.UnitsPerInnerPack, OD.UnitsOrdered, OD.UnitsAuthorizedToShip,
           OD.UnitsAssigned, OD.UnitsNeeded, coalesce(I.AvailUnits, 0),
           SC.UnitsPicked, SC.UnitsPacked, SC.UnitsLabeled, SC.UnitsShipped,
           coalesce(OD.LPNsOrdered, 0), coalesce(OD.LPNsToShip, 0),coalesce(SC.LPNsAssigned, 0), OD.LPNsNeeded,
           coalesce(I.AvailLPNs, 0), case when (OD.LPNsNeeded <= coalesce(I.AvailLPNs, 0)) then 0 else coalesce(OD.LPNsNeeded, 0) - coalesce(I.AvailLPNs, 0) end,
           coalesce(SC.LPNsPicked, 0), coalesce(SC.LPNsPacked, 0), coalesce(SC.LPNsLabeled, 0), coalesce(SC.LPNsShipped, 0)
    from @ttOrderDtls OD
    left outer join SKUs              S  on OD.SKUId = S.SKUId
    left outer join @ttAvailInventory I  on OD.SKUId = I.SKUId and ((@vValidateUnitsPerCarton = 'N') or (S.UoM = 'PP') or (OD.UnitsPerCarton = I.UnitsPerCarton))
    left outer join @ttSKULPNCounts   SC on OD.SKUId = SC.SKUId and (OD.Warehouse = SC.Warehouse) and (OD.Ownership = SC.Ownership) --and (OD.OrderDetailId = SC.OrderDetailId)
    --where LPNsNeeded > AvailLPNs
    order by S.SKU;

    /* Returning Inventory Summary Dataset */
  select coalesce(Line, ''), coalesce(HostOrderLine, ''), coalesce(OrderDetailId, 0), CustSKU, CustPO, ShipToStore,
         SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, Description,
         UnitsPerCarton, UnitsPerInnerPack, UnitsOrdered , UnitsAuthorizedToShip,
         UnitsAssigned, UnitsNeeded, UnitsAvailable, UnitsShort,
         coalesce(UnitsPicked, 0), coalesce(UnitsPacked, 0), coalesce(UnitsLabeled, 0), coalesce(UnitsShipped, 0),
         LPNsOrdered, LPNsToShip, LPNsAssigned, coalesce(LPNsNeeded, 0),
         LPNsAvailable, LPNsShort, LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped,
         UDF1, UDF2, UDF3, UDF4, UDF5
  from @PickBatchInvSummary;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));

end /* pr_PickBatch_InventorySummary */

Go
