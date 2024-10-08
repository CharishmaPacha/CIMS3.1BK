/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/14  NB      Initial revision (HA-320)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Import Files Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Maintenance_ImportFiles';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,               UIControl,             FieldCaption,            IsRequired, DefaultValue,     SortSeq, DataTagType, DataTagName, FieldHint, FormName,  BusinessUnit)
      select 'ImportFileType',         'DropDown',            'select File Type',      1,          null,             1,       'Data',      null,        null,      @FormName, BusinessUnit from vwBusinessUnits

Go
