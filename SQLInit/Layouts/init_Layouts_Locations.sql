/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/04  AJM     Added LocationClass, IsReplenishable, PolicyCompliant (CIMSV3-1334)
  2020/04/25  SAK     Added Fileld LocationSubTypeDesc and changed Visablity (HA-263)
  2020/04/03  AY      Forcing fields to be visible in summary layouts is causing exception (JL-186)
  2020/03/11  MS      Added LocationStatus,LocationStatusDesc and Missingfields (CIMSV3-749)
  2019/12/06  MJ      Added AllowedOperations field (CIMSV3-504)
  2019/05/14  RBV     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2017/12/07  CK      Added MaxPallets,MaxLPNs,MaxInnerPacks,MaxUnits,MaxVolume,MaxWeight (CIMS-1749)
  2017/09/29  YJ      pr_Setup_Layout: Change to setup Layouts using procedure (CIMSV3-73)
  2017/09/26  AY      Removed Empty/Unassigned Locations layouts as they are more of filters in V3
  2017/09/14  CK      Added return TrackingNo (CIMSV3-41)
                      Initial revision.
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

select @ContextName = 'List.Locations',
       @DataSetName = 'vwLocations';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default          Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                     */
insert into @Layouts select 'L',    'Y',     'Standard',                   null,            null,  null,   0,      null
insert into @Layouts select 'L',    'N',     'Picklanes',                  'PicklanesOnly', null,  null,   0,      null

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
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'LocationType',                null,     -2,   null,               null, null
insert into @ttLF select 'LocationTypeDesc',            null,      1,   null,               null, null
insert into @ttLF select 'LocationSubType',             null,     -2,   null,               null, null
insert into @ttLF select 'LocationSubTypeDesc',         null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,     -2,   null,               null, null
insert into @ttLF select 'StorageTypeDesc',             null,      1,   null,               null, null
insert into @ttLF select 'LocationStatus',              null,     -2,   null,               null, null
insert into @ttLF select 'LocationStatusDesc',          null,      1,   null,               null, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,     -2,   null,               null, null

insert into @ttLF select 'LocationRow',                 null,   null,   null,               null, null
insert into @ttLF select 'LocationBay',                 null,   null,   null,               null, null
insert into @ttLF select 'LocationSection',             null,   null,   null,               null, null
insert into @ttLF select 'LocationLevel',               null,   null,   null,               null, null

insert into @ttLF select 'NumPallets',                  null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'InnerPacks',                  null,   null,   '# Cases',          null, null
insert into @ttLF select 'Quantity',                    null,   null,   '# Units',          null, null
insert into @ttLF select 'Volume',                      null,     -2,   null,               null, null
insert into @ttLF select 'Weight',                      null,     -2,   null,               null, null

insert into @ttLF select 'SKU',                         null,     -1,   null,               null, null
insert into @ttLF select 'SKUId',                       null,     -2,   null,               null, null

insert into @ttLF select 'MinReplenishLevel',           null,     -1,   null,               null, null
insert into @ttLF select 'MaxReplenishLevel',           null,     -1,   null,               null, null
insert into @ttLF select 'ReplenishUoM',                null,     -2,   null,               null, null
insert into @ttLF select 'ReplenishUoMDesc',            null,     -1,   null,               null, null

insert into @ttLF select 'PutawayZone',                 null,     -2,   null,               null, null
insert into @ttLF select 'PutawayZoneDesc',             null,      1,   null,               null, null
insert into @ttLF select 'PutawayZoneDisplayDesc',      null,     -2,   null,               null, null
insert into @ttLF select 'PickingZone',                 null,     -2,   null,               null, null
insert into @ttLF select 'PickingZoneDesc',             null,      1,   null,               null, null
insert into @ttLF select 'PickingZoneDisplayDesc',      null,     -2,   null,               null, null

insert into @ttLF select 'PutawayPath',                 null,   null,   null,               null, null
insert into @ttLF select 'PickPath',                    null,   null,   null,               null, null
insert into @ttLF select 'AllowMultipleSKUs',           null,     -1,   null,               null, null
insert into @ttLF select 'IsReplenishable',             null,     -1,   null,               null, null
insert into @ttLF select 'AllowedOperations',           null,   null,   null,               null, null
insert into @ttLF select 'PrevAllowedOperations',       null,   null,   null,               null, null
insert into @ttLF select 'LocationClass',               null,   null,   null,               null, null
insert into @ttLF select 'LocationABCClass',            null,   null,   null,               null, null
insert into @ttLF select 'PolicyCompliant',             null,   null,   null,               null, null

insert into @ttLF select 'WarehouseDesc',               null,   null,   null,               null, null
insert into @ttLF select 'LastCycleCounted',            null,   null,   null,               null, null
insert into @ttLF select 'LocationVerified',            null,   null,   null,               null, null
insert into @ttLF select 'LastVerified',                null,   null,   null,               null, null

insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Barcode',                     null,     -1,   null,               null, null

insert into @ttLF select 'MaxPallets',                  null,     -1,   null,               null, null
insert into @ttLF select 'MaxLPNs',                     null,     -1,   null,               null, null
insert into @ttLF select 'MaxInnerpacks',               null,     -1,   null,               null, null
insert into @ttLF select 'MaxUnits',                    null,     -1,   null,               null, null
insert into @ttLF select 'MaxVolume',                   null,     -1,   null,               null, null
insert into @ttLF select 'MaxWeight',                   null,     -1,   null,               null, null

insert into @ttLF select 'LOC_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'LOC_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'LOC_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'LOC_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'LOC_UDF5',                    null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF5',                  null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'LocationId;Location'/* Key fields */;

/******************************************************************************/
/* Picklanes Layout */
/******************************************************************************/
delete from @ttLF;
/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'LocationId',                  null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'LocationType',                null,     -2,   null,               null, null
insert into @ttLF select 'LocationTypeDesc',            null,     -1,   null,               null, null
insert into @ttLF select 'LocationSubType',             null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,     -2,   null,               null, null
insert into @ttLF select 'StorageTypeDesc',             null,      1,   null,               null, null
insert into @ttLF select 'LocationStatus',              null,     -2,   null,               null, null
insert into @ttLF select 'LocationStatusDesc',          null,      1,   null,               null, null
insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'StatusDescription',           null,     -2,   null,               null, null

insert into @ttLF select 'LocationRow',                 null,     -1,   null,               null, null
insert into @ttLF select 'LocationBay',                 null,     -1,   null,               null, null
insert into @ttLF select 'LocationSection',             null,     -1,   null,               null, null
insert into @ttLF select 'LocationLevel',               null,     -1,   null,               null, null

insert into @ttLF select 'NumPallets',                  null,     -1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   '# SKUs',           null, null
insert into @ttLF select 'InnerPacks',                  null,   null,   '# Cases',          null, null
insert into @ttLF select 'Quantity',                    null,   null,   '# Units',          null, null

insert into @ttLF select 'MinReplenishLevel',           null,      1,   null,               null, null
insert into @ttLF select 'MaxReplenishLevel',           null,      1,   null,               null, null
insert into @ttLF select 'ReplenishUoM',                null,     -2,   null,               null, null
insert into @ttLF select 'ReplenishUoMDesc',            null,      1,   null,               null, null
insert into @ttLF select 'AllowMultipleSKUs',           null,      1,   null,               null, null

insert into @ttLF select 'PutawayZone',                 null,     -2,   null,               null, null
insert into @ttLF select 'PutawayZoneDesc',             null,      1,   null,               null, null
insert into @ttLF select 'PutawayZoneDisplayDesc',      null,     -2,   null,               null, null
insert into @ttLF select 'PickingZone',                 null,     -2,   null,               null, null
insert into @ttLF select 'PickingZoneDesc',             null,      1,   null,               null, null
insert into @ttLF select 'PickingZoneDisplayDesc',      null,     -2,   null,               null, null

insert into @ttLF select 'PutawayPath',                 null,   null,   null,               null, null
insert into @ttLF select 'PickPath',                    null,   null,   null,               null, null
insert into @ttLF select 'WarehouseDesc',               null,   null,   null,               null, null
insert into @ttLF select 'LastCycleCounted',            null,   null,   null,               null, null
insert into @ttLF select 'LocationVerified',            null,   null,   null,               null, null
insert into @ttLF select 'LastVerified',                null,   null,   null,               null, null

insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Barcode',                     null,     -2,   null,               null, null

insert into @ttLF select 'LOC_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'LOC_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'LOC_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'LOC_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'LOC_UDF5',                    null,   null,   null,               null, null


insert into @ttLF select 'vwLoc_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwLoc_UDF5',                  null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Picklanes', @ttLF, @DataSetName, 'LocationId;Location';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Pick Zone';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'PickingZoneDesc',            null,      1,   null,               null, null,    null
insert into @ttLFE select 'Location',                   null,      1,   null,               null, null,    'Count'
insert into @ttLFE select 'NumPallets',                 null,      1,   null,               null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',                    null,      1,   null,               null, null,    'Sum'
insert into @ttLFE select 'InnerPacks',                 null,      1,   null,               null, null,    'Sum'
insert into @ttLFE select 'Quantity',                   null,      1,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Putaway Zone';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'PutawayZoneDesc',            null,      1,   null,               null, null,    null
insert into @ttLFE select 'Location',                   null,      1,   null,               null, null,    'Count'
insert into @ttLFE select 'NumPallets',                 null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',                    null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'InnerPacks',                 null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'Quantity',                   null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Row/Type';
delete from @ttLFE;

/*                         Field                         Visible Visible Field               Width Display  Aggregate
                           Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'LocationRow',                 null,      1,   null,               null, null,    null
insert into @ttLFE select 'LocationTypeDesc',            null,      1,   null,               null, null,    null
insert into @ttLFE select 'StorageTypeDesc',             null,      1,   null,               null, null,    null
insert into @ttLFE select 'Location',                    null,   null,   null,               null, null,    'Count'
insert into @ttLFE select 'NumPallets',                  null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'NumLPNs',                     null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'InnerPacks',                  null,   null,   null,               null, null,    'Sum'
insert into @ttLFE select 'Quantity',                    null,   null,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
/*                        FieldName,           SummaryType, DisplayFormat,           AggregateMethod */
insert into @ttLSF select 'Location',          'Count',     '# Locs: {0:n0}',         null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* Layout description */, @ttLSF;

Go
