/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/13  AY      Status field disabled (HA-2091)
  2021/05/06  SJ      Added PickedDate (HA-2704)
  2021/03/17  KBB     Added Label Cancellation (HA-2311)
  2020/11/05  MS      Added LPN_UDF11 to LPN_UDF20 (JL-294)
  2020/08/05  AY      Revised layout Summary By Pallet & Status (HA-982)
  2020/07/20  SAK     Added SummaryLayout by Style (HA-1163)
  2020/05/20  MS      Added LPNStatusDesc (HA-604)
  2020/05/18  MS      Added WaveId & WaveNo (HA-593)
  2020/05/04  AY      Moved WH to front as that is key info for a multi-WH operation
  2020/04/03  AY      Associate Summary by Load/Wave layouts with ReservedLPNs selection (JL-190)
  2020/03/30  MS      Added InventoryClasses (HA-83)
  2020/02/11  AY      Added LPN_UDF fields
  2019/01/23  MS      Added SummaryLayout for InTransit LPNs (JL-56)
  2019/05/14  RBV     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/05/11  NB      Renamed Status to LPNStatus (CIMSV3-138)
  2017/09/29  YJ      pr_Setup_Layout: Change to setup Layouts using procedure (CIMSV3-73)
  2017/09/29  YJ      Initial revision.
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

select @ContextName = 'List.LPNs',
       @DataSetName = 'vwLPNs';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Expires in Days',               null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Receiving LPNs',                'ReceivedNotPutaway', null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Inventory On Hold',             null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Label Cancellation',            null,                 null,  null,   0,      null
/* Not active, for future use in case we need it. We would be using Receiving LPNs with Selection of LPNsInTransit */
insert into @Layouts select 'L',    'N',     'Inventory - InTransit',         'LPNsInTransit',       'I',  null,   0,      null

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
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'DestWarehouse',               null,   null,   null,               null, null

insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNTypeDescription',          null,   null,   null,               null, null
insert into @ttLF select 'LPNStatus',                   null,   null,   null,               null, null
insert into @ttLF select 'LPNStatusDesc',               null,   null,   null,               null, null
insert into @ttLF select 'OnhandStatus',                null,   null,   null,               null, null
insert into @ttLF select 'OnhandStatusDescription',     null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,     -1,   null,               null, null
insert into @ttLF select 'SKUDescription',              null,   null,   null,               null, null

insert into @ttLF select 'SKU1Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU2Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU3Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU4Description',             null,   null,   null,               null, null
insert into @ttLF select 'SKU5Description',             null,   null,   null,               null, null

insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, '{0:###,###,##0}'

insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null

insert into @ttLF select 'ExpiryDate',                  null,   null,   null,               null, null
insert into @ttLF select 'ExpiresInDays',               null,   null,   null,               null, null

insert into @ttLF select 'ReceiverNumber',              null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null

insert into @ttLF select 'PickBatchNo',                 null,    -20,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,     -1,   null,               null, null
insert into @ttLF select 'TaskId',                      null,   null,   null,               null, null
insert into @ttLF select 'PickedDate',                  null,   null,   null,               null, null

insert into @ttLF select 'ReservedQty',                 null,     -1,   null,               null, null
insert into @ttLF select 'DirectedQty',                 null,     -1,   null,               null, null
insert into @ttLF select 'AllocableQty',                null,     -1,   null,               null, null

insert into @ttLF select 'CustPO',                      null,     -1,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,     -1,   null,               null, null
insert into @ttLF select 'ShipTo',                      null,     -1,   null,               null, null
insert into @ttLF select 'CustAccount',                 null,   null,   null,               null, null
insert into @ttLF select 'CustAccountName',             null,   null,   null,               null, null

insert into @ttLF select 'LoadNumber',                  null,     -1,   null,               null, null

insert into @ttLF select 'DestZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestLocation',                null,   null,   null,               null, null
insert into @ttLF select 'LocationType',                null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,     -1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'PutawayClass',                null,   null,   null,               null, null
insert into @ttLF select 'PickingClass',                null,   null,   null,               null, null

insert into @ttLF select 'Lot',                         null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null
insert into @ttLF select 'AlternateLPN',                null,   null,   null,               null, null
insert into @ttLF select 'CartonType',                  null,   null,   null,               null, null

insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null

insert into @ttLF select 'UCCBarcode',                  null,     -1,   null,               null, null
insert into @ttLF select 'TrackingNo',                  null,   null,   null,               null, null
insert into @ttLF select 'PackageSeqNo',                null,   null,   null,               null, null
insert into @ttLF select 'PickingZone',                 null,     -1,   null,               null, null
insert into @ttLF select 'ReturnTrackingNo',            null,   null,   null,               null, null

insert into @ttLF select 'CoO',                         null,   null,   null,               null, null
insert into @ttLF select 'ASNCase',                     null,   null,   null,               null, null
insert into @ttLF select 'ReceivedDate',                null,   null,   null,               null, null
insert into @ttLF select 'LastMovedDate',               null,   null,   null,               null, null
insert into @ttLF select 'InventoryStatus',             null,   null,   null,               null, null
insert into @ttLF select 'ProductCost',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitCost',                    null,     -1,   null,               null, null
insert into @ttLF select 'UnitPrice',                   null,     -1,   null,               null, null
insert into @ttLF select 'PrintFlags',                  null,     -2,   null,               null, null
insert into @ttLF select 'Reference',                   null,     -1,   null,               null, null

insert into @ttLF select 'ActualWeight',                null,   null,   null,               null, null
insert into @ttLF select 'ActualVolume',                null,   null,   null,               null, null
insert into @ttLF select 'EstimatedWeight',             null,   null,   null,               null, null
insert into @ttLF select 'EstimatedVolume',             null,   null,   null,               null, null

insert into @ttLF select 'UnitWeight',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitVolume',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitLength',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitWidth',                   null,   null,   null,               null, null
insert into @ttLF select 'UnitHeight',                  null,   null,   null,               null, null

insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null

insert into @ttLF select 'PalletId',                    null,   null,   null,               null, null
insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'PickBatchId',                 null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'ShipmentId',                  null,   null,   null,               null, null
insert into @ttLF select 'LoadId',                      null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'ReceiverId',                  null,   null,   null,               null, null

insert into @ttLF select 'LPN_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF5',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF6',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF7',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF8',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF9',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF10',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF11',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF12',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF13',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF14',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF15',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF16',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF17',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF18',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF19',                   null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF20',                   null,   null,   null,               null, null

insert into @ttLF select 'vwLPN_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLPN_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLPN_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLPN_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLPN_UDF5',                  null,   null,   null,               null, null

insert into @ttLF select 'SKU_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF5',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF6',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF7',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF8',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF9',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU_UDF10',                   null,   null,   null,               null, null

insert into @ttLF select 'RH_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF5',                     null,   null,   null,               null, null

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

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
/* Unused fields */
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null -- makes it FieldVisible = -2 and Selectable = N
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null -- makes it FieldVisible = -2 and Selectable = N

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'LPNId;LPN' /* Key fields */;

/******************************************************************************/
/* Expires in Days Layout */
/******************************************************************************/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null

insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNTypeDescription',          null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'LPNStatusDesc',               null,   null,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null
insert into @ttLF select 'OnhandStatus',                null,     -2,   null,               null, null
insert into @ttLF select 'OnhandStatusDescription',     null,     -1,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,     -1,   null,               null, null
insert into @ttLF select 'SKUDescription',              null,   null,   null,               null, null

insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null
insert into @ttLF select 'ReservedQty',                 null,     -1,   null,               null, null

insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null

insert into @ttLF select 'ExpiryDate',                  null,   null,   null,               null, null
insert into @ttLF select 'ExpiresInDays',               null,      1,   null,               null, null
insert into @ttLF select 'Lot',                         null,     -1,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'ReceiverNumber',              null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null

insert into @ttLF select 'PickBatchNo',                 null,    -20,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'TaskId',                      null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,     -1,   null,               null, null

insert into @ttLF select 'DestZone',                    null,     -1,   null,               null, null
insert into @ttLF select 'DestLocation',                null,     -1,   null,               null, null
insert into @ttLF select 'LocationType',                null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,     -1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,     -1,   null,               null, null
insert into @ttLF select 'PutawayClass',                null,     -1,   null,               null, null
insert into @ttLF select 'PickingClass',                null,     -1,   null,               null, null
insert into @ttLF select 'DestWarehouse',               null,     -1,   null,               null, null

insert into @ttLF select 'CoO',                         null,     -1,   null,               null, null
insert into @ttLF select 'ASNCase',                     null,     -1,   null,               null, null
insert into @ttLF select 'ReceivedDate',                null,     -1,   null,               null, null

insert into @ttLF select 'UnitsPerInnerPack',           null,     -1,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,     -1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Expires in Days', @ttLF, @DataSetName, 'LPNId;LPN' /* Key fields */;

/******************************************************************************/
/* Receiving LPNs */
/******************************************************************************/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null

insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNTypeDescription',          null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'LPNStatusDesc',               null,   null,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null
insert into @ttLF select 'OnhandStatus',                null,   null,   null,               null, null
insert into @ttLF select 'OnhandStatusDescription',     null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'SKUDescription',              null,   null,   null,               null, null

insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null

insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null

insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null

insert into @ttLF select 'DestZone',                    null,      1,   null,               null, null
insert into @ttLF select 'DestLocation',                null,      1,   null,               null, null
insert into @ttLF select 'DestWarehouse',               null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'PutawayClass',                null,   null,   null,               null, null
insert into @ttLF select 'PickingClass',                null,   null,   null,               null, null

insert into @ttLF select 'ReceivedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ASNCase',                     null,   null,   null,               null, null
insert into @ttLF select 'CoO',                         null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'UnitsPerInnerPack',           null,     -1,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,     -1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Receiving LPNs', @ttLF, @DataSetName, 'LPNId;LPN' /* KeyFields */;

/******************************************************************************/
/* Inventory InTransit */
/******************************************************************************/
/* Copy fields from Standards Layout */
exec pr_LayoutFields_Copy @ContextName, 'Receiving LPNs', @ContextName, 'Inventory - InTransit';

/******************************************************************************/
/* Label Cancellation */
/******************************************************************************/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null

insert into @ttLF select 'DestWarehouse',               null,   null,   null,               null, null
insert into @ttLF select 'LPNStatusDesc',               null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null

insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'UCCBarcode',                  null,   null,   null,               null, null
insert into @ttLF select 'PackageSeqNo',                null,   null,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'TrackingNo',                  null,   null,   null,               null, null

insert into @ttLF select 'PackingGroup',                null,   null,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Label Cancellation', @ttLF, @DataSetName, 'LPNId;LPN' /* KeyFields */;

/******************************************************************************/
/* Inventory on hold */
/******************************************************************************/
delete from @ttLF

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null

insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNTypeDescription',          null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'LPNStatusDesc',               null,   null,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,    -20,   null,               null, null
insert into @ttLF select 'OnhandStatus',                null,   null,   null,               null, null
insert into @ttLF select 'OnhandStatusDescription',     null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,     -1,   null,               null, null
insert into @ttLF select 'SKUDescription',              null,   null,   null,               null, null

insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null

insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'ExpiryDate',                  null,   null,   null,               null, null
insert into @ttLF select 'ExpiresInDays',               null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null

insert into @ttLF select 'PickBatchNo',                 null,     -1,   null,               null, null
insert into @ttLF select 'TaskId',                      null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,     -1,   null,               null, null
insert into @ttLF select 'ReservedQty',                 null,     -1,   null,               null, null

insert into @ttLF select 'DestWarehouse',               null,   null,   null,               null, null
insert into @ttLF select 'DestZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestLocation',                null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'PutawayClass',                null,   null,   null,               null, null
insert into @ttLF select 'PickingClass',                null,   null,   null,               null, null

insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Inventory On Hold', @ttLF, @DataSetName, 'LPNId;LPN' /* KeyFields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Location';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'Location',               null,        1, null,          null, null,    null
insert into @ttLFE select 'LPN',                    null,        1, null,          null, null,    'Count'
insert into @ttLFE select 'SKU',                    null,        1, null,          null, null,    'DCount'
insert into @ttLFE select 'Quantity',               null,        1, null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by SKU';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'SKU',                    null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'Count'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary By Style';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'SKU1',                   null,   null,   null,          null, null,    null
insert into @ttLFE select 'SKU2',                   null,   null,   null,          null, null,    'DCount'
insert into @ttLFE select 'SKU3',                   null,   null,   null,          null, null,    'DCount'
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'Count'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By Pallet & Status'; -- this is used as default in Load Entity Info, so do not change it
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'Pallet',                 null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPNStatusDesc',          null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'Count'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By ASN, SKU';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'ReceiptNumber',          null,      1,   null,          null, null,    null
insert into @ttLFE select 'SKU',                    null,      1,   null,          null, null,    null
insert into @ttLFE select 'Pallet',                 null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'LPNsInTransit' /* Selection */;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By Wave';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'PickBatchNo',            null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPNStatusDesc',          null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'Count'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'
insert into @ttLFE select 'PickTicket',             null,      1,   null,          null, null,    'DCount'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'ReservedLPNs' /* Selection */;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By Load';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'LoadNumber',             null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPN',                    null,      1,   null,          null, null,    'Count'
insert into @ttLFE select 'Location',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',             null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'Quantity',               null,      1,   null,          null, null,    'Sum'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE, 'ReservedLPNs' /* Selection */;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
