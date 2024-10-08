/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  SAK     Added caption for TotalShipmentValue as '$ Amount' (HA-2391)
  2020/12/23  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/06/11  RV      Added standard layout for ManageLoads.LoadOrders (HA-839)
  2020/06/09  MS      Initial revision (HA-858)
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

select @ContextName = 'List.LoadOrders',
       @DataSetName = 'vwLoadOrders';

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
insert into @ttLF select 'OrderId',                     null,     -3,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null

insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderTypeDesc',               null,   null,   null,               null, null
insert into @ttLF select 'OrderStatus',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderStatusDesc',             null,   null,   null,               null, null

insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null

insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   '# Ordered',        null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,   null,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,   null,   null,               null, null
insert into @ttLF select 'TotalShipmentValue',          null,   null,   '$ Amount',         null, null

insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalVolume',                 null,      1,   null,               null, null
insert into @ttLF select 'TotalWeight',                 null,      1,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToCity',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToState',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToZip',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipToCountry',               null,   null,   null,               null, null
insert into @ttLF select 'ShipToDesc',                  null,   null,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'CancelDays',                  null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'OrderCategory1',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory3',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory4',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory5',              null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipComplete',                null,   null,   null,               null, null
insert into @ttLF select 'WaveFlag',                    null,   null,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,   null,   null,               null, null
insert into @ttLF select 'OrderDate',                   null,   null,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'ReturnAddress',               null,   null,   null,               null, null
insert into @ttLF select 'NumLines',                    null,   null,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,   null,   null,               null, null
insert into @ttLF select 'PickZone',                    null,   null,   null,               null, null
insert into @ttLF select 'HasNotes',                    null,   null,   null,               null, null

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

insert into @ttLF select 'PB_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF10',                    null,   null,   null,               null, null

insert into @ttLF select 'vwLDOH_UDF1',                 null,   null,   null,               null, null
insert into @ttLF select 'vwLDOH_UDF2',                 null,   null,   null,               null, null
insert into @ttLF select 'vwLDOH_UDF3',                 null,   null,   null,               null, null
insert into @ttLF select 'vwLDOH_UDF4',                 null,   null,   null,               null, null
insert into @ttLF select 'vwLDOH_UDF5',                 null,   null,   null,               null, null

insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
/* Deprecated fields */
insert into @ttLF select 'OrderTypeDescription',        null,    -20,   null,               null, null
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null

insert into @ttLF select 'vwUDF1',                      null,     -2,   null,               null, null
insert into @ttLF select 'vwUDF2',                      null,     -2,   null,               null, null
insert into @ttLF select 'vwUDF3',                      null,     -2,   null,               null, null
insert into @ttLF select 'vwUDF4',                      null,     -2,   null,               null, null
insert into @ttLF select 'vwUDF5',                      null,     -2,   null,               null, null


/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'OrderId;PickTicket' /* Key fields */;

/******************************************************************************/
/* ManageLoads Load orders */
/******************************************************************************/

select @ContextName = 'ManageLoads.LoadOrders',
       @DataSetName = 'vwLoadOrders';

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'OrderId',                     null,     -3,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null

insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderTypeDesc',               null,   null,   null,               null, null
insert into @ttLF select 'OrderStatus',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderStatusDesc',             null,   null,   null,               null, null

insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   '# Ordered',        null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,   null,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalVolume',                 null,      1,   null,               null, null
insert into @ttLF select 'TotalWeight',                 null,      1,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToCity',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToState',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToZip',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipToCountry',               null,   null,   null,               null, null
insert into @ttLF select 'ShipToDesc',                  null,   null,   null,               null, null
insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'CancelDays',                  null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'OrderCategory1',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory3',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory4',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory5',              null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipComplete',                null,   null,   null,               null, null
insert into @ttLF select 'WaveFlag',                    null,   null,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,   null,   null,               null, null
insert into @ttLF select 'OrderDate',                   null,   null,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'ReturnAddress',               null,   null,   null,               null, null
insert into @ttLF select 'NumLines',                    null,   null,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,   null,   null,               null, null
insert into @ttLF select 'PickZone',                    null,   null,   null,               null, null
insert into @ttLF select 'HasNotes',                    null,   null,   null,               null, null

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

insert into @ttLF select 'PB_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF10',                    null,   null,   null,               null, null

insert into @ttLF select 'vwLDOH_UDF1',                 null,   null,   null,               null, null
insert into @ttLF select 'vwLDOH_UDF2',                 null,   null,   null,               null, null
insert into @ttLF select 'vwLDOH_UDF3',                 null,   null,   null,               null, null
insert into @ttLF select 'vwLDOH_UDF4',                 null,   null,   null,               null, null
insert into @ttLF select 'vwLDOH_UDF5',                 null,   null,   null,               null, null

insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Deprecated fields */
insert into @ttLF select 'OrderTypeDescription',        null,    -20,   null,               null, null
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null

insert into @ttLF select 'vwUDF1',                      null,     -2,   null,               null, null
insert into @ttLF select 'vwUDF2',                      null,     -2,   null,               null, null
insert into @ttLF select 'vwUDF3',                      null,     -2,   null,               null, null
insert into @ttLF select 'vwUDF4',                      null,     -2,   null,               null, null
insert into @ttLF select 'vwUDF5',                      null,     -2,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'OrderId;PickTicket' /* Key fields */;
Go