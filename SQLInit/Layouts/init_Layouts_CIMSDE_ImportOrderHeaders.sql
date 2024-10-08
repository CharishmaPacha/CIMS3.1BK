/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/30  SJ      Added New fields (JL-48)
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

select @ContextName = 'List.CIMSDE_ImportOrderHeaders',
       @DataSetName = 'vwCIMSDE_ImportOrderHeaders';

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
insert into @ttLF select 'RecordType',                  null,   null,   null,                null, null
insert into @ttLF select 'RecordAction',                null,   null,   null,                null, null

insert into @ttLF select 'OrderId',                     null,     -1,   null,                null, null
insert into @ttLF select 'PickTicket',                  null,      1,   null,                null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,                null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,                null, null
insert into @ttLF select 'Status',                      null,     -1,   null,                null, null

insert into @ttLF select 'OrderDate',                   null,   null,   null,                null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,                null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,                null, null
insert into @ttLF select 'NB4Date',                     null,   null,   null,                null, null

insert into @ttLF select 'DeliveryStart',               null,   null,   null,                null, null
insert into @ttLF select 'DeliveryEnd',                 null,   null,   null,                null, null

insert into @ttLF select 'DeliveryRequirement',         null,   null,   null,                null, null
insert into @ttLF select 'CarrierOptions',              null,   null,   null,                null, null
insert into @ttLF select 'CartonGroup',                 null,   null,   null,                null, null
insert into @ttLF select 'Priority',                    null,   null,   null,                null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,                null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,                null, null
insert into @ttLF select 'ShipToName',                  null,   null,   null,                null, null
insert into @ttLF select 'ShipToAddressLine1',          null,   null,   null,                null, null
insert into @ttLF select 'ShipToAddressLine2',          null,   null,   null,                null, null
insert into @ttLF select 'ShipToAddressLine3',          null,   null,   null,                null, null
insert into @ttLF select 'ShipToCity',                  null,   null,   null,                null, null
insert into @ttLF select 'ShipToState',                 null,   null,   null,                null, null
insert into @ttLF select 'ShipToCountry',               null,   null,   null,                null, null
insert into @ttLF select 'ShipToZip',                   null,   null,   null,                null, null
insert into @ttLF select 'ShipCompletePercent',         null,   null,   null,                null, null

insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,                null, null
insert into @ttLF select 'HostNumLines',                null,     -1,   null,                null, null

insert into @ttLF select 'ReturnAddress',               null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddress',              null,   null,   null,                null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,                null, null

insert into @ttLF select 'ShipVia',                     null,   null,   null,                null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,                null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,                null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,                null, null

insert into @ttLF select 'Account',                     null,   null,   null,                null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,                null, null

insert into @ttLF select 'OrderCategory1',              null,   null,   null,                null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,                null, null
insert into @ttLF select 'OrderCategory3',              null,   null,   null,                null, null
insert into @ttLF select 'OrderCategory4',              null,   null,   null,                null, null
insert into @ttLF select 'OrderCategory5',              null,   null,   null,                null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,                null, null
insert into @ttLF select 'WaveGroup',                   null,   null,   null,                null, null

insert into @ttLF select 'SoldToName',                  null,   null,   null,                null, null
insert into @ttLF select 'SoldToAddressLine1',          null,   null,   null,                null, null
insert into @ttLF select 'SoldToAddressLine2',          null,   null,   null,                null, null
insert into @ttLF select 'SoldToCity',                  null,   null,   null,                null, null
insert into @ttLF select 'SoldToState',                 null,   null,   null,                null, null
insert into @ttLF select 'SoldToCountry',               null,   null,   null,                null, null
insert into @ttLF select 'SoldToZip',                   null,   null,   null,                null, null
insert into @ttLF select 'SoldToPhoneNo',               null,   null,   null,                null, null
insert into @ttLF select 'SoldToEmail',                 null,   null,   null,                null, null
insert into @ttLF select 'SoldToAddressReference1',     null,   null,   null,                null, null

insert into @ttLF select 'SoldToAddressReference2',     null,   null,   null,                null, null

insert into @ttLF select 'ShipToPhoneNo',               null,   null,   null,                null, null
insert into @ttLF select 'ShipToEmail',                 null,   null,   null,                null, null
insert into @ttLF select 'ShipToAddressReference1',     null,   null,   null,                null, null

insert into @ttLF select 'ShipToAddressReference2',     null,   null,   null,                null, null

insert into @ttLF select 'ShipToResidential',           null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddrId',                null,   null,   null,                null, null

insert into @ttLF select 'ReturnAddressName',           null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressLine1',          null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressLine2',          null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressCity',           null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressState',          null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressCountry',        null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressZip',            null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressPhoneNo',        null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressEmail',          null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressReference1',     null,   null,   null,                null, null
insert into @ttLF select 'ReturnAddressReference2',     null,   null,   null,                null, null

insert into @ttLF select 'MarkForAddressName',          null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressLine1',         null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressLine2',         null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressCity',          null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressState',         null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressCountry',       null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressZip',           null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressPhoneNo',       null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressEmail',         null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressReference1',    null,   null,   null,                null, null
insert into @ttLF select 'MarkForAddressReference2',    null,   null,   null,                null, null

insert into @ttLF select 'SourceSystem',                null,   null,   null,                null, null

insert into @ttLF select 'TotalTax',                    null,   null,   null,                null, null
insert into @ttLF select 'TotalShippingCost',           null,   null,   null,                null, null
insert into @ttLF select 'TotalDiscount',               null,   null,   null,                null, null
insert into @ttLF select 'TotalSalesAmount',            null,   null,   null,                null, null
insert into @ttLF select 'FreightCharges',              null,   null,   null,                null, null
insert into @ttLF select 'FreightTerms',                null,   null,   null,                null, null
insert into @ttLF select 'BillToAccount',               null,   null,   null,                null, null

insert into @ttLF select 'BillToAddress',               null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressName',           null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressLine1',          null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressLine2',          null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressCity',           null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressState',          null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressCountry',        null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressZip',            null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressPhoneNo',        null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressEmail',          null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressReference1',     null,   null,   null,                null, null
insert into @ttLF select 'BillToAddressReference2',     null,   null,   null,                null, null

insert into @ttLF select 'Comments',                    null,   null,   null,                null, null

insert into @ttLF select 'OH_UDF1',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF2',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF3',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF4',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF5',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF6',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF7',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF8',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF9',                     null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF10',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF11',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF12',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF13',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF14',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF15',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF16',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF17',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF18',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF19',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF20',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF21',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF22',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF23',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF24',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF25',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF26',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF27',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF28',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF29',                    null,   null,   null,                null, null
insert into @ttLF select 'OH_UDF30',                    null,   null,   null,                null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,                null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,                null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,                null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,                null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,                null, null

insert into @ttLF select 'InputXML',                    null,   null,   null,                null, null
insert into @ttLF select 'ResultXML',                   null,   null,   null,                null, null

insert into @ttLF select 'HostRecId',                   null,      1,   null,                null, null
insert into @ttLF select 'RecordId',                    null,      1,   null,                null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,                null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,                null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,                null, null
insert into @ttLF select 'Reference',                   null,   null,   null,                null, null
insert into @ttLF select 'Result',                      null,   null,   null,                null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
