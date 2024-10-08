/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  PKK     Corrected file as per template (CIMSV3-1282)
  2019/04/30  RIA     Initial revision.
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

select @ContextName = 'List.SKUPrePacks',
       @DataSetName = 'vwSKUPrePacks';

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
insert into @ttLF select 'SKUPrePackId',                null,   null,   null,               null, null
insert into @ttLF select 'MasterSKUId',                 null,   null,   null,               null, null
insert into @ttLF select 'MasterSKU',                   null,      1,   null,               null, null
insert into @ttLF select 'MSKU1',                       null,   null,   null,               null, null
insert into @ttLF select 'MSKU2',                       null,   null,   null,               null, null
insert into @ttLF select 'MSKU3',                       null,   null,   null,               null, null
insert into @ttLF select 'MSKU4',                       null,   null,   null,               null, null
insert into @ttLF select 'MSKU5',                       null,   null,   null,               null, null
insert into @ttLF select 'MasterSKUDescription',        null,   null,   null,               null, null

insert into @ttLF select 'ComponentSKUId',              null,   null,   null,               null, null
insert into @ttLF select 'ComponentSKU',                null,      1,   null,               null, null
insert into @ttLF select 'CSKU1',                       null,   null,   null,               null, null
insert into @ttLF select 'CSKU2',                       null,   null,   null,               null, null
insert into @ttLF select 'CSKU3',                       null,   null,   null,               null, null
insert into @ttLF select 'CSKU4',                       null,   null,   null,               null, null
insert into @ttLF select 'CSKU5',                       null,   null,   null,               null, null
insert into @ttLF select 'ComponentSKUDescription',     null,   null,   null,               null, null

insert into @ttLF select 'ComponentQty',                null,      1,   null,               null, null
insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,   null,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'SKUPrePackId;'

Go