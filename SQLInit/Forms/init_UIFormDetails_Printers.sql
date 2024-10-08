/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/02  SJ      Setup DD for PrintProtocol, Added fields StockSize, ProcessGroup for  Add & Edit printer (HA-2019)
  2020/11/10  SJ      Added form attributes for Printers_Add & Printers_Edit (JL-293)
  2020/10/09  RV      Printers_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/08/11  NB      Printers_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/07/28  NB      Initial revision(CIMSV3-1029)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Printers_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Printers_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',             null,                    1,          'TaskId',           1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  'Label Format',          1,          null,               2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD','Label Printer',         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                          3,       'Data',      null,        'PrinterName',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',             null,                    1,          '1',                4,       'Data',      null,        'NumCopies',           @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Printers_Add  Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Printers_Add ';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'PrinterName',           'Text',                    null,                    0,          null,               1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterDescription',    'Text',                    null,                    0,          null,               2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterType',           'PrinterType_DD',          null,                    1,          null,               3,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',             'Warehouse_DD',            null,                    1,          null,               4,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterConfigName',     'HiddenInput',             null,                    0,          null,               5,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterConfigIP',       'Text',                    null,                    0,          null,               6,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterPort',           'Text',                    null,                    0,          null,               7,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrintProtocol',         'PrintProtocol_DD',        null,                    1,          null,               8,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterUsability',      'Text',                    null,                    0,          null,               9,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'ProcessGroup',          'Text',                    null,                    0,          null,               10,      'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'StockSizes',            'Text',                    null,                    0,          null,               11,      'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Status',                'Status_DD',               null,                    1,          '_1',               12,      'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Printers_Edit  Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Printers_Edit ';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'PrinterId',             'HiddenInput',             null,                    0,          null,               0,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterName',           'Text',                    null,                    0,          null,               1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterDescription',    'Text',                    null,                    0,          null,               2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterType',           'PrinterType_DD',          null,                    1,          null,               3,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',             'Warehouse_DD',            null,                    1,          null,               4,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterConfigName',     'HiddenInput',             null,                    0,          null,               5,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterConfigIP',       'Text',                    null,                    0,          null,               6,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterPort',           'Text',                    null,                    0,          null,               7,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrintProtocol',         'PrintProtocol_DD',        null,                    1,          null,               8,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'PrinterUsability',      'Text',                    null,                    0,          null,               9,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'ProcessGroup',          'Text',                    null,                    0,          null,               10,      'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'StockSizes',            'Text',                    null,                    0,          null,               11,      'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'Status',                'Status_DD',               null,                    1,          null,               12,      'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits

Go
