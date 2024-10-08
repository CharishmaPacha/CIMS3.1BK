/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/30  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/07/30  RV      Added PrintStatus (S2GCA-1199)
  2020/07/22  TK      Added CartType & other missing fields (HA-1176)
  2020/05/15  MS      Use vwUIPickTasks as Dataset(HA-566)
  2020/05/15  TK      Changes to display task status (HA-557)
  2019/08/14  MJ      Added StopTime, PrintDate, ElapsedMins, CompletedDate and Renamed PrintedDate as PrintedDateTime (OB2-900)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/01/11  KSK     Initial revision (CIMSV3-186)
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

select @ContextName = 'List.PickTasks',
       @DataSetName = 'vwUIPickTasks';

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
insert into @ttLF select 'TaskId',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveType',                    null,   null,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'TaskType',                    null,     -2,   null,               null, null -- Made invisible on purpose
insert into @ttLF select 'TaskTypeDesc',                null,     -2,   null,               null, null
insert into @ttLF select 'PickTaskSubType',             null,   null,   null,               null, null
insert into @ttLF select 'PickTaskSubTypeDesc',         null,   null,   null,               null, null
insert into @ttLF select 'TaskDesc',                    null,   null,   null,               null, null -- used for Row in CC tasks
insert into @ttLF select 'TaskStatus',                  null,   null,   null,               null, null
insert into @ttLF select 'TaskStatusDesc',              null,   null,   null,               null, null
insert into @ttLF select 'TaskStatusGroup',             null,   null,   null,               null, null

insert into @ttLF select 'DestZone',                    null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'CartType',                    null,   null,   null,               null, null
insert into @ttLF select 'DestLocation',                null,     -1,   null,               null, null

insert into @ttLF select 'TotalInnerPacks',             null,   null,   null,               null, null
insert into @ttLF select 'TotalIPsRemaining',           null,   null,   null,               null, null
insert into @ttLF select 'TotalIPsCompleted',           null,   null,   null,               null, null
insert into @ttLF select 'TotalUnits',                  null,   null,   null,                 60, null
insert into @ttLF select 'TotalUnitsRemaining',         null,   null,   null,               null, null
insert into @ttLF select 'TotalUnitsCompleted',         null,   null,   null,               null, null
insert into @ttLF select 'DetailCount',                 null,   null,   '# Picks',            60, null
insert into @ttLF select 'UnitsToPick',                 null,   null,   null,               null, null
insert into @ttLF select 'UnitsCompleted',              null,   null,   null,               null, null
insert into @ttLF select 'PercentUnitsComplete',        null,   null,   null,               null, null
insert into @ttLF select 'CompletedCount',              null,   null,   null,               null, null
insert into @ttLF select 'PercentComplete',             null,   null,   null,               null, null

insert into @ttLF select 'OrderCount',                  null,   null,   null,               null, null
insert into @ttLF select 'NumOrders',                   null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'NumTempLabels',               null,   null,   null,               null, null
insert into @ttLF select 'NumCases',                    null,   null,   null,               null, null
insert into @ttLF select 'NumLocations',                null,   null,   null,               null, null
insert into @ttLF select 'NumDestinatons',              null,   null,   null,               null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null

insert into @ttLF select 'LabelsPrinted',               null,   null,   null,               null, null
insert into @ttLF select 'PrintStatus',                 null,   null,   null,               null, null
insert into @ttLF select 'IsTaskConfirmed',             null,      1,   null,               null, null
insert into @ttLF select 'IsTaskAllocated',             null,   null,   null,               null, null
insert into @ttLF select 'DependencyFlags',             null,   null,   null,               null, null
insert into @ttLF select 'DependentOn',                 null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'WaveCancelDate',              null,   null,   null,               null, null
insert into @ttLF select 'WaveGroup',                   null,   null,   null,               null, null
insert into @ttLF select 'WaveShipDate',                null,   null,   null,               null, null
insert into @ttLF select 'WaveShipToStore',             null,   null,   null,               null, null
insert into @ttLF select 'PickZone',                    null,   null,   null,               null, null
insert into @ttLF select 'PutawayZone',                 null,   null,   null,               null, null
insert into @ttLF select 'PickZoneDescription',         null,   null,   null,               null, null
insert into @ttLF select 'PutawayZoneDescription',      null,   null,   null,               null, null
insert into @ttLF select 'AssignedTo',                  null,   null,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'ScheduledDate',               null,     -1,   null,               null, null

insert into @ttLF select 'WarehouseDescription',        null,   null,   null,               null, null

insert into @ttLF select 'StartLocation',               null,   null,   null,               null, null
insert into @ttLF select 'EndLocation',                 null,   null,   null,               null, null
insert into @ttLF select 'StartDestination',            null,   null,   null,               null, null
insert into @ttLF select 'EndDestination',              null,   null,   null,               null, null
insert into @ttLF select 'PicksFrom',                   null,   null,   null,               null, null
insert into @ttLF select 'PicksFor',                    null,   null,   null,               null, null
insert into @ttLF select 'PickZones',                   null,   null,   null,               null, null
insert into @ttLF select 'PickGroup',                   null,   null,   null,               null, null

insert into @ttLF select 'TaskCategory1',               null,   null,   null,               null, null
insert into @ttLF select 'TaskCategory2',               null,   null,   null,               null, null
insert into @ttLF select 'TaskCategory3',               null,   null,   null,               null, null
insert into @ttLF select 'TaskCategory4',               null,   null,   null,               null, null
insert into @ttLF select 'TaskCategory5',               null,   null,   null,               null, null
insert into @ttLF select 'StartTime',                   null,   null,   null,               null, null
insert into @ttLF select 'EndTime',                     null,     -1,   null,               null, null
insert into @ttLF select 'StopTime',                    null,   null,   null,               null, null
insert into @ttLF select 'ElapsedMins',                 null,   null,   null,               null, null
insert into @ttLF select 'DurationInMins',              null,   null,   null,               null, null
insert into @ttLF select 'CompletedDate',               null,   null,   null,               null, null
insert into @ttLF select 'PrintedDateTime',             null,   null,   null,               null, null
insert into @ttLF select 'PrintDate',                   null,   null,   null,               null, null

insert into @ttLF select 'PalletId',                    null,   null,   null,               null, null

insert into @ttLF select 'vwT_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'vwT_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'vwT_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'vwT_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'vwT_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'vwPT_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF5',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF6',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF7',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF8',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF9',                   null,   null,   null,               null, null
insert into @ttLF select 'vwPT_UDF10',                  null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'TaskId;TaskId' /* Key fields */;

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

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'TaskId',                     'Count',     '# Tasks: {0:n0}',            null
insert into @ttLSF select 'OrderCount',                 'Sum',       '{0:n0}',                     null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go