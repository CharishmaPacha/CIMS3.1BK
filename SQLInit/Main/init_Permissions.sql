/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/11/07  CHP     Added CC.Rpt.ResultsList (BK-1150)
  2023/08/22  VKN     Added permission for RFBuildInventory (CIMSV3-3034)
  2023/03/29  RKC     Added Waves.Act.PreprocessOrders (BK-1036)
  2022/08/04  SAK     Added permissions for PickTasks.Act.ConfirmPicks (BK-864)
  2022/04/21  SRP     Added SKU Velocity (BK-813)
  2022/04/08  GAG     Added SKUs.Act.ModifyCommercialInfo (BK-797)
  2022/02/28  MS      Added UserAuditLog (BK-778)
  2022/02/25  SRS     Added permission for ExportInvSnapshot (BK-767)
  2022/02/17  SRS     Added permission for LocationReplenishLevels (BK-764)
  2021/09/30  RV      Added permission CreateReceiptInventory (FBV3-265)
  2021/08/25  SK      Default deny permission for all roles for RFAllowScanAllOptionsToPick (BK-452)
  2021/07/27  RV      Added Orders.Act.ConvertToSetSKUs (OB2-1948)
  2021/07/26  SK      Added new WarehouseMetrics dashboards section (HA-3020)
  2021/07/23  SK      Added permissions for Warehouse metrics (HA-3020)
  2021/07/08  SK      Added UserProductivityDetails (HA-2972)
  2021/05/25  SK      Loads.Act.ActivateShipCartons: New permission to activate ship cartons based of Load (HA-2808)
  2021/05/11  NB      Enabled Permission for Order Packing(CIMSV3-156)
  2021/04/28  AJM     Modified permissionname from Locations.Act.ChangeLocationProfile to Locations.Act.ChangeProfile (CIMSV3-1436)
  2021/04/19  KBB     Added LPNs.Rpt.TransferList (HA-2656)
  2021/04/15  AJM     Modified permissionname from Locations.Act.ChangeLocationAttributes to Locations.Act.ModifyAttributes (CIMSV3-1428)
  2021/03/21  RKC     Added Orders.Privileges, Waves.Pri.RemoveOrdersFromReleasedWave (HA-2368)
  2021/03/18  RIA     Added permissions for returns (OB2-1357)
  2021/03/17  SAK     Added permissions for action Edit Address (HA-2309)
  2021/03/10  PHK     Added Loads.Act.PrintVICSBoLReportforAccount (HA-2098)
  2021/03/03  SK      Added Loads.Act.PrintShipManifestSummary (HA-2103)
  2021/02/26  RIA     Added RFCancelShipCartons (HA-2087)
  2021/02/26  KBB     Added LPNs.Act.CancelShipCartons (HA-2089)
  2021/02/05  MS      Added PrintJobDetails (BK-156)
  2021/02/04  RBV     Added Locations_Rpt_PalletList Report (HA-1923)
  2021/01/19  SJ      Added new permissions API Tables (CID-1594)
  2021/01/11  SK      Added new permission Loads.Act.RequestForRouting (HA-1896)
  2021/01/06  RIA     Enabled permission for RFCreateNewLPN (HA-1839)
  2020/12/17  MS      Renamed CancelWave Privileges (CIMSV3-1078)
  2020/12/16  KBB     Added Permissions for CycleCountTasks.Act.PrintTaskLabels (HA-1793)
  2020/12/15  PHK     Permission name modified as ReGenerateTrackingNo (HA-1772)
  2020/12/15  SJ      Added Permissions for Printers.Act.ResetStatus (HA-1767)
  2020/12/15  KBB     Added Permissions for CycleCountTasks.Act.AssignToUser (HA-1792)
  2020/12/03  RT      Included Permission Export in PickTaskDetails (CID-1569)
  2020/11/23  KBB     Enabled Permissions for ShipVias (HA-1670)
  2020/11/19  MS      Enabled SKUs & SKUPrepacks Excel Import (JL-312)
  2020/11/18  RIA     Added: RFSKUSetup (CIMSV3-1108)
  2020/11/18  RIA     Added RFCaptureSerialNo (CIMSV3-1211)
  2020/11/16  SJ      Added permissions for Add/Edit/Delete Printers (JL-293)
  2020/11/11  KBB     Added Permission for LPNs.Act.PrintPalletandLPNLabels (HA-1645)
  2020/11/10  SJ      Added Permissions for Add Carton Group, Edit Carton Group, CartonType To Group, Edit Carton Type In Group & Delete CartonType from group (HA-1621)
  2020/11/03  RV      Added permissions for Add/Edit Report formats (CIMSV3-1189)
  2020/11/03  VM      ReportFormats: Enabled (CIMSV3-1189)
  2020/10/23  MS      Added AllowToReceiveLPNToanotherPallet (JL-212)
  2020/10/12  RIA     Added RFStyleInquiry (HA-1569)
  2020/10/06  RKC     Added Layouts.Act.Modify, Layouts.Pri.EditStandardLayouts, Layouts.Pri.EditSystemLayouts (CIMSV3-967)
  2020/09/30  RKC     Added Layouts.Act.Modify (CIMSV3-967)
  2020/09/28  VM      Replenishments: Added RFReplenPutawayToPicklanes (CIMSV3-1101)
  2020/09/28  VM      Picking Permissions: Renamed and re-arranged (CIMSV3-1100)
  2020/09/25  VM      RFPutawayLPNOnPallet => RFPutawayToPicklanes
                      RFReplenishPutaway => RFReplenishLPNPutaway
                      RFPutawayReplenishPallet, RFPickingLocationSetup: Remove as they are not necessary
                      (CIMSV3-1101)
  2020/09/24  VM      RFAdjustLPNQuantity => RFAdjustQuantity; Removed RFAdjustLocationQuantity as both clubbed into one (HA-1468)
  2020/09/22  MS      Added Receipts.Act.ActivateRouting, ReceiptDetails.Act.ActivateRouting (JL-251)
  2020/09/17  YJ      Disabled permissions: RFAdjustLocationQuantity, RFExplodePrepack, RFTransferPallet, RFCaptureUPC, RFBatchPalletPicking,
                      RFUnitPicking, RFPutawayReplenishPallet, RFReturnDisposition, RFProcessLPN, RFTotePAPallet (HA-1418)
  2020/09/15  SJ      Enabled permissions for Receipts.Pri.CloseIncompleteRO (HA-1355)
  2020/09/14  AY      Added SerialNos
  2020/09/13  MS      Added ReceiptDetails.Act.PrepareForSorting action permissions (JL-236)
  2020/09/09  YJ      RFPutawayLPNOnPallet: Description correction as per Pavan's confirmation (HA-1358)
  2020/09/04  SK      Added ReplenishBatchPicking
  2020/09/04  YJ      Added permissions RFXferInventory, RFCompleteRework and set Active and
                      RFClosePackingCarton, RFPackingCartonContents, RFOrderInquiry, RFPutawayLPNs, RFPickingLocationSetup and set Inactive (HA-1358)
  2020/09/01  KBB     Corrected the permissions name for CycleCountTasks.Act.Cancel (CIMSV3-549)
  2020/08/26  RBV     Added Cartontypes permission(HA-1110)
  2020/08/14  NB      Added ImportFiles permission(HA-320)
  2020/08/04  MS      Rename BatchSummary Report to 'Waves.Rpt.WaveSKUSummary' (HA-1262)
  2020/07/30  SJ      Added permissions for ChangeArrivalInfo (HA-1228)
  2020/07/23  PHK     Added Location Report (HA-1083)
  2020/07/23  HYP     Added BoLs.Act.ModifyShipToAddress (HA-1020)
  2020/07/21  AJM     Added OrderDetails.Act.ModifyReworkInfo (HA-1059)
  2020/07/21  SJ      Added permissions for UnassignUser (HA-1134)
  2020/07/17  KBB     Added Permissions for CycleCountTaskDetails (CIMSV3-1024)
  2020/07/16  OK      Added Loads.Act.ModifyBoLInfo, Loads.Act.ModifyApptDetails (HA-1146, HA-1147)
  2020/07/14  KBB     Added ShippingLog (HA-1093)
  2020/07/14  TK      Added LPNs.Act.ActivateShipCartons (HA-1030)
  2020/07/13  MS      Added CycleCountLocations.Act.CreateTasks (CIMSV3-548)
  2020/07/09  TK      Added LPNs.Act.MoveLPNs (HA-1115)
  2020/07/02  TK      Added LPNs.Act.PalletizeLPNs (HA-1031)
  2020/07/01  TK      Added Loads.Act.CreateTransferLoad (HA-830)
  2020/06/30  SAK     Added Mapping.Delete (CIMSV3-1001)
  2020/06/24  AJ      Added Loads.Act.PrintDocuments permission (HA-984)
  2020/06/23  HYP     Added permission for CartonGroups (HA-796)
  2020/06/21  TK      Added Orders.Act.CompleteRework (HA-834)
  2020/06/17  SJ      Added Permissions for BoL OrderDetails (HA-874)
  2020/06/18  KBB     Added Bol's (HA-986)
  2020/06/16  AJM     Added new permission Receipts.Act.ChangeWarehouse (HA-926)
  2020/06/02  MS      Enable PrepareforSorting (JL-226)
  2020/05/26  SAK     Added new permission ModifyPackCombination (HA-644)
  2020/05/23  SK      Added new permission RFActivateShipCartons (HA-640)
  2020/05/20  KBB     Added permission for Remove Selections option(HA-549)
  2020/05/19  VM      AddSystemLayouts => AddEditSystemLayouts
                      Added AddEditStandardLayouts (HA-554)
  2020/05/18  PK      Changed PermissionNames and also re-organized permissions to match with V3 (HA-409)
  2020/05/18  SJ      Revised Permissions for Pick Tasks (HA-370)
  2020/05/18  MS      Added Notifications permission (HA-580)
  2020/05/15  VM      Added EditStandardLayouts (HA-554)
  2020/05/15  MS      Removed DashboardMenu permission since we have new permissions as Dashboards for it (HA-555)
  2020/05/14  AJM     Added permission for Cancel print job (HA-467)
  2020/05/12  SJ      Added permission for PrintWaveLabels (HA-490)
  2020/05/12  YJ      Added permission RFReceiptOrderInquiry (CIMSV3-828)
  2020/05/08  SAK     Added Mapping.Add & Mapping.Edit (CIMSV3-811)
  2020/05/04  VM      Added Maintenance -> PrintRequests (HA-251)
  2020/04/27  SV      Added Layouts.View (HA-305)
  2020/04/24  MS      Added InterfacelogDetails (HA-283)
  2020/04/23  RT      OrderDetails.ModifyOrderDetails: Activated Action (HA-287)
  2020/04/20  SAK     Added permissions UserInterface, SystemRules, ShippingConfig, BaseTables (HA-244)
  2020/04/16  SJ      Added permission for PrintLabels (HA-99)
  2020/04/15  MS      Added LPNDetails.AdjustQty permission (HA-181)
  2020/04/12  MS      Changes to Insert/Update Permissions using Stored Procedure (CIMSV3-813)
  2020/04/10  TK      Enabled permissions for Close Receiver action (CIMSV3-754)
  2020/04/08  RV      Added Permissions for PrintJobs under Maintanence (HA-48)
  2020/04/03  YJ      Added Permissions for Controls.Actions (CIMSV3-776)
  2020/04/03  VS      Added AddRoleConfig (HA-96)
  2020/04/01  TK      Added RolePermissions (HA-69)
  2020/03/31  MS      Enabled ModifyLPNs permission (HA-77)
  2020/03/30  PHK     Added Receivers.PrintLabels (HA-51)
  2020/03/24  OK      Added permission for Printers Listing (HA-46)
  2020/01/08  RT      Included PrepareForSorting (JL-59)
------------------------------------------------------------------------------*/

Go

/******************************************************************************
  All Default Permissions will be inserted into temptable and later procedure will handle
  updating other fields on Permissions Table. Client version version will have another
  file, disabling the permissions will handle in client branch.
 ******************************************************************************/

declare @ttP TPermissions;

/*                      PermissionName                     Description                        IsActive, IsVisible, SortSeq, Operation */
insert into @ttP select 'RFMainMenu',                      'RF Application',                  1,        1,         null,    'RFMainMenu'
/*-----------------*/
/* RF Main Menu Items */
/*-----------------*/
insert into @ttP select 'RFReceiving',                     'Receiving',                       1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFPutaway',                       'Putaway',                         1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFInventoryManagement',           'Inventory Management',            1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFCycleCounting',                 'Cycle Counting',                  1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFPicking',                       'Picking',                         1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFPacking',                       'Packing',                         0,        0,         null,    'RFMainMenu'
insert into @ttP select 'RFReplenishment',                 'Replenishment',                   1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFShipping',                      'Shipping',                        1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFReturns',                       'Returns',                         1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFInquiry',                       'Inquiry',                         1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFMiscellaneous',                 'Miscellaneous',                   1,        1,         null,    'RFMainMenu'
insert into @ttP select 'RFToteOperations',                'Tote Operations',                 0,        0,         null,    'RFMainMenu'
/*----------------------*/
/* Receiving Menu Items */
/*----------------------*/
insert into @ttP select 'RFReceiveToLocation',             'Receive to Location',             1,        1,         null,    'RFReceiving'
insert into @ttP select 'RFReceiveToLPN',                  'Receive to LPN',                  1,        1,         null,    'RFReceiving'
insert into @ttP select 'RFReceiveASNCase',                'Receive ASN Case',                1,        1,         null,    'RFReceiving'
insert into @ttP select 'RFReturnDisposition',             'Return Disposition',              0,        0,         null,    'RFReceiving'
insert into @ttP select 'AllowToReceiveLPNToanotherPallet','Receive LPN to alternate Pallet', 1,        1,         null,    'RFReceiving'

/*--------------------*/
/* Putaway Menu Items */
/*--------------------*/
insert into @ttP select 'RFPutawayLPN',                    'Putaway LPN',                     1,        1,         null,    'RFPutaway'
insert into @ttP select 'RFPutawayLPNs',                   'Putaway LPNs',                    0,        0,         null,    'RFPutaway'
insert into @ttP select 'RFPutawayToPicklanes',            'Putaway To Picklanes',            1,        1,         null,    'RFPutaway'
insert into @ttP select 'RFPutawayByLocation',             'Putaway By Location',             1,        1,         null,    'RFPutaway'
insert into @ttP select 'RFPutawayPallet',                 'Putaway Of Pallet',               1,        1,         null,    'RFPutaway'
--insert into @ttP select 'RFPutawayReplenishPallet',        'Putaway Replenish Pallet',        0,        0,         null,    'RFPutaway'
--insert into @ttP select 'RFPickingLocationSetup',          'Picking Location Setup',          0,        0,         null,    'RFPutaway'
insert into @ttP select 'RFCompleteProduction',            'Complete Production',             0,        0,         null,    'RFPutaway'
insert into @ttP select 'AllowPAToDiffLocation',           'Allow PA To Diff. Location',      1,        1,         null,    'RFPutaway'
insert into @ttP select 'AllowPAToDiffZone',               'Allow PA To Diff. Zone',          1,        1,         null,    'RFPutaway'

/*---------------------------------*/
/* Inventory Management Menu Items */
/*---------------------------------*/
insert into @ttP select 'RFBuildInventory',                'Build Inventory',                 1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFCreateNewLPN',                  'Create New LPN',                  1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFMoveLPN',                       'Move LPN',                        1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFAdjustQuantity',                'Adjust LPN/Location Quantity',    1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFAddSKUToLPN',                   'Add SKU To LPN',                  0,        0,         null,    'RFInventoryManagement'
insert into @ttP select 'RFChangeLPNSKU',                  'Change LPN SKU',                  0,        0,         null,    'RFInventoryManagement'
insert into @ttP select 'RFTransferInventory',             'Transfer Inventory',              1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFXferInventory',                 'Xfer Inventory',                  0,        0,         null,    'RFInventoryManagement'
insert into @ttP select 'RFManagePickLanes',               'Manage PickLanes',                1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFMovePallet',                    'Move Pallet',                     1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFBuildPallet',                   'Build Pallet',                    1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFTransferPallet',                'Transfer Pallet',                 0,        0,         null,    'RFInventoryManagement'
insert into @ttP select 'RFExplodePrepack',                'Explode Prepack',                 0,        0,         null,    'RFInventoryManagement'
insert into @ttP select 'RFTransferInventoryToEmptyLoc',   'Transfer Inventory to Empty Location',
                                                                                              1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFTransferInventoryToUnassignedLoc','Transfer Inventory to Unassigned Location',
                                                                                              1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFTransferInvenotryToInactiveLoc','Transfer Inventory to Inactive Location',
                                                                                              1,        1,         null,    'RFInventoryManagement'
insert into @ttP select 'RFSKUSetup',                      'SKU Setup',                       1,        1,         null,    'RFInventoryManagement'

/*------------------------*/
/* Cycle Count Menu Items */
/*------------------------*/
insert into @ttP select 'RFLocationCycleCount',            'Location Cycle Count',            1,        1,         null,    'RFCycleCounting'
insert into @ttP select 'RFDirectedCycleCount',            'Directed Cycle Count',            1,        1,         null,    'RFCycleCounting'

/*--------------------*/
/* Picking Menu Items */
/*--------------------*/
insert into @ttP select 'RFBatchPalletPicking',            'Batch Pallet Picking',            0,        0,         null,    'RFPicking'
insert into @ttP select 'RFBatchLPNPicking',               'LPN Picking',                     1,        1,         null,    'RFPicking'
insert into @ttP select 'RFBatchPicking',                  'Case/Unit Picking',               1,        1,         null,    'RFPicking'
insert into @ttP select 'RFBatchCasePicking',              'Case Picking',                    0,        0,         null,    'RFPicking'
insert into @ttP select 'RFBatchUnitPicking',              'Unit Picking',                    0,        0,         null,    'RFPicking'
insert into @ttP select 'RFPickToCart',                    'Pick To Cart',                    1,        1,         null,    'RFPicking'
insert into @ttP select 'RFPickToShip',                    'Pick To Ship',                    1,        1,         null,    'RFPicking'

insert into @ttP select 'RFLPNReservation',                'LPN Reservation',                 1,        1,         null,    'RFPicking'
insert into @ttP select 'RFBuildCart',                     'Build Cart',                      1,        1,         null,    'RFPicking'
insert into @ttP select 'RFDropPallet',                    'Drop Pallet',                     1,        1,         null,    'RFPicking'
insert into @ttP select 'RFConfirmTaskPicks',              'Confirm Pick Tasks',              1,        1,         null,    'RFPicking'
insert into @ttP select 'RFActivateShipCartons',           'Activate Ship Cartons',           1,        1,         null,    'RFPicking'

/*--------------------*/
/* Packing Menu Items */
/*--------------------*/
insert into @ttP select 'RFScanPacking',                   'Scan Packing',                    0,        0,         null,    'RFPacking'
insert into @ttP select 'RFStartPacking',                  'Start Packing',                   1,        1,         null,    'RFPacking'
insert into @ttP select 'RFClosePackingCarton',            'Close Packing Carton',            0,        0,         null,    'RFPacking'
insert into @ttP select 'RFPackingCartonContents',         'Packing Carton Contents',         0,        0,         null,    'RFPacking'

/*--------------------*/
/* Inquiry Menu Items */
/*--------------------*/
insert into @ttP select 'RFLocationInquiry',               'Location Inquiry',                1,        1,         null,    'RFInquiry'
insert into @ttP select 'RFLPNInquiry',                    'LPN Inquiry',                     1,        1,         null,    'RFInquiry'
insert into @ttP select 'RFSKUInquiry',                    'SKU Inquiry',                     1,        1,         null,    'RFInquiry'
insert into @ttP select 'RFPalletInquiry',                 'Pallet Inquiry',                  1,        1,         null,    'RFInquiry'
insert into @ttP select 'RFOrderInquiry',                  'Order Inquiry',                   0,        0,         null,    'RFInquiry'
insert into @ttP select 'RFReceiptOrderInquiry',           'ReceiptOrder Inquiry',            1,        1,         null,    'RFInquiry'
insert into @ttP select 'RFStyleInquiry',                  'Style Inquiry',                   1,        1,         null,    'RFInquiry'

/*----------------*/
/* Replenishments */
/*----------------*/
insert into @ttP select 'RFReplenishLPNPicking',           'Replen LPN Picking',              1,        1,         null,    'RFReplenishment'
insert into @ttP select 'RFReplenishBatchPicking',         'Replen Case/Unit Picking',        1,        1,         null,    'RFReplenishment'
insert into @ttP select 'RFReplenishCasePicking',          'Replen Case Picking',             1,        1,         null,    'RFReplenishment'
insert into @ttP select 'RFReplenishLPNPutaway',           'Replen LPN Putway',               1,        1,         null,    'RFReplenishment'
insert into @ttP select 'RFReplenPutawayToPicklanes',      'Replen Putaway To Picklanes',     1,        1,         null,    'RFReplenishment'

/*----------------*/
/* Returns */
/*----------------*/
insert into @ttP select 'RFReturnProcess',                 'Return Processing',               1,        1,         null,    'RFReturns'

/*--------------------------*/
/* Miscellaneous Menu Items */
/*--------------------------*/
insert into @ttP select 'RFCaptureUPC',                    'Manage UPCs',                     0,        0,         null,    'RFMiscellaneous'
insert into @ttP select 'RFCaptureUPC_Add',                'Add UPC',                         1,        1,         null,    'RFCaptureUPC'
insert into @ttP select 'RFCaptureUPC_Remove',             'Remove UPC',                      1,        1,         null,    'RFCaptureUPC'
insert into @ttP select 'RFCompleteRework',                'Complete Rework',                 1,        1,         null,    'RFMiscellaneous'

/*---------------------*/
/* Shipping Menu Items */
/*---------------------*/
insert into @ttP select 'RFLoad',                          'Load Pallet/LPN',                 1,        1,         null,    'RFShipping'
insert into @ttP select 'RFUnLoad',                        'UnLoad Pallet/LPN',               1,        1,         null,    'RFShipping'
insert into @ttP select 'RFCaptureTrackingNoInfo',         'Capture TrackingNo Info',         1,        1,         null,    'RFShipping'
insert into @ttP select 'RFCaptureSerialNo',               'Capture Serial Numbers',          0,        0,         null,    'RFShipping'
insert into @ttP select 'RFLPNQC',                         'LPN QC',                          1,        1,         null,    'RFShipping'
insert into @ttP select 'RFCancelShipCartons',             'Cancel Ship Cartons',             1,        1,         null,    'RFShipping'

/*----------------------------*/
/* Tote Operations Menu Items */
/*-----------------------------*/
insert into @ttP select 'RFProcessLPN',                    'Process LPN',                     0,        0,         null,    'RFToteOperations'
insert into @ttP select 'RFTotePAPallet',                  'Putaway Totes on Pallet',         0,        0,         null,    'RFToteOperations'

/*--------------------------*/
/* Batch Picking Menu Items */
/*--------------------------*/
insert into @ttP select 'RFAllowShortPick',                'Allow Short Pick',                1,        1,         null,    'RFBatchPicking'
insert into @ttP select 'RFUnMaskPick' ,                   'Allow Un Mask Pick',              1,        1,         null,    'RFBatchPicking'
insert into @ttP select 'RFAllowSkipPick',                 'Allow Skip Pick',                 1,        1,         null,    'RFBatchPicking'
insert into @ttP select 'RFAllowScanAllOptionsToPick',     'Allow scan all options to pick',  0,        1,         null,    'RFBatchPicking'

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*                                                        Permissions for UI                                                              */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
insert into @ttP select 'UIMainMenu',                      'UI Main Menu',                    1,        1,         null,    'UIMainMenu'
/*--------------------*/
/* UI Main Menu Items */
/*--------------------*/
insert into @ttP select 'ReceiveMenu',                     'Receiving',                       1,        1,         null,    'UIMainMenu'
insert into @ttP select 'InventoryMenu',                   'Inventory',                       1,        1,         null,    'UIMainMenu'
insert into @ttP select 'OrderMenu',                       'Order Fulfillment',               1,        1,         null,    'UIMainMenu'
insert into @ttP select 'ReplenishmentMenu',               'Replenishments',                  1,        1,         null,    'UIMainMenu'
insert into @ttP select 'ShippingMenu',                    'Shipping',                        1,        1,         null,    'UIMainMenu'
insert into @ttP select 'MaintenanceMenu',                 'Maintenance',                     1,        1,         null,    'UIMainMenu'
insert into @ttP select 'ReportsMenu',                     'Reports',                         1,        0,         null,    'UIMainMenu'
insert into @ttP select 'Dashboards',                      'Dashboards',                      1,        1,         null,    'UIMainMenu'
insert into @ttP select 'Interface',                       'Interface',                       0,        0,         null,    'UIMainMenu'
insert into @ttP select 'General',                         'General',                         1,        1,         null,    'UIMainMenu'
/*--------------------*/
/* Layout Permissions */
/*--------------------*/
insert into @ttP select 'Layouts.Privileges',              'Layout Privileges & Overrides',   1,        1,         null,    'General'
insert into @ttP select 'AddUserLayouts',                  'Add User Defined Layouts',        1,        1,         null,    'Layouts.Privileges'
insert into @ttP select 'AddRoleLayouts',                  'Add Role wise Layouts',           0,        0,         null,    'Layouts.Privileges'
insert into @ttP select 'AddEditSystemLayouts',            'Add/Edit System wide Layouts',    1,        1,         null,    'Layouts.Privileges'
insert into @ttP select 'AddEditStandardLayouts',          'Add/Edit Standard Layouts',       1,        0,         null,    'Layouts.Privileges'
insert into @ttP select 'DeleteLayouts',                   'Delete layouts owned by user',    1,        0,         null,    'Layouts.Privileges'
insert into @ttP select 'Layouts.Pri.EditStandardLayouts', 'Edit Standard Layout',            1,        1,         null,    'Layouts.Privileges'
insert into @ttP select 'Layouts.Pri.EditSystemLayouts',   'Edit System Layout',              1,        1,         null,    'Layouts.Privileges'
insert into @ttP select 'Layouts.Pri.EditOthersLayouts',   'Edit Layouts created by others',  1,        1,         null,    'Layouts.Privileges'
insert into @ttP select 'Layouts.Pri.DeleteOthersLayouts', 'Delete Layouts created by others',1,        1,         null,    'Layouts.Privileges'
insert into @ttP select 'DefaultLayout',                   'Apply Default Layout',            0,        0,         null,    'Layouts.Privileges'

/*----------------------------------------------------------------------------------------------------------------------------------------*/
                                                   /* Permissions for UI Sub Menu Items */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------------*/
/* Receiving Menu Items */
/*----------------------*/
insert into @ttP select 'Receipts',                        'Receipts',                        1,        1,         null,    'ReceiveMenu'
insert into @ttP select 'ReceiptDetails',                  'Receipt Details',                 1,        1,         null,    'ReceiveMenu'
insert into @ttP select 'Receivers',                       'Receivers',                       1,        1,         null,    'ReceiveMenu'
insert into @ttP select 'Vendors',                         'Vendors',                         1,        1,         null,    'ReceiveMenu'
insert into @ttP select 'Returns',                         'Return Orders',                   0,        0,         null,    'ReceiveMenu'
insert into @ttP select 'CreateReceiptInventory',          'Create Receipt Inventory',        1,        1,         null,    'ReceiveMenu'

/*----------------------*/
/* Inventory Menu Items */
/*----------------------*/
insert into @ttP select 'SKUs',                            'SKUs',                            1,        1,         null,    'InventoryMenu'
insert into @ttP select 'SKUPrepacks',                     'SKU Prepacks',                    1,        1,         null,    'InventoryMenu'
insert into @ttP select 'LPNs',                            'LPNs',                            1,        1,         null,    'InventoryMenu'
insert into @ttP select 'LPNDetails',                      'LPN Details',                     1,        1,         null,    'InventoryMenu'
insert into @ttP select 'SerialNos',                       'Serial Nos',                      0,        0,         null,    'InventoryMenu'
insert into @ttP select 'Pallets',                         'Pallets',                         1,        1,         null,    'InventoryMenu'
insert into @ttP select 'Locations',                       'Locations',                       1,        1,         null,    'InventoryMenu'
insert into @ttP select 'LocationReplenishLevels',         'Location Replen Levels',          1,        1,         null,    'InventoryMenu'
insert into @ttP select 'OnhandInventory',                 'Onhand Inventory',                1,        1,         null,    'InventoryMenu'
insert into @ttP select 'CreateInventoryLPNs',             'Create Inventory',                1,        1,         null,    'InventoryMenu'
insert into @ttP select 'CycleCount',                      'Cycle Count',                     1,        1,         null,    'InventoryMenu'
insert into @ttP select 'GenLocations',                    'Generate Locations',              0,        0,         null,    'InventoryMenu'

/*----------------------*/
/* CycleCount Items */
/*----------------------*/
insert into @ttP select 'CycleCountLocations',             'Cycle Count Locations',           1,        1,         null,    'CycleCount'
insert into @ttP select 'CycleCountTasks',                 'Cycle Count Tasks',               1,        1,         null,    'CycleCount'
insert into @ttP select 'CycleCountTaskDetails',           'Cycle Count Task Details',        1,        1,         null,    'CycleCount'
insert into @ttP select 'CycleCountStatistics',            'Cycle Count Statistics',          1,        1,         null,    'CycleCount'

/*-------------------------------*/
/* Order Fullfillment Menu Items */
/*-------------------------------*/
insert into @ttP select 'Orders',                          'Orders',                          1,        1,         null,    'OrderMenu'
insert into @ttP select 'OrderDetails',                    'Order Details',                   1,        1,         null,    'OrderMenu'
insert into @ttP select 'Waves',                           'Waves',                           1,        1,         null,    'OrderMenu'
insert into @ttP select 'ManageWaves',                     'Manage Waves',                    1,        1,         null,    'OrderMenu'
insert into @ttP select 'PickTasks',                       'Pick Tasks',                      1,        1,         null,    'OrderMenu'
insert into @ttP select 'PickTaskDetails',                 'Pick Task Details',               1,        1,         null,    'OrderMenu'

insert into @ttP select 'Customers',                       'Customers',                       1,        1,         null,    'OrderMenu'

insert into @ttP select 'BatchesToPack',                   'Packing',                         0,        0,         null,    'OrderMenu'
insert into @ttP select 'OrderPacking',                    'Order Packing',                   1,        1,         null,    'OrderMenu'
insert into @ttP select 'SLOrderPacking',                  'Single Line Order Packing',       0,        0,         null,    'OrderMenu'
insert into @ttP select 'ShippingDocs',                    'Shipping Docs',                   1,        1,         null,    'OrderMenu'

/*----------------------*/
/* Replenishments Items */
/*----------------------*/
insert into @ttP select 'ReplenishLocations',              'Manage Replenishments',           1,        1,         null,    'ReplenishmentMenu'
insert into @ttP select 'ReplenishOrders',                 'Replenish Orders',                1,        1,         null,    'ReplenishmentMenu'

/*---------------------*/
/* Shipping Menu Items */
/*---------------------*/
insert into @ttP select 'Loads',                           'Loads',                           1,        1,         null,    'ShippingMenu'
insert into @ttP select 'ManageLoads',                     'Manage Loads',                    1,        1,         null,    'ShippingMenu'
insert into @ttP select 'ShippingLog',                     'Shipping Log',                    1,        1,         null,    'ShippingMenu'

--insert into @ttP select 'Tasks',                         'Tasks',                           0,        0,         null,    'OrderMenu'
--insert into @ttP select 'Wave.PrintLabels',              'Print Labels',                    0,        0,         null,    'OrderMenu'

/*------------------------*/
/* Maintenance Menu Items */
/*------------------------*/
/*---------------------*/
/* Access & Privileges */
/*---------------------*/
insert into @ttP select 'Access&Privileges',               'Access & Privileges',             1,        1,         null,    'MaintenanceMenu'
insert into @ttP select 'Users',                           'Users',                           1,        1,         null,    'Access&Privileges'
insert into @ttP select 'Roles',                           'Roles',                           1,        1,         null,    'Access&Privileges'
insert into @ttP select 'Permission',                      'Pemrissions',                     0,        0,         null,    'Access&Privileges'
insert into @ttP select 'RolePermissions',                 'Role Permissions',                1,        1,         null,    'Access&Privileges'

/*------------------*/
/* Lists & Controls */
/*------------------*/
insert into @ttP select 'List&Controls',                   'Lists & Controls',                1,        1,         null,    'MaintenanceMenu'
insert into @ttP select 'Lookups',                         'Lists',                           1,        1,         null,    'List&Controls'
insert into @ttP select 'Controls',                        'System Controls',                 1,        1,         null,    'List&Controls'

/*---------------*/
/* Data Exchange */
/*---------------*/
insert into @ttP select 'DataExchange',                    'Data Exchange',                   1,        1,         null,    'MaintenanceMenu'
insert into @ttP select 'Exports',                         'Data Exports',                    1,        1,         null,    'DataExchange'
insert into @ttP select 'InterfaceLog',                    'Interface Log',                   1,        1,         null,    'DataExchange'
insert into @ttP select 'InterfaceLogDetails',             'Interface Log Details',           0,        0,         null,    'DataExchange'
insert into @ttP select 'Mapping',                         'Data Mappings',                   1,        1,         null,    'DataExchange'
insert into @ttP select 'ImportFiles',                     'Import Files',                    1,        1,         null,    'DataExchange'

/*-------------------------------*/
/* Data Exchange - Import Tables */
/*-------------------------------*/
insert into @ttP select 'ImportTables',                    'DE Import Tables',                1,        1,         null,    'DataExchange'
insert into @ttP select 'ImportASNLPNs',                   'ASN LPNs',                        1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportASNLPNDetails',             'ASN LPN Details',                 1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportCartonTypes',               'Carton Types',                    1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportContacts',                  'Contacts',                        1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportNotes',                     'Notes',                           1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportOrderDetails',              'Order Details',                   1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportOrderHeaders',              'Order Headers',                   1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportReceiptDetails',            'Receipt Details',                 1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportReceiptHeaders',            'Receipt Headers',                 1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportSKUPrePacks',               'SKU Prepacks',                    1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportSKUs',                      'SKUs',                            1,        1,         null,    'ImportTables'
insert into @ttP select 'ImportUPCs',                      'UPCs',                            0,        0,         null,    'ImportTables'
insert into @ttP select 'ImportResults',                   'Results',                         1,        1,         null,    'ImportTables'
/*-------------------------------*/
/* Data Exchange - Export Tables */
/*-------------------------------*/
insert into @ttP select 'ExportTables',                    'DE Export Tables',                1,        1,         null,    'DataExchange'
insert into @ttP select 'ExportTransactions',              'Export Transactions',             1,        1,         null,    'ExportTables'
insert into @ttP select 'ExportOnhandInventory',           'Export Onhand Inventory',         1,        1,         null,    'ExportTables'
insert into @ttP select 'ExportOpenOrders',                'Export Open Orders',              1,        1,         null,    'ExportTables'
insert into @ttP select 'ExportOpenReceipts',              'Export Open Receipts',            1,        1,         null,    'ExportTables'
insert into @ttP select 'ExportInvSnapshot',               'Export Inv Snapshot',             1,        1,         null,    'ExportTables'
insert into @ttP select 'ExportShippedLoads',              'Export Shipped Loads',            0,        0,         null,    'ExportTables'
/*-------------------------------*/
/* API Tables */
/*-------------------------------*/
insert into @ttP select 'APIInboundTransactions',         'API Inbound Transactions',         0,        1,         null,    'APITables'
insert into @ttP select 'APIOutboundTransactions',        'API OutboundTransactions',         0,        1,         null,    'APITables'

/*-------------*/
/* System Info */
/*-------------*/
insert into @ttP select 'SystemInfo',                      'System Info',                     1,        1,         null,    'MaintenanceMenu'
/*------------------------------*/
/* System Info - User Interface */
/*------------------------------*/
insert into @ttP select 'UserInterface',                   'User Interface',                  1,        1,         null,    'SystemInfo'
insert into @ttP select 'Fields',                          'Fields',                          1,        1,         null,    'UserInterface'
insert into @ttP select 'Layouts',                         'Layouts',                         1,        1,         null,    'UserInterface'
insert into @ttP select 'LayoutFields',                    'Layout Fields',                   1,        1,         null,    'UserInterface'
insert into @ttP select 'Messages',                        'Messages',                        1,        1,         null,    'UserInterface'
insert into @ttP select 'Notifications',                   'Notifications',                   1,        1,         null,    'UserInterface'
/*----------------------------*/
/* System Info - System Rules */
/*----------------------------*/
insert into @ttP select 'SystemRules',                     'System Rules',                    1,        1,         null,    'SystemInfo'
insert into @ttP select 'RulesSets',                       'Rule Sets',                       1,        1,         null,    'SystemRules'
insert into @ttP select 'Rules',                           'Rules',                           1,        1,         null,    'SystemRules'
insert into @ttP select 'PutawayRules',                    'Putaway Rules',                   1,        1,         null,    'SystemRules'
insert into @ttP select 'AllocationRules',                 'Allocation Rules',                1,        1,         null,    'SystemRules'
insert into @ttP select 'PickBatchRules',                  'Waving Rules',                    1,        1,         null,    'SystemRules'
/*---------------------------------------*/
/* System Info - Shipping Configurations */
/*---------------------------------------*/
insert into @ttP select 'ShippingConfig',                  'Shipping Configuration',          1,        1,         null,    'SystemInfo'
insert into @ttP select 'ShipVias',                        'Ship Vias',                       1,        1,         null,    'ShippingConfig'
insert into @ttP select 'ShippingAccounts',                'Shipping Accounts',               1,        1,         null,    'ShippingConfig'
/*---------------------------*/
/* System Info - Base Tables */
/*---------------------------*/
insert into @ttP select 'BaseTables',                      'Base Tables',                     1,        1,         null,    'SystemInfo'
insert into @ttP select 'Contacts',                        'Contacts',                        1,        1,         null,    'BaseTables'
insert into @ttP select 'Devices',                         'Devices',                         1,        1,         null,    'BaseTables'
insert into @ttP select 'Notes',                           'Notes',                           1,        1,         null,    'BaseTables'
insert into @ttP select 'SKUAttributes',                   'SKU Attributes',                  1,        1,         null,    'BaseTables'
insert into @ttP select 'CartonTypes',                     'Carton Types',                    1,        1,         null,    'BaseTables'
insert into @ttP select 'CartonGroups',                    'Carton Groups',                   1,        1,         null,    'BaseTables'
insert into @ttP select 'ShipLabels',                      'Ship Labels',                     1,        1,         null,    'BaseTables'
insert into @ttP select 'SKUPriceLists',                   'SKU Price Lists',                 1,        1,         null,    'BaseTables'
/*---------------------------*/
/* System Info - DCMS Tables */
/*---------------------------*/
insert into @ttP select 'DCMSTables',                      'DCMS Tables',                     1,        1,         null,    'SystemInfo'
insert into @ttP select 'RouterInstructions',              'Router Instructions',             1,        1,         null,    'DCMSTables'
insert into @ttP select 'RouterConfirmations',             'Router Confirmations',            1,        1,         null,    'DCMSTables'
insert into @ttP select 'PandALabels',                     'Panda Labels',                    1,        1,         null,    'DCMSTables'
insert into @ttP select 'LPNRouting',                      'LPN Routing',                     1,        1,         null,    'DCMSTables'

/*--------------*/
/* Print Center */
/*--------------*/
insert into @ttP select 'PrintCenter',                     'Print Center',                    1,        1,         null,    'MaintenanceMenu'
insert into @ttP select 'PrintRequests',                   'Print Requests',                  1,        1,         null,    'PrintCenter'
insert into @ttP select 'PrintJobs',                       'Print Jobs',                      1,        1,         null,    'PrintCenter'
insert into @ttP select 'PrintJobDetails',                 'Print Job Details',               0,        0,         null,    'PrintCenter'
insert into @ttP select 'Printers',                        'Printers',                        1,        1,         null,    'PrintCenter'
insert into @ttP select 'LabelFormats',                    'Label Formats',                   1,        1,         null,    'PrintCenter'
insert into @ttP select 'ReportFormats',                   'Report Formats',                  1,        1,         null,    'PrintCenter'
insert into @ttP select 'ZPLLabelTemplates',               'ZPL Label Templates',             0,        0,         null,    'PrintCenter'

insert into @ttP select 'PrintLabels',                     'Print Labels',                    0,        0,         null,    'SystemInfo'
insert into @ttP select 'ConfigureLabelPrinter',           'Configure Label Printer',         0,        0,         null,    'MaintenanceMenu'

/*--------------*/
/* Print Center Actions */
/*--------------*/
insert into @ttP select 'CancelPrintJobs',                 'Cancel print job',                0,        0,         null,    'PrintCenter'

/*--------------*/
/*  Analytics   */
/*--------------*/
insert into @ttP select 'Analytics',                       'Analytics',                       1,        1,         null,    'MaintenanceMenu'
insert into @ttP select 'UserProductivity',                'User Productivity',               1,        1,         null,    'Analytics'
insert into @ttP select 'UserAuditLog',                    'User Audit Log',                  1,        1,         null,    'Analytics'
insert into @ttP select 'SummariesProductivity',           'Summaries for Productivity',      1,        1,         null,    'Analytics'
insert into @ttP select 'SKUVelocity',                     'SKU Velocity',                    1,        1,         null,    'Analytics'
insert into @ttP select 'WarehouseKPI',                    'Warehouse Metrics',               1,        1,         null,    'Analytics'
insert into @ttP select 'WHKPIPeriod',                     'Warehouse KPI By Time',           1,        1,         null,    'WarehouseMetrics'
insert into @ttP select 'WHKPICust',                       'Warehouse KPI By Customer',       1,        1,         null,    'WarehouseMetrics'

/*------------*/
/* Dashboards */
/*------------*/
insert into @ttP select 'Receiving.Dab',                   'Receiving Dashboards',            1,        1,         null,    'Dashboards'
insert into @ttP select 'Inventory.Dab',                   'Inventory Dashboards',            1,        1,         null,    'Dashboards'
insert into @ttP select 'CycleCount.Dab',                  'Cycle Count Dashboards',          1,        1,         null,    'Dashboards'
insert into @ttP select 'Orders.Dab',                      'Orders Dashboards',               1,        1,         null,    'Dashboards'
insert into @ttP select 'Waves.Dab',                       'Waves Dashboards',                1,        1,         null,    'Dashboards'
insert into @ttP select 'Replenishments.Dab',              'Replenishment Dashboards',        1,        1,         null,    'Dashboards'
insert into @ttP select 'Picking.Dab',                     'Picking Dashboards',              1,        1,         null,    'Dashboards'
insert into @ttP select 'Packing.Dab',                     'Packing Dashboards',              1,        1,         null,    'Dashboards'
insert into @ttP select 'Shipping.Dab',                    'Shipping Dashboards',             1,        1,         null,    'Dashboards'
insert into @ttP select 'Productivity.Dab',                'Productivity Dashboards',         1,        1,         null,    'Dashboards'
insert into @ttP select 'WarehouseMetrics.Dab',            'WarehouseMetrics Dashboards',     1,        1,         null,    'Dashboards'

/*--------------------*/
/* Reports Menu Items */
/*--------------------*/
insert into @ttP select 'HistoricalReports',               'Historical Reports',              0,        0,         null,    'ReportsMenu'
insert into @ttP select 'Productivity',                    'Productivity',                    0,        0,         null,    'ReportsMenu'
insert into @ttP select 'EmployeeAuditTrail',              'Employee Audit Trail',            0,        0,         null,    'ReportsMenu'
insert into @ttP select 'ShippedCounts',                   'Shipped Counts',                  0,        0,         null,    'ReportsMenu'
/*----------------------*/
/* Interface Menu Items */
/*----------------------*/
insert into @ttP select 'LMSData',                         'LMS Data',                        0,        0,         null,    'InterfaceMenu'

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*                                          Permissions for Receiving Menu sub menu item Actions                                          */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*----------*/
/* Receipts */
/*----------*/
insert into @ttP select 'Receipts.View',                   'View',                            0,        0,         null,    'Receipts'

insert into @ttP select 'Receipts.Actions',                'Actions',                         1,        1,         null,    'Receipts'
insert into @ttP select 'Receipts.Act.ModifyOwnership',    'Modify Ownership',                0,        0,         null,    'Receipts.Actions'
insert into @ttP select 'Receipts.Act.ChangeWarehouse',    'Change Warehouse',                1,        1,         null,    'Receipts.Actions'
insert into @ttP select 'Receipts.Act.ChangeArrivalInfo',  'Change ArrivalInfo',              1,        1,         null,    'Receipts.Actions'
insert into @ttP select 'Receipts.Act.PrepareForReceiving','Prepare For Receiving',           1,        1,         null,    'Receipts.Actions'
insert into @ttP select 'Receipts.Act.SelectLPNsForQC',    'select LPNs For QC',              1,        1,         null,    'Receipts.Actions'
/*----*/
insert into @ttP select 'Receipts.Act.PrepareForSorting',  'Prepare For Sorting',             0,        0,         null,    'Receipts.Actions'
insert into @ttP select 'Receipts.Act.ActivateRouting',    'Activate Routing',                0,        0,         null,    'Receipts.Actions'
/*----*/
insert into @ttP select 'Receipts.Act.ROClose',            'Close Receipt Order',             1,        1,         null,    'Receipts.Actions'
insert into @ttP select 'Receipts.Act.ROOpen',             'Re-Open Receipt Order',           1,        1,         null,    'Receipts.Actions'
/*----*/
insert into @ttP select 'Receipts.Act.CrossDockASN',       'Cross Dock Cartons on ASN',       0,        0,         null,    'Receipts.Actions'
insert into @ttP select 'Receipts.Act.ReceiveInventory',   'Receive Inventory',               0,        0,         null,    'Receipts.Actions'
insert into @ttP select 'Receipts.Act.PrintLabels',        'Print Labels',                    1,        1,         null,    'Receipts.Actions'

/*-------------------*/
/* Receiving Reports */
/*-------------------*/
insert into @ttP select 'Receipts.Reports',                'Reports',                         1,        1,         null,    'Receipts'
insert into @ttP select 'Receipts.Rpt.ReceivingSummary',   'Receiving Summary',               1,        1,         null,    'Receipts.Reports'
insert into @ttP select 'Receipts.Rpt.PalletListing',      'Receiving Pallets',               1,        1,         null,    'Receipts.Reports'

/*---------------------------------------*/
/* Privileges & Overrides - Receipts */
/*---------------------------------------*/
insert into @ttP select 'Receipts.Privileges',             'Privileges & Overrides',          1,        1,         null,    'Receipts'
insert into @ttP select 'Receipts.Pri.CloseIncompleteRO',  'Close an incomplete RO',          1,        1,         null,    'Receipts.Privileges'
insert into @ttP select 'Receipts.Pri.CreateLPNsToReceive','Create LPNs To Receive',          0,        0,         null,    'Receipts.Privileges'
insert into @ttP select 'Receipts.Pri.Reset',              'Reset',                           0,        0,         null,    'Receipts.Privileges'
insert into @ttP select 'Receipts.Pri.Receive',            'Receive',                         0,        0,         null,    'Receipts.Privileges'

/*------------------------*/
/* ReceiptDetails Actions */
/*------------------------*/
insert into @ttP select 'ReceiptDetails.View',                  'View',                            0,        0,         null,    'ReceiptDetails'

insert into @ttP select 'ReceiptDetails.Actions',               'Actions',                         0,        0,         null,    'ReceiptDetails'
insert into @ttP select 'ReceiptDetails.Act.Modify',            'Modify Receipt Details',          0,        0,         null,    'ReceiptDetails.Actions'
insert into @ttP select 'ReceiptDetails.Act.PrepareForSorting', 'Prepare For Sorting',             0,        0,         null,    'ReceiptDetails.Actions'
insert into @ttP select 'ReceiptDetails.Act.ActivateRouting',   'Activate Routing',                0,        0,         null,    'ReceiptDetails.Actions'

/*-------------------*/
/* Receivers Actions */
/*-------------------*/
insert into @ttP select 'Receivers.View',                  'View',                            0,        0,         null,    'Receivers'

insert into @ttP select 'Receivers.Actions',               'Actions',                         1,        1,         null,    'Receivers'
insert into @ttP select 'Receivers.Act.CreateReceiver',    'Create Receiver',                 1,        1,         null,    'Receivers.Actions'
insert into @ttP select 'Receivers.Act.ModifyReceiver',    'Modify Receiver',                 1,        1,         null,    'Receivers.Actions'
insert into @ttP select 'Receivers.Act.PrepareForReceiving',
                                                           'Prepare For Receiving',           1,        1,         null,    'Receivers.Actions'
insert into @ttP select 'Receivers.Act.CreateLPNsToReceive',
                                                           'Create LPNs To Receive',          0,        0,         null,    'Receivers.Actions'
insert into @ttP select 'Receivers.Act.SelectLPNsForQC',   'select LPNs For QC',              1,        1,         null,    'Receivers.Actions'
insert into @ttP select 'Receivers.Act.AssignASNs',        'Assign ASN LPNs',                 0,        0,         null,    'Receivers.Actions'
insert into @ttP select 'Receivers.Act.UnassignLPNs',      'Unassign LPNs',                   0,        0,         null,    'Receivers.Actions'
insert into @ttP select 'Receivers.Act.CloseReceivers',    'Close Receivers',                 1,        1,         null,    'Receivers.Actions'


insert into @ttP select 'Receivers.Act.PrintLabels',       'Print Labels',                    1,        1,         null,    'Receivers.Actions'

/*---------------------------------------*/
/* Privileges & Overrides - Receivers */
/*---------------------------------------*/
insert into @ttP select 'Receivers.Privileges',            'Privileges & Overrides',          1,        1,         null,    'Receivers'
insert into @ttP select 'Receivers.ReceiveExtraQty',       'Receive Extra Qty',               1,        1,         null,    'Receivers.Privileges'
insert into @ttP select 'Receivers.OverrideMaxQty',        'Override Max Ordered Qty',        1,        1,         null,    'Receivers.Privileges'

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*                                          Permissions for Inventory Menu - Sub Menu items Actions                                       */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*--------------*/
/* SKUs Actions */
/*--------------*/
insert into @ttP select 'SKUs.View',                       'View',                            0,        0,         null,    'SKUs'

insert into @ttP select 'SKUs.Actions',                    'Actions',                         1,        1,         null,    'SKUs'
insert into @ttP select 'SKUs.Act.ModifyDimensions',       'Modify SKU Dimensions',           1,        1,         null,    'SKUs.Actions'
insert into @ttP select 'SKUs.Act.ModifyPackConfigurations','Modify SKU Pack Configurations', 1,        1,         null,    'SKUs.Actions'
insert into @ttP select 'SKUs.Act.ModifyClasses',          'Modify SKU Classes',              1,        1,         null,    'SKUs.Actions'
insert into @ttP select 'SKUs.Act.ModifyAliases',          'Modify SKU Aliases',              1,        1,         null,    'SKUs.Actions'
insert into @ttP select 'SKUs.Act.ModifyCommercialInfo',   'Modify Commercial Info',          1,        1,         null,    'SKUs.Actions'
insert into @ttP select 'SKUs.Act.PrintLabels',            'Print Labels',                    1,        1,         null,    'SKUs.Actions'

insert into @ttP select 'SKUs.Act.AddUPC',                 'Add UPC',                         0,        0,         null,    'SKUs.Actions'
insert into @ttP select 'SKUs.Act.RemoveUPC',              'Remove UPC',                      0,        0,         null,    'SKUs.Actions'
insert into @ttP select 'SKUs.Act.ModifyCartonGroup',      'Modify Carton Group',             0,        0,         null,    'SKUs.Actions'

/*----------------------*/
/* SKU Prepacks Actions */
/*----------------------*/
insert into @ttP select 'SKUPrepacks.View',                'View',                            0,        0,         null,    'SKUPrepacks'

insert into @ttP select 'SKUPrepacks.Actions',             'Actions',                         1,        1,         null,    'SKUPrepacks'
insert into @ttP select 'SKUPrepacks.Act.ModifySKUPrepack','Modify SKU Prepack',              1,        1,         null,    'SKUPrepacks.Actions'

/*--------------*/
/* LPNs Actions */
/*--------------*/
insert into @ttP select 'LPNs.View',                       'View',                            0,        0,         null,    'LPNs'

insert into @ttP select 'LPNs.Actions',                    'Actions',                         1,        1,         null,    'LPNs'
insert into @ttP select 'LPNs.Act.AdjustLPNQty',           'Adjust LPN Quantity',             1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.ChangeSKU',              'Modify SKU',                      1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.ChangeOwner',            'Change Ownership',                1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.ChangeWarehouse',        'Change Warehouse',                1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.GenerateLPNs',           'Generate LPNs',                   1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.ModifyLPNType',          'Modify LPN Type',                 1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.ModifyLPNs',             'Update Invetory Categories',      1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.UpdateExpiryDate',       'Update Expiry Date',              0,        0,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.Reverse-Receipt',        'Reverse Receipt',                 1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.UnallocateLPNs',         'Unallocate LPN',                  1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.ModifyCartonDetails',    'Modify Carton Type/Weight',       1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.PalletizeLPNs',          'Palletize LPNs',                  1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.MoveLPNs',               'Move LPNs',                       1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.ActivateShipCartons',    'Activate Ship Cartons',           1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.CancelShipCartons',      'Cancel Ship Cartons',             1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.VoidLPNs',               'Void LPN',                        1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.RemoveZeroQtySKUs',      'Remove Zero Quantity SKUs',       1,        1,         null,    'LPNs.Actions'

insert into @ttP select 'LPNs.Act.PrintLabels',            'Print Labels',                    1,        1,         null,    'LPNs.Actions'

insert into @ttP select 'LPNs.Act.ReGenerateTrackingNo',   '(Re)Generate Tracking Number',    1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.QCHold',                 'QC Hold',                         1,        1,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.QCRelease',              'QC Release',                      1,        1,         null,    'LPNs.Actions'

insert into @ttP select 'LPNs.Act.PrintPackingList',       'Print Packing List',              0,        0,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.PrintShipLabels',        'Print Shipping Labels',           0,        0,         null,    'LPNs.Actions'
insert into @ttP select 'LPNs.Act.PrintPalletandLPNLabels','Print Pallet & LPNs Labels',      1,        1,         null,    'LPNs.Actions'

/*-------------------*/
/* LPNs Reports */
/*-------------------*/
insert into @ttP select 'LPNs.Rpt.TransferList',           'Transfer LPN Report',             1,        1,         null,    'LPNs.Actions'

--insert into @ttP select 'LPNs.Act.Add',                    'Add LPNs',                        0,        0,         null,    'LPNs.Actions'
/*--------------------*/
/* LPNDetails Actions */
/*--------------------*/
insert into @ttP select 'LPNDetails.View',                 'View',                            0,        0,         null,    'LPNDetails'

insert into @ttP select 'LPNDetails.Actions',              'Actions',                         1,        1,         null,    'LPNDetails'
insert into @ttP select 'LPNDetails.Act.AdjustQty',        'Adjust Quantity',                 1,        1,         null,    'LPNDetails.Actions'

/*-----------------*/
/* Pallets Actions */
/*-----------------*/
insert into @ttP select 'Pallets.View',                    'View',                            0,        0,         null,    'Pallets'

insert into @ttP select 'Pallets.Actions',                 'Actions',                         1,        1,         null,    'Pallets'
insert into @ttP select 'Pallets.Act.GeneratePallets',     'Generate Pallets',                1,        1,         null,    'Pallets.Actions'
insert into @ttP select 'Pallets.Act.GenerateCarts',       'Generate Carts',                  1,        1,         null,    'Pallets.Actions'
insert into @ttP select 'Pallets.Act.ClearCartUser',       'Clear User on Cart',              1,        1,         null,    'Pallets.Actions'
insert into @ttP select 'Pallets.Act.ClearCart',           'Clear Cart',                      1,        1,         null,    'Pallets.Actions'
insert into @ttP select 'Pallets.Act.PrintLabels',         'Print Labels',                    1,        1,         null,    'Pallets.Actions'

/*-------------------*/
/* Locations Actions */
/*-------------------*/
insert into @ttP select 'Locations.View',                  'View',                            0,        0,         null,    'Locations'

insert into @ttP select 'Locations.Actions',               'Actions',                         1,        1,         null,    'Locations'
insert into @ttP select 'Locations.Act.ModifyPutawayZones','Modify Putaway Zone',             1,        1,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.ModifyPickZones',   'Modify Pick Zone',                1,        1,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.ModifyLocationType','Change Location type',            1,        1,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.ModifyAttributes',  'Change Location Attributes',      1,        1,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.ChangeProfile',     'Change Location Profile',         1,        1,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.UpdateAllowedOperations',
                                                           'Allowed Operations',              1,        1,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.CreateNewLocation', 'Create New Location',             1,        1,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.DeleteLocation',    'Delete Location(s)',              1,        1,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.PrintLabels',       'Print labels',                    1,        1,         null,    'Locations.Actions'


insert into @ttP select 'Locations.Act.Activate',          'Activate Locations',              0,        0,         null,    'Locations.Actions'
insert into @ttP select 'Locations.Act.Deactivate',        'Deactivate Locations',            0,        0,         null,    'Locations.Actions'

insert into @ttp select 'Locations.Rpt.LPNList',           'LPN List Report',                 1,        1,         null,    'Locations.Actions'
insert into @ttp select 'Locations.Rpt.PalletList',        'Pallet List Report',              1,        1,         null,    'Locations.Actions'
insert into @ttp select 'Locations.Rpt.TransferList',      'Transfer LPN Report',             1,        1,         null,    'Locations.Actions'

/*--------------------*/
/* Cycle Count Locations Actions */
/*--------------------*/
insert into @ttP select 'CycleCountLocations.View',             'View',                       0,        0,         null,    'CycleCountLocations'
insert into @ttP select 'CycleCountLocations.Actions',          'Actions',                    1,        1,         null,    'CycleCountLocations'
insert into @ttP select 'CycleCountLocations.Act.CreateTasks',  'Create Cycle Count Tasks',   1,        1,         null,    'CycleCountLocations.Actions'

/*--------------------*/
/* Cycle Count Tasks Actions */
/*--------------------*/
insert into @ttP select 'CycleCountTasks.View',                 'View',                       0,        0,         null,    'CycleCountTasks'
insert into @ttP select 'CycleCountTasks.Actions',              'Actions',                    1,        1,         null,    'CycleCountTasks'
insert into @ttP select 'CycleCountTasks.Act.Cancel',           'Cancel Cycle Count Tasks',   1,        1,         null,    'CycleCountTasks.Actions'
insert into @ttP select 'CycleCountTasks.Act.AssignToUser',     'Assign To User',             1,        1,         null,    'CycleCountTasks.Actions'
insert into @ttP select 'CycleCountTasks.Act.PrintTaskLabels',  'Print Cycle Count Task labels',
                                                                                              1,        1,         null,    'CycleCountTasks.Actions'
                                                                                             
/*--------------------*/
/* Cycle Count Results Actions */
/*--------------------*/
insert into @ttP select 'CycleCountResults.Actions',            'Actions',                    1,        1,         null,    'CycleCountResults'
insert into @ttP select 'CC.Rpt.ResultsList',                   'CC Results List Report',     1,        1,         null,    'CycleCountResults.Actions'

/*--------------------------------------------*/
/* Privileges & Overrides - Cycle Counting */
/*--------------------------------------------*/
insert into @ttP select 'CycleCount.Privileges',            'Privileges & Overrides',         1,        1,         null,    'CycleCount'
insert into @ttP select 'CycleCount.Pri.AllowCycleCount_L2','Allow Supervisor Counts',        1,        1,         null,    'CycleCount.Privileges'
insert into @ttP select 'CycleCount.Pri.OverrideCCThresholds',
                                                            'Allow override cycle count thresholds',
                                                                                              1,        1,         null,    'CycleCount.Privileges'
insert into @ttP select 'CycleCount.Pri.AllowCycleCount_L3','Allow Manager cycle Counts',     1,        1,         null,    'CycleCount.Privileges'

/*------------------*/
/* Onhand Inventory */
/*------------------*/
insert into @ttP select 'OnhandInventory.View',            'Onhand Inventory Export',         0,        0,         null,    'OnhandInventory'

insert into @ttP select 'OnhandInventory.Actions',         'Onhand Inventory Export',         0,        0,         null,    'OnhandInventory'
insert into @ttP select 'OnhandInventory.Act.ExportOnhandInventory',
                                                           'Export Onhand Inventory',         0,        0,         null,    'OnhandInventory.Actions'
/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*                                          Permissions for Order Fullfilment Menu - Sub Menu items Actions                                       */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*----------------*/
/* Orders Actions */
/*----------------*/
insert into @ttP select 'Orders.View',                     'View',                            0,        0,         null,    'Orders'

insert into @ttP select 'Orders.Actions',                  'Actions',                         1,        1,         null,    'Orders'
insert into @ttP select 'Orders.Act.ModifyShipDetails',    'Modify Ship Details',             1,        1,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.CancelPickTicket',     'Cancel Pick Ticket',              1,        1,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.ClosePickTicket',      'Close Pick Ticket',               1,        1,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.PrintPackingList',     'Reprint Packing List',            1,        1,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.ReleaseOrders',        'Release Orders',                  0,        0,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.CreateKits',           'Create kits for Orders',          1,        1,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.ConvertToSetSKUs',     'Convert To Set SKUs',             1,        1,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.ModifyPickTicket',     'Modify PickTicket',               1,        1,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.PrintEngravingLabels', 'Reprint Engraving Labels',        0,        0,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.RemoveOrdersFromWave', 'Remove Order(s) From Wave',       1,        1,         null,    'Orders.Actions'
insert into @ttP select 'Orders.Act.AddReplaceDeleteNote', 'Add/replace/Delete Note',         1,        1,         null,    'Orders.Actions'

insert into @ttP select 'Orders.Act.CompleteRework',       'Complete Rework',                 1,        1,         null,    'Orders.Actions'

insert into @ttP select 'OrderHeaders.Act.Addresses',      'Edit Address',                    1,        1,         null,    'Orders.Actions'

insert into @ttP select 'Orders.Privileges',               'Privileges & Overrides',          0,        0,         null,    'Orders'

/*-----------------------*/
/* Order Details Actions */
/*-----------------------*/
insert into @ttP select 'OrderDetails.View',                         'View',                            0,        0,         null,    'OrderDetails'

insert into @ttP select 'OrderDetails.Actions',                      'Actions',                         1,        1,         null,    'OrderDetails'
insert into @ttP select 'OrderDetails.Act.ModifyOrderDetails',       'Modify Order Details',            1,        1,         null,    'OrderDetails.Actions'
insert into @ttP select 'OrderDetails.Act.ModifyPackCombination',    'Modify Pack Combination',         1,        1,         null,    'OrderDetails.Actions'
insert into @ttP select 'OrderDetails.Act.ModifyReworkInfo',         'Modify Rework Info',              1,        1,         null,    'OrderDetails.Actions'
insert into @ttP select 'OrderDetails.Act.CancelCompleteLine',       'Cancel All Remaining Qty',        1,        1,         null,    'OrderDetails.Actions'
insert into @ttP select 'OrderDetails.Act.CancelPTLine',             'Cancel Line',                     1,        1,         null,    'OrderDetails.Actions'

/*---------------------*/
/* Waves Actions */
/*---------------------*/
insert into @ttP select 'Waves.View',                                'View',                            0,        0,         null,    'Waves'

insert into @ttP select 'Waves.Actions',                             'Actions',                         1,        1,         null,    'Waves'
insert into @ttP select 'Waves.Act.Modify',                          'Modify Wave',                     1,        1,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.ModifyPriority',                  'Modify Priority',                 0,        0,         null,    'Waves.Actions'

insert into @ttP select 'Waves.Act.Plan',                            'Planned',                         0,        0,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.UnPlan',                          'Un Planned',                      0,        0,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.ApproveToRelease',                'Approve To Release',              1,        1,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.PreprocessOrders',                'Pre-process Orders',              0,        0,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.ReleaseForAllocation',            'Release For Allocation',          1,        1,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.ReleaseForPicking',               'Release For Picking',             1,        1,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.Reallocate',                      'Reallocate Wave',                 1,        1,         null,    'Waves.Actions'

insert into @ttP select 'Waves.Act.RemoveOrdersFromWave',            'Remove Order From Wave',          0,        0,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.Cancel',                          'Cancel Wave',                     1,        1,         null,    'Waves.Actions'
insert into @ttP select 'Waves.Act.PrintLabels',                     'Print Labels',                    1,        1,         null,    'Waves.Actions'

insert into @ttP select 'Waves.Reports',                             'Reports',                         1,        1,         null,    'Waves'
insert into @ttP select 'Waves.Rpt.BatchedSKUSummaryReport',         'Print Wave SKU Summary Report',   0,        0,         null,    'Waves.Reports'
insert into @ttP select 'Waves.Rpt.ExportPickBatchSummary',          'Export Wave Summary',             1,        1,         null,    'Waves.Reports'
insert into @ttP select 'Waves.Rpt.WaveSKUSummary',                  'Wave SKU Summary',                1,        1,         null,    'Waves.Reports'
insert into @ttP select 'Waves.Rpt.PrintPackingList',                'Print Packing List',              0,        0,         null,    'Waves.Reports'

insert into @ttP select 'Waves.Privileges',                          'Privileges & Overrides',          1,        1,         null,    'Waves'
insert into @ttP select 'Waves.Pri.CancelReleasedWave',              'Cancel Released Wave',            1,        1,         null,    'Waves.Privileges'
insert into @ttP select 'Waves.Pri.RemoveOrdersFromReleasedWave',    'Remove Order from Released Wave', 1,        1,         null,    'Waves.Privileges'

/*-----------------------*/
/* ManageWaves Actions */
/*-----------------------*/
insert into @ttP select 'ManageWaves.View',                'View',                            0,        0,         null,    'ManageWaves'

insert into @ttP select 'ManageWaves.Actions',             'Actions',                         1,        1,         null,    'ManageWaves'
--insert into @ttP select 'ManageWaves.Act.AssignTo',        'Assign To User',                  0,        0,         null,    'ManageWaves.Actions'
insert into @ttP select 'ManageWaves.Act.CreateWave',      'Create Wave',                     1,        1,         null,    'ManageWaves.Actions'
insert into @ttP select 'ManageWaves.Act.GenerateWaves',   'Generate Waves',                  1,        1,         null,    'ManageWaves.Actions'
insert into @ttP select 'ManageWaves.Act.AddOrdersToWave', 'Add Orders To Wave',              1,        1,         null,    'ManageWaves.Actions'
insert into @ttP select 'ManageWaves.Act.AddOrderDetailsToWave',
                                                           'Add Order Details To Wave',       0,        0,         null,    'ManageWaves.Actions'
insert into @ttP select 'ManageWaves.Act.ReleaseWave',     'Release Wave for Allocation',     1,        1,         null,    'ManageWaves.Actions'
insert into @ttP select 'ManageWaves.Act.RemoveOrdersFromWave',
                                                           'Remove Orders From Wave',         1,        1,         null,    'ManageWaves.Actions'
insert into @ttP select 'ManageWaves.Act.CancelPTLine',    'Cancel PickTicket Line',          1,        1,         null,    'ManageWaves.Actions'

/*------------*/
/* Pick Tasks */
/*------------*/
insert into @ttP select 'PickTasks.View',                  'View',                            0,        0,         null,    'PickTasks'

insert into @ttP select 'PickTasks.Actions',               'Actions',                         1,        1,         null,    'PickTasks'
insert into @ttP select 'PickTasks.Act.AssignToUser',      'Assign To User',                  1,        1,         null,    'PickTasks.Actions'
insert into @ttP select 'PickTasks.Act.UnassignUser',      'Unassign User',                   1,        1,         null,    'PickTasks.Actions'
insert into @ttP select 'PickTasks.Act.ReleaseTask',       'Release Tasks',                   1,        1,         null,    'PickTasks.Actions'
insert into @ttP select 'PickTasks.Act.ConfirmPicks',      'Confirm Picks Completed',         1,        1,         null,    'PickTasks.Actions'
insert into @ttP select 'PickTasks.Act.CancelTask',        'Cancel Pick Task',                1,        1,         null,    'PickTasks.Actions'
insert into @ttP select 'PickTasks.Act.PrintLabels',       'Print Labels',                    1,        1,         null,    'PickTasks.Actions'
insert into @ttP select 'PickTasks.Act.PrintDocuments',    'Print Documents',                 1,        1,         null,    'PickTasks.Actions'

insert into @ttP select 'PickTasks.Act.ConfirmTaskForPicking',
                                                           'Confirm Tasks for Picking',       1,        1,         null,    'PickTasks.Actions'
insert into @ttP select 'PickTasks.Act.PrintPickLabels',   'Print Pick Labels',               0,        0,         null,    'PickTasks.Actions'

/*-------------------*/
/* Pick Task Details */
/*-------------------*/
insert into @ttP select 'PickTaskDetails.View',            'View',                            0,        0,         null,    'PickTaskDetails'

insert into @ttP select 'PickTaskDetails.Actions',         'Actions',                         1,        1,         null,    'PickTaskDetails'
insert into @ttP select 'PickTaskDetails.Act.AssignTo',    'Assign To User',                  1,        1,         null,    'PickTaskDetails.Actions'
insert into @ttP select 'PickTaskDetails.Act.CancelLine',  'Cancel Pick Line',                1,        1,         null,    'PickTaskDetails.Actions'
insert into @ttP select 'PickTaskDetails.Act.Export',      'Export Picks',                    1,        1,         null,    'PickTaskDetails.Actions'

/*--------------------------------*/
/* GenerateReplenishments Actions */
/*--------------------------------*/
insert into @ttP select 'ReplenishLocations.View',         'View',                            0,        0,         null,    'ReplenishLocations'

insert into @ttP select 'ReplenishLocations.Actions',      'Actions',                         1,        1,         null,    'ReplenishLocations'
insert into @ttP select 'ReplenishLocations.Act.GenerateReplenishOrders',
                                                           'Generate Replenish Orders',       1,        1,         null,    'ReplenishLocations.Actions'
insert into @ttP select 'ReplenishLocations.Act.PrintReplenishReport',
                                                           'Print Replenish Report',          1,        1,         null,    'ReplenishLocations.Actions'

insert into @ttP select 'ReplenishOrders.Actions',         'ReplenishOrders Actions',         1,        1,         null,    'ReplenishOrders.View'
insert into @ttP select 'ReplenishOrders.Act.ChangePriority',
                                                           'Change Order Priority',           1,        1,         null,    'ReplenishOrders.Actions'
insert into @ttP select 'ReplenishOrders.Act.Close',       'Close Replenish Order',           1,        1,         null,    'ReplenishOrders.Actions'
insert into @ttP select 'ReplenishOrders.Act.Cancel',      'Cancel Replenish Order',          1,        1,         null,    'ReplenishOrders.Actions'
insert into @ttP select 'ReplenishOrders.Act.Archive',     'Archive Replenish Order',         1,        1,         null,    'ReplenishOrders.Actions'

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*                                          Permissions for Shipping Menu - Sub Menu items Actions                                     */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*--------------*/
/* Loads Actions*/
/*--------------*/
insert into @ttP select 'Loads.View',                      'View',                            0,        0,         null,    'Loads'

insert into @ttP select 'Loads.Actions',                   'Actions',                         1,        1,         null,    'Loads'
insert into @ttP select 'Loads.Act.CreateNew',             'Create Load',                     1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.CreateTransferLoad',    'Create Transfer Load',            1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.ModifyLoad',            'Modify Load',                     1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.ModifyBoLInfo',         'Modify BoL Info',                 1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.ModifyApptDetails',     'Modify Appointment Details',      1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.RequestForRouting',     'Request For Routing',             1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.GenerateVICSBoLData',   'Generate BoL info',               1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.ActivateShipCartons',   'Activate Ship Cartons',           1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Rpt.PrintVICSBoLReport',    'Print BoL Report',                1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Rpt.PrintVICSBoLReportforAccount',
                                                           'Print BoL Report for Account',    1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Rpt.ShippingManifest',      'Print Shipping Manifest',         1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Rpt.ShipManifestSummary',   'Print Ship Manifest Summary',     1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.RemoveOrders',          'Remove Order from Load',          1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.PrintStorePackingList', 'Print Store Packing List',        1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.ConfirmAsShipped',      'Confirm Load as Shipped ',        1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.CancelLoad',            'Cancel Load',                     1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.PrintLabels',           'Print Labels',                    1,        1,         null,    'Loads.Actions'
insert into @ttP select 'Loads.Act.PrintDocuments',        'Print Documents',                 1,        1,         null,    'Loads.Actions'

insert into @ttP select 'BoLs.Actions',                    'BoLs',                            1,        1,         null,    'Loads'
insert into @ttP select 'BoLs.Act.Modify',                 'Modify BoL',                      1,        1,         null,    'BoLs.Actions'
insert into @ttP select 'BoLs.Act.ModifyShipToAddress',    'Modify BoL Ship To Address',      1,        1,         null,    'BoLs.Actions'
insert into @ttP select 'BoLOrderDetails.Act.Modify',      'Modify BoL Order Details',        1,        1,         null,    'BoLs.Actions'
insert into @ttP select 'BoLCarrierDetails.Act.Modify',    'Modify BoL Carrier Details',      1,        1,         null,    'BoLs.Actions'

/*-----------------------*/
/* ManageLoads Actions */
/*-----------------------*/
insert into @ttP select 'ManageLoads.View',                     'View',                       0,        0,         null,    'ManageLoads'

insert into @ttP select 'ManageLoads.Actions',                  'Actions',                    1,        1,         null,    'ManageLoads'
insert into @ttP select 'ManageLoads.Act.CreateLoad',           'Create Load',                1,        1,         null,    'ManageLoads.Actions'
insert into @ttP select 'ManageLoads.Act.EditLoad',             'Edit Load',                  1,        1,         null,    'ManageLoads.Actions'
insert into @ttP select 'ManageLoads.Act.AddOrderToLoad',       'Add Order(s) to Load',       1,        1,         null,    'ManageLoads.Actions'
insert into @ttP select 'ManageLoads.Act.RemoveOrdersFromLoad', 'Remove Order(s) from Load',  1,        1,         null,    'ManageLoads.Actions'
insert into @ttP select 'ManageLoads.Act.GenerateLoad',         'Generate Load',              1,        1,         null,    'ManageLoads.Actions'
insert into @ttP select 'ManageLoads.Act.CancelLoad',           'Cancel Load',                1,        1,         null,    'ManageLoads.Actions'

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*                                          Permissions for Maintenance Menu - Sub Menu items Actions                                     */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*---------------*/
/* Users Actions */
/*---------------*/
insert into @ttP select 'Users.View',                      'View',                            0,        0,         null,    'Users'

insert into @ttP select 'Users.Actions',                   'Actions',                         1,        1,         null,    'Users'
insert into @ttP select 'Users.Act.AddUser',               'Add User',                        1,        1,         null,    'Users.Actions'
insert into @ttP select 'Users.Act.EditUser',              'Edit User',                       1,        1,         null,    'Users.Actions'
insert into @ttP select 'Users.Act.SetUpUserFilters',      'Setup User Filters',              1,        1,         null,    'Users.Actions'
insert into @ttP select 'Users.Act.PrintLabels',           'Print Labels',                    1,        1,         null,    'Users.Actions'

/*--------------*/
/* Role Actions */
/*--------------*/
insert into @ttP select 'Roles.View',                      'View',                            0,        0,         null,    'Roles'

insert into @ttP select 'Roles.Actions',                   'Actions',                         1,        1,         null,    'Roles'
insert into @ttP select 'Roles.Act.Add',                   'Add Role ',                       1,        1,         null,    'Roles.Actions'
insert into @ttP select 'Roles.Act.Edit',                  'Edit Role',                       1,        1,         null,    'Roles.Actions'
insert into @ttP select 'Roles.Act.Delete',                'Delete Role ',                    1,        1,         null,    'Roles.Actions'

/*--------------------------*/
/* Role Permissions Actions */
/*--------------------------*/
insert into @ttP select 'RolePermissions.View',            'View',                            0,        0,         null,    'RolePermissions'

insert into @ttP select 'RolePermissions.Actions',         'Actions',                         1,        1,         null,    'RolePermissions'
insert into @ttP select 'RolePermissions.Act.GrantPermission',
                                                           'Grant Permission',                1,        1,         null,    'RolePermissions.Actions'
insert into @ttP select 'RolePermissions.Act.RevokePermission',
                                                           'Revoke Permission',               1,        1,         null,    'RolePermissions.Actions'

/*------------------*/
/* Lists & Controls */
/*------------------*/
/*---------------*/
/* Lists Actions */
/*---------------*/
insert into @ttP select 'Lookups.View',                    'View',                            0,        0,         null,    'LookUps'

insert into @ttP select 'Lookups.Actions',                 'Actions',                         1,        1,         null,    'LookUps'
insert into @ttP select 'Lookups.Act.Add',                 'Add New List item',               1,        1,         null,    'LookUps.Actions'
insert into @ttP select 'Lookups.Act.Edit',                'Edit List item',                  1,        1,         null,    'LookUps.Actions'

/*-------------------------*/
/* Selection Actions */
/*-------------------------*/
insert into @ttP select 'Selections.Act.Remove',            'Remove Selections',              1,        1,         null,    'Selections.Action'

/*-------------------------*/
/* System Controls Actions */
/*-------------------------*/
insert into @ttP select 'Controls.View',                   'View',                            0,        0,         null,    'Controls'

insert into @ttP select 'Controls.Actions',                'Actions',                         1,        1,         null,    'Controls'
insert into @ttP select 'Controls.Act.Add',                'Add Control',                     0,        0,         null,    'Controls.Actions'
insert into @ttP select 'Controls.Act.Edit',               'Edit Control',                    1,        1,         null,    'Controls.Actions'

/*-----------------------------*/
/* SystemInfo - User Interface */
/*-----------------------------*/
/*----------------*/
/* Fields Actions */
/*----------------*/
insert into @ttP select 'Fields.View',                     'View',                            0,        0,         null,    'Fields'

insert into @ttP select 'Fields.Actions',                  'Actions',                         1,        1,         null,    'Fields'
insert into @ttP select 'Fields.Act.Add',                  'Add Field',                       1,        1,         null,    'Fields.Actions'
insert into @ttP select 'Fields.Act.Edit',                 'Edit Field',                      1,        1,         null,    'Fields.Actions'

/*----------------------*/
/* LayoutFields Actions */
/*----------------------*/
insert into @ttP select 'LayoutFields.View',               'View',                            0,        0,         null,    'LayoutFields'

insert into @ttP select 'LayoutFields.Actions',            'Actions',                         1,        1,         null,    'LayoutFields'
insert into @ttP select 'LayoutFields.Act.Add',            'Add LayoutFields',                1,        1,         null,    'LayoutFields.Actions'
insert into @ttP select 'LayoutFields.Act.Edit',           'Edit LayoutFields',               1,        1,         null,    'LayoutFields.Actions'

/*-----------------*/
/* Layouts Actions */
/*-----------------*/
insert into @ttP select 'Layouts.View',                    'View',                            0,        0,         null,    'Layouts'

insert into @ttP select 'Layouts.Actions',                 'Actions',                         1,        1,         null,    'Layouts'
insert into @ttP select 'Layouts.Act.Modify',              'Modify Layout',                   1,        1,         null,    'Layouts.Actions'
insert into @ttP select 'Layouts.Act.Delete',              'Delete Layout(s)',                1,        1,         null,    'Layouts.Actions'

/*------------------*/
/* Messages Actions */
/*------------------*/
insert into @ttP select 'Messages.View',                   'View',                            0,        0,         null,    'Messages'

insert into @ttP select 'Messages.Actions',                'Actions',                         1,        1,         null,    'Messages'
insert into @ttP select 'Messages.Act.Edit',               'Edit Message',                    1,        1,         null,    'Messages.Actions'

/*---------------*/
/* Data Exchange */
/*---------------*/
/*---------------*/
/* Data Mappings */
/*---------------*/
insert into @ttP select 'Mapping.View',                    'View',                            0,        0,         null,    'Mapping'

insert into @ttP select 'Mapping.Actions',                 'Actions',                         1,        1,         null,    'Mapping'
insert into @ttP select 'Mapping.Act.Add',                 'Create Mapping',                  1,        1,         null,    'Mapping.Actions'
insert into @ttP select 'Mapping.Act.Edit',                'Edit Mapping',                    1,        1,         null,    'Mapping.Actions'
insert into @ttP select 'Mapping.Act.Delete',              'Delete Mapping',                  1,        1,         null,    'Mapping.Actions'

/*---------------------------*/
/* SystemInfo - System Rules */
/*---------------------------*/
/*----------------*/
/*  Rules Actions */
/*----------------*/
insert into @ttP select 'Rules.View',                      'View',                            0,        0,         null,    'Rules'

insert into @ttP select 'Rules.Actions',                   'Actions',                         0,        0,         null,    'Rules'
insert into @ttP select 'Rules.Act.Add',                   'Add Rule',                        0,        0,         null,    'Rules.Actions'
insert into @ttP select 'Rules.Act.Edit',                  'Edit Rule',                       0,        0,         null,    'Rules.Actions'
/*----------------------*/
/* PutawayRules Actions */
/*----------------------*/
insert into @ttP select 'PutawayRules.View',               'View',                            0,        0,         null,    'PutawayRules'

insert into @ttP select 'PutawayRules.Actions',            'Actions',                         0,        0,         null,    'PutawayRules'
insert into @ttP select 'PutawayRules.Act.Add',            'Add Putaway Rule',                0,        0,         null,    'PutawayRules.Actions'
insert into @ttP select 'PutawayRules.Act.Edit',           'Edit Putaway Rules',              0,        0,         null,    'PutawayRules.Actions'

/*-------------------------*/
/* AllocationRules Actions */
/*-------------------------*/
insert into @ttP select 'AllocationRules.View',            'View',                            0,        0,         null,    'AllocationRules'

insert into @ttP select 'AllocationRules.Actions',         'Actions',                         0,        0,         null,    'AllocationRules'
insert into @ttP select 'AllocationRules.Act.Add',         'Add Allocation Rule',             0,        0,         null,    'AllocationRules.Actions'
insert into @ttP select 'AllocationRules.Act.Edit',        'Edit Allocation Rule',            0,        0,         null,    'AllocationRules.Actions'
/*----------------------*/
/* Waving Rules Actions */
/*----------------------*/
insert into @ttP select 'PickBatchRules.View',             'View',                            0,        0,         null,    'PickBatchRules'

insert into @ttP select 'PickBatchRules.Actions',          'Actions',                         0,        0,         null,    'PickBatchRules'
insert into @ttP select 'PickBatchRules.Act.Add',          'Add Waving Rule',                 0,        0,         null,    'PickBatchRules.Actions'
insert into @ttP select 'PickBatchRules.Act.Edit',         'Edit Waving Rule',                0,        0,         null,    'PickBatchRules.Actions'
/*-----------------------*/
/* Routing Rules Actions */
/*-----------------------*/
insert into @ttP select 'RoutingRules.View',               'View',                            0,        0,         null,    'RoutingRules'

insert into @ttP select 'RoutingRules.Actions',            'Actions',                         0,        0,         null,    'RoutingRules'
insert into @ttP select 'RoutingRules.Act.AddRoutingRule', 'Add New Routing Rule',            0,        0,         null,    'RoutingRules.Actions'
insert into @ttP select 'RoutingRules.Act.EditRoutingRule','Edit Routing Rule',               0,        0,         null,    'RoutingRules.Actions'

/*-----------------------*/
/* Routing Zones Actions */
/*-----------------------*/
insert into @ttP select 'RoutingZones.View',               'View',                            0,        0,         null,    'RoutingZones'

insert into @ttP select 'RoutingZones.Actions',            'Actions',                         0,        0,         null,    'RoutingZones'
insert into @ttP select 'RoutingZones.Act.AddRoutingZone', 'Add New Routing Zone',            0,        0,         null,    'RoutingZones.Actions'
insert into @ttP select 'RoutingZones.Act.EditRoutingZone','Edit Routing Zone',               0,        0,         null,    'RoutingZones.Actions'

/*--------------------------------------*/
/* SystemInfo - Shipping Configurations */
/*--------------------------------------*/
/*------------------*/
/* ShipVias Actions */
/*------------------*/
insert into @ttP select 'ShipVias.View',                   'View',                            0,        0,         null,    'ShipVias'

insert into @ttP select 'ShipVias.Actions',                'Actions',                         1,        1,         null,    'ShipVias'
insert into @ttP select 'ShipVias.Act.LTLCarrierAdd',      'Add LTL Carrier',                 1,        1,         null,    'ShipVias.Actions'
insert into @ttP select 'ShipVias.Act.LTLCarrierEdit',     'Edit LTL Carrier',                1,        1,         null,    'ShipVias.Actions'
insert into @ttP select 'ShipVias.Act.SPGServiceAdd',      'Add Small Package Service',       0,        0,         null,    'ShipVias.Actions'
insert into @ttP select 'ShipVias.Act.SPGServiceEdit',     'Edit Small Package Service',      0,        0,         null,    'ShipVias.Actions'

/*--------------------------*/
/* ShippingAccounts Actions */
/*--------------------------*/
insert into @ttP select 'ShippingAccounts.View',           'View',                            0,        0,         null,    'ShippingAccounts'

insert into @ttP select 'ShippingAccounts.Actions',        'Actions',                         0,        0,         null,    'ShippingAccounts'
insert into @ttP select 'ShippingAccounts.Act.Add',        'Add Shipping Accounts',           0,        0,         null,    'ShippingAccounts.Actions'
insert into @ttP select 'ShippingAccounts.Act.Edit',       'Edit Shipping Accounts',          0,        0,         null,    'ShippingAccounts.Actions'

/*-------------------------*/
/* SystemInfo - Base Table */
/*-------------------------*/
/*-----------------*/
/* Devices Actions */
/*-----------------*/
insert into @ttP select 'Devices.View',                    'View',                            0,        0,         null,    'Devices'

insert into @ttP select 'Devices.Actions',                 'Actions',                         0,        0,         null,    'Devices'
insert into @ttP select 'Devices.Act.Add',                 'Add Device',                      0,        0,         null,    'Devices.DeviceActions'
insert into @ttP select 'Devices.Act.Edit',                'Edit Device',                     0,        0,         null,    'Devices.DeviceActions'

/*---------------*/
/* Notes Actions */
/*---------------*/
insert into @ttP select 'Notes.View',                      'View',                            0,        0,         null,    'Notes'

insert into @ttP select 'Notes.Actions',                   'Actions',                         0,        0,         null,    'Notes'
insert into @ttP select 'Notes.Act.Add',                   'Add Device',                      0,        0,         null,    'Notes.Actions'
insert into @ttP select 'Notes.Act.Edit',                  'Edit Device',                     0,        0,         null,    'Notes.Actions'

/*----------------------*/
/* Carton Types Actions */
/*----------------------*/
insert into @ttP select 'CartonTypes.View',                'View',                            0,        0,         null,    'CartonTypes'

insert into @ttP select 'CartonTypes.Actions',             'Actions',                         1,        1,         null,    'CartonTypes'
insert into @ttP select 'CartonTypes.Act.Add',             'Add Carton Type',                 1,        1,         null,    'CartonTypes.Actions'
insert into @ttP select 'CartonTypes.Act.Edit',            'Edit Carton Type',                1,        1,         null,    'CartonTypes.Actions'

/*----------------------*/
/* Carton Groups Actions */
/*----------------------*/
insert into @ttP select 'CartonGroups.View',                'View',                            0,        0,         null,    'CartonGroups'

insert into @ttP select 'CartonGroups.Actions',             'Actions',                         1,        1,         null,    'CartonGroups'
insert into @ttP select 'CartonGroups.Act.Add',             'Add Carton Group',                1,        1,         null,    'CartonGroups.Actions'
insert into @ttP select 'CartonGroups.Act.Edit',            'Edit Carton Group',               1,        1,         null,    'CartonGroups.Actions'
insert into @ttP select 'CartonGroupCartonType.Act.Add',    'Add Carton Type To Group',        1,        1,         null,    'CartonGroups.Actions'
insert into @ttP select 'CartonGroupCartonType.Act.Edit',   'Edit Carton Type In Group',       1,        1,         null,    'CartonGroups.Actions'
insert into @ttP select 'CartonGroupCartonType.Act.Delete', 'Delete Carton Type from Group',   1,        1,         null,    'CartonGroups.Actions'

/*------------------*/
/* Contacts Actions */
/*------------------*/
insert into @ttP select 'Contacts.View',                   'View',                            0,        0,         null,    'Contacts'

insert into @ttP select 'Contacts.Actions',                'Actions',                         1,        1,         null,    'Contacts'
insert into @ttP select 'Contacts.Act.AddContact',         'Add New Contact',                 1,        1,         null,    'Contacts.Actions'
insert into @ttP select 'Contacts.Act.EditContact',        'Edit Contact',                    1,        1,         null,    'Contacts.Actions'

/*--------------*/
/* Print Center */
/*--------------*/
/*----------*/
/* Printers */
/*----------*/
insert into @ttP select 'Printers.View',                   'View',                            0,        0,         null,    'Printers'

insert into @ttP select 'Printers.Actions',                'Actions',                         1,        1,         null,    'Printers'
insert into @ttP select 'Printers.Act.Add',                'Add Printer',                     1,        1,         null,    'Printers.Actions'
insert into @ttP select 'Printers.Act.Edit',               'Edit Printer',                    1,        1,         null,    'Printers.Actions'
insert into @ttP select 'Printers.Act.Delete',             'Delete Printer',                  1,        1,         null,    'Printers.Actions'
insert into @ttP select 'Printers.Act.ResetStatus',        'Reset Printer Status',            1,        1,         null,    'Printers.Actions'
insert into @ttP select 'Printers.Act.PrintLabels',        'Print Labels',                    1,        1,         null,    'Printers.Actions'

/*------------*/
/* Print Jobs */
/*------------*/
insert into @ttP select 'PrintJobs.View',                  'View',                            0,        0,         null,    'PrintJobs'

insert into @ttP select 'PrintJobs.Actions',               'Actions',                         0,        1,         null,    'PrintJobs'
insert into @ttP select 'PrintJobs.Act.Release',           'Release for printing',            1,        1,         null,    'PrintJobs.Actions'
insert into @ttP select 'PrintJobs.Act.Reprint',           'Reprint the job',                 1,        1,         null,    'PrintJobs.Actions'
insert into @ttP select 'PrintJobs.Act.Cancel',            'Cancel print job',                1,        1,         null,    'PrintJobs.Actions'

/*----------------------*/
/* LabelFormats Actions */
/*----------------------*/
insert into @ttP select 'LabelFormats.View',               'View',                            0,        0,         null,    'LabelFormats'

insert into @ttP select 'LabelFormats.Actions',            'Actions',                         1,        1,         null,    'LabelFormats'
insert into @ttP select 'LabelFormats.Act.Add',            'Add Label Formats',               1,        1,         null,    'LabelFormats.Actions'
insert into @ttP select 'LabelFormats.Act.Edit',           'Edit Label Formats',              1,        1,         null,    'LabelFormats.Actions'

/*----------------------*/
/* ReportFormats Actions */
/*----------------------*/
insert into @ttP select 'ReportFormats.View',              'View',                            0,        0,         null,    'ReportFormats'

insert into @ttP select 'ReportFormats.Actions',           'Actions',                         1,        1,         null,    'ReportFormats'
insert into @ttP select 'ReportFormats.Act.Add',           'Add Report Formats',              1,        1,         null,    'ReportFormats.Actions'
insert into @ttP select 'ReportFormats.Act.Edit',          'Edit Report Formats',             1,        1,         null,    'ReportFormats.Actions'

/*-----------------*/
/* LMSData Actions */
/*-----------------*/
insert into @ttP select 'LMSData.View',                    'View',                            0,        0,         null,    'LMSData'

insert into @ttP select 'LMSData.Actions',                 'Actions',                         0,        0,         null,    'LMSData'
insert into @ttP select 'LMSData.Act.ReExportBatch',       'Re Export Batch',                 0,        0,         null,    'LMSData.Actions'

/*------------------------------*/
/* HistoricalReports Menu Items */
/*------------------------------*/
insert into @ttP select 'WeeklySales',                     'Weekly Sales',                    0,        0,         null,    'HistoricalReports'

/*---------------*/
/* Presentation  */
/*---------------*/
insert into @ttP select 'Selections',                      'Selections',                      1,        1,         null,    'General'
insert into @ttP select 'EditSelection',                   'Edit Selections',                 1,        1,         null,    'Selections'

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/* Generic Global Export to Excel & Export to PDF Permissions */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
insert into @ttP select 'Receipts.XLSExport',              'Receipts Export to Excel',        1,        0,         null,    'Receipts'
insert into @ttP select 'Receipts.PDFExport',              'Receipts Expot to PDF',           1,        0,         null,    'Receipts'

insert into @ttP select 'ReceiptDetails.XLSExport',        'Receipt Details Export to Excel', 1,        0,         null,    'ReceiptDetails'
insert into @ttP select 'ReceiptDetails.PDFExport',        'Receipt Details Export to PDF',   1,        0,         null,    'ReceiptDetails'

insert into @ttP select 'Receivers.XLSExport',             'Receivers Export to Excel',       1,        0,         null,    'Receivers'
insert into @ttP select 'Receivers.PDFExport',             'Receivers Export to PDF',         1,        0,         null,    'Receivers'

insert into @ttP select 'Vendors.XLSExport',               'Vendors Export to Excel',         1,        0,         null,    'Vendors'
insert into @ttP select 'Vendors.PDFExport',               'Vendors Export to PDFs',          1,        0,         null,    'Vendors'

insert into @ttP select 'SKUs.XLSExport',                  'SKUs Export to Excel',            1,        1,         null,    'SKUs'
insert into @ttP select 'SKUs.PDFExport',                  'SKUs Export to PDF',              1,        1,         null,    'SKUs'

insert into @ttP select 'SKUPrepacks.XLSExport',           'SKU Prepacks Export to Excel',    1,        1,         null,    'SKUPrepacks'
insert into @ttP select 'SKUPrepacks.PDFExport',           'SKU Prepacks Export to PDF',      1,        1,         null,    'SKUPrepacks'

insert into @ttP select 'LPNs.XLSExport',                  'LPNs Export to Excel',            1,        0,         null,    'LPNs'
insert into @ttP select 'LPNs.PDFExport',                  'LPNs Export to PDF',              1,        0,         null,    'LPNs'

insert into @ttP select 'LPNDetails.XLSExport',            'LPNDetails Export to Excel',      1,        0,         null,    'LPNDetails'
insert into @ttP select 'LPNDetails.PDFExport',            'LPNDetails Export to PDF',        1,        0,         null,    'LPNDetails'

insert into @ttP select 'Pallets.XLSExport',               'Pallets Export to Excel',         1,        0,         null,    'Pallets'
insert into @ttP select 'Pallets.PDFExport',               'Pallets Export to PDF',           1,        0,         null,    'Pallets'

insert into @ttP select 'Locations.XLSExport',             'Locations Export to Excel',       1,        0,         null,    'Locations'
insert into @ttP select 'Locations.PDFExport',             'Locations Export to PDF',         1,        0,         null,    'Locations'

insert into @ttP select 'CycleCount.XLSExport',            'Cycle Count Export to Excel',     1,        0,         null,    'CycleCount'
insert into @ttP select 'CycleCount.PDFExport',            'Cycle Count Export to PDF',       1,        0,         null,    'CycleCount'

insert into @ttP select 'CycleCountStatistics.XLSExport',  'Cycle Count Statistics Export to Excel',
                                                                                              1,        0,         null,    'CycleCountStatistics'
insert into @ttP select 'CycleCountStatistics.PDFExport',  'Cycle Count Statistics Export to PDF',
                                                                                              1,        0,         null,    'CycleCountStatistics'

insert into @ttP select 'OnhandInventory.XLSExport',       'Onhand Inventory Export to Excel',1,        0,         null,    'OnhandInventory'
insert into @ttP select 'OnhandInventory.PDFExport',       'Onhand Inventory Export to PDF',  1,        0,         null,    'OnhandInventory'

insert into @ttP select 'Orders.XLSExport',                'Orders Export to Excel',          1,        0,         null,    'Orders'
insert into @ttP select 'Orders.PDFExport',                'Orders Export to PDF',            1,        0,         null,    'Orders'

insert into @ttP select 'OrderDetails.XLSExport',          'Order Details Export to Excel',   1,        0,         null,    'OrderDetails'
insert into @ttP select 'OrderDetails.PDFExport',          'Order Details Export to PDF',     1,        0,         null,    'OrderDetails'

insert into @ttP select 'PickBatches.XLSExport',           'Waves Export to Excel',           1,        0,         null,    'PickBatches'
insert into @ttP select 'PickBatches.PDFExport',           'Waves Export to PDF',             1,        0,         null,    'PickBatches'

insert into @ttP select 'ExportBatchSummarytoPDF',         'Export Batch Summary to PDF',     1,        1,         null,    'Waves.Actions'
insert into @ttP select 'ExportBatchSummarytoExcel',       'Export Batch Summary to Excel',   1,        1,         null,    'Waves.Actions'


insert into @ttP select 'Customers.XLSExport',             'Customers Export to Excel',       1,        0,         null,    'Customers'
insert into @ttP select 'Customers.PDFExport',             'Customers Export to PDF',         1,        0,         null,    'Customers'

insert into @ttP select 'PickBatching.XLSExport',          'Waves Export to Excel',           1,        0,         null,    'PickBatching'
insert into @ttP select 'PickBatching.PDFExport',          'Waves Export to PDF',             1,        0,         null,    'PickBatching'

insert into @ttP select 'Loads.XLSExport',                 'Loads Export to Excel',           1,        0,         null,    'Loads'
insert into @ttP select 'Loads.PDFExport',                 'Loads Export to PDF',             1,        0,         null,    'Loads'

insert into @ttP select 'ManageLoads.XLSExport',           'Loads Export to Excel',           1,        0,         null,    'ManageLoads'
insert into @ttP select 'ManageLoads.PDFExport',           'Loads Export to PDF',             1,        0,         null,    'ManageLoads'

insert into @ttP select 'PickTasks.XLSExport',             'Pick Tasks Export to Excel',      1,        0,         null,    'PickTasks'
insert into @ttP select 'PickTasks.PDFExport',             'Pick Tasks Export to PDF',        1,        0,         null,    'PickTasks'

insert into @ttP select 'PickTaskDetails.XLSExport',       'Pick Task Details Export to Excel',
                                                                                              1,        0,         null,    'PickTaskDetails'
insert into @ttP select 'PickTaskDetails.PDFExport',       'Pick Task Details Export to PDF', 1,        0,         null,    'PickTaskDetails'

insert into @ttP select 'Tasks.XLSExport',                 'Tasks Export to Excel',           1,        0,         null,    'Tasks'
insert into @ttP select 'Tasks.PDFExport',                 'Tasks Export to PDF',             1,        0,         null,    'Tasks'

insert into @ttP select 'ReplenishOrders.XLSExport',       'ReplenishOrders Export to Excel', 1,        0,         null,    'ReplenishOrders'
insert into @ttP select 'ReplenishOrders.PDFExport',       'ReplenishOrders Export to PDF',   1,        0,         null,    'ReplenishOrders'

insert into @ttP select 'ReplenishLocations.XLSExport',    'GenerateReplenishments Export to Excel',
                                                                                              1,        0,         null,    'ReplenishLocations'
insert into @ttP select 'ReplenishLocations.PDFExport',    'GenerateReplenishments Export to PDF',
                                                                                              1,        0,         null,    'ReplenishLocations'

insert into @ttP select 'Users.XLSExport',                 'Users Export to Excel',           1,        0,         null,    'Users'
insert into @ttP select 'Users.PDFExport',                 'Users Export to PDF',             1,        0,         null,    'Users'

insert into @ttP select 'Lookups.XLSExport',               'Lists Export to Excel',           1,        0,         null,    'Lookups'
insert into @ttP select 'Lookups.PDFExport',               'Lists Export to PDF',             1,        0,         null,    'Lookups'

insert into @ttP select 'Controls.XLSExport',              'Controls Export to Excel',        1,        0,         null,    'Controls'
insert into @ttP select 'Controls.PDFExport',              'Controls Export to PDF',          1,        0,         null,    'Controls'

insert into @ttP select 'PutawayRules.XLSExport',          'Putaway Rules Export to Excel',   1,        0,         null,    'PutawayRules'
insert into @ttP select 'PutawayRules.PDFExport',          'Putaway Rules Export to PDF',     1,        0,         null,    'PutawayRules'

insert into @ttP select 'PickBatchRules.XLSExport',        'Waving Rules Export to Excel',    1,        0,         null,    'PickBatchRules'
insert into @ttP select 'PickBatchRules.PDFExport',        'Waving Rules Export to PDF',      1,        0,         null,    'PickBatchRules'

insert into @ttP select 'Exports.XLSExport',               'Exports Export to Excel',         1,        0,         null,    'Exports'
insert into @ttP select 'Exports.PDFExport',               'Exports Export to PDF',           1,        0,         null,    'Exports'

insert into @ttP select 'Contacts.XLSExport',              'Contacts Export to Excel',        1,        0,         null,    'Contacts'
insert into @ttP select 'Contacts.PDFExport',              'Contacts Export to PDF',          1,        0,         null,    'Contacts'

insert into @ttP select 'RoutingZones.XLSExport',          'Routing Zones Export to Excel',   1,        0,         null,    'RoutingZones'
insert into @ttP select 'RoutingZones.PDFExport',          'Routing Zones Export to PDF',     1,        0,         null,    'RoutingZones'

insert into @ttP select 'RoutingRules.XLSExport',          'Routing Rules Export to Excel',   1,        0,         null,    'RoutingRules'
insert into @ttP select 'RoutingRules.PDFExport',          'Routing Rules Export to PDF',     1,        0,         null,    'RoutingRules'

insert into @ttP select 'GenericListing.XLSExport',        'System Info Export to Excel',     1,        0,         null,    'SystemInfo'
insert into @ttP select 'GenericListing.PDFExport',        'System Info Export to PDF',       1,        0,         null,    'SystemInfo'

insert into @ttP select 'ShipVias.PDFExport',              'ShipVia Export to PDF',           1,        0,         null,    'SystemInfo.ShipViaActions'
insert into @ttP select 'ShipVias.XLSExport',              'ShipVia Export to Excel',         1,        0,         null,    'SystemInfo.ShipViaActions'

insert into @ttP select 'Productivity.XLSExport',          'Productivity Export to Excel',    1,        0,         null,    'Productivity'
insert into @ttP select 'Productivity.PDFExport',          'Productivity Export to PDF',      1,        0,         null,    'Productivity'

insert into @ttP select 'ShippingDetails.XLSExport',       'Cycle Count Export to Excel',     1,        0,         null,    'ShippingDetails'
insert into @ttP select 'ShippingDetails.PDFExport',       'Cycle Count Export to PDF',       1,        0,         null,    'ShippingDetails'

insert into @ttP select 'ReceivingDetails.XLSExport',      'ReceivingDetails Export to Excel',1,        0,         null,    'ReceivingDetails'
insert into @ttP select 'ReceivingDetails.PDFExport',      'ReceivingDetails Export to Excel',1,        0,         null,    'ReceivingDetails'

insert into @ttP select 'ProductivityChart.XLSExport',     'ProductivityChart Export to Excel',1,       0,         null,    'ProductivityDetails'
insert into @ttP select 'ProductivityChart.PDFExport',     'ProductivityChart Export to Excel',1,       0,         null,    'ProductivityDetails'

insert into @ttP select 'InterfaceLog.XLSExport',          'InterfaceLog Export to Excel',    1,        0,         null,    'InterfaceLog'
insert into @ttP select 'InterfaceLog.PDFExport',          'InterfaceLog Export to PDF',      1,        0,         null,    'InterfaceLog'

insert into @ttP select 'ReceiveInventory.XLSExport',      'Export to Excel',                 1,        0,         null,    'ReceiveInventory'
insert into @ttP select 'ReceiveInventory.PDFExport',      'Expot to PDF',                    1,        0,         null,    'ReceiveInventory'

insert into @ttP select 'ShippedCounts.XLSExport',         'Shipped Counts to Excel',         1,        1,         null,    'ShippedCounts'
insert into @ttP select 'ShippedCounts.PDFExport',         'Shipped Counts to PDF',           1,        1,         null,    'ShippedCounts'

/********************************************************************************/
exec pr_Setup_Permissions @ttP, 'AU' /* Add/Update */, null, null

Go
