/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/21  NB      Added DefaultSelectionName(HA-2271)
  2020/10/05  RKC     Initial revision (CIMSV3-967)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Modify Layouts Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Layouts_Modify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
              (FieldName,          ControlName,    UIControl,         FieldCaption,        FieldHint,     IsRequired,  DefaultValue,  SortSeq, DataTagType,  DataTagName,   FormName,   BusinessUnit)
      select  'RecordId',          'HiddenInput',  null,              null,                null,          0,           null,          0,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'ContextName',       'ReadOnlyText', null,              null,                null,          0,           null,          1,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'LayoutDescription', 'Text',         null,              null,                null,          0,           null,          2,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'UserId',            'Text',         null,              null,                null,          0,           null,          3,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'SortSeq',           'Integer',      null,              null,                null,          0,           null,          4,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits
union select  'DefaultSelectionName',
                                    null,          'DBLookupDropDown','Default Selection', null,          0,           null,          5,       'Data',       null,          @FormName,  BusinessUnit from vwBusinessUnits


Go
