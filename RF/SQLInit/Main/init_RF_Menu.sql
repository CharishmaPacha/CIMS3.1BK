/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/08/22  VKN     Added RFBuildInventory (CIMSV3-3034)
  2021/04/26  RIA     Added Build Load (HA-2675)
  2021/03/19  RIA     Added LoadInquiry (HA-2347)
  2021/02/26  RIA     Added Cancel ShipCartons (HA-2087)
  2021/02/23  RIA     Enabled returns (OB2-1357)
  2021/01/06  RIA     Defined workflow for RFCreateNewLPN (HA-1839)
  2020/11/18  RIA     Added CaptureSerialNo (CIMSV3-1211)
  2020/11/11  MS      RFReplenishBatchPicking: Permissionname corrected (HA-1414)
  2020/11/05  RIA     Added ReceiveASNLPN (JL-283)
  2020/11/05  RIA     Renamed the current RFReceiveASNLPN as RFReceiveASN (JL-296)
  2020/10/12  RIA     Added RFStyleInquiry (HA-1569)
  2020/10/12  RIA     Changed PermissionName for VASInstructions (CIMSV3-1126)
  2020/10/02  RIA     Added SKU Setup (CIMSV3-1108)
  2020/09/28  VM      RFReplenishment: RFPutawayToPicklanes => RFReplenPutawayToPicklanes (CIMSV3-1101)
  2020/09/25  VM      RFPicking: Renamed and re-arranged menus and their Permissions (CIMSV3-1100)
  2020/09/25  VM      RFPutawayLPNOnPallet: Menu and PermissionName => RFPutawayToPicklanes
                      RFReplenishPutaway: Menu and PermissionName => RFReplenishLPNPutaway
                      RFPutawayToPicklanes: Copied to show the same in RFReplenishments as well
                      RFPutawayReplenishPallet, RFPickingLocationSetup: Remove as they are not necessary
                      (CIMSV3-1101)
  2020/09/24  VM      RFAdjustQuantity's PermissionName changed: RFAdjustLPNQuantity => RFAdjustQuantity (HA-1468)
  2020/09/17  YJ      Disabled Menu's which are Inactive (HA-1418)
  2020/09/18  RIA     Updated status and visibility for RFPacking (CIMSV3-622)
  2020/09/04  TK      Added Work Flow details for Replenish Case/Unit Picking (HA-1398)
  2020/08/22  RIA     Defined worflow for Directed Cycle Count (HA-1079)
  2020/06/19  RIA     Defined workflow for Complete Rework (HA-832)
  2020/05/23  SK      Updated workflow name for Picking_Activation (HA-640)
  2020/05/22  TK      Corrected workflow name for RFLPNReservation (HA-521)
  2020/05/15  TK      LPN Picking to use LPNPicking workflow and changed caption for Case Picking (HA-543)
  2020/04/22  YJ      Defined work flow for RFReceiptOrderInquiry (CIMSV3-828)
  2020/05/05  RIA     Changed IsVisble for functions under InventoryManagement and Putaway (HA-404)
  2020/04/03  RT      Changed work flow for Configure Printer (HA-81)
  2020/03/31  VM      Defined WorkFlowName to RFChangeWarehouse (HA-79)
  2020/03/29  RIA     Defined work flow for Cycle count (CIMSV3-773)
  2020/03/17  RIA     Defined work flow for Receive To Location (CIMSV3-755)
  2020/03/17  RIA     Defined work flow for Receive To LPN (CIMSV3-754)
  2020/02/24  RIA     Defined work flow for return RMA (CIMSV3-732)
  2020/02/03  RIA     Defined work flow for Reeceive ASN LPN (CIMSV3-652)
  2020/01/23  RIA     Defined work flow for CaptureTrackingNo in Shipping (CIIMSV3-691)
  2020/01/22  RIA     Defined work flow for Unload Pallet/LPN in Shipping (CIIMSV3-690)
  2020/01/22  RIA     Defined work flow for Load Pallet/LPN in Shipping (CIIMSV3-689)
  2019/12/26  RIA     Defined work flow for Manage Picklane (CIIMSV3-643)
  2019/12/09  RIA     Defined work flow for Complete Production (CID-1211)
  2019/11/21  RIA     Defined work flow for LPN Picking (CIMSV3-650)
  2019/11/12  RIA     Defined work flow for Putaway By Location (CIMSV3-647)
  2019/10/30  RIA     Defined work flow for Xfer Inventory (CIMSV3-636)
  2019/10/28  RIA     Defined work flow for Transfer Inventory (CIMSV3-632)
  2019/10/15  RIA     Defined work flow for Replen Putaway LPN (CIMSV3-631)
  2019/10/04  RIA     Defined work flow for Replenish LPN Picking (CID-836)
  2019/09/24  RIA     Defined work flow for Adjust Qty (CIMSV3-624)
  2019/09/15  RIA     Defined work flow for Putaway Pallet (CIMSV3-623)
  2019/08/17  RIA     Defined work flow for Add SKU To LPN (CID-948)
  2019/08/14  RIA     Defined work flow for Build Pallet (CID-947)
  2019/08/14  RIA     Defined work flow for Putaway LPNs Pallet (CID-910)
  2019/08/11  RIA     Defined work flow for Move Pallet (CID-911)
  2019/07/29  RIA     Defined work flow for Move LPN (CID-871)
  2019/07/16  RIA     Defined work flow for Putaway LPN (CID-726)
  2019/07/10  RIA     Changed caption for Pallet Inquiry (CID-GoLive)
  2019/06/25  RIA     Defined work flow for RFAdjustLPNQuantity (CID-593)
  2019/06/17  RIA     Added Clear Cart (CID-591)
  2019/06/07  RIA     Updated WorkFlow for Confirm Task Picks (CID-518)
  2019/05/13  RIA     Made changes to display the fields based on SortSeq (CIMSV3-535)
  2019/05/12  RIA     Added SortSeq and did alignment changes (CIMSV3-535)
              AY      Added SKU/LPN Inquiry work flows
  2019/03/13  NB      Updated WorkFlow for Location Inquiry Menu Item(CIMSV3-389)
  2019/02/25  NB      Defined work flow for Build Cart under Picking (CIMSV3-370)
  2018/11/29  NB      Initial Revision(CIMSV3-335)
------------------------------------------------------------------------------*/

Go

declare @ParentMenuName       TName;

/* Create temp table */
if (object_id('tempdb..#AMFMenuDetails') is not null) drop table #AMFMenuDetails;
select * into #AMFMenuDetails from AMF_Menu where (1 = 0);

/*----------------------------------------------------------------------------*/
select @ParentMenuName = null;
insert into #AMFMenuDetails
            (MenuName,                  Caption,                      Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'MainMenu',                'AMF Application',            1,       'A',    null,                         'RFMainMenu',                 @ParentMenuName,  0

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'MainMenu';

insert into #AMFMenuDetails
            (MenuName,                  Caption,                      Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFReceiving',             'Receiving',                  1,       'A',    null,                         'RFReceiving',                @ParentMenuName,  1
union select 'RFPutaway',               'Putaway',                    1,       'A',    null,                         'RFPutaway',                  @ParentMenuName,  2
union select 'RFInventoryManagement',   'Inventory Management',       1,       'A',    null,                         'RFInventoryManagement',      @ParentMenuName,  3
union select 'RFCycleCounting',         'Cycle Counting',             1,       'A',    null,                         'RFCycleCounting',            @ParentMenuName,  4
union select 'RFPicking',               'Picking',                    1,       'A',    null,                         'RFPicking',                  @ParentMenuName,  5
union select 'RFPacking',               'Packing',                    1,       'A',    null,                         'RFPacking',                  @ParentMenuName,  6
union select 'RFReplenishment',         'Replenishment',              1,       'A',    null,                         'RFReplenishment',            @ParentMenuName,  7
union select 'RFShipping',              'Shipping',                   1,       'A',    null,                         'RFShipping',                 @ParentMenuName,  8
union select 'RFReturns',               'Returns',                    1,       'A',    null,                         'RFReturns',                  @ParentMenuName,  12
union select 'RFInquiry',               'Inquiry',                    1,       'A',    null,                         'RFInquiry',                  @ParentMenuName,  9
union select 'RFMiscellaneous',         'Miscellaneous Operations',   1,       'A',    null,                         'RFMiscellaneous',            @ParentMenuName,  10
union select 'RFToteOperations',        'Tote Operations',            0,       'I',    null,                         'RFToteOperations',           @ParentMenuName,  11

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFReceiving';

insert into #AMFMenuDetails
            (MenuName,                  Caption,                      Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFReceiveToLPN',          'Receive to LPN',             1,       'A',    'Receiving_ReceiveToLPN',     'RFReceiveToLPN',             @ParentMenuName,  1
union select 'RFReceiveASN',            'Receive ASN',                1,       'A',    'Receiving_ReceiveASN',       'RFReceiveASNCase',           @ParentMenuName,  2
union select 'RFReceiveASNLPN',         'Receive ASN LPN',            1,       'A',    'Receiving_ReceiveASNLPN',    'RFReceiveASNCase',           @ParentMenuName,  3
union select 'RFReceiveToLocation',     'Receive to Location',        1,       'A',    'Receiving_ReceiveToLocation','RFReceiveToLocation',        @ParentMenuName,  4
union select 'RFReturnDisposition',     'Return Disposition',         0,       'I',    null,                         'RFReturnDisposition',        @ParentMenuName,  5
union select 'RFSKUSetup',              'SKU Setup',                  1,       'A',    'Inventory_ModifySKU',        'RFSKUSetup',                 @ParentMenuName,  6

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFPutaway';

insert into #AMFMenuDetails
            (MenuName,                  Caption,                      Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFPutawayLPN',            'Putaway LPN',                1,       'A',    'Putaway_PutawayLPN',         'RFPutawayLPN',               @ParentMenuName,  1
union select 'RFPutawayLPNs',           'Putaway LPNs',               0,       'I',    null,                         'RFPutawayLPNs',              @ParentMenuName,  2
union select 'RFPutawayToPicklanes',    'Putaway To Picklanes',       1,       'A',    'Putaway_PAToPicklane',       'RFPutawayToPicklanes',       @ParentMenuName,  3
union select 'RFPutawayByLocation',     'Putaway By Location',        1,       'A',    'Putaway_PutawayByLocation',  'RFPutawayByLocation',        @ParentMenuName,  4
union select 'RFPutawayPallet',         'Putaway Pallet',             1,       'A',    'Putaway_PutawayPallet',      'RFPutawayPallet',            @ParentMenuName,  5
union select 'RFCompleteProduction',    'Complete Production',        1,       'A',    'Putaway_CompleteVAS',        'RFCompleteProduction',       @ParentMenuName,  6

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFInventoryManagement';

insert into #AMFMenuDetails
            (MenuName,                  Caption,                      Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFBuildInventory',        'Build Inventory',            1,       'A',    'Inventory_BuildInventory',   'RFBuildInventory',           @ParentMenuName,  1
union select 'RFCreateNewLPN',          'Create Inventory LPN',       1,       'A',    'Inventory_CreateInvLPN',     'RFCreateNewLPN',             @ParentMenuName,  2
union select 'RFMoveLPN',               'Move LPN',                   1,       'A',    'Inventory_MoveLPN',          'RFMoveLPN',                  @ParentMenuName,  3
union select 'RFAdjustQuantity',        'Adjust LPN/Location Quantity',
                                                                      1,       'A',    'Inventory_AdjustQty',        'RFAdjustQuantity',           @ParentMenuName,  3
union select 'RFAdjustLocationQuantity','Adjust Location Quantity',   0,       'I',    null,                         'RFAdjustLocationQuantity',   @ParentMenuName,  4
union select 'RFManagePickLanes',       'Manage PickLanes',           1,       'A',    'Inventory_ManagePicklane',   'RFManagePickLanes',          @ParentMenuName,  5
union select 'RFMovePallet',            'Move Pallet',                1,       'A',    'Inventory_MovePallet',       'RFMovePallet',               @ParentMenuName,  6
union select 'RFBuildPallet',           'Build Pallet',               1,       'A',    'Inventory_BuildPallet',      'RFBuildPallet',              @ParentMenuName,  7
union select 'RFTransferInventory',     'Transfer Inventory',         1,       'A',    'Inventory_TransferInventory','RFTransferInventory',        @ParentMenuName,  8
union select 'RFXferInventory',         'Xfer Inventory',             0,       'I',    'Inventory_XferInventory',    'RFXferInventory',            @ParentMenuName,  9

union select 'RFAddSKUToLPN',           'Add SKU To LPN',             1,       'A',    'Inventory_AddSKUToLPN',      'RFAddSKUToLPN',              @ParentMenuName,  10
union select 'RFChangeLPNSKU',          'Change LPN SKU',             0,       'I',    null,                         'RFChangeLPNSKU',             @ParentMenuName,  11
union select 'RFTransferPallet',        'Transfer Pallet',            0,       'I',    null,                         'RFTransferPallet',           @ParentMenuName,  12
union select 'RFExplodePrepack',        'Explode Prepack',            0,       'I',    null,                         'RFExplodePrepack',           @ParentMenuName,  13

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFCycleCounting';

insert into #AMFMenuDetails
            (MenuName,                  Caption,                       Visible, Status, WorkFlowName,                 PermissionName,              ParentMenuName,   SortSeq)
      select 'RFLocationCycleCount',    'Location Cycle Count',        1,       'A',    'LocationCycleCount',         'RFLocationCycleCount',      @ParentMenuName,  1
union select 'RFDirectedCycleCount',    'Directed Cycle Count',        1,       'A',    'DirectedCycleCount',         'RFDirectedCycleCount',      @ParentMenuName,  2

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFPicking';

insert into #AMFMenuDetails
            (MenuName,                  Caption,                      Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFBatchPalletPicking',    'Pallet Picking',             0,       'I',    null,                         'RFBatchPalletPicking',       @ParentMenuName,  1
union select 'RFBatchLPNPicking',       'LPN Picking',                1,       'A',    'LPNPicking',                 'RFBatchLPNPicking',          @ParentMenuName,  2
union select 'RFBatchPicking',          'Case/Unit Picking',          1,       'A',    'BatchPicking',               'RFBatchPicking',             @ParentMenuName,  3
union select 'RFCasePicking',           'Case Picking',               0,       'I',    'BatchPicking',               'RFBatchCasePicking',         @ParentMenuName,  4
union select 'RFUnitPicking',           'Unit Picking',               0,       'I',    'BatchPicking',               'RFBatchUnitPicking',         @ParentMenuName,  5
union select 'RFPickToCart',            'Pick To Cart',               1,       'A',    'BatchPicking',               'RFPickToCart',               @ParentMenuName,  6
union select 'RFPickToShip',            'Pick To Ship',               1,       'A',    'BatchPicking',               'RFPickToShip',               @ParentMenuName,  7

union select 'RFLPNReservation',        'LPN Reservation',            1,       'A',    'Picking_LPNReservation',     'RFLPNReservation',           @ParentMenuName,  11
union select 'RFConfirmTaskPicks',      'Confirm Pick Tasks',         1,       'A',    'ConfirmPickTasks',           'RFConfirmTaskPicks',         @ParentMenuName,  12
union select 'RFActivateShipCarton',    'Activate Ship Cartons',      1,       'A',    'Picking_ActivateShipCartons','RFActivateShipCartons',      @ParentMenuName,  13

union select 'RFBuildCart',             'Build Cart',                 1,       'A',    'Picking_BuildCart',          'RFBuildCart',                @ParentMenuName,  21
union select 'RFClearCart',             'Clear Cart',                 1,       'A',    'ClearCart',                  'ClearCartUser',              @ParentMenuName,  22
union select 'RFDropPallet',            'Drop Pallet',                1,       'A',    'DropPickingPallet',          'RFDropPallet',               @ParentMenuName,  23

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFPacking';

insert into #AMFMenuDetails
            (MenuName,                   Caption,                     Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFOrderScanPacking',       'Order Scan Packing',        1,       'A',    'Packing_OrderPacking',       'RFStartPacking',             @ParentMenuName,  1
union select 'RFClosePackingCarton',     'Close Packing Carton',      1,       'A',    null,                         'RFClosePackingCarton',       @ParentMenuName,  2
union select 'RFPackingCartonContents',  'Packing Carton Contents',   1,       'A',    null,                         'RFPackingCartonContents',    @ParentMenuName,  3

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFInquiry';

insert into #AMFMenuDetails
            (MenuName,                    Caption,                    Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFLocationInquiry',         'Location Inquiry',         1,       'A',    'Inquiry_Location',           'RFLocationInquiry',          @ParentMenuName,  1
union select 'RFLPNInquiry',              'LPN Inquiry',              1,       'A',    'Inquiry_LPN',                'RFLPNInquiry',               @ParentMenuName,  2
union select 'RFSKUInquiry',              'SKU Inquiry',              1,       'A',    'Inquiry_SKU',                'RFSKUInquiry',               @ParentMenuName,  3
union select 'RFPalletInquiry',           'Pallet / Cart Inquiry',    1,       'A',    'Inquiry_Pallet',             'RFPalletInquiry',            @ParentMenuName,  4
union select 'RFOrderInquiry',            'Order Inquiry',            0,       'I',    'Inquiry_Order',              'RFOrderInquiry',             @ParentMenuName,  5
union select 'RFVASInstructions',         'VAS Instructions',         1,       'A',    'Inquiry_VAS',                'RFVASInstructions',          @ParentMenuName,  6
union select 'RFReceiptOrderInquiry',     'Receipt Order Inquiry',    1,       'A',    'Inquiry_ReceiptOrder',       'RFReceiptOrderInquiry',      @ParentMenuName,  7
union select 'RFStyleInquiry',            'SKU - Style Inquiry',      1,       'A',    'Inquiry_SKUStyle',           'RFStyleInquiry',             @ParentMenuName,  8

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFReplenishment';

insert into #AMFMenuDetails
            (MenuName,                    Caption,                    Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFReplenishLPNPicking',     'Replen LPN Picking',       1,       'A',    'ReplenishLPNPicking',        'RFReplenishLPNPicking',      @ParentMenuName,  1
union select 'RFReplenishBatchPicking',   'Replen Case/Unit Picking', 1,       'A',    'ReplenishBatchPicking',      'RFReplenishBatchPicking',    @ParentMenuName,  2
union select 'RFReplenPutawayToPicklanes','Replen Putaway To Picklanes',
                                                                      1,       'A',    'Putaway_PAToPicklane',       'RFReplenPutawayToPicklanes', @ParentMenuName,  3
union select 'RFReplenishLPNPutaway',     'Replen LPN Putaway',       1,       'A',    'ReplenishLPNPutaway',        'RFReplenishLPNPutaway',      @ParentMenuName,  4

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFShipping';

insert into #AMFMenuDetails
            (MenuName,                    Caption,                    Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFBuildLoad',               'Build Load',               1,       'A',    'Shipping_BuildLoad',         'RFLoad',                     @ParentMenuName,  1
union select 'RFLoad',                    'Load Pallet/LPN',          1,       'A',    'Shipping_Load',              'RFLoad',                     @ParentMenuName,  2
union select 'RFUnLoad',                  'UnLoad Pallet/LPN',        1,       'A',    'Shipping_Unload',            'RFUnLoad',                   @ParentMenuName,  3
union select 'RFCaptureTrackingNoInfo',   'Capture Tracking Info',    1,       'A',    'Shipping_CaptureTrackingNo', 'RFCaptureTrackingNoInfo',    @ParentMenuName,  4
union select 'RFCaptureSerialNos',        'Capture Serial Numbers',   1,       'A',    'Shipping_CaptureSerialNo',   'RFCaptureSerialNo',          @ParentMenuName,  5
union select 'RFCancelShipCartons',       'Cancel Ship Cartons',      1,       'A',    'Shipping_CancelShipCartons', 'RFCancelShipCartons',        @ParentMenuName,  6
union select 'RFLoadInquiry',             'Load Inquiry',             1,       'A',    'Inquiry_Load',               'RFLPNInquiry',               @ParentMenuName,  7

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFMiscellaneous';

insert into #AMFMenuDetails
            (MenuName,                    Caption,                    Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFCaptureUPC',              'Manage UPCs',              0,       'I',    null,                         'RFCaptureUPC',               @ParentMenuName,  1
union select 'RFChangeWarehouse',         'Change Warehouse',         1,       'A',    'Misc_ChangeWarehouse',       'RFMiscellaneous',            @ParentMenuName,  2
union select 'RFConfigurePrinter',        'Configure Printer',        1,       'A',    'Misc_ConfigurePrinter',      'RFMiscellaneous',            @ParentMenuName,  3
union select 'RFCompleteRework',          'Complete Rework',          1,       'A',    'Misc_CompleteRework',        'RFCompleteRework',           @ParentMenuName,  4
/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFToteOperations';

insert into #AMFMenuDetails
            (MenuName,                    Caption,                    Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFProcessLPN',              'Process LPN',              0,       'I',    null,                         'RFProcessLPN',               @ParentMenuName,  1
union select 'RFTotePAPallet',            'Putaway Totes on Pallet',  0,       'I',    null,                         'RFTotePAPallet',             @ParentMenuName,  2

/*----------------------------------------------------------------------------*/
select @ParentMenuName = 'RFReturns';

insert into #AMFMenuDetails
            (MenuName,                    Caption,                    Visible, Status, WorkFlowName,                 PermissionName,               ParentMenuName,   SortSeq)
      select 'RFReturnRMA',               'Receive Returns',          1,       'A',    'Return_RMA',                 'RFReturnProcess',            @ParentMenuName,  1

/******************************************************************************/
delete from AMF_Menu;

insert into AMF_Menu (MenuName, Caption, Visible, Status, WorkFlowName, PermissionName, ParentMenuName, SortSeq)
  select MD.MenuName, MD.Caption, MD.Visible, MD.Status, MD.WorkFlowName, MD.PermissionName, MD.ParentMenuName, coalesce(nullif(MD.SortSeq, 0), RecordId)
  from #AMFMenuDetails MD;

Go
