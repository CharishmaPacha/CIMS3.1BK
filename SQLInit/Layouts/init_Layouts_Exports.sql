/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/17  SGK     Added SKU_SortSeq (HA-2907)
  2021/05/02  AY      Added AbsTransQty and LoadType
  2021/02/04  SK      Added NumPallets, NumLPNs, NumCartons, InnerPacks, Quantity (HA-1896)
  2021/01/20  PKK     Corrected the file as per the template (CIMSV3-1282)
  2020/11/20  NB      DefaultSortOrder set to TransDateTime Desc for Listing Layouts (HA-205)
  2020/10/21  TK      Added FromLPNId & FromLPN (HA-1516)
  2020/07/07  MRK     Added SourceSystem field in Standard layout (HA-1063)
  2020/05/08  AY      Fix Quantity in summary layouts (HA-402)
  2020/05/04  AY      Setup layout by SKU/WH & IC
  2020/03/30  YJ      Added Inventory Classses (HA-85)
  2020/04/20  MS      Added ExportStatus,ExportStatusDesc (HA-232)
  2019/05/14  KBB     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/03/23  AJ      Added summaryfield setup for TransQty (CIMSV3-239)
  2018/02/02  AJ      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName         TName,
        @DataSetName         TName,

        @Layouts             TLayoutTable,
        @LayoutDescription   TDescription,
        @NewLayout           TName,

        @ttLF                TLayoutFieldsTable,
        @ttLFE               TLayoutFieldsExpandedTable,
        @ttLSF               TLayoutSummaryFields,
        @BusinessUnit        TBusinessUnit;

select @ContextName = 'List.Exports',
       @DataSetName = 'vwExports';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                          */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Receipt Confirmations',    'ReceiptConfirmations',    null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Inv Adjustments',          'InvAdjustments',          null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Ship Confirmations',       'ShipConfirmations',       null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'WH Transfers',             'WhTransfers',             null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts , 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/* Setup Default sort order on all Listing Layouts */
update Layouts
set DefaultSortOrder = 'TransDateTime Desc'
where (ContextName = @ContextName) and (LayoutType = 'L' /* Listing */);

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'RecordType',                  null,   null,   null,               null, null
insert into @ttLF select 'TransType',                   null,   null,   null,               null, null
insert into @ttLF select 'TransTypeDescription',        null,   null,   null,               null, null
insert into @ttLF select 'TransEntity',                 null,   null,   null,               null, null
insert into @ttLF select 'TransEntityDescription',      null,   null,   null,               null, null
insert into @ttLF select 'ExportStatus',                null,      2,   null,               null, null
insert into @ttLF select 'ExportStatusDesc',            null,      1,   null,                105, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,     -2,   null,                105, null

insert into @ttLF select 'TransDate',                   null,     -1,   null,               null, null -- for Selections
insert into @ttLF select 'TransDateTime',               null,   null,   null,               null, null
insert into @ttLF select 'TransQty',                    null,   null,   null,               null, null
insert into @ttLF select 'AbsTransQty',                 null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'ProcessedDateTime',           null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'Description',                 null,     -1,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU_SortSeq',                 null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'NumPallets',                  null,     -1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumCartons',                  null,   null,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null

insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,   null,   null,               null, null

/* LPN Info */
insert into @ttLF select 'LPNType',                     null,     -1,   null,               null, null
insert into @ttLF select 'TrackingNo',                  null,     -1,   null,               null, null
insert into @ttLF select 'CartonDimensions',            null,     -1,   null,               null, null
insert into @ttLF select 'LPNLine',                     null,     -1,   null,               null, null
insert into @ttLF select 'InnerPacks',                  null,     -1,   null,               null, null
insert into @ttLF select 'Quantity',                    null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerPackage',             null,     -1,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,     -1,   null,               null, null
insert into @ttLF select 'ReceivedUnits',               null,     -1,   null,               null, null
/* Receiver Info */
insert into @ttLF select 'ReceiverBoL',                 null,     -1,   null,               null, null
/* Location Info */
insert into @ttLF select 'HostLocation',                null,   null,   null,               null, null
insert into @ttLF select 'LocationType',                null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,     -1,   null,               null, null
insert into @ttLF select 'PickingZone',                 null,     -1,   null,               null, null
insert into @ttLF select 'PutawayZone',                 null,     -1,   null,               null, null
/* Receipt Info */
insert into @ttLF select 'ReceiptType',                 null,     -1,   null,               null, null
insert into @ttLF select 'Vessel',                      null,     -1,   null,               null, null
insert into @ttLF select 'ContainerSize',               null,     -1,   null,               null, null
insert into @ttLF select 'BillNo',                      null,     -1,   null,               null, null
insert into @ttLF select 'SealNo',                      null,     -1,   null,               null, null
insert into @ttLF select 'InvoiceNo',                   null,     -1,   null,               null, null
insert into @ttLF select 'ContainerNo',                 null,     -1,   null,               null, null
insert into @ttLF select 'ETACountry',                  null,     -1,   null,               null, null
insert into @ttLF select 'ETACity',                     null,     -1,   null,               null, null
insert into @ttLF select 'ETAWarehouse',                null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptLine',                 null,     -1,   null,               null, null
insert into @ttLF select 'VendorId',                    null,     -1,   null,               null, null
insert into @ttLF select 'CoO',                         null,     -1,   null,               null, null
insert into @ttLF select 'UnitCost',                    null,     -1,   null,               null, null
insert into @ttLF select 'HostReceiptLine',             null,     -1,   null,               null, null

insert into @ttLF select 'ReasonCode',                  null,     -1,   null,               null, null

insert into @ttLF select 'OrderType',                   null,     -1,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,     -1,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,     -1,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,     -1,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,     -1,   null,               null, null
insert into @ttLF select 'CustPO',                      null,     -1,   null,               null, null
insert into @ttLF select 'Account',                     null,     -1,   null,               null, null
insert into @ttLF select 'AccountName',                 null,     -1,   null,               null, null
insert into @ttLF select 'TotalVolume',                 null,     -1,   null,               null, null
insert into @ttLF select 'TotalWeight',                 null,     -1,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,     -1,   null,               null, null
insert into @ttLF select 'TotalTax',                    null,     -1,   null,               null, null
insert into @ttLF select 'TotalShippingCost',           null,     -1,   null,               null, null
insert into @ttLF select 'TotalDiscount',               null,     -1,   null,               null, null
insert into @ttLF select 'FreightCharges',              null,     -1,   null,               null, null
insert into @ttLF select 'BillToAccount',               null,     -1,   null,               null, null
insert into @ttLF select 'BillToAddress',               null,     -1,   null,               null, null

insert into @ttLF select 'OrderLine',                   null,     -2,   null,               null, null
insert into @ttLF select 'UnitsOrdered',                null,     -1,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,     -1,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,     -1,   null,               null, null
insert into @ttLF select 'UnitsToAllocate',             null,     -1,   null,               null, null
insert into @ttLF select 'RetailUnitPrice',             null,     -1,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,     -1,   null,               null, null
insert into @ttLF select 'HostOrderLine',               null,     -1,   null,               null, null

insert into @ttLF select 'ASNCase',                     null,     -1,   null,               null, null
insert into @ttLF select 'UCCBarcode',                  null,     -1,   null,               null, null

insert into @ttLF select 'Reference',                   null,      1,   null,               null, null

insert into @ttLF select 'ShippedDate',                 null,     -1,   null,               null, null
insert into @ttLF select 'BoL',                         null,     -1,   null,               null, null
insert into @ttLF select 'LoadShipVia',                 null,     -1,   null,               null, null
insert into @ttLF select 'TrailerNumber',               null,     -1,   null,               null, null
insert into @ttLF select 'ProNumber',                   null,     -1,   null,               null, null
insert into @ttLF select 'SealNumber',                  null,     -1,   null,               null, null
insert into @ttLF select 'MasterBoL',                   null,     -1,   null,               null, null
insert into @ttLF select 'LoadType',                    null,    -11,   null,               null, null -- needs to be selectable as view does not have LoadTypeDesc

insert into @ttLF select 'FromWarehouse',               null,     -1,   null,               null, null
insert into @ttLF select 'ToWarehouse',                 null,     -1,   null,               null, null
insert into @ttLF select 'FromLPNId',                   null,   null,   null,               null, null
insert into @ttLF select 'FromLPN',                     null,   null,   null,               null, null
insert into @ttLF select 'FromLocation',                null,     -1,   null,               null, null
insert into @ttLF select 'ToLocation',                  null,     -1,   null,               null, null
insert into @ttLF select 'Lot',                         null,     -1,   null,               null, null
insert into @ttLF select 'MonetaryValue',               null,     -1,   null,               null, null

insert into @ttLF select 'Brand',                       null,     -1,   null,               null, null
insert into @ttLF select 'Length',                      null,     -1,   null,               null, null
insert into @ttLF select 'Width',                       null,     -1,   null,               null, null
insert into @ttLF select 'Height',                      null,     -1,   null,               null, null
insert into @ttLF select 'Weight',                      null,     -1,   null,               null, null
insert into @ttLF select 'Volume',                      null,     -1,   null,               null, null
insert into @ttLF select 'SerialNo',                    null,     -2,   null,               null, null

insert into @ttLF select 'ExportBatch',                 null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'ExpiryDate',                  null,     -1,   null,               null, null
insert into @ttLF select 'ReceiverDate',                null,     -1,   null,               null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPNDetailId',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailId',               null,   null,   null,               null, null
insert into @ttLF select 'PrevSKUId',                   null,   null,   null,               null, null
insert into @ttLF select 'PalletId',                    null,   null,   null,               null, null
insert into @ttLF select 'FromLocationId',              null,   null,   null,               null, null
insert into @ttLF select 'ToLocationId',                null,   null,   null,               null, null
insert into @ttLF select 'ShipmentId',                  null,   null,   null,               null, null
insert into @ttLF select 'LPNShipmentId',               null,   null,   null,               null, null
insert into @ttLF select 'LoadId',                      null,   null,   null,               null, null
insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'ReceiptDetailId',             null,   null,   null,               null, null

insert into @ttLF select 'SoldToName',                  null,     -1,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,     -1,   null,               null, null
insert into @ttLF select 'ShipViaDescription',          null,     -1,   null,               null, null
insert into @ttLF select 'FreightTerms',                null,     -1,   null,               null, null
insert into @ttLF select 'BillToName',                  null,     -1,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'EDIShipmentNumber',           null,   null,   null,               null, null
insert into @ttLF select 'EDITransCode',                null,   null,   null,               null, null
insert into @ttLF select 'EDIFunctionalCode',           null,   null,   null,               null, null

/* unused UDFs - move to above section as needed */
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

insert into @ttLF select 'LPN_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'LPN_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'LPND_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'LPND_UDF5',                   null,   null,   null,               null, null

insert into @ttLF select 'RH_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'RH_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'RHU_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'RHU_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'RHU_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'RHU_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'RHU_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'RD_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'RD_UDF5',                     null,   null,   null,               null, null

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

insert into @ttLF select 'OD_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF10',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF11',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF12',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF13',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF14',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF15',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF16',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF17',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF18',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF19',                    null,   null,   null,               null, null
insert into @ttLF select 'OD_UDF20',                    null,   null,   null,               null, null

insert into @ttLF select 'LD_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'LD_UDF10',                    null,   null,   null,               null, null

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
insert into @ttLF select 'UDF11',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF12',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF13',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF14',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF15',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF16',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF17',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF18',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF19',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF20',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF21',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF22',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF23',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF24',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF25',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF26',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF27',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF28',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF29',                       null,   null,   null,               null, null
insert into @ttLF select 'UDF30',                       null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/*----------------------------------------------------------------------------*/
/* Inv Adjustments */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
select @NewLayout = 'Inv Adjustments'

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,     -1,   null,               null, null
insert into @ttLF select 'RecordType',                  null,     -1,   null,               null, null
insert into @ttLF select 'TransType',                   null,   null,   null,               null, null
insert into @ttLF select 'TransTypeDescription',        null,   null,   null,               null, null
insert into @ttLF select 'TransEntity',                 null,   null,   null,               null, null
insert into @ttLF select 'TransEntityDescription',      null,   null,   null,               null, null
insert into @ttLF select 'ExportStatus',                null,      2,   null,               null, null
insert into @ttLF select 'ExportStatusDesc',            null,      1,   null,                105, null

insert into @ttLF select 'TransDate',                   null,     -1,   null,               null, null -- for Selections
insert into @ttLF select 'TransDateTime',               null,   null,   null,               null, null
insert into @ttLF select 'ProcessedDateTime',           null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'TransQty',                    null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'Description',                 null,     -1,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null

insert into @ttLF select 'ReceiverNumber',              null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,     -1,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,     -1,   null,               null, null

insert into @ttLF select 'ExportBatch',                 null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, @NewLayout, @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/*----------------------------------------------------------------------------*/
/* Receipts Confirmations */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
select @NewLayout = 'Receipt Confirmations'

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,     -1,   null,               null, null
insert into @ttLF select 'RecordType',                  null,     -1,   null,               null, null
insert into @ttLF select 'TransType',                   null,   null,   null,               null, null
insert into @ttLF select 'TransTypeDescription',        null,   null,   null,               null, null
insert into @ttLF select 'TransEntity',                 null,   null,   null,               null, null
insert into @ttLF select 'TransEntityDescription',      null,   null,   null,               null, null
insert into @ttLF select 'ExportStatus',                null,      2,   null,               null, null
insert into @ttLF select 'ExportStatusDesc',            null,      1,   null,                105, null

insert into @ttLF select 'TransDate',                   null,     -1,   null,               null, null -- for Selections
insert into @ttLF select 'TransDateTime',               null,   null,   null,               null, null
insert into @ttLF select 'ProcessedDateTime',           null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'TransQty',                    null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'Description',                 null,     -1,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null

insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,     -1,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,     -1,   null,               null, null

insert into @ttLF select 'ExportBatch',                 null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, @NewLayout, @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/*----------------------------------------------------------------------------*/
/* Ship Confirmations */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
select @NewLayout = 'Ship Confirmations'

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,     -1,   null,               null, null
insert into @ttLF select 'RecordType',                  null,     -1,   null,               null, null
insert into @ttLF select 'TransType',                   null,   null,   null,               null, null
insert into @ttLF select 'TransTypeDescription',        null,   null,   null,               null, null
insert into @ttLF select 'TransEntity',                 null,   null,   null,               null, null
insert into @ttLF select 'TransEntityDescription',      null,   null,   null,               null, null
insert into @ttLF select 'ExportStatus',                null,      2,   null,               null, null
insert into @ttLF select 'ExportStatusDesc',            null,      1,   null,                105, null

insert into @ttLF select 'TransDate',                   null,     -1,   null,               null, null -- for Selections
insert into @ttLF select 'TransDateTime',               null,   null,   null,               null, null
insert into @ttLF select 'ProcessedDateTime',           null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'TransQty',                    null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'Description',                 null,     -1,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'ReceiverNumber',              null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null

insert into @ttLF select 'PickTicket',                  null,      1,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,      1,   null,               null, null
insert into @ttLF select 'LoadNumber',                  null,      1,   null,               null, null

insert into @ttLF select 'ExportBatch',                 null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, @NewLayout, @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/*----------------------------------------------------------------------------*/
/* Ship Confirmations */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
select @NewLayout = 'WH Transfers'

/* Copy fields from Standards Layout */
exec pr_LayoutFields_Copy @ContextName, 'Standard', @ContextName, @NewLayout;

/* Hide the fields not applicable to this layout */
exec pr_LayoutFields_ChangeVisibility @ContextName, @NewLayout, 'PickTicket,LoadNumber,ReceiptNumber,ReceiverNumber,Reference';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By SKU';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'SKU',               null,      1,   null,          null, null,    null
insert into @ttLFE select 'TransType',         null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPN',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'Location',          null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',        null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'TransQty',          null,      1,   null,          null, null,    'Sum'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By Date & TransType';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'TransDate',         null,      1,   null,          null, null,    null
insert into @ttLFE select 'TransType',         null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPN',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'Location',          null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',        null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'TransQty',          null,      1,   null,          null, null,    'Sum'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By Receipt';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'ReceiptNumber',     null,      1,   null,          null, null,    null
insert into @ttLFE select 'StatusDescription', null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPN',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'Location',          null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',        null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'TransQty',          null,      1,   null,          null, null,    'Sum'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'By SKU, WH & Inv Class';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'SKU',               null,      1,   null,          null, null,    null
insert into @ttLFE select 'Warehouse',         null,      1,   null,          null, null,    null
insert into @ttLFE select 'InventoryClass1',   null,      1,   null,          null, null,    null
insert into @ttLFE select 'TransType',         null,      1,   null,          null, null,    null
insert into @ttLFE select 'LPN',               null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'Location',          null,      1,   null,          null, null,    'DCount'
insert into @ttLFE select 'InnerPacks',        null,   null,   null,          null, null,    'Sum'
insert into @ttLFE select 'TransQty',          null,      1,   null,          null, null,    'Sum'

/* Add the fields for this Layout */
exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'TransQty',                   'Sum',       '{0:n0}',                     null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
