/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/08  MRK     Receivers_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/08/11  NB      Receivers_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/07/04  SAK     Receiver_Create and Receiver_Modify changed ControlName for Warehouse field (HA-1276)
  2020/07/28  NB      changes to Receivers_PrintLabels form details(CIMSV3-1029)
  2020/06/25  NB      Added Warehouse field to Receiver_Create and Receiver_Modify(CIMSV3-987)
  2020/05/08  AJ      Changes to show default values for ReceiverDate field (HA-309)
  2020/03/30  PHK     Added Receivers_PrintLabels (HA-51)
  2020/03/28  AY      Changes to send ReceiverId (JL-160)
  2019/05/08  RIA     Changes to display the form correctly
  2018/01/17  RA      Initial revision(CIMSV3-217)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Create Receiver Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Receiver_Create';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,    FieldHint,           IsRequired, DefaultValue,          SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'ReceiverDate',          'DateFuture',            null,            null,                1,          'Today',               1,       'Data',      'ReceiverDate',     @FormName, BusinessUnit from vwBusinessUnits
union select 'BoLNumber',             'Text',                  null,            null,                1,          null,                  2,       'Data',      'BoLNo',            @FormName, BusinessUnit from vwBusinessUnits
union select 'Container',             'Text',                  null,            null,                1,          null,                  3,       'Data',      'ContainerNo',      @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',             'Warehouse_DBDD',        null,            null,                1,          null,                  4,       'Data',      'Warehouse',        @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef1',          'Text',                  null,            null,                0,          null,                  5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef2',          'Text',                  null,            null,                0,          null,                  6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef3',          'Text',                  null,            null,                0,          null,                  7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef4',          'Text',                  null,            null,                0,          null,                  8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef5',          'Text',                  null,            null,                0,          null,                  9,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify Receiver Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Receiver_Modify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,    FieldHint,           IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'ReceiverId',            'HiddenInput',           null,            null,                0,          null,         0,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverNumber',        'HiddenInput',           null,            null,                0,          null,         0,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverDate',          'DateFuture',            null,            null,                1,          null,         1,       'Data',      'ReceiverDate',     @FormName, BusinessUnit from vwBusinessUnits
union select 'BoLNumber',             'Text',                  null,            null,                1,          null,         2,       'Data',      'BoLNo',            @FormName, BusinessUnit from vwBusinessUnits
union select 'Container',             'Text',                  null,            null,                1,          null,         3,       'Data',      'ContainerNo',      @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',             'Warehouse_DBDD',        null,            null,                1,          null,         4,       'Data',      'Warehouse',        @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef1',          'Text',                  null,            null,                0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef2',          'Text',                  null,            null,                0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef3',          'Text',                  null,            null,                0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef4',          'Text',                  null,            null,                0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReceiverRef5',          'Text',                  null,            null,                0,          null,         9,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Print  Receiver Label */
/*------------------------------------------------------------------------------*/
select @FormName = 'Receivers_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue,     SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',           null,                    1,          'ReceiverNumber', 1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  'Label Format',        1,          null,             2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD','Label Printer',       1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                      3,       'Data',      null,        'PrinterName',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',           null,                    1,          '1',              4,       'Data',      null,        'NumCopies',           @FormName, BusinessUnit from vwBusinessUnits

Go
