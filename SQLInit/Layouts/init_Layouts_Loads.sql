/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  SAK     Added caption for TotalShipmentValue as '$ Amount' (HA-2391)
  2021/03/31  KBB     Added BoLStatus (HA-2465)
  2021/03/17  AY      Added TotalShipmentValue (HA GoLive)
  2021/03/05  SJ      Added fields CarrierCheckIn, CarrierCheckOut (HA-2137)
  2021/02/11  TK      Added EstimatedCartons (HA-1964)
  2021/02/04  AJM     Added LPNVolume, LPNWeight, CreatedOn, ModifiedOn (CIMSV3-1334)
  2020/11/23  SJ      Changed Field Caption & Visibility  for ShipToId,ShipToDesc fields (HA-1101)
  2020/10/08  MRK     Added missing fields (HA-1430)
  2020/07/15  SAK     Added New Layout Additional Info (HA-1086)
  2020/07/10  RKC     Added StagingLocation, LoadingMethod, Palletized fields (HA-1106)
  2020/07/01  NB      Loads: Added ShipFrom (CIMSV3-996)
  2020/06/23  SAK     Added ConsolidatorAddressId (HA-1001)
  2020/06/18  KBB     Added AppointmentConfirmation,AppointmentDate,AppointmentDateTime,DeliveryRequestType, (HA-1003)
  2020/06/12  OK      Added MasterTrackingNo (HA-843)
  2019/05/14  RBV     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/04/26  RC      Added Summary Layouts (CIMSV3-194)
  2018/01/10  SPP     Initial revision (CIMSV3-210)
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

select @ContextName = 'List.Loads',
       @DataSetName = 'vwLoads';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Pick Ups',                   null,          null,  null,   0,      null

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
insert into @ttLF select 'LoadNumber',                  null,   null,   null,               null, null
insert into @ttLF select 'LoadType',                    null,   null,   null,               null, null
insert into @ttLF select 'LoadTypeDesc',                null,   null,   null,               null, null

insert into @ttLF select 'LoadStatus',                  null,   null,   null,               null, null
insert into @ttLF select 'LoadStatusDesc',              null,   null,   null,               null, null

insert into @ttLF select 'RoutingStatus',               null,   null,   null,               null, null
insert into @ttLF select 'RoutingStatusDesc',           null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,    -11,   null,               null, null
insert into @ttLF select 'ShipViaDescription',          null,     11,   null,               null, null

insert into @ttLF select 'NumOrders',                   null,   null,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null -- use LPNs Assigned
insert into @ttLF select 'NumPackages',                 null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   null,               null, null
insert into @ttLF select 'EstimatedCartons',            null,   null,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,     -1,   null,               null, null
insert into @ttLF select 'TotalShipmentValue',          null,     -1,   '$ Amount',         null, null

insert into @ttLF select 'Volume',                      null,      1,   null,               null, null
insert into @ttLF select 'Weight',                      null,   null,   null,               null, null
insert into @ttLF select 'LPNVolume',                   null,   null,   null,               null, null
insert into @ttLF select 'LPNWeight',                   null,   null,   null,               null, null

insert into @ttLF select 'FromWarehouse',               null,     -1,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,      1,   null,               null, null
insert into @ttLF select 'DockLocation',                null,   null,   null,               null, null
insert into @ttLF select 'StagingLocation',             null,     -1,   null,               null, null
insert into @ttLF select 'LoadingMethod',               null,     -1,   null,               null, null
insert into @ttLF select 'Palletized',                  null,     -1,   null,               null, null

insert into @ttLF select 'AppointmentConfirmation',     null,     -1,   null,               null, null
insert into @ttLF select 'AppointmentDate',             null,     -1,   null,               null, null
insert into @ttLF select 'AppointmentDateTime',         null,     -1,   null,               null, null
insert into @ttLF select 'DeliveryRequestType',         null,     -1,   null,               null, null

insert into @ttLF select 'CarrierCheckIn',              null,     -1,   null,               null, null
insert into @ttLF select 'CarrierCheckOut',             null,     -1,   null,               null, null

insert into @ttLF select 'TrailerNumber',               null,   null,   null,               null, null
insert into @ttLF select 'SealNumber',                  null,   null,   null,               null, null
insert into @ttLF select 'ProNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'MasterTrackingNo',            null,   null,   null,               null, null
insert into @ttLF select 'MasterBoL',                   null,   null,   null,               null, null
insert into @ttLF select 'BoLStatus',                   null,   null,   null,               null, null

insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToDesc',                  null,    -20,   null,               null, null
insert into @ttLF select 'ConsolidatorAddressId',       null,   null,   null,               null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'ShippedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'DeliveryDate',                null,   null,   null,               null, null
insert into @ttLF select 'TransitDays',                 null,   null,   null,               null, null
insert into @ttLF select 'FreightCharges',              null,   null,   null,               null, null

insert into @ttLF select 'Priority',                    null,     -1,   null,               null, null
insert into @ttLF select 'Account',                     null,     -1,   null,               null, null
insert into @ttLF select 'AccountName',                 null,     -1,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,     -1,   null,               null, null
insert into @ttLF select 'ClientLoad',                  null,     -1,   null,               null, null
insert into @ttLF select 'LoadGroup',                   null,     -1,   null,               null, null
insert into @ttLF select 'FoB',                         null,     -1,   null,               null, null
insert into @ttLF select 'BoLCID',                      null,     -1,   null,               null, null

insert into @ttLF select 'LoadId',                      null,     -3,   null,               null, null

insert into @ttLF select 'UDF1',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,               null, null
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
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedOn',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedOn',                  null,   null,   null,               null, null

/* Deprecated fields */
insert into @ttLF select 'LoadTypeDescription',         null,    -20,   null,               null, null
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null
insert into @ttLF select 'RoutingStatusDescription',    null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'LoadId;LoadNumber' /* Key fields */;

/******************************************************************************/
/* Layout Fields for Additional Info Layout */
/******************************************************************************/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'AppointmentDateTime',         null,   1,      'Pick-Up Time',     null, null
insert into @ttLF select 'AppointmentConfirmation',     null,   1,      'Confirmation #',   null, null
insert into @ttLF select 'LoadStatusDesc',              null,   1,      null,               null, null
insert into @ttLF select 'ShipToName',                  null,   1,      null,               null, null
insert into @ttLF select 'ClientLoad',                  null,   1,      'Client Load #',    null, null
insert into @ttLF select 'LoadNumber',                  null,   1,      'Load #',           null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   'Boxes',            null, null
insert into @ttLF select 'Shipvia',                     null,   null,   'Carrier',          null, null
insert into @ttLF select 'DockLocation',                null,   null,   'Dock',             null, null
insert into @ttLF select 'StagingLocation',             null,   1,      'Row #',            null, null
insert into @ttLF select 'NumPallets',                  null,   null,   'Pallets',          null, null
insert into @ttLF select 'ShippedDate ',                null,   null,   'Shipped',          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Pick Ups', @ttLF, @DataSetName, 'LoadId;LoadNumber' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details, AccountName */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by ShipVia';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ShipViaDescription',null,     1,   null,          null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPackages',      null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Weight',           null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Volume',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Account';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'Account',          null,      1,   null,          null, null,    null
insert into @ttLFE select 'AccountName',      null,      1,   null,          null, null,    null
insert into @ttLFE select 'PickBatchGroup',   null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPackages',      null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Weight',           null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Volume',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Ship To';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ShipToDesc',       null,      1,   null,          null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPackages',      null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Weight',           null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Volume',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Load Type';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'LoadTypeDescription',null,    1,   null,          null, null,    null
insert into @ttLFE select 'NumOrders',        null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPallets',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',          null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumPackages',      null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',         null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Weight',           null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Volume',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'LoadNumber',                 'Count',     '# Loads: {0:n0}',            null
insert into @ttLSF select 'TotalShipmentValue',         'Sum',       '# Value: {0:c2}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
