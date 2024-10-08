/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/23  SV      Added list link for AT (HA-231)
  2020/01/30  MS      Removed Pickers_DD (CIMSV3-561)
  2019/05/29  AY      Initial Revision
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

select @ContextName      = 'List.PickTasks',
       @Category         = 'S', /* Selection */
       @UIControl        = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,               ReferenceCategory,  ReferenceValueField)
       select 'TaskStatusDesc',        '_MAPPEDFIELD_',    'TaskStatus'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'I' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityDetail';

insert into @ttFieldUIAttributes
             (FieldName,              ReferenceCategory,  ReferenceValueField,  UIControl,  ReferenceContext)
      select 'SKU',                   'SKU',              'SKUId',              @UIControl, @ReferenceContext
union select 'Pallet',                'PAL',              'PalletId',           @UIControl, @ReferenceContext
union select 'Location',              'LOC',              'LocationId',         @UIControl, @ReferenceContext

--exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
             (FieldName,    DestinationContextName,  DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,                      ReferenceValueField,  ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'DetailCount', 'List.PickTaskDetails',  'Standard',             null,                      null,                                   'TaskId',             null,                       @UIControl, @ReferenceContext
union select 'TaskId',      'List.ATEntity',         'Standard',             null,                      'EntityType=''Task''|Entity Type',      null,                 'EntityId',                 @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'I' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

Go
