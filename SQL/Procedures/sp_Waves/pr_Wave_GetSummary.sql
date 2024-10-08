/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/28  VS      pr_Wave_GetSummary, pr_Wave_InventorySummary: Show UnitsRequiredtoActivate for Activate remainig ShipCartons (HA-2714)
  2021/04/23  RV      pr_Wave_GetSummary: Show wave summary by label code
  2020/06/19  NB      pr_Wave_GetSummary: changes to Temp Table Name(CIMSV3-817)
  2020/05/24  NB      pr_Wave_GetSummary: changes to verify SaveToTempTable input param and return data to caller(HA-101)
  2018/03/30  AY      pr_Wave_InventorySummary, pr_Wave_GetSummary: New versions of existing procs
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_GetSummary') is not null
  drop Procedure pr_Wave_GetSummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_GetSummary:  This procedure returns the
    summary for the given PickBatch which is consistent with TWaveSummary
    definition.

   SaveToTempTable indicates whether to just capture data to temp table or capture and return data

   null or N - procedure returns the data captured
   Y         - procedure only captures the data to temp table. In this case, the temp table is mostly
               created by caller
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_GetSummary
  (@WaveId           TRecordId,
   @WaveNo           TWaveNo,
   @SaveToTempTable  TFlag = null)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName;

  declare @ttWaveSummary TWaveSummary;
begin
  SET NOCOUNT ON;

  /* Create Temp Table */
  select * into #WaveSummary from @ttWaveSummary;

  /* LPNs short is not the sum of LPNs short.
     An example: Store 1 ordered 10 units, Store 2 ordered 10 units, in stock 15 units
                 fn_PickBatches_InventorySummary returns the statistics by Store,
                 so neither store is short of inventory as returned by that function
                 however, here we sum them up, we have to recalculate LPNsShort,
                 if we do that, we will be short of 5 units */

  /* Inserts data into #WaveSummary */
  exec pr_Wave_InventorySummary @WaveId, @WaveNo;

  /* Create Temp Table, if not already created by caller */
  if (object_id('tempdb..#ResultDataSet') is null)
    select * into #ResultDataSet from @ttWaveSummary;

  /* Capture output for WaveSummary */
  insert into #ResultDataSet
  select Min(WaveNo) as WaveNo, Min(HostOrderLine) as HostOrderLine, Min(OrderDetailId) as OrderDetailId, Min(CustSKU) as CustSKU, Min(CustPO) as CustPO, null ShipToStore,  Min(PickLocation) as  PickLocation,
         Min(Ownership) as Ownership, Min(Warehouse) as Warehouse,
         min(SKUId) as SKUId, min(SKU) as SKU, Min(SKU1) as SKU1,
         Min(SKU2) as SKU2, Min(SKU3) as SKU3, Min(SKU4) as SKU4, Min(SKU5) as SKU5, Min(UPC) as UPC, Min(Description) as Description,
         min(NewSKU) as NewSKU, min(InventoryClass1) as InventoryClass1, min(InventoryClass2) as InventoryClass2, min(InventoryClass3) as InventoryClass3,
         min(NewInventoryClass1) as NewInventoryClass1, min(NewInventoryClass2) as NewInventoryClass2, min(NewInventoryClass3) as NewInventoryClass3, min(Notification) as Notification,
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
         Min(UnitsReservedForWave), Min(ToActivateShipCartonQty), Min(UnitsRequiredtoActivate),
         Min(UDF1) as UDF1, Min(UDF2) as UDF2, Min(UDF3) as UDF3, Min(UDF4) as UDF4, Min(UDF5) as UDF5,
         Min(UDF6) as UDF6, Min(UDF7) as UDF7, Min(UDF8) as UDF8, Min(UDF9) as UDF9, Min(UDF10) as UDF10,
         Min(RecordId) as RecordId, Min(KeyValue)
   from #WaveSummary
   group by KeyValue;

   /* Verify whether the caller requested to only capture the data
      There are instance when the caller will create the # table and access the data through the # table
      in such instances, do not run this select */
   if (coalesce(@SaveToTempTable, 'N') = 'N')
     select * from #ResultDataSet;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Wave_GetSummary */

Go
