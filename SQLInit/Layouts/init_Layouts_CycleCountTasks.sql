/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/09  AY      Enabled TaskDesc (HA GoLive)
  2020/07/22  KBB     Corrected the DataSetName (CIMSV3-1024)
  2020/07/15  MS      Rename FileName & Change ContextName (CIMSV3-548)
  2019/05/14  KBB     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/01/09  RT      Initial revision (CIMSV3-206)
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

select @ContextName = 'List.CycleCountTasks',
       @DataSetName = 'vwCycleCountTasks';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

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
insert into @ttLF select 'TaskId',                      null,     -3,   null,               null, null
insert into @ttLF select 'BatchNo',                     null,   null,   'Batch No',         null, null
insert into @ttLF select 'TaskType',                    null,    -20,   null,               null, null
insert into @ttLF select 'TaskTypeDesc',                null,    -20,   null,               null, null
insert into @ttLF select 'TaskSubType',                 null,   null,   null,               null, null
insert into @ttLF select 'TaskSubTypeDesc',             null,   null,   'Type',             null, null
insert into @ttLF select 'TaskDesc',                    null,      1,   null,               null, null
insert into @ttLF select 'TaskStatus',                  null,   null,   null,               null, null
insert into @ttLF select 'TaskStatusDesc',              null,   null,   null,               null, null
insert into @ttLF select 'TaskStatusGroup',             null,   null,   null,               null, null

insert into @ttLF select 'ScheduledDate',               null,   null,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null

insert into @ttLF select 'DetailCount',                 null,   null,   null,               null, null
insert into @ttLF select 'CompletedCount',              null,   null,   null,               null, null
insert into @ttLF select 'PercentComplete',             null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'WarehouseDesc',               null,   null,   null,               null, null

insert into @ttLF select 'AssignedTo',                  null,     -1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'StartTime',                   null,     -1,   null,               null, null
insert into @ttLF select 'EndTime',                     null,     -1,   null,               null, null
insert into @ttLF select 'StopTime',                    null,     -1,   null,               null, null
insert into @ttLF select 'ElapsedMins',                 null,     -1,   null,               null, null
insert into @ttLF select 'DurationInMins',              null,     -1,   null,               null, null
insert into @ttLF select 'CompletedDate',               null,     -1,   null,               null, null
insert into @ttLF select 'PrintedDateTime',             null,     -1,   null,               null, null
insert into @ttLF select 'PrintDate',                   null,     -1,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Not applicable in this context */
insert into @ttLF select 'PickGroup',                   null,    -20,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,    -20,   null,               null, null
insert into @ttLF select 'NumLocations',                null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'TaskId;Location' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,           SummaryType, DisplayFormat,           AggregateMethod */
insert into @ttLSF select 'BatchNo',           'Count',     '# Batches: {0:n0}',     null

-- This won't work i.e. avergae of averages, so let's not do it.
--insert into @ttLSF select 'PercentComplete',   'Avg',       'Avg: {0:0.00}%',        null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* Layout description */, @ttLSF;

Go