/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/29  KBB     Added Description,Brand (BK-446)
  2021/03/10  RV      Port back InventoryClass1 changes and added SKUSortOrder (HA-2237)
  2021/03/09  AY      Initial Revision (HA-2208)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLocationLPNs') is not null
  drop View dbo.vwLocationLPNs;
Go

Create View dbo.vwLocationLPNs (
  LPNId,

  LPN,
  LPNType,
  LPNTypeDescription,
  Status,
  LPNStatus,
  StatusDescription, --Deprecated
  LPNStatusDesc,
  OnhandStatus,
  OnhandStatusDescription,
  LPNWeight,
  LPNVolume,

  /* SKU */
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  Description,
  SKU1Desc,
  SKU2Desc,
  SKU3Desc,
  SKU4Desc,
  SKU5Desc,
  UPC,
  ProductCost,
  Brand,

  /* Qty */
  InnerPacks,
  Quantity,
  ReservedQty,
  DirectedQty,
  AllocableQty,
  UnitsPerInnerPack,
  InnerPacksPerLPN,

  DestWarehouse,
  DestZone,
  DestLocation,

  PalletId,
  Pallet,
  LocationId,
  Location,

  ReceiverId,
  ReceiverNumber,
  ReceiptId,
  ReceiptNumber,
  PutawayClass,
  PickingClass,
  ReceivedDate,
  ReasonCode,
  Reference,

  OrderId,
  PickTicket,
  PickTicketNo,
  SalesOrder,
  OrderType,

  PickBatchId,
  PickBatchNo,
  WaveId,
  WaveNo,
  SorterName,

  AlternateOrderId,
  AlternatePickTicket,

  TaskId,

  ShipmentId,
  LoadId,
  LoadNumber,
  BoL,
  ASNCase,
  UCCBarcode,
  TrackingNo,
  ReturnTrackingNo,
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
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,

  AlternateLPN,
  CartonType,
  PackingGroup,
  NumLines,
  HostNumLines,
  /* Flags */
  ExportFlags,
  PrintFlags,

  /* Other SKU fields */
  SKUDescription,
  UnitPrice,
  UnitCost,
  UnitWeight,
  UnitVolume,
  UnitLength,
  UnitHeight,
  UnitWidth,
  UoM,
  ProdCategory,
  SKUSortOrder,

  /* Other Location fields */
  LocationType,
  StorageType,
  PickingZone,

  /* Other Order Fields */
  SoldToId,
  SoldToName,
  ShipTo,
  ShipToName,
  CustAccount,
  CustAccountName,
  CustPO,
  ShipToStore,

  /* LPN UDFs */ -- these are depracated, do not use anymore. Use the LPN_UDF fields
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

  /* LPN UDFs */
  LPN_UDF1,
  LPN_UDF2,
  LPN_UDF3,
  LPN_UDF4,
  LPN_UDF5,
  LPN_UDF6,
  LPN_UDF7,
  LPN_UDF8,
  LPN_UDF9,
  LPN_UDF10,
  LPN_UDF11,
  LPN_UDF12,
  LPN_UDF13,
  LPN_UDF14,
  LPN_UDF15,
  LPN_UDF16,
  LPN_UDF17,
  LPN_UDF18,
  LPN_UDF19,
  LPN_UDF20,

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
  vwLPN_UDF1,
  vwLPN_UDF2,
  vwLPN_UDF3,
  vwLPN_UDF4,
  vwLPN_UDF5,

  UniqueId,
  Visible,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,
  ModifiedOn
) As
select
  coalesce(L.LPNId, 0),

  coalesce(L.LPN, ''),
  L.LPNType,
  LT.TypeDescription,
  L.Status,
  L.Status, /* Mapped to LPNStatus column */
  ST.StatusDescription,
  ST.StatusDescription, /* Mapped to LPNStatusDesc column */
  L.OnhandStatus,
  OST.StatusDescription,
  L.LPNWeight,
  L.LPNVolume,

  coalesce(L.SKUId, 0),
  coalesce(S.SKU,  L.SKU, ''),
  coalesce(S.SKU1, L.SKU1, ''),
  coalesce(S.SKU2, L.SKU2, ''),
  coalesce(S.SKU3, L.SKU3, ''),
  coalesce(S.SKU4, L.SKU4, ''),
  coalesce(S.SKU5, L.SKU5, ''),
  S.Description,
  S.SKU1Description,
  S.SKU2Description,
  S.SKU3Description,
  S.SKU4Description,
  S.SKU5Description,
  S.UPC,
  S.UnitPrice,
  S.Brand,

  L.InnerPacks,
  L.Quantity,
  L.ReservedQty,
  L.DirectedQty,
  case when (L.OnhandStatus in ('A'/* Available */)) then L.Quantity + L.DirectedQty - L.ReservedQty else 0 end, /* Allocable Qty */
  L.Quantity/nullif(L.InnerPacks, 0),
  S.InnerPacksPerLPN,

  L.DestWarehouse,
  L.DestZone,
  L.DestLocation,

  coalesce(L.PalletId, 0),
  coalesce(L.Pallet, ''),
  LOC.LocationId,
  LOC.Location,

  L.ReceiverId,
  L.ReceiverNumber,
  L.ReceiptId,
  L.ReceiptNumber,
  L.PutawayClass,
  L.PickingClass,
  L.ReceivedDate,
  L.ReasonCode,
  L.Reference,

  L.OrderId,
  L.PickTicketNo,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,

  L.PickBatchId,
  L.PickBatchNo,
  L.PickBatchId, /* Wave Id */
  L.PickBatchNo, /* Wave No */
  L.SorterName,

  L.AlternateOrderId,
  L.AlternatePickTicket,

  L.TaskId,

  L.ShipmentId,
  L.LoadId,
  L.LoadNumber,
  L.BoL,
  L.ASNCase,
  L.UCCBarcode,
  L.TrackingNo,
  L.ReturnTrackingNo,
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
  coalesce(L.CoO, S.DefaultCoO),
  L.Lot,
  L.InventoryClass1,
  L.InventoryClass2,
  L.InventoryClass3,

  L.AlternateLPN,
  L.CartonType,
  L.PackingGroup,
  L.NumLines,
  L.HostNumLines,
  /* Flags */
  L.ExportFlags,
  L.PrintFlags,

  /* Related Fields of SKU, Loc, Order */
  case when L.SKUId is null and L.Quantity > 0 then 'Mixed SKUs' else S.Description + ' / ' + L.InventoryClass1 end,
  S.UnitPrice,
  S.UnitCost,
  S.UnitWeight,
  S.UnitVolume,
  S.UnitLength,
  S.UnitHeight,
  S.UnitWidth,
  S.UoM,
  S.ProdCategory,
  S.SKUSortOrder,

  LOC.LocationType,
  LOC.StorageType,
  LOC.PickingZone,

  OH.SoldToId,
  OH.SoldToName,
  OH.ShipToId,
  OH.ShipToName,
  OH.Account,
  OH.AccountName,
  OH.CustPO,
  OH.ShipToStore,

  /* LPN UDFs */
  L.UDF1,
  L.UDF2,
  L.UDF3,
  L.UDF4,
  L.UDF5,
  L.UDF6,
  L.UDF7,
  L.UDF8,
  L.UDF9,
  L.UDF10,
  L.UDF11,
  L.UDF12,
  L.UDF13,
  L.UDF14,
  L.UDF15,
  L.UDF16,
  L.UDF17,
  L.UDF18,
  L.UDF19,
  L.UDF20,
  /* Duplicated as earlier ones are used in V2 and these are for V3 */
  L.UDF1,
  L.UDF2,
  L.UDF3,
  L.UDF4,
  L.UDF5,
  L.UDF6,
  L.UDF7,
  L.UDF8,
  L.UDF9,
  L.UDF10,
  L.UDF11,
  L.UDF12,
  L.UDF13,
  L.UDF14,
  L.UDF15,
  L.UDF16,
  L.UDF17,
  L.UDF18,
  L.UDF19,
  L.UDF20,

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

  /* For performance reasons we will comment out RH UDFs and uncomment as required */
  cast(' ' as varchar(50)), -- RH.UDF1,
  cast(' ' as varchar(50)), -- RH.UDF2,
  cast(' ' as varchar(50)), -- RH.UDF3,
  cast(' ' as varchar(50)), -- RH.UDF4,
  cast(' ' as varchar(50)), -- RH.UDF5,

  cast(' ' as varchar(50)), /* vwLPN_UDF1 */
  cast(' ' as varchar(50)), /* vwLPN_UDF2 */
  cast(' ' as varchar(50)), /* vwLPN_UDF3 */
  cast(' ' as varchar(50)), /* vwLPN_UDF4 */
  cast(' ' as varchar(50)), /* vwLPN_UDF5 */

  L.UniqueId,
  L.Visible,

  L.Archived,
  L.BusinessUnit,
  L.CreatedDate,
  L.ModifiedDate,
  L.CreatedBy,
  L.ModifiedBy,
  L.ModifiedOn
From
Locations LOC
  left outer join LPNs               L   on (L.LocationId     = LOC.LocationId )
  left outer join EntityTypes       LT   on (LT.TypeCode      = L.LPNType      ) and
                                            (LT.Entity        = 'LPN'          ) and
                                            (LT.BusinessUnit  = L.BusinessUnit )
  left outer join SKUs              S    on (L.SKUId          = S.SKUId        )
  left outer join Statuses          ST   on (ST.StatusCode    = L.Status       ) and
                                            (ST.Entity        = 'LPN'          ) and
                                            (ST.BusinessUnit  = L.BusinessUnit )
  left outer join Statuses          OST  on (OST.StatusCode   = L.OnhandStatus ) and
                                            (OST.Entity       = 'Onhand'       ) and
                                            (OST.BusinessUnit = L.BusinessUnit )
  left outer join OrderHeaders      OH   on (L.OrderId        = OH.OrderId     )
where (coalesce(L.Status, '') not in ('I' /* Inactive/Deleted */));

Go