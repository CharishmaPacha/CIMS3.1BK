/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/11/07  YAN     portback Changes from BK onsite prod (BK-75)
  2022/08/18  VS      Added Comments (BK-885)
  2021/06/17  SGK     Added SKU_SortSeq (HA-2907)
  2022/02/25  MS      Added InventoryKey (BK-768)
  2021/05/02  AY      Added AbsTransQty and LoadType
  2021/03/18  OK      Changes to get the transaction time as a shipped date for Ship transaction (HA-2336)
  2021/03/02  PK      Added ClientLoad (HA-2109)
  2021/02/21  PK      Added DesiredShipDate (HA-2029)
  2020/02/01  AY      Added NumPallets/NumLPN/NumCartons (HA-1896)
  2021/01/22  AY      Use InnerPacks/Quantity from exports table if available (HA-1896)
  2020/11/22  MS      Changes to send Weight & Volume (JL-316)
  2020/10/21  TK      Added FromLPNId & FromLPN (HA-1516)
  2020/07/20  YJ      UDF1 added condtion to get TransType, CartonType (HA-296) (Ported from Prod)
  2020/04/27  SPP     Commented RecordType for E.TransType = Recv(HA-296) (Ported from Prod)
  2020/04/20  MS      Added ExportStatus,ExportStatusDesc (HA-232)
  2020/03/30  YJ      Added Inventory Classses (HA-85)
  2019/12/05  RKC     Removed the Contact table join condition (CID-1175)
  2019/11/29  RKC     Added ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry, ShipToZip,
                        ShipToPhoneNo, ShipToEmail, ShipToReference1, ShipToReference2 (CID-1175)
  2019/11/27  HYP     Added new field TrackingBarcode (FB-1695)
  2019/10/21  MJ      Changes to ReceiptNumber (S2G-727) (Ported from Prod)
  2019/09/17  MS      Changes to ShipVia and other related field mappings (CID-1029)
  2019/09/17  MS      Mapping changed for OH_UDF9 (GNC-2535)
  2019/09/10  RKC     Get ShipVia by fn_GetMappedValue instead of joins (OB2-951)
  2019/09/10  MS      Changes to ShipVia mapping (CID-1029)
  2018/08/14  VM      Send FreighCharges from Exports table itself as we calculate there with rules (OB2-563)
  2019/08/10  RV      Mapped InsuranceFee to UDF5 (S2GCA-890)
  2018/08/02  VM      OB specific changes plus send ActualWeight from LPN (OB2-OutboundGoLive)
  2018/08/03  TD/AY   Changes to get MasterBoL, ClientLoad: Migrated from Prod (Ob2-190)
  2019/08/01  RT      Updating LoadId from Loads for LoadASN transaction (GNC-2346)
  2019/07/30  VM      Added LPN.UDF6..LPN.UDF10 (GNC-2217)
  2019/07/29  AY      Export Load.MasterTrackingNo if LPN doesn't have one (CID-859)
  2019/07/25  AY      ShipVia missed on Consolidate orders (CID-GoLive)
  2019/07/24  YJ      Changes UDF1 to get SL.Barcode if TransType = 'Ship' else SL.TrackingNo (S2GCA-98)(Ported from Staging)
  2019/07/10  AY      Export Client Load# as LD_UDF1 (CID-GoLive)
  2019/07/03  TD      Changes to show Freight Charges (CID-700)
  2019/04/23  VS      CID specific: Used UDF5 to UDF14 to pass ShipTo address fields (CID-313)
  2018/09/18  TK      Use SCAC code from standard attributes xml, if not available then consider ShipVia as SCAC code for LTL (S2GCA-284)
  2018/07/19  SPP     Added UDF-8 varchar as cast UnitSalePrice as varchar taken port back change(FB-992)
  2018/07/05  VS      Change the shipvia order to improve Exports page Performance (HPI-1950)
  2018/05/30  DK      Made changes to send UPC value in SKU field for shopify sourcesystem (FB-1149)

  2018/05/17  YJ      Used cast for UDF2, UDF3 (S2G-855)
  2018/05/04  YJ      Used cast for EDIFunctionalCode, PrevSKU (S2G-810)
  2018/04/18  TD      Sending ShipVia On order if the order was not added to a load.(HPI-1875)
  2018/03/30  TD      Added OrderDetail UDFs (HPI-1843)
  2018/03/17  AY      Standardized ReceiverRef fields, PrevSKU, ShipViaSCAC and relieved UDFs (S2G-379)
  2018/03/14  DK      Added SourceSystem (FB-1111)
  2012/02/24  SV      Mapped the Receiver's info Export's UDF5 to UDF10 (S2G-225)
  2018/02/10  AY      Exports: Added TransDate for selections & grouping
  2017/12/07  VM      OB Specific - Send mapped ShipVia to RH based on certain rules (OB-670)
  2017/12/04  YJ      Modified check for FreightCharges, used coalesce (SRI-780)

  2017/10/06  CK      Include remaining order UDFs (OB-617)
  2017/10/05  VM      Include remaining order UDFs (OB-617)

  2017/08/25  PK      Added Mapping to send customer requested ShipVia codes for DICKDS customer (OB-548).
  2017/01/05  NY      Implemented rules to get FreightCharges (OB-466)
  2016/09/07  AY      Mapped RecvRet for ReverseReceipt (HPI-587)
  2016/08/31  AY      Capture freight charges using rules and Export from table  (HPI-531)
  2016/08/30  AY      Send LoadId in ShipOH/OD records when shipped against a Load. (HPI-546)
  2016/07/15  DK      Made changes to send Freightcharges as zero for HPI in case 3rd party billing (HPI-216).
  2016/06/28  VM      OB wants to charge AcctNetCharge (discounted rate) to Canadian Orders (OB-427)
  2016/05/18  AY      International Orders have multiple labels, duplicating exports - temp fixed by
                        filtering by LabelType = S
  2016/04/10  AY      Mapped UDF2 to ShipVia.SCAC or Carrier
  2016/04/05  NB      Build RecordType with TransType+TransEntity for Recv-RV transactions(NBD-89)
  2016/03/14  NY      Freight Charges- Added condition to get it from Ship Label type (FB-640)
  2016/02/15  NB      Introduced FreightTerms transformation to host value using mapping (NBD-102)
  2016/02/11  NB      modified CartonDimension format to send as LxBxH without quotes(NBD-103)
  2016/02/09  TK      Used join condition to retrieve Freight charge instead of sub query (NBD-142)
  2016/02/05  TK      Added ShipViaDescription (NBD-142)
              AY      ShipVia to be exported is from Shipments, not Order Header.
  2016/02/02  NB      EDI Transaction code for 'InvCh' is 947(NBD-104)
  2016/01/28  DK      Made changes to get underlying BoL instead of Maser BoL (FB-610)
  2016/01/27  TK      Added TrackingNumber, BillToName, ShipToName, SoldToName, CartonDimensions, EDIShipmentNumber (NBD-103)
  2015/11/19  VM      UDF3 - Cast to varchar as it is mapped to ReceiverDate (FB-531)
  2015/10/28  PK      Returning SoldToId from UDF4 field.
  2015/09/30  AY      Setup RecordType for Returns transactions
  2015/08/21  RV      Cast UDF1 field (mapped with FreightCharges) to avoid mismatch with data layer (FB-301)
  2015/06/23  PK      FB specific: Mapping ReceiverNumber, ReceiverDate, BolNumber, ClientLoad to
                        UDF2, UDF3, UDF4, UDF5.
  2015/06/12  YJ      Added ExpiryDate field.
  2015/06/04  PK      Mapping host SCAC codes.
  2015/05/09  PK      Mapped L.UDF4 to ShipVia.

  2015/05/04  PK      Mapped FreightCharges to E.UDF1 field.
  2015/04/22  PK      Mapped TrackingNo to Reference field.
  2015/01/20  VM      Added MasterBoL
  2014/12/29  TK      Issue fix: to update LoadNumber for shipment exports.
  2014/08/27  VM      When FreightTerms is 'INVOICE', export freight charges to host
  2014/08/27  AY      Define Monetary Value
  2014/07/12  PK      ReceiptNumber: On Recv transactions Mapping with LPN.ReceiptNumber.
  2014/05/28  PK      RecordType - Picking transactions have diff. RecordTypes
  2014/05/27  VM      Joined with Mapping table for client specific reason codes
  2014/05/09  PKS     Converted ReasonCode from short int to varchar, because we are passing
                      TargetValue (varchar 120) if Export.ReasonCode is null
  2014/04/25  DK      UDF11 is used to send ReceiverNumber in case of consolidated exports
  2014/03/03  PKS     Added ReceiverNumber, ReceiverDate, ReceiverBoL  and UDF1 to UDF30
                      Made changes to consider CustPO of Exports table
  2014/02/14  NY      Exports: Added additional UDF's.
  2014/02/03  TD      Mapping reference to UDF1(Receiver Number) if those are of type Receiving.
  2014/01/27  TD      Added UDFs.
  2014/01/20  TD      Added FromLocation, ToLocation.
  2013/12/30  TD      Added join with Pallet to show Pallet instead of showing from LPNs.
  2013/11/21  TD      Changes to avoid duplicate records.
  2013/11/10  TD      Changes to Map Reasoncodes.
  2013/11/01  VM      OB specific - Do not send frieght charges if the Freight Terms is/are SENDER
  2013/10/17  VM      OB specific - Do not send frieght charges for 3POINT5.COM customer packages
  2013/08/09  VM      Populate LPN weight into weight for shipped transactions
  2013/08/06  AY      Added HostLocation
  2013/08/05  TD      Added Length, Width, Height.
  2013/08/01  VM      Export Freight Charges only when the Frieght Terms is SENDER, if TransEntity is LPN.
  2013/06/10  PK      Added RecordType - Cancel PT trasnactions have different RecordTypes
  2013/04/20  AY      CustPO: For Recv transactions return ROD.CustPo else OH.CustPO
                      Change to export FreightCharges for ShipLPN records
  2013/04/18  PK      Added ContainerSize, BillNo, SealNo, InvoiceNo, ContainerNo, ETACountry,
                        ETACity, ETAWarehouse, Account, AccountName, TotalVolume, TotalWeight,
                        TotalSalesAmount, TotalTax, TotalShippingCost, TotalDiscount, FreightCharges,
                        FreightTerms, BillToAccount, BillToAddress.
  2012/11/16  SP      Added Archived field.
  2012/10/26  VM      Added ShippedDate (from Loads)
  2012/10/15  VM      Get Load details from OrderShipment's load for ShipOH RecordType
  2012/09/24  SP      Added "LD_" as suffix for UDF's of Loads.
                      Added   LoadNumber, BoL, LoadShipVia, UCCBarcode, TrailerNumber,
                      and UDF1...UDF10 fields. Added "Pallet" field.
  2012/09/11  AY      Added RecordType - Shipping transactions have diff. RecordTypes
  2012/07/17  AY      Added Exports.Warehouse
  2011/10/07  VM      Added LPNDetail.SerialNo
  2011/07/06  PK      Added UDF's fields from all tables, and also added SKU1 - SKU5 from SKU table.
  2011/02/16  PK      Added UDF's, removed 'HostReceiptLine' from values.
  2011/02/04  PK      Removed joing with views and joined with appropriate tables.
  2011/01/22  VK      Added TransTypeDescription,TransEntityDescription and
                      StatusDescription
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwExports') is not null
  drop View dbo.vwExports;
Go

Create View dbo.vwExports (
  RecordId,

  RecordType,
  TransType,
  TransTypeDescription,
  TransEntity,
  TransEntityDescription,
  TransQty,
  AbsTransQty,

  TransDateTime,
  ExportStatus,
  ExportStatusDesc,
  Status,
  StatusDescription,
  ProcessedDateTime,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  Description,
  UoM,
  UPC,
  Brand,
  SKU_SortSeq,
  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,    --TI
  SKU_UDF5,    --HI
  SKU_UDF6,
  SKU_UDF7,
  SKU_UDF8,
  SKU_UDF9,
  SKU_UDF10,

  /* LPN */
  LPNId,
  LPN,
  LPNType,
  LPNShipmentId,
  LoadId,
  ASNCase,
  UCCBarcode,
  TrackingNo,
  CartonDimensions,

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

  /* Counts */
  NumPallets,
  NumLPNs,
  NumCartons,

  /* LPN Details */
  LPNDetailId,
  LPNLine,
  Innerpacks,
  Quantity,
  UnitsPerPackage,
  ReceivedUnits,
  SerialNo,

  LPND_UDF1,
  LPND_UDF2,
  LPND_UDF3,
  LPND_UDF4,
  LPND_UDF5,

  /* Location */
  LocationId,
  Location,
  HostLocation,
  LocationType,
  StorageType,
  PickingZone,
  PutawayZone,

  /* RO Hdr */
  ReceiptId,
  ReceiptNumber,
  ReceiptType,
  Vessel,
  ContainerSize,
  BillNo,
  SealNo,
  InvoiceNo,
  ContainerNo,
  ETACountry,
  ETACity,
  ETAWarehouse,

  RH_UDF1,
  RH_UDF2,
  RH_UDF3,
  RH_UDF4,
  RH_UDF5,

  /* RO Details */
  ReceiptDetailId,
  ReceiptLine,
  VendorId,
  CoO,
  UnitCost,
  HostReceiptLine,

  ReasonCode,
  Warehouse,
  Ownership,
  SourceSystem,
  ExpiryDate,
  Weight,
  Volume,
  Length,
  Width,
  Height,
  InnerPacksPerLPN,

  RD_UDF1,
  RD_UDF2,
  RD_UDF3,
  RD_UDF4,
  RD_UDF5,

  /* Receiver Details */
  ReceiverNumber,
  ReceiverDate,
  ReceiverBoL,
  ReceiverRef1,
  ReceiverRef2,
  ReceiverRef3,
  ReceiverRef4,
  ReceiverRef5,

  /* Sales Order Header */
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  ShipToStore,
  SoldToId,
  SoldToName,
  ShipToId,
  ShipToName,
  ShipVia,
  ShipViaDescription,
  ShipViaSCAC,
  ShipFrom,
  CustPO,
  Account,
  AccountName,
  TotalVolume,
  TotalWeight,
  TotalSalesAmount,
  TotalTax,
  TotalShippingCost,
  TotalDiscount,
  FreightCharges,
  FreightTerms,
  BillToAccount,
  BillToName,
  BillToAddress,

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
  OH_UDF11,
  OH_UDF12,
  OH_UDF13,
  OH_UDF14,
  OH_UDF15,
  OH_UDF16,
  OH_UDF17,
  OH_UDF18,
  OH_UDF19,
  OH_UDF20,
  OH_UDF21,
  OH_UDF22,
  OH_UDF23,
  OH_UDF24,
  OH_UDF25,
  OH_UDF26,
  OH_UDF27,
  OH_UDF28,
  OH_UDF29,
  OH_UDF30,

  /* Sales Order Detail */
  OrderDetailId,
  OrderLine,
  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsToAllocate,
  RetailUnitPrice,
  CustSKU,
  HostOrderLine,

  Reference,
  ExportBatch,
  TransDate,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,

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

  /* Loads */
  LoadNumber,
  ClientLoad,
  DesiredShipDate,
  ShippedDate,
  BoL,
  LoadShipVia,
  TrailerNumber,
  ProNumber,
  SealNumber,
  MasterBoL,
  LoadType,

  LD_UDF1,
  LD_UDF2,
  LD_UDF3,
  LD_UDF4,
  LD_UDF5,
  LD_UDF6,
  LD_UDF7,
  LD_UDF8,
  LD_UDF9,
  LD_UDF10,

  /* EDI */
  EDIShipmentNumber,
  EDITransCode,
  EDIFunctionalCode,

  /* ShipToAddress */
  ShipToAddressLine1,
  ShipToAddressLine2,
  ShipToCity,
  ShipToState,
  ShipToCountry,
  ShipToZip,
  ShipToPhoneNo,
  ShipToEmail,
  ShipToReference1,
  ShipToReference2,
  Comments,

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
  UDF21,
  UDF22,
  UDF23,
  UDF24,
  UDF25,
  UDF26,
  UDF27,
  UDF28,
  UDF29,
  UDF30,

  /* Future Use */
  PrevSKUId,
  PrevSKU,
  PalletId,
  Pallet,
  FromWarehouse,
  ToWarehouse,
  FromLPNId,
  FromLPN,
  FromLocationId,
  FromLocation,
  ToLocationId,
  ToLocation,
  Lot,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,
  InventoryKey,
  MonetaryValue,
  ShipmentId
  /* Future Use */

) As
select
  E.RecordId,

  /* RecordType */
  case
    when ((E.TransType = 'Ship') or (E.TransType = 'PTCancel') or
          (E.TransType = 'Pick') or (E.TransType = 'Return') --or
          --((E.TransType = 'Recv') and (E.TransEntity ='RV'))
          ) then
      E.TransType + E.TransEntity
    when E.TransType = 'Recv' and E.TransQty < 0 then 'RecvRet'
    else E.TransType
  end,
  /* TransType */
  E.TransType,

  TRN.TypeDescription,
  E.TransEntity,
  TE.TypeDescription,
  case when E.TransType = 'Recv' then abs(E.TransQty)
       else E.TransQty
  end,
  abs(E.TransQty),

  E.TransDateTime,
  E.Status,
  PF.LookUpDescription,
  E.Status,
  PF.LookUpDescription,
  E.ProcessedDateTime,

  E.SKUId,
  SKU.SKU,
  SKU.SKU1,
  SKU.SKU2,
  SKU.SKU3,
  SKU.SKU4,
  SKU.SKU5,
  SKU.Description,
  SKU.UoM,
  case when E.TransType in ('UPC+', 'UPC-') then E.Reference else SKU.UPC end,
  SKU.Brand,
  SKU.SKUSortOrder,

  SKU.UDF1,
  SKU.UDF2,
  SKU.UDF3,
  SKU.UDF4,
  SKU.UDF5,
  SKU.UDF6,
  SKU.UDF7,
  SKU.UDF8,
  SKU.UDF9,
  SKU.UDF10,

  E.LPNId,
  L.LPN,
  L.LPNType,
  L.ShipmentId,
  coalesce(E.LoadId, L.LoadId),
  L.ASNCase,
  L.UCCBarcode,
  L.TrackingNo,
  /* Carton Dimensions */
  cast(CT.OuterLength as varchar)+ 'x' + cast(CT.OuterWidth as varchar) + 'x' + cast(CT.OuterHeight as varchar),

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

  E.NumPallets,
  E.NumLPNs,
  E.NumCartons,

  E.LPNDetailId,
  LPND.LPNLine,
  coalesce(E.InnerPacks, LPND.Innerpacks),
  coalesce(E.Quantity, LPND.Quantity),
  case when E.TransType = 'SKUCh' then SKU.UnitsPerInnerPack else LPND.UnitsPerPackage end,
  LPND.ReceivedUnits,
  LPND.SerialNo,

  LPND.UDF1,
  LPND.UDF2,
  LPND.UDF3,
  LPND.UDF4,
  LPND.UDF5,

  E.LocationId,
  LOC.Location,
  MLOC.TargetValue,
  LOC.LocationType,
  LOC.StorageType,
  LOC.PickingZone,
  LOC.PutawayZone,

  E.ReceiptId,
  coalesce(nullif(L.ReceiptNumber, ''), RH.ReceiptNumber),
  RH.ReceiptType,
  RH.Vessel,
  RH.ContainerSize,
  RH.BillNo,
  RH.SealNo,
  RH.InvoiceNo,
  coalesce(R.Container, RH.ContainerNo, CR.Container),
  RH.ETACountry,
  RH.ETACity,
  RH.ETAWarehouse,

  RH.UDF1,
  RH.UDF2,
  RH.UDF3,
  RH.UDF4,
  RH.UDF5,

  E.ReceiptDetailId,
  RD.ReceiptLine, --deprecated
  RD.VendorId,
  RD.CoO,
  RD.UnitCost,
  RD.HostReceiptLine,

  coalesce(MCCRC.TargetValue, convert(varchar, E.ReasonCode)),
  E.Warehouse,
  E.Ownership,
  E.SourceSystem,
  L.ExpiryDate,

  case when ((E.TransType = 'Ship') and (E.TransEntity = 'LPN')) then coalesce(L.LPNWeight, E.Weight) else E.Weight end,
  case when ((E.TransType = 'Ship') and (E.TransEntity = 'LPN')) then coalesce(L.LPNVolume, E.Volume) else E.Volume end,
  E.Length,
  E.Width,
  E.Height,
  SKU.InnerPacksPerLPN,

  RD.UDF1,
  RD.UDF2,
  RD.UDF3,
  RD.UDF4,
  RD.UDF5,

  /* Receiver Details */
  coalesce(R.ReceiverNumber, E.ReceiverNumber, E.UDF11),
  coalesce(R.ReceiverDate, CR.ReceiverDate),
  coalesce(R.BoLNumber, CR.BoLNumber),
  coalesce(R.Reference1, CR.Reference1),
  coalesce(R.Reference2, CR.Reference2),
  coalesce(R.Reference3, CR.Reference3),
  coalesce(R.Reference4, CR.Reference4),
  coalesce(R.Reference5, CR.Reference5),

  E.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OH.ShipToStore,
  E.SoldToId,
  E.SoldToName,
  E.ShipToId,
  E.ShipToName,
  E.ShipVia,
  E.ShipViaDesc, /* ShipViaDescription */
  E.SCAC,

  OH.ShipFrom,
  case when E.TransType = 'Recv' then RD.CustPO else OH.CustPO end,
  OH.Account,
  OH.AccountName,
  OH.TotalVolume,
  OH.TotalWeight,
  OH.TotalSalesAmount,
  OH.TotalTax,
  OH.TotalShippingCost,
  OH.TotalDiscount,
  E.FreightCharges,
  -- case
  --   when OH.FreightTerms = '3RDPARTY' and OH.BusinessUnit= 'HPI' then
  --     0
  --   when TransType = 'Ship' and TransEntity = 'LPN' and E.Reference is not null then
  --     (select ListNetCharge from ShipLabels where EntityType = 'L' and LabelType = 'S' and EntityKey = L.LPN and TrackingNo = E.Reference and BusinessUnit = E.BusinessUnit)
  --   when TransType = 'Ship' and TransEntity = 'OH' then
  --     OH.FreightCharges
  --   else
  --     null
  -- end /* FreightCharges */,
  coalesce(MCFT.TargetValue, OH.FreightTerms),
  OH.BillToAccount,
  BTA.Name,
  OH.BillToAddress,

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
  OH.UDF11,
  OH.UDF12,
  OH.UDF13,
  OH.UDF14,
  OH.UDF15,
  OH.UDF16,
  OH.UDF17,
  OH.UDF18,
  OH.UDF19,
  OH.UDF20,
  OH.UDF21,
  OH.UDF22,
  OH.UDF23,
  OH.UDF24,
  OH.UDF25,
  OH.UDF26,
  OH.UDF27,
  OH.UDF28,
  OH.UDF29,
  OH.UDF30,

  E.OrderDetailId,
  OD.OrderLine,
  OD.UnitsOrdered,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  (OD.UnitsAuthorizedToShip - OD.UnitsAssigned),
  OD.RetailUnitPrice,
  OD.CustSKU,
  OD.HostOrderLine,

  case when E.TransType = 'Ship' then L.TrackingNo
       else E.Reference
  end, /* Reference */
  E.ExportBatch,
  E.TransDate,

  E.Archived,
  E.BusinessUnit,
  E.CreatedDate,
  E.ModifiedDate,
  E.CreatedBy,
  E.ModifiedBy,

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

  coalesce(LD.LoadNumber,      SLD.LoadNumber     ),
  coalesce(LD.ClientLoad,      SLD.ClientLoad     ),
  coalesce(LD.DesiredShipDate, SLD.DesiredShipDate),
  coalesce(LD.ShippedDate,     SLD.ShippedDate,   case when E.TransType = 'Ship' then E.TransDateTime else null end),
  BoL.VICSBoLNumber,
  coalesce(LD.ShipVia,         SLD.ShipVia        ),
  coalesce(LD.TrailerNumber,   SLD.TrailerNumber  ),
  coalesce(LD.ProNumber,       SLD.ProNumber      ),
  coalesce(LD.SealNumber,      SLD.SealNumber     ),
  SLD.MasterBoL,
  LD.LoadType,

  coalesce(LD.UDF1,  SLD.UDF1),
  coalesce(LD.UDF2,  SLD.UDF2),
  coalesce(LD.UDF3,  SLD.UDF3),
  coalesce(LD.UDF4,  SLD.UDF4),
  coalesce(LD.UDF5,  SLD.UDF5),
  coalesce(LD.UDF6,  SLD.UDF6),
  coalesce(LD.UDF7,  SLD.UDF7),
  coalesce(LD.UDF8,  SLD.UDF8),
  coalesce(LD.UDF9,  SLD.UDF9),
  coalesce(LD.UDF10, SLD.UDF10),

  /* EDI */
  L.LPN, -- temporary /* EDIShipmentNumber - Need to know which field does LPN contains EDI Shipment Number*/
  case
    when TransType = 'InvCh' then 947
    when TransType = 'Ship'  then 945
    when TransType = 'Recv'  then 861
    else null
  end, /* EDITransCode */
  cast(' ' as varchar(50)), /* EDIFunctionalCode */

  /* ShipToAddress */
  E.ShipToAddressLine1 ,
  E.ShipToAddressLine2,
  E.ShipToCity,
  E.ShipToState,
  E.ShipToCountry,
  E.ShipToZip,
  E.ShipToPhoneNo,
  E.ShipToEmail,
  E.ShipToReference1,
  E.ShipToReference2,
  E.Comments,

  case when (E.TransType = 'Ship') and (E.TransEntity = 'LPN') then CT.CartonType else E.UDF1 end, /* Carton Type */
  E.UDF2,
  E.UDF3,
  E.UDF4,
  E.UDF5,
  E.UDF6,
  E.UDF7,
  E.UDF8,
  E.UDF9,
  E.UDF10,
  E.UDF11,
  E.UDF12,
  E.UDF13,
  E.UDF14,
  E.UDF15,
  E.UDF16,
  E.UDF17,
  E.UDF18,
  E.UDF19,
  E.UDF20,
  E.UDF21,
  E.UDF22,
  E.UDF23,
  E.UDF24,
  E.UDF25,
  E.UDF26,
  E.UDF27,
  E.UDF28,
  E.UDF29,
  E.UDF30,

  /* Future Use */
  E.PrevSKUId,
  cast(' ' as varchar(50)), /* PrevSKU */ -- Need to get SKU for PrevSKUId for SKU change record
  E.PalletId,
  P.Pallet,-- Currently we are updating in Pallet on LPN in some case and in some cases we are not updating--
  E.FromWarehouse,
  E.ToWarehouse,

  E.FromLPNId,
  E.FromLPN,
  E.FromLocationId,
  case when E.FromLocation = 'LOST' then E.FromLocation
       when E.FromLocation <> 'LOST'then 'PICKSTOR'  else E.FromLocation end,
  E.ToLocationId,
  case when E.ToLocation = 'LOST' then E.ToLocation
       when E.ToLocation <> 'LOST'then 'PICKSTOR'  else E.ToLocation end,
  E.Lot,
  E.InventoryClass1,
  E.InventoryClass2,
  E.InventoryClass3,
  E.InventoryKey,
  coalesce(E.MonetaryValue, E.TransQty * SKU.UnitCost),
  E.ShipmentId
  /* Future Use */
from
Exports E
  left outer join SKUs             SKU   on (E.SKUId             = SKU.SKUId         )
  left outer join LPNs             L     on (E.LPNId             = L.LPNId           )
  left outer join LPNDetails       LPND  on (E.LPNDetailId       = LPND.LPNDetailId  )
  left outer join Locations        LOC   on (E.LocationId        = LOC.LocationId    )
  left outer join ReceiptHeaders   RH    on (E.ReceiptId         = RH.ReceiptId      )
  left outer join ReceiptDetails   RD    on (E.ReceiptDetailId   = RD.ReceiptDetailId)
  left outer join Receivers        R     on (R.ReceiverNumber    = L.ReceiverNumber  )
  left outer join Receivers        CR    on (CR.ReceiverNumber   = E.ReceiverNumber  ) /* for consolidated receiver exports */
  left outer join OrderDetails     OD    on (E.OrderDetailId     = OD.OrderDetailId  )
  left outer join OrderHeaders     OH    on (E.OrderId           = OH.OrderId        )
  left outer join vwOrderShipments OSH   on (OH.OrderId          = OSH.OrderId       ) and
                                            (E.LoadId            = OSH.LoadId        ) and
                                            (OSH.ShipmentStatus = 'S' /* Shipped */  )
  left outer join Shipments        SH    on (OSH.ShipmentId      = SH.ShipmentId     )
  left outer join Bols             BoL   on (SH.BoLId            = BoL.BoLId)
  left outer join Loads            SLD   on (SH.LoadId           = SLD.LoadId        )
  left outer join EntityTypes      TRN   on (E.TransType         = TRN.TypeCode      ) and
                                            (TRN.Entity          = 'Transaction'     ) and
                                            (TRN.BusinessUnit    = E.BusinessUnit    )
  left outer join EntityTypes      TE    on (E.TransEntity       = TE.TypeCode       ) and
                                            (TE.Entity           = 'TransEntity'     ) and
                                            (TE.BusinessUnit     = E.BusinessUnit    )
  left outer join LookUps          PF    on (E.Status            = PF.LookUpCode     ) and
                                            (PF.LookUpCategory   = 'ProcessedFlag'   ) and
                                            (PF.BusinessUnit     = E.BusinessUnit    )
  left outer join Loads            LD    on (E.LoadId            = LD.LoadId         )
  left outer join Mapping          MLOC  on (MLOC.SourceSystem   = 'CIMS'            ) and
                                            (MLOC.EntityType     = 'Location'        ) and
                                            (MLOC.SourceValue    = LOC.Location      )
  left outer join Mapping          MCCRC on (MCCRC.SourceSystem  = 'CIMS'            ) and
                                            (MCCRC.EntityType    = 'ReasonCode'      ) and
                                            (MCCRC.SourceValue   = E.ReasonCode      )
  left outer join Pallets          P     on (P.PalletId          = E.PalletId        )
  left outer join Contacts         BTA   on (BTA.ContactRefId    = OH.BillToAddress  ) and  /* Bill To Address */
                                            (BTA.ContactType     = 'B' /* Bill To */ )
  left outer join CartonTypes      CT    on (L.CartonType        = CT.CartonType     ) and
                                            (L.BusinessUnit      = CT.BusinessUnit   )
  --left outer join ShipVias         SV    on (SH.ShipVia          = SV.ShipVia        )
  -- left outer join ShipLabels       SL    on (SL.EntityKey        = L.LPN             ) and
  --                                           (SL.TrackingNo       = E.Reference       ) and
  --                                           (SL.BusinessUnit     = E.BusinessUnit    ) and
  --                                           (SL.EntityType       = 'L' /* LPN */     ) and
  --                                           (SL.LabelType        = 'S' /* Shipping */)
  left outer join Mapping          MCFT  on (MCFT.SourceSystem   = 'CIMS'            ) and
                                            (MCFT.TargetSystem   = 'HOST'            ) and
                                            (MCFT.EntityType     = 'FreightTerms'    ) and
                                            (MCFT.SourceValue    = OH.FreightTerms   )

;
Go
