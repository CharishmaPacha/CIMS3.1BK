/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/05/09  KL      Corrected the positions of ShortPick, Archived (HPI-1502)
  2017/05/26  LRA/VM  Added view UDFs - vwBOD_* (CIMS-1093)
  2016/09/08  YJ      Added field UnitsPreAllocated (HPI-585)
  2014/05/05  PK      Excluding Bulk Order information.
  2013/12/19  NY      Added OrderCategories.
  2103/10/04  TD      Calculate LPNsAssigned as UnitsAssigned / UnitsPerInnerPack.
  2013/09/17  NY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBatchOrderDetails') is not null
  drop View dbo.vwBatchOrderDetails;
Go

Create View dbo.vwBatchOrderDetails (
  PickBatchId,
  OrderDetailId,
  OrderLine,

  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  Status,
  ExchangeStatus,
  StatusDescription,

  OrderDate,
  CancelDate,
  DesiredShipDate,
  DateShipped,

  Priority,

  SoldToId,
  ShipToId,
  ShipToStore,
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
  LPNsAssigned,
  TotalUnitsAssigned,
  NumLPNs,

  TotalSalesAmount,
  TotalTax,
  TotalShippingCost,
  TotalDiscount,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

  ShortPick,
  Archived,

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
  UoM,
  ProductCost,
  UnitsPerInnerPack,

  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsPreAllocated,
  UnitsShipped,
  UnitsToAllocate,
  RetailUnitPrice,
  UnitSalePrice,
  UnitsPerCarton,
  UnitDiscount,
  ResidualDiscount,
  UnitTaxAmount,

  Lot,
  CustSKU,

  LocationId,  /* Used for replenishments */
  Location,

  OD_UDF1,
  OD_UDF2,
  OD_UDF3,
  OD_UDF4,
  OD_UDF5,
  OD_UDF6,
  OD_UDF7,
  OD_UDF8,
  OD_UDF9,
  OD_UDF10,

  BOD_UDF1,
  BOD_UDF2,
  BOD_UDF3,
  BOD_UDF4,
  BOD_UDF5,
  BOD_UDF6,
  BOD_UDF7,
  BOD_UDF8,
  BOD_UDF9,
  BOD_UDF10,

  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,
  SKU_UDF5,

  vwBOD_UDF1,
  vwBOD_UDF2,
  vwBOD_UDF3,
  vwBOD_UDF4,
  vwBOD_UDF5,
  vwBOD_UDF6,
  vwBOD_UDF7,
  vwBOD_UDF8,
  vwBOD_UDF9,
  vwBOD_UDF10,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  BD.PickBatchId,
  OD.OrderDetailId,
  OD.OrderLine,

  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OT.TypeDescription,
  OH.Status,
  OH.ExchangeStatus,
  OS.StatusDescription,

  cast(OH.OrderDate as Date),
  cast(OH.Canceldate as Date),
  cast(OH.DesiredShipDate as Date),
  case when OH.Status in ('S' /* Shipped */, 'D' /* Completed */) then
    cast(OH.ModifiedDate as Date)
  else
    null
  end,
  OH.Priority,

  OH.SoldToId,
  OH.ShipToId,
  OH.ShipToStore,
  BD.PickBatchNo,
  OH.ShipVia,
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,
  OH.Warehouse,
  OH.PickBatchGroup,

  OH.NumLines,
  OH.NumSKUs,
  OH.NumUnits,
  case when OH.OrderType <> 'B' and coalesce(S.UnitsPerInnerPack, 0) > 0 then OD.UnitsAssigned / S.UnitsPerInnerPack
       when OH.OrderType <> 'B' then OD.UnitsAssigned
       else 0
  end,
  OH.UnitsAssigned,
  case when OH.OrderType <> 'B' and coalesce(S.UnitsPerInnerPack, 0) > 0 then OD.UnitsAuthorizedToShip / S.UnitsPerInnerPack
       when OH.OrderType <> 'B' then OD.UnitsAuthorizedToShip
       else 0
  end,

  OH.TotalSalesAmount,
  OH.TotalTax,
  OH.TotalShippingCost,
  OH.TotalDiscount,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

  OH.ShortPick,
  OH.Archived,
  
  OH.UDF1,
  OH.UDF2,
  OH.UDF3,
  OH.UDF4,
  OH.UDF5,
  OH.UDF6,
  OH.UDF7,
  OH.UDF8,
  OH.UDF9,
  OH.UDF10,

  OD.HostOrderLine,
  OD.LineType,
  OD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.Description,
  S.UPC,
  S.UoM,
  S.UnitPrice,
  S.UnitsPerInnerPack,

  case when OH.OrderType <> 'B' then OD.UnitsOrdered else 0 end,
  case when OH.OrderType <> 'B' then OD.UnitsAuthorizedToShip else 0 end,
  OD.UnitsAssigned,
  OD.UnitsPreAllocated,
  OD.UnitsShipped,
  case when OH.OrderType <> 'B' then OD.UnitsToAllocate else 0 end,
  OD.RetailUnitPrice,
  OD.UnitSalePrice,
  OD.UnitsPerCarton,
  /* Discount per unit */
  0.0,
  /* Residual Discount */
  0.0,
  OD.UnitTaxAmount,

  OD.Lot,
  OD.CustSKU,

  OD.LocationId,
  OD.Location,

  OD.UDF1,
  OD.UDF2,
  OD.UDF3,
  OD.UDF4,
  OD.UDF5,
  OD.UDF6,
  OD.UDF7,
  OD.UDF8,
  OD.UDF9,
  OD.UDF10,

  BD.UDF1,
  BD.UDF2,
  BD.UDF3,
  BD.UDF4,
  BD.UDF5,
  BD.UDF6,
  BD.UDF7,
  BD.UDF8,
  BD.UDF9,
  BD.UDF10,

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,

  cast(' ' as varchar(50)), /* vwBOD_UDF1  */
  cast(' ' as varchar(50)), /* vwBOD_UDF2  */
  cast(' ' as varchar(50)), /* vwBOD_UDF3  */
  cast(' ' as varchar(50)), /* vwBOD_UDF4  */
  cast(' ' as varchar(50)), /* vwBOD_UDF5  */
  cast(' ' as varchar(50)), /* vwBOD_UDF6  */
  cast(' ' as varchar(50)), /* vwBOD_UDF7  */
  cast(' ' as varchar(50)), /* vwBOD_UDF8  */
  cast(' ' as varchar(50)), /* vwBOD_UDF9  */
  cast(' ' as varchar(50)), /* vwBOD_UDF10 */

  OD.BusinessUnit,
  OD.CreatedDate,
  OD.ModifiedDate,
  OD.CreatedBy,
  OD.ModifiedBy
from
 OrderDetails OD
             join PickBatchDetails BD  on (OD.OrderDetailId = BD.OrderDetailId)
  left outer join OrderHeaders     OH  on (OH.OrderId       = OD.OrderId      )
  left outer join SKUs              S  on (OD.SKUId         = S.SKUId         )
  left outer join EntityTypes      OT  on (OT.TypeCode      = OH.OrderType    ) and
                                          (OT.Entity        = 'Order'         ) and
                                          (OT.BusinessUnit  = OD.BusinessUnit )
  left outer join Statuses         OS  on (OS.StatusCode    = OH.Status       ) and
                                          (OS.Entity        = 'Order'         ) and
                                          (OS.BusinessUnit  = OD.BusinessUnit )

Go
