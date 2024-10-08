/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  PKK     Corrected the file as per template (CIMSV3-1282)
  2019/04/24  YJ      Initial revision.
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

select @ContextName = 'List.AllocationRules',
       @DataSetName = 'vwAllocationRules';

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

insert into @ttLF select 'SearchOrder',                 null,   null,   null,               null, null
insert into @ttLF select 'SearchSet',                   null,   null,   null,               null, null

insert into @ttLF select 'SearchType',                  null,   null,   null,               null, null

insert into @ttLF select 'WaveType',                    null,   null,   null,               null, null
insert into @ttLF select 'WaveTypeDescription',         null,   null,   null,               null, null

insert into @ttLF select 'SKUABCClass',                 null,   null,   null,               null, null
insert into @ttLF select 'ReplenishClass',              null,     -1,   null,               null, null
insert into @ttLF select 'RuleGroup',                   null,   null,   null,               null, null

insert into @ttLF select 'LocationType',                null,   null,   null,               null, null
insert into @ttLF select 'LocationTypeDescription',     null,   null,   null,               null, null
insert into @ttLF select 'LocationSubType',             null,   null,   null,               null, null
insert into @ttLF select 'StorageType',                 null,   null,   null,               null, null

insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null

insert into @ttLF select 'PickingClass',                null,   null,   null,               null, null
insert into @ttLF select 'PickingZone',                 null,   null,   null,               null, null
insert into @ttLF select 'PutawayClass',                null,   null,   null,               null, null

insert into @ttLF select 'QuantityCondition',           null,   null,   null,               null, null

insert into @ttLF select 'OrderByField',                null,   null,   null,               null, null
insert into @ttLF select 'OrderByType',                 null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,     -1,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,   null,   null,               null, null

insert into @ttLF select 'ConsiderRuleGroup',           null,     -1,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, 'vwAllocationRules', 'RecordId'

Go
