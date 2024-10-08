/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/13  AY      pr_Waves_GetLabelDataByStyle: print labels by Style/Color/Size (HA-2974)
  2021/03/20  KBB     pr_Waves_GetLabelDataByStyle: Added InvAllocationModel (HA-2365)
  2021/02/24  AY/KBB  pr_Waves_GetLabelDataByStyle: Enhanced to print by Style or Style Color (HA-2045)
  2021/01/05  RV      pr_Waves_GetLabelDataByStyle: Initial revision (HA-1855)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_GetLabelDataByStyle') is not null
  drop Procedure pr_Waves_GetLabelDataByStyle;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_GetLabelDataByStyle: This procedure returns the dataset with required
  fields to print on Style labels for waves
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_GetLabelDataByStyle
  (@WaveId     TRecordId,
   @Operation  TOperation = 'ByStyle')
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vRecordId           TRecordId,

          @vNumOrdersPerWave   TCount,
          @vNumLPNsPerWave     TCount,
          @vInvAllocationModel TDescription,
          @vNumUnitsPerWave    TCount;
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vRecordId         = 0;

  select @vNumOrdersPerWave   = NumOrders,
         @vNumLPNsPerWave     = NumLPNs,
         @vNumUnitsPerWave    = NumUnits,
         @vInvAllocationModel = case when InvAllocationModel = 'SR' /* System Reservation */ then 'System' else 'Manual' end
  from Waves
  where (WaveId = @WaveId);

  /* Get the values to be printed on Wave Label by Style */
  if (@Operation = 'ByStyle')
    select min(WaveNo) WaveNo, min(WaveType) WaveType, @vNumOrdersPerWave NumOrdersPerWave, @vNumLPNsPerWave NumLPNsPerWave,
           @vNumUnitsPerWave NumUnitsPerWave, @vInvAllocationModel InvAllocationModel, min(SalesOrder) SalesOrder, min(PickTicket) PickTicket,
           min(OrderType) OrderType, min(OrderStatus) OrderStatus, min(SoldToId) SoldToId, min(ShipToId) ShipToId,
           min(ShipToStore) ShipToStore, sum(NumLPNs) NumLPNs, min(Warehouse) Warehouse, min(Ownership) Ownership,
           min(Priority) Priority, min(ShipVia) ShipVia, min(CustPO) CustPO, min(CancelDate) CancelDate, min(Account) Account,
           min(AccountName) AccountName, min(HasNotes) HasNotes, min(OrderCategory1) OrderCategory1,
           min(OrderCategory2) OrderCategory2, min(OrderCategory3) OrderCategory3, min(OrderCategory4) OrderCategory4,
           min(OrderCategory5) OrderCategory5, sum(UnitsOrdered) UnitsOrdered, sum(UnitsAuthorizedToShip) UnitsAuthorizedToShip,
           sum(UnitsAssigned) UnitsAssigned, sum(UnitsPreAllocated) UnitsPreAllocated, sum(UnitsShipped) UnitsShipped,
           sum(UnitsToAllocate) UnitsToAllocate, min(UnitsPerCarton) UnitsPerCarton, min(CustSKU) CustSKU, min(PickZone) PickZone,
           min(DestZone) DestZone, min(ODLot) ODLot, min(InventoryClass1) InventoryClass1, min(InventoryClass2) InventoryClass2,
           min(InventoryClass3) InventoryClass3, min(SKU) SKU, min(SKU1) SKU1, min(SKU2) SKU2, min(SKU3) SKU3, min(SKU4) SKU4,
           min(SKU5) SKU5, min(SKUDescription) SKUDescription, min(AlternateSKU) AlternateSKU, min(BarCode) BarCode,
           sum(UnitWeight) UnitWeight, sum(UnitVolume) UnitVolume, min(UoM) UoM, sum(ProductCost) ProductCost,
           min(UnitsPerInnerPack) UnitsPerInnerPack, min(SourceSystem) SourceSystem, min(IsSortable) IsSortable,
           count(distinct SKU2) SKU2Count, count(distinct SKU3) SKU3Count, count(distinct SKU4) SKU4Count, count(distinct SKU5) SKU5Count,
           sum(UnitsAuthorizedToShip) UnitToShipForGroup
    from vwPickBatchDetails PBD
    where (PBD.WaveId = @WaveId)
    group by SKU1 /* CIMS default field for Style */;
  else
  if (@Operation = 'ByStyleColor')
    select min(WaveNo) WaveNo, min(WaveType) WaveType, @vNumOrdersPerWave NumOrdersPerWave, @vNumLPNsPerWave NumLPNsPerWave,
           @vNumUnitsPerWave NumUnitsPerWave, @vInvAllocationModel InvAllocationModel, min(SalesOrder) SalesOrder, min(PickTicket) PickTicket,
           min(OrderType) OrderType, min(OrderStatus) OrderStatus, min(SoldToId) SoldToId, min(ShipToId) ShipToId,
           min(ShipToStore) ShipToStore, sum(NumLPNs) NumLPNs, min(Warehouse) Warehouse, min(Ownership) Ownership,
           min(Priority) Priority, min(ShipVia) ShipVia, min(CustPO) CustPO, min(CancelDate) CancelDate, min(Account) Account,
           min(AccountName) AccountName, min(HasNotes) HasNotes, min(OrderCategory1) OrderCategory1,
           min(OrderCategory2) OrderCategory2, min(OrderCategory3) OrderCategory3, min(OrderCategory4) OrderCategory4,
           min(OrderCategory5) OrderCategory5, sum(UnitsOrdered) UnitsOrdered, sum(UnitsAuthorizedToShip) UnitsAuthorizedToShip,
           sum(UnitsAssigned) UnitsAssigned, sum(UnitsPreAllocated) UnitsPreAllocated, sum(UnitsShipped) UnitsShipped,
           sum(UnitsToAllocate) UnitsToAllocate, min(UnitsPerCarton) UnitsPerCarton, min(CustSKU) CustSKU, min(PickZone) PickZone,
           min(DestZone) DestZone, min(ODLot) ODLot, min(InventoryClass1) InventoryClass1, min(InventoryClass2) InventoryClass2,
           min(InventoryClass3) InventoryClass3, min(SKU) SKU, min(SKU1) SKU1, min(SKU2) SKU2, min(SKU3) SKU3, min(SKU4) SKU4,
           min(SKU5) SKU5, min(SKUDescription) SKUDescription, min(AlternateSKU) AlternateSKU, min(BarCode) BarCode,
           sum(UnitWeight) UnitWeight, sum(UnitVolume) UnitVolume, min(UoM) UoM, sum(ProductCost) ProductCost,
           min(UnitsPerInnerPack) UnitsPerInnerPack, min(SourceSystem) SourceSystem, min(IsSortable) IsSortable,
           count(distinct SKU2) SKU2Count, count(distinct SKU3) SKU3Count, count(distinct SKU4) SKU4Count, count(distinct SKU5) SKU5Count,
           sum(UnitsAuthorizedToShip) UnitToShipForGroup
    from vwPickBatchDetails PBD
    where (PBD.WaveId = @WaveId)
    group by SKU1, SKU2 /* CIMS default field for Style & Color */;
  else
  if (@Operation = 'ByStyleColorSize')
    select min(WaveNo) WaveNo, min(WaveType) WaveType, @vNumOrdersPerWave NumOrdersPerWave, @vNumLPNsPerWave NumLPNsPerWave,
           @vNumUnitsPerWave NumUnitsPerWave, @vInvAllocationModel InvAllocationModel, min(SalesOrder) SalesOrder, min(PickTicket) PickTicket,
           min(OrderType) OrderType, min(OrderStatus) OrderStatus, min(SoldToId) SoldToId, min(ShipToId) ShipToId,
           min(ShipToStore) ShipToStore, sum(NumLPNs) NumLPNs, min(Warehouse) Warehouse, min(Ownership) Ownership,
           min(Priority) Priority, min(ShipVia) ShipVia, min(CustPO) CustPO, min(CancelDate) CancelDate, min(Account) Account,
           min(AccountName) AccountName, min(HasNotes) HasNotes, min(OrderCategory1) OrderCategory1,
           min(OrderCategory2) OrderCategory2, min(OrderCategory3) OrderCategory3, min(OrderCategory4) OrderCategory4,
           min(OrderCategory5) OrderCategory5, sum(UnitsOrdered) UnitsOrdered, sum(UnitsAuthorizedToShip) UnitsAuthorizedToShip,
           sum(UnitsAssigned) UnitsAssigned, sum(UnitsPreAllocated) UnitsPreAllocated, sum(UnitsShipped) UnitsShipped,
           sum(UnitsToAllocate) UnitsToAllocate, min(UnitsPerCarton) UnitsPerCarton, min(CustSKU) CustSKU, min(PickZone) PickZone,
           min(DestZone) DestZone, min(ODLot) ODLot, min(InventoryClass1) InventoryClass1, min(InventoryClass2) InventoryClass2,
           min(InventoryClass3) InventoryClass3, min(SKU) SKU, min(SKU1) SKU1, min(SKU2) SKU2, min(SKU3) SKU3, min(SKU4) SKU4,
           min(SKU5) SKU5, min(SKUDescription) SKUDescription, min(AlternateSKU) AlternateSKU, min(BarCode) BarCode,
           sum(UnitWeight) UnitWeight, sum(UnitVolume) UnitVolume, min(UoM) UoM, sum(ProductCost) ProductCost,
           min(UnitsPerInnerPack) UnitsPerInnerPack, min(SourceSystem) SourceSystem, min(IsSortable) IsSortable,
           count(distinct SKU2) SKU2Count, count(distinct SKU3) SKU3Count, count(distinct SKU4) SKU4Count, count(distinct SKU5) SKU5Count,
           sum(UnitsAuthorizedToShip) UnitToShipForGroup
    from vwPickBatchDetails PBD
    where (PBD.WaveId = @WaveId)
    group by SKU1, SKU2, SKU3 /* CIMS default field for Style, Color & Size */;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_GetLabelDataByStyle */

Go
