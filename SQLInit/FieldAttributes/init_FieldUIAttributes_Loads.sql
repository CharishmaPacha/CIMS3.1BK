/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/21  SK      Added BOD_GroupCriteria_DD (HA-2676)
  2021/03/31  KBB     Added BoLStatus_DD (HA-2467)
  2021/03/12  AY      Changed Consolidator_DD to use AddressBrief view (HA GoLive)
                      Setup hyperlink to Loads from LoadNumber in all pages
  2021/02/25  NB      changes RowsPerPage to 20 for ConsolidatorAddress_DD (HA-2067)
  2021/02/17  AY      Setup hyperlink from LoadNumber in all places to Loads Entity Info page (BK-176)
  2020/10/27  RKC     Added LoadStagingLocation_DBDD (HA-1280)
  2020/08/11  MS      Bug fix UIControl corrected and removed contextname for DBLookupropdown
  2020/08/07  SAK     Added LoadWarehouse_DBDD Controls (HA-1279)
  2020/08/07  HYP     Added LoadDockLocation_DBDD Control (HA-1281)
  2020/07/31  NB      Added LoadLabelPrinter_DBDD, LoadReportPrinter_DBDD(HA-1269)
  2020/07/27  AJM     Hyperlink to Pallets (HA-1168)
  2020/07/18  OK      Added DeliveryRequestType_DD (HA-1147)
  2020/07/15  RKC     Added StagingLocation_DD, LoadingMethod_DD, LoadingMethod_DDMS (HA-1106)
  2020/06/25  KBB     Added ControlName BillToAddressId_DD (HA-986)
  2020/06/23  KBB     Added ControlName FOB in Forms (HA-986)
  2020/06/14  AY      Hyperlink to LPNs (HA-920)
  2020/06/08  RT      Included Detail Link as Load (HA-824)
  2020/06/06  AY      Setup LoadType, LoadStatus, RoutingStatus controls
  2020/04/23  SV      Initial Revision (HA-231)
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

select @ContextName      = 'List.Loads',
       @UIControl        = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Types, Statuses & LookUps - Selections */
/*------------------------------------------------------------------------------*/
select @Category = 'S'; /* Selections */
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,         ControlName,             ReferenceCategory, ReferenceDescriptionField, AllowMultiSelect, AttributeType)
      select 'LoadType',        'LoadType_DDMS',         'Load',            null,                      'Y',              'E'
union select 'LoadStatus',      'LoadStatus_DDMS',       'Load',            null,                      'Y',              'S'
union select 'RoutingStatus',   'RoutingStatus_DDMS',    'LoadRouting',     null,                      'Y',              'S'
union select 'LoadingMethod',   'LoadingMethod_DDMS',    'LoadingMethod',   null,                      'Y',              'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Types, Statuses & LookUps - Forms */
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (ControlName,              ReferenceCategory,     AllowMultiSelect, AttributeType)
      select 'LoadType_DD',            'Load',                'N',              'E'
union select 'LoadStatus_DD',          'Load',                'N',              'S'
union select 'RoutingStatus_DD',       'LoadRouting',         'N',              'S'
union select 'FoB_DD',                 'FoB',                 'N',              'L'
union select 'LoadingMethod_DD',       'LoadingMethod',       'N',              'L'
union select 'DeliveryRequestType_DD', 'DeliveryRequestType', 'N',              'L'
union select 'BoLStatus_DD',           'BoLStatus',           'N',              'S'
union select 'BOD_GroupCriteria_DD',   'BOD_GroupCriteria',   'N',              'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
select @Category = 'SF'; /* Selection & Forms */

delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
  In this case, the column filter must be added with the respective code field, instead of description field
  The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
            (FieldName,                   ReferenceCategory,   ReferenceValueField)
      select 'LoadTypeDesc',              '_MAPPEDFIELD_',     'LoadType'
union select 'LoadStatusDesc',            '_MAPPEDFIELD_',     'LoadStatus'
union select 'RoutingStatusDesc',         '_MAPPEDFIELD_',     'RoutingStatus'

/* Context for mapped fields should be null so that they are applicable in all contexts */
exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* BOL modify Form Field UI Attributes */
/*------------------------------------------------------------------------------*/
select @Category    = 'F' /* Form */;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,             UIControl,           DbSource,           DbsourceFilter,     DbLookUpFieldName,    DBLookupFieldList,               DestinationContextName,                 DestinationLayoutName,  ReferenceValueField,  ReferenceDescriptionField)
      select  'BillToAddressId_DD',    'DBLookupDropDown',  'vwBillToAddress' , 'Status=''A''',     'Name',               null,                            'UserControl.SelectAddress',            'Standard',             'ContactId',    'Name'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Links to Lists */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'ListLink',
       @ReferenceContext = '/Home/List';

/* For the record with WaveNo as FieldName, we can use WaveId/PickBatchId as ReferenceValueField rather than RecordId.
   But the functionality of linked list is purily depedens over the FieldVisibility value in the LayoutFields and Visible value
   in the Fields table. For the current configuration of the respective field visibilities taken RecordId into consideration. */

insert into @ttFieldUIAttributes
             (FieldName,              DestinationContextName, DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,                       ReferenceValueField, ReferenceDescriptionField,  UIControl,  ReferenceContext)
--      select 'NumOrders',             'List.Orders',          'Standard',             null,                      null,                                    'LoadId',            null,                       @UIControl, @ReferenceContext
      select 'NumLPNs',               'List.LPNs',            'Standard',             null,                      null,                                    'LoadId',            null,                       @UIControl, @ReferenceContext
union select 'NumPallets',            'List.Pallets',         'Standard',             null,                      null,                                    'LoadId',            null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,       ReferenceCategory,   UIControl,  ReferenceContext,  ReferenceValueField)
      select 'LoadNumber',    'Load_EntityInfo',    @UIControl, @ReferenceContext, 'LoadId'

exec pr_Setup_FieldUIAttributes null, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* DB look ups */
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (ControlName,                  DbSource,           DbsourceFilter,     DbLookUpFieldName,         DBLookupFieldList,               DestinationContextName,          DestinationLayoutName,  ReferenceValueField,  ReferenceDescriptionField, RowsPerPage)
      select 'ConsolidatorAddress_DD',     'vwContacts' ,      'ContactType = ''FC'' and Status=''A''',
                                                                                   'Name',                    null,                            'UserControl.SelectAddressBrief','Standard',             'ContactRefId',       'Name',                    20
insert into @ttFieldUIAttributes
            (ControlName,                  DbSource,           DbsourceFilter,     DbLookUpFieldName,         DBLookupFieldList,               DestinationContextName,          DestinationLayoutName,  ReferenceValueField,  ReferenceDescriptionField)
      select 'LoadLabelPrinter_DBDD',      'vwPrinters',       '((Warehouse is null) or ~INPUTFILTER_FromWarehouse_Warehouse~) and PrinterType=''Label'' and Status = ''A''',
                                                                                   'DeviceName',              'DeviceId,DeviceName',           null,                            null,                   'DeviceId',           'DeviceName'
union select 'LoadReportPrinter_DBDD',     'vwPrinters',       '((Warehouse is null) or ~INPUTFILTER_FromWarehouse_Warehouse~) and PrinterType=''Report'' and Status = ''A''',
                                                                                   'DeviceName',              'DeviceId,DeviceName',           null,                            null,                   'DeviceId',           'DeviceName'
/* To be Displayed in Load's page/actions Dropdowns */
union select 'LoadWarehouse_DBDD',         'vwLookups',        '~INPUTFILTER_FromWarehouse_LookupCode~ and LookupCategory=''Warehouse'' and Status = ''A''',
                                                                                   'LookupDisplayDescription','LookupCode,LookupDisplayDescription',
                                                                                                                                               null,                            null,                   'LookupCode',         'LookupDisplayDescription'
union select 'LoadDockLocation_DBDD',      'vwLocations',      '~INPUTFILTER_FromWarehouse_Warehouse~ and LocationType = ''D''',
                                                                                   'Location',                'Location',                      null,                            null,                   'Location',           'Location'
union select 'LoadStagingLocation_DBDD',   'vwLocations',      '~INPUTFILTER_FromWarehouse_Warehouse~ and LocationType = ''S'' and PutawayZone like ''ShipStaging%''',
                                                                                   'Location',                'Location',                      null,                            null,                   'Location',           'Location'

update @ttFieldUIAttributes set UIControl = 'DBLookupDropDown';

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

Go
