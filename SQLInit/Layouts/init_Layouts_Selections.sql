/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/30  PKK     Corrected the file as per template (CIMSV-1282)
  2020/07/23  KBB     Corrected the visiblity (HA-1210),(CIMSV3-966)
  2020/06/05  KBB     Initial revision.(HA-549)
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

select @ContextName = 'List.Selections',
       @DataSetName = 'Selections';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                      */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,   null,    0,       null

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
insert into @ttLF select 'RecordId',                    null,     -3,   null,               null, null
insert into @ttLF select 'SelectionType',               null,   null,   null,               null, null
insert into @ttLF select 'ContextName',                 null,      1,   null,               null, null
insert into @ttLF select 'SelectionName',               null,   null,   null,               null, null
insert into @ttLF select 'SelectionDescription',        null,   null,   null,               null, null

insert into @ttLF select 'UserName',                    null,      1,   null,               null, null
insert into @ttLF select 'RoleId',                      null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null
insert into @ttLF select 'Visible',                     null,    -20,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;'  /* Key Fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/


/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'SelectionName',              'Count',     '# Selections: {0:n0}',       null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* Layout description */, @ttLSF;

Go
