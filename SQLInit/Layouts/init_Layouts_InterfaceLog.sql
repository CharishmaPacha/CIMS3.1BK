/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/30  PKK     Corrected the file as per template (CIMSV-1282)
  2020/11/18  KBB     Added Archived field (HA-1309)
  2020/10/12  AY/RKC  Corrected Aggregate method for RecordsPassed and RecordsFailed (CIMSV3-1113)
  2020/10/08  MRK     Added missing fields (HA-1430)
  2020/09/24  RKC     Added By TransferType, By RecordType, By Status Summary layout (CIMSV3-195)
  2020/09/11  AY      Make RecordId selectable if it is visible (HA-1419)
  2020/08/12  MS      Template Correction & Added UDF;s (HA-283)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/04/20  RT      Initial revision (CIMSV3-240)
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

select @ContextName = 'List.InterfaceLog',
       @DataSetName = 'vwInterfaceLog';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

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
insert into @ttLF select 'RecordId',                    null,     11,   null,                 60, null

insert into @ttLF select 'SourceReference',             null,   null,   null,                240, null
insert into @ttLF select 'RecordTypes',                 null,   null,   null,               null, null
insert into @ttLF select 'TransferType',                null,   null,   null,               null, null

insert into @ttLF select 'InterfaceLogStatus',          null,   null,   null,               null, null
insert into @ttLF select 'InterfaceLogStatusDesc',      null,   null,   null,               null, null

insert into @ttLF select 'RecordsProcessed',            null,   null,   null,               null, null
insert into @ttLF select 'RecordsFailed',               null,   null,   null,               null, null
insert into @ttLF select 'RecordsPassed',               null,   null,   null,               null, null

insert into @ttLF select 'StartTime',                   null,   null,   null,               null, null
insert into @ttLF select 'EndTime',                     null,   null,   null,               null, null
insert into @ttLF select 'InputXML',                    null,   null,   null,               null, null
insert into @ttLF select 'HasInputXML',                 null,   null,   null,               null, null
insert into @ttLF select 'AlertSent',                   null,   null,   null,               null, null

insert into @ttLF select 'SourceSystem',                null,     -1,   null,               null, null
insert into @ttLF select 'TargetSystem',                null,     -1,   null,               null, null

insert into @ttLF select 'vwIL_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwIL_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwIL_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwIL_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwIL_UDF5',                   null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'CreatedOn',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Status';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'InterfaceLogStatusDesc',     null,      1,   null,               null, null,    null
insert into @ttLFE select 'SourceSystem',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'TargetSystem',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'RecordTypes',                null,      1,   null,               null, null,    null
insert into @ttLFE select 'TransferType',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'RecordsPassed',              null,      1,   null,               null, null,    'Sum'
insert into @ttLFE select 'RecordsFailed',              null,      1,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by Date';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'CreatedOn',                  null,      1,   null,               null, null,    null
insert into @ttLFE select 'SourceSystem',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'TargetSystem',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'RecordTypes',                null,      1,   null,               null, null,    null
insert into @ttLFE select 'TransferType',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'RecordsPassed',              null,      1,   null,               null, null,    'Sum'
insert into @ttLFE select 'RecordsFailed',              null,      1,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by TransferType';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'TransferType',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'SourceSystem',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'TargetSystem',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'RecordsPassed',              null,      1,   null,               null, null,    'Sum'
insert into @ttLFE select 'RecordsFailed',              null,      1,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Summary by RecordType';
delete from @ttLFE;

/*                        Field                         Visible Visible Field               Width Display  Aggregate
                          Name                          Index           Caption                   Format   Method */
insert into @ttLFE select 'RecordTypes',                null,      1,   null,               null, null,    null
insert into @ttLFE select 'SourceSystem',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'TargetSystem',               null,      1,   null,               null, null,    null
insert into @ttLFE select 'RecordsPassed',              null,      1,   null,               null, null,    'Sum'
insert into @ttLFE select 'RecordsFailed',              null,      1,   null,               null, null,    'Sum'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'RecordId',                   'Count',     '# Records: {0:n0}',          null
insert into @ttLSF select 'RecordsProcessed',           'Sum',       '{0:###,###,###}',            null
insert into @ttLSF select 'RecordsFailed',              'Sum',       '{0:###,###,###}',            null
insert into @ttLSF select 'RecordsPassed',              'Sum',       '{0:###,###,###}',            null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go
