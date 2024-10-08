/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/02  AY      Initial Revision(HA-2849)
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
        @UIControl                  TTypeCode;

select @ContextName = 'List.BoLs',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;


--exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

/*------------------------------------------------------------------------------*/
/* BoL related controls for forms */
/*------------------------------------------------------------------------------*/
select @Category    = 'F', /* Forms */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,               ReferenceCategory,        ReferenceDescriptionField,   AllowMultiSelect,  AttributeType)
      select  'BoLFreightTerms_DD',      'BoLFreightTerms',        null,                        'N',               'L'
union select  'BoLFreightTerms_DDMS',    'BoLFreightTerms',        null,                        'Y',               'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and  Insert */;

Go
