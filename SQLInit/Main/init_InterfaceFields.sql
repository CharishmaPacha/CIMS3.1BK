/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/16  AY      Walmart added new field in their Routing Info (HA Golive)
  2021/03/04  VS      LoadRoutingInfo changed to LRI (HA-2122)
  2021/02/20  TK      Generalized field names for LoadRoutingInfo, LRI_WM & LRI_TAR (HA-1962)
  2021/01/27  RKC     Added Fields for INV (CIMSV3-1323)
  2021/01/25  RKC     Made changes to create DataSetname for respective Import file type Layouts (HA-1951)
  2021/01/22  RKC     Added Fields for LRI_TAR (HA-1946)
  2021/01/20  AY/RKC  Included Load Routing info (HA-1926)
  2020/11/14  SV      Changes to Location imports from UI (CIMSV3-1120)
  2020/01/21  MS      Added SKUPriceList Dataset (CID-1117)
  2018/04/24  RV      Initial revision (S2G-233)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Router Confirmations */
/*------------------------------------------------------------------------------*/
declare @vProcessName TName,
        @vDataSetName TName;

select @vProcessName = 'Import',
       @vDataSetName = 'RouterConfirmations';

delete from InterfaceFields where DataSetName = @vDataSetName and ProcessName = @vProcessName;

insert into InterfaceFields
             (ProcessName,   DataSetName,   FieldName,        ExternalFieldName, FieldType, FieldWidth, Justification, PadChar, SortSeq, Status, versionId, BusinessUnit)
      select  @vProcessName, @vDataSetName, 'LPN',            'LPN',             'string',  '20',       'left',        ' ',     '1',     'A',    '1',       BusinessUnit from vwBusinessUnits
union select  @vProcessName, @vDataSetName, 'ActualWeight',   'ActualWeight',    'integer', '9',        'left',        ' ',     '2',     'A',    '1',       BusinessUnit from vwBusinessUnits
union select  @vProcessName, @vDataSetName, 'Destination',    'Destination',     'string',  '3',        'left',        ' ',     '3',     'A',    '1',       BusinessUnit from vwBusinessUnits
union select  @vProcessName, @vDataSetName, 'DivertDateTime', 'DivertDateTime',  'string',  '14',       'left',        ' ',     '4',     'A',    '1',       BusinessUnit from vwBusinessUnits

/* Create the Data set name to the layout for respective Import file type */
exec pr_Setup_CreateInterfaceDataSet @vProcessName, @vDataSetName;

/*------------------------------------------------------------------------------*/
/* ImportFile: SKUPriceList */
/*------------------------------------------------------------------------------*/

select @vProcessName = 'ImportFile',
       @vDataSetName = 'SKUPriceList';

delete from InterfaceFields where DataSetName = @vDataSetName and ProcessName = @vProcessName;

insert into InterfaceFields
             (FieldName,         ExternalFieldName, FieldType, FieldWidth, Justification, PadChar, SortSeq, Status, versionId, ProcessName,   DataSetName,   BusinessUnit)
      select  'SKU',             'SKU',             'TSKU',    null,       null,          ' ',     '1',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'SoldToId',        'SoldToId',        'TVarchar',null,       null,          ' ',     '2',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CustSKU',         'CustSKU',         'TCustSKU',null,       null,          ' ',     '3',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'RetailUnitPrice', 'UnitSalePrice',   'TPrice',  null,       null,          ' ',     '4',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'UnitSalePrice',   'UnitSalePrice',   'TPrice',  null,       null,          ' ',     '5',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'BusinessUnit',    'BusinessUnit',    'TVarchar',null,       null,          ' ',     '6',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'RecordAction',    'RecordAction',    'TVarchar',null,       null,          ' ',     '7',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

/* Create the Data set name to the layout for respective Import file type */
exec pr_Setup_CreateInterfaceDataSet @vProcessName, @vDataSetName;

/*------------------------------------------------------------------------------*/
/* ImportFile: Location */
/*------------------------------------------------------------------------------*/

select @vProcessName = 'ImportFile',
       @vDataSetName = 'Locations';

delete from InterfaceFields where DataSetName = @vDataSetName and ProcessName = @vProcessName;

insert into InterfaceFields
             (FieldName,              ExternalFieldName,     FieldType,       FieldWidth, Justification, PadChar, SortSeq, Status, versionId, ProcessName,   DataSetName,   BusinessUnit)
      select  'Location',             'Location',            'TLocation',     null,       null,          ' ',     '1',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LocationType',         'LocationType',        'TLocationType', null,       null,          ' ',     '2',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LocationSubType',      'LocationSubType',     'TTypeCode',     null,       null,          ' ',     '3',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'StorageType',          'StorageType',         'TStorageType',  null,       null,          ' ',     '4',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LocationRow',          'LocationRow',         'TRow',          null,       null,          ' ',     '5',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LocationBay',          'LocationBay',         'TBay',          null,       null,          ' ',     '6',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LocationLevel',        'LocationLevel',       'TLevel',        null,       null,          ' ',     '7',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LocationSection',      'LocationSection',     'TSection',      null,       null,          ' ',     '8',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LocationClass',        'LocationClass',       'TCategory',     null,       null,          ' ',     '9',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'MinReplenishLevel',    'MinReplenishLevel',   'TQuantity',     null,       null,          ' ',     '10',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'MaxReplenishLevel',    'MaxReplenishLevel',   'TQuantity',     null,       null,          ' ',     '11',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ReplenishUoM',         'ReplenishUoM',        'TUoM',          null,       null,          ' ',     '12',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'AllowMultipleSKUs',    'AllowMultipleSKUs',   'TFlag',         null,       null,          ' ',     '13',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Barcode',              'Barcode',             'TBarcode',      null,       null,          ' ',     '14',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PutawayPath',          'PutawayPath',         'TLocation',     null,       null,          ' ',     '15',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PickPath',             'PickPath',            'TLocation',     null,       null,          ' ',     '16',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PickingZone',          'PickingZone',         'TZone',         null,       null,          ' ',     '17',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PutawayZone',          'PutawayZone',         'TZone',         null,       null,          ' ',     '18',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Warehouse',            'Warehouse',           'TWarehouse',    null,       null,          ' ',     '19',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'BusinessUnit',         'BusinessUnit',        'TVarchar',      null,       null,          ' ',     '20',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'RecordAction',         'RecordAction',        'TVarchar',      null,       null,          ' ',     '21',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

/* Create the Data set name to the layout for respective Import file type */
exec pr_Setup_CreateInterfaceDataSet @vProcessName, @vDataSetName;

/*------------------------------------------------------------------------------*/
/* ImportFile: Load Routing Info for Hybrid */
/*------------------------------------------------------------------------------*/

select @vProcessName = 'ImportFile',
       @vDataSetName = 'LRI';

delete from InterfaceFields where DataSetName = @vDataSetName and ProcessName = @vProcessName;

insert into InterfaceFields
             (FieldName,              ExternalFieldName,     FieldType,            FieldWidth, Justification, PadChar, SortSeq, Status, versionId, ProcessName,   DataSetName,   BusinessUnit)
      select  'CustomerNo',           '',                    'TAccount',           null,       null,          ' ',     '1',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CustomerName',         '',                    'TName',              null,       null,          ' ',     '2',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LotRef',               '',                    'TUDF',               null,       null,          ' ',     '3',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CustPO',               '',                    'TCustPO',            null,       null,          ' ',     '4',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PickTicketFrom',       '',                    'TUDF',               null,       null,          ' ',     '5',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PickTicketTo',         '',                    'TUDF',               null,       null,          ' ',     '6',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipTo',               '',                    'TShipToId',          null,       null,          ' ',     '7',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipToStore',          '',                    'TShipToStore',       null,       null,          ' ',     '8',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ClientLoad',           '',                    'TLoadNumber',        null,       null,          ' ',     '9',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipVia',              '',                    'TUDF',               null,       null,          ' ',     '10',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Consolidator',         '',                    'TUDF',               null,       null,          ' ',     '11',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PickUpDate',           '',                    'TName',              null,       null,          ' ',     '12',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PickUpTime',           '',                    'TUDF',               null,       null,          ' ',     '13',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Boxes',                '',                    'TInteger',           null,       null,          ' ',     '14',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Weight',               '',                    'TInteger',           null,       null,          ' ',     '15',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Cube',                 '',                    'TInteger',           null,       null,          ' ',     '16',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Comments',             '',                    'TDescription',       null,       null,          ' ',     '17',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

/* Create the Data set name to the layout for respective Import file type */
exec pr_Setup_CreateInterfaceDataSet @vProcessName, @vDataSetName;

/*------------------------------------------------------------------------------*/
/* ImportFile: Load Routing Info - Walmart */
/*------------------------------------------------------------------------------*/

select @vProcessName = 'ImportFile',
       @vDataSetName = 'LRI_WM';

delete from InterfaceFields where DataSetName = @vDataSetName and ProcessName = @vProcessName;

insert into InterfaceFields
             (FieldName,               ExternalFieldName,     FieldType,            FieldWidth, Justification, PadChar, SortSeq, Status, versionId, ProcessName,   DataSetName,   BusinessUnit)
      select  'CustPO',                '',                    'TCustPO',            null,       null,          ' ',     '1',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ClientLoad',            '',                    'TLoadNumber',        null,       null,          ' ',     '2',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LoadDest',              '',                    'TName',              null,       null,          ' ',     '3',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LoadDestType',          '',                    'TName',              null,       null,          ' ',     '4',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LoadDestAddress',       '',                    'TName',              null,       null,          ' ',     '5',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LoadP_UWindowStart',    '',                    'TDate',              null,       null,          ' ',     '6',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LoadP_UWindowEnd',      '',                    'TDate',              null,       null,          ' ',     '7',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'MABD',                  '',                    'TName',              null,       null,          ' ',     '8',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CarrierPUDate',         '',                    'TDate',              null,       null,          ' ',     '9',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CarrierDueDate',        '',                    'TDate',              null,       null,          ' ',     '10',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CarrierName',           '',                    'TName',              null,       null,          ' ',     '11',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'SCAC',                  '',                    'TName',              null,       null,          ' ',     '12',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Mode',                  '',                    'TName',              null,       null,          ' ',     '13',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipPoint',             '',                    'TName',              null,       null,          ' ',     '14',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LoadingMethod',         '',                    'TName',              null,       null,          ' ',     '15',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Cases',                 '',                    'TInteger',           null,       null,          ' ',     '16',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Weight',                '',                    'TInteger',           null,       null,          ' ',     '17',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Cube',                  '',                    'TInteger',           null,       null,          ' ',     '18',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Pallets',               '',                    'TInteger',           null,       null,          ' ',     '19',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'EventCode',             '',                    'TName',              null,       null,          ' ',     '20',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'POType',                '',                    'TName',              null,       null,          ' ',     '21',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Department',            '',                    'TName',              null,       null,          ' ',     '22',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ConfirmedDate',         '',                    'TDate',              null,       null,          ' ',     '23',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Held_Suspended',        '',                    'TName',              null,       null,          ' ',     '24',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PODest',                '',                    'TName',              null,       null,          ' ',     '25',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

/* Create the Data set name to the layout for respective Import file type */
exec pr_Setup_CreateInterfaceDataSet @vProcessName, @vDataSetName;

/*------------------------------------------------------------------------------*/
/* ImportFile: Load Routing Info - Target */
/*------------------------------------------------------------------------------*/

select @vProcessName = 'ImportFile',
       @vDataSetName = 'LRI_TAR';

delete from InterfaceFields where DataSetName = @vDataSetName and ProcessName = @vProcessName;

insert into InterfaceFields
             (FieldName,               ExternalFieldName,     FieldType,            FieldWidth, Justification, PadChar, SortSeq, Status, versionId, ProcessName,   DataSetName,   BusinessUnit)
      select  'ShipmentStatus',        '',                    'TStatus',            null,       null,          ' ',     '1',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Dept',                  '',                    'TName',              null,       null,          ' ',     '2',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CustPO',                '',                    'TCustPO',            null,       null,          ' ',     '3',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipToStore',           '',                    'TName',              null,       null,          ' ',     '4',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipPointName',         '',                    'TName',              null,       null,          ' ',     '5',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'VendorNo',              '',                    'TName',              null,       null,          ' ',     '6',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'AddressLine1',          '',                    'TAddressLine',       null,       null,          ' ',     '7',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'AddressLine2',          '',                    'TAddressLine',       null,       null,          ' ',     '8',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'City',                  '',                    'TCity',              null,       null,          ' ',     '9',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'State',                 '',                    'TState',             null,       null,          ' ',     '10',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PostalCode',            '',                    'TTypeCode',          null,       null,          ' ',     '11',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ContactName',           '',                    'TName',              null,       null,          ' ',     '12',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ContactNumber',         '',                    'TPhoneNo',           null,       null,          ' ',     '13',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Cartons',               '',                    'TInteger',           null,       null,          ' ',     '14',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Weight',                '',                    'TInteger',           null,       null,          ' ',     '15',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Cube',                  '',                    'TInteger',           null,       null,          ' ',     '16',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PalletSpaces',          '',                    'TInteger',           null,       null,          ' ',     '17',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PalletsStackable',      '',                    'TFlag',              null,       null,          ' ',     '18',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'AvailablePickup',       '',                    'TDate',              null,       null,          ' ',     '19',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Latestpickup',          '',                    'TDate',              null,       null,          ' ',     '20',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Notes',                 '',                    'TNote',              null,       null,          ' ',     '21',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Equipment',             '',                    'TName',              null,       null,          ' ',     '22',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Commodity',             '',                    'TName',              null,       null,          ' ',     '23',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipTogetherId',        '',                    'TName',              null,       null,          ' ',     '24',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'BOL',                   '',                    'TBoLNumber',         null,       null,          ' ',     '25',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Appt',                  '',                    'TDescription',       null,       null,          ' ',     '26',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Itemlevel',             '',                    'TTypeCode',          null,       null,          ' ',     '27',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ItemLevelEntry',        '',                    'TName',              null,       null,          ' ',     '28',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'OrderType',             '',                    'TName',              null,       null,          ' ',     '29',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'BKHL_DC',               '',                    'TName',              null,       null,          ' ',     '30',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'VRSEntryMadeDate',      '',                    'TDateTime',          null,       null,          ' ',     '31',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'VRSLastUpdatedDate',    '',                    'TDateTime',          null,       null,          ' ',     '32',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'VRSEnteredUser',        '',                    'TName',              null,       null,          ' ',     '33',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'VRSUpdatedLastUser',    '',                    'TName',              null,       null,          ' ',     '34',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'UpdateCuttOffTime',     '',                    'TDateTime',          null,       null,          ' ',     '35',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PlanId',                '',                    'TRecordId',          null,       null,          ' ',     '36',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ClientLoad',            '',                    'TLoadNumber',        null,       null,          ' ',     '37',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'DC_ShipTO',             '',                    'TName',              null,       null,          ' ',     '38',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PlannedPickUpDate',     '',                    'TDate',              null,       null,          ' ',     '39',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'StopNumberOf',          '',                    'TName',              null,       null,          ' ',     '40',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CarrierSCAC',           '',                    'TCarrier',           null,       null,          ' ',     '41',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PRONumber',             '',                    'TProNumber',         null,       null,          ' ',     '42',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CONS_SCAC',             '',                    'TTypeCode',          null,       null,          ' ',     '43',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CONS_Auth',             '',                    'TTypeCode',          null,       null,          ' ',     '44',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'StatusDate',            '',                    'TDate',              null,       null,          ' ',     '45',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'PreassignedCarrier',    '',                    'TCarrier',           null,       null,          ' ',     '46',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'FreightTerms',          '',                    'TLookUpCode',        null,       null,          ' ',     '47',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'EarlyDelivery',         '',                    'TDate',              null,       null,          ' ',     '48',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LateDelivery',          '',                    'TDate',              null,       null,          ' ',     '49',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'TripID',                '',                    'TRecordId',          null,       null,          ' ',     '50',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipmentID',            '',                    'TName',              null,       null,          ' ',     '51',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

/* Create the Data set name to the layout for respective Import file type */
exec pr_Setup_CreateInterfaceDataSet @vProcessName, @vDataSetName;

/*------------------------------------------------------------------------------*/
/* ImportFile: Inventory */
/*------------------------------------------------------------------------------*/

select @vProcessName = 'ImportFile',
       @vDataSetName = 'Inventory';

delete from InterfaceFields where DataSetName = @vDataSetName and ProcessName = @vProcessName;

insert into InterfaceFields
             (FieldName,              ExternalFieldName,     FieldType,          FieldWidth, FieldDefaultValue, Justification, PadChar, SortSeq, Status, versionId, ProcessName,   DataSetName,   BusinessUnit)
      select  'SKU',                  '',                    'TSKU',             null,       null,              null,          ' ',     '1',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'SKU1',                 '',                    'TSKU',             null,       null,              null,          ' ',     '2',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'SKU2',                 '',                    'TSKU',             null,       null,              null,          ' ',     '3',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'SKU3',                 '',                    'TSKU',             null,       null,              null,          ' ',     '4',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'SKU4',                 '',                    'TSKU',             null,       null,              null,          ' ',     '5',     'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'SKU5',                 '',                    'TSKU',             null,       null,              null,          ' ',     '6',     'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'InventoryClass1',      '',                    'TInventoryClass',  null,       null,              null,          ' ',     '7',     'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'InventoryClass2',      '',                    'TInventoryClass',  null,       null,              null,          ' ',     '8',     'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'InventoryClass3',      '',                    'TInventoryClass',  null,       null,              null,          ' ',     '9',     'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

union select  'InnerPacksPerLPN',     '',                    'TInteger',         null,       null,              null,          ' ',     '20',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'UnitsPerInnerPack',    '',                    'TInteger',         null,       null,              null,          ' ',     '21',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'UnitsPerLPN',          '',                    'TInteger',         null,       null,              null,          ' ',     '22',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'UoM',                  '',                    'TUoM',             null,       'EA',              null,          ' ',     '23',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

union select  'NumLPNsToCreate',      '',                    'TCount',           null,       '1',               null,          ' ',     '24',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

union select  'Palletization',        '',                    'TFlags',           null,       'Y',               null,          ' ',     '30',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'NumLPNsPerPallet',     '',                    'TCount',           null,       null,              null,          ' ',     '31',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Pallet',               '',                    'TPallet',          null,       null,              null,          ' ',     '32',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Reference',            '',                    'TReference',       null,       null,              null,          ' ',     '33',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ShipmentDate',         '',                    'TUDF',             null,       null,              null,          ' ',     '34',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'CoO',                  '',                    'TCoO',             null,       null,              null,          ' ',     '35',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'ExpiryDate',           '',                    'TDate',            null,       null,              null,          ' ',     '36',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

union select  'ReasonCode',           '',                    'TReasonCode',      null,       null,              null,          ' ',     '40',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Ownership',            '',                    'TOwnership',       null,       'HA',              null,          ' ',     '41',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'Warehouse',            '',                    'TWarehouse',       null,       null,              null,          ' ',     '42',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

union select  'Location',             '',                    'TLocation',        null,       null,              null,          ' ',     '50',    'A',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LocationType',         '',                    'TLocationType',    null,       null,              null,          ' ',     '51',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits
union select  'LPNType',              '',                    'TTypeCode',        null,       'C',               null,          ' ',     '52',    'I',    '1',       @vProcessName, @vDataSetName, BusinessUnit from vwBusinessUnits

/* Create the Data set name to the layout for respective Import file type */
exec pr_Setup_CreateInterfaceDataSet @vProcessName, @vDataSetName;

Go
