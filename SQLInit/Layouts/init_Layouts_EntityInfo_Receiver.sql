/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  PKK     Corrected the file as per template (CIMSV3-1282)
  2020/06/10  MS      Use LF Flag to copy Layout & Fields (HA-861)
  2020/05/14  MS      Initial revision.(HA-202)
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

/******************************************************************************/
/* RCV_EntityInfo_Summary */
/******************************************************************************/

select @ContextName = 'RCV_EntityInfo_Summary',
       @DataSetName = 'vwReceivedCounts';

/*----------------------------------------------------------------------------*/
/* Layouts */
/*----------------------------------------------------------------------------*/
delete from @Layouts;

/*                          Layout  Default  Layout                        Default        Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                   SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                   null,          null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Listing Layouts Details */
/*----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'ReceiverId',                  null,   null,   null,               null, null
insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'CustPO',                      null,      1,   null,               null, null
insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'QtyOrdered',                  null,   null,   null,               null, null
insert into @ttLF select 'QtyInTransit',                null,   null,   null,               null, null
insert into @ttLF select 'QtyReceived',                 null,   null,   null,               null, null
insert into @ttLF select 'QtyToReceive',                null,   null,   null,               null, null
insert into @ttLF select 'NumLPNs',                     null,   null,   null,               null, null
insert into @ttLF select 'LPNsInTransit',               null,      1,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'ReceiverId;' /* Key fields */;

/******************************************************************************/
/* RCV_EntityInfo_LPNs */
/******************************************************************************/
select @ContextName = 'RCV_EntityInfo_LPNs',
       @DataSetName = 'vwLPNs';
/*----------------------------------------------------------------------------*/
/* Layouts */
/*----------------------------------------------------------------------------*/

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.LPNs', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'L' /* Options - L: Copy Layout */;

/*----------------------------------------------------------------------------*/
/* Listing Layouts Details */
/*----------------------------------------------------------------------------*/

delete from @ttLF;

/*                        Field                         Visible Visible Field               Width Display
                          Name                          Index           Caption                   Format */
insert into @ttLF select 'LPNId',                       null,   null,   null,               null, null
insert into @ttLF select 'LPN',                         null,   null,   null,               null, null

insert into @ttLF select 'LPNStatus',                   null,   null,   null,               null, null
insert into @ttLF select 'LPNStatusDesc',               null,   null,   null,               null, null

insert into @ttLF select 'SKU',                         null,   null,   null,               null, null
insert into @ttLF select 'SKU1',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU2',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU3',                        null,   null,   null,               null, null
insert into @ttLF select 'SKU4',                        null,   null,   null,               null, null
insert into @ttLF select 'SKUDescription',              null,   null,   null,               null, null

insert into @ttLF select 'InnerPacks',                  null,   null,   null,               null, null
insert into @ttLF select 'Quantity',                    null,   null,   null,               null, null

insert into @ttLF select 'Pallet',                      null,   null,   null,               null, null
insert into @ttLF select 'Location',                    null,   null,   null,               null, null
insert into @ttLF select 'DestWarehouse',               null,   null,   null,               null, null

insert into @ttLF select 'ReceiptNumber',               null,   null,   null,               null, null
insert into @ttLF select 'DestZone',                    null,   null,   null,               null, null
insert into @ttLF select 'DestLocation',                null,   null,   null,               null, null

insert into @ttLF select 'PickTicket',                  null,   null,   null,               null, null

/* Add the fields for this Layout */
exec pr_LayoutFields_Setup @ContextName, 'Standard', @ttLF, @DataSetName, 'LPNId;LPN' /* Key fields */;

/******************************************************************************/
/* RCV_EntityInfo_AuditTrail */
/******************************************************************************/
select @ContextName = 'RCV_EntityInfo_AuditTrail';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.ATEntity', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/*----------------------------------------------------------------------------*/
/* Summary Layouts Details */
/*----------------------------------------------------------------------------*/


Go
