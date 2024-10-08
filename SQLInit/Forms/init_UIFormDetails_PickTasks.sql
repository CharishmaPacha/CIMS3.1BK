/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/08  MRK     PickTasks_PrintLabels: Added NumCopies (CIMSV3-1115)
  2020/08/11  NB      PickTasks_PrintLabels: defined HandlerTagName for LabelPrinter for Local Printer Support(CIMSV3-1047)
  2020/07/31  NB      PickTasks_PrintDocuments..changes to display printers by allowed Warehouses, default
                        label and report printer to device configured printers(HA-1268)
  2020/07/28  NB      Added PickTasks_PrintLabels form details(CIMSV3-1029)
  2020/06/03  AY      Setup new action to print documents for tasks
  2020/03/20  MS      Changes to display Placeholder for AssignTo Field (CIMSV3-768)
  2019/04/19  AJ      Changed FormaName, FieldName and UI control (CIMSV3-264)
  2019/03/23  AJ      Initial revision(CIMSV3-215)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* AssignTaskToUser Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'PickTasks_AssignToUser';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            FieldHint,                      IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'AssignedTo',            'Pickers_DD',            'Assign To User',        'select a user to assign to',   1,          null,         1,       'Data',      'AssignUser',       @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* PickTasks_PrintDocuments Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'PickTasks_PrintDocuments';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,                      FieldCaption, IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LabelPrinterName',      'GenericLabelPrinter_DBDD',       null,         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName2',     'GenericLabelPrinter_DBDD',       null,         0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReportPrinterName',     'GenericReportPrinter_DBDD',      null,         1,          '~SessionKey_DeviceDocumentPrinter~',
                                                                                                                3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* PickTasks_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'PickTasks_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,               FieldCaption,            IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName, HandlerTagName,        FormName,  BusinessUnit)
      select 'EntityKeyName',         'HiddenInput',             null,                    1,          'TaskId',           1,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelFormatName',       'EntityLabelFormat_DBDD',  'Label Format',          1,          null,               2,       'Data',      null,        null,                  @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName',      'GenericLabelPrinter_DBDD','Label Printer',         1,          '~SessionKey_DeviceLabelPrinter~',
                                                                                                                          3,       'Data',      null,        'PrinterName',         @FormName, BusinessUnit from vwBusinessUnits
union select 'NumCopies',             'IntegerMin1',             null,                    1,          '1',                4,       'Data',      null,        'NumCopies',           @FormName, BusinessUnit from vwBusinessUnits

Go
