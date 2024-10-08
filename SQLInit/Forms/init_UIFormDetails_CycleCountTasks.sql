/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/16  KBB     Added CycleCountTasks_PrintLabels (HA-1793)
  2020/12/15  KBB     Initial Revision (HA-1792)
------------------------------------------------------------------------------*/

Go

declare @FormName TName;

/*------------------------------------------------------------------------------*/
/* CycleCountTasks_AssignToUser Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CycleCountTasks_AssignToUser';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            FieldHint,                      IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'AssignedTo',            'CCUsers_DD',            'Assign To User',        'select a user to assign to',   1,          null,         1,       'Data',      'AssignUser',       @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* CycleCountTasks_PrintLabels Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CycleCountTasks_PrintLabels'; -- NOTE: CHANGING THIS WILL IMPACT THE ACTION

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