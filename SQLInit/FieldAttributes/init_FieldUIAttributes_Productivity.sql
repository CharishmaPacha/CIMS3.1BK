/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/09  SK      Initial Revision (HA-2972)
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

select @ContextName = 'List.UserProductivity',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;


--exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,  DestinationFilter,                       ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
      select 'WaveTypeDesc',   'List.ATEntity',        'Standard',            null,                      'EntityType=''Wave''|Entity Type',       'WaveId',               'EntityId',                 @UIControl,  @ReferenceContext
union select 'NumUnits',       'List.ATEntity',        'Standard',            null,                      null,                                    'UserId',               null,                       @UIControl,  @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;


Go
