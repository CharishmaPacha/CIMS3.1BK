/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/09/05  NY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwUIReceiptDetails') is not null
  drop View dbo.vwUIReceiptDetails;
Go

Create View dbo.vwUIReceiptDetails (
  ReceiptDetailId,
  ReceiptLine,
  ReceiptId,
  ReceiptNumber,
  ReceiptType,
  ReceiptTypeDesc,

  VendorId,
  VendorName,
  Ownership,

  DateOrdered,
  DateShipped,
  DateExpected,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  Description,
  SKU1Description,
  SKU2Description,
  SKU3Description,
  SKU4Description,
  SKU5Description,
  AlternateSKU,
  UPC,

  CoO,

  InnerPacksPerLPN,
  UnitsPerInnerPack,
  UnitsPerLPN,

  InnerPackWeight,
  InnerPackLength,
  InnerPackWidth,
  InnerPackHeight,
  InnerPackVolume,

  UnitWeight,
  UnitLength,
  UnitWidth,
  UnitHeight,
  UnitVolume,

  UnitPrice,

  SKUSortOrder,
  Barcode,
  Brand,

  ProdCategory,
  ProdSubCategory,
  PutawayClass,
  ABCClass,
  Serialized,

  QtyOrdered,
  QtyReceived,
  LPNsReceived,
  QtyInTransit,
  LPNsInTransit,
  ExtraQtyAllowed,

  QtyToReceive,
  MaxQtyAllowedToReceive,

  UnitCost,
  HostReceiptLine,
  CustPO,
  PackingSlipNumber,

  Vessel,
  ContainerSize,
  Warehouse,

  NumLPNs,
  NumUnits,
  UnitsInTransit,
  UnitsReceived,

  BillNo,
  SealNo,
  InvoiceNo,
  ContainerNo,

  ETACountry,
  ETACity,
  ETAWarehouse,

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

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  RD.ReceiptDetailId,
  RD.ReceiptLine, --deprecated
  RD.ReceiptId,
  RH.ReceiptNumber,
  RH.ReceiptType,
  ET.TypeDescription,

  RH.VendorId,
  V.VendorName,
  RH.Ownership,

  RH.DateOrdered,
  RH.DateShipped,
  RH.DateExpected,

  RD.SKUId,
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
  S.AlternateSKU,
  S.UPC,

  RD.CoO,

  S.InnerPacksPerLPN,
  S.UnitsPerInnerPack,
  S.UnitsPerLPN,

  S.InnerPackWeight,
  S.InnerPackLength,
  S.InnerPackWidth,
  S.InnerPackHeight,
  S.InnerPackVolume,

  S.UnitWeight,
  S.UnitLength,
  S.UnitWidth,
  S.UnitHeight,
  S.UnitVolume,

  S.UnitPrice,

  S.SKUSortOrder,
  S.Barcode,
  S.Brand,

  S.ProdCategory,
  S.ProdSubCategory,
  S.PutawayClass,
  S.ABCClass,
  S.Serialized,

  RD.QtyOrdered,
  RD.QtyReceived,
  RD.LPNsReceived,
  RD.QtyInTransit,
  RD.LPNsInTransit,
  RD.ExtraQtyAllowed,

  (RD.QtyOrdered - RD.QtyReceived),
  (RD.QtyOrdered - RD.QtyReceived + RD.ExtraQtyAllowed),

  RD.UnitCost,
  RD.HostReceiptLine,
  RD.CustPO,
  'PackingSlipNo',

  RH.Vessel,
  RH.ContainerSize,
  RH.Warehouse,

  RH.NumLPNs,
  RH.NumUnits,
  RH.UnitsInTransit,
  RH.UnitsReceived,

  RH.BillNo,
  RH.SealNo,
  RH.InvoiceNo,
  RH.ContainerNo,

  RH.ETACountry,
  RH.ETACity,
  RH.ETAWarehouse,

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,
  RD.UDF1,
  RD.UDF2,
  RD.UDF3,
  RD.UDF4,
  RD.UDF5,
  RD.UDF6,
  RD.UDF7,
  RD.UDF8,
  RD.UDF9,
  RD.UDF10,

  RD.BusinessUnit,
  RD.CreatedDate,
  RD.ModifiedDate,
  RD.CreatedBy,
  RD.ModifiedBy
from
  ReceiptDetails RD
             join ReceiptHeaders  RH  on (RD.ReceiptId      = RH.ReceiptId   )
  left outer join SKUs            S   on (RD.SKUId          = S.SKUId        )
  left outer join EntityTypes     ET  on (RH.ReceiptType    = ET.TypeCode    ) and
                                         (ET.Entity         = 'Receipt'      ) and
                                         (ET.BusinessUnit   = RD.BusinessUnit)
  left outer join Statuses        ST  on (RH.Status         = ST.StatusCode  ) and
                                         (ST.Entity         = 'Receipt'      ) and
                                         (ST.BusinessUnit   = RD.BusinessUnit)
  left outer join Vendors         V   on (RH.VendorId       = V.VendorId     )
;

Go
