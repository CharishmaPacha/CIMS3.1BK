/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person   Comments

  2022/03/10  PHK     Added layout for SKUS (HA-109)
  2021/03/08  RKC     corrected the data set name for LRI_TAR (HA-1926)
  2021/01/20  TK      Corrected field name for LRI, TAR, WA (HA-1962)
  2021/01/27  RKC     Added layout for INV - Inventory (CIMSV3-1323)
  202101/25   RKC     Changed the DataSetName for LRI, LRI_WM, LRI_TAR (HA-1951)
  2021/01/22  RKC     Added layout for LoadRoutingInfo - Target (HA-1946)
  2021/01/20  RKC     Added layout for LoadRoutingInfo, WalmartRoutingInfo imports (HA-1926)
  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/11/14  SV      Added layout for Location imports (CIMSV3-1120)
  2020/10/08  MRK     Added missing fields (HA-1430)
  2020/09/03  NB      Initial revision (HA-320)
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
/* SKU Price List Layouts */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'ImportFiles.SPL',
       @DataSetName = 'SKUPriceList';

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
insert into @ttLF select 'RecordId',                     null,   null,   null,              null, null
insert into @ttLF select 'SKU',                          null,      1,   null,              null, null
insert into @ttLF select 'SoldToId',                     null,      1,   null,              null, null
insert into @ttLF select 'CustSKU',                      null,      1,   null,              null, null
insert into @ttLF select 'RetailUnitPrice',              null,      1,   null,              null, null
insert into @ttLF select 'UnitSalePrice',                null,      1,   null,              null, null
insert into @ttLF select 'RecordAction',                 null,      1,   null,              null, null
insert into @ttLF select 'Validated',                    null,   null,   null,              null, null
insert into @ttLF select 'ValidationMsg',                null,   null,   null,              null, null
insert into @ttLF select 'KeyData',                      null,   null,   null,              null, null
insert into @ttLF select 'BusinessUnit',                 null,   null,   null,              null, null
insert into @ttLF select 'CreatedBy',                    null,   null,   null,              null, null

insert into @ttLF select 'SKUId',                        null,   null,   null,              null, null
insert into @ttLF select 'Price1',                       null,   null,   null,              null, null
insert into @ttLF select 'Price2',                       null,   null,   null,              null, null
insert into @ttLF select 'Price3',                       null,   null,   null,              null, null
insert into @ttLF select 'Status',                       null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU',                   null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU1',                  null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU2',                  null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU3',                  null,   null,   null,              null, null
insert into @ttLF select 'UniqueId',                     null,   null,   null,              null, null
insert into @ttLF select 'CreatedDate',                  null,   null,   null,              null, null
insert into @ttLF select 'ModifiedBy',                   null,   null,   null,              null, null
insert into @ttLF select 'ModifiedDate',                 null,   null,   null,              null, null


/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Location Layouts */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'ImportFiles.LOC',
       @DataSetName = 'Locations';

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Locations' standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                   Visible Visible Field          Width Display
                          Name                    Index           Caption              Format */
insert into @ttLF select 'LocationId',            null,   null,   null,          null, null
insert into @ttLF select 'Location',              null,      1,   null,          null, null

insert into @ttLF select 'LocationType',          null,      1,   null,          null, null
insert into @ttLF select 'LocationSubType',       null,      1,   null,          null, null
insert into @ttLF select 'StorageType',           null,      1,   null,          null, null

insert into @ttLF select 'LocationRow',           null,      1,   null,          null, null
insert into @ttLF select 'LocationBay',           null,      1,   null,          null, null
insert into @ttLF select 'LocationLevel',         null,      1,   null,          null, null
insert into @ttLF select 'LocationSection',       null,      1,   null,          null, null

insert into @ttLF select 'LocationClass',         null,      1,   null,          null, null
insert into @ttLF select 'MinReplenishLevel',     null,      1,   null,          null, null
insert into @ttLF select 'MaxReplenishLevel',     null,      1,   null,          null, null
insert into @ttLF select 'ReplenishUoM',          null,      1,   null,          null, null

insert into @ttLF select 'AllowMultipleSKUs',     null,      1,   null,          null, null
insert into @ttLF select 'Barcode',               null,      1,   null,          null, null

insert into @ttLF select 'PutawayPath',           null,      1,   null,          null, null
insert into @ttLF select 'PickPath',              null,      1,   null,          null, null
insert into @ttLF select 'PickingZone',           null,      1,   null,          null, null
insert into @ttLF select 'PutawayZone',           null,      1,   null,          null, null
insert into @ttLF select 'Warehouse',             null,      1,   null,          null, null

insert into @ttLF select 'Validated',             null,      1,   null,          null, null
insert into @ttLF select 'ValidationMsg',         null,      1,   null,          null, null
insert into @ttLF select 'KeyData',               null,     -1,   null,          null, null

insert into @ttLF select 'LOC_UDF1',              null,   null,   null,          null, null
insert into @ttLF select 'LOC_UDF2',              null,   null,   null,          null, null
insert into @ttLF select 'LOC_UDF3',              null,   null,   null,          null, null
insert into @ttLF select 'LOC_UDF4',              null,   null,   null,          null, null
insert into @ttLF select 'LOC_UDF5',              null,   null,   null,          null, null

insert into @ttLF select 'Ownership',             null,   null,   null,          null, null
insert into @ttLF select 'CreatedBy',             null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'LocationId;Location' /* Key fields */;

/******************************************************************************/
/* LoadRoutingInfo Layouts */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'ImportFiles.LRI',
       @DataSetName = 'vwImportFileLRI';

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Locations' standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'CustomerNo',                  null,      1,   null,               null, null
insert into @ttLF select 'CustomerName',                null,      1,   null,               null, null
insert into @ttLF select 'LotRef',                      null,      1,   null,               null, null
insert into @ttLF select 'CustPO',                      null,      1,   null,               null, null
insert into @ttLF select 'PickTicketFrom',              null,      1,   'PT Range From',    null, null
insert into @ttLF select 'PickTicketTo',                null,      1,   'PT Range To',      null, null
insert into @ttLF select 'ShipTo',                      null,      1,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,      1,   null,               null, null
insert into @ttLF select 'LoadGroup',                   null,      1,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,      1,   null,               null, null
insert into @ttLF select 'Consolidator',                null,      1,   null,               null, null
insert into @ttLF select 'PickUpDate',                  null,      1,   null,               null, null
insert into @ttLF select 'PickUpTime',                  null,      1,   null,               null, null
insert into @ttLF select 'Boxes',                       null,      1,   null,               null, null
insert into @ttLF select 'Weight',                      null,      1,   null,               null, null
insert into @ttLF select 'Cube',                        null,      1,   null,               null, null
insert into @ttLF select 'Comments',                    null,      1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Walmart Routing info Layouts */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'ImportFiles.LRI_WM',
       @DataSetName = 'vwImportFileLRI_WM';

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for LRI_WM standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field                    Width Display
                          Name                          Index           Caption                        Format */
insert into @ttLF select 'CustPO',                      null,      1,   'PO Number',             null, null
insert into @ttLF select 'ClientLoad',                  null,      1,   'Load Number',           null, null
insert into @ttLF select 'LoadDest',                    null,      1,   'Load Dest',             null, null
insert into @ttLF select 'LoadDestType',                null,      1,   'Load Dest Type',        null, null
insert into @ttLF select 'LoadDestAddress',             null,      1,   'Load Dest Address',     null, null
insert into @ttLF select 'LoadP_UWindowStart',          null,      1,   'Load P/U Window Start', null, null
insert into @ttLF select 'LoadP_UWindowEnd',            null,      1,   'Load P/U Window end',   null, null
insert into @ttLF select 'MABD',                        null,      1,   null,                    null, null
insert into @ttLF select 'CarrierPUDate',               null,      1,   null,                    null, null
insert into @ttLF select 'CarrierDueDate',              null,      1,   null,                    null, null
insert into @ttLF select 'CarrierName',                 null,      1,   null,                    null, null
insert into @ttLF select 'Mode',                        null,      1,   null,                    null, null
insert into @ttLF select 'ShipPoint',                   null,      1,   null,                    null, null
insert into @ttLF select 'Cases',                       null,      1,   null,                    null, null
insert into @ttLF select 'Weight',                      null,      1,   null,                    null, null
insert into @ttLF select 'Cube',                        null,      1,   null,                    null, null
insert into @ttLF select 'Pallets',                     null,      1,   null,                    null, null
insert into @ttLF select 'EventCode',                   null,      1,   null,                    null, null
insert into @ttLF select 'POType',                      null,      1,   null,                    null, null
insert into @ttLF select 'Department',                  null,      1,   null,                    null, null
insert into @ttLF select 'ConfirmedDate',               null,      1,   null,                    null, null
insert into @ttLF select 'Held_Suspended',              null,      1,   null,                    null, null
insert into @ttLF select 'PODest',                      null,      1,   null,                    null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Target RoutingInfo Layouts */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'ImportFiles.LRI_TAR',
       @DataSetName = 'vwImportFileLRI_TAR';

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Locations' standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                   Visible Visible Field                      Width Display
                          Name                    Index           Caption                    Format */
insert into @ttLF select  'CustPO',                null,      1,  null,                      null, null
insert into @ttLF select  'ClientLoad',            null,      1,  'Load Number',            null, null
insert into @ttLF select  'ShipToStore',           null,      1,  null,                      null, null
insert into @ttLF select  'Cartons',               null,      1,  null,                     null, null
insert into @ttLF select  'PlannedPickUpDate',     null,      1,  'Planned Pick Up Date',   null, null
insert into @ttLF select  'CarrierSCAC',           null,      1,  'Carrier SCAC',           null, null

insert into @ttLF select  'ShipmentStatus',        null,      1,  'Shipment Status',         null, null
insert into @ttLF select  'Dept',                  null,      1,  null,                      null, null
insert into @ttLF select  'ShipPointName',         null,      1,  'Ship Point Name',         null, null
insert into @ttLF select  'VendorNo',              null,      1,  'Vendor No',               null, null
insert into @ttLF select  'AddressLine1',          null,     -1,  'Address Line1',           null, null
insert into @ttLF select  'AddressLine2',          null,     -1,  'Address Line2',          null, null
insert into @ttLF select  'City',                  null,     -1,  null,                     null, null
insert into @ttLF select  'State',                 null,     -1,  null,                     null, null
insert into @ttLF select  'PostalCode',            null,     -1,  'Postal Code',            null, null
insert into @ttLF select  'ContactName',           null,     -1,  'Contact Name',           null, null
insert into @ttLF select  'ContactNumber',         null,     -1,  'Contact Number',         null, null
insert into @ttLF select  'Weight',                null,      1,  null,                     null, null
insert into @ttLF select  'Cube',                  null,      1,  null,                     null, null
insert into @ttLF select  'PalletSpaces',          null,      1,  'Pallet Spaces',          null, null
insert into @ttLF select  'PalletsStackable',      null,      1,  'Pallets Stackable',      null, null
insert into @ttLF select  'AvailablePickup',       null,      1,  'Available Pickup',       null, null
insert into @ttLF select  'Latestpickup',          null,      1,  'Latest pickup',          null, null
insert into @ttLF select  'Notes',                 null,      1,  null,                     null, null
insert into @ttLF select  'Equipment',             null,      1,  null,                     null, null
insert into @ttLF select  'Commodity',             null,      1,  null,                     null, null
insert into @ttLF select  'ShipTogetherId',        null,      1,  'Ship To gether Id',      null, null
insert into @ttLF select  'BOL',                   null,      1,  null,                     null, null
insert into @ttLF select  'Appt',                  null,      1,  null,                     null, null
insert into @ttLF select  'Itemlevel',             null,      1,  'Item level',             null, null
insert into @ttLF select  'ItemLevelEntry',        null,      1,  'Item Level Entry',       null, null
insert into @ttLF select  'OrderType',             null,      1,  'Order Type',             null, null
insert into @ttLF select  'BKHL_DC',               null,      1,  'BKHL DC',                null, null
insert into @ttLF select  'VRSEntryMadeDate',      null,      1,  'VRS Entry Made Date',    null, null
insert into @ttLF select  'VRSLastUpdatedDate',    null,      1,  'VRS Last Updated Date',  null, null
insert into @ttLF select  'VRSEnteredUser',        null,      1,  'VRS Entered User',       null, null
insert into @ttLF select  'VRSUpdatedLastUser',    null,      1,  'VRS Updated Last User',  null, null
insert into @ttLF select  'UpdateCuttOffTime',     null,      1,  'Update CuttOff Time',    null, null
insert into @ttLF select  'PlanId',                null,      1,  'Plan Id',                null, null
insert into @ttLF select  'DC_ShipTO',             null,      1,  'DC/Ship TO',             null, null
insert into @ttLF select  'StopNumberOf',          null,      1,  'Stop #Of',               null, null
insert into @ttLF select  'PRONumber',             null,      1,  'PRO#',                   null, null
insert into @ttLF select  'CONS_SCAC',             null,      1,  'CONS SCAC',              null, null
insert into @ttLF select  'CONS_Auth',             null,      1,  'CONS Auth',              null, null
insert into @ttLF select  'StatusDate',            null,      1,  'Status Date',            null, null
insert into @ttLF select  'PreassignedCarrier',    null,      1,  'Preassigned Carrier',    null, null
insert into @ttLF select  'FreightTerms',          null,      1,  'Freight Terms',          null, null
insert into @ttLF select  'EarlyDelivery',         null,      1,  'Early Delivery',         null, null
insert into @ttLF select  'LateDelivery',          null,      1,  'Late Delivery',          null, null
insert into @ttLF select  'TripID',                null,      1,  'Trip ID',                null, null
insert into @ttLF select  'ShipmentID',            null,      1,  'Shipment ID',            null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Inventory create Layouts */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'ImportFiles.INV',
       @DataSetName = 'vwImportFileInventory';

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Inventory create standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   'Style',            null, null
insert into @ttLF select 'SKU2',                        null,   null,   'Color',            null, null
insert into @ttLF select 'SKU3',                        null,   null,   'Size',             null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   'Label Code',       null, null
insert into @ttLF select 'UnitsPerLPN',                 null,      1,   null,               null, null
insert into @ttLF select 'NumLPNsToCreate',             null,      1,   'Num LPNs',         null, null
insert into @ttLF select 'Reference',                   null,      1,   null,               null, null
insert into @ttLF select 'ReasonCode',                  null,      1,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,      1,   null,               null, null
insert into @ttLF select 'Location',                    null,      1,   null,               null, null
insert into @ttLF select 'Validated',                   null,      1,   null,               null, null
insert into @ttLF select 'ValidationMsg',               null,      1,   null,               null, null
insert into @ttLF select 'KeyData',                     null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'SKUId' /* Key fields */;

/******************************************************************************/
/* SKUs Layouts */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'ImportFiles.SKU',
       @DataSetName = 'SKUs';

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for SKUs standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                   Visible Visible Field          Width Display
                          Name                    Index           Caption              Format */
insert into @ttLF select  'SKU',                  null,      1,   null,          null, null
insert into @ttLF select  'SKU1',                 null,   null,   null,          null, null
insert into @ttLF select  'SKU2',                 null,   null,   null,          null, null
insert into @ttLF select  'SKU3',                 null,   null,   null,          null, null
insert into @ttLF select  'SKU4',                 null,   null,   null,          null, null
insert into @ttLF select  'SKU5',                 null,   null,   null,          null, null
insert into @ttLF select  'Description',          null,   null,   null,          null, null
insert into @ttLF select  'SKU1Description',      null,   null,   null,          null, null
insert into @ttLF select  'SKU2Description',      null,   null,   null,          null, null
insert into @ttLF select  'SKU3Description',      null,   null,   null,          null, null
insert into @ttLF select  'SKU4Description',      null,   null,   null,          null, null
insert into @ttLF select  'SKU5Description',      null,   null,   null,          null, null
insert into @ttLF select  'AlternateSKU',         null,   null,   null,          null, null
insert into @ttLF select  'Barcode',              null,   null,   null,          null, null
insert into @ttLF select  'Status',               null,      1,   null,          null, null
insert into @ttLF select  'UoM',                  null,      1,   null,          null, null
insert into @ttLF select  'InnerPacksPerLPN',     null,   null,   null,          null, null
insert into @ttLF select  'UnitsPerInnerPack',    null,   null,   null,          null, null
insert into @ttLF select  'UnitsPerLPN',          null,   null,   null,          null, null
insert into @ttLF select  'InnerPackWeight',      null,   null,   null,          null, null
insert into @ttLF select  'InnerPackLength',      null,   null,   null,          null, null
insert into @ttLF select  'InnerPackWidth',       null,   null,   null,          null, null
insert into @ttLF select  'InnerPackHeight',      null,   null,   null,          null, null
insert into @ttLF select  'InnerPackVolume',      null,   null,   null,          null, null
insert into @ttLF select  'UnitWeight',           null,   null,   null,          null, null
insert into @ttLF select  'UnitLength',           null,   null,   null,          null, null
insert into @ttLF select  'UnitWidth',            null,   null,   null,          null, null
insert into @ttLF select  'UnitHeight',           null,   null,   null,          null, null
insert into @ttLF select  'UnitVolume',           null,   null,   null,          null, null
insert into @ttLF select  'NestingFactor',        null,   null,   null,          null, null
insert into @ttLF select  'PalletTie',            null,   null,   null,          null, null
insert into @ttLF select  'PalletHigh',           null,   null,   null,          null, null
insert into @ttLF select  'UnitPrice',            null,   null,   null,          null, null
insert into @ttLF select  'UnitCost',             null,   null,   null,          null, null
insert into @ttLF select  'PickUoM',              null,   null,   null,          null, null
insert into @ttLF select  'ShipUoM',              null,   null,   null,          null, null
insert into @ttLF select  'ShipPack',             null,   null,   null,          null, null
insert into @ttLF select  'UPC',                  null,      1,   null,          null, null
insert into @ttLF select  'CaseUPC',              null,   null,   null,          null, null
insert into @ttLF select  'Brand',                null,   null,   null,          null, null
insert into @ttLF select  'SKUImageURL',          null,   null,   null,          null, null
insert into @ttLF select  'ProdCategory',         null,      1,   null,          null, null
insert into @ttLF select  'ProdSubCategory',      null,      1,   null,          null, null
insert into @ttLF select  'PutawayClass',         null,   null,   null,          null, null
insert into @ttLF select  'ABCClass',             null,   null,   null,          null, null
insert into @ttLF select  'NMFC',                 null,   null,   null,          null, null
insert into @ttLF select  'HarmonizedCode',       null,   null,   null,          null, null
insert into @ttLF select  'HTSCode',              null,   null,   null,          null, null
insert into @ttLF select  'Serialized',           null,   null,   null,          null, null
insert into @ttLF select  'ReturnDisposition',    null,   null,   null,          null, null
insert into @ttLF select  'IsSortable',           null,   null,   null,          null, null
insert into @ttLF select  'IsConveyable',         null,   null,   null,          null, null
insert into @ttLF select  'IsScannable',          null,   null,   null,          null, null
insert into @ttLF select  'IsBaggable',           null,   null,   null,          null, null
insert into @ttLF select  'SKUSortOrder',         null,   null,   null,          null, null
insert into @ttLF select  'Ownership',            null,   null,   null,          null, null
insert into @ttLF select  'DefaultCoO',           null,   null,   null,          null, null
insert into @ttLF select  'SourceSystem',         null,      1,   null,          null, null
insert into @ttLF select  'RecordAction',         null,      1,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'SKU' /* Key fields */;

Go