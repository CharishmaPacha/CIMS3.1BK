/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/15  RV      SKUImageURL: Added Preview Link (BK-916)
  2020/11/10  SAK     Added PutawayClassDesc to bind values from DropDowns (JL-285)
  2020/04/06  OK      Changes to use V3 status fields instead of V2 fields (HA-132)
  2019/05/27  RIA     Code clean up (CIMSV3-219)
  2019/05/26  RIA     Changes to bind values from DropDowns (CIMSV3-219)
  2019/05/25  AY      Changed to use control name
  2019/03/10  AY      Initial Revision
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

select @ContextName = 'List.SKUs',
       @Category    = 'SF', /* Selection & Forms */
       @UIControl   = 'DropDown' ;

/*------------------------------------------------------------------------------*/
/* EntityTypes */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* LookUps */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,           ControlName,                 ReferenceCategory,      ReferenceDescriptionField,   AllowMultiSelect, AttributeType)
      select 'ReplenishClass',     'ReplenishClass_DDMS',       'ReplenishClasses',     null,                        'Y',              'L'
union select 'PutawayClass',       'PAClass_DDMS',              'PutawayClasses',       null,                        'Y',              'L'
union select 'ABCClass',           'ABCClass_DDMS',             'ABCClasses',           null,                        'Y',              'L'
union select 'ProdCategory',       'ProductCategory_DDMS',      'ProductCategory',      null,                        'Y',              'L'
union select 'ProdSubCategory',    'ProductSubCategory_DDMS',   'ProductSubCategory',   null,                        'Y',              'L'
/* MS: When null is passed as FieldName but ContextName is defined, We are getting ObjectReference error, 
   hence passing empty in field, this has to be Revisited to correct properly */
union select '',                   'ReplenishClass_DD',         'ReplenishClasses',     null,                        'N',              'L'
union select '',                   'PAClass_DD',                'PutawayClasses',       null,                        'N',              'L'
union select '',                   'ABCClass_DD',               'ABCClasses',           null,                        'N',              'L'
union select '',                   'ProductCategory_DD',        'ProductCategory',      null,                        'N',              'L'
union select '',                   'ProductSubCategory_DD',     'ProductSubCategory',   null,                        'N',              'L'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Statuses */
/*------------------------------------------------------------------------------*/
select @Category    = 'S', /* Selection */
       @UIControl   = 'DropDown';
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,          ReferenceCategory,  AllowMultiSelect)
      select 'SKUStatus',         'Status',           'Y'
union select 'OnhandStatus',      'Onhand',           'Y'
union select 'InventoryStatus',   'Inventory',        'Y'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'S' /* Reference: Status */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
select @Category = 'SF'; /* Selection & Forms */

delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,          ReferenceCategory,  ReferenceValueField)
      select 'SKUStatusDesc',     '_MAPPEDFIELD_',    'SKUStatus'
union select 'PutawayClassDesc',       '_MAPPEDFIELD_',    'PutawayClass'
union select 'ProdCategoryDesc',       '_MAPPEDFIELD_',    'ProdCategory'
union select 'ProdSubCategoryDesc',    '_MAPPEDFIELD_',    'ProdSubCategory'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityDetail';

insert into @ttFieldUIAttributes
             (FieldName,          ReferenceCategory,  UIControl,  ReferenceContext,  ReferenceValueField)
      select 'SKU',               'SKU',              @UIControl, @ReferenceContext, 'SKUId'

--exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

-- insert into @ttFieldUIAttributes
--              (FieldName,   DestinationContextName, DestinationLayoutName, ReferenceValueField, UIControl,  ReferenceContext)
--       select 'Pallet',    'List.Pallets',          'Standard',            'PalletId',          @UIControl, @ReferenceContext

--exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'I' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to preview sku image */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @Category  = 'A', /* Hyperlink */
       @UIControl = 'PreviewLink';

insert into @ttFieldUIAttributes
               (FieldName,        ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
       select  'SKUImageURL',     null,                   null,                       @UIControl,  dbo.fn_Controls_GetAsString('SKU', 'ImageURLPath', '', BusinessUnit, '' /* UserId */) from vwBusinessUnits

exec pr_Setup_FieldUIAttributes @ContextName, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'PL' /* Reference: Preview Links */;

Go
