/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2022/06/14  LAC     Added APIInbound and APIOutbound Transactions (OBV3-501)
  2020/10/29  VS      ActivityLog_All: DaysToRetain changed to 92 to have 3 months back data 
                        and ActivityLog tables (cIMSV3-1172)
  2020/09/10  VS      EntityKeyField renamed as PrimaryKeyField and
                        ArchiveFlag renamed as Action (CIMSV3-1080)
              AY      Initialize PrimaryKeyField from System tables
  2020/07/24  VS      Added EntityKeyField, ArchiveFlag to Move the data into ArchiveDB (S2GCA-1186)
  2020/07/27  SK      Added InvSnapshot & InvVariance (HA-1180)
  2020/04/17  VS      Reduced DaysToRetain for Interfacelogs and Interfacelog details (FB-1989)
  2019/03/06  RIA     Setup purging control for cIMSDE tables (S2G-31)
  2016/07/19  NY      Setup purging control for Tasks, orders, PickBatchDetails (GNC-1327)
  2016/06/24  NY      Added ArchiveFlag (GNC-1327)
  2015/03/27  NB      Initial revision
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Create temp table */
if object_id('tempdb..#PurgingControl') is not null
  drop table #PurgingControl;

select * into #PurgingControl from PurgingControl
alter table #PurgingControl alter column BusinessUnit varchar(10) null

/*----------------------------------------------------------------------------*/
insert into #PurgingControl
             (Name,                         Entity,                          DaysToRetain, EntityStatus, EntityStatusField,    EntityType, EntityTypeField, EntityDateField,       ArchivedOnly,  Action,        RecordsPerRun, RecordsPerDelete, PurgeGroup, Status, Description)
      select 'ActivityLog_All',             'ActivityLog',                   92,           null,         null,                 null,       null,            'DateTimeStamp',       'N',          'Purge',        10000000,      1000000,          'CIMS',     'I',    'Purge ActivityLog'
/* Exports & Interface */
union select 'Exports_OldUnprocessed',      'Exports',                       90,           'N',          'Status',             null,       null,            'TransDateTime',       'N',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge old unprocessed Exports'
union select 'Exports_Processed',           'Exports',                       60,           'Y',          'Status',             null,       null,            'ProcessedDateTime',   'Y',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge processed Exports'
union select 'InterfaceLog_All',            'InterfaceLog',                  90,           null,         null,                 null,       null,            'CreatedDate',         'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Interface Log'
union select 'InterfaceLogDetails_Errors',  'InterfaceLogDetails',           90,           null,         null,                 null,       null,            'LogDateTime',         'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge error Interface Log Details'
union select 'InterfaceLogDetails_NoErrors','InterfaceLogDetails',           30,           null,         null,                 null,       null,            'LogDateTime',         'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge successful Interface Log Details'
/* LPNs */
union select 'LPNs_Archived',               'LPNs',                          90,           'CVI',        'Status',             null,       null,            'ModifiedDate',        'Y',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge archived Consumed/Voided/Inactive LPNs'
union select 'LPNs_Shipped',                'LPNs',                          90,           'S',          'Status',             null,       null,            'ModifiedDate',        'Y',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Shipped LPNs'
/* Orders */
union select 'Orders_Archived',             'OrderHeaders',                  90,           'XS',         'Status',             null,       null,            'ModifiedDate',        'Y',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Archived Shipped/Cancelled Orders'
/* Tasks */
union select 'Tasks_Archived',              'Tasks',                         90,           'XS',         'Status',             null,       null,            'ModifiedDate',        'Y',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Completed/Cancelled Tasks'
/* Waves */
union select 'WaveDetails',                 'PickBatchDetails',              90,           null,         null,                 null,       null,            'CreatedDate',         'N',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Wave Details'
union select 'Waves',                       'PickBatches',                   90,           'DXS',        'Status',             null,       null,            'ModifiedDate',        'N',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Shipped/Canceled/Completed Waves'
/* Orphan records */
union select 'AuditEntities_PickBatch',     'AuditEntities',                 null,         null,         null,                 null,       null,            '',                    'N',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Orphan Pickbatch AuditEntities'
union select 'LPNDetails_Orphan',           'LPNDetails',                    null,         null,         null,                 null,       null,            null,                  'N',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Orphan LPNDetails'
union select 'OrderDetails_Orphan',         'OrderDetails',                  null,         null,         null,                 null,       null,            null,                  'N',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Orphan Order Details'
union select 'TaskDetails_Orphan',          'TaskDetails',                   null,         null,         null,                 null,       null,            null,                  'N',          'Archive',      10000000,      1000000,          'CIMS',     'A',    'Purge Orphan Task Details'
/* Inventory related Tables */
union select 'InvSnapshot',                 'InvSnapshot',                   60,           null,         null,                 null,       null,            'SnapshotDate',        'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge InvSnapshot Table'
union select 'InvComparison',               'InvComparison',                 60,           null,         null,                 null,       null,            'CreatedOn',           'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge InvComparison Table'

/* API Tables */
union select 'APIInboundTransactions',      'APIInboundTransactions',        60,           null,         null,                 null,       null,            'CreatedDate',         'N',           null,          1000000,       1000000,          'CIMS',     'I',    'Purge API Inbound Transactions'
union select 'APIOutboundTransactions',     'APIOutboundTransactions',       60,           null,         null,                 null,       null,            'CreatedDate',         'N',           null,          1000000,       1000000,          'CIMS',     'A',    'Purge API Outbound Transactions'

/******************************************************************************/
/* WCS Tables */
/******************************************************************************/
/* Panda Labels */
union select 'PandALabels_Processed',       'PandALabels',                   60,           'P',          'ConfirmationStatus', null,       null,            'ConfirmedDate',       'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Processed PandALabels'
/* Router */
union select 'RouterConfirmation_Exported', 'RouterConfirmation',            90,           'Y',          'ProcessedStatus',    null,       null,            'ProcessedDateTime',   'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Processed Router Confirmations'
union select 'RouterConfirmation_Ignored',  'RouterConfirmation',            90,           'I',          'ProcessedStatus',    null,       null,            'CreatedDate',         'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Ignored Router Confirmations'
union select 'RouterInstruction_Error',     'RouterInstruction',             30,           'X',          'ExportStatus',       null,       null,            'ExportDateTime',      'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Error Router Instructions'
union select 'RouterInstruction_Exported',  'RouterInstruction',             90,           'Y',          'ExportStatus',       null,       null,            'ExportDateTime',      'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Exported Router Instructions'
/* Sorter */
union select 'SrtrConsumedLPNs_All',        'SrtrConsumedLPNs',              90,           null,         null,                 null,       null,            'CreatedDate',         'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Sorter Consumed LPNs'
union select 'SrtrLPNs_Error',              'SrtrLPNs',                      60,           'E',          'ExportedStatus',     null,       null,            'ExportedDate',        'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Error Sorter LPNs'
union select 'SrtrLPNs_Exported',           'SrtrLPNs',                      60,           'Y',          'ExportedStatus',     null,       null,            'ExportedDate',        'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Processed Sorter LPNs'
union select 'SrtrPackedLPNs_Exported',     'SrtrPackedLPNs',                60,           'Y',          'ProcessedStatus',    null,       null,            'ProcessedDate',       'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Processed Sorter Packed LPNs'
union select 'SrtrPackedLPNs_Ignored',      'SrtrPackedLPNs',                60,           'I',          'ProcessedStatus',    null,       null,            'CreatedDate',         'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Ignored Sorter Packed LPNs'
union select 'SrtrWaveDetails_Exported',    'SrtrWaveDetails',               60,           'Y',          'ExportedStatus',     null,       null,            'ExportedDate',        'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Exported Sorter Wave Details'
union select 'SrtrWaveDetails_Ignored',     'SrtrWaveDetails',               60,           'I',          'ExportedStatus',     null,       null,            'ExportedDate',        'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Ignored Sorter Wave Details'
union select 'SrtrWaveTransactions_All',    'SrtrWaveTransactions',          120,          null,         null,                 null,       null,            'CreatedDate',         'N',          'Purge',        10000000,      1000000,          'CIMS',     'A',    'Purge Sorter Wave Transactions'

/******************************************************************************/
/* CIMS DE */
/******************************************************************************/
/* CIMSDE Exports */
union select 'ExportOnhandInventory',       'CIMSDE_ExportOnhandInventory',  60,           null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Exported Onhand Inventory'
union select 'ExportOpenOrders',            'CIMSDE_ExportOpenOrders',       60,           null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Exported Open Orders'
union select 'ExportOpenReceipts',          'CIMSDE_ExportOpenReceipts',     60,           null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Exported Open Receipts'
union select 'ExportShippedLoads',          'CIMSDE_ExportShippedLoads',     60,           null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Exported Shipped Loads'
union select 'ExportTransactions',          'CIMSDE_ExportTransactions',     180,          null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Exported Transactions'
/* CIMSDE Imports */
union select 'ImportASNLPNDetails',         'CIMSDE_ImportASNLPNDetails',    60,           null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported ASN LPN Details'
union select 'ImportASNLPNs',               'CIMSDE_ImportASNLPNs',          60,           null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported ASN LPNs'
union select 'ImportCartonTypes',           'CIMSDE_ImportCartonTypes',      60,           null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Carton Types'
union select 'ImportContacts',              'CIMSDE_ImportContacts',         60,           null,         null,                 null,       null,            'InsertedTime',        'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Contacts'
union select 'ImportInvAdjustments',        'CIMSDE_ImportInvAdjustments',   60,           null,         null,                 null,       null,            'ProcessedTime',       'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Inv Adjustments'
union select 'ImportNotes',                 'CIMSDE_ImportNotes',            60,           null,         null,                 null,       null,            'ProcessedTime',       'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Notes'
union select 'ImportOrderDetails',          'CIMSDE_ImportOrderDetails',     60,           null,         null,                 null,       null,            'ProcessedTime',       'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Order Details'
union select 'ImportOrderHeaders',          'CIMSDE_ImportOrderHeaders',     60,           null,         null,                 null,       null,            'ProcessedTime',       'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Order Headers'
union select 'ImportReceiptDetails',        'CIMSDE_ImportReceiptDetails',   60,           null,         null,                 null,       null,            'ProcessedTime',       'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Receipt Details'
union select 'ImportReceiptHeaders',        'CIMSDE_ImportReceiptHeaders',   60,           null,         null,                 null,       null,            'ProcessedTime',       'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Receipt Headers'
union select 'ImportResults',               'CIMSDE_ImportResults',          60,           null,         null,                 null,       null,            'CreatedDate',         'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported Results'
union select 'ImportSKUPrePacks',           'CIMSDE_ImportSKUPrePacks',      60,           null,         null,                 null,       null,            'ProcessedTime',       'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported SKU PrePacks'
union select 'ImportSKUs',                  'CIMSDE_ImportSKUs',             60,           null,         null,                 null,       null,            'ProcessedTime',       'Y',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported SKUs'
union select 'ImportUPCs',                  'CIMSDE_ImportUPCs',             60,           null,         null,                 null,       null,            'ProcessedTime',       'N',          'Purge',        10000000,      1000000,          'CIMSDE',   'A',    'Purge Imported UPCs'


/******************************************************************************/
/* Delete and then insert new entries */
delete from PurgingControl;

insert into PurgingControl(Name, Description, Entity, EntityType, EntityTypeField, EntityStatus,  EntityStatusField,
                           DaysToRetain,  EntityDateField, ArchivedOnly, RecordsPerRun, RecordsPerDelete, CustomSQLFrom,
                           CustomSQLWhere, PurgeGroup, SeqNo, Status, EntityDetails, Action, BusinessUnit)
  select PC.Name, PC.Description, PC.Entity, PC.EntityType, PC.EntityTypeField, PC.EntityStatus,  PC.EntityStatusField,
         PC.DaysToRetain,  PC.EntityDateField, PC.ArchivedOnly, PC.RecordsPerRun, PC.RecordsPerDelete, PC.CustomSQLFrom,
         PC.CustomSQLWhere, PC.PurgeGroup, PC.SeqNo, PC.Status, PC.EntityDetails, PC.Action, B.BusinessUnit
  from #PurgingControl PC, vwBusinessUnits B

/* Instead of setting primary key field for all table above, use the system tables to identify and update it as below */
update PC
set PC.PrimaryKeyField = IS_KCU.COLUMN_NAME
from PurgingControl PC
  join Information_Schema.Table_Constraints IS_TC on PC.Entity = IS_TC.Table_Name and Constraint_Type = 'Primary Key'
  join Information_Schema.Key_Column_Usage IS_KCU on IS_KCU.Constraint_Name = IS_TC.Constraint_Name
where PC.PrimaryKeyField is null;

/*

delete PickBatchDetails
from PickBatchDetails PBD left outer join PickBatches PB on PBD.PickBatchId =PB.RecordId
where PB.RecordId is null and PBD.PickBatchId < 400

select orphan AE
select *
from AuditEntities AE left outer join PickBatches PB on AE.EntityId =PB.RecordId
where AE.EntityType = 'Pickbatch' and PB.RecordId is null and AE.EntityId < 3000

delete orphan AE
delete AuditEntities
from AuditEntities AE left outer join PickBatches PB on AE.EntityId =PB.RecordId
where AE.EntityType = 'Pickbatch' and PB.RecordId is null and AE.EntityId < 2000


*/
