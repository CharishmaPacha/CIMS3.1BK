/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/02  AY      Added fields to show/edit ZPL (CIMSV3-1183)
  2020/10/08  MRK     Added missing fields (HA-1430)
  2020/09/22  RV      Added NumCopies (CIMSV3-1079)
  2019/05/14  KBB     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2019/03/30  MJ      Initial revision(CIMSV3-236)
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

select @ContextName = 'List.LabelFormats',
       @DataSetName = 'vwLabelFormats';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
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
insert into @ttLF select 'RecordId',                    null,   -2,     null,               null, null
insert into @ttLF select 'EntityType',                  null,   null,   null,               null, null
insert into @ttLF select 'LabelFormatName',             null,   null,   null,               null, null
insert into @ttLF select 'LabelFormatDesc',             null,   null,   null,               null, null
insert into @ttLF select 'LabelFileName',               null,   null,   null,               null, null
insert into @ttLF select 'LabelSize',                   null,   null,   null,               null, null

insert into @ttLF select 'PrinterMake',                 null,     -1,   null,               null, null
insert into @ttLF select 'AdditionalContent',           null,   null,   null,               null, null
insert into @ttLF select 'ZPLLabelSQLStatement',        null,   null,   null,               null, null
insert into @ttLF select 'PrintOptions',                null,     -1,   null,               null, null
insert into @ttLF select 'NumCopies',                   null,   null,   null,               null, null
insert into @ttLF select 'PrintDataStream',             null,     -1,   null,               null, null

insert into @ttLF select 'Status',                      null,      1,   null,               null, null
insert into @ttLF select 'LabelTemplateType',           null,     -1,   null,               null, null
insert into @ttLF select 'LabelSQLStatement',           null,   null,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null

insert into @ttLF select 'ZPLTemplate',                 null,   null,   null,               null, null
insert into @ttLF select 'ZPLFile',                     null,   null,   null,               null, null
insert into @ttLF select 'ZPLLink',                     null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'Visible',                     null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = 'Labels by Entity';
delete from @ttLFE;

/*                        Field               Visible Visible Field          Width Display  Aggregate
                          Name                Index           Caption              Format   Method */
insert into @ttLFE select 'EntityType',        null,      1,   null,          null, null,    null
insert into @ttLFE select 'RecordId',          null,      1,   '# Labels',    null, null,    'Count'

exec pr_LayoutFieldsSummary_Setup @ContextName, @LayoutDescription, @ttLFE;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

Go
