/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/08  VM      Initial revision.
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

select @ContextName = 'List.***',
       @DataSetName = 'vw....';

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
insert into @ttLF select 'Field1',                      null,   null,   null,               null, null
insert into @ttLF select 'Field2',                      null,   null,   null,               null, null
insert into @ttLF select 'Field3',                      null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'EntityId;EntityKey' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary description here...';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'SummaryField1',              null,      1,   null,               null, null,    null
insert into @ttLFE select 'SummaryField2',              null,      1,   null,               null, null,    null
insert into @ttLFE select 'SummaryField3',              null,      1,   'FieldCaption',     null, null,    'DCount'
insert into @ttLFE select 'SummaryField4',              null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'SummaryField5',              null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'SummaryField6',              null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary description here...';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'SummaryField1',              null,      1,   null,               null, null,    null
insert into @ttLFE select 'SummaryField2',              null,      1,   'FieldCaption',     null, null,    'DCount'
insert into @ttLFE select 'SummaryField3',              null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'SummaryField4',              null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'SummaryField5',              null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

insert into @ttLSF(FieldName,                    SummaryType, DisplayFormat,                AggregateMethod)
            select 'SummaryField1',              'Count',     '# Caption:{0:n0}',           null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
