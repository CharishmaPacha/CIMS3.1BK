/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/06  AY      TMapping: Added Status (BK-393)
  2021/03/19  RKC     TImportInvAdjustments: Initial revision (HA-2341)
  2021/03/13  VM      TOpenOrdersSummary: Added LoadDesiredShipDate, AppointmentDateTime (HA-2275)
  2021/03/02  PK      Added ClientLoad to TExportsType table domain (HA-2109)
  2021/02/20  PK      Added DesiredShipDate to TExportsType table domain (HA-2029)
  2021/02/15  TD      Added new domain TExportCarrierTrackingInfo (BK-207)
  2021/01/06  RKC     TSKUImportType: Changed the data type for HarmonizedCode field (CID-1616)
  2020/01/22  AY      TExportsType: Added NumPallets, NumLPNs, NumCartons, Quantity (HA-1896)
  2020/08/12  SK      TOpenOrdersSummary: New table type for exporting open order summary (HA-1267)
  2020/05/15  KBB     Need to change ReasonCode data type and setup HA reason codes (HA-544)
  2020/05/13  MS      TImportValidationType: Added HostOrderLine
                      TOrderDetailsImportType: Added not null constraints for Primary Columns (HA-483)
  2020/03/20  YJ      TASNLPNImportType: Added InventoryClass1 to InventoryClass3
                      TASNLPNHeaderImportType: UDF Renamed as LH_UDF1 to 5 and Removed from 6-30 UDF's
                      TASNLPNDetailImportType: Added InventoryClass1 to 3, and UDF Renamed as LD_UDF1 to 5 and Removed from 6-25 UDF's
                      TOnhandInventoryExportType, TOrderDetailsImportType, TExportsType: Added InventoryClass1 to InventoryClass3
                      TSKUImportType: UDF's Renamed as SKU_UDF1 to 30, TSKUPrepacksImportType: SPP_UDF1 to 5
                      TReceiptHeaderImportType: Removed RH_UDF11 to RH_UDF30
                      TReceiptDetailImportType: Added Lot, InventoryClass1 to InventoryClass3 and Removed RD_UDF11 to 30, TContactImportType: Added CT_UDF1 to 5
  2020/03/19  YJ      TOrderDetailsImportType: Removed OrderLine and changed UDF1 to 10 as OD_UDF1 to 10 and also added OD_UDF11 to 30
                      TSKUImportType: Added UDF11 to 30 and Removed SKUValidations, AuditTrail
                      TSKUPrepacksImportType: Added MasterSKU1 to 5, ComponentSKU1 to ComponentSKU5
                      TReceiptHeaderImportType: Added RH_UDF6 to RH_UDF30
                      TReceiptDetailImportType: Removed NextLineNo, ReceiptLine and added RD_UDF11 to RD_UDF30 (CIMS-2984)
  2020/02/25  SJ      TReceiptHeaderImportType: Modified Archived field (JL-48)
  2019/12/23  TD      TASNLPNImportType,TASNLPNDetailImportType- Added HostReceiptLine(CID-1233)
  2019/11/28  RKC     TExportsType:Added ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry, ShipToZip,
                        ShipToPhoneNo, ShipToEmail, ShipToReference1, ShipToReference2 (CID-1175)
  2019/09/24  RKC     TSKUImportType ,TImportValidationType:Added CartonGroup
                      TOrderHeaderImportType:Added CartonGroup (S2GCA-929)
  2019/08/29  RKC     TContactImportType: Added AddressLine3 (HPI-2711)
                      TOrderHeaderImportType: Added ShipToAddressLine3
  2019/08/06  KBB     Added DeliveryStart & DeliveryEnd fields for Orders (S2GCA-891)
  2019/07/24  RIA     TLocationImportType: Added SKUId and SKUStatus (S2GCA-867)
  2019/07/12  KBB     TOrderHeaderImportType: Added ShipCompletePercent field (CID-533)
  2019/06/28  VS      TOnhandInventoryExportType: To Show UPC in Onhandinventory Export (CID-659)
  2019/02/26  PK      TOrderDetailsImportType: Added ParentLineId, ParentHostLineNo.
  2019/03/22  TD      TNoteImportType:Added EntityLineNo(HPI-2530)
  2019/02/22  RIA     TASNLPNImportType, TASNLPNHeaderImportType: Changed LPNId type (CID-87)
  2019/02/05  TD      TASNLPNImportType,TReceiptHeaderImportType:Added HostNumLines(CID-44)
  2019/02/04  TD      TASNLPNHeaderImportType,TASNLPNImportType  (CID-66)
  2019/02/02  AY      Earlier TASNLPNImportType renamed to TASNLPNHeaderImportType
                      Introduced TASNLPNImportType which is combination of Hdr + Dtl (HPI-2360)
  2019/01/25  HB      TASNLPNImportType: Added RecordType,ActualWeight,InnerPacks,Quantity,PalletId,ReceiptId
                        ,ShipmentId,LoadId,Status,InventoryStatus,OnhandStatus,InputXML,ResultXML
                      TASNLPNDetailImportType: Added RecordType,UnitsPerPackage,ReceiptId,ReceivedUnits,InputXML,ResultXML
                      TImportValidationType : Added LPNType,DestWarehouse (HPI-2360)
  2019/01/23  VM      TReceiptDetailValidationType: Added ReceiptStatus (HPI-2349)
  2018/04/25  TK      TReceiptDetailValidationType: Added QtyInTransit (HPI-1886)
  2018/05/24  RT      TLocationImportType: Added LocationClass and SKU
                      TImportValidationType : Added LocationClass (S2GCAN-24)
  2018/04/26  RV      TRouterConfirmationImportType: Intial version (S2G-233)
  2018/04/05  YJ      TSKUImportType: Added CaseUPC(S2G-528)
  2018/03/29  SV      TOnhandInventoryExportType: Added SourceSystem (HPI-1845)
  2018/03/28  TD      TOrderHeaderImportType:Changes to update HostNumLines (HPI-1831)
  2018/03/22  DK      TOrderHeaderImportType, TImportValidationType: Added SourceSystem (FB-1117)
  2018/03/22  DK      TOrderHeaderImportType, ROHImportType, SKUImportType: Added SourceSystem (FB-1117)
  2018/03/21  SV      TOpenOrderExportType, TOpenReceiptExportType, TExportsType Added SourceSystem field (S2G-379)
  2018/03/17  RT      TOrderHeaderImportType: Updated Status Field Type (HPI-1815)
  2018/03/16  AY      TOrderHeaderImportType: Added HostNumLines
  2018/03/16  SV      TOnhandInventoryExportType: Added Warehouse field (S2G-437)
  2018/03/15  SV      TExportsType: Added the missing fields to send the complete exports to DE db (S2G-379)
  2018/02/06  RT      Added NestingFactor and DefaultCoO fields in TSKUImportType (S2G-19)
  2018/01/31  OK      Changed the ExpiryDate datatype to TDate as caller sending TDate type data (S2G-187)
  2018/01/31  SV      TInventoryExportType: Corrected to TOnhandInventoryExportType, added other required fields (S2G-188)
  2017/11/28  TD/SV   Added TASNLPNImportType, TASNLPNDetailImportType, TCartonImportType,
                        TSKUPrePackImportType, TUPCImportType (CIMSDE-33)
                      Added TInventoryExportType, TOpenOrderExportType, TOpenReceiptExportType,
                        TShippedLoadsExportType (CIMSDE-34)
  2017/11/27  TD      Added TExports : (CIMSDE-15)
  2017/11/27  SV      TReceiptHeaderImportType: Added HostRecId (CIMSDE-17)
                      TReceiptDetailImportType: Added HostRecId (CIMSDE-18)
  2017/12/22  PK      Added TNoteImportType (CIMS-1722).
  2017/11/09  TD      TSKUImportType, TImportValidationType - added HostRecId (CIMSDE-14)
  2017/09/06  DK      TOrderHeaderImportType: Added CarrierOptions (FB-1020)
  2017/08/23  SV      TOrderHeaderImportType: Included UDF11 to UDF30 (OB-548)
  2017/05/26  NB      TReceiptDetailImportType: Added RecordType column(HPI-1396)
  2017/05/15  OK      Added TLocationImportType (CIMS-1339)
  2017/04/11  DK      TOrderHeaderImportType, TContactImportType: Added ShipToResidential, DeliveryRequirement (CIMS-1289)
  2016/09/01  KL      Added ReceiptType in TReceiptDetailValidationType  and TReceiptDetailImportType (HPI-512)
  2016/07/04  TK      TReceiptDetailValidationType: Added Key Data (HPI-231)
  2016/06/01  KL      Added UoM field in TImportValidationType (HPI-97)
  2016/05/25  NB      Added RecordType to TReceiptHeaderImportType(NBD-552)
  2016/04/07  AY      TOrderHeaderImportType: Removed not null constraints.
  2016/03/01  YJ      TOrderHeaderImportType: Added field ReceiptNumber, And TSKUImportType: SKUSortOrder (CIMS-780)
  2016/01/10  DK      Added ReasonCode field in TReceiptDetailImportType (FB-596)
  2015/12/10  AY      TImportValidationType: Added more fields for generic use
  2015/12/03  OK      TReceiptDetailValidationType: Added the Ownership fields(NBD-58)
  2015/10/16  AY      TOrderDetailsImportType: Added OHStatus, Ownership
                      TEDIProcessMap: Added for EDI processing
  2015/10/30  TK      Changed Datatype of CartonType (ACME-393)
  2015/09/30  DK      Added PickTicket field in TReceiptHeaderImportType (FB-416).
  2015/09/01  OK      Added TMapping type (CIMS-607).
  2015/08/27  AY      TImportValidationType: Added EntityType & Status
  2015/08/17  NY      Added SKU for TReceiptDetailValidationType
  2015/08/05  YJ      Added missing fields for TImportValidationType.
  2015/07/09  SK      Extended Unique constraint for TContactImportType including RecordId (LL-206).
  2015/07/01  OK      Added the TCartonTypesValidation,TCartonTypesImportType types.
  2015/01/08  SK      Added TContactImportType
  2015/02/13  SV      Moved TWarehouse to Domains_Inventory.
  2014/12/03  SV      Added fields in TReceiptHeaderImportType
  2014/12/02  SK      Added TReceiptDetailImportType, TReceiptDetailValidationType
  2014/12/01  SK      Added TReceiptHeaderImportType
  2014/11/27  SK      Added TSKUPrepacksImportValidation, TSKUPrepacksImportType
  2014/11/18  SK      Added TSKUAttributeImportType
  2014/10/22  YJ      Added TOrderHeaderImportType
  2014/10/20  NB      Added TSKUImportType
  2014/08/05  AY      Added TWorkId for SDI-WCS Interface
  2014/05/14  NB      Added TOrderDetailsImportType, TImportValidationType
  2014/04/21  AY      Added TRecordTypes
  2011/02/07  VK      Added TWarehouse with varchar(10).
  2010/12/14  PK      Created TProcedureName, TRecordType.
  2010/12/13  PK      Created domain for TTransferType, TReasonType
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/* Uploads */
Create Type TTransactionType           from char(1);            Grant References on Type:: TTransactionType           to public;
Create Type THostReceiptLine           from varchar(10);        Grant References on Type:: THostReceiptLine           to public;
Create Type TReasonCode                from varchar(20);        Grant References on Type:: TReasonCode                to public;
Create Type TBatch                     from integer;            Grant References on Type:: TBatch                     to public;

/* ImportExportLog */
Create Type TTransferType              from varchar(50);        Grant References on Type:: TTransferType              to public;
Create Type TReasonType                from varchar(50);        Grant References on Type:: TReasonType                to public;
Create Type TProcedureName             from varchar(50);        Grant References on Type:: TProcedureName             to public;
Create Type TRecordType                from varchar(50);        Grant References on Type:: TRecordType                to public;
Create Type TRecordTypes               from varchar(250);       Grant References on Type:: TRecordTypes               to public;

/* DCMS */
Create Type TWorkId                    from varchar(300);       Grant References on Type:: TWorkId                    to public;

Go
