/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/20  PKK     Added CartonizationModel (HA-2813)
  2021/03/18  RKC     Made changes to enable the Wave Entity info for all pages (HA-2318)
  2020/11/12  SAK     Added DestinationFilter for NumPicks (HA-1616)
  2020/07/29  NB      WaveDropLocation_DD..modified to add placeholders to present context sensitive values (HA-1242)
  2020/06/03  RKC     Added NumLPNs listlink (HA-587)
  2020/06/02  SK      Wave drop locations: Do not include Pause & Hold zones (HA-774)
  2020/05/29  TK      Added NumTasks (HA-691)
  2020/05/24  NB      Added Wave Summary Link on NumUnits(HA-101)
  2020/05/18  MS      Setup EntityInfo for Wave (HA-569)
  2020/05/15  TK      Correct List Links (HA-557)
  2020/05/15  RT      WaveDropLocation_DD: Made changes to get the dropdown (HA-437)
  2020/05/01  RT      Included InvAllocationModel (HA-312)
  2020/04/28  SV      Changes to show Wave's AT (HA-291)
  2020/04/23  SV      Added list link for AT (HA-231)
  2019/05/10  AY      Initial Revision
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

select @ContextName      = 'List.Waves',
       @Category         = 'SF', /* Selection & Forms */
       @UIControl        = 'DropDown';

/*------------------------------------------------------------------------------*/
/* Field Attributes for Wave Selections & Forms */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
            (FieldName,               ControlName,                ReferenceCategory,      AllowMultiSelect, AttributeType)
      select 'WaveType',              'WaveType_DD',              'Wave',                 'N',              'E'
union select 'WaveStatus',            'WaveStatus_DD',            'Wave',                 'Y',              'S'
union select 'InvAllocationModel',    'InvAllocationModel_DD',    'InvAllocationModel',   'N',              'L'
union select 'CartonizationModel',    'CartonizationModel_DD',    'CartonizationModel',   'N',              'L'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
            (FieldName,                    ReferenceCategory, ReferenceValueField)
      select 'WaveTypeDesc',               '_MAPPEDFIELD_',   'WaveType'
union select 'WaveStatusDesc',             '_MAPPEDFIELD_',   'WaveStatus'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Wave ReleaseForAllocation Form Field UI Attributes */
/*------------------------------------------------------------------------------*/
select @Category    = 'F' /* Form */;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,          ControlName,            UIControl,              DbSource,          DbsourceFilter,                                            DbLookUpFieldName,    DBLookupFieldList,  DestinationContextName,          DestinationLayoutName, ReferenceValueField,  ReferenceDescriptionField)
      select 'DropLocation',      'WaveDropLocation_DD',  'DBLookupDropDown',     'vwLocations',     '~INPUTFILTER_Warehouse~  and ~SELECTEDRECORDFILTER_Warehouse~ and (LocationType = ''S'') and (PutawayZone like ''Drop-~SELECTEDRECORDVALUE_WaveType~%'')',
                                                                                                                                                                'Location',           null,               'UserControl.SelectLocation',    'Standard',            'Location',           'Location'

exec pr_Setup_FieldUIAttributes null, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityDetail';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, ReferenceValueField, UIControl,  ReferenceContext)
      select 'SKU',        'SKU',             'SKUId',             @UIControl, @ReferenceContext
union select 'Pallet',     'PAL',             'PalletId',          @UIControl, @ReferenceContext
union select 'Location',   'LOC',             'LocationId',        @UIControl, @ReferenceContext

-- exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

/*------------------------------------------------------------------------------*/
/* Detail Links */
/*------------------------------------------------------------------------------*/
delete from @ttFieldUIAttributes;

select @UIControl        = 'DetailLink',
       @ReferenceContext = '/Home/EntityInfo';

insert into @ttFieldUIAttributes
             (FieldName,   ReferenceCategory, UIControl,  ReferenceContext,  ReferenceValueField)
      select 'WaveNo',     'Wave_EntityInfo', @UIControl, @ReferenceContext, 'WaveId'

/* Context for mapped fields should be null so that they are applicable in all contexts */
exec pr_Setup_FieldUIAttributes null, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'ID' /* Action - Insert */, 'DL' /* Reference: Detail Links */;

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
             (FieldName,              DestinationContextName, DestinationLayoutName,  DestinationSelectionName,  DestinationFilter,                            ReferenceValueField, ReferenceDescriptionField,  UIControl,  ReferenceContext)
      select 'NumOrders',             'List.Orders',          'Standard',             null,                      null,                                         'PickBatchNo',       null,                       @UIControl, @ReferenceContext
union select 'NumLines',              'List.OrderDetails',    'Standard',             null,                      null,                                         'PickBatchNo',       null,                       @UIControl, @ReferenceContext
union select 'LPNsAssigned',          'List.LPNs',            'Standard',             null,                      'LPNType = ''S''|Shipping Cartons',           'PickBatchNo',       null,                       @UIControl, @ReferenceContext
union select 'NumTasks',              'List.PickTasks',       'Standard',             null,                      null,                                         'WaveId',            null,                       @UIControl, @ReferenceContext
union select 'NumPicks',              'List.PickTaskDetails', 'Standard',             null,                      'TaskDetailStatus <> ''X''|Canceled',         'WaveNo',            null,                       @UIControl, @ReferenceContext
union select 'NumLPNs',               'List.LPNs',            'Standard',             null,                      'LPNType <> ''S''|',                          'PickBatchNo',       null,                       @UIControl, @ReferenceContext
union select 'PercentPicksComplete',  'List.PickTasks',       'Standard',             null,                      'TaskStatusGroup = ''Open''|Open Tasks',      'WaveNo',            null,                       @UIControl, @ReferenceContext
union select 'NumUnits',              'List.WaveSummary',     'Standard',             null,                      null,                                         'WaveNo',            null,                       @UIControl, @ReferenceContext

exec pr_Setup_FieldUIAttributes @ContextName, 'A' /* Category - Hyper link */, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'LL' /* Reference: List Links */;

Go
