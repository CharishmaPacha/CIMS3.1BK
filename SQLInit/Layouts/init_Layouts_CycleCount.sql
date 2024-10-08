/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

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

select @ContextName = 'List.CycleCounts',
       @DataSetName = 'vwTasks';

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

/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select 'TaskId',            null,     -2,   null,          null, null
insert into @ttLF select 'BatchNo',           null,   null,   'Batch No',    null, null
insert into @ttLF select 'TaskType',          null,     -2,   null,          null, null
insert into @ttLF select 'TaskTypeDescription',
                                              null,     -2,   null,          null, null
insert into @ttLF select 'TaskSubType',       null,   null,   null,          null, null
insert into @ttLF select 'TaskSubTypeDescription',
                                              null,   null,   'Type',        null, null
insert into @ttLF select 'TaskDesc',          null,   null,   'Print Time',  null, null
insert into @ttLF select 'ScheduledDate',     null,   null,   null,          null, null
insert into @ttLF select 'Status',            null,   null,   null,          null, null
insert into @ttLF select 'Priority',          null,   null,   null,          null, null
insert into @ttLF select 'StatusDescription', null,   null,   null,          null, null

insert into @ttLF select 'DetailCount',       null,   null,   null,          null, null
insert into @ttLF select 'CompletedCount',    null,   null,   null,          null, null
insert into @ttLF select 'PercentComplete',   null,   null,   null,          null, null

insert into @ttLF select 'PickZoneDescription',
                                              null,     -1,   null,          null, null
insert into @ttLF select 'Warehouse',         null,     -1,   null,          null, null
insert into @ttLF select 'AssignedTo',        null,     -1,   null,          null, null

insert into @ttLF select 'TotalInnerPacks',   null,     -2,   null,          null, null
insert into @ttLF select 'TotalUnits',        null,     -2,   null,          null, null
insert into @ttLF select 'OrderCount',        null,     -2,   null,          null, null
insert into @ttLF select 'LabelsPrinted',     null,     -2,   null,          null, null
insert into @ttLF select 'IsTaskAllocated',   null,     -2,   null,          null, null
insert into @ttLF select 'DependencyFlags',   null,     -2,   null,          null, null
insert into @ttLF select 'DependentOn',       null,     -2,   null,          null, null
insert into @ttLF select 'Ownership',         null,   null,   null,          null, null

insert into @ttLF select 'Account',           null,     -2,   null,          null, null
insert into @ttLF select 'AccountName',       null,     -2,   null,          null, null
insert into @ttLF select 'WaveCancelDate',    null,     -2,   null,          null, null
insert into @ttLF select 'WaveGroup',         null,     -2,   null,          null, null

insert into @ttLF select 'BatchType',         null,     -2,   null,          null, null
insert into @ttLF select 'BatchTypeDesc',     null,     -2,   null,          null, null
insert into @ttLF select 'PickZone',          null,     -2,   null,          null, null
insert into @ttLF select 'PutawayZone',       null,     -2,   null,          null, null
insert into @ttLF select 'PutawayZoneDescription',
                                              null,     -2,   null,          null, null
insert into @ttLF select 'WarehouseDescription',
                                              null,     -2,   null,          null, null
insert into @ttLF select 'DestZone',          null,     -2,   null,          null, null
insert into @ttLF select 'DestLocation',      null,     -2,   null,          null, null
insert into @ttLF select 'PalletId',          null,   null,   null,          null, null
insert into @ttLF select 'Pallet',            null,     -2,   null,          null, null

insert into @ttLF select 'TaskCategory1',     null,     -2,   null,          null, null
insert into @ttLF select 'TaskCategory2',     null,     -2,   null,          null, null
insert into @ttLF select 'TaskCategory3',     null,     -2,   null,          null, null
insert into @ttLF select 'TaskCategory4',     null,     -2,   null,          null, null
insert into @ttLF select 'TaskCategory5',     null,     -2,   null,          null, null

insert into @ttLF select 'StartTime',         null,     -1,   null,          null, null
insert into @ttLF select 'EndTime',           null,     -1,   null,          null, null
insert into @ttLF select 'DurationInMins',    null,     -1,   null,          null, null

insert into @ttLF select 'vwT_UDF1',          null,   null,   null,          null, null
insert into @ttLF select 'vwT_UDF2',          null,   null,   null,          null, null
insert into @ttLF select 'vwT_UDF3',          null,   null,   null,          null, null
insert into @ttLF select 'vwT_UDF4',          null,   null,   null,          null, null
insert into @ttLF select 'vwT_UDF5',          null,   null,   null,          null, null

insert into @ttLF select 'vwPT_UDF1',         null,   null,   null,          null, null
insert into @ttLF select 'vwPT_UDF2',         null,   null,   null,          null, null
insert into @ttLF select 'vwPT_UDF3',         null,   null,   null,          null, null
insert into @ttLF select 'vwPT_UDF4',         null,   null,   null,          null, null
insert into @ttLF select 'vwPT_UDF5',         null,   null,   null,          null, null

insert into @ttLF select 'Archived',          null,   null,   null,          null, null
insert into @ttLF select 'BusinessUnit',      null,   null,   null,          null, null
insert into @ttLF select 'ModifiedDate',      null,   null,   null,          null, null
insert into @ttLF select 'ModifiedBy',        null,   null,   null,          null, null
insert into @ttLF select 'CreatedDate',       null,   null,   null,          null, null
insert into @ttLF select 'CreatedBy',         null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'TaskId;BatchNo' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

Go
