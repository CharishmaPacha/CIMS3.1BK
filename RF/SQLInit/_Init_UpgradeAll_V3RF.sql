/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/08/23  CHP     Added WorkFlow and Form for Build Inventory (CIMSV3-3034)
  2021/04/26  RIA     Added forms for Build Load (HA-2675)
  2021/04/19  RIA     Added forms for Location Inquiry (OB2-1767)
  2021/03/19  RIA     Added work flow and forms for Load Inquiry (HA-2347)
  2021/02/26  RIA     Added work flow and forms for Cancel Ship Cartons (HA-2087)
  2021/01/06  RIA     Added workflow and form for Create Inventory LPN (HA-1839)
  2020/11/18  RIA     Added workflow and form for Capture SerialNo (CIMSV3-1211)
  2020/11/15  RIA     Moved workflow and form for SKU Setup (CIMSV3-1108)
  2020/11/09  RIA     Added form for Start Receiving (JL-296)
  2020/11/05  RIA     Added workflow and forms for ReceiveASNLPN (JL-283)
  2020/11/05  RIA     Renamed the current RFReceiveASNLPN as RFReceiveASN (JL-296)
  2020/10/12  RIA     Added workflow and forms for SKU Style Inquiry (HA-1569)
  2020/10/05  RIA     Added SKU Info panel form (CIMSV3-1110)
  2020/09/04  SK      Added workflow and forms for Replenish Case/Unit picking (HA-1398)
  2020/09/03  RIA     Added form for Suggested Location screen for Directed CC (HA-1079)
  2020/07/12  RIA     Added workflow and forms for Directed CC (HA-1079)
  2020/07/20  RIA     Added form for InvClasses in Manage Picklane (HA-652)
  2020/07/14  SK      Added form for CC Reserve Pallet (HA-1077)
  2020/07/01  RIA     Added a new form for Drop Pallet (HA-790)
  2020/06/22  RIA     Renamed workflow and forms for Rework Order processing (HA-832)
  2020/06/20  RIA     Added workflow and forms for rework order processing (HA-832)
  2020/05/26  AY      Add forms for DropPallet & drop Cart i.e. Split DropPallet/Drop Cart forms (HA-649)
  2020/05/24  SK      Added workflow and forms for LPN Activation (HA-640)
  2020/05/23  TK      Added LPN Reservation related form and work flow (HA-521)
  2020/05/12  YJ      Added workflow and forms for Receipt Order Inquiry (CIMSV3-828)
  2020/04/17  RIA     Added workflow and forms for PutawayPallet (CIMSV3-623)
  2020/04/15  SK      Added workflow and forms for cycle counting (CIMSV3-788)
  2020/04/01  VM      Added workflow and form for Miscellaneous->Change Warehouse (HA-79)
  2020/03/17  RIA     Added workflow and forms for Receive To Location (CIMSV3-755)
  2020/03/16  RIA     Added workflow and forms for Receive To LPN (CIMSV3-754)
  2020/02/24  RIA     Added workflow and forms for Returns (CIMSV3-732)
  2020/02/04  RIA     Added workflow and forms for ASN Receiving (CIMSV3-652)
  2020/01/23  RIA     Added workflow and forms for Capture TrackingNo in Shipping (CIMSV3-691)
  2020/01/22  RIA     Added workflow and forms for Unload in Shipping (CIMSV3-690)
  2020/01/22  RIA     Added workflow and forms for Add Load in Shipping (CIMSV3-689)
  2020/01/05  RIA     Added workflow and forms for Manage Picklane (CID-643)
  2019/12/09  RIA     Added workflow and forms for Complete Production(VAS) (CID-1211)
  2019/11/22  RIA     Added workflow and forms for LPN Picking (CIMSV3-650)
  2019/11/20  RIA     Added workflow and forms for Putaway By Location (CIMSV3-647)
  2019/11/13  RIA     Added workflow and forms for Adjust Qty (CIMSV3-624)
  2019/10/30  RIA     Added workflow and forms for Xfer Inventory (CIMSV3-636)
  2019/10/30  RIA     Added workflow and forms for Transfer Inventory (CIMSV3-632)
  2019/10/28  RIA     Renamed workflow and forms for Adjust Quantity (CIMSV3-624)
  2019/10/15  RIA     Added Replen LPN Putaway work flow forms and details (CIMSV3-631)
  2019/10/04  RIA     Added Replenishment LPN picking work flow forms and details (CID-836)
  2019/08/17  RIA     Added Add SKU To LPN forms and details (CID-948)
  2019/08/16  RIA     Added Build Pallet forms and details (CID-947)
  2019/08/14  RIA     Added Putaway LPNs on Pallet forms and details (CID-910)
  2019/08/11  RIA     Added Move Pallet forms and details (CID-911)
  2019/08/04  RIA     Added Putaway LPN forms and details (CID-726)
  2019/07/29  RIA     Added putaway LPN work flow forms and details(CID-871)
  2019/07/21  NB      Added init_DebugControls (CID-835)
  2019/07/16  RIA     Added Putaway LPN work flow forms and details (CID-726)
  2019/06/26  RIA     Added Adjust LPN Quantity work flow forms and details (CID-593)
  2019/06/24  RIA     Added init_Messages (CID-577)
  2019/06/17  RIA     Added Clear Cart work flow forms and details (CID-591)
  2019/06/07  RIA     Added Confirm Task picks work flow forms and details (CID-518)
  2019/05/31  RIA     Added Pallet Inquiry work flow forms and details (CIMSV3-463)
  2019/05/21  RIA     Added VAS Instructions work flow forms and details (CID-382)
  2019/03/27  NB      Added Location Inquiry work flow forms and details (CIMSV3-389)
  2019/03/25  YJ/VM   Initial revision.
------------------------------------------------------------------------------*/
/* Apply AMF related init changes to a CIMS Database */

/* Inits */
Input .\Main\init_DebugControls.sql;
Input .\Main\init_RF_DeviceCategories.sql;
Input .\Main\init_RF_Fields.sql;
Input .\Main\init_RF_Menu.sql;
Input .\Main\init_Messages.sql;

/******************************************************************************/
/* The workflows below are organized by module as they appear in the RF Menu
   and not in alphabetic order as is the usual convention for CIMS */
/******************************************************************************/

/******************************************************************************/
/* Common Forms & Form Segments */
/******************************************************************************/
Input .\Common\Init_RF_FormSegment_Common_QuantityInputPanel.sql;
Input .\Common\Init_RF_FormSegment_Common_SKUInfoPanel.sql;

/******************************************************************************/
/* Putaway Work Flows */
/******************************************************************************/
/* Putaway LPN Flow Forms  */
Input .\Putaway\Init_RF_WF_Putaway_PutawayLPN.sql;
Input .\Putaway\Init_RF_Form_Putaway_PutawayLPN.sql;
Input .\Putaway\Init_RF_Form_Putaway_PutawayToPickLane.sql;

/* Putaway LPNs on Pallet Work Flow Forms */
Input .\Putaway\Init_RF_WF_Putaway_PAToPicklane.sql;
Input .\Putaway\Init_RF_Form_Putaway_PAtoPL_ScanPalletOrCart.sql;
Input .\Putaway\Init_RF_Form_Putaway_PAToPicklane.sql;

/* Putaway By Location Work Flow Forms  */
Input .\Putaway\Init_RF_WF_Putaway_PutawayByLocation.sql;
Input .\Putaway\Init_RF_Form_Putaway_PutawayByLocation.sql;

/* Putaway Pallet Work Flow Forms  */
Input .\Putaway\Init_RF_WF_Putaway_PutawayPallet.sql;
Input .\Putaway\Init_RF_Form_Putaway_PutawayPallet.sql;

/* Complete Production Work Flow Forms  */
Input .\Putaway\Init_RF_WF_Putaway_VASComplete.sql;
Input .\Putaway\Init_RF_Form_Putaway_VASComplete.sql;

/******************************************************************************/
/* Inventory Work Flows */
/******************************************************************************/
/* Add SKU To LPN Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_AddSKUToLPN.sql;
Input .\Inventory\Init_RF_Form_Inventory_AddSKUToLPN.sql;

/* Adjust LPN Quantity Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_AdjustQty.sql;
Input .\Inventory\Init_RF_Form_Inventory_AdjustLPNQty.sql;
Input .\Inventory\Init_RF_Form_Inventory_AdjustLocationQty.sql;

/* Build Inventory Work Flow Forms  */
Input .\Inventory\init_RF_WF_Inventory_BuildInventory.sql;
Input .\Inventory\init_RF_Form_Inventory_BuildInventory.sql;

/* Create Inventory LPN Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_CreateInvLPN.sql;
Input .\Inventory\Init_RF_Form_Inventory_CreateInvLPN.sql;

/* Manage Picklanes Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_ManagePicklane.sql;
Input .\Inventory\Init_RF_Form_Inventory_ManagePicklane.sql;
Input .\Inventory\Init_RF_Form_Inventory_ManagePicklane_SetUpPicklane.sql;
Input .\Inventory\Init_RF_Form_Inventory_ManagePicklane_AddInventory.sql;
Input .\Inventory\Init_RF_Form_Inventory_ManagePicklane_AddSKUWithInvClass.sql;

/* Move LPN Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_MoveLPN.sql;
Input .\Inventory\Init_RF_Form_Inventory_MoveLPN.sql;

/* Move Pallet Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_MovePallet.sql;
Input .\Inventory\Init_RF_Form_Inventory_MovePallet.sql;

/* Build Pallet Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_BuildPallet.sql;
Input .\Inventory\Init_RF_Form_Inventory_BuildPallet.sql;

/* SKU Setup Work Flow Forms  */
Input .\Inventory\init_RF_WF_Inventory_ModifySKU.sql;
Input .\Inventory\init_RF_Form_Inventory_ModifySKU.sql;

/* Transfer Inventory Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_TransferInventory.sql;
Input .\Inventory\Init_RF_Form_Inventory_TransferLPNInventory.sql;
Input .\Inventory\Init_RF_Form_Inventory_TransferLocationInventory.sql;

/* Xfer Inventory Work Flow Forms  */
Input .\Inventory\Init_RF_WF_Inventory_XferInventory.sql;
Input .\Inventory\Init_RF_Form_Inventory_XferLPNInventory.sql;
Input .\Inventory\Init_RF_Form_Inventory_XferLocationInventory.sql;

/******************************************************************************/
/* Cycle Counting Work Flows */
/******************************************************************************/
/* Location Cycle Count */
Input .\CycleCount\init_RF_WF_CycleCount_LocationCC.sql;
Input .\CycleCount\init_RF_Form_CycleCount_StartLocationCC.sql;
Input .\CycleCount\init_RF_Form_Cyclecount_ConfirmReserveLocLD2.sql;
Input .\CycleCount\init_RF_Form_CycleCount_ConfirmPicklaneCount.sql;
Input .\CycleCount\init_RF_Form_Cyclecount_ConfirmReserveLocPD3.sql;

/* Directed Cycle Count */
Input .\CycleCount\init_RF_WF_CycleCount_DirectedCC.sql;
Input .\CycleCount\init_RF_Form_CycleCount_DirectedCC_Start.sql;
Input .\CycleCount\init_RF_Form_CycleCount_DirectedCC_ScanLoc.sql;

/******************************************************************************/
/* Picking Work Flows */
/******************************************************************************/
/* Batch Picking Work Flow Forms */
Input .\Picking\init_RF_Form_Picking_BatchPicking_GetPickTask.sql;
Input .\Picking\init_RF_Form_Picking_BatchPicking_ConfirmUnitPick.sql;
Input .\Picking\init_RF_Form_Picking_BatchPicking_ConfirmLPNPick.sql;

/* Batch Picking Work Flow Definition */
Input .\Picking\init_RF_WF_Picking_BatchPicking.sql;

/* Build Cart Work Flow Forms */
Input .\Picking\init_RF_Form_Picking_BuildCart_AddCartonToCart.sql;
Input .\Picking\init_RF_Form_Picking_BuildCart_StartAndConfirm.sql;
/* Build Cart Work Flow Definition */
Input .\Picking\init_RF_WF_Picking_BuildCart.sql;

/* Clear Cart Work Flow Forms */
Input .\Picking\init_RF_WF_Picking_ClearCart.sql;
Input .\Picking\init_RF_Form_Picking_ClearCart.sql;

/* Confirm picks Work Flow Forms */
Input .\Picking\init_RF_WF_Picking_ConfirmTaskPicks.sql;
Input .\Picking\init_RF_Form_Picking_ConfirmTaskPicks.sql;

/* Drop Picking Pallet Work Flow Forms */
Input .\Picking\init_RF_Form_Picking_DropPickingPallet_ValidatePallet.sql;
Input .\Picking\init_RF_Form_Picking_DropPickingPallet_Confirm.sql;
Input .\Picking\init_RF_Form_Picking_DropPickingCart_Confirm.sql;
Input .\Picking\init_RF_Form_Picking_DropReservedPallet_Confirm.sql;
--Input .\Picking\init_RF_Form_Picking_DropPickingPallet_DropPallet.sql;
/* Drop Picking Pallet Work Flow Definition */
Input .\Picking\init_RF_WF_Picking_DropPickingPallet.sql;

/* LPN Picking Work Flow Forms  */
Input .\Picking\init_RF_WF_Picking_LPNPicking.sql;
Input .\Picking\init_RF_Form_Picking_LPNPick_GetPick.sql;
Input .\Picking\init_RF_Form_Picking_LPNPick_Confirm.sql;

/* LPN Reservations Work Flow Forms  */
Input .\Picking\init_RF_Form_Picking_LPNReservation.sql;
Input .\Picking\init_RF_WF_Picking_LPNReservation.sql;

/* LPN Ship Cartons Reservation Work Flow Forms */
Input .\Picking\init_RF_WF_Picking_ActivateShipCartons.sql;
Input .\Picking\init_RF_Form_Picking_ActivateShipCartons.sql;

/******************************************************************************/
/* Packing Work Flows */
/******************************************************************************/
/* Packing Flow Forms  */
Input .\Packing\Init_RF_WF_Packing_OrderPacking.sql;
Input .\Packing\Init_RF_Form_Packing_ScanOrder.sql;
Input .\Packing\Init_RF_Form_Packing_ScanPackOrder.sql;
Input .\Packing\Init_RF_Form_Packing_ClosePackage.sql;

/******************************************************************************/
/* Inquiry Work Flows */
/******************************************************************************/
/* Location Inquiry Work Flow Forms  */
Input .\Inquiry\init_RF_WF_Inquiry_Location.sql;
Input .\Inquiry\init_RF_Form_Inquiry_Location.sql;
Input .\Inquiry\init_RF_Form_Inquiry_Location_Picklane.sql;

/* LPN Inquiry Work Flow Forms  */
Input .\Inquiry\init_RF_WF_Inquiry_LPN.sql;
Input .\Inquiry\init_RF_Form_Inquiry_LPN.sql;

/* Pallet Inquiry Work Flow Forms  */
Input .\Inquiry\init_RF_WF_Inquiry_Pallet.sql;
Input .\Inquiry\init_RF_Form_Inquiry_Pallet.sql;

/* Receipt Order Inquiry Work Flow Forms  */
Input .\Inquiry\Init_RF_WF_Inquiry_ReceiptOrder.sql;
Input .\Inquiry\Init_RF_Form_Inquiry_ReceiptOrder.sql;

/* SKU Inquiry Work Flow Forms  */
Input .\Inquiry\init_RF_WF_Inquiry_SKU.sql;
Input .\Inquiry\init_RF_Form_Inquiry_SKU.sql;

/* SKU Style Inquiry Work Flow Forms  */
Input .\Inquiry\init_RF_WF_Inquiry_SKUStyle.sql;
Input .\Inquiry\init_RF_Form_Inquiry_SKUStyle.sql;

/* Load Inquiry Work Flow Forms  */
Input .\Inquiry\Init_RF_WF_Inquiry_Load.sql;
Input .\Inquiry\Init_RF_Form_Inquiry_Load.sql;

/* VAS Instructions Work Flow Forms  */
Input .\Inquiry\init_RF_WF_Inquiry_VAS.sql;
Input .\Inquiry\init_RF_Form_Inquiry_VAS.sql;

/******************************************************************************/
/* Miscellenous Work Flows */
/******************************************************************************/
/* Change Warehouse Work Flow Forms */
Input .\Miscellaneous\init_RF_WF_Misc_ChangeWarehouse.sql;
Input .\Miscellaneous\init_RF_Form_Misc_ChangeWarehouse.sql;
/* Configure Printer Work Flow Forms */
Input .\Miscellaneous\init_RF_WF_Misc_ConfigurePrinter.sql;
Input .\Miscellaneous\init_RF_Form_Misc_ConfigurePrinter.sql;

/* Complete Production Work Flow Forms */
Input .\Miscellaneous\init_RF_WF_Misc_CompleteRework.sql;
Input .\Miscellaneous\init_RF_Form_Misc_CompleteRework.sql;
Input .\Miscellaneous\init_RF_Form_Misc_CompleteRework_ScanOrder.sql;

/******************************************************************************/
/* Receiving Work Flows */
/******************************************************************************/
/* Common form for Start Receiving */
Input .\Receiving\init_RF_Form_Receiving_StartReceiving.sql;

/* Receive ASN Work Flow Forms  */
Input .\Receiving\init_RF_WF_Receiving_ReceiveASN.sql;
Input .\Receiving\init_RF_Form_Receiving_ReceiveASN_StartReceiving.sql;
Input .\Receiving\init_RF_Form_Receiving_ReceiveASN.sql;

/* Receive ASN LPN Work Flow Forms */
Input .\Receiving\init_RF_WF_Receiving_ReceiveASNLPN.sql;
Input .\Receiving\init_RF_Form_Receiving_ReceiveASNLPN.sql;

/* Receive To LPN Work Flow Forms  */
Input .\Receiving\init_RF_WF_Receiving_ReceiveToLPN.sql;
Input .\Receiving\init_RF_Form_Receiving_ReceiveToLPN_StartReceiving.sql;
Input .\Receiving\init_RF_Form_Receiving_ReceiveToLPN.sql;

/* Receive To Location Work Flow Forms  */
Input .\Receiving\init_RF_WF_Receiving_ReceiveToLocation.sql;
Input .\Receiving\init_RF_Form_Receiving_ReceiveToLocation_StartReceiving.sql;
Input .\Receiving\init_RF_Form_Receiving_ReceiveToLocation.sql;

/******************************************************************************/
/* Replenishment Work Flows */
/******************************************************************************/
/* Replenish LPN Picking Work Flow Forms  */
Input .\Replenishment\init_RF_WF_Replenishment_LPNPicking.sql;
Input .\Replenishment\init_RF_Form_Replenishment_GetLPNPick.sql;
Input .\Replenishment\init_RF_Form_Replenishment_ConfirmLPNPick.sql;

/* Replenish Case/Unit Picking Work Flow Forms  */
Input .\Replenishment\init_RF_WF_Replenishment_BatchPicking.sql;
Input .\Replenishment\init_RF_Form_Replenishment_GetPickTask.sql;
Input .\Replenishment\init_RF_Form_Replenishment_ConfirmUnitPick.sql;

/* Replenish LPN Putaway Work Flow Forms  */
Input .\Replenishment\init_RF_WF_Replenishment_PutawayLPN.sql;
Input .\Replenishment\init_RF_Form_Replenishment_PutawayLPN.sql;

/******************************************************************************/
/* Returns Work Flows */
/******************************************************************************/
/* Return RMA Work Flow Forms  */
Input .\Returns\init_RF_WF_Returns_RMA.sql;
Input .\Returns\init_RF_Form_Returns_ScanRMA.sql;
Input .\Returns\init_RF_Form_Returns_StartReturns.sql;

/******************************************************************************/
/* Shipping Work Flows */
/******************************************************************************/
/* Load LPNOrPallet Work Flow Forms  */
Input .\Shipping\init_RF_WF_Shipping_Load.sql;
Input .\Shipping\init_RF_Form_Shipping_Load.sql;

/* Unload LPNOrPallet Work Flow Forms  */
Input .\Shipping\init_RF_WF_Shipping_Unload.sql;
Input .\Shipping\init_RF_Form_Shipping_Unload.sql;

/* Capture TrackingNo Work Flow Forms  */
Input .\Shipping\init_RF_WF_Shipping_CaptureTrackingNo.sql;
Input .\Shipping\init_RF_Form_Shipping_CaptureTrackingNo.sql;

/* Capture SerialNo Work Flow and Forms  */
Input .\Shipping\init_RF_WF_Shipping_CaptureSerialNos.sql;
Input .\Shipping\init_RF_Form_Shipping_CaptureSerialNos.sql;

/* Cancel Ship Cartons Work Flow and Forms  */
Input .\Shipping\init_RF_WF_Shipping_CancelShipCartons.sql;
Input .\Shipping\init_RF_Form_Shipping_CancelShipCartons.sql;

/* Build LPNOrPallet on Load Work Flow Forms  */
Input .\Shipping\init_RF_WF_Shipping_BuildLoad.sql;
Input .\Shipping\init_RF_Form_Shipping_BuildLoad.sql;

Go
