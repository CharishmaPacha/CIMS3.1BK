/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV-1282)
  2020/04/24  MS      Changes to KeyField (HA-292)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/04/25  SPP     Inital Revision(CIMSV3-237)
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

select @ContextName = 'List.Rules',
       @DataSetName = 'vwRules'

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
insert into @ttLF select 'RuleId',                      null,   null,   null,               null, null
insert into @ttLF select 'RuleSetId',                   null,   null,   null,               null, null

insert into @ttLF select 'RuleSetName',                 null,   null,   null,               null, null
insert into @ttLF select 'RuleDescription',             null,   null,   null,               null, null
insert into @ttLF select 'RuleCondition',               null,   null,   null,               null, null
insert into @ttLF select 'RuleQuery',                   null,   null,   null,               null, null
insert into @ttLF select 'RuleQueryType',               null,     -1,   null,               null, null

insert into @ttLF select 'RuleConditionField',          null,     -2,   null,               null, null
insert into @ttLF select 'RuleConditionOperator',       null,     -2,   null,               null, null
insert into @ttLF select 'RuleConditionValues',         null,     -2,   null,               null, null

insert into @ttLF select 'RuleQuerySelect',             null,     -2,   null,               null, null
insert into @ttLF select 'RuleQueryFrom',               null,     -2,   null,               null, null
insert into @ttLF select 'RuleQueryWhere',              null,     -2,   null,               null, null

insert into @ttLF select 'SortSeq',                     null,      1,   null,               null, null
insert into @ttLF select 'Status',                      null,      1,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RuleId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
