/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/16  SJ      Added missing fields & changed the order of fields (JL-48)
  2020/09/30  SAK     Changed visibility as 11 for RecordId field (JL-147)
  2020/02/17  AJM     Added missing fields, changed the ContextName, DataSetName (JL-49)
  2019/04/22  PHK     Initial revision.
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

select @ContextName = 'List.CIMSDE_OnhandInventory',
       @DataSetName = 'vwCIMSDE_ExportOnhandInventory';

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

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null

insert into @ttLF select 'AvailableQty',                null,      1,   null,               null, null
insert into @ttLF select 'ReservedQty',                 null,      1,   null,               null, null
insert into @ttLF select 'OnhandQty',                   null,      1,   null,               null, null
insert into @ttLF select 'ReceivedQty',                 null,      1,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null
insert into @ttLF select 'LotNumber',                   null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNTypeDescription',          null,   null,   null,               null, null

insert into @ttLF select 'TransDateTime',               null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'CIMSRecId',                   null,   null,   null,               null, null
insert into @ttLF select 'RecordId',                    null,     11,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,               null, null
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
