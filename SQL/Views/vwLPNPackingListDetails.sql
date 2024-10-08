/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/26  TK      For New & Waved orders BackOrdered should be '0' (BK-530)
  2021/07/29  RV      Added LineType (OB2-1960)
  2021/06/26  OK      Added DisplaySKU and DisplaySKUDesc and rearranged SKUDescription (BK-377)
  2019/03/20  MJ      Added PackedDate field (CID-196)
  2018/10/25  MS      Master Copy (CIMS 2063 & HPI 2050)
  2018/10/01  RT      Consider UnitsAuthorizedToShip when the Status is New or Waved (S2GCA-306)
  2018/09/11  SPP     Added Missing fields from vwPackingListDetails (CIMS-1928)
  2018/04/10  TD      Added SourceSystem. (HPI-1848)
  2016/09/28  AY      Compute back ordered qty based upon OrigUnitsToShip (HPI-GoLive)
  2016/07/27  YJ      Added OD_UDF5 to OD_UDF10 fields (HPI-330)
  2016/07/25  RV      Added Back Ordered (HPI-363)
  2016/07/08  RV      Added Packinglist UDFs (HPI-246)
  2016/04/11  RV      Corrected Line Sale Amount (NBD-371)
  2015/11/03  TK      Added LPNsAssigned field (ACME-390)
  2015/07/04  RV      Added CustSKU (ACME-189).
  2015/07/03  TK      Changes UDFs -> OD_UDFs
  2015/04/10  AK      Added UnitsShipped.
  2015/01/13  VM      Temp fix: As LPN Packing list using UnitsAssigned as Quantity, changed porting it now to LD.Quantity
  2014/12/23  SV      Do not show rates when the order is a gift order (UDF8 is used in OB to send flag (Y/N) based on gift order)
  2014/12/29  PKS     Added SKU1Description to SKU5Description, UCCBarCode, PackageSeqNo, UPC
  2011/11/10  AY      Added LineDiscount, LineTotalAmount fields.
                      Changed computations to handle residual discount amounts
  2011/10/27  AY      Added UnitTaxAmount, LineTaxAmount & LineSaleAmount fields
  2011/10/09  AY      No price to be printed for Gift Orders
                      Print last 4 digits of SerialNo along with Description.
  2011/08/24  AA      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwLPNPackingListDetails') is not null
  drop View dbo.vwLPNPackingListDetails;
Go
/* Note: If any fields needs to be added here please add same fields in vwPackingListDetails (Both are dependent on each other) */
Create View dbo.vwLPNPackingListDetails (
  LPNId,
  LPN,
  LPNDetailId,
  LPNLine,
  LPNType,
  CoO,
  ExpiryDate,

  /* SKU fields */
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  SKUDescription,
  SKU1Description,
  SKU2Description,
  SKU3Description,
  SKU4Description,
  SKU5Description,
  DisplaySKU,
  DisplaySKUDesc,
  CustSKU,
  UOM,
  UPC,
  UnitsPerInnerPack,
  Brand,
  HarmonizedCode,

  InnerPacks,
  Quantity,
  UnitsPerPackage,

  ShipmentId,
  LoadId,
  ASNCase,

  UCCBarCode,
  PackageSeqNo,
  PackedDate,
  TrackingNo,

  /* Order */
  OrderId,
  PalletId,
  Pallet,
  PickTicket,
  SalesOrder,
  SourceSystem,
  OrderDetailId,
  OrderLine,
  HostOrderLine,
  LineType,

  /* Counts */
  UnitsOrdered,
  UnitsShipped,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsToAllocate,
  LPNsAssigned,
  BackOrdered,
  /* Money */
  RetailUnitPrice,
  UnitSalePrice, /* This is now actually Order Line Discount */
  LineSaleAmount,
  LineDiscount, /* One order line could be packed into multiple cartons, this is the line on the packing list */
  LineTotalAmount,
  UnitTaxAmount,
  LineTaxAmount,
  Weight,
  Volume,
  Lot,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

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
  SKU_UDF6,
  SKU_UDF7,
  SKU_UDF8,
  SKU_UDF9,
  SKU_UDF10,

  PL_UDF1, /* Future Use */
  PL_UDF2, /* Future Use */
  PL_UDF3, /* Future Use */
  PL_UDF4, /* Future Use */
  PL_UDF5, /* Future Use */

  BusinessUnit
) as
select
  LD.LPNId,
  L.LPN,
  LD.LPNDetailId,
  LD.LPNLine,
  L.LPNType,
  LD.CoO,
  L.ExpiryDate,

  LD.SKUId,
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
  S.DisplaySKU,
  S.DisplaySKUDesc,
  OD.CustSKU,
  S.UOM,
  S.UPC,
  S.UnitsPerInnerPack,
  S.Brand,
  S.HarmonizedCode,

  LD.InnerPacks,
  LD.Quantity,
  LD.UnitsPerPackage,

  L.ShipmentId,
  L.LoadId,
  L.ASNCase,

  L.UCCBarCode,
  L.PackageSeqNo,
  LD.PackedDate,
  L.TrackingNo,

  LD.OrderId,
  L.PalletId,
  L.Pallet,
  OH.PickTicket,
  OH.SalesOrder,
  OH.SourceSystem,
  LD.OrderDetailId,
  OD.OrderLine,
  OD.HostOrderLine,
  OD.LineType,

  OD.UnitsOrdered,
  OD.UnitsShipped,
  OD.UnitsAuthorizedToShip,
  case
    /* Consider UnitsAuthorizedToShip when the Status is New or Waved */
    when (OH.Status in ('N', 'W' /* New, Waved */)) then
      OD.UnitsAuthorizedToShip
    else
      LD.Quantity
  end /* UnitsAssigned */,
  OD.UnitsToAllocate,
  OH.LPNsAssigned,
  case when (OH.Status in ('N', 'W' /* New, Waved */)) then 0
       else (OD.OrigUnitsAuthorizedToShip - OD.UnitsAssigned)
  end /* BackOrdered */,
  OD.RetailUnitPrice,                    /* Retail Unit Price */
  OD.UnitSalePrice,                      /* Unit Sale Price */
  LD.Quantity * OD.UnitSalePrice,        /* Line Sale Amount */
  0.0,                                   /* Line Discount Amount */
  LD.Quantity * OD.UnitSalePrice,        /* Line Total Amount */
  OD.UnitTaxAmount,
  (LD.Quantity * OD.UnitTaxAmount), /* Number of Units X Unit Tax Amount */
  LD.Weight,
  LD.Volume,
  LD.Lot,

  LD.UDF1,
  LD.UDF2,
  LD.UDF3,
  LD.UDF4,
  LD.UDF5,

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
  S.UDF6,
  S.UDF7,
  S.UDF8,
  S.UDF9,
  S.UDF10,

  cast(' ' as varchar(50)), /* PL_UDF1 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF2 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF3 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF4 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF5 - Future use */

  LD.BusinessUnit
from LPNDetails LD
             join LPNs             L   on (LD.LPNId           = L.LPNId            )
  left outer join SKUs             S   on (LD.SKUId           = S.SKUId            )
  left outer join OrderHeaders     OH  on (LD.OrderId         = OH.OrderId         )
  left outer join OrderDetails     OD  on (LD.OrderDetailId   = OD.OrderDetailId   )
where (L.LPNType in ('C' /* Carton */, 'S' /* Ship Carton */));

Go
