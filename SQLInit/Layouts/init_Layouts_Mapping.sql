/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/26  SAK     Added Fields Status and SortSeq (CIMSV3-811)
  2019/04/26  KSK     Initial revision (CIMSV3-240)
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

select @ContextName = 'List.Mapping',
       @DataSetName = 'vwMapping';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null
insert into @Layouts select 'S',    'Y',     'Available Mappings',            null,                 null,  null,   0,      null

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
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'SourceSystem',                null,      1,   null,               null, null
insert into @ttLF select 'TargetSystem',                null,      1,   null,               null, null
insert into @ttLF select 'EntityType',                  null,   null,   null,               null, null
insert into @ttLF select 'Operation',                   null,      1,   null,               null, null
insert into @ttLF select 'SourceValue',                 null,   null,   null,               null, null
insert into @ttLF select 'TargetValue',                 null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,      1,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* KeyFields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Available Mappings';
delete from @ttLFE;

/*                        Field                     Visible Visible Field          Width Display  Aggregate
                          Name                      Index           Caption              Format   Method */
insert into @ttLFE select 'SourceSystem',           null,        1, null,          null, null,    null
insert into @ttLFE select 'TargetSystem',           null,        1, null,          null, null,    null
insert into @ttLFE select 'EntityType',             null,        1, null,          null, null,    null
insert into @ttLFE select 'Operation',              null,        1, null,          null, null,    null
insert into @ttLFE select 'SourceValue',            null,        1, null,          null, null,    'DCount'
insert into @ttLFE select 'TargetValue',            null,        1, null,          null, null,    'DCount'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

Go
