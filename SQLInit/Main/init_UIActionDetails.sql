/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/11/06  RV      Added OnhandInventory_Rpt_InvSnapshot (BK-1149)
  2023/03/27  LAC     Added Waves_PreprocessOrders (BK-1036)
  2023/03/22  PKK     Added Waves_ApproveToRelease (BK-1033)
  2022/08/04  SAK     Added action Tasks_ConfirmPicks used for confrim picks to be completed (BK-864)
  2021/06/09  AJM     Added ActionProcedure name for RemoveOrdersFromWave (CIMSV3-1322)
  2022/04/08  GAG     Added new action ModifyCommercialInfo (BK-797)
  2021/09/27  KBB     Changed the actionId from ChangeSKU To LPNs_ChangeSKU (BK-623)
  2021/09/06  SJ      Waves_Rpt_WaveSKUSummary: Changed LayoutType from 'L'  to 'A' (BK-571)
  2021/07/28  NB      Added UpdateRolePermissions(CIMSV3-1341)
  2021/07/27  RV      ConvertToSetSKUs: Added (OB2-1948)
  2021/07/21  PKD     Changed the actionId from ChangeOwnership to LPNs_ChangeOwnership (OB2-1954)
  2021/07/20  VS      Added action proc for Tasks_Cancel (CIMSV3-1387)
  2021/06/29  VS      Added Action proc for GrantPermission and RevokePermission (OB2-1914)
  2021/06/23  AJM     Added ActionProcedure name for New/EditUser (CIMSV3-1523)
  2021/06/22  VM      Loads_CreateLoad: Updated with ActionProcedureName (CIMSV3-1514)
  2021/06/22  SAK     Added Action proc name for AddOrdersToWave (CIMSV3-1516)
  2021/06/18  SV      Changes as per the new action procedure pr_Loads_Action_CreateNew (CIMSV3-1517)
  2021/06/17  RKC     LookUps_Edit: Changed the SelectionCriteria to 'M' & MaxRecordsPerRun to 1000 (HA-2889)
  2021/06/16  VM      OrderDetails_Modify: ActionInputFormName - OrderDetails_ModifyOrderDetails => OrderDetails_Modify (CIMSV3-1515)
  2021/06/17  KBB     Added Actionprocedure name for Loads_Modify (CIMSV3-1501)
  2021/06/15  SJ      Added Action proc for GenerateBoLs (CIMSV3-1513)
  2021/06/10  RKC     Renamed the CancelPTLine as OrderDetails_CancelPTLine & CancelAllRemainingQuantity as OrderDetails_CancelAllRemainingQty,
                      OrderDetails_CancelPTLine & OrderDetails_CancelAllRemainingQuantity: Added ActionProcedure name (CIMSV3-1500)
  2021/06/09  VM      ModifyShipDetails: Updated with ActionProcedureName (OB2-1887)
  2021/06/24  SAK     Added proc name for AddOrdersToWave (CIMSV3-1516)
  2021/06/08  PKK     Added Action procedure name for CancelPickTicket (CIMSV3-1487)
  2021/05/31  PKK     Added procedure name for ClosePickTicket (CIMSV3-1488)
  2021/05/25  SK      Loads_ActivateShipCartons: New action setup to activate ship cartons based of Load (HA-2808)
  2021/05/20  AJM     Added ActionProcedure name for Reallocate Wave (CIMSV3-1474)
  2021/05/12  AJM     Changed the ActionId & Added ActionProcedure name for RemoveZeroQtySKUs (CIMSV3-1394)
  2021/05/10  AJM     Added ActionProcedure name for ModifyWave (CIMSV3-1462)
  2021/05/06  VM      CancelPickTicket, ClosePickTicket: ConfirmAction set to 'Y' (HA-2690)
  2021/04/30  SAK     Added Report actions for loads (HA-2674)
  2021/04/28  AJM     Changed the ActionId, Permissionname, Actionprocedurename for Change Location Profile (CIMSV3-1436)
  2021/04/26  AJM     Added ActionProcedure name for ModifyLPNType (CIMSV3-1450)
  2021/04/22  NB      OrderHeaders_Addresses: changed action procedure(HA-2309)
  2021/04/19  KBB     Added New Action LPNs_Rpt_TransferList (HA-2656)
  2021/04/15  AJM     Changed the ActionId, Permissionname, Actionprocedurename for Change Location Attributes Action (CIMSV3-1428)
  2021/04/12  AJM     Added Contacts_Add action (HA-2583)
  2021/04/12  MS      Changes to print LPNListing report from LPNs&Pallets page (HA-2597)
  2021/04/06  AY/YJ   Changes to ChangeSKU: Ported changes done by onsite team (HA-2560)
  2021/03/24  MS      ReGenerateTrackingNo: Added form to utilize (HA-2410)
  2021/03/18  OK      Added Edit contact action (HA-2317)
  2021/03/15  AY      Publish ModifyPT/ShipDetails actions in Manage Loads & allow users to update 1000 PTs (HA GoLive)
  2021/03/11  OK      Added CCLocations_CreateTasks action in CC Results page (HA-2274)
  2021/03/11  OK      Added CCLocations_CreateTasks action in CC Statistics page (HA-2248)
  2021/03/10  PHK     Added new action Loads_Rpt_BoL_Account (HA-2098)
  2021/03/03  AY      Make print LPN/Pallet labels available on entity info (HA Mock GoLive)
  2021/03/03  SK      Added new Action Loads_Rpt_ShipManifestSummary
                      Modified Loads_Rpt_ShipManifest to Loads_Rpt_ShippingManifest (HA-2103)
  2021/02/26  KBB     Added New Action LPNs_CancelShipCartons in LPN, Entityinfo Loads and Entityinfo Orders (HA-2089)
  2021/02/26  AJM     Added ActionProcedure name for Waves_ReleaseForAllocation (CIMSV3-1326)
  2021/02/25  TK      Loads_GenerateBoLs: Execute dialog with regenrate option (HA-2064)
  2021/02/19  YJ      Added VoidLPNs in Loads.EntityInfo.LPNs actions (HA-2015)
  2021/02/18  AY      Added OrderDetails actions in OH EntityInfo (HA-MockGoLive)
  2021/02/04  RBV     Added Locations_Rpt_PalletList action (HA-1923)
  2021/01/25  SJ      Added  Loads_Cancel, Loads_Modify, Waves_Cancel actions for ManageLoads & ManageWaves Pages (HA-1942)
  2021/01/11  SK      Added new action under Loads as Loads_RequestForRouting (HA-1896)
  2020/12/30  AJM     Added ActionProcedure name for ModifyPickTicket (CIMSV3-1296)
  2020/12/29  KBB     Added Wave Entity info Actions in Order details tab (HA-1826)
  2020/12/16  YJ      Included ActionProcedureName for LookUps_Add, LookUps_Edit (CIMSV3-1222)
  2020/12/16  KBB     Added New Action for CycleCountTasks_PrintLabels (HA-1793)
  2020/12/15  AJM     Added ActionProcedure name for UpdateAllowedOperations (CIMSV3-1280)
  2020/12/15  PHK     Modified ActionId as ReGenerateTrackingNo and added action proc (HA-1772)
  2020/12/15  SJ      Added New Action for Printers_ResetStatus (HA-1767)
  2020/12/15  KBB     Added New Action for CycleCountTasks_AssignToUser (HA-1792)
  2020/12/11  RT      Action to ReExport in PickTaskDetails (CID-1569)
  2020/11/25  AJM     Added ActionProcedure name for DeleteLocation (CIMSV3-1241)
  2020/11/24  KBB     Changed Caption Print Labels to Print User Labels (CIMSV3-1215)
  2020/11/23  KBB     Added New Action for ShipVias_LTLCarrierAdd & ShipVias_LTLCarrierEdit(HA-1670)
  2020/11/21  AJM     Added ActionProcedure name for ModifyPickZone (CIMSV3-1231)
  2020/11/16  SJ      Added Printers Add/Edit/Delete actions (JL-293)
  2020/11/12  KBB     Added ActionProcedure name for AssignTaskToUser (CIMSV3-1178)
  2020/11/11  KBB     Added New Action for LPNs_PrintPalletandLPNLabels (HA-1645)
  2020/11/11  MS      Added ActionProcName for ModifyCartonDetails (CIMSV3-1155)
  2020/11/10  SJ      Added Actions for Add Carton Group, Edit Carton Group, Carton Type To Group & Edit Carton Type In Group & Delete CartonType from group (HA-1621)
  2020/11/10  SJ      Added Printers Add/Edit/Delete actions (JL-293)
  2020/11/03  RV      Added LabelFormat actions (CIMSV3-1189)
  2020/11/02  AY      Added LabelFormat actions (CIMSV3-1183)
  2020/10/27  SJ      Added Proc name for Archive orders action (HA-376)
  2020/10/23  AJM     RemoveOrdersFromWave Action : Made changes to get Confirmation pop-up (HA-1627)
  2020/10/22  SJ      Added New Action Print Shipping Manifest in Loads page (HA-1593)
  2020/10/20  VS      Added proc name for ModifyReceiver action (HA-1600)
  2020/10/14  SV      Changes to utilize static form for CreateLoad action from Manage Loads (HA-1566)
  2020/09/24  VS      Added proc name for Wave_Cancel action (CIMSV3-1078)
  2020/09/22  MS      Added Receipts_ActivateRouting & ReceiptDetails_ActivateRouting (JL-251)
  2020/09/18  RKC     Added New Action Layouts_Modify, Layouts_Delete (CIMSV3-967)
  2020/09/16  MS      Added ActionProc for GenerateWaves Actions (HA-1403)
  2020/09/16  MS      Added ActionProc for the Action OrderDetails_ModifyPackCombination (HA-775)
  2020/09/13  MS      Added ReceiptDetails_PrepareforSorting
                      Modified actionproc for Receipt_PrepareforSorting (JL-236)
  2020/09/12  TK      Orders.CreateKits & CompleteRework should be grouped together (HA-1238)
  2020/09/08  RV      Included Orders_CreateKits (HA-1239)
  2020/08/26  RBV     Added Action CartonType_Add, CartonType_Edit in Carton Types page (HA-1110)
  2020/08/19  KBB     Added Print label action on ReceiverEntityInfo in LPNs Tab:(HA-1330)
  2020/08/04  MS      Added Waves_Rpt_WaveSKUSummary (HA-1262)
  2020/07/30  SJ      Added Action ChangeArrivalInfo in Receipts page (HA-1228)
  2020/07/28  PHK     Added Locations_Rpt_LPNList action (HA-1083)
  2020/07/28  NB      Renamed PrintPalletLabels to Pallets_PrintLabels, PrintLabels to Printers_PrintLabels,
                      PrintSKULabels to SKUs_PrintLabels  (CIMSV3-1029)
  2020/07/27  NB      Renamed PrintLPNLabels to LPNs_PrintLabels (CIMSV3-1029)
  2020/07/24  MS      Corrected ContextName for CCTasks page (CIMSV3-1024)
  2020/07/23  HYP     Added BoL_ShipToAddressModify Action in loads page (HA-1020)
  2020/07/21  AJM     Added OrderDetails_ModifyReworkDetails in orderdetails page (HA-1059)
  2020/07/21  SJ      Added Action UnassignUser in PickTasks page (HA-1134)
  2020/07/16  OK      Added actions to modify Load appointment details and BoL info (HA-1146, HA-1147)
  2020/07/15  SAK     Enabled LPN actions as required in Loads EntityInfo page (HA-1141)
  2020/07/15  TK      Enable LPN actions as required in EntityInfo pages (HA-1115)
  2020/07/14  TK      New Action to activate ship cartons from UI (HA-1030)
  2020/07/10  MS      Setup action CCLocations_CreateTasks (CIMSV3-548)
  2020/07/10  NB      Added UISetup_DeviceConfiguration(CIMSV3-1012)
  2020/07/10  AY      Changed Entity ReceiptOrder to Receipt
  2020/07/11  TK      New Action to Move LPNs (HA-1115)
  2020/07/07  AY      Allow multi select of ROs for Receiving reports
  2020/07/07  SAK     Added Action ModifyShipDetails in Loads Entity Info page (HA-1108)
  2020/07/07  SAK     Changed MaxRecordsPerRun as 1 for Fields_Edit action (CIMSV3-971)
  2020/07/02  TK      Added Action to Palletize LPNs (HA-1031)
  2020/07/01  TK      Added Action to create transfers load (HA-830)
  2020/06/29  NB      changes to define ParentActionId for Waves_ReleaseForAllocation for Open Waves Listing(HA-779)
  2020/06/25  SJ      Added LayoutField_Edit Action in Layout Fields page (CIMSV3-972)
  2020/06/24  AJ      Loads_PrintDocuments: Added new action for Loads to print the documents (HA-984)
  2020/06/22  SAK     Added proc name for Mapping actions (CIMSV3-811)
  2020/06/21  TK      Added Action CompleteRework (HA-834)
  2020/06/20  MS      Corrected ActionProcName for Loads_Cancel & PrintJob Actions (CIMSV3-984)
  2020/06/17  SJ      Added BoL OrderDetails Action in Loads page (HA-874)
  2020/06/17  KBB     Added BoLs Action in Loads page (HA-986)
  2020/06/17  TK      MinMaxReplenish: Should be able to select multiple locations to generate orders (HA-985)
              MS      PickTasks_PrintDocuments: ActionProcName corrected (HA-853)
  2020/06/16  AJM     Added Receipts_ChangeWarehouse action in Receipts page (HA-926)
  2020/06/12  RKC     Added Confirm as Shipped Action for Loads page (HA-897)
  2020/06/11  RV      Added RemoveOrdersFromLoad action (HA-839)
  2020/06/10  RT      Load_GenerateBoLs,Load_PrintBoLs: Included the action (HA-824)
  2020/06/10  OK      Added Load_CreateLoad action (HA-843)
  2020/06/10  YJ      Correction for PermissionName PrintLabels (HA-883)
  2020/06/09  NB      Added SetupUserFilters Action (CIMSV3-103)
              RV      Added RemoveOrdersFromLoad action (HA-839)
  2020/06/08  RKC     Added Load_Cancel action (HA-844)
  2020/06/03  AY      Task Print Documents: New action
  2020/06/03  RT      PrintJobs_Reprint: Changes in the Action (HA-650)
  2020/06/01  AJ      Waves_Modify: Changed selection criteria for this action (HA-713)
  2020/05/31  TK      Orders: Action to remove orders from wave (HA-696)
  2020/05/26  SAK     Added Action ModifyPackCombination (HA-644)
  2020/05/22  RT      Included PrintJobs_Release (HA-603)
  2020/07/03  KBB     Added Selections action(CIMSV3-966)
  2020/05/20  MS      Lookups: PermissionNames migrated from Dev (HA-605)
  2020/05/13  SJ      Added PrintWaveLabels Action (HA-490)
  2020/05/07  VS      Added GenerateReplenishOrders Action (HA-372)
  2020/05/04  SJ      Added PrintTaskLabels action (HA-370)
  2020/04/29  RT      ModifyOrderDetails: Corrected the PermissionName (HA-287)
  2020/04/16  SJ      Actions for Printers page (HA-99)
  2020/04/15  VS      Made changes for Add/Edit/DeleteRole Roles actions (HA-96)
  2020/04/15  MS      Added AdjustLPNQty (HA-181)
  2020/04/09  AJM     Added Add/Edit LookUps  (HA-91)
  2020/04/03  TK      Actions for RolePermissions page (HA-69)
  2020/04/03  YJ      Added EditControls action (CIMSV3-776)
  2020/04/03  MS      Changes to consider Task as Entity (CIMSV3-561)
  2020/03/31  MS      Changes to captions for ModifyLPNs (CIMSV3-424)
  2020/03/30  MS      Changes to consider OrderHeader as Entity (CIMSV3-424)
  2020/03/30  TK      Actions for RolePermissions page (HA-69)
  2020/03/27  PHK     Added Receipts_PrintLabels action (HA-50)
  2020/03/26  OK      Corrected Entity for SKUs actions (JL-150)
  2020/03/20  RV      LoadManagement.OpenLoads: Added CreateLoad (CIMSV3-760)
  2020/03/06  RV      Shipping: Added new action StartLoadEditing (CIMSV3-154)
  2020/01/29  MS      Changes to CancelAllRemainingQuantity Action (CIMSV3-431)
  2020/01/28  MS      Added Receipts_Rpt_PalletListing (JL-60)
  2020/01/17  NB      Changes to update ActionType for Report Actions (CIMSV3-686)
  2020/01/07  RT      ReceiptHeaders: Included New Action Receipts_PrepareforSorting (JL-59)
  2020/01/02  RT      Receivers_PrepareforReceiving: Made changes to set ConfirmAction as Y
  2019/12/02  MS      Corrections to ModifyOrderDetails Action (CIMSV3-425)
  2019/11/26  NB      Added Receipts_ReceivingSummary(CIMSV3-658)
  2019/05/22  RKC     Added Cancel Cycle Count Tasks Action for Cycle Count page (CIMSV3-549)
  2019/04/30  RT      Included Receipts_PrepareforReceiving and Receiver_PrepareforReceiving (CIMSV3-474)
  2019/04/26  MS      Added CancelAllRemainingQuantity action for Orders Page (CIMSV3-428)
  2019/04/21  MS      Added ModifyOrderDeatils action for OrderDetails page (CIMSV3-429)
  2019/03/30  MS      Added CloseOrder action for Orders Page (CIMSV3-428)
  2019/03/30  MS      Added CancelPickTicket action for Orders Page (CIMSV3-427)
  2019/03/30  MS      Added ModifyShipDetails action for Orders Page (CIMSV3-426)
  2019/03/30  MS      Added ModifyPickTicket action for Orders Page (CIMSV3-424)
  2019/02/20  MJ      Added Change Location type action for Locations page (CIMSV3-253)
  2019/02/19  MJ      Added Delete Location action for Locations page (CIMSV3-254)
  2019/02/18  RIA     Added ModifySKUAttributes, ModifySKUDimensions actions for SKUs page (CIMSV3-219)
  2018/06/29  NB      Added action GenerateWavesviaSelectedRules(CIMSV3-153)
  2018/06/22  NB      Added Action PrintLPNLabels (CIMSV3-152)
  2018/04/20  NB      Script changes to insert StartNewMenuGroup field, Re-organized LPNs actions for displaying actions grouped similar to V2 Menu (CIMSV3-152)
  2018/02/20  NB      Script changes to insert ActionId ContextName mapping to new table UIActionContexts(CIMSV3-265)
  2018/02/19  NB      Added actions for Open Waves and Unwaved Orders in Waving (CIMSV3-153)
  2018/02/14  NB      Added actions for Unwaved Orders in Waving (CIMSV3-153)
  2018/02/12  MJ      Added Modify PutawayZones & Modify PickZones action for Locations page (CIMSV3-214)
  2018/01/17  RA      Added Modify Ownership action for Receipt page (CIMSV3-217)
  2018/01/11  RV      Added ReOpen and Close Receipt action for Receipt page (CIMSV3-177)
  2018/01/08  NB      Defined MaxRecordsPerRun to VoidLPNs, ModifyLPNType, ChangeSKU actions (CIMSV3-189)
  2018/01/08  DK      Added CancelPTLine action for Orderdetails page (CIMSV3-178)
  2018/01/01  NB      Changed VoidLPN action to dynamic form action(CIMSV3-167)
  2018/01/05  YJ      Added ActivateLocations, DeactivateLocations action for Locations page (CIMSV3-174)
  2018/01/05  OK      Added CloseReceiver action for Receivers page (CIMSV3-176)
  2018/01/04  SV      Added ClearUserOnCart action for Pallets page (CIMSV3-175)
  2017/11/27  NB      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName            TName,
        @ParentActionId         TName,
        @Entity                 TEntity,
        @ExecuteDialog          TName = 'Entity/ExecuteAction',
        @ExecuteNoDialog        TName = 'Entity/ExecuteActionConfirm',
        @ExecuteReport          TName = 'Entity/ExecuteReport',
        @ExecuteReportNoDialog  TName = 'Entity/ExecuteReportConfirm';

select @ContextName = null;

/* Clear Table Entries */
delete from UIActionDetails;
delete from UIActionContexts;

/******************************************************************************/
/* Common Actions valid across the application */
insert into UIActionDetails
            (ActionId,                       PermissionName,    StartNewMenuGroup, BusinessUnit )
             output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'List.EditLayout',              'EditLayout',      0,                 BusinessUnit from vwBusinessUnits
union select 'List.AddLayout',               'AddLayout',       0,                 BusinessUnit from vwBusinessUnits
union select 'List.EditSelection',           'EditSelection',   0,                 BusinessUnit from vwBusinessUnits
union select 'List.AddSelection',            'AddSelection',    0,                 BusinessUnit from vwBusinessUnits
union select 'List.ExportCurrentPage',       'XLSExport',       0,                 BusinessUnit from vwBusinessUnits
union select 'List.ExportAllSelected',       'XLSExport',       0,                 BusinessUnit from vwBusinessUnits

/* List.LPNs Common Action Overrides
Sample script
select @ContextName = 'List.LPNs';
insert into UIActionDetails
              (ActionId,                 PermissionName,  Status,   StartNewMenuGroup, BusinessUnit )
               output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select  'List.EditSelection',      'EditSelection', 'I',      0,                 BusinessUnit from vwBusinessUnits
*/

/******************************************************************************/
/* UISetup actions */
select @ContextName    = 'UISetup',
       @ParentActionId = 'UISetup.Actions',
       @Entity         = 'UISetup';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'UISetup_DeviceConfiguration',  'UIMainMenu',                       'Device Configuration',        @ExecuteDialog,      @Entity,  'A',         'D',                  'UISetup_DeviceConfiguration', 'N',                null,                       null,                         'N',           0,                0,                 1,       'pr_UI_Action_DeviceConfiguration',                                   @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Contacts actions */
select @ContextName    = 'List.Contacts',
       @ParentActionId = 'List.Contacts.Actions',
       @Entity         = 'Contact';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Contacts_Add',                 'Contacts.Act.AddContact',         'Add Contact',                  @ExecuteDialog,      @Entity,  'A',         'D',                  'Contacts_Add',                'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_Contacts_Action_AddorEdit',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Contacts_Edit',                'Contacts.Act.EditContact',        'Edit Contact',                 @ExecuteDialog,      @Entity,  'L',         'D',                  'Contacts_Edit',               'S',                null,                       null,                         'N',           1,                0,                 1,       'pr_Contacts_Action_AddorEdit',                                       @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Controls actions */
select @ContextName    = 'List.Controls',
       @ParentActionId = 'List.Controls.Actions',
       @Entity         = 'Controls';

insert into UIActionDetails
            (ActionId,                          PermissionName,                            Caption,                      UITarget,                     Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,               SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit)
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Controls_Edit',                   'Controls.Act.Edit',                       'Edit Control',               @ExecuteDialog,               @Entity,  'A',         'D',                  'Controls_Edit',                   'S',                null,                       null,                         'N',           1,                0,                 2,       null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.CycleCountLocations actions */
select @ContextName    = 'List.CycleCountLocations',
       @ParentActionId = 'List.CycleCountLocations.Actions',
       @Entity         = 'CCLocations';

insert into UIActionDetails
            (ActionId,                       PermissionName,                               Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'CCLocations_CreateTasks',      'CycleCountLocations.Act.CreateTasks',        'Create Cycle Count Tasks',    @ExecuteDialog,      @Entity,  'A',         'D',                  'CC_CreateTasks',              'M',                null,                       null,                         'N',           1000,             0,                 1,       'pr_CycleCount_Action_CreateTasks',                                   @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.CycleCountTasks actions */
select @ContextName    = 'List.CycleCountTasks',
       @ParentActionId = 'List.CycleCountTasks.Actions',
       @Entity         = 'CycleCountTasks';

insert into UIActionDetails
            (ActionId,                       PermissionName,                               Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                             ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'CycleCountTasks_Cancel',       'CycleCountTasks.Act.Cancel',                 'Cancel Cycle Count Tasks',    @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           1000,             0,                 1,       'pr_CycleCount_Action_CancelTasks',                              @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'CycleCountTasks_AssignToUser', 'CycleCountTasks.Act.AssignToUser',           'Assign To User',              @ExecuteDialog,      @Entity,  'L',         'D',                  'CycleCountTasks_AssignToUser','M',                'Status',                   'O,N,I',                      'N',           100,              1,                 10,      'pr_CycleCount_Action_AssignUser',                               @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'CycleCountTasks_PrintLabels',  'CycleCountTasks.Act.PrintTaskLabels',        'Print Task labels',           'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           100,              1,                 20,      null,                                                            @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.CycleCountStatistics actions */
select @ContextName    = 'List.CycleCountStatistics',
       @ParentActionId = 'List.CycleCountStatistics.Actions',
       @Entity         = 'CycleCountStatistics';

/* Copy the CycleCountLocations actions that are needed for CycleCountStatistics page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('CCLocations_CreateTasks');

/******************************************************************************/
/* List.CycleCountResults actions */
select @ContextName    = 'List.CycleCountResults',
       @ParentActionId = 'List.CycleCountResults.Actions',
       @Entity         = 'CycleCountResults';

/* Copy the CycleCountLocations actions that are needed for CycleCountStatistics page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('CCLocations_CreateTasks');

/******************************************************************************/
/* List.CartonTypes actions */
select @ContextName    = 'List.CartonTypes',
       @ParentActionId = 'List.CartonTypes.Actions',
       @Entity         = 'CartonTypes';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'CartonTypes_Add',              'CartonTypes.Act.Add',              'Add Carton Type',             @ExecuteDialog,      @Entity,  'A',         'D',                  'CartonType_Add',              'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_CartonTypes_Action_AddorUpdate',                                  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'CartonTypes_Edit',             'CartonTypes.Act.Edit',             'Edit Carton Type',            @ExecuteDialog,      @Entity,  'A',         'D',                  'CartonType_Edit',             'S',                null,                       null,                         'N',           1,                0,                 2,       'pr_CartonTypes_Action_AddorUpdate',                                  @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.CartonGroups actions */
select @ContextName    = 'List.CartonGroups',
       @ParentActionId = 'List.CartonGroups.Actions',
       @Entity         = 'CartonGroups';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'CartonGroups_Add',             'CartonGroups.Act.Add',             'Add Carton Group',            @ExecuteDialog,      @Entity,  'A',         'D',                  'CartonGroup_Add',             'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_CartonGroups_Action_AddOrEdit',                                   @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'CartonGroups_Edit',            'CartonGroups.Act.Edit',            'Edit Carton Group',           @ExecuteDialog,      @Entity,  'A',         'D',                  'CartonGroup_Edit',            'S',                null,                       null,                         'N',           1,                0,                 2,       'pr_CartonGroups_Action_AddOrEdit',                                   @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'CartonGroupsCartonType_Add',   'CartonGroupCartonType.Act.Add',    'Add Carton Type To Group',    @ExecuteDialog,      @Entity,  'A',         'D',                  'CartonGroupCartonType_Add',   'N',                null,                       null,                         'N',           1,                0,                 3,       'pr_CartonGroups_Action_ModifyList',                                  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'CartonGroupsCartonType_Edit',  'CartonGroupCartonType.Act.Edit',   'Edit Carton Type In Group',   @ExecuteDialog,      @Entity,  'A',         'D',                  'CartonGroupCartonType_Edit',  'S',                null,                       null,                         'N',           1,                0,                 4,       'pr_CartonGroups_Action_ModifyList',                                  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'CartonGroupsCartonType_Delete','CartonGroupCartonType.Act.Delete', 'Delete Carton Type From Group',@ExecuteNoDialog,   @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           1,                0,                 5,       'pr_CartonGroups_Action_Delete',                                      @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Fields actions */
select @ContextName    = 'List.Fields',
       @ParentActionId = 'List.Fields.Actions',
       @Entity         = 'Fields';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Fields_Edit',                  'Fields.Act.Edit',                  'Edit Field',                  @ExecuteDialog,      @Entity,  'L',         'D',                  'Fields_Edit',                 'S',                null,                       null,                         'N',           1,                0,                 1,       'pr_Fields_Action_Edit',                                              @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.LabelFormats actions */
select @ContextName    = 'List.LabelFormats',
       @ParentActionId = 'List.LabelFormats.Actions',
       @Entity         = 'LabelFormats';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit)
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'LabelFormats_Add',             'LabelFormats.Act.Add',             'Add Label format',            @ExecuteDialog,      @Entity,  'L',         'D',                  'LabelFormats_Add',            'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_LabelFormats_Action_AddOrEdit',                                   @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LabelFormats_Edit',            'LabelFormats.Act.Edit',            'Edit Label format',           @ExecuteDialog,      @Entity,  'L',         'D',                  'LabelFormats_Edit',           'S',                null,                       null,                         'N',           1,                0,                 1,       'pr_LabelFormats_Action_AddOrEdit',                                   @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.LayoutFields actions */
select @ContextName    = 'List.LayoutFields',
       @ParentActionId = 'List.LayoutFields.Actions',
       @Entity         = 'LayoutFields';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit)
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'LayoutFields_Edit',            'LayoutFields.Act.Edit',            'Edit Layout Field',           @ExecuteDialog,      @Entity,  'L',         'D',                  'LayoutFields_Edit',           'S',                null,                       null,                         'N',           1,                0,                 1,       'pr_LayoutFields_Action_Update',                                      @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Layouts actions */
select @ContextName    = 'List.Layouts',
       @ParentActionId = 'List.Layouts.Actions',
       @Entity         = 'Layouts';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Layouts_Modify',               'Layouts.Act.Modify',               'Modify Layout',               @ExecuteDialog,      @Entity,  'A',         'D',                  'Layouts_Modify',              'S',                null,                       null,                         'N',           1,                0,                 1,       'pr_Layouts_Action_Modify',                                           @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Layouts_Delete',               'Layouts.Act.Delete',               'Delete Layout(s)',            @ExecuteNoDialog,    @Entity,  'A',         'N',                   null,                         'M',                null,                       null,                         'Y',           10,               0,                 2,       'pr_Layouts_Action_Delete',                                           @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Loads actions */
select @ContextName    = 'List.Loads',
       @ParentActionId = 'List.Loads.Actions',
       @Entity         = 'Load';

insert into UIActionDetails
            (ActionId,                                PermissionName,                             Caption,                               UITarget,               Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                               ParentActionId,  BusinessUnit)
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Loads_CreateLoad',                      'Loads.Act.CreateNew',                      'Create Load',                         @ExecuteDialog,         @Entity,  'A',         'S',                  'Load_CreateOrModify',         'N',                null,                       null,                         'N',           100,              1,                 1,       'pr_Loads_Action_CreateNew',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_CreateTransferLoad',              'Loads.Act.CreateTransferLoad',             'Create Transfer Load',                @ExecuteDialog,         @Entity,  'A',         'D',                  'Loads_CreateTransferLoad',    'N',                null,                       null,                         'N',           100,              0,                 2,       'pr_Loads_Action_CreateTransferLoad',                              @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_Modify',                          'Loads.Act.ModifyLoad',                     'Modify Load',                         @ExecuteDialog,         @Entity,  'L',         'S',                  'Load_CreateOrModify',         'S',                null,                       null,                         'N',           10,               0,                 3,       'pr_Loads_Action_Modify',                                          @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_ModifyBoLInfo',                   'Loads.Act.ModifyBoLInfo',                  'Modify BoL Info',                     @ExecuteDialog,         @Entity,  'L',         'D',                  'Loads_ModifyBoLInfo',         'S',                null,                       null,                         'N',           10,               0,                 4,       'pr_Loads_Action_ModifyBoLInfo',                                   @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_ModifyApptDetails',               'Loads.Act.ModifyApptDetails',              'Modify Appointment Details',          @ExecuteDialog,         @Entity,  'L',         'D',                  'Loads_ModifyApptDetails',     'S',                null,                       null,                         'N',           10,               0,                 5,       'pr_Loads_Action_ModifyApptDetails',                               @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Loads_GenerateBoLs',                    'Loads.Act.GenerateVICSBoLData',            'Generate BoLs',                       @ExecuteDialog,         @Entity,  'L',         'D',                  'Load_GenerateBoLs',           'M',                null,                       null,                         'Y',           10,               1,                 10,      'pr_Loads_Action_GenerateBoLs',                                    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_RequestForRouting',               'Loads.Act.RequestForRouting',              'Request For Routing',                 @ExecuteNoDialog,       @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              0,                 11,      'pr_Loads_Action_RequestForRouting',                               @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_ActivateShipCartons',             'Loads.Act.ActivateShipCartons',            'Activate Load Ship Cartons',          @ExecuteNoDialog,       @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              0,                 12,      'pr_Loads_Action_ActivateShipCartonsValidate',                     @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Loads_Cancel',                          'Loads.Act.CancelLoad',                     'Cancel Load(s)',                      @ExecuteNoDialog,       @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           10,               1,                 21,      'pr_Loads_Action_Cancel',                                          @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_MarkAsShipped',                   'Loads.Act.ConfirmAsShipped',               'Confirm Load as Shipped ',            @ExecuteNoDialog,       @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           10,               0,                 20,      'pr_Loads_Action_MarkAsShipped',                                   @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Loads_PrintLabels',                     'Loads.Act.PrintLabels',                    'Print Labels',                        'Entity/PrintLabels',   @Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           100,              1,                 90,      null,                                                              @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_PrintDocuments',                  'Loads.Act.PrintDocuments',                 'Print Documents',                     @ExecuteDialog,         @Entity,  'A',         'D',                  'Loads_PrintDocuments',        'M',                null,                       null,                         'N',           100,              0,                 91,      'pr_Loads_Action_PrintDocuments',                                  @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Loads_Rpt_BoL',                         'Loads.Rpt.PrintVICSBoLReport',             'Print BoLs',                          @ExecuteReportNoDialog, @Entity,  'L',         'N',                  null,                          'S',                null,                       null,                         'N',           10,               0,                 11,      null,                                                              @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_Rpt_BoL_Account',                 'Loads.Rpt.PrintVICSBoLReportforAccount',   'Print BoLs (Macy''s)',                @ExecuteReportNoDialog, @Entity,  'L',         'N',                  null,                          'S',                null,                       null,                         'N',           10,               0,                 12,      null,                                                              @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Loads_Rpt_ShippingManifest',            'Loads.Rpt.ShippingManifest',               'Print Shipping Manifest',             @ExecuteReportNoDialog, @Entity,  'L',         'N',                  null,                          'S',                null,                       null,                         'N',           10,               1,                 13,      null,                                                              @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_Rpt_ShippingManifest_Customs',    'Loads.Rpt.PrintShippingManifestCustoms',   'Print Customs Checklist',             @ExecuteReportNoDialog, @Entity,  'L',         'N',                  null,                          'S',                null,                       null,                         'N',           10,               0,                 15,      null,                                                              @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Loads_Rpt_ShipManifestSummary',         'Loads.Rpt.ShipManifestSummary',            'Print Shipping Manifest Summary',     @ExecuteReportNoDialog, @Entity,  'L',         'N',                  null,                          'S',                null,                       null,                         'N',           10,               0,                 14,      null,                                                              @ParentActionId, BusinessUnit from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Load.EntityInfo.BoLs actions */
select @ContextName    = 'Load_EntityInfo_BoLs',
       @ParentActionId = 'Load_EntityInfo_BoLs.Actions',
       @Entity         = 'BoL';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,               Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                               ParentActionId,  BusinessUnit)
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'BoL_Modify',                   'BoLs.Act.Modify',                  'Modify BoL',                  @ExecuteDialog,         @Entity,  'L',         'D',                  'BoLs_Modify',                 'S',                null,                       null,                         'N',           20,               1,                 1,       'pr_BoLs_Action_BoLModify',                                        @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'BoLs_ModifyShipToAddress',     'BoLs.Act.ModifyShipToaddress',     'Modify BoL ShipTo',           @ExecuteDialog,         @Entity,  'L',         'D',                  'BoLs_ModifyShipToAddress',    'S',                null,                       null,                         'N',           1,                1,                 1,       'pr_BoLs_Action_MasterBoLShipToModify',                            @ParentActionId, BusinessUnit from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Load.EntityInfo..BoLOrderDetails actions */
select @ContextName    = 'Load_EntityInfo_BoLOrderDetails',
       @ParentActionId = 'Load_EntityInfo_BoLOrderDetails.Actions',
       @Entity         = 'BoLOrderDetails';

insert into UIActionDetails
            (ActionId,                       PermissionName,                  Caption,                       UITarget,                 Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'BoLOrderDetails_Modify',       'BoLOrderDetails.Act.Modify',    'Modify BoL Order Details',    @ExecuteDialog,           @Entity,  'L',         'D',                  'BoLOrderDetails_Modify',      'S',                null,                       null,                         'N',           20,               1,                 1,       'pr_BoLs_Action_BoLOrderDetailsModify',                             @ParentActionId, BusinessUnit from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Load.EntityInfo..BoLCarrierDetails actions */
select @ContextName    = 'Load_EntityInfo_BoLCarrierDetails',
       @ParentActionId = 'Load_EntityInfo_BoLCarrierDetails.Actions',
       @Entity         = 'BoLCarrierDetails';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'BoLCarrierDetails_Modify',     'BoLCarrierDetails.Act.Modify',     'Modify BoL Carrier Details',  @ExecuteDialog,      @Entity,  'L',         'D',                  'BoLCarrierDetails_Modify',    'S',                null,                       null,                         'N',           20,               1,                 1,       'pr_BoLs_Action_BoLCarrierDetailsModify',                             @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Locations actions */
select @ContextName    = 'List.Locations',
       @ParentActionId = 'List.Locations.Actions',
       @Entity         = 'Location';

insert into UIActionDetails
            (ActionId,                       PermissionName,                               Caption,                       UITarget,               Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                     ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'ModifyPutawayZone',            'Locations.Act.ModifyPutawayZones',           'Modify Putaway Zone',         @ExecuteDialog,         @Entity,  'A',         'D',                  'Location_ModifyPutawayZone',  'M',                null,                       null,                         'N',           1000,             0,                 1,       'pr_Locations_Action_ModifyPutawayZone',                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ModifyPickZone',               'Locations.Act.ModifyPickZones',              'Modify Pick Zone',            @ExecuteDialog,         @Entity,  'A',         'D',                  'Location_ModifyPickZone',     'M',                null,                       null,                         'N',           1000,             0,                 2,       'pr_Locations_Action_ModifyPickZone',                    @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'ModifyLocationType',           'Locations.Act.ModifyLocationType',           'Change Location type',        @ExecuteDialog,         @Entity,  'A',         'D',                  'Location_ChangeType',         'M',                null,                       null,                         'N',           1000,             1,                 4,       'pr_Locations_Action_ModifyLocationType',                @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Location_ModifyAttributes',    'Locations.Act.ModifyAttributes',             'Change Location Attributes',  @ExecuteDialog,         @Entity,  'A',         'D',                  'Location_ChangeAttributes',   'M',                null,                       null,                         'N',           1000,             0,                 5,       'pr_Locations_Action_ModifyAttributes',                  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Locations_ChangeProfile',      'Locations.Act.ChangeProfile',                'Change Location Profile',     @ExecuteDialog,         @Entity,  'A',         'D',                  'Location_ChangeProfile',      'M',                null,                       null,                         'N',           1000,             0,                 6,       'pr_Locations_Action_ChangeProfile',                     @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'UpdateAllowedOperations',      'Locations.Act.UpdateAllowedOperations',      'Allowed Operations',          @ExecuteDialog,         @Entity,  'A',         'D',                  'Location_AllowedOperations',  'M',                null,                       null,                         'N',           1000,             0,                 7,       'pr_Locations_Action_UpdateAllowedOperations',           @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Activate',                     'Locations.Act.Activate',                     'Activate Location(s)',        @ExecuteNoDialog,       @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           1000,             1,                 9,       null,                                                    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Deactivate',                   'Locations.Act.Deactivate',                   'Deactivate Location(s)',      @ExecuteNoDialog,       @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           1000,             0,                 10,      null,                                                    @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'CreateLocation',               'Locations.Act.CreateNewLocation',            'Create New Location',         @ExecuteDialog,         @Entity,  'A',         'D',                  'Location_CreateLocation',     'N',                null,                       null,                         'N',           1000,             1,                 12,      null,                                                    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'DeleteLocation',               'Locations.Act.DeleteLocation',               'Delete Location(s)',          @ExecuteNoDialog,       @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           1000,             0,                 13,      'pr_Locations_Action_DeleteLocation',                    @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Location_PrintLabels',         'Locations.Act.PrintLabels',                  'Print Labels',                'Entity/PrintLabels',   @Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           1000,             1,                 90,      null,                                                    @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
/* Actions for Reports */
union select 'Locations_Rpt_LPNList',        'Locations.Rpt.LPNList',                      'LPN List Report',             @ExecuteReportNoDialog, @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'N',           1,                1,                 99,      null,                                                    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Locations_Rpt_PalletList',     'Locations.Rpt.PalletList',                   'Pallet List Report',          @ExecuteReportNoDialog, @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'N',           1,                0,                 100,     null,                                                    @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Lookups actions */
select @ContextName    = 'List.LookUps',
       @ParentActionId = 'List.LookUps.Actions',
       @Entity         = 'LookUps';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'LookUps_Add',                  'Lookups.Act.Add',                  'Add New List item',           @ExecuteDialog,      @Entity,  'A',         'D',                  'LookUp_Add',                  'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_LookUps_Action_AddOrUpdate',                                      @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LookUps_Edit',                 'Lookups.Act.Edit',                 'Edit List item',              @ExecuteDialog,      @Entity,  'A',         'D',                  'LookUp_Edit',                 'M',                null,                       null,                         'N',           1000,             0,                 2,       'pr_LookUps_Action_AddOrUpdate',                                      @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.LPNs actions */
select @ContextName    = 'List.LPNs',
       @ParentActionId = 'List.LPNs.Actions',
       @Entity         = 'LPN';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'LPNs_ChangeSKU',               'LPNs.Act.ChangeSKU',               'Modify SKU',                  @ExecuteDialog,      @Entity,  'L',         'D',                  'LPN_ChangeLPNSKU',            'M',                'Status',                   'P',                          'N',           500,              0,                 1,       'pr_LPNs_Action_ChangeSKU',                                           @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LPNs_ChangeOwnership',         'LPNs.Act.ChangeOwner',             'Change Ownership',            @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_ChangeOwnership',         'M',                'Status',                   'R,P',                        'N',           100,              0,                 2,       'pr_LPNs_Action_ModifyOwnership',                                     @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ChangeWarehouse',              'LPNs.Act.ChangeWarehouse',         'Change Warehouse',            @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_ChangeWarehouse',         'M',                'Status',                   'R,P',                        'N',           100,              0,                 3,       null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'GenerateLPNs',                 'LPNs.Act.GenerateLPNs',            'Generate LPNs',               @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_GenerateLPNs',            'N',                null,                       null,                         'N',           0,                1,                 10,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LPNs_Palletize',               'LPNs.Act.PalletizeLPNs',           'Palletize LPNs',              @ExecuteDialog,      @Entity,  'A',         'D',                  'LPNs_Palletize',              'M',                null,                       null,                         'N',           3000,             0,                 11,      'pr_LPNs_Action_PalletizeLPNs',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LPNs_BulkMove',                'LPNs.Act.MoveLPNs',                'Bulk Move LPNs',              @ExecuteDialog,      @Entity,  'A',         'D',                  'LPNs_BulkMove',               'M',                null,                       null,                         'N',           3000,             0,                 12,      'pr_LPNs_Action_BulkMove',                                            @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LPNs_ActivateShipCartons',     'LPNs.Act.ActivateShipCartons',     'Activate Ship Cartons',       @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                'LPNType',                  'S',                          'Y',           3000,             0,                 13,      'pr_LPNs_Action_ActivateShipCartons',                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'LPNs_ModifyLPNType',           'LPNs.Act.ModifyLPNType',           'Modify LPNType',              @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_ModifyType',              'M',                'Status',                   'R,P',                        'N',           500,              1,                 20,      'pr_LPNs_Action_ModifyLPNType',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ModifyLPNs',                   'LPNs.Act.ModifyLPNs',              'Update Inventory Categories', @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_Modify',                  'M',                'Status',                   'R,P',                        'N',           100,              0,                 21,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'UpdateInvExpDate',             'LPNs.Act.UpdateExpiryDate',        'Update Expiry Date',          @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_UpdateInvExpDate',        'M',                'Status',                   'R,P',                        'N',           100,              0,                 22,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Reverse-Receipt',              'LPNs.Act.Reverse-Receipt',         'Reverse Receipt',             @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_ReverseReceipt',          'M',                'Status',                   'P',                          'Y',           100,              1,                 70,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'UnallocateLPNs',               'LPNs.Act.UnallocateLPNs',          'Unallocate LPN',              @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              0,                 71,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LPNs_ModifyCartonDetails',     'LPNs.Act.ModifyCartonDetails',     'Modify Carton Type/Weight',   @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_ModifyCartonType',        'M',                'Status',                   'R,P',                        'N',           100,              0,                 72,      'pr_LPNs_Action_ModifyCartonDetails',                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LPNs_CancelShipCartons',       'LPNs.Act.CancelShipCartons',       'Cancel Ship Cartons',         @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       'S',                          'Y',           1000,             0,                 73,      'pr_LPNs_Action_CancelShipCartons',                                   @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ReGenerateTrackingNo',         'LPNs.Act.ReGenerateTrackingNo',    '(Re)Generate Tracking Number',@ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_RegenerateTrackingNo',    'M',                null,                       null,                         'Y',           500,              0,                 74,      'pr_LPNs_Action_ReGenerateTrackingNo',                                @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'LPNs_RemoveZeroQtySKUs',       'LPNs.Act.RemoveZeroQtySKUs',       'Remove Zero Qty SKUs',        @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                'LPNType',                  'L',                          'Y',           100,              1,                 80,      'pr_Locations_Action_RemoveSKUs',                                     @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'VoidLPNs',                     'LPNs.Act.VoidLPNs',                'Void LPNs',                   @ExecuteDialog,      @Entity,  'A',         'D',                  'LPN_Void',                    'M',                'Status',                   'P',                          'Y',           100,              0,                 81,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'LPNs_PrintLabels',             'LPNs.Act.PrintLabels',             'Print Labels',                'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           100,              1,                 90,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'LPNs_PrintPalletandLPNLabels', 'LPNs.Act.PrintPalletandLPNLabels', 'Print Pallet & LPNs Labels',  @ExecuteDialog,      @Entity,  'A',         'D',                  'LPNs_PrintPalletandLPNLabels','M',                null,                       null,                         'N',           100,              1,                 100,     'pr_LPNs_Action_PrintPalletandLPNLabels',                             @ParentActionId, BusinessUnit from vwBusinessUnits

/*----------------*/
union select 'LPNs_Rpt_TransferList',        'LPNs.Rpt.TransferList',            'Transfer LPN Report',         @ExecuteReportNoDialog, @Entity,'L',        'N',                  null,                          'M',                null,                       null,                         'N',           100,              0,                 103,     null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits

/* Copy the Location actions that are needed for LPNs page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('Locations_Rpt_LPNList');

/******************************************************************************/
/* RCV.EntityInfo.LPNs actions */
select @ContextName    = 'RCV_EntityInfo_LPNs',
       @ParentActionId = 'RCV_EntityInfo_LPNs.Actions',
       @Entity         = 'LPN';

/* Copy the LPN actions that are needed for Receivers page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('LPNs_Palletize', 'LPNs_BulkMove', 'LPNs_PrintLabels');

/*----------------------------------------------------------------------------*/
/* OH.EntityInfo.LPNs actions */
select @ContextName    = 'OH_EntityInfo_LPNs',
       @ParentActionId = 'OH_EntityInfo_LPNs.Actions',
       @Entity         = 'LPN';

/* Copy the LPN actions that are needed for Orders page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('LPNs_Palletize', 'LPNs_BulkMove', 'LPNs_ActivateShipCartons', 'ReGenerateTrackingNo', 'LPNs_PrintLabels');

/*----------------------------------------------------------------------------*/
/* Wave.EntityInfo.LPNs actions */
select @ContextName    = 'Wave_EntityInfo_LPNs',
       @ParentActionId = 'Wave_EntityInfo_LPNs.Actions',
       @Entity         = 'LPN';

/* Copy the LPN actions that are needed for Waves page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('LPNs_Palletize', 'LPNs_BulkMove', 'LPNs_ActivateShipCartons', 'ReGenerateTrackingNo', 'LPNs_PrintLabels');

/*----------------------------------------------------------------------------*/
/* Load.EntityInfo.LPNs actions */
select @ContextName    = 'Load_EntityInfo_LPNs',
       @ParentActionId = 'Load_EntityInfo_LPNs.Actions',
       @Entity         = 'LPN';

/* Copy the LPN actions that are needed for Loads page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('LPNs_Palletize', 'LPNs_BulkMove', 'LPNs_ActivateShipCartons', 'ReGenerateTrackingNo', 'LPNs_ModifyCartonDetails', 'LPNs_PrintLabels');

/******************************************************************************/
/* List.LPNDetails actions */
select @ContextName    = 'List.LPNDetails',
       @ParentActionId = 'List.LPNDetails.Actions',
       @Entity         = 'LPNDetails';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'LPNDetail_AdjustQty',          'LPNDetails.Act.AdjustQty',         'Adjust Quantity',             @ExecuteDialog,      @Entity,  'L',         'D',                  'LPNDetail_AdjustQty',         'S',                null,                       null,                         'N',           1,                0,                 1,       null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.ManagePermissions actions */
select @ContextName    = 'List.ManagePermissions',
       @ParentActionId = 'List.ManagePermissions.Actions',
       @Entity         = 'RolePermissions';

insert into UIActionDetails
            (ActionId,                       PermissionName,      Caption,                 UITarget,                 Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,  SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction,  MaxRecordsPerRun,  StartNewMenuGroup,  SortSeq,  ActionProcedureName,                       ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'UpdateRolePermissions',        'RolePermissions',  'Update Role Permissions', @ExecuteNoDialog,        @Entity,  'A',         'N',                  null,                 'N',                null,                       null,                         'N',            0,                 0,                  1,        'pr_Access_Action_UpdateRolePermissions',  @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Mapping actions */
select @ContextName    = 'List.Mapping',
       @ParentActionId = 'List.Mapping.Actions',
       @Entity         = 'Mapping';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Mapping_Add',                  'Mapping.Act.Add',                  'Create Mapping',              @ExecuteDialog,      @Entity,  'A',         'D',                  'Mapping_Add',                 'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_Mapping_Action_AddorUpdate',                                      @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Mapping_Edit',                 'Mapping.Act.Edit',                 'Edit Mapping',                @ExecuteDialog,      @Entity,  'A',         'D',                  'Mapping_Edit',                'M',                null,                       null,                         'N',           100,              0,                 2,       'pr_Mapping_Action_AddorUpdate',                                      @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Mapping_Delete',               'Mapping.Act.Delete',               'Delete Mapping',              @ExecuteNoDialog,    @Entity,  'A',         'N',                   null,                         'M',                null,                       null,                         'Y',           100,              0,                 3,       'pr_Mapping_Action_Delete',                                           @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.OnhandInventory actions */
select @ContextName    = 'List.OnhandInventory',
       @ParentActionId = 'List.OnhandInventory.Actions',
       @Entity         = 'OnhandInventory';

insert into UIActionDetails
            (ActionId,                          PermissionName,                     Caption,                       UITarget,               Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction,  ConfirmChangeToSubmit,  MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      /* Actions for Reports */
      select 'OnhandInventory_Rpt_InvSnapshot', 'OnhandInventory.Rpt.InvSnapshot',  'Inventory Snapshot',          @ExecuteReportNoDialog, @Entity,  'L',         'N',                  null,                          'Multiple',         null,                       null,                         'N',            'No',                   10,               0,                 50,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Orders actions */
select @ContextName    = 'List.Orders',
       @ParentActionId = 'List.Orders.Actions',
       @Entity         = 'OrderHeader';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'ModifyPickTicket',             'Orders.Act.ModifyPickTicket',      'Modify Pick Ticket',          @ExecuteDialog,      @Entity,  'L',         'D',                  'Order_ModifyPickTicket',      'M',                null,                       null,                         'N',           1000,             0,                 10,      'pr_OrderHeaders_Action_ModifyPickTicket',                            @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ModifyShipDetails',            'Orders.Act.ModifyShipDetails',     'Modify Ship Details',         @ExecuteDialog,      @Entity,  'A',         'D',                  'Order_ModifyShipDetails',     'M',                null,                       null,                         'N',           1000,             0,                 11,      'pr_OrderHeaders_Action_ModifyShipDetails',                           @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'RemoveOrdersFromWave',         'Orders.Act.RemoveOrdersFromWave',  'Remove Order(s) from Wave',   @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              1,                 20,      'pr_OrderHeaders_Action_RemoveOrdersFromWave',                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'CancelPickTicket',             'Orders.Act.CancelPickTicket',      'Cancel Pick Ticket',          @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'S',                null,                       null,                         'Y',           100,              1,                 30,      'pr_OrderHeaders_Action_CancelPickTicket',                            @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ClosePickTicket',              'Orders.Act.ClosePickTicket',       'Close Pick Ticket',           @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'S',                null,                       null,                         'Y',           100,              0,                 40,      'pr_OrderHeaders_Action_ClosePickTicket',                             @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'ConvertToSetSKUs',             'Orders.Act.ConvertToSetSKUs',      'Convert To Set SKUs',         @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              0,                 18,      'pr_OrderHeaders_Action_ConvertToSetSKUs',                            @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Orders_CreateKits',            'Orders.Act.CreateKits',            'Create Kits',                 @ExecuteDialog,      @Entity,  'L',         'S',                  'CreateKits',                  'S',                null,                       null,                         'N',           100,              1,                 45,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'CompleteRework',               'Orders.Act.CompleteRework',        'Complete Rework',             @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'S',                null,                       null,                         'N',           1,                0,                 50,      'pr_OrderHeaders_Action_CompleteRework',
                                                                                                                                                                                                                                                                                                                                                                                                                                  @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------------------------------------------------------------------*/
/* Load.EntityInfo.Orders actions */
select @ContextName    = 'Load_EntityInfo_Orders',
       @ParentActionId = 'Load_EntityInfo_Orders.Actions',
       @Entity         = 'OrderHeader';

/* Copy some of the Order actions to show in Load Entity Info */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('ModifyPickTicket', 'ModifyShipDetails');

/*----------------------------------------------------------------------------*/
/* Wave.EntityInfo.Orders actions */
select @ContextName    = 'Wave_EntityInfo_Orders',
       @ParentActionId = 'Wave_EntityInfo_Orders.Actions',
       @Entity         = 'OrderHeader';

/* Copy some of the Order actions to show in Wave Entity Info */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('ModifyPickTicket', 'ModifyShipDetails');

/******************************************************************************/
/* List.OrderDetails actions */
select @ContextName    = 'List.OrderDetails',
       @ParentActionId = 'List.OrderDetails.Actions',
       @Entity         = 'OrderDetails';

insert into UIActionDetails
            (ActionId,                                    PermissionName,                           Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,                 SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'OrderDetails_Modify',                       'OrderDetails.Act.ModifyOrderDetails',    'Modify Order Details',        @ExecuteDialog,      @Entity,  'L',         'D',                  'OrderDetails_Modify',               'S',                null,                       null,                         'N',           100,              0,                 10,      'pr_OrderDetails_Action_ModifyOrderDetails',                          @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'OrderDetails_ModifyPackCombination',        'OrderDetails.Act.ModifyPackCombination', 'Modify Pack Combination',     @ExecuteDialog,      @Entity,  'A',         'D',                  'OrderDetails_ModifyPackCombination','M',                null,                       null,                         'N',           5000,             0,                 11,      'pr_OrderDetails_Action_ModifyPackCombination',                       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'OrderDetails_ModifyReworkInfo',             'OrderDetails.Act.ModifyReworkInfo',      'Modify Rework Info',          @ExecuteDialog,      @Entity,  'A',         'D',                  'OrderDetails_ModifyReworkInfo',     'M',                null,                       null,                         'N',           100,              0,                 15,      'pr_OrderDetails_Action_ModifyReworkInfo',                            @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'OrderDetails_CancelPTLine',                 'OrderDetails.Act.CancelPTLine',          'Cancel Order Line',           @ExecuteDialog,      @Entity,  'L',         'D',                  'OrderDetails_CancelPTLine',         'S',                null,                       null,                         'N',           100,              1,                 20,      'pr_OrderDetails_Action_CancelPTLine',                                @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'OrderDetails_CancelRemainingQty',           'OrderDetails.Act.CancelCompleteLine',    'Cancel Remaining Qty',        @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                                'M',                null,                       null,                         'Y',           1000,             0,                 30,      'pr_OrderDetails_Action_CancelPTLine',                                @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* Order.EntityInfo.OrderDetails actions */
select @ContextName    = 'OH_EntityInfo_OrderDetails',
       @ParentActionId = 'OH_EntityInfo_OrderDetails.Actions',
       @Entity         = 'OrderDetails';

/* Copy the OrderDetails actions that are needed for Waves page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('OrderDetails_Modify', 'OrderDetails_ModifyPackCombination', 'OrderDetails_ModifyReworkInfo', 'OrderDetails_CancelPTLine');

/******************************************************************************/
/* Wave.EntityInfo.OrderDetails actions */
select @ContextName    = 'Wave_EntityInfo_OrderDetails',
       @ParentActionId = 'Wave_EntityInfo_OrderDetails.Actions',
       @Entity         = 'OrderDetails';

/* Copy the OrderDetails actions that are needed for Waves page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('OrderDetails_Modify', 'OrderDetails_ModifyPackCombination', 'OrderDetails_ModifyReworkInfo', 'CancelPTLine');

/******************************************************************************/
/* List.Pallets actions */
select @ContextName    = 'List.Pallets',
       @ParentActionId = 'List.Pallets.Actions',
       @Entity         = 'Pallet';

insert into UIActionDetails
            (ActionId,                       PermissionName,                 Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction,  MaxRecordsPerRun,  StartNewMenuGroup,  SortSeq,  ParentActionId, BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'GeneratePallets',              'Pallets.Act.GeneratePallets',  'Generate Pallets',            @ExecuteDialog,      @Entity,  'A',         'D',                  'Pallet_GeneratePallets',      'N',                null,                       null,                         'N',            0,                 0,                  1,        @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'GenerateCarts',                'Pallets.Act.GenerateCarts',    'Generate Carts',              @ExecuteDialog,      @Entity,  'A',         'D',                  'Pallet_GenerateCarts',        'N',                null,                       null,                         'N',            0,                 0,                  2,        @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'ClearUserOnCart',              'Pallets.Act.ClearCartUser',    'Clear User on Cart',          @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',            100,               1,                  11,       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ClearCart',                    'Pallets.Act.ClearCart',        'Clear Cart',                  @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',            20,                0,                  12,       @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Pallets_PrintLabels',          'Pallets.Act.PrintLabels',      'Print Labels',                'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',            100,               1,                  90,       @ParentActionId, BusinessUnit from vwBusinessUnits
/* Copy the Location actions that are needed for Pallets page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('Locations_Rpt_LPNList');

/*----------------------------------------------------------------------------*/
/* Wave.EntityInfo.Pallets actions */
select @ContextName    = 'Wave_EntityInfo_Pallets',
       @ParentActionId = 'Wave_EntityInfo_Pallets.Actions',
       @Entity         = 'Pallet';

/* Copy the Pallets actions that are needed for Waves page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('Pallets_PrintLabels');

/*----------------------------------------------------------------------------*/
/* Load.EntityInfo.Pallets actions */
select @ContextName    = 'Load_EntityInfo_Pallets',
       @ParentActionId = 'Load_EntityInfo_Pallets.Actions',
       @Entity         = 'Pallet';

/* Copy the Pallet actions that are needed for Loads page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('Pallets_PrintLabels');

/******************************************************************************/
/* List.PickTaskDetails actions */
select @ContextName    = 'List.PickTaskDetails',
       @ParentActionId = 'List.PickTaskDetails.Actions',
       @Entity         = 'TaskDetails';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                           ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'TaskDetails_Cancel',           'PickTaskDetails.Act.CancelLine',   'Cancel Pick',                 @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              1,                 2,       null,                                          @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'TaskDetails_Export',           'PickTaskDetails.Act.Export',       'Export Picks',                @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              1,                 3,       'pr_TaskDetails_Action_Export',                @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.PickTasks actions */
select @ContextName    = 'List.PickTasks',
       @ParentActionId = 'List.PickTasks.Actions',
       @Entity         = 'Task';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Tasks_AssignToUser',           'PickTasks.Act.AssignToUser',       'Assign To User',              @ExecuteDialog,      @Entity,  'L',         'D',                  'PickTasks_AssignToUser',      'M',                'Status',                   'O,N,I',                      'N',           100,              0,                 10,      'pr_Tasks_Action_AssignUser',                                         @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Tasks_UnassignUser',           'PickTasks.Act.UnassignUser',       'Unassign User',               @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                'Status',                   'O,N,I',                      'N',           100,              0,                 11,      'pr_Tasks_Action_UnassignUser',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'ReleaseTask',                  'PickTasks.Act.ReleaseTask',        'Release Tasks',               @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              1,                 12,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Tasks_ConfirmPicks',           'PickTasks.Act.ConfirmPicks',       'Confirm Picks Completed',     @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              1,                 13,      'pr_Tasks_Action_ConfirmPicks',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Tasks_Cancel',                 'PickTasks.Act.CancelTask',         'Cancel Pick Task',            @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              1,                 20,      'pr_Tasks_Action_Cancel',                                             @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'PickTasks_PrintLabels',        'PickTasks.Act.PrintLabels',        'Print Labels',                'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           100,              1,                 90,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'PickTasks_PrintDocuments',     'PickTasks.Act.PrintDocuments',     'Print Documents',             @ExecuteDialog,      @Entity,  'A',         'D',                  'PickTasks_PrintDocuments',    'M',                null,                       null,                         'N',           100,              0,                 91,      'pr_Tasks_Action_PrintDocuments',                                     @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
select @ContextName    = 'List.Printers',
       @ParentActionId = 'List.Printers.Actions',
       @Entity         = 'Printer';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Printers_Add',                 'Printers.Act.Add',                 'Add Printer',                 @ExecuteDialog,      @Entity,  'A',         'D',                  'Printers_Add',                'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_Printers_Action_AddOrEdit',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Printers_Edit',                'Printers.Act.Edit',                'Edit Printer',                @ExecuteDialog,      @Entity,  'A',         'D',                  'Printers_Edit',               'S',                null,                       null,                         'N',           1,                0,                 2,       'pr_Printers_Action_AddOrEdit',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Printers_Delete',              'Printers.Act.Delete',              'Delete Printer',              @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           5,                0,                 3,       'pr_Printers_Action_AddOrEdit',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Printers_ResetStatus',         'Printers.Act.ResetStatus',         'Reset Printer Status',        @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              0,                 4,       'pr_Printers_Action_ResetStatus',                                     @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Printers_PrintLabels',         'Printers.Act.PrintLabels',         'Print Labels',                'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           100,              1,                 10,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.PrintJobs actions */
select @ContextName    = 'List.PrintJobs',
       @ParentActionId = 'List.PrintJobs.Actions',
       @Entity         = 'PrintJob';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'PrintJobs_Release',            'PrintJobs.Act.Release',            'Release For Printing',        @ExecuteDialog,      @Entity,  'A',         'D',                  'PrintJobs_Release',           'M',                null,                       null,                         'N',           250,              0,                 1,       'pr_PrintJobs_Action_ReleaseForPrinting',                             @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'PrintJobs_Reprint',            'PrintJobs.Act.Reprint',            'Reprint the job',             @ExecuteDialog,      @Entity,  'A',         'D',                  'PrintJobs_Release',           'M',                null,                       null,                         'N',           250,              0,                 2,       'pr_PrintJobs_Action_Reprint',                                        @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'PrintJobs_Cancel',             'PrintJobs.Act.Cancel',             'Cancel print job',            @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           250,              1,                 90,      'pr_PrintJobs_Action_Cancel',                                         @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Receipt Header actions */
select @ContextName    = 'List.ReceiptHeaders',
       @ParentActionId = 'List.ReceiptHeaders.Actions',
       @Entity         = 'Receipt';

insert into UIActionDetails
            (ActionId,                       PermissionName,                           Caption,                       UITarget,                 Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction,  MaxRecordsPerRun,  StartNewMenuGroup,  SortSeq,  ActionProcedureName,                     ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Receipts_ModifyOwnership',     'Receipts.Act.ModifyOwnership',           'Modify Ownership',            @ExecuteDialog,           @Entity,  'A',         'D',                  'RO_ModifyOwnership',          'M',                'Status',                   'E,I,R,T',                    'N',            10,                0,                  1,        null,                                    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Receipts_ChangeWarehouse',     'Receipts.Act.ChangeWarehouse',           'Change Warehouse',            @ExecuteDialog,           @Entity,  'A',         'D',                  'Receipts_ChangeWarehouse',    'M',                'Status',                   'R,P',                        'N',            100,               0,                  2,        'pr_Receipts_Action_ChangeWarehouse',    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Receipts_ChangeArrivalInfo',   'Receipts.Act.ChangeArrivalInfo',         'Change Arrival Info',         @ExecuteDialog,           @Entity,  'A',         'D',                  'Receipts_ChangeArrivalInfo',  'M',                'Status',                   'E,I,R,T',                    'N',            10,                0,                  3,        'pr_Receipts_Action_ChangeArrivalInfo',  @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Receipts_PrepareForReceiving', 'Receipts.Act.PrepareForReceiving',       'Prepare for Receiving',       @ExecuteNoDialog,         @Entity,  'L',         'N',                  null,                          'S',                'Status',                   'E,I,R,T',                    'Y',            10,                0,                  10,       null,                                    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Receipts_SelectLPNsForQC',     'Receipts.Act.SelectLPNsForQC',           'select LPNs for QC',          @ExecuteNoDialog,         @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'N',            10,                0,                  11,       null,                                    @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Receipts_PrepareForSorting',   'Receipts.Act.PrepareForSorting',         'Prepare for Sorting',         @ExecuteDialog,           @Entity,  'A',         'D',                  'Receipt_PrepareForSorting',   'S',                null,                       null,                         'N',            1,                 1,                  12,       'pr_Receipts_Action_PrepareForSortation',@ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Receipts_ActivateRouting',     'Receipts.Act.ActivateRouting',           'Activate Routing',            @ExecuteNoDialog,         @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',            100,               0,                  13,       'pr_Receipts_Action_ActivateRouting',    @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'ROClose',                      'Receipts.Act.ROClose',                   'Close Receipt Order',         @ExecuteNoDialog,         @Entity,  'L',         'N',                  null,                          'M',                'Status',                   'E, I, R, T',                 'Y',            10,                1,                  30,       null,                                    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ROOpen',                       'Receipts.Act.ROOpen',                    'Re-Open Receipt Order',       @ExecuteNoDialog,         @Entity,  'L',         'N',                  null,                          'M',                'Status',                   'C' /* Closed */,             'Y',            10,                0,                  31,       null,                                    @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Receipts_PrintLabels',         'Receipts.Act.PrintLabels',               'Print Labels',                'Entity/PrintLabels',     @Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',            100,               1,                  40,       null,                                    @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
/* Actions for Reports */
union select 'Receipts_Rpt_ReceivingSummary','Receipts.Rpt.ReceivingSummary',          'Receiving Summary',           @ExecuteReportNoDialog,   @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'N',            1,                 1,                  50,       null,                                    @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Receipts_Rpt_PalletListing',   'Receipts.Rpt.PalletListing',             'Receiving Pallets',           @ExecuteReportNoDialog,   @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'N',            1,                 0,                  51,       null,                                    @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Receipt Details actions */
select @ContextName    = 'List.ReceiptDetails',
       @ParentActionId = 'List.ReceiptDetails.Actions',
       @Entity         = 'ReceiptDetails';

insert into UIActionDetails
            (ActionId,                             PermissionName,                           Caption,                       UITarget,                 Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction,  MaxRecordsPerRun,  StartNewMenuGroup,  SortSeq,  ActionProcedureName,                     ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'ReceiptDetails_PrepareForSorting',   'ReceiptDetails.Act.PrepareForSorting',   'Prepare for Sorting',         @ExecuteDialog,           @Entity,  'A',         'D',                  'Receipt_PrepareForSorting',   'M',                null,                       null,                         'N',            100,               0,                  1,        'pr_Receipts_Action_PrepareForSortation',@ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ReceiptDetails_ActivateRouting',     'ReceiptDetails.Act.ActivateRouting',     'Activate Routing',            @ExecuteNoDialog,         @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',            100,               0,                  2,        'pr_Receipts_Action_ActivateRouting',    @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Receivers actions */
select @ContextName    = 'List.Receivers',
       @ParentActionId = 'List.Receivers.Actions',
       @Entity         = 'Receiver';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'CreateReceiver',               'Receivers.Act.CreateReceiver',     'Create Receiver',             @ExecuteDialog,      @Entity,  'A',         'D',                  'Receiver_Create',             'N',                null,                       null,                         'N',           100,              0,                 1,       null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ModifyReceiver',               'Receivers.Act.ModifyReceiver',     'Modify Receivers',            @ExecuteDialog,      @Entity,  'A',         'D',                  'Receiver_Modify',             'S',                'Status',                   'R,P',                        'N',           10,               0,                 2,       'pr_Receivers_Action_Modify',                                         @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Receivers_SelectLPNsForQC',    'Receivers.Act.SelectLPNsForQC',    'select LPNs for QC',          @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'N',           100,              0,                 4,       null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Receivers_PrepareForReceiving','Receivers.Act.PrepareForReceiving','Prepare for Receiving',       @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'S',                'Status',                   null,                         'Y',           100,              1,                 3,       null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'CloseReceiver',                'Receivers.Act.CloseReceivers',     'Close Receivers',             @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'N',           100,              1,                 5,       null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Receivers_PrintLabels',        'Receivers.Act.PrintLabels',        'Print Labels',                'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           100,              1,                 20,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Replenish Orders actions */
select @ContextName    = 'List.ReplenishOrders',
       @ParentActionId = 'List.ReplenishOrders.Actions',
       @Entity         = 'ReplenishOrders';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'ReplenishOrders_ChangePriority',    'ReplenishOrders.Act.ChangePriority','Change Order Priority',       @ExecuteDialog,           @Entity,  'L',         'D',                 'ReplenishOrder_ChangePriority','M',                null,                       null,                         'N',            100,               0,                  1,        'pr_ReplenishOrders_Action_ChangePriority', @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ReplenishOrders_Archive',           'ReplenishOrders.Act.Archive',       'Archive Order(s)',            @ExecuteNoDialog,         @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'N',            100,               0,                  2,        'pr_ReplenishOrders_Action_Archive',        @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'ReplenishOrders_Cancel',            'ReplenishOrders.Act.Cancel',        'Cancel Orders',               @ExecuteNoDialog,         @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',            100,               1,                  10,       'pr_ReplenishOrders_Action_Cancel',         @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ReplenishOrders_Close',             'ReplenishOrders.Act.Close',         'Close Order',                 @ExecuteNoDialog,         @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',            100,               0,                  11,       'pr_ReplenishOrders_Action_Close',          @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.ReportFormats actions */
select @ContextName    = 'List.ReportFormats',
       @ParentActionId = 'List.ReportFormats.Actions',
       @Entity         = 'ReportFormats';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit)
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'ReportFormats_Add',            'ReportFormats.Act.Add',            'Add Report format',           @ExecuteDialog,      @Entity,  'L',         'D',                  'ReportFormats_Add',           'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_Reports_Action_AddOrEdit',                                        @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ReportFormats_Edit',           'ReportFormats.Act.Edit',           'Edit Report format',          @ExecuteDialog,      @Entity,  'L',         'D',                  'ReportFormats_Edit',          'S',                null,                       null,                         'N',           1,                0,                 2,       'pr_Reports_Action_AddOrEdit',                                        @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.RolePermissions actions */
select @ContextName    = 'List.RolePermissions',
       @ParentActionId = 'List.RolePermissions.Actions',
       @Entity         = 'RolePermissions';

insert into UIActionDetails
            (ActionId,                       PermissionName,                           Caption,                       UITarget,                 Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,             SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction,  MaxRecordsPerRun,  StartNewMenuGroup,  SortSeq,  ActionProcedureName,                                 ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'GrantPermission',              'RolePermissions.Act.GrantPermission',    'Grant Permission',            @ExecuteDialog,           @Entity,  'A',         'D',                  'RolePermissions_GrantOrRevoke', 'M',                null,                       null,                         'N',            1000,              0,                  1,        'pr_Access_Action_GrantOrRevokePermission',          @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'RevokePermission',             'RolePermissions.Act.RevokePermission',   'Revoke Permission',           @ExecuteDialog,           @Entity,  'A',         'D',                  'RolePermissions_GrantOrRevoke', 'M',                null,                       null,                         'N',            1000,              0,                  1,        'pr_Access_Action_GrantOrRevokePermission',          @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Roles actions */
select @ContextName    = 'List.Roles',
       @ParentActionId = 'List.Roles.Actions',
       @Entity         = 'Roles';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Role_Add',                     'Roles.Act.Add',                    'Add Role',                    @ExecuteDialog,      @Entity,  'A',         'D',                  'Roles_Add',                   'N',                null,                       null,                         'N',           100,              0,                 1,       'pr_Access_Action_ManageRole',                                        @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Role_Edit',                    'Roles.Act.Edit',                   'Edit Role',                   @ExecuteDialog,      @Entity,  'A',         'D',                  'Roles_Edit',                  'S',                null,                       null,                         'N',           1,                0,                 2,       'pr_Access_Action_ManageRole',                                        @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Role_Delete',                  'Roles.Act.Delete',                 'Delete Role',                 @ExecuteNoDialog,    @Entity,  'A',         'N',                   null,                         'S',                null,                       null,                         'Y',           100,              0,                 3,       'pr_Access_Action_ManageRole',                                        @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Replenishments actions */
select @ContextName    = 'List.ReplenishmentLocations',
       @ParentActionId = 'List.ReplenishmentLocations.Actions',
       @Entity         = 'ReplenishmentLocations';

insert into UIActionDetails
            (ActionId,                       PermissionName,                                  Caption,                       UITarget,                 Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,                       SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction,  MaxRecordsPerRun,  StartNewMenuGroup,  SortSeq,  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId,        @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'MinMaxReplenish',             'ReplenishLocations.Act.GenerateReplenishOrders', 'Generate Replenish Orders',   @ExecuteDialog,           @Entity,  'A',         'D',                  'ReplenishOrders_Generate',                'M',                null,                       null,                         'Y',            100,               0,                  1,        @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Selections actions */
select @ContextName    = 'List.Selections',
       @ParentActionId = 'List.Selections.Actions',
       @Entity         = 'Selections';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Selections_Remove',            'Selections.Act.Remove',            'Remove Selections',           @ExecuteNoDialog,    @Entity,  'L',         'N',                  null,                          'M',                null,                       null,                         'Y',           10,               0,                 1,       'pr_Selections_Action_Delete',                                        @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.ShipLabels actions */
select @ContextName    = 'List.ShipLabels',
       @ParentActionId = 'List.ShipLabels.Actions',
       @Entity         = 'ShipLabels';

/* ReGenerateTrackingNo action is already defined earlier, just need to enable it for this context */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit) select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('ReGenerateTrackingNo');

/******************************************************************************/
/* List.ShipVias actions */
select @ContextName    = 'List.ShipVias',
       @ParentActionId = 'List.ShipVias.Actions',
       @Entity         = 'ShipVias';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'ShipVias_LTLCarrierAdd',       'ShipVias.Act.LTLCarrierAdd',       'Add LTL Carrier',             @ExecuteDialog,      @Entity,  'A',         'D',                  'ShipVias_LTLCarrierAdd',      'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_ShipVias_Action_LTLCarrierAddOrEdit',                             @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ShipVias_LTLCarrierEdit',      'ShipVias.Act.LTLCarrierEdit',      'Edit LTL Carrier',            @ExecuteDialog,      @Entity,  'A',         'D',                  'ShipVias_LTLCarrierEdit',     'S',                null,                       null,                         'N',           100,              0,                 2,       'pr_ShipVias_Action_LTLCarrierAddOrEdit',                             @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ShipVias_SPGServiceAdd',       'ShipVias.Act.SPGServiceAdd',       'Add Small Package Service',   @ExecuteDialog,      @Entity,  'A',         'D',                  'ShipVias_SPGServiceAdd',      'N',                null,                       null,                         'N',           1,                1,                 11,      'pr_ShipVias_Action_SPGServiceAdd',                                   @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ShipVias_SPGServiceEdit',      'ShipVias.Act.SPGServiceEdit',      'Edit Small Package Service',  @ExecuteDialog,      @Entity,  'A',         'D',                  'ShipVias_SPGServiceEdit',     'M',                null,                       null,                         'N',           100,              0,                 12,      'pr_ShipVias_Action_SPGServiceEdit',                                  @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.SKUs actions */
select @ContextName    = 'List.SKUs',
       @ParentActionId = 'List.SKUs.Actions',
       @Entity         = 'SKU';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                   ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'ModifySKUDimensions',          'SKUs.Act.ModifyDimensions',        'Modify SKU Dimensions',       @ExecuteDialog,      @Entity,  'A',         'D',                  'SKU_ModifyDimensions',        'M',                null,                       null,                         'N',           1000,             0,                 1,       null,                                                                  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ModifyPackConfigurations',     'SKUs.Act.ModifyPackConfigurations',
                                                                                 'Modify Pack Configurations',  @ExecuteDialog,      @Entity,  'A',         'D',                  'SKU_ModifyPackConfigurations','M',                null,                       null,                         'N',           1000,             0,                 2,       null,                                                                  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ModifySKUClasses',             'SKUs.Act.ModifyClasses',           'Modify SKU Classes',          @ExecuteDialog,      @Entity,  'A',         'D',                  'SKU_ModifyClasses',           'M',                null,                       null,                         'N',           1000,             0,                 3,       null,                                                                  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'ModifyAliases',                'SKUs.Act.ModifyAliases',           'Modify Aliases',              @ExecuteDialog,      @Entity,  'A',         'D',                  'SKU_ModifyAliases',           'M',                null,                       null,                         'N',           1000,             0,                 4,       null,                                                                  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'SKU_ModifyCommercialInfo',     'SKUs.Act.ModifyCommercialInfo',    'Modify Commercial Info',      @ExecuteDialog,      @Entity,  'A',         'D',                  'SKU_ModifyCommercialInfo',    'M',                null,                       null,                         'N',           1000,             0,                 6,       'pr_SKUs_Action_ModifyCommercialInfo',                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'SKUs_PrintLabels',             'SKUs.Act.PrintLabels',             'Print Labels',                'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           100,              1,                 20,      null,                                                                  @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Users actions */
select @ContextName    = 'List.Users',
       @ParentActionId = 'List.Users.Actions',
       @Entity         = 'User';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'User_Add',                     'Users.Act.AddUser',                'Add User',                    @ExecuteDialog,      @Entity,  'A',         'D',                  'User_Add',                    'N',                null,                       null,                         'N',           1,                0,                 1,       'pr_Users_Action_AddorEdit',                                          @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'User_Edit',                    'Users.Act.EditUser',               'Edit User',                   @ExecuteDialog,      @Entity,  'A',         'D',                  'User_Edit',                   'S',                null,                       null,                         'N',           1,                0,                 2,       'pr_Users_Action_AddorEdit',                                          @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'SetupUserFilters',             'Users.Act.SetupUserFilters',       'Setup User Filters',          @ExecuteDialog,      @Entity,  'A',         'D',                  'User_SetupFilters',           'M',                null,                       null,                         'N',           20,               0,                 3,       'pr_Users_Action_SetupFilters',                                       @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Users_PrintLabels',            'Users.Act.PrintLabels',            'Print User Labels',           'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           1000,             1,                 90,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* List.Waves actions */
select @ContextName    = 'List.Waves',
       @ParentActionId = 'List.Waves.Actions',
       @Entity         = 'Wave';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Waves_Modify',                 'Waves.Act.Modify',                 'Modify Wave',                 @ExecuteDialog,      @Entity,  'A',         'D',                  'Waves_Modify',                'M',                null,                       null,                         'Y',           100,              0,                 10,      'pr_Waves_Action_Modify',           @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Waves_Plan',                   'Waves.Act.Plan',                   'Plan',                        @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                'Status',                   'E,I,R,T',                    'N',           100,              1,                 20,      null,                               @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Waves_UnPlan',                 'Waves.Act.UnPlan',                 'Un Plan',                     @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                'Status',                   'E,I,R,T',                    'N',           100,              0,                 21,      null,                               @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Waves_ReleaseForAllocation',   'Waves.Act.ReleaseForAllocation',   'Release Wave for Allocation', @ExecuteDialog,      @Entity,  'A',         'D',                  'Wave_ReleaseForAllocation',   'M',                null,                       null,                         'N',           100,              1,                 30,      'pr_Waves_Action_ReleaseForAllocation',                               @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Waves_ReleaseForPicking',      'Waves.Act.ReleaseForPicking',      'Release Wave for Picking',    @ExecuteDialog,      @Entity,  'A',         'D',                  'Wave_ReleaseForPicking',      'M',                null,                       null,                         'N',           100,              0,                 31,      null,                               @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Waves_Reallocate',             'Waves.Act.Reallocate',             'Reallocate Wave',             @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                'Status',                   'B,L,E,R,P,U,K,A,C,G',        'Y',           100,              0,                 32,      'pr_Waves_Action_Reallocate',       @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Waves_Cancel',                 'Waves.Act.Cancel',                 'Cancel Wave',                 @ExecuteNoDialog,    @Entity,  'A',         'N',                  'Waves_Cancel',                'M',                'Status',                   'N,B,L,E,R,P,U,K,A,C,G,O',    'Y',           100,              1,                 40,      'pr_Waves_Action_Cancel',           @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
union select 'Waves_PrintLabels',            'Waves.Act.PrintLabels',            'Print Labels',                'Entity/PrintLabels',@Entity,  'A',         'S',                  'PrintLabels',                 'M',                null,                       null,                         'N',           100,              1,                 90,      null,                               @ParentActionId, BusinessUnit from vwBusinessUnits
/*----------------*/
/* Actions for Reports */
union select 'Waves_Rpt_WaveSKUSummary',     'Waves.Rpt.WaveSKUSummary',         'Wave SKU Summary',            @ExecuteReportNoDialog, @Entity,'A',        'N',                  null,                          'M',                null,                       null,                         'N',            1,               1,                100,      null,                               @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* Waving.Orders actions */
select @ContextName    = 'Waving.Orders',
       @ParentActionId = 'Waving.Orders.Actions',
       @Entity         = 'OrderHeader';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                                  UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,              ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'GenerateWavesviaCustom',       'ManageWaves.Act.GenerateWaves',    'Generate Wave(s) with Custom Settings',  'Waving/Generate',   @Entity,  'A',         'S',                  'GenerateWavesCustomSetings',  'M',                null,                       null,                         'N',           3000,             0,                 1,       'pr_Waves_Action_GenerateWaves',  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'GenerateWavesviaRules',        'ManageWaves.Act.GenerateWaves',    'Generate Wave(s) via Rules',             'Waving/Generate',   @Entity,  'A',         'S',                  'GenerateWavesRules',          'M',                null,                       null,                         'N',           3000,             0,                 2,       'pr_Waves_Action_GenerateWaves',  @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'GenerateWavesviaSelectedRules','ManageWaves.Act.GenerateWaves',    'Generate Wave(s) via Selected Rules',    'Waving/Generate',   @Entity,  'A',         'S',                  'GenerateWavesRules',          'M',                null,                       null,                         'N',           3000,             0,                 3,       'pr_Waves_Action_GenerateWaves',  @ParentActionId, BusinessUnit from vwBusinessUnits

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       HandlerTagName,        UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                  ParentActionId,  BusinessUnit )
             output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'AddOrdersToWave',              'ManageWaves.Act.AddOrdersToWave',  'Add Orders(s) to Wave',       'AddOrdersToWave',     @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              1,                 20,      'pr_Waves_Action_AddOrdersToWave',    @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* Waving.Waves actions */
select @ContextName    = 'Waving.Waves',
       @ParentActionId = 'Waving.Waves.Actions',
       @Entity         = 'Wave';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       HandlerTagName,        UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                           ParentActionId,  BusinessUnit )
             output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'StartWaveEditing',             'ManageWaves.Act.AddOrdersToWave',  'Start Wave editing',          'StartWaveEditing',    'Waving/WaveDetails',@Entity,  'A',         'N',                  null,                          'S',                null,                       null,                         'Y',           null,             0,                 1,       null,                                          @ParentActionId, BusinessUnit from vwBusinessUnits

/* Wave release for action is already defined earlier, just need to enable it for this context */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit) select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('Waves_ReleaseForAllocation', 'Waves_Cancel');

/******************************************************************************/
/* ManageLoads.actions */
select @ContextName    = 'ManageLoads.OpenLoads',
       @ParentActionId = 'ManageLoads.OpenLoads.Actions',
       @Entity         = 'Load';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       HandlerTagName,        UITarget,              Entity, LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                           ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'ManageLoads_CreateLoad',       'ManageLoads.Act.CreateLoad',       'Create Load',                 null,                  @ExecuteDialog,        @Entity,'L',         'S',                  'Load_CreateOrModify',         'N',                null,                       null,                         'N',           null,             0,                 1,       'pr_Loads_Action_CreateNew',                   @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'StartLoadEditing',             'ManageLoads.Act.AddOrderToLoad',   'Start Load editing',          'StartLoadEditing',    'Shipping/LoadDetails',@Entity,'L',         'N',                  null,                          'S',                null,                       null,                         'Y',           null,             0,                 1,       null,                                          @ParentActionId, BusinessUnit from vwBusinessUnits

/* Load cancel release for action is already defined earlier, just need to enable it for this context */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit) select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('Loads_Cancel', 'Loads_Modify');

/******************************************************************************/
/* ManageLoads actions */
select @ContextName    = 'ManageLoads.OrdersToShip',
       @ParentActionId = 'ManageLoads.OrdersToShip.Actions';

insert into UIActionDetails
            (ActionId,                       PermissionName,                      Caption,                       HandlerTagName,        UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'AddOrdersToLoad',              'ManageLoads.Act.AddOrderToLoad',    'Add Orders(s) to Load',       'AddOrderToLoad',      @ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              0,                 22,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'GenerateLoad',                 'ManageLoads.Act.GenerateLoad',      'Generate Load',               null,                  @ExecuteDialog,      @Entity,  'A',         'D',                  'OrdersToShip_GenerateLoad',   'M',                null,                       null,                         'N',           1000,             1,                 21,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* MangeLoad.Orders actions */

/* Copy some of the Order actions to show in Manage Loads page */
insert into UIActionContexts (ActionId, ParentActionId, ContextName, BusinessUnit)
  select ActionId, @ParentActionId, @ContextName, BusinessUnit from UIActionDetails where ActionId in ('ModifyPickTicket', 'ModifyShipDetails');

/******************************************************************************/
/* ManageLoads actions */
select @ContextName    = 'ManageLoads.LoadOrders',
       @ParentActionId = 'ManageLoads.LoadOrders.Actions',
       @Entity         = 'PickTicket';

insert into UIActionDetails
            (ActionId,                       PermissionName,                        Caption,                     HandlerTagName,        UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'RemoveOrdersFromLoad',         'ManageLoads.Act.RemoveOrdersFromLoad','Remove Orders(s) from Load','RemoveOrdersFromLoad',@ExecuteNoDialog,    @Entity,  'A',         'N',                  null,                          'M',                null,                       null,                         'Y',           100,              1,                 20,      null,                                                                 @ParentActionId, BusinessUnit from vwBusinessUnits
/******************************************************************************/
/* Order.EntityInfo.Order actions */
select @ContextName    = 'OH_EntityInfo_Addresses',
       @ParentActionId = 'OH_EntityInfo_Addresses.Actions',
       @Entity         = 'OrderHeader';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                       UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                                                  ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'OrderHeaders_Addresses',       'OrderHeaders.Act.Addresses',       'Edit Addresses',              @ExecuteDialog,      @Entity,  'A',         'D',                  'Order_Addresses',             'S',                null,                       null,                         'N',           1,                0,                 1,       'pr_Contacts_Action_AddorEdit',                                       @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* Wave.EntityInfo.EstimatedCartons actions */
select @ContextName    = 'Wave_EntityInfo_EstimatedCartons',
       @ParentActionId = 'Wave_EntityInfo_EstimatedCartons.Actions',
       @Entity         = 'Wave';

insert into UIActionDetails
            (ActionId,                       PermissionName,                     Caption,                                  UITarget,            Entity,   LayoutType,  ActionInputFormType,  ActionInputFormName,           SelectionCriteria,  ActionActivationFieldName,  ActionActivationFieldValues,  ConfirmAction, MaxRecordsPerRun, StartNewMenuGroup, SortSeq, ActionProcedureName,                      ParentActionId,  BusinessUnit )
            output INSERTED.ActionId, @ContextName, INSERTED.BusinessUnit into UIActionContexts(ActionId, ContextName, BusinessUnit)
      select 'Waves_ApproveToRelease',       'Waves.Act.ApproveToRelease',       'Approve To Release Wave',               @ExecuteNoDialog,     @Entity,  'A',         'N',                  null,                          'Multiple',         null,                       null,                         'N',           100,              0,                  1,      'pr_Waves_Action_ApproveToRelease',       @ParentActionId, BusinessUnit from vwBusinessUnits
union select 'Waves_PreprocessOrders',       'Waves.Act.PreprocessOrders',       'Pre-process Orders',                    @ExecuteNoDialog,     @Entity,  'A',         'N',                  null,                          'Multiple',         null,                       null,                         'N',           100,              0,                  1,      'pr_OrderHeaders_Action_Preprocess',      @ParentActionId, BusinessUnit from vwBusinessUnits

/******************************************************************************/
/* Update Action Type for Report Actions */
update UIActionDetails
set ActionType = case
                   when UITarget in (@ExecuteReport, @ExecuteReportNoDialog) then 'R' /* Report action */
                   else coalesce(ActionType, 'C' /* Change action */)
                  end;

Go
