/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/23  RV      UserControl.SelectReceiptNumber and UserControl.SelectReceiptNumber: Set layout widths (FBV3-468)
  2021/09/30  RV      SelectReceiptSKU and SelectReceiptNumber: Corrected the field visibility and added new fields (FBV3-265)
  2021/08/16  RV      UserControl.SelectReceiptSKU: QtyOrdered, QtyToReceive, QtyToLabel, QtyToLabel and QtyInTransit (FBV3-244)
  2021/08/05  RV      SelectReceiver, SelectReceiptDetail: Added (CIMSV3-1556)
  2021/03/12  AY      UserControl.SelectAddressBrief: New control added to show brief addres
                      UserControl.SelectShipVia: Revised to show complete description (HA-GoLive)
  2021/03/06  TK      UserControl.SelectSKU: Increased field width (HA-MockGoLive)
  2021/02/25  NB      UserControl.SelectAddress: Modified ContactRefId to Visible (HA-2067)
  2020/12/01  RKC     UserControl.SelectAddress: Added ContactRefId (HA-1714)
  2020/06/26  KBB     Added UserControl.SelectBillToAddressId (HA-986)
  2020/06/10  OK      Added layouts for ShipTo and ShipFrom DB lookups (HA-843)
  2020/06/08  SJ      Changed Visibility for Description (HA-708)
  2020/05/18  TK      Display PickZoneDesc instead of LocationType is droplocation selection (HA-543)
  2020/05/15  RT      Included UserControl.SelectLocation (HA-437)
  2020/04/14  RV      UserControl.SelectSKU: Added SKUId (CIMSV3-299)
  2020/04/10  RT      Included UserControl.SelectCartonType (HA-143)
  2020/03/05  MS      Added layout UserControl.SelectUser (CIMSV3-561)
  2020/03/05  MS      Added layout UserControl.SelectShipVia (CIMSV3-426)
  2020/03/20  RV      Initial revision (CIMSV3-760)
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

/********************************************************************************/
/* Layout for GridLookUpCombo for ShipVia selection */
select @ContextName = 'UserControl.SelectShipVia';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectShipVia */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select 'ShipVia',           null,   null,   null,          null, null
insert into @ttLF select 'Carrier',           null,   null,   null,          null, null
insert into @ttLF select 'Description',       null,      1,   null,          null, null
insert into @ttLF select 'CarrierServiceCode',null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for User selection */
select @ContextName = 'UserControl.SelectUser';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectUser */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select 'UserName',          null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for SKU selection */
select @ContextName = 'UserControl.SelectSKU';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectSKU */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select 'SKUId',              null,   null,   null,          null, null
insert into @ttLF select 'SKU',                null,   null,   null,          100,  null
insert into @ttLF select 'SKU1',               null,   null,   null,          140,  null
insert into @ttLF select 'SKU2',               null,   null,   null,           80,  null
insert into @ttLF select 'SKU3',               null,   null,   null,           80,  null
insert into @ttLF select 'SKU4',               null,   null,   null,           80,  null
insert into @ttLF select 'SKU5',               null,   null,   null,           80,  null
insert into @ttLF select 'Description',        null,   null,   null,          null, null

insert into @ttLF select 'SKU1Description',    null,   null,   null,          null, null
insert into @ttLF select 'SKU2Description',    null,   null,   null,          null, null
insert into @ttLF select 'SKU3Description',    null,   null,   null,          null, null
insert into @ttLF select 'SKU4Description',    null,   null,   null,          null, null
insert into @ttLF select 'SKU5Description',    null,   null,   null,          null, null

insert into @ttLF select 'AlternateSKU',       null,   null,   null,          null, null
insert into @ttLF select 'Status',             null,   null,   null,          null, null
insert into @ttLF select 'StatusDescription',  null,   null,   null,          null, null
insert into @ttLF select 'UoM',                null,   null,   null,          null, null
insert into @ttLF select 'UoMDescription',     null,   null,   null,          null, null
insert into @ttLF select 'InnerPacksPerLPN',   null,   null,   null,          null, null
insert into @ttLF select 'UnitsPerInnerPack',  null,   null,   null,          null, null
insert into @ttLF select 'UnitsPerLPN',        null,   null,   null,          null, null
insert into @ttLF select 'Barcode',            null,   null,   null,          null, null

insert into @ttLF select 'UPC',                null,      1,   null,          100,  null

insert into @ttLF select 'Brand',              null,   null,   null,          null, null
insert into @ttLF select 'ProdCategory',       null,     -1,   null,          null, null
insert into @ttLF select 'ProdCategoryDesc',   null,     -1,   null,          null, null

insert into @ttLF select 'ProdSubCategory',    null,     -1,   null,          null, null
insert into @ttLF select 'ProdSubCategoryDesc',null,     -1,   null,          null, null
insert into @ttLF select 'PutawayClass',       null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for SKU selection */
select @ContextName = 'UserControl.SelectOrderDetailKit';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectOrderDetailKit */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select 'OrderDetailId',      null,   null,   null,          null, null
insert into @ttLF select 'SKUId',              null,   null,   null,          null, null
insert into @ttLF select 'SKU',                null,   null,   null,          null, null
insert into @ttLF select 'SKU1',               null,   null,   null,          null, null
insert into @ttLF select 'SKU2',               null,   null,   null,          null, null
insert into @ttLF select 'SKU3',               null,   null,   null,          null, null
insert into @ttLF select 'SKU4',               null,   null,   null,          null, null
insert into @ttLF select 'SKU5',               null,   null,   null,          null, null
insert into @ttLF select 'Description',        null,   null,   null,          null, null

insert into @ttLF select 'AlternateSKU',       null,   null,   null,          null, null
insert into @ttLF select 'Status',             null,   null,   null,          null, null
insert into @ttLF select 'StatusDescription',  null,   null,   null,          null, null
insert into @ttLF select 'UoM',                null,   null,   null,          null, null
insert into @ttLF select 'UoMDescription',     null,   null,   null,          null, null
insert into @ttLF select 'InnerPacksPerLPN',   null,   null,   null,          null, null
insert into @ttLF select 'UnitsPerInnerPack',  null,   null,   null,          null, null
insert into @ttLF select 'UnitsPerLPN',        null,   null,   null,          null, null
insert into @ttLF select 'Barcode',            null,   null,   null,          null, null
insert into @ttLF select 'UPC',                null,   null,   null,          null, null

insert into @ttLF select 'UnitsOrdered',       null,      1,   null,          null, null
insert into @ttLF select 'UnitsToAllocate',    null,      1,   '# Remaining', null, null
insert into @ttLF select 'LOT',                null,   null,   null,          null, null

insert into @ttLF select 'Brand',              null,   null,   null,          null, null
insert into @ttLF select 'ProdCategory',       null,     -1,   null,          null, null
insert into @ttLF select 'ProdCategoryDesc',   null,     -1,   null,          null, null

insert into @ttLF select 'ProdSubCategory',    null,     -1,   null,          null, null
insert into @ttLF select 'ProdSubCategoryDesc',null,     -1,   null,          null, null
insert into @ttLF select 'PutawayClass',       null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for SKU selection */
select @ContextName = 'UserControl.SelectReceiptSKU';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectReceiptSKU */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select 'ReceiptDetailId',    null,   null,   null,          null, null
insert into @ttLF select 'ReceiptId',          null,   null,   null,          null, null
insert into @ttLF select 'SKUId',              null,   null,   null,          null, null
insert into @ttLF select 'SKU',                null,   null,   null,           150, null
insert into @ttLF select 'SKUDescription',     null,   1,      null,           150, null
insert into @ttLF select 'SKU1',               null,   null,   null,          null, null
insert into @ttLF select 'SKU2',               null,   null,   null,          null, null
insert into @ttLF select 'SKU3',               null,   null,   null,          null, null
insert into @ttLF select 'SKU4',               null,   null,   null,          null, null
insert into @ttLF select 'SKU5',               null,   null,   null,          null, null

insert into @ttLF select 'AlternateSKU',       null,   null,   null,          null, null
insert into @ttLF select 'Status',             null,   null,   null,          null, null
insert into @ttLF select 'StatusDescription',  null,   null,   null,          null, null
insert into @ttLF select 'UoM',                null,   null,   null,          null, null
insert into @ttLF select 'UoMDescription',     null,   null,   null,          null, null
insert into @ttLF select 'InnerPacksPerLPN',   null,   null,   null,          null, null
insert into @ttLF select 'UnitsPerInnerPack',  null,   null,   null,          null, null
insert into @ttLF select 'UnitsPerLPN',        null,   null,   null,          null, null
insert into @ttLF select 'Barcode',            null,   null,   null,          null, null
insert into @ttLF select 'QtyOrdered',         null,      1,   null,            80, null
insert into @ttLF select 'QtyToReceive',       null,      1,   null,            90, null
insert into @ttLF select 'QtyToLabel',         null,      1,   null,            80, null
insert into @ttLF select 'QtyInTransit',       null,   null,   null,            80, null
insert into @ttLF select 'UPC',                null,      1,   null,           100, null

insert into @ttLF select 'Brand',              null,   null,   null,          null, null
insert into @ttLF select 'ProdCategory',       null,     -1,   null,          null, null
insert into @ttLF select 'ProdCategoryDesc',   null,     -1,   null,          null, null

insert into @ttLF select 'ProdSubCategory',    null,     -1,   null,          null, null
insert into @ttLF select 'ProdSubCategoryDesc',null,     -1,   null,          null, null
insert into @ttLF select 'PutawayClass',       null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;
/********************************************************************************/
/* Layout for GridLookUpCombo for Receiver selection */
select @ContextName = 'UserControl.SelectReceiver';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectReceiver */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field                Visible Visible Field          Width Display
                          Name                 Index           Caption              Format */
insert into @ttLF select  'ReceiverId',         null,   null,   null,          null, null
insert into @ttLF select  'ReceiverNumber',     null,   null,   null,          null, null
insert into @ttLF select  'ReceiverStatusDesc', null,   null,   null,          null, null
insert into @ttLF select  'BoLNumber',          null,   null,   null,          null, null
insert into @ttLF select  'Container',          null,   null,   null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;


/********************************************************************************/
/* Layout for GridLookUpCombo for Receipt Number selection */
select @ContextName = 'UserControl.SelectReceiptNumber';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectReceiptNumber */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field                Visible Visible Field          Width Display
                          Name                 Index           Caption              Format */
insert into @ttLF select  'ReceiptId',         null,   null,   null,          null, null
insert into @ttLF select  'ReceiptNumber',     null,   null,   null,           100, null
insert into @ttLF select  'ReceiptType',       null,      1,   'Type',          90, null
insert into @ttLF select  'ReceiptTypeDesc',   null,     -1,   'Type',          90, null
insert into @ttLF select  'StatusDescription', null,   null,   null,            80, null
insert into @ttLF select  'QtyToReceive',      null,   null,   null,            85, null
insert into @ttLF select  'UnitsInTransit',    null,   null,   null,            80, null
insert into @ttLF select  'UnitsReceived',     null,   null,   null,            80, null
insert into @ttLF select  'NumLPNs',           null,   null,   null,            70, null
insert into @ttLF select  'LPNsInTransit',     null,   null,   null,            80, null
insert into @ttLF select  'LPNsReceived',      null,   null,   null,           100, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;


/********************************************************************************/
/* Layout for GridLookUpCombo for Receipt Detail  selection */
select @ContextName = 'UserControl.SelectReceiptDetail';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectReceiptDetail */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field                Visible Visible Field          Width Display
                          Name                 Index           Caption              Format */
insert into @ttLF select  'SKU',               null,   1,      null,          null, null
insert into @ttLF select  'QtyOrdered',        null,   1,      null,          null, null
insert into @ttLF select  'QtyInTransit',      null,   1,      null,          null, null
insert into @ttLF select  'QtyReceived',       null,   1,      null,          null, null
insert into @ttLF select  'QtyToReceive',      null,   1,      null,          null, null
insert into @ttLF select  'QtyToLabel',        null,   1,      null,          null, null
insert into @ttLF select  'LPNsReceived',      null,   1,      null,          null, null
insert into @ttLF select  'LPNsInTransit',     null,   1,      null,          null, null
insert into @ttLF select  'ExtraQtyAllowed',   null,   1,      null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for CartonType selection */
select @ContextName = 'UserControl.SelectCartonType';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectCartonType */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select  'CartonType',       null,   1,      null,          null, null
insert into @ttLF select  'Description',      null,   1,      null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for CartonType selection */
select @ContextName = 'UserControl.SelectLocation';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectLocation */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select  'Location',         null,   1,      null,          null, null
insert into @ttLF select  'Warehouse',        null,   1,      null,          null, null
insert into @ttLF select  'LocationTypeDesc', null,   1,      null,          null, null
insert into @ttLF select  'PutawayZoneDesc',  null,  -1,      null,          null, null
insert into @ttLF select  'PickZoneDesc',     null,  -1,      null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for CartonType selection */
select @ContextName = 'UserControl.WaveDropLocation';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.WaveDropLocation */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select  'Location',         null,   1,      null,          null, null
insert into @ttLF select  'Warehouse',        null,   1,      null,          null, null
insert into @ttLF select  'LocationTypeDesc', null,   1,      null,          null, null
insert into @ttLF select  'PutawayZoneDesc',  null,   1,      null,          null, null
insert into @ttLF select  'PickZoneDesc',     null,   1,      null,          null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for BillToAddressId selection */
select @ContextName = 'UserControl.SelectAddress';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectAddress */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select  'ContactId',        null,  -3,      null,          null, null
insert into @ttLF select  'ContactRefId',     null,   1,      null,          50,   null
insert into @ttLF select  'Name',             null,   1,      null,          100,  null
insert into @ttLF select  'AddressLine1',     null,   1,      null,          200,  null
insert into @ttLF select  'City',             null,   1,      null,          120,  null
insert into @ttLF select  'State',            null,   1,      null,          50,   null
insert into @ttLF select  'Zip',              null,   1,      null,          40,   null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

/********************************************************************************/
/* Layout for GridLookUpCombo for simple address selection selection. In most
   cases user is selecting based upon name and city/state  */
select @ContextName = 'UserControl.SelectAddressBrief';
delete from @Layouts;

/*------------------------------------------------------------------------------*/
/* UserControl.SelectAddressBrief */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 'A',   null,   0,      'Y'

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;
/*                        Field               Visible Visible Field          Width Display
                          Name                Index           Caption              Format */
insert into @ttLF select  'ContactId',        null,  -3,      null,          null, null
insert into @ttLF select  'ContactRefId',     null,   1,      null,          50,   null
insert into @ttLF select  'Name',             null,   1,      null,          100,  null
insert into @ttLF select  'AddressLine1',     null,  -1,      null,          200,  null
insert into @ttLF select  'CityState',        null,   1,      null,          120,  null
insert into @ttLF select  'City',             null,   1,      null,          80,   null
insert into @ttLF select  'State',            null,  -1,      null,          50,   null
insert into @ttLF select  'Zip',              null,  -1,      null,          40,   null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF;

Go
