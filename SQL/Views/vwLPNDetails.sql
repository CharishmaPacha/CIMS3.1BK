/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/19  MS      Setup LPN UDF's as per new standard (JL-266)
  2020/05/20  MS      Added LPNStatusDesc (HA-604)
  2020/05/18  MS      Added WaveId & WaveNo (HA-593)
  2020/04/22  TK      Added ReceiverId & ReceiverNumber (HA-211)
              AY      Code optimization, removed join with Receipt Details
  2020/03/30  MS      Added InventoryClasses (HA-83)
  2019/12/05  RT      Included AlternateSKU and Barcode (HPI-2807)
  2019/09/13  TK      Added DisplaySKU, DisplaySKUDesc (S2GCA-939)
  2019/04/02  TK      Added AlternateOrderId and AlternatePickTicket (S2GCA-546)
  2018/12/29  AY      Added LocationSubType and PutawayZone for RF SKU Inquiry
  2018/10/30  AY      Added UnitVolume (S2GCA-368)
  2018/10/30  SV      Added HostOrderLine to show up in LPNDetails page (HPI-2097)
  2018/10/02  AY      Changed joins for performance - excluded joins with views (HPI-Support)
  2018/09/12  TK      Added LPNLot (S2GCA-216)
  2018/07/08  VM/RT   Added LPN totals - TotalInnerPacks,TotalQuantity,TotalReservedQty,TotalDirectedQty,TotalNumLines(Migrated from S2GL1) (S2G-1006)
  2018/03/24  VM      Added AllocableInnerPacks (S2G-CRP)
  2018/02/22  VM      Added AllocableQty (S2G-477)
  2018/02/13  TK      Changes to ReservedQuantity (S2G-182)
  2018/01/25  AJ      Added fields OD_UDF1-10 (HPI-1796)
  2017/03/08  LRA     Added ReplenishOrder (HPI-1435)
  2017/12/05  SPP     Added ReferenceLocation (OB-649)
  2016/10/16  AY      Added TaskId (HPI-GoLive)
  2016/09/21  VM      Added ReplenishOrderId, ReplenishOrderDetailId (HPI-GoLive)
  2015/08/20  RV      Added UnitWeight (HPI-483)
  2015/06/18  OK      Added AlternateLPN.
  2014/11/28  AK      Added Archived
  2014/09/11  PK      Added ShipPack.
  2014/06/03  PV      Added DefaultUOM and PickTicket computations.
  2014/05/21  PKS     Added OwnershipDescription
  2014/05/16  PV      Added ReservedQuantity.
  2014/05/08  PKS     Added DisplayDestination
  2014/05/06  PV      Calculating UnitsPerPackage from LPNDetails instead considering SKU configured value as it may change
                       after inventory is added to LPN.
  2014/05/05  PV      Added DisplayQuantity.
  2014/04/24  AK      Added PickedBy, PackedBy,PickedDate,PackedDate fields.
  2014/03/26  TD      Added DefaultUoM.
  2013/03/21  PK      Added Warehouse, LPNStatusDescription, WarehouseDescription.
  2013/04/05  PK      Added PackageSeqNo, SKUDescription, SKU1Description, SKU2Description,
                        SKU3Description, SKU4Description, SKU5Description, CustSKU.
  2012/06/07  PK      Added LPNStatus.
  2011/09/26  PK      Added LocationType, Ownership, UPC.
  2011/07/25  VM      Added LastPutawayDate
  2011/07/16  AY      Changed left outer join between LPND and LPN to normal join.
  2011/07/06  PK      Added SKUS.SKU1 - SKU5 fields and LPNDetails.UDF's.
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2011/01/21  Vk      Added OnhandStatusDescription
  2011/01/14  PK      Added PickTicket, SalesOrder, OrderLine, ReceiptNumber, ReceiptLine.
  2010/12/30  PK      Added LPNType, ShipmentId, LoadId, ASNCase.
  2010/12/03  PK      Added UOM, Location and joined with Locations table.
  2010/12/03  VM      Added LocationId
  2010/11/26  PK      Added OnhandStatus
  2010/11/10  VM      Added LPN, LPNDetailId
  2010/10/26  VM      CoE => CoO
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLPNDetails') is not null
  drop View dbo.vwLPNDetails;
Go

Create View dbo.vwLPNDetails (
  LPNId,
  LPN,
  /* Key Info */
  LPNDetailId,
  LPNLine,
  LPNType,
  LPNStatus,
  LPNStatusDescription, --Deprecated
  LPNStatusDesc,
  OnhandStatus,
  OnhandStatusDescription,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,

  OrderId,
  PickTicket,
  OrderDetailId,

  ReceiptId,
  ReceiptNumber,
  ReceiptDetailId,
  ReceiptLine,

  /* LD IPs/Units */
  InnerPacks,
  Quantity,
  ReservedQuantity,

  AllocableInnerPacks,
  AllocableQty,
  UnitsPerPackage,

  /* Other LPND Info */
  CoO,
  ReceivedUnits,
  DisplayQuantity,
  Weight,
  Volume,

  Lot,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,

  ReplenishOrderId,
  ReplenishOrder,
  ReplenishOrderDetailId,

  /* SKU info */
  SKUDescription,
  SKU1Description, /* Style Description */
  SKU2Description, /* Color Description */
  SKU3Description, /* Size Description */
  SKU4Description,
  SKU5Description,
  UOM,
  UPC,
  AlternateSKU,
  SKUBarcode,
  DisplaySKU,
  DisplaySKUDesc,
  InnerPacksPerLPN,
  UnitsPerInnerPack,
  UnitsPerLPN,
  UnitWeight,
  UnitVolume,
  ShipPack,

  /*LPN info*/
  Ownership,
  OwnershipDescription,
  Warehouse,
  WarehouseDescription,

  AlternateLPN,
  InventoryStatus,
  LastMovedDate,
  SorterName,
  ExportFlags,
  LPNLot,
  TotalInnerPacks,
  TotalQuantity,
  TotalReservedQty,
  TotalDirectedQty,
  TotalNumLines,

  ShipmentId,
  LoadId,
  ASNCase,
  PackageSeqNo,

  PalletId,
  Pallet,
  LocationId,
  TaskId,

  PickBatchId,
  PickBatchNo,
  WaveId,
  WaveNo,

  AlternateOrderId,
  AlternatePickTicket,

  ReceiverId,
  ReceiverNumber,

  DestWarehouse,
  DestZone,
  DestLocation,
  DisplayDestination,

  ActualWeight,
  EstimatedWeight,
  ActualVolume,
  EstimatedVolume,
  LPNWeight,
  LPNVolume,
  CartonType,

  /* Location */
  Location,
  LocationType,
  LocationSubType,
  StorageType,
  PickingZone,
  PutawayZone,
  Barcode,

  MinReplenishLevel,
  MaxReplenishLevel,
  ReplenishUoM,

  /* Order Header/Detail */
  SalesOrder,
  OrderType,
  ShipToStore,
  OrderLine,
  HostOrderLine,
  CustSKU,

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

  /* LPN Details, reference fields & UDFs */
  LastPutawayDate,
  ReferenceLocation,
  PickedBy,
  PickedDate,
  PackedBy,
  PackedDate,

  /* LPNDetail UDF's */
  LPND_UDF1,
  LPND_UDF2,
  LPND_UDF3,
  LPND_UDF4,
  LPND_UDF5,

  /* Deprecated UDF's */
  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  DefaultUoM,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  LD.LPNId,
  L.LPN,
  /* Key Info */
  LD.LPNDetailId,
  LD.LPNLine,
  L.LPNType,
  L.Status,
  LST.StatusDescription,
  LST.StatusDescription, /* Mapped for LPNStatusDesc */
  LD.OnhandStatus,
  OST.StatusDescription,

  LD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,

  LD.OrderId,
  coalesce(OH.PickTicket, '-') PickTicket /* This is to prevent RF crashing */,
  LD.OrderDetailId,

  LD.ReceiptId,
  RH.ReceiptNumber,
  LD.ReceiptDetailId,
  '', -- RD.ReceiptLine, --deprecated

  /* LD IPs/Units */
  LD.InnerPacks,
  LD.Quantity,
  LD.ReservedQty,

  LD.AllocableInnerPacks,
  LD.AllocableQty,
  LD.UnitsPerPackage,

  /* Other LPND Info */
  LD.CoO,
  LD.ReceivedUnits,
  cast(' ' as varchar(50)), /* Quantity Display for RF */
  LD.Weight,
  LD.Volume,

  LD.Lot,
  L.InventoryClass1,
  L.InventoryClass2,
  L.InventoryClass3,

  LD.ReplenishOrderId,
  LD.ReplenishPickTicket,
  LD.ReplenishOrderDetailId,

  /* SKU info */
  S.Description,
  S.SKU1Description,
  S.SKU2Description,
  S.SKU3Description,
  S.SKU4Description,
  S.SKU5Description,
  S.UOM,
  S.UPC,
  S.AlternateSKU,
  S.Barcode,
  S.DisplaySKU,
  S.DisplaySKUDesc,
  S.InnerPacksPerLPN,
  S.UnitsPerInnerPack,
  S.UnitsPerLPN,
  S.UnitWeight,
  S.UnitVolume,
  S.ShipPack,

  /* LPN info */
  L.Ownership,
  OWD.LookUpDescription, /* OWD - OwnershipDescription */
  L.DestWarehouse,
  LWH.LookUpDisplayDescription,

  L.AlternateLPN,
  L.InventoryStatus,
  L.LastMovedDate,
  L.SorterName,
  L.ExportFlags,
  L.Lot,
  L.InnerPacks,
  L.Quantity,
  L.ReservedQty,
  L.DirectedQty,
  L.NumLines,

  L.ShipmentId,
  L.LoadId,
  L.ASNCase,
  L.PackageSeqNo,

  L.PalletId,
  L.Pallet,
  L.LocationId,
  L.TaskId,

  L.PickBatchId,
  L.PickBatchNo,
  L.PickBatchId, /* WaveId */
  L.PickBatchNo, /* WaveNo */

  L.AlternateOrderId,
  L.AlternatePickTicket,

  L.ReceiverId,
  L.ReceiverNumber,

  L.DestWarehouse,
  L.DestZone,
  L.DestLocation,
  case
    when (L.DestZone <> L.DestLocation) then
      coalesce(L.DestLocation + ' / ', '') + coalesce(L.DestZone, '')
    else
      coalesce(L.DestLocation, '')
  end,

  L.ActualWeight,
  L.EstimatedWeight,
  L.ActualVolume,
  L.EstimatedVolume,
  L.LPNWeight,
  L.LPNVolume,
  L.CartonType,

  /* Location */
  LOC.Location,
  LOC.LocationType,
  LOC.LocationSubType,
  LOC.StorageType,
  LOC.PickingZone,
  LOC.PutawayZone,
  LOC.Barcode,

  LOC.MinReplenishLevel,
  LOC.MaxReplenishLevel,
  LOC.ReplenishUoM,

  /* Order Header/Detail */
  OH.SalesOrder,
  OH.OrderType,
  OH.ShipToStore,
  OD.OrderLine,
  OD.HostOrderLine,
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

  /* LPN Details, reference fields & UDFs */
  LD.LastPutawayDate,
  LD.ReferenceLocation,
  LD.Pickedby,
  LD.PickedDate,
  LD.Packedby,
  LD.PackedDate,

  LD.UDF1,
  LD.UDF2,
  LD.UDF3,
  LD.UDF4,
  LD.UDF5,

  /* Deprecated UDF's */
  LD.UDF1,
  LD.UDF2,
  LD.UDF3,
  LD.UDF4,
  L.CartonType,

  case  /* Set default UoM here */
    when ((LD.UnitsPerPackage > 0) and coalesce((LD.Quantity / nullif(LD.UnitsPerPackage,0)),0) > 1) then 'CS'
    else 'EA'
  end,

  L.Archived,
  LD.BusinessUnit,
  LD.CreatedDate,
  LD.ModifiedDate,
  LD.CreatedBy,
  LD.ModifiedBy

from
LPNDetails LD
             join LPNs             L   on (LD.LPNId           = L.LPNId            )
  left outer join Locations        LOC on (L.LocationId       = LOC.LocationId     )
  left outer join SKUs             S   on (LD.SKUId           = S.SKUId            )
  left outer join OrderHeaders     OH  on (LD.OrderId         = OH.OrderId         )
  left outer join OrderDetails     OD  on (LD.OrderDetailId   = OD.OrderDetailId   )
  left outer join ReceiptHeaders   RH  on (LD.ReceiptId       = RH.ReceiptId       )
  --left outer join ReceiptDetails   RD  on (LD.ReceiptDetailId = RD.ReceiptDetailId )
  left outer join Statuses         OST on (LD.OnhandStatus    = OST.StatusCode     ) and
                                          (OST.Entity         = 'OnHand'           ) and
                                          (OST.BusinessUnit   = LD.BusinessUnit    )
  left outer join Statuses         LST on (L.Status           = LST.StatusCode     ) and
                                          (LST.Entity         = 'LPN'              ) and
                                          (LST.BusinessUnit   = L.BusinessUnit     )
  left outer join LookUps          LWH on (L.DestWarehouse    = LWH.LookUpCode     ) and
                                          (LWH.LookUpCategory = 'Warehouse'        ) and
                                          (LWH.BusinessUnit   = L.BusinessUnit     )
  left outer join LookUps          OWD on (L.Ownership        = OWD.LookUpCode     ) and
                                          (OWD.LookUpCategory = 'Owner'            ) and
                                          (OWD.BusinessUnit   = L.BusinessUnit     )
where (L.Status <> 'I' /* Inactive/Deleted */);

Go
