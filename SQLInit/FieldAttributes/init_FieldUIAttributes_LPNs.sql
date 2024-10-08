/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/24  RV      Added TrackingNo for tracking information (BK-277)
  2021/03/24  MS      Added RegenerateTrackingNo_DD (HA-2410)
  2020/07/12  OK      Added RC_LPNCreateInv_DD, LPNTypeCreateInv, GeneratePalletOptions_DD
                      Changes to display Label format description in control LPNLabelFormat_DD (HA-1272)
  2020/07/21  TK      Added RC_TransferInv_DD (HA-1186)
  2020/07/01  SJ      Removed Warehouse Dropdown details for LPNs page (HA-1045)
  2020/05/20  MS      Changes to use LPNStatusDesc (HA-604)
  2020/05/16  RKC     Added LPNLabelFormat_DD (HA-447)
  2020/05/07  SV      Added RC_UpdateInvCategories_DD (HA-420)
  2002/05/06  YJ      Added changes to show LookUpDisplayDescription for DestWarehouse (HA-411)
  2020/04/21  AY      Added list link for AT (HA-231)
  2020/04/15  MS      Added RC_LPNAdjust_DD (HA-181)
  2020/03/11  MS      Corrections to Onhand Status attribute (CIMSV3-748)
  2020/01/30  AY      Added different controls for LPNType for Modify and Generate (CIMSV3-697)
  2019/05/27  RIA     Changes for Dropdowns, data binding and file format (CIMSV3-211)
              AY      Changes to use new AttributeType in TFieldUIAttributes
  2019/05/26  AY      Change to ControlName
  2019/05/11  NB      Removed Status column, Replaced mapped field for Status with LPNStatus(CIMSV3-138)
  2017/11/16  NB      (CIMSV3-117)
                      Added FiedUIAttr to map TypeDescription to Type Code fields
                      Enabled Multi Selection for Status Columns
  2017/11/09  NB      Changed FieldUIAttr for Description fields to Map to Code fields(CIMSV3-117)
  2017/10/18  NB      Added DetailLink attributes(CIMSV3-82)
  2017/10/11  NB      Added DropDown attributes for Description columns to display list in column filter (CIMSV3-84)
  2017/10/04  NB      Renamed ContextName to List.LPNs(CIMSV3-11)
  2017/08/XX  NB      Initial Revision
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

select @ContextName = 'List.LPNs',
       @Category    = 'SF', /* Selection & Forms */
       @UIControl   = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Atributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
insert into @ttFieldUIAttributes
            (FieldName,           ControlName,                 ReferenceCategory,      ReferenceDescriptionField,   AllowMultiSelect, AttributeType)
      select 'LPNType',           'LPNType_DDMS',              'LPN',                  null,                        'Y',              'E'
union select 'PutawayClass',      'LPNPutawayClass_DD',        'LPNPutawayClasses',    null,                        'N',              'L'
union select 'ReasonCode',        'RC_RevReceipt_DD',          'RC_RecvAdjust',        'LookUpDisplayDescription',  'N',              'L'
union select 'ReasonCode',        'RC_LPNAdjust_DD',           'RC_LPNAdjust',         'LookUpDisplayDescription',  'N',              'L'
union select 'ReasonCode',        'RC_LPNVoid_DD',             'RC_LPNVoid',           'LookUpDisplayDescription',  'N',              'L'
union select 'ReasonCode',        'RC_UpdateInvCategories_DD', 'RC_LPNAdjust',         'LookUpDisplayDescription',  'N',              'L'
union select 'ReasonCode',        'RC_TransferInv_DD',         'RC_TransferInv',       'LookUpDisplayDescription',  'N',              'L'
union select 'ReasonCode',        'RC_LPNCreateInv_DD',        'RC_LPNCreateInv',      'LookUpDisplayDescription',  'N',              'L'
/* LPNTypeModify is the limited set of LPNTypes used during creation of LPNs or modification of LPNType */
union select 'LPNTypeModify',     'LPNTypeModify_DD',          'LPNTypeForModify',     null,                        'N',              'L'
union select 'LPNTypeGenerate',   'LPNTypeGenerate_DD',        'LPNTypeForGenerate',   null,                        'N',              'L'
union select 'LPNTypeCreateInv',  'LPNTypeCreateInv_DD',       'LPNTypeForCreateInventory', 
                                                                                       null,                        'N',              'E'
--union select 'DestWarehouse',     'DestWarehouse_DD',          'Warehouse',            'LookUpDisplayDescription',  'N',              'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Field Attributes for Selection and Forms */
/*------------------------------------------------------------------------------*/
select @Category    = 'F', /* Forms */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;
insert into @ttFieldUIAttributes
            (ControlName,                ReferenceCategory,            ReferenceDescriptionField,   AllowMultiSelect, AttributeType)
      select 'PalletizationGroups_DD',   'PalletizationGroups',        null,                        'N',              'L'
union select 'GeneratePalletOptions_DD', 'GeneratePalletOptions',      null,                        'N',              'L'
union select 'RegenerateTrackingNo_DD',  'RegenerateTrackingNoOptions',null,                        'N',              'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Statuses */
/*------------------------------------------------------------------------------*/
select @Category    = 'SF', /* Forms */
       @UIControl   = 'DropDown' ;
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,         ControlName,             ReferenceCategory, AllowMultiSelect, AttributeType)
      select 'OnhandStatus',    'OnhandStatus_DDMS',     'Onhand',          'Y',              'S'
union select 'InventoryStatus', 'InventoryStatus_DDMS',  'Inventory',       'Y',              'S'

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
      select 'LPNTypeDescription',         '_MAPPEDFIELD_',     'LPNType'
union select 'LPNStatusDesc',              '_MAPPEDFIELD_',     'LPNStatus'
union select 'OnhandStatusDescription',    '_MAPPEDFIELD_',     'OnhandStatus'

/* Context for mapped fields should be null so that they are applicable in all contexts */
exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* LPNs Generate Form Field UI Attributes */
/*------------------------------------------------------------------------------*/
select @Category    = 'F' /* Form */;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,            UIControl,          DbSource,          DbsourceFilter,          DbLookUpFieldName,   DBLookupFieldList,  DestinationContextName,          DestinationLayoutName, ReferenceValueField,  ReferenceDescriptionField)
      select  'LPNLabelFormat_DD',    'DBLookupDropDown', 'vwLabelFormats',  'EntityType = ''LPN'' and status = ''A''',
                                                                                                      'LabelFormatName',   'LabelFormatName,LabelFormatDesc',
                                                                                                                                               null,                           null,                  'LabelFormatName',    'LabelFormatDesc'
exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityDetail';

insert into @ttFieldUIAttributes
            (FieldName,    ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'LPN',        'LPN',             @UIControl, @ReferenceContext, 'LPNId'
union select 'SKU',        'SKU',             @UIControl, @ReferenceContext, 'SKUId'
union select 'Pallet',     'PAL',             @UIControl, @ReferenceContext, 'PalletId'
union select 'Location',   'LOC',             @UIControl, @ReferenceContext, 'LocationId'

--exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,      DestinationFilter,                      ReferenceValueField,  ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'Pallet',         'List.Pallets',         'Standard',            null,                          null,                                   'PalletId',           null,                       @UIControl, @ReferenceContext
union select 'Quantity',       'List.LPNDetails',      'Standard',            null,                          null,                                   'LPNId',              null,                       @UIControl, @ReferenceContext
union select 'LPN',            'List.ATEntity',        'Standard',            null,                          'EntityType=''LPN''|Entity Type',       'LPNId',              'EntityId',                 @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Links to view the tracking info */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
select @Category  = 'A', /* Hyperlink */
       @UIControl = 'PreviewLink';

insert into @ttFieldUIAttributes
               (FieldName,        ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
       select  'TrackingNo',      'LPNId',                null,                       @UIControl,  'GETENTITYINFO_TRACKINGURL'

exec pr_Setup_FieldUIAttributes @ContextName, @Category /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'PL' /* Reference: Preview Links */;

Go
