/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Setup ShipLabels Tab (HA-2406)
  2020/06/10  MS      Setup Addresses Tab (HA-861)
  2020/06/03  MS      Orderdetails: Hide unneccassary fields (HA-777)
  2020/05/17  MS      Added Tabs to Layout (HA-568)
  2019/05/14  KBB     File organized to be in compliance with latest template init_Layouts_Template.sql (CIMSV3-537)
  2018/03/20  NB      Corrections to ContextNames, use Copy procedure for LayoutFields(CIMSV3-151).
  2018/01/23  NB      Initial revision.
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
/* OH_EntityInfo_OrderDetails */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_OrderDetails';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.OrderDetails', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/* Hide the fields not applicable to this layout */
exec pr_LayoutFields_ChangeVisibility @ContextName, 'Standard', 'PickTicket,OrderStatusDesc,WaveNo,Warehouse';

/******************************************************************************/
/* OH_EntityInfo_LPNs */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_LPNs';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.LPNs', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* OH_EntityInfo_LPNDetails */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_LPNDetails';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.LPNDetails', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* OH_EntityInfo_PickTasks */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_PickTasks';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.PickTasks', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* OH_EntityInfo_PickTaskDetails */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_PickTaskDetails';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.PickTaskDetails', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* OH_EntityInfo_ShipLabels */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_ShipLabels';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.ShipLabels', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* OH_EntityInfo_Addresses */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_Addresses',
       @DatasetName = 'pr_OrderHeaders_DS_GetAddresses';

/*----------------------------------------------------------------------------*/
/* Layouts */
/*----------------------------------------------------------------------------*/
delete from @Layouts;

/*                          Layout  Default  Layout                           Default               Status Visible SortSeq ShowExpanded
                            Type    Layout   Description                      SelectionName                                   */
insert into @Layouts select 'L',    'N',     'Standard',                      null,                 null,  null,   0,      null

exec pr_Setup_Layout @ContextName, @DataSetName, @Layouts, 'DI' /* Delete & Insert */, 'cimsdba', @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Layout Fields for Standard Layout */
/*----------------------------------------------------------------------------*/
/* Copy standard layout and layout fields */
exec pr_LayoutFields_Copy 'List.Contacts', 'Standard', @ContextName, 'Standard';

/******************************************************************************/
/* OH_EntityInfo_Notifications */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_Notifications';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.Notifications', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* OH_EntityInfo_Notes */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_Notes';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.Notes', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* OH_EntityInfo_AuditTrail */
/******************************************************************************/
select @ContextName = 'OH_EntityInfo_AuditTrail';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.ATEntity', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
