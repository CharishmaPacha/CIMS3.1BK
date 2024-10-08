/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/25  SRS     Initial revision (BK-767).
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

select @ContextName = 'List.CIMSDE_ExportInvSnapshot',
       @DataSetName = 'vwCIMSDE_ExportInvSnapshot';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                      */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width  Display
                          Name                          Index           Caption                    Format */
insert into @ttLF select 'SnapshotId',                  null,   null,   null,               null, null
insert into @ttLF select 'SnapshotDate',                null,   null,   null,               null, null
insert into @ttLF select 'SnapshotDateTime',            null,   null,   null,               null, null
insert into @ttLF select 'SnapshotType',                null,   null,   null,               null, null

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'UPC',                         null,   null,   null,               null, null

insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'LPNOnhandStatus',             null,   null,   null,               null, null
insert into @ttLF select 'LPNStatus',                   null,   null,   null,               null, null
insert into @ttLF select 'LPNDetailId',                 null,   null,   null,               null, null
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Ownership ',                  null,   null,   null,               null, null

insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'AvailableIPs',                null,   null,   null,               null, null
insert into @ttLF select 'ReservedIPs',                 null,   null,   null,               null, null
insert into @ttLF select 'OnhandIPs',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceivedIPs',                 null,   null,   null,               null, null
insert into @ttLF select 'ToShipIPs',                   null,   null,   null,               null, null

insert into @ttLF select 'AvailableQty',                null,   null,   null,               null, null
insert into @ttLF select 'ReservedQty',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceivedQty',                 null,   null,   null,               null, null
insert into @ttLF select 'PutawayQty',                  null,   null,   null,               null, null
insert into @ttLF select 'AdjustedQty',                 null,   null,   null,               null, null
insert into @ttLF select 'ShippedQty',                  null,   null,   null,               null, null
insert into @ttLF select 'ToShipQty',                   null,   null,   null,               null, null
insert into @ttLF select 'OnhandQty',                   null,   null,   null,               null, null
insert into @ttLF select 'AvailableToSell',             null,   null,   null,               null, null

insert into @ttLF select 'OnhandValue',                 null,   null,   null,               null, null
insert into @ttLF select 'InventoryKey',                null,   null,   null,               null, null

insert into @ttLF select 'vwEOHINV_UDF1',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF2',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF3',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF4',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF5',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF6',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF7',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF8',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF9',               null,   null,   null,               null, null
insert into @ttLF select 'vwEOHINV_UDF10',              null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'RecordId',                    null,     11,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null
insert into @ttLF select 'CIMSRecId',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key Fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

insert into @ttLSF(FieldName,                    SummaryType, DisplayFormat,                AggregateMethod)
           select 'RecordId',                    'Count',     '# Records: {0:n0}',          null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* Layout description */, @ttLSF;

Go
