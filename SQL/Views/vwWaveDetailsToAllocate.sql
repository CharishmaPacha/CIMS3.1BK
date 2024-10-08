/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/10  TK      Consider lines with UnitsAuthorizedToShip greater that zero (HA-1434)
  2020/06/22  TK      Added new SKU, InventoryClasses & SourceSystem (HA-834)
  2020/04/19  TK      Cloned from vwPickBatchDetailsToAllocate (HA-86)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwWaveDetailsToAllocate') is not null
  drop View dbo.vwWaveDetailsToAllocate;
Go

Create View dbo.vwWaveDetailsToAllocate (
  RecordId,

  /* Wave details here */
  WaveId,
  WaveNo,
  WaveType,
  WaveAllocateFlags,

  /* order related */
  OrderId,
  SalesOrder,
  PickTicket,
  OrderType,
  OrderStatus,
  SoldToId,
  ShipToId,
  ShipToStore,
  NumLPNs,
  Warehouse,

  Priority,
  ShipVia,
  CustPO,
  Canceldate,
  Ownership,
  Account,

  HasNotes,
  SourceSystem,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

  /* Order Details related */
  OrderDetailId,
  OrderLine,
  HostOrderLine,
  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsShipped,
  UnitsToAllocate,
  UnitsPreAllocated,
  UnitsPerCarton,
  CustSKU,
  PickZone,
  LocationId,
  Location,
  DestLocationId,
  DestLocation,
  DestZone,
  Lot,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,
  NewInventoryClass1,
  NewInventoryClass2,
  NewInventoryClass3,
  ODUDF1,
  ODUDF2,
  ODUDF3,
  ODUDF4,
  ODUDF5,

  AllocateFlags,

  /* SKU details */
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  SKUDescription,
  NewSKUId,
  NewSKU,
  AlternateSKU,
  BarCode,
  UnitWeight,
  UnitVolume,
  UoM,
  ProductCost,
  UnitsPerInnerPack,
  ShipPack,
  ABCClass,
  IsSortable,
  IsConveyable,
  IsScannable,

  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,
  SKU_UDF5,

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

  /* batch details here */
  W.WaveId,
  W.WaveNo,
  W.WaveType,
  W.AllocateFlags,

  /* order related */
  BD.OrderId,
  OH.SalesOrder,
  OH.PickTicket,
  OH.OrderType,
  OH.Status,
  OH.SoldToId,
  OH.ShipToId,
  OH.ShipToStore,
  OH.NumLPNs,
  OH.Warehouse,
  OH.Priority,
  OH.ShipVia,
  OH.CustPO,
  cast(OH.Canceldate as Date),
  OH.Ownership,
  OH.Account,

  OH.HasNotes,
  OH.SourceSystem,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

  /* Order Details related */
  BD.OrderDetailId,
  OD.OrderLine,
  OD.HostOrderLine,
  OD.UnitsOrdered,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  OD.UnitsShipped,
  case when S.ShipPack > 0 then OD.UnitsToAllocate/S.ShipPack * S.ShipPack else OD.UnitsToAllocate end,
  OD.UnitsPreAllocated,
  OD.UnitsPerCarton,
  OD.CustSKU,
  OD.PickZone,
  OD.LocationId,
  OD.Location,
  OD.DestLocationId,
  OD.DestLocation,
  OD.DestZone,
  OD.Lot,
  OD.InventoryClass1,
  OD.InventoryClass2,
  OD.InventoryClass3,
  OD.NewInventoryClass1,
  OD.NewInventoryClass2,
  OD.NewInventoryClass3,
  OD.UDF1,
  OD.UDF2,
  OD.UDF3,
  OD.UDF4,
  OD.UDF5,

  OD.AllocateFlags,

  S.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.Description,
  OD.NewSKUId,
  OD.NewSKU,
  S.AlternateSKU,
  S.BarCode,
  S.UnitWeight,
  S.UnitVolume,
  S.UoM,
  S.UnitPrice,
  S.UnitsPerInnerPack,
  S.ShipPack,
  S.ABCClass,
  S.IsSortable,
  S.IsConveyable,
  S.IsScannable,

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,

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

  BD.RuleId,              /* For future use */

  BD.BusinessUnit,
  BD.CreatedDate,
  BD.ModifiedDate,
  BD.CreatedBy,
  BD.ModifiedBy
From
  PickBatchDetails     BD
  join OrderDetails    OD on (BD.OrderDetailId = OD.OrderDetailId)
  join OrderHeaders    OH on (OD.OrderId       = OH.OrderId      )
  join Waves           W  on (BD.WaveId        = W.WaveId        )
  left outer join SKUs S  on (OD.SKUId         = S.SKUId         )

  where (OD.UnitsToAllocate > 0) and
        (OD.UnitsAuthorizedToShip > 0) and
        (OH.Status not in ('H', 'S', 'D', 'X' /* Hold, Shipped, Completed, Cancelled */))

Go
