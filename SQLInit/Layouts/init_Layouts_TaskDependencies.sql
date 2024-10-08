/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/12  MS      Initial revision.
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

select @ContextName = 'List.TaskDependencies',
       @DataSetName = 'pr_Waves_DS_GetDependencies';

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

insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'Task',                        null,   null,   null,               null, null
insert into @ttLF select 'NumOrders',                   null,   null,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveType',                    null,   null,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,   null,   null,               null, null
insert into @ttLF select 'ReplenishTask',               null,   null,   null,               null, null
insert into @ttLF select 'ReplenishLPN',                null,   null,   null,               null, null
insert into @ttLF select 'ReplenishLPNQty',             null,   null,   null,               null, null
insert into @ttLF select 'ReplenishLPNStatus',          null,   null,   null,               null, null
insert into @ttLF select 'ReplenishLPNLocation',        null,   null,   null,               null, null
insert into @ttLF select 'PickBin',                     null,   null,   null,               null, null
insert into @ttLF select 'PickBinQty',                  null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKUDesc',                     null,   null,   null,               null, null
insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, ';WaveId' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
