/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/05/18  MS      Initial revision (HA-580)
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

select @ContextName = 'List.Notifications',
       @DataSetName = 'vwNotifications';

/******************************************************************************/
/* Layouts */
/******************************************************************************/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/* Setup Default sort order */
update Layouts
set DefaultSortOrder = 'RecordId desc'
where (ContextName = @ContextName);

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

insert into @ttLF select 'NotificationType',            null,   null,   null,               null, null
insert into @ttLF select 'Operation',                   null,      1,   null,               null, null
insert into @ttLF select 'Message',                     null,   null,   null,               null, null

insert into @ttLF select 'MasterEntityType',            null,   null,   null,               null, null
insert into @ttLF select 'MasterEntityId',              null,   null,   null,               null, null
insert into @ttLF select 'MasterEntityKey',             null,   null,   null,               null, null

insert into @ttLF select 'EntityType',                  null,   null,   null,               null, null
insert into @ttLF select 'EntityId',                    null,   null,   null,               null, null
insert into @ttLF select 'EntityKey',                   null,   null,   null,               null, null

insert into @ttLF select 'VisibleFlags',                null,    -20,   null,               null, null
insert into @ttLF select 'DisplayFormat',               null,    -20,   null,               null, null

insert into @ttLF select 'NotificationSource',          null,    -20,   null,               null, null
insert into @ttLF select 'Status',                      null,    -20,   null,               null, null
insert into @ttLF select 'SortSeq',                     null,    -20,   null,               null, null

insert into @ttLF select 'NF_UDF1',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF2',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF3',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF4',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF5',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF6',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF7',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF8',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF9',                     null,   null,   null,               null, null
insert into @ttLF select 'NF_UDF10',                    null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,    -20,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,    -20,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,    -20,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,    -20,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,    -20,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'RecordId;' /* Key fields */;

/******************************************************************************/
/* Summary Layouts Details */
/******************************************************************************/

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/


Go