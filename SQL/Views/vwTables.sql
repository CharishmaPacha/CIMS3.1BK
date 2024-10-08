/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/11/24  VM      Moved all Base related from WMS to Base (CIMSV3-3213)
  2023/05/22  GAG     vwUIRolePermissions: Commented as it is invalid code here (JLCA-683)
  2022/02/25  SRS     Added vwCIMSDE_ExportInvSnapshot (BK-767)
  2021/02/05  KBB     Removed vwRoles (CIMSV3-1215)
  2020/11/20  MS      Removed vwRouterConfirmations (JL-314)
  2020/11/02  AY      Added vwReportFormats (CIMSV3-1183)
  2020/09/23  RV      Removed vwLabelFormats (CIMSV3-1079)
  2020/04/23  RKC     Added view for Note table (HA-159)
  2020/04/14  AY      Added dbo.vwCIMSDE_ImportInvAdjustments
  2020/03/24  SAK     Added View for PandaLabels Tables (CIMSV3-232)
  2020/03/18  KBB     Added View for SKUPriceList Tables (CID-1227)
  2020/02/13  AJM     Added View for DE Export Tables  (JL-49)
  2020/01/23  KBB     Added View for DCMS Tables (JL-62)
  2019/05/23  RKC     Added views for Imports table(CIMSV3-550)
  2019/05/01  SPP     Added view for RoutingRules, RoutingZones table(CIMSV3-485)
  2019/04/29  PHK     Added view for UIRolePermissions(CIMSV3-245)
  2019/04/26  SPP     Added view for Contacts table(CIMSV3-482)
  2019/04/20  KSK     Added view for roles table(CIMSV3-244)
  2019/03/30  RC      Added views for Fields and LayoutFields tables(CIMSV3-227)
  2019/03/25  AY      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*---------------------------------------------------------------------------*/
/* ExportTransactions */
if (object_id('dbo.vwCIMSDE_ExportTransactions') is not null)
  drop View dbo.vwCIMSDE_ExportTransactions;
if (object_id('CIMSDE_ExportTransactions') is not null)
  exec('Create View dbo.vwCIMSDE_ExportTransactions as select * from CIMSDE_ExportTransactions');
Go

/* ExportOnhandInventory */
if (object_id('dbo.vwCIMSDE_ExportOnhandInventory') is not null)
  drop View dbo.vwCIMSDE_ExportOnhandInventory;
if (object_id('CIMSDE_ExportOnhandInventory') is not null)
  exec('Create View dbo.vwCIMSDE_ExportOnhandInventory as select * from CIMSDE_ExportOnhandInventory')
Go

/* ExportOpenOrders */
if (object_id('dbo.vwCIMSDE_ExportOpenOrders') is not null)
  drop View dbo.vwCIMSDE_ExportOpenOrders;
if (object_id('CIMSDE_ExportOpenOrders') is not null)
  exec('Create View dbo.vwCIMSDE_ExportOpenOrders as select * from CIMSDE_ExportOpenOrders');
Go

/* ExportOpenReceipts */
if (object_id('dbo.vwCIMSDE_ExportOpenReceipts') is not null)
  drop View dbo.vwCIMSDE_ExportOpenReceipts;
if (object_id('CIMSDE_ExportOpenReceipts') is not null)
   exec('Create View dbo.vwCIMSDE_ExportOpenReceipts as select * from CIMSDE_ExportOpenReceipts');
Go

/* ExportInvSnapshot  */
if (object_id('dbo.vwCIMSDE_ExportInvSnapshot') is not null)
  drop View dbo.vwCIMSDE_ExportInvSnapshot;
if (object_id('CIMSDE_ExportInvSnapshot') is not null)
   exec('Create View dbo.vwCIMSDE_ExportInvSnapshot as select * from CIMSDE_ExportInvSnapshot');
Go

/* ExportShippedLoads */
if (object_id('dbo.vwCIMSDE_ExportShippedLoads') is not null)
  drop View dbo.vwCIMSDE_ExportShippedLoads;
if (object_id('CIMSDE_ExportShippedLoads') is not null)
   exec('Create View dbo.vwCIMSDE_ExportShippedLoads as select * from CIMSDE_ExportShippedLoads');
Go

/*---------------------------------------------------------------------------*/
/* Import ASNLPN Details */
if (object_id('dbo.vwCIMSDE_ImportASNLPNDetails') is not null)
  drop View dbo.vwCIMSDE_ImportASNLPNDetails;
if (object_id('CIMSDE_ImportASNLPNDetails') is not null)
   exec('Create View dbo.vwCIMSDE_ImportASNLPNDetails as select * from CIMSDE_ImportASNLPNDetails');
Go

/* Import ASNLPNs */
if (object_id('dbo.vwCIMSDE_ImportASNLPNs') is not null)
  drop View dbo.vwCIMSDE_ImportASNLPNs;
if (object_id('CIMSDE_ImportASNLPNs') is not null)
   exec('Create View dbo.vwCIMSDE_ImportASNLPNs as select * from CIMSDE_ImportASNLPNs');
Go

/* Import Carton Types */
if (object_id('dbo.vwCIMSDE_ImportCartonTypes') is not null)
  drop View dbo.vwCIMSDE_ImportCartonTypes;
if (object_id('CIMSDE_ImportCartonTypes') is not null)
   exec('Create View dbo.vwCIMSDE_ImportCartonTypes as select * from CIMSDE_ImportCartonTypes');
Go

/* Import Contacts */
if (object_id('dbo.vwCIMSDE_ImportContacts') is not null)
  drop View dbo.vwCIMSDE_ImportContacts;
if (object_id('CIMSDE_ImportContacts') is not null)
   exec('Create View dbo.vwCIMSDE_ImportContacts as select * from CIMSDE_ImportContacts');
Go

/* Import Inv Adjustments */
if (object_id('dbo.vwCIMSDE_ImportInvAdjustments') is not null)
  drop View dbo.vwCIMSDE_ImportInvAdjustments;
if (object_id('CIMSDE_ImportInvAdjustments') is not null)
   exec('Create View dbo.vwCIMSDE_ImportInvAdjustments as select * from CIMSDE_ImportInvAdjustments');
Go

/* Import Notes */
if (object_id('dbo.vwCIMSDE_ImportNotes') is not null)
  drop View dbo.vwCIMSDE_ImportNotes;
if (object_id('CIMSDE_ImportNotes') is not null)
   exec('Create View dbo.vwCIMSDE_ImportNotes as select * from CIMSDE_ImportNotes');
Go

/* Import OrderDetails */
if (object_id('dbo.vwCIMSDE_ImportOrderDetails') is not null)
  drop View dbo.vwCIMSDE_ImportOrderDetails;
if (object_id('CIMSDE_ImportOrderDetails') is not null)
   exec('Create View dbo.vwCIMSDE_ImportOrderDetails as select * from CIMSDE_ImportOrderDetails');
Go

/* Import Order Headers */
if (object_id('dbo.vwCIMSDE_ImportOrderHeaders') is not null)
  drop View dbo.vwCIMSDE_ImportOrderHeaders;
if (object_id('CIMSDE_ImportOrderHeaders') is not null)
   exec('Create View dbo.vwCIMSDE_ImportOrderHeaders as select * from CIMSDE_ImportOrderHeaders');
Go

/* CIMSDE_ImportReceiptDetails */
if (object_id('dbo.vwCIMSDE_ImportReceiptDetails') is not null)
  drop View dbo.vwCIMSDE_ImportReceiptDetails;
if (object_id('CIMSDE_ImportReceiptDetails') is not null)
   exec('Create View dbo.vwCIMSDE_ImportReceiptDetails as select * from CIMSDE_ImportReceiptDetails');
Go

/* CIMSDE_ImportReceiptHeaders */
if (object_id('dbo.vwCIMSDE_ImportReceiptHeaders') is not null)
  drop View dbo.vwCIMSDE_ImportReceiptHeaders;
if (object_id('CIMSDE_ImportReceiptHeaders') is not null)
   exec('Create View dbo.vwCIMSDE_ImportReceiptHeaders as select * from CIMSDE_ImportReceiptHeaders');
Go

/* CIMSDE_ImportResults */
if (object_id('dbo.vwCIMSDE_ImportResults') is not null)
  drop View dbo.vwCIMSDE_ImportResults;
if (object_id('CIMSDE_ImportResults') is not null)
   exec('Create View dbo.vwCIMSDE_ImportResults as select * from CIMSDE_ImportResults');
Go

/* CIMSDE_ImportSKUPrePacks */
if (object_id('dbo.vwCIMSDE_ImportSKUPrePacks') is not null)
  drop View dbo.vwCIMSDE_ImportSKUPrePacks;
if (object_id('CIMSDE_ImportSKUPrePacks') is not null)
   exec('Create View dbo.vwCIMSDE_ImportSKUPrePacks as select * from CIMSDE_ImportSKUPrePacks');
Go

/* CIMSDE_ImportSKUs */
if (object_id('dbo.vwCIMSDE_ImportSKUs') is not null)
  drop View dbo.vwCIMSDE_ImportSKUs;
if (object_id('CIMSDE_ImportSKUs') is not null)
   exec('Create View dbo.vwCIMSDE_ImportSKUs as select * from CIMSDE_ImportSKUs');
Go

/* CIMSDE_ImportUPCs */
if (object_id('dbo.vwCIMSDE_ImportUPCs') is not null)
  drop View dbo.vwCIMSDE_ImportUPCs;
if (object_id('CIMSDE_ImportUPCs') is not null)
  exec('Create View dbo.vwCIMSDE_ImportUPCs as select * from CIMSDE_ImportUPCs');
Go

/*---------------------------------------------------------------------------*/
/* Notes */
if object_id('dbo.vwNotes') is not null
  drop View dbo.vwNotes;
exec('Create View dbo.vwNotes as select * from Notes');
Go

--/* PandaLabels */
--if object_id('dbo.vwPandALabels') is not null
--  drop View dbo.vwPandALabels;
--exec('Create View dbo.vwPandALabels as select * from PandALabels');
--Go

/* RouterInstruction */
if object_id('dbo.vwRouterInstructions') is not null
  drop View dbo.vwRouterInstructions;
exec('Create View dbo.vwRouterInstructions as select * from RouterInstruction');
Go

--/* RoutingRules */
--if object_id('dbo.vwRoutingRules') is not null
--  drop View dbo.vwRoutingRules;
--exec('Create View dbo.vwRoutingRules as select * from RoutingRules');
--Go

--/* RoutingZones */
--if object_id('dbo.vwRoutingZones') is not null
--  drop View dbo.vwRoutingZones;
--exec('Create View dbo.vwRoutingZones as select * from RoutingZones');
--Go

/* RuleSets */
if object_id('dbo.vwRuleSets') is not null
  drop View dbo.vwRuleSets;
exec('Create View dbo.vwRuleSets as select * from RuleSets');
Go

/* SKUPriceLists */
if object_id('dbo.vwSKUPriceList') is not null
  drop View dbo.vwSKUPriceList;
exec('Create View dbo.vwSKUPriceList as select * from SKUPriceList');
Go

--/* ShipLabels */
--if object_id('dbo.vwShipLabels') is not null
--  drop View dbo.vwShipLabels;
--exec('Create View dbo.vwShipLabels as select * from ShipLabels');
--Go

/* ShippingAccounts */
if object_id('dbo.vwShippingAccounts') is not null
  drop View dbo.vwShippingAccounts;
exec('Create View dbo.vwShippingAccounts as select * from ShippingAccounts');
Go

--/* Ship Vias */
--if object_id('dbo.vwShipVias') is not null
--  drop View dbo.vwShipVias;
--exec('Create View dbo.vwShipVias as select * from ShipVias');
--Go

--/* UI Role Permissions */
--if object_id('dbo.vwUIRolePermissions') is not null
--  drop View dbo.vwUIRolePermissions;
--exec('Create View dbo.vwUIRolePermissions as select * from UIRolePermissions');

Go
