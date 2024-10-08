/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/24. AY      TCarrierPackagesInfo: Added CI related fields (CIMSV3-3434)
  2024/02/19  RV      TCarrierResponseNotifications: Added SeverityLevel (CIMSV3-3396)
  2024/02/16  AY      TCarrierPackagesInfo: Added LabelReference[1-5]/[Type.Value] for FedEx API (CIMSV3-3395)
  2023/12/05  AY      TCarrierPackagesInfo: Added PackageWeight (JLFL-320)
  2023/08/21  RV      TCarrierPackagesInfo: Added DimensionUoM
                      TCarrierShipmentData: Added OrderDate and ReceiverTaxId (CIMSV3-2760)
  2023/08/16  RV      TCarrierPackagesInfo: Initial Version
                      TCarrierShipmentData: Added OrderDate, CarrierOptions, TotalPackages, LabelFormatType, LabelStockType etc, (JLFL-320)
  2023/03/20  VS      TCarrierResponseData: Added BillToAccount (JLFL-297)
  2023/03/20  VS      TShipLabels: Added FreightTerms, BillToAccount (JLFL-297)
  2023/02/24  SK      TCarrierTrackingData: Added SourceSystem (BK-1025)
  2023/01/13  RV      TShipLabels: Added Notifications (OBV3-1613)
  2023/01/10  RV      TCommoditiesInfo, TPackingListDetails: Added UnitCost, LineTotalCost and LineTotalPrice (OBV3-1653)
  2022/12/23  VS      TCarrierShipmentData: Added PackageWeight and Volume (OBV3-1363)
  2022/12/09  AY      TCommoditiesInfo: Added ProductInfo1/2/3 (OBV3-1586)
  2022/12/08  RKC     Added TStatusGroup (OBV3-1559)
  2022/11/18  VS      TCarrierShipmentData: Added ShipToInfo (OBV3-1447)
  2022/11/17  AY      TCarrierShipmentData: To hold several pieces of data for carrier integration (OBV3-1447)
  2022/11/07  SK/AY   TCarrierTrackingEventData: New Type (BK-956)
  2022/11/05  RV      TShipLabels: Added MessageType (OBV3-1361)
  2022/11/04  VS      TCarrierResponseNotifications: Initial Version (OBV3-1353)
  2022/10/26  VS      TShipppingAccountDetails: Initial Version (OBV3-1301)
  2022/10/18  VS      TCarrierResponseData: Initial version (CIMSV3-1780)
  2021/11/26  RV      TShipLabels: InsertRequired changed TFlag to TFlags (CIMSV3-1746)
  2021/07/30  OK      Added TCommoditiesInfo (BK-382)
  2021/07/30  RV      TPackingListDetails: Added LineType (OB2-1960)
  2021/07/02  AY      TShipLabels: Added LabelsRequired & ShipmentType (CIMSV3-1525)
  2021/06/28  RV      TPackingListDetails: DisplaySKU and DisplaySKUDesc (OB2-1822)
  2021/06/13  TK      TShipLabels: Added APIWorkFlow (BK-349)
  2021/06/04  MS      TLPNShipLabelData: Added new fields WaveSeqNo & NumOrders (BK-344)
  2021/04/22  SAK     TManifestLPNDetails and TShippingManifestDetails: Added fields LPNInventoryClass1..,InventoryClass1.. (HA-2674)
  2021/04/08  AY      TShippingManifestDetails: Added OrderId, SortOrder (HA-2572)
  2021/03/24  RV      TBoLLPNs: Added BOD_ShipperInfo (HA-2390)
  2021/03/16  OK      TShippingLogData: Changed the data type of DesiredShipDate and CancelDate to TDateTime as original table data is type of TDateTime (HA-2291)
  2021/03/13  OK      TShippingLogData: Added LoadType, LoadStatus and ShipToId (HA-2264)
  2021/03/10  AY      TShippingLogData: (HA-1093)
  2021/02/19  AY      TLPNsToLoad: Renamed status as LPNStatus (HA-2002)
  2021/02/02  AY/RT   TBoLLPNs: Included Reference feilds and Added to summarize LPNs on a BoL
                      TBoLCarrierDetails and TBoLCustomerOrderDetails: new reference fields (FB-2225/HA-1954)
  2021/01/31  TK      TLPNsToLoad: Added fields that are required to Create Shipments in bulk (HA-1947)
  2021/01/06  RKC     TPackingListDetails: Changed the data type for HarmonizedCode field (CID-1616)
  2020/01/24  AY      TLPNsToLoad: Added LoadNumber, BoLNumber (HA-1947)
  2020/01/05  RT      TManifestLPNDetails, TShippingManifestDetails: Included LPNLot and LPNLot (HA-1849)
  2020/11/13  RKC     Added TLoadAddOrders (HA-1610)
  2020/10/20  PK      TLPNShipLabelData: Included OD_UDF11..OD_UDF30 - Port back from HA Prod/Stag by VM (HA-1483)
  2020/09/30  KBB     Added TShippingLogData (HA-1093)
  2020/09/23  PHK     TPackingListDetails: Added NumCartons (HA-1308)
  2020/09/01  RKC     TShippingManifestDetails, TManifestLPNDetails: Added ShipCartons (HA-1304)
  2020/07/24  RT      TLPNsToLoad: Added (S2GCA-970)
  2020/07/09  VM      TLPNShipLabelData: Add CustSKU (Deprecate CustomerSKU) (HA-1130)
  2020/07/07  VM      TLPNShipLabelData: Add LPNNumLines,LPNNumSKUs,LPNNumSizes (HA-1072)
  2020/06/30  VM      TLPNShipLabelData: Add SCCBarcode (HA-1037)
  2020/06/26  VM      TLPNShipLabelData: Add OH_UDF11..OH_UDF30 (HA-1037)
  2020/06/25  VM      TLPNShipLabelData: Added SKUSizeScale, SKUSizeSpread (HA-1013)
  2020/06/24  AY      TLPNContents: Return data set of pr_ShipLabel_GetLPNContents (HA-1013)
  2020/05/26  RV      TLPNShipLabelData: Commented out Label image type - causing conversion issue (HA-667)
  2020/01/21  TK      TLPNsToLoad: Added (S2GCA-970)
  2020/01/07  MJ      TLPNContentsLabelData, TLPNShipLabelData: Added ShipToAddress3 (CID-1240)
  2019/12/09  AY      TShipLabel_PriceStickers_GetData: DataSet that is returned by price stickers procedure (CID-933)
  2019/09/14  AY      TLabelsToPrint: Added Account
  2019/08/20  RT      TPackingListDetails: Included OD_UDF11 to 20 (CID-944)
  2019/08/11  AY      TLabelListToPrint: Added AdditionalContent (CID-909)
  2019/08/07  AY      TDocumentListToPrint: Added Action, options to save documents (CID-901)
  2019/08/02  AY      TLabelListToPrint & TDocumentListToPrint: Added new fields for presentation (CID-884)
  2019/07/31  AY      TLabelListToPrint: Added (CID-884)
  2019/07/30  PHK     TLPNShipLabelData : Added WaveType (CID-751)
  2019/07/18  MJ      TLPNContentsLabelData: Added PackedBy (CID-822)
  2019/07/16  AY/RV   TLPNShipLabelData: Changed ShipVia domain type to TShipVia (CID-806)
  2019/07/04  KSK     TPackingListDetails: Added the HarmonizedCode,CoO (CID-632)
  2019/06/27  RV      TDocumentListToPrint: Renamed from TOutboundDocsToPrint and added new fields and cleaned up TStaticDocsToPrint (CID-630)
  2019/06/26  RV      TOutBoundDocsToPrint: Added (CID-612)
  2019/04/24  MS      Added LPNWeight in TLPNShipLabelData (CID-420)
  2019/05/23  RT      TLabelsToPrint: PackageSeqNo,LPNsAssigned,OrderStatus (CID-365)
  2019/04/18  RV      TLPNShipLabelData: Added Label and IsValidTrackingnNo (CID-210)
  2019/04/12  AJ      TPackingListDetails: Added Brand (CID-219)
  2019/04/10  MS      Added TLPNContentsLabelData & TLPNContentLabelDetails (CID-221)
  2019/03/29  OK      Added PDNote to type TPackingListDetails (HPI-2541)
  2019/03/26  MJ      TLPNShipLabelData: Added AlternateLPN (CID-209)
  2019/03/20  VS      Added ShipFrom Column in TLabelsToPrint (CID-188)
  2019/03/08  VM      Moved V3 specific domains to V3 branch files (CIMSV3-406)
  2019/03/19  MJ      TLPNShipLabelData: Added UOM (CID-174)
  2019/02/27  PHK     TPalletShipLabelData: Added NumCases (S2GMI-88)
  2019/01/21  RT      Added LoadNumber, AddressRegion, Operation, DocSubType, CustPOsOnPallet in TLabelsToPrint (S2GMI-39)
  2019/01/21  RT      Added LoadNumber in TLabelsToPrint (S2GMI-76)
  2019/01/16  RV      Added TCarrierInterface (S2GCA-434)
  2019/01/11  RT/PHK  Added ShipFromPhoneNo, ShipToCountry, NumLPNs and PalletSeqNo, ClientLoad, LoadNumber,SpecialInstructions and Pallet UDFs in TPalletShipLabelData (S2GMI-39)
  2018/11/28  RV      TAESNumber, TShipmentRefNumber: Added (S2G-1177)
  2018/10/09  AY      TManifestLPNDetails, TShippingManifestDetails: Added (S2GCA-357)
  2018/09/18  NB      TDocumentsToPrint added Weight, CartonType, ReturnTrackingNo + additional columns (CIMSV3-221)
  2018/09/07  NB      TDocumentsToPrint added with ParentRecordId, PrinterDataStream (CIMSV3-221)
  2018/08/27  NB      Added TDocumentsToPrint(CIMSV3-221)
  2018/06/08  VM      TBoLCustomerOrderDetails: Included UDF1..5 (S2G-923)
  2018/05/10  MJ      TLPNShipLabelData: Added required fields (S2G-803)
  2018/05/07  AY      Added TLoadGroup (S2G-830)
  2018/04/30  RV      Added ShipFromAddr2 to TPalletShipLabelData (S2G-765)
  2018/04/27  RV      Added TPalletShipLabelData (S2G-686)
  2018/04/05  MJ      Added field MarkForAddress in TLPNShipLabelData (SRI-862)
  2016/08/26  OK      Added the SortOrder and changed the data types for Value fields(HPI-520)
  2016/08/02  RV      TPackingListDetails: UnitsBackOrdered renamed as BackOrdered.
  2016/07/20  YJ      Added more fields to type TPackingListDetails (HPI-330)
  2016/06/27  PSK     TLPNShipLabelData: Added LPNLot (HPI-173).
  2016/06/19  DK      TLPNShipLabelData: Added Account and AccountName (HPI-169)
  2016/02/18  TK      Added TMeterNumber, TAccessKey (LL-276)
  2015/11/09  SV      TLabelsToPrint: Added Carrier field (LL-248)
  2015/10/27  AY      TLPNShipLabelData: Added new fields to be in sync with procedure
  2015/08/14  AY      TLabelsToPrint: Added LPNPrintFlags, PalletPrintFlags and UDF1..5
  2015/07/23  AY      TLabelsToPrint: Added EntityType, DocumentType, BusinessUnit & Ownership
  2015/07/12  AY      TLabelsToPrint: Added LPNId, OrderId, TaskId and other fields for future use to be used in rules
  2015/06/19  YJ      Added TAccountName, And Correction for type TBoLCID.
  2015/06/18  AY      TBoLCID and TShipToLocation added
  2015/06/14  VM      TLPNShipLabelData: Fieds considered as case sensitive in bartender label, hence corrected NumberofCartons
  2015/02/06  PKS     TLPNShipLabelData:Added Warehouse.
  2015/02/04  PKS     Column NumLabels renamed to NumberofLabels
  2014/09/11  PK      TLPNShipLabelData: TaskId
  2014/07/30  PKS     TLPNShipLabelData: Added PickZone, PickedBy, Location Row, Level and Section
  2014/06/13  SV      Added TLabelsToPrint.
  2013/07/26  AY      Added TBoL and TVICSBoL - deprecating TBoLNumber and TVICSBoLNumber
                        as those are not per our convention
  2013/01/04  TD      Added PageNumber to the TBoLCustomerOrderDetails,
                      TBoLCarrierDetails.
  2012/12/30  AY      Added TBoLCarrierDetails and TBoLCustomerOrderDetails
  2012/12/07  TD      Added New domain TVICSBoLNumber,TBoLId.
  2012/06/19  NB      New Domains for Shipping Functionality.
  2011/08/29  NB      Initial revision.
------------------------------------------------------------------------------*/

Go

Create Type TTrackingNo                from varchar(60);        Grant References on Type:: TTrackingNo                to public;
Create Type TShippingLabel             from image;              Grant References on Type:: TShippingLabel             to public;
Create Type TCarrier                   from varchar(50);        Grant References on Type:: TCarrier                   to public;
Create Type TCarrierInterface          from varchar(50);        Grant References on Type:: TCarrierInterface          to public;
Create Type TTrailerNumber             from varchar(60);        Grant References on Type:: TTrailerNumber             to public;
Create Type TPackingListType           from varchar(30);        Grant References on Type:: TPackingListType           to public;
Create Type TSealNumber                from varchar(60);        Grant References on Type:: TSealNumber                to public;
Create Type TProNumber                 from varchar(60);        Grant References on Type:: TProNumber                 to public;
Create Type TAESNumber                 from varchar(60);        Grant References on Type:: TAESNumber                 to public;
Create Type TShipmentRefNumber         from varchar(60);        Grant References on Type:: TShipmentRefNumber         to public;
Create Type TBoL                       from varchar(60);        Grant References on Type:: TBoL                       to public;
Create Type TVICSBoL                   from varchar(60);        Grant References on Type:: TVICSBoL                   to public;
Create Type TBoLNumber                 from varchar(60);        Grant References on Type:: TBoLNumber                 to public;
Create Type TVICSBoLNumber             from varchar(60);        Grant References on Type:: TVICSBoLNumber             to public;
Create Type TBoLId                     from integer;            Grant References on Type:: TBoLId                     to public;
Create Type TBoLCID                    from varchar(60);        Grant References on Type:: TBoLCID                    to public;
Create Type TShipToLocation            from varchar(60);        Grant References on Type:: TShipToLocation            to public;
Create Type TAccountName               from varchar(60);        Grant References on Type:: TAccountName               to public;
Create Type TMeterNumber               from varchar(60);        Grant References on Type:: TAccountName               to public;
Create Type TAccessKey                 from varchar(60);        Grant References on Type:: TAccountName               to public;
Create Type TLoadGroup                 from varchar(100);       Grant References on Type:: TLoadGroup                 to public;
Create Type TStatusGroup               from varchar(20);        grant references on Type:: TStatusGroup               to public;

Go
