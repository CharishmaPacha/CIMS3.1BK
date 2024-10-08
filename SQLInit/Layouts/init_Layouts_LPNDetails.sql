/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/12/22  SAK     Changed Visible as -1 for ReceiptLine (CIMSV3-1288)
  2020/10/19  MS      Added LPN UDF's & Code Formated (JL-266)
  2020/05/20  MS      Added LPNStatusDesc (HA-604)
  2020/05/18  MS      Added WaveId & WaveNo (HA-593)
  2020/03/30  MS      Added InventoryClasses (HA-83)
  2019/05/14  RBV     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/01/05  RT      Initial revision (CIMSV3-191)
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

select @ContextName = 'List.LPNDetails',
       @DataSetName = 'vwLPNDetails';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
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
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPNDetailId',                 null,   null,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'LPNLine',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'AlternateLPN',                null,   null,   null,               null, null

insert into @ttLF select 'LPNStatus',                   null,   null,   null,               null, null
insert into @ttLF select 'LPNStatusDesc',               null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'SKUDescription',              null,   null,   null,               null, null
insert into @ttLF select 'SKU1Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU2Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU3Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU4Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU5Description',             null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'CoO',                         null,   null,   null,               null, null

insert into @ttLF select 'OnhandStatus',                null,   null,   null,               null, null
insert into @ttLF select 'OnhandStatusDescription',     null,   null,   null,               null, null
insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null
insert into @ttLF select 'ReservedQuantity',            null,   null,   null,               null, null
insert into @ttLF select 'DisplayQuantity',             null,     -2,   null,               null, null
insert into @ttLF select 'UnitsPerPackage',             null,   null,   null,               null, null
insert into @ttLF select 'ReceivedUnits',               null,     -1,   null,               null, null

insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null

insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'OwnershipDescription',        null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null -- we have dest Warehouse below
insert into @ttLF select 'WarehouseDescription',        null,   null,   null,               null, null
insert into @ttLF select 'ASNCase',                     null,   null,   null,               null, null
insert into @ttLF select 'TaskId',                      null,   null,   null,               null, null
/* Order Info */
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'PackageSeqNo',                null,   null,   null,               null, null
insert into @ttLF select 'OrderLine',                   null,   null,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,    -20,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,     -1,   null,               null, null

insert into @ttLF select 'DestWarehouse',               null,   null,   null,               null, null
insert into @ttLF select 'DestZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestLocation',                null,   null,   null,               null, null
insert into @ttLF select 'DisplayDestination',          null,   null,   null,               null, null

insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptLine',                 null,   null,   null,               null, null
insert into @ttLF select 'ReplenishOrder',              null,   null,   null,               null, null

/* SKU Info */
insert into @ttLF select 'InnerPacksPerLPN',            null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerLPN',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitWeight',                  null,     -1,   null,               null, null
insert into @ttLF select 'ShipPack',                    null,     -1,   null,               null, null
insert into @ttLF select 'DefaultUoM',                  null,     -1,   null,               null, null
/* Location Info */
insert into @ttLF select 'LocationType',                null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,     -1,   null,               null, null
insert into @ttLF select 'PickingZone',                 null,     -1,   null,               null, null
insert into @ttLF select 'Barcode',                     null,     -1,   null,               null, null
insert into @ttLF select 'MinReplenishLevel',           null,     -1,   null,               null, null
insert into @ttLF select 'MaxReplenishLevel',           null,     -1,   null,               null, null
insert into @ttLF select 'ReplenishUoM',                null,     -1,   null,               null, null

insert into @ttLF select 'Weight',                      null,   null,   null,               null, null
insert into @ttLF select 'Volume',                      null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'LastPutawayDate',             null,   null,   null,               null, null
insert into @ttLF select 'PickedBy',                    null,     -1,   null,               null, null
insert into @ttLF select 'PickedDate',                  null,     -1,   null,               null, null
insert into @ttLF select 'PackedBy',                    null,     -1,   null,               null, null
insert into @ttLF select 'PackedDate',                  null,     -1,   null,               null, null

insert into @ttLF select 'LPNWeight',                   null,     -1,   null,               null, null
insert into @ttLF select 'LPNVolume',                   null,     -1,   null,               null, null
insert into @ttLF select 'CartonType',                  null,     -1,   null,               null, null

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceiptDetailId',             null,   null,   null,               null, null
insert into @ttLF select 'ReplenishOrderId',            null,   null,   null,               null, null
insert into @ttLF select 'ReplenishOrderDetailId',      null,   null,   null,               null, null
insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailId',               null,   null,   null,               null, null
insert into @ttLF select 'PickBatchId',                 null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'PalletId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipmentId',                  null,   null,   null,               null, null
insert into @ttLF select 'LoadId',                      null,   null,   null,               null, null

insert into @ttLF select 'LPND_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF5',                   null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
/* Unused Fields */
insert into @ttLF select 'LPNStatusDescription',        null,    -20,   null,               null, null
insert into @ttLF select 'UDF1',                        null,    -20,   null,               null, null
insert into @ttLF select 'UDF2',                        null,    -20,   null,               null, null
insert into @ttLF select 'UDF3',                        null,    -20,   null,               null, null
insert into @ttLF select 'UDF4',                        null,    -20,   null,               null, null
insert into @ttLF select 'UDF5',                        null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'LPNDetailId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by SKU';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'SKU',                    null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPNDetailId',            null,      1,   'Lines',       null, null,    'Count'
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'ReservedQuantity',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'AllocableQty',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Style/Color/Size';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'SKU1',                   null,      1,   null,          null, null,    null
insert into @ttLFE select 'SKU2',                   null,      1,   null,          null, null,    null
insert into @ttLFE select 'SKU3',                   null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPNDetailId',            null,      1,   'Lines',       null, null,    'Count'
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'ReservedQuantity',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'AllocableQty',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Style';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'SKU1',                   null,      1,   null,          null, null,    null
insert into @ttLFE select 'SKU2',                   null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'SKU3',                   null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'LPNDetailId',            null,      1,   'Lines',       null, null,    'Count'
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'ReservedQuantity',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'AllocableQty',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Style & WH';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'SKU1',                   null,      1,   null,          null, null,    null
insert into @ttLFE select 'DestWarehouse',          null,      1,   null,          null, null,    null
insert into @ttLFE select 'SKU2',                   null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'SKU3',                   null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'LPNDetailId',            null,      1,   'Lines',       null, null,    'Count'
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'ReservedQuantity',       null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'AllocableQty',           null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'LPN',                        'Count',     '# Lines: {0:n0}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
