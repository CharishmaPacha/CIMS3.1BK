/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/20  VM/KSK  pr_PickBatch_BatchSummary: Added PrimaryLocation and SecondaryLocation (S2G-433)
  2016/07.20  TD      pr_PickBatch_BatchSummary:Changes to correct available quantity in picklane and reserve.
  2016/04/07  SV      pr_PickBatch_BatchSummary, fn_PickBatches_InventorySummary: Changes to the Units avaialble and shorts over the batch summary (SRI-481)
  2015/08/18  OK      pr_PickBatch_BatchSummary, fn_PickBatches_InventorySummary: Migrated from GNC and fixed bugs (FB-311).
  2015/08/04  RV      pr_PickBatch_BatchSummary : Migrated changes from GNC.
  2014/06/14  PKS     fn_PickBatches_InventorySummary: RecordId (Identity Column) added and implemented in pr_PickBatch_BatchSummary
  2014/05/21  PV      pr_PickBatch_BatchSummary: changed fn_PickBatches_BatchSummary to procedure and removed fn_PickBatches_BatchSummary
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_BatchSummary') is not null
  drop Procedure pr_PickBatch_BatchSummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_BatchSummary:  This procedure returns the
    summary for the given PickBatch which is consistent with TPickBatchSummary
    definition.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_BatchSummary
  (@PickBatchNo  TPickBatchNo)
as
  declare @PickBatchInvSummary TPickBatchSummary;

  declare @ReturnCode  TInteger,
          @MessageName TMessageName;
begin
  SET NOCOUNT ON;

  /* Redirect to new procedure */
  exec pr_Wave_GetSummary null, @PickbatchNo;
  return;

  /* LPNs short is not the sum of LPNs short.
     An example: Store 1 ordered 10 units, Store 2 ordered 10 units, in stock 15 units
                 fn_PickBatches_InventorySummary returns the statistics by Store,
                 so neither store is short of inventory as returned by that function
                 however, here we sum them up, we have to recalculate LPNsShort,
                 if we do that, we will be short of 5 units */

  insert into @PickBatchInvSummary (Line, HostOrderLine, OrderDetailId, CustSKU, CustPO, ShipToStore,
                                    SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, Description,
                                    UnitsPerCarton, UnitsPerInnerPack, UnitsOrdered , UnitsAuthorizedToShip,
                                    UnitsAssigned, UnitsNeeded, UnitsAvailable, UnitsShort,
                                    UnitsPicked, UnitsPacked, UnitsLabeled, UnitsShipped,
                                    LPNsOrdered, LPNsToShip, LPNsAssigned, LPNsNeeded,
                                    LPNsAvailable, LPNsShort, LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped,
                                    UDF1, UDF2, UDF3, UDF4, UDF5)
    exec pr_PickBatch_InventorySummary @PickBatchNo;

  select Min(Line)as Line, Min(BatchNo) as BatchNo, Min(HostOrderLine) as HostOrderLine, Min(OrderDetailId) as OrderDetailId, Min(CustSKU) as CustSKU, Min(CustPO) as CustPO, null ShipToStore,  Min(PickLocation) as  PickLocation,
         SKUId as SKUId, SKU as SKU, Min(SKU1) as SKU1,
         Min(SKU2) as SKU2, Min(SKU3) as SKU3, Min(SKU4) as SKU4, Min(SKU5) as SKU5, Min(UPC) as UPC, Min(Description) as Description,
         min(UnitsPerCarton) as UnitsPerCarton, min(UnitsPerInnerPack) as UnitsPerInnerPack,
         sum(UnitsOrdered) as UnitsOrdered, sum(UnitsAuthorizedToShip) as UnitsAuthorizedToShip,
         sum(UnitsPreAllocated) as UnitsPreAllocated, sum(UnitsAssigned) as UnitsAssigned, sum(UnitsAuthorizedToShip) - sum(UnitsAssigned) as UnitsNeeded,
         Min(UnitsAvailable) as UnitsAvailable, min(UnitsAvailable_UPicklane) as UnitsAvailable_UPicklane,
         Min(UnitsAvailable_PPicklane) as UnitsAvailable_PPicklane, Min(UnitsAvailable_Reserve) as UnitsAvailable_Reserve,
         Min(UnitsAvailable_Bulk) as UnitsAvailable_Bulk, Min(UnitsAvailable_RB) as UnitsAvailable_RB, Min(UnitsAvailable_Other) as UnitsAvailable_Other,
         Min(UnitsShort_UPicklane) as UnitsShort_UPicklane, Min(UnitsShort_PPicklane) as UnitsShort_PPicklane, Min(UnitsShort_Other) as UnitsShort_Other,
         Min(UnitsShort) as UnitsShort, Min(CasesAvailable) as CasesAvailable, Min(CasesAvailable_PPicklane) as CasesAvailable_PPicklane,
         Min(CasesAvailable_Reserve) as CasesAvailable_Reserve, Min(CasesAvailable_Bulk) as CasesAvailable_Bulk, Min(CasesAvailable_RB) as CasesAvailable_RB,
         Min(CasesAvailable_Other) as CasesAvailable_Other, Min(CasesShort_PPicklane) as CasesShort_PPicklane, Min(CasesShort_Other) as CasesShort_Other,
         Min(CasesShort) as CasesShort, Min(UnitsPicked) as UnitsPicked, Min(UnitsPacked) as UnitsPacked, Min(UnitsLabeled) as UnitsLabeled,
         Min(UnitsShipped) as UnitsShipped, Min(CasesOrdered) as CasesOrdered, Min(CasesToShip) as CasesToShip, Min(CasesPreAllocated) as CasesPreAllocated,
         Min(CasesAssigned) as CasesAssigned, Min(CasesNeeded) as CasesNeeded, Min(CasesPicked) as CasesPicked, Min(CasesPacked) as CasesPacked,
         Min(CasesLabeled) as CasesLabeled, Min(CasesStaged) as CasesStaged, Min(CasesLoaded) as CasesLoaded, Min(CasesShipped) as CasesShipped,
         Min(LPNsOrdered) as LPNsOrdered, Min(LPNsToShip) as LPNsToShip, Min(LPNsAssigned) as LPNsAssigned,
         Min(LPNsNeeded) as LPNsNeeded, min(LPNsAvailable) as LPNsAvailable,
         case when (Min(LPNsNeeded) <= min(LPNsAvailable)) then 0 else Min(LPNsNeeded) - Min(LPNsAvailable) end as LPNsShort,
         Min(LPNsPicked) as LPNsPicked, Min(LPNsPacked) as LPNsPacked,
         Min(LPNsLabeled) as LPNsLabeled, Min(LPNsStaged) as LPNsStaged, Min(LPNsLoaded) as LPNsLoaded, Min(LPNsShipped) as LPNsShipped,
         Min(PrimaryLocation) as PrimaryLocation, Min(SecondaryLocation) as SecondaryLocation,
         Min(UDF1) as UDF1, cast('' as varchar(50)) as UDF2, cast('' as varchar(50)) as UDF3,
         cast('' as varchar(50)) as UDF4, cast('' as varchar(50)) as UDF5, cast('' as varchar(50)) as UDF6, cast('' as varchar(50)) as UDF7,
         cast('' as varchar(50)) as UDF8, cast('' as varchar(50)) as UDF9, cast('' as varchar(50)) as UDF10,
         Min(RecordId) as RecordId
   from @PickBatchInvSummary
   group by SKUId, SKU;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_BatchSummary */

Go
