/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/14  NB      Initial Revision(HA-320)
------------------------------------------------------------------------------*/

Go

declare @ContextName                TName,                                         /* Name of DB View, DB Table, Layout Context */
        @ttFieldUIAttributes        TFieldUIAttributes,
        @FieldName                  TName,                                         /* Name of Field in the DB View, DB Table, Layout Context */
        @Category                   TTypeCode,
        @ReferenceContext           TName,
        @ReferenceCategory          TName,
        @ReferenceCategoryField     TName,
        @ReferenceValueField        TName,
        @ReferenceDescriptionField  TName,
        @AllowMultiSelect           TFlag,
        @UIControl                  TName;

select @ContextName      = 'Maintenance_ImportFiles',
       @Category         = 'F', /* Form */
       @UIControl        = 'DropDown';

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,         ControlName,             ReferenceCategory, AllowMultiSelect, AttributeType)
     select 'ImportFileType',   null,                    'ImportFileType',  'N',              'L'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

Go
