/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/16  SJ      Added missing fields (JL-48)
  2020/09/30  SAK     Changed visibility as 11 for RecordId field (JL-147)
  2019/05/23  RKC     Initial revision (CIMSV3-550).
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

select @ContextName = 'List.CIMSDE_ImportASNLPNs',
       @DataSetName = 'vwCIMSDE_ImportASNLPNs';

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

insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNWeight',                   null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'PalletId',                    null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'ASNCase',                     null,   null,   null,               null, null

insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null

insert into @ttLF select 'ReceivedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ExpiryDate',                  null,   null,   null,               null, null
insert into @ttLF select 'DestWarehouse',               null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'InventoryStatus',             null,   null,   null,               null, null
insert into @ttLF select 'OnhandStatus',                null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null

insert into @ttLF select 'LPNDetailId',                 null,   null,   null,               null, null
insert into @ttLF select 'LPNLine',                     null,   null,   null,               null, null

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerPackage',             null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null
insert into @ttLF select 'PrevLPNQty',                  null,   null,   null,               null, null
insert into @ttLF select 'PrevLPNInnerPacks',           null,   null,   null,               null, null
insert into @ttLF select 'ReceivedUnits',               null,   null,   null,               null, null
insert into @ttLF select 'Weight',                      null,   null,   null,               null, null
insert into @ttLF select 'Volume',                      null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null
insert into @ttLF select 'CoO',                         null,   null,   null,               null, null

insert into @ttLF select 'ReceiptDetailId',             null,   null,   null,               null, null
insert into @ttLF select 'HostNumLines',                null,   null,   null,               null, null
insert into @ttLF select 'HostReceiptLine',             null,   null,   null,               null, null

insert into @ttLF select 'LPN_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF5',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF6',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF7',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF8',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF9',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF10',                   null,   null,   null,               null, null

insert into @ttLF select 'LPND_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF5',                   null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'InputXML',                    null,   null,   null,               null, null
insert into @ttLF select 'ResultXML',                   null,   null,   null,               null, null

insert into @ttLF select 'HostRecId',                   null,      1,   null,               null, null
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
