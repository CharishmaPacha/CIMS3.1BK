/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/06/25  NB      Added Warehouse field(CIMSV3-987)
  2020/04/25  MS      Removed captions & visibilities (JL-205)
  2020/03/12  MS      Added ReceiverStatus & ReceiverStatusDesc (CIMSV3-750)
  2019/05/14  RKC     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2017/09/29  YJ      pr_Setup_Layout: Change to setup Layouts using procedure (CIMSV3-72)
  2017/09/29  YJ      Initial revision.
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

select @ContextName = 'List.Receivers',
       @DataSetName = 'vwReceivers';

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
insert into @ttLF select 'ReceiverId',                  null,   null,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null
insert into @ttLF select 'ReceiverDate',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverStatus',              null,     -2,   null,               null, null
insert into @ttLF select 'ReceiverStatusDesc',          null,   null,   null,               null, null

insert into @ttLF select 'BoLNumber',                   null,      1,   null,               null, null
insert into @ttLF select 'Container',                   null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null

insert into @ttLF select 'ReceiverRef1',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef2',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef3',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef4',                null,   null,   null,               null, null
insert into @ttLF select 'ReceiverRef5',                null,   null,   null,               null, null

insert into @ttLF select 'RCV_UDF1',                    null,   null,   null,               null, null
insert into @ttLF select 'RCV_UDF2',                    null,   null,   null,               null, null
insert into @ttLF select 'RCV_UDF3',                    null,   null,   null,               null, null
insert into @ttLF select 'RCV_UDF4',                    null,   null,   null,               null, null
insert into @ttLF select 'RCV_UDF5',                    null,   null,   null,               null, null

insert into @ttLF select 'vwRCV_UDF1',                  null,   null,   null,               null, null
insert into @ttLF select 'vwRCV_UDF2',                  null,   null,   null,               null, null
insert into @ttLF select 'vwRCV_UDF3',                  null,   null,   null,               null, null
insert into @ttLF select 'vwRCV_UDF4',                  null,   null,   null,               null, null
insert into @ttLF select 'vwRCV_UDF5',                  null,   null,   null,               null, null

/* Deprecated, use above UDFs */
insert into @ttLF select 'UDF1',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF2',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF3',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF4',                        null,   null,   null,               null, null
insert into @ttLF select 'UDF5',                        null,   null,   null,               null, null

insert into @ttLF select 'vwUDF1',                      null,   null,   null,               null, null
insert into @ttLF select 'vwUDF2',                      null,   null,   null,               null, null
insert into @ttLF select 'vwUDF3',                      null,   null,   null,               null, null
insert into @ttLF select 'vwUDF4',                      null,   null,   null,               null, null
insert into @ttLF select 'vwUDF5',                      null,   null,   null,               null, null

insert into @ttLF select 'Status',                      null,     -2,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
/* Unused fields */
insert into @ttLF select 'Reference1',                  null,    -20,   null,               null, null
insert into @ttLF select 'Reference2',                  null,    -20,   null,               null, null
insert into @ttLF select 'Reference3',                  null,    -20,   null,               null, null
insert into @ttLF select 'Reference4',                  null,    -20,   null,               null, null
insert into @ttLF select 'Reference5',                  null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'ReceiverId;ReceiverNumber' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/
select @LayoutDescription = null; -- Applicable to all layouts in this context
delete from @ttLSF;

/*                        FieldName,                    SummaryType, DisplayFormat,                AggregateMethod */
insert into @ttLSF select 'ReceiverNumber',             'Count',     '# Receivers: {0:n0}',        null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLSF;

Go