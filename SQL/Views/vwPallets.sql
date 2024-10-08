/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/20  AY      Added ShipToCityState (HA-2342)
  2021/03/05  AY      Changes to show Account info for Pallet with Multiple shipTos (HA Mock GoLive)
  2021/02/15  PHK     Made changes to get ShipToCity  & State on the shipping label (HA-1972)
  2021/02/09  AY      Use Pallet's ShipToStore, CustPO for multi Order pallets (HA-1229)
  2021/02/03  SGK     Added TrackingNo, PrintFlags, PutawayClass, ModifiedOn (CIMSV3-1334)
  2020/12/21  PK      Added ShipToCityStateZip: Ported changes done by Pavan (HA-1818)
  2020/07/28  AY      Added Pallet.Reference (HA-1244)
  2020/07/16  AY      Added several Order fields to print on Shipping Pallet labels
  2020/07/10  RIA     Added DisplaySKU, DisplaySKUDesc (HA-426)
  2020/05/18  MS      Added WaveId & WaveNo (HA-593)
  2020/05/15  SK      Need SKU UoM for the data set (CIMSV3-788)
  2020/02/20  AY      Pallets: Mapped SKU, SKU1..5 to Pallets
  2020/02/18  MS      Pallets: Added ReceiverNumber & ReceiptNumber (JL-104)
              AY      Added PalletStatus, PalletStatusDesc
  2019/07/15  AY      Added TaskId
  2014/01/10  TD      Added new fields
  2019/02/14  AJ      Added DestZone and DestLocation (CID-103)
  2016/11/24  VM      Added PickPath
  2016/06/24  KL      Added PackingByUser
  2014/02/24  NY      Added LoadNumber
  2013/10/24  TD      Added new fields
  2012/10/03  SP      Added Archived
  2012/08/17  AY      Changed to join with Pickbatches for BatchNo
  2012/06/27  SP/AY   Added fields Warehouse, Ownership
  2012/04/26  PK      Added PickBatchId
  2012/04/04  YA      Added PickBatchNo
  2012/03/27  YA      Added PalletTypeDesc and StatusDesc
  2012/03/21  PK      Added PalletType
  2011/02/22  AY      Added SKU fields
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate
  2010/09/24  PK      Initial Revision
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPallets') is not null
  drop View dbo.vwPallets;
Go

Create View dbo.vwPallets (
  PalletId,

  Pallet,
  PalletType,
  PalletTypeDesc,
  PalletStatus,
  PalletStatusDesc,
  Status,
  StatusDesc,
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UPC,
  SKUUoM,
  SKUDescription,
  DisplaySKU,
  DisplaySKUDesc,

  NumLPNs,
  InnerPacks,
  Quantity,

  LocationId,
  Location,
  LocationType,
  StorageType,
  PickingZone,
  PickPath,
  PickingClass,
  PutawayClass,
  DestZone,
  DestLocation,

  Ownership,
  Warehouse,

  OrderId,
  PickTicket,
  SalesOrder,
  SoldToId,
  SoldToName,
  Account,
  AccountName,
  CustPO,
  ShipToStore,

  PickBatchId,
  PickBatchNo,
  WaveId,
  WaveNo,
  WaveType,
  TaskId,

  Weight,
  Volume,

  ShipToId,
  ShipToName,
  ShipToCity,
  ShipToState,
  ShipToCityState,
  ShipToCityStateZip,

  PackingByUser,
  ShipmentId,
  LoadId,
  LoadNumber,
  PalletSeqNo,
  TrackingNo,
  PrintFlags,

  ReceiptId,
  ReceiptNumber,
  ReceiverId,
  ReceiverNumber,

  Reference,

  PAL_UDF1,
  PAL_UDF2,
  PAL_UDF3,
  PAL_UDF4,
  PAL_UDF5,

  vwPAL_UDF1,
  vwPAL_UDF2,
  vwPAL_UDF3,
  vwPAL_UDF4,
  vwPAL_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,
  ModifiedOn

) As
select
  P.PalletId,
  P.Pallet,
  P.PalletType,
  ET.TypeDescription,
  P.Status,
  PST.StatusDescription,
  P.Status,
  PST.StatusDescription,
  P.SKUId,
  P.SKU,
  P.SKU1,
  P.SKU2,
  P.SKU3,
  P.SKU4,
  P.SKU5,
  SKU.UPC,
  SKU.UoM,
  SKU.Description,
  case when P.SKUId > 0 then SKU.DisplaySKU else null end,
  case when P.SKUId > 0 then SKU.DisplaySKUDesc else null end,

  P.NumLPNs,
  P.InnerPacks,
  P.Quantity,

  P.LocationId,
  LOC.Location,
  LOC.LocationType,
  LOC.StorageType,
  LOC.PickingZone,
  LOC.PickPath,
  P.PickingClass,
  P.PutawayClass,
  P.DestZone,
  P.DestLocation,

  P.Ownership,
  P.Warehouse,

  P.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.SoldToId,
  OH.SoldToName,
  coalesce(OH.Account,     LD.Account),
  coalesce(OH.AccountName, LD.AccountName),
  coalesce(OH.CustPO,      P.CustPO),
  coalesce(OH.ShipToStore, P.ShipToStore),

  P.PickBatchId,
  W.WaveNo,
  P.PickBatchId, /* Wave Id */
  W.WaveNo, /* Wave No */
  W.WaveType,
  P.TaskId,

  P.Weight,
  P.Volume,

  P.ShipToId,
  SHTA.Name,
  SHTA.City,
  SHTA.State,
  SHTA.CityState,
  SHTA.CityStateZip,

  P.PackingByUser,
  P.ShipmentId,
  P.LoadId,
  LD.LoadNumber,
  P.PalletSeqNo,
  P.TrackingNo,
  P.PrintFlags,

  P.ReceiptId,
  P.ReceiptNumber,
  P.ReceiverId,
  P.ReceiverNumber,

  P.Reference,

  P.UDF1,
  P.UDF2,
  P.UDF3,
  P.UDF4,
  P.UDF5,

  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),

  P.Archived,
  P.BusinessUnit,
  P.CreatedDate,
  P.ModifiedDate,
  P.CreatedBy,
  P.ModifiedBy,
  P.ModifiedOn

from
Pallets P
 left outer join SKUs         SKU  on (P.SKUId           = SKU.SKUId     )
 left outer join Locations    LOC  on (P.LocationId      = LOC.LocationId)
 left outer join OrderHeaders OH   on (P.OrderId         = OH.OrderId    )
 left outer join Waves        W    on (P.PickBatchId     = W.RecordId    )
 left outer join EntityTypes  ET   on (ET.TypeCode       = P.PalletType  ) and
                                      (ET.Entity         = 'Pallet'      ) and
                                      (ET.BusinessUnit   = P.BusinessUnit)
 left outer join Statuses     PST  on (P.Status          = PST.StatusCode) and
                                      (PST.Entity        = 'Pallet'      ) and
                                      (PST.BusinessUnit  = P.BusinessUnit)
 left outer join Contacts     SHTA on (SHTA.ContactRefId = P.ShipToId    ) and
                                      (SHTA.ContactType  = 'S' /* ShipTo */ ) and
                                      (SHTA.BusinessUnit = P.BusinessUnit)
 left outer join Loads        LD   on (P.LoadId          = LD.LoadId     )
;

Go
