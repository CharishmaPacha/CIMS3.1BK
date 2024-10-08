/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  AY      Pallet Status/Type not selectable in all contexts where Pallets are shown (HA GoLive)
  2020/06/03  MS      Category change for Dropdowns (HA-805)
  2020/05/16  RKC     Added PalletLabelFormat_DD (HA-447)
  2020/04/22  SV      ListLink on ReceiptNumber for AuditTrail Listing (HA-231)
  2020/03/19  RT      Changed LPNTypeforCart to LPNTypeForCart (CIMSV3-697)
  2020/03/11  MS      Changes to show palletstatus in dropdown (JL-111)
  2020/02/19  RIA     Changes to address Index was outside the bounds of the array (CIMSV3-694)
  2020/02/13  RIA     Added LPNTypeforCart_DD, PalletLPNFormat_DD, PalletType_DD, CartType_DD (CIMSV3-694)
  2020/02/02  RIA     Added PalletFormat_DD, CartFormat_DD (CIMSV3-694)
  2017/10/20  NB      Initial Revision(CIMSV3-82)
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

select @ContextName      = 'List.Pallets',
       @Category         = 'SF', /* Selection */
       @UIControl        = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
insert into @ttFieldUIAttributes
            (FieldName,               ControlName,             ReferenceCategory,        AllowMultiSelect, AttributeType)
      select 'PalletFormat',          'PalletFormat_DD',       'PalletFormat_I',         'N',              'L'
union select 'CartFormat',            'CartFormat_DD',         'PalletFormat_C',         'N',              'L'
union select 'LPNTypeForCart',        'LPNTypeForCart_DD',     'LPNTypeForCart',         'N',              'L'
union select 'CartPositionFormat',    'CartPositionFormat_DD', 'PalletLPNFormat',        'N',              'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Entities */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,           ControlName,           ReferenceCategory,        AllowMultiSelect)
      select 'PalletType',        'PalletType_DD',       'Pallet',                 'Y'
union select 'PalletTypeGen',     'PalletTypeGen_DD',    'PalletTypeGen',          'N'
union select 'CartTypeGen',       'CartTypeGen_DD',      'CartTypeGen',            'N'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'E' /* Reference: EntityType */;

/*------------------------------------------------------------------------------*/
/* Pallet Generate Form Field UI Attributes */
/*------------------------------------------------------------------------------*/
select @Category    = 'F' /* Form */;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,               UIControl,              DbSource,            DbsourceFilter,             DbLookUpFieldName,   DBLookupFieldList,  DestinationContextName,          DestinationLayoutName, ReferenceValueField,  ReferenceDescriptionField)
      select  'PalletLabelFormat_DD',    'DBLookupDropDown',     'vwLabelFormats',    'EntityType = ''Pallet'' and status = ''A''',
                                                                                                                  'LabelFormatName',   'LabelFormatName',   null,                           null,                  'LabelFormatName',    'LabelFormatName'
exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
select @Category = 'SF'; /* Selection */

delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
            (FieldName,               ReferenceCategory,  ReferenceValueField)
      select 'PalletTypeDesc',        '_MAPPEDFIELD_',    'PalletType'
union select 'PalletStatusDesc',      '_MAPPEDFIELD_',    'PalletStatus'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

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

--exec pr_Setup_FieldUIAttributes @ContextName, 'A'DetailLink /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
             (FieldName,  DestinationContextName,  DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,                     ReferenceValueField,  ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'NumLPNs',   'List.LPNs',             'Standard',             null,                      null,                                  'PalletId',           null,                       @UIControl, @ReferenceContext
union select 'Pallet',    'List.ATEntity',         'Standard',             null,                      'EntityType=''Pallet''|Entity Type',   'PalletId',           'EntityId',                 @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'I' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

Go
