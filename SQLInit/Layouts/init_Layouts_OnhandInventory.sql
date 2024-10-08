/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/04/06  YJ      Added InventoryClass fields (HA-87)
  2019/05/25  AY      Standardized and added summary layouts
  2019/03/24  RIA     Initial revision
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

select @ContextName = 'List.OnhandInventory',
       @DataSetName = 'vwExportsOnhandInventory';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                      */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null
insert into @Layouts select 'S',    'N',     'Summary by LPN & SKU',       null,          null,  null,   0,      null
insert into @Layouts select 'S',    'N',     'Summary by SKU',             null,          null,  null,   0,      null
insert into @Layouts select 'S',    'N',     'Summary by Style',           null,          null,  null,   0,      null

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
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'Description',                 null,   null,   null,                140, null
insert into @ttLF select 'SKU1Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU2Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU3Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU4Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU5Description',             null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,      1,   null,               null, null

insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null

insert into @ttLF select 'Quantity',                    null,      1,   null,               null, null
insert into @ttLF select 'ReservedQty',                 null,   null,   null,               null, null
insert into @ttLF select 'AvailableQty',                null,      1,   null,               null, null
insert into @ttLF select 'ReceivedQty',                 null,   null,   null,               null, null

insert into @ttLF select 'OnhandValue',                 null,   null,   null,               null, null

insert into @ttLF select 'InnerPacks',                  null,     -1,   null,               null, null
insert into @ttLF select 'ReservedIPs',                 null,   null,   null,               null, null
insert into @ttLF select 'AvailableIPs',                null,   null,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null
insert into @ttLF select 'ExpiryDate',                  null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,     -1,   null,               null, null
insert into @ttLF select 'UnitPrice',                   null,   null,   null,               null, null
insert into @ttLF select 'Brand',                       null,     -1,   null,               null, null
insert into @ttLF select 'ProdCategory',                null,     -1,   null,               null, null
insert into @ttLF select 'ProdSubCategory',             null,     -1,   null,               null, null
insert into @ttLF select 'ABCClass',                    null,   null,   null,               null, null
insert into @ttLF select 'SKUSortOrder',                null,   null,   null,               null, null

insert into @ttLF select 'Businessunit',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, null /* KeyFields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by LPN & SKU';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'SKU',              null,   1,      null,          null, null,    null
insert into @ttLFE select 'SKU1',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU2',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU3',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU4',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU5',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'Description',      null,   null,   null,          null, null,    null
insert into @ttLFE select 'LPN',              null,   null,   null,          null, null,    null

insert into @ttLFE select 'Quantity',         null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'ReservedQty',      null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'AvailableQty',     null,   1,      null,          null, null,    'Sum'
insert into @ttLFE select 'ReceivedQty',      null,   null,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by SKU';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'SKU',              null,   1,      null,          null, null,    null
insert into @ttLFE select 'SKU1',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU2',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU3',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU4',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU5',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'Description',      null,   null,   null,          null, null,    null
insert into @ttLFE select 'Warehouse',        null,   null,   null,          null, null,    null
insert into @ttLFE select 'Location',         null,   null,   null,          null, null,    'DCount'
insert into @ttLFE select 'Quantity',         null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'ReservedQty',      null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'AvailableQty',     null,   1,      null,          null, null,    'Sum'
insert into @ttLFE select 'ReceivedQty',      null,   null,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Style';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'SKU1',             null,   null,   null,          null, null,    null
insert into @ttLFE select 'Description',      null,   null,   null,          null, null,    null
insert into @ttLFE select 'Warehouse',        null,   null,   null,          null, null,    null
insert into @ttLFE select 'Location',         null,   null,   null,          null, null,    'DCount'
insert into @ttLFE select 'Quantity',         null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'ReservedQty',      null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'AvailableQty',     null,   1,      null,          null, null,    'Sum'
insert into @ttLFE select 'ReceivedQty',      null,   null,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'ReservedQty',                'Sum',       '{0:n0}',                     null
insert into @ttLSF select 'AvailableQty',               'Sum',       '{0:n0}',                     null
insert into @ttLSF select 'ReceivedQty',                'Sum',       '{0:n0}',                     null

insert into @ttLSF select 'ReservedIPs',                'Sum',       '{0:n0}',                     null
insert into @ttLSF select 'AvailableIPs',               'Sum',       '{0:n0}',                     null
insert into @ttLSF select 'ReceivedIPs',                'Sum',       '{0:n0}',                     null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;


Go