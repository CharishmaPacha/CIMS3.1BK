/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/10/08  MRK     Added missing fields (HA-1430)
  2020/09/09  KBB     Added SummaryFieldsSetup (HA-1406)
  2020/07/17  KBB     Initial revision (CIMSV3-1024)
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

select @ContextName = 'List.CycleCountTaskDetails',
       @DataSetName = 'vwCycleCountTaskDetails';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

      /*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                                  Type    Layout   Description                      SelectionName                                   */
insert into @Layouts  select    'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts , 'DI' /* Delete & insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/*  Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'TaskDetailId',                null,     -3,   null,               null, null
insert into @ttLF select 'TaskId',                      null,     -3,   null,               null, null
insert into @ttLF select 'BatchNo',                     null,      1,   'Batch',            null, null
insert into @ttLF select 'Location',                    null,      1,   null,               null, null
insert into @ttLF select 'TaskType',                    null,     -2,   null,               null, null
insert into @ttLF select 'TaskTypeDesc',                null,     -2,   null,               null, null
insert into @ttLF select 'TaskStatus',                  null,     -2,   null,               null, null
insert into @ttLF select 'TaskSubType',                 null,     -2,   null,               null, null
insert into @ttLF select 'TaskSubTypeDesc',             null,     -2,   null,               null, null
insert into @ttLF select 'TaskStatusGroup',             null,     -2,   null,               null, null

insert into @ttLF select 'TaskDetailStatus',            null,   null,   null,               null, null
insert into @ttLF select 'TaskDetailStatusDesc',        null,   null,   'Status',           null, null
insert into @ttLF select 'TaskDetailStatusGroup',       null,     -1,   'Status Group',     null, null

insert into @ttLF select 'PutawayZone',                 null,     -2,   null,               null, null
insert into @ttLF select 'PickZone',                    null,     -2,   null,               null, null
insert into @ttLF select 'PutawayZoneDesc',             null,     -1,   null,               null, null
insert into @ttLF select 'PickZoneDesc',                null,      1,   null,               null, null

insert into @ttLF select 'TransactionDate',             null,     -1,   null,               null, null

insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'LocationRow',                 null,      1,   null,               null, null
insert into @ttLF select 'LocationSection',             null,      1,   null,               null, null
insert into @ttLF select 'LocationLevel',               null,      1,   null,               null, null
insert into @ttLF select 'LocationType',                null,   null,   null,               null, null
insert into @ttLF select 'LocationTypeDesc',            null,      1,   null,               null, null
insert into @ttLF select 'PickPath',                    null,      1,   null,               null, null
insert into @ttLF select 'PutawayPath',                 null,      1,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKUDescription',              null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'ScheduledDate',               null,     -1,   null,               null, null
insert into @ttLF select 'TaskPriority',                null,   null,   null,               null, null
insert into @ttLF select 'PickGroup',                   null,     -1,   null,               null, null

insert into @ttLF select 'vwCCT_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF5',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF6',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF7',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF8',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF9',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCT_UDF10',                 null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'TaskDetailId;' /* KeyFields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts in this context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'Location',                   'Count',     '# Locs: {0:n0}',             null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* Layout description */, @ttLSF;

Go