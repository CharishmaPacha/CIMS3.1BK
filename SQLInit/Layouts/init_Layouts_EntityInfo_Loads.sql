/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/21  OK      Added layout for Load.Notifications (CIMSV3-1232)
  2020/09/08  MRK     Added by status in Load_EntityInfo_LPNs (HA-982)
  2020/06/10  MS      Use LF Flag to copy Layout & Fields (HA-861)
  2020/06/09  MS      Added OrderHeaders, LPNs, Pallets Tabs (HA-858)
  2020/06/08  RT      Intial Revision
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
/* Load_EntityInfo_Orders */
/******************************************************************************/
select @ContextName = 'Load_EntityInfo_Orders';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.LoadOrders', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* Load_EntityInfo_Pallets */
/******************************************************************************/
select @ContextName = 'Load_EntityInfo_Pallets';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.Pallets', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* Load_EntityInfo_LPNs */
/******************************************************************************/
select @ContextName = 'Load_EntityInfo_LPNs';

/* Copy Summary by status layout and layout fields */
exec pr_Layout_Copy 'List.LPNs', 'By Pallet & Status', @ContextName, 'By Pallet & Status', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.LPNs', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* Load_EntityInfo_BoLs */
/******************************************************************************/
select @ContextName = 'Load_EntityInfo_BoLs';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.BoLs', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* Load_EntityInfo_BoLOrderDetails */
/******************************************************************************/
select @ContextName = 'Load_EntityInfo_BoLOrderDetails';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.BoLOrderDetails', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* Load_EntityInfo_BoLCarrierDetails */
/******************************************************************************/
select @ContextName = 'Load_EntityInfo_BoLCarrierDetails';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.BoLCarrierDetails', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* Load_EntityInfo_Notifications */
/******************************************************************************/
select @ContextName = 'Load_EntityInfo_Notifications';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.Notifications', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout */;

/******************************************************************************/
/* Load_EntityInfo_AuditTrail */
/******************************************************************************/
select @ContextName = 'Load_EntityInfo_AuditTrail';

/* Copy standard layout and layout fields */
exec pr_Layout_Copy 'List.ATEntity', 'Standard', @ContextName, 'Standard', null /* Default selectionName */, 'LF' /* Options - LF: Copy Fields & Layout*/;

/******************************************************************************/
/* Summary Fields Setup */
/******************************************************************************/

Go
