/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/18  AY      set FieldCaption as not required (HA-1886)
  2020/01/08  SJ      Added FieldVisible to form (HA-1887)
  2020/06/25  SJ      Initial revision (CIMSV3-972)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Modify LayoutFields Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LayoutFields_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,          ControlName,        FieldCaption,  IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'RecordId',          'HiddenInput',      null,          0,           null,          0,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContextName',       'HiddenInput',      null,          0,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LayoutDescription', 'ReadOnlyText',     null,          0,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldName',         'ReadOnlyText',     null,          0,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldCaption',      'Text',             null,          0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldWidth',        'IntegerMin0',      null,          0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldVisible',      'Integer',          null,          0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldDisplayFormat','Text',             null,          0,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'IsSelectable',      'YesNo_DD',         null,          0,           null,          14,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'IsSortable',        'YesNo_DD',         null,          0,           null,          15,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*
-- Not used
union select  'UserId',            'Text',             null,          0,           null,          10,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'RoleId',            'Text',             null,          0,           null,          11,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldDefaultValue', 'Text',             null,          0,           null,          9,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

-- these are changed using layout editor, so there is no need for user to change directly in the table
union select  'AggregateMethod',   'Text',             null,          0,           null,          12,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldType',         'Text',             null,          0,           null,          13,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldVisible',      'Integer',          null,          0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'FieldVisibleIndex', 'Integer',          null,          0,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

--Not editable, this is defined on standard layout and all others use that
union select  'KeyFieldType',      'Text',             null,          0,           null,          16,      'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

*/

Go
