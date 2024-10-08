/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

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

select @ContextName = 'List.Controls',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Entity Type Fields for Selection */
/*------------------------------------------------------------------------------*/
select @Category    = 'S', /* Selection */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,           ControlName,                 ReferenceCategory,      ReferenceDescriptionField,   AllowMultiSelect, AttributeType)
      select 'DataType',         'DataType_DD',                'Data',                 null,                        'N',              'E'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,                   ReferenceCategory,   ReferenceValueField)
      select 'DataTypeDescription',        '_MAPPEDFIELD_',     'DataType'

/* Context for mapped fields should be null so that they are applicable in all contexts */
exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

Go
