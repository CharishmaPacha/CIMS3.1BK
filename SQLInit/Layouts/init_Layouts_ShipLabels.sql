/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/25  VS      Key field Order changed to EntityId for ReGenerateTrackingNo action (HA-2424)
  2021/03/24  MS      Added New Fields & Formated the layout (HA-2413)
  2019/04/23  KSK     Initial revision (CIMSV3-233)
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

select @ContextName = 'List.ShipLabels',
       @DataSetName = 'vwShipLabels';

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
/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'RecordId',                    null,   null,   null,               null, null

insert into @ttLF select 'EntityType',                  null,     -1,   null,               null, null
insert into @ttLF select 'EntityId',                    null,     -1,   null,               null, null
insert into @ttLF select 'EntityKey',                   null,      1,  'LPN',               null, null

insert into @ttLF select 'OrderId',                     null,   null,   null,               null, null
insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null
insert into @ttLF select 'TotalPackages',               null,   null,   null,               null, null
insert into @ttLF select 'TaskId',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveId',                      null,   null,   null,               null, null
insert into @ttLF select 'WaveNo',                      null,   null,   null,               null, null
insert into @ttLF select 'LabelType',                   null,     -1,   null,               null, null
insert into @ttLF select 'TrackingNo',                  null,   null,   null,               null, null
insert into @ttLF select 'IsValidTrackingNo',           null,      1,   null,               null, null

insert into @ttLF select 'Label',                       null,   null,   null,               null, null
insert into @ttLF select 'ZPLLabel',                    null,   null,   null,               null, null

insert into @ttLF select 'RequestedShipVia',            null,   null,   null,               null, null
insert into @ttLF select 'ShipVia',                     null,   null,   null,               null, null
insert into @ttLF select 'Carrier',                     null,   null,   null,               null, null
insert into @ttLF select 'ListNetCharge',               null,      1,   null,               null, null
insert into @ttLF select 'AcctNetCharge',               null,      1,   null,               null, null
insert into @ttLF select 'Status',                      null,      1,   null,               null, null

insert into @ttLF select 'ProcessStatus',               null,      1,   null,               null, null
insert into @ttLF select 'ProcessedInstance',           null,   null,   null,               null, null
insert into @ttLF select 'ProcessBatch',                null,   null,   null,               null, null
insert into @ttLF select 'ProcessedDateTime',           null,     -1,   null,               null, null

insert into @ttLF select 'ExportStatus',                null,     -1,   null,               null, null
insert into @ttLF select 'ExportInstance',              null,   null,   null,               null, null
insert into @ttLF select 'ExportBatch',                 null,   null,   null,               null, null

insert into @ttLF select 'Priority',                    null,     -1,   null,               null, null

insert into @ttLF select 'AlertSent',                   null,     -1,   null,               null, null
insert into @ttLF select 'Reference',                   null,      1,   null,               null, null
insert into @ttLF select 'Notifications',               null,   null,   null,               null, null
insert into @ttLF select 'NotificationSource',          null,   null,   null,               null, null
insert into @ttLF select 'NotificationTrace',           null,   null,   null,               null, null

insert into @ttLF select 'BusinessUnit',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedDate',                 null,   null,   null,               null, null
insert into @ttLF select 'ModifiedDate',                null,   null,   null,               null, null
insert into @ttLF select 'CreatedBy',                   null,   null,   null,               null, null
insert into @ttLF select 'ModifiedBy',                  null,   null,   null,               null, null
insert into @ttLF select 'Archived',                    null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'EntityId;RecordId;' /* KeyFields */;

Go

