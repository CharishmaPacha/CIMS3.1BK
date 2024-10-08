/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/25  PKK     Added PrepackCode (HA-2840)
  2020/12/30  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/07/28  SPP     Added missing fields from View (HA-1225)
  2020/06/23  TK      Layout for Rework orders (HA-833)
  2020/05/18  HYP     Added layout Summary by Wave/SKU (HA-581)
  2020/05/18  MS      Added WaveGroup, WaveId & WaveNo (HA-593)
  2020/05/15  TK      Added NewSKU & NewInventoryClasses (HA-543)
  2020/05/02  MS      Added OrderStatus, OrderStatusDesc (HA-293)
  2020/03/30  MS      Added InventoryClasses (HA-83)
  2019/05/24  MS      Changed the visiblity for OrderDetailId Field (CIMSV3-429)
  2019/05/19  MS      Fixed issue with Actions (CIMSV3-423)
  2019/05/14  RBV     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/03/23  AY      Added summary fields
  2018/01/05  AJ      Added missing fields and corrected indentations (CIMSV3-184)
  2018/01/08  DK      Initial revision.
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

select @ContextName = 'List.OrderDetails',
       @DataSetName = 'vwOrderDetails';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Short Lines',                   null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Rework Orders',                 null,                 null,  null,   0,      null

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
insert into @ttLF select 'OrderDetailId',               null,     -3,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'HostOrderLine',               null,   null,   null,               null, null
insert into @ttLF select 'ParentHostLineNo',            null,   null,   null,               null, null
insert into @ttLF select 'OrderStatus',                 null,   null,   'Order Status',     null, null
insert into @ttLF select 'OrderStatusDesc',             null,   null,   'Order Status',     null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'SKUDesc',                     null,   null,   null,               null, null
insert into @ttLF select 'SKU1Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU2Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU3Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU4Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU5Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'DisplaySKU',                  null,     -2,   null,               null, null /* used in RF */
insert into @ttLF select 'DisplaySKUDesc',              null,     -2,   null,               null, null /* used in RF */

insert into @ttLF select 'UnitsOrdered',                null,   null,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,               null, null
insert into @ttLF select 'OrigUnitsAuthorizedToShip',   null,   null,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'UnitsPreAllocated',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsToAllocate',             null,   null,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,   null,   null,               null, null

insert into @ttLF select 'UnitsPerCarton',              null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'ShipPack',                    null,   null,   null,               null, null
insert into @ttLF select 'IsSortable',                  null,   null,   null,               null, null
insert into @ttLF select 'IsConveyable',                null,   null,   null,               null, null
insert into @ttLF select 'IsScannable',                 null,   null,   null,               null, null
insert into @ttLF select 'Serialized',                  null,   null,   null,               null, null

insert into @ttLF select 'PickBatchId',                 null,   null,   null,               null, null
insert into @ttLF select 'PickBatchNo',                 null,    -20,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null

insert into @ttLF select 'NewSKU',                      null,      1,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null
insert into @ttLF select 'NewInventoryClass1',          null,   null,   null,               null, null
insert into @ttLF select 'NewInventoryClass2',          null,   null,   null,               null, null
insert into @ttLF select 'NewInventoryClass3',          null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailWeight',           null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailVolume',           null,   null,   null,               null, null

insert into @ttLF select 'RetailUnitPrice',             null,   null,   null,               null, null
insert into @ttLF select 'UnitSalePrice',               null,   null,   null,               null, null
insert into @ttLF select 'LineValue',                   null,   null,   null,               null, null

insert into @ttLF select 'PickZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestLocation',                null,   null,   null,               null, null
insert into @ttLF select 'PackingGroup',                null,   null,   null,               null, null
insert into @ttLF select 'PrepackCode',                 null,   null,   null,               null, null
insert into @ttLF select 'AllocateFlags',               null,   null,   null,               null, null

/* OH Info */
insert into @ttLF select 'OrderCategory1',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory3',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory4',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory5',              null,   null,   null,               null, null

insert into @ttLF select 'OrderType',                   null,     -1,   null,               null, null
insert into @ttLF select 'OrderTypeDescription',        null,   null,   null,               null, null
insert into @ttLF select 'StatusGroup',                 null,     -1,   null,               null, null
insert into @ttLF select 'OrderDate',                   null,   null,   null,               null, null
insert into @ttLF select 'DesiredShipDate',             null,     -1,   null,               null, null
insert into @ttLF select 'Priority',                    null,     -1,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToName',                  null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'Account',                     null,   null,   null,               null, null
insert into @ttLF select 'AccountName',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'ODCustPO',                    null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,     -1,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,     -1,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,     -1,   null,               null, null
insert into @ttLF select 'DateShipped',                 null,     -1,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,    -20,   null,               null, null
insert into @ttLF select 'WaveGroup',                   null,     -1,   null,               null, null
insert into @ttLF select 'PrevWaveNo',                  null,   null,   null,               null, null
insert into @ttLF select 'NumLines',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,     -1,   'Total Ordered',      95, null
insert into @ttLF select 'TotalUnitsAssigned',          null,     -1,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,     -1,   null,               null, null
insert into @ttLF select 'TotalTax',                    null,     -1,   null,               null, null
insert into @ttLF select 'TotalShippingCost',           null,     -1,   null,               null, null
insert into @ttLF select 'TotalDiscount',               null,     -1,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,               null, null
/* SKU Info */
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'ProductCost',                 null,   null,   null,               null, null
/* Other OD fields */
insert into @ttLF select 'ShortPick',                   null,   null,   null,               null, null
insert into @ttLF select 'LineType',                    null,   null,   null,               null, null
insert into @ttLF select 'UnitDiscount',                null,   null,   null,               null, null
insert into @ttLF select 'ResidualDiscount',            null,   null,   null,               null, null
insert into @ttLF select 'UnitTaxAmount',               null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,     -1,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,   null,   null,               null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null

insert into @ttLF select 'OrderLine',                   null,     -2,   null,               null, null  -- deprecated
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null  -- deprecated
insert into @ttLF select 'StatusDescription',           null,     -2,   null,               null, null  -- deprecated

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

insert into @ttLF select 'SKUUDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF5',                     null,   null,   null,               null, null

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

insert into @ttLF select 'vwOD_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF5',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF6',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF7',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF8',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF9',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF10',                  null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'PreProcessFlag',              null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'OrderDetailId;PickTicket' /* Key fields */;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Short Lines */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'OrderDetailId',               null,     -3,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null
insert into @ttLF select 'HostOrderLine',               null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'SKUDesc',                     null,   null,   null,               null, null

insert into @ttLF select 'UnitsOrdered',                null,   null,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',
                                                        null,   null,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'UnitsPreAllocated',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsToAllocate',             null,      1,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,   null,   null,               null, null

insert into @ttLF select 'UnitsPerCarton',              null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'PackingGroup',                null,   null,   null,               null, null

insert into @ttLF select 'PickBatchNo',                 null,    -20,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,     -1,   null,               null, null

insert into @ttLF select 'CustSKU',                     null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailWeight',           null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailVolume',           null,   null,   null,               null, null

insert into @ttLF select 'OrderType',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderTypeDescription',
                                                        null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,   null,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,   null,   'Order Status',     null, null
insert into @ttLF select 'OrderDate',                   null,   null,   null,               null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null
insert into @ttLF select 'DateShipped',                 null,   null,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,     -2,   null,               null, null
insert into @ttLF select 'WaveGroup',                   null,   null,   null,               null, null
insert into @ttLF select 'NumLines',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,     -1,   'Total Ordered',      95, null
insert into @ttLF select 'RetailUnitPrice',             null,   null,   null,               null, null
insert into @ttLF select 'UnitSalePrice',               null,   null,   null,               null, null
insert into @ttLF select 'TotalUnitsAssigned',          null,   null,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,     -1,   null,               null, null
insert into @ttLF select 'TotalTax',                    null,   null,   null,               null, null
insert into @ttLF select 'TotalShippingCost',           null,   null,   null,               null, null
insert into @ttLF select 'TotalDiscount',               null,   null,   null,               null, null
insert into @ttLF select 'ShortPick',                   null,   null,   null,               null, null
insert into @ttLF select 'LineType',                    null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'ProductCost',                 null,   null,   null,               null, null
insert into @ttLF select 'UnitDiscount',                null,   null,   null,               null, null
insert into @ttLF select 'ResidualDiscount',            null,   null,   null,               null, null
insert into @ttLF select 'UnitTaxAmount',               null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,     -1,   null,               null, null
insert into @ttLF select 'PickZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestLocation',                null,   null,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,   null,   null,               null, null

insert into @ttLF select 'OrderCategory1',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory3',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory4',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory5',              null,   null,   null,               null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null

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

insert into @ttLF select 'SKUUDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF5',                     null,   null,   null,               null, null

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

insert into @ttLF select 'vwOD_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF5',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF6',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF7',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF8',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF9',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF10',                  null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Short Lines', @ttLF, @DataSetName, 'OrderDetailId;PickTicket' /* KeyFields */;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Short Lines */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'OrderDetailId',               null,     -3,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'SalesOrder',                  null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'SKUDesc',                     null,   null,   null,               null, null

insert into @ttLF select 'UnitsOrdered',                null,     -2,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   '# Requested',      null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   '# Completed',      null, null
insert into @ttLF select 'UnitsPreAllocated',           null,      1,   '# In WIP',         null, null
insert into @ttLF select 'UnitsToAllocate',             null,      1,   '# Remaining',      null, null

insert into @ttLF select 'PickBatchNo',                 null,    -20,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null

insert into @ttLF select 'NewSKU',                      null,      1,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,   null,   null,               null, null
insert into @ttLF select 'Lot',                         null,   null,   null,               null, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null
insert into @ttLF select 'NewInventoryClass1',          null,   null,   null,               null, null
insert into @ttLF select 'NewInventoryClass2',          null,   null,   null,               null, null
insert into @ttLF select 'NewInventoryClass3',          null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailWeight',           null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailVolume',           null,   null,   null,               null, null

insert into @ttLF select 'RetailUnitPrice',             null,   null,   null,               null, null
insert into @ttLF select 'UnitSalePrice',               null,   null,   null,               null, null
insert into @ttLF select 'LineValue',                   null,     -2,   null,               null, null

/* OH Info */
insert into @ttLF select 'OrderCategory1',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory2',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory3',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory4',              null,   null,   null,               null, null
insert into @ttLF select 'OrderCategory5',              null,   null,   null,               null, null

insert into @ttLF select 'OrderType',                   null,     -1,   null,               null, null
insert into @ttLF select 'OrderTypeDescription',        null,   null,   null,               null, null
insert into @ttLF select 'StatusGroup',                 null,   null,   null,               null, null
insert into @ttLF select 'OrderDate',                   null,   null,   null,               null, null
insert into @ttLF select 'DesiredShipDate',             null,   null,   null,               null, null
insert into @ttLF select 'Priority',                    null,   null,   null,               null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToId',                    null,   null,   null,               null, null
insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'ShipFrom',                    null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,     -1,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,     -1,   null,               null, null
insert into @ttLF select 'CancelDate',                  null,   null,   null,               null, null
insert into @ttLF select 'DateShipped',                 null,     -1,   null,               null, null
insert into @ttLF select 'PickBatchGroup',              null,    -20,   null,               null, null
insert into @ttLF select 'WaveGroup',                   null,     -1,   null,               null, null
insert into @ttLF select 'NumLines',                    null,     -1,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'NumUnits',                    null,     -1,   'Total Ordered',      95, null
insert into @ttLF select 'TotalUnitsAssigned',          null,     -1,   null,               null, null
insert into @ttLF select 'TotalSalesAmount',            null,     -1,   null,               null, null
insert into @ttLF select 'TotalTax',                    null,     -1,   null,               null, null
insert into @ttLF select 'TotalShippingCost',           null,     -1,   null,               null, null
insert into @ttLF select 'TotalDiscount',               null,     -1,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,               null, null
/* SKU Info */
insert into @ttLF select 'UPC',                         null,   null,   null,               null, null
insert into @ttLF select 'UoM',                         null,   null,   null,               null, null
insert into @ttLF select 'ProductCost',                 null,   null,   null,               null, null
/* Other OD fields */
insert into @ttLF select 'ShortPick',                   null,   null,   null,               null, null
insert into @ttLF select 'LineType',                    null,   null,   null,               null, null
insert into @ttLF select 'UnitDiscount',                null,   null,   null,               null, null
insert into @ttLF select 'ResidualDiscount',            null,   null,   null,               null, null
insert into @ttLF select 'UnitTaxAmount',               null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,     -1,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,   null,   null,               null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null

insert into @ttLF select 'OrderLine',                   null,     -2,   null,               null, null  -- deprecated
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null  -- deprecated
insert into @ttLF select 'StatusDescription',           null,     -2,   null,               null, null  -- deprecated

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

insert into @ttLF select 'SKUUDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'SKUUDF5',                     null,   null,   null,               null, null

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

insert into @ttLF select 'vwOD_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF5',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF6',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF7',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF8',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF9',                   null,   null,   null,               null, null
insert into @ttLF select 'vwOD_UDF10',                  null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Rework Orders', @ttLF, @DataSetName, 'OrderDetailId;PickTicket' /* KeyFields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by ShipDate & SKU';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'DesiredShipDate',            null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU',                        null,        1, null,               null, null,    null
insert into @ttLFE select 'OrderId',                    null,        1, 'Orders',           null, null,    'DCount'
insert into @ttLFE select 'UnitsToShip',                null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsAssigned',              null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToAllocate',            null,        1, null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Style';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'SKU1',                       null,        1, null,               null, null,    null
insert into @ttLFE select 'PackingGroup',               null,        1, null,               null, null,    null
insert into @ttLFE select 'UnitsPerCarton',             null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU2',                       null,        1, null,               null, null,    'DCount'
insert into @ttLFE select 'SKU3',                       null,        1, null,               null, null,    'DCount'
insert into @ttLFE select 'OrderId',                    null,        1, 'Orders',           null, null,    'DCount'
insert into @ttLFE select 'UnitsToShip',                null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsAssigned',              null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToAllocate',            null,        1, null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by SKU';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'SKU',                        null,        1, null,               null, null,    null
insert into @ttLFE select 'DesiredShipDate',            null,        1, 'Ship Date',        null, null,    'Min'
insert into @ttLFE select 'CancelDate',                 null,        1, 'Cancel Date',      null, null,    'Min'
insert into @ttLFE select 'OrderId',                    null,        1, 'Orders',           null, null,    'DCount'
insert into @ttLFE select 'UnitsToShip',                null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsAssigned',              null,        1, null,               null, null,    'Sum'
insert into @ttLFE select 'UnitsToAllocate',            null,        1, null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Wave/SKU';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'WaveNo',                     null,        1, null,               null, null,    null
insert into @ttLFE select 'SKU',                        null,        1, null,               null, null,    null
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
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

insert into @ttLSF(FieldName,                    SummaryType, DisplayFormat,                AggregateMethod)
            select 'PickTicket',                 'DCount',    '# PTs:{0:n0}',               null
      union select 'SKU',                        'DCount',    '{0:n0}',                     null
      union select 'PickBatchNo',                'DCount',    '{0:n0}',                     null
      union select 'LineValue',                  'Sum',       '{0:n0}',                     null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go