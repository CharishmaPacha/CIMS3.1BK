/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/18  OK      Added Contact_DD (HA-2317)
  2020/11/10  SAK     Initial Revision(JL-285)
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

select @ContextName = 'List.Contacts',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,               ControlName,             ReferenceCategory,  AllowMultiSelect, AttributeType)
      select  'ContactType',           'Contact_DDMS',          'Contact',          'Y',              'E'
union select  'ContactType',           'Contact_DD',            'Contact',          'N',              'E'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,                   ReferenceCategory,   ReferenceValueField)
      select 'ContactTypeDesc',            '_MAPPEDFIELD_',     'ContactType'

/* Context for mapped fields should be null so that they are applicable in all contexts */
exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

Go
