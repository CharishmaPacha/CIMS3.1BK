/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/10  SAK     Added ReplenishUoMDesc Dropdown (JL-285)
  2020/07/15  KBB     Corrected the UIControl name(HA-1145)
  2020/07/14  MS      Bug fix removed contextname for DBLookupDropDowns (HA-1143)
  2020/07/11  AY      Moved location DBLookups to this file and added several options
  2020/04/25  MS      Added LocationSubTypeDesc mapping (HA-263)
  2020/04/22  SV      Added list link for AT (HA-231)
  2020/03/11  MS      Initial Revision (CIMSV3-749)
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

select @ContextName = 'List.Locations',
       @Category    = 'SF', /* Selection */
       @UIControl   = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Lookup Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,           ControlName,                 ReferenceCategory,      ReferenceDescriptionField,   AllowMultiSelect, AttributeType)
      select 'ReplenishUoM',      'ReplenishUoM_DDMS',         'ReplenishUoM',         null,                        'Y',              'L'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;
/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,                   ReferenceCategory,   ReferenceValueField)
      select 'ReplenishUoMDesc',           '_MAPPEDFIELD_',     'ReplenishUoM'

/* Context for mapped fields should be null so that they are applicable in all contexts */
exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

insert into @ttFieldUIAttributes
            (FieldName,        DestinationContextName, DestinationLayoutName, DestinationSelectionName,  DestinationFilter,                       ReferenceValueField,    ReferenceDescriptionField,  UIControl,   ReferenceContext)
      select 'NumPallets',     'List.Pallets',         'Standard',            null,                      null,                                    'LocationId',           null,                       @UIControl,  @ReferenceContext
union select 'NumLPNs',        'List.LPNs',            'Standard',            null,                      null,                                    'LocationId',           null,                       @UIControl,  @ReferenceContext
union select 'Location',       'List.ATEntity',        'Standard',            null,                      'EntityType=''Location''|Entity Type',   'LocationId',           'EntityId',                 @UIControl,  @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;

/*------------------------------------------------------------------------------*/
/* DB Location look ups */
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,                  DbsourceFilter)
      select  'Locations_D_DD',             'LocationType = ''D'''
union select  'Locations_RBKS_DD',          'LocationType in (''R'', ''B'', ''K'', ''S'')'
union select  'Locations_RB_DD',            'LocationType in (''R'', ''B'')'
union select  'Locations_S_DD',             'LocationType = ''S'''
union select  'Locations_K_DD',             'LocationType = ''K'''
union select  'Locations_RecvStaging_DD',   'LocationType = ''S'' and PutawayZone like ''RecvStaging%'''
union select  'Locations_ShipStaging_DD',   'LocationType = ''S'' and PutawayZone like ''ShipStaging%'''
union select  'Locations_PickingDrop_DD',   'LocationType = ''S'' and PutawayZone like ''Drop%'''

/* Update the default fields */
update @ttFieldUIAttributes
set UIControl                 = 'DBLookupDropDown',
    DBSource                  = 'vwLocations',
    DBLookupFieldName         = 'Location',
    DBLookUpFieldList         = 'Location,LocationTypeDesc,Warehouse,PutawayZoneDesc,PickingZoneDesc',
    ReferenceValueField       = 'Location',
    ReferenceDescriptionField = 'Location';

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

Go
