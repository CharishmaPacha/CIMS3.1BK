/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  PKK     Corrected the file as per the template (CIMSV3-1282)
  2020/09/30  SAK     Changed visibility as 11 for RecordId field (JL-147)
  2020/02/17  AJM     Added missing fields, changed ContextName , DataSetName (JL-49)
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

select @ContextName = 'List.CIMSDE_OpenReceipts',
       @DataSetName = 'vwCIMSDE_ExportOpenReceipts';

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
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptType',                 null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'QtyOrdered',                  null,   null,   null,               null, null
insert into @ttLF select 'QtyIntransit',                null,   null,   null,               null, null
insert into @ttLF select 'QtyReceived',                 null,   null,   null,               null, null
insert into @ttLF select 'QtyOpen',                     null,   null,   null,               null, null

insert into @ttLF select 'CoO',                         null,   null,   null,               null, null
insert into @ttLF select 'UnitCost',                    null,     -1,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Ownership ',                  null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null

insert into @ttLF select 'VendorId',                    null,   null,   null,               null, null
insert into @ttLF select 'Vessel',                      null,   null,   null,               null, null
insert into @ttLF select 'ContainerNo',                 null,   null,   null,               null, null
insert into @ttLF select 'HostReceiptLine',             null,   null,   null,               null, null

insert into @ttLF select 'RH_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'RD_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF10',                    null,   null,   null,               null, null

insert into @ttLF select 'vwORE_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF5',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF6',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF7',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF8',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF9',                  null,   null,   null,               null, null
insert into @ttLF select 'vwORE_UDF10',                 null,   null,   null,               null, null

insert into @ttLF select 'RecordType',                  null,     -2,   null,               null, null

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
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null
insert into @ttLF select 'CIMSRecId',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
