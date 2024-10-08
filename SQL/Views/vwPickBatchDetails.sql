/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/19  KBB     Added UDF11 to UDF30 (HA-2647)
  2021/03/20  MS      Added ShipDate (HA-2358)
  2020/05/24  TK      Added InventoryClasses (HA-521)
  2020/01/21  AY      Add InnerPacksToAllocate and Wave fields (FB-1667)
  2018/04/05  AY      Add OH_UDF1 to 10 (S2G-508)
                      Added CasesToShip, RemainingUnitsToShip
  2016/11/06  AY      Map OH.PickZone to UDF1 (HPI-GoLive)
  2016/08/04  TK      Added ODLot (HPI-443)
  2016/07/15  DK      Added UnitsPreAllocated (HPI-273).
  2015/07/18  AY      Added OH.Account, AccountName
  2014/04/10  TD      Added DestLocation.
  2014/03/11  DK      Added HasNotes
  2013/12/19  NY      Added OrderCategories.
  2013/12/02  TD      Added Order Status.
  2013/10/04  AY      Added UnitsPerInnerPack
  2012/10/02  TD      Added new fields.
  2012/09/12  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPickBatchDetails') is not null
  drop View dbo.vwPickBatchDetails;
Go

Create View dbo.vwPickBatchDetails (
  RecordId,
  Status,

  /* Wave details here */
  PickBatchId,
  PickBatchNo,
  BatchType,
  WaveId,
  WaveNo,
  WaveType,

  /* order related */
  OrderId,
  SalesOrder,
  PickTicket,
  OrderType,
  OrderStatus,
  SoldToId,
  ShipToId,
  ShipToStore,
  ShipDate,
  NumLPNs,
  Warehouse,
  Ownership,
  Priority,
  ShipVia,
  CustPO,
  CancelDate,
  Account,
  AccountName,

  HasNotes,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

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

  /* Order Details related */
  OrderDetailId,
  OrderLine,
  HostOrderLine,
  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsPreAllocated,
  UnitsShipped,
  UnitsToAllocate,
  UnitsPerCarton,
  CustSKU,
  PickZone,
  DestZone,
  ODLot,

  InventoryClass1,
  InventoryClass2,
  InventoryClass3,

  ODUDF1,
  ODUDF2,
  ODUDF3,
  ODUDF4,
  ODUDF5,

  InnerPacksToAllocate,
  CasesToShip,
  RemainingUnitsToShip,

  /* SKU details */
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  SKUDescription,
  AlternateSKU,
  BarCode,
  UnitWeight,
  UnitVolume,
  UoM,
  ProductCost,
  UnitsPerInnerPack,
  SourceSystem,
  IsSortable,

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

  RuleId,              /* For future use */

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) AS
select
  BD.RecordId,
  BD.Status,

  /* Wave details here */
  BD.PickBatchId,
  BD.PickBatchNo,
  PB.BatchType,
  BD.PickBatchId,
  BD.PickBatchNo,
  PB.BatchType,

  /* order related */
  BD.OrderId,
  OH.SalesOrder,
  OH.PickTicket,
  OH.OrderType,
  OH.Status,
  OH.SoldToId,
  OH.ShipToId,
  OH.ShipToStore,
  OH.DesiredShipDate,
  OH.NumLPNs,
  OH.Warehouse,
  OH.Ownership,
  OH.Priority,
  OH.ShipVia,
  OH.CustPO,
  cast(OH.Canceldate as Date),
  OH.Account,
  OH.AccountName,

  OH.HasNotes,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

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

  /* Order Details related */
  BD.OrderDetailId,
  OD.OrderLine,
  OD.HostOrderLine,
  OD.UnitsOrdered,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  OD.UnitsPreAllocated,
  OD.UnitsShipped,
  OD.UnitsToAllocate,
  OD.UnitsPerCarton,
  OD.CustSKU,
  OD.PickZone,
  OD.DestZone,
  OD.Lot,

  OD.InventoryClass1,
  OD.InventoryClass2,
  OD.InventoryClass3,

  OD.UDF1,
  OD.UDF2,
  OD.UDF3,
  OD.UDF4,
  OD.UDF5,

  /* InnerPacksToAllocate */
  case when OD.UnitsPerCarton > 0  then OD.UnitsToAllocate/OD.UnitsPerCarton
       when S.UnitsPerInnerPack > 0 then OD.UnitsToAllocate/S.UnitsPerInnerPack
       else 0
  end,
  /* CasesToShip */
  case when S.UnitsPerInnerPack > 0 then OD.UnitsAuthorizedToShip/S.UnitsPerInnerPack else 0 end,
  /* Remaining Units to Ship */
  case when S.UnitsPerInnerPack > 0 then OD.UnitsAuthorizedToShip % S.UnitsPerInnerPack else OD.UnitsAuthorizedToShip end,

  S.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.Description,
  S.AlternateSKU,
  S.Barcode,
  S.UnitWeight,
  S.UnitVolume,
  S.UoM,
  S.UnitPrice,
  coalesce(nullif(S.UnitsPerInnerPack, 0), 1), /* prevent div by zero error */
  S.Sourcesystem,
  S.IsSortable,

  coalesce(OH.PickZone, ''),
  BD.UDF2,
  BD.UDF3,
  BD.UDF4,
  BD.UDF5,
  BD.UDF6,
  BD.UDF7,
  BD.UDF8,
  BD.UDF9,
  BD.UDF10,

  BD.RuleId,              /* For future use */

  BD.BusinessUnit,
  BD.CreatedDate,
  BD.ModifiedDate,
  BD.CreatedBy,
  BD.ModifiedBy
From
  PickBatchDetails BD
             join OrderDetails OD on (BD.OrderDetailId = OD.OrderDetailId)
             join OrderHeaders OH on (OD.OrderId       = OH.OrderId      )
  left outer join PickBatches  PB on (BD.PickBatchNo   = PB.BatchNo      )
  left outer join SKUs         S  on (OD.SKUId         = S.SKUId         )

Go
