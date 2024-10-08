/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/22  PKK     Added MaxUnitsPerCarton and CartonizationModel (HA-2813)
  2021/04/13  TK      Added EstimatedCartons (HA-GoLive)
  2021/02/23  SGK     Added ReleaseDateTime, NumLPNsToPA, PickSequence, PrintStatus, PickMethod,
                      WaveRuleGroup, CreatedOn, ModifiedOn (CIMSV3-1364)
  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/10/08  TK      Summary Layout 'Summary by CustPO' migrated from Prod (HA-1531)
  2020/06/08  VS      Migrated the missed fields in the vwWaves, vwOrderstobatch (HA-582)
  2020/06/08  KBB     Migrated the missed fields in the vwOrdersToBatch (HA-804)
  2020/06/03  SAK     Changed visibility as 1 for Field 'PrevWaveNo' (HA-682)
  2020/06/02  NB      Changed KeyField to WaveNo (HA-792)
  2020/06/01  SAK     Added Field 'PrevWaveNo' to Standard Layout (HA-682)
  2020/05/30  NB      Added PickBatchNo as Invisible Field to Waving.Waves Layout (HA-693)
  2020/05/20  MS      Display Descriptions insetad of Code (HA-617)
  2020/05/18  VS      Added Summary Layouts for OpenWave and UnWave grid (HA-582)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/07/12  NB      Added Summary Fields setup section(CIMSV3-298)
  2018/02/02  NB      Initial revision(CIMSV3-153)
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

select @ContextName = 'Waving.Waves',
       @DataSetName = 'vwWaves';

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
insert into @ttLF select 'WaveId',                      null,     -3,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,     -3,   null,               null, null
insert into @ttLF select 'WaveType',                    null,   null,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,   null,   null,               null, null
insert into @ttLF select 'WaveStatus',                  null,   null,   null,               null, null
insert into @ttLF select 'WaveStatusDesc',              null,   null,   null,               null, null

insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null

insert into @ttLF select 'ReleaseDateTime',             null,   null,   null,               null, null
insert into @ttLF select 'PickDate',                    null,     -1,   null,               null, null
insert into @ttLF select 'ShipDate',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumOrders',                   null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -2,   null,               null, null
insert into @ttLF select 'NumLPNsToPA',                 null,   null,   null,               null, null
insert into @ttLF select 'NumInnerPacks',               null,     -2,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   'To Ship',          null, null
insert into @ttLF select 'WaveGroup',                   null,   null,   null,               null, null

insert into @ttLF select 'WA_IsReplenished',            null,   null,   null,               null, null
insert into @ttLF select 'WA_ReplenishWaveNo',          null,   null,   null,               null, null

insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null

insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'SoldToName',                  null,   null,   null,               null, null
insert into @ttLF select 'SoldToDesc',                  null,     -1,   null,               null, null
insert into @ttLF select 'ShipToDescription',           null,     -1,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'PickZone',                    null,   null,   null,               null, null
insert into @ttLF select 'PickZoneDesc',                null,   null,   null,               null, null
insert into @ttLF select 'PickSequence',                null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipViaDesc',                 null,   null,   null,               null, null

insert into @ttLF select 'NumLines',                    null,   null,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,   null,   null,               null, null

insert into @ttLF select 'ColorCode',                   null,     -2,   null,               null, null

insert into @ttLF select 'TotalWeight',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalVolume',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalAmount',                 null,   null,   null,               null, null
insert into @ttLF select 'MaxUnitsPerCarton',           null,   null,   null,               null, null

insert into @ttLF select 'Category1',                   null,   null,   null,               null, null
insert into @ttLF select 'Category2',                   null,   null,   null,               null, null
insert into @ttLF select 'Category3',                   null,   null,   null,               null, null
insert into @ttLF select 'Category4',                   null,   null,   null,               null, null
insert into @ttLF select 'Category5',                   null,   null,   null,               null, null

insert into @ttLF select 'AllocateFlags',               null,   null,   null,               null, null
insert into @ttLF select 'IsAllocated',                 null,   null,   null,               null, null
insert into @ttLF select 'DependencyFlags',             null,     -2,   null,               null, null
insert into @ttLF select 'PrintStatus',                 null,   null,   null,               null, null
insert into @ttLF select 'InvAllocationModel',          null,   null,   null,               null, null
insert into @ttLF select 'CartonizationModel',          null,   null,   null,               null, null
insert into @ttLF select 'PickMethod',                  null,   null,   null,               null, null
insert into @ttLF select 'WCSStatus',                   null,     -2,   null,               null, null
insert into @ttLF select 'WCSDependency',               null,     -2,   null,               null, null

insert into @ttLF select 'OrdersWaved',                 null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null

insert into @ttLF select 'RuleId',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveRuleGroup',               null,   null,   null,               null, null

insert into @ttLF select 'W_UDF1',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF2',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF3',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF4',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF5',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF6',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF7',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF8',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF9',                      null,   null,   null,               null, null
insert into @ttLF select 'W_UDF10',                     null,   null,   null,               null, null

insert into @ttLF select 'vwW_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF5',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF6',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF7',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF8',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF9',                    null,   null,   null,               null, null
insert into @ttLF select 'vwW_UDF10',                   null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* ------------ Fields not applicable in this context -----------*/
insert into @ttLF select 'UnitsAssigned',               null,     -2,   null,               null, null
insert into @ttLF select 'NumTasks',                    null,     -2,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -2,   null,               null, null
insert into @ttLF select 'DropLocation',                null,     -2,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,     -2,   null,               null, null
insert into @ttLF select 'NumPicks',                    null,     -2,   null,               null, null
insert into @ttLF select 'NumPicksCompleted',           null,     -2,   null,               null, null
insert into @ttLF select 'PercentPicksComplete',        null,     -2,   null,               null, null

insert into @ttLF select 'OrdersAllocated',             null,     -2,   null,               null, null
insert into @ttLF select 'OrdersPicked',                null,     -2,   null,               null, null
insert into @ttLF select 'OrdersPacked',                null,     -2,   null,               null, null
insert into @ttLF select 'OrdersLoaded',                null,     -2,   null,               null, null
insert into @ttLF select 'OrdersStaged',                null,     -2,   null,               null, null
insert into @ttLF select 'OrdersShipped',               null,     -2,   null,               null, null
insert into @ttLF select 'OrdersOpen',                  null,     -2,   null,               null, null

insert into @ttLF select 'UnitsPicked',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsPacked',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsStaged',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsLoaded',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,     -2,   null,               null, null

insert into @ttLF select 'LPNsPicked',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsPacked',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsStaged',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsLoaded',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsShipped',                 null,     -2,   null,               null, null

/* Unused Fields */
insert into @ttLF select 'PickBatchId',                 null,    -20,   null,               null, null
insert into @ttLF select 'BatchNo',                     null,    -20,   null,               null, null
insert into @ttLF select 'BatchType',                   null,    -20,   null,               null, null
insert into @ttLF select 'BatchTypeDesc',               null,    -20,   null,               null, null
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null
insert into @ttLF select 'StatusDesc',                  null,    -20,   null,               null, null
insert into @ttLF select 'Description',                 null,    -20,   null,               null, null
insert into @ttLF select 'PalletId',                    null,     -2,   null,               null, null
insert into @ttLF select 'Pallet',                      null,     -2,   null,               null, null
insert into @ttLF select 'AssignedTo',                  null,     -2,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'WaveId;WaveNo' /* Key Fields */;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Account';
delete from @ttLFE;

/*                        Field                    Visible Visible Field          Width Display  Aggregate
                          Name                     Index           Caption              Format   Method */
insert into @ttLFE select 'Account',               null,      1,   null,          null, null,    null
insert into @ttLFE select 'WaveStatusDesc',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'WaveNo',                null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumOrders',             null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumSKUs',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',              null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by WaveType';
delete from @ttLFE;

/*                        Field                    Visible Visible Field          Width Display  Aggregate
                          Name                     Index           Caption              Format   Method */
insert into @ttLFE select 'WaveType',              null,      1,   null,          null, null,    null
insert into @ttLFE select 'WaveNo',                null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'NumOrders',             null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumSKUs',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'NumUnits',              null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Layouts */
/******************************************************************************/
select @ContextName       = 'Waving.Orders',
       @DataSetName       = 'vwOrdersToBatch';

delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'HasNotes',                    null,   null,   null,               null, null
insert into @ttLF select 'HasComments',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderTypeDescription',        null,     -1,   null,               null, null
insert into @ttLF select 'OrderStatus',                 null,     -1,   null,               null, null
insert into @ttLF select 'OrderStatusDesc',             null,     -1,   null,               null, null
insert into @ttLF select 'StatusGroup',                 null,     -1,   null,               null, null

insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null

insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null

insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   '# Ordered',        null, null
insert into @ttLF select 'UnitsAssigned',               null,     -1,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,               null, null
insert into @ttLF select 'EstimatedCartons',            null,      1,   null,               null, null

insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,      1,   null,               null, null
insert into @ttLF select 'CustomerName',                null,     -1,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,     -1,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToAddressLine1',          null,     -1,   null,               null, null
insert into @ttLF select 'ShipToAddressLine2',          null,     -1,   null,               null, null
insert into @ttLF select 'ShipToCityStateZip',          null,     -1,   null,               null, null

insert into @ttLF select 'PrevWaveNo',                  null,   null,   null,               null, null
insert into @ttLF select 'WaveGroup',                   null,   null,   null,               null, null

insert into @ttLF select 'Carrier',                     null,     -1,   null,               null, null
insert into @ttLF select 'CarrierOptions',              null,     -1,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipViaDesc',                 null,     -1,   null,               null, null

insert into @ttLF select 'NumLines',                    null,   null,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,   null,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,     -1,   null,               null, null

insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'CancelDays',                  null,   null,   null,               null, null
insert into @ttLF select 'DeliveryRequirement',         null,     -1,   null,               null, null
insert into @ttLF select 'OrderCategory1',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory3',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory4',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory5',              null,   null,   null,               null, null

insert into @ttLF select 'PickZone',                    null,     -1,   null,               null, null

insert into @ttLF select 'OrderDate',                   null,   null,   null,               null, null
insert into @ttLF select 'DownloadedDate',              null,   null,   null,               null, null
insert into @ttLF select 'NB4Date',                     null,   null,   null,               null, null
insert into @ttLF select 'DeliveryStart',               null,   null,   null,               null, null
insert into @ttLF select 'DeliveryEnd',                 null,   null,   null,               null, null
insert into @ttLF select 'QualifiedDate',               null,   null,   null,               null, null
insert into @ttLF select 'PackedDate',                  null,     -1,   null,               null, null
insert into @ttLF select 'DateShipped',                 null,     -1,   null,               null, null
insert into @ttLF select 'OrderAge',                    null,   null,   null,               null, null

insert into @ttLF select 'ShipperAccountName',          null,   null,   null,               null, null
insert into @ttLF select 'AESNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipmentRefNumber',           null,   null,   null,               null, null

insert into @ttLF select 'ShipToCity',                  null,     -1,   null,               null, null
insert into @ttLF select 'ShipToState',                 null,     -1,   null,               null, null
insert into @ttLF select 'ShipToZip',                   null,     -1,   null,               null, null
insert into @ttLF select 'ShipToCountry',               null,     -1,   null,               null, null
insert into @ttLF select 'ReturnAddress',               null,   null,   null,               null, null
insert into @ttLF select 'MarkForAddress',              null,     -1,   null,               null, null
insert into @ttLF select 'FreightTerms',                null,   null,   null,               null, null
insert into @ttLF select 'FreightCharges',              null,   null,   null,               null, null
insert into @ttLF select 'BillToAccount',               null,   null,   null,               null, null
insert into @ttLF select 'BillToAddress',               null,   null,   null,               null, null

insert into @ttLF select 'TotalTax',                    null,     -1,   null,               null, null
insert into @ttLF select 'TotalShippingCost',           null,     -1,   null,               null, null
insert into @ttLF select 'TotalDiscount',               null,     -1,   null,               null, null
insert into @ttLF select 'Comments',                    null,     -1,   null,               null, null

insert into @ttLF select 'LoadNumber',                  null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null
insert into @ttLF select 'WaveFlag',                    null,   null,   null,               null, null
insert into @ttLF select 'TotalWeight',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalVolume',                 null,   null,   null,               null, null
insert into @ttLF select 'HostNumLines',                null,   null,   null,               null, null

insert into @ttLF select 'PreprocessFlag',              null,   null,   null,               null, null

insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'LoadId',                      null,   null,   null,               null, null

insert into @ttLF select 'ColorCode',                   null,   null,   null,               null, null
insert into @ttLF select 'CartonGroups',                null,   null,   null,               null, null

insert into @ttLF select 'NumCases',                    null,     -1,   null,               null, null
insert into @ttLF select 'ShipCompletePercent',         null,     -1,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,     -1,   null,               null, null

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
insert into @ttLF select 'OH_UDF11',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF12',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF13',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF14',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF15',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF16',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF17',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF18',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF19',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF20',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF21',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF22',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF23',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF24',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF25',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF26',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF27',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF28',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF29',                    null,   null,   null,               null, null
insert into @ttLF select 'OH_UDF30',                    null,   null,   null,               null, null

insert into @ttLF select 'vwOH_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOH_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOH_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOH_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOH_UDF5',                   null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* ------------ Fields not applicable in this context -----------*/
insert into @ttLF select 'WaveNo',                      null,     -2,   null,               null, null
insert into @ttLF select 'WaveType',                    null,     -2,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,     -2,   null,               null, null

insert into @ttLF select 'UnitsPicked',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsToPick',                 null,     -2,   null,               null, null
insert into @ttLF select 'ShortPick',                   null,     -2,   null,               null, null
insert into @ttLF select 'UnitsPacked',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsToPack',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsStaged',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsLoaded',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsToLoad',                 null,     -2,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,     -2,   null,               null, null
insert into @ttLF select 'UnitsToShip',                 null,     -2,   null,               null, null

insert into @ttLF select 'LPNsPicked',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsPacked',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsStaged',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsLoaded',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsToLoad',                  null,     -2,   null,               null, null
insert into @ttLF select 'LPNsShipped',                 null,     -2,   null,               null, null

/* Unused fields */
insert into @ttLF select 'PickBatchId',                 null,    -20,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,    -20,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,    -20,   null,               null, null
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null -- makes it FieldVisible = -2 and Selectable = N
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null -- makes it FieldVisible = -2 and Selectable = N
insert into @ttLF select 'ExchangeStatus',              null,     -2,   null,               null, null
insert into @ttLF select 'ShipComplete',                null,     -2,   null,               null, null
insert into @ttLF select 'ProcessOperation',            null,     -2,   null,               null, null

insert into @ttLF select 'vwUDF1',                      null,    -20,   null,               null, null
insert into @ttLF select 'vwUDF2',                      null,    -20,   null,               null, null
insert into @ttLF select 'vwUDF3',                      null,    -20,   null,               null, null
insert into @ttLF select 'vwUDF4',                      null,    -20,   null,               null, null
insert into @ttLF select 'vwUDF5',                      null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName,  'OrderId;PickTicket'

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/
/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Customer & Class';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'CustomerName',               null,   1,      null,               null, null,    null
insert into @ttLFE select 'OrderCategory1',             null,   1,      null,               null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',           null, null,    'DCount'
insert into @ttLFE select 'NumSKUs',                    null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',                    null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'NumUnits',                   null,   1,      null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by CustPO';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'CustPO',                     null,   1,      null,               null, null,    null
insert into @ttLFE select 'Account',                    null,   1,      null,               null, null,    null
insert into @ttLFE select 'Warehouse',                  null,   1,      null,               null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',           null, null,    'DCount'
insert into @ttLFE select 'NumLines',                   null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'NumSKUs',                    null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'TotalSalesAmount',           null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'NumUnits',                   null,   1,      null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by OrderType';
delete from @ttLFE;

/*                        Field                         Visible Visible Field                Width Display  Aggregate
                          Name                          Index           Caption                    Format   Method */
insert into @ttLFE select 'OrderType',                  null,   1,      null,                null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',            null, null,    'DCount'
insert into @ttLFE select 'NumSKUs',                    null,   1,      null,                null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',                    null,   1,      null,                null, null,    'Sum'
insert into @ttLFE select 'NumUnits',                   null,   1,      null,                null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by DC/Store';
delete from @ttLFE;

/*                        Field                         Visible Visible Field                Width Display  Aggregate
                          Name                          Index           Caption                    Format   Method */
insert into @ttLFE select 'ShipToStore',                null,   1,      null,                null, null,    null
insert into @ttLFE select 'OrderCategory1',             null,   1,      null,                null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',            null, null,    'DCount'
insert into @ttLFE select 'NumSKUs',                    null,   1,      null,                null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',                    null,   1,      null,                null, null,    'Sum'
insert into @ttLFE select 'NumUnits',                   null,   1,      null,                null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
select @ContextName       = 'Waving.Waves',
       @LayoutDescription = null; -- Applicable to all layouts in this context

delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'WaveNo',                     'Count',     '# Waves: {0:n0}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

/*----------------------------------------------------------------------------*/
select @ContextName       = 'Waving.Orders',
       @LayoutDescription = null; -- Applicable to all layouts  in this context

delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'PickTicket',                 'Count',     '# Orders: {0:n0}',           null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
