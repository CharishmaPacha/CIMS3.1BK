/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/01  SK      Initial revision (HA-2972)
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

select @ContextName = 'List.SummaryProductivity',
       @DataSetName = 'pr_Prod_DS_GetUserProductivity';

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
insert into @ttLF select 'UserId',                      null,      1,   null,               null, null
insert into @ttLF select 'ActivityDate',                null,      1,   null,               null, null
insert into @ttLF select 'Operation',                   null,      1,   null,               null, null

insert into @ttLF select 'Duration',                    null,      1,   null,               null, '{0:hh:mm:ss}'
insert into @ttLF select 'DurationInMins',              null,      1,   null,               null, null
insert into @ttLF select 'DurationInSecs',              null,     -1,   null,               null, null

insert into @ttLF select 'NumUnits',                    null,      1,   null,               null, null
insert into @ttLF select 'UnitsPerHr',                  null,     -1,   null,               null, '{0:n2}'

insert into @ttLF select 'NumTasks',                    null,      1,   null,               null, null
insert into @ttLF select 'NumPicks',                    null,      1,   null,               null, null
insert into @ttLF select 'NumWaves',                    null,      1,   '# Waves',          null, null
insert into @ttLF select 'NumOrders',                   null,      1,   null,               null, null
insert into @ttLF select 'NumLocations',                null,      1,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,      1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,      1,   null,               null, null
insert into @ttLF select 'NumAssignments',              null,      1,   null,               null, null
insert into @ttLF select 'NumPackages',                 null,     -1,   null,               null, null

insert into @ttLF select 'WaveNo',                      null,     -1,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,     -1,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'SKU',                         null,     -1,   null,               null, null
insert into @ttLF select 'LPN',                         null,     -1,   null,               null, null
insert into @ttLF select 'Location',                    null,     -1,   null,               null, null
insert into @ttLF select 'Pallet',                      null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,     -1,   null,               null, null
insert into @ttLF select 'TaskId',                      null,     -1,   null,               null, null

insert into @ttLF select 'Status',                      null,     -2,   null,               null, null
insert into @ttLF select 'Archived',                    null,     -1,   null,               null, null

insert into @ttLF select 'DeviceId',                    null,     -1,   null,               null, null
insert into @ttLF select 'UserName',                    null,     -1,   null,               null, null
insert into @ttLF select 'RoleName',                    null,     -1,   null,               null, null
insert into @ttLF select 'ParentRecordId',              null,   null,   null,               null, null

insert into @ttLF select 'Warehouse',                   null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,      1,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'UserId;Assignment' /* Key fields */;

/******************************************************************************/
/* Layouts - Picking */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Picking',                    null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;


/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'UserId',                      null,      1,   null,               null, null
insert into @ttLF select 'ActivityDate',                null,      1,   null,               null, null
insert into @ttLF select 'Operation',                   null,      1,   null,               null, null

insert into @ttLF select 'Duration',                    null,      1,   null,               null, '{0:hh:mm:ss}'
insert into @ttLF select 'DurationInMins',              null,      1,   null,               null, null
insert into @ttLF select 'DurationInSecs',              null,     -1,   null,               null, null

insert into @ttLF select 'NumUnits',                    null,      1,   null,               null, null
insert into @ttLF select 'UnitsPerHr',                  null,     -1,   null,               null, '{0:n2}'

insert into @ttLF select 'NumTasks',                    null,      1,   null,               null, null
insert into @ttLF select 'NumPicks',                    null,      1,   null,               null, null
insert into @ttLF select 'NumWaves',                    null,      1,   '# Waves',          null, null
insert into @ttLF select 'NumOrders',                   null,      1,   null,               null, null
insert into @ttLF select 'NumLocations',                null,      1,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,      1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,      1,   null,               null, null
insert into @ttLF select 'NumAssignments',              null,     -1,   null,               null, null
insert into @ttLF select 'NumPackages',                 null,     -1,   null,               null, null

insert into @ttLF select 'WaveNo',                      null,     -1,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,      1,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'SKU',                         null,     -1,   null,               null, null
insert into @ttLF select 'LPN',                         null,     -1,   null,               null, null
insert into @ttLF select 'Location',                    null,     -1,   null,               null, null
insert into @ttLF select 'Pallet',                      null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,     -1,   null,               null, null
insert into @ttLF select 'TaskId',                      null,     -1,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,      1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Picking', @ttLF, @DataSetName, 'UserId;Assignment' /* Key fields */;

/******************************************************************************/
/* Layouts - Reservation */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Reservation',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;


/*----------------------------------------------------------------------------*/
/* Layout Fields for Reservation */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'UserId',                      null,      1,   null,               null, null
insert into @ttLF select 'ActivityDate',                null,      1,   null,               null, null
insert into @ttLF select 'Operation',                   null,      1,   null,               null, null

insert into @ttLF select 'Duration',                    null,      1,   null,               null, '{0:hh:mm:ss}'
insert into @ttLF select 'DurationInMins',              null,      1,   null,               null, null
insert into @ttLF select 'DurationInSecs',              null,     -1,   null,               null, null

insert into @ttLF select 'NumUnits',                    null,      1,   null,               null, null
insert into @ttLF select 'NumLocations',                null,      1,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,      1,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,      1,   null,               null, null
insert into @ttLF select 'NumAssignments',              null,     -1,   null,               null, null

insert into @ttLF select 'PickTicket',                  null,     -1,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,     -1,   null,               null, null
insert into @ttLF select 'WaveTypeDesc',                null,      1,   null,               null, null
insert into @ttLF select 'SKU',                         null,     -1,   null,               null, null
insert into @ttLF select 'LPN',                         null,     -1,   null,               null, null
insert into @ttLF select 'Location',                    null,     -1,   null,               null, null
insert into @ttLF select 'Pallet',                      null,     -1,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,     -1,   null,               null, null
insert into @ttLF select 'ReceiverNumber',              null,     -1,   null,               null, null
insert into @ttLF select 'TaskId',                      null,     -1,   null,               null, null
insert into @ttLF select 'Warehouse',                   null,      1,   null,               null, null
insert into @ttLF select 'Ownership',                   null,      1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Reservation', @ttLF, @DataSetName, 'UserId;Assignment' /* Key fields */;


Go
