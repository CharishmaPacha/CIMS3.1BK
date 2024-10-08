/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments
  
  2017/12/21  SPP     Added ReferenceLocation(OB-649)
  2017/03/08  LRA     Added ReplenishOrder (HPI-1435)
  2016/09/21  VM      LPNDetails.gvLPNDetails: Added ReplenishOrderId, ReplenishOrderDetailId (HPI-GoLive)
  2015/06/18  OK      Added AlternateLPN field.
  2104/11/28  AK      Added Archived and set -2 for Warehouse, WarehouseDescription and SKU5Description.
  2014/11/07  PKS     All Id columns are set to -2
  2014/10/17  PKS     Caption assigned to DisplayQuantity
  2014/10/06  AK      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName TName;
set @ContextName = 'LPNDetails.gvLPNDetails';
delete from Layouts where (ContextName = @ContextName) and (CreatedBy = 'cimsdba');

/*------------------------------------------------------------------------------*/
/*LPNDetails.gvLPNDetails */
/*------------------------------------------------------------------------------*/

insert into Layouts
               (ContextName,  LayoutDescription,                       Layout,   DefaultLayout,  ShowExpanded, Status, SortSeq, Visible, CreatedBy, BusinessUnit)
       select   @ContextName, 'Standard',                              null,     'N',            'Y',          'I',    0,       0,       'cimsdba', BusinessUnit from vwBusinessUnits

declare @ttLF TLayoutFieldsTable;

/*----------------------------------------------------------------------------*/
/* Standard Layout */
/*----------------------------------------------------------------------------*/
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select 'LPNId',             null,     -2,   null,          null, null
insert into @ttLF select 'LPN',               null,   null,   null,          null, null
insert into @ttLF select 'LPNDetailId',       null,     -2,   null,          null, null
insert into @ttLF select 'LPNLine',           null,   null,   null,          null, null
insert into @ttLF select 'LPNType',           null,   null,   null,          null, null
insert into @ttLF select 'LPNStatus',         null,     -1,   null,          null, null
insert into @ttLF select 'LPNStatusDescription',
                                              null,   null,   null,          null, null
insert into @ttLF select 'CoO',               null,   null,   null,          null, null
insert into @ttLF select 'SKUId',             null,     -2,   null,          null, null
insert into @ttLF select 'SKU',               null,   null,   null,          null, null
insert into @ttLF select 'SKU1',              null,   null,   null,          null, null
insert into @ttLF select 'SKU2',              null,   null,   null,          null, null
insert into @ttLF select 'SKU3',              null,   null,   null,          null, null
insert into @ttLF select 'SKU4',              null,   null,   null,          null, null
insert into @ttLF select 'SKU5',              null,   null,   null,          null, null
insert into @ttLF select 'SKUDescription',    null,   null,   null,          null, null
insert into @ttLF select 'SKU1Description',   null,   null,   null,          null, null
insert into @ttLF select 'SKU2Description',   null,   null,   null,          null, null
insert into @ttLF select 'SKU3Description',   null,   null,   null,          null, null
insert into @ttLF select 'SKU4Description',   null,   null,   null,          null, null
insert into @ttLF select 'SKU5Description',   null,     -2,   null,          null, null
insert into @ttLF select 'UOM',               null,   null,   null,          null, null
insert into @ttLF select 'UPC',               null,   null,   null,          null, null
insert into @ttLF select 'InnerPacksPerLPN',  null,   null,   null,          null, null
insert into @ttLF select 'UnitsPerInnerPack', null,   null,   null,          null, null
insert into @ttLF select 'UnitsPerLPN',       null,   null,   null,          null, null
insert into @ttLF select 'ShipPack',          null,   null,   null,          null, null
insert into @ttLF select 'OnhandStatus',      null,   null,   null,          null, null
insert into @ttLF select 'OnhandStatusDescription',
                                              null,   null,   null,          null, null
insert into @ttLF select 'Ownership',         null,   null,   null,          null, null
insert into @ttLF select 'OwnershipDescription',
                                              null,   null,   null,          null, null
insert into @ttLF select 'Warehouse',         null,     -2,   null,          null, null
insert into @ttLF select 'WarehouseDescription',
                                              null,     -2,   null,          null, null
insert into @ttLF select 'InnerPacks',        null,   null,   null,          null, null
insert into @ttLF select 'Quantity',          null,   null,   null,          null, null
insert into @ttLF select 'ReservedQuantity',  null,   null,   null,          null, null
insert into @ttLF select 'DisplayQuantity',   null,     -2,   'Display Qty', null, null
insert into @ttLF select 'UnitsPerPackage',   null,   null,   null,          null, null
insert into @ttLF select 'ReceivedUnits',     null,   null,   null,          null, null
insert into @ttLF select 'ShipmentId',        null,   null,   null,          null, null
insert into @ttLF select 'LoadId',            null,   null,   null,          null, null
insert into @ttLF select 'ASNCase',           null,   null,   null,          null, null
insert into @ttLF select 'PalletId',          null,   null,   null,          null, null
insert into @ttLF select 'Pallet',            null,   null,   null,          null, null
insert into @ttLF select 'LocationId',        null,   null,   null,          null, null
insert into @ttLF select 'Location',          null,   null,   null,          null, null
insert into @ttLF select 'LocationType',      null,   null,   null,          null, null
insert into @ttLF select 'AlternateLPN',      null,   null,   null,          null, null
insert into @ttLF select 'StorageType',       null,   null,   null,          null, null
insert into @ttLF select 'PickingZone',       null,   null,   null,          null, null
insert into @ttLF select 'Barcode',           null,   null,   null,          null, null
insert into @ttLF select 'MinReplenishLevel', null,     -1,   null,          null, null
insert into @ttLF select 'MaxReplenishLevel', null,     -1,   null,          null, null
insert into @ttLF select 'ReplenishUoM',      null,   null,   null,          null, null
insert into @ttLF select 'OrderId',           null,   null,   null,          null, null
insert into @ttLF select 'PickTicket',        null,   null,   null,          null, null
insert into @ttLF select 'SalesOrder',        null,   null,   null,          null, null
insert into @ttLF select 'OrderType',         null,   null,   null,          null, null
insert into @ttLF select 'PackageSeqNo',      null,   null,   null,          null, null
insert into @ttLF select 'OrderDetailId',     null,   null,   null,          null, null
insert into @ttLF select 'OrderLine',         null,      1,   null,          null, null
insert into @ttLF select 'CustSKU',           null,   null,   null,          null, null
insert into @ttLF select 'ShipToStore',       null,   null,   null,          null, null
insert into @ttLF select 'PickBatchId',       null,   null,   null,          null, null
insert into @ttLF select 'PickBatchNo',       null,   null,   null,          null, null
insert into @ttLF select 'DestWarehouse',     null,   null,   null,          null, null
insert into @ttLF select 'DestZone',          null,   null,   null,          null, null
insert into @ttLF select 'DestLocation',      null,   null,   null,          null, null
insert into @ttLF select 'DisplayDestination',null,   null,   null,          null, null
insert into @ttLF select 'ReceiptId',         null,   null,   null,          null, null
insert into @ttLF select 'ReceiptNumber',     null,   null,   null,          null, null
insert into @ttLF select 'ReceiptDetailId',   null,   null,   null,          null, null
insert into @ttLF select 'ReceiptLine',       null,   null,   null,          null, null
insert into @ttLF select 'ReplenishOrderId',  null,   null,   null,          null, null
insert into @ttLF select 'ReplenishOrder',    null,      1,   null,          null, null
insert into @ttLF select 'ReplenishOrderDetailId',
                                              null,   null,   null,          null, null
insert into @ttLF select 'Weight',            null,   null,   null,          null, null
insert into @ttLF select 'Volume',            null,   null,   null,          null, null
insert into @ttLF select 'Lot',               null,   null,   null,          null, null
insert into @ttLF select 'LastPutawayDate',   null,   null,   null,          null, null
insert into @ttLF select 'ReferenceLocation', null,   null,   null,          null, null
insert into @ttLF select 'PickedBy',          null,   null,   null,          null, null
insert into @ttLF select 'PickedDate',        null,   null,   null,          null, null
insert into @ttLF select 'PackedBy',          null,   null,   null,          null, null
insert into @ttLF select 'PackedDate',        null,   null,   null,          null, null
insert into @ttLF select 'UDF1',              null,   null,   null,          null, null
insert into @ttLF select 'UDF2',              null,   null,   null,          null, null
insert into @ttLF select 'UDF3',              null,   null,   null,          null, null
insert into @ttLF select 'UDF4',              null,   null,   null,          null, null
insert into @ttLF select 'UDF5',              null,   null,   null,          null, null
insert into @ttLF select 'DefaultUoM',        null,   null,   null,          null, null
insert into @ttLF select 'Archived',          null,   null,   null,          null, null
insert into @ttLF select 'BusinessUnit',      null,   null,   null,          null, null
insert into @ttLF select 'CreatedDate',       null,   null,   null,          null, null
insert into @ttLF select 'ModifiedDate',      null,   null,   null,          null, null
insert into @ttLF select 'CreatedBy',         null,   null,   null,          null, null
insert into @ttLF select 'ModifiedBy',        null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup 'LPNDetails.gvLPNDetails', 'Standard', @ttLF;

Go
