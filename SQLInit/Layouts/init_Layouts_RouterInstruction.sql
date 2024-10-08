/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/05  MS      Added UDF1 to UDF5 (JL-294)
  2020/09/28  MS      Corrections as per new template (JL-65)
  2020/02/12  KBB     Added the fileds RouterInstruction (JL-62)
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

select @ContextName = 'List.RouterInstructions',
       @DataSetName = 'vwRouterInstructions' ;

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
insert into @ttLF select 'TrackingNo',                  null,   null,   null,               null, null
insert into @ttLF select 'UCCBarcode',                  null,   null,   null,               null, null
insert into @ttLF select 'RouteLPN',                    null,   null,   null,               null, null
insert into @ttLF select 'EstimatedWeight',             null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'ReceiptId',                   null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'WorkId',                      null,   null,   null,               null, null
insert into @ttLF select 'ExportStatus',                null,   null,   null,               null, null
insert into @ttLF select 'ExportDateTime',              null,   null,   null,               null, null
insert into @ttLF select 'ExportBatch',                 null,      1,   null,               null, null
insert into @ttLF select 'ExportedOn',                  null,   null,   null,               null, null

insert into @ttLF select 'RI_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'RI_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'RI_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'RI_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'RI_UDF5',                     null,   null,   null,               null, null

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
