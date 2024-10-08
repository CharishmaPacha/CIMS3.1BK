/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/21  AY      Added WaveId, WaveNo, UnitsToAllocate (FBV3-886)
  2022/01/31  TK      Added InventoryClasses & InventoryKey (FBV3-772)
  2021/10/12  RV      Added PackGroupKey (BK-636)
  2021/06/15  RIA     Added SKUSortOrder (OB2-1882)
  2021/06/10  NB      Added UnitsToPack and UnitsPacked (CIMSV3-156)
  2020/10/12  RIA     Added DisplaySKU, DisplaySKUDesc, SKUImageURL (CIMSV3-622)
  2019/11/16  AJ      Migrated latest changes from vwOrderToPackDetails (FB-1595)
  2019/07/29  RV      Added LocationId, Location and LastMovedDate (CID-868)
  2017/02/09  KN      Added new fields UnitWeight, PackingGroup, LPNType, GiftCardSerialNumber (HPI-699)
  2015/10/17  DK      Added LPNStatus Field (FB-440).
  2015/01/30  DK      Modified to Send the SKU instead of UPC.
  2014/03/03  DK      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwBulkOrderToPackDetails') is not null
  drop View dbo.vwBulkOrderToPackDetails;
Go
/* Note: If any fields needs to be added here please add same fields in vwOrderToPackDetails (Both are dependent on each other) */
Create View dbo.vwBulkOrderToPackDetails (
  OrderDetailId,
  OrderLine,

  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  Status,

  Priority,
  SoldToId,
  ShipToId,

  WaveId,
  WaveNo,
  PickBatchId,
  PickBatchNo,
  ShipVia,
  CustPO,
  Ownership,

  HostOrderLine,
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
  Serialized,
  UPC,
  AlternateSKU,
  DisplaySKU,
  DisplaySKUDesc,
  SKUBarcode,
  UnitWeight,
  SKUImageURL,
  SKUSortOrder,

  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsToAllocate,

  UnitsToPack, /* Placeholder Field  for V3 UI Packing */
  UnitsPacked, /* Placeholder Field for V3 UI Packing */

  InventoryClass1,
  InventoryClass2,
  InventoryClass3,
  Lot,
  InventoryKey,
  CustSKU,
  PackingGroup,

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

  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,
  SKU_UDF5,

  PalletId,
  Pallet,
  LPNId,
  LPN,
  LPNType,
  LPNStatus,
  LPNDetailId,
  PickedQuantity,
  PickedFromLocation,
  PickedBy,
  SerialNo,
  GiftCardSerialNumber,

  LocationId,
  Location,
  LastMovedDate,

  BusinessUnit,
  PageTitle,

  PackGroupKey,
  vwOPDtls_UDF1,
  vwOPDtls_UDF2,
  vwOPDtls_UDF3,
  vwOPDtls_UDF4,
  vwOPDtls_UDF5
)
As
select
  OD.OrderDetailId,
  OD.OrderLine,

  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OH.Status,

  OH.Priority,
  OH.SoldToId,
  OH.ShipToId,

  OH.PickBatchId,
  OH.PickBatchNo,
  OH.PickBatchId,
  OH.PickBatchNo,
  OH.ShipVia,
  OH.CustPO,
  OH.Ownership,

  OD.HostOrderLine,
  OD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.Description,
  S.SKU1Description,
  S.SKU2Description,
  S.SKU3Description,
  S.SKU4Description,
  S.SKU5Description,
  S.Serialized,
  S.UPC,
  S.AlternateSKU,
  S.DisplaySKU,
  S.DisplaySKUDesc,
  S.Barcode,
  S.UnitWeight,
  S.SKUImageURL,
  S.SKUSortOrder,

  OD.UnitsOrdered,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  OD.UnitsToAllocate,

  0, /* UnitsToPack - Placeholder Field for V3 UI Packing */
  0, /* UnitsPacked - Placeholder Field for V3 UI Packing */

  OD.InventoryClass1,
  OD.InventoryClass2,
  OD.InventoryClass3,
  OD.Lot,
  OD.InventoryKey,
  OD.CustSKU,
  OD.PackingGroup,

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

  L.PalletId,
  P.Pallet,
  LD.LPNId,
  L.LPN,
  L.LPNType,
  L.Status,
  LD.LPNDetailId,
  LD.Quantity,
  LD.ReferenceLocation,
  LD.PickedBy,
  LD.SerialNo,
  cast(' ' as varchar(50)), /* Gift card serial number */

  L.LocationId,
  L.Location,
  L.LastMovedDate,

  OD.BusinessUnit,
  'Pack Order '+ OH.PickTicket + ' ' + OH.SoldToId + '/' + OH.ShipToId,

  cast(''  as varchar(max)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50))

 from OrderDetails OD
             join OrderHeaders OH on (OD.OrderId       = OH.OrderId      )
  left outer join SKUs         S  on (OD.SKUId         = S.SKUId         )
  left outer join LPNs         L  on (L.OrderId         = OD.OrderId   ) and
                                     (L.LPNType not in ('C' /* Carton */, 'S' /* Ship Carton */))
  left outer join LPNDetails   LD on (L.LPNId = LD.LPNID)                and
                                     (OD.OrderDetailId = LD.OrderDetailId)
  left outer join Pallets      P  on (L.PalletId       = P.PalletId      );

Go
