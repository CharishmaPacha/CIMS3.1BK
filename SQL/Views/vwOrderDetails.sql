/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/25  PKK     Added PrepackCode (HA-2840)
  2020/09/03  RV      Added InventoryUoM (HA-1239)
  2020/05/18  MS      Added WaveGroup, WaveId & WaveNo (HA-593)
  2020/05/15  TK      Added NewSKU & NewInventoryClasses (HA-543)
  2020/05/02  MS      Added OrderStatus, OrderStatusDesc (HA-293)
  2020/03/30  MS      Added InventoryClasses (HA-83)
  2019/12/25  AY      Added SoldToName, Account, AccountName
  2019/05/14  RV      Added Serialized field (S2GCA-651)
  2016/10/25  MS      Added OD_UDFs (HPI-2050)
  2018/10/25  MS      Added OD_UDFs (HPI-2050)
  2018/09/18  MS      Added StatusGroup Field (OB2-606)
  2018/08/14  KSK     Added LineValue field (OB2-572)
  2018/07/13  AY/PK   Added PrevWaveNo: Migrated from Prod (S2G-727)
  2018/03/28  TK      Changed to consider DestLocaiton on Order Detail instead of Location (S2G-516)
  2018/03/16  TK      Added PickBatchId (S2G-382)
  2017/10/05  VM      Include remaining order UDFs (OB-617)
  2017/05/04  LRA     Changes to resolve the truncate issue with data (CIMS-1326)
  2016/09/28  AY      Compute back ordered qty based upon OrigUnitsToShip (HPI-GoLive)
  2016/08/16  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2016/07/29  TK      Added PackingGroup (HPI-380)
  2016/06/14  PK      Displaying UnitWeight in SKUUDF5 and calculated line weight in vwOD_UDF1.
  2016/05/19  TK      Added UnitsPreAllocated and PreProcessFlag
  2015/09/29  RV      Added All SKUs descriptions (FB-421)
  2015/06/30  YJ      Mapped UDFs with OD_UDF's
  2015/06/25  OK      Added the ODCustPo.
  2015/06/24  OK      CustPo fetching the values from OrderDetails.
  2015/04/29  YJ      Added ShipPack.
  2014/08/05  TD      Added IsSortable,IsConveyable, IsScannable.
  2014/04/03  TD      Added DestLocation, DestZone.
  2013/12/16  NY      Added OrderCategories.
  2013/12/13  NY      Added UnitsPerInnerPack and vwUDF's.
  2013/09/16  PK      Retrieving PickBatchNo from OrderDetails table
  2103/04/25  TD      Added SKU.UnitPrice.
  2012/10/22  PK      Added UnitsPerCarton.
  2012/10/02  AY      Added Archived, changed cast on datetime fields.
  2012/09/20  PKS     Added ShipToStore, LPNsAssigned.
              AY      Added UoM
  2012/07/18  SP      Added the fields UDF6 to UDF10.
  2012/06/27  SP      Added the field Warehouse.
  2012/06/23  PKS     UPC Column was added.
  2012/02/07  YA      Added LocationId, Location as it is need for Replenishment.
  2011/11/10  AY      Added UnitSalePrice, UnitDiscount, ResidualDiscount & UnitTaxAmount
  2011/11/07  AY      Added LineType
  2011/10/24  NB      UnitsToAllocate: Directly fetch the value from table.
  2011/09/28  PKS     UnitsShipped column added.
  2011/08/03  PK      Added Status, PickBatchNo.
  2011/07/06  PK      Added SKU1 - SKU5 fields.
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2010/12/30  PK      Added SalesOrder, OrderType, OrderDate, DesiredShipDate,
                      Priority, SoldToId, ShipToId, ShipVia, ShipFrom, CustPO, Ownership
  2010/12/21  AY      Added UnitsToAllocate
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOrderDetails') is not null
  drop View dbo.vwOrderDetails;
Go

/* vwOrderDetailsToAllocate is dependent on the vwOrderDetails, if any changes done
   to the vwOrderDetails then vwOrderDetailsToAllocate should also change according to that
   since it is dependent on the vwOrderDetails */

Create View dbo.vwOrderDetails (
  OrderDetailId,
  OrderLine,
  OrderDetailWeight,
  OrderDetailVolume,

  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  Status,
  StatusDescription,
  OrderStatus,
  OrderStatusDesc,
  ExchangeStatus,
  StatusGroup,

  OrderDate,
  DesiredShipDate,
  CancelDate,
  DateShipped,
  Priority,

  SoldToId,
  SoldToName,
  ShipToId,
  Account,
  AccountName,
  ShipToStore,
  PickBatchId,
  PickBatchNo,
  WaveId,
  WaveNo,
  ShipVia,
  ShipFrom,
  CustPO,
  ODCustPO,
  Ownership,
  Warehouse,
  PickBatchGroup,
  WaveGroup,
  PrevWaveNo,

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

  ShortPick,
  Archived,
  PreProcessFlag,

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
  ParentHostLineNo,
  LineType,
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  SKUDesc,
  SKU1Desc,
  SKU2Desc,
  SKU3Desc,
  SKU4Desc,
  SKU5Desc,
  DisplaySKU,
  DisplaySKUDesc,
  UPC,
  UoM,
  InventoryUoM,
  ProductCost,
  UnitsPerInnerPack,
  ShipPack,
  IsSortable,
  IsConveyable,
  IsScannable,
  Serialized,

  UnitsOrdered,
  OrigUnitsAuthorizedToShip,
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
  LineValue,

  Lot,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,
  CustSKU,

  LocationId,  /* Used for replenishments */
  Location,
  PickZone,

  DestZone,
  DestLocation,
  PackingGroup,
  PrepackCode,
  AllocateFlags,

  NewSKU,
  NewInventoryClass1,
  NewInventoryClass2,
  NewInventoryClass3,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

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
  OD_UDF11,
  OD_UDF12,
  OD_UDF13,
  OD_UDF14,
  OD_UDF15,
  OD_UDF16,
  OD_UDF17,
  OD_UDF18,
  OD_UDF19,
  OD_UDF20,

  /* Set to be deprecated use SKU_UDF's instead of SKUUDF's */
  SKUUDF1,
  SKUUDF2,
  SKUUDF3,
  SKUUDF4,
  SKUUDF5,

  vwOD_UDF1,
  vwOD_UDF2,
  vwOD_UDF3,
  vwOD_UDF4,
  vwOD_UDF5,
  vwOD_UDF6,
  vwOD_UDF7,
  vwOD_UDF8,
  vwOD_UDF9,
  vwOD_UDF10,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  OD.OrderDetailId,
  OD.OrderLine,
  OD.UnitsAuthorizedToShip *  S.UnitWeight,
  OD.UnitsAuthorizedToShip *  S.UnitVolume,

  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OT.TypeDescription,
  OH.Status,
  OS.StatusDescription,
  OH.Status, /* OrderStatus */
  OS.StatusDescription, /* OrderStatusDesc */
  OH.ExchangeStatus,
  case
    when (OH.Status in ('O'/* Downloaded */,'N'/* New */,'W'/* Waved */))
      then 'To Process'
    when (OH.Status in ('S'/* Shipped */,'D'/* Completed */,'X'/* Cancelled */))
      then 'Closed'
    else
      'In Process'
  end,

  cast(OH.OrderDate as Date),
  cast(OH.DesiredShipDate as Date),
  cast(OH.CancelDate as Date),

  case when OH.Status in ('S' /* Shipped */, 'D' /* Completed */) then
    cast(OH.ModifiedDate as Date)
  else
    null
  end,
  OH.Priority,

  OH.SoldToId,
  OH.SoldToName,
  OH.ShipToId,
  OH.Account,
  OH.AccountName,
  OH.ShipToStore,
  PBD.PickBatchId,
  PBD.PickBatchNo,
  PBD.PickBatchId, /* Wave Id */
  PBD.PickBatchNo, /* Wave No */
  OH.ShipVia,
  OH.ShipFrom,
  OH.CustPO,
  OD.CustPO,
  OH.Ownership,
  OH.Warehouse,
  OH.PickBatchGroup,
  OH.PickBatchGroup, /* Wave Group */
  OH.PrevWaveNo,

  OH.NumLines,
  OH.NumSKUs,
  OH.NumUnits,
  OH.LPNsAssigned,
  OH.UnitsAssigned,
  OH.NumLPNs,

  OH.TotalSalesAmount,
  OH.TotalTax,
  OH.TotalShippingCost,
  OH.TotalDiscount,

  OH.ShortPick,
  OH.Archived,
  OH.PreProcessFlag,

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
  OD.ParentHostLineNo,
  OD.LineType,
  OD.SKUId,
  OD.SKU,
  OD.SKU1,
  OD.SKU2,
  OD.SKU3,
  OD.SKU4,
  OD.SKU5,
  S.Description,
  S.SKU1Description,
  S.SKU2Description,
  S.SKU3Description,
  S.SKU4Description,
  S.SKU5Description,
  S.DisplaySKU,
  S.DisplaySKUDesc,
  S.UPC,
  S.UoM,
  S.InventoryUOM,
  S.UnitPrice,
  S.UnitsPerInnerPack,
  S.ShipPack,
  S.IsSortable,
  S.IsConveyable,
  S.IsScannable,
  OD.Serialized,

  OD.UnitsOrdered,
  OD.OrigUnitsAuthorizedToShip,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  OD.UnitsPreAllocated,
  OD.UnitsShipped,
  OD.UnitsToAllocate,
  OD.RetailUnitPrice,
  OD.UnitSalePrice,
  OD.UnitsPerCarton,
  /* Discount per unit */
  0.0,
  /* Residual Discount */
  0.0,
  OD.UnitTaxAmount,
  case
     when (OH.Status <> 'S' /* Shipped */) then
       (OD.UnitsAuthorizedToShip * OD.UnitSalePrice)
     else
       (OD.UnitsShipped * OD.UnitSalePrice)
  end, /* Line Value */

  OD.Lot,
  OD.InventoryClass1,
  OD.InventoryClass2,
  OD.InventoryClass3,
  OD.CustSKU,

  OD.DestLocationId,
  OD.DestLocation,
  OD.PickZone,

  OD.DestZone,
  OD.DestLocation,
  OD.PackingGroup,
  OD.PrepackCode,
  OD.AllocateFlags,

  OD.NewSKU,
  OD.NewInventoryClass1,
  OD.NewInventoryClass2,
  OD.NewInventoryClass3,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

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

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,

  OH.Account, --cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),   /* For Future Use */
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),

  OD.BusinessUnit,
  OD.CreatedDate,
  OD.ModifiedDate,
  OD.CreatedBy,
  OD.ModifiedBy
from

OrderDetails OD
             join OrderHeaders     OH  on (OD.OrderId       = OH.OrderId       )
  left outer join PickBatchDetails PBD on (OD.OrderDetailId = PBD.OrderDetailId)
  left outer join SKUs             S   on (OD.SKUId         = S.SKUId          )
  left outer join EntityTypes      OT  on (OT.TypeCode      = OH.OrderType     ) and
                                          (OT.Entity        = 'Order'          ) and
                                          (OT.BusinessUnit  = OD.BusinessUnit  )
  left outer join Statuses         OS  on (OS.StatusCode    = OH.Status        ) and
                                          (OS.Entity        = 'Order'          ) and
                                          (OS.BusinessUnit  = OD.BusinessUnit  );

Go
