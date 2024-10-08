/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/11  GAG     Added new form for Modify Commercial Info (BK-797)
  2020/09/22  RV      SKUs_PrintLabels: Added NumCopies (CIMSV3-1079)
  2020/08/11  NB      SKUs_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/07/28  NB      Added SKUs_PrintLabels form details (CIMSV3-1029)
  2019/05/26  RIA     SKU_ModifyDimensions: Changes to display values for Tie and High (CIMSV3-219)
  2019/03/08  RIA     Initial Version (CIMSV3-219)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Modify SKU Dimensions Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'SKU_ModifyDimensions';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'UnitLength',            'Decimal4',              null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitWidth',             'Decimal4',              null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitHeight',            'Decimal4',              null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitVolume',            'Decimal4',              null,                    0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitWeight',            'Decimal4',              null,                    0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPackLength',       'Decimal4',              null,                    0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPackWidth',        'Decimal4',              null,                    0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPackHeight',       'Decimal4',              null,                    0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPackVolume',       'Decimal4',              null,                    0,          null,         9,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPackWeight',       'Decimal4',              null,                    0,          null,         10,      'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify Pack Configurations Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'SKU_ModifyPackConfigurations';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName)

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'UnitsPerInnerPack',     'IntegerMin0',           null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitsPerLPN',           'IntegerMin0',           null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InnerPacksperLPN',      'IntegerMin0',           null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipPack',              'IntegerMin1',           null,                    0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'PalletTie',             'IntegerMin0',           'Tie',                   0,          null,         5,       'Data',      'Tie',              @FormName, BusinessUnit from vwBusinessUnits
union select 'PalletHigh',            'IntegerMin0',           'High',                  0,          null,         6,       'Data',      'High',             @FormName, BusinessUnit from vwBusinessUnits
union select 'UoM',                   'UoM_DD',                null,                    0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'InventoryUoM',          'UoM_DDMS',             'Inventory UoM',          0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify SKU Classes Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'SKU_ModifyClasses';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'PutawayClass',          'PAClass_DD',            null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReplenishClass',        'ReplenishClass_DD',     null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ABCClass',              'ABCClass_DD',           null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify SKU Attributes Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'SKU_ModifyAliases';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'CaseUPC',               null,                    null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'AlternateSKU',          null,                    null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'UPC',                   null,                    null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify SKU Commercial Info */
/*------------------------------------------------------------------------------*/
select @FormName = 'SKU_ModifyCommercialInfo';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'HarmonizedCode',        null,                    null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'DefaultCoO',            'CoO_DD',                null,                    0,          '_1',         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'UnitPrice',             null,                    null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* SKUs_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'SKUs_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,                      SortSeq, DataTagType, DataTagName, HandlerTagName,    FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',             null,                    1,          'SKU',                             1,       'Data',      null,        null,              @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  null,                    1,          null,                              2,       'Data',      null,        'LabelFormatName', @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD',null,                    1,          '~SessionKey_DeviceLabelPrinter~', 3,       'Data',      null,        'PrinterName',     @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',             null,                    1,          '1',                               4,       'Data',      null,        'NumCopies',       @FormName, BusinessUnit from vwBusinessUnits

Go
