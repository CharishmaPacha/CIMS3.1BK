/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/02/17  AJM     Changed the ContextName, DataSetName  (JL-49)
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

select @ContextName = 'List.CIMSDE_OpenOrders',
       @DataSetName = 'vwCIMSDE_ExportOpenOrders';

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
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,     -1,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'UnitsOrdered',                null,   null,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,               null, null
insert into @ttLF select 'UnitsReserved',               null,   null,   null,               null, null
insert into @ttLF select 'UnitsNeeded',                 null,   null,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,      1,   null,               null, null
insert into @ttLF select 'UnitsRemainToShip',           null,   null,   null,               null, null

insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null

insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null

insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null

insert into @ttLF select 'HostOrderLine',               null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null

insert into @ttLF select 'OH_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF10',                    null,   null,   null,               null, null

insert into @ttLF select 'OD_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF10',                    null,   null,   null,               null, null

insert into @ttLF select 'vwOOE_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF5',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF6',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF7',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF8',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF9',                  null,   null,   null,               null, null
insert into @ttLF select 'vwOOE_UDF10',                 null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'RecordId',                    null,      1,   null,               null, null
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