/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/02  SJ      Order_ModifyPickTicket: Added Cancel date (OB-1829)
  2021/03/17  SAK     Added Form For Edit Addresses (HA-2309)

  2021/03/06  SAK     Added field DesiredShipDate in Order_ModifyPickTicket (HA-2138) 
  2020/12/04  AY      Changed control for ShipComplete Percent (HA-1655)
  2020/11/28  AY      Order_ModifyShipDetails: Made ShipVia required (CIMSV3-792)
  2020/09/15  RV      Orders_CreateKits: InventoryClass1 changed from drop down to read only text box and removed as required controls for LabelFormatName and PrinterName (HA-1434)
  2020/09/10  RV      Orders_CreateKits: Added form details (HA-1239)
  2020/06/08  YJ      Changed FreightTerms_DDMS as FreightTerms_DD (HA-862)
  2019/12/18  MS      Initial revision (CIMSV3-424)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ModifyPickTicket Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Order_ModifyPickTicket';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'PickTicket',            'ReadOnlyText',          null,          0,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'OrderType',             'OrderType_DD',          null,          0,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'DesiredShipDate',       'DateFuture',            null,          0,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CancelDate',            'DateFuture',            null,          0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ShipCompletePercent',   'PercentMax100',         null,          0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Priority',              'IntegerMin0',           null,          0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CarrierOptions',        'CarrierOptions_DD',     'Insurance',   0,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AESNumber',             'Text',                  'AES Number',  0,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ShipmentRefNumber',     'Text',                  null,          0,           null,          9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyShipDetails Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Order_ModifyShipDetails';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,         ControlName,        FieldCaption,  IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'PickTicket',       'ReadOnlyText',     null,          0,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ShipVia',          'ShipVia_DD',       null,          1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FreightTerms',     'FreightTerms_DD',  null,          0,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'BillToAccount',    'Text',             null,          0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FreightCharges',   'Decimal4',         null,          0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Orders_CreateKits Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Orders_CreateKits';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,                ControlName,               FieldCaption,            IsRequired, Visible, DefaultValue,  SortSeq,  DataTagType, DataTagName,            HandlerTagName,        FormName,  BusinessUnit)
      select 'PickTicket',             'ReadOnlyText',             null,                    0,          1,       null,           1,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Ownership',              'ReadOnlyText',             null,                    0,          1,       null,           2,       'Data',      'Owner',                null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'CustomerName',           'ReadOnlyText',             null,                    0,          1,       null,           3,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',              'ReadOnlyText',             null,                    0,          1,       null,           4,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Kits',                   'OrderDetailKits_DD',       'Kits',                  1,          1,       null,           5,       'Data',      'OrderDetailId',        'KitSelection',        @FormName, BusinessUnit from vwBusinessUnits
union select 'Lot',                    'ReadOnlyText',             null,                    0,          1,       null,           6,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'UOM',                    'UoM_DD',                   null,                    1,          1,       null,           7,       'Data',      null,                   'CreationUoM',         @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitsPerInnerPack',      'IntegerMin0',              'Units per Case',        1,          1,       null,           8,       'Data',      null,                   'UnitsPerInnerPack',   @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPacksPerLPN',       'IntegerMin0',              'Cases per LPN',         1,          1,       null,           9,       'Data',      null,                   'InnerPacksPerLPN',    @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitsPerLPN',            'IntegerMin0',              'Qty per LPN',           1,          1,       null,          10,       'Data',      null,                   'UnitsPerLPN',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumLPNsToCreate',        'IntegerMin1',              '# LPNs to create',      1,          1,       null,          11,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'InventoryClass1',        'ReadOnlyText',             null,                    0,          1,       null,          12,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Reference',              'InputText',                null,                    0,          1,       null,          13,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'GeneratePallet',         'GeneratePalletOptions_DD', 'Palletization',         1,          1,       null,          14,       'Data',      'GeneratePalletOption', 'GeneratePalletOption',@FormName, BusinessUnit from vwBusinessUnits
union select 'Pallet',                 'InputText',                null,                    1,          1,       null,          15,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',        'LPNLabelFormat_DD',        null,                    0,          1,       null,          16,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterName',            'LPNLabelPrinter_DBDD',     null,                    0,          1,       '~SessionKey_DeviceLabelPrinter~',
                                                                                                                                17,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'KitSelectionEntityType', 'HiddenInput',              null,                    0,          1,       'OrderDetail', 18,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'SKUId',                  'HiddenInput',              null,                    0,          1,       null,          19,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'OrderId',                'HiddenInput',              null,                    0,          1,       null,          20,       'Data',      null,                   null,                  @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Addresses Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Order_Addresses';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,             FieldCaption,  IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'Name',                  'Text',                  null,          1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine1',          'Text',                  null,          1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine2',          'Text',                  null,          0,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'AddressLine3',          'Text',                  null,          0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'City',                  'Text',                  null,          1,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'State',                 'Text',                  null,          1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Zip',                   'Text',                  null,          1,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Country',               'Text',                  null,          1,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'PhoneNo',               'Text',                  null,          0,           null,          9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactPerson',         'Text',                  null,          0,           null,          10,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactId',             'HiddenInput',           null,          1,           null,          11,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContactType',           'HiddenInput',           null,          1,           null,          12,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

Go
