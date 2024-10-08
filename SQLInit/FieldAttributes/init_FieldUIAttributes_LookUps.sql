/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/09  YJ       Separated LookUpCategory_DD to for both Selections & Forms (HA-862)
  2020/06/02  AY       Remove status - already defined in FieldUIAttributes_Generic
  2020/04/28  MS       Changes to select Statuses (HA-293)
  2020/04/16  AJM      Initial Revision (HA-91)
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

select @ContextName = 'List.LookUps',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;

/*------------------------------------------------------------------------------*/
/*  Field Attributes for LookUps Selections & Forms */
/*------------------------------------------------------------------------------*/
select @Category = 'S'; /* Selections */
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,         ControlName,             ReferenceCategory,   AllowMultiSelect, AttributeType)
      select 'LookUpCategory',  'LookUpCategory_DDMS',   'CategoryDesc',      'Y',              'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/*  Field Attributes for LookUps Selections & Forms */
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,         ControlName,             ReferenceCategory,   AllowMultiSelect, AttributeType)
      select 'LookUpCategory',  'LookUpCategory_DD',     'CategoryDesc',      'N',              'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,                   ReferenceCategory,   ReferenceValueField)
      select 'CategoryDesc',              '_MAPPEDFIELD_',     'LookUpCategory'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

Go
