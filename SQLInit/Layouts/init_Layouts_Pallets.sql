/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/06  AJM     PutawayClass: Changed the visibility from null to -1 (CIMSV3-1334)
  2021/02/04  AJM     Added TrackingNo, PrintFlags, PutawayClass, ModifiedOn (CIMSV3-1334)
  2021/01/07  KBB     Changes to resolve the display of duplicate fields (OB2-1329)
  2020/12/30  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/07/28  AY      Added Pallet.Reference (HA-1244)
  2020/07/17  PHK     Added several Order fields (HA-1153)
  2020/05/18  MS      Added WaveId & WaveNo (HA-593)
  2020/02/19  MS      Added additional fields (JL-104)
  2019/05/14  RBV     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2017/09/29  YJ      pr_Setup_Layout: Change to setup Layouts using procedure (CIMSV3-73)
  2017/09/14  CK      Added PickingClass and Pickpath (CIMSV3-41)
                      Initial revision.
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

select @ContextName = 'List.Pallets',
       @DataSetName = 'vwPallets';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Shipping Pallets',           'Default',     null,  null,   0,      null

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
insert into @ttLF select 'Pallet',                      null,      1,   null,               null, null
insert into @ttLF select 'PalletType',                  null,    -21,   null,               null, null
insert into @ttLF select 'PalletTypeDesc',              null,   null,   null,               null, null
insert into @ttLF select 'PalletStatus',                null,   null,   null,               null, null
insert into @ttLF select 'PalletStatusDesc',            null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'SKUDescription',              null,   null,   null,               null, null

insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null

insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'PickingZone',                 null,     -1,   null,               null, null

insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null

insert into @ttLF select 'PickBatchNo',                 null,    -20,   null,               null, null
insert into @ttLF select 'WaveType',                    null,     -1,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'Account',                     null,     -1,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,     -1,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,     -1,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,     -1,   null,               null, null
insert into @ttLF select 'TrackingNo',                  null,   null,   null,               null, null
insert into @ttLF select 'PrintFlags',                  null,   null,   null,               null, null

insert into @ttLF select 'PackingByUser',               null,     -1,   null,               null, null
insert into @ttLF select 'PickingClass',                null,   null,   null,               null, null
insert into @ttLF select 'PutawayClass',                null,     -1,   null,               null, null
insert into @ttLF select 'PickPath',                    null,     -1,   null,               null, null

insert into @ttLF select 'Weight',                      null,     -1,   null,               null, null
insert into @ttLF select 'Volume',                      null,     -1,   null,               null, null

insert into @ttLF select 'LocationType',                null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,     -1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
/* Id fields */
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'PickBatchId',                 null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'PalletId',                    null,   null,   null,               null, null
insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipmentId',                  null,   null,   null,               null, null
insert into @ttLF select 'LoadId',                      null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceiverId',                  null,   null,   null,               null, null
/* UDFs */
insert into @ttLF select 'PAL_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'PAL_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'PAL_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'PAL_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'PAL_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'vwPAL_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwPAL_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwPAL_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwPAL_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwPAL_UDF5',                  null,   null,   null,               null, null

/* Common fields */
insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'ModifiedOn',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
/* Unused fields */
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null -- makes it FieldVisible = -2 and Selectable = N
insert into @ttLF select 'StatusDesc',                  null,    -20,   null,               null, null -- makes it FieldVisible = -2 and Selectable = N

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'PalletId;Pallet' /* Key fields */;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Shipping Pallets Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'Pallet',                      null,      1,   null,               null, null
insert into @ttLF select 'PalletStatusDesc',            null,      1,   null,               null, null
insert into @ttLF select 'SKU1',                        null,      1,   null,               null, null
insert into @ttLF select 'SKU2',                        null,      1,   null,               null, null
insert into @ttLF select 'SKU3',                        null,      1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,      1,   null,               null, null
insert into @ttLF select 'Quantity',                    null,      1,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,      1,   null,               null, null
insert into @ttLF select 'Location',                    null,      1,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,      1,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,      1,   null,                155, null
insert into @ttLF select 'CustPO',                      null,      1,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,      1,   null,               null, null
insert into @ttLF select 'AccountName',                 null,      1,   null,               null, null
insert into @ttLF select 'ShipToCityStateZip',          null,      1,   null,               null, null

/* Add Fields to Layout */
exec pr_LayoutFields_Setup @ContextName, 'Shipping Pallets', @ttLF, @DataSetName,'PalletId;Pallet'/* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by SKU';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'SKU',                        null,      1,   null,               null, null,    null
insert into @ttLFE select 'SKU1',                       null,   null,   null,               null, null,    null
insert into @ttLFE select 'SKU2',                       null,   null,   null,               null, null,    null
insert into @ttLFE select 'SKU3',                       null,   null,   null,               null, null,    null
insert into @ttLFE select 'SKU4',                       null,   null,   null,               null, null,    null
insert into @ttLFE select 'SKU5',                       null,   null,   null,               null, null,    null
insert into @ttLFE select 'Pallet',                     null,      1,   null,               null, null,    'Count'
insert into @ttLFE select 'Location',                   null,      1,   null,               null, null,    'DCount'
insert into @ttLFE select 'NumLPNs',                    null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'InnerPacks',                 null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'Quantity',                   null,      1,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Load/Cust PO';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'LoadNumber',                 null,      1,   null,               null, null,    null
insert into @ttLFE select 'CustPO',                     null,      1,   null,               null, null,    null
insert into @ttLFE select 'ShipToStore',                null,      1,   null,               null, null,    null
insert into @ttLFE select 'Pallet',                     null,      1,   null,               null, null,    'Count'
insert into @ttLFE select 'Location',                   null,      1,   null,               null, null,    'DCount'
insert into @ttLFE select 'NumLPNs',                    null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'InnerPacks',                 null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'Quantity',                   null,      1,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'Pallet',                     'Count',     '# Pallets: {0:n0}',          null
insert into @ttLSF select 'Location',                   'DCount',    '{0:###,###,###}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go