/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/29  VS     Added UnitsRequiredtoActivate, UnitsReservedForWave, ToActivateShipCartonQty (HA-2714)
  2021/01/19  PKK    Corrected the file as per the template(CIMSV3-1282)
  2020/12/01  SJ     Added Layout for Contractor Waves  (HA-1693)
  2020/05/24  NB     Initial revision(HA-101)
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

select @ContextName = 'List.WaveSummary',
       @DataSetName = 'pr_UI_DS_WaveSummary';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Contractor Waves',              null,                 null,  null,   0,      null

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
insert into @ttLF select 'RecordId',                    null,     -1,   null,               null, null
insert into @ttLF select 'BatchNo',                     null,     -1,   null,               null, null
insert into @ttLF select 'Line',                        null,     -1,   null,               null, null

insert into @ttLF select 'ShipToStore',                 null,     -1,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,     -1,   null,               null, null
insert into @ttLF select 'CustPO',                      null,     -1,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,     -1,   null,               null, null
insert into @ttLF select 'Description',                 null,   null,   null,                250, null

insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null
insert into @ttLF select 'NewSKU',                      null,     -1,   null,               null, null
insert into @ttLF select 'NewInventoryClass1',          null,     -1,   null,               null, null
insert into @ttLF select 'NewInventoryClass2',          null,     -1,   null,               null, null
insert into @ttLF select 'NewInventoryClass3',          null,     -1,   null,               null, null

insert into @ttLF select 'UnitsOrdered',                null,      1,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,               null, null
insert into @ttLF select 'UnitsPreAllocated',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'UnitsNeeded',                 null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable',              null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_UPicklane',    null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_PPicklane',    null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_Reserve',      null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_Bulk',         null,     -2,   null,               null, null
insert into @ttLF select 'UnitsAvailable_RB',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_Other',        null,   null,   null,               null, null
insert into @ttLF select 'UnitsShort_UPicklane',        null,   null,   null,               null, null
insert into @ttLF select 'UnitsShort_PPicklane',        null,   null,   null,               null, null
insert into @ttLF select 'UnitsShort_Other',            null,   null,   null,               null, null
insert into @ttLF select 'UnitsShort',                  null,   null,   null,               null, null

insert into @ttLF select 'CasesAvailable',              null,   null,   null,               null, null
insert into @ttLF select 'CasesAvailable_PPicklane',    null,   null,   null,               null, null
insert into @ttLF select 'CasesAvailable_Reserve',      null,   null,   null,               null, null
insert into @ttLF select 'CasesAvailable_Bulk',         null,     -2,   null,               null, null
insert into @ttLF select 'CsaesAvailable_RB',           null,   null,   null,               null, null
insert into @ttLF select 'CasesAvailable_Other',        null,   null,   null,               null, null
insert into @ttLF select 'CasesShort_PPicklane',        null,   null,   null,               null, null
insert into @ttLF select 'CasesShort_Other',            null,   null,   null,               null, null
insert into @ttLF select 'CasesShort',                  null,   null,   null,               null, null
insert into @ttLF select 'UnitsReservedForWave',        null,   null,   null,               null, null
insert into @ttLF select 'ToActivateShipCartonQty',     null,   null,   null,               null, null
insert into @ttLF select 'UnitsRequiredtoActivate',     null,   null,   null,               null, null

insert into @ttLF select 'UnitsPicked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPacked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsLoaded',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsLabeled',                null,     -1,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,     -1,   null,               null, null

insert into @ttLF select 'CasesOrdered',                null,   null,   null,               null, null
insert into @ttLF select 'CasesToShip',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesPreAllocated',           null,   null,   null,               null, null
insert into @ttLF select 'CasesAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'CasesNeeded',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesPicked',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesPacked',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesLabeled',                null,   null,   null,               null, null
insert into @ttLF select 'CasesStaged',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesLoaded',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesShipped',                null,   null,   null,               null, null

insert into @ttLF select 'UnitsPercarton',              null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,      1,   null,               null, null

insert into @ttLF select 'LPNsOrdered',                 null,     -1,   null,               null, null
insert into @ttLF select 'LPNsToShip',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,               null, null
insert into @ttLF select 'LPNsNeeded',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsAvailable',               null,     -1,   null,               null, null
insert into @ttLF select 'LPNsShort',                   null,     -1,   null,               null, null
insert into @ttLF select 'LPNsPicked',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsPacked',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsLabeled',                 null,     -1,   null,               null, null
insert into @ttLF select 'LPNsShipped',                 null,     -1,   null,               null, null
insert into @ttLF select 'LPNsStaged',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsLoaded',                  null,     -1,   null,               null, null

insert into @ttLF select 'PrimaryLocation',             null,      1,   null,               null, null
insert into @ttLF select 'SecondaryLocation',           null,      1,   null,               null, null

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailId',               null,   null,   null,               null, null
insert into @ttLF select 'HostOrderLine',               null,     -1,   null,               null, null

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

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* KeyFields */;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Contractor Waves Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format **/
insert into @ttLF select 'RecordId',                    null,     -1,   null,               null, null
insert into @ttLF select 'BatchNo',                     null,     -1,   null,               null, null
insert into @ttLF select 'Line',                        null,     -1,   null,               null, null

insert into @ttLF select 'ShipToStore',                 null,   null,   null,               null, null
insert into @ttLF select 'CustSKU',                     null,     -1,   null,               null, null
insert into @ttLF select 'CustPO',                      null,     -1,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'UPC',                         null,     -1,   null,               null, null
insert into @ttLF select 'Description',                 null,   null,   null,                250, null

-- New SKU & New IC are the key elements for contractor waves
insert into @ttLF select 'NewSKU',                      null,      1,   null,               null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null
insert into @ttLF select 'NewInventoryClass1',          null,      1,   null,               null, null
insert into @ttLF select 'NewInventoryClass2',          null,   null,   null,               null, null
insert into @ttLF select 'NewInventoryClass3',          null,   null,   null,               null, null

insert into @ttLF select 'UnitsOrdered',                null,      1,   null,               null, null
insert into @ttLF select 'UnitsAuthorizedToShip',       null,   null,   null,               null, null
insert into @ttLF select 'UnitsPreAllocated',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'UnitsNeeded',                 null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable',              null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_UPicklane',    null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_PPicklane',    null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_Reserve',      null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_Bulk',         null,     -2,   null,               null, null
insert into @ttLF select 'UnitsAvailable_RB',           null,   null,   null,               null, null
insert into @ttLF select 'UnitsAvailable_Other',        null,   null,   null,               null, null
insert into @ttLF select 'UnitsShort_UPicklane',        null,   null,   null,               null, null
insert into @ttLF select 'UnitsShort_PPicklane',        null,   null,   null,               null, null
insert into @ttLF select 'UnitsShort_Other',            null,   null,   null,               null, null
insert into @ttLF select 'UnitsShort',                  null,   null,   null,               null, null

insert into @ttLF select 'UnitsReservedForWave',        null,     -1,   null,               null, null
insert into @ttLF select 'ToActivateShipCartonQty',     null,     -1,   null,               null, null
insert into @ttLF select 'UnitsRequiredtoActivate',     null,      1,   null,               null, null

insert into @ttLF select 'CasesAvailable',              null,   null,   null,               null, null
insert into @ttLF select 'CasesAvailable_PPicklane',    null,   null,   null,               null, null
insert into @ttLF select 'CasesAvailable_Reserve',      null,   null,   null,               null, null
insert into @ttLF select 'CasesAvailable_Bulk',         null,     -2,   null,               null, null
insert into @ttLF select 'CsaesAvailable_RB',           null,   null,   null,               null, null
insert into @ttLF select 'CasesAvailable_Other',        null,   null,   null,               null, null
insert into @ttLF select 'CasesShort_PPicklane',        null,   null,   null,               null, null
insert into @ttLF select 'CasesShort_Other',            null,   null,   null,               null, null
insert into @ttLF select 'CasesShort',                  null,   null,   null,               null, null

insert into @ttLF select 'UnitsPicked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPacked',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsLoaded',                 null,     -1,   null,               null, null
insert into @ttLF select 'UnitsLabeled',                null,     -1,   null,               null, null
insert into @ttLF select 'UnitsShipped',                null,     -1,   null,               null, null

insert into @ttLF select 'CasesOrdered',                null,   null,   null,               null, null
insert into @ttLF select 'CasesToShip',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesPreAllocated',           null,   null,   null,               null, null
insert into @ttLF select 'CasesAssigned',               null,   null,   null,               null, null
insert into @ttLF select 'CasesNeeded',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesPicked',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesPacked',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesLabeled',                null,   null,   null,               null, null
insert into @ttLF select 'CasesStaged',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesLoaded',                 null,   null,   null,               null, null
insert into @ttLF select 'CasesShipped',                null,   null,   null,               null, null

insert into @ttLF select 'UnitsPercarton',              null,     -1,   null,               null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,      1,   null,               null, null

insert into @ttLF select 'LPNsOrdered',                 null,     -1,   null,               null, null
insert into @ttLF select 'LPNsToShip',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsAssigned',                null,     -1,   null,               null, null
insert into @ttLF select 'LPNsNeeded',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsAvailable',               null,     -1,   null,               null, null
insert into @ttLF select 'LPNsShort',                   null,     -1,   null,               null, null
insert into @ttLF select 'LPNsPicked',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsPacked',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsLabeled',                 null,     -1,   null,               null, null
insert into @ttLF select 'LPNsShipped',                 null,     -1,   null,               null, null
insert into @ttLF select 'LPNsStaged',                  null,     -1,   null,               null, null
insert into @ttLF select 'LPNsLoaded',                  null,     -1,   null,               null, null

insert into @ttLF select 'PrimaryLocation',             null,      1,   null,               null, null
insert into @ttLF select 'SecondaryLocation',           null,      1,   null,               null, null

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'OrderDetailId',               null,   null,   null,               null, null
insert into @ttLF select 'HostOrderLine',               null,     -1,   null,               null, null

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

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Contractor Waves', @ttLF, @DataSetName, 'RecordId;' /* KeyFields */;

Go
