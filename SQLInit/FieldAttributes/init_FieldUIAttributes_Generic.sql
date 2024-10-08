/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/19  VM      Pickers_DD: Use FullNameUserName instead of Name to avoid ambiguity (OBV3-488)
  2022/02/28  SRP     Added UserName_DD (HA-2110)
  2021/07/09  SK      Added OperationType_DD (HA-2972)
  2021/07/08  NB      Added Users_DD (CIMSV3-1341)
  2021/05/07  AY      Added Integer1-100 & Integer1-9 (HA-2018)
  2021/04/13  TK      Display Warehouse specific printers (HA-2607)
  2021/03/12  AY      Changed Consolidator_DD to use AddressBrief view (HA GoLive)
  2021/02/23  KBB     Added Status_DBDD (CIMSV3-1215)
  2021/01/21  OK      Added WaveTypeToCreate_DD, WaveStatusToCreate_DD, WavePriority5-1 (HA-1910)
  2020/12/28  AJM     Added control LocAllowedOperations_CBDD (CIMSV3-1280)
  2020/12/03  PHK     Consolidator_DD: Added new control (HA_1020)
  2020/12/03  MRK     Changed ReferenceValueField from TaskStatus to TaskDetailStatus for TaskDetailStatusDesc (HA-1667)
  2020/12/01  RKC     ShipFrom_DD, ShipTo_DD: Changed the ReferenceValueField (HA-1714)
  2020/11/30  AY      Added controls for Percent fields (HA-1655)
  2020/11/17  SJ      Added control CartonGroup_DD (HA-1621)
  2020/10/26  SAK     Added Mapped Field for OwnershipDesc (JL-147)
  2020/10/12  NB      Added WarehouseCodes_CBDD (HA-1500)
  2020/09/10  SAK     Added DefaultFilterCondition_DD (CIMSV3-971)
  2020/09/01  NB      Added DateTimeFuture InputDateTime Generic FieldUIAttribute (HA-1303)
  2020/08/07  OK      Added CreateInvSKU_DD since SKU_DD value field is set to SKU and using SKUId in create inv form
                      Added CoO_DD and changed InventoryClass control to DBLookup from dropdown (HA-1272)
  2020/07/31  NB      Added GenericReportPrinter_DBDD(HA-1268),
  2020/07/30  NB      Added Warehouse_DBDD DBLookup for Warehouses(HA-1256)
  2020/07/24  PK      Pickers_DD: Changed where condition to consider PermissionName instead of Operation (HA-1208)
  2020/07/27  NB      Added EntityLabelFormat_DBDD, LPNLabelPrinter_DBDD and GenericLabelPrinter_DBDD(CIMSV3-1029)
  2020/07/24  PK      Pickers_DD: Changed DBSource & DBSourceFilter to use new view to display users who has
                       picking permissions (HA-1208)
  2020/07/22  HYP     ShipTo_DD: Changed the ReferenceValueField (HA-1020)
  2020/07/11  AY      Moved location DBLookups to respective file
  2020/07/09  TK      ReserveLocations_DD: Added (HA-1115)
  2020/07/07  AY      Warehouse_DD: Show LookUpDisplayDescription, DefaultWarehouse_DD: Added
  2020/07/06  SAK     Added Alignments_DD, DataTypes_DD, FieldTypes_DD (CIMSV3-971)
  2020/06/23  SAK/RV  Added ControlName ConsolidatorAddress_DD in DB look ups (HA-1001)
  2020/06/17  RV      ShipFrom_DD, ShipTo_DD: Corrected look up fields (HA-961)
  2020/06/16  YJ      SKU_DD corrected to show SKU value (HA-934)
  2020/06/12  NB      Added ReplenishType_CBDD(HA-368)
  2020/06/11  AY      Added StatusBitType (HA-862)
  2020/06/10  OK      Added ShipFrom_DD, ShipTo_DD, DockLocation_DD (HA-843)
  2020/06/09  NB      Added Warehouse_DDMS(CIMSV3-103)
  2020/06/08  YJ      Added FreightTerms_DD and changed Selection Status_DD to AllowMultiSelect 'Y' (HA-862)
  2020/06/05  AY      Changed the Status MultiSelect to SingleSelect (HA-513)
  2020/05/27  NB      Added ReplenishType_DD, SKU_DD(HA-368)
  2020/05/26  RT      Inlcuded PrinterName in the Dropdown (HA-603)
  2020/05/18  RKC     Added LabelPrinter_DD (HA-445)
  2020/05/15  RKC     Added StorageTypeDesc, LocationStatusDesc, LocationTypeDesc, LocationSubTypeDesc mappings (HA-451)
  2020/05/06  YJ      Added DataType_DD (CIMSV3-776)
  2020/04/25  MS      Added LocationSubType_DDMS (HA-263)
  2020/04/09  MS      Changes AttributeType for PutawayZone_DD & PickZone_DD (HA-151)
  2020/04/08  VS      IsActive_DD moved to Form Category (HA-96)
  2020/04/07  OK      Added SKUStatus_DDMS (HA-132)
  2020/04/06  NB      Pckers_DD changed to display name instead of user name (CIMSV3-561)
  2020/04/03  MS      Added Role_DD (CIMSV3-467)
  2020/03/31  MS      Added control for HiddenInput (CIMSV3-467)
  2020/03/30  TK      Added Boolean_DD & Boolean_DDMS (HA-69)
  2020/03/20  RV      Added LoadType_DD (CIMSV3-760)
  2020/03/11  MS      Added LocationStatus_DDMS (CIMSV3-749)
  2020/03/05  MS      Added Pickers_DD (cIMSV3-561)
  2019/12/18  MS      Controls Corrections (cIMSV3-424)
  2019/06/19  MS      Added ShipVia Control (cIMSV3-426)
  2019/06/13  MS      Added OrderType_DD, FreightTerms_DD & ReadOnlyText Controls (cIMSV3-422)
  2019/05/27  RIA     Added LPNFormat_DD (CIMSV3-211)
  2019/05/25  AY      Added Decimal, Integer and text controls
  2018/05/16  NB      Added WarehouseDropDown(CIMSV3-544)
  2018/05/08  NB      Initial Revision(CIMSV3-138)
------------------------------------------------------------------------------*/

Go

declare @ContextName                TName,                                         /* Name of DB View, DB Table, Layout Context */
        @ttFieldUIAttributes        TFieldUIAttributes,
        @Category                   TTypeCode,
        @UIControl                  TName;

select @ContextName = null; /* All the generic details would have no ContextName */

/*------------------------------------------------------------------------------*/
/* Common Lookup Fields */
/*------------------------------------------------------------------------------*/
select @Category    = 'SF', /* Selections and Forms */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,               ReferenceCategory,        ReferenceDescriptionField,   AllowMultiSelect)
      select  'Ownership_DD',            'Owner',                  null,                        'N'
union select  'Warehouse_DD',            'Warehouse',              'LookUpDisplayDescription',  'N'
union select  'Warehouse_DDMS',          'Warehouse',              null,                        'Y'
union select  'DefaultWarehouse_DD',     'UserDefaultWarehouse',   'LookUpDisplayDescription',  'N'
union select  'UoM_DD',                  'UoM',                    null,                        'N'
union select  'UoM_DDMS',                'UoM',                    null,                        'Y'
union select  'YesNo_DD',                'YesNo',                  null,                        'N'
union select  'YesNo_DDMS',              'YesNo',                  null,                        'Y'
union select  'Boolean_DD',              'Boolean',                null,                        'N'
union select  'Boolean_DDMS',            'Boolean',                null,                        'Y'
union select  'LPNFormat_DD',            'LPNFormat',              null,                        'N'
union select  'FreightTerms_DD',         'FreightTerms',           null,                        'N'
union select  'FreightTerms_DDMS',       'FreightTerms',           null,                        'Y'
union select  'OperationType_DD',        'Operation',              null,                        'N'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and  Insert */, 'L' /* Reference: LookUps */;

/*------------------------------------------------------------------------------*/
/* Status Fields Selection */
/*------------------------------------------------------------------------------*/
select @Category    = 'S', /* Selection */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,               ControlName,             ReferenceCategory,  AllowMultiSelect)
      select  'Status',                'Status_DD',             'Status',           'N'
union select  'RoleStatus',            'Status_DBDD',           'Status',           'N'
union select  'StatusBitType',         'StatusBT_DD',           'StatusBitType',    'N'
union select  'SKUStatus',             'SKUStatus_DDMS',        'Status',           'Y'
union select  'LPNStatus',             'LPNStatus_DDMS',        'LPN',              'Y'
union select  'LocationStatus',        'LocationStatus_DDMS',   'Location',         'Y'
union select  'PalletStatus',          'PalletStatus_DDMS',     'Pallet',           'Y'
union select  'OrderStatus',           'OrderStatus_DDMS',      'Order',            'Y'
union select  'ReceiptStatus',         'ReceiptStatus_DDMS',    'Receipt',          'Y'
union select  'TaskStatus',            'TaskStatus_DDMS',       'Task',             'Y'
union select  'TaskDetailStatus',      'TaskDetailStatus_DDMS', 'Task',             'Y'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - delete and Insert */, 'S' /* Reference: Status */;

/*------------------------------------------------------------------------------*/
/* Entity Type Fields for Selection */
/*------------------------------------------------------------------------------*/
select @Category    = 'S', /* Selection */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,               ControlName,             ReferenceCategory,  AllowMultiSelect)
      select  'LocationType',          'LocationType_DDMS',     'Location',         'Y'
union select  'StorageType',           'StorageType_DDMS',      'LocationStorage',  'Y'
union select  'LocationSubType',       'LocationSubType_DDMS',  'LocationSubType',  'Y'
union select  'TaskType',              'TaskType_DDMS',         'Task',             'Y'
union select  'PickTaskSubType',       'PickTaskSubType_DDMS',  'PickTaskSubType',  'Y'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */, 'E' /* Reference: Type */;

/*------------------------------------------------------------------------------*/
/* Lookups for Selection */
/*------------------------------------------------------------------------------*/
select @Category    = 'S', /* Selection */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (FieldName,               ControlName,             ReferenceCategory,       AllowMultiSelect)
      select  'Ownership',             'Ownership_DDMS',        'Owner',                 'Y'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - delete and Insert */, 'L' /* Reference: LookUps */;

/*------------------------------------------------------------------------------*/
/* Field Attributes for Forms */
/*------------------------------------------------------------------------------*/
select @Category    = 'F', /* Forms */
       @UIControl   = 'DropDown' ;

delete from @ttFieldUIAttributes;
insert into @ttFieldUIAttributes
            (ControlName,                  ReferenceCategory,            ReferenceDescriptionField,   AllowMultiSelect, AttributeType)
-- Location fields
      select 'LocationType_DD',            'Location',                   null,                        'N',              'E'
union select 'LocationSubType_DD',         'LocationSubType',            null,                        'N',              'E'
union select 'StorageType_DD',             'LocationStorage',            null,                        'N',              'E'
union select 'PutawayZone_DD',             'PutawayZones',               null,                        'N',              'L'
union select 'PickZone_DD',                'PickZones',                  null,                        'N',              'L'
-- Load
union select 'LoadType_DD',                'Load',                       null,                        'N',              'E'
-- Status
union select 'Status_DD',                  'Status',                     null,                        'N',              'S'
union select 'IsActive_DD',                'StatusBitType',              null,                        'N',              'S'
union select 'StatusBT_DD',                'StatusBitType',              null,                        'N',              'S'
-- Entity Types
union select 'ReplenishType_DD',           'Replenish',                  null,                        'Y',              'E'
-- Fields
union select 'Alignments_DD',              'Alignments',                 null,                        'N',              'L'
union select 'FieldTypes_DD',              'FieldTypes',                 null,                        'N',              'L'
union select 'DefaultFilterCondition_DD',  'FilterOperations',           null,                        'N',              'L'
union select 'AggregateMethod_DD',         'AggregateMethods',           null,                        'N',              'L'
union select 'FieldDisplayFormat_DD',      'FieldDisplayFormats',        null,                        'N',              'L'
-- LPN Fields
union select 'CoO_DD',                     'CoO',                        'LookUpDescription',         'N',              'L'
--CartonGroups
union select 'CartonGroup_DD',             'CartonGroups',               'LookUpDisplayDescription',  'N',              'L'
--Waves
union select 'WaveTypeToCreate_DD',        'CreateWave',                 null,                        'N',              'E'
union select 'WaveStatusToCreate_DD',      'GeneratePickBatch',          null,                        'N',              'S'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

/*------------------------------------------------------------------------------*/
/* Field Attributes for CheckBoxDropDown in Forms */
/*------------------------------------------------------------------------------*/
select @Category    = 'F', /* Forms */
       @UIControl   = 'CheckBoxDropDown' ;

delete from @ttFieldUIAttributes;
insert into @ttFieldUIAttributes
            (ControlName,                  ReferenceCategory,            ReferenceDescriptionField,   AllowMultiSelect, AttributeType, UIControl)
-- Entity Types
      select 'ReplenishType_CBDD',         'Replenish',                  null,                        'Y',              'E',           @UIControl
union select 'Warehouse_CBDD',             'Warehouse',                  null,                        'Y',              'L',           @UIControl
union select 'WarehouseCodes_CBDD',        'Warehouse',                  'LookUpDisplayDescription',  'Y',              'L',           @UIControl
union select 'LocAllowedOperations_CBDD',  'LocAllowedOperations',       'LookUpDisplayDescription',  'Y',              'L',           @UIControl

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

/*------------------------------------------------------------------------------*/
/* Mapped Fields */
/*------------------------------------------------------------------------------*/
select @Category    = 'SF'; /* Selections and Forms */

delete from @ttFieldUIAttributes;

/* Type description columns - at times user add filters from the column filters
   In this case, the column filter must be added with the respective code field, instead of description field
   The solution is to identify the mapped field name of the description column and add filter for the actual field */

insert into @ttFieldUIAttributes
             (FieldName,                   ReferenceCategory,   ReferenceValueField)
      select 'StatusDescription',          '_MAPPEDFIELD_',     'Status'
union select 'RoleStatusDesc',             '_MAPPEDFIELD_',     'RoleStatus'
union select 'OwnershipDesc',              '_MAPPEDFIELD_',     'Ownership'
/* Location */
union select 'LocationTypeDesc',           '_MAPPEDFIELD_',     'LocationType'
union select 'LocationSubTypeDesc',        '_MAPPEDFIELD_',     'LocationSubType'
union select 'StorageTypeDesc',            '_MAPPEDFIELD_',     'StorageType'
union select 'LocationStatusDesc',         '_MAPPEDFIELD_',     'LocationStatus'
/* Task */
union select 'TaskTypeDesc',               '_MAPPEDFIELD_',     'TaskType'
union select 'TaskSubTypeDesc',            '_MAPPEDFIELD_',     'TaskSubType'
union select 'PickTaskSubTypeDesc',        '_MAPPEDFIELD_',     'PickTaskSubType'
union select 'TaskStatusDesc',             '_MAPPEDFIELD_',     'TaskStatus'
union select 'TaskDetailStatusDesc',       '_MAPPEDFIELD_',     'TaskDetailStatus'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Insert */, 'M' /* Reference: Mapped Fields */;

/*------------------------------------------------------------------------------*/
/* Input Number Fields for Forms */
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,             UIControl,               DecimalPrecision,   MinValue,  MaxValue)
      select 'Decimal4',               'InputNumber',           4,                  0,         null
union select 'Decimal3',               'InputNumber',           3,                  0,         null
union select 'Decimal2',               'InputNumber',           2,                  0,         null
union select 'Decimal1',               'InputNumber',           1,                  0,         null
union select 'Integer',                'InputNumber',           0,                  null,      99999
union select 'Integer1-10',            'InputNumber',           0,                  1,         10
union select 'Integer1-100',           'InputNumber',           0,                  1,         100
union select 'IntegerMin0',            'InputNumber',           0,                  0,         99999
union select 'IntegerMin1',            'InputNumber',           0,                  1,         99999
union select 'Percent',                'InputNumber',           0,                  0,         1000
union select 'Percent1',               'InputNumber',           1,                  0,         1000
union select 'Percent2',               'InputNumber',           2,                  0,         1000
union select 'PercentMax100',          'InputNumber',           0,                  0,         100
union select 'PercentMax100-1',        'InputNumber',           1,                  0,         100
union select 'PercentMax100-2',        'InputNumber',           2,                  0,         100
union select 'WavePriority5-1',        'InputNumber',           1,                  1,         5

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

/*------------------------------------------------------------------------------*/
/* Input Text Fields for Forms */
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,             UIControl)
      select  'Text',                  'InputText'
union select  'ReadOnlyText',          'ReadOnlyText'
union select  'HiddenInput',           'HiddenInput'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

/*------------------------------------------------------------------------------*/
/* Date Text Fields for Forms */
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,             UIControl,                MinValue,  MaxValue)
      select  'DatePast',              'InputDate',              null,      0
union select  'DateFuture',            'InputDate',              0,         null
union select  'DateTimeFuture',        'InputDateTime',          0,         null
union select  'DateAny',               'InputDate',              null,      null

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

/*------------------------------------------------------------------------------*/
/* DB look ups */
/*------------------------------------------------------------------------------*/
select @Category = 'F'; /* Forms */

delete from @ttFieldUIAttributes;

insert into @ttFieldUIAttributes
             (ControlName,             UIControl,           DbSource,           DbsourceFilter,     DbLookUpFieldName,    DBLookupFieldList,               DestinationContextName,          DestinationLayoutName,  ReferenceValueField,  ReferenceDescriptionField)
      select  'CartonType_DD',         'DBLookupDropDown',  'vwCartonTypes',    'Status=''A''',     'DisplayDescription', null,                            'UserControl.SelectCartonType',  'Standard',             'CartonType',         'Description'
union select  'ShipVia_DD',            'DBLookupDropDown',  'vwShipVias',       'Status=''A''',     'Description',        null,                            'UserControl.SelectShipVia',     'Standard',             'ShipVia',            'Description'
union select  'Pickers_DD',            'DBLookupDropDown',  'vwUserRolePermissions',
                                                                                'PermissionName = ''RFPicking'' and IsAllowed = 1',
                                                                                                    'FullNameUserName',  'FullNameUserName,UserName',      null,                             null,                  'UserName',           'FullNameUserName'
union select  'Users_DD',              'DBLookupDropDown',  'vwUsers',          'IsActive = 1',     'FullNameUserName',  'FullNameUserName,UserId',        null,                             null,                  'UserId',             'FullNameUserName'
union select  'UserName_DD',           'DBLookupDropDown',  'vwUsers',          'IsActive = 1',     'FullNameUserName',  'FullNameUserName,UserName',      null,                             null,                  'UserName',           'FullNameUserName'
union select  'Role_DD',               'DBLookupDropDown',  'vwRoles',          'IsActive = 1',     'Description',       'Description,RoleId',             null,                             null,                  'RoleId',             'Description'
union select  'LabelPrinter_DD',       'DBLookupDropDown',  'vwPrinters',       '((Warehouse is null) or ~INPUTFILTER_Warehouse~) and Status = ''A'' and PrinterType = ''Label''',
                                                                                                    'PrinterName',       'PrinterName,PrinterDescription', null,                             null,                  'PrinterName',        'PrinterDescription'
union select  'ReportPrinter_DD',      'DBLookupDropDown',  'vwPrinters',       '((Warehouse is null) or ~INPUTFILTER_Warehouse~) and Status = ''A'' and PrinterType = ''Report''',
                                                                                                    'PrinterName',       'PrinterName,PrinterDescription', null,                             null,                  'PrinterName',        'PrinterDescription'
union select  'SKU_DD',                'DBLookupDropDown',  'vwActiveSKUs',     null,               'SKU',                null,                            'UserControl.SelectSKU',         'Standard',             'SKU',                'SKU'
union select  'CreateInvSKU_DD',       'DBLookupDropDown',  'vwActiveSKUs',     null,               'SKU',                null,                            'UserControl.SelectSKU',         'Standard',             'SKUId',              'SKU'
union select  'ShipFrom_DD',           'DBLookupDropDown',  'vwShipFromAddress','Status=''A''',     'Name',               null,                            'UserControl.SelectAddress',     'Standard',             'ContactRefId',       'Name'
union select  'ShipTo_DD',             'DBLookupDropDown',  'vwShipToAddress',  'Status=''A''',     'Name',               null,                            'UserControl.SelectAddress',     'Standard',             'ContactId',          'Name'
union select  'Consolidator_DD',       'DBLookupDropDown',  'vwContacts',       'Status=''A'' and ContactType = ''CO''',
                                                                                                    'Name',               null,                            'UserControl.SelectAddressBrief','Standard',             'ContactId',          'Name'

/* This is a generic control used by PrintLabels static form user across multiple actions */
union select  'EntityLabelFormat_DBDD','DBLookupDropDown',  'vwLabelFormats',  'EntityType = ''~ActionDetail_Entity~'' and Status = ''A''',
                                                                                                      'LabelFormatName',   'LabelFormatName,LabelFormatDesc',null,                           null,                  'LabelFormatName',    'LabelFormatDesc'
/* ~INPUTFILTER_DestWarehouse_Warehouse~ placeholder will be replaced with a where condition
    INPUTFILTER is the identifier to suggest which fields filters should be used for place holder
    DestWarehouse is the field name of the input selection filter to be used for the condition
    Warehouse is the field name to be use in the where condition

    This can translate into
    Warehouse is not null
    Warehouse in ('A', 'B', 'C')
    Warehouse = 'A'
*/
union select  'LPNLabelPrinter_DBDD','DBLookupDropDown', 'vwPrinters',     '((Warehouse is null) or ~INPUTFILTER_DestWarehouse_Warehouse~) and PrinterType=''Label'' and Status = ''A''',
                                                                                                      'DeviceName',      'DeviceId,DeviceName',            null,                            null,                   'DeviceId',           'DeviceName'
/* ~INPUTFILTER_Warehouse~ placeholder will be replaced with a where condition
    INPUTFILTER is the identifier to suggest which fields filters should be used for place holder
    Warehouse is the field name of the input selection filter to be used for the condition

    This can translate into
    Warehouse is not null
    Warehouse in ('A', 'B', 'C')
    Warehouse = 'A'
*/
union select  'GenericLabelPrinter_DBDD','DBLookupDropDown', 'vwPrinters',    '((Warehouse is null) or ~INPUTFILTER_Warehouse~) and PrinterType=''Label'' and Status = ''A''',
                                                                                                      'DeviceName',      'DeviceId,DeviceName',            null,                            null,                   'DeviceId',           'DeviceName'
union select  'GenericReportPrinter_DBDD','DBLookupDropDown','vwPrinters',    '((Warehouse is null) or ~INPUTFILTER_Warehouse~) and PrinterType=''Report'' and Status = ''A''',
                                                                                                      'DeviceName',      'DeviceId,DeviceName',            null,                            null,                   'DeviceId',           'DeviceName'
union select  'Warehouse_DBDD',          'DBLookupDropDown', 'vwLookups',     '~INPUTFILTER_Warehouse_LookupCode~ and LookupCategory=''Warehouse'' and Status = ''A''',
                                                                                                      'LookupDisplayDescription','LookupCode,LookupDisplayDescription',null,                null,                   'LookupCode',         'LookupDisplayDescription'
/* To be Displayed in LPN's page/actions Dropdowns */
union select  'DestWarehouse_DBDD',      'DBLookupDropDown', 'vwLookups',     '~INPUTFILTER_DestWarehouse_LookupCode~ and LookupCategory=''Warehouse'' and Status = ''A''',
                                                                                                      'LookupDisplayDescription','LookupCode,LookupDisplayDescription',null,                null,                   'LookupCode',         'LookupDisplayDescription'
union select  'InventoryClass1_DD',     'DBLookupDropDown',  'vwLookups',     'LookupCategory=''InventoryClass1'' and Status = ''A''',
                                                                                                      'LookupDisplayDescription','LookupCode,LookupDisplayDescription',null,                null,                   'LookupCode',         'LookupDisplayDescription'
union select  'InventoryClass2_DD',     'DBLookupDropDown',  'vwLookups',     'LookupCategory=''InventoryClass2'' and Status = ''A''',
                                                                                                      'LookupDisplayDescription','LookupCode,LookupDisplayDescription',null,                null,                   'LookupCode',         'LookupDisplayDescription'
union select  'InventoryClass3_DD',     'DBLookupDropDown',  'vwLookups',     'LookupCategory=''InventoryClass3'' and Status = ''A''',
                                                                                                      'LookupDisplayDescription','LookupCode,LookupDisplayDescription',null,                null,                   'LookupCode',         'LookupDisplayDescription'

exec pr_Setup_FieldUIAttributes @ContextName, @Category, @ttFieldUIAttributes, 'DI' /* Action - Delete and Insert */;

Go
