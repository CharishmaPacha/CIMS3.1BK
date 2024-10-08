/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/23  SK      Initial revision (HA-3020)
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

select @ContextName = 'List.WHKPIPeriod',
       @DataSetName = 'vwWarehouseKPI';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default                      Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,                        null,  null,   99,     null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for WHKPIPeriod - Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */

insert into @ttLF select 'Operation',                   null,      1,   null,               null, null
insert into @ttLF select 'SubOperation1',               null,      1,   null,               null, null
insert into @ttLF select 'SubOperation2',               null,     -1,   null,               null, null
insert into @ttLF select 'SubOperation3',               null,     -1,   null,               null, null
insert into @ttLF select 'JobCode',                     null,     -1,   null,               null, null

insert into @ttLF select 'ActivityDate',                null,     -1,   null,               null, null
insert into @ttLF select 'ActivityDate_DMY',            null,     10,   null,               null, null -- for display, not selection
insert into @ttLF select 'ActivityDate_MY',             null,    -10,   null,               null, null -- for display, not selection
insert into @ttLF select 'ActivityDate_QY',             null,    -10,   null,               null, null -- for display, not selection
insert into @ttLF select 'ActivityDate_Y',              null,    -10,   null,               null, null -- for display, not selection

insert into @ttLF select 'Account',                     null,     -1,   null,               null, null
insert into @ttLF select 'AccountName',                 null,     -1,   null,               null, null

insert into @ttLF select 'NumWaves',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumOrders',                   null,      1,   null,               null, null
insert into @ttLF select 'NumLines',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumLocations',                null,      1,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,      1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,      1,   null,               null, null
insert into @ttLF select 'NumInnerPacks',               null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,      1,   null,               null, null
insert into @ttLF select 'NumTasks',                    null,      1,   null,               null, null
insert into @ttLF select 'NumPicks',                    null,      1,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,     -1,   null,               null, null

insert into @ttLF select 'Weight',                      null,     -1,   null,               null, null
insert into @ttLF select 'Volume',                      null,     -1,   null,               null, null

insert into @ttLF select 'Comment',                     null,     -2,   null,               null, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'Archived',                    null,     -1,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'SortOrder',                   null,     -1,   null,               null, null

insert into @ttLF select 'KPI_UDF1',                    null,     -1,   null,               null, null
insert into @ttLF select 'KPI_UDF2',                    null,     -1,   null,               null, null
insert into @ttLF select 'KPI_UDF3',                    null,     -1,   null,               null, null
insert into @ttLF select 'KPI_UDF4',                    null,     -1,   null,               null, null
insert into @ttLF select 'KPI_UDF5',                    null,     -1,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'KPIId',                       null,     -3,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'KPIId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Day';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ActivityDate_DMY', null,      1,   null,          null, null,    null
insert into @ttLFE select 'Operation',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'SubOperation1',    null,      1,   null,          null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLines',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLocations',     null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumTasks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'SortOrder',        null,      1,   'Index',       null, null,    'Min'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'WHKPIPeriod.ThisWeek' /* Selection name */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Month-Year';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ActivityDate_MY',  null,      1,   null,          null, null,    null
insert into @ttLFE select 'Operation',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'SubOperation1',    null,      1,   'Category',    null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLines',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLocations',     null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumTasks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'SortOrder',        null,      1,   'Index',       null, null,    'Min'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'WHKPIPeriod.ThisMonth' /* Selection name */;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Quarter-Year';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ActivityDate_QY',  null,      1,   null,          null, null,    null
insert into @ttLFE select 'Operation',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'SubOperation1',    null,      1,   null,          null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLines',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLocations',     null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumTasks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'SortOrder',        null,      1,   'Index',       null, null,    'Min'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'WHKPIPeriod.ThisQuarter' /* Selection name */;

/******************************************************************************/
select @ContextName = 'List.WHKPICust',
       @DataSetName = 'vwWarehouseKPI';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default                  Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,                    null,  null,   99,     null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for WHKPICust - Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */

insert into @ttLF select 'Operation',                   null,      1,   null,               null, null
insert into @ttLF select 'AccountName',                 null,      1,   null,               null, null
insert into @ttLF select 'Account',                     null,      1,   null,               null, null

insert into @ttLF select 'SubOperation1',               null,     -1,   null,               null, null
insert into @ttLF select 'SubOperation2',               null,     -1,   null,               null, null
insert into @ttLF select 'SubOperation3',               null,     -1,   null,               null, null
insert into @ttLF select 'JobCode',                     null,     -1,   null,               null, null

insert into @ttLF select 'ActivityDate',                null,     -1,   null,               null, null

insert into @ttLF select 'NumWaves',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumOrders',                   null,      1,   null,               null, null
insert into @ttLF select 'NumLines',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumLocations',                null,      1,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,      1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,      1,   null,               null, null
insert into @ttLF select 'NumInnerPacks',               null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,      1,   null,               null, null
insert into @ttLF select 'NumTasks',                    null,      1,   null,               null, null
insert into @ttLF select 'NumPicks',                    null,      1,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,     -1,   null,               null, null

insert into @ttLF select 'Weight',                      null,     -1,   null,               null, null
insert into @ttLF select 'Volume',                      null,     -1,   null,               null, null

insert into @ttLF select 'Comment',                     null,     -2,   null,               null, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'Archived',                    null,     -1,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'SortOrder',                   null,     -1,   null,               null, null

insert into @ttLF select 'KPI_UDF1',                    null,     -1,   null,               null, null
insert into @ttLF select 'KPI_UDF2',                    null,     -1,   null,               null, null
insert into @ttLF select 'KPI_UDF3',                    null,     -1,   null,               null, null
insert into @ttLF select 'KPI_UDF4',                    null,     -1,   null,               null, null
insert into @ttLF select 'KPI_UDF5',                    null,     -1,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'KPIId',                       null,     -3,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'KPIId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Day';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ActivityDate_DMY', null,      1,   null,          null, null,    null
insert into @ttLFE select 'Operation',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'SubOperation1',    null,      1,   null,          null, null,    null
insert into @ttLFE select 'AccountName',      null,      1,   null,          null, null,    null
insert into @ttLFE select 'Warehouse',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLines',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLocations',     null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumTasks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'SortOrder',        null,      1,   'Index',       null, null,    'Min'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'WHKPICust.ThisWeek' /* Selection name */;


/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Month-Year';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ActivityDate_MY',  null,      1,   null,          null, null,    null
insert into @ttLFE select 'Operation',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'SubOperation1',    null,      1,   'Category',    null, null,    null
insert into @ttLFE select 'AccountName',      null,      1,   null,          null, null,    null
insert into @ttLFE select 'Warehouse',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLines',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLocations',     null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumTasks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'SortOrder',        null,      1,   'Index',       null, null,    'Min'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'WHKPICust.ThisMonth' /* Selection name */;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Quarter-Year';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ActivityDate_QY',  null,      1,   null,          null, null,    null
insert into @ttLFE select 'Operation',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'SubOperation1',    null,      1,   null,          null, null,    null
insert into @ttLFE select 'AccountName',      null,      1,   null,          null, null,    null
insert into @ttLFE select 'Warehouse',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLines',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLocations',     null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumTasks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPicks',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'SortOrder',        null,      1,   'Index',       null, null,    'Min'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'WHKPICust.ThisQuarter' /* Selection name */;


Go