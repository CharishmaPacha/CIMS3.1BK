/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  SJ     Initial revision.(CID-1594)
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

select @ContextName = 'List.APIInboundTransactions',
       @DataSetName = 'APIInboundTransactions';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                      */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,   null,    0,       null

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
insert into @ttLF select 'IntegrationName',             null,   null,   null,               null, null
insert into @ttLF select 'MessageType',                 null,   null,   null,               null, null
insert into @ttLF select 'RawInput',                    null,   null,   null,               null, null
insert into @ttLF select 'ProcessedInput',              null,   null,   null,               null, null

insert into @ttLF select 'ResponseCode',                null,   null,   null,               null, null
insert into @ttLF select 'Response',                    null,   null,   null,               null, null
insert into @ttLF select 'TransactionStatus',           null,   null,   null,
                                                                                            null, null
insert into @ttLF select 'ProcessStatus',               null,   null,   null,               null, null
insert into @ttLF select 'ProcessMessage',              null,   null,   null,               null, null

insert into @ttLF select 'AlertSent',                   null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null

insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'CreatedOn',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;'  /* Key Fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/


/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
select @LayoutDescription = null; -- Applicable to all layouts of this Context
delete from @ttLSF;

insert into @ttLSF(FieldName,                    SummaryType, DisplayFormat,                AggregateMethod)
           select 'RecordId',                    'Count',     '# Records: {0:n0}',          null

exec pr_Setup_LayoutSummaryFields @ContextName, null /* Layout description */, @ttLSF;

Go
