                                                               /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/12  MS      Initial revision (HA-283)
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

select @ContextName = 'List.InterfaceLogDetails',
       @DataSetName = 'vwInterfaceLogDetails';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & insert */, 'cimsdba', @BusinessUnit;

/******************************************************************************/
/* Listing Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */

insert into @ttLF select 'RecordId',                    null,   null,   null,                 60, null
insert into @ttLF select 'ParentLogId',                 null,      1,   null,                 60, null

insert into @ttLF select 'TransferType',                null,   null,   null,               null, null
insert into @ttLF select 'RecordType',                  null,   null,   null,               null, null
insert into @ttLF select 'InterfaceLogStatus',          null,   null,   null,               null, null

insert into @ttLF select 'LogMessage',                  null,   null,   null,               null, null
insert into @ttLF select 'LogDateTime',                 null,   null,   null,               null, null
insert into @ttLF select 'KeyData',                     null,   null,   null,               null, null
insert into @ttLF select 'HostReference',               null,   null,   null,               null, null

insert into @ttLF select 'RecordsProcessed',            null,   null,   null,               null, null
insert into @ttLF select 'RecordsFailed',               null,   null,   null,               null, null
insert into @ttLF select 'RecordsPassed',               null,   null,   null,               null, null

insert into @ttLF select 'HasInputXML',                 null,   null,   null,               null, null
insert into @ttLF select 'HasResultXML',                null,   null,   null,               null, null
insert into @ttLF select 'LogDate',                     null,   null,   null,               null, null

insert into @ttLF select 'vwILD_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwILD_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwILD_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwILD_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwILD_UDF5',                  null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

Go
