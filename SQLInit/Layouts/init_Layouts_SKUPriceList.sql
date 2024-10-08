/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person   Comments

  2020/10/08  MRK      Added missing fields (HA-1430)
  2020/03/18  KBB      Initial revision (CID-1227)
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

select @ContextName = 'List.SKUPriceLists',
       @DataSetName = 'vwSKUPriceList';

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
insert into @ttLF select 'RecordId',                     null,   null,   null,              null, null
insert into @ttLF select 'SKU',                          null,      1,   null,              null, null
insert into @ttLF select 'SoldToId',                     null,      1,   null,              null, null
insert into @ttLF select 'CustSKU',                      null,      1,   null,              null, null
insert into @ttLF select 'RetailUnitPrice',              null,      1,   null,              null, null
insert into @ttLF select 'UnitSalePrice',                null,      1,   null,              null, null
insert into @ttLF select 'Price1',                       null,   null,   null,              null, null
insert into @ttLF select 'Price2',                       null,   null,   null,              null, null
insert into @ttLF select 'Price3',                       null,   null,   null,              null, null
insert into @ttLF select 'Status',                       null,      1,   null,              null, null

insert into @ttLF select 'SKUId',                        null,   null,   null,              null, null
insert into @ttLF select 'UniqueId',                     null,   null,   null,              null, null

insert into @ttLF select 'Validated',                    null,   null,   null,              null, null
insert into @ttLF select 'ValidationMsg',                null,   null,   null,              null, null

insert into @ttLF select 'BusinessUnit',                 null,   null,   null,              null, null
insert into @ttLF select 'CreatedDate',                  null,   null,   null,              null, null
insert into @ttLF select 'CreatedBy',                    null,   null,   null,              null, null
insert into @ttLF select 'ModifiedDate',                 null,   null,   null,              null, null

insert into @ttLF select 'DisplaySKU',                   null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU1',                  null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU2',                  null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU3',                  null,   null,   null,              null, null
insert into @ttLF select 'ModifiedBy',                   null,   null,   null,              null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;UniqueId' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
