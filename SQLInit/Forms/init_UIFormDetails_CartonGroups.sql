/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/04  SJ     Added forms  Add CartonTypeToGroup & Edit CartonTypeInGroup (HA-1621)
  2020/10/28  SJ     Initial revision (HA-1621)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ModifyFields Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CartonGroup_Add';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'CartonGroup',           'Text',            null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CartonGroupDesc',       'Text',            'Description',              1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CG_Status',             'Status_DD',       null,                       1,           '_1',          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyFields Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CartonGroup_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'CartonGroup',           'ReadonlyText',    null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CartonGroupDesc',       'Text',            'Description',              1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CG_Status',             'Status_DD',       null,                       1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyFields Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CartonGroupCartonType_Add';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'CartonGroup',           'CartonGroup_DD',  null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CartonType',            'CartonType_DD',   null,                       1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CG_AvailableSpace',     'Text',            null,                       0,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CG_MaxWeight',          'Text',            null,                       0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CG_MaxUnits',           'Text',            null,                       0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CGT_Status',            'Status_DD',       'Status',                   1,           '_1',          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyFields Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'CartonGroupCartonType_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,              ControlName,       FieldCaption,               IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'CartonGroup',           'ReadonlyText',    null,                       1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CartonType',            'ReadonlyText',    null,                       1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CG_AvailableSpace',     'Text',            null,                       0,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CG_MaxWeight',          'Text',            null,                       0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CG_MaxUnits',           'Text',            null,                       0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'CGT_Status',            'Status_DD',       'Status',                   1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

Go
