/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/17  SRS      Initial Revision (BK-764).
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

select @ContextName = 'List.LocationReplenishLevels',
       @DataSetName = 'vwLocationReplenishLevels';

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

insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'InventoryKey',                null,   null,   null,               null, null

insert into @ttLF select 'MinReplenishLevel',           null,      1,   null,               null, null
insert into @ttLF select 'MaxReplenishLevel',           null,      1,   null,               null, null
insert into @ttLF select 'ReplenishUoM',                null,      1,   null,               null, null
insert into @ttLF select 'IsReplenishable',             null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,      1,   null,               null, null

insert into @ttLF select 'SV_PrevWeek',                 null,   null,   null,               null, null
insert into @ttLF select 'SV_Prev2Week',                null,   null,   null,               null, null
insert into @ttLF select 'SV_PrevMonth',                null,   null,   null,               null, null
insert into @ttLF select 'SV_Prev2Month',               null,   null,   null,               null, null
insert into @ttLF select 'SV_PrevQuarter',              null,   null,   null,               null, null
insert into @ttLF select 'SV_Prev2Quarter',             null,   null,   null,               null, null

insert into @ttLF select 'PV_PrevWeek',                 null,   null,   null,               null, null
insert into @ttLF select 'PV_Prev2Week',                null,   null,   null,               null, null
insert into @ttLF select 'PV_PrevMonth',                null,   null,   null,               null, null
insert into @ttLF select 'PV_Prev2Month',               null,   null,   null,               null, null
insert into @ttLF select 'PV_PrevQuarter',              null,   null,   null,               null, null
insert into @ttLF select 'PV_Prev2Quarter',             null,   null,   null,               null, null

insert into @ttLF select 'LOCRL_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'LOCRL_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'LOCRL_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'LOCRL_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'LOCRL_UDF5',                  null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Deprecated fields */

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;RecordId' /* Key fields */;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                SummaryType, DisplayFormat,         AggregateMethod */
insert into @ttLSF select 'Location',               'DCount',    '# Locations: {0:n0}', null
insert into @ttLSF select 'SKU',                    'DCount',    '# SKUs: {0:n0}',      null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* LayoutDescription */, @ttLSF;

Go
