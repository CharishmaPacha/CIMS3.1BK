/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  PKK    Corrected the file as per the template(CIMSV3-1282)
  2019/05/14  KBB    File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/02/02  KSK    Initial revision.
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

select @ContextName = 'List.Devices',
       @DataSetName = 'vwDevices';

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
insert into @ttLF select 'DeviceId',                    null,     -3,   null,               null, null
insert into @ttLF select 'DeviceName',                  null,   null,   null,               null, null
insert into @ttLF select 'DeviceType',                  null,   null,   null,               null, null
insert into @ttLF select 'Make',                        null,   null,   null,               null, null
insert into @ttLF select 'Model',                       null,   null,   null,               null, null
insert into @ttLF select 'SourcedFrom',                 null,   null,   null,               null, null
insert into @ttLF select 'PurchaseDate',                null,   null,   null,               null, null
insert into @ttLF select 'WarrantyStart',               null,   null,   null,               null, null
insert into @ttLF select 'WarrantyExpiry',              null,   null,   null,               null, null
insert into @ttLF select 'WarrantyReferenceNo',         null,   null,   null,               null, null
insert into @ttLF select 'LastServiced',                null,   null,   null,               null, null
insert into @ttLF select 'AssignedToDept',              null,   null,   null,               null, null
insert into @ttLF select 'AssignedToUser',              null,     -1,   null,               null, null
insert into @ttLF select 'Configuration',               null,     -2,   null,               null, null
insert into @ttLF select 'CurrentUserId',               null,   null,   null,               null, null
insert into @ttLF select 'CurrentOperation',            null,   null,   null,               null, null
insert into @ttLF select 'CurrentResponse',             null,     -1,   null,               null, null
insert into @ttLF select 'Status',                      null,      1,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,      1,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'SerialNo',                    null,   null,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,   null,   null,               null, null
insert into @ttLF select 'LastLoginDateTime',           null,   null,   null,               null, null
insert into @ttLF select 'LastUsedDateTime',            null,   null,   null,               null, null
insert into @ttLF select 'PickPathPosition',            null,     -1,   null,               null, null
insert into @ttLF select 'LPN',                         null,     -1,   null,               null, null
insert into @ttLF select 'PickingDirection',            null,     -1,   null,               null, null
                                                                                       
/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'DeviceId;DeviceName' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

/*----------------------------------------------------------------------------*/

Go
