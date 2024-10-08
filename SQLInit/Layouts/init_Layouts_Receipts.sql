/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/04  AJM     Added HostNumLines, PrepareRecvFlag, PreprocessFlag, SourceSystem, ModifiedOn (CIMSV3-1334)
  2020/11/05  MS      Added New Fields SortLanes & SortOptions (JL-294)
  2020/08/05  SJ      Added AppointmentDateTime for Standard layout (HA-1228)
  2020/05/04  AY      Moved WH to front as that is key info for a multi-WH operation
  2020/04/25  MS      Fixes in selection & Layouts (HA-293)
  2020/04/20  VM      Added: Summary by Receipt Type (HA-241)
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

select @ContextName = 'List.ReceiptHeaders',
       @DataSetName = 'vwReceiptHeaders';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                          */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Pending Receipts',              null,                 null,  null,   0,      null

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
insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptType',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceiptTypeDesc',             null,   null,   null,               null, null

insert into @ttLF select 'ReceiptStatus',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptStatusDesc',           null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,     -2,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'VendorId',                    null,   null,   null,               null, null
insert into @ttLF select 'VendorName',                  null,     -1,   null,               null, null

insert into @ttLF select 'HostNumLines',                null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   '# Ordered',          70, null
insert into @ttLF select 'UnitsInTransit',              null,   null,   null,               null, null
insert into @ttLF select 'UnitsReceived',               null,   null,   null,               null, null
insert into @ttLF select 'QtyToReceive',                null,   null,   null,               null, null
insert into @ttLF select 'LPNsInTransit',               null,   null,   null,               null, null
insert into @ttLF select 'LPNsReceived',                null,   null,   null,               null, null

insert into @ttLF select 'ETACountry',                  null,     -1,   null,               null, null
insert into @ttLF select 'ETACity',                     null,     -1,   null,               null, null
insert into @ttLF select 'ETAWarehouse',                null,   null,   null,               null, null
insert into @ttLF select 'AppointmentDateTime',         null,   null,   null,               null, null

insert into @ttLF select 'ContainerNo',                 null,   null,   null,               null, null
insert into @ttLF select 'BillNo',                      null,   null,   null,               null, null
insert into @ttLF select 'SealNo',                      null,   null,   null,               null, null
insert into @ttLF select 'InvoiceNo',                   null,   null,   null,               null, null
insert into @ttLF select 'Vessel',                      null,   null,   null,               null, null
insert into @ttLF select 'ContainerSize',               null,   null,   null,               null, null

insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null

insert into @ttLF select 'SortLanes',                   null,   null,   null,               null, null
insert into @ttLF select 'SortOptions',                 null,   null,   null,               null, null
insert into @ttLF select 'PrepareRecvFlag',             null,   null,   null,               null, null
insert into @ttLF select 'PreprocessFlag',              null,   null,   null,               null, null
insert into @ttLF select 'DateOrdered',                 null,     -1,   null,               null, null
insert into @ttLF select 'DateShipped',                 null,   null,   null,               null, null
insert into @ttLF select 'DateExpected',                null,   null,   null,               null, null

insert into @ttLF select 'Ownership',                   null,     -1,   null,               null, null  -- Ownership is by default not visible

insert into @ttLF select 'UDF1',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,               null, null

insert into @ttLF select 'ROH_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'ROH_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'ROH_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'ROH_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'ROH_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'vwROH_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwROH_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwROH_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwROH_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwROH_UDF5',                  null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'ModifiedOn',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'ReceiptId;ReceiptNumber' /* Key fields */;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Pending Receipts */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'ReceiptTypeDesc',             null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,      1,   null,               null, null
insert into @ttLF select 'ReceiptStatus',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptStatusDesc',           null,   null,   null,               null, null

insert into @ttLF select 'VendorName',                  null,      1,   null,               null, null
insert into @ttLF select 'Vessel',                      null,      1,   null,               null, null
insert into @ttLF select 'ContainerNo',                 null,      1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,      1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,      1,   null,               null, null
insert into @ttLF select 'BillNo',                      null,      1,   null,               null, null
insert into @ttLF select 'SealNo',                      null,      1,   null,               null, null
insert into @ttLF select 'InvoiceNo',                   null,      1,   null,               null, null
insert into @ttLF select 'ETACountry',                  null,      1,   null,               null, null
insert into @ttLF select 'ETACity',                     null,      1,   null,               null, null
insert into @ttLF select 'ETAWarehouse',                null,      1,   null,               null, null
insert into @ttLF select 'ContainerSize',               null,      1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Pending Receipts', @ttLF, @DataSetName, 'ReceiptId;ReceiptNumber' /* Key Fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Receipt Type';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'ReceiptTypeDesc',            null,   1,      null,               null, null,    null
insert into @ttLFE select 'ReceiptNumber',              null,   1,      'Receipts',         null, null,    'DCount'
insert into @ttLFE select 'NumUnits',                   null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsInTransit',             null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsReceived',              null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'QtyToReceive',               null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'LPNsReceived',               null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts
delete from @ttLSF;

/*                        FieldName,             SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'ReceiptNumber',       'Count',     '# Receipts: {0:n0}',         null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
