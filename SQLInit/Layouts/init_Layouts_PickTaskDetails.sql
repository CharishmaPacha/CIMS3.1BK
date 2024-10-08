/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/07/01  RKC     Changed TaskDetailId field visible to -3 (HA-638)
  2020/06/04  SAK     PickList Layout Added (523)
  2020/05/15  MS      Use vwUIPickTaskDetails as Dataset (HA-566)
  2018/01/24  KSK     Initial revision (CIMSV3-208)
------------------------------------------------------------------------------*/

Go

declare @ContextName        TName,
        @DataSetName        TName,
        @LayoutDescription  TDescription,
        @Layouts            TLayoutTable,

        @ttLF               TLayoutFieldsTable,
        @ttLSF              TLayoutSummaryFields,
        @ttLFE              TLayoutFieldsExpandedTable,
        @BusinessUnit       TBusinessUnit;

select @ContextName = 'List.PickTaskDetails',
       @DataSetName = 'vwUIPickTaskDetails';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                              Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                                Type    Layout   Description                   SelectionName                                      */
insert into @Layouts  select  'L',    'N',     'Standard',                   null,          null,  null,   0,      null
insert into @Layouts  select  'L',    'N',     'Pick List',                  null,          null,  null,   0,      null
insert into @Layouts  select  'S',    'N',     'Summary By Wave & Zone',     null,          null,  null,   0,      null
insert into @Layouts  select  'S',    'N',     'Summary By Wave Type',       null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts , 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLSF;

/*                        Field                         Visible Visible Field                 Width Display
                          Name                          Index           Caption                     Format */
insert into @ttLF select 'TaskDetailId',                null,     -3,   null,                 null, null
insert into @ttLF select 'TaskId',                      null,   null,   null,                 null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,                 null, null
insert into @ttLF select 'Location',                    null,     -1,   null,                 null, null
insert into @ttLF select 'TaskStatus',                  null,     -2,   null,                 null, null
insert into @ttLF select 'TaskStatusDesc',              null,      1,   null,                 null, null
insert into @ttLF select 'TaskStatusGroup',             null,   null,   null,                 null, null

insert into @ttLF select 'SKU',                         null,   null,   null,                 null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,                 null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,                 null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,                 null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,                 null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,                 null, null

insert into @ttLF select 'TaskPriority',                null,   null,   null,                 null, null
insert into @ttLF select 'TaskDetailStatus',            null,   null,   null,                 null, null
insert into @ttLF select 'TaskDetailStatusDesc',        null,   null,   null,                 null, null
insert into @ttLF select 'TaskDetailStatusGroup',       null,   null,   null,                 null, null

insert into @ttLF select 'DetailInnerPacks',            null,     -2,   null,                 null, null
insert into @ttLF select 'DetailQuantity',              null,     -2,   null,                 null, null
insert into @ttLF select 'DetailPercentComplete',       null,     -2,   null,                 null, null
insert into @ttLF select 'UnitsToPick',                 null,   null,   null,                 null, null
insert into @ttLF select 'UnitsCompleted',              null,   null,   null,                 null, null

insert into @ttLF select 'InnerPacksToPick',            null,   null,   null,                 null, null
insert into @ttLF select 'InnerPacksCompleted',         null,   null,   null,                 null, null
insert into @ttLF select 'TotalInnerPacks',             null,     -2,   null,                 null, null
insert into @ttLF select 'TotalUnits',                  null,     -2,   null,                 null, null

insert into @ttLF select 'PercentComplete',             null,   null,   null,                 null, null

insert into @ttLF select 'AlternateLPN',                null,   null,   null,                 null, null
insert into @ttLF select 'PickZone',                    null,      1,   null,                 null, null
insert into @ttLF select 'PickZoneDesc',                null,   null,   null,                 null, null
insert into @ttLF select 'AssignedTo',                  null,     -2,   null,                 null, null
insert into @ttLF select 'DestZone',                    null,   null,   null,                 null, null

insert into @ttLF select 'LPN',                         null,   null,   null,                 null, null
insert into @ttLF select 'LPNType',                     null,   null,   null,                 null, null
insert into @ttLF select 'LPNQuantity',                 null,     -1,   null,                 null, null
insert into @ttLF select 'OnHandStatus',                null,   null,   null,                 null, null
insert into @ttLF select 'TempLabel',                   null,   null,   null,                 null, null

insert into @ttLF select 'TempLabelId',                 null,   null,   null,                 null, null
insert into @ttLF select 'PickPosition',                null,   null,   null,                 null, null

insert into @ttLF select 'TaskType',                    null,     -1,   null,                 null, null
insert into @ttLF select 'TaskSubType',                 null,      1,   null,                 null, null
insert into @ttLF select 'TaskDesc',                    null,     -2,   null,                 null, null

insert into @ttLF select 'UnitWeight',                  null,     -1,   null,                 null, null
insert into @ttLF select 'UnitVolume',                  null,     -1,   null,                 null, null
insert into @ttLF select 'PickWeight',                  null,   null,   null,                 null, null
insert into @ttLF select 'PickVolume',                  null,   null,   null,                 null, null
insert into @ttLF select 'IsLabelGenerated',            null,      1,   null,                 null, null
insert into @ttLF select 'DependentOn',                 null,      1,   null,                 null, null

insert into @ttLF select 'ScheduledDate',               null,     -1,   null,                 null, null
insert into @ttLF select 'DetailCount',                 null,     -1,   null,                 null, null
insert into @ttLF select 'CompletedCount',              null,     -1,   null,                 null, null
insert into @ttLF select 'BatchPickZone',               null,     -1,   null,                 null, null
insert into @ttLF select 'PutawayZone',                 null,     -1,   null,                 null, null
insert into @ttLF select 'BatchPriority',               null,     -1,   null,                 null, null
insert into @ttLF select 'Warehouse',                   null,      1,   null,                 null, null

insert into @ttLF select 'TransactionDate',             null,     -1,   null,                 null, null

insert into @ttLF select 'LocationId',                  null,     -1,   null,                 null, null
insert into @ttLF select 'LocationRow',                 null,     -1,   null,                 null, null
insert into @ttLF select 'LocationSection',             null,     -1,   null,                 null, null
insert into @ttLF select 'LocationLevel',               null,     -1,   null,                 null, null
insert into @ttLF select 'LocationType',                null,     -1,   null,                 null, null
insert into @ttLF select 'PickPath',                    null,     -1,   null,                 null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,     -1,   null,                 null, null
insert into @ttLF select 'UnitsToAllocate',             null,     -2,   null,                 null, null
insert into @ttLF select 'DetailDestZone',              null,   null,   null,                 null, null
insert into @ttLF select 'DetailDestLocation',          null,   null,   null,                 null, null
insert into @ttLF select 'DetailDependencyFlags',       null,   null,   null,                 null, null

insert into @ttLF select 'LPNDetailId',                 null,     -1,   null,                 null, null
insert into @ttLF select 'SKUId',                       null,     -1,   null,                 null, null
insert into @ttLF select 'PalletId',                    null,   null,   null,                 null, null
insert into @ttLF select 'Pallet',                      null,      1,   null,                 null, null
insert into @ttLF select 'LPNId',                       null,     -1,   null,                 null, null
insert into @ttLF select 'OrderId',                     null,     -1,   null,                 null, null
insert into @ttLF select 'PickTicket',                  null,      1,   null,                 null, null
insert into @ttLF select 'OrderDetailId',               null,   null,   null,                 null, null

insert into @ttLF select 'WaveId',                      null,   null,   null,                 null, null
insert into @ttLF select 'WaveType',                    null,   null,   null,                 null, null
insert into @ttLF select 'WaveSatus',                   null,     -1,   null,                 null, null

insert into @ttLF select 'NumOrders',                   null,     -1,   null,                 null, null
insert into @ttLF select 'NumLines',                    null,     -1,   null,                 null, null
insert into @ttLF select 'NumSKUs',                     null,     -1,   null,                 null, null
insert into @ttLF select 'NumLPNs',                     null,     -2,   null,                 null, null
insert into @ttLF select 'NumUnits',                    null,     -1,   null,                 null, null
insert into @ttLF select 'TotalAmount',                 null,   null,   null,                 null, null
insert into @ttLF select 'TotalWeight',                 null,   null,   null,                 null, null
insert into @ttLF select 'TotalVolume',                 null,   null,   null,                 null, null

insert into @ttLF select 'SoldToId',                    null,   null,   null,                 null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,                 null, null
insert into @ttLF select 'ShipVia',                     null,     -1,   null,                 null, null
insert into @ttLF select 'BatchPickTicket',             null,     -1,   null,                 null, null
insert into @ttLF select 'SoldToName',                  null,     -2,   null,                 null, null
insert into @ttLF select 'ShipToStore',                 null,     -2,   null,                 null, null

insert into @ttLF select 'BatchPalletId',               null,   null,   null,                 null, null
insert into @ttLF select 'BatchPallet',                 null,     -1,   null,                 null, null
insert into @ttLF select 'BatchAssignedTo',             null,     -2,   null,                 null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,                 null, null
insert into @ttLF select 'PickBatchWarehouse',          null,     -1,   'Wave WH',            null, null
insert into @ttLF select 'DropLocation',                null,     -1,   null,                 null, null
insert into @ttLF select 'PickBatchGroup',              null,     -1,   null,                 null, null
insert into @ttLF select 'PickBatchCancelDate',         null,     -1,   'Wave Cancel Date',   null, null
insert into @ttLF select 'PickDate',                    null,   null,   null,                 null, null
insert into @ttLF select 'ShipDate',                    null,   null,   null,                 null, null
insert into @ttLF select 'Description',                 null,     -2,   null,                 null, null

insert into @ttLF select 'CancelDate',                  null,   null,   null,                 null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,                 null, null
insert into @ttLF select 'CustomerName',                null,     -1,   null,                 null, null

insert into @ttLF select 'RuleId',                      null,   null,   null,                 null, null
insert into @ttLF select 'IsAllocated',                 null,   null,   null,                 null, null

insert into @ttLF select 'DetailModifiedDate',          null,      1,   'Picked Date',        null, null
insert into @ttLF select 'DetailModifiedBy',            null,   null,   'Picked By',          null, null

insert into @ttLF select 'Category1',                   null,   null,   null,                 null, null
insert into @ttLF select 'Category2',                   null,   null,   null,                 null, null
insert into @ttLF select 'Category3',                   null,   null,   null,                 null, null
insert into @ttLF select 'Category4',                   null,   null,   null,                 null, null
insert into @ttLF select 'Category5',                   null,   null,   null,                 null, null

insert into @ttLF select 'UDF1',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF6',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF7',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF8',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF9',                        null,   null,   null,                 null, null
insert into @ttLF select 'UDF10',                       null,   null,   null,                 null, null

insert into @ttLF select 'OHUDF1',                      null,   null,   null,                 null, null
insert into @ttLF select 'OHUDF2',                      null,   null,   null,                 null, null
insert into @ttLF select 'OHUDF3',                      null,   null,   null,                 null, null
insert into @ttLF select 'OHUDF4',                      null,   null,   null,                 null, null
insert into @ttLF select 'OHUDF5',                      null,   null,   null,                 null, null

insert into @ttLF select 'ODUDF1',                      null,   null,   null,                 null, null
insert into @ttLF select 'ODUDF2',                      null,   null,   null,                 null, null
insert into @ttLF select 'ODUDF3',                      null,   null,   null,                 null, null
insert into @ttLF select 'ODUDF4',                      null,   null,   null,                 null, null
insert into @ttLF select 'ODUDF5',                      null,   null,   null,                 null, null

insert into @ttLF select 'vwPT_UDF1',                   null,      1,   'Printed',            null, null
insert into @ttLF select 'vwPT_UDF2',                   null,   null,   null,                 null, null
insert into @ttLF select 'vwPT_UDF3',                   null,   null,   null,                 null, null
insert into @ttLF select 'vwPT_UDF4',                   null,   null,   null,                 null, null
insert into @ttLF select 'vwPT_UDF5',                   null,   null,   null,                 null, null
insert into @ttLF select 'vwPT_UDF6',                   null,   null,   null,                 null, null
insert into @ttLF select 'vwPT_UDF7',                   null,   null,   null,                 null, null
insert into @ttLF select 'vwPT_UDF8',                   null,   null,   null,                 null, null
insert into @ttLF select 'vwPT_UDF9',                   null,   null,   null,                 null, null
insert into @ttLF select 'vwPT_UDF10',                  null,   null,   null,                 null, null

insert into @ttLF select 'Archived',                    null,   null,   null,                 null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,                 null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,                 null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,                 null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,                 null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,                 null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'TaskDetailId;' /* KeyFields */;

/******************************************************************************/
/* Layout Fields for Pick List Layout */
/******************************************************************************/
delete from @ttLF;

/*                        Field                   Visible Visible Field                 Width Display
                          Name                    Index           Caption                     Format */
insert into @ttLF select  'TaskId',               null,   null,   null,                 null, null
insert into @ttLF select  'WaveNo',               null,   null,   null,                 null, null
insert into @ttLF select  'TaskStatusDesc',       null,   null,   null,                 null, null
insert into @ttLF select  'Location',             null,   null,   null,                 null, null
insert into @ttLF select  'TaskStatusGroup',      null,     -1,   null,                 null, null
insert into @ttLF select  'LPN',                  null,   null,   null,                 null, null

insert into @ttLF select  'SKU',                  null,   null,   null,                 null, null
insert into @ttLF select  'SKU1',                 null,      1,   null,                 null, null
insert into @ttLF select  'SKU2',                 null,      1,   null,                 null, null
insert into @ttLF select  'SKU3',                 null,      1,   null,                 null, null

insert into @ttLF select  'UnitsToPick',          null,   null,   null,                 null, null
insert into @ttLF select  'UnitsCompleted',       null,   null,   null,                 null, null
insert into @ttLF select  'TaskDetailStatusGroup',null,     -1,   null,                 null, null
insert into @ttLF select  'TaskPriority',         null,     -1,   null,                 null, null
insert into @ttLF select  'TaskDetailStatusDesc', null,   null,   null,                 null, null
insert into @ttLF select  'PercentComplete',      null,     -1,   null,                 null, null

insert into @ttLF select  'PickZone',             null,      1,   null,                 null, null
insert into @ttLF select  'PickPosition',         null,   null,   null,                 null, null
insert into @ttLF select  'TaskSubType',          null,      1,   null,                 null, null
insert into @ttLF select  'InnerPacksToPick',     null,     -1,   null,                 null, null
insert into @ttLF select  'DependentOn',          null,      1,   null,                 null, null
insert into @ttLF select  'InnerPacksCompleted',  null,   null,   null,                 null, null
insert into @ttLF select  'IsLabelGenerated',     null,   null,   null,                 null, null
insert into @ttLF select  'PickTicket',           null,   null,   null,                 null, null
insert into @ttLF select  'AlternateLPN',         null,   null,   null,                 null, null
insert into @ttLF select  'Pallet',               null,      1,   null,                 null, null

insert into @ttLF select  'Warehouse',            null,   null,   null,                 null, null
insert into @ttLF select  'DestZone',             null,   null,   null,                 null, null
insert into @ttLF select  'LPNQuantity',          null,     -1,   null,                 null, null
insert into @ttLF select  'TempLabel',            null,   null,   null,                 null, null
insert into @ttLF select  'TempLabelId',          null,   null,   null,                 null, null
insert into @ttLF select  'DetailModifiedDate',   null,   null,   null,                 null, null
insert into @ttLF select  'TaskType',             null,     -1,   null,                 null, null

insert into @ttLF select  'UnitWeight',           null,   null,   null,                 null, null
insert into @ttLF select  'vwPT_UDF1',            null,      1,   null,                 null, null
insert into @ttLF select  'UnitVolume',           null,   null,   null,                 null, null
insert into @ttLF select  'PickWeight',           null,   null,   null,                 null, null
insert into @ttLF select  'PickVolume',           null,   null,   null,                 null, null
insert into @ttLF select  'ScheduledDate',        null,     -1,   null,                 null, null

insert into @ttLF select  'DetailCount',          null,     -1,   null,                 null, null
insert into @ttLF select  'CompletedCount',       null,     -1,   null,                 null, null
insert into @ttLF select  'BatchPickZone',        null,     -1,   null,                 null, null
insert into @ttLF select  'PutawayZone',          null,     -1,   null,                 null, null
insert into @ttLF select  'BatchPriority',        null,     -1,   null,                 null, null
insert into @ttLF select  'TaskDetailId',         null,     -1,   null,                 null, null
insert into @ttLF select  'TransactionDate',      null,     -1,   null,                 null, null

insert into @ttLF select  'LocationId',           null,     -1,   null,                 null, null
insert into @ttLF select  'LocationRow',          null,     -1,   null,                 null, null
insert into @ttLF select  'LocationSection',      null,     -1,   null,                 null, null
insert into @ttLF select  'LocationLevel',        null,     -1,   null,                 null, null
insert into @ttLF select  'LocationType',         null,   null,   null,                 null, null

insert into @ttLF select  'PickPath',             null,     -1,   null,                 null, null
insert into @ttLF select  'UnitsAuthorizedToShip',null,     -1,   null,                 null, null
insert into @ttLF select  'LPNDetailId',          null,     -1,   null,                 null, null
insert into @ttLF select  'SKUId',                null,     -1,   null,                 null, null
insert into @ttLF select  'LPNId',                null,     -1,   null,                 null, null
insert into @ttLF select  'OrderId',              null,     -1,   null,                 null, null
insert into @ttLF select  'OrderDetailId',        null,   null,   null,                 null, null

insert into @ttLF select  'NumOrders',            null,     -1,   null,                 null, null
insert into @ttLF select  'NumLines',             null,     -1,   null,                 null, null
insert into @ttLF select  'NumSKUs',              null,     -1,   null,                 null, null
insert into @ttLF select  'NumUnits',             null,     -1,   null,                 null, null
insert into @ttLF select  'TotalAmount',          null,   null,   null,                 null, null
insert into @ttLF select  'TotalWeight',          null,   null,   null,                 null, null
insert into @ttLF select  'TotalVolume',          null,   null,   null,                 null, null

insert into @ttLF select  'SoldToId',             null,   null,   null,                 null, null
insert into @ttLF select  'ShipToId',             null,   null,   null,                 null, null
insert into @ttLF select  'ShipVia',              null,     -1,   null,                 null, null

insert into @ttLF select  'BatchPickTicket',      null,     -1,   null,                 null, null
insert into @ttLF select  'BatchPalletId',        null,   null,   null,                 null, null
insert into @ttLF select  'BatchPallet',          null,     -1,   null,                 null, null
insert into @ttLF select  'PickBatchWarehouse',   null,     -1,   null,                 null, null
insert into @ttLF select  'DropLocation',         null,     -1,   null,                 null, null
insert into @ttLF select  'PickBatchGroup',       null,     -1,   null,                 null, null
insert into @ttLF select  'PickBatchCancelDate',  null,     -1,   null,                 null, null
insert into @ttLF select  'PickDate',             null,   null,   null,                 null, null
insert into @ttLF select  'ShipDate',             null,   null,   null,                 null, null
insert into @ttLF select  'CancelDate',           null,   null,   null,                 null, null
insert into @ttLF select  'DesiredShipDate',      null,   null,   null,                 null, null

insert into @ttLF select  'CustomerName',         null,     -1,   null,                 null, null
insert into @ttLF select  'RuleId',               null,   null,   null,                 null, null
insert into @ttLF select  'IsAllocated',          null,   null,   null,                 null, null
insert into @ttLF select  'DetailModifiedBy',     null,   null,   null,                 null, null
insert into @ttLF select  'Archived',             null,   null,   null,                 null, null

insert into @ttLF select  'ModifiedDate',         null,   null,   null,                 null, null
insert into @ttLF select  'ModifiedBy',           null,   null,   null,                 null, null
insert into @ttLF select  'CreatedDate',          null,   null,   null,                 null, null
insert into @ttLF select  'CreatedBy',            null,   null,   null,                 null, null

exec pr_LayoutFields_Setup @ContextName, 'Pick List', @ttLF, @DataSetName, 'TaskDetailId;' /* KeyFields */;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'BatchNo',                    'Count',     '# Waves: {0:n0}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* Layout description */, @ttLSF;

/******************************************************************************/
/* Summary by Wave */
/******************************************************************************/
select @LayoutDescription = 'Summary by Wave & Zone';
delete from @ttLFE;

/*                        Field                Visible  Visible  Field          Width Display  Aggregate
                          Name                 Index             Caption              Format   Method */
insert into @ttLFE select 'BatchNo',           null,        1,   null,          null, null,    null
insert into @ttLFE select 'PickZone',          null,        1,   null,          null, null,    null
insert into @ttLFE select 'TaskSubType',       null,        1,   null,          null, null,    null
insert into @ttLFE select 'TaskDetailId',      null,        1,   'Picks',       null, null,    'Count'
insert into @ttLFE select 'SKU',               null,        1,   null,          null, null,    'DCount'
insert into @ttLFE select 'OrderId',           null,        1,   'Orders',      null, null,    'DCount'
insert into @ttLFE select 'DetailQuantity',    null,        1,   'Total Qty',   null, null,    'Sum'
insert into @ttLFE select 'UnitsCompleted',    null,        1,   null,          null, null,    'Sum'
insert into @ttLFE select 'UnitsToPick',       null,        1,   null,          null, null,    'Sum'
insert into @ttLFE select 'DetailPercentComplete',null,     1,   '% Complete',  null, null,    'Avg'


exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary by Wave Type */
/******************************************************************************/
select @LayoutDescription = 'Summary by Wave Type';
delete from @ttLFE;

/*                        Field                Visible  Visible  Field          Width Display  Aggregate
                          Name                 Index             Caption              Format   Method */
insert into @ttLFE select 'BatchType',         null,        1,   null,          null, null,    null
insert into @ttLFE select 'PickZone',          null,        1,   null,          null, null,    null
insert into @ttLFE select 'TaskSubType',       null,        1,   null,          null, null,    null
insert into @ttLFE select 'TaskDetailId',      null,        1,   'Picks',       null, null,    'Count'
insert into @ttLFE select 'SKU',               null,        1,   null,          null, null,    'DCount'
insert into @ttLFE select 'OrderId',           null,        1,   'Orders',      null, null,    'DCount'
insert into @ttLFE select 'DetailQuantity',    null,        1,   'Total Qty',   null, null,    'Sum'
insert into @ttLFE select 'UnitsCompleted',    null,        1,   null,          null, null,    'Sum'
insert into @ttLFE select 'UnitsToPick',       null,        1,   null,          null, null,    'Sum'
insert into @ttLFE select 'DetailPercentComplete',null,     1,   '% Complete',  null, null,    'Avg'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

Go
