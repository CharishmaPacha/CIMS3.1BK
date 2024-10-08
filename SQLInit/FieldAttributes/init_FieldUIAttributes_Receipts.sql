/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/01  RV      Added OpenReceipts_DD and CreateReceiptInvSKU_DD (FBV3-265)
  2021/05/04  SAK     Detail Links added for ReceiptNumber (HA-2723)
  2020/03/22  NB      ListLink on ReceiptNumber for AuditTrail Listing(HA-231)
  2020/03/20  OK      Added selections for InTransit and Received LPNs hyper links
                      Added DestinationFilter for LPNsReceived (CIMSV3-739)
  2020/02/17  AY      Add hyperlinks to LPNs
  2020/01/11  RT      Included Form for PrepareForSorting (JL-59)
  2019/12/31  RV      Initial Revision (CIMSV3-671)
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

select @ContextName = 'List.ReceiptHeaders',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown' ;

/*------------------------------------------------------------------------------*/
/* Field Attributes for Receipts Selections & Forms */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,          ControlName,           ReferenceCategory,      AllowMultiSelect, AttributeType)
      select 'ReceiptType',      'ReceiptType_DD',      'Receipt',              'Y',              'E'
union select 'ROH_UDF2',         'PalletSize_DD',       'PalletSize',           'N',              'L'

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
       select 'ReceiptTypeDesc',           '_MAPPEDFIELD_',     'ReceiptType'
 union select 'ReceiptStatusDesc',         '_MAPPEDFIELD_',     'ReceiptStatus'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Field Attributes only for Forms */
/*------------------------------------------------------------------------------*/
select @Category    = 'F' /* Form */;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,              UIControl,           DbSource,           DbsourceFilter,                     DbLookUpFieldName,    ReferenceValueField,  ReferenceDescriptionField, DbLookUpFieldList, AllowMultiSelect, DestinationContextName,            DestinationLayoutName)
      select  'Lane_DD',                'DBLookupDropDown',  'vwLocations',      'LocationType = ''C''',             'Location',           'Location',           'Location',                'Location',        'Y',              null,                              null
union select  'OpenReceipts_DD',        'DBLookupDropDown',  'vwReceiptHeaders', '(~INPUTFILTER_Warehouse~) and Status in (''I'', ''T'', ''R'', ''E'')',
                                                                                                                     'ReceiptNumber',      'ReceiptId',          'ReceiptNumber',           null,              'N',              'UserControl.SelectReceiptNumber', 'Standard'
union select  'CreateReceiptInvSKU_DD', 'DBLookupDropDown',  'vwReceiptDetails', null,                               'SKU',                'ReceiptDetailId',    'SKU',                     null,              'N',              'UserControl.SelectReceiptSKU',    'Standard'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,      DestinationFilter,                      ReferenceValueField, ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'NumUnits',       'List.ReceiptDetails',  'Standard',            null,                          null,                                   'ReceiptId',         null,                       @UIControl, @ReferenceContext
union select 'LPNsInTransit',  'List.LPNs',            'Standard',            null,                          'LPNStatus = ''T''|Intransit LPNs',     'ReceiptId',         null,                       @UIControl, @ReferenceContext
union select 'LPNsReceived',   'List.LPNs',            'Standard',            null,                          'LPNStatus <> ''T''|Received LPNs',     'ReceiptId',         null,                       @UIControl, @ReferenceContext
--union select 'ReceiptNumber',  'List.ATEntity',        'Standard',            null,                          'EntityType=''Receipt''|Entity Type',   'ReceiptId',         'EntityId',                 @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,       ReferenceCategory,   UIControl,  ReferenceContext,  ReferenceValueField)
      select 'ReceiptNumber',  'RH_EntityInfo',     @UIControl, @ReferenceContext, 'ReceiptId'

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

Go
