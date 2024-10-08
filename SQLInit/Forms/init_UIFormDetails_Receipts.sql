/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/05  MS      Receipt_PrepareForSorting: Renamed FieldNames (JL-286)
  2020/10/08  MRK     Receipts_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/09/22  MS      Receipt_PrepareForSorting: Added Send Router Instruction (JL-251)
  2020/08/11  NB      Receipts_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/08/04  HYP     Change Warehouse control for Receipts_ChangeWarehouse (HA-1275)
  2020/07/28  NB      changes to Receipts_PrintLabels form details (CIMSV3-1029)
  2020/06/16  AJM     Included Receipts_ChangeWarehouse (HA-926)
  2020/03/27  PHK     Included Receipts_PrintLabels (HA-50)
  2020/01/11  RT      Included Receipt_PrepareForSorting (JL-59)
  2018/01/17  RA      Initial revision(CIMSV3-217)
------------------------------------------------------------------------------*/

Go

declare @FormName TName;

/*------------------------------------------------------------------------------*/
/* ChangeWarehouse Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Receipts_ChangeWarehouse';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'Warehouse',             'Warehouse_DBDD',        null,                    1,          null,         1,       'Data',      'NewWarehouse',     @FormName, BusinessUnit from vwBusinessUnits

 /*------------------------------------------------------------------------------*/
/* ChangeArrivalInfo Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Receipts_ChangeArrivalInfo';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,              ControlName,              FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'Vessel',               'Text',                   null,                    0,          null,         0,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ContainerNo',          'Text',                   null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ContainerSize',        'Text',                   null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BillNo',               'Text',                   null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ETACountry',           'DateAny',                null,                    0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ETACity',              'DateAny',                null,                    0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ETAWarehouse',         'DateAny',                null,                    0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'AppointmentDateTime',  'DateTimeFuture',         null,                    0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* RO_ModifyOwnership Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'RO_ModifyOwnership';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
           (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
     select 'Ownership',             'Ownership_DD',          null,                    1,          null,         1,       'Data',      'NewOwnership',     @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Prepare for Sorting Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Receipt_PrepareForSorting';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,                IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'SortLanes',             'Lane_DD',               'Lane',                      1,          null,         1,       'Data',      'Lanes',            @FormName, BusinessUnit from vwBusinessUnits
union select 'PalletSize',            'PalletSize_DD',         'Pallet Size',               1,          '_1',         2,       'Data',      'PalletSize',       @FormName, BusinessUnit from vwBusinessUnits
union select 'ActivateRI',            'YesNo_DD',              'Activate Routing',          0,          'N',          3,       'Data',      'ActivateRI',       @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Receipts_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Receipts_PrintLabels';  -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue,   SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',           null,                    1,          'ReceiptNumber',1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  'Label Format',        1,          null,           2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD','Label Printer',       1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                    3,       'Data',      null,        'PrinterName',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',             null,                  1,          '1',            4,       'Data',      null,        'NumCopies',           @FormName, BusinessUnit from vwBusinessUnits

Go
