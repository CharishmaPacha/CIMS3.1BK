/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/05  VS      Made changes to show the grid in V3 application (HA-367)
  2016/02/23  TK      Added Ownership field (NBD-175)
  2015/12/17  TK      Added MinMax ReplenishLevelUnits (ACME-419)
  2015/02/27  YJ      set visible -2 for InnerPacks, PercentFull.
  2104/06/10  TK      Corrected alignment of the fields and removed extra spaces.
  2014/06/06  TK      Initial revision.
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

select @ContextName = 'List.ReplenishOrders',
       @DataSetName = 'vwReplenishOrderHeaders';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Standard Layout */
/*----------------------------------------------------------------------------*/
/*                        Field                  Visible Visible Field   Width Display
                          Name                   Index           Caption       Format */
insert into @ttLF select 'OrderId',              null,   null,   null,   null, null
insert into @ttLF select 'PickTicket',           null,   null,   null,   null, null
insert into @ttLF select 'SalesOrder',           null,   null,   null,   null, null
insert into @ttLF select 'OrderType',            null,   null,   null,   null, null
insert into @ttLF select 'OrderTypeDesc',        null,   null,   null,   null, null
insert into @ttLF select 'OrderStatus',          null,   null,   null,   null, null
insert into @ttLF select 'OrderStatusDesc',      null,   null,   null,   null, null
insert into @ttLF select 'ExchangeStatus',       null,   null,   null,   null, null
insert into @ttLF select 'StatusDescription',    null,   null,   null,   null, null
insert into @ttLF select 'OrderDate',            null,   null,   null,   null, null
insert into @ttLF select 'CancelDate',           null,   null,   null,   null, null
insert into @ttLF select 'DesiredShipDate',      null,   null,   null,   null, null
insert into @ttLF select 'DateShipped',          null,     -1,   null,   null, null
insert into @ttLF select 'CancelDays',           null,     -1,   null,   null, null
insert into @ttLF select 'Priority',             null,   null,   null,   null, null
insert into @ttLF select 'SoldToId',             null,   null,   null,   null, null
insert into @ttLF select 'CustomerName',         null,   null,   null,   null, null
insert into @ttLF select 'ShipToId',             null,   null,   null,   null, null
insert into @ttLF select 'ReturnAddress',        null,   null,   null,   null, null
insert into @ttLF select 'MarkForAddress',       null,   null,   null,   null, null
insert into @ttLF select 'ShipToStore',          null,   null,   null,   null, null
insert into @ttLF select 'PickBatchNo',          null,   null,   null,   null, null
insert into @ttLF select 'PickBatchId',          null,   null,   null,   null, null
insert into @ttLF select 'ShipVia',              null,   null,   null,   null, null
insert into @ttLF select 'ShipFrom',             null,   null,   null,   null, null
insert into @ttLF select 'CustPO',               null,   null,   null,   null, null
insert into @ttLF select 'Ownership',            null,   null,   null,   null, null
insert into @ttLF select 'Account',              null,   null,   null,   null, null
insert into @ttLF select 'AccountName',          null,   null,   null,   null, null
insert into @ttLF select 'OrderCategory1',       null,   null,   null,   null, null
insert into @ttLF select 'OrderCategory2',       null,   null,   null,   null, null
insert into @ttLF select 'OrderCategory3',       null,   null,   null,   null, null
insert into @ttLF select 'OrderCategory4',       null,   null,   null,   null, null
insert into @ttLF select 'OrderCategory5',       null,   null,   null,   null, null
insert into @ttLF select 'Warehouse',            null,   null,   null,   null, null
insert into @ttLF select 'PickZone',             null,   null,   null,   null, null
insert into @ttLF select 'PickBatchGroup',       null,   null,   null,   null, null
insert into @ttLF select 'NumLines',             null,   null,   null,   null, null
insert into @ttLF select 'NumSKUs',              null,   null,   null,   null, null
insert into @ttLF select 'NumUnits',             null,   null,   null,   null, null
insert into @ttLF select 'LPNsAssigned',         null,   null,   null,   null, null
insert into @ttLF select 'UnitsAssigned',        null,   null,   null,   null, null
insert into @ttLF select 'NumLPNs',              null,   null,   null,   null, null

insert into @ttLF select 'TotalVolume',          null,     -2,   null,   null, null
insert into @ttLF select 'TotalWeight',          null,     -2,   null,   null, null
insert into @ttLF select 'TotalSalesAmount',     null,     -2,   null,   null, null
insert into @ttLF select 'TotalTax',             null,     -2,   null,   null, null
insert into @ttLF select 'TotalShippingCost',    null,     -2,   null,   null, null
insert into @ttLF select 'TotalDiscount',        null,     -2,   null,   null, null
insert into @ttLF select 'FreightCharges',       null,     -2,   null,   null, null
insert into @ttLF select 'FreightTerms',         null,     -2,   null,   null, null
insert into @ttLF select 'BillToAccount',        null,     -2,   null,   null, null
insert into @ttLF select 'BillToAddress',        null,     -2,   null,   null, null
insert into @ttLF select 'ShortPick',            null,   null,   null,   null, null
insert into @ttLF select 'Comments',             null,   null,   null,   null, null
insert into @ttLF select 'HasNotes',             null,   null,   null,   null, null
insert into @ttLF select 'UDF1',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF2',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF3',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF4',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF5',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF6',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF7',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF8',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF9',                 null,   null,   null,   null, null
insert into @ttLF select 'UDF10',                null,   null,   null,   null, null
insert into @ttLF select 'vwUDF1',               null,   null,   null,   null, null
insert into @ttLF select 'vwUDF2',               null,   null,   null,   null, null
insert into @ttLF select 'vwUDF3',               null,   null,   null,   null, null
insert into @ttLF select 'vwUDF4',               null,   null,   null,   null, null
insert into @ttLF select 'vwUDF5',               null,   null,   null,   null, null
insert into @ttLF select 'LoadId',               null,   null,   null,   null, null
insert into @ttLF select 'LoadNumber',           null,   null,   null,   null, null
insert into @ttLF select 'Archived',             null,   null,   null,   null, null
insert into @ttLF select 'BusinessUnit',         null,   null,   null,   null, null
insert into @ttLF select 'CreatedDate',          null,      1,   'Request Date',
                                                                           85, '{0:MM/dd/yyyy}'
insert into @ttLF select 'ModifiedDate',         null,   null,   null,   null, null
insert into @ttLF select 'CreatedBy',            null,   null,   null,   null, null
insert into @ttLF select 'ModifiedBy',           null,   null,   null,   null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'OrderId;PickTicket' /* Key fields */;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by ProcessType';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'OrderCategory1',   null,      1,   null,          null, null,    null
insert into @ttLFE select 'Warehouse',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'PickTicket',       null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumSKUs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Priority';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'Priority',         null,      1,   null,          null, null,    null
insert into @ttLFE select 'Warehouse',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'PickTicket',       null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'


exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

Go
