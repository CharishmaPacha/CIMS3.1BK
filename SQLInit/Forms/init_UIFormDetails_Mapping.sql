/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/26  SAK      Initial revision (CIMSV3-811)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* CreateNewMapping Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Mapping_Add';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,         ControlName,        FieldCaption,  IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'SourceSystem',     'Text',             null,          1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'TargetSystem',     'Text',             null,          1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'EntityType',       'Text',             null,          1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Operation',        'Text',             null,          0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SourceValue',      'Text',             null,          1,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'TargetValue',      'Text',             null,          1,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',           'Status_DD',        null,          1,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',          'Integer',          null,          0,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* ModifyMapping Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Mapping_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,         ControlName,        FieldCaption,  IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'SourceSystem',     'ReadOnlyText',     null,          1,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'TargetSystem',     'ReadOnlyText',     null,          1,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'EntityType',       'ReadOnlyText',     null,          1,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Operation',        'ReadOnlyText',     null,          0,           null,          6,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SourceValue',      'ReadOnlyText',     null,          1,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'TargetValue',      'Text',             null,          1,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'Status',           'Status_DD',        null,          1,           null,          7,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',          'Integer',          null,          0,           null,          8,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits

Go
