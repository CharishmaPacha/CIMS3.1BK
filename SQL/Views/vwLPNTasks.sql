/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/20  MS      Added LPNStatus & LPNStatusDesc (HA-604)
  2015/06/08  YJ      Added AlternateLPN
  2014/06/10  PKS     Added BatchType, BatchTypeDesc.
  2014/04/25  TD      Added TaskDetailId.
  2014/04/21  PV      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLPNTasks') is not null
  drop View dbo.vwLPNTasks;
Go

Create View dbo.vwLPNTasks (
  TaskId,
  TaskDetailId,
  LPNId,

  LPN,
  LPNType,
  LPNTypeDescription,
  Status, --Deprecated
  LPNStatus,
  StatusDescription, --Deprecated
  LPNStatusDesc,
  OnhandStatus,
  OnhandStatusDescription,

  /* SKU */
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UPC,

  /* Qty */
  InnerPacks,
  Quantity,
  ReservedQty,
  UnitsPerInnerPack,
  InnerPacksPerLPN,

  DestWarehouse,
  DestZone,
  DestLocation,

  PalletId,
  Pallet,
  LocationId,
  Location,

  ReceiverNumber,
  ReceiptId,
  ReceiptNumber,
  PutawayClass,
  PickingClass,
  ReceivedDate,

  OrderId,
  PickTicket,
  SalesOrder,

  PickBatchId,
  PickBatchNo,
  BatchType,
  BatchTypeDesc,

  ShipmentId,
  LoadId,
  LoadNumber,
  ASNCase,
  UCCBarcode,
  TrackingNo,
  PackageSeqNo,

  ExpiryDate,
  ExpiresInDays,
  LastMovedDate,

  ActualWeight,
  ActualVolume,
  EstimatedWeight,
  EstimatedVolume,

  InventoryStatus,
  Ownership,
  CoO,
  Lot,

  /* Other SKU fields */
  SKUDescription,
  UnitPrice,
  UnitCost,
  UnitWeight,
  UnitVolume,
  UnitLength,
  UnitHeight,
  UnitWidth,
  UOM,

  /* Other Location fields */
  LocationType,
  StorageType,
  PickingZone,

  /* Other Order Fields */
  CustPO,
  ShipToStore,
  ShipTo,
  CustAccount,
  CustAccountName,
  AlternateLPN,

  /* LPN UDFs */
  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  /* SKU UDFs */
  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,
  SKU_UDF5,
  SKU_UDF6,
  SKU_UDF7,
  SKU_UDF8,
  SKU_UDF9,
  SKU_UDF10,

  /* Order Hdr UDFs */
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

  /* Receipt Hdr UDFs */
  RH_UDF1,
  RH_UDF2,
  RH_UDF3,
  RH_UDF4,
  RH_UDF5,

  /* Place holders for any new fields which needs to be added quickly without
     changing data layer and install UI again. Change requires only in .aspx file */
  vwLPNTask_UDF1,
  vwLPNTask_UDF2,
  vwLPNTask_UDF3,
  vwLPNTask_UDF4,
  vwLPNTask_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  LPNT.TaskId,
  LPNT.TaskDetailId,
  L.LPNId,

  L.LPN,
  L.LPNType,
  L.LPNTypeDescription,
  L.Status,
  L.Status, /* Mapped for LPNStatus */
  L.StatusDescription,
  L.LPNStatusDesc, /* Mapped for LPNStatusDesc */
  L.OnhandStatus,
  L.OnhandStatusDescription,

  S.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.UPC,

  LD.InnerPacks,
  LD.Quantity,
  case when LD.OnhandStatus = 'R' /* Reserved */ then LD.Quantity else 0 end,   --Reserved Qty
  coalesce(LD.UnitsPerPackage, S.UnitsperInnerPack),
  S.InnerPacksPerLPN,

  L.DestWarehouse,
  L.DestZone,
  L.DestLocation,

  L.PalletId,
  L.Pallet,
  L.LocationId,
  L.Location,

  L.ReceiverNumber,
  L.ReceiptId,
  L.ReceiptNumber,
  L.PutawayClass,
  L.PickingClass,
  L.ReceivedDate,

  L.OrderId,
  L.PickTicket,
  L.SalesOrder,

  L.PickBatchId,
  L.PickBatchNo,
  PB.BatchType,
  ET.TypeDescription,

  L.ShipmentId,
  L.LoadId,
  L.LoadNumber,
  L.ASNCase,
  L.UCCBarcode,
  L.TrackingNo,
  L.PackageSeqNo,

  L.ExpiryDate,
  L.ExpiresInDays,
  L.LastMovedDate,

  L.ActualWeight,
  L.ActualVolume,
  L.EstimatedWeight,
  L.EstimatedVolume,
  L.InventoryStatus,
  L.Ownership,
  L.CoO,
  L.Lot,

  S.Description,
  S.UnitPrice,
  S.UnitCost,
  S.UnitWeight,
  S.UnitVolume,
  S.UnitLength,
  S.UnitHeight,
  S.UnitWidth,
  S.UOM,

  L.LocationType,
  L.StorageType,
  L.PickingZone,

  L.CustPO,
  L.ShipToStore,
  L.ShipTo,
  L.CustAccount,
  L.CustAccountName,
  L.AlternateLPN,

  L.UDF1,
  L.UDF2,
  L.UDF3,
  L.UDF4,
  L.UDF5,

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,
  S.UDF6,
  S.UDF7,
  S.UDF8,
  S.UDF9,
  S.UDF10,

  L.OH_UDF1,
  L.OH_UDF2,
  L.OH_UDF3,
  L.OH_UDF4,
  L.OH_UDF5,
  L.OH_UDF6,
  L.OH_UDF7,
  L.OH_UDF8,
  L.OH_UDF9,
  L.OH_UDF10,

  L.RH_UDF1,
  L.RH_UDF2,
  L.RH_UDF3,
  L.RH_UDF4,
  L.RH_UDF5,

  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),

  L.Archived,
  L.BusinessUnit,
  L.CreatedDate,
  L.ModifiedDate,
  L.CreatedBy,
  L.ModifiedBy
from
 LPNTasks LPNT
  join vwLPNs      L  on (LPNT.LPNId       = L.LPNId)
  join LPNDetails  LD on (LPNT.LPNDetailId = LD.LPNDetailId)
  join SKUs        S  on (LD.SKUId         = S.SKUId)
  join PickBatches PB on (L.PickBatchNo    = PB.BatchNo)
  join EntityTypes ET on (PB.BatchType     = ET.TypeCode) and
                         (ET.Entity        = 'PickBatch') and
                         (ET.BusinessUnit  = PB.BusinessUnit);

Go
