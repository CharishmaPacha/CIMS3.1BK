/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/30  SAK     Changed visibility as 11 for RecordId field (JL-147)
  2020/02/14  SJ      Added missing fields (JL-48)
  2019/05/23  RKC     Initial revision (CIMSV3-550).
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

select @ContextName = 'List.CIMSDE_ImportNotes',
       @DataSetName = 'vwCIMSDE_ImportNotes';

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
insert into @ttLF select 'RecordType',                  null,     -1,   null,               null, null
insert into @ttLF select 'RecordAction',                null,   null,   null,               null, null

insert into @ttLF select 'NoteType',                    null,   null,   null,               null, null
insert into @ttLF select 'Note',                        null,   null,   null,               null, null
insert into @ttLF select 'NoteFormat',                  null,   null,   null,               null, null

insert into @ttLF select 'EntityType',                  null,   null,   null,               null, null
insert into @ttLF select 'EntityId',                    null,   null,   null,               null, null
insert into @ttLF select 'EntityKey',                   null,   null,   null,               null, null
insert into @ttLF select 'EntityLineNo',                null,   null,   null,               null, null

insert into @ttLF select 'PrintFlags',                  null,   null,   null,               null, null
insert into @ttLF select 'VisibleFlags',                null,   null,   null,               null, null
insert into @ttLF select 'Status',                      null,      1,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

insert into @ttLF select 'InputXML',                    null,   null,   null,               null, null
insert into @ttLF select 'ResultXML',                   null,   null,   null,               null, null

insert into @ttLF select 'HostRecId',                   null,     1,   null,               null, null
insert into @ttLF select 'RecordId',                    null,    11,   null,               null, null
insert into @ttLF select 'ExchangeStatus',              null,     1,   null,               null, null
insert into @ttLF select 'InsertedTime',                null,     1,   null,               null, null
insert into @ttLF select 'ProcessedTime',               null,     1,   null,               null, null
insert into @ttLF select 'Reference',                   null,   null,   null,               null, null
insert into @ttLF select 'Result',                      null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;';

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */

/******************************************************************************/

Go
