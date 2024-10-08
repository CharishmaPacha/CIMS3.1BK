/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/04  VS      Added SKUImageURL (BK-1053)
  2021/07/08  SPP     Added New Field AppointmentDateTime (HA-2969)
  2020/11/05  MS      Added New Fields SortLanes & SortOptions (JL-294)
  2020/09/10  MS      Added RH&RD UDF's (JL-241)
  2020/03/30  MS      Added InventoryClasses (HA-83)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2017/09/29  YJ      pr_Setup_Layout: Change to setup Layouts using procedure (CIMSV3-72)
  2017/09/29  YJ      Initial revision.
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

select @ContextName = 'List.ReceiptDetails',
       @DataSetName = 'vwReceiptDetails';

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
insert into @ttLF select 'ReceiptDetailId',             null,   null,    null,              null, null
insert into @ttLF select 'ReceiptLine',                 null,     -2,    'Line #',            60, null -- deprecated
insert into @ttLF select 'ReceiptId',                   null,   null,    null,              null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,    null,              null, null
insert into @ttLF select 'ReceiptType',                 null,   null,    null,              null, null
insert into @ttLF select 'ReceiptTypeDesc',             null,   null,    null,              null, null
insert into @ttLF select 'ReceiptStatus',               null,   null,    null,              null, null
insert into @ttLF select 'ReceiptStatusDesc',           null,   null,    null,              null, null

insert into @ttLF select 'HostReceiptLine',             null,   null,    null,              null, null
insert into @ttLF select 'SKUId',                       null,   null,    null,              null, null
insert into @ttLF select 'SKU',                         null,   null,    null,              null, null
insert into @ttLF select 'SKU1',                        null,   null,    null,              null, null
insert into @ttLF select 'SKU2',                        null,   null,    null,              null, null
insert into @ttLF select 'SKU3',                        null,   null,    null,              null, null
insert into @ttLF select 'SKU4',                        null,   null,    null,              null, null
insert into @ttLF select 'SKU5',                        null,   null,    null,              null, null

insert into @ttLF select 'SKUDescription',              null,   null,    null,              null, null
insert into @ttLF select 'SKU1Description',             null,   null,    null,              null, null
insert into @ttLF select 'SKU2Description',             null,   null,    null,              null, null
insert into @ttLF select 'SKU3Description',             null,   null,    null,              null, null
insert into @ttLF select 'SKU4Description',             null,   null,    null,              null, null
insert into @ttLF select 'SKU5Description',             null,   null,    null,              null, null

insert into @ttLF select 'QtyOrdered',                  null,   null,    null,              null, null
insert into @ttLF select 'QtyInTransit',                null,   null,    null,              null, null
insert into @ttLF select 'QtyReceived',                 null,   null,    null,              null, null
insert into @ttLF select 'QtyToReceive',                null,   null,    null,              null, null

insert into @ttLF select 'LPNsInTransit',               null,   null,    null,              null, null
insert into @ttLF select 'LPNsReceived',                null,     -1,    null,              null, null

insert into @ttLF select 'ExtraQtyAllowed',             null,   null,    null,              null, null
insert into @ttLF select 'MaxQtyAllowedToReceive',      null,   null,    null,              null, null
insert into @ttLF select 'QtyToLabel',                  null,   null,    null,              null, null

insert into @ttLF select 'VendorId',                    null,   null,    null,              null, null
insert into @ttLF select 'VendorName',                  null,   null,    null,              null, null
insert into @ttLF select 'Ownership',                   null,   null,    null,              null, null
insert into @ttLF select 'OwnershipDesc',               null,   null,    null,              null, null
insert into @ttLF select 'Warehouse',                   null,   null,    null,              null, null
insert into @ttLF select 'WarehouseDesc',               null,   null,    null,              null, null
insert into @ttLF select 'BUDescription',               null,   null,    null,              null, null
insert into @ttLF select 'DateOrdered',                 null,   null,    null,              null, null
insert into @ttLF select 'DateExpected',                null,   null,    null,              null, null
insert into @ttLF select 'AppointmentDateTime',         null,   null,    null,              null, null

insert into @ttLF select 'UPC',                         null,     -1,    null,              null, null
insert into @ttLF select 'UoM',                         null,     -1,    null,              null, null
insert into @ttLF select 'UoMDescription',              null,   null,    null,              null, null
insert into @ttLF select 'CoO',                         null,   null,    null,              null, null
insert into @ttLF select 'Description',                 null,     -2,    null,              null, null  -- deprecated, we added SKU description above

insert into @ttLF select 'Lot',                         null,   null,    null,              null, null
insert into @ttLF select 'InventoryClass1',             null,   null,    null,              null, null
insert into @ttLF select 'InventoryClass2',             null,   null,    null,              null, null
insert into @ttLF select 'InventoryClass3',             null,   null,    null,              null, null

insert into @ttLF select 'SortLanes',                   null,   null,    null,              null, null
insert into @ttLF select 'SortOptions',                 null,   null,    null,              null, null
insert into @ttLF select 'SortStatus',                  null,   null,    null,              null, null

insert into @ttLF select 'UnitCost',                    null,   null,    null,              null, null
insert into @ttLF select 'CustPO',                      null,   null,    null,              null, null
insert into @ttLF select 'PackingSlipNumber',           null,   null,    null,              null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,    null,              null, null

insert into @ttLF select 'SKUImageURL',                 null,   null,    null,              null, null
insert into @ttLF select 'SKU_UDF1',                    null,   null,    null,              null, null
insert into @ttLF select 'SKU_UDF2',                    null,   null,    null,              null, null
insert into @ttLF select 'SKU_UDF3',                    null,   null,    null,              null, null
insert into @ttLF select 'SKU_UDF4',                    null,   null,    null,              null, null
insert into @ttLF select 'SKU_UDF5',                    null,   null,    null,              null, null

insert into @ttLF select 'RH_UDF1',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF2',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF3',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF4',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF5',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF6',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF7',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF8',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF9',                     null,   null,    null,              null, null
insert into @ttLF select 'RH_UDF10',                    null,   null,    null,              null, null

insert into @ttLF select 'RD_UDF1',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF2',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF3',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF4',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF5',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF6',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF7',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF8',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF9',                     null,   null,    null,              null, null
insert into @ttLF select 'RD_UDF10',                    null,   null,    null,              null, null

insert into @ttLF select 'BusinessUnit',                null,   null,    null,              null, null
insert into @ttLF select 'CreatedDate',                 null,   null,    null,              null, null
insert into @ttLF select 'ModifiedDate',                null,   null,    null,              null, null
insert into @ttLF select 'CreatedBy',                   null,   null,    null,              null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,    null,              null, null

/* Deprecated Fields */
insert into @ttLF select 'UDF1',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF2',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF3',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF4',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF5',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF6',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF7',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF8',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF9',                        null,   null,    null,              null, null
insert into @ttLF select 'UDF10',                       null,   null,    null,              null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'ReceiptDetailId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Receipt & SKU';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'ReceiptNumber',              null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU',                        null,        1, null,               null, null,    null
insert into @ttLFE select 'QtyOrdered',                 null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyInTransit',               null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyReceived',                null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyToReceive',               null,        1, null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'OpenReceipts';

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by SKU & ETA';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'SKU',                        null,        1, null,               null, null,    null
insert into @ttLFE select 'SKUDescription',             null,        1, null,               null, null,    null
insert into @ttLFE select 'ETAWH',                      null,        1, null,               null, null,    null
insert into @ttLFE select 'QtyOrdered',                 null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyInTransit',               null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyReceived',                null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyToReceive',               null,        1, null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'OpenReceipts';

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Style, Color';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'SKU1',                       null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU2',                       null,        1, null,               null, null,    null
insert into @ttLFE select 'QtyOrdered',                 null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyInTransit',               null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyReceived',                null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyToReceive',               null,        1, null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'OpenReceipts';

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Type & SKU';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'ReceiptTypeDesc',            null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU',                        null,        1, null,               null, null,    null
insert into @ttLFE select 'QtyOrdered',                 null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyInTransit',               null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyReceived',                null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'QtyToReceive',               null,        1, null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'OpenReceipts';

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
