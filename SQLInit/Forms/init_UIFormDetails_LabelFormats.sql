/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/02  AY      Initial revision (CIMSV3-1183)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Label Formats - Add Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LabelFormats_Add';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'EntityType',            'Text',            null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LabelFormatName',       'Text',            'Format Name',              1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LabelFormatDesc',       'Text',            'Format Descripton',        1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LabelTemplateType',     'Text',            null,                       1,           'ZPL',         4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ZPLTemplate',           'Text',            null,                       0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LabelSize',             'Text',            null,                       1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'NumCopies',             'IntegerMin1',     null,                       1,           '1',           7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',               'Integer',         null,                       0,           null,          20,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',                'Status_DD',       null,                       1,           '_1',          21,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Label Formats - Edit Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LabelFormats_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'EntityType',            'Text',            null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LabelFormatName',       'ReadOnlyText',    'Format Name',              1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LabelFormatDesc',       'Text',            'Format Descripton',        1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LabelTemplateType',     'Text',            null,                       1,           'ZPL',         4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ZPLTemplate',           'Text',            null,                       0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LabelSize',             'Text',            null,                       1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'NumCopies',             'IntegerMin1',     null,                       1,           '1',           7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',               'Integer',         null,                       0,           null,          20,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',                'Status_DD',       null,                       1,           '_1',          21,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

Go
