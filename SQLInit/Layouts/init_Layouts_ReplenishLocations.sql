/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/21  MS      Modified Dataset (BK-302)
  2020/10/08  MRK     Added missing fields (HA-1430)
  2020/06/23  SJ      Added Status,StatusDesc,LocationStatus,LocationStatusDesc (HA-936)
  2020/06/16  TK      Added InventoryClasses (HA-938)
  2020/06/15  SJ      Changed visible for LocationType,LocationSubType,StorageType,Status Desc fields (HA-936)
  2020/06/12  NB      set DatasetName to vwLocationsToReplenish.This is a  temp fix for Actions
                        in Manage Replenishment to work (HA-372)
  2020/05/04  VS      Made changes to show the grid in V3 application (HA-368)
  2016/02/23  TK      Added Ownership field (NBD-175)
  2015/12/17  TK      Added MinMax ReplenishLevelUnits (ACME-419)
  2015/02/27  YJ      set visible -2 for InnerPacks, PercentFull
  2104/06/10  TK      Corrected alignment of the fields and removed extra spaces
  2014/06/06  TK      Initial revision.
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

select @ContextName = 'List.ReplenishmentLocations',
       @DataSetName = 'pr_UI_DS_LocationsToReplenish';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Standard Layout */
/*----------------------------------------------------------------------------*/
/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'LocationType',                null,   null,   null,               null, null
insert into @ttLF select 'LocationTypeDesc',            null,   null,   null,               null, null
insert into @ttLF select 'LocationSubType',             null,   null,   null,               null, null
insert into @ttLF select 'LocationSubTypeDesc',         null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,   null,   null,               null, null
insert into @ttLF select 'StorageTypeDesc',             null,   null,   null,               null, null
insert into @ttLF select 'LocationStatus',              null,   null,   null,               null, null
insert into @ttLF select 'LocationStatusDesc',          null,   null,   null,               null, null
insert into @ttLF select 'LocationRow',                 null,   null,   null,               null, null
insert into @ttLF select 'ReplenishType',               null,   null,   null,               null, null
insert into @ttLF select 'ReplenishTypeDesc',           null,     -1,   null,               null, null
insert into @ttLF select 'LocationLevel',               null,     -1,   null,               null, null
insert into @ttLF select 'LocationSection',             null,     -1,   null,               null, null
insert into @ttLF select 'PutawayZone',                 null,     -1,   null,               null, null
insert into @ttLF select 'PickZone',                    null,      1,   null,               null, null

insert into @ttLF select 'LPNId',                       null,     -3,   null,               null, null
insert into @ttLF select 'LPN',                         null,     -1,   null,               null, null
insert into @ttLF select 'InventoryClass1',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass2',             null,   null,   null,               null, null
insert into @ttLF select 'InventoryClass3',             null,   null,   null,               null, null

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'InnerPacks',                  null,   null,   'Curr Cases',       null, null
insert into @ttLF select 'Quantity',                    null,   null,   'Curr Units',       null, null
insert into @ttLF select 'UnitsPerInnerPack',           null,   null,   null,               null, null
insert into @ttLF select 'InnerPacksPerLPN',            null,   null,   null,               null, null
insert into @ttLF select 'UnitsPerLPN',                 null,   null,   null,               null, null
insert into @ttLF select 'MinReplenishLevel',           null,   null,   null,               null, null

insert into @ttLF select 'MinReplenishLevelDesc',       null,      1,   null,               null, null
insert into @ttLF select 'MinReplenishLevelUnits',      null,     -1,   null,               null, null
insert into @ttLF select 'MinReplenishLevelInnerPacks', null,   null,   null,               null, null
insert into @ttLF select 'MaxReplenishLevel',           null,     -1,   null,               null, null
insert into @ttLF select 'MaxReplenishLevelDesc',       null,      1,   null,               null, null
insert into @ttLF select 'MaxReplenishLevelUnits',      null,     -1,   null,               null, null
insert into @ttLF select 'MaxReplenishLevelInnerPacks', null,   null,   null,               null, null
insert into @ttLF select 'ReplenishUoM',                null,     -1,   null,               null, null

insert into @ttLF select 'PercentFull',                 null,     -2,   null,               null, null

insert into @ttLF select 'MinToReplenish',              null,   null,   null,               null, null
insert into @ttLF select 'MinToReplenishDesc',          null,   null,   null,               null, null
insert into @ttLF select 'MinUnitsToReplenish',         null,   null,   null,               null, null
insert into @ttLF select 'MinIPsToReplenish',           null,   null,   null,               null, null

insert into @ttLF select 'MaxToReplenish',              null,   null,   null,               null, null
insert into @ttLF select 'MaxToReplenishDesc',          null,   null,   null,               null, null
insert into @ttLF select 'MaxUnitsToReplenish',         null,   null,   null,               null, null
insert into @ttLF select 'MaxIPsToReplenish',           null,   null,   null,               null, null

insert into @ttLF select 'UnitsInProcess',              null,      1,   null,               null, null
insert into @ttLF select 'OrderedUnits',                null,     -1,   null,               null, null
insert into @ttLF select 'ResidualUnits',               null,     -1,   null,               null, null

insert into @ttLF select 'ProdCategory',                null,     -1,   null,               null, null
insert into @ttLF select 'ProdSubCategory',             null,     -1,   null,               null, null

insert into @ttLF select 'UniqueId',                    null,     -3,   null,               null, null
insert into @ttLF select 'AllowedOperations',           null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, ';UniqueId' /* Key fields */;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                SummaryType, DisplayFormat,         AggregateMethod */
insert into @ttLSF select 'Location',               'DCount',    '# Locations: {0:n0}', null
insert into @ttLSF select 'SKU',                    'DCount',    '# SKUs: {0:n0}',      null
insert into @ttLSF select 'MinToReplenish',         'Sum',       '{0:n0}',              null
insert into @ttLSF select 'MaxToReplenish',         'Sum',       '{0:n0}',              null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* LayoutDescription */, @ttLSF;

Go
