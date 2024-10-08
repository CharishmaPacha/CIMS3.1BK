/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/08  MRK     Pallets_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/08/11  NB      Pallets_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/07/30  NB      Pallet_GeneratePallets, Pallet_GenerateCarts..changed to display user allowed
                        Warehouse label printer on and defaulted to device label printer,
                        changed to display user allowed Warehouses only in Warehouse selection(HA-1256, HA-1257)
  2020/07/28  NB      Added Pallets_PrintLabels form details(CIMSV3-1029)
  2020/05/18  RKC     Added LabelFormatName, DeviceName For LPN_GenerateLPNs (HA-447)
  2020/02/21  MS      Changes to display default PalletFormat for GeneratePallets form (JL-118)
  2020/02/13  RIA     Changes to FieldName, ControlName, FieldCaption, DefaultValue and DataTagName (CIMSV3-694)
  2020/02/02  RIA     Changes to FieldName, ControlName, DataTag and DefaultValue (CIMSV3-694)
  2019/03/28  RIA     Initial Version
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Generate Pallets Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Pallet_GeneratePallets';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,                FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'PalletTypeGen',         'PalletTypeGen_DD',         'Pallet Type',           1,          '_1',         1,       'Data',      'PalletType',       @FormName, BusinessUnit from vwBusinessUnits
union select 'NumPallets',            'IntegerMin1',              'Num Pallets to Create', 1,          '1',          2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'PalletFormat',          'PalletFormat_DD',          'select Pallet Format',  1,          '_1',         3,       'Data',      'PalletFormat',     @FormName, BusinessUnit from vwBusinessUnits
union select 'WarehouseDesc',         'Warehouse_DBDD',            null,                   1,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'PalletLabelFormat_DD',     'Label Format',          0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD', 'Label Printer',         0,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                     6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Generate Pallets Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Pallet_GenerateCarts';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,                 FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'CartTypeGen',           'CartTypeGen_DD',            'Cart Type',             1,          '_1',         1,       'Data',      'PalletType',       @FormName, BusinessUnit from vwBusinessUnits
union select 'NumPallets',            'IntegerMin1',               'Num Pallets to Create', 1,          '1',          2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'CartFormat',            'CartFormat_DD',             'Cart Format',           1,          '_1',         3,       'Data',      'PalletFormat',     @FormName, BusinessUnit from vwBusinessUnits
union select 'LPNTypeForCart',        'LPNTypeForCart_DD',         'LPN Type',              1,          '_1',         4,       'Data',      'LPNType',          @FormName, BusinessUnit from vwBusinessUnits
union select 'NumPositions',          'IntegerMin0',               'Num Positions/Cart',    1,          '0',          5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'CartPositionFormat',    'CartPositionFormat_DD',     'Cart Position Format',  0,          '_2',         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'WarehouseDesc',         'Warehouse_DBDD',            null,                    1,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'PalletLabelFormat_DD',      'Label Format',          0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD',  'Label Printer',         0,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                      9,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
/*------------------------------------------------------------------------------*/
/* Pallets_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Pallets_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',             null,                    1,          'Pallet',           1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  'Label Format',          1,          null,               2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD','Label Printer',         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                          3,       'Data',      null,        'PrinterName',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',             null,                    1,          '1',                4,       'Data',      null,        'NumCopies',           @FormName, BusinessUnit from vwBusinessUnits

Go
