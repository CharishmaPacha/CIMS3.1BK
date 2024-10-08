/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/27  LAC     Added AT_PreprocessOrder (BK-1036)
  2023/03/22  PKK     Added AT_ApproveToReleaseWave (BK-1033)
  2022/05/16  RKC     Added AT_LPNSubstitute_AddNewLine (BK-819)
  2022/04/11  GAG     Added AT_SKUCommercialInfoModified (BK-797)
  2021/12/30  SRP     Modified description for AT_WaveCancelled (BK-730)
  2021/12/24  TK      AT_OrderUnWaved & AT_OrderDetailUnWaved: Corrected description (BK-720)
  2021/11/12  AJM     Added AT_OrderUnWaved, AT_OrderDetailUnWaved (CIMSV3-1322)
  2021/08/26  TK      Added AT_WaveAllocationCompleted (BK-536)
  2021/07/21  PKD     LPNOwnerModified: Changed to AT_ChangeOwnership (OB2-1954)
  2021/06/28  SAK     AT_WaveOrdersAdded added for AddOrdersToWave (CIMSV3-1516)
  2021/06/15  VM      AT_ODModifyOrderDetails: Added (CIMSV3-1515)
  2021/06/15  KBB     Modified description for AT_LoadModified (CIMSV3-1501)
  2021/06/10  VM      AT_ShipDetailsModify => AT_OrderShipDetailsModify (OB2-1887)
  2021/06/09  SJ      Modified AT messages for AT_TaskAssigned & AT_TaskUnassigned (OB2-1821)
  2021/05/25  SK      Added AT_Load_ActivateShipCartons (HA-2808)
  2021/05/25  SK      Added AT_Load_ActivateShipCartons and Load_ActivateShipCartonsInvalidInput (HA-2808)
  2021/05/20  AJM     Changed the messagename 'AT_PickBatchReAllocation' to 'AT_WaveReAllocation' & modified description (CIMSV3-1474)
  2021/05/12  SV      Added AT_RMAReceived (OB2-1794)
  2021/05/11  AJM     Changed the messagename 'AT_PickBatchModifyPriority' to AT_WaveModified (CIMSV3-1462)
  2021/05/04  AJM     Modified description for AT_LPNTypeModified (CIMSV3-1450)
  2021/04/14  AJM     Modified description for AT_ModifyLocationType (CIMSV3-1429)
  2021/04/06  AJM     Modified description for AT_ModifyLocationAtrributes (CIMSV3-1428)
  2021/04/03  TK      Changes to AT_LPNShipped & AT_OrderShipped (HA-1842)
  2021/03/19  RKC     Changed the AT_PalletsMerged: Include LPNs merged (HA-2340)
  2021/03/17  SV      Added AT_CreateRMA (OB2-1358)
  2021/03/08  OK      AT_OrderRemovedFromLoad: Changed the place holders to be able to use bulk AT logging (HA-2121)
  2021/03/04  AJM     Changed the messagename 'AT_pickbatchReleased' from 'AT_WaveReleased' (CIMSV3-1326)
  2021/02/26  KBB     Added new AT message AT_CancelShipLabel (HA-2089)
  2021/02/19  TK      Added AT_LoadGenerated,
                            AT_OrderAddedToNewLoad &
                            AT_OrderAddedToNewLoadFromDiffLoad (HA-1962)
  2021/01/30  RKC     Added New AT message AT_ModifyLocationType,
                       AT_ChangeLocationStorageType: Reverted back to original message (CIMSV3-1181)
  2021/01/21  SK      Added AT_Activation (HA-1932)
              AY      Added AT_ScanLoadLPN, AT_ScanLoadPallet (HA-1947)
  2021/01/06  AJM     Modified description for AT_ModifyPickTicket (CIMSV3-1296)
  2020/12/15  AJM     Modified description for AT_Loc_UpdateAllowedOperations (CIMSV3-1280)
  2020/12/10  RT      Included AT_TaskDetail_Export (CID-1569)
  2020/11/26  KBB     Changed the description for AT_TaskAssigned (CIMSV3-1178)
  2020/11/24  MS      Added AT_PalletizeLPN, Modified AT_ReceiveToLPN (JL-306)
  2020/11/21  AJM     Modified description for AT_LocPickZoneModified (CIMSV3-1231)
  2020/11/17  AJM     Modified description for AT_LocPutawayZoneModified (CIMSV3-1182)
  2020/11/11  MS      Aded AT_LPNCartonDetailsModified (CIMSV3-1155)
  2020/11/03  AJM     Modified description for AT_LPNSKUChanged (HA-615)
  2020/11/01  RKC     Changed the description for AT_ChangeLocationStorageType (CIMSV3-1181)
  2020/10/27  MS      Added AT_ReceiptHeaderReopened, AT_ReceiptHeaderClosed (CIMSV3-1146)
  2020/10/06  SK      Added AT_Reservation (HA-1491)
  2020/09/25  VS      Added AT_DeferCancelWave, AT_CancelWave (CIMSV3-1078)
  2020/09/16  AJM     Added AT_LPNReworked, AT_OrderReworked (HA-598)
  2020/09/16  MS      Added AT_ODModifyPackCombination (HA-775)
  2020/09/12  TK      Added AT_CreateLPNs_OrderLPNs (HA-1238)
  2020/09/04  TK      Corrected %Task to %TaskId (HA-1392)
  2020/09/02  AJM     Corrected description for AT_ReceiveToLocation (HA-229)
  2020/08/19  RIA     Added AT_PalletsMerged (HA-1245)
  2020/08/19  AJM     Added AT_PalletMovedToLocation (HA-1310)
  2020/08/15  OK      pr_OrderHeaders_VoidTempLabels: Added AT_UnWaveOrder_VoidTempLabel (HA-1306)
  2020/08/05  SJ      Added AT_Receipts_ChangeArrivalInfo (HA-1228)
  2020/07/21  RKC     Added AT_LPNContentsXferedToPicklane (HA-1182)
  2020/07/18  OK      Added AT_Loads_ModifyApptDetails, AT_Loads_ModifyBoLInfo (HA-1147)
  2020/07/17  RKC     Added AT_LPNAddedToLoad, AT_LPNRemovedFromLoad (HA-1088)
  2020/07/11  TK      Added AT_LPNPalletized, AT_LPNPalletized_FromDiffPallet & AT_LPNDePalletized (HA-1031)
  2020/06/17  AJM     Added AT_ReceiptsWarehouseChanged (HA-926)
  2020/06/23  TK      Added Rework releated AT messages (HA-833)
  2020/06/17  SAK     Added AT_LPNReservedForWave and AT_LPNUnReservedForWave (HA-819)
  2020/06/12  RKC     Added AT_ODModified_PTcancel (HA-712)
  2020/05/10  TK      Modified description for AT_LPNSKUChanged (HA-475)
  2020/05/07  TK      Modified description for AT_ModifyLPNs (HA-422)
  2020/04/08  VS      Added AT_RFUserLogout (HA-95)
  2019/10/02  MS      Added AT_PackingPackLPN (SRI-1063)
  2019/07/16  MJ      Made change to log the message correctly in AT_ModifyLPNs (GNC-2196)
  2019/07/12  RKC     Added AT_LPNPackedAtShippingdoc (CID-787)
  2019/03/12  RIA     Changed AT_SKUDimensionsModified to display SKU (HPI-2485)
  2019/02/14  RIA     Added AT_OrderDisqualified_PartiallyAllocated (S2G-1204)
  2019/02/08  AY/VS   Added AT_LPNQCHold, AT_LPNQCRelease (CID-68)
  2019/02/05  HB      Added AT_BuildCart (HPI-2381)
  2018/11/22  RT      Added AT_FullPalletTransferEachLPN (HPI-2169)
  2018/11/21  TK      Added AT_PutawayLPNToOtherThanSuggPicklane (HPI-2166)
  2018/11/13  RT      Added AT_ModifyLocationAtrbts_UpdatedBothAttributes, AT_ModifyLocationAtrbts_UpdateLocationSubType
                        AT_ModifyLocationAtrbts_UpdateAllowMultipleSKUs (HPI-2131)
  2018/11/13  MJ      Added AT_PickBatchOrderDetailsAdded (S2GCA-313)
              TK      Added AT_TransferReservation (HPI-2116)
  2018/06/07  AJ      Added ModifyLocationAttributes_AllowMultipleSKUs & ModifyLocationAttributes_RestrictMultipleSKUs (S2G-904)
  2018/05/31  SV      AT_LPNVoided: Updated with Reference value (HPI-1921)
  2018/05/18  AJ      Added AT_AddNote,AT_ReplaceNote and AT_DeleteNote (S2G-838)
  2018/04/25  AJ      Added AT_RegenerateTrackingNo(S2G-549)
  2018/03/13  AJ      Added AT_TaskDetailCancel_NoCartPosition and
                      modified AT_PickBatchesReleased to AT_WaveReleaseForPicking(S2G-388)
  2018/03/13  OK      Added AT_Replenish_LPNAllocatedToOrderOnBatch, AT_Replenish_UnitsAllocatedToOrderOnBatch (S2G-397)
  2018/03/08  TD      Added AT_NoteModified (S2G-378)
  2018/02/28  CK      Changed description for AT_CCLPN (S2G-294)
  2018/02/19  SV      Updated AT_ReceiveToLocation, AT_ReceiveToLPN as pet the AT defined for LPNs which got created from UI (S2G-225)
  2018/02/16  AJ      Changed Description for AT_PickBatchReleased (S2G-231)
  2018/01/03  TD      Added AT_ChangeLocationProfile, AT_ChangeLocationMaxLimits (CIMS-1741)
  2017/09/27  SV      Added AT_PackingReopenLPN (OB-592)
  2017/07/18  TK      Added AT_CloseBPT_UnallocateLPNDetail (HPI-1597)
  2017/06/30  CK      Added AT_LPNShortPickedWithAvailableQty (FB-953)
  2017/03/03  PSK     Added AT_VAS_RePrintEngravingLabels (HPI-792)
  2017/03/03  AY      Added AT_ReplenishPA (HPI-684)
  2017/01/06  PSK     Changed AT_VAS_PrintEngravingLabels (HPI-792)
  2017/01/04  YJ      Added AT_PickTasksConfirm (HPI-1158)
  2016/11/04  OK      Added AT_DropLPNOnBuildPallet (HPI-1003)
  2016/09/27  PSK     Added AT_VAS_PrintEngravingLabels_LPNs (HPI-792)
  2016/09/17  SV      Added AT messages during fulfilling the replenish order (HPI-684)
  2016/09/16  RV      Added AT_LPNSubstitute (HPI-685)
  2016/08/30  NY      Added AT_TaskDetailCancel (HPI-431)
  2016/08/11  SV      Added AT_LPNLOCAllocatedForOrder (HPI-458)
  2016/07/28  AY      Added AT_VAS_InventoryAdjustment (HPI-293)
  2016/07/13  OK      Added AT_ShipCartonDropped (HPI-247)
  2016/07/08  OK      Added AT_VAS_CompleteProduction, AT_VAS_PrintEngravingLabels, AT_SoftAllocation_Qualified (HPI-245)
  2016/06/22  KL      Added AT_ClearedUserOnCart (NBD-593)
  2016/06/17  PSK     Changed description for AT_Load_UnderlyingBoLGenerated(CIMS-976).
  2016/06/06  TK      Added AT_RDModified_QtyOrdered (FB-685)
  2016/05/25  OK      Added AT_ReceiptOwnerModified (CIMS-680)
  2016/05/24  OK      Changed AT_LPNAdjustQty description to display Original Quantity in AT(HPI-121)
  2016/05/12  PSK     Corrected from AT_OrdersRemovedFromLoad to AT_OrderRemovedFromLoad (CIMS-921)
  2016/05/10  SV      Added AT_OrdersUnWaved (NBD-481)
  2016/05/05  TK      Added AT_ExplodePrepackOnAllocation (FB-648)
  2016/04/27  AY      Added messages for Load-BoL generation.
  2016/04/01  DK      Modified Audittrail for AT_InvTransferLPNToLPN, AT_InvTransferLPNToLoc, AT_InvTransferLOCToLPN and AT_InvTransferLOCToLoc (FB-646).
  2016/02/26  NY      Added AT_UPCRemovedFromSKU
  2016/02/18  OK      Added AT_DeleteLocation (NBD-169)
  2016/02/12  SV      Added AT_ShipDetailsModify (CIMS-769)
  2016/01/28  SV      Added AT_ModifyPickTicket (FB-609)
  2016/01/04  SV      Added AT_LoadCreated, AT_OrderAddedToLoad, AT_OrdersRemovedFromLoad, AT_LoadCancelled, AT_LoadMarkedAsShipped,
                            AT_Load_UnderlyingBoLGenerated (CIMS-730)
  2015/12/11  VS      Added AT_PalletPick (FB-453)
  2015/12/08  TK      Changed Description for AT_LocationSetUpSuccessful (ACME-419)
  2015/12/05  SV      Added AT_SKUSeasonChanged (SRI-422)
  2015/11/05  OK      Added AT_ChangeLocationStorageType (NBD-36)
  2015/10/15  TK      Changes to AT_PutawayLPNToPicklane (ACME-367)
  2015/09/29  OK      Added AT_CreateReturns (FB-388).
  2015/09/21  AY      Added AT_LPNLabelled
  2015/09/18  SK      Added AT_UnpackingOrder(CIMS-584)
  2015/09/03  TK      Added AT_PutawayLPNAddedToPallet
  2015/08/11  OK      Added AT_ShipViaModify.
  2015/06/29  TK      Added AT_PseudoPicksCreated.
  2015/06/24  DK      Corrected descriptions for AT_AddSKUAndInventory, AT_RemoveSKUFromLocation and AT_AddSKU.
  2015/06/03  DK      Added AT_LPNAddedToCart.
  2015/06/03  SV      Updated AT_AddSKU description.
  2015/05/29  RV      Added AT_UnAssignedLPNsFromReceivers.
  2015/03/20  DK      Added AT_ExplodePrepack.
  2015/02/13  AK      Added AT_ModifyCartonType.
  2015/02/12  DK      Added AT_RemoveALLSKUsFromLocation.
  2014/12/02  SK      Added Audit messages for Receipt Details
  2014/12/01  SK      Added Audit messages for Receipt Headers
  2014/11/27  SK      Added Audit messages for UPC
  2014/11/27  PKS     Added AT_RFUserLogin
  2014/11/27  VM      Added Audit messages for SKU Prepack
  2014/11/12  DK      Added AT_LocationSetUpSuccessful.and AT_AddSKU
  2014/11/11  TK      Added AT_TaskUnassigned, AT_CancelTask, AT_CancelTaskDetail, AT_RemoveSKUFromLocation
  2014/10/29  DK      Corrected AT_AddSKUAndInventory and AT_RemoveSKUFromLocation message to show the units
  2014/10/20  NB      Added AT_SKUModified, AT_SKUDeleted
  2014/09/01  TK      Updated AT_PutawayLPNToLocation description.
  2014/07/24  TK      Updated AT_UpdateInvExpDate to AT_UpdateLPNInvExpDate.
  2014/07/23  PK      AT_PutawayLPNToPicklane: Changed the description to show the SKU and Units.
  2014/07/19  NY      Added AT_LPNWarehouseModified.
  2014/07/18  PKS     Added Reason Code in AT_LPNAdjustQty and AT_LocationAdjustQty
  2014/07/17  TD      Added LPNLoaded.
  2014/07/15  AK      Added AT_ActivateLocation and AT_DectivateLocation.
  2014/05/30  PV      Added audit comments for Replenishment.
  2014/05/19  PV      Modified AT_CCLocation, Added AT_CCLocation_U, AT_CCLocation_P, AT_CCLocation_A,
                        AT_CCLocation_L, AT_CCLocation_LA.
  2014/05/13  PV      Added AT_LocationSetUpSuccessful
  2014/05/13  YJ      Added GenerateLocation
  2014/04/28  PV      Added SKU keyword for Inventory transfer transactions.
  2014/04/25  DK      Added AT_ReceiverAssigned and AT_ReceiverUnAssign
  2014/04/21  YJ      Added some comments comparing with AuditTrail table.
  2014/04/19  PKS     Added AT_LocationCreated
  2014/04/05  DK      Added AT_CaptureTrackingNo.
  2014/04/18  DK      Added AT_ReceiverClosed, AT_UnAssignLPNs
  2014/04/17  DK      Added AT_AssignASNLPNs, AT_ReceiverCreated, AT_ReceiverModified.
  2014/03/24  AY      Enh. to show Inner packs in AT
  2014/01/23  NY      Added AT_CCLPNMovedAndAdjusted.
  2013/01/20  NY      Added AT_PickBatchRemoveOrderDetails.
  2013/12/16  TD      Changes to AT_OrderShortPicked to log Pallet and Batch too.
  2013/11/11  TD      Added AT_LPNAllocatedToOrderOnBatch.
  2013/12/12  PK      Added AT_PalletTransferred.
  2013/12/12  PK      Added AT_PalletTransferFull, AT_PalletTransferLPN, AT_PalletTransferUnits.
  2013/10/04  PK      Added AT_PickBatchAddOrderDetail.
                      AT_BatchUnitPick: Changed to show LPN/Location in the message.
  2103/09/11  NY      Added AT_CreateLocation,AT_UpdateLocation.
  2013/09/04  PK      Added AT_Receipts_ROClose, AT_Receipts_ROReopen.
  2013/08/05  TD      Added AT_SKUDimensionsModified.
  2012/12/14  PKS     Added AT_ODModified related messages
  2012/11/30  NY      Added AT_LocPutawayZoneModified ,AT_LocPickZoneModified.
  2012/11/27  YA      Added AT_PickBatchCancelled.
  2012/11/24  PKS     Added AT_OrderCanceled, AT_OrderDetailsModified.
  2012/11/09  NY      Added AT_OrderLineDeleted, AT_OrderLineModified.
  2012/10/20  NY      Added AT_LPNUnallocatedFromOrder.
  2012/10/14  AY      Added AT_PandAConfirmedNotVerified
  2012/10/09  PKS     Added AT_LPNReAllocatedToOrder.
  2012/09/12  YA      Modified 'AT_LPNAddedToPallet', %PalletLocation to %ToPalletLocation
              PK      Corrected AT_CCPalletFound message to show the Location
  2012/08/22  PK      Added CCPalletLocated, CCPalletFound, PalletShortPicked
  2012/08/20  NY      Added %LPN to Message AT_CCLPNMoved.
  2012/08/17  PK      Added AT_LPNAllocatedToOrder, AT_PalletAllocatedToBatch,
                      AT_PalletPickBatchComplete, AT_StartBatchPalletPick
  2012/08/10  YA      Added AT_LPNLost, AT_LPNShortPicked
  2012/08/02  YA      Added AT_LPNsGenerated.
  2012/08/01  PK      Added AT_CycleCounting, AT_CCLPNAddedSKU.
  2012/07/31  YA      Included AT_PalletsGenerated & AT_PalletsGeneratedWithLPNs
  2012/07/13  VM      AT_LPNSKUChanged: Modified to log it properly.
  2012/06/04  PK      Added AT_LPNOnPalletMoved.
  2012/05/28  YA      Included messages on Receiving and a message on Putaway.
  2012/05/17  YA      Included some message on Inventorymanagement(WIP).
  2012/04/19  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

/* Create temp table */
select MessageName, Description into #AuditComments from Messages where MessageName = '#';

insert into #AuditComments
            (MessageName,                              Description)
/*------------------------------------------------------------------------------*/
/* Basic field names */
/*------------------------------------------------------------------------------*/
      select 'AT_LPN',                                 'LPN'
union select 'AT_SKU',                                 'SKU'
union select 'AT_Pallet',                              'Pallet'
union select 'AT_Location',                            'Location'
union select 'AT_PickBatch',                           'Wave'
union select 'AT_PickBatches',                         'Waves'
union select 'AT_Order',                               'Order'
union select 'AT_Load',                                'Load'
union select 'AT_InventoryClass1',                     'Label Code'

/*------------------------------------------------------------------------------*/
/* Batch Picking */
/*------------------------------------------------------------------------------*/
union select 'AT_BatchUnitPick',                       'Picked %Units of %DisplaySKU from LPN/Location %LPNLocation into LPN %ToLPN for Order/Wave %PTBatch'
union select 'AT_StartBatchPick',                      'Started picking #PickBatch %PickBatch using Pallet %Pallet'
union select 'AT_PickBatchCreated',                    '%PickBatchType #PickBatch %PickBatch created'
union select 'AT_PickBatchAddOrder',                   '#Order %PickTicket added to #PickBatch %PickBatch'
union select 'AT_PickBatchOrdersAdded',                '%NumOrders #Order(s) added to #PickBatch %PickBatch'
union select 'AT_PickBatchOrderDetailsAdded',          '%NumOrders #OrderDetail(s) added to #PickBatch %PickBatch'
union select 'AT_PickBatchAddOrderDetail',             'Order %PickTicket, %DisplaySKU added to #PickBatch %PickBatch'
union select 'AT_WaveReleased',                        'Wave %Wave released for allocation'
union select 'AT_WaveReleaseForPicking',               '#PickBatch released for picking'
union select 'AT_DeferCancelWave',                     '%1 Wave is scheduled to be canceled'
union select 'AT_WaveCancelled',                       'Wave %WaveNo is canceled'
union select 'AT_BatchAssigned',                       '#PickBatch assigned to user %Note1'
union select 'AT_BatchUnAssigned',                     '#PickBatch unassigned from user'
union select 'AT_PickBatchCompleted',                  'Picking completed on #PickBatch %PickBatch'
union select 'AT_PickBatchShipped',                    '%NumOrders Order(s) on the #PickBatch %PickBatch have been shipped'
union select 'AT_PickPalletDropped',                   'Picking pallet %Pallet dropped at %Location'
union select 'AT_PickedLPNDropped',                    'Picked LPN %LPN dropped at %Location'
union select 'AT_OrderShortPicked',                    'Short Picked LPN (%Units of %DisplaySKU) for %PTBatch using Pallet %Pallet'
union select 'AT_PickBatchRemoveOrders',               '%NumOrders Orders removed from #PickBatch'
union select 'AT_PickBatchOrderRemoved',               'Order %PickTicket removed from #PickBatch %PickBatch'
union select 'AT_WaveConsolidated',                    'Bulk Order %PickTicket created for Wave %PickBatch'
union select 'AT_WaveModified',                        'Wave updated; %Note1'
union select 'AT_PauseBatchPick',                      'Paused Picking of #PickBatch %PickBatch using Pallet %Pallet'
union select 'AT_PickBatchRemoveOrderDetails',         'Line %OrderLine (%DisplaySKU, %Units Units) on Order %PickTicket removed from #PickBatch %PickBatch'
union select 'AT_LPNAddedToCart',                      'LPN %LPN added to position %ToLPN on Cart %ToPallet'
union select 'AT_LPNsOnPickPalletDropped',             'Picked LPN dropped at %Note1'
union select 'AT_LPNSubstitute',                       'Substituted LPN %ToLPN (Qty: %Note2) for LPN %LPN (Qty: %Note1) of SKU %SKU'
union select 'AT_LPNSubstitute_AddNewLine',            '%UnitsOfSKU added to LPN %LPN from substitution'

/*------------------------------------------------------------------------------*/
/* Batch Pallet Picking */
/*------------------------------------------------------------------------------*/
union select 'AT_StartBatchPalletPick',                'Started Pallet picking for #PickBatch %PickBatch'
union select 'AT_PalletAllocatedToBatch',              'Pallet %Pallet was allocated to #PickBatch %PickBatch'
union select 'AT_PalletPickBatchComplete',             'Pallet Picking completed on #PickBatch %PickBatch'
union select 'AT_PalletShortPicked',                   'Pallet was Short Picked on #PickBatch %PickBatch at %Location'
union select 'AT_PalletPick',                          'Pallet %Pallet (%NumLPNs, %Units) picked from Location %Location on #PickBatch %PickBatch'
union select 'AT_LPNUnallocatedFromOrder',             'LPN %LPN of %DisplaySKU with %Units was unallocated from Order %PickTicket'
union select 'AT_ClearedUserOnCart',                   'Cleared user on pallet/cart %Pallet'
union select 'AT_BuildCart',                           'Task %TaskId build to cart %Pallet'
union select 'AT_BuildCartAddLPN',                     'LPN added to cart %Note1 on build cart with Task %Note2'

/*------------------------------------------------------------------------------*/
/* Allocation */
/*------------------------------------------------------------------------------*/
union select 'AT_LPNLOCAllocatedForOrder',             '%Units units of SKU %DisplaySKU from LPN %LPN of Loc %Location has been allocated for Order %PickTicket'

/*------------------------------------------------------------------------------*/
/* Wave */
/*------------------------------------------------------------------------------*/
union select 'AT_PickBatchCancelled',                  '#PickBatch %PickBatch has been cancelled'
union select 'AT_PickBatch_Cancel',                    '#PickBatch %PickBatch canceled'
union select 'AT_ApproveToReleaseWave',                'Wave has been verified and approved for release'
union select 'AT_WaveAllocationCompleted',             'Wave allocation completed'
union select 'AT_WaveReAllocation',                    'Wave Reallocation initiated'
union select 'AT_PseudoPicksCreated',                  'Pick tasks are generated for #PickBatch %PickBatch'
union select 'AT_PickBatchModify',                     '#PickBatch %PickBatch has been modified'
union select 'AT_PickBatchPlanned',                    '#PickBatch %PickBatch has been planned'
union select 'AT_WaveOrdersAdded',                     '%Note1 Order(s) added to Wave %Wave'
union select 'AT_WaveOrderDetailsAdded',               '%Note1 Order Detail(s) added to Wave %Wave'
union select 'AT_WaveRemoveOrders',                    '%NumOrders Orders removed from Wave'
union select 'AT_WaveOrderRemoved',                    'Order %PickTicket removed from Wave %Wave'

/*------------------------------------------------------------------------------*/
/* LPN Picking */
/*------------------------------------------------------------------------------*/
union select 'AT_LPNPick',                             'Picked LPN %LPN (%Units of %DisplaySKU) from %Location for Order/Wave %PTBatch'
union select 'AT_PickTask_Cancel',                     'Pick Task %TaskId has been canceled successfully'
union select 'AT_TaskAssigned',                        'Pick Task has been assigned to user %1'
union select 'AT_TaskUnassigned',                      'Pick Task has been unassigned from user %1'
union select 'AT_CancelTask',                          'Pick Task %TaskId has been Cancelled'
union select 'AT_CancelTaskDetail',                    'Pick Task Detail has been Cancelled'
union select 'AT_TaskDetailCancel',                    '%Units of %DisplaySKU in LPN %LPN are unallocated from Order %PickTicket on %ToLPN'
union select 'AT_TaskDetail_Export',                   'Task Detail %1 scheduled for export via API'
union select 'AT_TaskDetailCancel_NoCartPosition',     '%Units of %DisplaySKU in LPN %LPN are unallocated from Order %PickTicket'
union select 'AT_PickTasksConfirm',                    'All picks for LPN %LPN are completed using Confirm Pick Tasks'

/*------------------------------------------------------------------------------*/
/* LPN Packed */
/*------------------------------------------------------------------------------*/
union select 'AT_LPNPackedAtShippingdoc',              'LPN %LPN Packed from Shipping Docs for the Order %PickTicket'

/*------------------------------------------------------------------------------*/
/* LPN Allocate/Unallocate/Reallocate */
/*------------------------------------------------------------------------------*/
union select 'AT_LPNAllocatedToOrder',                 'LPN %LPN of %DisplaySKU with %Units was allocated to Order %PickTicket'
union select 'AT_LPNReAllocatedToOrder',               'LPN %LPN of %DisplaySKU with %Units was reallocated from Order %PrevPickTicket to Order %PickTicket'
union select 'AT_UnallocateLPNDetail',                 '%Units of %DisplaySKU in LPN %LPN are unallocated from Order %PickTicket'
union select 'AT_LPNReservedForWave',                  'LPN %LPN of %DisplaySKU with %Units was allocated to Order %PickTicket'
union select 'AT_LPNUnReservedForWave',                'LPN %LPN of %DisplaySKU with %Units was unallocated to Order %PickTicket'
union select 'AT_CloseBPT_UnallocateLPNDetail',        '%Units of %DisplaySKU in LPN %LPN are unallocated from Order %PickTicket, since bulk order is closed'

/*------------------------------------------------------------------------------*/
/* LPN Allocate/Unallocate/Reallocate To a Wave */
/*------------------------------------------------------------------------------*/
union select 'AT_LPNAllocatedToOrderOnWave',           'LPN %LPN of %DisplaySKU with %Units allocated to Order %PickTicket on #PickBatch %PickBatch'
union select 'AT_UnitsAllocatedToOrderOnWave',         '%UnitsofSKU from LPN %LPN allocated to Order %PickTicket on #PickBatch %PickBatch'
union select 'AT_InvAllocatedForDirectedLine',         'DirectedLine of the LPN %LPN is allocated with %Units of %DisplaySKU for %Location Location'

/*------------------------------------------------------------------------------*/
/* Unit Picking */
/*------------------------------------------------------------------------------*/
union select 'AT_UnitPick',                            'Picked %Units of %DisplaySKU from Location %Location into LPN %ToLPN for Order/Wave %PTBatch'

/*------------------------------------------------------------------------------*/
/* SKU */
/*------------------------------------------------------------------------------*/
union select 'AT_SKU15',                               'Style %SKU1, Color %SKU2, Size %SKU3'
union select 'AT_PrevSKU15',                           'Style %PrevSKU1, Color %PrevSKU2, Size %PrevSKU3'
union select 'AT_UPCAddedToSKU',                       'UPC %Note1 added to %DisplaySKU'
union select 'AT_UPCRemovedFromSKU',                   'UPC %Note1 removed from %DisplaySKU'
union select 'AT_SKUSeasonChanged',                    'SKU Season changed from %Note1 to %Note2'
/*------------------------------------------------------------------------------*/
/* Putaway */
/*------------------------------------------------------------------------------*/
union select 'AT_PutawayLPNToLocation',                'LPN %LPN %OnPallet %FromLocation putaway to %ToLocation'
union select 'AT_PutawayLPNToPicklane',                '%UnitsOfSKU from LPN %LPN %OnPallet %FromLocation putaway into picklane %ToLocation'
union select 'AT_PutawayLPNToAlternatePicklane',       '%UnitsOfSKU from LPN %LPN %OnPallet %FromLocation putaway into picklane %ToLocation instead of %Note1'
union select 'AT_PutawayDRQtyToPicklane',              '%UnitsOfSKUof SKU is replenished to Location %ToLocation during putaway'
union select 'AT_PutawayLPNAddedToPallet',             'LPN %LPN (%UnitsOfSKU) %OnPallet putaway to %ToPalletLocation'
union select 'AT_PutawayLPNOnPallet',                  'LPN %LPN on Pallet %Pallet putaway to %ToLocation'
union select 'AT_PutawayPallet',                       'Pallet %Pallet (%NumLPNs, %Units) putaway to %Location'

/*------------------------------------------------------------------------------*/
/* Replenishment */
/*------------------------------------------------------------------------------*/
union select 'AT_GenerateReplenishOrder',              'Replenish Order created'
union select 'AT_ChangeOrderPriority',                 'Replenish Order Priority Changed'
union select 'AT_CancelReplenishOrder',                'Replenish Order Cancelled'
union select 'AT_CloseReplenishOrder',                 'Replenish Order Closed'
union select 'AT_Replenish_LPNAllocatedToOrderOnWave', 'LPN %LPN of %DisplaySKU with %Units allocated to replenish Location %Location to Replenish Order/#PickBatch %PickTicket/%PickBatch'
union select 'AT_Replenish_UnitsAllocatedToOrderOnWave',
                                                       '%UnitsofSKU from LPN %LPN allocated to replenish Location %Location for Replenish Order/#PickBatch %PickTicket/%PickBatch'

/*------------------------------------------------------------------------------*/
/* Replenish Order Picking and Putaway */
/*------------------------------------------------------------------------------*/
union select 'AT_ReplenishPA_ReleaseDirResvQty',       '%UnitsOfSKU released and reserved for %PickTicket at %Location'
union select 'AT_ReplenishPA_ReleaseDirQty',           '%UnitsOfSKU became available from replenishment at %Location'
union select 'AT_ReplenishPA_AddToOrderLine',          '%UnitsOfSKU released and added to existing line for %PickTicket at %Location'
union select 'AT_ReplenishPA_ReleasePartialDRQty',     '%UnitsOfSKU released and reserved for %PickTicket, more awaiting replenishment for %Location'
union select 'AT_ReplenishPA_AddToAvailableLine',      '%UnitsOfSKU added to available quantity at %Location'
union select 'AT_ReplenishPA_AddNewLine',              '%UnitsOfSKU added to %Location from replenishment'

/*------------------------------------------------------------------------------*/
/* Reservation */
/*------------------------------------------------------------------------------*/
union select 'AT_Reservation',                         'Reserved Units %Units of LPN %LPN against Wave %Wave'
union select 'AT_Activation',                          'Activated Units %Units of LPN %LPN against Wave %Wave'

/*------------------------------------------------------------------------------*/
/* Receiving */
/*------------------------------------------------------------------------------*/
union select 'AT_ReceiveToLocation',                   'Received %Units of %DisplaySKU into location %Location against RO %ReceiptNumber and Receiver %ReceiverNumber'
union select 'AT_ReceiveToLPN',                        'Received %Units of %DisplaySKU to LPN %LPN against RO/Receiver %ReceiptNumber/%ReceiverNumber'
union select 'AT_PalletizeLPN',                        'Received %Units of %DisplaySKU to LPN %LPN against RO/Receiver %ReceiptNumber/%ReceiverNumber onto Pallet %Pallet'
union select 'AT_Receipts_ROClose',                    'Receipt has been Closed'
union select 'AT_Receipts_ROReopen',                   'Receipt has been Reopened'

union select 'AT_CreateLPNToReceive_LPNs',             'Created LPN with %Units of %DisplaySKU against %ROType %ReceiptNumber'
union select 'AT_CreateLPNToReceive_LPNsPallets',      'Created LPN with %Units of %DisplaySKU on pallet %Pallet against %ROType %ReceiptNumber'
union select 'AT_CreateLPNs',                          'Created %NumLPNs with %Units of %DisplaySKU on each LPN'

union select 'AT_CreateLPNs_InvLPN',                   'Created LPN %Note1 with %Units units of %Note2'
union select 'AT_CreateLPNs_InvLPNs',                  'Created LPNs %Note1 each with %Units units of %Note2'
union select 'AT_CreateLPNs_Pallet',                   'Created %NumLPNs on %ToPallet Pallet with %Units of %DisplaySKU on each LPN'
union select 'AT_CreateLPNs_OrderLPNs',                'Created LPN with %Units of SKU %SKU for Order %PickTicket'

/*------------------------------------------------------------------------------*/
/* VAS */
/*------------------------------------------------------------------------------*/
union select 'AT_VAS_CompleteProduction',              'Production completed for LPN %LPN and moved to Location %Location'
union select 'AT_VAS_PrintEngravingLabels_LPNs',       'Engraving labels printed for LPN %LPN'
union select 'AT_VAS_PrintEngravingLabels',            'Engraving label printed for Order %PickTicket; LPN %LPN'
union select 'AT_VAS_RePrintEngravingLabels',          'Engraving label Reprinted for Order %PickTicket; LPN %LPN'
union select 'AT_VAS_InventoryAdjustment',             'Quantity reduced by %Units of %DisplaySKU against Order/LPN %Note2/%Note1'

/*------------------------------------------------------------------------------*/
/* Inventory Management */
/*------------------------------------------------------------------------------*/
union select 'AT_LPNUoM1',                             'LPN'
union select 'AT_LPNUoM2',                             'LPNs'
union select 'AT_IPUoM1',                              'Case'
union select 'AT_IPUoM2',                              'Cases'
union select 'AT_UnitUoM1',                            'Unit'
union select 'AT_UnitUoM2',                            'Units'
/* In the below, IPUoM will be replaced by IPUoM1 or IPUoM2 based upon whether it is single or multiple InnerPacks
   similarly for Units. Whereever we use %Units we would use the format of IPUnits if the transaction has both
   InnerPacks and Units else we use the format of UnitsOnly */
union select 'AT_IPUnits',                             '%InnerPacks %IPUoM (%Quantity %UnitUoM)'
union select 'AT_UnitsOnly',                           '%Quantity %UnitUoM'

/* Use one or the other below to show the SKU */
union select 'AT_DisplaySKU',                          '#SKU %SKU'
union select 'AT_PrevDisplaySKU',                      '#SKU %PrevSKU'

union select 'AT_AddSKUToLPN',                         '%Units of %DisplaySKU added to %LPN'
union select 'AT_ExplodePP_AddSKUToLPN',               '%Quantity of %SKU15 added to %LPN on prepack explosion'
union select 'AT_ExplodePrepackOnAllocation',          '%Quantity Prepacks of %SKU15 exploded in LPN %LPN during Allocation'
union select 'AT_AddSKUAndInventory',                  'Added %DisplaySKU to Location %Location with %Units'
union select 'AT_AddSKU',                              '%Units of %DisplaySKU added to Location %Location'
union select 'AT_RemoveSKUFromLocation',               'Removed %DisplaySKU from %Location'
union select 'AT_RemoveALLSKUsFromLocation',           'Removed all zero Quantity SKUs from %Location'
union select 'AT_ExplodePrepack',                      '%Units of %DisplaySKU exploded to %ToLPN from %LPN'
union select 'AT_LPNAdjustQty',                        'LPN %LPN quantity adjusted from %PrevUnits to %Units of %DisplaySKU. Reason: %ReasonCodeDesc'
union select 'AT_LocationAdjustQty',                   'Quantity of %DisplaySKU in Location %Location adjusted to %Units. Reason: %ReasonCodeDesc'
union select 'AT_CreateInvLPNOnPallet',                'Created LPN %LPN with %Units of %DisplaySKU on pallet %Pallet'
union select 'AT_CreateInvLPN',                        'Created LPN %LPN with %Units of %DisplaySKU. Reason: %ReasonCodeDesc'
union select 'AT_LPNGenerated',                        'LPN %LPN created'
union select 'AT_LPNsGenerated',                       'LPN created'
union select 'AT_LocationSetUpSuccessful',             'Replenish levels of Location %Location are updated to Min %MinQty %ReplenishUoM and Max %MaxQty %ReplenishUoM'
union select 'AT_TransferReservation',                 '%UnitsofSKU reserved for Order %PickTicket is transferred from Location %Location to Location %ToLocation'

-- LPN Modify
union select 'AT_ModifyLPNs',                          'LPN(s) modified; %Note1'
union select 'AT_LPNAddedToPallet',                    'LPN %LPN (%UnitsOfSKU) added to Pallet %ToPalletLocation'
union select 'AT_LPNPalletized_FromDiffPallet',        'LPN %LPN moved from Pallet %OldPallet on to Pallet %NewPallet'
union select 'AT_LPNPalletized',                       'LPN %LPN added onto Pallet %NewPallet'
union select 'AT_LPNDePalletized',                     'LPN %LPN removed from Pallet %Pallet'
union select 'AT_LPNTypeModified',                     'LPN Type modified to %Note1'
union select 'AT_LPNChangeOwnership',                  'LPN Ownership changed from %1 to %2'
union select 'AT_LPNWarehouseModified',                'Warehouse of %LPN changed from %Note1 to %Note2'
union select 'AT_LPNSKUChanged',                       'SKU changed to (New %1); (Previous %2)'
union select 'AT_LPNCreated',                          'Created LPN %LPN with %Units of %DisplaySKU and moved into Location %Location'
union select 'AT_LPNCartonDetailsModified',            'LPN Carton Type modified to %1 and weight to %2'
union select 'AT_LPNMovedToLocation',                  'LPN %LPN moved %FromLocation to %ToLocation'
union select 'AT_PalletMovedToLocation',               'Pallet %Pallet moved %FromLocation to %ToLocation'
union select 'AT_LPNContentsXferedToPicklane',         'LPN %LPN contents transfered to picklane %ToLocation'
union select 'AT_LPNMovedToPallet',                    'LPN %LPN moved from %PalletLocation to %ToPalletLocation'
union select 'AT_LPNShipped',                          'LPN shipped for Order %1, Load %2'
union select 'AT_LPNLoaded',                           'LPN %LPN Loaded for Order %PickTicket'
union select 'AT_LPNVoided',                           'LPN %LPN with %Units of %DisplaySKU voided. Reason: %ReasonCodeDesc, Reference: %Note1'
union select 'AT_LPNLost',                             'LPN %LPN lost at location %Location'
union select 'AT_LPNShortPicked',                      'LPN %LPN short picked at location %Location'
union select 'AT_LPNShortPickedWithAvailableQty',      'Short Picked LPN (Available %Units of %DisplaySKU)'
union select 'AT_UpdateLPNInvExpDate',                 'Expiry Date changed to %Note1'
union select 'AT_LPNLabelled',                         '%Note1 Label printed for LPN %LPN'

union select 'AT_InvTransferLPNToLPN',                 'Transferred %Units of %DisplaySKU from LPN %LPN to LPN %ToLPN. Reason: %ReasonCodeDesc'
union select 'AT_InvTransferLPNToLoc',                 'Transferred %Units of %DisplaySKU from LPN %LPN to Location %ToLocation. Reason: %ReasonCodeDesc'
union select 'AT_InvTransferLOCToLPN',                 'Transferred %Units of %DisplaySKU from Location %Location to LPN %ToLPN. Reason: %ReasonCodeDesc'
union select 'AT_InvTransferLOCToLoc',                 'Transferred %Units of %DisplaySKU from Location %Location to Location %ToLocation. Reason: %ReasonCodeDesc'

union select 'AT_PalletsGenerated',                    'Pallet generated'
union select 'AT_PalletsGeneratedWithLPNs',            'Pallet generated with %NumLPNs'
union select 'AT_PalletDropped',                       'Pallet %Pallet with %NumLPNs dropped at %Location'
union select 'AT_PalletMoved',                         'Pallet %Pallet (%NumLPNs, %Units) moved %FromLocation to %ToLocation'
union select 'AT_PalletsMerged',                       '%Note1 LPNs on Pallet %Pallet are moved to Pallet %ToPallet'
union select 'AT_LPNOnPalletMoved',                    'LPN %LPN on Pallet %Pallet moved to %Location'
union select 'AT_DropLPNOnBuildPallet',                'LPN %LPN on Pallet %Pallet dropped at Location %Location'


union select 'AT_PalletTransferFull',                  'Transferred %NumLPNs (%Units) from Pallet %Pallet to %ToPallet'
union select 'AT_PalletTransferLPN',                   'Transferred LPN %LPN with %UnitsOfSKU from Pallet %Pallet to %ToPallet'
union select 'AT_PalletTransferUnits',                 'Transferred LPN %LPN with %UnitsOfSKU from LPN/Pallet %LPN/%Pallet to %ToLPN/%ToPallet'
union select 'AT_FullPalletTransferEachLPN',           'Transferred LPN %LPN with %UnitsOfSKU from Pallet %Note1 to %Note2'
union select 'AT_CaptureTrackingNo',                   'LPN %LPN tracking number changed to  %TrackingNo'
union select 'AT_LPNQCHold',                           'Inventory was placed on QC hold and moved to %Note2 Warehouse'
union select 'AT_LPNQCRelease',                        'Inventory was released from QC hold and reverted to %Note2 Warehouse'

/*------------------------------------------------------------------------------*/
/* LPN Regenerate*/
/*------------------------------------------------------------------------------*/
union select 'AT_RegenerateTrackingNo',                'Tracking number regenerated'
/*------------------------------------------------------------------------------*/
/* UnWaving */
/*------------------------------------------------------------------------------*/
union select 'AT_OrdersUnWaved',                       'Order unwaved as SKU %SKU is short of inventory'
union select 'AT_UnWaveOrders_VoidTempLabel',          'LPNs on Order %1 voided as Order is removed from the Wave %2'

/*------------------------------------------------------------------------------*/
/* Location */
/*------------------------------------------------------------------------------*/
union select 'AT_CreateLocation',                                'Created Location %Location'
union select 'AT_UpdateLocation',                                'Updated Location %Location'
union select 'AT_LocPutawayZoneModified',                        'Putaway Zone of location changed to %1'
union select 'AT_LocPickZoneModified',                           'Pick Zone of location changed to %1'
union select 'AT_GenerateLocation',                              'Location created'
union select 'AT_ActivateLocation',                              'Location has been activated successfully'
union select 'AT_DeactivateLocation',                            'Location has been deactivated successfully'
union select 'AT_ModifyLocationType',                            'Location Type/Storage Type/Sub Type changed to: %1'
union select 'AT_ChangeLocationStorageType',                     'Location Type and Storage Type changed to %Note1 and %Note2 respectively'
union select 'AT_DeleteLocation',                                'Location deleted successfully'
union select 'AT_ChangeLocationCapacities',                      'Location capacities updated'
union select 'AT_ChangeLocClassWithCapacities',                  'Location class changed to %Note1 and capacities updated to defaults'
union select 'AT_ChangeLocationClassAndCapacities',              'Location class changed to %Note1 and capacities updated with user selected values'
union select 'AT_Loc_UpdateAllowedOperations',                   'Location operations changed to %1'
union select 'AT_Loc_ReleaseOnhold',                             'Location released for operations from onhold'
union select 'AT_ModifyLocationAtrributes',                      'Allow multiple SKUs changed to %1 on the Location'

/*------------------------------------------------------------------------------*/
/* SKU */
/*------------------------------------------------------------------------------*/
union select 'AT_SKUDimensionsModified',               'SKU %SKU Dimensions have been changed'
union select 'AT_SKUModified',                         'SKU %SKU modified'
union select 'AT_SKUDeleted',                          'SKU %SKU deactivated'
union select 'AT_SKUCommercialInfoModified',           'Commercial Info modified from (Previous %2) to (New %1)'

/*------------------------------------------------------------------------------*/
/* UPC */
/*------------------------------------------------------------------------------*/
union select 'AT_UPCModified',                         'UPC %UPC modified'
union select 'AT_UPCDeleted',                          'UPC %UPC deactivated'

/*------------------------------------------------------------------------------*/
/* SKU Prepack */
/*------------------------------------------------------------------------------*/
union select 'AT_SKUPrePackModified',                  'Master SKU - Component SKU %MSKU-CSKU modified'
union select 'AT_SKUPrePackDeleted',                   'Master SKU - Component SKU %MSKU-CSKU deactivated'

/*------------------------------------------------------------------------------*/
/* ReceiptHeader */
/*------------------------------------------------------------------------------*/
union select 'AT_ReceiptHeaderModified',               'Receipt Header %Receipt modified'
union select 'AT_ReceiptHeaderDeleted',                'Receipt Header %Receipt deleted'
union select 'AT_ReceiptHeaderClosed',                 'Receipt Header %Receipt Closed'
union select 'AT_ReceiptHeaderReopened',               'Receipt Header %Receipt ReOpened'
union select 'AT_ReceiptHeaderCancelled',              'Receipt Header %Receipt cancelled'
union select 'AT_ReceiptOwnerModified',                'Owner of %ReceiptNumber changed from %Note1 to %Note2'
union select 'AT_Receipt_WarehouseChanged',            'Warehouse of %1 changed from %2 to %3'
union select 'AT_Receipts_ChangeArrivalinfo',          'Arrival Info on Receipt modified; %Note1'

/*------------------------------------------------------------------------------*/
/* ReceiptDetail */
/*------------------------------------------------------------------------------*/
union select 'AT_ReceiptDetailModified',               'Receipt Detail %RD modified'
union select 'AT_ReceiptDetailDeleted',                'Receipt Detail %RD deleted'
union select 'AT_ReceiptDetailCancelled',              'Receipt Detail %RD cancelled'

/*------------------------------------------------------------------------------*/
/* PandA */
/*------------------------------------------------------------------------------*/
union select 'AT_PandAInducted_Intransit',             'LPN %LPN inducted on PandA and marked as Received'
union select 'AT_PandAInducted_Other',                 'LPN %LPN inducted into PandA'
union select 'AT_PandAConfirmed',                      'Confirmed by PandA'
union select 'AT_PandAConfirmedNotVerified',           'Confirmed by PandA however, Label was not verified as printed properly'

/*------------------------------------------------------------------------------*/
/* CrossDock */
/*------------------------------------------------------------------------------*/
union select 'AT_CrossDockLPN',                        'LPN %LPN of %ROType %ReceiptNumber cross docked for Order %PickTicket'

/*------------------------------------------------------------------------------*/
/* Cycle Counting */
/*------------------------------------------------------------------------------*/
union select 'AT_CCLocation_U',                        'Location %Location was cycle counted with %UnitsOfSKU'
union select 'AT_CCLocation_P',                        'Location %Location was cycle counted with %UnitsOfSKU'
union select 'AT_CCLocation_L',                        'Location %Location was cycle counted with %UnitsOfSKU in %NumLPNs'
union select 'AT_CCLocation_A',                        'Location %Location was cycle counted with %UnitsOfSKU in %NumLPNs on %NumPallets Pallet(s)'
union select 'AT_CCLocation_LA',                       'Location %Location was cycle counted with %UnitsOfSKU in %NumLPNs on %NumPallets Pallet(s)'
union select 'AT_CCLocationConfirmedEmpty',            'Location %Location was cycle counted and confirmed to be empty'
union select 'AT_CCLocationEmpty',                     'Location %Location was cycle counted as empty and contents marked as lost'

union select 'AT_CCLPNMoved',                          'LPN %LPN moved %FromLocation to %ToLocation during cycle count'
union select 'AT_CCLPNLost',                           'LPN %LPN Lost %OnPallet at %Location during cycle count'
union select 'AT_CCLPNFound',                          'LPN %LPN found %OnPallet at %Location during cycle count'
union select 'AT_CCLPNAdjusted',                       'LPN %LPN quantity adjusted to %Units of %DisplaySKU at %Location during cycle count'
union select 'AT_CCLPNAddedSKU',                       '%Units of %DisplaySKU was added to LPN %LPN during cycle counting'
union select 'AT_CCLPNPalletChanged',                  'LPN %LPN moved %FromPallet to %Pallet at %Location during cycle count'
union select 'AT_CCLPN',                               'LPN %LPN cycle counted at %Location with %Units of %DisplaySKU'

union select 'AT_CCPalletScanOnly',                    '#Pallet %Pallet confirmed at Location %Location during cycle count'
union select 'AT_CCPalletLocated',                     '#Pallet %Pallet located at %Location during cycle count'
union select 'AT_CCPalletFound',                       '#Pallet %Pallet found at %ToLocation during cycle count'
union select 'AT_CCPalletMoved',                       '#Pallet %Pallet moved %FromLocation to %ToLocation during cycle count'
union select 'AT_CCPalletLost',                        '#Pallet %Pallet lost at %Location during cycle count'
union select 'AT_CCPallet',                            '#Pallet %Pallet was cycle counted at %Location with %Units, %NumLPNs'
union select 'AT_CCLPNMovedAndAdjusted',               'LPN %LPN moved %FromLocation to %ToLocation and quantity adjusted to %Units of %DisplaySKU during cycle count'

/*------------------------------------------------------------------------------*/
/* Orders Processing */
/*------------------------------------------------------------------------------*/
union select 'AT_OrderCompleted',                         '%OrderType Order %PickTicket has been completed'
union select 'AT_OrderLineDeleted',                       'Order Line %OrderLine with %DisplaySKU deleted from Order %PickTicket'
union select 'AT_OrderLineModified',                      'Order Line %OrderLine with %DisplaySKU modified in Order %PickTicket'
union select 'AT_OrderCanceled',                          'Order %PickTicket has been canceled; Reason: %ReasonCodeDesc'
union select 'AT_OrderShipped',                           'Order shipped'

union select 'AT_ODModified_UnitsToShip',                 'Units to ship on Order %PickTicket, %DisplaySKU has been changed from %PrevUnitsToShip to %NewUnitsToShip'
union select 'AT_ODModified_UnitsOrdered',                'Units ordered on Order %PickTicket, %DisplaySKU has been changed from %PrevUnitsOrdered to %NewUnitsOrdered'
union select 'AT_ODModified_UnitsOrderedAndToShip',       'Units to ship and Units ordered on Order %PickTicket, %DisplaySKU has been changed from %PrevUnitsToShip to %NewUnitsToShip and from %PrevUnitsOrdered to %NewUnitsOrdered respectively'
union select 'AT_ODModifyOrderDetails',                   'Order %1, %2 details modified %3'
union select 'AT_ODModifyPackCombination',                'Pack info update on Order Detail (Line %2), SKU %3 - %1'
union select 'AT_ODModified_PTcancel',                    'Canceled %UnitsOfSKU from Order %PickTicket'
union select 'AT_ODModifyReworkInfo',                     'Order Detail for SKU %1 (Order Line %3) updated - %2'

union select 'AT_OrderHeadersModified',                   'PickTicket %PickTicket modified during import process'
union select 'AT_OrderHeadersDeleted',                    'PickTicket %PickTicket deleted during import process'
union select 'AT_ShipViaModify',                          'Ship Via changed from %Note1 to %Note2'
union select 'AT_ShipViaModifyMultiple',                  'Ship Via changed to %Note2'
union select 'AT_OrderShipDetailsModify',                 'Ship Detail(s) modified %1'
union select 'AT_ModifyPickTicket',                       'Order modified %1 %2'
union select 'AT_OrderDisqualified_PartiallyAllocated',   'Order is disqualified: Only %2 units of SKU %1 are allocated while %3 units are required'
union select 'AT_SoftAllocation_Qualified',               'Order qualified by Soft Allocation'
union select 'AT_OrderUnWaved',                           'Order %PickTicket removed from Wave %Wave'
union select 'AT_OrderDetailUnWaved',                     'Line %HostOrderLine of SKU %SKU on Order %PickTicket removed from Wave %Wave'
union select 'AT_PreprocessOrder',                        'Order is scheduled for pre-process'

union select 'AT_AddNote',                                'Notes added for Pick Ticket'
union select 'AT_ReplaceNote',                            'Notes updated for Pick Ticket'
union select 'AT_DeleteNote',                             'Notes deleted for Pick Ticket'

union select 'AT_ReworkTransfer_FromLPN',                 'Inventory %Quantity units of SKU %SKU transferred Picklane %ToLPN to rework order %PickTicket'
union select 'AT_ReworkTransfer_ToLPN',                   'Inventory %Quantity units of SKU %SKU transferred from Picklane %FromLPN to rework order %PickTicket'
union select 'AT_ReworkTransfer_PickTicket',              'Inventory %Quantity units of SKU %SKU transferred from Picklane %FromLPN to Picklane %ToLPN'

union select 'AT_CreateInventory_FromLPN',                '%Quantity units of SKU %SKU transferred to %ToLPN'
union select 'AT_CreateInventory_ToLPN',                  '%Quantity units of SKU %SKU transferred from %FromLPN'

union select 'AT_ReworkComplete_FromLPN',                 '%Quantity units of SKU %SKU reworked for %PickTicket & transferred to Picklane %ToLPN'
union select 'AT_ReworkComplete_ToLPN',                   '%Quantity units of SKU %SKU reworked for %PickTicket & transferred from Picklane %FromLPN'
union select 'AT_ReworkComplete_PickTicket',              '%Quantity units of SKU %SKU reworked & transferred from Picklane %FromLPN to Picklane %ToLPN'

union select 'AT_ReworkCompleteSKUChange_FromLPN',        '%Quantity units of SKU %SKU reworked to make up new SKU %NewSKU for %PickTicket & transferred to Picklane %ToLPN'
union select 'AT_ReworkCompleteSKUChange_ToLPN',          '%Quantity units of SKU %SKU reworked to make up new SKU %NewSKU for %PickTicket & transferred from Picklane %FromLPN'
union select 'AT_ReworkCompleteSKUChange_PickTicket',     '%Quantity units of SKU %SKU reworked to make up new SKU %NewSKU & transferred from Picklane %FromLPN to Picklane %ToLPN'

union select 'AT_ReworkCompleteICChange_FromLPN',         '%Quantity units of SKU %SKU reworked for new Label Code %NewInventoryClass1 for %PickTicket & transferred to Picklane %ToLPN'
union select 'AT_ReworkCompleteICChange_ToLPN',           '%Quantity units of SKU %SKU reworked for new Label Code %NewInventoryClass1 for %PickTicket & transferred from Picklane %FromLPN'
union select 'AT_ReworkCompleteICChange_PickTicket',      '%Quantity units of SKU %SKU reworked for new Label Code %NewInventoryClass1 & transferred from Picklane %FromLPN to Picklane %ToLPN'

union select 'AT_ReworkCompleteSKU&ICChange_FromLPN',     '%Quantity units of SKU %SKU reworked to make up new SKU %NewSKU with Label Code %NewInventoryClass1 for %PickTicket & transferred to Picklane %ToLPN'
union select 'AT_ReworkCompleteSKU&ICChange_ToLPN',       '%Quantity units of SKU %SKU reworked to make up new SKU %NewSKU with Label Code %NewInventoryClass1 for %PickTicket & transferred from Picklane %FromLPN'
union select 'AT_ReworkCompleteSKU&ICChange_PickTicket',  '%Quantity units of SKU %SKU reworked to make up new SKU %NewSKU with Label Code %NewInventoryClass1 & transferred from Picklane %FromLPN to Picklane %ToLPN'

union select 'AT_ReworkOrder_CloseLPN',                   'LPN with %1 units reworked. SKU changed from %2 to %3. #InventoryClass1 code changed from %4 to %5'
union select 'AT_ReworkOrder_CloseLPN_PickTicket',        '%1 units on Order reworked. SKU changed from %2 to %3. #InventoryClass1 changed from %4 to %5'
union select 'AT_OrderAddedToNewLoad',                    'Order %1 added to Load %2'
union select 'AT_OrderAddedToNewLoadFromDiffLoad',        'Order %1 removed from Load %3 & added to new Load %2'

/*------------------------------------------------------------------------------*/
/* Notes */
/*------------------------------------------------------------------------------*/
union select 'AT_NoteModified',                        'Notes %Note modified during import process'
union select 'AT_NoteDeleted',                         'Note %Note deleted during import process'

/*------------------------------------------------------------------------------*/
/* Packing */
/*------------------------------------------------------------------------------*/
union select 'AT_PackingStartBatch',                   'Packing started for batch %PickBatch from pallet %Pallet'
union select 'AT_PackingPauseBatch',                   'Paused packing batch %PickBatch from pallet %Pallet'
union select 'AT_Packing_PackLPN.SingleSKU',           'Packed %Units of %DisplaySKU from %LPN into %ToLPN for Order %PickTicket/%PickBatch'
union select 'AT_Packing_PackLPN.MultipleSKUs',        'Packed %Units from %LPN into %ToLPN for Order %PickTicket/%PickBatch'
union select 'AT_PackingCloseLPN',                     'Closed %LPN for Order %PickTicket'
union select 'AT_PackingPackLPN',                      'Paused %LPN for Order %PickTicket'
union select 'AT_PackingReopenLPN',                    'Re-opened %LPN for Order %PickTicket'
union select 'AT_ModifyCartonType',                    'CartonType and Weight of %LPN for Order %PickTicket has been modified from (%Note1) to (%Note2)'
union select 'AT_UnpackingOrder',                      'LPN %LPN of Order %PickTicket unpacked to Cart %ToPallet'

/*------------------------------------------------------------------------------*/
/* Receiver: */
/*------------------------------------------------------------------------------*/
union select 'AT_ASNLPNsAssigned',                     'LPN is assigned to Receiver %Note1'
union select 'AT_ASNReceiptLPNsAssigned',              'Some of the LPNs are assigned to Receiver %Note1'
union select 'AT_ASNReceiptLPNsUnassigned',            'Some of the LPNs are unassigned from Receiver %Note1'
union select 'AT_ReceiverCreated',                     'Receiver created'
union select 'AT_ReceiverModified',                    'Modified %Note1'
union select 'AT_ReceiverAssigned',                    'Assigned %Note1 LPNs to Receiver %ReceiverNumber successfully'

union select 'AT_ReceiverUnAssigned',                  'Unassigned %Note1 LPNs from Receiver %ReceiverNumber successfully'
union select 'AT_UnAssignedLPNsFromReceivers',         'LPN unassigned from Receiver %Note1'

union select 'AT_ReceiverClosed',                      'Receiver closed'
union select 'AT_RDModified_QtyOrdered',               'Units ordered on Receipt %ReceiptNumber, %DisplaySKU has been changed from %PrevUnitsOrdered to %NewUnitsOrdered'

/*------------------------------------------------------------------------------*/
/* Returns: */
/*------------------------------------------------------------------------------*/
union select 'AT_CreateReturns',                       'LPN %LPN created for return %ReceiptNumber against Order %PickTicket'
union select 'AT_CreateRMA',                           'RMA %ReceiptNumber created for the Returns'
union select 'AT_RMAReceived',                         '%Quantity units received against RMA %ReceiptNumbers'

/*------------------------------------------------------------------------------*/
/* DCMS */
/*------------------------------------------------------------------------------*/
union select 'AT_LPNShipDivert',                       'LPN %LPN diverted to shipping lane %Note1 and Loaded onto truck'

/*------------------------------------------------------------------------------*/
/* Loads */
/*------------------------------------------------------------------------------*/
union select 'AT_LoadCreated',                         'Load %LoadNumber created'
union select 'AT_LoadGenerated',                       'Load %2 generated'
union select 'AT_OrderAddedToLoad',                    'Order %PickTicket is added to Load %LoadNumber'
union select 'AT_OrderRemovedFromLoad',                'Order %1 removed from Load %2'
union select 'AT_LoadModified',                        'Load %1 Modified; %2'
union select 'AT_LoadCancelled',                       'Load %LoadNumber has been cancelled'
union select 'AT_LoadMarkAsShipped',                   'Load %LoadNumber has been shipped'
union select 'AT_Load_MasterBoLGenerated',             'Master BoL %Note1/%Note2 generated for Load %LoadNumber'
union select 'AT_Load_UnderlyingBoLGenerated',         'BoL %Note1/%Note2 generated for Load %LoadNumber'
union select 'AT_LPNAddedToLoad',                      'LPN %LPN added to Load %LoadNumber'
union select 'AT_LPNRemovedFromLoad',                  'LPN %LPN removed from Load %LoadNumber'
union select 'AT_Loads_ModifyApptDetails',             'Load(s) appointment details modified %Note1'
union select 'AT_Loads_ModifyBoLInfo',                 'Load(s) BoL info modified %Note1'
union select 'AT_Load_ActivateShipCartonsRequest',     'Load %LoadNumber Ship cartons activation process request initiated'
union select 'AT_Load_ActivateShipCartonsDone',        'For Load %LoadNumber: %Note1 out of %Note2 Ship cartons activated successfully'

/*------------------------------------------------------------------------------*/
/* Shipping */
/*------------------------------------------------------------------------------*/
union select 'AT_ShipmentShipped',                     'Shipped %NumLPNs against Load %LoadNumber'
union select 'AT_RFLPNLoad',                           'LPN %LPN loaded for Order %PickTicket successfully onto the truck from dock %Note1'
union select 'AT_ScanLoadLPN',                         'LPN %1 loaded for Order/Load %3/%4 onto the truck from dock %5'
union select 'AT_ScanLoadPallet',                      'Pallet %1 with %2 LPNs loaded for Load %4 onto the truck from dock %5'
union select 'AT_CancelShipLabel',                     'ShipLabel for LPN %LPN Cancelled Successfully, Unallocated Units %Units from PickTicket %PickTicket and Reserved against Bulk Order %BulkOrder, Wave %Wave'

/*------------------------------------------------------------------------------*/
/* Imports - ASNLPNs Receiving */
/*------------------------------------------------------------------------------*/
union select 'AT_ASNLPNLineInserted',                  'Imported %UnitsOfSKU to LPN %LPN %OnROTypeAndNumber'
union select 'AT_ASNLPNLineModified',                  'Updated LPN %LPN on import with %UnitsOfSKU %OnROTypeAndNumber'
union select 'AT_ASNLPNLineDeleted',                   'Deleted %UnitsOfSKU to LPN %LPN on %OnROTypeAndNumber'

/*------------------------------------------------------------------------------*/
/* Users */
/*------------------------------------------------------------------------------*/
union select 'AT_RFUserLogin',                         '%UserId logged in with device %DeviceId at %Warehouse'
union select 'AT_RFUserLogout',                        '%UserId logged out on device %DeviceId at %Warehouse '

Go

/*------------------------------------------------------------------------------*/
/* Delete any existing audit comments */
delete from Messages where MessageName like 'AT_%';

/* Add the new messages */
insert into Messages (MessageName, Description, NotifyType, Status, BusinessUnit)
select MessageName, Description, 'I' /* Info */, 'A' /* Active */, (select Top 1 BusinessUnit from vwBusinessUnits order by SortSeq)
from #AuditComments;

/*------------------------------------------------------------------------------*/
/* Replace the captions for fields like SKU, LPN, Pallet, PickBatch, PickTicket
   Note this has to be done after messages are inserted above as fn_Messages_GetDescription
   gets from Messages table and not from # table */
update Messages
set Description = replace(Description, '#SKU', dbo.fn_Messages_GetDescription('AT_SKU'));

update Messages
set Description = replace(Description, '#PickBatches', dbo.fn_Messages_GetDescription('AT_PickBatches'));

update Messages
set Description = replace(Description, '#PickBatch', dbo.fn_Messages_GetDescription('AT_PickBatch'));

update Messages
set Description = replace(Description, '#LPN', dbo.fn_Messages_GetDescription('AT_LPN'));

update Messages
set Description = replace(Description, '#Pallet', dbo.fn_Messages_GetDescription('AT_Pallet'));

update Messages
set Description = replace(Description, '#Location', dbo.fn_Messages_GetDescription('AT_Location'));

update Messages
set Description = replace(Description, '#Order', dbo.fn_Messages_GetDescription('AT_Order'));

Go
