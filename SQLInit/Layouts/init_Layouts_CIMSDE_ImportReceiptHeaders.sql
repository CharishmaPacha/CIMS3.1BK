/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/30  SAK     Changed visibility as 11 for RecordId field (JL-147)
  2019/05/10  RKC     Initial revision (CIMSV3-550).
------------------------------------------------------------------------------*/
Go

declare @ContextName  TName,
        @DataSetName  TName,
        @BusinessUnit TBusinessUnit;

declare @ttLayouts    TLayoutTable,
        @ttLF         TLayoutFieldsTable;

select @ContextName = 'List.CIMSDE_ImportReceiptHeaders',
       @DataSetName = 'vwCIMSDE_ImportReceiptHeaders';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
/*                            Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                              Type    Layout   Description                   SelectionName                                      */
insert into @ttLayouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @ttLayouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

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

insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptType',                 null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null

insert into @ttLF select 'VendorId',                    null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null

insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   '# Ordered',          70, null
insert into @ttLF select 'HostNumLines',                null,   null,   null,               null, null

insert into @ttLF select 'Vessel',                      null,   null,   null,               null, null
insert into @ttLF select 'ContainerSize',               null,   null,   null,               null, null
insert into @ttLF select 'ContainerNo',                 null,   null,   null,               null, null

insert into @ttLF select 'DateOrdered',                 null,   null,   null,               null, null
insert into @ttLF select 'DateShipped',                 null,   null,   null,               null, null
insert into @ttLF select 'ETACountry',                  null,   null,   null,               null, null
insert into @ttLF select 'ETACity',                     null,   null,   null,               null, null
insert into @ttLF select 'ETAWarehouse',                null,   null,   null,               null, null

insert into @ttLF select 'BillNo',                      null,   null,   null,               null, null
insert into @ttLF select 'SealNo',                      null,   null,   null,               null, null
insert into @ttLF select 'InvoiceNo',                   null,   null,   null,               null, null

insert into @ttLF select 'RH_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF10',                    null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'HostRecId',                   null,      1,   null,               null, null
insert into @ttLF select 'RecordId',                    null,     11,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,               null, null
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;';

Go
