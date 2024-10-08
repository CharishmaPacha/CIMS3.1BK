/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/04/06  NB      Initial revision.
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

select @ContextName = 'CreateInventory.FormLayout';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, null, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

 /*****************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'SKU',                         null,      1,   null,               null, null
insert into @ttLF select 'Description',                 null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,      1,   null,               null, null
insert into @ttLF select 'SKU2',                        null,      1,   null,               null, null
insert into @ttLF select 'SKU3',                        null,     -1,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU1Description',             null,     -1,   null,               null, null
insert into @ttLF select 'SKU2Description',             null,     -1,   null,               null, null
insert into @ttLF select 'SKU3Description',             null,     -1,   null,               null, null
insert into @ttLF select 'SKU4Description',             null,     -1,   null,               null, null
insert into @ttLF select 'SKU5Description',             null,     -1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

Go