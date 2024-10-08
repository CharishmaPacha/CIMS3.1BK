/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/23  AY      Sort Audit Trail in reverse chronological order by default
  2020/04/21  NB      Initial revision (HA-231)
------------------------------------------------------------------------------*/

Go

Go

declare @ContextName         TName,
        @DataSetName         TName,

        @Layouts             TLayoutTable,
        @LayoutDescription   TDescription,

        @ttLF                TLayoutFieldsTable,
        @ttLFE               TLayoutFieldsExpandedTable,
        @ttLSF               TLayoutSummaryFields,
        @BusinessUnit        TBusinessUnit;


select @ContextName = 'List.ATEntity',
       @DataSetName = 'vwATEntity';

/*------------------------------------------------------------------------------*/
/* List.ATEntity */
/*------------------------------------------------------------------------------*/
/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/* Setup Default sort order */
update Layouts
set DefaultSortOrder = 'AuditId desc'
where (ContextName = @ContextName);

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'AuditId',                     null,   null,   null,               null, null
insert into @ttLF select 'EntityId',                    null,     -2,   null,               null, null
insert into @ttLF select 'EntityKey',                   null,      1,   'Key',              null, null
insert into @ttLF select 'ActivityDateTime',            null,      1,   null,               null, null
insert into @ttLF select 'UserId',                      null,      1,   null,               null, null
insert into @ttLF select 'Comment',                     null,      1,   null,               null, null

insert into @ttLF select 'ActivityType',                null,     -2,   null,               null, null
insert into @ttLF select 'EntityType',                  null,     -2,   null,               null, null
insert into @ttLF select 'NumOrders',                   null,     -2,   null,               null, null
insert into @ttLF select 'NumPallets',                  null,     -2,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,     -2,   null,               null, null
insert into @ttLF select 'NumSKUs',                     null,     -2,   null,               null, null
insert into @ttLF select 'InnerPacks',                  null,     -2,   null,               null, null
insert into @ttLF select 'Quantity',                    null,     -2,   null,               null, null

insert into @ttLF select 'ProductivityFlag',            null,     -1,   null,               null, null
insert into @ttLF select 'ProductivityId',              null,     -1,   null,               null, null
insert into @ttLF select 'DeviceId',                    null,     -1,   null,               null, null

insert into @ttLF select 'Archived',                    null,   null,   null,               null, null
insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'AuditId;' /* KeyFields */;

Go
