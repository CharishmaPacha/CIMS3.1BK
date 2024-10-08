/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/10/06  CK      Include remaining order UDFs (OB-617)
  2010/11/10  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwCurrentOrderDetails') is not null
  drop View dbo.vwCurrentOrderDetails;
Go

Create View dbo.vwCurrentOrderDetails (
  OrderDetailId,
  OrderLine,

  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  Status,
  StatusDescription,
  StatusSortSeq,

  OrderDate,
  DesiredShipDate,

  Priority,

  SoldToId,
  ShipToId,
  PickBatchNo,
  ShipVia,
  ShipFrom,
  CustPO,
  Ownership,

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
  OH_UDF11,
  OH_UDF12,
  OH_UDF13,
  OH_UDF14,
  OH_UDF15,
  OH_UDF16,
  OH_UDF17,
  OH_UDF18,
  OH_UDF19,
  OH_UDF20,
  OH_UDF21,
  OH_UDF22,
  OH_UDF23,
  OH_UDF24,
  OH_UDF25,
  OH_UDF26,
  OH_UDF27,
  OH_UDF28,
  OH_UDF29,
  OH_UDF30,

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

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  OD.OrderDetailId,
  OD.OrderLine,

  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OH.Status,
  S.StatusDescription,
  cast(S.SortSeq as varchar) + '-' + S.StatusDescription,

  OH.OrderDate,
  OH.DesiredShipDate,

  OH.Priority,

  OH.SoldToId,
  OH.ShipToId,
  OH.PickBatchNo,
  OH.ShipVia,
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,

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
  OH.UDF11,
  OH.UDF12,
  OH.UDF13,
  OH.UDF14,
  OH.UDF15,
  OH.UDF16,
  OH.UDF17,
  OH.UDF18,
  OH.UDF19,
  OH.UDF20,
  OH.UDF21,
  OH.UDF22,
  OH.UDF23,
  OH.UDF24,
  OH.UDF25,
  OH.UDF26,
  OH.UDF27,
  OH.UDF28,
  OH.UDF29,
  OH.UDF30,

  OD.HostOrderLine,
  OD.LineType,
  OD.SKUId,
  SKU.SKU,
  SKU.SKU1,
  SKU.SKU2,
  SKU.SKU3,
  SKU.SKU4,
  SKU.SKU5,
  SKU.Description,

  OD.UnitsOrdered,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  OD.UnitsShipped,
  OD.UnitsToAllocate,
  OD.RetailUnitPrice,
  OD.UnitSalePrice,
  /* Discount per unit */
  cast(round(OD.UnitSalePrice / OD.UnitsAuthorizedToship, 2) as money),
  /* Residual Discount */
  OD.UnitSalePrice - cast(round(OD.UnitSalePrice / OD.UnitsAuthorizedToship, 2) as money) * OD.UnitsAuthorizedToShip as money,
  OD.UnitTaxAmount,

  OD.Lot,
  OD.CustSKU,

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
  OD.UDF11,
  OD.UDF12,
  OD.UDF13,
  OD.UDF14,
  OD.UDF15,
  OD.UDF16,
  OD.UDF17,
  OD.UDF18,
  OD.UDF19,
  OD.UDF20,

  SKU.UDF1,
  SKU.UDF2,
  SKU.UDF3,
  SKU.UDF4,
  SKU.UDF5,

  OH.Archived,
  OD.BusinessUnit,
  OD.CreatedDate,
  OD.ModifiedDate,
  OD.CreatedBy,
  OD.ModifiedBy
from
  OrderDetails OD
  left outer join OrderHeaders OH   on (OD.OrderId      = OH.OrderId      )
  left outer join SKUs         SKU  on (OD.SKUId        = SKU.SKUId       )
  left outer join EntityTypes  ET   on (ET.TypeCode     = OH.OrderType    ) and
                                       (ET.Entity       = 'Order'         ) and
                                       (ET.BusinessUnit = OD.BusinessUnit )
  left outer join Statuses     S    on (S.StatusCode    = OH.Status       ) and
                                       (S.Entity        = 'Order'         ) and
                                       (S.BusinessUnit  = OD.BusinessUnit )
where (OH.Archived = 'N') and (OH.OrderType = 'E');

Go
