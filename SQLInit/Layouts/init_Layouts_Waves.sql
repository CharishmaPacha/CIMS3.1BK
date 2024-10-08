/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/22  PKK     Added MaxUnitsPerCarton and CartonizationModel HA(2813)
  2021/02/23  SGK     Added NumLPNsToPA, ReleaseDateTime, CustPO, PickSequence,
                      PrintStatus, WaveRuleGroup, CreatedOn, ModifiedOn (CIMSV3-1364)
  2021/01/19  PKK     Corrected the file as per the template (CIMSV3-1282)
  2020/10/05  RBV     Added PickMethod field (CID-1488)
  2020/06/03  VS      Migrated the missed fields in the vwWaves (HA-582)
  2020/05/29  TK      Added NumTasks (HA-691)
  2020/05/28  AY      LPN Counts added
  2020/05/07  RT      Included InvAllocationModel (HA-312)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/05/10  VS      Added Summary Layouts (CIMSV3-193)
  2018/01/05  MJ      Initial revision (CIMSV3-185)
------------------------------------------------------------------------------*/

Go

declare @ContextName         TName,
        @DataSetName         TName,

        @Layouts             TLayoutTable,
        @LayoutDescription   TDescription,

        @ttLF                TLayoutFieldsTable,
        @ttLFE               TLayoutFieldsExpandedTable,
        @ttLSF               TLayoutSummaryFields,
        @BusinessUnit        TBusinessUnit;

select @ContextName = 'List.Waves',
       @DataSetName = 'vwWaves';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,   -3,     null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveType',                    null,   null,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,   null,   null,               null, null
insert into @ttLF select 'WaveStatus',                  null,   null,   null,               null, null
insert into @ttLF select 'WaveStatusDesc',              null,   null,   null,               null, null
insert into @ttLF select 'StatusGroup',                 null,   null,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'WCSStatus',                   null,   null,   null,               null, null
insert into @ttLF select 'WCSDependency',               null,   null,   null,               null, null

insert into @ttLF select 'NumOrders',                   null,   null,   null,               null, null
insert into @ttLF select 'NumLines',                    null,   null,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,     -1,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumInnerPacks',               null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumLPNsToPA',                 null,   null,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,      1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   null,               null, null
insert into @ttLF select 'NumTasks',                    null,   null,   null,               null, null
insert into @ttLF select 'NumPicks',                    null,   null,   null,               null, null
insert into @ttLF select 'NumPicksCompleted',           null,   null,   null,               null, null
insert into @ttLF select 'PercentPicksComplete',        null,   null,   null,               null, null

insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null
insert into @ttLF select 'PickDate',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipDate',                    null,   null,   null,               null, null
insert into @ttLF select 'ReleaseDateTime',             null,   null,   null,               null, null
insert into @ttLF select 'Description',                 null,     -2,   null,               null, null
insert into @ttLF select 'ColorCode',                   null,   null,   null,               null, null
insert into @ttLF select 'Category1',                   null,   null,   null,               null, null
insert into @ttLF select 'Category2',                   null,   null,   null,               null, null
insert into @ttLF select 'Category3',                   null,   null,   null,               null, null
insert into @ttLF select 'Category4',                   null,   null,   null,               null, null
insert into @ttLF select 'Category5',                   null,   null,   null,               null, null

insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToDesc',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToDescription',           null,   null,   null,               null, null
insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,     -1,   null,               null, null
insert into @ttLF select 'ShipViaDesc',                 null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'SoldToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'PickZone',                    null,   null,   null,               null, null
insert into @ttLF select 'PickZoneDesc',                null,   null,   null,               null, null
insert into @ttLF select 'PickSequence',                null,   null,   null,               null, null

insert into @ttLF select 'Pallet',                      null,     -2,   null,               null, null -- deprecated
insert into @ttLF select 'AssignedTo',                  null,     -2,   null,               null, null -- deprecated
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'DropLocation',                null,   null,   null,               null, null
insert into @ttLF select 'WaveGroup',                   null,   null,   null,               null, null
insert into @ttLF select 'WA_IsReplenished',            null,   null,   null,               null, null
insert into @ttLF select 'WA_ReplenishWaveNo',          null,   null,   null,               null, null

insert into @ttLF select 'AllocateFlags',               null,   null,   null,               null, null
insert into @ttLF select 'DependencyFlags',             null,   null,   null,               null, null
insert into @ttLF select 'PrintStatus',                 null,   null,   null,               null, null
insert into @ttLF select 'IsAllocated',                 null,   null,   null,               null, null
insert into @ttLF select 'InvAllocationModel',          null,   null,   null,               null, null
insert into @ttLF select 'CartonizationModel',          null,   null,   null,               null, null
insert into @ttLF select 'PickMethod',                  null,   null,   null,               null, null

/* Counts of orders in various statuses */
insert into @ttLF select 'OrdersWaved',                 null,   null,   null,               null, null
insert into @ttLF select 'OrdersAllocated',             null,     -1,   null,               null, null
insert into @ttLF select 'OrdersToAllocate',            null,     -1,   null,               null, null
insert into @ttLF select 'OrdersPicked',                null,     -1,   null,               null, null
insert into @ttLF select 'OrdersToPick',                null,     -1,   null,               null, null
insert into @ttLF select 'OrdersPacked',                null,     -1,   null,               null, null
insert into @ttLF select 'OrdersToPack',                null,     -1,   null,               null, null
insert into @ttLF select 'OrdersLoaded',                null,     -1,   null,               null, null
insert into @ttLF select 'OrdersToLoad',                null,     -1,   null,               null, null
insert into @ttLF select 'OrdersStaged',                null,     -1,   null,               null, null
insert into @ttLF select 'OrdersToStage',               null,     -1,   null,               null, null
insert into @ttLF select 'OrdersShipped',               null,     -1,   null,               null, null
insert into @ttLF select 'OrdersOpen',                  null,     -1,   null,               null, null

 /* Sum of Units in various statuses */
insert into @ttLF select 'UnitsAssigned',               null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPicked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPacked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsStaged',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsLoaded',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,     -1,   null,               null, null
/* Below fields not available on vwWaves */
insert into @ttLF select 'UnitsToPick',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsToPack',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsToStage',                null,     -2,   null,               null, null
insert into @ttLF select 'UnitsToShip',                 null,     -2,   null,               null, null

insert into @ttLF select 'LPNsPicked',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsPacked',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsStaged',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsLoaded',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsShipped',                 null,     -1,   null,               null, null

insert into @ttLF select 'TotalAmount',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalWeight',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalVolume',                 null,   null,   null,               null, null
insert into @ttLF select 'MaxUnitsPerCarton',           null,   null,   null,               null, null

insert into @ttLF select 'UDF1',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF6',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF7',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF8',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF9',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF10',                       null,   null,   null,               null, null

insert into @ttLF select 'vwPB_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF5',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF6',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF7',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF8',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF9',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPB_UDF10',                  null,   null,   null,               null, null

insert into @ttLF select 'PalletId',                    null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'RuleId',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveRuleGroup',               null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedOn',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedOn',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'WaveId;WaveNo' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by WaveType';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'WaveTypeDesc',           null,      1,   null,          null, null,    null
insert into @ttLFE select 'WaveNo',                 null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumOrders',              null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumTasks',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicks',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicksCompleted',      null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'PercentPicksComplete',   null,      1,   null,          null, null,    'Avg'
insert into @ttLFE select 'OrdersPicked',           null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'OrdersPacked',           null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'OrdersStaged',           null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'OrdersLoaded',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by ShipVia';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'ShipVia',                null,      1,   null,          null, null,    null
insert into @ttLFE select 'WaveNo',                 null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumOrders',              null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumTasks',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicks',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicksCompleted',      null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'PercentPicksComplete',   null,      1,   null,          null, null,    'Avg'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Priority';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'Priority',               null,      1,   null,          null, null,    null
insert into @ttLFE select 'WaveNo',                 null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumOrders',              null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Account';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'Account',                null,      1,   null,          null, null,    null
insert into @ttLFE select 'AccountName',            null,      1,   null,          null, null,    null
insert into @ttLFE select 'WaveNo',                 null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumOrders',              null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'WaveNo',                     'Count',     '# Waves:{0:n0}',             null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
