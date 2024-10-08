/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/11  KBB     Added Warehouse Field (HA-1406)
  2020/07/16  MS      Initial revision.
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

select @ContextName = 'List.CycleCountLocations',
       @DataSetName = 'pr_CycleCount_DS_GetLocationsToCount';

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
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'LocationType',                null,   null,   null,               null, null
insert into @ttLF select 'LocationTypeDesc',            null,      1,   null,               null, null
insert into @ttLF select 'LocationSubType',             null,   null,   null,               null, null
insert into @ttLF select 'LocationSubTypeDesc',         null,     -1,   null,               null, null
insert into @ttLF select 'StorageType',                 null,   null,   null,               null, null
insert into @ttLF select 'StorageTypeDesc',             null,      1,   null,               null, null
insert into @ttLF select 'LocationStatus',              null,   null,   null,               null, null
insert into @ttLF select 'LocationStatusDesc',          null,   null,   null,               null, null

insert into @ttLF select 'LocationRow',                 null,   null,   null,               null, null
insert into @ttLF select 'LocationLevel',               null,     -1,   null,               null, null
insert into @ttLF select 'LocationSection',             null,     -1,   null,               null, null
insert into @ttLF select 'PutawayZone',                 null,     -1,   null,               null, null
insert into @ttLF select 'PickZone',                    null,     -1,   null,               null, null
insert into @ttLF select 'PutawayZoneDesc',             null,     -1,   null,               null, null
insert into @ttLF select 'PickZoneDesc',                null,      1,   null,               null, null

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU1Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU2Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU3Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU4Desc',                    null,   null,   null,               null, null
insert into @ttLF select 'SKU5Desc',                    null,   null,   null,               null, null

insert into @ttLF select 'NumSKUs',                     null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null
insert into @ttLF select 'LocationABCClass',            null,   null,   null,               null, null
insert into @ttLF select 'LastCycleCounted',            null,   null,   null,               null, null
insert into @ttLF select 'PolicyCompliant',             null,   null,   null,               null, null
insert into @ttLF select 'DaysAfterLastCycleCount',     null,   null,   null,               null, null
insert into @ttLF select 'HasActiveTask',               null,   null,   null,               null, null
insert into @ttLF select 'ScheduledDate',               null,   null,   null,               null, null

insert into @ttLF select 'TaskId',                      null,   null,   null,               null, null
insert into @ttLF select 'BatchNo',                     null,   null,   null,               null, null

insert into @ttLF select 'CC_LocUDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF5',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF6',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF7',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF8',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF9',                  null,   null,   null,               null, null
insert into @ttLF select 'CC_LocUDF10',                 null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'UniqueId',                    null,     -3,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, ';UniqueId' /* Key fields */;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'Location',                   'Count',     '# Locs: {0:n0}',             null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
