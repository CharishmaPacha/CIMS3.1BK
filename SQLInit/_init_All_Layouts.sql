/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/20  SRP     Added init_Layouts_SKUVelocity (BK-813)
  2022/02/25  SRS     Added init_Layouts_CIMSDE_ExportInvSnapshot.sql (BK-767)
  2022/02/17  SRS     Added init_Layouts_LocationReplenishLevels.sql (BK-764)
  2021/07/26  SK      Added init_Layouts_WarehouseKPIs.sql (HA-3020)
  2021/05/11  NB      Added Init_Layouts_Packing.sql(CIMSV3-156)
  2021/05/05  SAK     Added Init_Layouts_EntityInfo_Receipts.sql; (HA-2723)
  2021/03/04  KBB     Added init_Layouts_CycleCountResults.sql (HA-2003)
  2020/11/17  YJ      Added init_Layouts_SerialNos (CIMSV3-1212)
  2020/11/03  VM      Added init_Layouts_ReportFormats (CIMSV3-1184)
  2020/10/05  SK      Added init_Layouts_Productivity (HA-1479)
  2020/09/04  NB      Added init_Layouts_ImportFiles (HA-320)
  2020/07/17  KBB     Added init_Layouts_CycleCountTaskDetails (CIMSV3-1024)
  2020/07/15  KBB     Added init_Layouts_ShippingLog (HA-1093)
  2020/07/15  MS      Renamed init_Layouts_CycleCount as init_Layouts_CycleCountTasks (CIMSV3-548)
  2020/07/13  MS      Added init_Layouts_CycleCountLocations (CIMSV3-548)
  2020/06/24  HYP     Added Init_Layouots_CartonGroups (HA-796)
  2020/06/10  RV      Added Init_Layouts_ManageLoads (HA-838)
  2020/06/09  MS      Added Init_Layouts_LoadOrders (HA-858)
  2020/06/08  RT      Included init_Layouts_BoLs,init_Layouts_BoLOrderDetails,init_Layouts_BoLCarrierDetails and Init_Layouts_EntityInfo_Loads (HA-824)
  2020/05/24  NB      Added Init_Layouts_WaveSummary(CIMSV3-817, HA-101)
  2020/05/21  SV      Added init_Layouts_UserControlSelectWavingRule (HA-510)
  2020/05/20  KBB     Added init_Layouts_Selections.sql (HA-549)
  2020/05/18  MS      Added init_Layouts_Notifications (HA-580)
  2020/05/05  VS      Added Init_Layouts_ReplenishOrders.sql, init_Layouts_ReplenishLocations (HA-367 & 368)
  2020/04/23  MS      Added init_Layouts_InterfaceLogDetails (HA-283)
  2020/04/23  RKC     Uncommeted the init_Layouts_Notes (HA-159)
  2020/04/21  NB      Added Init_Layouts_ATEntity(HA-231)
  2020/04/20  MS      Added Init_Layouts_EntityInfo_Receiver (HA-202)
  2020/04/19  VM      init_Layouts_PickBatchRules => init_Layouts_WaveRules (CIMSV3-824)
  2020/04/14  AY      Added Init_Layouts_CIMSDE_ImportInvAdjustments
  2020/04/07  VS      init_Layouts_Roles.sql file move to Base(HA-96);
  2020/03/28  TK      Added init_Layouts_RolePermissions & init_Layouts_Roles (HA-68)
  2020/03/25  VM      Moved Init_Layouts_* from Base\InitScripts\_Init_Base.sql (CIMSV3-769)
------------------------------------------------------------------------------*/

Go

/********************************************************************************/
/* Layout Fields  - The order of these is sometimes important as we now
   copy fields from one layout to another */
/********************************************************************************/
Input .\Layouts\init_Layouts_AllocationRules.sql;
Input .\Layouts\init_Layouts_ATEntity.sql;

--Input .\Layouts\init_Layouts_BusinessUnits.sql;
Input .\Layouts\init_Layouts_BoLs.sql;
Input .\Layouts\init_Layouts_BoLOrderDetails.sql;
Input .\Layouts\init_Layouts_BoLCarrierDetails.sql;

Input .\Layouts\init_Layouts_CartonTypes.sql;
Input .\Layouts\init_Layouts_CartonGroups.sql;
/* Need to verify any dependencies and reposition "Init_Layouts_ShipLabels.sql" */
Input .\Layouts\init_Layouts_ShipLabels.sql;

Input .\Layouts\init_Layouts_Contacts.sql;
Input .\Layouts\init_Layouts_Controls.sql;
Input .\Layouts\init_Layouts_Customers.sql;
Input .\Layouts\init_Layouts_CycleCountLocations.sql;
Input .\Layouts\init_Layouts_CycleCountResults.sql;
Input .\Layouts\init_Layouts_CycleCountTaskDetails.sql
Input .\Layouts\init_Layouts_CycleCountTasks.sql;
Input .\Layouts\init_Layouts_CycleCountStatistics.sql;

Input .\Layouts\init_Layouts_Devices.sql;
--Input .\Layouts\init_Layouts_DirectedCycleCount.sql;

Input .\Layouts\init_Layouts_Exports.sql;

--Input .\Layouts\init_Layouts_Fields.sql;

Input .\Layouts\init_Layouts_ImportFiles.sql;
Input .\Layouts\init_Layouts_InterfaceLog.sql;
Input .\Layouts\init_Layouts_InterfaceLogDetails.sql;
--Input .\Layouts\init_Layouts_InventoryTransfer.sql

Input .\Layouts\init_Layouts_LabelFormats.sql;
--Input .\Layouts\init_Layouts_LayoutFields.sql;
Input .\Layouts\init_Layouts_Rules.sql;
--Input .\Layouts\init_Layouts_RuleSets.sql;

/* Init_Layouts_LPNs - Has to preceed Loads etc */
Input .\Layouts\init_Layouts_LPNs.sql;
Input .\Layouts\init_Layouts_LPNDetails.sql;
Input .\Layouts\init_Layouts_Loads.sql;
Input .\Layouts\Init_Layouts_LoadOrders.sql;
Input .\Layouts\init_Layouts_Locations.sql;
Input .\Layouts\init_Layouts_LocationReplenishLevels.sql;
Input .\Layouts\init_Layouts_LookUps.sql;

Input .\Layouts\init_Layouts_Mapping.sql;
Input .\Layouts\init_Layouts_Messages.sql;

Input .\Layouts\init_Layouts_Notes.sql;
Input .\Layouts\init_Layouts_Notifications.sql;

Input .\Layouts\init_Layouts_OnhandInventory.sql;
Input .\Layouts\init_Layouts_OrderDetails.sql;
--Input .\Layouts\init_Layouts_OrderPacking.sql;
Input .\Layouts\init_Layouts_Orders.sql;

Input .\Layouts\init_Layouts_Packing.sql;
/* Init_Layouts_Pallets - Has to follow LPNs */
Input .\Layouts\init_Layouts_Pallets.sql;
--Input .\Layouts\init_Layouts_PandaLabels.sql;
--Input .\Layouts\init_Layouts_PickBatches.sql;
--Input .\Layouts\init_Layouts_PickBatching.sql;
--Input .\Layouts\init_Layouts_PickBatchSummary.sql;
Input .\Layouts\init_Layouts_PickTaskDetails.sql;
Input .\Layouts\init_Layouts_PickTasks.sql;
Input .\Layouts\init_Layouts_Productivity.sql;
Input .\Layouts\init_Layouts_PutawayRules.sql;

Input .\Layouts\init_Layouts_ReceiptDetails.sql;
Input .\Layouts\init_Layouts_Receipts.sql;
Input .\Layouts\init_Layouts_Receivers.sql;
Input .\Layouts\init_Layouts_ReplenishLocations.sql;
Input .\Layouts\init_Layouts_ReplenishOrders.sql;
Input .\Layouts\init_Layouts_ReportFormats.sql;
--Input .\Layouts\init_Layouts_Returns.sql;
--Input .\Layouts\init_Layouts_RFInquiry.sql;
Input .\Layouts\init_Layouts_RouterConfirmation.sql;
Input .\Layouts\init_Layouts_RouterInstruction.sql;
--Input .\Layouts\init_Layouts_RoutingRules.sql;
--Input .\Layouts\init_Layouts_RoutingZones.sql;

Input .\Layouts\init_Layouts_Selections.sql;
Input .\Layouts\init_Layouts_SerialNos.sql;
Input .\Layouts\init_Layouts_ShipLabels.sql;
Input .\Layouts\Init_Layouts_ManageLoads.sql;
Input .\Layouts\init_Layouts_ShippingAccounts.sql;
Input .\Layouts\init_Layouts_ShippingLog.sql;
Input .\Layouts\init_Layouts_ShipVias.sql;
--Input .\Layouts\init_Layouts_ShippedCounts.sql;
/* Init_Layouts_SKUPrepacks - Has to preceed SKUs layout */

Input .\Layouts\init_Layouts_SKUPrepacks.sql;
Input .\Layouts\init_Layouts_SKUPriceList.sql;

/* Init_Layouts_SKUs - Has to follow SKUPrepacks and LPNs */
Input .\Layouts\init_Layouts_SKUs.sql;
Input .\Layouts\init_Layouts_SKUVelocity.sql;
--Input .\Layouts\init_Layouts_SrtrWaveDetails.sql;

--Input .\Layouts\init_Layouts_TaskDependencies.sql;
-- Input .\Layouts\init_Layouts_ucCreateReceiver.sql;
Input .\Layouts\Init_Layouts_CreateInventory.sql;
-- Input .\Layouts\init_Layouts_UserLogin.sql;
--Input .\Layouts\init_Layouts_ucReceiveLPNs.sql;
Input .\Layouts\init_Layouts_UserControlLookupGrids.sql;
Input .\Layouts\init_Layouts_UserControlSelectWavingRule.sql;

Input .\Layouts\init_Layouts_Waves.sql;
--Input .\Layouts\init_Layouts_WaveRules.sql;
Input .\Layouts\init_Layouts_Waving.sql;
Input .\Layouts\init_Layouts_WaveSummary.sql;
Input .\Layouts\init_Layouts_WarehouseKPIs.sql;

/* cIMSV3.0 Layouts */
Input .\Layouts\Init_Layouts_CIMSDE_ExportOpenOrders.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ExportOpenReceipts.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ExportTransactions.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ExportOnhandInventory.sql;
Input .\Layouts\init_Layouts_CIMSDE_ExportInvSnapshot.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ExportShippedLoads.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportASNLPNDetails.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportASNLPNs.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportCartonTypes.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportContacts.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportInvAdjustments.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportNotes.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportOrderDetails.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportOrderHeaders.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportReceiptDetails.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportReceiptHeaders.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportResults.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportSKUPrePacks.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportSKUs.sql;
Input .\Layouts\Init_Layouts_CIMSDE_ImportUPCs.sql;

Input .\Layouts\Init_LayoutSummaryFields.sql;

Input .\Layouts\Init_Layouts_EntityInfo_Loads.sql;
Input .\Layouts\Init_Layouts_EntityInfo_OrderHeader.sql;
Input .\Layouts\Init_Layouts_EntityInfo_Receipts.sql;
Input .\Layouts\Init_Layouts_EntityInfo_Receiver.sql;
Input .\Layouts\Init_Layouts_EntityInfo_Wave.sql;

Go
