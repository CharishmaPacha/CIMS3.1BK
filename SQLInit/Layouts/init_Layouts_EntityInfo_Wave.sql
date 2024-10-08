/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/03  VS      Added Summaryfield for UnitsRequiredtoActivate, UnitsReservedForWave, ToActivateShipCartonQty (HA-2714)
  2021/03/24  MS      Setup ShipLabels Tab (HA-2406)
  2021/03/23  TK      Added Layout for wave summary (HA-2381)
  2021/03/02  SAK     Added LoadGroup (HA-1981)
  2020/06/10  MS      Use LF Flag to copy Layout & Fields (HA-861)
  2020/05/18  MS      Initial revision (HA-569).
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

/******************************************************************************/
/* Wave_EntityInfo_WaveSummary */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_WaveSummary',
       @DataSetName = 'pr_UI_DS_WaveSummary';

/*----------------------------------------------------------------------------*/
/* Layouts */
/*----------------------------------------------------------------------------*/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'Y',     'Contractor Waves',              null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
/* Copy fields from Standards Layout */
exec pr_LayoutFields_Copy 'List.WaveSummary', 'Standard', @ContextName, 'Standard';

exec pr_LayoutFields_Copy 'List.WaveSummary', 'Contractor Waves', @ContextName, 'Contractor Waves';

/******************************************************************************/
/* Wave_EntityInfo_Orders */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_Orders',
       @DataSetName = 'vwOrderHeaders';

/*----------------------------------------------------------------------------*/
/* Layouts */
/*----------------------------------------------------------------------------*/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'Y',     'Orders on Wave',                null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
/* Copy fields from Standards Layout */
exec pr_LayoutFields_Copy 'List.Orders', 'Standard', @ContextName, 'Standard';

/*----------------------------------------------------------------------------*/
/* Layout Fields for Orders on Wave */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field              Width Display
                          Name                          Index           Caption                  Format */

insert into @ttLF select 'OrderId',                     null,   null,   null,              null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,              null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,              null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,              null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,              null, null
insert into @ttLF select 'HasNotes',                    null,   null,   null,              null, null
insert into @ttLF select 'OrderStatusDesc',             null,   null,   null,              null, null
insert into @ttLF select 'OrderTypeDescription',        null,     -1,   null,              null, null
insert into @ttLF select 'Account',                     null,   null,   null,              null, null

insert into @ttLF select 'NumLPNs',                     null,   null,   null,              null, null
insert into @ttLF select 'NumUnits',                    null,   null,   null,              null, null
insert into @ttLF select 'StatusGroup',                 null,     -1,   null,              null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,              null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,              null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,              null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,              null, null
insert into @ttLF select 'UnitsToAllocate',             null,   null,   null,              null, null
insert into @ttLF select 'WaveNo',                      null,     -1,   null,              null, null
insert into @ttLF select 'CustomerName',                null,   null,   null,              null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,              null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,              null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,              null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,              null, null

insert into @ttLF select 'WaveShipDate',                null,     -1,   null,              null, null
insert into @ttLF select 'WaveDropLocation',            null,     -1,   null,              null, null
insert into @ttLF select 'Priority',                    null,     -1,   null,              null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,              null, null
insert into @ttLF select 'NumLines',                    null,     -1,   null,              null, null
insert into @ttLF select 'NumSKUs',                     null,     -1,   null,              null, null
insert into @ttLF select 'TotalSalesAmount',            null,   null,   null,              null, null
insert into @ttLF select 'WaveGroup',                   null,   null,   null,              null, null
insert into @ttLF select 'UnitsPicked',                 null,   null,   null,              null, null
insert into @ttLF select 'UnitsToPick',                 null,   null,   null,              null, null
insert into @ttLF select 'CancelDays',                  null,   null,   null,              null, null
insert into @ttLF select 'UnitsPacked',                 null,   null,   null,              null, null
insert into @ttLF select 'OrderCategory1',              null,   null,   null,              null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,              null, null
insert into @ttLF select 'UnitsToPack',                 null,   null,   null,              null, null
insert into @ttLF select 'UnitsStaged',                 null,   null,   null,              null, null
insert into @ttLF select 'LoadNumber',                  null,     -1,   null,              null, null
insert into @ttLF select 'LoadGroup',                   null,   null,   null,              null, null
insert into @ttLF select 'PickZone',                    null,     -1,   null,              null, null
insert into @ttLF select 'OrderDate',                   null,   null,   null,              null, null
insert into @ttLF select 'ShipperAccountName',          null,   null,   null,              null, null
insert into @ttLF select 'AESNumber',                   null,   null,   null,              null, null
insert into @ttLF select 'ShipmentRefNumber',           null,   null,   null,              null, null
insert into @ttLF select 'UnitsLoaded',                 null,   null,   null,              null, null
insert into @ttLF select 'ShipToCity',                  null,   null,   null,              null, null
insert into @ttLF select 'ShipToState',                 null,   null,   null,              null, null
insert into @ttLF select 'ShipToZip',                   null,   null,   null,              null, null
insert into @ttLF select 'ShipToCountry',               null,   null,   null,              null, null
insert into @ttLF select 'ReturnAddress',               null,   null,   null,              null, null
insert into @ttLF select 'UnitsToLoad',                 null,   null,   null,              null, null
insert into @ttLF select 'MarkForAddress',              null,   null,   null,              null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,              null, null
insert into @ttLF select 'TotalTax',                    null,   null,   null,              null, null
insert into @ttLF select 'TotalShippingCost',           null,   null,   null,              null, null
insert into @ttLF select 'UnitsToShip',                 null,   null,   null,              null, null
insert into @ttLF select 'TotalDiscount',               null,   null,   null,              null, null
insert into @ttLF select 'Comments',                    null,   null,   null,              null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,              null, null
insert into @ttLF select 'ShipComplete',                null,   null,   null,              null, null
insert into @ttLF select 'WaveFlag',                    null,   null,   null,              null, null
insert into @ttLF select 'TotalWeight',                 null,   null,   null,              null, null
insert into @ttLF select 'TotalVolume',                 null,   null,   null,              null, null
insert into @ttLF select 'PrevWaveNo',                  null,   null,   null,              null, null
insert into @ttLF select 'UnitsShipped',                null,   null,   null,              null, null

insert into @ttLF select 'LPNsPacked',                  null,   null,   null,              null, null
insert into @ttLF select 'LPNsLoaded',                  null,   null,   null,              null, null
insert into @ttLF select 'LPNsToLoad',                  null,   null,   null,              null, null
insert into @ttLF select 'LPNsShipped',                 null,   null,   null,              null, null
insert into @ttLF select 'LPNsToShip',                  null,   null,   null,              null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,              null, null
insert into @ttLF select 'Archived',                    null,   null,   null,              null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,              null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,              null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,              null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,              null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Orders on Wave', @ttLF, @DataSetName, 'OrderId;PickTicket' /* Key fields */;

/******************************************************************************/
/* Wave_EntityInfo_OrderDetails */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_OrderDetails';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.OrderDetails', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/*----------------------------------------------------------------------------
/ Summary Layout Details
/----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Wave/SKU';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'SKU',                        null,        1, null,               null, null,    null
insert into @ttLFE select 'WaveNo',                     null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU1',                       null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU2',                       null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU3',                       null,        1, null,               null, null,    null
insert into @ttLFE select 'PackingGroup',               null,        1, null,               null, null,    null
insert into @ttLFE select 'UnitsPerCarton',             null,        1, null,               null, null,    null
insert into @ttLFE select 'PickTicket',                 null,        1, null,               null, null,    'DCount'
insert into @ttLFE select 'UnitsAssigned',              null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToAllocate',            null,        1, null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Wave_EntityInfo_Pallets */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_Pallets';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.Pallets', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* Wave_EntityInfo_LPNs */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_LPNs';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.LPNs', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* Wave_EntityInfo_PickTasks */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_PickTasks';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.PickTasks', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* Wave_EntityInfo_PickTaskDetails */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_PickTaskDetails';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.PickTaskDetails', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/*-----------------------------------------------------------------------------/
/ Summary Layout Details
/-----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by SKU';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'SKU',                    null,      1,   null,          null, null,    null
insert into @ttLFE select 'TotalUnits',             null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Wave_EntityInfo_ShipLabels */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_ShipLabels';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.ShipLabels', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* Wave_EntityInfo_Notifications */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_Notifications';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.Notifications', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* Wave_EntityInfo_AuditTrail */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_AuditTrail';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.ATEntity', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/* Hide the fields not applicable to this layout */
exec pr_LayoutFields_ChangeVisibility @ContextName, 'Standard', 'EntityKey';

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
select @ContextName = 'Wave_EntityInfo_WaveSummary';
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                 AggregateMethod */
insert into @ttLSF select 'UnitsRequiredtoActivate',    'sum',       '{0:n0}',                      null
insert into @ttLSF select 'UnitsReservedForWave',       'sum',       '{0:n0}',                      null
insert into @ttLSF select 'ToActivateShipCartonQty',    'sum',       '{0:n0}',                      null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
