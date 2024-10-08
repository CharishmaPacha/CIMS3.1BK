/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/17  RKC     Changed the IsRequied fields for few fields (HA-2889)
  2020/05/03  MS      Added RecordId and default Status (HA-91)
  2020/04/07  AJM     Initial revision (HA-91)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Add New List Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LookUp_Add';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,    FieldHint,           IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LookUpCategory',        'LookUpCategory_DD',     null,            null,                1,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LookUpCode',            'Text',                  null,            null,                1,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LookUpDescription',     'Text',                  null,            null,                1,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'SortSeq',               'IntegerMin1',           null,            null,                1,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Status',                'Status_DD',             null,            null,                1,          '_1',         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify Edit List Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'LookUp_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,    FieldHint,           IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'RecordId',              'HiddenInput',           null,            null,                0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LookUpCategory',        'ReadOnlyText',          null,            null,                1,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LookUpCode',            'ReadOnlyText',          null,            null,                0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LookUpDescription',     'Text',                  null,            null,                0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'SortSeq',               'IntegerMin1',           null,            null,                0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Status',                'Status_DD',             null,            null,                1,          '_1',         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

Go
