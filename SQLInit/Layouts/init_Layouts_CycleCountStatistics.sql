/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/17  AY      Added AbsUnitsChange & Summary Fields (HA-3093)
  2021/03/13  SK      Minor changes required for statistics page (HA-2270)
  2021/03/11  OK      Added UniqueId (HA-2248)
  2021/03/11  SAK     Added TaskSubType,TaskSubTypeDesc,AbsPercentUnitsChange and other (HA-2247)
  2021/01/19  PKK     Corrected the file as per the template(CIMSV3-1282)
  2020/09/11  KBB     Added PrevQuantity, NewQuantity Fields.
                      Updated Visibility on PickZone (HA-1406)
  2020/09/02  SK      Reorder and revamp based on the data source for this page (CIMSV3-1066, CIMSV3-1026)
  2020/06/26  NB      Added Warehouse (CIMSV3-988)
  2019/03/24  RIA     Initial revision
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

select @ContextName = 'List.CycleCountStatistics',
       @DataSetName = 'pr_CycleCount_DS_GetResults';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                      */
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
insert into @ttLF select 'BatchNo',                     null,   null,   'Batch No',         null, null
insert into @ttLF select 'TaskId',                      null,     -1,   null,               null, null
insert into @ttLF select 'TaskDetailId',                null,     -1,   null,               null, null
insert into @ttLF select 'TaskSubType',                 null,   null,   null,               null, null
insert into @ttLF select 'TaskSubTypeDesc',             null,   null,   'Type',             null, null
insert into @ttLF select 'TaskDesc',                    null,   null,   null,               null, null
insert into @ttLF select 'TransactionDate',             null,     -1,   null,               null, null
insert into @ttLF select 'TransactionTime',             null,   null,   null,               null, null

insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'LocationType',                null,   null,   null,               null, null
insert into @ttLF select 'LocationTypeDesc',            null,   null,   null,               null, null
insert into @ttLF select 'StorageTypeDesc',             null,     -1,   null,               null, null

insert into @ttLF select 'PutawayClass',                null,   null,   null,               null, null
insert into @ttLF select 'PutawayZone',                 null,     -1,   null,               null, null
insert into @ttLF select 'PickZone',                    null,     -1,   null,               null, null

insert into @ttLF select 'PrevInnerPacks',              null,     -1,   null,               null, null
insert into @ttLF select 'NewInnerPacks',               null,     -1,   null,               null, null
insert into @ttLF select 'InnerPacksChange',            null,     -1,   null,               null, null
insert into @ttLF select 'PercentIPChange',             null,     -1,   null,               null, null
insert into @ttLF select 'IPAccuracy',                  null,     -1,   null,               null, null

insert into @ttLF select 'PrevQuantity',                null,   null,   null,               null, null
insert into @ttLF select 'NewQuantity',                 null,   null,   null,               null, null

insert into @ttLF select 'PreviousUnits',               null,   null,   null,               null, null
insert into @ttLF select 'NewUnits',                    null,   null,   null,               null, null
insert into @ttLF select 'UnitsChange',                 null,   null,   null,               null, null
insert into @ttLF select 'AbsUnitsChange',              null,   null,   null,               null, null
insert into @ttLF select 'PercentUnitsChange',          null,   null,   null,               null, null
insert into @ttLF select 'UnitsAccuracy',               null,   null,   null,               null, null
insert into @ttLF select 'AbsPercentUnitsChange',       null,   null,   null,               null, null

insert into @ttLF select 'PrevLPNs',                    null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   'New LPNs',         null, null
insert into @ttLF select 'LPNsChange',                  null,   null,   null,               null, null

insert into @ttLF select 'PreviousNumSKUs',             null,   null,   null,               null, null
insert into @ttLF select 'NewNumSKUs',                  null,   null,   null,               null, null
insert into @ttLF select 'SKUsChange',                  null,   null,   null,               null, null
insert into @ttLF select 'PercentSKUsChange',           null,   null,   null,               null, null
insert into @ttLF select 'SKUsAccuracy',                null,   null,   null,               null, null

insert into @ttLF select 'OldValue',                    null,   null,   null,               null, null
insert into @ttLF select 'NewValue',                    null,   null,   null,               null, null
insert into @ttLF select 'ValueChange',                 null,   null,   null,               null, null

insert into @ttLF select 'Count1',                      null,     -1,   'Change in Units',  null, null
insert into @ttLF select 'Count2',                      null,   null,   null,               null, null
insert into @ttLF select 'Count3',                      null,   null,   null,               null, null
insert into @ttLF select 'Count4',                      null,   null,   null,               null, null
insert into @ttLF select 'Count5',                      null,   null,   null,               null, null

insert into @ttLF select 'CCV_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'CCV_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'CCV_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'CCV_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'CCV_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'CountVariance',               null,   null,   null,               null, null
insert into @ttLF select 'SKUVariance',                 null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'Ownership',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null

insert into @ttLF select 'vwCCR_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF5',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF6',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF7',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF8',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF9',                  null,   null,   null,               null, null
insert into @ttLF select 'vwCCR_UDF10',                 null,   null,   null,               null, null

insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null

insert into @ttLF select 'UniqueId',                    null,     -3,   null,               null, null

/* Un-used for now
insert into @ttLF select 'StorageType',       null,   null,   null,   null, null
insert into @ttLF select 'Archived',          null,   null,   null,   null, null
*/

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, ';UniqueId' /* KeyFields */;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'BatchNo',                    'DCount',    '# Batches: {0:n0}',          null
insert into @ttLSF select 'Location',                   'DCount',    '# Locs: {0:n0}',             null
--insert into @ttLSF select 'UnitsChange',                'Sum',       'Nett: {0:n0}',               null
insert into @ttLSF select 'UnitsAccuracy',              'Avg',       'Avg: {0:0.00}%',             null
insert into @ttLSF select 'SKUsAccuracy',               'Avg',       'Avg: {0:0.00}%',             null
insert into @ttLSF select 'PrevQuantity',               'Sum',       '{0:###,###,##0}',            null
insert into @ttLSF select 'FinalQuantity',              'Sum',       '{0:###,###,##0}',            null
insert into @ttLSF select 'QuantityChange',             'Sum',       '{0:###,###,##0}',            null
insert into @ttLSF select 'AbsQuantityChange',          'Sum',       '{0:###,###,###}',            null
insert into @ttLSF select 'PreviousUnits',              'Sum',       '{0:###,###,##0}',            null
insert into @ttLSF select 'NewUnits',                   'Sum',       '{0:###,###,##0}',            null
insert into @ttLSF select 'UnitsChange',                'Sum',       '{0:###,###,##0}',            null
insert into @ttLSF select 'AbsUnitsChange',             'Sum',       '{0:###,###,###}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* Layout description */, @ttLSF;

Go