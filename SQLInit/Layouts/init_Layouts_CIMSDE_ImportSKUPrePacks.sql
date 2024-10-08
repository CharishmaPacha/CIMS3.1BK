/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/18  MS      Added Missing Fields & Code Cleanup (JL-48)
  2019/05/10  RKC     Initial revision (CIMSV3-550).
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

select @ContextName = 'List.CIMSDE_ImportSKUPrePacks',
       @DataSetName = 'vwCIMSDE_ImportSKUPrePacks';

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
insert into @ttLF select 'RecordType',                  null,     -1,   null,               null, null
insert into @ttLF select 'RecordAction',                null,   null,   null,               null, null

insert into @ttLF select 'MasterSKU',                   null,   null,   null,               null, null
insert into @ttLF select 'MasterSKU1',                  null,   null,   null,               null, null
insert into @ttLF select 'MasterSKU2',                  null,   null,   null,               null, null
insert into @ttLF select 'MasterSKU3',                  null,   null,   null,               null, null
insert into @ttLF select 'MasterSKU4',                  null,   null,   null,               null, null
insert into @ttLF select 'MasterSKU5',                  null,   null,   null,               null, null

insert into @ttLF select 'ComponentSKU',                null,      1,   null,               null, null
insert into @ttLF select 'ComponentSKU1',               null,   null,   null,               null, null
insert into @ttLF select 'ComponentSKU2',               null,   null,   null,               null, null
insert into @ttLF select 'ComponentSKU3',               null,   null,   null,               null, null
insert into @ttLF select 'ComponentSKU4',               null,   null,   null,               null, null
insert into @ttLF select 'ComponentSKU5',               null,   null,   null,               null, null

insert into @ttLF select 'ComponentQty',                null,      1,   null,               null, null

insert into @ttLF select 'MasterSKUId',                 null,   null,   null,               null, null
insert into @ttLF select 'ComponentSKUId',              null,   null,   null,               null, null
insert into @ttLF select 'SKUPrePackId',                null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null

insert into @ttLF select 'SPP_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'SPP_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'SPP_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'SPP_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'SPP_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'InputXML',                    null,   null,   null,               null, null
insert into @ttLF select 'ResultXML',                   null,   null,   null,               null, null

insert into @ttLF select 'HostRecId',                   null,      1,   null,               null, null
insert into @ttLF select 'RecordId',                    null,      1,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,               null, null
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;SKUPrePackId';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
