/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/01  TK      Added InventoryClass (HA-86)
  2019/12/31  AY      Changed to use Wave terminology
  2019/08/05  SPP     vwPickBatchDetailsToAllocate:remove status D (CID-136) (Ported from prod)
  2018/05/07  PK      Calculating UnitsToAllocate value by considering ShipPack
                        value which is defined on the SKUs (S2G-671).
  2018/03/27  TK      Added DestLocationId (S2G-499)
  2015/11/12  AY      Added Ownerhip, Lot, Account
  2015/06/17  DK      Added ShipPack.
  2014/08/05  AY      Added IsScannable, IsSortable, IsConveyable Flags
  2014/05/18  PK      Added LocationId, Location.
  2014/04/02  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPickBatchDetailsToAllocate') is not null
  drop View dbo.vwPickBatchDetailsToAllocate;
Go

Create View dbo.vwPickBatchDetailsToAllocate (
  RecordId,

  /* Wave details here */
  PickBatchId,
  PickBatchNo,
  BatchType,
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
  BD.PickBatchId,
  BD.PickBatchNo,
  W.BatchType,
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
  S.AlternateSKU,
  S.BarCode,
  S.UnitWeight,
  S.UnitVolume,
  S.UoM,
  S.UnitPrice,
  coalesce(nullif(S.UnitsPerInnerPack, 0), 1), /* prevent div by zero error */
  coalesce(nullif(S.ShipPack, 0), 1),
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
        (OH.Status not in ('H', 'S', 'D', 'X' /* Hold, Shipped, Completed, Cancelled */))

Go
