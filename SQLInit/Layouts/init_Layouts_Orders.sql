/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/08  SAK     Summary by Date Layout (HA-2703)
  2021/03/09  AJM     Added SoldToName (HA-2048)
  2021/03/01  SAK     Portbacked the layout By Cust PO/DC (HA-2047)
  2021/02/23  PKK     Added OrderTypeDesc, WaveSeqNo and LoadSeqNo,
                      ShipCompletePercent, Numcases, CarrierOptions, CartonGroups, ColorCode, WaveType, SourceSystem (CIMSV3-1364)
  2021/02/17  SGK     Added ReturnLabelRequired, TotalShipmentValue, ShipFromCompanyId, UCC128LabelFormat,
                      PackingListFormat, ContentsLabelFormat, PriceStickerFormat, PrevStatus, CreatedOn, ModifiedOn (CIMSV3-1364)
  2021/02/03  TK      Added EstimatedCartons (HA-1964)
  2021/01/20  AY      Added LoadGroup (HA-1933)
  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/06/01  AY      Added HostNumLines
  2020/05/30  VS      Added FreightTerms and other fields in vwOrderHeaders (HA-697)
  2020/05/28  RKC     Changed the visible for NumLPNs field to -1 (HA-587)
  2020/05/18  MS      Added WaveGroup, WaveId & WaveNo (HA-593)
  2020/05/09  MS      Hide deprecated fields
  2019/06/17  RIA     Added Summary Layout By Customer/Start Ship (OB2-861)
  2019/05/14  RBV     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/07/12  NB      Added Summary Fields setup section(CIMSV3-298)
  2017/10/12  AY      Initial revision.
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

select @ContextName = 'List.Orders',
       @DataSetName = 'vwOrderHeaders';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'By Cust PO/DC',              null,          null,  null,   0,      null

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
insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'HasNotes',                    null,   null,   null,               null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderTypeDesc',               null,   null,   null,               null, null
insert into @ttLF select 'OrderTypeDescription',        null,   null,   null,               null, null
insert into @ttLF select 'OrderStatus',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderStatusDesc',             null,   null,   null,               null, null
insert into @ttLF select 'StatusGroup',                 null,     -1,   null,               null, null -- more so for selections

insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null

insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null

insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveType',                    null,   null,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,   null,   null,               null, null

insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumCases',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,   null,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'UnitsToAllocate',             null,   null,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,   null,   null,               null, null
insert into @ttLF select 'EstimatedCartons',            null,   null,   null,               null, null

insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'CustomerName',                null,     -1,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToAddressLine1',          null,     -1,   null,               null, null
insert into @ttLF select 'ShipToAddressLine2',          null,     -1,   null,               null, null
insert into @ttLF select 'ShipToCityStateZip',          null,     -1,   null,               null, null

insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipViaDesc',                 null,   null,   null,               null, null

insert into @ttLF select 'NumLines',                    null,   null,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,   null,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,     -1,   null,               null, null
insert into @ttLF select 'WaveDropLocation',            null,     -1,   null,               null, null
insert into @ttLF select 'WaveShipDate',                null,     -1,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'CancelDays',                  null,   null,   null,               null, null
insert into @ttLF select 'DeliveryRequirement',         null,   null,   null,               null, null
insert into @ttLF select 'CarrierOptions',              null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory1',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory3',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory4',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory5',              null,   null,   null,               null, null
insert into @ttLF select 'ShipCompletePercent',         null,   null,   null,               null, null
insert into @ttLF select 'ProcessOperation',            null,   null,   null,               null, null

insert into @ttLF select 'PickZone',                    null,   -1,     null,               null, null
insert into @ttLF select 'WaveGroup',                   null,   null,   null,               null, null
insert into @ttLF select 'CartonGroups',                null,   null,   null,               null, null
insert into @ttLF select 'OrderDate',                   null,   null,   null,               null, null
insert into @ttLF select 'DownloadedDate',              null,   null,   null,               null, null
insert into @ttLF select 'DownloadedOn',                null,   null,   null,               null, null
insert into @ttLF select 'NB4Date',                     null,   null,   null,               null, null
insert into @ttLF select 'DeliveryStart',               null,   null,   null,               null, null
insert into @ttLF select 'DeliveryEnd',                 null,   null,   null,               null, null
insert into @ttLF select 'QualifiedDate',               null,   null,   null,               null, null
insert into @ttLF select 'PackedDate',                  null,   null,   null,               null, null
insert into @ttLF select 'DateShipped',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderAge',                    null,   null,   null,               null, null
insert into @ttLF select 'ColorCode',                   null,   null,   null,               null, null

insert into @ttLF select 'ShipperAccountName',          null,   null,   null,               null, null
insert into @ttLF select 'AESNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipmentRefNumber',           null,   null,   null,               null, null

insert into @ttLF select 'ShipToCity',                  null,   -1,     null,               null, null
insert into @ttLF select 'ShipToState',                 null,   -1,     null,               null, null
insert into @ttLF select 'ShipToZip',                   null,   -1,     null,               null, null
insert into @ttLF select 'ShipToCountry',               null,   -1,     null,               null, null
insert into @ttLF select 'ReturnAddress',               null,   null,   null,               null, null
insert into @ttLF select 'MarkForAddress',              null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipFromCompanyId',           null,   null,   null,               null, null
insert into @ttLF select 'Carrier',                     null,   null,   null,               null, null
insert into @ttLF select 'FreightTerms',                null,   null,   null,               null, null
insert into @ttLF select 'FreightCharges',              null,   null,   null,               null, null
insert into @ttLF select 'BillToAccount',               null,   null,   null,               null, null
insert into @ttLF select 'BillToAddress',               null,   null,   null,               null, null

insert into @ttLF select 'TotalTax',                    null,   null,   null,               null, null
insert into @ttLF select 'TotalShippingCost',           null,   null,   null,               null, null
insert into @ttLF select 'TotalShipmentValue',          null,   null,   null,               null, null
insert into @ttLF select 'TotalDiscount',               null,   null,   null,               null, null
insert into @ttLF select 'Comments',                    null,   null,   null,               null, null

insert into @ttLF select 'UCC128LabelFormat',           null,   null,   null,               null, null
insert into @ttLF select 'PackingListFormat',           null,   null,   null,               null, null
insert into @ttLF select 'ContentsLabelFormat',         null,   null,   null,               null, null
insert into @ttLF select 'PriceStickerFormat',          null,   null,   null,               null, null
insert into @ttLF select 'ReturnLabelRequired',         null,   null,   null,               null, null

insert into @ttLF select 'LoadNumber',                  null,     -1,   null,               null, null
insert into @ttLF select 'LoadGroup',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null
insert into @ttLF select 'ShipComplete',                null,   null,   null,               null, null
insert into @ttLF select 'WaveFlag',                    null,   null,   null,               null, null
insert into @ttLF select 'TotalWeight',                 null,   null,   null,               null, null
insert into @ttLF select 'TotalVolume',                 null,   null,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,   null,   null,               null, null
insert into @ttLF select 'PrevWaveNo',                  null,   null,   null,               null, null
insert into @ttLF select 'PrevStatus',                  null,   null,   null,               null, null
insert into @ttLF select 'HostNumLines',                null,   null,   null,               null, null

insert into @ttLF select 'UnitsPicked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsToPick',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPacked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsToPack',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsStaged',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsLoaded',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsToLoad',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,     -1,   null,               null, null
insert into @ttLF select 'UnitsToShip',                 null,     -1,   null,               null, null

insert into @ttLF select 'LPNsPicked',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsPacked',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsStaged',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsLoaded',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsToLoad',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsShipped',                 null,     -1,   null,               null, null
insert into @ttLF select 'LPNsToShip',                  null,     -1,   null,               null, null

insert into @ttLF select 'PreprocessFlag',              null,     -1,   null,               null, null
insert into @ttLF select 'ShortPick',                   null,     -1,   null,               null, null
insert into @ttLF select 'ShippedDate',                 null,   null,   null,               null, null

insert into @ttLF select 'WaveSeqNo',                   null,   null,   null,               null, null
insert into @ttLF select 'LoadSeqNo',                   null,   null,   null,               null, null

insert into @ttLF select 'VASCodes',                    null,   null,   null,               null, null
insert into @ttLF select 'VASDescriptions',             null,   null,   null,               null, null

insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'LoadId',                      null,   null,   null,               null, null

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

insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'CreatedOn',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedOn',                  null,   null,   null,               null, null

/* Unused fields */
insert into @ttLF select 'PickBatchId',                 null,    -30,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,    -30,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,    -20,   null,               null, null
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null -- makes it FieldVisible = -2 and Selectable = N
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null -- makes it FieldVisible = -2 and Selectable = N

insert into @ttLF select 'vwUDF1',                      null,    -20,   null,               null, null
insert into @ttLF select 'vwUDF2',                      null,    -20,   null,               null, null
insert into @ttLF select 'vwUDF3',                      null,    -20,   null,               null, null
insert into @ttLF select 'vwUDF4',                      null,    -20,   null,               null, null
insert into @ttLF select 'vwUDF5',                      null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'OrderId;PickTicket' /* Key fields */;

/*----------------------------------------------------------------------------*/
/* Layout Fields for By Cust PO/DC Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'AccountName',                 null,      1,   null,                100, null
insert into @ttLF select 'CustPO',                      null,      1,   null,                105, null
--insert into @ttLF select 'ShipToId',                    null,      1,   null,                 80, null
insert into @ttLF select 'ShipToStore',                 null,      1,   null,                 80, null
insert into @ttLF select 'ShipToCityStateZip',          null,      1,   null,                150, null
insert into @ttLF select 'PickTicket',                  null,      1,   null,                105, null
insert into @ttLF select 'LPNsAssigned',                null,      1,   null,                 70, null
insert into @ttLF select 'NumUnits',                    null,      1,   null,                 65, null
insert into @ttLF select 'UnitsPicked',                 null,      1,   null,                 70, null
insert into @ttLF select 'UnitsPacked',                 null,      1,   null,                 80, null
insert into @ttLF select 'UnitsToPack',                 null,      1,   null,                 90, null
insert into @ttLF select 'UnitsStaged',                 null,      1,   null,                 70, null
insert into @ttLF select 'UnitsLoaded',                 null,      1,   null,                 70, null
insert into @ttLF select 'UnitsShipped',                null,      1,   null,                 70, null

/* Add Fields to Layout */
exec pr_LayoutFields_Setup @ContextName, 'By Cust PO/DC', @ttLF, @DataSetName,'OrderId;PickTicket'/* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Account';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'Account',                    null,   1,      null,               null, null,    null
insert into @ttLFE select 'AccountName',                null,   1,      null,               null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',           null, null,    'DCount'
insert into @ttLFE select 'NumLines',                   null,   -1,     null,               null, null,    'Sum'
insert into @ttLFE select 'NumSKUs',                    null,   -1,     null,               null, null,    'Sum'
insert into @ttLFE select 'NumUnits',                   null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPicked',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPick',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPacked',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPack',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsLoaded',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToLoad',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsShipped',               null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Ship Method';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'ShipVia',                    null,   1,      null,               null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',           null, null,    'DCount'
insert into @ttLFE select 'NumUnits',                   null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPicked',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPick',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPacked',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPack',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsLoaded',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToLoad',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsShipped',               null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Order Class';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'OrderCategory1',             null,   1,      null,               null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',           null, null,    'DCount'
insert into @ttLFE select 'NumUnits',                   null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPicked',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPick',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPacked',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPack',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsLoaded',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToLoad',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsShipped',               null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Order Type';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'OrderTypeDescription',       null,   1,      null,               null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',           null, null,    'DCount'
insert into @ttLFE select 'NumUnits',                   null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPicked',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPick',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPacked',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPack',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsLoaded',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToLoad',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsShipped',               null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By Customer/Start Ship';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'CustomerName',               null,   1,      null,               null, null,    null
insert into @ttLFE select 'ShipToId',                   null,   1,      null,               null, null,    null
insert into @ttLFE select 'DesiredShipDate',            null,   1,      null,               null, null,    null
insert into @ttLFE select 'Carrier',                    null,   1,      null,               null, null,    null
insert into @ttLFE select 'CancelDays',                 null,   null,   null,               null, null,    null
insert into @ttLFE select 'TotalSalesAmount',           null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'NumLines',                   null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'NumUnits',                   null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsAssigned',              null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToAllocate',            null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPicked',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPick',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPacked',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPack',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsLoaded',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToLoad',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'LPNsPacked',                 null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'LPNsLoaded',                 null,   1,      null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Date';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'OrderTypeDescription',       null,   1,      null,               null, null,    null
insert into @ttLFE select 'DownloadedDate',             null,   1,      null,               null, null,    null
insert into @ttLFE select 'DownloadedOn',               null,   1,      null,               null, null,    null
insert into @ttLFE select 'PickTicket',                 null,   1,      'Orders',           null, null,    'DCount'
insert into @ttLFE select 'NumUnits',                   null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPick',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPicked',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsPacked',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToPack',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsLoaded',                null,   1,      null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToLoad',                null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsShipped',               null,   1,      null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'PickTicket',                 'Count',     '# PTs: {0:n0}',              null
insert into @ttLSF select 'TotalSalesAmount',           'Sum',       '{0:c2}',                     null

exec pr_Setup_LayoutSummaryFields null, @LayoutDescription, @ttLSF;

Go
