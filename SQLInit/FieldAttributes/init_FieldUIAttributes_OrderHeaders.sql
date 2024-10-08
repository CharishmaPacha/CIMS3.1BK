/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/16  RV      Added notes link for HasNotes (OB2-1883)
  2020/06/23  OK      Changed PickTicket Detail link to applicable to all contexts (HA-707)
  2020/06/15  AY      Added mapping for OrderTypeDesc
  2020/06/03  RKC     Added NumLPNs listlink (HA-587)
  2020/05/17  MS      Consider PickTicket as Detailed Link (HA-568)
  2020/05/09  MS      Setup OrderStatus
  2020/05/04  SV      Added list link for AT (HA-231)
  2018/12/18  MS      Changes to use Controlnames (cIMSV3-424)
  2018/03/10  NB      Minor changes to EntityInfo Detail link(CIMSV3-151)
  2018/01/25  NB      Initial Revision
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

select @ContextName = 'List.Orders',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
insert into @ttFieldUIAttributes
             (FieldName,              ControlName,           ReferenceCategory,     AllowMultiSelect,  AttributeType)
      select 'OrderType',             'OrderType_DD',        'Order',               'Y',               'E'
union select 'CarrierOptions',        'CarrierOptions_DD',   'CarrierOptions',      'N',               'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @Category = 'SF'; /* Selection */

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,                   ReferenceCategory,   ReferenceValueField)
      select 'OrderTypeDescription',       '_MAPPEDFIELD_',     'OrderType' -- deprecated
union select 'OrderTypeDesc',              '_MAPPEDFIELD_',     'OrderType'
union select 'OrderStatusDesc',            '_MAPPEDFIELD_',     'OrderStatus'

/* When context is null, they apply to all contexts */
exec pr_Setup_FieldUIAttributes null/* Context */, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'PickTicket', 'OH_EntityInfo',   @UIControl, @ReferenceContext, 'OrderId'

exec pr_Setup_FieldUIAttributes null/* Context */, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,      DestinationFilter,                            ReferenceValueField,    ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'NumUnits',       'List.OrderDetails',    'Standard',            null,                          null,                                         'OrderId',              null,                       @UIControl, @ReferenceContext
union select 'LPNsAssigned',   'List.LPNs',            'Standard',            null,                          'LPNType = ''S''|Shipping Cartons',           'OrderId',              null,                       @UIControl, @ReferenceContext
union select 'NumLPNs',        'List.LPNs',            'Standard',            null,                          'LPNType <> ''S''|',                          'OrderId',              null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to notes */
/*------------------------------------------------------------------------------*/

delete from @ttFieldUIAttributes;

select @UIControl        = 'NotesLink',
       @ReferenceContext = 'Entity/GetNotes';

insert into @ttFieldUIAttributes
             (FieldName, ReferenceDescriptionField,   ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'HasNotes', 'Y',                         'Order',           @UIControl, @ReferenceContext, 'OrderId'

exec pr_Setup_FieldUIAttributes null/* Context */, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;


Go
