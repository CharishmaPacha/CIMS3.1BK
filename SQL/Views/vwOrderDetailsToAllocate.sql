/*------------------------------------------------------------------------------
  Revision History:

  Date        Person  Comments

  2018/05/31  YJ      Added case statement to update ShipPack (S2G-727)
  2017/10/05  VM      Include remaining order UDFs (OB-617)
  2015/07/01  TK      Changes UDF -> OD_UDF
  2015/04/08  AY      Do not select Shipped/Canceled/Completed Orders
  2014/09/26  TK      Added IsSortable field.
  2012/08/23  DP      Listed all the fields instead of *
  2010/12/26  AY      Moved UnitsToAllocate to vwOrderDetails as it would need
                        to be shown in UI as well. Added condition to only show
                        allocable lines
  2010/11/25  NB      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOrderDetailsToAllocate') is not null
  drop View dbo.vwOrderDetailsToAllocate;
Go


Create View dbo.vwOrderDetailsToAllocate (
  OrderDetailId,
  OrderLine,

  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  Status,
  StatusDescription,

  OrderDate,
  DesiredShipDate,

  CancelDate,
  DateShipped,

  Priority,
  DestZone,

  SoldToId,
  ShipToId,
  PickBatchNo,
  ShipVia,
  ShipFrom,
  CustPO,
  Ownership,
  Warehouse,
  PickBatchGroup,

  NumLines,
  NumSKUs,
  NumUnits,
  TotalUnitsAssigned,
  NumLPNs,

  TotalSalesAmount,
  TotalTax,
  TotalShippingCost,
  TotalDiscount,

  ShortPick,

  OH_UDF1,
  OH_UDF2,
  OH_UDF3,
  OH_UDF4,
  OH_UDF5,
  OH_UDF6,
  OH_UDF7,
  OH_UDF8,
  OH_UDF9,
  OH_UDF10,

  HostOrderLine,
  LineType,
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  SKUDesc,
  UPC,
  UnitsPerInnerPack,
  IsSortable,

  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsShipped,
  UnitsToAllocate,
  RetailUnitPrice,
  UnitSalePrice,
  UnitDiscount,
  ResidualDiscount,
  UnitTaxAmount,

  Lot,
  CustSKU,

  LocationId,  /* Used for replenishments */
  Location,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,
  UDF6,
  UDF7,
  UDF8,
  UDF9,
  UDF10,
  UDF11,
  UDF12,
  UDF13,
  UDF14,
  UDF15,
  UDF16,
  UDF17,
  UDF18,
  UDF19,
  UDF20,

  SKUUDF1,
  SKUUDF2,
  SKUUDF3,
  SKUUDF4,
  SKUUDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  OD.OrderDetailId,
  OD.OrderLine,

  OD.OrderId,
  OD.PickTicket,
  OD.SalesOrder,
  OD.OrderType,
  OD.OrderTypeDescription,
  OD.Status,
  OD.StatusDescription,

  OD.OrderDate,
  OD.DesiredShipDate,

  OD.CancelDate,
  OD.DateShipped,

  OD.Priority,
  OD.DestZone,

  OD.SoldToId,
  OD.ShipToId,
  OD.PickBatchNo,
  OD.ShipVia,
  OD.ShipFrom,
  OD.CustPO,
  OD.Ownership,
  OD.Warehouse,
  OD.PickBatchGroup,

  OD.NumLines,
  OD.NumSKUs,
  OD.NumUnits,
  OD.TotalUnitsAssigned,
  OD.NumLPNs,

  OD.TotalSalesAmount,
  OD.TotalTax,
  OD.TotalShippingCost,
  OD.TotalDiscount,

  OD.ShortPick,

  OD.OH_UDF1,
  OD.OH_UDF2,
  OD.OH_UDF3,
  OD.OH_UDF4,
  OD.OH_UDF5,
  OD.OH_UDF6,
  OD.OH_UDF7,
  OD.OH_UDF8,
  OD.OH_UDF9,
  OD.OH_UDF10,

  OD.HostOrderLine,
  OD.LineType,
  OD.SKUId,
  OD.SKU,
  OD.SKU1,
  OD.SKU2,
  OD.SKU3,
  OD.SKU4,
  OD.SKU5,
  OD.SKUDesc,
  OD.UPC,
  OD.UnitsPerInnerPack,
  OD.IsSortable,

  OD.UnitsOrdered,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  OD.UnitsShipped,
  case when OD.ShipPack > 0 then OD.UnitsToAllocate / OD.ShipPack * OD.ShipPack else OD.UnitsToAllocate end,
  OD.RetailUnitPrice,
  OD.UnitSalePrice,
  OD.UnitDiscount,
  OD.ResidualDiscount,
  OD.UnitTaxAmount,

  OD.Lot,
  OD.CustSKU,

  OD.LocationId,  /* Used for replenishments */
  OD.Location,

  OD.OD_UDF1,
  OD.OD_UDF2,
  OD.OD_UDF3,
  OD.OD_UDF4,
  OD.OD_UDF5,
  OD.OD_UDF6,
  OD.OD_UDF7,
  OD.OD_UDF8,
  OD.OD_UDF9,
  OD.OD_UDF10,
  OD.OD_UDF11,
  OD.OD_UDF12,
  OD.OD_UDF13,
  OD.OD_UDF14,
  OD.OD_UDF15,
  OD.OD_UDF16,
  OD.OD_UDF17,
  OD.OD_UDF18,
  OD.OD_UDF19,
  OD.OD_UDF20,

  OD.SKUUDF1,
  OD.SKUUDF2,
  OD.SKUUDF3,
  OD.SKUUDF4,
  OD.SKUUDF5,

  OD.BusinessUnit,
  OD.CreatedDate,
  OD.ModifiedDate,
  OD.CreatedBy,
  OD.ModifiedBy
from vwOrderDetails OD
  where (UnitsToAllocate > 0) and
        (Status not in ('S', 'X', 'D' /* Shipped, Canceled, Completed */));

Go
