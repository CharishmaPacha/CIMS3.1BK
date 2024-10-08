/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/03  VS      Added Hyperlink for LPN.Quantity (HA-2714)
  2021/03/05  SJ      Initial Revision
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

select @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @ContextName      = 'Wave_EntityInfo_Orders',
       @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,      DestinationFilter,                            ReferenceValueField,    ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'NumUnits',       'List.OrderDetails',    'Standard',            null,                          null,                                         'OrderId',              null,                       @UIControl, @ReferenceContext
union select 'LPNsAssigned',   'List.LPNs',            'Standard',            null,                          'LPNType = ''S''|Shipping Cartons',           'OrderId',              null,                       @UIControl, @ReferenceContext
union select 'NumLPNs',        'List.LPNs',            'Standard',            null,                          'LPNType <> ''S''|',                          'OrderId',              null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to LPN.Quantity */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @ContextName = 'Wave_EntityInfo_LPNs';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,      DestinationFilter,                            ReferenceValueField,    ReferenceDescriptionField,  UIControl,  ReferenceContext)
     select 'Quantity',       'List.LPNDetails',      'Standard',             null,                          null,                                         'LPNId',                null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

Go
