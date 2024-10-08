/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/19  MS      Added UDF's & New Fields (JL-314)
  2020/09/28  MS      Corrections as per new template (JL-65)
  2020/02/12  KBB     Added the fileds RouterConfirmation (JL-62)
  2020/01/23  KBB     Initial revision(JL-62)
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

select @ContextName = 'List.RouterConfirmations',
       @DataSetName = 'vwRouterConfirmations' ;

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
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Destination',                 null,   null,   null,               null, null
insert into @ttLF select 'DivertDateTime',              null,   null,   null,               null, null
insert into @ttLF select 'DivertDate',                  null,   null,   null,               null, null
insert into @ttLF select 'DivertTime',                  null,   null,   null,               null, null

insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'ReceivertId',                 null,   null,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,   null,   null,               null, null

insert into @ttLF select 'ActualWeight',                null,   null,   null,               null, null
insert into @ttLF select 'EstimatedWeight',             null,   null,   null,               null, null

insert into @ttLF select 'ProcessedStatus',             null,   null,   null,               null, null
insert into @ttLF select 'ProcessedDateTime',           null,   null,   null,               null, null
insert into @ttLF select 'ProcessedOn',                 null,   null,   null,               null, null
insert into @ttLF select 'ExternalRecId',               null,   null,   null,               null, null

insert into @ttLF select 'RC_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'RC_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'RC_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'RC_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'RC_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'vwRC_UDF1',                   null,   null,   null,               null, null
insert into @ttLF select 'vwRC_UDF2',                   null,   null,   null,               null, null
insert into @ttLF select 'vwRC_UDF3',                   null,   null,   null,               null, null
insert into @ttLF select 'vwRC_UDF4',                   null,   null,   null,               null, null
insert into @ttLF select 'vwRC_UDF5',                   null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
