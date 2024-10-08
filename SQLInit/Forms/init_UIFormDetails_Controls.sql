/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/06  YJ      Added RecordId (CIMSV3-776)
  2020/04/07  RIA     Changes to ControlName (CIMSV3-776)
  2020/03/31  YJ      Intial revision (CIMSV3-776)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Create Controls Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Controls_Edit';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,   IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,          FormName,  BusinessUnit)
      select 'RecordId',              'HiddenInput',           null,           0,          null,         1,       'Data',      null,                 @FormName, BusinessUnit from vwBusinessUnits
union select 'ControlCategory',       'ReadOnlyText',          null,           0,          null,         2,       'Data',      null,                 @FormName, BusinessUnit from vwBusinessUnits
union select 'Description',           'Text',                  null,           1,          null,         3,       'Data',      null,                 @FormName, BusinessUnit from vwBusinessUnits
union select 'DataTypeDescription',   'ReadOnlyText',          null,           0,          null,         4,       'Data',      null,                 @FormName, BusinessUnit from vwBusinessUnits
union select 'ControlValue',          'Text',                  null,           1,          null,         5,       'Data',      null,                 @FormName, BusinessUnit from vwBusinessUnits
union select 'Status',                'Status_DD',             null,           1,          null,         6,       'Data',      null,                 @FormName, BusinessUnit from vwBusinessUnits

Go
