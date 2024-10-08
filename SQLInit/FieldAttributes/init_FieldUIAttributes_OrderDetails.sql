/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/15  RV      OrderDetailKits_DD: Show kits only units allocate greater than zero to create kits (HA-1434)
  2020/09/08  RV      Added OrderDetailKits to get the OrderDetails of the selected order (HA-1239)
  2020/05/19  MS      Commented EntityInfo (HA-568)
  2019/06/22  AY      Initial Revision
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

select @ContextName = 'List.OrderDetails',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;
/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Create Kits Form Field UI Attributes */
/*------------------------------------------------------------------------------*/
select @Category    = 'F' /* Form */;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,           ControlName,            UIControl,              DbSource,          DbsourceFilter,                                            DbLookUpFieldName,    DBLookupFieldList,  DestinationContextName,             DestinationLayoutName, ReferenceValueField,  ReferenceDescriptionField)
      select 'OrderDetailKits',    'OrderDetailKits_DD',   'DBLookupDropDown',     'vwOrderDetails',  '(OrderId = ''~SELECTEDRECORDVALUE_OrderId~'') and (LineType = ''A'') and (UnitsToAllocate > 0)',
                                                                                                                                                                 'SKU',                null,               'UserControl.SelectOrderDetailKit', 'Standard',            'OrderDetailId',      'SKU'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

Go
