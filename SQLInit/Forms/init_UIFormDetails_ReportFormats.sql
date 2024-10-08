/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/03  RV      Corrected captions and sort sequence (CIMSV3-1189)
  2020/11/03  RV      Initial revision (CIMSV3-1189)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Label Formats - Add Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ReportFormats_Add';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,          IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'EntityType',            'Text',            null,                  1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportName',            'Text',            null,                  1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportDescription',     'Text',            null,                  1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportTemplateName',    'Text',            null,                  1,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportSchema',          'Text',            null,                  1,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportFileName',        'Text',            null,                  0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportDisplayName',     'Text',            null,                  0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FolderName',            'Text',            null,                  1,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'PageSize',              'Text',            null,                  0,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'DocumentType',          'Text',            null,                  0,           null,          9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'DocumentSubType',       'Text',            null,                  0,           null,          10,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'DocumentSet',           'Text',            null,                  0,           null,          11,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportProcedureName',   'Text',            null,                  0,           null,          12,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',               'Integer',         null,                  0,           null,          13,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',                'Status_DD',       null,                  1,           '_1',          14,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Label Formats - Edit Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ReportFormats_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'EntityType',            'ReadOnlyText',    null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportName',            'ReadOnlyText',    null,                       1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportDescription',     'Text',            null,                       1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportTemplateName',    'Text',            null,                       1,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportSchema',          'Text',            null,                       1,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportFileName',        'Text',            null,                       0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportDisplayName',     'Text',            null,                       0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FolderName',            'Text',            null,                       1,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'PageSize',              'Text',            null,                       0,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'DocumentType',          'Text',            null,                       0,           null,          9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'DocumentSubType',       'Text',            null,                       0,           null,          10,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'DocumentSet',           'Text',            null,                       0,           null,          11,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ReportProcedureName',   'Text',            null,                       0,           null,          12,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',               'Integer',         null,                       0,           null,          13,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',                'Status_DD',       null,                       1,           '_1',          14,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

Go
