/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/27  AY      Loads_ModifyApptDetails: Add Dock Location (HA-2835)
  2021/04/27  RIA     Loads_CreateTransferLoad: Made ShipVia as requiered input (HA-2675)
  2021/04/21  SK      Load_GenerateBoLs: Added BOD_GroupCriteria (HA-2676)
  2021/03/31  KBB     Loads_ModifyBoLInfo: Added BoLStatus (HA-2467)
  2021/03/05  SJ      Loads_ModifyApptDetails: Added fields CarrierCheckIn, CarrierCheckOut (HA-2137)
  2021/02/25  TK      Load_GenerateBoLs: Initial revision (HA-2064)
  2021/02/18  AY      Load_CreateOrModify: Default Loading Method to RFScan Loading (HA-1940)
  2020/10/27  RKC     Changed the control name for StagingLocation (HA-1280)
  2020/10/14  SV      Changes done as per change in the static form and folder name at UI end (HA-1566)
  2020/10/08  MRK     Loads_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/09/01  NB      Loads_ModifyApptDetails.AppointmentDateTime changed to DateTimeFuture(HA-1303)
  2020/08/11  NB      Loads_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/08/11  KBB     Added Fields for load Shipping_CreateOrModifyLoad (HA-1003)
  2020/08/06  HYP     Corrections to DockLocation Dropdown (HA-1281)
  2020/08/06  MS/MRK  Corrections to Warehouse Dropdown (HA-1278)
  2020/08/06  SAK     Loads_CreateTransferLoad ControlName changed for ShipToId and ShipFrom fields (HA-1279)
  2020/08/05  MRK     Changed control name in Load_GenerateLoad Form Attributes   (HA-1278)
  2020/07/31  NB      Loads_PrintDocuments..changes to display printers by allowed Warehouses, default
                        label and report printer to device configured printers(HA-1269)
  2020/07/28  NB      Added Loads_PrintLabels form details(CIMSV3-1029)
  2020/07/22  OK      Changed the control for Weight and Volume to allow decimals (HA-1155)
  2020/07/16  OK      Added form details for Modify Load appt details form and modify BoL info form (HA-1146, HA-1147)
  2020/07/10  RKC     Shipping_CreateLoad: Added StagingLocation, LoadingMethod, Palletized fileds (HA-1106)
  2020/07/07  KBB     Changed Warehouse field Default value as first one (HA-1026)
  2020/07/01  TK      Loads_CreateTransferLoad: Added (HA-830)
  2020/07/01  NB      Shipping_CreateLoad: Added ShipFrom field(CIMSV3-996)
  2020/06/24  AJ      Loads_PrintDocuments: Added FormDetails (HA-984)
  2020/06/23  SAK/RV  Shipping_CreateLoad: changed ControlName for ShipToId_DD as ConsolidatorAddress_DD (HA-1001)
  2020/06/17  RV      Shipping_CreateLoad: Corrected field name (HA-961)
  2020/06/10  OK      Added form details for create load action (HA-843)
  2020/03/19  RV      Load_CreateLoad: Added form details (CIMSV3-760)
  2020/03/17  RV      Initial revision(CIMSV3-759)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;
/*------------------------------------------------------------------------------*/
/* Load_GenerateLoad Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'OrdersToShip_GenerateLoad';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption, UIControl,     IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'PickTicket',            'HiddenInput',           '',           'HiddenInput', 0,          'PickTicket', 1,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Load_GenerateLoad Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Load_CreateLoad';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LoadType',             'LoadType_DD',            null,                    1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipVia',              'ShipVia_DD',             null,                    1,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DesiredShipDate',      'DateFuture',             null,                    0,          null,         3,       'Data',      'DesiredShipDate',  @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Loads_CreateTransferLoad Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Loads_CreateTransferLoad';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LoadType',              'HiddenInput',           '',                      0,          'Transfer',   1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipFrom',              'LoadWarehouse_DBDD',    null,                    1,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipToId',              'LoadWarehouse_DBDD',    null,                    1,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipVia',               'ShipVia_DD',            null,                    1,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DockLocation',          'LoadDockLocation_DBDD', null,                    0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Loads_PrintDocuments Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Loads_PrintDocuments';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,                  FieldCaption,  IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LabelPrinterName',      'LoadLabelPrinter_DBDD',      null,          1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                             1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName2',     'LoadLabelPrinter_DBDD',      null,          0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReportPrinterName',     'LoadReportPrinter_DBDD',     null,          1,          '~SessionKey_DeviceDocumentPrinter~',
                                                                                                             3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Load_CreateOrModify Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Load_CreateOrModify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LoadNumber',           'ReadOnlyText',             null,                    1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LoadType',             'LoadType_DD',              null,                    1,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'FromWarehouse',        'LoadWarehouse_DBDD',       'Warehouse',             1,          '_1',         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipFrom',             'ShipFrom_DD',              'Ship From',             1,          '_1',         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipVia',              'ShipVia_DD',               null,                    1,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'RoutingStatus',        'RoutingStatus_DD',         null,                    0,          '_1',         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DesiredShipDate',      'DateFuture',               null,                    0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShippedDate',          'DateFuture',               null,                    0,          null,        10,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'PRONumber',            'Text',                     null,                    0,          null,        12,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'TrailerNumber',        'Text',                     null,                    0,          null,        13,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'SealNumber',           'Text',                     null,                    0,          null,        14,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DockLocation',         'LoadDockLocation_DBDD',    null,                    0,          null,        15,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'StagingLocation',      'LoadStagingLocation_DBDD', null,                    0,          null,        17,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LoadingMethod',        'LoadingMethod_DD',         null,                    0,          '_1',        18,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Palletized',           'YesNo_DD',                 null,                    0,          null,        19,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Weight',               'Decimal4',                 null,                    0,          null,        20,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Volume',               'Decimal4',                 null,                    0,          null,        21,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ClientLoad',           'Text',                     null,                    0,          null,        22,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'FreightCharges',       'Decimal4',                 null,                    0,          null,        24,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Load_GenerateBoLs Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Load_GenerateBoLs';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'Regenerate',            'YesNo_DD',              'Re-Generate BoL?',      0,          '_1',         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BOD_GroupCriteria',     'BOD_GroupCriteria_DD',  'Customer Order Group',  0,          '_1',         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Loads_ModifyBoLinfo Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Loads_ModifyBoLInfo';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LoadNumber',           'ReadOnlyText',           null,                    1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'FoB',                  'FoB_DD',                 null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BoLCID',               'Text',                   null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MasterBoL',            'Text',                   null,                    0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'MasterTrackingNo',     'Text',                   null,                    0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ConsolidatorAddressId','ConsolidatorAddress_DD', 'Consolidator Address',  0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BoLStatus',            'BoLStatus_DD',           null,                    0,          '_1',         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Loads_ModifyApptDetails Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Loads_ModifyApptDetails';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,                 ControlName,              FieldCaption,  UIControl,     IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LoadNumber',              'ReadOnlyText',           null,          null,          1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'AppointmentConfirmation', 'Text',                   null,          null,          0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'AppointmentDateTime',     'DateTimeFuture',         null,          null,          0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DeliveryRequestType',     'DeliveryRequestType_DD', null,          null,          0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DeliveryDate',            'DateFuture',             null,          null,          0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'TransitDays',             'Text',                   null,          null,          0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DockLocation',            'LoadDockLocation_DBDD',  null,          null,          0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'CarrierCheckIn',           null,                    null,          'InputTime',   0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'CarrierCheckOut',          null,                    null,          'InputTime',   0,          null,         9,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Loads_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Loads_PrintLabels';  -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,                  FieldCaption,            IsRequired, DefaultValue,   SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',                null,                    1,          'LoadNumber',   1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',     'Label Format',          1,          null,           2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'LoadLabelPrinter_DBDD',      'Label Printer',         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                         3,       'Data',      null,        'PrinterName',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',                null,                    1,          '1',            4,       'Data',      null,        'NumCopies',           @FormName, BusinessUnit from vwBusinessUnits

Go