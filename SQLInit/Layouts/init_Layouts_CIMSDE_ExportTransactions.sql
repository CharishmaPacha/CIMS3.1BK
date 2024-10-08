/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/04/24  MS      Changes to Visibilities (HA-292)
  2020/02/17  AJM     Added missing fields, Changed the ContextName (JL-49)
  2019/04/22  PHK     Initial revision.
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

select @ContextName = 'List.CIMSDE_ExportTransactions',
       @DataSetName = 'vwCIMSDE_ExportTransactions';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   1,      null
insert into @Layouts select 'L',    'N',     'Receipt Confirmations',         null,                 null,  null,   2,      null
insert into @Layouts select 'L',    'N',     'Ship Confirmations',            null,                 null,  null,   3,      null
insert into @Layouts select 'L',    'N',     'Inventory Changes',             null,                 null,  null,   4,      null

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
insert into @ttLF select 'RecordType',                  null,   null,   null,               null, null
insert into @ttLF select 'ExportBatch',                 null,      1,   null,               null, null
insert into @ttLF select 'TransDateTime',               null,   null,   null,               null, null
insert into @ttLF select 'TransQty',                    null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'HostLocation',                null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null
insert into @ttLF select 'ReceiverDate',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverBoL',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef1',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef2',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef3',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef4',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef5',                null,   null,   null,               null, null

/* SKU info */
insert into @ttLF select 'Description',                 null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'Brand',                       null,   null,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,     -1,   null,               null, null
insert into @ttLF select 'Innerpacks',                  null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerPackage',             null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,     -1,   null,               null, null
/* LPN Info */
insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'ASNCase',                     null,   null,   null,               null, null
insert into @ttLF select 'UCCBarcode',                  null,   null,   null,               null, null
insert into @ttLF select 'TrackingNo',                  null,   null,   null,               null, null
insert into @ttLF select 'CartonDimensions',            null,   null,   null,               null, null
insert into @ttLF select 'LPNLine',                     null,     -2,   null,               null, null

insert into @ttLF select 'Reference',                   null,   null,   null,               null, null
insert into @ttLF select 'MonetaryValue',               null,   null,   null,               null, null
insert into @ttLF select 'ReasonCode',                  null,   null,   null,               null, null
insert into @ttLF select 'ExpiryDate',                  null,   null,   null,               null, null
insert into @ttLF select 'LotNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'SerialNo',                    null,   null,   null,               null, null
insert into @ttLF select 'Weight',                      null,     -1,   null,               null, null
insert into @ttLF select 'Volume',                      null,     -1,   null,               null, null
insert into @ttLF select 'Length',                      null,     -1,   null,               null, null
insert into @ttLF select 'Width',                       null,     -1,   null,               null, null
insert into @ttLF select 'Height',                      null,     -1,   null,               null, null

/* RO Info */
insert into @ttLF select 'ReceiptContainerSize',        null,   null,   null,               null, null
insert into @ttLF select 'ReceiptBillNo',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptSealNo',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptInvoiceNo',            null,   null,   null,               null, null
insert into @ttLF select 'ReceiptContainerNo',          null,   null,   null,               null, null

insert into @ttLF select 'ReceiptType',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceiptLine',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceiptVessel',               null,   null,   null,               null, null
insert into @ttLF select 'VendorId',                    null,   null,   null,               null, null
insert into @ttLF select 'CoO',                         null,   null,   null,               null, null
insert into @ttLF select 'UnitCost',                    null,   null,   null,               null, null
insert into @ttLF select 'HostReceiptLine',             null,   null,   null,               null, null
/* OH Info */
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToName',                  null,   null,   null,               null, null

insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToAddressLine1',          null,   null,   null,               null, null
insert into @ttLF select 'ShipToAddressLine2',          null,   null,   null,               null, null
insert into @ttLF select 'ShipToCity',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToState',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToCountry',               null,   null,   null,               null, null
insert into @ttLF select 'ShipToZip',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipToPhoneNo',               null,   null,   null,               null, null
insert into @ttLF select 'ShipToEmail',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToReference1',            null,   null,   null,               null, null
insert into @ttLF select 'ShipToReference2',            null,   null,   null,               null, null

insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipViaSCAC',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipViaDescription',          null,   null,   null,               null, null
insert into @ttLF select 'FreightTerms',                null,   null,   null,               null, null

insert into @ttLF select 'BillToAccount',               null,   null,   null,               null, null
insert into @ttLF select 'BillToAddress',               null,   null,   null,               null, null
insert into @ttLF select 'BillToName',                  null,   null,   null,               null, null
insert into @ttLF select 'FreightCharges',              null,   null,   null,               null, null

insert into @ttLF select 'HostOrderLine',               null,   null,   null,               null, null
insert into @ttLF select 'OrderLine',                   null,     -2,   null,               null, null
insert into @ttLF select 'UnitsOrdered',                null,   null,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,   null,   null,               null, null
/* Shipping info */
insert into @ttLF select 'LoadNumber',                  null,   null,   null,               null, null
insert into @ttLF select 'MasterBoL',                   null,   null,   null,               null, null
insert into @ttLF select 'BoL',                         null,   null,   null,               null, null
insert into @ttLF select 'ShippedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'LoadShipVia',                 null,   null,   null,               null, null
insert into @ttLF select 'TrailerNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ProNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'SealNumber',                  null,   null,   null,               null, null
/* Transfers related */
insert into @ttLF select 'FromWarehouse',               null,   null,   null,               null, null
insert into @ttLF select 'ToWarehouse',                 null,   null,   null,               null, null
insert into @ttLF select 'FromLocation',                null,   null,   null,               null, null
insert into @ttLF select 'ToLocation',                  null,   null,   null,               null, null
insert into @ttLF select 'FromSKU',                     null,   null,   null,               null, null
insert into @ttLF select 'ToSKU',                       null,   null,   null,               null, null
/* EDI */
insert into @ttLF select 'EDIShipmentNumber',           null,   null,   null,               null, null
insert into @ttLF select 'EDITransCode',                null,   null,   null,               null, null
insert into @ttLF select 'EDIFunctionalCode',           null,   null,   null,               null, null

insert into @ttLF select 'TransDate',                   null,     -2,   null,               null, null

insert into @ttLF select 'ShipmentId',                  null,   null,   null,               null, null
insert into @ttLF select 'LoadId',                      null,   null,   null,               null, null

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

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,   null,      1,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null
insert into @ttLF select 'CIMSRecId',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;';

/*----------------------------------------------------------------------------*/
/* Layout Fields for Receipt Confirmations */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordType',                  null,   null,   null,               null, null
insert into @ttLF select 'ExportBatch',                 null,      1,   null,               null, null
insert into @ttLF select 'TransDateTime',               null,   null,   null,               null, null
insert into @ttLF select 'TransQty',                    null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'HostLocation',                null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

insert into @ttLF select 'ReceiverDate',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverBoL',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef1',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef2',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef3',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef4',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef5',                null,   null,   null,               null, null

/* SKU info */
insert into @ttLF select 'Description',                 null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'Brand',                       null,   null,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,     -1,   null,               null, null
insert into @ttLF select 'Innerpacks',                  null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerPackage',             null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,     -1,   null,               null, null
/* LPN Info */
insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'ASNCase',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNLine',                     null,     -2,   null,               null, null

insert into @ttLF select 'MonetaryValue',               null,   null,   null,               null, null
insert into @ttLF select 'ReasonCode',                  null,   null,   null,               null, null
insert into @ttLF select 'ExpiryDate',                  null,   null,   null,               null, null
insert into @ttLF select 'LotNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'SerialNo',                    null,   null,   null,               null, null
insert into @ttLF select 'Weight',                      null,     -1,   null,               null, null
insert into @ttLF select 'Volume',                      null,     -1,   null,               null, null
insert into @ttLF select 'Length',                      null,     -1,   null,               null, null
insert into @ttLF select 'Width',                       null,     -1,   null,               null, null
insert into @ttLF select 'Height',                      null,     -1,   null,               null, null

insert into @ttLF select 'ReceiptContainerSize',        null,   null,   null,               null, null
insert into @ttLF select 'ReceiptBillNo',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptSealNo',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiptInvoiceNo',            null,   null,   null,               null, null
insert into @ttLF select 'ReceiptContainerNo',          null,   null,   null,               null, null
/* RO Info */
insert into @ttLF select 'ReceiptType',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceiptLine',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceiptVessel',               null,   null,   null,               null, null
insert into @ttLF select 'VendorId',                    null,   null,   null,               null, null
insert into @ttLF select 'CoO',                         null,   null,   null,               null, null
insert into @ttLF select 'UnitCost',                    null,   null,   null,               null, null
insert into @ttLF select 'HostReceiptLine',             null,   null,   null,               null, null

/* OH Info */
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null

insert into @ttLF select 'Reference',                   null,   null,   null,               null, null

insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null
insert into @ttLF select 'CIMSRecId',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Receipt Confirmations', @ttLF, @DataSetName, 'RecordId;';

/*----------------------------------------------------------------------------*/
/* Layout Fields for Ship Confirmations */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordType',                  null,   null,   null,               null, null
insert into @ttLF select 'ExportBatch',                 null,      1,   null,               null, null
insert into @ttLF select 'TransDateTime',               null,   null,   null,               null, null
insert into @ttLF select 'TransQty',                    null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null

insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'HostLocation',                null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null

/* SKU info */
insert into @ttLF select 'Description',                 null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'Brand',                       null,   null,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,     -1,   null,               null, null
insert into @ttLF select 'Innerpacks',                  null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerPackage',             null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,     -1,   null,               null, null
/* LPN Info */
insert into @ttLF select 'LPNType',                     null,   null,   null,               null, null
insert into @ttLF select 'ASNCase',                     null,   null,   null,               null, null
insert into @ttLF select 'UCCBarcode',                  null,   null,   null,               null, null
insert into @ttLF select 'TrackingNo',                  null,   null,   null,               null, null
insert into @ttLF select 'CartonDimensions',            null,   null,   null,               null, null
insert into @ttLF select 'LPNLine',                     null,     -2,   null,               null, null

insert into @ttLF select 'MonetaryValue',               null,   null,   null,               null, null
insert into @ttLF select 'ReasonCode',                  null,   null,   null,               null, null
insert into @ttLF select 'ExpiryDate',                  null,   null,   null,               null, null
insert into @ttLF select 'LotNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'SerialNo',                    null,   null,   null,               null, null
insert into @ttLF select 'Weight',                      null,     -1,   null,               null, null
insert into @ttLF select 'Volume',                      null,     -1,   null,               null, null
insert into @ttLF select 'Length',                      null,     -1,   null,               null, null
insert into @ttLF select 'Width',                       null,     -1,   null,               null, null
insert into @ttLF select 'Height',                      null,     -1,   null,               null, null

/* OH Info */
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToName',                  null,   null,   null,               null, null

insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToAddressLine1',          null,   null,   null,               null, null
insert into @ttLF select 'ShipToAddressLine2',          null,   null,   null,               null, null
insert into @ttLF select 'ShipToCity',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToState',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToCountry',               null,   null,   null,               null, null
insert into @ttLF select 'ShipToZip',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipToPhoneNo',               null,   null,   null,               null, null
insert into @ttLF select 'ShipToEmail',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToReference1',            null,   null,   null,               null, null
insert into @ttLF select 'ShipToReference2',            null,   null,   null,               null, null

insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'ShipViaSCAC',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipViaDescription',          null,   null,   null,               null, null
insert into @ttLF select 'FreightTerms',                null,   null,   null,               null, null

insert into @ttLF select 'BillToAccount',               null,   null,   null,               null, null
insert into @ttLF select 'BillToAddress',               null,   null,   null,               null, null
insert into @ttLF select 'BillToName',                  null,   null,   null,               null, null
insert into @ttLF select 'FreightCharges',              null,   null,   null,               null, null

insert into @ttLF select 'HostOrderLine',               null,   null,   null,               null, null
insert into @ttLF select 'OrderLine',                   null,     -2,   null,               null, null
insert into @ttLF select 'UnitsOrdered',                null,   null,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,   null,   null,               null, null
/* Shipping info */
insert into @ttLF select 'LoadNumber',                  null,   null,   null,               null, null
insert into @ttLF select 'MasterBoL',                   null,   null,   null,               null, null
insert into @ttLF select 'BoL',                         null,   null,   null,               null, null
insert into @ttLF select 'ShippedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'LoadShipVia',                 null,   null,   null,               null, null
insert into @ttLF select 'TrailerNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ProNumber',                   null,   null,   null,               null, null
insert into @ttLF select 'SealNumber',                  null,   null,   null,               null, null

insert into @ttLF select 'Reference',                   null,   null,   null,               null, null

insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,      1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,      1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,      1,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null
insert into @ttLF select 'CIMSRecId',                   null,   null,   null,               null, null
                                                   
/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Ship Confirmations', @ttLF, @DataSetName, 'RecordId;';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go