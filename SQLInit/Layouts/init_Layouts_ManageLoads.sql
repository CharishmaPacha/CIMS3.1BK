/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  SAK     Added caption for TotalShipmentValue as '$ Amount' (HA-2391)
  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/07/01  NB      Loads: Added ShipFrom (CIMSV3-996)
  2020/06/25  NB      FromWarehouse changed to be Visible (CIMSV3-996)
  2020/06/18  AJ      Change visibility to not show duplicate fields (HA-957)
  2020/06/18  KBB     Added AppointmentConfirmation,AppointmentDate,AppointmentDateTime,DeliveryRequestType, (HA-1003)
  2020/06/12  RV      Added Status description to show description instead of status codes (HA-838)
  2020/06/10  RV      Initial revision(HA-383)
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

select @ContextName = 'ManageLoads.OpenLoads',
       @DataSetName = 'vwLoadsToManage';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'Y',     'Standard',                   null,          null,  null,   0,      null

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
insert into @ttLF select 'LoadType',                    null,   null,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,      1,   null,               null, null
insert into @ttLF select 'LoadTypeDescription',         null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,   null,   null,               null, null

insert into @ttLF select 'RoutingStatus',               null,     -2,   null,               null, null
insert into @ttLF select 'RoutingStatusDescription',    null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,    -20,   null,               null, null
insert into @ttLF select 'ShipViaDescription',          null,     -1,   null,               null, null

insert into @ttLF select 'NumOrders',                   null,   null,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'NumPackages',                 null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,     -1,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,     -1,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,               null, null
insert into @ttLF select 'Volume',                      null,      1,   null,               null, null
insert into @ttLF select 'Weight',                      null,      1,   null,               null, null
insert into @ttLF select 'FreightCharges',              null,      1,   null,               null, null

insert into @ttLF select 'AppointmentConfirmation',     null,   null,   null,               null, null
insert into @ttLF select 'AppointmentDate',             null,   null,   null,               null, null
insert into @ttLF select 'AppointmentDateTime',         null,   null,   null,               null, null
insert into @ttLF select 'DeliveryRequestType',         null,   null,   null,               null, null

insert into @ttLF select 'TrailerNumber',               null,   null,   null,               null, null
insert into @ttLF select 'SealNumber',                  null,   null,   null,               null, null
insert into @ttLF select 'ProNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'MasterTrackingNo',            null,   null,   null,               null, null
insert into @ttLF select 'MasterBoL',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToDesc',                  null,      1,   'Ship To Name',       90, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'ShippedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'DeliveryDate',                null,   null,   null,               null, null
insert into @ttLF select 'TransitDays',                 null,   null,   null,               null, null

insert into @ttLF select 'FromWarehouse',               null,   1,     null,                null, null
insert into @ttLF select 'ShipFrom',                    null,   1,     'Ship From',         null, null
insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,     -1,   null,               null, null
insert into @ttLF select 'DockLocation',                null,   null,   null,               null, null
insert into @ttLF select 'ClientLoad',                  null,   null,   null,               null, null
insert into @ttLF select 'FoB',                         null,   null,   null,               null, null
insert into @ttLF select 'BoLCID',                      null,   null,   null,               null, null

insert into @ttLF select 'LoadId',                      null,     -2,   null,               null, null

insert into @ttLF select 'UDF1',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF2',                        null,   null,   'BoL Number',       null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF6',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF7',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF8',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF9',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF10',                       null,   null,   null,               null, null

insert into @ttLF select 'vwLD_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwLD_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwLD_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwLD_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwLD_UDF5',                   null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'LoadId;LoadNumber' /* Key Fields */;

/******************************************************************************/
/* Layouts */
/******************************************************************************/
select @ContextName       = 'ManageLoads.OrdersToShip',
       @DataSetName       = 'vwOrdersForLoads';

delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

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
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null

insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderTypeDesc',               null,   null,   null,               null, null
insert into @ttLF select 'OrderStatus',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderStatusDesc',             null,   null,   null,               null, null

insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,   null,   null,               null, null
insert into @ttLF select 'WaveType',                    null,   null,   null,               null, null
insert into @ttLF select 'BatchPickDate',               null,   null,   null,               null, null
insert into @ttLF select 'BatchToShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'BatchDescription',            null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToCity',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToState',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToZip',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipToCountry',               null,   null,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'CancelDays',                  null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipComplete',                null,   null,   null,               null, null
insert into @ttLF select 'WaveFlag',                    null,   null,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'OrderDate',                   null,   null,   null,               null, null
insert into @ttLF select 'ReturnAddress',               null,   null,   null,               null, null
insert into @ttLF select 'MarkForAddress',              null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,   null,   null,               null, null
insert into @ttLF select 'LPNsLoaded',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsToLoad',                  null,      1,   null,               null, null
insert into @ttLF select 'LPNsShipped',                 null,     -2,   null,               null, null
insert into @ttLF select 'LPNsToShip',                  null,      1,   null,               null, null
insert into @ttLF select 'NumLines',                    null,   null,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,   null,   null,               null, null
insert into @ttLF select 'UntisAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'UnitsToAllocate',             null,      1,   null,               null, null
insert into @ttLF select 'UnitsPicked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsToPick',                 null,   null,   null,               null, null
insert into @ttLF select 'UnitsPacked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsToPack',                 null,   null,   null,               null, null
insert into @ttLF select 'UnitsLoaded',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsToLoad',                 null,   null,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,     -2,   null,               null, null
insert into @ttLF select 'UnitsToShip',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalTax',                    null,   null,   null,               null, null
insert into @ttLF select 'TotalShippingCost',           null,   null,   null,               null, null
insert into @ttLF select 'TotalDiscount',               null,   null,   null,               null, null
insert into @ttLF select 'Comments',                    null,   null,   null,               null, null
insert into @ttLF select 'WaveDropLocation',            null,   null,   null,               null, null
insert into @ttLF select 'DeliveryRequirement',         null,   null,   null,               null, null
insert into @ttLF select 'WaveShipDate',                null,   null,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,   null,   null,               null, null

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
insert into @ttLF select 'PB_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'PB_UDF10',                    null,   null,   null,               null, null

insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,     -1,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Deprecated fields */
insert into @ttLF select 'BatchType',                   null,    -20,   null,               null, null
insert into @ttLF select 'OrderTypeDescription',        null,    -20,   null,               null, null
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName,  'OrderId;PickTicket'

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
select @ContextName       = 'ManageLoads.OpenLoads',
       @LayoutDescription = null; -- Applicable to all layouts

delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'LoadNumber',                 'Count',     '# Loads:{0:n0}',             null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

/*----------------------------------------------------------------------------*/
select @ContextName       = 'ManageLoads.OrdersToShip',
       @LayoutDescription = null; -- Applicable to all layouts

delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'PickTicket',                 'Count',     '# Orders:{0:n0}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go