/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/21  SRP     Added New fields included as per SKU Velocity and (BK-813)
  2022/03/02  LAC     Added SKUImageURL, IsBaggable (BK-775)
  2022/02/17  SRS     Added New fields included as per LocationReplenishLevels (BK-764)
  2021/10/12  RV      Added PackGroupKey (BK-636)
  2021/06/22  RV      HasNotes: Caption changed to Notes and align center (OB2-1883)
  2021/06/17  SGK     Added SKU_SortSeq (HA-2907)
  2021/05/25  PKK     Added PrepackCode (HA-2840)
  2021/05/22  PKK     Added CartonizationModel and MaxUnitsPerCarton (HA-2813)
  2021/05/08  SAK     Added New field DownloadedOn (HA-2703)
  2021/05/02  AY      Added AbsTransQty and LoadType
  2021/04/29  VS      Added UnitsRequiredtoActivate, UnitsReservedForWave, ToActivateShipCartonQty (HA-2417)
  2021/03/31  KBB     Added BoLStatus (HA-2467)
  2021/03/16  RV      EstimatedCartons: Added display format (HA Golive)
  2021/03/13  SK      Modified field attributes as per requirement (HA-2270)
  2021/03/11  KBB     Added AppointmentTime, Count4, Count5, UDFDesc1-5 (HA-1093)
  2021/03/11  SAK     Added Fields AbsPercentUnitsChange,CCV_UDF1..CCV_UDF5 (HA-2247)
  2021/03/09  KBB     Added missing Fields from vwCycleCountResults (HA-2198)
  2021/03/05  SJ      Added fields CarrierCheckIn, CarrierCheckOut (HA-2137)
  2021/02/05  MS      Added RunningCount1, RunningCount2, RunningCount3, Count3 (BK-156)
  2021/02/04  SK      Added NumCartons (HA-1986)
  2021/02/04  KBB     Changed IsSelectable for MonetaryValue (OB2-1616)
  2021/02/03  TK      Added EstimatedCartons (HA-1964)
  2021/02/03  KBB     Changed IsSelectable for PutawayZone (OB2-1610)
  2021/01/20  SAK     Changed the DisplayFormat for Unit and case fields to display four digits (HA-1803)
  2020/12/23  SJ      Changed the visibility for SKU Case Dimension fields (HA-1804)
  2020/12/23  AY      Added RoutingStatusDesc (HA-1101)
  2020/11/22  RV      Report: Added new and Corrected the fields (CIMSV3-1189)
  2020/11/19  MS      Added RC_UDF1 to RC_UDF5 & vwRC_UDF1 to vwRC_UDF5 (JL-314)
  2020/11/18  KBB     Added ServiceClassDesc, ServiceClass (HA-1670)
  2020/11/17  YJ      Added SerialNoStatus, SerialNoStatusDesc (CIMSV3-1212)
  2020/11/05  MS      Added LPN_UDF11 to LPN_UDF20, RI_UDF1 to RI_UDF5, SortLanes, SortOptions & SortStatus (JL-294)
  2020/11/03  VM      Report format related fields added (CIMSV3-1189)
  2020/10/23  SAK     Changed IsSelectable  as Y for ProdCategoryDesc, ProdSubCategoryDesc (JL-147)
  2020/10/21  TK      Added FromLPNId & FromLPN (HA-1516)
  2020/10/17  SJ      Added new field VendorSKU (JL-48)
  2020/10/14  AY      Added UoMs for Dimensions/Weight/Volume (CIMSV3-1108)
  2020/10/12  YJ      Added new field ShipToCityState (HA-1559)
  2020/10/05  SK      Added new fields for productivity (HA-1479)
  2020/10/05  RBV     Added PickMethod Field (CID-1488)
  2020/09/28  MS      Added ExternalRecId & DivertDateTime (JL-65)
  2020/09/22  RV      Added NumCopies (CIMSV3-1079)
  2020/09/17  HYP     Added the Newfields (HA-796)
  2020/09/13  MS      Changed visibility of ReceiptDetailId (JL-236)
  2020/09/12  AY      Added ComittedQty (OB2-1199)
  2020/09/11  AY      Changed ShipViaDesc caption as code and desc had same caption causing confusion (HA-493)
  2020/09/08  SK      Added LabelStockSizes, ReportStockSizes for PrintJobs (HA-1233)
  2020/08/28  RKC     Added CreatedOn (CIMSV3-195)
  2020/08/28  SAK     Added Fields NumLabels and NumReports,
                      Added Fields Count1 and Count2 (HA-887)
  2020/08/13  MS      Added Interfacelog UDF's and Status Fields
                      Defined DisplayFormat for LogDate,LogDateTime (HA-283)
  2020/08/12  RKC     Added PasswordPolicy, InvalidPasswordAttempts, LockedTime, IsLocked, PasswordExpiryDate (S2G-1409)
  2020/07/30  RV      Added PrintStatus (S2GCA-1199)
  2020/07/29  MS      TaskDependencies Fields corrected (HA-1004)
  2020/07/16  MS      LocationType, LocationTypeDesc, StorageType & StorageTypeDesc visibilities changed (CIMSV3-548)
                      Added New Fields CC_LocUDF1 to 10, PolicyCompliant, LocationABCClass
  2020/07/16  KBB     Changed IsSelectable as Y in TaskSubTypeDescription (CIMSV3-1023)
  2020/07/10  RKC     Added StagingLocation, LoadingMethod, Palletized fileds (HA-1106)
  2020/06/17  AY      Added Task Detail fields DetailDependencyFlags, DetailDestLocation, DetailDestZone
  2020/06/17  SAK     Added Fields NumLabels and NumReports (HA-887)
  2020/06/17  SAK     Added Fields FieldGroups and CultureName (CIMSV3-971)
  2020/06/15  TK      Added UniqueId (HA-938)
  2020/06/13  RV      Added LoadStatusDesc (HA-908)
  2020/06/12  OK      Added MasterTrackingNo (HA-843)
  2020/06/05  KBB     Added NumCases, CarrierOptions (HA-804)
  2020/06/03  MS      Reverted back IsSelectable for PalletTypeDesc, PalletStatus, PalletStatusDesc (HA-805)
  2020/05/30  AJ      Changed IsSelectable for PalletTypeDesc, PalletStatus, PalletStatusDesc (HA-718)
  2020/05/29  TK      Added NumTasks (HA-691)
  2020/05/20  MS      Added LPNStatusDesc (HA-604)
  2020/05/19  MS      Added WaveGroup (HA-593)
  2020/05/19  MS      Added UserId (HA-Support)
  2020/05/18  MS      Added Fields related to Notifications (HA-580)
  2020/05/15  TK      Added NewSKU & NewInventoryClasses (HA-543)
  2020/05/15  RKC     Added new field ShipCompletePercent (HA-553)
                      Changes to display '0' value for PercentPicksComplete (HA-557)
  2020/05/13  SV      Added missing fields from Layouts and LayoutFields table (HA-305)
  2020/05/01  RT      Included InvAllocationModel (HA-312)
  2020/04/28  MS      Added OrderStatus & Corrections to Field visibilities (HA-293)
  2020/04/25  SAK     Added Field LocationSubTypeDesc (HA-263)
  2020/04/20  MS      Added ExportStatusDesc (HA-232)
  2020/04/16  AY      set FieldVisible = -3 for id fields PalletId, LPNId etc
  2020/04/06  OK      Added V3 status fields (HA-132)
  2020/03/31  OK      Added PrinterPort and StockSize (HA-46)
  2020/03/31  MS      Sync with Base/Init_Fields (CIMSV3-786)
  2020/03/30  TK      Added RolePermissionKey (HA-69)
  2020/03/29  MS      Changes to generate Fields based on System Version (CIMSV3-786)
  2020/03/29  MS      Added UserStatus (CIMSV3-467)
  2020/03/28  TK      Added RolePermission related fields (HA-68)
  2020/03/27  HYP     Migrated from Base/Init_Fields (CIMSV3-779)
  2020/03/27  MS      Added InventoryClasses (HA-77)
  2020/03/20  MS      Visibility changed to -2 for PalletType (JL-111)
  2020/03/12  MS      Added ReceiverStatus & ReceiverStatusDesc (CIMSV3-750)
  2020/03/11  MS      Added LocationStatus,LocationStatusDesc (CIMSV3-749)
  2020/03/09  AJM     Added ShipViaSCAC field in shipvias (JL-49)
  2020/03/09  SJ      Added CartonGroup field in CIMSDE (JL-48)
  2020/03/06  SJ      Added HostNumLines, InputXML fields in CIMSDE (JL-48)
  2020/02/20  AJM     Added some fields in Receivers, Receipts, SKU (JL-49)
  2020/02/19  AY      Added PalletStatus/PalletStatusDesc (JL-104)
  2020/02/17  SJ      Added Result field (JL-48)
  2020/02/16  KBB     Added ProcessedOn/RouteLPN fields(JL-62)
  2020/02/13  KBB     Added Exported on field (JL-62)
  2020/02/11  AY      Added all LPN_UDF fields (JL-75)
------------------------------------------------------------------------------*/

Go

declare @vSystemVersion TVarchar,
        @vBusinessUnit  TVarchar;

declare @ttFields TFieldsTable;

/*----------------------------------------------------------------------------*/
/* Field Properties:

  This file is organized by Entity, alphabetically ordered by EntityName. All
   Generic fields are at the end - please keep it that way.

  Do not specify value for Alignment - let it be default unless you would like
    to change default

*/
/*----------------------------------------------------------------------------*/

insert into @ttFields
             (FieldName,               Caption,                 Width, Visible, Alignment, MaxLength, IsSelectable, DisplayFormat)

/*----------------------------------------------------------------------------*/
/* Allocation Rules Fields */
      select  'ConsiderRuleGroup',     'Consider Rule Group',     120,       1,      null,      null,         null, null
union select  'OrderByField',          'Order By Field',          100,       1,      null,      null,         null, null
union select  'OrderByType',           'Order By Type',           100,       1,      null,      null,         null, null
union select  'Alignment',             'Alignment',                85,       1,      null,      null,         null, null
union select  'RuleGroup',             'Rule Group',               80,       1,      null,      null,         null, null
union select  'SearchOrder',           'Search Order',             85,       1,      null,      null,         null, null
union select  'SearchSet',             'Search set',               80,       1,      null,      null,         null, null
union select  'SearchType',            'Search Type',              85,       1,      null,      null,         null, null
union select  'WaveTypeDescription',   'Wave Type',               110,       1,      null,      null,         null, null
union select  'QuantityCondition',     'QuantityCondition',       110,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Audit Trail */
union select  'AuditId',               'AuditId',                  80,      -2,      null,      null,         null, null
union select  'ActivityDateTime',      'Activity Date',           120,       1,      null,      null,         null, null
union select  'ActivityType',          'Activity Type',            70,       1,      null,      null,         null, null
union select  'Comment',               'Comment',                 250,       1,      null,      null,         null, null
union select  'ActivityAge',           'Activity Age',             35,       1,      null,      null,         null, null
union select  'EntityDetails',         'Entity Details',           40,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* BackOrderSKUs */
union select  'TotalStock',            'Total Stock',             100,       1,      null,      null,         null, null
union select  'TotalAvailableQty',     'Total Avail Qty',         100,       1,      null,      null,         null, null
union select  'TotalReservedQty',      'Total Reserved Qty',      130,       1,      null,      null,         null, null
union select  'UnitsBackOrdered',      'Units Back Ordered',      130,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* BillTo Address */

union select  'BillToAddressId',       'Bill To Address',         100,      -1,      null,      null,         null, null
union select  'BillToAddressName',     'Bill To Address Name',    120,      -1,      null,      null,         null, null
union select  'BillToAddressLine1',    'Bill To AddressLine1',    120,      -1,      null,      null,         null, null
union select  'BillToAddressLine2',    'Bill To AddressLine2',    120,      -1,      null,      null,         null, null

union select  'BillToCity',            'Bill To City',            100,      -1,      null,      null,         null, null
union select  'BillToState',           'Bill To State',           100,      -1,      null,      null,         null, null
union select  'BillToZip',             'Bill To Zip',             100,      -1,      null,      null,         null, null
union select  'BillToCountry',         'Bill To Country',         100,      -1,      null,      null,         null, null
union select  'BillToPhoneNo',         'Bill To PhoneNo',         100,      -1,      null,      null,         null, null
union select  'BillToEmail',           'Bill To Email',           100,      -1,      null,      null,         null, null

union select  'BillToAddressCity',     'Bill To City',            100,      -1,      null,      null,         null, null
union select  'BillToAddressState',    'Bill To Address State',   120,      -1,      null,      null,         null, null
union select  'BillToAddressZip',      'Bill To AddressZip',      120,      -1,      null,      null,         null, null
union select  'BillToAddressCountry',  'Bill To Country',         100,      -1,      null,      null,         null, null
union select  'BillToAddressPhoneNo',  'Bill To Address PhoneNo', 120,      -1,      null,      null,         null, null
union select  'BillToAddressEmail',    'Bill To Email',           100,      -1,      null,      null,         null, null

union select  'BillToContactId',       'Bill To ContactId',       100,      -2,      null,      null,         null, null
union select  'BillToContactAddrId',   'Bill To Contact AddrId',  130,      -2,      null,      null,         null, null
union select  'BillToOrgAddrId',       'Bill To Org AddrId',      105,      -2,      null,      null,         null, null
union select  'BillToContactRefId',    'Bill To Contact RefId',   120,      -2,      null,      null,         null, null
union select  'BillToContactPerson',   'Bill To Contact Name',    120,      -1,      null,      null,         null, null
union select  'BillToAddressReference1',
                                       'Bill To Addr Reference1', 120,      -1,      null,      null,         null, null
union select  'BillToAddressReference2',
                                       'Bill To Addr Reference2', 120,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* BoL */
union select  'BoLId',                 'BoLId',                     0,      -2,      null,      null,         null, null
union select  'BoLNumber',             'BoL',                      75,       1,      null,      null,         null, null
union select  'VICSBoLNumber',         'VICS BoL',                130,       1,      null,      null,         null, null
union select  'BoLType',               'Type',                     80,      -1,      null,      null,         null, null
union select  'BoLTypeDesc',           'Type',                     80,       1,      null,      null,         null, null
union select  'MasterBoL',             'Master BoL',              130,       1,      null,      null,         null, null
union select  'BoLStatus',             'BoL Status',              100,       1,      null,      null,         null, null
union select  'ShipToLocation',        'Location #',              100,       1,      null,      null,         null, null
union select  'BoLCID',                'CID #',                    90,      -1,      null,      null,         null, null
union select  'FoB',                   'FoB',                      40,      -1,      null,      null,         null, null
union select  'BoLInstructions',       'Special Instructions',    200,       1,      null,      null,         null, null

union select  'BoL_UDF1',              'BoL_UDF1',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF2',              'BoL_UDF2',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF3',              'BoL_UDF3',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF4',              'BoL_UDF4',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF5',              'BoL_UDF5',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF6',              'BoL_UDF6',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF7',              'BoL_UDF7',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF8',              'BoL_UDF8',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF9',              'BoL_UDF9',                 60,      -2,      null,      null,         null, null
union select  'BoL_UDF10',             'BoL_UDF10',                60,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* BoL Carrier Details */
union select  'BoLCarrierDetailId',    'BoLCarrierDetailId',       60,      -1,      null,      null,         null, null
union select  'HandlingUnitQty',       'HU Qty',                   55,       1,      null,      null,         null, null
union select  'HandlingUnitType',      'HU Type',                  60,       1,      null,      null,         null, null
union select  'PackageQty',            'Pkg Qty',                  55,       1,      null,      null,         null, null
union select  'PackageType',           'Pkg Type',                 60,       1,      null,      null,         null, null
union select  'Hazardous',             'Hazardous',                70,      -1,      null,      null,         null, null
union select  'CommDescription',       'Commodity Description',   250,       1,      null,      null,         null, null
union select  'NMFCCode',              'NMFC#',                    75,       1,      null,      null,         null, null
union select  'CommClass',             'Class',                    50,       1,      null,      null,         null, null

union select  'BCD_UDF1',              'BCD UDF1',                 80,      -1,      null,      null,         null, null
union select  'BCD_UDF2',              'BCD UDF2',                 80,      -1,      null,      null,         null, null
union select  'BCD_UDF3',              'BCD UDF3',                 80,      -1,      null,      null,         null, null
union select  'BCD_UDF4',              'BCD UDF4',                 80,      -1,      null,      null,         null, null
union select  'BCD_UDF5',              'BCD UDF5',                 80,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* BoL Order Details */
union select  'BoLOrderDetailId',      'BoL Order DetailId',       20,      -1,      null,      null,         null, null
union select  'CustomerOrderNo',       'Customer Order No',       150,       1,      null,      null,         null, null
union select  'Palletized',            'Pallet/Slip',              60,       1,      null,      null,         null, null
union select  'ShipperInfo',           'Additional Shipper Info.',250,       1,      null,      null,         null, null

union select  'BOD_UDF1',              'BOD UDF1',                 80,      -1,      null,      null,         null, null
union select  'BOD_UDF2',              'BOD UDF2',                 80,      -1,      null,      null,         null, null
union select  'BOD_UDF3',              'BOD UDF3',                 80,      -1,      null,      null,         null, null
union select  'BOD_UDF4',              'BOD UDF4',                 80,      -1,      null,      null,         null, null
union select  'BOD_UDF5',              'BOD UDF5',                 80,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* BusinessUnits */
union select  'BusinessUnitName',      'Business Name',            80,       1,      null,      null,         null, null
union select  'BusinessUnitDesc',      'Business Name',           100,       1,      null,      null,         null, null
union select  'HostCode',              'Host Code',                50,       1,      null,      null,         null, null
union select  'CreatedByName',         'Created By',               80,      -1,      null,      null,         null, null
union select  'ModifiedByName',        'Modified By',              80,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Carton Groups */
union select  'CartonGroup',           'Carton Group',            100,      -1,      null,      null,          'Y', null
union select  'CartonGroupDesc',       'Carton Group',            100,      -2,      null,      null,         null, null
union select  'CartonGroupDisplayDesc','Carton Group & Desc',     100,      -2,      null,      null,         null, null

union select  'MaxInnerDimension',     'Max Inner Dimension',      90,      -1,      null,      null,         null, null
union select  'FirstDimension',        'First Dimension',          90,      -1,      null,      null,         null, null
union select  'SecondDimension',       'Second Dimension',         90,      -1,      null,      null,         null, null
union select  'ThirdDimension',        'Third Dimension',          90,      -1,      null,      null,         null, null

union select  'AvailableSpace',        'Available Space',          90,       1,      null,      null,         null, '{0:###,###,###}'
union select  'CGT_Status',            'Carton Group/Type Status', 80,       1,      null,      null,         null, null

union select  'CG_Status',             'Carton Group Status',      80,      -1,      null,      null,         null, null
union select  'CG_SortSeq',            'Carton Group SortSeq',     80,      -1,      null,      null,         null, null
union select  'CG_Visible',            'Carton Group Visible',     80,      -2,      null,      null,         null, null

union select  'CG_AvailableSpace',     'CG Available Space',      110,       1,      null,      null,         null, null
union select  'CG_MaxWeight',          'CG Max Weight',           120,       1,      null,      null,         null, null
union select  'CG_MaxUnits',           'CG Max Units',             90,       1,      null,      null,         null, null

union select  'CG_UDF1',               'CG_UDF1',                  90,      -2,      null,      null,         null, null
union select  'CG_UDF2',               'CG_UDF2',                  90,      -2,      null,      null,         null, null
union select  'CG_UDF3',               'CG_UDF3',                  90,      -2,      null,      null,         null, null
union select  'CG_UDF4',               'CG_UDF4',                  90,      -2,      null,      null,         null, null
union select  'CG_UDF5',               'CG_UDF5',                  90,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Carton Types */
union select  'CartonType',            'Carton Type',              80,      -1,      null,      null,         null, null
union select  'CartonTypeId',          'Carton Type Id',           80,      -2,      null,      null,         null, null
union select  'CartonTypeDesc',        'Carton Type Desc',        110,      -1,      null,      null,         null, null
union select  'CartonTypeDisplayDesc', 'Carton Type & Desc',      110,      -1,      null,      null,         null, null

union select  'EmptyWeight',           'Empty Weight',             90,       1,      null,      null,         null, null

union select  'CT_InnerDimensions',    'Carton Type Inner Dims',   80,      -1,      null,      null,         null, null
union select  'InnerLength',           'Inner Length',             80,       1,      null,      null,         null, null
union select  'InnerWidth',            'Inner Width',              80,       1,      null,      null,         null, null
union select  'InnerHeight',           'Inner Height',             80,       1,      null,      null,         null, null
union select  'InnerVolume',           'Inner Volume',             90,       1,      null,      null,         null, null

union select  'CT_OuterDimensions',    'Carton Type Outer Dims',   80,      -2,      null,      null,         null, null
union select  'OuterLength',           'Outer Length',             90,      -2,      null,      null,         null, null
union select  'OuterWidth',            'Outer Width',              80,      -2,      null,      null,         null, null
union select  'OuterHeight',           'Outer Height',             90,      -2,      null,      null,         null, null
union select  'OuterVolume',           'Outer Volume',             90,      -2,      null,      null,         null, null

union select  'CT_AvailableSpace',     'CT Available Space',      110,      -1,      null,      null,         null, null
union select  'CT_MaxWeight',          'CT Max Weight',           120,      -1,      null,      null,         null, null
union select  'CT_MaxUnits',           'CT Max Units',             90,      -1,      null,      null,         null, null

union select  'CT_Status',             'Carton Type Status',       80,      -1,      null,      null,         null, null
union select  'CT_SortSeq',            'Carton Type SortSeq',      80,      -1,      null,      null,         null, null
union select  'CT_Visible',            'Carton Type Visible',      90,      -2,      null,      null,         null, null

union select  'CT_UDF1',               'CT_UDF1',                  90,      -2,      null,      null,         null, null
union select  'CT_UDF2',               'CT_UDF2',                  90,      -2,      null,      null,         null, null
union select  'CT_UDF3',               'CT_UDF3',                  90,      -2,      null,      null,         null, null
union select  'CT_UDF4',               'CT_UDF4',                  90,      -2,      null,      null,         null, null
union select  'CT_UDF5',               'CT_UDF5',                  90,      -2,      null,      null,         null, null

union select  'CartonTypeFilter',      'Carton Group',            120,      -2,      null,      null,         null, null
union select  'CarrierPackagingType',  'Carrier Packing Type',    130,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Contacts */
union select  'ContactId',             'ContactId',                80,      -3,      null,      null,         null, null
union select  'ContactRefId',          'Contact Key',              90,      -1,      null,      null,         null, null
union select  'ContactType',           'Contact Type',            100,      -2,      null,      null,          'Y', null
union select  'ContactTypeDesc',       'Contact Type',             80,       1,      null,      null,          'N', null
union select  'Name',                  'Name',                    180,       1,      null,      null,         null, null
union select  'AddressLine1',          'Address Line 1',          180,       1,      null,      null,         null, null
union select  'AddressLine2',          'Address Line 2',          180,       1,      null,      null,         null, null
union select  'AddressLine3',          'Address Line 3',          180,      -1,      null,      null,         null, null
union select  'City',                  'City',                     70,       1,      null,      null,         null, null
union select  'State',                 'State',                    80,       1,      null,      null,         null, null
union select  'Country',               'Country',                  80,       1,      null,      null,         null, null
union select  'Zip',                   'Zip',                      80,       1,      null,      null,         null, null
union select  'CityStateZip',          'City/State/Zip',          120,       1,      null,      null,         null, null
union select  'PhoneNo',               'Phone No',                 95,       1,  'Center',      null,         null, null
union select  'ContactPerson',         'Contact Person',          120,       1,      null,      null,         null, null
union select  'ContactAddrId',         'Contact Address Id',      100,      -2,      null,      null,         null, null
union select  'OrgAddrId',             'Organization Address Id', 150,      -2,      null,      null,         null, null
union select  'AddressReference1',     'Address Reference1',      120,      -1,      null,      null,         null, null
union select  'AddressReference2',     'Address Reference2',      120,      -1,      null,      null,         null, null
union select  'Reference1',            'Reference1',              120,      -1,      null,      null,         null, null
union select  'Reference2',            'Reference2',              120,      -1,      null,      null,         null, null
union select  'Reference3',            'Reference3',              120,      -1,      null,      null,         null, null
union select  'VendorContactId',       'VendorId',                 80,      -3,      null,      null,         null, null
union select  'OrganizationContactRefId',
                                       'Organization Contact Ref Id',
                                                                  120,      -2,      null,      null,         null, null
union select  'PrimaryContactRefId',   'Primary Contact Ref Id',  100,      -2,      null,      null,         null, null
union select  'Residential',           'Residential',              70,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Control */
union select  'ControlCategory',       'Category',                120,       1,      null,      null,         null, null
union select  'ControlCode',           'Code',                     80,       1,      null,      null,         null, null
union select  'DataType',              'Data Type',                90,      -2,      null,      null,          'Y', null
union select  'DataTypeDescription',   'Data Type',                90,       1,      null,      null,          'N', null
union select  'ControlValue',          'Control Value',           250,       1,      null,      null,         null, null
union select  'CategorySortSeq',       'Category Sort Order',     120,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Customers */
union select  'CustomerId',            'CustomerId',               80,      -2,      null,      null,         null, null
union select  'CustomerName',          'Customer Name',           105,       1,      null,      null,         null, null
union select  'CustContactPerson',     'Contact Name',            150,       1,      null,      null,         null, null

union select  'CustAddressLine1',      'Cust AddressLine1',       120,       1,      null,      null,         null, null
union select  'CustAddressLine2',      'Cust AddressLine2',       120,       1,      null,      null,         null, null
union select  'CustCity',              'Cust City',               120,       1,      null,      null,         null, null
union select  'CustContactAddrId',     'Cust Contact AddrId',     120,      -2,      null,      null,         null, null
union select  'CustContactRefId',      'Cust Contact RefId',      115,      -2,      null,      null,         null, null
union select  'CustCountry',           'Cust Country',            100,       1,      null,      null,         null, null
union select  'CustEmail',             'Cust Email',              100,       1,      null,      null,         null, null
union select  'CustomerContactId',     'Customer ContactId',      120,      -2,      null,      null,         null, null
union select  'CustOrgAddrId',         'Cust Org AddrId',         100,      -2,      null,      null,         null, null
union select  'CustPhoneNo',           'Cust PhoneNo',            100,       1,      null,      null,         null, null
union select  'CustState',             'Cust State',              100,       1,      null,      null,         null, null
union select  'CustZip',               'Cust Zip',                100,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Cycle Count */
union select  'ScheduledDate',         'Scheduled Date',          110,       1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'DetailCount',           '# Locations',              90,       1,      null,      null,         null, '{0:###,###,###}'
union select  'CompletedCount',        '# Completed',              85,       1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentComplete',       '% Complete',               80,       1,      null,      null,         null, '{0:F2}'
union select  'TransactionDate',       'Transaction Date',        120,       1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'Variance',              'Variance',                 70,       1,      null,      null,         null, null
union select  'RequestedCCLevel',      'Requested CC Level',       80,       1,      null,      null,         null, null
union select  'ActualCCLevel',         'Actual CC Level',          80,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Cycle Count Statistics */
union select  'TransactionTime',       'Time',                     80,       1,      null,      null,         null, null
union select  'CountVariance',         'Units Changed?',           80,       1,      null,      null,         null, null
union select  'SKUVariance',           'SKU Changed',             100,       1,      null,      null,         null, null

union select  'CCV_UDF1',              'CCV_UDF1',                 80,      -1,      null,      null,         null, null
union select  'CCV_UDF2',              'CCV_UDF2',                 80,      -1,      null,      null,         null, null
union select  'CCV_UDF3',              'CCV_UDF3',                 80,      -1,      null,      null,         null, null
union select  'CCV_UDF4',              'CCV_UDF4',                 80,      -1,      null,      null,         null, null
union select  'CCV_UDF5',              'CCV_UDF5',                 80,      -1,      null,      null,         null, null

/* Units */
union select  'PreviousUnits',         'Prev. Units',              80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NewUnits',              'New Units',                80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsChange',           'Units Change',             80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentUnitsChange',    '% Units Change',           80,       1,      null,      null,         null, '{0:F2}'
union select  'UnitsAccuracy',         'Units Accuracy',          100,       1,      null,      null,         null, '{0:F2}'
union select  'AbsPercentUnitsChange', '% Abs Units Change',       80,       1,      null,      null,         null, '{0:F2}'

/* LPNs */
union select  'PrevLPNS',              'Prev. LPNs',               80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNChange',             'LPNs Change',              80,       1,      null,      null,         null, '{0:F2}'
/* Locations */
union select  'PrevLocationId',        'Prev LocationId',         100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'PrevLocation',          'Prev Location ',          100,       1,      null,      null,         null, '{0:###,###,###}'
/* Pallets */
union select  'PrevPalletId',          'Prev PalletId',            90,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'PrevPallet',            'Prev Pallet',              90,       1,      null,      null,         null, '{0:###,###,###}'

/* Value */
union select  'OldValue',              'Old Value',                80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NewValue',              'New Value',                80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ValueChange',           'Value Changed',            80,       1,      null,      null,         null, '{0:###,###,###}'
/* Quantity */
union select  'PrevQuantity',          'Prev. Units',             100,       1,      null,      null,         null, '{0:###,###,###}'
union select  'Quantity1',             'Qty First Count',         100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'NewQuantity',           'New Units',                80,      -2,      null,      null,         null, '{0:###,###,###}' -- deprecaetd, use Final Qty
union select  'FinalQuantity',         'Final Quantity',           80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'QuantityChange',        'Units Change',             80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentQtyChange',      '% Units Change',          100,       1,      null,      null,         null, null
union select  'QtyAccuracy',           'Units Accuracy',          100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'AbsQuantityChange',     'Abs Units Change',        100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'AbsPercentQtyChange',   '% Abs Units Change',      100,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'QuantityChange1',       'Units Change 1',          100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'QuantityChange2',       'Units Change 2',          100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentQtyChange1',     '% Units Change 1',        100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentQtyChange2',     '% Units Change 1',        100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'QtyAccuracy1',          'Units Accuracy 1',         80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'QtyAccuracy2',          'Units Accuracy 2',        100,      -1,      null,      null,         null, '{0:###,###,###}'

/* Inner Packs */
union select  'PrevInnerPacks',        'Prev. Cases',             100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'InnerPacks1',           'Cases First Count',       100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'NewInnerPacks',         'New Cases',                80,      -2,      null,      null,         null, '{0:###,###,###}' -- deprecated, use Final IPs
union select  'FinalInnerPacks',       'FinalInnerPacks',          80,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'InnerPacksChange',      'Cases Change',            100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentIPChange',       '% Cases Change',          100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'IPAccuracy',            'Cases Accuracy',          100,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'InnerPacksChange1',     'Cases Change1',           100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'InnerPacksChange2',     'Cases Change2',           100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'InnerPacksChange',      'Cases Change',            100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentIPChange1',      'PercentIPChange1',        100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentIPChange2',      'PercentIPChange2',        100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'IPAccuracy1',           'Cases Accuracy1',         100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'IPAccuracy2',           'Cases Accuracy2',         100,      -1,      null,      null,         null, '{0:###,###,###}'

/* SKUs */
union select  'PreviousNumSKUs',       '# Prev SKUs',              80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'NewNumSKUs',            '# New SKUs',               80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'SKUsChange',            'SKUs Change',              80,      -1,      null,      null,         null, '{0:F2}'
union select  'PercentSKUsChange',     '% SKUs Change',            90,      -1,      null,      null,         null, '{0:F2}'
union select  'SKUsAccuracy',          'SKUs Accuracy',            80,       1,      null,      null,         null, '{0:F2}'
union select  'SKUVarianceDesc',       'SKUVariance Desc',         80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'CurrentSKUCount',       'CurrentSKU Count',         80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'OldSKUCount',           'OldSKU Count',             80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'SKU_SortSeq',           'SKU Sort Seq',             80,      -1,      null,      null,         null, null

union select  'vwCCR_UDF1',            'vwCCR_UDF1',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF2',            'vwCCR_UDF2',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF3',            'vwCCR_UDF3',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF4',            'vwCCR_UDF4',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF5',            'vwCCR_UDF5',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF6',            'vwCCR_UDF6',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF7',            'vwCCR_UDF7',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF8',            'vwCCR_UDF8',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF9',            'vwCCR_UDF9',              120,      -2,      null,      null,         null, null
union select  'vwCCR_UDF10',           'vwCCR_UDF10',             120,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Devices */
union select  'DeviceId',              'Device Id',               120,       1,      null,      null,         null, null
union select  'DeviceName',            'Device Name',             120,       1,      null,      null,         null, null
union select  'DeviceType',            'Device Type',              80,       1,      null,      null,         null, null
union select  'Make',                  'Make',                     60,      -1,      null,      null,         null, null
union select  'Model',                 'Model',                    60,      -1,      null,      null,         null, null
union select  'SourcedFrom',           'Sourced From',             90,      -1,      null,      null,         null, null
union select  'PurchaseDate',          'Purchase Date',            90,      -1,      null,      null,         null, null
union select  'WarrantyStart',         'Warranty Start',           90,      -1,      null,      null,         null, null
union select  'WarrantyExpiry',        'Warranty Expiry',         100,      -1,      null,      null,         null, null
union select  'WarrantyReferenceNo',   'Warranty ReferenceNo',    140,      -1,      null,      null,         null, null
union select  'LastServiced',          'Last Serviced',            90,      -1,      null,      null,         null, null
union select  'AssignedToDept',        'Assigned Dept',           100,      -1,      null,      null,         null, null
union select  'AssignedToUser',        'Assigned User',            90,       1,      null,      null,         null, null
union select  'Configuration',         'Configuration',            90,       1,      null,      null,         null, null
union select  'CurrentUserId',         'Current UserId',           90,       1,      null,      null,         null, null
union select  'CurrentOperation',      'Current Operation',       110,       1,      null,      null,         null, null
union select  'CurrentResponse',       'Current Response',        110,       1,      null,      null,         null, null
union select  'PickPathPosition',      'Pick Path Position',      110,       1,      null,      null,         null, null
union select  'LastLoginDateTime',     'Last Login DateTime',     120,       1,      null,      null,         null, null
union select  'LastUsedDateTime',      'Last Used DateTime',      120,       1,      null,      null,         null, null
union select  'PickSequence',          'Pick Sequence',           110,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* DirectedCycleCount */
union select  'LastCycleCounted',      'Last Cycle Counted',      150,       1,      null,      null,         null, null
union select  'DaysAfterLastCycleCount',
                                       'Days since Last CC',      150,       1,      null,      null,         null, null
union select  'HasActiveCCTask',       'Has Active CC Task',      125,      -1,      null,      null,         null, null
union select  'PolicyCompliant',       'Policy Compliant',        125,      -1,      null,      null,         null, null

union select  'CC_LocUDF1',            'UDF1',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF2',            'UDF2',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF3',            'UDF3',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF4',            'UDF4',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF5',            'UDF5',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF6',            'UDF6',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF7',            'UDF7',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF8',            'UDF8',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF9',            'UDF9',                    20,       -2,      null,      null,         null, null
union select  'CC_LocUDF10',           'UDF10',                   20,       -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Exports */
union select  'TransType',             'Transaction Type',         80,      -2,      null,      null,         'Y', null
union select  'TransTypeDescription',  'Transaction Type',        120,       1,      null,      null,         'N', null
union select  'TransEntity',           'Entity',                   80,      -2,      null,      null,         'Y', null
union select  'TransEntityDescription','Entity',                   90,       1,      null,      null,         'N', null

union select  'TransDate',             'Transaction Date',        100,       1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'TransDateTime',         'Transaction DateTime',    150,       1,      null,      null,         null, null
union select  'TransactionDateTime',   'Transaction DateTime',    150,      -1,      null,      null,         null, null
union select  'TransQty',              'Quantity',                 60,       1,      null,      null,         null,'{0:###,###,###}'
union select  'AbsTransQty',           'Abs-Quantity',             60,      -1,      null,      null,         null,'{0:###,###,###}'
union select  'ExportStatus',          'Export Status',            99,      -2,      null,      null,         'Y', null
union select  'ExportStatusDesc',      'Status',                   80,       1,      null,      null,         'N', null

union select  'BoL',                   'BoL',                      80,       1,      null,      null,         null, null
union select  'LoadShipVia',           'Load Ship Via',            80,       1,      null,      null,         null, null
union select  'ProcessedDateTime',     'Processed DateTime',      150,       1,      null,      null,         null, null
union select  'Length',                'Length',                   70,      -1,      null,      null,         null, '{0:n2}'
union select  'Width',                 'Width',                    70,      -1,      null,      null,         null, '{0:n2}'
union select  'Height',                'Height',                   70,      -1,      null,      null,         null, '{0:n2}'
union select  'Reference',             'Reference',                70,      -1,      null,      null,         null, null
union select  'ExportBatch',           'Export Batch',             70,      -1,      null,      null,         null, '{0:#########}'
union select  'PrevSKUId',             'Prev SKUId',               70,      -1,      null,      null,         null, null
union select  'FromWarehouse',         'From WH',                  70,      -1,      null,      null,         null, null
union select  'ToWarehouse',           'To WH',                    70,      -1,      null,      null,         null, null
union select  'MonetaryValue',         'Monetary Value',           70,      -2,      null,      null,          'Y', null
union select  'ReasonCode',            'Reason Code',              70,       1,      null,      null,         null, null
union select  'FromLocation',          'From Location',            70,      -1,      null,      null,         null, null
union select  'ToLocation',            'To Location',              70,      -1,      null,      null,         null, null
union select  'FromLocationId',        'From LocationId',          70,      -1,      null,      null,         null, null
union select  'ToLocationId',          'To LocationId',            70,      -1,      null,      null,         null, null
union select  'FromSKU',               'From SKU',                 70,      -1,      null,      null,         null, null
union select  'ToSKU',                 'To SKU',                   70,      -1,      null,      null,         null, null
union select  'EDITransCode',          'EDI Trans Code',           70,      -1,      null,      null,         null, null

/* Used in CIMS DE */
union select  'ReceiptVessel',         'Vessel',                   90,      -2,      null,      null,         null, null
union select  'ReceiptContainerNo',    'Container #',              90,      -2,      null,      null,         null, null
union select  'ReceiptContainerSize',  'Cont. Size',               90,      -2,      null,      null,         null, null
union select  'ReceiptBillNo',         'Bill #',                   90,      -2,      null,      null,         null, null
union select  'ReceiptSealNo',         'Seal #',                   90,      -2,      null,      null,         null, null
union select  'ReceiptInvoiceNo',      'Invoice #',                90,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Fields */
union select  'FieldName',             'Field Name',              120,       1,      null,      null,         null, null
union select  'Caption',               'Caption',                 120,       1,      null,      null,         null, null
union select  'Visible',               'Visible',                  60,      -2,      null,      null,         null, null
union select  'Alignment',             'Alignment',                85,       1,      null,      null,         null, null
union select  'MaxLength',             'Max. Length',              75,       1,      null,      null,         null, null
union select  'DisplayFormat',         'Display Format',          120,       1,      null,      null,         null, null
union select  'DefaultValue',          'Default Value',           100,      -1,      null,      null,         null, null
union select  'ToolTip',               'Tool Tip',                150,      -1,      null,      null,         null, null
union select  'FieldType',             'Field Type',               70,      -1,      null,      null,         null, null
union select  'AggregateMethod',       'Aggregate Method',         70,      -1,      null,      null,         null, null
union select  'IsSelectable',          'Is Selectable',            70,      -1,      null,      null,         null, null
union select  'FieldGroups',           'Field Groups',             75,      -1,      null,      null,         null, null
union select  'CultureName',           'Culture Name',             75,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Generate Locations */
union select  'Row',                   'Row',                      45,       1,      null,      null,         null, null
union select  'Level',                 'Level',                    45,       1,      null,      null,         null, null
union select  'ActionStatus',          'Action Status',           125,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* HostExportInventory */
union select  'ExportTransactionId',   'Export TransactionId',     85,      -1,      null,      null,         null, null
union select  'ins_dt',                'Created Date',             80,       1,      null,      null,         null, null
union select  'LotNumber',             'Lot Number',               85,      -1,      null,      null,         null, null
union select  'OnhandQuantity',        'Onhand Quantity',         130,       1,      null,      null,         null, '{0:###,###,###}'
union select  'processed_dte',         'Processed Date',          100,       1,      null,      null,         null, null
union select  'processed_flg',         'Processed Flag',          100,       1,      null,      null,         null, null
union select  'ReceivedQuantity',      'Received Quantity',       115,       1,      null,      null,         null, '{0:###,###,###}'

/*----------------------------------------------------------------------------*/
/* HostImportPackedCartons */
union select  'ShippingLane',          'Shipping Lane',           115,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* HostExportOpenOrders */
union select  'UnitsRemainToShip',     'Units Remain To Ship',    140,       1,      null,      null,         null, null
union select  'UnitsReserved',         'Units Reserved',          105,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* HostExportOpenReceipts */
union select  'QtyOpen',               '# To Receive',             80,       1,      null,      null,         null, null

union select  'vwORE_UDF1',            'ORE UDF1',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF2',            'ORE UDF2',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF3',            'ORE UDF3',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF4',            'ORE UDF4',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF5',            'ORE UDF5',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF6',            'ORE UDF6',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF7',            'ORE UDF7',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF8',            'ORE UDF8',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF9',            'ORE UDF9',                 30,      -2,      null,      null,         null, null
union select  'vwORE_UDF10',           'ORE UDF10',                30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Imports */
union select  'RecordAction',          'Action',                   30,       1,      null,      null,         null, null
union select  'InsertedTime',          'Inserted Time',           150,       1,      null,        50,         null, null
union select  'ProcessedTime',         'Processed Time',          150,       1,      null,        50,         null, null
union select  'UpdateOption',          'Update Option',            90,      -1,      null,      null,         null, null

union select  'Entity',                'Entity',                   30,      -1,      null,      null,         null, null
union select  'Result',                'Result',                  100,      -1,      null,      null,         null, null
union select  'InputXML',              'Input XML',                90,      -1,      null,      null,         null, null
union select  'ResultXML',             'Result XML',              125,      -1,      null,      null,         null, null

/* Import Files */
union select  'Validated',             'Validated',                30,      -1,      null,      null,         null, null
union select  'ValidationMsg',         'ValidationMsg',           100,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* InterfaceLog */
union select  'AlertSent',             'Alert',                    45,       1,  'Center',      null,         null, null
union select  'HasInputXML',           'XML',                      30,       1,      null,      null,         null, null
union select  'KeyData',               'Key Data',                100,       1,      null,      null,         null, null
union select  'RecordsFailed',         '# Failed',                 60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'RecordsPassed',         '# Passed',                 60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'RecordsProcessed',      '# Processed',              80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'RecordTypes',           'Record Types',             85,       1,      null,      null,         null, null
union select  'InterfaceLogStatus',    'Status',                   85,      -2,      null,      null,          'Y', null
union select  'InterfaceLogStatusDesc','Status',                   85,       1,      null,      null,          'N', null

union select  'SourceReference',       'Source Reference',        180,       1,      null,      null,         null, null
union select  'StartTime',             'Start Time',              140,       1,      null,      null,         null, null
union select  'EndTime',               'End Time',                140,       1,      null,      null,         null, null
union select  'TransferType',          'Transfer Type',            90,       1,      null,      null,         null, null
union select  'HostReference',         'Host Reference',          125,       1,      null,      null,         null, null
union select  'LogDate',               'Log Date',                 45,       1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'LogDateTime',           'Log Date-Time',           140,       1,      null,      null,         null, null
union select  'LogMessage',            'Log Message',              45,      -1,      null,      null,         null, null
union select  'ParentLogId',           'Parent Log Id',            90,       1,      null,      null,         null, null

union select  'vwIL_UDF1',             'IL UDF1',                  30,      -2,      null,      null,         null, null
union select  'vwIL_UDF2',             'IL UDF2',                  30,      -2,      null,      null,         null, null
union select  'vwIL_UDF3',             'IL UDF3',                  30,      -2,      null,      null,         null, null
union select  'vwIL_UDF4',             'IL UDF4',                  30,      -2,      null,      null,         null, null
union select  'vwIL_UDF5',             'IL UDF5',                  30,      -2,      null,      null,         null, null

union select  'vwILD_UDF1',            'ILD UDF1',                 30,      -2,      null,      null,         null, null
union select  'vwILD_UDF2',            'ILD UDF2',                 30,      -2,      null,      null,         null, null
union select  'vwILD_UDF3',            'ILD UDF3',                 30,      -2,      null,      null,         null, null
union select  'vwILD_UDF4',            'ILD UDF4',                 30,      -2,      null,      null,         null, null
union select  'vwILD_UDF5',            'ILD UDF5',                 30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Label Formats */
union select  'LabelFormatName',       'Label Format',            130,       1,      null,      null,         null, null
union select  'LabelFormatDesc',       'Label Format Desc',       150,       1,      null,      null,         null, null
union select  'LabelFileName',         'Label File Name',         150,       1,      null,      null,         null, null
union select  'LabelTemplateType',     'Label Template Type',     150,      -1,      null,      null,         null, null
union select  'LabelSQLStatement',     'Label SQL Statement',     150,      -1,      null,      null,         null, null
union select  'PrintDataStream',       'Print Data Stream',       105,      -1,      null,      null,         null, null
union select  'PrintOptions',          'Print Options',           300,       1,      null,      null,         null, null
union select  'LabelSize',             'Label Size',               50,       1,      null,      null,         null, null
union select  'NumCopies',             'Num Copies',               80,      -1,      null,      null,         null, null
union select  'PrinterMake',           'Printer Make',             80,       1,      null,      null,         null, null

union select  'ZPLTemplate',           'ZPL Template',             80,      -1,      null,      null,         null, null
union select  'ZPLFile',               'ZPL File',                 80,      -1,      null,      null,         null, null
union select  'ZPLLink',               'ZPL Link',                 80,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Load */
union select  'LoadId',                'Load Id',                  80,      -2,      null,      null,         null, '{0:.}'
union select  'LoadNumber',            'Load',                    100,       1,      null,      null,         null, null

union select  'LoadType',              'Load Type',                85,      -2,      null,      null,          'Y', null
union select  'LoadTypeDescription',   'Load Type',                85,      -1,      null,      null,          'N', null
union select  'LoadTypeDesc',          'Load Type',                85,      -1,      null,      null,          'N', null

union select  'LoadStatus',            'Status',                   85,      -2,      null,      null,          'Y', null
union select  'LoadStatusDesc',        'Status',                   85,       1,      null,      null,          'N', null

union select  'RoutingStatus',         'Routing',                  90,      -2,      null,      null,         null, null
union select  'RoutingStatusDesc',     'Routing',                  90,      -1,      null,      null,         null, null
union select  'RoutingStatusDescription','Routing',                90,      -2,      null,      null,         null, null
union select  'TrailerNumber',         'Trailer',                  90,      -1,      null,      null,         null, null
union select  'SealNumber',            'Seal #',                   75,      -1,      null,      null,         null, null
union select  'ProNumber',             'PRO Number',               90,      -1,      null,      null,         null, null
union select  'MasterTrackingNo',      'Master Tracking No',      100,      -1,      null,      null,         null, null
union select  'DeliveryDate',          'Delivery Date',           110,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'ASNCase',               'ASN Case',                 90,      -1,      null,      null,         null, null
union select  'NumShippables',         '# Shippables',             60,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'TrackingNo',            'Tracking #',              165,       1,      null,      null,         null, null
union select  'PackageSeqNo',          'Package Seq #',           110,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'ClientLoad',            'Client Load #',            85,       1,      null,      null,         null, null
union select  'DockLocation',          'Dock',                     70,       1,      null,      null,         null, null
union select  'ConsolidatorAddressId', 'Consolidator Address',    100,      -1,      null,      null,         null, null
union select  'StagingLocation',       'Staging Location',        100,      -1,      null,      null,         null, null
union select  'LoadingMethod',         'Loading Method',          100,      -1,      null,      null,         null, null
union select  'LoadGroup',             'Load Group',               80,      -1,      null,      null,         null, null
union select  'CarrierCheckIn',        'Carrier CheckIn',          80,      -1,      null,      null,         null, '{0:hh:mm:ss}'
union select  'CarrierCheckOut',       'Carrier CheckOut',         80,      -1,      null,      null,         null, '{0:hh:mm:ss}'

union select  'AppointmentConfirmation',
                                       'Appt Confirmation',       115,       1,      null,      null,         null, null
union select  'AppointmentDate',       'Appt Date',               120,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'AppointmentDateTime',   'Appt Date/Time',          150,      -1,      null,      null,         null, null
union select  'AppointmentTime',       'Appt Time',               150,      -1,      null,      null,         null, null
union select  'DeliveryRequestType',   'Delivery Request Type',   140,      -1,      null,      null,         null, null

union select  'LD_UDF1',               'LD UDF1',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF2',               'LD UDF2',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF3',               'LD UDF3',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF4',               'LD UDF4',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF5',               'LD UDF5',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF6',               'LD UDF6',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF7',               'LD UDF7',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF8',               'LD UDF8',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF9',               'LD UDF9',                  80,      -2,      null,      null,         null, null
union select  'LD_UDF10',              'LD UDF10',                 80,      -2,      null,      null,         null, null

union select  'vwLD_UDF1',             'vwLD_UDF1',                80,      -2,      null,      null,         null, null
union select  'vwLD_UDF2',             'vwLD_UDF2',                80,      -2,      null,      null,         null, null
union select  'vwLD_UDF3',             'vwLD_UDF3',                80,      -2,      null,      null,         null, null
union select  'vwLD_UDF4',             'vwLD_UDF4',                80,      -2,      null,      null,         null, null
union select  'vwLD_UDF5',             'vwLD_UDF5',                80,      -2,      null,      null,         null, null

union select  'vwLDOH_UDF1',           'LDOH UDF1',                80,      -2,      null,      null,         null, null
union select  'vwLDOH_UDF2',           'LDOH UDF2',                80,      -2,      null,      null,         null, null
union select  'vwLDOH_UDF3',           'LDOH UDF3',                80,      -2,      null,      null,         null, null
union select  'vwLDOH_UDF4',           'LDOH UDF4',                80,      -2,      null,      null,         null, null
union select  'vwLDOH_UDF5',           'LDOH UDF5',                80,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Load Management */
union select  'TotalTax',              'Tax',                      80,      -1,      null,      null,         null, '{0:.}'
union select  'TotalShippingCost',     'Shipping Cost',            80,      -1,      null,      null,         null, '{0:.}'
union select  'TotalDiscount',         'Total Discount',           90,      -1,      null,      null,         null, '{0:.}'
union select  'Comments',              'Comments',                100,      -1,      null,      null,         null, null
union select  'DateShipped',           'Shipped Date',             85,      -1,      null,      null,         null, null
union select  'ShortPick',             'Short Pick',               80,      -1,      null,      null,         null, null

union select  'ShipName',              'Ship To Name',             85,      -1,      null,      null,         null, null
union select  'ShipAddressLine1',      'Ship To Street',           85,      -1,      null,      null,         null, null
union select  'ShipAddressLine2',      'Ship To Line 2',           85,      -1,      null,      null,         null, null
union select  'ShipCity',              'Ship City',                85,      -1,      null,      null,         null, null
union select  'ShipCountry',           'Ship Country',            100,      -1,      null,      null,         null, null
union select  'ShipPhoneNo',           'Ship To PhoneNo',          85,      -1,      null,      null,         null, null

union select  'SoldName',              'Sold To Name',             85,      -1,      null,      null,         null, null
union select  'SoldAddressLine1',      'Sold To Street',           85,      -1,      null,      null,         null, null
union select  'SoldAddressLine2',      'Sold To Line2',            85,      -1,      null,      null,         null, null
union select  'SoldCity',              'Sold City',                85,      -1,      null,      null,         null, null
union select  'SoldCountry',           'Sold Country',            100,      -1,      null,      null,         null, null
union select  'SoldPhoneNo',           'Sold PhoneNo',             85,      -1,      null,      null,         null, null

union select  'TransitDays',           'Transit Days',             85,      -1,      null,      null,         null, null

union select  'ShipFrom',              'Ship From',                70,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Mark For Address */
union select  'MarkForAddress',        'Mark For Address',        110,      -1,      null,      null,         null, null
union select  'MarkForAddressName',    'Mark For Name',           110,      -1,      null,      null,         null, null
union select  'MarkForAddressLine1',   'Mark For Addr Line1',     10,      -1,      null,      null,         null, null
union select  'MarkForAddressLine2',   'Mark For Addr Line2',     110,      -1,      null,      null,         null, null
union select  'MarkForAddressCity',    'Mark For City',           110,      -1,      null,      null,         null, null
union select  'MarkForAddressState',   'Mark For State',          110,      -1,      null,      null,         null, null
union select  'MarkForAddressZip',     'Mark For Zip',            110,      -1,      null,      null,         null, null
union select  'MarkForAddressCountry', 'Mark For Country',        110,      -1,      null,      null,         null, null

union select  'MarkForAddressPhoneNo', 'Mark For PhoneNo',        110,      -1,      null,      null,         null, null
union select  'MarkForAddressEmail',   'Mark For Email',          110,      -1,      null,      null,         null, null

union select  'MarkForAddressReference1',
                                       'Mark For Reference 1',    110,      -1,      null,      null,         null, null
union select  'MarkForAddressReference2',
                                       'Mark For Reference2',     110,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Ship Labels */
union select  'Label',                 'Label',                    65,      -2,      null,      null,         null, null
union select  'NetCharge',             'Net Charge',               65,       1,      null,      null,         null, '{0:.}'
union select  'ZPLLabel',              'ZPL Label',                65,      -2,      null,      null,         null, null
union select  'RequestedShipVia',      'Requested ShipVia',       110,      -2,      null,      null,         null, null
union select  'ListNetCharge',         'List Net Charge',         100,      -2,      null,      null,         null, null
union select  'AcctNetCharge',         'Acct Net Charge',         100,      -2,      null,      null,         null, null
union select  'ProcessStatus',         'Process Status',          100,       1,      null,      null,         null, null
union select  'ProcessedInstance',     'Processed Instance',      100,      -2,      null,      null,         null, null
union select  'ProcessBatch',          'Process Batch',           100,      -2,      null,      null,         null, null
union select  'ExportInstance',        'Export Instance',         100,      -2,      null,      null,         null, null
union select  'Notifications',         'Notifications',            65,       1,      null,      null,         null, null
union select  'NotificationSource',    'Notification Source',      65,       1,      null,      null,         null, null
union select  'NotificationTrace',     'Notification Trace',       65,       1,      null,      null,         null, null
union select  'ManifestExportStatus',  'Manifest Status',         100,      -1,      null,      null,         null, null
union select  'ManifestExportBatch',   'Manifest Batch',          100,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Location */
union select  'LocationId',            'LocationId',               70,      -3,      null,      null,         null, null
union select  'Location',              'Location',                 80,       1,      null,      null,         null, null

union select  'LocationType',          'Location Type',           105,      -2,      null,      null,          'Y', null
union select  'LocationTypeDesc',      'Location Type',           120,      -1,      null,      null,          'N', null
union select  'LocationSubType',       'Location Sub Type',       115,      -2,      null,      null,          'Y', null
union select  'LocationSubTypeDesc',   'Location Sub Type',       115,      -1,      null,      null,          'N', null
union select  'LocationStatus',        'Location Status',         115,      -2,      null,      null,          'Y', null
union select  'LocationStatusDesc',    'Location Status',         135,      -1,      null,      null,          'N', null
union select  'StorageType',           'Storage Type',             95,      -2,      null,      null,          'Y', null
union select  'StorageTypeDesc',       'Storage Type',            120,       1,      null,      null,          'N', null

union select  'PickingZone',           'Pick Zone',                90,       1,      null,      null,         null, null
union select  'PickingZoneDesc',       'Pick Zone',               120,       1,      null,      null,         null, null
union select  'PickingZoneDisplayDesc','Pick Zone',               120,      -2,      null,      null,         null, null
union select  'PutawayZone',           'Putaway Zone',             90,      -2,      null,      null,          'Y', null
union select  'PutawayZoneDesc',       'Putaway Zone',            135,       1,      null,      null,         null, null
union select  'PutawayZoneDisplayDesc','Putaway Zone',            120,      -2,      null,      null,         null, null
union select  'PutawayPath',           'Putaway Path',             90,       1,      null,      null,         null, null
union select  'PickPath',              'Pick Path',                90,       1,      null,      null,         null, null

union select  'LocationRow',           'Row',                      55,       1,  'Center',      null,         null, null
union select  'LocationBay',           'Bay',                      55,       1,  'Center',      null,         null, null
union select  'LocationLevel',         'Level',                    55,       1,  'Center',      null,         null, null
union select  'LocationSection',       'Section',                  65,       1,  'Center',      null,         null, null
union select  'LocationABCClass',      'Location ABC Class',      130,      -1,      null,      null,         null, null

union select  'ReplenishType',         'Replenish Type',          100,       1,      null,      null,         null, null
union select  'MinReplenishLevel',     'Min Replenish Level',     130,      -1,      null,      null,         null, null
union select  'MinReplenishLevelDesc', 'Min Level',                60,      -1,      null,      null,         null, null
union select  'MaxReplenishLevel',     'Max Replenish Level',     130,      -1,      null,      null,         null, null
union select  'MaxReplenishLevelDesc', 'Max Level',                60,      -1,      null,      null,         null, null
union select  'ReplenishUoM',          'Replenish UoM',           100,      -1,      null,      null,         null, null
union select  'ReplenishUoMDesc',      'Replenish UoM',           100,      -2,      null,      null,         null, null
union select  'ReplenishOrderId',      'Replenish OrderId',        90,      -2,      null,      null,         null, null
union select  'ReplenishOrder',        'Replenish Order',          90,      -2,      null,      null,         null, null
union select  'ReplenishOrderDetailId','Replenish Order Detail Id',
                                                                  120,      -2,      null,      null,         null, null
union select  'MinToReplenish',        '# Min To Replenish',      120,       1,      null,      null,         null, null
union select  'MinToReplenishDesc',    '# Min To Replenish',      120,      -2,      null,      null,         null, null
union select  'MinReplenishLevelUnits','Min Units To Repl.',      130,       1,  'Center',      null,         null, null
union select  'MaxToReplenish',        '# Max To Replenish',      120,       1,      null,      null,         null, null
union select  'MaxToReplenishDesc',    '# Max To Replenish',      120,      -2,      null,      null,         null, null
union select  'MaxReplenishLevelUnits','Max Units To Repl.',      130,       1,  'Center',      null,         null, null

union select  'AllowMultipleSKUs',     'Multiple SKUs?',          120,       1,  'Center',      null,         null, null
union select  'AllowedOperations',     'Allowed Operations',      120,       1,      null,      null,         null, null
union select  'HostLocation',          'Host Location',            90,      -1,      null,      null,         null, null

union select  'LocationVerified',      'Location Verified',       120,      -1,      null,      null,         null, null
union select  'LastVerified',          'Last Verified',           120,      -1,      null,      null,         null, null

union select  'LOC_UDF1',              'LOC_UDF1',                 70,      -2,      null,      null,         null, null
union select  'LOC_UDF2',              'LOC_UDF2',                 70,      -2,      null,      null,         null, null
union select  'LOC_UDF3',              'LOC_UDF3',                 70,      -2,      null,      null,         null, null
union select  'LOC_UDF4',              'LOC_UDF4',                 70,      -2,      null,      null,         null, null
union select  'LOC_UDF5',              'LOC_UDF5',                 70,      -2,      null,      null,         null, null

union select  'vwLOC_UDF1',            'vwLOC_UDF1',               70,      -2,      null,      null,         null, null
union select  'vwLOC_UDF2',            'vwLOC_UDF2',               70,      -2,      null,      null,         null, null
union select  'vwLOC_UDF3',            'vwLOC_UDF3',               70,      -2,      null,      null,         null, null
union select  'vwLOC_UDF4',            'vwLOC_UDF4',               70,      -2,      null,      null,         null, null
union select  'vwLOC_UDF5',            'vwLOC_UDF5',               70,      -2,      null,      null,         null, null
union select  'UniqueId',              'UniqueId',                 70,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Lookups */
union select  'LookUpCategory',        'Category',                170,      -2,      null,      null,         null, null
union select  'CategoryDesc',          'Category',                130,       1,      null,      null,         null, null

union select  'LookUpCode',            'Code',                    125,       1,      null,      null,          'Y', null
union select  'LookUpDescription',     'Description',             250,       1,      null,      null,          'Y', null
union select  'LookUpDisplayDescription','Description',           250,      -1,      null,      null,         null, null
union select  'CategoryStatus',        'Category Status',          60,      -1,      null,      null,         null, null
union select  'CategoryActions',       'Category Actions',         60,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* LPNs */
union select  'LPNId',                 'LPNId',                    60,      -3,      null,      null,         null, null
union select  'LPN',                   'LPN',                      95,       1,      null,      null,         null, null
union select  'LPNType',               'Type',                     60,      -2,      null,      null,         'Y',  null
union select  'LPNTypeDescription',    'Type',                     60,      -1,      null,      null,         'N',  null
union select  'LPNStatus',             'Status',                   85,      -2,      null,      null,         'Y',  null
union select  'LPNStatusDescription',  'Status',                   85,      -2,      null,      null,         'N',  null
union select  'LPNStatusDesc',         'Status',                   85,       1,      null,      null,         'N',  null
union select  'OnhandStatus',          'Onhand Status',            90,      -2,      null,      null,         'Y',  null
union select  'OnhandStatusDescription',
                                       'Onhand Status',            90,       1,      null,      null,         'N',  null
union select  'InventoryStatus',       'Inventory Status',         90,      -2,      null,      null,         null, null
union select  'InnerPacks',            'Cases',                    65,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'Quantity',              'Quantity',                 65,       1,      null,      null,         null, '{0:###,###,###}'
union select  'DirectedQty',           'Directed Qty',             80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'AllocableQty',          'Allocable Qty',            85,       1,      null,      null,         null, '{0:###,###,###}'
union select  'DestWarehouse',         'WH',                       40,      -1,  'Center',      null,         null, null
union select  'ReceivedUnits',         'Received Units',          120,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsPerPackage',       'Units Per Package',        60,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UCCBarcode',            'UCC Barcode',             135,       1,      null,      null,         null, null
union select  'LPNShipmentId',         'LPN Shipment',             80,      -1,      null,      null,         null, null
union select  'ReceiptCustPO',         'Cust PO',                  90,      -1,      null,      null,         null, null
union select  'ProductCost',           'Product Cost',             85,      -2,      null,      null,          'Y', '{0:c2}'
union select  'PickingClass',          'Picking Class',            90,      -1,      null,      null,         null, null

union select  'ExpiryDate',            'Exp. Date',                85,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'ExpiresInDays',         'Expires In Days',         110,      -1,      null,      null,         null, null
union select  'LastMovedDate',         'Last Moved',               90,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'

union select  'Lot',                   'Lot',                      80,      -1,      null,      null,         null, null
union select  'InventoryClass1',       'Inventory Class',          90,      -1,      null,      null,         null, null
union select  'InventoryClass2',       'Inventory Class2',         90,      -2,      null,      null,         null, null
union select  'InventoryClass3',       'Inventory Class3',         90,      -2,      null,      null,         null, null
union select  'NewInventoryClass1',    'New Inventory Class',      90,      -1,      null,      null,         null, null
union select  'NewInventoryClass2',    'New Inventory Class2',     90,      -2,      null,      null,         null, null
union select  'NewInventoryClass3',    'New Inventory Class3',     90,      -2,      null,      null,         null, null

union select  'AlternateLPN',          'Cart Position',           100,      -1,      null,      null,         null, null
union select  'PackingGroup',          'Packing Group',            80,      -1,      null,      null,         null, null
union select  'PrevLPNQty',            'Prev LPN Qty',             80,      -1,      null,      null,         null, null
union select  'PrevLPNInnerPacks',     'Prev LPN InnerPacks',     125,      -1,      null,      null,         null, null

union select  'ActualWeight',          'Actual Weight',            90,      -1,      null,      null,         null, null
union select  'ActualVolume',          'Actual Volume',            90,      -1,      null,      null,         null, '{0:.}'
union select  'EstimatedWeight',       'Estimated Weight',        120,      -1,      null,      null,         null, null
union select  'EstimatedVolume',       'Estimated Volume',        120,      -1,      null,      null,         null, null
union select  'LPNWeight',             'LPN Weight',               80,      -1,      null,      null,         null, null
union select  'LPNVolume',             'LPN Volume',               80,      -1,      null,      null,         null, null

union select  'FromLPNId',             'FromLPNId',                60,      -2,      null,      null,         null, null
union select  'FromLPN',               'From LPN',                 95,       1,      null,      null,         null, null

union select  'LPN_UDF1',              'LPN UDF1',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF2',              'LPN UDF2',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF3',              'LPN UDF3',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF4',              'LPN UDF4',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF5',              'LPN UDF5',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF6',              'LPN UDF6',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF7',              'LPN UDF7',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF8',              'LPN UDF8',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF9',              'LPN UDF9',                 80,      -2,      null,      null,         null, null
union select  'LPN_UDF10',             'LPN UDF10',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF11',             'LPN UDF11',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF12',             'LPN UDF12',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF13',             'LPN UDF13',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF14',             'LPN UDF14',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF15',             'LPN UDF15',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF16',             'LPN UDF16',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF17',             'LPN UDF17',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF18',             'LPN UDF18',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF19',             'LPN UDF19',                80,      -2,      null,      null,         null, null
union select  'LPN_UDF20',             'LPN UDF20',                80,      -2,      null,      null,         null, null

union select  'vwLPN_UDF1',            'vwLPN_UDF1',               20,      -2,      null,      null,         null, null
union select  'vwLPN_UDF2',            'vwLPN_UDF2',               20,      -2,      null,      null,         null, null
union select  'vwLPN_UDF3',            'vwLPN_UDF3',               20,      -2,      null,      null,         null, null
union select  'vwLPN_UDF4',            'vwLPN_UDF4',               20,      -2,      null,      null,         null, null
union select  'vwLPN_UDF5',            'vwLPN_UDF5',               20,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* LPN Counts */
union select  'LPNsAssigned',          '# Cartons',                70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsPicked',            'Ctns Picked',              50,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsPacked',            'Ctns Packed',              50,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsLabeled',           'Ctns Labeled',             50,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsStaged',            'Ctns Staged',              50,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsLoaded',            'Ctns Loaded',              50,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsToLoad',            'Ctns To Load',             50,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsShipped',           'Ctns Shipped',             50,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsToShip',            'Ctns To Ship',             55,      -1,      null,      null,         null, '{0:###,###,###}'

/*----------------------------------------------------------------------------*/
/* LPN Details */
union select  'LPNDetailId',           'LPN Detail Id',            90,      -2,      null,      null,         null, null
union select  'LPNLine',               'Line',                     40,      -1,      null,      null,         null, null

union select  'DisplayDestination',    'Destination',              80,       1,      null,      null,         null, null
union select  'DisplayQuantity',       'Quantity',                 60,       1,      null,      null,         null, '{0:###,###,###}' /* Not configured */
union select  'ReservedQuantity',      'Reserved Qty',             90,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ComittedQty',           'Comitted Qty',             80,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'LPND_UDF1',             'LPND UDF1',                30,      -2,      null,      null,         null, null
union select  'LPND_UDF2',             'LPND UDF2',                30,      -2,      null,      null,         null, null
union select  'LPND_UDF3',             'LPND UDF3',                30,      -2,      null,      null,         null, null
union select  'LPND_UDF4',             'LPND UDF4',                30,      -2,      null,      null,         null, null
union select  'LPND_UDF5',             'LPND UDF5',                30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* LPNTasks */
union select  'vwLPNTask_UDF1',        'vwLPNTask_UDF1',           70,      -2,      null,      null,         null, null
union select  'vwLPNTask_UDF2',        'vwLPNTask_UDF2',           70,      -2,      null,      null,         null, null
union select  'vwLPNTask_UDF3',        'vwLPNTask_UDF3',           70,      -2,      null,      null,         null, null
union select  'vwLPNTask_UDF4',        'vwLPNTask_UDF4',           70,      -2,      null,      null,         null, null
union select  'vwLPNTask_UDF5',        'vwLPNTask_UDF5',           70,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Mapping */
union select  'SourceSystem',          'Source System',            95,      -1,      null,      null,         null, null
union select  'SourceValue',           'Source Value',             90,       1,      null,      null,         null, null
union select  'TargetSystem',          'Target System',            95,       1,      null,      null,         null, null
union select  'TargetValue',           'Target Value',             90,       1,      null,      null,         null, null
union select  'Operation',             'Operation',                80,      -1,      null,      null,          'Y', null
union select  'EntityType',            'Entity Type',              80,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Messages */
union select  'MessageName',           'Message Name',            170,       1,      null,      null,         null, null
union select  'NotifyType',            'Notify Type',              80,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Notes */
union select  'NoteType',              'Note Type',                90,       1,      null,      null,         null, null
union select  'Note',                  'Note',                     80,       1,      null,      null,         null, null
union select  'NoteFormat',            'Note Format',              90,       1,      null,      null,         null, null
union select  'EntityId',              'Entity Id',                90,       1,      null,      null,         null, null
union select  'EntityKey',             'Entity Key',               90,       1,      null,      null,         null, null
union select  'EntityLineNo',          'Entity Line No',          130,      -1,      null,      null,         null, null
union select  'PrintFlags',            'Print Flags',              95,       1,      null,      null,         null, null
union select  'ExportFlags',           'Export Flags',             95,      -2,      null,      null,         null, null
union select  'VisibleFlags',          'Visible Flags',           110,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Onhand Inventory */
union select  'OnhandQty',             'Onhand Qty',               60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ReservedQty',           'Reserved Qty',             80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ReceivedQty',           'Received Qty',             60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ToShipQty',             'To Ship',                  60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ShortQty',              'Short Qty',                60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'OnhandValue',           'Onhand $Value',            80,      -1,      null,      null,         null, '{0:c2}'
union select  'SKUSortOrder',          'SKU SortOrder',            95,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'OnhandIPs',             'Onhand Cases',             85,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'ReservedIPs',           'Reserved Cases',           95,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'AvailableIPs',          'Available Cases',          95,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'ToShipIPs',             'To Ship Cases',            85,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'AvailableQty',          'AvailableQty',             60,      -1,      null,      null,         null, '{0:###,###,###}'

/*----------------------------------------------------------------------------*/
/* Order Details */
union select  'OrderDetailId',         'Order DetailId',           90,      -1,      null,      null,         null, null
union select  'OrderLine',             'Order Line #',             70,      -2,      null,      null,         null, null
union select  'HostOrderLine',         'Order Line#',              90,       1,  'Center',      null,         null, '{0:.}'
union select  'ParentHostLineNo',      'Parent Host LineNo',       90,      -1,      null,      null,         null, null
union select  'ParentLineId',          'Parent LineId',            90,      -2,      null,      null,         null, null

union select  'UnitsOrdered',          '# Ordered',                70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsAuthorizedToShip', '# To Ship',                80,       1,   'Right',      null,         null, '{0:###,###,###}'
union select  'UnitsToShip',           '# To Ship',                80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsAssigned',         '# Reserved',               80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsToAllocate',       '# To Allocate',            90,       1,      null,      null,         null, '{0:###,###,###}'

union select  'OrigUnitsAuthorizedToShip',
                                       'Host - Units To Ship',     80,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'RetailUnitPrice',       'Retail Unit Price',       115,      -1,      null,      null,         null, '{0:c2}'
union select  'UnitSalePrice',         'Unit Sale Price',          85,      -2,      null,      null,         null, '{0:c2}'
union select  'LineValue',             'Line Value',              100,       1,      null,      null,         null, '{0:c2}'
union select  'LineType',              'Line Type',                85,      -1,      null,      null,         null, null
union select  'NewSKU',                'New SKU',                 140,      -1,      null,      null,         null, null
union select  'NewSKUId',              'New SKUId',                85,      -1,      null,      null,         null, null
union select  'CustSKU',               'Cust SKU',                140,      -1,      null,      null,         null, null
union select  'TotalUnitsAssigned',    'Total Units',              85,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'OrderDetailWeight',     'OrderDetailWeight',       130,      -1,      null,      null,         null, '{0:n2}'
union select  'OrderDetailVolume',     'OrderDetailVolume',       130,      -1,      null,      null,         null, '{0:n2}'
union select  'PickBatchCategory',     'Wave Category',            85,      -1,      null,      null,         null, null
union select  'OH_PickZone',           'OH_PickZone',              85,      -1,      null,      null,         null, null
union select  'OH_PickBatchNo',        'OH_WaveNo',               105,      -1,      null,      null,         null, null
union select  'OH_PickBatchGroup',     'OH_WaveGroup',             85,      -1,      null,      null,         null, null
union select  'TotalShippmentCost',    'Total Shipment Cost',      85,      -1,      null,      null,         null, '{0:c2}'
union select  'ODCustPO',              'OD Cust PO',              105,      -1,      null,      null,         null, null
union select  'PrepackCode',           'Prepack Code',            105,       1,      null,      null,         null, null

union select  'LineDiscount',          'Line Discount',            85,      -1,      null,      null,         null, '{0:.}'
union select  'UnitDiscount',          'Unit Discount',            85,      -1,      null,      null,         null, '{0:.}'
union select  'ResidualDiscount',      'Residual Discount',       105,      -1,      null,      null,         null, '{0:.}'
union select  'UnitTaxAmount',         'Unit Tax Amount',         105,      -1,      null,      null,         null, '{0:.}'

union select  'OD_UDF1',               'OD UDF1',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF2',               'OD UDF2',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF3',               'OD UDF3',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF4',               'OD UDF4',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF5',               'OD UDF5',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF6',               'OD UDF6',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF7',               'OD UDF7',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF8',               'OD UDF8',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF9',               'OD UDF9',                  30,      -2,      null,      null,         null, null
union select  'OD_UDF10',              'OD UDF10',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF11',              'OD UDF11',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF12',              'OD UDF12',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF13',              'OD UDF13',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF14',              'OD UDF14',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF15',              'OD UDF15',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF16',              'OD UDF16',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF17',              'OD UDF17',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF18',              'OD UDF18',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF19',              'OD UDF19',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF20',              'OD UDF20',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF21',              'OD UDF21',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF22',              'OD UDF22',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF23',              'OD UDF23',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF24',              'OD UDF24',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF25',              'OD UDF25',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF26',              'OD UDF26',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF27',              'OD UDF27',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF28',              'OD UDF28',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF29',              'OD UDF29',                 30,      -2,      null,      null,         null, null
union select  'OD_UDF30',              'OD UDF30',                 30,      -2,      null,      null,         null, null

union select  'vwOD_UDF1',             'vwOD_UDF1',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF2',             'vwOD_UDF2',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF3',             'vwOD_UDF3',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF4',             'vwOD_UDF4',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF5',             'vwOD_UDF5',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF6',             'vwOD_UDF6',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF7',             'vwOD_UDF7',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF8',             'vwOD_UDF8',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF9',             'vwOD_UDF9',                85,      -2,      null,      null,         null, null
union select  'vwOD_UDF10',            'vwOD_UDF10',               85,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Order Headers */
union select  'OrderId',               'Order Id',                 65,      -3,      null,      null,         null, null
union select  'PickTicket',            'Pick Ticket',             105,       1,      null,      null,         null, null
union select  'SalesOrder',            'Order',                    70,      -1,      null,      null,         null, null

union select  'OrderType',             'Order Type',              110,      -2,      null,      null,          'Y', null
union select  'OrderTypeDescription',  'Order Type',               90,      -1,      null,      null,          'N', null
union select  'OrderTypeDesc',         'Order Type',               90,      -1,      null,      null,          'N', null
union select  'OrderStatus',           'Order Status',            110,      -2,      null,      null,          'Y', null
union select  'OrderStatusDesc',       'Order Status',             90,       1,      null,      null,          'N', null

union select  'Account',               'Account',                  70,       1,  'Center',      null,         null, null
union select  'AccountName',           'Account Name',            100,      -1,      null,      null,         null, null
union select  'SoldToId',              'Sold To',                  80,      -1,      null,      null,         null, null
union select  'ShipToId',              'Ship To',                  80,      -1,      null,      null,         null, null
union select  'ShipToStore',           'DC/Store',                 80,      -1,      null,      null,         null, null
union select  'ShipToDC',              'DC #',                     80,      -1,      null,      null,         null, null

union select  'OrderCategory1',        'Order Class',              90,       1,      null,      null,         null, null
union select  'OrderCategory2',        'Order Category2',         100,      -1,      null,      null,         null, null
union select  'OrderCategory3',        'Order Category3',         100,      -1,      null,      null,         null, null
union select  'OrderCategory4',        'Order Category4',         100,      -1,      null,      null,         null, null
union select  'OrderCategory5',        'Order Category5',         100,      -1,      null,      null,         null, null

union select  'PrevWaveNo',            'Prev Wave #',              80,      -1,      null,      null,         null, null
union select  'CustPO',                'Cust PO',                 105,      -1,      null,      null,         null, null
union select  'TotalSalesAmount',      '$ Value',                  85,      -1,      null,      null,         null, '{0:c2}'
union select  'TotalShipmentValue',    'Total Shipment Value',    120,      -1,      null,      null,         null, '{0:c2}'
union select  'PickBatchGroup',        'Wave Group',               85,      -1,      null,      null,         null, null
union select  'WaveGroup',             'Wave Group',               85,      -1,      null,      null,         null, null
union select  'CartonGroups',          'Carton Groups',            90,      -1,      null,      null,         null, null

union select  'BillToAccount',         'Bill To Account',          90,      -1,      null,      null,         null, null
union select  'BillToAddress',         'Bill To Address',          90,      -1,      null,      null,         null, null

union select  'ShipperAccountName',    'Shipper Account',         100,      -1,      null,      null,         null, null
union select  'AESNumber',             'AES Number',               90,      -1,      null,      null,         null, null
union select  'ShipmentRefNumber',     'Shipment Reference #',    120,      -1,      null,      null,         null, null
union select  'CarrierOptions',        'Carrier Options',          90,      -1,      null,      null,        'null',null
union select  'FreightCharges',        'Freight Charges',         100,      -1,      null,      null,         null, '{0:c2}'
union select  'FreightTerms',          'Freight Terms',            85,      -1,      null,      null,         null, null

union select  'OrderDate',             'Order Date',              100,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'DownloadedDate',        'Downloaded Date',         100,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'DownloadedOn',          'Downloaded On',            80,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'QualifiedDate',         'Qualified Date',          100,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'NB4Date',               'NB4Date',                 100,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'DesiredShipDate',       'To Ship On',              100,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'CancelDate',            'Cancel Date',             110,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'ShippedDate',           'Shipped Date',            110,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'OrderShippedDate',      'Shipped Date',            110,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'DeliveryStart',         'Delivery Start',           90,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'DeliveryEnd',           'Delivery end',             90,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'

union select  'CancelDays',            'Cancel in Days',           85,      -1,  'Center',      null,         null, null
union select  'OrderAge',              'Order Age',                75,      -1,  'Center',      null,         null, null

union select  'HasNotes',              'Notes',                    60,      -1,  'Center',      null,         null, null
union select  'ShipCompletePercent',   'Ship Complete %',         120,      -1,      null,      null,         null, '{0:F2}'
union select  'WaveFlag',              'Wave Flag',                70,      -1,      null,      null,         null, null
union select  'CustAccount',           'Cust Account',             70,      -1,  'Center',      null,         null, null
union select  'CustAccountName',       'Cust Account Name',       120,      -1,      null,      null,         null, null
union select  'PreprocessFlag',        'Preprocess Status',        70,      -1,      null,      null,         null, null
union select  'HostNumLines',          'Expected Lines',           90,      -1,      null,      null,         null, null
union select  'EstimatedCartons',      'Estimated Cartons',       100,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'ProcessOperation',      'Process Operation',        85,      -2,      null,      null,         null, null
union select  'ExchangeStatus',        'Xchg Status',              60,      -2,      null,      null,         'Y',  null
union select  'ShipComplete',          'Ship Complete',            90,      -2,      null,      null,         null, null

union select  'VASCodes',              'VAS',                      90,      -1,      null,      null,         null, null
union select  'VASDescriptions',       'VAS Desc',                 90,      -1,      null,      null,         null, null

union select  'ShipFromCompanyId',     'Ship From Company',       120,      -1,      null,      null,         null, null
union select  'UCC128LabelFormat',     'UCC128 LabelFormat',      120,      -1,      null,      null,         null, null
union select  'PackingListFormat',     'Packing List Format',     120,      -1,      null,      null,         null, null
union select  'ContentsLabelFormat',   'Contents Label Format',   120,      -1,      null,      null,         null, null
union select  'PriceStickerFormat',    'Price Sticker Format',    120,      -1,      null,      null,         null, null

union select  'ReturnLabelRequired',   'Return Label Required',   120,      -1,      null,      null,         null, null
union select  'PrevStatus',            'Prev Status',              70,      -1,      null,      null,         null, null

union select  'OH_Category1',          'OH Category1',            100,      -1,      null,      null,         null, null
union select  'OH_Category2',          'OH Category2',            100,      -1,      null,      null,         null, null
union select  'OH_Category3',          'OH Category3',            100,      -1,      null,      null,         null, null
union select  'OH_Category4',          'OH Category4',            100,      -1,      null,      null,         null, null
union select  'OH_Category5',          'OH Category5',            100,      -1,      null,      null,         null, null

union select  'OH_UDF1',               'OH_UDF1',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF2',               'OH_UDF2',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF3',               'OH_UDF3',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF4',               'OH_UDF4',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF5',               'OH_UDF5',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF6',               'OH_UDF6',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF7',               'OH_UDF7',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF8',               'OH_UDF8',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF9',               'OH_UDF9',                  30,      -2,      null,      null,         null, null
union select  'OH_UDF10',              'OH_UDF10',                 30,      -2,      null,      null,         null, null

union select  'OH_UDF11',              'OH_UDF11',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF12',              'OH_UDF12',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF13',              'OH_UDF13',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF14',              'OH_UDF14',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF15',              'OH_UDF15',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF16',              'OH_UDF16',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF17',              'OH_UDF17',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF18',              'OH_UDF18',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF19',              'OH_UDF19',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF20',              'OH_UDF20',                 30,      -2,      null,      null,         null, null

union select  'OH_UDF21',              'OH_UDF21',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF22',              'OH_UDF22',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF23',              'OH_UDF23',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF24',              'OH_UDF24',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF25',              'OH_UDF25',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF26',              'OH_UDF26',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF27',              'OH_UDF27',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF28',              'OH_UDF28',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF29',              'OH_UDF29',                 30,      -2,      null,      null,         null, null
union select  'OH_UDF30',              'OH_UDF30',                 30,      -2,      null,      null,         null, null

union select  'vwOH_UDF1',             'vwOH_UDF1',                20,      -2,      null,      null,         null, null
union select  'vwOH_UDF2',             'vwOH_UDF2',                20,      -2,      null,      null,         null, null
union select  'vwOH_UDF3',             'vwOH_UDF3',                20,      -2,      null,      null,         null, null
union select  'vwOH_UDF4',             'vwOH_UDF4',                20,      -2,      null,      null,         null, null
union select  'vwOH_UDF5',             'vwOH_UDF5',                20,      -2,      null,      null,         null, null

union select  'WaveSeqNo',             'Wave SeqNo',               20,      -2,      null,      null,         null, null
union select  'LoadSeqNo',             'Load SeqNo',               20,      -2,      null,      null,         null, null
/*----------------------------------------------------------------------------*/
/* Order Counts */
union select  'OrdersWaved',           'Orders Waved',             90,      -1,      null,      null,         null, null
union select  'OrdersAllocated',       'Orders Allocated',        120,      -1,      null,      null,         null, null
union select  'OrdersToAllocate',      'Orders To Allocate',      120,      -1,      null,      null,         null, null
union select  'OrdersPicked',          'Orders Picked',            90,      -1,      null,      null,         null, null
union select  'OrdersToPick',          'Orders To Pick',           90,      -1,      null,      null,         null, null
union select  'OrdersPacked',          'Orders Packed',            90,      -1,      null,      null,         null, null
union select  'OrdersToPack',          'Orders To Pack',           90,      -1,      null,      null,         null, null
union select  'OrdersStaged',          'Orders Staged',            90,      -1,      null,      null,         null, null
union select  'OrdersToStage',         'Orders To Stage',         100,      -1,      null,      null,         null, null
union select  'OrdersLoaded',          'Orders Loaded',            90,      -1,      null,      null,         null, null
union select  'OrdersToLoad',          'Orders To Load',           95,      -1,      null,      null,         null, null
union select  'OrdersShipped',         'Orders Shipped',           90,      -1,      null,      null,         null, null
union select  'OrdersToShip',          'Orders To Ship',           90,      -1,      null,      null,         null, null
union select  'OrdersOpen',            'Open Orders',              80,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Order Counts - Units */
union select  'UnitsPicked',           '# Picked',                 70,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsPacked',           '# Packed',                 80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsToPack',           '# To Pack',                90,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsStaged',           '# Staged',                 70,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsToStage',          '# To Stage',               70,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsLoaded',           '# Loaded',                 70,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsToLoad',           '# To Load',                70,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsLabeled',          '# Labeled',                70,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsShipped',          '# Shipped',                70,      -1,      null,      null,         null, '{0:###,###,###}'

/*----------------------------------------------------------------------------*/
/* OrderStatusSummary */
union select  'Target',                'Target',                   85,       1,      null,      null,         null, null
union select  'OrdersReadyToPick',     'Orders ReadyTo Pick',     120,       1,      null,      null,         null, null
union select  'OrdersWaitingReplen',   'Orders Waiting Replen',   120,       1,      null,      null,         null, null
union select  'OrdersWaitingPA',       'Orders Waiting PA',       100,       1,      null,      null,         null, null
union select  'NumLPNsToPA',           '# LPNs To PA',             95,       1,      null,      null,         null, null
union select  'OrdersWaitingOnPicks',  'Orders Waiting OnPicks',  130,       1,      null,      null,         null, null
union select  'NumReplenTasks',        'Num Replen Tasks',        120,       1,      null,      null,         null, null
union select  'NumReplenLPNs',         'Num Replen LPNs',         100,       1,      null,      null,         null, null
union select  'TotalOrdersToWave',     'Total Orders ToWave',     120,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Packing */
union select  'SKUBarcode',            'SKU Barcode',              70,      -1,      null,      null,         null, null
union select  'PickedFromLocation',    'Picked From Location',     85,      -1,      null,      null,         null, null
union select  'PageTitle',             'Page Title',               85,      -1,      null,      null,         null, null
union select  'PickedQuantity',        '# on Cart',               120,       1,      null,      null,         null, '{0:###,###,###}'
union select  'GiftCardSerialNumber',  'Serial #',                250,      -1,      null,      null,         null, null
union select  'PackGroupKey',          'Pack Group Key',          250,      -1,      null,      null,         null, null

union select  'vwOPDtls_UDF1',         'vwOPDtls_UDF1',            85,      -2,      null,      null,         null, null
union select  'vwOPDtls_UDF2',         'vwOPDtls_UDF2',            85,      -2,      null,      null,         null, null
union select  'vwOPDtls_UDF3',         'vwOPDtls_UDF3',            85,      -2,      null,      null,         null, null
union select  'vwOPDtls_UDF4',         'vwOPDtls_UDF4',            85,      -2,      null,      null,         null, null
union select  'vwOPDtls_UDF5',         'vwOPDtls_UDF5',            85,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Pallets */
union select  'PalletId',              'Pallet Id',                 0,      -3,      null,      null,         null, null
union select  'Pallet',                'Pallet',                   75,       1,      null,      null,         null, null
union select  'PalletType',            'Type',                     85,      -2,      null,      null,          'Y', null
union select  'PalletTypeDescription', 'Type',                    110,      -2,      null,      null,          'N', null
union select  'PalletTypeDesc',        'Pallet Type',             110,      -1,      null,      null,          'N', null
union select  'PalletStatus',          'Status',                   85,      -2,      null,      null,          'Y', null
union select  'PalletStatusDesc',      'Status',                  110,       1,      null,      null,          'N', null

union select  'CartType',              'Cart Type',               110,       1,      null,      null,         null, null
union select  'PackingByUser',         'Packing By User',         100,       1,      null,      null,         null, null

union select  'PAL_UDF1',              'PAL_UDF1',                 70,      -2,      null,      null,         null, null
union select  'PAL_UDF2',              'PAL_UDF2',                 70,      -2,      null,      null,         null, null
union select  'PAL_UDF3',              'PAL_UDF3',                 70,      -2,      null,      null,         null, null
union select  'PAL_UDF4',              'PAL_UDF4',                 70,      -2,      null,      null,         null, null
union select  'PAL_UDF5',              'PAL_UDF5',                 70,      -2,      null,      null,         null, null

union select  'vwPAL_UDF1',            'vwPAL_UDF1',               70,      -2,      null,      null,         null, null
union select  'vwPAL_UDF2',            'vwPAL_UDF2',               70,      -2,      null,      null,         null, null
union select  'vwPAL_UDF3',            'vwPAL_UDF3',               70,      -2,      null,      null,         null, null
union select  'vwPAL_UDF4',            'vwPAL_UDF4',               70,      -2,      null,      null,         null, null
union select  'vwPAL_UDF5',            'vwPAL_UDF5',               70,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Panda Labels */
union select  'InBarcode',             'In Barcode',               90,       1,      null,      null,         null, null
union select  'LabelVerify',           'Label Verify',             85,       1,      null,      null,         null, null
union select  'LabelData',             'Label Data',               90,       1,      null,      null,         null, null
union select  'LabelType',             'Label Type',               90,       1,      null,      null,         null, null
union select  'StationName',           'Station Name',             95,       1,      null,      null,         null, null
union select  'LabeledDateTime',       'Labeled Date Time',       140,       1,      null,      null,         null, null
union select  'ExportDateTime',        'Export Date Time',        140,       1,      null,      null,         null, null
union select  'InductionStatus',       'Induction Status',        120,       1,      null,      null,         null, null
union select  'InductedDate',          'Inducted Date',           140,       1,      null,      null,         null, null
union select  'ConfirmationStatus',    'Confirmation Status',     130,       1,      null,      null,         null, null
union select  'ConfirmedDate',         'Confirmed Date',          140,       1,      null,      null,         null, null
union select  'PandAStation',          'PandA Station',           100,       1,      null,      null,         null, null
union select  'ErrorMessage',          'Error Message',           105,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Report Formats */
union select  'ReportName',            'Report Name',             130,       1,      null,      null,         null, null
union select  'ReportDescription',     'Report Description',      150,       1,      null,      null,         null, null
union select  'ReportTemplateName',    'Report Template Name',    150,      -1,      null,      null,         null, null
union select  'ReportSchema',          'Report Schema',           150,       1,      null,      null,         null, null
union select  'ReportFileName',        'File Name',               100,      -1,      null,      null,         null, null
union select  'ReportDisplayName',     'Display Name',            100,       1,      null,      null,         null, null
union select  'FolderName',            'Folder Name',             100,      -1,      null,      null,         null, null
union select  'PageSize',              'Page Size',               100,      -1,      null,      null,         null, null
union select  'DocumentType',          'Document Type',           150,       1,      null,      null,         null, null
union select  'DocumentSubType',       'Document Sub Type',       150,      -1,      null,      null,         null, null
union select  'DocumentSet',           'Document set',            150,       1,      null,      null,         null, null
union select  'ReportProcedureName',   'Procedure Name',          150,      -1,      null,      null,         null, null
/* To add more...? */

/*----------------------------------------------------------------------------*/
/* Waves */
union select  'PickBatchId',           'Wave Id',                  90,      -3,      null,      null,         null, '{0:.}'
union select  'WaveId',                'Wave Id',                  60,      -3,      null,      null,         null, null

union select  'PickBatch',             'Wave',                     80,       1,      null,      null,         null, null
union select  'PickBatchNo',           'Wave',                     90,      -1,      null,      null,         null, null
union select  'BatchNo',               'Wave',                     90,       1,      null,      null,         null, null
union select  'WaveNo',                'Wave',                     90,       1,      null,      null,         null, null

union select  'WaveType',              'Wave Type',                90,      -2,      null,      null,         'Y',  null
union select  'WaveTypeDesc',          'Wave Type',               110,       1,      null,      null,         'N',  null
union select  'WaveStatus',            'Wave Status',             100,      -2,      null,      null,         'Y',  null
union select  'WavePriority',          'Wave Priority',           100,      -2,      null,      null,         null, null
union select  'WaveStatusDesc',        'Wave Status',             100,       1,      null,      null,         'N',  null

union select  'BatchType',             'Wave Type',                90,      -1,      null,      null,         null, null
union select  'BatchTypeDesc',         'Wave Type',               110,       1,      null,      null,         null, null
union select  'BatchAssignedTo',       'Wave Assigned To',        130,       1,      null,      null,         null, null
union select  'BatchStatus',           'Wave Status',             100,       1,      null,      null,         null, null
union select  'WaveShipDate',          'Ship Date',               100,      -1,      null,      null,         null, null
union select  'WaveCancelDate',        'Wave Cancel Date',        135,      -1,      null,      null,         null, null
union select  'PickDate',              'Pick Date',                90,      -1,  'Center',      null,         null, null
union select  'ShipDate',              'Ship Date',                90,      -1,  'Center',      null,         null, null
union select  'ReleaseDateTime',       'ReleaseDateTime',         135,      -1,      null,      null,         null, null
union select  'LastPutawayDate',       'Last Putaway Date',       130,      -1,  'Center',      null,         null, null
union select  'PickZone',              'Pick Zone',                80,      -2,      null,      null,         'Y',  null
union select  'PickZones',             'Pick Zones',               80,      -2,      null,      null,         'Y',  null
union select  'PickGroup',             'Pick Group',               80,      -2,      null,      null,         null, null
union select  'PickZoneDesc',          'Pick Zone',               125,      -1,      null,      null,         null, null
union select  'AssignedTo',            'Assigned To',              90,       1,      null,      null,         null, null
union select  'AllocateFlags',         'Allocate Flags',           90,      -1,      null,      null,         null, null
union select  'IsAllocated',           'Is Allocated',             90,      -1,      null,      null,         null, null
union select  'InvAllocationModel',    'Allocation Model',         90,      -1,      null,      null,         null, null
union select  'CartonizationModel',    'Cartonization Model',      90,      -1,      null,      null,         null, null
union select  'PickMethod',            'Pick Method',             100,      -1,      null,      null,         null, null
union select  'WCSStatus',             'WSS Status',               90,      -1,      null,      null,         null, null
union select  'WCSDependency',         'Ready to Pick?',           90,      -1,      null,      null,         null, null
union select  'ColorCode',             'Color',                    90,      -2,      null,      null,         null, null

union select  'UnitsReservedForWave',   'Available for Wave',      90,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'ToActivateShipCartonQty','To Activate',             90,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsRequiredtoActivate','Short to Activate',       90,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'W_UDF1',                'W_UDF1',                   30,      -2,      null,      null,         null, null
union select  'W_UDF2',                'W_UDF2',                   30,      -2,      null,      null,         null, null
union select  'W_UDF3',                'W_UDF3',                   30,      -2,      null,      null,         null, null
union select  'W_UDF4',                'W_UDF4',                   30,      -2,      null,      null,         null, null
union select  'W_UDF5',                'W_UDF5',                   30,      -2,      null,      null,         null, null
union select  'W_UDF6',                'W_UDF6',                   30,      -2,      null,      null,         null, null
union select  'W_UDF7',                'W_UDF7',                   30,      -2,      null,      null,         null, null
union select  'W_UDF8',                'W_UDF8',                   30,      -2,      null,      null,         null, null
union select  'W_UDF9',                'W_UDF9',                   30,      -2,      null,      null,         null, null
union select  'W_UDF10',               'W_UDF10',                  30,      -2,      null,      null,         null, null

union select  'vwW_UDF1',              'vwW_UDF1',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF2',              'vwW_UDF2',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF3',              'vwW_UDF3',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF4',              'vwW_UDF4',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF5',              'vwW_UDF5',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF6',              'vwW_UDF6',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF7',              'vwW_UDF7',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF8',              'vwW_UDF8',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF9',              'vwW_UDF9',                 40,      -2,      null,      null,         null, null
union select  'vwW_UDF10',             'vwW_UDF10',                40,      -2,      null,      null,         null, null

union select  'WaveDropLocation',      'Wave DropLocation',       180,      -1,      null,      null,         null, null

union select  'BatchPickDate',         'Pick Date',                90,      -2,      null,      null,         null, null
union select  'BatchToShipDate',       'Ship Date',                90,      -2,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'BatchDescription',      'Wave Desc.',              115,      -1,      null,      null,         null, null


union select  'DefaultUoM',            'Default UoM',              80,       1,      null,      null,         null, null

union select  'DetailModifiedDate',    'Detail Modified Date',     80,      -1,      null,      null,         null, null
union select  'DetailModifiedBy',      'Detail Modified By',       80,      -1,      null,      null,         null, null
union select  'LPNsOrdered',           'Ordered',                  55,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsNeeded',            'Needed',                   55,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'AvailLPNs',             'Avail.',                   55,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsAvailable',         'Avail.',                   55,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsShort',             'Short',                    50,      -2,      null,      null,         null, '{0:###,###,###}'

union select  'PickLocation',          'Pick Location',           100,       1,      null,      null,         null, null
union select  'ReferenceLocation',     'Reference Location',      100,       1,      null,      null,         null, null

union select  'PickedBy',              'Picked By',                80,      -1,      null,      null,         null, null
union select  'PackedBy',              'Packed By',                80,      -1,      null,      null,         null, null
union select  'PickedDate',            'Picked on',                80,      -1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'PackedDate',            'Packed on',                90,      -1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'PickBatchCancelDate',   'Wave Cancel Date',        150,       1,      null,      null,         null, null
union select  'Line',                  'Line',                     30,       1,      null,      null,         null, null

union select  'UnitsPerCarton',        'Pack Qty',                 60,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsPreAllocated',     '# Pre-allocated',          90,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsNeeded',           '# Needed',                 70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsAvailable',        '# In Stock',               70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsShort',            '# Short',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsAvailablePicklane','# In Picklane',           120,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsShortPicklane',    '# Short In Picklane',     120,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsAvailableReserve', '# In Reserve',            120,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsShortReserve',     '# Short In Reserve',      120,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'CasesOrdered',          '# CasesOrdered',          100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesToShip',           '# Cases ToShip',          100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesPreAllocated',     '# Cases PreAllocated',    100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesAssigned',         '# Cases Assigned',        100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesNeeded',           '# Cases Needed',          100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesPicked',           '# Cases Picked',          100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesPacked',           '# Cases Packed',          100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesPacked',           '# Cases Packed',          100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesLabeled',          '# Cases Labeled',         100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesStaged',           '# Cases Staged',          100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesLoaded',           '# Cases Loaded',          100,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'CasesShipped',          '# Cases Shipped',         100,      -2,      null,      null,         null, '{0:###,###,###}'

union select  'PrimaryLocation',       'Primary Location',        110,       1,      null,      null,         null, null
union select  'SecondaryLocation',     'Secondary Location',      120,       1,      null,      null,         null, null

union select  'PB_UDF1',               'PB UDF1',                  30,      -2,      null,      null,         null, null
union select  'PB_UDF2',               'PB UDF2',                  30,      -2,      null,      null,         null, null
union select  'PB_UDF3',               'PB UDF3',                  70,      -2,      null,      null,         null, null
union select  'PB_UDF4',               'PB UDF4',                  30,      -2,      null,      null,         null, null
union select  'PB_UDF5',               'PB UDF5',                  30,      -2,      null,      null,         null, null
union select  'PB_UDF6',               'PB UDF6',                  30,      -2,      null,      null,         null, null
union select  'PB_UDF7',               'PB UDF7',                  30,      -2,      null,      null,         null, null
union select  'PB_UDF8',               'PB UDF8',                  30,      -2,      null,      null,         null, null
union select  'PB_UDF9',               'PB UDF9',                  30,      -2,      null,      null,         null, null
union select  'PB_UDF10',              'PB UDF10',                 30,      -2,      null,      null,         null, null

union select  'vwOTW_UDF1',            'vwOTW_UDF1',               70,      -2,      null,      null,         null, null
union select  'vwOTW_UDF2',            'vwOTW_UDF2',               70,      -2,      null,      null,         null, null
union select  'vwOTW_UDF3',            'vwOTW_UDF3',               70,      -2,      null,      null,         null, null
union select  'vwOTW_UDF4',            'vwOTW_UDF4',               70,      -2,      null,      null,         null, null
union select  'vwOTW_UDF5',            'vwOTW_UDF5',               70,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* PickBatchAttributes */
union select  'AvgUnitsPerOrder',      'Avg. Units Per Order',     85,       1,      null,      null,         null, null
union select  'DefaultDestination',    'Default Destination',      95,       1,      null,      null,         null, null
union select  'NumSKUOrdersPerBatch',  '% of Orders needing SKU', 100,       1,      null,      null,         null, null
union select  'SorterExportStatus',    'Sorter Export Status',     80,       1,      null,      null,         null, null
union select  'UnitsPerLine',          'Units per Line',           80,       1,      null,      null,         null, null
union select  'IsReplenished',         'Is Replenished',           90,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* PickTasks */
union select  'PickZoneDescription',   'Pick Zone',               120,       1,      null,      null,         null, null
union select  'DetailQuantity',        'Task Line Qty',           105,       1,      null,      null,         null, '{0:###,###,###}'
union select  'DetailInnerPacks',      'Task Line Cases',         115,       1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNQuantity',           'LPN Qty',                  80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'PickBatchStatus',       'Wave Status',              95,       1,      null,      null,         null, null
union select  'TotalAmount',           'Amt',                      65,      -1,      null,      null,         null, null
union select  'BatchPickZone',         'Wave Pick Zone',          110,      -2,      null,      null,         null, null
union select  'BatchPickTicket',       'Pick Ticket',              85,       1,      null,      null,         null, null
union select  'BatchPalletId',         'Pallet Id',                85,      -1,      null,      null,         null, null
union select  'BatchPallet',           'Pallet',                   85,       1,      null,      null,         null, null
union select  'PickBatchWarehouse',    'WH',                       85,       1,      null,      null,         null, null
union select  'DropLocation',          'Drop Location',           110,       1,      null,      null,         null, null
union select  'TaskCategory1',         'Category1',                85,      -1,      null,      null,         null, null
union select  'TaskCategory2',         'Category2',                85,      -1,      null,      null,         null, null
union select  'TaskCategory3',         'Category3',                85,      -1,      null,      null,         null, null
union select  'TaskCategory4',         'Category4',                85,      -1,      null,      null,         null, null
union select  'TaskCategory5',         'Category5',                85,      -1,      null,      null,         null, null
union select  'TaskPriority',          'Priority',                 85,      -1,      'Center',  null,         null, '{0:.}'
union select  'TotalInnerPacks',       '# Cases',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'TotalUnits',            '# Units',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'PickWeight',            'Pick Wgt',                 85,      -1,      null,      null,         null, '{0:n2}'
union select  'PickVolume',            'Pick Vol',                 85,      -1,      null,      null,         null, '{0:n2}'
union select  'InnerPacksToPick',      'Cases To Pick',            85,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'InnerPacksCompleted',   'Cases Picked',            100,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsToPick',           '# To Pick',                85,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsCompleted',        '# Units Picked',          100,       1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentUnitsComplete',  '% Units Complete',        105,       1,      null,      null,         null, null

union select  'IsLabelGenerated',      'IsLabelGenerated',        120,      -1,      null,      null,         null, null
union select  'LabelsPrinted',         'Printed',                  55,       1,  'Center',      null,         null, null
union select  'PrintStatus',           'Print Status',             55,       1,  'Center',      null,         null, null
union select  'DependentOn',           'Dependent On',            100,       1,      null,      null,         null, null

union select  'vwPT_UDF1',             'vwPT_UDF1',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF2',             'vwPT_UDF2',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF3',             'vwPT_UDF3',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF4',             'vwPT_UDF4',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF5',             'vwPT_UDF5',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF6',             'vwPT_UDF6',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF7',             'vwPT_UDF7',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF8',             'vwPT_UDF8',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF9',             'vwPT_UDF9',                70,      -2,      null,      null,         null, null
union select  'vwPT_UDF10',            'vwPT_UDF10',               70,      -2,      null,      null,         null, null

union select  'vwT_UDF1',              'vwT_UDF1',                 70,      -2,      null,      null,         null, null
union select  'vwT_UDF2',              'vwT_UDF2',                 70,      -2,      null,      null,         null, null
union select  'vwT_UDF3',              'vwT_UDF3',                 70,      -2,      null,      null,         null, null
union select  'vwT_UDF4',              'vwT_UDF4',                 70,      -2,      null,      null,         null, null
union select  'vwT_UDF5',              'vwT_UDF5',                 70,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Wave Rules */
union select  'OrderPriority',         'Order Priority',          120,       1,      'Center',  null,         null, null
union select  'DestLocationId',        'Dest LocationId',         100,      -1,      null,      null,         null, null
union select  'DestLocation',          'Dest Location',           100,       1,      null,      null,         null, null
union select  'DestZone',              'Dest Zone',                85,      -1,      null,      null,         null, null
union select  'MaxLines',              'Max Lines',                65,      -1,      null,      null,         null, null
union select  'MaxOrders',             'Max Orders',               70,      -1,      null,      null,         null, null
union select  'MaxSKUs',               'Max SKUs',                 65,      -1,      null,      null,         null, null
union select  'MaxVolume',             'Max Volume',               95,      -1,      null,      null,         null, null
union select  'MaxPallets',            'Max Pallets',              75,      -1,      null,      null,         null, null
union select  'MaxLPNs',               'Max LPNs',                 75,      -1,      null,      null,         null, null
union select  'MaxInnerPacks',         'Max Cases',                75,      -1,      null,      null,         null, null
union select  'MaxUnits',              'Max Units',                70,      -1,      null,      null,         null, null
union select  'BatchPriority',         'Wave Priority',            95,       1,      'Center',  null,         null, null
union select  'MaxWeight',             'Max Weight',               85,      -1,      null,      null,         null, '{0:n2}'
union select  'OrderVolumeMax',        'Order Volume Max',        115,      -1,      null,      null,         null, '{0:.}'
union select  'OrderVolumeMin',        'Order Volume Min',        115,      -1,      null,      null,         null, '{0:.}'
union select  'OrderWeightMax',        'Order Weight Max',        115,      -1,      null,      null,         null, '{0:.}'
union select  'OrderWeightMin',        'Order Weight Min',        115,      -1,      null,      null,         null, '{0:.}'
union select  'BatchingLevel',         'Wave Level',               90,      -1,      'Center',  null,         null, null

union select  'BatchStatusDescription','Wave Status',              80,      -1,      null,      null,         null, null
union select  'BatchTypeDescription',  'Wave Type',                70,      -1,      null,      null,         null, null
union select  'DestZoneDescription',   'Dest Zone',                70,      -1,      null,      null,         null, null
union select  'DestZoneDisplayDescription',
                                       'Dest Zone',                70,      -1,      null,      null,         null, null
union select  'OrderInnerPacks',       'Cases On Order',           95,      -1,      null,      null,         null, null
union select  'OrderUnits',            'Units On Order',           95,      -1,      null,      null,         null, null

union select  'VersionId',             'VersionId',                70,      -2,      null,      null,         null, null
union select  'WaveRuleGroup',         'WaveRuleGroup',           120,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Productivity */
union select  'LogId',                 'LogId',                    70,      -3,      null,      null,         null, null
union select  'ProductivityId',        'ProductivityId',           70,      -3,      null,      null,         null, null
union select  'ActivityDate',          'Date',                    110,       1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'Assignment',            'Assignment',               70,       1,      null,      null,         null, null
union select  'SubOperation',          'Operation',                70,       1,      null,      null,         null, null
union select  'JobCode',               'Job Code',                 70,       1,      null,      null,         null, null
union select  'UnitsPerHr',            'Units/Hr',                 70,       1,      null,      null,         null, null
union select  'UnitsPerMin',           'Units/Min',                70,       1,      null,      null,         null, null
union select  'LPNsPerHr',             'Units/Hr',                 70,       1,      null,      null,         null, '{0:.}'
union select  'LPNsPerMin',            'Units/Min',                70,       1,      null,      null,         null, '{0:.}'
union select  'LocationsPerHr',        '# Locs/Hr',                70,       1,      null,      null,         null, '{0:.}'
union select  'LocationsPerMin',       '# Locs/Min',               70,       1,      null,      null,         null, '{0:.}'

union select  'Duration',              'Duration',                 70,       1,      null,      null,         null, '{0:hh:mm:ss}'
union select  'DurationInSecs',        'Time (secs)',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'DurationInMins',        'Time (mins)',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'DurationInHrs',         'Time (hrs)',               70,       1,      null,      null,         null, '{0:.}'

/*----------------------------------------------------------------------------*/
/* Putaway Rules */
union select  'LocationStatusDescription',
                                       'Location Status',         115,       1,      null,      null,         null, null
union select  'LocationTypeDescription',
                                       'Location Type',           115,       1,      null,      null,         null, null
union select  'SequenceNo',            'Sequence No',              90,       1,  'Center',      null,         null, null
union select  'SKUExists',             'SKU Exists',               90,       1,      null,      null,         null, null
union select  'PAType',                'PA Type',                  90,      -2,      null,      null,         null, null
union select  'PATypeDescription',     'PA Type',                  90,       1,      null,      null,         null, null
union select  'StorageTypeDescription','Storage Type',             85,       1,      null,      null,         null, null
union select  'PutawayZoneDescription','Putaway Zone',            110,      -1,      null,      null,         null, null
union select  'LPNPutawayClass',       'LPN PA Class',            120,       1,      null,      null,         null, null
union select  'LPNPutawayClassDesc',   'LPN PA Class',            120,       1,      null,      null,         null, null
union select  'SKUPutawayClass',       'SKU PA Class',            120,      -2,      null,      null,         null, null
union select  'SKUPutawayClassDescription',
                                       'SKU PA Class',            110,      -2,      null,      null,         null, null
union select  'SKUPutawayClassDisplayDescription',
                                       'SKU PA Class',            110,      -1,      null,      null,         null, null
union select  'PutawayClassDescription','PutawayClassDescription', 85,      -1,      null,      null,         null, null
union select  'PutawayClassDisplayDescription',
                                 'PutawayClassDisplayDescription', 85,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* QC */
union select  'QCRecordId',            'QC RecordId',              70,      -3,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Receipts */
union select  'ReceiptId',             'Receipt Id',               90,      -3,      null,      null,         null, null
union select  'ReceiptNumber',         'Receipt #',               110,       1,      null,      null,         null, null
union select  'ReceiptType',           'Receipt Type',            110,      -2,      null,      null,          'Y', null
union select  'ReceiptTypeDesc',       'Receipt Type',            110,       1,      null,      null,          'N', null
union select  'ReceiptStatus',         'Receipt Status',          110,      -2,      null,      null,          'Y', null
union select  'ReceiptStatusDesc',     'Receipt Status',          110,       1,      null,      null,          'N', null

union select  'VendorId',              'Vendor Id',               100,      -1,      null,      null,         null, null
union select  'VendorSKU',             'Vendor SKU',              100,      -1,      null,      null,         null, null
union select  'VendorName',            'Vendor',                  100,       1,      null,      null,         null, null
union select  'Vessel',                'Vessel',                  120,       1,      null,      null,         null, null
union select  'ContainerNo',           'Container #',             110,       1,      null,      null,         null, null
union select  'ContainerSize',         'Cont. Size',               80,       1,      null,      null,         null, null

union select  'BillNo',                'Bill #',                  120,       1,      null,      null,         null, null
union select  'SealNo',                'Seal #',                  120,       1,      null,      null,         null, '{0:###,###,###}'
union select  'InvoiceNo',             'Invoice #',               110,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'DateOrdered',           'Ordered Date',            100,       1,  'Center',      null,         null, null
union select  'DateExpected',          'Expected Date',           100,      -2,  'Center',      null,         null, null
union select  'ETACountry',            'ETA USA',                  70,      -1,  'Center',      null,         null, '{0:MM/dd}'
union select  'ETACity',               'ETA City',                 70,      -1,  'Center',      null,         null, '{0:MM/dd}'
union select  'ETAWarehouse',          'ETA WH',                  100,       1,  'Center',      null,         null, '{0:MM/dd}'

union select  'UnitsReceived',         '# Received',               70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsInTransit',        '# In Transit',             70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ExtraQtyAllowed',       'Extra Allowed',            80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'MaxQtyAllowedToReceive','Max Allowed',              80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsInTransit',         'LPNs In Transit',         110,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'LPNsReceived',          'LPNs Received',           110,       1,      null,      null,         null, '{0:###,###,###}'

union select  'CoO',                   'Origin',                   60,      -1,  'Center',      null,         null, null
union select  'ShipmentId',            'Shipment',                 80,      -1,      null,      null,         null, '{0:.}'
union select  'PackingSlipNumber',     'Packing Slip #',           70,      -1,      null,      null,         null, null
union select  'ReceivedDate',          'Received Date',           150,      -1,      null,      null,         null, null

union select  'SortLanes',             'Lanes',                    70,      -1,      null,      null,         null, null
union select  'SortOptions',           'Sortation Options',       100,      -1,      null,      null,         null, null
union select  'SortStatus',            'Sortation Status',        100,      -1,      null,      null,         null, null

union select  'RH_UDF1',               'RH UDF1',                  50,      -2,      null,      null,         null, null
union select  'RH_UDF2',               'RH UDF2',                  30,      -2,      null,      null,         null, null   -- obsolete, to be changed
union select  'RH_UDF3',               'RH UDF3',                  30,      -2,      null,      null,         null, null
union select  'RH_UDF4',               'RH UDF4',                  30,      -2,      null,      null,         null, null
union select  'RH_UDF5',               'RH UDF5',                  30,      -2,      null,      null,         null, null
union select  'RH_UDF6',               'RH UDF6',                  30,      -2,      null,      null,         null, null
union select  'RH_UDF7',               'RH UDF7',                  30,      -2,      null,      null,         null, null
union select  'RH_UDF8',               'RH UDF8',                  30,      -2,      null,      null,         null, null
union select  'RH_UDF9',               'RH UDF9',                  30,      -2,      null,      null,         null, null
union select  'RH_UDF10',              'RH UDF10',                 30,      -2,      null,      null,         null, null

union select  'vwRH_UDF1',             'vwRH_UDF1',                30,      -2,      null,      null,         null, null
union select  'vwRH_UDF2',             'vwRH_UDF2',                30,      -2,      null,      null,         null, null
union select  'vwRH_UDF3',             'vwRH_UDF3',                30,      -2,      null,      null,         null, null
union select  'vwRH_UDF4',             'vwRH_UDF4',                30,      -2,      null,      null,         null, null
union select  'vwRH_UDF5',             'vwRH_UDF5',                30,      -2,      null,      null,         null, null

-- below are deprecated
union select  'RHU_UDF1',              'RHU UDF1',                 30,      -2,      null,      null,         null, null
union select  'RHU_UDF2',              'RHU UDF2',                 30,      -2,      null,      null,         null, null
union select  'RHU_UDF3',              'RHU UDF3',                 30,      -2,      null,      null,         null, null
union select  'RHU_UDF4',              'RHU UDF4',                 30,      -2,      null,      null,         null, null
union select  'RHU_UDF5',              'RHU UDF5',                 30,      -2,      null,      null,         null, null
-- below are deprecated
union select  'ROH_UDF1',              'ROH_UDF1',                 30,      -2,      null,      null,         null, null
union select  'ROH_UDF2',              'ROH_UDF2',                 30,      -2,      null,      null,         null, null
union select  'ROH_UDF3',              'ROH_UDF3',                 30,      -2,      null,      null,         null, null
union select  'ROH_UDF4',              'ROH_UDF4',                 30,      -2,      null,      null,         null, null
union select  'ROH_UDF5',              'ROH_UDF5',                 30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Receipt Details */
union select  'ReceiptDetailId',       'Receipt Detail Id',       100,      -3,      null,      null,         null, null
union select  'ReceiptLine',           'Receipt Line #',           70,      -2,      null,      null,          'N', null
union select  'HostReceiptLine',       'Host Receipt Line',       100,       1,      null,      null,         null, null

union select  'QtyOrdered',            '# Ordered',                80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'QtyReserved',           '# Reserved',               80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'QtyNeeded',             '# Needed',                 80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'QtyReceived',           '# Received',               80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'QtyInTransit',          '# In Transit',             80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'QtyToReceive',          '# To Receive',             90,       1,      null,      null,         null, '{0:###,###,###}'
union select  'QtyToLabel',            '# To Label',               90,       1,      null,      null,         null, '{0:###,###,###}'

union select  'RD_UDF1',               'RD UDF1',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF2',               'RD UDF2',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF3',               'RD UDF3',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF4',               'RD UDF4',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF5',               'RD UDF5',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF6',               'RD UDF6',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF7',               'RD UDF7',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF8',               'RD UDF8',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF9',               'RD UDF9',                  30,      -2,      null,      null,         null, null
union select  'RD_UDF10',              'RD UDF10',                 30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Receipt LPN Details */
union select  'vwROLPNDetails_UDF1',    'vwROLPNDetails_UDF1',     20,      -2,      null,      null,         null, null
union select  'vwROLPNDetails_UDF2',    'vwROLPNDetails_UDF2',     20,      -2,      null,      null,         null, null
union select  'vwROLPNDetails_UDF3',    'vwROLPNDetails_UDF3',     20,      -2,      null,      null,         null, null
union select  'vwROLPNDetails_UDF4',    'vwROLPNDetails_UDF4',     20,      -2,      null,      null,         null, null
union select  'vwROLPNDetails_UDF5',    'vwROLPNDetails_UDF5',     20,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Receivers */
union select  'ReceiverId',            'Receiver Id',              90,      -2,      null,      null,         null, null
union select  'ReceiverNumber',        'Receiver #',               90,       1,      null,      null,         null, null
union select  'ReceiverBoL',           'Receiver BoL #',          100,       1,      null,      null,         null, null
union select  'ReceiverDate',          'Receiver Date',            90,       1,      null,      null,         null, null
union select  'ReceiverStatus',        'Status',                  110,      -2,      null,      null,          'Y', null
union select  'ReceiverStatusDesc',    'Status',                  120,       1,      null,      null,          'N', null
union select  'Container',             'Container #',             110,       1,      null,      null,         null, null

union select  'ReceiverRef1',          'Reference #1',            120,      -1,      null,      null,         null, null
union select  'ReceiverRef2',          'Reference #2',            120,      -1,      null,      null,         null, null
union select  'ReceiverRef3',          'Reference #3',            120,      -1,      null,      null,         null, null
union select  'ReceiverRef4',          'Reference #4',            120,      -1,      null,      null,         null, null
union select  'ReceiverRef5',          'Reference #5',            120,      -1,      null,      null,         null, null

/* Below are deprecated, do not use */
union select  'RcvrReference1',        'Reference #1',            120,      -2,      null,      null,         null, null
union select  'RcvrReference2',        'Reference #2',            120,      -2,      null,      null,         null, null
union select  'RcvrReference3',        'Reference #3',            120,      -2,      null,      null,         null, null
union select  'RcvrReference4',        'Reference #4',            120,      -2,      null,      null,         null, null
union select  'RcvrReference5',        'Reference #5',            120,      -2,      null,      null,         null, null

union select  'RCV_UDF1',              'RCV UDF1',                 70,      -2,      null,      null,         null, null
union select  'RCV_UDF2',              'RCV UDF2',                 70,      -2,      null,      null,         null, null
union select  'RCV_UDF3',              'RCV UDF3',                 70,      -2,      null,      null,         null, null
union select  'RCV_UDF4',              'RCV UDF4',                 70,      -2,      null,      null,         null, null
union select  'RCV_UDF5',              'RCV UDF5',                 70,      -2,      null,      null,         null, null

union select  'vwRCV_UDF1',            'vwRCV UDF1',               70,      -2,      null,      null,         null, null
union select  'vwRCV_UDF2',            'vwRCV UDF2',               70,      -2,      null,      null,         null, null
union select  'vwRCV_UDF3',            'vwRCV UDF3',               70,      -2,      null,      null,         null, null
union select  'vwRCV_UDF4',            'vwRCV UDF4',               70,      -2,      null,      null,         null, null
union select  'vwRCV_UDF5',            'vwRCV UDF5',               70,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Replenishments */
union select  'PercentFull',           'Percent Full',             80,       1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsInProcess',        'Units In Process',        100,       1,      null,      null,         null, '{0:###,###,###}'
union select  'OrderedUnits',          '# Units Ordered',         100,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ResidualUnits',         '# Units Residual',        100,       1,      null,      null,         null, '{0:###,###,###}'

/*----------------------------------------------------------------------------*/
/* Rules */
union select  'RuleId',                'Rule Id',                  60,      -1,      null,      null,         null, null
union select  'RuleDescription',       'Rule Description',        120,       1,      null,      null,         null, null
union select  'RuleCondition',         'Rule Condition',          100,       1,      null,      null,         null, null
union select  'RuleQuery',             'Rule Query',              100,       1,      null,      null,         null, null
union select  'RuleConditionField',    'Rule Condition Field',    120,      -1,      null,      null,         null, null
union select  'RuleConditionOperator', 'Rule Condition Operator', 120,      -1,      null,      null,         null, null
union select  'RuleConditionValues',   'Rule Condition Values',   120,      -1,      null,      null,         null, null
union select  'RuleQueryType',         'Rule Query Type',         100,      -1,      null,      null,         null, null
union select  'RuleQuerySelect',       'Rule Query select',       100,      -1,      null,      null,         null, null
union select  'RuleQueryFrom',         'Rule Query From',         100,      -1,      null,      null,         null, null
union select  'RuleQueryWhere',        'Rule Query where',        100,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* RuleSets */
union select  'RuleSetId',             'RuleSet Id',               80,      -2,      null,      null,         null, null
union select  'RuleSetName',           'RuleSet Name',             80,       1,      null,      null,         null, null
union select  'RuleSetDescription',    'RuleSet Description',     120,       1,      null,      null,         null, null
union select  'RuleSetType',           'RuleSet Type',            100,       1,      null,      null,         null, null
union select  'RuleSetFilter',         'RuleSet Filter',          100,       1,      null,      null,         null, null
union select  'RuleFilterField',       'Rule Filter Field',       100,      -1,      null,      null,         null, null
union select  'RuleFilterOperator',    'Rule Filter Operator',    100,      -1,      null,      null,         null, null
union select  'RuleFilterValues',      'Rule Filter Values',      100,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* SerialNos */
union select  'SerialNo',              'Serial No',               120,       1,      null,      null,         null, null
union select  'SerialNoStatus',        'Serial No Status',         80,      -2,      null,      null,         'N',  null
union select  'SerialNoStatusDesc',    'Serial No Status',         80,       1,      null,      null,         'Y',  null

/*----------------------------------------------------------------------------*/
/* ShipTo */
union select  'ShipTo',                'Ship To',                  90,      -1,      null,      null,         null, null
union select  'ShipToName',            'Ship To Name',            110,       1,      null,      null,         null, null
union select  'ShipToDesc',            'Ship To Name',             70,      -1,      null,      null,         null, null
union select  'ShipToDescription',     'Ship To Name',             70,      -1,      null,      null,         null, null

union select  'ShipToAddressId',       'Ship To Address',         100,      -1,      null,      null,         null, null
union select  'ShipToAddressLine1',    'Ship To Address Line1',   120,       1,      null,      null,         null, null
union select  'ShipToAddressLine2',    'Ship To Address Line2',   120,       1,      null,      null,         null, null
union select  'ShipToAddressLine3',    'Ship To Address Line3',   120,      -1,      null,      null,         null, null
union select  'ShipToCity',            'Ship To City',             75,      -1,      null,      null,         null, null
union select  'ShipToState',           'Ship To State',            70,      -1,      null,      null,         null, null
union select  'ShipToZip',             'Ship To Zip',              70,      -1,      null,      null,         null, null
union select  'ShipToCityStateZip',    'Ship To City/State/Zip',  150,       1,      null,      null,         null, null
union select  'ShipToCityState',       'Ship To City/State',      110,       1,      null,      null,         null, null
union select  'ShipToCountry',         'Ship To Country',          70,      -1,      null,      null,         null, null
union select  'ShipToAddressRegion',    'Address Region',          30,       1,      null,      null,         null, null
union select  'ShipToEmail',           'Ship To Email',            70,      -1,      null,      null,         null, null
union select  'ShipToPhoneNo',         'Ship To PhoneNo',          70,      -1,      null,      null,         null, null
union select  'ShipToResidential',     'Ship To Residential',      70,      -1,      null,      null,         null, null
union select  'ShipToAddressReference1',
                                       'Ship To Address Ref1',    100,      -1,      null,      null,         null, null
union select  'ShipToAddressReference2',
                                       'Ship To Address Ref2',    100,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* SoldTo */
union select  'SoldTo',                'Sold To',                  70,      -1,      null,      null,         null, null
union select  'SoldToDesc',            'Sold To Name',             70,      -1,      null,      null,         null, null
union select  'SoldToDescription',     'Sold To Name',             70,      -1,      null,      null,         null, null

union select  'SoldToName',            'Sold To Name',            110,      -1,      null,      null,         null, null
union select  'SoldToAddressLine1',    'Sold To Address Line1',   100,      -1,      null,      null,         null, null
union select  'SoldToAddressLine2',    'Sold To Address Line2',   100,      -1,      null,      null,         null, null
union select  'SoldToCity',            'Sold To City',             80,      -1,      null,      null,         null, null
union select  'SoldToState',           'Sold To State',            80,      -1,      null,      null,         null, null
union select  'SoldToZip',             'Sold To Zip',              80,      -1,      null,      null,         null, null
union select  'SoldToCountry',         'Sold To Country',          80,      -1,      null,      null,         null, null
union select  'SoldToEmail',           'Sold To Email ',           80,      -1,      null,      null,         null, null
union select  'SoldToPhoneNo',         'Sold To Phone No',         80,      -1,      null,      null,         null, null
union select  'SoldToAddressReference1',
                                       'Sold To Address Ref1',    100,      -1,      null,      null,         null, null
union select  'SoldToAddressReference2',
                                       'Sold To Address Ref2',    100,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* ShipVias */
union select  'ShipVia',               'Ship Via',                 80,       1,      null,      null,         null, null
union select  'ShipViaSCAC',           'SCAC',                     80,       1,      null,      null,         null, null
union select  'ShipViaDescription',    'Ship Via Desc',           120,      -1,      null,      null,         'Y',  null
union select  'ShipViaDesc',           'Ship Via Desc',           125,      -1,      null,      null,         null, null
union select  'Carrier',               'Carrier',                  80,       1,      null,      null,         null, null
union select  'CarrierServiceCode',    'Service Code',            150,       1,      null,      null,         null, null
union select  'StandardAttributes',    'Attributes',              300,       1,      null,      null,         null, null
union select  'ServiceClass',          'Service Class',            80,      -1,      null,      null,         null, null
union select  'ServiceClassDesc',      'Service Class Desc',      100,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* SKU */
union select  'SKUId',                 'SKU Id',                   60,      -2,      null,      null,         null, null
union select  'SKU',                   'SKU',                      80,       1,      null,      null,         null, null
union select  'SKU1',                  'SKU1',                     70,      -1,      null,      null,         null, null
union select  'SKU2',                  'SKU2',                     70,      -1,      null,      null,         null, null
union select  'SKU3',                  'SKU3',                     55,      -1,  'Center',      null,         null, null
union select  'SKU4',                  'SKU4',                     55,      -1,  'Center',      null,         null, null
union select  'SKU5',                  'SKU5',                     55,      -1,  'Center',      null,         null, null

union select  'SKUDesc',               'SKU Description',         150,       1,      null,      null,         null, null
union select  'SKUDescription',        'SKU Description',         140,       1,      null,      null,         null, null

union select  'DisplaySKU',            'SKU',                      80,      -2,      null,      null,         null, null
union select  'DisplaySKUDesc',        'SKU Description',         150,      -2,      null,      null,         null, null
union select  'SKU1Description',       'SKU1 Desc.',               85,      -2,      null,      null,         null, null
union select  'SKU2Description',       'SKU2 Desc.',               85,      -2,      null,      null,         null, null
union select  'SKU3Description',       'SKU3 Desc.',               85,      -2,      null,      null,         null, null
union select  'SKU4Description',       'SKU4 Desc.',               85,      -2,      null,      null,         null, null
union select  'SKU5Description',       'SKU5 Desc.',               85,      -2,      null,      null,         null, null

union select  'SKUStatus',             'Status',                   85,      -2,      null,      null,          'Y', null
union select  'SKUStatusDesc',         'Status',                   85,       1,      null,      null,          'N', null

union select  'SKU1Desc',              'SKU1 Desc.',               85,      -2,      null,      null,         null, null
union select  'SKU2Desc',              'SKU2 Desc.',               85,      -2,      null,      null,         null, null
union select  'SKU3Desc',              'SKU3 Desc.',               85,      -2,      null,      null,         null, null
union select  'SKU4Desc',              'SKU4 Desc.',               85,      -2,      null,      null,         null, null
union select  'SKU5Desc',              'SKU5 Desc.',               85,      -2,      null,      null,         null, null

union select  'UPC',                   'UPC',                      95,      -1,      null,      null,         null, null
union select  'CaseUPC',               'Case UPC',                 95,      -1,      null,      null,         null, null
union select  'AlternateSKU',          'Alternate SKU',            95,      -1,      null,      null,         null, null
union select  'SKUImageURL',           'SKU Image URL',            95,      -1,      null,      null,         null, null
union select  'Barcode',               'Barcode',                  55,      -1,      null,      null,         null, null
union select  'UoM',                   'UoM',                      60,      -1,      null,      null,         null, null
union select  'InventoryUoM',          'Inventory UoM',            95,      -1,      null,      null,         null, null

union select  'UnitWeight',            'Unit Weight',              80,      -1,      null,      null,         null, '{0:n4}'
union select  'UnitLength',            'Unit Length',              75,      -1,      null,      null,         null, '{0:n4}'
union select  'UnitWidth',             'Unit Width',               80,      -1,      null,      null,         null, '{0:n4}'
union select  'UnitHeight',            'Unit Height',              80,      -1,      null,      null,         null, '{0:n4}'
union select  'UnitVolume',            'Unit Volume',              80,      -1,      null,      null,         null, '{0:n4}'

union select  'VolumeStdUoM',          'cubic inches',             50,      -1,      null,      null,         null, '{0:n2}'
union select  'VolumeStdUoMShort',     'cu. in.',                  50,      -1,      null,      null,         null, '{0:n2}'
union select  'DimensionStdUoM',       'inches',                   50,      -1,      null,      null,         null, '{0:n2}'
union select  'WeightStdUoM',          'lbs',                      50,      -1,      null,      null,         null, '{0:n2}'

union select  'InnerPackWeight',       'Case Weight',              80,      -1,      null,      null,         null, '{0:n4}'
union select  'InnerPackLength',       'Case Length',              70,      -1,      null,      null,         null, '{0:n4}'
union select  'InnerPackWidth',        'Case Width',               70,      -1,      null,      null,         null, '{0:n4}'
union select  'InnerPackHeight',       'Case Height',              70,      -1,      null,      null,         null, '{0:n4}'
union select  'InnerPackVolume',       'Case Volume',              80,      -1,      null,      null,         null, '{0:n4}'

union select  'PalletTie',             'Pallet Tie',               70,      -1,      null,      null,         null, '{0:.}'
union select  'PalletHigh',            'Pallet High',              70,      -1,      null,      null,         null, '{0:.}'

union select  'UnitPrice',             'Unit Price',               60,      -2,      null,      null,          'Y', '{0:c2}'
union select  'UnitCost',              'Unit Cost',                60,      -2,      null,      null,          'Y', '{0:c2}'

union select  'PickUoM',               'Pick Method',              80,      -2,      null,      null,         null, null
union select  'ShipUoM',               'Ship Method',              80,      -2,      null,      null,         null, null
union select  'ShipPack',              'Ship Pack',                50,      -1,      null,      null,         null, '{0:.}'

union select  'IsSortable',            'Is Sortable',              75,      -1,      null,      null,         null, null
union select  'IsConveyable',          'Is Conveyable',            80,      -1,      null,      null,         null, null
union select  'IsScannable',           'Is Scannable',             75,      -1,      null,      null,         null, null
union select  'IsBaggable',            'Is Baggable',              75,      -1,      null,      null,         null, null

union select  'InnerPacksPerLPN',      'Cases/LPN',                70,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsPerInnerPack',     'Units/Case',               80,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'UnitsPerLPN',           'Units/LPN',                70,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'SKUABCClass',           'SKU ABC Class',            60,      -1,      null,      null,         null, null
union select  'ABCClass',              'ABC Class',                65,      -1,      null,      null,         null, null
union select  'ReplenishClass',        'Replenish Class',         100,      -1,      null,      null,         null, null
union select  'Brand',                 'Brand',                    60,      -1,      null,      null,         null, null
union select  'ProdCategory',          'Prod Category',           110,      -2,      null,      null,          'Y', null
union select  'ProdCategoryDesc',      'Prod Category',           120,       1,      null,      null,          'N', null
union select  'ProdSubCategory',       'Prod Subcategory',        110,      -2,      null,      null,          'Y', null
union select  'ProdSubCategoryDesc',   'Prod Subcategory',        140,       1,      null,      null,          'N', null
union select  'PutawayClass',          'Putaway Class',           110,      -2,      null,      null,          'Y', null
union select  'PutawayClassDesc',      'Putaway Class',           110,      -1,      null,      null,          'N', null
union select  'PutawayClassDisplayDesc',
                                       'PA Class Desc',           110,      -2,      null,      null,         null, null

union select  'DefaultCoO',            'Default CoO',              60,      -1,  'Center',      null,         null, null
union select  'Serialized',            'Serialized',               60,      -1,      null,      null,         null, null
union select  'SKUmageURL',            'Image URL',                90,      -1,      null,      null,         null, null
union select  'NMFC',                  'NMFC',                     75,      -1,      null,      null,         null, null
union select  'HarmonizedCode',        'Harmonized Code',         100,      -1,      null,      null,         null, null
union select  'NestingFactor',         'Nesting Factor',          100,      -1,      null,      null,         null, null

union select  'SKU_UDF1',              'SKU_UDF1',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF2',              'SKU_UDF2',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF3',              'SKU_UDF3',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF4',              'SKU_UDF4',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF5',              'SKU_UDF5',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF6',              'SKU_UDF6',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF7',              'SKU_UDF7',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF8',              'SKU_UDF8',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF9',              'SKU_UDF9',                 30,      -2,      null,      null,         null, null
union select  'SKU_UDF10',             'SKU_UDF10',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF11',             'SKU_UDF11',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF12',             'SKU_UDF12',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF13',             'SKU_UDF13',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF14',             'SKU_UDF14',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF15',             'SKU_UDF15',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF16',             'SKU_UDF16',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF17',             'SKU_UDF17',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF18',             'SKU_UDF18',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF19',             'SKU_UDF19',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF20',             'SKU_UDF20',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF21',             'SKU_UDF21',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF22',             'SKU_UDF22',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF23',             'SKU_UDF23',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF24',             'SKU_UDF24',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF25',             'SKU_UDF25',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF26',             'SKU_UDF26',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF27',             'SKU_UDF27',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF28',             'SKU_UDF28',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF29',             'SKU_UDF29',                30,      -2,      null,      null,         null, null
union select  'SKU_UDF30',             'SKU_UDF30',                30,      -2,      null,      null,         null, null

union select  'vwSKU_UDF1',            'vwSKU_UDF1',               30,      -2,      null,      null,         null, null
union select  'vwSKU_UDF2',            'vwSKU_UDF2',               30,      -2,      null,      null,         null, null
union select  'vwSKU_UDF3',            'vwSKU_UDF3',               30,      -2,      null,      null,         null, null
union select  'vwSKU_UDF4',            'vwSKU_UDF4',               30,      -2,      null,      null,         null, null
union select  'vwSKU_UDF5',            'vwSKU_UDF5',               30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* SKU Attributes */
union select  'SKUAttributeId',        'SKUAttributeId',           80,      -1,      null,      null,         null, null
union select  'AttributeType',         'Type',                     80,       1,      null,      null,         null, null
union select  'AttributeValue',        'Data',                    200,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* SKU PrePacks */
union select  'SKUPrePackId',          'SKUPrePackId',             50,      -2,      null,      null,         null, null

union select  'MasterSKUId',           'Master SKUId',            110,      -2,      null,      null,         null, null
union select  'MasterSKU',             'Master SKU',              120,       1,      null,      null,         null, null
--Fields using in ImportSKUPrepacks
union select  'MasterSKU1',            'M-SKU1',                   85,      -1,      null,      null,         null, null
union select  'MasterSKU2',            'M-SKU2',                   45,      -1,  'Center',      null,         null, null
union select  'MasterSKU3',            'M-SKU3',                   45,      -1,  'Center',      null,         null, null
union select  'MasterSKU4',            'M-SKU4',                   60,      -1,      null,      null,         null, null
union select  'MasterSKU5',            'M-SKU5',                   60,      -1,      null,      null,         null, null
--Fields using in vwSKUPrepacks -MS: View has to be corrected later to use Above Fields
union select  'MSKU1',                 'M-SKU1',                   85,      -1,      null,      null,         null, null
union select  'MSKU2',                 'M-SKU2',                   45,      -1,  'Center',      null,         null, null
union select  'MSKU3',                 'M-SKU3',                   45,      -1,  'Center',      null,         null, null
union select  'MSKU4',                 'M-SKU4',                   60,      -1,      null,      null,         null, null
union select  'MSKU5',                 'M-SKU5',                   60,      -1,      null,      null,         null, null
union select  'MasterSKUDescription',  'M-SKU Description',       120,      -1,      null,      null,         null, null

union select  'ComponentSKUId',        'Component SKUId',         110,      -2,      null,      null,         null, null
union select  'ComponentSKU',          'Component SKU',           120,       1,      null,      null,         null, null

union select  'ComponentSKU1',         'C-SKU1',                   85,      -1,      null,      null,         null, null
union select  'ComponentSKU2',         'C-SKU2',                   45,      -1,  'Center',      null,         null, null
union select  'ComponentSKU3',         'C-SKU3',                   45,      -1,  'Center',      null,         null, null
union select  'ComponentSKU4',         'C-SKU4',                   60,      -1,      null,      null,         null, null
union select  'ComponentSKU5',         'C-SKU5',                   60,      -1,      null,      null,         null, null

union select  'CSKU1',                 'C-SKU1',                   85,      -1,      null,      null,         null, null
union select  'CSKU2',                 'C-SKU2',                   45,      -1,  'Center',      null,         null, null
union select  'CSKU3',                 'C-SKU3',                   45,      -1,  'Center',      null,         null, null
union select  'CSKU4',                 'C-SKU4',                   60,      -1,      null,      null,         null, null
union select  'CSKU5',                 'C-SKU5',                   60,      -1,      null,      null,         null, null
union select  'ComponentSKUDescription',
                                       'Comp. Description',       120,      -1,      null,      null,         null, null
union select  'ComponentQty',          'Quantity',                 70,       1,      null,      null,         null,'{0:###,###,###}'

union select  'SPP_UDF1',              'SPP_UDF1',                 30,      -2,      null,      null,         null, null
union select  'SPP_UDF2',              'SPP_UDF2',                 30,      -2,      null,      null,         null, null
union select  'SPP_UDF3',              'SPP_UDF3',                 30,      -2,      null,      null,         null, null
union select  'SPP_UDF4',              'SPP_UDF4',                 30,      -2,      null,      null,         null, null
union select  'SPP_UDF5',              'SPP_UDF5',                 30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* SKU Velocity */
union select  'InventoryKey',          'Inventory Key',            30,      -1,      null,      null,         null, null
union select  'VelocityType',          'Velocity Type',            30,      -1,      null,      null,         null, null

union select  'SVCategory1',           'SVCategory1',             100,      -1,      null,      null,         null, null
union select  'SVCategory2',           'SVCategory2',             100,      -1,      null,      null,         null, null
union select  'SVCategory3',           'SVCategory3',             100,      -1,      null,      null,         null, null
union select  'SVCategory4',           'SVCategory4',             100,      -1,      null,      null,         null, null
union select  'SVCategory5',           'SVCategory5',             100,      -1,      null,      null,         null, null

union select  'SV_UDF1',               'SV_UDF1',                  70,      -1,      null,      null,         null, null
union select  'SV_UDF2',               'SV_UDF2',                  70,      -1,      null,      null,         null, null
union select  'SV_UDF3',               'SV_UDF3',                  70,      -1,      null,      null,         null, null
union select  'SV_UDF4',               'SV_UDF4',                  70,      -1,      null,      null,         null, null
union select  'SV_UDF5',               'SV_UDF5',                  70,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Sorter */
union select  'ExportedStatus',        'Exported Status',         100,       1,      null,        50,         null, null
union select  'ExportedDate',          'Exported Date',           150,      -1,      null,        15,         null, null
union select  'SorterName',            'Sorter Name',             100,       1,      null,        50,         null, null
union select  'OrderWaveId',           'Wave',                    150,       1,      null,        50,         null, null
union select  'DownloadTime',          'DownloadTime',            150,       1,      null,        50,         null, null
union select  'LPNNumLines',           'LPN NumLines',            150,       1,      null,      null,         null, null
union select  'AllocatedQty',          'Allocated Qty',           150,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Tasks */
union select  'TaskId',                'Task Id',                  85,       1,      null,      null,         null, null
union select  'TaskDesc',              'Row',                      60,      -1,      null,      null,         null, null
union select  'TaskType',              'Task Type',                75,      -2,      null,      null,          'Y', null
union select  'TaskTypeDescription',   'Task Type',                80,       1,      null,      null,          'N', null
union select  'TaskSubType',           'Pick Type',                85,      -2,      null,      null,          'Y', null
union select  'TaskSubTypeDescription','Pick Type',                85,       1,      null,      null,          'Y', null
union select  'TaskSubTypeDesc',       'Pick Type',                85,       1,      null,      null,          'Y', null

union select  'PickTaskSubType',       'Pick Type',                85,      -2,      null,      null,          'Y', null
union select  'PickTaskSubTypeDesc',   'Pick Type',                85,       1,      null,      null,          'N', null
union select  'PickType, ',            'Pick Type',                85,      -1,      null,      null,         null, null
union select  'TaskStatus',            'Task Status',              90,      -2,      null,      null,          'Y', null
union select  'TaskStatusDesc',        'Task Status',             110,       1,      null,      null,          'N', null
union select  'TaskStatusGroup',       'Task Status Group',       115,      -1,      null,      null,         null, null

union select  'IsTaskAllocated',       'Is Task Allocated',       130,      -1,      null,      null,         null, null
union select  'IsTaskConfirmed',       'Confirmed?',               65,       1,  'Center',      null,         null, null
union select  'DependencyFlags',       'Dependency',               75,       1,  'Center',      null,         null, null
union select  'DependentOn',           'Dependent On',            100,       1,      null,      null,         null, null
union select  'OrderCount',            '# Orders',                 65,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumTasks',              '# Tasks',                  60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumPicks',              '# Picks',                  60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumPicksCompleted',     '# Completed',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'PercentPicksComplete',  '% Completed',              90,       1,      null,      null,         null, null

union select  'StopTime',              'Stop Time',               140,       1,      null,      null,         null, null
union select  'ElapsedMins',           'ElapsedMins',              75,       1,      null,      null,         null, null
union select  'CompletedDate',         'Completed Date',           95,       1,      null,      null,         null, null
union select  'PrintedDateTime',       'Printed Date Time',       140,      -1,      null,      null,         null, null
union select  'PrintDate',             'Print Date',               80,      -1,      null,      null,         null, null

union select  'DetailDependencyFlags', 'TD Dependency',            75,       1,  'Center',      null,         null, null
union select  'DetailDestLocation',    'TD Dest Location',        100,       1,      null,      null,         null, null
union select  'DetailDestZone',        'TD Dest Zone',             85,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* TaskDependencies */
union select  'Task',                   'Task',                    60,       1,      null,      null,         null, null
union select  'ReplenishTask',          'Replenish Task',          90,       1,      null,      null,         null, null
union select  'ReplenishLPN',           'Replenish LPN',           85,       1,      null,      null,         null, null
union select  'ReplenishLPNQty',        'Replenish LPN Qty',      105,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ReplenishLPNStatus',     'Replenish LPN Status',   120,       1,      null,      null,         null, null
union select  'ReplenishLPNLocation',   'Replenish LPN Location', 120,       1,      null,      null,         null, null
union select  'PickBin',                'Pick Bin',                80,       1,      null,      null,         null, null
union select  'PickBinQty' ,            'Pick Bin Qty',            80,       1,      null,      null,         null, '{0:###,###,###}'

/*----------------------------------------------------------------------------*/
/* Replenishment Frequency Report */
union select  'ReplenishTimes',         'Replenish Times',         95,       1,      null,      null,         null, null
union select  'Days',                   'Days',                    50,       1,      null,      null,         null, null
union select  'UnitsReplenished',       'Units Replenished',      115,       1,      null,      null,         null, null
union select  'StartDate',              'Start Date',              85,       1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'EndDate',                'End Date',                85,       1,      null,      null,         null, '{0:MM/dd/yyyy}'
union select  'AvgUnitsPerInstance',    'Avg. Units Per Instance',135,       1,      null,      null,         null, null
union select  'AvgUnitsPerDay',         'Avg. Units Per Day',     115,       1,      null,      null,         null, null
union select  'OutStandingUnits',       'Outstanding Units',      115,       1,      null,      null,         null, null
union select  'MinWaveNo',              'Min. Wave No',            85,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Location ReplenishLevels */
/* SV_Prev*_Velocity - Units Shipped for the SKU (based on the sales-orders - Picks from all locations).*/

union select  'SV_PrevWeek',            '# Shipped Prev Week',      100,    -1,      null,      null,         null, null
union select  'SV_Prev2Week',           '# Shipped Prev 2 Weeks',   100,    -1,      null,      null,         null, null
union select  'SV_PrevMonth',           '# Shipped Prev Month',     100,    -1,      null,      null,         null, null
union select  'SV_Prev2Month',          '# Shipped Prev 2 Months',  100,    -1,      null,      null,         null, null
union select  'SV_PrevQuarter',         '# Shipped Prev Quarter',   100,    -1,      null,      null,         null, null
union select  'SV_Prev2Quarter',        '# Shipped Prev 2 Quarters',100,    -1,      null,      null,         null, null

/* PV_Prev*_Velocity - Units Picked from the current location */
union select  'PV_PrevWeek',            '# Picked Prev Week',       100,    -1,      null,      null,         null, null
union select  'PV_Prev2Week',           '# Picked Prev 2 Weeks',    100,    -1,      null,      null,         null, null
union select  'PV_PrevMonth',           '# Picked Prev Month',      100,    -1,      null,      null,         null, null
union select  'PV_Prev2Month',          '# Picked Prev 2 Months',   100,    -1,      null,      null,         null, null
union select  'PV_PrevQuarter',         '# Picked Prev Quarter',    100,    -1,      null,      null,         null, null
union select  'PV_Prev2Quarter',        '# Picked Prev 2 Quarters', 100,    -1,      null,      null,         null, null

union select  'LOCRL_UDF1',              'LOCRL_UDF1',             70,      -2,      null,      null,         null, null
union select  'LOCRL_UDF2',              'LOCRL_UDF2',             70,      -2,      null,      null,         null, null
union select  'LOCRL_UDF3',              'LOCRL_UDF3',             70,      -2,      null,      null,         null, null
union select  'LOCRL_UDF4',              'LOCRL_UDF4',             70,      -2,      null,      null,         null, null
union select  'LOCRL_UDF5',              'LOCRL_UDF5',             70,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* In-Transit Shipment Summary Report */
union select  '1',                      '1',                       40,       1,      null,      null,         null, null
union select  '2',                      '2',                       40,       1,      null,      null,         null, null
union select  '3',                      '3',                       40,       1,      null,      null,         null, null
union select  '4',                      '4',                       40,       1,      null,      null,         null, null
union select  '5',                      '5',                       40,       1,      null,      null,         null, null
union select  '6',                      '6',                       40,       1,      null,      null,         null, null
union select  '7',                      '7',                       40,       1,      null,      null,         null, null
union select  '8',                      '8',                       40,       1,      null,      null,         null, null
union select  'XS',                     'XS',                      40,       1,      null,      null,         null, null
union select  'S',                      'S',                       40,       1,      null,      null,         null, null
union select  'M',                      'M',                       40,       1,      null,      null,         null, null
union select  'L',                      'L',                       40,       1,      null,      null,         null, null
union select  'XL',                     'XL',                      40,       1,      null,      null,         null, null
union select  'XXL',                    'XXL',                     40,       1,      null,      null,         null, null
union select  'Mixed',                  'Mixed',                   50,       1,      null,      null,         null, null
union select  'GrandTotal',             'Grand Total',             90,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* TaskDetails */
union select  'TaskDetailId',           'Task Detail Id',          90,      -2,      null,      null,         null, null
union select  'TaskDetailStatus',       'Pick Status',             90,      -2,      null,      null,          'Y', null
union select  'TaskDetailStatusDesc',   'Pick Status',             85,       1,      null,      null,          'N', null
union select  'TaskDetailStatusGroup',  'Pick Status Group',      115,       1,      null,      null,         null, null
union select  'DetailPercentComplete',  'Detail Percent Complete',160,       1,      null,      null,         null, null
union select  'LPNInnerPacks',          'LPN Cases',               70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'TDInnerPacks',           'Cases',                   60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'TDQuantity',             'Units',                   60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'TDInnerPacksCompleted',  'Cases Picked',            75,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'TDUnitsCompleted',       'Units Picked',            75,       1,      null,      null,         null, '{0:###,###,###}'
union select  'TempLabel',              'Temp Label',              80,      -1,      null,      null,         null, null
union select  'TempLabelId',            'Temp Label Id',           80,      -1,      null,      null,         null, null
union select  'PickPosition',           'Pick Position',           85,       1,      null,      null,         null, null

union select  'TDCategory1',            'TD Category1',            85,      -1,      null,      null,         null, null
union select  'TDCategory2',            'TD Category2',            85,      -1,      null,      null,         null, null
union select  'TDCategory3',            'TD Category3',            85,      -1,      null,      null,         null, null
union select  'TDCategory4',            'TD Category4',            85,      -1,      null,      null,         null, null
union select  'TDCategory5',            'TD Category5',            85,      -1,      null,      null,         null, null

union select  'TDMergeCriteria1',       'TDMergeCriteria1',        85,      -1,      null,      null,         null, null
union select  'TDMergeCriteria2',       'TDMergeCriteria2',        85,      -1,      null,      null,         null, null
union select  'TDMergeCriteria3',       'TDMergeCriteria3',        85,      -1,      null,      null,         null, null
union select  'TDMergeCriteria4',       'TDMergeCriteria4',        85,      -1,      null,      null,         null, null
union select  'TDMergeCriteria5',       'TDMergeCriteria5',        85,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* LPNTasks */
union select  'vwLPNTask_UDF1',         'vwLPNTask_UDF1',          70,      -2,      null,      null,         null, null
union select  'vwLPNTask_UDF2',         'vwLPNTask_UDF2',          70,      -2,      null,      null,         null, null
union select  'vwLPNTask_UDF3',         'vwLPNTask_UDF3',          70,      -2,      null,      null,         null, null
union select  'vwLPNTask_UDF4',         'vwLPNTask_UDF4',          70,      -2,      null,      null,         null, null
union select  'vwLPNTask_UDF5',         'vwLPNTask_UDF5',          70,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Users, Roles & Permissions */
union select  'UserId',                 'User Id',                80,        1,      null,      null,         null, null
--Removing the above field in WMS, will cause issue with missing UserId in AuditTrail Layout
union select  'UserName',               'User Name',              100,       1,      null,        50,         null, null
union select  'Password',               'Password',               100,      -1,      null,        15,          'N', null
union select  'FirstName',              'First Name',             100,       1,      null,        50,         null, null
union select  'LastName',               'Last Name',              100,       1,      null,        50,         null, null
union select  'Email',                  'Email',                  150,       1,      null,        50,         null, null
union select  'UIDefaultPage',          'Default Page',           150,      -2,      null,      null,         null, null
union select  'LastLoggedIn',           'Last Logged In',         150,       1,      null,      null,         null, null
union select  'UserStatus',             'Status',                  90,      -2,      null,      null,         null, null
union select  'DefaultWarehouse',       'Default WH',              70,      -2,      null,      null,         null, null
union select  'DefaultWarehouseDesc',   'Default WH',              70,       1,      null,      null,         null, null

union select  'PasswordPolicy',         'Password Policy',         90,      -1,      null,      null,         null, null
union select  'InvalidPasswordAttempts','# Password Failures',     50,      -1,      null,      null,         null, null
union select  'IsLocked',               'Is Locked',               50,      -1,  'Center',      null,         null, null
union select  'LockedTime',             'Locked Time',            120,      -1,      null,      null,         null, null
union select  'PasswordExpiryDate',     'Password Expiry Date',   150,      -1,      null,      null,         null, null

union select  'UserRoleId',             'User Role Id',           150,      -1,      null,      null,         null, null
union select  'RoleId',                 'Role Id',                 50,      -2,      null,      null,          'Y', null
union select  'RoleName',               'Role',                   120,      -2,      null,      null,         null, null
union select  'RoleDescription',        'Role',                   120,       1,      null,      null,         null, null

union select  'PermissionId',           'Permission Id',           50,      -2,      null,      null,         null, null
union select  'PermissionName',         'Permission',             120,      -2,      null,      null,         null, null
union select  'PermissionDesc',         'Permission',             120,       1,      null,      null,         null, null

union select  'Application',            'Application',            100,      -1,      null,      null,         null, null
union select  'OperationDescription',   'Operation',               80,       1,      null,      null,         null, null
union select  'NodeLevel',              'Node Level',              80,      -2,      null,      null,         null, null
union select  'RolePermissionKey',      'Role Permission Key',     50,      -2,      null,      null,         null, null
union select  'RolePermissionId',       'Role Permission Id',      50,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* WCS (SDI) - Router & Sorter tables */
union select  'RecId',                  'Rec Id',                  60,       1,      null,      null,         null, null
union select  'CIMSRecId',              'CIMS RecId',             110,      -1,      null,      null,         null, null
union select  'ExternalRecId',          'External RecId',         110,       1,      null,      null,         null, null
union select  'CartonId',               'Carton Id',               95,       1,      null,      null,         null, null
union select  'SorterId',               'Sorter Id',              120,       1,      null,      null,         null, null
union select  'WorkId',                 'Work Id',                 60,       1,      null,      null,         null, null

union select  'PackSize',               'PackSize',                75,       1,      null,      null,         null, null
union select  'ProcessedStatus',        'Processed Status',       110,       1,      null,      null,         null, null
union select  'ProcessedDate',          'Processed Date',         100,       1,      null,      null,         null, null
union select  'WaveNumber',             'Wave',                   150,       1,      null,      null,         null, null

union select  'LPNsCreated',            'LPNs Created',            95,       1,      null,      null,         null, null
union select  'ShipLabeled',            'Ship Labeled',            95,       1,      null,      null,         null, null
union select  'Routed',                 'Routed',                  65,       1,      null,      null,         null, null
union select  'Destination',            'Destination',             95,       1,      null,      null,         null, null
union select  'ExportedOn',             'Exported On',             95,       1,      null,      null,         null, null
union select  'ProcessedOn',            'Processed On',            95,       1,      null,      null,         null, null
union select  'RouteLPN',               'Route LPN',               95,       1,      null,      null,         null, null
union select  'iLPN',                   'iLPN',                   100,       1,      null,      null,         null, null
union select  'oLPN',                   'oLPN',                   100,       1,      null,      null,         null, null

union select  'ErrorReason',            'Error Reason',            95,       1,      null,      null,         null, null
union select  'LastCartonFlag',         'LastCartonFlag',         120,       1,      null,      null,         null, null
union select  'Done',                   'Done',                    60,       1,      null,      null,         null, null
union select  'HostExportStatus',       'HostExportStatus',       110,       1,      null,      null,         null, null
union select  'Verified',               'Verified',                80,       1,      null,      null,         null, null

union select  'ContainerQty',           'Container Qty',           95,       1,      null,      null,         null, null
union select  'QtyRemaining',           'Qty Remaining',          110,       1,      null,      null,         null, null
union select  'AllocatedQuantity',      'Allocated Quantity',     120,       1,      null,      null,         null, '{0:###,###,###}'
union select  'DistributedQuantity',    'Distributed Quantity',   130,       1,      null,      null,         null, '{0:###,###,###}'

union select  'DivertDateTime',         'Divert DateTime',        120,       1,      null,      null,         null, null
union select  'DivertDate',             'Divert Date',             95,      -1,      null,      null,         null, null
union select  'DivertTime',             'Divert Time',             95,      -1,      null,      null,         null, null
union select  'CreationTime',           'Creation Time',          110,       1,      null,      null,         null, null
union select  'UploadTime',             'Upload Time',            110,       1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* General/Misc. fields */
union select  'NumBatches',             '# Waves',                 60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumOrders',              '# Orders',                55,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumPallets',             '# Pallets',               60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumLPNs',                '# LPNs',                  65,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumPackages',            '# Pkgs',                  60,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumInnerpacks',          '# Cases',                 60,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'NumUnits',               '# Units',                 65,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumCases',               'Num Cases',               90,      -2,      null,      null,         null, null
union select  'NumSKUs',                '# SKUs',                  65,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'NumLocations',           '# Locations',             65,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumLines',               '# Lines',                 65,      -1,      null,      null,         null, '{0:###,###,###}'
union select  'NumLabels',              '# Labels',                65,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumReports',             '# Reports',               65,       1,      null,      null,         null, '{0:###,###,###}'
union select  'NumCartons',             '# ShipCarton',            65,      -1,      null,      null,         null, '{0:###,###,###}'

union select  'Count1',                 '# Orders',                55,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'Count2',                 '# Cartons',               65,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'Count3',                 '# Reports',               65,      -2,      null,      null,         null, '{0:###,###,###}'

union select  'RunningCount1',          '# Labels',                55,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'RunningCount2',          '# RC2',                   65,      -2,      null,      null,         null, '{0:###,###,###}'
union select  'RunningCount3',          '# RC3',                   65,      -2,      null,      null,         null, '{0:###,###,###}'

union select  'Volume',                 'Vol (cuft)',              70,      -1,      null,      null,         null, '{0:.}'
union select  'Weight',                 'Wgt (lbs)',               70,      -1,      null,      null,         null, '{0:.}'
union select  'TotalVolume',            'Total Vol.',              80,      -1,      null,      null,         null, '{0:n2}'
union select  'MaxUnitsPerCarton',      'Max Units/Carton',        80,      -1,      null,      null,         null, null
union select  'TotalWeight',            'Total Wgt.',              80,      -1,      null,      null,         null, '{0:n2}'

union select  'IsActive',               'Active',                  40,       1,      null,      null,         null, null
union select  'IsVisible',              'Visible',                 40,      -2,      null,      null,         null, null
union select  'IsAllowed',              'Allowed',                 40,      -2,      null,      null,         null, null
union select  'IsAllowedBitValue',      'Allowed',                 40,       1,      null,      null,         null, null
union select  'Status',                 'Status',                  80,      -3,  'Center',      null,          'Y', null
/* many views now have two status descriptions i.e LPNStatusDec and StatusDescription, so making this hidden */
union select  'StatusCode',             'Status',                  85,      -2,      null,      null,          'N', null
union select  'StatusDescription',      'Status',                  85,      -2,      null,      null,          'N', null
union select  'StatusGroup',            'Status Group',            95,       1,      null,      null,         null, null
union select  'StatusDesc',             'Status',                  85,      -2,      null,      null,          'N', null
union select  'SortSeq',                'Sort Order',              80,      -1,  'Center',      null,         null, null
union select  'Priority',               'Priority',                50,       1,  'Center',      null,         null, '{0:.}'
union select  'Description',            'Description',            200,      -1,      null,      null,         null, null
union select  'CreatedDate',            'Created Date',           150,      -1,  'Center',      null,         null, null
union select  'ModifiedDate',           'Modified Date',          150,      -1,  'Center',      null,         null, null
union select  'CreatedOn',              'Created On',             120,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'ModifiedOn',             'Modified On',            120,      -1,  'Center',      null,         null, '{0:MM/dd/yyyy}'
union select  'CreatedBy',              'Created By',             100,      -1,      null,      null,         null, null
union select  'ModifiedBy',             'Modified By',            100,      -1,      null,      null,         null, null
union select  'Archived',               'Archived',                65,      -1,      null,      null,         null, null
union select  'BusinessUnit',           'Business Unit',           80,      -2,      null,      null,          'N', null
union select  'BUDescription',          'Business Unit',           80,      -2,      null,      null,          'N', null

union select  'Ownership',              'Owner',                   65,      -2,  'Center',      null,          'Y', null
union select  'OwnershipDesc',          'Owner',                   30,      -1,  'Center',      null,          'N', null
union select  'OwnershipDescription',   'Ownership Description',  170,      -1,      null,      null,         null, null
union select  'Warehouse',              'WH',                      45,      -1,  'Center',      null,          'Y', null
union select  'WarehouseDesc',          'Warehouse',               60,      -1,      null,      null,         null, null
union select  'WarehouseDescription',   'Warehouse',               60,      -1,      null,      null,         null, null

union select  'RecordId',               'Record Id',               70,      -3,      null,      null,         null, null
union select  'RecordType',             'Record Type',             95,       1,      null,      null,         null, null
union select  'HostRecId',              'Host Rec Id',             70,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* PrintJobs */
union select  'LabelStockSizes',        'LabelStock Sizes',       130,      -1,      null,      null,         null, null
union select  'ReportStockSizes',       'ReportStock Sizes',      130,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Return Address */
union select  'ReturnAddress',         'Return Address',          120,      -1,      null,      null,         null, null
union select  'ReturnAddrId',          'Return Addr Id',          120,      -1,      null,      null,         null, null
union select  'ReturnAddressCity',     'Return Addr City',        120,      -1,      null,      null,         null, null
union select  'ReturnAddressState',    'Return Addr State',       120,      -1,      null,      null,         null, null
union select  'ReturnAddressZip',      'Return Addr Zip',         120,      -1,      null,      null,         null, null
union select  'ReturnAddressCountry',  'Return Addr Country',     120,      -1,      null,      null,         null, null
union select  'ReturnAddressEmail',    'Return Addr Email',       120,      -1,      null,      null,         null, null
union select  'ReturnAddressLine1',    'Return Addr Line1',       120,      -1,      null,      null,         null, null
union select  'ReturnAddressLine2',    'Return Addr Line2',       120,      -1,      null,      null,         null, null
union select  'ReturnAddressName',     'Return Addr Name',        120,      -1,      null,      null,         null, null
union select  'ReturnAddressPhoneNo',  'Return Addr PhoneNo',     120,      -1,      null,      null,         null, null
union select  'ReturnAddressReference1',
                                       'Return Addr Reference1',  120,      -1,      null,      null,         null, null
union select  'ReturnAddressReference2',
                                       'Return Addr Reference2',  120,      -1,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Routing Instructions */
union select  'RI_UDF1',                'RI_UDF1',                 30,      -2,      null,      null,         null, null
union select  'RI_UDF2',                'RI_UDF2',                 30,      -2,      null,      null,         null, null
union select  'RI_UDF3',                'RI_UDF3',                 30,      -2,      null,      null,         null, null
union select  'RI_UDF4',                'RI_UDF4',                 30,      -2,      null,      null,         null, null
union select  'RI_UDF5',                'RI_UDF5',                 30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Routing Confirmations */
union select  'RC_UDF1',                'RC_UDF1',                 30,      -2,      null,      null,         null, null
union select  'RC_UDF2',                'RC_UDF2',                 30,      -2,      null,      null,         null, null
union select  'RC_UDF3',                'RC_UDF3',                 30,      -2,      null,      null,         null, null
union select  'RC_UDF4',                'RC_UDF4',                 30,      -2,      null,      null,         null, null
union select  'RC_UDF5',                'RC_UDF5',                 30,      -2,      null,      null,         null, null

union select  'vwRC_UDF1',              'vwRC_UDF1',               30,      -2,      null,      null,         null, null
union select  'vwRC_UDF2',              'vwRC_UDF2',               30,      -2,      null,      null,         null, null
union select  'vwRC_UDF3',              'vwRC_UDF3',               30,      -2,      null,      null,         null, null
union select  'vwRC_UDF4',              'vwRC_UDF4',               30,      -2,      null,      null,         null, null
union select  'vwRC_UDF5',              'vwRC_UDF5',               30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Routing Zones */
union select  'ZoneName',               'Zone Name',              130,       1,      null,      null,         null, null
union select  'ShipToZipStart',         'Start Zip',               70,       1,      null,      null,         null, null
union select  'ShipToZipEnd',           'End Zip',                 70,       1,      null,      null,         null, null
union select  'DeliveryRequirement',    'Delivery Requirement',   130,      -2,      null,      null,         null, null

union select  'RZ_UDF1',                'Type',                    80,      -1,      null,      null,         null, null
union select  'RZ_UDF2',                'RZ_UDF2',                 30,      -2,      null,      null,         null, null
union select  'RZ_UDF3',                'RZ_UDF3',                 30,      -2,      null,      null,         null, null
union select  'RZ_UDF4',                'RZ_UDF4',                 30,      -2,      null,      null,         null, null
union select  'RZ_UDF5',                'RZ_UDF5',                 30,      -2,      null,      null,         null, null

union select  'vwRZ_UDF1',              'vwRZ_UDF1',               30,      -2,      null,      null,         null, null
union select  'vwRZ_UDF2',              'vwRZ_UDF2',               30,      -2,      null,      null,         null, null
union select  'vwRZ_UDF3',              'vwRZ_UDF3',               30,      -2,      null,      null,         null, null
union select  'vwRZ_UDF4',              'vwRZ_UDF4',               30,      -2,      null,      null,         null, null
union select  'vwRZ_UDF5',              'vwRZ_UDF5',               30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Routing Rules */
union select  'ShipToZone',             'Ship To Zone',            80,       1,      null,      null,         null, null
union select  'InputCarrier',           'Input Carrier',           80,       1,      null,      null,         null, null
union select  'InputShipVia',           'Input ShipVia',           80,       1,      null,      null,         null, null
union select  'InputShipViaDesc',       'Input ShipViaDesc',      125,       1,      null,      null,         null, null
union select  'InputFreightTerms',      'Input Freight Terms',     85,       1,      null,      null,         null, null
union select  'InputFreightTermsDesc',  'InputFreightTerms ',      85,       1,      null,      null,         null, null
union select  'MinWeight',              'MinWeight',               85,       1,      null,      null,         null, null
union select  'Criteria1',              'Criteria1',              125,       1,      null,      null,         null, null
union select  'Criteria2',              'Criteria2',              125,       1,      null,      null,         null, null
union select  'Criteria3',              'Criteria3',              125,       1,      null,      null,         null, null
union select  'Criteria4',              'Criteria4',              125,       1,      null,      null,         null, null
union select  'Criteria5',              'Criteria5',              125,       1,      null,      null,         null, null
union select  'FreightTermsDesc',       'Freight Terms',          125,       1,      null,      null,         null, null
union select  'BillToAccountName',      'Bill To Account',         90,       1,      null,      null,         null, null

union select  'RR_UDF1',                'Rule Type',               80,      -1,      null,      null,         null, null
union select  'RR_UDF2',                'RR_UDF2',                 30,      -1,      null,      null,         null, null
union select  'RR_UDF3',                'RR_UDF3',                 30,      -1,      null,      null,         null, null
union select  'RR_UDF4',                'RR_UDF4',                 30,      -1,      null,      null,         null, null
union select  'RR_UDF5',                'RR_UDF5',                 30,      -1,      null,      null,         null, null

union select  'vwRR_UDF1',              'vwRR_UDF1',               30,      -2,      null,      null,         null, null
union select  'vwRR_UDF2',              'vwRR_UDF2',               30,      -2,      null,      null,         null, null
union select  'vwRR_UDF3',              'vwRR_UDF3',               30,      -2,      null,      null,         null, null
union select  'vwRR_UDF4',              'vwRR_UDF4',               30,      -2,      null,      null,         null, null
union select  'vwRR_UDF5',              'vwRR_UDF5',               30,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Shipping Accounts */
union select  'ShippingAcctName',       'Account Name',           130,       1,      null,      null,         null, null
union select  'ShipperAccountNumber',   'Shipper Account Number', 130,       1,      null,      null,         null, null
union select  'ShipperMeterNumber',     'Shipper Meter Number',   130,       1,      null,      null,         null, null
union select  'ShipperAccessKey',       'Shipper Access Key',     130,       1,      null,      null,         null, null
union select  'MasterAccount',          'MasterAccount',          130,       1,      null,      null,         null, null
union select  'AccountDetails',         'Carrier Account Detail', 200,      -1,      null,      null,         null, null

union select  'SA_UDF1',                'UDF1',                    20,      -2,      null,      null,         null, null
union select  'SA_UDF2',                'UDF2',                    20,      -2,      null,      null,         null, null
union select  'SA_UDF3',                'UDF3',                    20,      -2,      null,      null,         null, null
union select  'SA_UDF4',                'UDF4',                    20,      -2,      null,      null,         null, null
union select  'SA_UDF5',                'UDF5',                    20,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Shipped Counts */
union select  'HourDisplay',            'Hour',                    70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'MonOrders',              'Mon Orders',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'MonOrdersRT',            'Mon RT',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'TueOrders',              'Tue Orders',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'TueOrdersRT',            'Tue RT',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'WedOrders',              'Wed Orders',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'WedOrdersRT',            'Wed RT',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ThuOrders',              'Thu Orders',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'ThuOrdersRT',            'Thu RT',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'FriOrders',              'Fri Orders',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'FriOrdersRT',            'Fri RT',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'SatOrders',              'Sat Orders',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'SatOrdersRT',            'Sat RT',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'SunOrders',              'Sun Orders',              70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'SunOrdersRT',            'Sun RT',                  70,       1,      null,      null,         null, '{0:###,###,###}'
union select  'Hour',                   'Hour',                    30,      -2,      null,      null,         null, null
/*----------------------------------------------------------------------------*/
/* Notifications */

union select  'NotificationType',       'Notification Type',       20,       1,      null,      null,         null, null
union select  'Message',                'Message',                 20,       1,      null,      null,         null, null
union select  'MasterEntityType',       'Master EntityType',       20,      -1,      null,      null,         null, null
union select  'MasterEntityId',         'Master EntityId',         20,      -1,      null,      null,         null, null
union select  'MasterEntityKey',        'Master EntityKey',        20,      -1,      null,      null,         null, null

union select  'NF_UDF1',                'UDF1',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF2',                'UDF2',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF3',                'UDF3',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF4',                'UDF4',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF5',                'UDF5',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF6',                'UDF6',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF7',                'UDF7',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF8',                'UDF8',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF9',                'UDF9',                    20,      -2,      null,      null,         null, null
union select  'NF_UDF10',               'UDF10',                   20,      -2,      null,      null,         null, null

/*----------------------------------------------------------------------------*/
/* Generic UDFs */
union select  'UDF1',                   'UDF1',                    20,      -2,      null,      null,         null, null
union select  'UDF2',                   'UDF2',                    20,      -2,      null,      null,         null, null
union select  'UDF3',                   'UDF3',                    20,      -2,      null,      null,         null, null
union select  'UDF4',                   'UDF4',                    20,      -2,      null,      null,         null, null
union select  'UDF5',                   'UDF5',                    20,      -2,      null,      null,         null, null
union select  'UDF6',                   'UDF6',                    20,      -2,      null,      null,         null, null
union select  'UDF7',                   'UDF7',                    20,      -2,      null,      null,         null, null
union select  'UDF8',                   'UDF8',                    20,      -2,      null,      null,         null, null
union select  'UDF9',                   'UDF9',                    20,      -2,      null,      null,         null, null
union select  'UDF10',                  'UDF10',                   20,      -2,      null,      null,         null, null

union select  'UDF11',                  'UDF11',                   20,      -2,      null,      null,         null, null
union select  'UDF12',                  'UDF12',                   20,      -2,      null,      null,         null, null
union select  'UDF13',                  'UDF13',                   20,      -2,      null,      null,         null, null
union select  'UDF14',                  'UDF14',                   20,      -2,      null,      null,         null, null
union select  'UDF15',                  'UDF15',                   20,      -2,      null,      null,         null, null
union select  'UDF16',                  'UDF16',                   20,      -2,      null,      null,         null, null
union select  'UDF17',                  'UDF17',                   20,      -2,      null,      null,         null, null
union select  'UDF18',                  'UDF18',                   20,      -2,      null,      null,         null, null
union select  'UDF19',                  'UDF19',                   20,      -2,      null,      null,         null, null
union select  'UDF20',                  'UDF20',                   20,      -2,      null,      null,         null, null

union select  'UDF21',                  'UDF21',                   20,      -2,      null,      null,         null, null
union select  'UDF22',                  'UDF22',                   20,      -2,      null,      null,         null, null
union select  'UDF23',                  'UDF23',                   20,      -2,      null,      null,         null, null
union select  'UDF24',                  'UDF24',                   20,      -2,      null,      null,         null, null
union select  'UDF25',                  'UDF25',                   20,      -2,      null,      null,         null, null
union select  'UDF26',                  'UDF26',                   20,      -2,      null,      null,         null, null
union select  'UDF27',                  'UDF27',                   20,      -2,      null,      null,         null, null
union select  'UDF28',                  'UDF28',                   20,      -2,      null,      null,         null, null
union select  'UDF29',                  'UDF29',                   20,      -2,      null,      null,         null, null
union select  'UDF30',                  'UDF30',                   20,      -2,      null,      null,         null, null

/* UDF Desc */
union select  'UDFDesc1',               'UDFDesc1',                20,      -2,      null,      null,         null, null
union select  'UDFDesc2',               'UDFDesc2',                20,      -2,      null,      null,         null, null
union select  'UDFDesc3',               'UDFDesc3',                20,      -2,      null,      null,         null, null
union select  'UDFDesc4',               'UDFDesc4',                20,      -2,      null,      null,         null, null
union select  'UDFDesc5',               'UDFDesc5',                20,      -2,      null,      null,         null, null

/* Identify Duplicates */
--select FieldName, count(*) from @ttfields group by FieldName having count(*) > 1;

/* Add the fields for all Business units.
   Option I  - Insert the above entries for all BUs and after deleting existing ones.
   Option AU - Add and/or Update i.e. Add ones that do not exist and update the ones that exist.
               If you are applying only few fields, use this option
   Option 3  - Update only V3 related attributes. */

/* Evaluate and update the Fields based on System Version, if we have ControlVar as 'V3' we have to use action 'I'
   if it is V2toV3 upgrade we have to use 'A3' */
select top 1 @vBusinessUnit = BusinessUnit
from vwBusinessUnits;

select @vSystemVersion = dbo.fn_Controls_GetAsString('System', 'Version', '$' /* Application Version */, @vBusinessUnit, null);

if (@vSystemVersion = 'V3')
  exec pr_Setup_Fields @ttFields, 'AU' /* Options - Insert/Initial Setup */, null /* Business Unit */, 'cimsdba' /* UserId */;
else
  exec pr_Setup_Fields @ttFields, 'A3' /* Options - Add/Update only V3 related attributes */, null /* Business Unit */, 'cimsdba' /* UserId */;

Go
