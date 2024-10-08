/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person   Comments

  2021/11/09  RV      Added new layout details for Packing_BulkOrderPacking (FBV3-421)
  2021/07/10  RV      Added PackGroupKey (BK-636)
  2021/08/09  NB      Packing_StandardOrderPacking.UnitWeight visible changed to -3(CIMSV3-1595)
  2021/07/15  RV      SKU: Set visibility to show in packing (OB2-1903)
  2021/05/05  NB      Initial revision (CIMSV3-156)
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
/* StandardOrderPacking Layout */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'Packing_StandardOrderPacking',
       @DataSetName = 'vwOrderToPackDetails';

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'OrderDetailId',               null,   -2,     null,              null, null
insert into @ttLF select 'HostOrderLine',               null,   null,   'Line #',          null, null
insert into @ttLF select 'SKU',                         null,   1,      null,              null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,              null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,              null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,              null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,              null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU',                  null,     -1,   null,              null, null
insert into @ttLF select 'DisplaySKUDesc',              null,     -1,   null,              null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,              null, null

insert into @ttLF select 'Pallet',                      null,   null,   'Cart',            null, null
insert into @ttLF select 'LPN',                         null,   null,   'Position',        null, null
insert into @ttLF select 'PickedQuantity',              null,   null,   null,              null, null
insert into @ttLF select 'UnitsToPack',                 null,   1,      null,              null, null
insert into @ttLF select 'UnitsPacked',                 null,   1,      null,              null, null
insert into @ttLF select 'UPC',                         null,   null,   null,              null, null

insert into @ttLF select 'PickedFromLocation',          null,   null,   null,              null, null
insert into @ttLF select 'PickedBy',                    null,   null,   null,              null, null

insert into @ttLF select 'Serialized',                  null,   null,   null,              null, null
insert into @ttLF select 'GiftCardSerialNumber',        null,   null,   null,              null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,              null, null
insert into @ttLF select 'SKUImageUrl',                 null,   -2,     null,              null, null

insert into @ttLF select 'LPNId',                       null,   null,   null,              null, null
insert into @ttLF select 'LPNDetailId',                 null,   null,   null,              null, null

insert into @ttLF select 'OrderLine',                   null,   -2,     null,              null, null
insert into @ttLF select 'AlternateSKU',                null,   null,   null,              null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,              null, null
insert into @ttLF select 'CustPO',                      null,    -3,    null,              null, null
insert into @ttLF select 'CustSKU',                     null,   null,   null,              null, null
insert into @ttLF select 'LastMovedDate',               null,   -3,     null,              null, null
insert into @ttLF select 'Location',                    null,   -3,     null,              null, null
insert into @ttLF select 'Lot',                         null,   null,   null,              null, null
insert into @ttLF select 'LPNStatus',                   null,   -3,     null,              null, null
insert into @ttLF select 'LPNType',                     null,   -3,     null,              null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,              null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,              null, null
insert into @ttLF select 'PackingGroup',                null,   -1,     null,              null, null
insert into @ttLF select 'PageTitle',                   null,   -3,     null,              null, null

insert into @ttLF select 'PickBatchNo',                 null,   -3,     null,              null, null
insert into @ttLF select 'PickTicket',                  null,   -3,     null,              null, null
insert into @ttLF select 'Priority',                    null,   -3,     null,              null, null
insert into @ttLF select 'SalesOrder',                  null,   -3,     null,              null, null
insert into @ttLF select 'SerialNo',                    null,   null,   null,              null, null
insert into @ttLF select 'ShipToId',                    null,   -3,     null,              null, null
insert into @ttLF select 'ShipVia',                     null,   -3,     null,              null, null

insert into @ttLF select 'SKU1Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU2Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU3Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU4Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU5Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKUBarcode',                  null,   null,   null,              null, null
insert into @ttLF select 'SKUDesc',                     null,   -3,     null,              null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,              null, null
insert into @ttLF select 'PalletId',                    null,   null,   null,              null, null
insert into @ttLF select 'PickBatchId',                 null,   null,   null,              null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,              null, null
insert into @ttLF select 'SoldToId',                    null,   null,   null,              null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,              null, null

insert into @ttLF select 'Status',                      null,   null,   null,              null, null
insert into @ttLF select 'UnitsAssigned',               null,   -3,     null,              null, null
insert into @ttLF select 'UnitsOrdered',                null,   -3,     null,              null, null
insert into @ttLF select 'UnitWeight',                  null,   -3,     null,              null, null
insert into @ttLF select 'PackGroupKey',                null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF1',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF2',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF3',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF4',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF5',                    null,   -3,     null,              null, null

insert into @ttLF select 'OD_UDF1',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF2',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF3',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF4',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF5',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF6',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF7',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF8',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF9',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF10',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF11',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF12',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF13',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF14',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF15',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF16',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF17',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF18',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF19',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF20',                    null,   -3,     null,              null, null

insert into @ttLF select 'vwOPDtls_UDF1',               null,   -3,     null,              null, null
insert into @ttLF select 'vwOPDtls_UDF2',               null,   -3,     null,              null, null
insert into @ttLF select 'vwOPDtls_UDF3',               null,   -3,     null,              null, null
insert into @ttLF select 'vwOPDtls_UDF4',               null,   -3,     null,              null, null
insert into @ttLF select 'vwOPDtls_UDF5',               null,   -3,     null,              null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'OrderDetailId;' /* Key fields */;

/******************************************************************************/
/* StandardOrderPacking Layout */
/******************************************************************************/
delete from @Layouts;

select @ContextName = 'Packing_BulkOrderPacking',
       @DataSetName = 'vwOrderToPackDetails';

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'OrderDetailId',               null,   -2,     null,              null, null
insert into @ttLF select 'HostOrderLine',               null,   null,   'Line #',          null, null
insert into @ttLF select 'SKU',                         null,   1,      null,              null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,              null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,              null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,              null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,              null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,              null, null
insert into @ttLF select 'DisplaySKU',                  null,   -1,     null,              null, null
insert into @ttLF select 'DisplaySKUDesc',              null,   -1,     null,              null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,              null, null

insert into @ttLF select 'Pallet',                      null,   null,   'Cart',            null, null
insert into @ttLF select 'LPN',                         null,   null,   'Position',        null, null
insert into @ttLF select 'PickedQuantity',              null,   1,      null,              null, null
insert into @ttLF select 'UnitsToPack',                 null,   1,      null,              null, null
insert into @ttLF select 'UnitsPacked',                 null,   1,      null,              null, null
insert into @ttLF select 'UPC',                         null,   null,   null,              null, null

insert into @ttLF select 'PickedFromLocation',          null,   null,   null,              null, null
insert into @ttLF select 'PickedBy',                    null,   null,   null,              null, null

insert into @ttLF select 'Serialized',                  null,   null,   null,              null, null
insert into @ttLF select 'GiftCardSerialNumber',        null,   null,   null,              null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,              null, null
insert into @ttLF select 'SKUImageUrl',                 null,   -2,     null,              null, null

insert into @ttLF select 'LPNId',                       null,   null,   null,              null, null
insert into @ttLF select 'LPNDetailId',                 null,   null,   null,              null, null

insert into @ttLF select 'OrderLine',                   null,   -2,     null,              null, null
insert into @ttLF select 'AlternateSKU',                null,   null,   null,              null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,              null, null
insert into @ttLF select 'CustPO',                      null,    -3,    null,              null, null
insert into @ttLF select 'CustSKU',                     null,   null,   null,              null, null
insert into @ttLF select 'LastMovedDate',               null,   -3,     null,              null, null
insert into @ttLF select 'Location',                    null,   -3,     null,              null, null
insert into @ttLF select 'Lot',                         null,   null,   null,              null, null
insert into @ttLF select 'LPNStatus',                   null,   -3,     null,              null, null
insert into @ttLF select 'LPNType',                     null,   -3,     null,              null, null
insert into @ttLF select 'OrderType',                   null,   null,   null,              null, null
insert into @ttLF select 'OrderTypeDesc',               null,   -3,   null,              null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,              null, null
insert into @ttLF select 'PackingGroup',                null,   -1,     null,              null, null
insert into @ttLF select 'PageTitle',                   null,   -3,     null,              null, null

insert into @ttLF select 'IsCubed',                     null,   -3,     null,              null, null
insert into @ttLF select 'CubedCarton',                 null,   -3,     null,              null, null
insert into @ttLF select 'CubedCartonType',             null,   -3,     null,              null, null
insert into @ttLF select 'CubedCartonWeight',           null,   -3,     null,              null, null

insert into @ttLF select 'PickBatchNo',                 null,   -3,     null,              null, null
insert into @ttLF select 'PickTicket',                  null,   -3,     null,              null, null
insert into @ttLF select 'Priority',                    null,   -3,     null,              null, null
insert into @ttLF select 'SalesOrder',                  null,   -3,     null,              null, null
insert into @ttLF select 'SerialNo',                    null,   null,   null,              null, null

insert into @ttLF select 'ShipVia',                     null,   -3,     null,              null, null
insert into @ttLF select 'ShipViaDesc',                 null,   -3,     null,              null, null

insert into @ttLF select 'Account',                     null,   -3,     null,              null, null
insert into @ttLF select 'AccountName',                 null,   -3,     null,              null, null

insert into @ttLF select 'SoldToId',                    null,   -3,     null,              null, null
insert into @ttLF select 'SoldToName',                  null,   -3,     null,              null, null

insert into @ttLF select 'ShipToId',                    null,   -3,     null,              null, null
insert into @ttLF select 'ShipToName',                  null,   -3,     null,               null, null
insert into @ttLF select 'ShipToAddressLine1',          null,   -3,     null,               null, null
insert into @ttLF select 'ShipToAddressLine2',          null,   -3,     null,               null, null
insert into @ttLF select 'ShipToCityStateZip',          null,   -3,     null,               null, null
insert into @ttLF select 'ShipToCityState',             null,   -3,     null,               null, null
insert into @ttLF select 'ShipToCity',                  null,   -3,     null,               null, null
insert into @ttLF select 'ShipToState',                 null,   -3,     null,               null, null
insert into @ttLF select 'ShipToZip',                   null,   -3,     null,               null, null
insert into @ttLF select 'ShipToCountry',               null,   -3,     null,               null, null

insert into @ttLF select 'SKU1Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU2Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU3Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU4Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU5Desc',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKUBarcode',                  null,   null,   null,              null, null
insert into @ttLF select 'SKUDesc',                     null,   -3,     null,              null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,              null, null
insert into @ttLF select 'PalletId',                    null,   null,   null,              null, null
insert into @ttLF select 'PickBatchId',                 null,   null,   null,              null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,              null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,              null, null

insert into @ttLF select 'Status',                      null,   null,   null,              null, null
insert into @ttLF select 'OrderStatus',                 null,   -3,     null,              null, null
insert into @ttLF select 'OrderStatusDesc',             null,   -3,     null,              null, null
insert into @ttLF select 'UnitsAssigned',               null,   -3,     null,              null, null
insert into @ttLF select 'UnitsOrdered',                null,   -3,     null,              null, null
insert into @ttLF select 'UnitWeight',                  null,   -3,     null,              null, null
insert into @ttLF select 'PackGroupKey',                null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF1',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF2',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF3',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF4',                    null,   -3,     null,              null, null
insert into @ttLF select 'SKU_UDF5',                    null,   -3,     null,              null, null

insert into @ttLF select 'OD_UDF1',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF2',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF3',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF4',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF5',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF6',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF7',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF8',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF9',                     null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF10',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF11',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF12',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF13',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF14',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF15',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF16',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF17',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF18',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF19',                    null,   -3,     null,              null, null
insert into @ttLF select 'OD_UDF20',                    null,   -3,     null,              null, null

insert into @ttLF select 'vwOPDtls_UDF1',               null,   -3,     null,              null, null
insert into @ttLF select 'vwOPDtls_UDF2',               null,   -3,     null,              null, null
insert into @ttLF select 'vwOPDtls_UDF3',               null,   -3,     null,              null, null
insert into @ttLF select 'vwOPDtls_UDF4',               null,   -3,     null,              null, null
insert into @ttLF select 'vwOPDtls_UDF5',               null,   -3,     null,              null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'OrderDetailId;' /* Key fields */;

Go