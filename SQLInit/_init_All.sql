/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/17  VM      All data initializations: InitDB.bat => _init_All.sql (CIMSV3-3625)
  2022/12/15  VM/GAG  File consolidation changes (CIMSV3-2459)
  2022/12/13  VM      Mapping files commented as they will now be processed by folder (CIMSV3-2481)
  2022/10/18  GAG     Commented few files and added few files newly (CIMSV3-1622)
  2022/01/25  VM      Added init_UIMenuDetails.sql, init_UIActionDetails.sql (CIMSV3-1872)
  2021/05/10  RV      Added Init_RoutingRules (BK-628)
  2021/09/09  MS      Added init_Mapping_Alerts.sql (BK-546)
  2021/07/24  RV      Added Init_Mapping_Carrier (BK-277)
  2021/07/18  SK      Added init_OperationTypes.sql, init_Productivity.sql (HA-2972)
  2021/07/06  MS      Added init_Mapping_ShippingDocuments.sql (BK-393)
  2021/07/02  AY      Added init_BoLs.sql (HA-2849)
  2021/06/22  SK      Moved init_fields.sql file to few places ahead as some of the setup here is used for message setup (OB2-1865)
  2021/05/24  NB      Added init_Packing(CIMSV3-156)
  2021/05/13  RV      Added Init_Mapping_UPSAPI (CIMSV3-1453)
  2021/03/24  MS      Added init_RegenerateTrackingNoOptions.sql (HA-2410)
  2021/05/22  PKK     Added Init_WaveInfo.sql (HA-2813)
  2020/11/19  VM      Added init_InterfaceFields.sql (HA-320)
  2020/11/15  MS      Removed init_LookUps.sql (CIMSV3-1210)
  2020/10/06  RBV     Added init_PickMethods.sql (CID-1488)
  2020/08/18  NB      Added init_Import_FileTypes.sql(HA-320)
  2020/08/10  NB      Added init_Reports.sql (CIMSV3-1022)
  2020/07/18  AY      Consolidate all Load info into one file
  2020/07/16  MS      Addded init_CycleCountInfo (CIMSV3-548)
  2020/07/14  NB      Commented init_DevicePrinterMapping. This should be setup from respective devices (CIMSV3-1012)
  2020/07/03  TK      Added init_PalletizationGroups (HA-1031)
  2020/06/23  KBB     Added init_FoB (HA-986)
  2020/06/15  NB      Added init_UserFilterGroups(CIMSV3-103)
  2020/06/11  RKC     Added init_Notes.sql (HA-890)
  2020/05/21  YJ      Added init_Printers.sql (CIMSV3-915)
              SV      Added init_WaveRules.sql (HA-565)
  2020/05/18  NB      Added init_DocumentType, init_DocumentClass (CIMSV3-221)
  2020/05/01  RT      Included init_InvAllocationModel (HA-312)
  2020/04/30  NB      Renamed init_FieldGroups to init_Fields_Update(CIMSV3-844)
  2020/04/20  TK      Added init_PropagatePermissions.sql (HA-69)
  2020/04/19  VM      init_BatchStatus => init_WaveStatus, init_BatchType => init_WaveType, init_PickBatchRules => init_WaveRules (CIMSV3-824)
  2020/04/10  MS      Added init_FieldGroups.sql; (CIMSV3-786)
  2020/03/30  MS      Added init_InventoryClasses.sql (HA-77)
  2020/03/30  TK      Added init_Boolean.sql (HA-69)
  2020/02/21  AY      Added init_Mapping_SizeScale
  2020/01/30  AY      Added Input .\Main\init_Sequences.sql
  2020/01/11  RT      Included init_PalletSize.sql (JL-59)
  2020/01/03  MS      Added init_CarrierOptions.sql (cIMSV3-424)
------------------------------------------------------------------------------*/

Go

/* Key Data - which would be referred to in other init scripts */
Input .\Main\init_BusinessUnits.sql;
Input .\Main\init_Sequences.sql;

/* Statuses and Types */
Input .\Main\init_Boolean.sql;
Input .\Main\init_ContactType.sql;
Input .\Main\init_ContentTemplates.sql;
Input .\Main\init_CycleCountInfo.sql;
Input .\Main\init_DataTypes.sql;
Input .\Main\init_DocumentInfo.sql;
Input .\Main\init_InventoryInfo.sql;
Input .\Main\init_LabelInfo.sql;

Input .\Main\init_LoadInfo.sql;

Input .\Main\init_LocationInfo.sql
Input .\Main\init_LPNInfo.sql;
Input .\Main\init_Notes.sql;
Input .\Main\init_OperationTypes.sql;
Input .\Main\init_OrderInfo.sql;
Input .\Main\init_Packing.sql
Input .\Main\init_PalletizationGroups.sql
Input .\Main\init_PalletInfo.sql;
Input .\Main\init_PandaLabelStatus.sql;
Input .\Main\init_Productivity.sql;
Input .\Main\init_ProductivityStatus.sql;
Input .\Main\init_PropagatePermissions.sql;
Input .\Main\init_PurgingControl.sql;
Input .\Main\init_ReceivingInfo.sql;
Input .\Main\init_ReplenishmentInfo.sql;
Input .\Main\init_RoutingRules.sql;
Input .\Main\init_SetupPermissions.sql;
Input .\Main\init_SKUInfo.sql;
Input .\Main\init_ShipLabelType.sql;
Input .\Main\init_ShipLabelEntityType.sql;
Input .\Main\init_ShipmentInfo.sql;
Input .\Main\init_Status.sql;
Input .\Main\init_StatusBitType.sql;
Input .\Main\init_TaskInfo.sql;
Input .\Main\init_UIMenuDetails.sql;
Input .\Main\init_UIActionDetails.sql;
Input .\Main\init_UserFilterGroups.sql;
Input .\Main\init_WaveRules.sql;
Input .\Main\init_WaveInfo.sql;
Input .\Main\init_PrintServiceRequestStatus.sql;

/* Flags */
Input .\Main\init_YesNo.sql;

/* Static data */
Input .\Main\init_Countries.sql;
Input .\Main\init_Interface.sql;
--Input .\Main\init_LookUps.sql;
Input .\Main\init_ShipVias.sql;
Input .\Main\init_States.sql;

/* Access - these have to be in this order only, please do not change */
Input .\Main\init_Roles.sql;
Input .\Main\init_Permissions.sql;

/* App related */
Input .\Main\init_Fields.sql;

/* Messages etc. Audit comments replaces field captions, so that should follow Messages */
Input .\Main\init_Messages.sql;
Input .\Main\init_AuditComments.sql;
Input .\Main\init_ProductivityComments.sql;

/********************************************************************************/
/* Client configuration data */
/********************************************************************************/

/* Key data that has to be initialized first */
Input .\Main\init_BasicInfo.sql;
/* init_Users has to be after Warehouses as users are to be updated with default Warehouse */
Input .\Main\init_Users.sql;

Input .\Main\init_CartonType.sql;
Input .\Main\init_CartType.sql;
Input .\Main\init_Control.sql;
Input .\Main\init_DBOBjects.sql;
Input .\Main\init_DebugControls.sql;
Input .\Main\init_ReasonCodes.sql;
Input .\Main\init_ShippingAccounts.sql;
Input .\Main\init_Zones.sql;

Input .\Main\init_EDIProcessImport.sql;
Input .\Main\init_EDIImport_Templates.sql;
Input .\Main\init_EDIImport_832.sql;
Input .\Main\init_EDIImport_832_Vionics.sql;
Input .\Main\init_EDIImport_850_Generic.sql;
Input .\Main\init_EDIImport_856_Generic.sql;
Input .\Main\init_EDIImport_940_Chrome.sql;
Input .\Main\init_EDIImport_940_Generic.sql;
Input .\Main\init_EDIImport_940_Vionics.sql;
Input .\Main\init_EDIExport_947_Vionics.sql;
Input .\Main\init_EDIExport_861_Generic.sql;
Input .\Main\init_EDIExport_947_Generic.sql;
Input .\Main\init_EDIExport_945_Generic.sql;

/* Formats */

/* Other - WIP */
Input .\Main\init_Client.sql;
Input .\Main\init_Devices.sql;
Input .\Main\init_Printers.sql;
Input .\Main\init_EventMonitor.sql;
-- This has to be after Fields
Input .\Main\init_Fields_Update.sql;
Input .\Main\init_InterfaceFields.sql;
Input .\Main\init_InterfaceInfo.sql;
Input .\Main\init_PasswordPolicys.sql;
Input .\Main\init_ProdOperations.sql;
Input .\Main\init_PutawayInfo.sql;
Input .\Main\init_Reports.sql;
--Input .\Main\init_SystemLayout.sql;
Input .\Main\init_Mapping_EDI_OrderTypes.sql;
Input .\Main\init_Mapping_EDI_Owners.sql;
Input .\Main\init_Mapping_EDI_ShipFrom.sql;
Input .\Main\init_Mapping_EDI_Warehouse.sql;
Input .\Main\init_Mapping_EDI_ReceiverId.sql;
Input .\Main\init_Mapping_EDI_SenderId.sql;

/* Rules - finally because they may have references to above initialized data */
Input .\Main\init_AllocationRules.sql;
Input .\Main\init_PutawayRules.sql;
Input .\Main\init_WaveRules.sql;

/* Generated Data */
/* FieldAttributes, Labels, LabelFormats, Layouts, EntityInfo, Forms, Rules, Selections, Mappings and EDI */
Input .\FieldAttributes;
Input .\Labels;
Input .\Main\init_LabelFormats.sql;
Input .\_init_All_Layouts.sql;
Input .\EntityInfo;
Input .\Forms;
Input .\Rules;
Input .\Selections;
Input .\Mappings;
--Input .\_init_All_EDI.sql;

Go
