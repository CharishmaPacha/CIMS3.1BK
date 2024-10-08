/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  YJ      Added PickTicket, WaveNo (CIMSV3-1212)
  2020/11/17  YJ      Initial revision (CIMSV3-1212)
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

select @ContextName = 'List.SerialNos',
       @DataSetName = 'vwSerialNos';

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
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null

insert into @ttLF select 'SerialNo',                    null,      1,   null,               null, null
insert into @ttLF select 'SerialNoStatus',              null,     -2,   null,               null, null
insert into @ttLF select 'SerialNoStatusDesc',          null,      1,   null,               null, null

insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null
insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null

insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU5',                        null,   null,   null,               null, null

insert into @ttLF select 'LPNDetailId',                 null,   null,   null,               null, null
insert into @ttLF select 'SKUId',                       null,   null,   null,               null, null

insert into @ttLF select 'SN_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'SN_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'SN_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'SN_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'SN_UDF5',                     null,   null,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
