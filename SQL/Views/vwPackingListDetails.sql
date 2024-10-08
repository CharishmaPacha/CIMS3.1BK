/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/26  TK      For New & Waved orders BackOrdered should be '0' (BK-530)
  2021/07/23  SJ      Added LineType (OB2-1960)
  2021/06/26  RV      Added DisplaySKU and DisplaySKUDesc and rearranged SKUDescription (OB2-1822)
  2020/01/22  SAK     Added Pallet and PalletId fields taken from vwLPNPackinglistDetails (CIMS-2791)
  2019/08/23  SPP     coalesce added in OD_UDF17 (CID-136) (Ported from Prod)
  2019/08/20  AY      Mapped PL_UDF1 to OD_UDF17 (CID-944)
  2019/06/30  KSK     Added new field HarmonizedCode (CID-632)
  2019/04/04  RT      Brand to display on the PL (CID-193)
  2019/03/20  MJ      Added PackedDate field (CID-196)
  2018/10/25  MS      Master Copy (CIMS 2063 & HPI 2050)
  2018/10/01  RT      Consider UnitsAuthorizedToShip when the Status is New or Waved (S2GCA-306)
  2018/09/17  SPP     Port back changes taken (HPI-1558)
  2018/09/11  SPP     Added Missing fields from vwLPNPackingListDetails (CIMS-1928)
  2018/08/27  TD      Changes to print only the name with in [],in barcode (HPI-2016)
  2018/08/23  TD      Changes to print only the name with in [] - (HPI-2008)
  2018/08/23  TD      Chanegs to supprress [ for only SAP orders (HPI-2009)
  2018/06/03  TD      BackOrder Units Changes for SAP(HPI-1880)
  2018/04/10  TD      Added SourceSystem. (HPI-1848)
  2018/04/10  AY      Suppresss [PRODUCTION] comment for SAP.
  2018/04/05  SV      SAP integration: Changes which reflects back over the PackingList (HPI-1848)
  2017/10/05  VM      Include remaining order UDFs (OB-617)
  2017/08/30  SV      Introduced OD_UDF6 to OD_UDF10 (OB-553)
                      Changes to fetch UPC and SKU to display on the PL (OB-553)
  2014/05/16  DK      Added SKUDescription1..5, UPC, Location, UnitsShipped, BO and Terms
  2016/09/28  AY      Compute back ordered qty based upon OrigUnitsToShip (HPI-GoLive)
  2016/08/10  RV      Truncate PL_UDF1 to aviod the exception (HPI-473)
  2016/08/03  AY      Handle special item descriptions (HPI-427)
  2016/07/25  RV      Added Back Ordered (HPI-363)
  2016/07/07  AY      Define PL_UDF1
  2016/02/12  RV      Added OD_UDF5 to OD_UDF10 (FB-624)
  2015/09/01  RV      Corrected LineSaleAmount computation (FB-392)
  2015/09/15  TK      Added missing fields (ACME-287)
  2015/08/12  RV      If users print packing list for New orders print UnitsAuthorizedToShip (FB-286)
  2015/07/03  TK      Changed UDFs -> OD_UDFs
  2015/06/25  RV      Get the batch type information from control variable.
  2015/04/15  PK      Corrected the packinglist to show UnitsAuthorizedToShip instead of UnitsOrdered.
  2015/03/02  TK      For Bulk Pull batches, need to print packing lists ahead, hence the changes
  2014/12/29  PKS     Added SKU1Description to SKU5Description, UPC
  2014/12/22  TK      Added new field UnitsShipped.
  2012/08/08  AY      Changed to use UnitsAssigned for computations as PLs
                        are printed prior to shipping
  2012/06/19  AY      Added UDF and removed LOEH customizations
  2012/06/07  PKS     Migrated from Fech.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPackingListDetails') is not null
  drop View dbo.vwPackingListDetails;
Go
/* Note: If any fields needs to be added here please add same fields in vwLPNPackingListDetails (Both are dependent on each other) */
Create View dbo.vwPackingListDetails (
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
  0,                         /* LPNId */
  cast(' ' as varchar(50)),  /* LPN */
  cast(' ' as varchar(50)),  /* LPNDetailId */
  cast(' ' as varchar(50)),  /* LPNLine */
  cast(' ' as varchar(10)),  /* LPNType */
  cast(' ' as varchar(20)),  /* CoO */
  cast(' ' as varchar(20)),  /* ExpiryDate*/

  S.SKUId,
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

  0,                         /* InnerPacks */
  0,                         /* Quantity */
  0,                         /* UnitsPerPackage */

  0,                         /* ShipmentId */
  0,                         /* LoadId */
  cast(' ' as varchar(50)),  /* ASNCase */

  cast(' ' as varchar(50)),  /* UCCBarCode */
  0,                         /* PackageSeqNo */
  null,                      /* PackedDate */
  cast(' ' as varchar(50)),  /* TrackingNo */

  OD.OrderId,
  0,                         /* PalletId */
  null,                      /* Pallet */
  OH.PickTicket,
  OH.SalesOrder,
  OH.SourceSystem,
  OD.OrderDetailId,
  OD.OrderLine,
  OD.HostOrderLine,
  OD.LineType,

  OD.UnitsOrdered,
  OD.UnitsShipped,
  OD.UnitsAuthorizedToShip,
  case
    /* Check Whether batch type is BPT or not*/
    when (OH.Status = 'N') /* New */ or
         ((dbo.fn_Controls_GetAsString('PB_CreateBPT', PB.BatchType, 'N' /* No */, OD.BusinessUnit, 'cIMSAgent') = 'Y' /* Yes */) and
          (OH.Status = 'W' /* Waved */)) then
      OD.UnitsAuthorizedToShip
    else
      OD.UnitsAssigned
  end /* UnitsAssigned */,
  OD.UnitsToAllocate,
  OH.LPNsAssigned,
  case when (OH.Status in ('N', 'W' /* New, Waved */)) then 0
       else (OD.OrigUnitsAuthorizedToShip - OD.UnitsAssigned)
  end /* BackOrdered */,
  OD.RetailUnitPrice,                    /* Retail Unit Price */
  OD.UnitSalePrice,                      /* Unit Sale Price */
  OD.UnitsAssigned * OD.UnitSalePrice,   /* Line Sale Amount */
  0, --OD.UnitDiscount * OD.UnitsAssigned,    /* Line Discount Amount */
  (OD.UnitsAssigned * OD.RetailUnitPrice), --  - (OD.UnitDiscount * OD.UnitsAssigned),   /* Line total amount */

  OD.UnitTaxAmount,
  (OD.UnitsAssigned * OD.UnitTaxAmount), /* Number of Units X Unit Tax Amount */
  0.0,                       /* Weight */
  0.0,                       /* Volume  */
  cast(' ' as varchar(60)),  /* Lot     */

  cast(' ' as varchar(50)),  /* LD.UDF1 */
  cast(' ' as varchar(50)),  /* LD.UDF2 */
  cast(' ' as varchar(50)),  /* LD.UDF3 */
  cast(' ' as varchar(50)),  /* LD.UDF4 */
  cast(' ' as varchar(50)),  /* LD.UDF5 */

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

  OD.BusinessUnit
from OrderDetails                  OD
  left outer join SKUs             S   on (OD.SKUId           = S.SKUId            )
  left outer join OrderHeaders     OH  on (OD.OrderId         = OH.OrderId         )
  left outer join PickBatches      PB  on (PB.RecordId        = OH.PickBatchId     );

Go
