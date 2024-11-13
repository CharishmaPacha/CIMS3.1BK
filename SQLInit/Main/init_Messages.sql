/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/09/11  RIA     Added BuildInv_InvalidLocation, BuildInv_InvalidExternalLPN (CIMSV3-3034)
  2023/03/27  LAC     Added Waves_PreprocessOrders_* & Orders_Reprocess_InvalidOrderStatus (BK-1036)
  2023/03/22  TD      Added ReleaseForAllocation_WaveNotApprovedYet (BK-1033)
  2023/03/22  PKK     Added Waves_ApproveToRelease_* (BK-1033)
  2022/08/11  PKK     Added Tasks_ComfirmPicks_* (BK-864)
  2022/08/05  SAK     Added Tasks_ConfirmPicks_Successful, NoneUpdated, SomeUpdated (BK-864)
  2022/06/03  RKC     Added Substitution_InvalidPickMode, Substitute_TaskSubTypeMismatch (BK-819)
  2022/04/11  GAG     Added message descriptions for SKU_ModifyCommercialInfo_* (BK-797)
  2022/03/24  OK      PackingSuccessful: Included PickTicket in message (FBV3-1075)
  2022/03/03  RT      Added Order_AddressValidation_Invalid (CID-1904)
  2022/02/02  RKC     Added CreateLPNs_HasMixedUoMSKUs and IP/Units required messages (BK-218)
  2021/10/19  RT      Added Picking_ConsoldiateOrder_CannotPickPartialUnits and Picking_ConsolidatePick_CannotShortPick (BK-643)
  2021/10/01  NB      Added PasswordPolicyIsRequired(CIMSV3-1635)
  2021/09/20  NB      Added UserPasswordPolicyNotDefined(CIMSV3-1548)
  2021/08/26  TK      Added Pallet_ClearCart_CartPositionsHasPickedInventory (BK-532)
  2021/08/25  VS      Added CancelWave_UnallocateUnitsFirst (HA-3099)
  2021/08/13  OK      Added WaveRelease_MissingShipFromContact, WaveRelease_MissingWarehouseContact,
                            OrderPreprocess_MissingShipFromContact, OrderPreprocess_MissingWarehouseContact (BK-487)
  2021/08/09  SK      Added UserRunInputStringEmpty & UserRunNoRecordFound (HA-3043)
  2021/07/27  RV      Added OrderHeader_ConvertToSetSKUs_* (OB2-1948)
  2021/07/21  PKD     LPN_ModifyOwnership_*:changed to LPNs_ChangeOwnership* & Modified description for LPNs_ChangeOwnership_SameOwner (OB2-1954)
  2021/07/20  VS      Added PickTask_TaskCancel_Deferred, PickTask_CancelTask_AlreadyCanceledorCompleted, PickTask_CancelTask_CancelInProgress (CIMSV3-1387)
  2021/07/14  OK      Added OrderHeader_Contacts_Edit_Successful messages (HA-2309)

  2021/07/02  SAK     Added Wave_AddOrders * (CIMSV3-1516)
  2021/06/30  VS      Added Receiver_Close_AlreadyClosed (HA-2941)
  2021/06/30  OK      Added WaveRelease_OrderDetailsWithInvalidPrepackRatio (HA-2934)

  2021/06/29  SAK     Added new messages for User actions (CIMSV3-1526)
  2021/06/29  SJ      Added Loads_CreateLoad_Successful (CIMSV3-1514)
  2021/06/22  SV      Added Load_ManageLoads_CreateLoad_Successful (CIMSV3-1517)
  2021/06/18  VM      Added OD_ModifyDetails_* (CIMSV3-1515)
  2021/06/16  VS      Added Load_Modify_InvalidStatus (HA-2884)
  2021/06/15  AJM     Added Waves_Reallocate_InvalidWaveStatus, Waves_Reallocate_AllocationInprogress (CIMSV3-1474)
  2021/06/15  AY      Setup messages such that # values are replaced (OB2-1865)
  2021/06/15  SJ      Modified Loads_GenerateBoLs related messages (CIMSV3-1513)
  2021/06/11  KBB     Added Loads_Modify_* Messages (CIMSV3-1501)
  2021/06/11  PKK     Added Messages Order_CancelPickTicket_* (CIMSV3-1487)
  2021/06/09  VM      Added Order_ModifyShipDetails_* => OrderHeader_ModifyShipDetails_* (OB2-1887)
  2021/06/08  PKK     Modified message name from Order_ClosePickTicket_* to OrderHeader_ClosePickTicket_*
                      and Order_CancelPickTicket_* to OrderHeader_CancelPickTicket_* (CIMSV3-1487)
  2021/06/08  NB      Added ClosePackage_ShipmentDataError(CIMSV3-156)
  2021/06/04  NB      Added ClosePackage_ShipmentRequestFailed(CIMSV3-156)
  2021/06/02  VS      Added MoveLPNs_LogicalLPNsCannotBeMoved (HA-2844)
  2021/05/25  SK      Added Loads_ActivateShipCartons_% and Load_ActivateShipCartons_% messages (HA-2808)
  2021/05/13  SV      Added Returns_InvalidReceiptStatus, Returns_ScannedSKUIsNotAssociatedWithReceipt (OB2-1794)
  2021/05/12  AJM     Changed messagename from PicklaneLPNs_RemoveZeroQtySKUs_* to PicklaneLPNs_LPNs_RemoveZeroQtySKUs_*
                      & Added messages Location_RemoveSKUs_InvalidLPNType, Location_RemoveSKUs_NonZeroQTYSKUs (CIMSV3-1394)
  2021/05/12  SV      Added Returns_ReceivedSuccessfully (OB2-1794)
  2021/05/10  AJM     Added messages Waves_Modify_SamePriority, Waves_Modify_InvalidStatus (CIMSV3-1462)
  2021/05/06  SAK     Added PrintJob_AlreadyReleased and PrintJob_OnHold (BK-269)
  2021/05/05  TK      Added Wave_RemoveOrders_AllocationInProgress (HA-2746)
  2021/04/29  AJM     Modified messagenames LPN_ModifyLPNType_* to LPNs_ModifyLPNType_* & added LPNs_ModifyLPNType_SameLPNType (CIMSV3-1450)
  2021/04/28  AJM     Modified messagenames Location_ChangeLocationProfile_* to Locations_ChangeProfile_* (CIMSV3-1436)
  2021/04/22  SJ      Added LoadShip_TrailerNumberIsRequired the Load (HA-2618)
  2021/04/21  TK      Added Loads_AddOrders_MultiShipmentOrder (HA-2641)
  2021/04/16  OK      Added LoadShip_PalletNotLoaded, LoadShip_LPNNotLoaded (HA-2418)
  2021/04/15  AJM     Modified messagenames Location_ModifyLocationAttributes_* to Location_ModifyAttributes_* (CIMSV3-1428)
  2021/04/14  TK      Added WaveRelease_CannotHaveTransferOrders & WaveRelease_CannotHaveReworkOrders (HA-2626)
  2021/04/12  AJM     Added new message Contacts_Add_Successful (HA-2583)
  2021/04/08  KBB     Added CreateTransferLoad_InvalidShipToId, CreateTransferLoad_ShipFromShipToCannotBeSame (HA-2551)
  2021/04/03  TK      Added LoadShip_NoLPNsOnShipment (HA-1842)
  2021/04/02  TK      Added WaveRelease_OrdersWithMultipleLabelCodes (HA-2527)
  2021/03/30  SAK     Added LPNActivation_AlreadyActivated (HA-2356)
  2021/03/26  SAK     Corrected the message name LPNPA_LPNStatusIsInvalid (HA-2435)
  2021/03/25  RV      Added MovePallet_ResvLPNsInvalidLocationType (HA Golive)
  2021/03/21  RKC/AY  Revised Wave_RemoveOrders messages (HA-2368)
  2021/03/19  SJ      Corrected message LoadShip_ShortShippingOrder to give more detailed error (HA-2325)
  2021/03/18  OK      Added messages for Contacts Edit (HA-2317)
  2021/03/17  RKC     Changed the message name for ShipLabel_InsertedPickTicket, ShipLabel_VoidedPickTicket (HA-2301)
  2021/03/16  PHK     LPNs_ActivateShipCartons_SomeUpdated: Corrected the message name (HA-2294)
  2021/03/15  SV      Added messages for Returns with 'CreatedRMA_%' (OB2-1358)
  2021/03/11  TK      Added LPNAdjust_CannotAdjustOverShipQty (HA-2175)
                      Added LPNResv_ReserveAgainstBulkOrder (HA-2133)
  2021/03/10  TK      Added LocationAddSKU_SameSKUWithDiffInvClass (HA-2236)
  2021/03/06  SAK     Corrected the message for Ship Cartons Cancel Action (HA-2161)
  2021/03/06  OK      Changed the message RFLoad_InvalidLPNStatus description to more informative (HA-2129)
  2021/02/26  PK      Added LPNs_CancelShipCartons_* and LPNInActivation_* (HA-2087)
  2021/02/23  VS      Added SKU and Style/Color/Size in validation OrderEstimatedCartons_InvalidUnitVolume message (HA-2013)
  2021/02/18  PHK     Added RFLoad_BulkOrderCannotBeLoaded (HA-1941)
  2021/02/13  TK      Added TransferInv_CannotTransferReservedQty
                            LocationAdjust_CannotAdjustReservedQty
                            LPNAdjust_CannotAdjustReservedQty (CID-1724)
  2021/02/04  VS      Added ShipLabel_VoidedLPNs (BK-126)
  2021/02/04  TK      Added OrderEstimatedCartons_InvalidUnitVolume & OrderEstimatedCartons_InvalidUnitsPerCarton (HA-1964)
  2021/01/30  RKC     Added Location_ModifyLocationType_*,
                        Locations_ChangeLocationStorageType_*: Reverted back to original messages (CIMSV3-1181)
  2021/01/27  AJM     Added Layouts_SelectionAddedSuccessfully (HA-1943)
  2021/01/11  SK      Added LoadRequestRouting% related messages (HA-1896)
  2021/01/11  AJM     Added BoL_CanOnlyChangeShiptoOnMasterBoL (HA-1858)
  2021/01/06  AJM     Added and revised messages for OrderHeader ModifyPickTicket (CIMSV3-1296)
  2020/12/30  MS      Added LPN_ModifyLPNs_LPNIsReserved (HA-1807)
  2020/12/26  AY      Added PALPNsOnPallet_PalletStatusInvalid (CIMSV3-727)
  2020/12/17  YJ      Added messages for Lookups Add/Edit (CIMSV3-1222)
  2020/12/16  SK      Added LPNActv_ShipCartons_WarehouseMismatch (HA-1734)
  2020/12/16  SJ      Added Printers ResetStatus related messages (HA-1767)
  2020/12/15  KBB     Added CCtasks Assign to user related messages (HA-1792)
  2020/12/11  RKC     Added Load_LoginWarehouseMismatch, UnLoad_ScannedLPNOrPalletWHMismatch (HA-1735)
  2020/12/11  RKC     Added Pallet_LoginWarehouseMismatch (HA-1736)
  2020/12/11  RT      Included TaskDetails_Export (CID-1569)
  2020/12/08  AJM     corrected messagename for LPNActv_ShipCartons_ActivationUnsuccessful (HA-1738)
  2020/12/08  RKC     Corrected the CancelTasks actions messages (HA-1755)
  2020/12/04  NB      Added UIAction_ExecuteInBackGround(CIMSV3-1265)
  2020/12/03  KBB     Corrected Assign to user action Messages (CIMSV3-1178)
  2020/11/24  MS      Added ASNLPNReceivedSuccessfully, ASNLPNPalletizedSuccessfully (JL-306)
  2020/11/21  AJM     Added Locations_ModifyPickZone_SamePickZone message (CIMSV3-1231)
  2020/11/20  RV      Added PrintJobs_NoDocumentsToProcess (CIMSV3-1229)
  2020/11/25  KBB     Added ShipVias actions Add and Edit messages (HA-1670)
  2020/11/19  MS      Added ReceiveASNLPN_ReceiverIsClosed (JL-305)
  2020/11/18  RIA     Migrated messages related to SerialNos from S2G (CIMSV3-1211)
  2020/11/17  AJM     Added Locations_ModifyPutawayZone_SamePutawayZone message (CIMSV3-1182)
  2020/11/17  RKC     Added TransferInv_ReceiverNotYetClosed (HA-1369)

  2020/11/11  SJ      Added CartonGroup related messages (HA-1621)
  2020/11/13  RKC     Added Loads_AddOrders_OrderNotWaved, Loads_AddOrders_OrderHasOpenpicks, Loads_AddOrders_ShipViaNull (HA-1610)
  2020/11/12  AJM     Changed InValidTempLabel message to Picking_ScanValidTempLabel (HA-1666)
  2020/11/13  RV      Added ShippingDocs_DocumentsQueued (HA-1659)
  2020/11/12  OK      Added PrintPalletandLPNLabels action messages (HA-1645)
  2020/11/11  MS      Modified description for LPNs_ModifyCartonDetails (CIMSV3-1155)
  2020/10/26  PK      Added Substitute_OwnershipMismatch (S2GCA-1353)
  2020/10/28  SJ      Added messages for ReplenishOrders_Archive (HA-376)
  2020/10/27  SK      Edited LPNResv_ReserveMoreThanOrderQuantity (HA-1583)
  2020/10/23  MS      Added ReceiveASNLPN_OnlySuggestedPallet (JL-212)
  2020/10/22  RBV     Added CartonType_Edit_Successful, CartonTypes_Add_Successful, CartonTypeIsRequired,
                        CartonDescriptionIsRequired, CartonTypeAlreadyExists, InvalidRecordId (HA-1110)
  2020/10/21  VS      Added Receiver_ModifyReceiver_Successful (HA-1600)
  2020/10/21  RBV     Added CartonType_Edit_Successful, CartonType_Add_Successful,
                        DescriptionIsRequired (HA-1110)
  2020/10/06  RKC     Added Layouts_Modify_NoneUpdated, Layouts_Modify_SomeUpdated, Layouts_Modify_Successful,
                        Layouts_Delete_NoneUpdated, Layouts_Delete_SomeUpdated, Layouts_Delete_Successful,
                        Layouts_CannotEditOthersLayouts (CIMSV3-967)
  2020/09/28  RBV     Added message description for Layouts_CannotChangeStandardLayoutCategory (HA-1437)
  2020/09/25  VS      Added WaveCancel_Deferred (CIMSV3-1078)
  2020/09/23  SAK     Added Loads_ModifyApptDetails (HA-1366)
  2020/09/19  MS      Added Messages for Generate Waves (HA-1403)
  2020/09/18  SK      Modified CC_InvalidSKUOrLPNOrPallet to CC_InvalidEntity
                        Added CC_InvalidPallet (HA-1428)
  2020/09/17  KBB     Added CreateLocations_SpecialCharsNotAllowed (HA-1401)
  2020/09/16  MS      Added OrderDetails_ModifyPackCombination messages (HA-775)
  2020/09/13  MS      Added Receipts_PrepareForSorting, ReceiptDetails_PrepareForSorting messages (JL-236)
  2020/09/11  TK      Added CreateLPNs_NoInventoryToCreateKits, CreateLPNs_NotEnoughInventoryToCreateKits &
                        CannotCloseKitOrder_UnitsAssigned (HA-1238)
  2020/09/09  SK      Added missing description for CC Message codes (HA-1371)
  2020/09/02  TK      Added DropPallet_NoDisqualifiedOrdersToHold (HA-1175)
  2020/08/13  PK      Added CompleteRework_InsufficientQty.(HA-1315)
  2020/09/02  SJ/SK   Added Messages for CycleCountTasks_Cancel (CIMSV3-549)
  2020/08/27  AJM     Added OrderDetails_ModifyReworkInfo_*, ODModifyReworkInfo_' messages (HA-1059)
  2020/08/27  RV      Added RecvInv_ReceivedExtraQty and RecvInv_ReceivedBeyondMaxQty (HA-1179)
  2020/08/25  TK      Added LoadShip_LoadBeingShippedInBackGround (S2GCA-1183)
  2020/08/25  RIA     Added MovePallet_InvalidLocationorPallet, MovePallet_CannotMoveEmptyPallet,
                            MovePallet_CannotMergeWithEmptyPallet, AddLPNToPallet_WarehouseMismatch (HA-1245)
  2020/08/19  RIA     Added PalletsMerged_Successful1y (HA-1245)
  2020/08/17  TK      Added MoveLPNs_ReservedLPNsToOrderShipFromWHOnly (HA-1307)
  2020/08/13  RKC     Added PwdPolicy_PasswordNotAllowed, PwdPolicy_LengthGreaterThan, PwdPolicy_MustHaveLowerCase, PwdPolicy_MustHaveUpperCase,
                            PwdPolicy_MustHaveNumber, PwdPolicy_MustHaveSymbol, PwdPolicy_CannotReuse, PwdPolicy_TooManyRepeats (S2G-1415)
  2020/08/05  TK      Added TasksRelease_WaitingOnReplenishment (HA-1211)
  2020/07/30  SJ/TK   Added messages Receipts_ChangeArrivalInfo_*  (HA-1228)
  2020/07/27  RKC     Added LoadShip_ErrorProcessing (HA-1156)
  2020/07/26  TK      Added MoveLPNs_OneOrMoreLPNsOnPalletDoesNotConform (HA-1115)
  2020/07/24  SAK     Added Fields_Edit_Successful (CIMSV3-971)
  2020/07/24  SAK     Added Messages for Mapping (CIMSV3-1001)
  2020/07/23  HYP     Added BoL_ShipToAddressModify (HA-1020)
  2020/07/21  SPP     Added ReceiptDetails_InvalidLabelCode for Receiving  (HA-1091)
  2020/07/21  RKC     Added RFLoad_LPNWarehouseMismatch, RFLoad_PalletWarehouseMismatch, RFLoad_ScannedDockLocationInvalid (HA-1073)
  2020/07/21  SJ      Added messages related to UnassignUser (HA-1134)
  2020/07/20  MS      Added LPNResv_LPNInventoryClassMismatch (HA-1099)
  2020/07/16  NB      Added messages related to Device Configuration (CIMSV3-1012)
  2020/07/15  TK      Added ShipCartonActivation messages (HA-1030)
  2020/07/13  TK      Added messages related to LPNs bulk move (HA-1115)
  2020/07/11  SK      Added CC_InvalidPalletScanned (HA-1077)
  2020/07/11  TK      Added Messages related to Palletization & DePalletization action (HA-1031)
  2020/07/07  RKC     Added WaveRelease_InvalidShipLabelFormat, WaveRelease_InvalidContentLabelFormat (HA-1076)
                            WaveRelease_InvalidPackingListFormat (HA-1087)
  2020/07/23  KBB     Added Selections_Deleted (CIMSV3-966)
  2020/07/02  RV      Added ModifyOrder_* messages (HA-745)
  2020/07/01  NB      Added Load_AddOrders_WarehouseDifferent (CIMSV3-996)
  2020/06/26  NB      Added Receiver_Modify_CannotChangeWH,ReceiverWHMismatch,ReceiverReceiptWHMismatch(CIMSV3-987)
  2020/06/25  SJ      Added LayoutField_Updated (CIMSV3-972)
  2020/06/25  SK      Added AutoActivation_WaveNotQualified for Auto Activation process (HA-906)
  2020/06/24  AJ      Added Load_DocumentsQueued_Successfully message (HA-984)
  2020/06/22  TK      Added Messages releated to Complete Rework (HA-834)
  2020/06/19  AJM     Added Receipt_ChangeWarehouse_* , Receipts_ChangeWH_* messages (HA-926)
  2020/06/19  SJ      Added BoL_OrderDetailsModify_Successful (HA-874)
  2020/06/18  KBB     Added BoL_Modify_Successful (HA-986)
  2020/06/18  OK      Added BoL_CarrierDetailsModify_Successful (HA-1005)
  2020/06/16  MS      Added CancelQtyCannotbeNull, CannotCancelPartialQty, CancelPartialQty, CannotCancelQtyMorethanToAllocate (HA-958)
  2020/06/11  YJ      Added WaveRelease_MissingShipFromPhoneNo (HA-645)
  2020/06/16  MS      Added Task_DocumentsQueued_Successful (HA-853)
  2020/06/10  AJM     Included LPNResv_ReserveMoreThanOrderQuantity (HA-734)
  2020/06/10  RKC     Added CancelLoad_InvalidStatus (HA-844)
  2020/06/10  NB      Added User_SetupFilters_Successful, User_SetupFilters_ValuesRequired, UIAction_NoSelectedEntities(CIMSV3-103)
  2020/07/17  KBB     Added ReworkOrder_InvaildStatusToClose, ReworkOrder_OrderAlreadyClosed (HA-835)
  2020/06/09  RT      Included PrintJobs_JobNotCompletedOrCancelled, PrintJobs_Reprint_NoneUpdated,PrintJobs_Reprint_SomeUpdated and PrintJobs_Reprint_SomeUpdated (HA-650)
  2020/06/06  TK      Added TransferInv_LocationIsNotActive
                      Corrected descriptions for TransferInv_DoNotHavePermissions & TransferInv_LocationIsNotSetupForSKU (HA-803)
  2020/06/04  RV      Included ShipLabel_Inserted and ShipLabel_Voided (HA-745)
  2020/06/03  RT      Included PrintJobs_Reprint_NoneUpdated,PrintJobs_Reprint_SomeUpdated and PrintJobs_Reprint_SomeUpdated (HA-650)
  2020/06/03  RKC     Added WaveRelease_WaveNeedsSystemReservation (HA-787)
  2020/05/29  AJM     Included PrintJobs_Cancel_Successful (HA-467)
  2020/05/26  SV      Added WaveRelease_WarehouseMismatch (HA-655)
  2020/05/23  SK      Added LPNActv_ShipCartons_InvalidLPN, LPNActv_ShipCartons_InvalidLPNType, LPNActv_ShipCartons_InvalidLPNStatus (HA-640)
  2020/05/23  RT      Included PrintJobs_ReleaseForPrinting_NoneUpdated,PrintJobs_ReleaseForPrinting_SomeUpdated and PrintJobs_ReleaseForPrinting_SomeUpdated (HA-603)
  2020/05/19  TK      Added WaveRelease_ODsWithoutPackingGroup &
                        WaveRelease_OrdersWithInvalidPackCombination(HA-386)
  2020/05/19  VM      Layouts_CannotAddSystemLayout => Layouts_CannotAddEditSystemLayout
                      Added Layouts_CannotAddEditStandardLayout (HA-554)
  2020/05/16  TK      Added WaveRelease_ODsWithoutPackingGroup (HA-386)
  2020/05/13  MS      Added HostOrderLineIsRequired (HA-483)
  2020/05/08  TK      Added WaveRelease_ODsWithInvalidUnitsPerCarton & migrated missing messages from CID (HA-386)
  2020/05/05  RKC     Added TransferInv_DestinationNotIdentified, TransferInv_SourceNotIdentified (HA-380)
  2020/05/05  RKC     Added TransferInv_TransferToUnavailableLPN (HA-340)
  2020/05/03  AJM/MS  Added LookUp_Created, LookUp_Updated, LookUpAlreadyExists (HA-91)
  2020/04/19  TK      Added TransferInv_ReceiverNotClosed (HA-222)
  2020/04/16  MS      Added LocationNotInGivenWarehouse (HA-187)
  2020/04/15  RT      Included LPNIsAlreadyOnSamePallet (HA-182)
  2020/04/15  VM      Added Recv_WarehouseMismatch (HA-174)
  2020/04/14  VM      Added LPNMove_BeforeReceiverClosed_NotAllowed
                            LPNMove_BeforeReceiverClosed_InvalidLocationType
                            LPNMove_BeforeReceiverClosed_InvalidWarehouse (HA-161)
  2020/04/13  VM      Added Recv_NotAValidWarehouseToReceive (HA-174)
  2020/04/11  VS      Added Roles Messages (HA-96)
  2020/04/10  VS      Added RFUserLogoutSuccess, RFUserLogoutFailed Messages (HA-95)
  2020/04/08  YJ      Added EditControls (CIMSV3-776)
  2020/04/04  SAK     Added ModifySKUClasses, ModifySKUAliases, ModifySKUDimensions, ModifyPackConfigurations
                            Receivers_PrepareForReceiving_ExecuteInBackGround, Layouts_SelectionSavedSuccessfully (JL-144)
  2020/04/07  VM      PALPN_ReceiverNotClosed: Description changed to suit for both LPN and Pallet (HA-118)
  2020/04/04  SAK     Added ModifySKU*, Receivers_PrepareForReceiving_ExecuteInBackGround, Layouts_SelectionSavedSuccessfully (JL-144)
  2020/04/01  MS      Added DefaultWHIsRequired, User_Created& User_Updated (CIMSV3-467)
  2020/04/01  TK      Added TransferInv_InventoryClassMismatch & Recv_InventoryClassMismatch (HA-84)
  2020/03/31  TK      Added PermissionsModifiedSuccessfully (HA-69)
  2020/02/17  MS      Added Receipt_NoLPNsInTransit (JL-113)
  2020/01/30  RBV     Added CancelWave_AllocationInProcess (HPI-2692)
  2020/02/20  SK      Added LPNResv_NoShipCartonsGenerated (Prod fix)
  2020/02/17  MS      Added Receipts_PrepareForSorting (JL-58)
  2020/01/30  YJ      Added LPNResv_LPNHasNoInnerPacks_ProvideQty (FB-1800)
  2020/01/22  SV      Added LPNResv_InvalidWave, LPNResv_InvalidPickTicket (FB-1667)
  2019/12/18  SK      Additional validation messages (FB-1660)
  2019/12/12  SK      Added LPNResv_MultiSKULPNMultipleCartons, LPNResv_ShipCartonNeedsMultiSKULPN, LPNResv_ImproperActivation (FB-1657)
  2019/11/28  SK      Added LPNResv_LPNOwnershipMismatch (FB-1668)
  2019/10/16  SK      Added new validation messages for 'LPN Reservations' (FB-1442)
  2019/09/24  MS      Added Substitute_LogicalLPNCannotBeSubstituted (OB2-976)
  2019/09/19  RKC     Added LoadShip_LPNsNotPacked (CID-842)
  2019/06/07  RT      Included Receipts_PrepareForReceiving_ExecuteInBackGround,ValidateReceiptToReceive (CID-510)
  2019/05/03  NB      Added BatchPicking_UnitsPickSuccessful(CID-262)
  2019/05/01  RIA     Added CartonTypeIsRequired, CartonTypeIsInvalid (S2GCA-669)
  2019/04/23  AJ      Changed Description for LPN_ModifyLPNs (CIMSV3-257)
  2019/04/22  NB      Added DefaultWHUndefined(AMF-41)
  2019/04/17  RIA     Added Message: Picking_PickListRemaining (CID-283)
  2019/04/10  KSK     Migrated Pallet_ClearedCart related messages (CIMSV3-436)
  2019/03/01  VS      CannotTransferIfLPNReceiverNotClosed: Added Validation message for Transfer LPN (CID-138)
  2019/02/18  VS      PALPN_ReceiverNotClosed: Added Validation message for QCLPN Putaway (CID-110)
  2019/02/18  VS      Receiver_Close_LPNsNotPutaway: Added Messages for QCLPNs Receivers close (CID-117)
  2019/02/13  RV      Added QCInbound_SelectLPNs_NoneUpdated,
                            QCInbound_SelectLPNs_SomeUpdated,
                            QCInbound_SelectLPNs_Successful (CID-53)
  2019/02/05  VM      Added LPNMove_CannotMoveAllocatedLPNToOtherWarehouses (FB-1265)
  2019/01/23  VM      Added Import_ROH_CannotInsertUpdateClosedReceipt (HPI-2349)
  2019/02/01  MJ      Added Messages for LPNs LPN_QCHold and LPN_QCRelease (CID-48)
  2018/11/22  RT      Added LPNResv_InvalidLPNStatus (FB-1200)
  2018/12/19  RIA     Added LoadShip_Has_FutureShipDate (OB2-781)
  2018/12/11  DA      Added message WaveRelease_InvalidAddress (S2GCA-439)
  2018/11/10  RIA     Added WaveRelease_SLWaveWithMultiLineOrders (OB2-666)
  2018/11/05  MJ      Added message descriptions related to PickBatch_AddOrderDetails (S2GCA-313)
  2018/02/11  CK/TD   Added CaptureTrackingNo_FreightSpecialCharsNotAllowed, CaptureTrackingNo_FreightShouldBeNumeric (HPI-2108)
  2018/10/23  VS      Added Import_CannotChangeSourceSystem (HPI-2011, HPI-2081)
  2018/10/01  KSK     Added LoadShip_SomeLPNsMissingUCCBarcodes (S2GCA-305)
  2018/09/26  DK      Added TransferInv_NotValidFromReceivedToPutaway (OB2-646)
  2018/09/28  CK      Added SKU_ModifyCartonGroup_Successful, SKU_ModifyCartonGroup_NoneUpdated, SKU_ModifyCartonGroup_SomeUpdated(HPI-2044)
  2018/09/04  TK      Added LPNOrLocationDoesNotExist (S2GCA-212)
  2018/08/24  TK      Added TaskNotAllocated & TaskNotConfirmed (S2GCA-158)
  2018/08/29  RV      Added Event Monitor related messages (S2G-1096)
  2018/07/04  RV      Added EMA_Message_ShippingDocsExport_1
                            EMA_Subject_ShippingDocsExport_1
                            EMA_Message_GenearateLabels_1
                            EMA_Subject_GenearateLabels_1 (S2G-351)
  2018/06/23  MJ      Added message for ReceiverIsClosed (S2G-933)
  2018/06/07  TK      Changed PickTask_Cancel_* -> PickTask_CancelTask_* (S2G-647)
  2018/06/06  AJ      Added Location_ModifyLocationAttributes_NoneUpdated, Location_ModifyLocationAttributes_SomeUpdated, Location_ModifyLocationAttributes_Successful (S2G-904)
  2018/05/24  RT      Made changes to message name OrderStatusInvalidForClosing by removing Waved status (S2G-630)
  2018/04/27  OK      Added messages for LPN split (S2G-706)
  2018/04/24  SPP     Change the Action name from close order to close PickTicket(CIMS-1941)
  2018/04/19  AJ      Added messages related to pr_Shipping_RegenerateTrackingNumbers (S2G-549)
  2018/04/17  VM      Added ActiveTaskOnPallet (S2G-660)
  2018/04/05  TK      Added PickToEmptyLPN (S2G-542)
  2018/03/30  TK      Added LocationAddSKU_InvaildSKUPackConfig (S2G-426)
  2018/03/23  SV      Added Import_InvalidSourceSystem (FB-1117)
  2018/03/17  KSK     Corrected messages Format for Wave_RFP (S2G-390)
  2018/03/17  AJ      Added ReplenishLPN_InValidOperation,NotALPNTask_UseBatchPicking (S2G-431)
  2018/03/14  TK      Added WaveRelease_OrdersOrUnitsExceededThresholdValue
                            WaveRelease_NoDropLocationOrShipDate
                            WaveRelease_InValidShipVia
                            WaveRelease_InValidCarrier
                            WaveRelease_CaseBinsNotSetUpForSomeSKUs
                            Wave_RFP_TasksNotReadyToConfirm (S2G-382)
  2018/03/13  RV      Added Wave_RFP_Successful (S2G-400)
  2018/03/10  OK      Added LPNPA_LPNStatusIsInvalid, LPNPA_ReplenishLPNStatusIsInValid (S2G-274)
  2018/03/07  RV      Added Wave_RFP_NotRequired, Wave_RFP_WaveTypeNotValid, Wave_RFP_WaveStatusNotValid,Wave_RFP_WaitingOnReplenishment,
                            Wave_RFP_LabelGenerationIncomplete, Wave_RFP_ShippingDocsNotExported (S2G-240)
  2018/03/01  VM      Added PALPN_DisplayIPsAndQty (S2G-315)
  2018/02/16  AJ      Added PickBatch_ReleaseForPicking &
                      modified PickBatch_ReleasePicking to PickBatch_ReleaseForAllocaton(S2G-231)
  2018/02/14  CK      Added UPCRequired, CaseUPCRequired (S2G-155)
  2018/02/10  TD      Added TaskPickGroupMismatch(S2G-218)
  2018/02/06  TD      Added InvalidTaskForReplenishment(S2G-218)
  2018/02/06  SV      Added CC_InvalidSKU (S2G-194)
  2018/02/06  YJ      Added Packing_InvalidLPNWeight (HPI-1802)
  2018/01/31  RV      Added OwnershipMismatch
                            ImportInvAdj_InvalidOperation
                            ImportInvAdj_LPNDoesNotExistInLocation
                            ImportInvAdj_LPNDoesNotExistToReduce
                            ImportInvAdj_InsufficientQtyinLPN
                            ImportInvAdj_WarehouseIsRequired
                            ImportInvAdj_OwnershipIsRequired
                            ImportInvAdj_BusinessUnitIsRequired (S2G-44)
  2018/01/31  TK      Added messages related to Confirm Tasks for Picking (S2G-153)
  2018/01/16  TD      Added Picking_LocationDoestNotAllow (CIMS-1717)
  2017/12/14  RA      Added Messages related to bcp Utitlity (CIMS-1659)
  2017/12/20  OK      Added ExportBatchNotCreated_Alert_Subject (FB-1060)
  2017/01/18  OK      Added CC_SupervisorTaskCreated, CC_UserDoNotHavePermissions_L2CC etc.(GNC-1408)
  2017/01/04  CK      Added Locations_ChangeLocationProfile_Successful (CIMS-1741)
  2017/12/29  TD      Added LocationClassIsRequired, and messaged for *_ChangeLocationProfile_* and
                            ChangeLocationLimits(CIMS-1741)
  2017/10/21  VM      Added Shipping_I_SoldShipCountriesDifferent (OB-576, 577)
  2017/10/19  RA      pr_Imports_ValidateLocations: Added new key for validating the Import of Locations(CIMS-1649)
  2017/10/16  SV      Added LoadShip_LPNOrPalletNotOnLoad
                            LoadShip_OrdersOnLoadWithNoUnits,
                            LoadShip_LPNsNotCompletedPacked (OB-615)
  2017/09/20  MV      Added CannotCloseOrderOnLoad (HPI-1650)
  2017/08/28  KL      Added Substitute_MisMatchWarehouse (HPI-1647)
  2017/08/14  TK      Added PAReplenishLPN_DisplayQty
                            PALPN_ReqUnitsHaveBeenPAAndRestUnitsUnallocated
                            PALPN_MinUnitsToCompletePA
                            PALPN_PartialPutaway
                            PALPN_MsgInfoWithLocQty
                            PALPN_PutawayComplete
                            PALPN_DisplayQty (HPI-1626)
  2017/02/20  OK      Added Picking_LocationOnHold (GNC-1426)
  2017/08/26  NB      Added Layouts_NoAggregateFields, Layouts_NoVisibleFields(CIMSV3-11)
  2017/08/23  NB      Added Layouts_ZeroSelectionFilters(CIMSV3-11)
  2017/08/18  NB      Added Layouts_CannotChangeLayoutType(CIMSV3-11)
  2017/08/14  NB      Added Layouts_SelectionNameAlreadyExists(CIMSV3-11)
  2017/07/18  DK      Migrated messages Substitute_InvalidLPNStatus, Substitute_NewLPNCannotBeSubstituted from HPI (FB-988)
  2017/07/11  SV      Added WaveRelease_UnitWgtVolNestingFactor (CIMS-1488)
  2017/07/05  PK      Added LoadShip_MissingBoLInfoOnSomeOrders (FB-977)
              VM      (FB-977)
                      ShipmentsOnLoadNotReadyToShip => LoadShip_ShipmentsOnLoadNotReadyToShip
                      LPNsOnLoadNotReadyToShip      => LoadShip_LPNsOnLoadNotReadyToShip
  2017/04/12  YJ      Added WaveRelease_OrderCategory1Missing (HPI-1502)
  2017/06/14  OK      Added UpdateConflict (GNC-1540)
  2017/03/31  PSK     Added LPNVoided (HPI-1402)
  2017/02/20  TK      Added Packing validation messages (HPI-1363)
  2017/02/03  TK      Added WaveRelease_PickBinsNotSetUpForSomeSKUs (HPI-1364)
  2017/01/20  VM      Added CloseOrderAllTasksNotCompleted (HPI-1301)
  2016/12/23  KL      Added TransferInv_ToLPNShouldBeEmpty (HPI-1114)
  2016/12/13  MV      Added PickBatchesCreatedSuccessfully,PickBatchesNotCreated messages (HPI-644)
  2016/12/28  RV      Added LPNAdjust_UnavailableLine (HPI-1222)
  2016/11/28  YJ      Added messages related to LPN Reservations (HPI-1062)
  2016/11/25  KL      Added CreateLPNsToReceive1, CreateLPNsToReceive_Pallet1 and enhanced the message formation while creating receive LPNs (HPI-886)
  2016/11/25  PSK     Added BuildCart_TaskPendingReplenish (HPI-602)
  2016/11/24  PSK     Added CC_LPNPicked,CC_LPNAlreadyShipped,CC_LPNVoidOrConsumed (HPI-1026)
  2016/11/21  VM      Added LPNAdjust_CannotAdjustReplenishLPN (HPI-1069)
  2016/11/17  SV      Added DropPallet_InvalidOperation, DropPallet_TasksInProgress,
                        DropPallet_InvalidPalletStatus (HPI-854)
  2016/11/14  RV      Added WaveRelease_OnlyPickToShipOrders (HPI-1046)
  2016/11/12  OK/VM   Added ConfirmTaskPicks_* messages (HPI-993/1008)
  2016/11/09  PSK     Added message RO_GenerateOrders (HPI-927)
  2016/11/01  RV      Added messages for Reverse Receipt (HPI-970)
  2016/10/31  RV      Added Packing_PalletHasOutstandingPicks (HPI-931)
  2016/09/30  KL      Added Order_RemoveOrdersFromWave related messages (HPI-739)
  2016/09/27  YJ      Changed message description for BuildCart_InvalidTaskStatus (HPI-769)
  2016/09/26  SV      Added ExceedingMaxQtyToReceive (HPI-732)
  2016/09/09  MV      Added Packing_InvalidCartonType (CIMS-1058)
  2016/09/06  VM      Added LoadShip_OrdersHaveOutstandingPicks (HPI-579)
  2016/08/31  KL      Added CompleteVAS_NoPicklaneToAdjustInv and CompleteVAS_NotEnoughInvToAdjust (HPI-551)
  2016/08/19  DK      Added message Shipments_Subject(HPI-457)
  2016/08/18  TK      Added ScannedPosIsReservedForEL (HPI-477)
  2016/08/10  PK      Added ELCannotPickIntoDiffPosition.
  2016/08/18  KN      Added GroupItemsAlreadyPacked (HPI-486)
  2016/08/05  KL      InvalidCombinationOfPalletAndWaveOrTask (CIMS-895)
  2016/08/03  OK      Added TaskIsDependentOnReplenishTask (HPI-371)
  2016/07/27  AY      Added ShipLabel_ReplenishOrder/ShipLabel_ReplenishWave
  2016/07/26  SV      Added ShipmentsWithMultipleShipVias (TDAX-374)
  2016/07/12  DK      Added message CompleteProductionSuccess (HPI-257)
  2016/07/12  AY/YJ   Added message PAByLocation_InvalidStorageType (HPI-196)
  2016/07/11  TD      Added GetNewLicenseToUseMoreDevices.
  2016/07/05  OK      Added LocationAddSKU_SKUAlreadyExists (GNC-1346)
  2016/07/03  TK      Added WaveRelease_CannotHaveReplenishOrders (NBD-624)
  2016/06/30  VM      Added LoadShip_SomeLPNsMissingTrkNos, CloseOrder_SomeLPNsMissingTrkNos (NBD-629, FB-738)
  2016/06/24  TK      Added messages for Print Engraving labels action (HPI-176)
  2016/06/18  TK      Added CannotShortPick (NBD-595)
  2016/06/17  PSK     Added GenerateBoLs_NoOrdersToGenerateBoL,GenerateBoLs_LoadShippedOrCancelled message(CIMS-976).
  2016/06/03  MV      Added Action to allow user to modify Receipt Details (FB-706)
  2016/06/03  RV      Added ClearCartUser related messages (NBD-573)
  2016/06/01  KL      Added Import_InvalidUoM message (HPI-97)
  2016/05/25  OK      Added RO change Ownership related messages (FB-680)
  2016/05/21  PSK     Show Order Count in Load_Generation_Successful2 (CIMS-921)
  2016/05/20  KL      Added LPNMove_InvalidUser (GNC-1313)
  2016/05/10  OK      Corrected Packing_CenterTitle to display ShipVia Description instead of displaying customer name (NBD-428)
  2016/05/03  OK      Added NextSeqNoMissing_LPN (HPI-84)
  2016/05/03  YJ      Added messsages Related Event Monitor Alert Mails (TD-344)
  2016/04/28  OK      Added Packing_ShipToAddress (NBD-428)
  2016/04/28  YJ      Renamed DailyUpdatesExport messages as ExportTrans_CSV,ExportTrans_PDV,ExportTrans_XML because we are no more goign to use DailyUpdatesExport in CIMS (TDAX-344)
  2016/04/28  AY      Added LoadShip_CannotShipEmptyLoad
  2016/04/27  OK      Added Picking_ScanToCartPositionInvalid, ScannedPositionFromAnotherCart (NBD391)
  2016/04/27  RV      Added Shipping_LPNWeightRequired and  Shipping_LPNCartonTypeRequired (NBD-384)
  2016/04/07  TK      Added NoPackingContents
  2016/03/29  SV      Added LoadShip_CannotShortShip, ModifyPickTicket_NoValues (NBD-293)
  2016/03/24  KL      Added InvalidPalletFormat message description (CIMS-810).
  2016/03/18  TK      Added Import_InvalidAction (NBD-260)
  2016/03/18  DK      Corrected CreateLPNsToReceive_Pallet message description (NBD-277).
  2016/03/16  TK      Added Layouts_DuplicateFields (NBD-298)
  2016/03/03  OK      Added BoLIsRequiredToShip (NBD-281)
  2016/03/10  RV      Added Messages ShipLabel_InvalidInput and ShipLabel_NotaValidEntity to validate while shiplabels print (NBD-153)
  2016/02/25  NY      Added Messages related to Receive SKUs (SRI-454)
  2016/02/22  TK      Added messages related to Putaway LPNs (GNC-1247)
  2016/02/12  SV      Added Order_ModifyShipDetails_None, Order_ModifyShipDetails_SomeUpdated, Order_ModifyShipDetails_Successful (CIMS-769)
  2016/02/25  TK      Corrected Putaway LPNs message descriptions (CIMS-790)
  2016/02/25  TK      Added messages related to Putaway LPNs (GNC-1247)
  2016/02/23  OK      Added PicklaneSetUp_SKUIsNotAdded (SRI-467)
  2016/02/12  SV      Added Order_ModifyShipDetails_NoneUpdated, Order_ModifyShipDetails_SomeUpdated, Order_ModifyShipDetails_Successful (CIMS-769)
  2016/02/09  NY      Added Import_ComponentQtyIsInvalid
  2016/02/04  KL      Added SKURemove_InventoryExists_CannotRemove for pr_RFC_Inventory (NBD-125)
  2016/02/03  SV      Added messages for Order_ModifyPickTicket action (FB-609)
  2016/02/02  OK      Added LPNAlreadyPicked(cims-714)
  2016/01/29  TK      Added more messages for RF Packing (FB-614)
  2016/01/19  KL      Added PicklaneLPNs_RemoveZeroQtySKUs messages (OB-407)
  2016/01/13  TK      Added messages for RF Packing (NBD-64)
  2015/12/14  NY      Added CannotCancelOrderOnLoad
  2015/12/23  SV      Added ExceedingQtyToReceive (FB-175)
  2015/12/16  TK      Added PA_AllocatedLPNCanOnlyPutawayToASuggestedLoc (ACME-419)
  2015/12/07  SV      Added Work/SalesOrdersNotYetProcessed (SRI-422)
  2015/12/03  OK      Added Import_ROD_InvalidOwnership (NBD-58)
  2015/12/01  TK      Changed message description PicksCompletedInScannedZone
              AY      Added BatchPickComplete
  2015/11/20  YJ      Receipts_AssignASNLPNs_Successful: Corrected message to show count of rows updated (FB-491)
  2015/11/12  NY      Added ReceiverClose_LPNsIntransit, ReceiverClose_LPNsNotPutaway (ACME- 398).
  2015/11/17  SV      Added Import_OD_InvalidStatusToUpdate (SRI-416)
  2015/11/05  OK      Added messages for action ChangeLocationStorageType(NBD-34)
  2015/11/03  SV      Added Location_CannotDeleted (NBD-35)
  2015/11/02  OK      Added InvalidPickZoneForTask for BatchPicking(FB-477)
  2015/10/28  YJ      Added ROModify_InvalidOrders, ROClose_LPNsNotPutaway (FB-400)
  2015/10/19  TK      Added CannotPutawayMultiSKUPallet (ACME-375)
  2015/10/17  RV      Added BatchIdentifiedButTaskNotReleasedForPicking for Batch Pallet Picking (FB-440)
  2015/10/06  TK      Added CC_PickZoneNotConfigured,CC_PickZoneIsInvalid, PA_LPNAlreadyOnOPallet (ACME-363, 354)
  2015/09/30  OK      Added the messages for Returns Process (FB-388).
  2015/09/29  AY      Corrected several messages
  2015/09/28  DK      Added LPNTypeIsInvalid and PutawaySuccessful.
  2015/09/25  VS      Added SKUPrepacks, OrderDetails, ASNLPNDetail, UPC, Vendors, CartonTypes (cIMS-642)
  2015/09/24  NY      Added ScannedMoreThanPicked.
  2015/09/25  TK      Added Activity Log messages (ACME-348)
  2015/09/15  TK      Added LPNIsRequired
  2015/09/07  OK      Added LocationAdjust_U_CannotAdjustReservedQty (FB-341).
  2015/09/05  SK      Added Unpack related Error and Success messages (CIMS-584).
  2015/09/03  TK      Added PA_ScanValidPalletOrLocation, PA_ScannedPalletIsOfDifferentWH
  2015/09/03  SV      Added CannotPackOrderToTheCarton (FB-248)
  2015/09/01  VM      Added TaskDoesNotExist
  2015/08/29  RV      Added Shipping Validation messages (OB-388)
  2015/08/25  RV      Corrected MessageNames and description as per fn_Messages_BuildActionResponse (ACME-241)
  2015/08/22  SV/AY   Corrected the descriptions for messages referring Batch to Task (ACME-291)
  2015/08/20  VM      Added DropPallet_InvalidWarehouse (FB-310)
  2015/08/19  TK      Added BuildCart_AllLPNsBuilt
  2015/08/17  NY      Added Import_InvalidReceipt
  2015/08/12  TK      Added BuildCart_PalletInUseForAnotherTask, CartPositionAlreadyAllocated.
  2015/07/27  OK      Added WaveRelease_OnlySameCustomerOrders (ACME-269).
  2015/06/16  DK      Corrected Description for TaskIsRequired.
  2015/06/12  TK      Changes to Confirm Load as Shipped
  2015/06/09  TK      Added NotEnoughPositionsToBuildCart
  2015/06/09  YJ      Added messages for BuildCart functionality.
  2015/06/08  TK      Added TaskIsRequired and PickZoneIsRequired.
  2015/06/05  TK      Added ScannedPalletIsNotAssociatedWithTask
  2015/06/03  DK      Added MessageNames for RF BuildCart functinality.
  2015/06/02  RV      Added Layouts_DoesNotHavePermissionsToCreate.
  2015/05/27  RV      Added Event Monitor and Interface Error Alert Mails Related.
  2015/04/20  YJ      Added Pick Tasks Related messages.
  2015/03/23  TK      Added CannotPickUnitsFromLPN
  2015/03/19  DK      Added messages for ExplodePrepack.
  2015/03/02  TK      Added BulkPull_InvalidPallet.
  2015/02/04  VM      Added Picking-Substitution Related messages
  2015/01/25  DK      Added CannotSubstituteAnyLPNWithAOpenLPN.
  2014/01/20  TK      Added PickLPNFromSuggestedLocationOnly.
  2014/01/16  TK      Added BatchIsNotAllocated.
  2015/01/09  PKS     LocationRemoveSKU_DirRes_Lines.
  2015/01/02  AY      Added OrderToBeCanceled.
  2014/11/28  DK      Added SKUUoMMismatch.
  2014/11/11  TK      Added Messages for close Wave action.
  2014/11/06  DK      Added LocationRemoveSKU_NotAPicklane
  2014/10/29  DK      Added LocationSubType_NotAStatic message.
  2014/10/28  VM      PackingSuccessful: Modified message as it is the same message used when reopen/modify package and close it as well.
                      NotAPackedLPNStatus: Added
  2014/09/04  TK      Added TaskNotReleasedForPicking.
  2014/08/19  NY      Added CannotCCLessthanReservedQty, CompleteLPNAllocated_CannotChangeLPNQty.
  2014/08/18  PV      Added CancelPutawayLPNSuccessful.
  2014/08/18  TK      Added SKUIsOfInactiveStatus and changed PicklaneSetUp_NotAPicklane to
                        picklaneLocationSetUp_NotAPicklane..
  2014/08/07  TK      Added PalletTypeIsLimitedOnlyToView.
  2014/08/05  TD      Added LPNTask_UseLPNPicking.
  2014/08/01  TK      Added TaskAlreadyAssigned.
  2014/07/25  TK      Added LPN_UpdateInvExpDate_Successful.
  2014/07/21  PK      Added PA_LPNPAClassHasNoRules.
  2014/07/05  AK      Added ReserveStorageTypeIsInvalid and PicklaneStorageTypeIsInvalid in Locations.
  2014/07/02  YJ      Replaced Wave for description in the place of PickBatch,Batch.
  2014/06/25  VM      Added TransferInv_CannotMoveReceivedInvBetweenWH.
  2014/06/20  AK      Added Messages for ReallocateBatch action.
  2014/06/18  PV      Added OrderStatusInvalidForDelete.
  2014/06/18  TK      Added PalletsCreatedSuccessfully.
  2014/06/12  TD      Added CannotPickAllInvIntoOneLabel.
  2014/06/07  YJ      Added message for Locations.
  2014/06/05  SV      Added SQLCannotBeNullOrEmpty.
  2014/06/06  AK      set Proper MessageName for Assign to user action for PickBatch.
  2014/06/03  PV      Modifed Archive_Orders messages.
  2014/05/30  PV      Added Replenishment messages, migrated from Fechheimer.
  2014/05/29  TD      Added InvalidTempLabel.
  2014/05/22  TK      Changes made to display count based on functions BuildAction and BuildActionResponse.
  2014/05/19  TK      Changes made to display the modified records count out of total records.
  2014/05/19  TD      Added LocationAdjust_NotAUnitPicklane.
  2014/05/16  PV      Added LocationSKUIsNotDefined
  2014/05/15  PV      Added LPNAlreadyPutaway
  2014/05/14  PV      Added LocReplenishUOMShouldbegrtCS.
  2014/05/13  PV      Added LocMaxQtyShouldbegrtMin
  2014/05/13  TD      Added CCCompletedSuccessfully.
  2014/05/12  PV      Reframed LPNInnerPacksAndQtyMismatch message description.
  2014/05/05  TD      Added PicklaneSetUp_NotAPicklane, PicklaneSetUp_ReplenishUnitsOnly.
  2014/05/03  PK      Added LPNAdjustment.
  2014/05/01  YJ      Added ValidateTransferInventory messages.
  2014/05/01  YJ      Added LPNs Entity messages.
  2014/05/01  PV      Changed InvalidTransferQty message to TransferInv_NoSufficientQty
  2014/04/28  PV      Added InvalidTransferQty message.
  2014/04/26  DK      Added Receiver_Modify_NoneSelected
  2014/04/25  DK      Modified messages on ReceiverCreatedSuccessfully and ReceiverUpdatedSuccessfully.
  2014/04/23  TD      Added PlanBatch_InvalidStatus.
  2014/04/22  TD      Added LocationAdjust_ReasonCodeRequired, LPNAdjust_ReasonCodeRequired.
  2014/04/21  PKS     Added LocationIsInvalidForPicking
  2014/04/18  DK      Added CannotPALPN_ReceiverOpen, CannotPAPallet_ReceiverOpen
  2014/04/18  DK      Added Receivers_CloseReceiver_NoneUpdated, Receivers_CloseReceiver_SomeUpdated,
                            Receivers_CloseReceiver_Successful, LPNs_UnAssignLPNs_NoneUpdated,
                            LPNs_UnAssignLPNs_SomeUpdated, LPNs_UnAssignLPNs_Successful,
  2014/04/17  DK      Added ReceiverCreatedSuccessfully, ReceiverUpdatedSuccessfully,.BoLNumberIsRequired,
                            Receipts_AssignASNLPNs_NoneUpdated, Receipts_AssignASNLPNs_SomeUpdated ,
                            Receipts_AssignASNLPNs_Successful, ReceiverModify_InvalidStatus
  2014/03/03  PKS     Added InvalidReceiverNumber.
  2014/04/15  AK      Added Messages for ReleaseTask action.
  2014/04/14  TD      Added InvalidInnerPacks.
  2014/07/10  AK      Added Messages for BatchPlanned action.
  2014/04/10  AK      Added Messages for BatchPlanned action.
  2014/04/08  PK      Added TaskDoesNotExist, TaskNotAvailableForPicking,
                        TaskIsNotAssociatedWithThisBatch, TaskIsNotAssociatedWithThisPickTicket.
  2014/04/05  DK      Added TrackingNo_Updated_Successful, CaptureTrackingNo_InvalidStatus message.
  2014/04/04  PK      Added LPNAdjust_ReferenceCannotbeEmpty.
  2014/03/20  PKS     Added ASNCaseReceivedSuccessfully, ReceiptHasMultipleCustPOsWithSameSKU,
                      CustPOCompletelyReceived, LPNNotAssociatedWithASN, NotAASNReceivingLocation
  2014/03/18  TD      Added TransferInventory_UnitPackagesAredifferent.
  2014/03/18  PKS     Added ReceiverNumberIsRequired.
  2014/03/17  TD      Added LocationAddSKU_NotACasePicklane,LocationAddSKU_NotAUnitPicklane.
  2014/03/11  TD      Added LPNInnePacksAndQtyMissMatch.
  2014/03/06  TD      Added LPN_ModifyLPNs related messages.
  2014/02/20  PK      Added TransferInv_LPNIsAllocated.
  2014/02/19  PK      Added LoadShip_SomeLPNsOnLoadWithInvalidLPNTypes, LoadShip_SomeLPNsOnLoadWithOutOrderInfo.
  2014/01/30  TD      Added LPN_Reverse-Receipt related messages.
  2013/12/18  PK      Added LPNAdjust_CannotAdjustReservedQuantity, TransferInv_CannotTransferReservedLine.
  2103/12/16  TD      Added LPNVoid_ReasonCodeRequired.
              PK      Added PalletStoreMismatch, PalletStatusMismatch, PalletLoadMismatch.
  2013/12/12  PK      Added CannotTransferEmptyPallet, SuccessfullyTransferredPallet,
                      SuccessfullyTransferredPartialPallet
  2103/12/12  TD      Added LoadShip_PalletAndLPNsAreOnDiffLoads, LPNMove_LPNIsAllcoated.
  2013/12/05  NY      Added Messages Layouts_CannotAddSystemWide, Layouts_CannotSaveDefaultLayout.
  2013/11/18  NY      Added Pick Task AssignedTo messages.
  2013/11/12  PK      Added Picking_PalletAlreadyPickedForTask, PickedQtyIsGreaterThanTaskQty.
  2013/10/29  PK      Added InvalidLPNOrPallet, PalletIsAlreadyOnALoad, LPNIsAlreadyOnALoad, PalletHasMultipleShipTos,
                        LoadForDifferentShipment, RFLoad_InvalidLPNStatus, RFLoad_InvalidPalletStatus, RFLoad_EmptyPallet.
  2103/09/10  TD      Added messages for Task Cancellation.
  2013/10/09  VM      NoLPNsVoided => LPNVoid_NoneUpdated, SomeLPNsVoided => LPNVoid_SomeUpdated, LPNsVoidedSuccessfully => LPNVoid_Successfully
  2013/09/26  VM      Added CannotDeleteReceipt, CannotDeleteReceiptDetail
  2013/09/04  NY      Added messages for modify Warehouse.
  2103/08/28  TD      Added UPCAssociatedWithSameSKU.
  2013/08/27  NY      Added Messages for Open/Close receipts
  2013/08/21  AY      Added MultiSKULPNsNotAllowed
  2013/08/19  NY      Added Description for Location_CannotDeactivate.
  2013/08/17  PK      Added SKUDimensionsRequired, SKUCubeWeightRequired, SKUPackInfoRequired.
  2013/08/10  AY      ScanLocIsNotSuggestedLocation: Added
  2013/08/06  TD      Added UPC add  to SKU or remove from SKU messages.
  2013/08/05  TD      Added SKU modify related changes.
  2013/07/12  AKP     Added messages: Order_ReleaseOrders_NoneUpdated, Order_ReleaseOrders_SomeUpdated, Order_ReleaseOrders_Successfull
  2103/06/04  TD      Added  Messages for Location Activate and Deactivate.
  2013/02/27  YA      Modified messages on LPN_UnallocateLPNs_SomeUpdated and LPN_UnallocateLPNs_Successful.
  2013/02/06  SP      Added message: ModifyBatch_InvalidStatus.
  2013/01/30  NY      Added messages:Layouts_AddedSuccessfully,Layouts_SavedSuccessfully.
  2013/01/22  TD/NB   VICSBoL Functionality related messages
  2013/01/08  SP      Corrected the messages Load_MarkAsShipped.
  2012/12/14  PKS     Added ToShipQtyIsGreaterThanOrderedQty
  2012/12/14  PKS     Added Load_BoLNumberAlreadyExists
  2012/11/30  PK      Added AdjAllocLPN_AdjQtyIsGreaterThanOrderedQty,
                            AdjAllocLPN_LPNQtyMismatchWithUnitsPerCarton.
  2012/11/29  YA      Added LPNResv_InvalidCombination
  2012/11/29  PKS     Renamed Load_MarkLoadsAsShip_AllShipped, Load_MarkLoadsAsShip_SomeShipped, Load_MarkLoadsAsShip_NonShipped as
                      Load_MarkAsShip_AllShipped, Load_MarkAsShip_SomeShipped, Load_MarkAsShip_NonShipped respectively.
  2012/11/20  YA      Added ReceiptDetailIsInvalid.
  2012/11/24  PKS     Added OrderDetails_Modify_None, OrderDetails_Modify_Some, OrderDetails_Modify_Successfully.
  2012/11/23  PKS     Added PickBatch_AddOrders_NoneUpdated, PickBatch_AddOrders_SomeUpdated, PickBatch_AddOrders_Successful
  2012/11/06  YA      Added PalletsWarehouseMismatch
  2012/10/26  YA      Added CancelBatch_InvalidStatus.
  2012/10/25  PKS     Added Load_MarkLoadsAsShip_AllShipped, Load_MarkLoadsAsShip_SomeShipped, Load_MarkLoadsAsShip_NonShipped
  2012/10/25  YA/VM   Added LPNReservation related messages.
  2012/10/25  VM      Added message for BatchPausedSuccesfully
  2012/10/25  PKS     Added LoadModify_InvalidBoLNumber.
  2012/10/20  NY      Added Messages for UnallocateLPNs.
  2012/10/09  VM      Added LPN_CreateInvLPNs_InvalidPallet, LPN_CreateInvLPNs_InvalidPalletStatus
  2012/09/28  AA      Added message for SKUIsNotActive
  2012/09/24  PKS     Corrected Load message.
  2012/09/20  YA      Added LPNsWarehouseMismatch
  2012/09/18  SP      Updated description for NoUnitsAvailToPickForBatch.
  2012/09/17  YA      Added DropPallet_EmptyPallet, TransferInv_LPNFromStatusIsInvalid, TransferInv_LPNToStatusIsInvalid
  2012/09/12  YA      Added LPNAdjust_CannotAdjustAllocatedLPN, LPNIsEmpty.
              PK      Added CC_InvalidLPN
  2012/09/12  NY      Added InvalidBatchToRemoveOrders,OrderAlreadyShipped
  2012/09/12  PKS     Corrected param for Load_Generation_Successful
  2012/09/12  VM      Added PA_InvalidLocationType.
  2012/09/12  PKS     Added InvalidDesiredShipDate, InvalidDeliveryDate.
  2012/09/11  YA      Added LPNMove_InvalidStatus
  2012/09/06  PK      Added BatchIsCompletelyPicked
  2012/09/06  YA      Added message CannotAddStagedLPNToReserveOrBulkLocation
  2012/09/05  AA      Added LoadShip_InvalidRoutingStatus
  2012/09/05  NY      Corrected Messages for multiple Load generations.
  2012/09/03  PK      Added CC_InvalidSKU, CC_ScanSKUNotLPN, CC_CannotScanLPN.
  2012/08/28  YA      Added messages, LoadModify_ShippedOrCanceled, LoadModify_NewLoad_CannotConfirmRouting;
  2012/08/27  YA      Added messages CannotMoveEmptyPallet, InvalidLocationorPallet
  2012/08/22  AA      Added message for Layouts 'Layouts_LayoutNameAlreadyExists'
              PK      Added CannotAddMoreThanOneSKUToLPN
  2012/08/20  AA      Modified Message Description for 'Load_AddOrders_Successful', 'Load_AddOrders_NoneAdded' (ta3572)
  2012/08/20  PK      Added DropPalletInvalidLocation, NoPalletPicksForTheBatch, NoPalletsAvailToPickForBatch
                       InvalidFromPallet, InvalidPickingPallet, PalletClosedForPicking.
  2012/08/17  PKS     Added message LPNsCreatedSuccessfully
  2012/08/09  VM      Added InvalidPickingLPN
  2012/08/08  VM      Added message for OrderAlreadyCanceled
              PK      Modified Message CC_InvalidSKUOrLPNOrPallet
  2012/08/07  YA      Added message CannotMovePalletIntoPicklane.
  2012/08/06  PKS     Added pr_CrossDock_SelectedASNs related messages.
  2012/08/06  PK      Added PalletAndStorageTypeMismatch.
  2012/08/03  YA      Added LPNAddedSuccessfully, DropBuildPallet_Successful.
  2012/08/03  AA      Added messages for Layouts
  2012/07/31  YA      Modified message description of LocationHasNoItemsToAdjust.
  2012/07/27  YA      Added message OrderShortPicked.
  2012/07/24  NY      Added Message SelectedBatchFromWrongWarehouse.
              PK      Added Message LPNAlreadyOnPallet
  2102/07/19  YA      Added 'CannotAdjustEmptyLocation'.
  2012/07/11  PK      Added RBAC Module and CycleCount Module related messages
  2012/07/11  NB      Corrections to Load Management Messages
                        Added missing messages
  2012/07/03  PK      Added NoValidASNLPNs.
  2012/06/30  PKS     Added message LPN_CreateInvLPNs_Successful.
  2012/06/29  PK      Added CannotDropToPicklane.
  2012/06/27  YA      Added messages on 'NotaReceivingPallet' and 'CannotReceiveToLocationType'.
  2012/06/27  NY      Added Messsages OwnerIsInvalid, OwnerIsRequired.
  2012/06/22  PKS     Added message PrePackSKUQtyShouldBeOne related to SKUPrepacks.
  2012/06/20  TD      Added Shipments/Load related messages, Added Cancel Load Messages.
  2012/06/18  PK      Added LPNClosedForPicking.
  2012/06/13  NY      Added messages NoOrdersClosed, SomeOrdersNotClosed, OrdersClosedSuccessfully.
  2012/05/31  AY      Added messages InvalidStorageTypeToMoveLPN, InvalidStorageTypeToMovePallet
  2012/05/11  PK      Added messages for InvalidBatchStatus, MulipleOwnersOnBatch, BatchAlreadyConsolidated
  2012/04/16  PKS     Added messages for ModifyLPNType, ModifyOwnership, ChangeSKU for Modify LPNs- non-updated
                      some updated, all updated successfully (totally nine messages added.)
              AY      Added MultipleDestinedWarehouses.
  2012/04/13  NY      Added CannotChangeAnLPNWhichHasMulipleSKUs,LPN should not hava Multiple Values
  2012/04/12  PKS     Added LPNOwnerIsRequired, InvalidOwner.
  2012/03/21  PK      Added PutawayPalletComplete, NoLocationsToPutawayPallet.
  2012/01/30  PKS     Added Orders page action menu 'modify shipvia' related messages.
  2012/01/27  PK      Added BusyInBatchAssignment.
  2012/01/11  PKS     Added Void LPN messages.
  2012/01/10  YA      Added CycleCount related messages.
  2011/12/09  YA      Added Putaway Pallet messages
  2011/11/29  AA      Added messages for Incomplete Orders in Packing.
  2011/11/17  SHR     Added messages for LPN Modify.
  2011/11/17  PK      Added BatchUsedWithAnotherPallet
  2011/11/04  PK      Added CannotPickToSameLPN, CannotPickToPickLane.
  2011/11/03  PKS     Added Messages CloseOrderAllUnitsAreNotShipped, OrderCanceledAndCannotbeClosed
                        OrderAlreadyClosed
  2011/10/24  NB      Added PackingInvalidCartonType
  2011/10/19  AA      Added Packing Messages.
  2011/10/18  SHR     Added SKUIsRequired.
  2011/10/11  TD      Added NoBatchesToPick.
  2011/10/10  VM      Added WarehouseIsRequired, LPNIsAlreadyInSameLocation
  2011/10/03  NB      Added Shipping related Messages.
  2011/09/26  PK      Added CannotTransferOnlyFromPicklane.
  2011/09/21  AA      Packing User Interface Messages
  2011/09/21  PKS     Added Force Order Close related messages
  2011/09/09  VM      for Picking: SKUMismatch => PickingSKUMismatch as SKUMismatch is already exist
  2011/08/25  PK      Added SKUMismatch, CannotDropIntoLocationType.
  2011/08/11  AA      Added Pallet/BatchDoesNotExist for packing module
  2011/08/01  AA      Add PalletNotReadyTobePacked and PalletCurrentlyInPacking for packing module
  2011/08/04  DP      Added  'BatchDoesNotExist','BatchNotAvailableForPicking','PalletNotAvailableForPicking'
                      'PickTicketNotOnaBatch','InvalidToLPN'

  2011/08/03  DP      Added PalletDoesNotExist, QuantityOfPalletShouldBeZero
                      QuantityOfLPNsOnPalletShouldBeZero for Picking.
  2011/07/26  DP      Changed the Description for the Message Name "LocationIsInvalid".
  2011/07/14  VM      Added NoLocationsToPutaway.
  2011/07/13  DP      Added LPNTypeCannotbePickLane, LPNStatusIsInvalid.
  2011/07/12  PK      Added ContactIsRequired, ContactIsInvalid, ContactAlreadyExist
                        ContactDoesNotExist, ContactTypeIsRequired.
  2011/07/11  PK      Added BusinessUnitIsRequired, LPNTypeIsRequired, DestWarehouseIsRequired
                       DestWarehouseIsInvalid.
  2011/03/11  VM      Added SKUMismatch
  2011/03/09  VM      Added CannotReceiveMultipleReceiptsIntoOneLPN
                      LPNIsNotInvalidStatus => InvalidLPNStatus & some other corrections
  2011/02/25  VM      Added VendorAlreadyExist, LPNLineAlreadyExist
  2011/02/16  VK      Added MessageName and Description for pr_RFC_ReceiveASNLPN.
  2011/02/15  VK      Added MessageName and Description for Locations.
  2011/02/01  VM      Added LPNConfirmSuccessful
  2011/01/26  VM      Added Picking related messages.
                      PickTicketInvalidForPicking: Place changed
  2011/01/25  VM      Added PickTicketInvalidForPicking
  2011/01/14  VK      Changed the MessageNames and their Descriptions
  2010/12/31  VK      Made changes to RFC_ValidateLPN Messagename and Description.
  2010/12/22  VK      Added MessageName for procedure pr_Imports_ValidateOrderDetail
  2010/12/16  VK      Added MessageNames of Imports Procedures and
                       pr_Receipts_ReceiveInventory procedure
  2010/12/10  VK      Added MessageNames of pr_Exports_AddOrUpdate
  2010/12/03  VK      Created the file and added different MessageNames
                       with their Description.
------------------------------------------------------------------------------*/
 Go
/*
  UI Notify Types:
    null -  ignore the message
    'W'  -  Warning
    'I'  -  Information
    'E'  -  Error
    'X'  -  Exception
*/

/* Create temp table */
select MessageName, Description into #Messages from Messages where MessageName = '#';

insert into #Messages
            (MessageName,                                   Description)
/*------------------------------------------------------------------------------*/
/* RBAC Module */
/*------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------*/
/* User Login */
/*------------------------------------------------------------------------------*/

      select 'UserNameIsRequired',                          'User name is required'
union select 'UserNameIsInvalid',                           'Invalid user name'
union select 'FirstNameIsRequired',                         'First name is required'
union select 'LastNameIsRequired',                          'Last name is required'
union select 'RoleIdIsRequired',                            'Role is required'
union select 'PasswordIsRequired',                          'Password is required'
union select 'PasswordPolicyIsRequired',                    'Password Policy is required'
union select 'PasswordIsInvalid',                           'Invalid password'
union select 'UserIsNotActive',                             'User is inactive'
union select 'UserAccountIsLocked',                         'User account is locked. Please contact system administrator!!!'
union select 'NotSufficientLicenses',                       'Devices licensed count exceeded, Please contact support team'
union select 'DefaultWHUndefined',                          'Default Warehouse must be defined for the user. Contact System Administrator.'
union select 'DefaultWHIsRequired',                         'Warhouse is required'
union select 'WarehouseIsInvalid',                          'Selected Warehouse is invalid'
union select 'ChangePWD_CurrentPasswordInvalid',            'Current password is invalid'

union select 'User_Created',                                'New account created successfully for user %1'
union select 'User_Updated',                                'Account details updated successfully for user %1'
union select 'UserAlreadyExists',                           'Given UserName already exists'
union select 'UserPasswordPolicyNotDefined',                'Password Policy should be defined for the user'

union select 'User_Add_Successful',                         'User added successfully'
union select 'User_Add_NoneUpdated',                        'User was not added'
union select 'User_Edit_Successful',                        'User updated successfully'
union select 'User_Edit_NoneUpdated',                       'User was not updated'

union select 'User_SetupFilters_Successful',                'Filters updated for %1 users successfully'
union select 'User_SetupFilters_ValuesRequired',            'Filter values should be given to setup'

union select 'User_AccountLock_NoneUpdated',                 'Note: None of the selected user accounts are locked'
union select 'User_AccountLock_SomeUpdated',                 'Note: %RecordsUpdated of %TotalRecords selected user accounts have been locked successfully'
union select 'User_AccountLock_Successful',                  'Note: All selected user accounts (%RecordsUpdated) have been locked successfully'

union select 'User_AccountUnLock_NoneUpdated',               'Note: None of the selected user accounts are unlocked'
union select 'User_AccountUnLock_SomeUpdated',               'Note: %RecordsUpdated of %TotalRecords selected user accounts have been unlocked successfully'
union select 'User_AccountUnLock_Successful',                'Note: All selected user accounts (%RecordsUpdated) have been unlocked successfully'

/*------------------------------------------------------------------------------*/
/* Password Policy */
/*------------------------------------------------------------------------------*/
union select 'PwdPolicy_PasswordNotAllowed',                'Simple passwords are not allowed'
union select 'PwdPolicy_LengthGreaterThan',                 'Password must be atleast %1 characters long'
union select 'PwdPolicy_MustHaveLowerCase',                 'Password should have %1 or more lower case letters'
union select 'PwdPolicy_MustHaveUpperCase',                 'Password should have %1 or more upper case letters'
union select 'PwdPolicy_MustHaveNumber',                    'Password should have %1 or more numbers'
union select 'PwdPolicy_MustHaveSymbol',                    'Password should have %1 or more special characters or symbols'
union select 'PwdPolicy_CannotReuse',                       'Password has already been used in the past and cannot be reused'
union select 'PwdPolicy_TooManyRepeats',                    'Same Password used too many times, try different password'

/*------------------------------------------------------------------------------*/
/* Contacts Module */
/*------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------*/
/* Contacts */
/*------------------------------------------------------------------------------*/
union select 'ContactNameIsInvalid',                        'Invalid ContactName'
union select 'BusinessUnitIsInvalid',                       'Invalid BusinessUnit'
union select 'BusinessUnitIsRequired',                      'BusinessUnit is required'

/*------------------------------------------------------------------------------*/
/*Customers Entity*/
/*------------------------------------------------------------------------------*/
union select 'CustomerIdIsInvalid',                         'Invalid CustomerId'
union select 'CustomerNameIsInvalid',                       'Invalid CustomerName'

/*------------------------------------------------------------------------------*/
/*Vendors Entity*/
/*------------------------------------------------------------------------------*/
union select 'VendorIdIsInvalid',                           'Invalid VendorId'
union select 'VendorNameIsInvalid',                         'Invalid VendorName'
union select 'Import_VendorIsRequired',                     'Vendor is required'

/*----------------------------------------------------------------------------*/
/* Generic */
/*----------------------------------------------------------------------------*/
union select 'NextSeqNoMissing',                            'Unable to get the next sequence number, Please contact system administrator'
union select 'NextSeqNoMissing_LPN',                        'Unable to get the next sequence number for %1 type LPNs, Please contact system administrator'
union select 'ConfigurationsMissing',                       'Configuration settings are missing or invalid, Please contact system administrator'
union select 'UIAction_NoSelectedEntities',                 'Failed to identify Records to process from Inputs!!!'
union select 'UIAction_ExecuteInBackGround',                'Your request to %1 will be processed in the background'

/*------------------------------------------------------------------------------*/
/* Core Module */
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Lookups Entity */
/*------------------------------------------------------------------------------*/
union select 'LookUp_CategoryIsInvalid',                    'Invalid LookUp Category'
union select 'LookUp_CategoryIsRequired',                   'LookUp category is required and cannot be blank'
union select 'LookUp_CodeIsInvalid',                        'Invalid LookUp Code'
union select 'LookUp_CodeIsRequired',                       'LookUp Code is required and cannot be blank'
union select 'LookUp_DescriptionIsRequired',                'Invalid LookUp Description'

union select 'LookUp_Created',                              'New list item %2 added successfully for %1'
union select 'LookUp_Updated',                              'List item details updated successfully for %1'
union select 'LookUp_AlreadyExists',                        'Given list item already exists, please update it instead'

union select 'LookUps_Edit_NoneUpdated',                    'Note: None of the selected list items are modified'
union select 'LookUps_Edit_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected list items have been modified'
union select 'LookUps_Edit_Successful',                     'Note: All selected list items (%RecordsUpdated) have been modified successfully'

union select 'LookUps_Add_Successful',                      'Note: The given list item has been created successfully'

/*------------------------------------------------------------------------------*/
/* Contacts Entity */
/*------------------------------------------------------------------------------*/
union select 'Contacts_Add_Successful',                     'New Contact created successfully'

union select 'Contacts_Edit_NoneUpdated',                   'Note: None of the selected contacts are modified'
union select 'Contacts_Edit_SomeUpdated',                   'Note: %RecordsUpdated of %TotalRecords selected contacts have been modified'
union select 'Contacts_Edit_Successful',                    'Note: All selected contatcs (%RecordsUpdated) have been modified successfully'


/*------------------------------------------------------------------------------*/
/* Controls Entity */
/*------------------------------------------------------------------------------*/
union select 'ControlCategoryIsInvalid',                    'Invalid Control Category'
union select 'ControlCodeIsInvalid',                        'Invalid Control Code'
union select 'DescriptionIsInvalid',                        'Invalid Description'
union select 'DataTypeIsInvalid',                           'Invalid DataType'
union select 'DataTypeDoesNotExist',                        'DataType does not exist'
union select 'ControlValueIsInvalid',                       'Invalid ControlValue'
union select 'Control_Updated',                             'Control detail updated successfully'

/*------------------------------------------------------------------------------*/
/* CartonTypes Action Messages */
/*-------------------------------------------------------------------------------*/
union select 'CartonTypes_Add_Successful',                  'New Carton Type created successfully'
union select 'CartonTypes_Edit_Successful',                 'Carton Type details updated successfully'
union select 'CartonDescriptionIsRequired',                 'Carton Type Description is required and should not be empty'
union select 'CartonTypeAlreadyExists',                     'Carton Type already exists and should be unique'
union select 'InvalidRecordId',                             'Carton Type not identified/valid'

/*------------------------------------------------------------------------------*/
/* CartonGroups Action Messages */
/*-------------------------------------------------------------------------------*/
union select 'CartonGroups_Add_Successful',                 'New Carton Group added successfully'
union select 'CartonGroups_Edit_Successful',                'Carton Group details updated successfully'
union select 'CartonGroupsCartonType_Add_Successful',       'Added new Carton Type to group successfully'
union select 'CartonGroupsCartonType_Edit_NoneUpdated',     'Note: None of the selected Carton types in the Group are updated'
union select 'CartonGroupsCartonType_Edit_SomeUpdated',     'Note: %RecordsUpdated of %TotalRecords selected CartonTypes in Group are updated'
union select 'CartonGroupsCartonType_Edit_Successful',      'Note: Selected CartonTypes in Group (%RecordsUpdated) have been updated successfully'
union select 'CartonGroupsCartonType_Delete_Successful',    'Note: All selected carton types (%RecordsUpdated) have been deleted successfully from their respective groups'

/*-------------------------------------------------------------------------------*/
/* Mapping Actions messages */
/*------------------------------------------------------------------------------*/
union select 'Mapping_Add_Successful',                      'New mapping created successfully'

union select 'Mapping_Edit_NoneUpdated',                    'Note: None of the selected mappings are updated'
union select 'Mapping_Edit_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected Mappings are updated'
union select 'Mapping_Edit_Successful',                     'Note: All selected mappings (%RecordsUpdated) have been updated successfully'

union select 'Mapping_Delete_NoneUpdated',                  'Note: None of the selected mappings are deleted'
union select 'Mapping_Delete_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected Mappings are deleted'
union select 'Mapping_Delete_Successful',                   'Note: All selected mappings (%RecordsUpdated) have been deleted successfully'

/*------------------------------------------------------------------------------*/
/* Selection Actions Messages */
/*------------------------------------------------------------------------------*/
union select 'Selections_Remove_NoneUpdated',               'Note: None of the selected Selections are deleted'
union select 'Selections_Remove_SomeUpdated',               'Note: %RecordsUpdated of %TotalRecords selected Selections are deleted'
union select 'Selections_Remove_Successful',                'Note: All selected Selections (%RecordsUpdated) have been deleted successfully'

/*-------------------------------------------------------------------------------*/
/* ShipVia Add or Edit  Actions messages */
/*------------------------------------------------------------------------------*/
union select 'ShipViaAlreadyExists',                        'Ship Vias already exists with that name'
union select 'ShipViaDoesNotExist',                         'Ship Vias does not exist to Edit'
union select 'ShipViaDescIsrequired',                       'Ship Vias Description is required'
union select 'CarrierIsRequired',                           'Carrier (LTL or Generic) is required to be specified for a Ship Via'
union select 'ShipVia_LTLCarrierIsInvalid',                 'Carrier can only be LTL or Generic for a Ship Via'

union select 'ShipVias_LTLCarrierAdd_Successful',           'New LTL Carrier Ship Via created successfully'

union select 'ShipVias_LTLCarrierEdit_NoneUpdated',         'Note: None of the selected Ship Vias are updated'
union select 'ShipVias_LTLCarrierEdit_SomeUpdated',         'Note: %RecordsUpdated of %TotalRecords selected Ship Vias are updated'
union select 'ShipVias_LTLCarrierEdit_Successful',          'Note: All selected Ship Vias (%RecordsUpdated) have been updated successfully'

/*------------------------------------------------------------------------------*/
/* Inventory  Module */
/*------------------------------------------------------------------------------*/
union select 'Work/SalesOrdersNotYetProcessed',             'There are Work/Sales orders which are not yet processed'

/*------------------------------------------------------------------------------*/
/* SKUs Entity */
/*------------------------------------------------------------------------------*/
union select 'SKUIsInvalid',                                'Invalid SKU'
union select 'SKUIsRequired',                               'SKU is required'
union select 'SKUAlreadyExists',                            'SKU already exists'
union select 'SKUDescriptionIsInvalid',                     'Invalid SKUDescription'
union select 'SKUUoMMismatch',                              'SKU UoM Mismatch'
union select 'ProdCategoryIsInvalid',                       'Invalid ProductCategory'
union select 'ProdSubCategoryIsInvalid',                    'Invalid ProductSubCategory'
union select 'SKU-LocationsPAZoneMismatch',                 'SKU Location and Putaway zone mismatch'
union select 'SKUIsInactive',                               'SKU is inactive'
union select 'UPCAssociatedWithOtherSKU',                   'Given UPC is already associated with SKU %1'
union select 'UPCAssociatedWithSameSKU',                    'Given UPC is already associated with the same SKU %1'

union select 'SKU_ModifySKU_NoneUpdated',                   'Note: None of the selected SKUs are modified'
union select 'SKU_ModifySKU_SomeUpdated',                   'Note: %RecordsUpdated of %TotalRecords selected SKUs are modified'
union select 'SKU_ModifySKU_Successful',                    'Note: All selected SKUs (%RecordsUpdated) have been modified successfully'

union select 'SKU_ModifySKUClasses_NoneUpdated',            'Note: SKU classes are not modified on any of the selected SKUs'
union select 'SKU_ModifySKUClasses_SomeUpdated',            'Note: SKU classes modified on %RecordsUpdated of the %TotalRecords selected SKUs'
union select 'SKU_ModifySKUClasses_Successful',             'Note: SKU classes modified successfully on all selected SKUs (%RecordsUpdated)'

union select 'SKU_ModifyAliases_NoneUpdated',               'Note: SKU aliases are not modified on any of the selected SKUs'
union select 'SKU_ModifyAliases_SomeUpdated',               'Note: SKU aliases modified on %RecordsUpdated of the %TotalRecords selected SKUs'
union select 'SKU_ModifyAliases_Successful',                'Note: SKU aliases modified successfully on all selected SKUs (%RecordsUpdated)'

union select 'SKU_ModifySKUDimensions_NoneUpdated',         'Note: SKU dimensions are not modified on any of the selected SKUs'
union select 'SKU_ModifySKUDimensions_SomeUpdated',         'Note: SKU dimensions modified on %RecordsUpdated of the %TotalRecords selected SKUs'
union select 'SKU_ModifySKUDimensions_Successful',          'Note: SKU dimensions modified successfully on all selected SKUs (%RecordsUpdated)'

union select 'SKU_ModifyCommercialInfo_NoneUpdated',        'Note: SKU Commercial Info not modified on any of the selected SKUs'
union select 'SKU_ModifyCommercialInfo_SomeUpdated',        'Note: SKU Commercial Info modified on %RecordsUpdated of the %TotalRecords selected SKUs'
union select 'SKU_ModifyCommercialInfo_Successful',         'Note: SKU Commercial Info modified successfully on all selected SKUs (%RecordsUpdated)'

union select 'SKU_ModifyPackConfigurations_NoneUpdated',    'Note: SKU pack configurations not modified on any of the selected SKUs'
union select 'SKU_ModifyPackConfigurations_SomeUpdated',    'Note: SKU pack configurations modified on %RecordsUpdated of the %TotalRecords selected SKUs'
union select 'SKU_ModifyPackConfigurations_Successful',     'Note: SKU pack configurations modified successfullyon all selected SKUs (%RecordsUpdated)'

union select 'SKU_UPCAdded_Successful',                     'Note: UPC (%1) has been added to SKU (%2) successfully'
union select 'SKU_UPCRemoved_Successful',                   'Note: UPC (%1) has been removed from SKU (%2) successfully'

union select 'SKUDimensionsRequired',                       'Unit Dimensions are not defined for the SKU'
union select 'SKUCubeWeightRequired',                       'Unit Weight/Volume are not defined for the SKU'
union select 'SKUPackInfoRequired',                         'Case Pack/Inner Packs are not defined for the SKU'
union select 'PalletTieHighRequired',                       'Pallet Tie/High info is missing on the SKU'
union select 'UPCRequired',                                 'UPC  info is missing on the SKU'
union select 'CaseUPCRequired',                             'Case UPC  info is missing on the SKU'
union select 'SKU_ModifyCartonGroup_NoneUpdated',           'Note: None of the selected SKUs'' carton group are modified'
union select 'SKU_ModifyCartonGroup_SomeUpdated',           'Note: %RecordsUpdated of %TotalRecords selected SKUs'' carton group are modified'
union select 'SKU_ModifyCartonGroup_Successful',            'Note: All selected SKUs (%RecordsUpdated) carton group have been modified successfully'

/*------------------------------------------------------------------------------*/
/* SKUPrePacks Entity */
/*------------------------------------------------------------------------------*/
union select 'MasterSKUIsInvalid',                          'Invalid MasterSKU'
union select 'MasterSKUDoesNotExist',                       'MasterSKU does not exist'
union select 'ComponentSKUIsInvalid',                       'Invalid ComponentSKU'
union select 'ComponentSKUDoesNotExist',                    'ComponentSKU does not exist'
union select 'ComponentQtyIsNullOrZero',                    'Enter a ComponentQty other than zero'
union select 'PrePackSKUQtyShouldBeOne',                    'LPN quantity for a prepack SKU should be one'
union select 'Import_BusinessUnitMismatch',                 'Business unit mismatch'
union select 'Import_SKUPrePackDetailAlreadyExists',        'SKUPrePack detail already exists'
union select 'Import_SKUPrepackDetailDoesNotExist',         'SKUPrepack detail does not exist'
union select 'Import_SKUPrepackDetailDoesNotExist',         'SKUPrepack detail does not exist'

/*------------------------------------------------------------------------------*/
/* LPNDetails Entity */
/*------------------------------------------------------------------------------*/
union select 'LPNDoesNotExist',                             'LPN does not exist'
union select 'LPNOrLocationDoesNotExist',                   'LPN or Location does not exist'
union select 'LPNLineIsInvalid',                            'Invalid LPN Line'
union select 'LPNLineAlreadyExists',                        'LPN Line already exists'
union select 'SKUDoesNotExist',                             'SKU does not exist'
union select 'QuantityCantBeZeroOrNull',                    'Enter a Quantity greater than zero'
union select 'ReceiptDetailDoesNotExist',                   'Receipt Detail does not exist'
union select 'OrderDetailDoesNotExist',                     'OrderDetail does not exist'

/*------------------------------------------------------------------------------*/
/* LPNs Entity */
/*------------------------------------------------------------------------------*/
union select 'LPNIsInvalid',                                'Invalid LPN'
union select 'LPNTypeIsInvalid',                            'Invalid LPN Type'
union select 'LPNAlreadyExists',                            'LPN already exists'
union select 'LPNIsEmpty',                                  'Scanned LPN is empty'
union select 'ReceiptDoesNotExist',                         'Receipt does not exist'
union select 'OrderDoesNotExist',                           'Order does not exist'
union select 'NumLPNsToCreateNotDefined',                   'Number of LPNs to create is not defined'
union select 'LPNTypeDoesNotExist',                         'LPNType does not exist'
union select 'NotAShippableLPNType',                        'Invalid LPN, Can only ship Packed Cartons'
union select 'LPNTypeIsRequired',                           'LPNType is required'
union select 'CannotMoveLPNintoPickLane',                   'Cannot Move LPN into a Picklane location'
union select 'InvalidStorageTypeToMoveLPN',                 'Cannot Move LPN into location not setup for LPNs'
union select 'DestWarehouseIsRequired',                     'Destination is required'
union select 'DestWarehouseIsInvalid',                      'Invalid Destination Warehouse'
union select 'OwnershipMismatch',                           'Ownership of LPN or Pallet and Location do not match, cannot put LPN or Pallet into this location'
union select 'WarehouseMismatch',                           'Warehouse of LPN or Pallet and Location do not match, cannot put LPN or Pallet into this location'
union select 'MultiSKULPNsNotAllowed',                      'Cannot have multiple SKU LPNs in Inventory and the LPN has another SKU'
/* LPN Carton Type modify */
union select 'CartonTypeIsRequired',                        'CartonType is required'
union select 'CartonTypeIsInvalid',                         'Invalid Carton Type'
union select 'CartonTypeIsInactive',                        'Selected Carton Type is not active'

union select 'CannotAddMoreThanOneSKUToLPN',                'Cannot add more than one SKU to this LPN'
union select 'LPNVoided',                                   'Carton Voided!!!'
union select 'LPNAlreadyShipped',                           'Carton already Shipped!!!'
union select 'LPNNotOnAnyOrder',                            'Carton should be on a PickTicket to Ship'
union select 'LPNNotReadyToShip',                           'Carton should be Packed to Ship'
union select 'LPNTypeModifiedSuccessfully',                 'LPN Type modified successfully for the selected LPNs'
union select 'UnsupportedAction',                           'Unsupported Action'
union select 'LPNTypeIsInactive',                           'LPN Type Is Inactive'
union select 'LPNInnerPacksAndQtyMismatch',                 'Quantity should be in cases or multiples of units per case'

union select 'NoLPNsModified',                              'Note: None of the selected LPNs are modified'
union select 'SomeLPNsNotModified',                         'Note: Some of the selected LPNs have not been modified'

union select 'CreateLPNs_OwnershipRequired',                'Ownership is required'
union select 'CreateLPNs_WarehouseRequired',                'Warehouse is required'
union select 'CreateLPNs_InvalidNumLPNs',                   'Number of LPNs to create is not defined'
union select 'CreateLPNs_InvalidNumLPNsPerPallet',          'Number of LPNs Per Pallet to create is not defined'
union select 'CreateLPNs_CannotCreateLogicalLPNs',          'Invalid LPN Type, Can not create Logical LPNs'
union select 'CreateLPNs_SKUDuplicated',                    'SKU is repeated in the details'
union select 'CreateLPNs_NoEnoughInventoryToDeduct',        'Not enough inventory to deduct from picklanes'
union select 'CreateLPNs_NoInventoryToCreateKits',          'No picked component inventory to create Kits'
union select 'CreateLPNs_NotEnoughInventoryToCreateKits',   'Picked component inventory is sufficient to create only %1 Kits'
union select 'CreateLPNs_ShortInInventoryToCreateLPNs',     'Short of Inventory to create KITs. Max KITs to create: %1'
union select 'CreateLPNs_UnitsPerInnerPackNotSame',         'Units per Case is not same on selected SKUs, cannot create Inventory'
union select 'CreateLPNs_InnerPacksPerLPNRequired',         'Cannot create Inventory for SKU %1, Case per LPN is required'
union select 'CreateLPNs_UnitsPerInnerPackRequired',        'Cannot create Inventory for SKU %1, Units per Case is required'
union select 'CreateLPNs_UnitsPerLPNRequired',              'Cannot create Inventory for SKU %1, Units Per LPN is required'
union select 'CreateLPNs_HasMixedUoMSKUs',                  'Note: Multi-SKU LPN can only be created with all of the same UoM'

union select 'LPN_Void_NoneUpdated',                        'Note: None of the selected LPNs (%TotalRecords) are voided'
union select 'LPN_Void_SomeUpdated',                        'Note: %RecordsUpdated of %TotalRecords selected LPNs have been voided'
union select 'LPN_Void_Successful',                         'Note: All Selected LPNs (%RecordsUpdated) voided successfully'

union select 'QCInbound_SelectLPNs_NoneUpdated',            'Note: None of the LPNs (%TotalRecords) selected for QC now (%1 LPNs selected earlier)'
union select 'QCInbound_SelectLPNs_SomeUpdated',            'Note: %RecordsUpdated of %TotalRecords LPNs are selected for QC now (%1 LPNs selected earlier)'
union select 'QCInbound_SelectLPNs_Successful',             'Note: All LPNs are selected (%RecordsUpdated) for QC'

union select 'LPN_QCHold_NoneUpdated',                      'Note: None of the selected LPNs (%TotalRecords) are updated'
union select 'LPN_QCHold_SomeUpdated',                      'Note: %RecordsUpdated of %TotalRecords selected LPNs have been updated'
union select 'LPN_QCHold_Successful',                       'Note: All Selected LPNs (%RecordsUpdated) updated successfully'

union select 'LPN_QCRelease_NoneUpdated',                   'Note: None of the selected LPNs (%TotalRecords) are Released '
union select 'LPN_QCRelease_SomeUpdated',                   'Note: %RecordsUpdated of %TotalRecords selected LPNs have been Released'
union select 'LPN_QCRelease_Successful',                    'Note: All Selected LPNs (%RecordsUpdated) Released successfully'
union select 'LPNVoid_ReasonCodeRequired',                  'Reason code required to void LPN'

union select 'LPNOwnerIsRequired',                          'LPN Owner is required'
union select 'InvalidOwner',                                'Invalid Owner'
union select 'CannotChangeAnLPNWhichHasMultipleSKUs',       'Cannot change SKU on an LPN that has multiple SKUs in it'

union select 'LPNs_ModifyLPNType_NoneUpdated',              'Note: None of the selected LPN are modified with new LPN Type'
union select 'LPNs_ModifyLPNType_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected LPNs have been modified'
union select 'LPNs_ModifyLPNType_Successful',               'Note: All selected LPNs (%RecordsUpdated) have been modified successfully'
union select 'LPNs_ModifyLPNType_SameLPNType',              'LPN %1 is already of Type "%2" and hence was not updated'

union select 'LPNs_ModifyCartonDetails_NoneUpdated',        'Note: None of the selected LPN(s) are modified with new Carton Type/Weight'
union select 'LPNs_ModifyCartonDetails_SomeUpdated',        'Note: %RecordsUpdated of %TotalRecords selected LPN(s) have been modified'
union select 'LPNs_ModifyCartonDetails_Successful',         'Note: All selected LPN(s) (%RecordsUpdated) have been modified successfully'

union select 'LPNs_ChangeOwnership_NoneUpdated',            'Note: None of the selected LPNs are changed to selected Owner'
union select 'LPNs_ChangeOwnership_SomeUpdated',            'Note: %RecordsUpdated of %TotalRecords selected LPNs have been modified with selected Owner'
union select 'LPNs_ChangeOwnership_Successful',             'Note: All selected LPNs (%RecordsUpdated) have been modified with selected Owner'
union select 'LPNs_ChangeOwnership_NotPutaway',             'LPN %1 is in %2 status and Ownership can only be changed on Putaway LPNs'
union select 'LPNs_ChangeOwnership_SameOwner',              'LPN %1 is already for owner %3 and hence was not updated'

union select 'LPN_ModifyWarehouse_NoneUpdated',             'Note: None of the selected LPNs are changed to selected Warehouse'
union select 'LPN_ModifyWarehouse_SomeUpdated',             'Note: %RecordsUpdated of %TotalRecords selected LPNs have been modified with selected Warehouse'
union select 'LPN_ModifyWarehouse_Successful',              'Note: All selected LPNs (%RecordsUpdated) have been modified with selected Warehouse'

union select 'LPNs_ChangeSKU_NoneUpdated',                  'Note: None of the selected LPNs are modified with selected SKU'
union select 'LPNs_ChangeSKU_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected LPNs have been modified with selected SKU'
union select 'LPNs_ChangeSKU_Successful',                   'Note: All selected LPNs (%RecordsUpdated) have been modified successfully with selected SKU'

union select 'LPNs_ChangeSKU_MultiSKULPN',                  'Cannot change SKU on LPN %1 as it has multiple SKUs in it.'
union select 'LPNs_ChangeSKU_ReservedLPN',                  'Cannot change SKU on LPN %1 as the quantity is reserved'
union select 'LPNs_ChangeSKU_HasDirectedQty',               'Cannot change SKU on Picklane %1 as it has quantity being directed to it'
union select 'LPNs_ChangeSKU_InvalidStatus',                'Cannot change SKU on LPN %1 as it is in %2 status'

union select 'LPNs_Palletize_LPNsAlreadyOnPallet',          '%1 out of %2 LPNs were not palletized because they were already on existing pallets'
union select 'LPNs_Palletize_NoneUpdated',                  'None of the selected LPNs have been Palletized'
union select 'LPNs_Palletize_SomeUpdated',                  'Palletized %RecordsUpdated of %TotalRecords selected LPNs onto %1 Pallets %2 to %3'
union select 'LPNs_Palletize_Successful',                   'Palletized all selected LPNs (%RecordsUpdated) onto %1 Pallets %2 to %3'

union select 'LPNDePalletized_LPNsNotOnPallet',             '%1 out of %2 LPNs were not De-Palletized because they not on any pallets'
union select 'LPNDePalletized_NoneUpdated',                 'None of the selected LPNs have been De-Palletized'
union select 'LPNDePalletized_SomeUpdated',                 '%RecordsUpdated of %TotalRecords selected LPNs have been De-Palletized'
union select 'LPNDePalletized_Successful',                  'All selected LPNs (%RecordsUpdated) have been De-Palletized'

union select 'LPN_UnallocateLPNs_NoneUpdated',              'Note: None of the selected LPNs are Unallocated'
union select 'LPN_UnallocateLPNs_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected LPNs have been Unallocated, and its related pallets if any'
union select 'LPN_UnallocateLPNs_Successful',               'Note: All selected LPNs (%RecordsUpdated) have been Unallocated, and its related pallets if any'

union select 'LPNUnpack_LPNsMustBeOfSameOrder',             'Please select LPNs of same order'
union select 'LPNUnpack_PalletIsNotEmptyOrNotRelated',      'Please select an empty pallet or a pallet related to order'
union select 'LPN_UnpackLPNs_NoneUpdated',                  'Note: None of the selected LPNs are Unpacked'
union select 'LPN_UnpackLPNs_SomeUpdated',                  'Note: %1 of %2 selected LPNs have been Unpacked'
union select 'LPN_UnpackLPNs_Successful',                   'Note: All selected LPNs (%1) have been Unpacked'

union select 'LPN_CreateInvLPNs_InvalidPallet',             'Invalid Pallet'
union select 'LPN_CreateInvLPNs_InvalidPalletStatus',       'Invalid Pallet Status'
union select 'LPN_CreateInvLPNs_Successful1',               'Successfully created LPN %2'
union select 'LPN_CreateInvLPNs_Successful2',               'Successfully created %1 LPNs from %2 to %3.'
union select 'LPNAddedSuccessfully',                        'LPN added successfully'

union select 'LPN_UpdateInvExpDate_Successful',             'Selected LPNs(%RecordsUpdated) updated with new Expiry Date'
union select 'LPN_UpdateInvExpDate_NoneUpdated',            'None of the selected LPNs(%TotalRecords) updated'
union select 'LPN_UpdateInvExpDate_SomeUpdated',            '%RecordsUpdated of %TotalRecords selected LPNs updated'

union select 'CannotAddStagedLPNToReserveOrBulkLocation',
                                                            'Cannot add staged LPNs to Pallets in Reserve or Bulk Location'
union select 'LPNAdjust_InvalidStatus',                     'Cannot adjust quantity of an LPN in %1 status'
union select 'LPNAdjust_EmptyLPN',                          'Cannot adjust quantity of an empty LPN, please use Add SKU functionality instead'
union select 'LPNAdjust_CannotAdjustAllocatedLPN',          'Cannot adjust an allocated LPN'
union select 'LPNAdjust_CannotAdjustReplenishLPN',          'Cannot adjust a replenish LPN'
union select 'LPNAdjust_ReferenceCannotbeEmpty',            'Reference information is required for the selected reason code'
union select 'LPNAdjust_NoNegativeInventory',               'Adjusting the LPN is leading to negative inventory and hence this operation cannot be completed'
union select 'LPNAdjust_CannotAdjustReservedQty',           'Cannot adjust LPN. %1 units in the LPN is reserved for orders'
union select 'LPNAdjust_CannotAdjustOverShipQty',           'Cannot increment quantity as this would cause over shipping the order, max quantity to adjust is %1 units'

union select 'LPNIsNotValidForAnyOperation',                'LPN is in %1 status and no operations can be performed on it'
union select 'LogicalLPN_InvalidOperation',                 'Scanned a picklane, please scan an LPN to proceed or use Location operations instead'
union select 'CartLPN_InvalidOperation',                    'Scanned a position on the cart which cannot be moved. Move the Cart instead'

union select 'LPN_RemoveZeroQtySKUs_NoneUpdated',           'Note: None of the selected SKUs have been Removed'
union select 'LPN_RemoveZeroQtySKUs_SomeUpdated',           'Note: (%RecordsUpdated) of (%TotalRecords) selected SKUs are Removed'
union select 'LPN_RemoveZeroQtySKUs_Successful',            'Note: All selected SKUs (%TotalRecords) have been removed successfully'
union select 'Location_RemoveSKUs_InvalidLPNType',          'Selected an invalid LPN. SKU can only be removed from a Picklane Location, so choose LPNs for Picklanes only'
union select 'Location_RemoveSKUs_NonZeroQtySKUs',          'Location %2 have inventory for SKU %1 and cannot be removed until the inventory is depleted from the Location'

union select 'LPN_Reverse-Receipt_NoneUpdated',             'Note: None of the selected LPNs (%RecordsUpdated) have been unreceived'
union select 'LPN_Reverse-Receipt_SomeUpdated',             'Note: %RecordsUpdated of %TotalRecords selected LPNs are unreceived'
union select 'LPN_Reverse-Receipt_Successful',              'Note: All selected LPNs (%RecordsUpdated) have been unreceived successfully'

union select 'LPN_ModifyLPNs_NoneUpdated',                  'Note: None of the selected LPNs (%RecordsUpdated) have been updated'
union select 'LPN_ModifyLPNs_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected LPNs are updated'
union select 'LPN_ModifyLPNs_Successful',                   'Note: All selected LPNs (%RecordsUpdated) have been updated successfully'
union select 'LPN_ModifyLPNs_LPNIsReserved',                'LPN %1 is reserved, cannot update Inventory class on Reserved LPNs'
union select 'LPNAdjustment',                               'LPN %1 quantity adjusted to %2 units of SKU %3 successfully'

union select 'MoveLPNs_LocationUndefined',                      'No Location specified to move LPN %1'
union select 'MoveLPNs_LPNStatusInvalid',                       'LPN %1 status is invalid to move'
union select 'MoveLPNs_ReceivedLPNsCanBeMovedToRBSDCLocsOnly',  'Received LPN %1 can only be moved to Reserve, Bulk, Staging, Dock & Conveyer locations'
union select 'MoveLPNs_PickedLPNsCanBeMovedToSDCLocsOnly',      'Picked, Packed or Staged LPN %1 can only be moved to Staging, Dock & Conveyer locations'
union select 'MoveLPNs_AllocatedLPNsCannotBeMoved',             'Allocated LPN %1 cannot be moved as there may be pick tasks assigned to them'
union select 'MoveLPNs_LogicalLPNsCannotBeMoved',               '%1 is a Picklane Location and cannot be moved'
union select 'MoveLPNs_OneOrMoreLPNsOnPalletDoesNotConform',    'One or more LPNs on pallet %2 does not conform rules to move LPN %1'
union select 'MoveLPNs_ReservedLPNsToOrderShipFromWHOnly',      'Reserved LPN %1 can only be moved to Warehouse %2 which is where Order is being shipped from'

union select 'LPNs_BulkMove_NoneUpdated',                   'None of the selected LPNs have been moved'
union select 'LPNs_BulkMove_SomeUpdated',                   '%RecordsUpdated of %TotalRecords selected LPNs have been moved successfully'
union select 'LPNs_BulkMove_Successful',                    'All selected LPNs (%RecordsUpdated) have been moved successfully'

union select 'LPNActivation_NoLPNsToActivate',              'No valid Ship cartons to activate. Please verify.'
union select 'LPNActivation_LPNTypeIsInvalid',              '%1 is not a Ship Carton to activate'
union select 'LPNActivation_InvalidLPNStatus',              'Ship Carton %1 is %2 and is invalid status to activate'
union select 'LPNActivation_WaveTypeIsInvalid',             'Ship Carton %1 belongs to invalid wave type to activate'
union select 'LPNActivation_NothingToActivate',             'Nothing to be activated against Ship Carton %1'
union select 'LPNActivation_AlreadyActivated',              'Ship Carton %1 Already activated'
union select 'LPNActivation_NotEnoughInventoryToDeduct',    'There is not enough inventory to activate selected Ship Cartons'
union select 'LPNActivation_InvShortToActivate',            'Short of %3 units of SKU %1 (%2; %4), Please reserve these units and try again'
union select 'LPNActivation_LPNInvalidOnhandStatus',        'Ship carton %1 may have been activated. Please verify'

union select 'LPNs_ActivateShipCartons_NoneUpdated',        'None of the selected Ship Cartons are activated'
union select 'LPNs_ActivateShipCartons_SomeUpdated',        '%RecordsUpdated of %TotalRecords selected Ship Cartons are activated'
union select 'LPNs_ActivateShipCartons_Successful',         'All selected Ship Cartons (%RecordsUpdated) activated successfully'

union select 'LPNInActivation_LPNTypeIsInvalid',            '%1 is not a Ship Carton to cancel'
union select 'LPNInActivation_InvalidLPNStatus',            '%1 is not a valid status Ship Carton to cancel'
union select 'LPNInActivation_WaveTypeIsInvalid',           '%1 does not belong to valid wave type to cancel'
union select 'LPNs_CancelShipCartons_NoneUpdated',          'None of the selected Ship Cartons are Canceled'
union select 'LPNs_CancelShipCartons_SomeUpdated',          '%RecordsUpdated of %TotalRecords selected Ship Cartons are Canceled'
union select 'LPNs_CancelShipCartons_Successful',           'All selected Ship Cartons (%RecordsUpdated) Canceled successfully'

union select 'LPNs_PrintPalletandLPNLabels_NoneUpdated',    'None of the LPNs and associated Pallet Labels are printed'
union select 'LPNs_PrintPalletandLPNLabels_SomeUpdated',    '%RecordsUpdated of %TotalRecords selected LPNs and associated Pallet Labels are printed'
union select 'LPNs_PrintPalletandLPNLabels_Successful',     'All selected LPNs(%RecordsUpdated) and associated Pallet Labels are printed'

union select 'CaptureTrackingNo_InvalidStatus',             'LPN is in %1 status and no operations can be performed on it'
union select 'CaptureTrackingNo_FreightSpecialCharsNotAllowed',
                                                            'Freight charge is required and cannot be special characters'
union select 'CaptureTrackingNo_FreightShouldBeNumeric',    'Freight charge should be a numeric value'
union select 'CaptureTrackingNo_Update_Successful',         'Tracking # %1 and FreightCharges %2 are updated successfully on LPN %3'

/* LPNs - set Pallet */
union select 'PickedLPN-InvalidPalletType',                 'Picked LPN can only be on Picking/Shipping Pallet/Cart'
union select 'ReceivedLPN-InvalidPalletType',               'Received LPN can only be placed on a Receiving or Empty Pallet'
union select 'LPNSetPallet_LoadMismatch',                   'Pallet and LPN belong to different Loads, LPN cannot be added to the Pallet'
union select 'LPNSetPallet_DiffOrders',                     'Pallet and LPN belong to different Orders, LPN cannot be added to the Pallet'
union select 'LPNSetPallet_NoMultipleSKUs',                 'Pallet and LPN are of different items, LPN cannot be added to the Pallet'

union select 'AdjAllocLPN_AdjQtyIsGreaterThanOrderedQty',
                                                 'LPN quantity cannot be greater than the Units Ordered'
union select 'AdjAllocLPN_LPNQtyMismatchWithUnitsPerCarton',
                                                 'LPN quantity mismatches with Order units per carton, Please unallocate the LPN and adjust the LPN'

/* LPNs - SplitLPN */
union select 'LPNSplit_FromLPNDetailIdRequired',            'LPN has multiple lines, please specify line to split quantity'
union select 'LPNSplit_IPsOrQuantityRequired',              'Cases or Quantity required to split the LPN'
union select 'LPNSplit_InvalidInnerPacksQuantity',          'Quantity should be multiples of Cases to split the LPN'
union select 'LPNSplit_InvalidUnitsPerPackage',             'Units per case on the detail is not matching with the IPs/Qty passed'
union select 'LPNSplit_QtyShouldBeInMultiplesOfIPs',        'Invalid Pallet entered/scanned'
union select 'LPNSplit_InvalidToLPN',                       'ToLPN is invalid to transfer the Cases/Qty'
union select 'LPNSplit_InvalidToLPNStatus',                 'To LPN should be New to transfer the Cases/Qty'

/*------------------------------------------------------------------------------*/
/* Pallets Entity*/
/*------------------------------------------------------------------------------*/
union select 'PalletIsInvalid',                             'Invalid Pallet entered/scanned'
union select 'PalletIsRequired',                            'Pallet is required field'
union select 'PalletDoesNotExist',                          'Pallet does not exist'
union select 'MultipleDestinedWarehouses',                  'LPNs on the Pallet are destined for multiple Warehouses and hence cannot be located'
union select 'PalletTypeIsLimitedOnlyToView',               'Selected Pallet Type can only be Viewed but cannot be Created.'
union select 'LPNAlreadyOnPallet',                          'Scanned LPN is already on the Pallet'
union select 'CannotMovePalletIntoPicklane',                'Cannot move pallet into picklane'
union select 'CannotMoveEmptyPallet',                       'Cannot move an empty pallet'
union select 'PalletsWarehouseMismatch',                    'Warehouse of Pallet and Location do not match, cannot put Pallet into this Location'
union select 'Pallet_LoginWarehouseMismatch',               'Cannot proceed the operation because Warehouse of Pallet and Login Warehouse do not match'

union select 'PalletsCreatedSuccessfully',                  'Successfully created Pallets (%1) from %2 to %3'
union select 'InvalidPalletFormat',                         'Invalid pallet format'

union select 'Pallet_ClearCartUser_NoneUpdated',            'Note: None of the selected Pallets (%RecordsUpdated) are cleared of Users'
union select 'Pallet_ClearCartUser_SomeUpdated',            'Note: %RecordsUpdated of %TotalRecords selected Pallets are cleared of users'
union select 'Pallet_ClearCartUser_Successful',             'Note: User is cleared successfully on all selected Pallets (%RecordsUpdated)'
union select 'Pallet_ClearCart_NoneUpdated',                'Note: None of the selected Cart(s) (%RecordsUpdated) are cleared'
union select 'Pallet_ClearCart_SomeUpdated',                'Note: %RecordsUpdated of %TotalRecords selected Cart(s) are cleared'
union select 'Pallet_ClearCart_Successful',                 'Note: All selected Cart(s) are cleared successfully'
union select 'ClearCart_CartPositionsHasPickedInventory',   'Cannot clear cart %1, cart positions has picked inventory'
/*------------------------------------------------------------------------------*/
/* Locations Entity */
/*------------------------------------------------------------------------------*/
union select 'LocationIsInvalid',                                   'Location is Invalid'
union select 'LocationDoesNotExist',                                'Location does not exist'
union select 'LocationAlreadyExists',                               'Location already exists'
union select 'LocationTypeIsInvalid',                               'Invalid LocationType'
union select 'StorageTypeIsInvalid',                                'Invalid StorageType'
union select 'InvalidStorageTypeToMovePallet',                      'Cannot Move Pallet into location not setup for Pallets'
union select 'LocationIsInactive',                                  'Location is inactive'
union select 'InvalidPutawayZone',                                  'PutawayZone is Invalid'
union select 'Location_CannotDeactivate',                           'Selected Location cannot be Deactivated'
union select 'Location_CannotDeleted',                              'Selected Location cannot be Deleted'
union select 'LocationTypeStorageTypeIsInvalid',                    'Location Type/Storage Type combination is invalid'
union select 'PicklaneStorageTypeIsInvalid',                        'Invalid StorageType for Picklane Location'
union select 'ReserveStorageTypeIsInvalid',                         'Invalid StorageType for Reserve Location'
union select 'BulkStorageTypeIsInvalid',                            'Invalid StorageType for Bulk Location'
union select 'StagingStorageTypeIsInvalid',                         'Invalid StorageType for Staging Location'
union select 'DockStorageTypeIsInvalid',                            'Invalid StorageType for Dock Location'
union select 'LocationDoesNotAllowMultipleSKUs',                    'Location does not allow multiple SKUs'
union select 'LocationClassIsRequired',                             'LocationClass is required'

union select 'CreateLocation',                                      'Location %1 created successfully'
union select 'UpdateLocation',                                      'Location %1 modified successfully'
union select 'CreateLocations_SpecialCharsNotAllowed',              'Only special chars - and * are allowed when creating Locations'

union select 'Location_ModifyPutawayZone_NoneUpdated',              'Note: None of the selected Locations are modified'
union select 'Location_ModifyPutawayZone_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected Locations have been modified'
union select 'Location_ModifyPutawayZone_Successful',               'Note: All selected Locations (%RecordsUpdated) have been modified successfully'
union select 'Locations_ModifyPutawayZone_SamePutawayZone',         'Location %1 is already in PutawayZone %2 and hence was not updated'

union select 'Location_ModifyPickZone_NoneUpdated',                 'Note: None of the selected Locations are modified'
union select 'Location_ModifyPickZone_SomeUpdated',                 'Note: %RecordsUpdated of %TotalRecords selected Locations are modified'
union select 'Location_ModifyPickZone_Successful',                  'Note: All selected Locations (%RecordsUpdated) have been modified successfully'
union select 'Locations_ModifyPickZone_SamePickZone',               'Location %1 is already in PickZone %2 and hence was not updated'

union select 'Location_Activate_NoneUpdated',                       'Note: None of the selected Locations are activated'
union select 'Location_Activate_SomeUpdated',                       'Note: %RecordsUpdated of %TotalRecords selected Locations are activated'
union select 'Location_Activate_Successful',                        'Note: %RecordsUpdated of %TotalRecords Location(s) activated successfully'

union select 'Location_Deactivate_NoneUpdated',                     'Note: None of the selected Locations are deactivated'
union select 'Location_Deactivate_SomeUpdated',                     'Note: %RecordsUpdated of %TotalRecords selected Locations are deactivated'
union select 'Location_Deactivate_Successful',                      'Note: %RecordsUpdated of %TotalRecords Location(s) deactivated successfully'

union select 'Locations_ChangeLocationStorageType_SomeUpdated',     'Note: %RecordsUpdated of %TotalRecords selected Locations are modified'
union select 'Locations_ChangeLocationStorageType_Successful',      'Note: All selected Locations (%RecordsUpdated) have been modified successfully'
union select 'Locations_ChangeLocationStorageType_NoneUpdated',     'Note: None of the selected Locations are modified'
union select 'ChangeLocationType_LocationsNotEmpty',                '%1 Locations were not updated as they are not empty'

union select 'Location_ModifyLocationType_SomeUpdated',             'Note: %RecordsUpdated of %TotalRecords selected Locations are modified'
union select 'Location_ModifyLocationType_Successful',              'Note: All selected Locations (%RecordsUpdated) have been modified successfully'
union select 'Location_ModifyLocationType_NoneUpdated',             'Note: None of the selected Locations are modified'
union select 'ModifyLocationType_LocationsNotEmpty',                '%1 Locations were not updated as they are not empty'

union select 'Location_DeleteLocation_NoneUpdated',                 'Note: None of the selected Locations are deleted'
union select 'Location_DeleteLocation_SomeUpdated',                 'Note: %RecordsUpdated of %TotalRecords selected Locations are deleted'
union select 'Location_DeleteLocation_Successful',                  'Note: %RecordsUpdated of %TotalRecords Location(s) deleted successfully'

union select 'LocDelete_AssociatedLPNs',                            '%1 Location was not deleted as there are LPNs associated with it'

union select 'Locations_ChangeProfile_NoneUpdated',                 'Note: None of the selected Locations are modified'
union select 'Locations_ChangeProfile_SomeUpdated',                 'Note: %RecordsUpdated of %TotalRecords selected Locations are modified'
union select 'Locations_ChangeProfile_Successful',                  'Note: All selected Locations (%RecordsUpdated) have been modified successfully'
union select 'Locations_ChangeLocationProfile_Successful',          'Note: %RecordsUpdated of %TotalRecords Location(s) changed successfully'

union select 'Location_UpdateAllowedOperations_NoneUpdated',        'Note: None of the selected Locations are updated'
union select 'Location_UpdateAllowedOperations_SomeUpdated',        'Note: %RecordsUpdated of %TotalRecords selected Locations are updated'
union select 'Location_UpdateAllowedOperations_Successful',         'Note: %RecordsUpdated of %TotalRecords Location(s) updated successfully'

union select 'Location_ModifyAttributes_NoneUpdated',               'Note: None of the selected Locations are updated'
union select 'Location_ModifyAttributes_SomeUpdated',               'Note: %RecordsUpdated of %TotalRecords selected Locations are updated'
union select 'Location_ModifyAttributes_Successful',                'Note: All selected Locations (%RecordsUpdated) have been modified successfully'
union select 'LocationModifyAttrs_AllowMultipleSKUsSame',           'Location %1 is already having Allow Multiple SKUs as %2 and hence was not updated'

/*------------------------------------------------------------------------------*/
/* Purchasing Module */
/*------------------------------------------------------------------------------*/

union select 'NotaReceivingPallet',                         'Pallet is not for receiving'
union select 'CannotReceiveToLocationType',                 'Can only Receive LPNs into Dock/Staging/Conveyor Locations'
union select 'NoValidASNLPNs',                              'No Valid ASN LPNs'
union select 'LPNNotAssociatedWithASN',                     'LPN not associated with ASN'
union select 'SKUDimensionsAreRequired',                    'Dimensions are required for the scanned SKU to receive'
union select 'CannotReceiveMultipleSKUsintoLPN',            'Cannot receive multiple SKUs into an LPN. This LPN already has another item in it'
union select 'CannotReceiveClosedRO',                       'Receipt is closed and cannot be received'
union select 'NotaReceivingLocation',                       'Can only receive to Dock/Staging or Picklane Locations'
union select 'NotAnASNReceivingLocation',                   'Can only receive to Dock or Staging or Intransit Locations'
union select 'Receipt_ReceiveSKUs_NoneUpdated',             'Note: None of the selected RODetails (%TotalRecords) are received'
union select 'Receipt_ReceiveSKUs_SomeUpdated',             'Note: %TotalRecords of %RecordsUpdated selected RODetails have been received'
union select 'Receipt_ReceiveSKUs_Successful',              'All Selected Details (%TotalRecords) received successfully'

/*------------------------------------------------------------------------------*/
/* Roles */
/*------------------------------------------------------------------------------*/
union select 'RoleNameAlreadyExists',                       'Role %1 already eixsts'
union select 'RoleisAssociatedwithusers',                   'Role %2 is associated with users and cannot be deleted'
union select 'RoleisAdded',                                 'Role %1 is added successfully'
union select 'RoleisEdited',                                'Role %1 is edited successfully'
union select 'RoleisDeleted',                               'Role %1 is deleted successfully'

/*------------------------------------------------------------------------------*/
/* Returns Entity */
/*------------------------------------------------------------------------------*/
union select 'InvalidTrackingNoOrPickTicket',               'Invalid Tracking Number Or PickTicket'
union select 'NotanLPNorPickTicket',                        'LPN or PickTicket does not exist'
union select 'OrderNotShipped',                             'Order was not shipped'
union select 'LPNNotShipped',                               'LPN was not Shipped'
union select 'CreateReturns_Successful',                    '%1 created successfully with LPNs %2 to %3'
union select 'CreateReturns_NotAValidOrderType',            'Not a valid order type to accept returns'
union select 'CreatedRMA_InvalidInputs',                    'Invalid Inputs'
union select 'CreatedRMA_LPNs_Successful',                  '%1 created successfully with the LPNs'
union select 'CreatedRMA_Totes_Successful',                 '%1 created successfully with the scanned Totes'

union select 'Returns_LPNTypeIsInvalid',                    'Scanned a LPN which is not a Carton or Tote. Can receive only to a Cartons or Totes'
union select 'Returns_LPNStatusIsInvalid',                  'Scanned a LPN which is not new/empty. Can receive only to an empty/new LPN'
union select 'Returns_LocationIsNotPicklane',               'Returns can only be received directly into a Picklane location and scanned Location is not a Picklane'
union select 'Returns_ReceivedSuccessfully',                'Received %1 successfully'
union select 'Returns_InvalidReceiptStatus',                'Return %1 is in %2 status and cannot be processed against anymore'
union select 'Returns_ScannedSKUIsNotAssociatedWithReceipt','SKU %1 is not associated with the return %2'
union select 'Returns_ExcessQtyNotAllowed',                 'Return authorized only for %1 units and cannot accept return for more units'

/*------------------------------------------------------------------------------*/
/* ReceiptHeader Entity */
/*------------------------------------------------------------------------------*/
union select 'ReceiptIsInvalid',                                     'Invalid Receipt'
union select 'ReceiptNumberIsInvalid',                               'Invalid Receipt number'
union select 'ReceiptTypeIsInvalid',                                 'Invalid Receipt type'
union select 'ReceiptTypeDoesNotExist',                              'ReceiptType does not exist'
union select 'VendorDoesNotExist',                                   'Vendor does not exist'
union select 'ReceiptHasMultipleCustPOsWithSameSKU',                 'Receipt has multiple CustPOs with same SKU'
union select 'CustPOCompletelyReceived',                             'CustPO completely received'
union select 'Receipts_PrepareForReceiving_ExecuteInBackGround',     'Your request to Prepare For Receiving will be processed in the background'

union select 'Receipts_PrepareForSorting_NoneUpdated',      'None of the selected Receipts (%TotalRecords) are processed for Sortation'
union select 'Receipts_PrepareForSorting_SomeUpdated',      '%RecordsUpdated of %TotalRecords selected Receipts are processed for Sortation'
union select 'Receipts_PrepareForSorting_Successful',       'All selected Receipts (%RecordsUpdated) are processed for Sortation'

union select 'Receipts_ActivateRouting_NoneUpdated',        'Routing is not activated for any of the selected Receipts (%RecordsUpdated) '
union select 'Receipts_ActivateRouting_SomeUpdated',        'Routing is activated for %RecordsUpdated of %TotalRecords selected Receipts'
union select 'Receipts_ActivateRouting_Successful',         'Routing is activated for all selected Receipts (%RecordsUpdated) '

union select 'Receipts_ActivateRouting_SomeRecordshaveRI',  'Note: %1 of %2 selected record(s) already have Active Routing Instructions'
union select 'Receipts_ActivateRouting_AllRecordshaveRI',   'Note: All selected record(s) already have active Routing Instructions'
union select 'Receipts_ActivateRouting_NoLPNstoActivateRI', 'There aren''t any Intransit & Palletized LPNs to activate routing'

union select 'Receipts_UseActivateRouting',                'Routing not activated. Please use ''Activate Routing'' action when needed'

union select 'Receipt_NoLPNsInTransit',                     'None of the LPNs are in InTransit to Palletize'

union select 'ReceiptIsNotPrepared',                        'Receipt is not ready to begin receiving. Please Prepare the Receipt Orders'

union select 'Receipt_ROClose_NoneUpdated',                 'Note: None of the selected Receipts (%TotalRecords) have been closed'
union select 'Receipt_ROClose_SomeUpdated',                 'Note: %RecordsUpdated of %TotalRecords selected Receipts are closed'
union select 'Receipt_ROClose_Successful',                  'Note: All selected Receipts (%RecordsUpdated) have been closed successfully'

union select 'Receipt_ROOpen_NoneUpdated',                  'Note: None of the selected Receipts (%TotalRecords) have been opened'
union select 'Receipt_ROOpen_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected Receipts are opened'
union select 'Receipt_ROOpen_Successful',                   'Note: All selected Receipts (%RecordsUpdated) have been opened successfully'

union select 'Receipts_ModifyOwnership_NoneUpdated',        'Note: None of the selected Receipts (%TotalRecords) are modified'
union select 'Receipts_ModifyOwnership_SomeUpdated',        'Note: %RecordsUpdated of %TotalRecords selected Receipts are modified'
union select 'Receipts_ModifyOwnership_Successful',         'Note: All selected Receipts (%RecordsUpdated) have been modified successfully'

union select 'Receipts_ChangeWarehouse_NoneUpdated',        'Note: None of the selected Receipts are changed to selected Warehouse'
union select 'Receipts_ChangeWarehouse_SomeUpdated',        'Note: %RecordsUpdated of %TotalRecords selected Receipts have been modified with Warehouse %1'
union select 'Receipts_ChangeWarehouse_Successful',         'Note: All selected Receipts (%RecordsUpdated) have been modified with Warehouse %1'
union select 'Receipts_ChangeWH_SameWarehouse',             'Receipt %1 is already for Warehouse %2 and hence was not updated'
union select 'Receipts_ChangeWH_InvalidStatus',             'Receipt %1 is in %2 status and the Warehouse cannot be changed now'

union select 'Receipts_ChangeArrivalInfo_NoneUpdated',      'Arrival Info update on selected Receipts was unsuccessful'
union select 'Receipts_ChangeArrivalInfo_SomeUpdated',      'Arrival Info updated on %RecordsUpdated of %TotalRecords selected Receipts successfully'
union select 'Receipts_ChangeArrivalInfo_Successful',       'Arrival Info on all selected Receipts (%RecordsUpdated) updated successfully'

/*------------------------------------------------------------------------------*/
/* ReceiptDetail Entity */
/*------------------------------------------------------------------------------*/
union select 'ReceiptDetailIsInvalid',                      'Invalid Receipt detail'
union select 'ReceiptLineIsInvalid',                        'Invalid Receipt line'

union select 'ReceiptDetails_Modify_NoneUpdated',           'Note: None of the Receipt Details have been modified'
union select 'ReceiptDetails_Modify_SomeUpdated',           'Note: %RecordsUpdated of %TotalRecords Receipt Details have been modified'
union select 'ReceiptDetails_Modify_Successful',            'Note: All selected (%TotalRecords) Receipt Details have been modified successfully'
union select 'ReceiptDetails_InvalidLabelCode',             'Some of details on the Receipt have an invalid or missing label code'

union select 'ReceiptDetails_PrepareForSorting_NoneUpdated','None of the selected Receipt Details (%TotalRecords) are processed for Sortation'
union select 'ReceiptDetails_PrepareForSorting_SomeUpdated','%RecordsUpdated of %TotalRecords selected Receipt Details are processed for Sortation'
union select 'ReceiptDetails_PrepareForSorting_Successful', 'All selected Receipt Details (%RecordsUpdated) are processed for Sortation'

union select 'ReceiptDetails_ActivateRouting_NoneUpdated',  'Routing is not activated for any of the selected Receipt Details (%RecordsUpdated) '
union select 'ReceiptDetails_ActivateRouting_SomeUpdated',  'Routing is activated for %RecordsUpdated of %TotalRecords selected Receipt Details'
union select 'ReceiptDetails_ActivateRouting_Successful',   'Routing is activated for all selected Receipt Details (%RecordsUpdated) '

/*------------------------------------------------------------------------------*/
/* Sales Module */
/*------------------------------------------------------------------------------*/
union select 'OrderStatusInvalidForClosing',                'Status of Order must be Picking or Picked or Packed or Staged to be closed'
union select 'OrderStatusInvalidForTranOrder',              'OrderStatus Invalid For Order Type Tranfer'
union select 'OrderStatusInvalidForE-ComOrder',             'OrderStatus Invalid For Order Type E-Commerce'
union select 'OrderAlreadyClosed',                          'Order already closed, cannot close it again'
union select 'OrderAlreadyCanceled',                        'Order already canceled, cannot cancel it again'
union select 'OrderToBeCanceled',                           'Nothing has been shipped for the Order, so cancel the Order instead'
union select 'OrderCanceledAndCannotbeClosed',              'Order has been Canceled and cannot be closed'
union select 'CloseOrderAllTasksNotCompleted',              'Order cannot be closed until all open tasks are completed/canceled'
union select 'CloseOrderAllUnitsAreNotShipped',             'Order cannot be closed until all picked units are shipped'
union select 'CloseOrderAllUnitsAreNotLoaded',              'Order cannot be closed until all picked units are Loaded'
union select 'CloseOrder_SomeLPNsMissingTrkNos',            'Cannot ship order as some of the LPNs does not have tracking numbers'
union select 'CannotCancelOrderOnLoad',                     'Cannot cancel an Order that is associated with a Load. Please remove order from load and then cancel'
union select 'CannotCloseOrderOnLoad',                      'Cannot close an Order that is associated with a Load. Please remove order from load and then close.'
union select 'CloseKitOrder_UnitsStillAssigned',            'Cannot close Kit order, there are some units assigned to it'

union select 'OrderPreprocess_MissingShipFromContact',      'Cannot Process the Order %1, Order has ShipFrom of %2 and the address is not setup for this Ship From'
union select 'OrderPreprocess_MissingWarehouseContact',     'Cannot Process the Order %1, Order ships from Warehouse %2 and the address is not setup for this Warehouse'
union select 'OrderPreprocess_OrderMissingShipToState',     'Cannot Process the Order %1, Order %1 does not have State specified on Ship To address'

/*------------------------------------------------------------------------------*/
/* OrderHeader Entity */
/*------------------------------------------------------------------------------*/
union select 'PickTicketIsInvalid',                         'Invalid PickTicket'
union select 'SalesOrderIsInvalid',                         'Invalid SalesOrder'
union select 'OrderTypeIsInvalid',                          'Invalid OrderType'
union select 'OrderTypeDoesNotExist',                       'OrderType does not exist'
union select 'CustomerDoesNotExist',                        'Customer does not exist'
union select 'ShipToIdDoesNotExist',                        'ShipToId does not exist'
union select 'ShipViaIsRequired',                           'ShipVia is required'
union select 'InvalidBatchToRemoveOrders',                  '#PickBatch is invalid to remove Orders'
union select 'OrderAlreadyShipped',                         'Order is already shipped'
union select 'UniqueIdIsRequired',                          'Unique Id is required'

union select 'Order_InvalidLinesOntheOrder',                'Order %1 does not have detail lines'
union select 'Order_InvalidHostNumLines',                   'Order %1 should have %2 lines, only %3 lines were downloaded'
union select 'Order_AddressValidation_Invalid',             'Order %1 is shipping to an invalid address %2; %3'
union select 'OrderEstimatedCartons_InvalidUnitVolume',     'Unable to estimate cartons, Order having SKU %1 (%2, %3, %4) with invalid Volume'
union select 'OrderEstimatedCartons_InvalidUnitsPerCarton', 'Unable to estimate cartons, Order having UnitsPerCarton un-defined on one or more lines '

union select 'Order_ModifyShipVia_NoneUpdated',             'Note: None of the selected Orders are modified with new Ship Via'
union select 'Order_ModifyShipVia_SomeUpdated',             'Note: ShipVia modified on %RecordsUpdated of %TotalRecords selected Orders'
union select 'Order_ModifyShipVia_Successful',              'Note: ShipVia modified successfully on selected %RecordsUpdated Order(s)'

union select 'OrderHeader_ModifyShipDetails_NoneUpdated',   'Note: None of the selected Orders are modified with new Ship Details'
union select 'OrderHeader_ModifyShipDetails_SomeUpdated',   'Note: Ship Details modified on %RecordsUpdated of %TotalRecords selected Orders'
union select 'OrderHeader_ModifyShipDetails_Successful',    'Note: Ship Details modified successfully on selected %RecordsUpdated Order(s)'

union select 'OrderHeader_Contacts_Edit_Successful',        'Note: Contact Address details are modified succesfully on selected %RecordsUpdated Order(s)'

union select 'ModifyOrder_AnyOfTheShipDetailRequired',      'Please select Ship Via / enter Bill To Account'
union select 'ModifyOrder_OrderOnLoad',                     'Order %1 is already on Load, cannot modify ship details'
union select 'ModifyOrder_AlreadySentToWSS',                'Order %1 is already Released/Exported to WSS, cannot modify ship details'
union select 'ModifyOrder_InvalidOrderStatus',              'Cannot modify Order %1 in %2 status'
union select 'ModifyOrder_InvalidOrderType',                'Cannot modify Order %1 of this order type'

union select 'OrderHeader_ModifyPickTicket_NoneUpdated',    'Note: None of the selected Orders are modified'
union select 'OrderHeader_ModifyPickTicket_SomeUpdated',    'Note: %RecordsUpdated of %TotalRecords selected Orders are modified'
union select 'OrderHeader_ModifyPickTicket_Successful',     'Note: All selected Orders (%RecordsUpdated) have been modified successfully'

union select 'ModifyPickTicket_InvalidOrderType',           'Cannot modify PickTicket %1 of this order type'
union select 'ModifyPickTicket_InvalidOrderStatus',         'Cannot modify PickTicket %1 in %2 status'

union select 'OrderHeader_ConvertToSetSKUs_NoneUpdated',        'Note: None of the selected Orders have been convert to sets'
union select 'OrderHeader_ConvertToSetSKUs_SomeUpdated',        'Note: %RecordsUpdated out of %TotalRecords selected Orders have been converted to sets'
union select 'OrderHeader_ConvertToSetSKUs_Successful',         'Note: All selected (%TotalRecords) Orders have been converted successfully'
union select 'OrderHeader_ConvertToSetSKUs_InvalidOrderType',   'Cannot convert to set SKUs Order %1 type %2'
union select 'OrderHeader_ConvertToSetSKUs_InvalidOrderStatus', 'Cannot convert to set SKUs Order %1 in %2 status'

union select 'Order_CancelPickTicket_InvalidOrderType',     'Cannot Cancel PickTicket %1 of this order type'
union select 'Order_CancelPickTicket_InvalidOrderStatus',   'Cannot Cancel PickTicket %1 in %2 status'
union select 'Order_CancelPickTicket_SomeUnitsAreShipped',  'Cannot Cancel PickTicket some units are shippeed, close the PickTicket instead'
union select 'Order_CancelPickTicket_OrderOnLoad',          'Cannot Cancel a PickTicket that is associated with a Load. Please remove PickTicket from load and then cancel'

union select 'OrderHeader_CancelPickTicket_NoneUpdated',    'Note: None of selected PickTickets are cancelled'
union select 'OrderHeader_CancelPickTicket_SomeUpdated',    'Note: %RecordsUpdated of %TotalRecords selected PickTickets are cancelled'
union select 'OrderHeader_CancelPickTicket_Successful',     'Note: All selected PickTickets (%RecordsUpdated) have been cancelled successfully'

union select 'Order_ClosePickTicket_InvalidOrderType',      'Cannot close PickTicket %1 of this order type'
union select 'Order_ClosePickTicket_InvalidOrderStatus',    'Cannot close PickTicket %1 in %2 status'

union select 'OrderHeader_ClosePickTicket_NoneUpdated',     'Note: None of selected PickTickets are closed'
union select 'OrderHeader_ClosePickTicket_SomeUpdated',     'Note: %RecordsUpdated of %TotalRecords selected PickTickets are closed'
union select 'OrderHeader_ClosePickTicket_Successful',      'Note: All selected PickTickets (%RecordsUpdated) have been closed successfully'

union select 'Order_ReleaseOrders_NoneUpdated',             'Note: None of the selected Orders are released'
union select 'Order_ReleaseOrders_SomeUpdated',             'Note: %RecordsUpdated of %TotalRecords selected Orders have been released'
union select 'Order_ReleaseOrders_Successful',              'Note: %RecordsUpdated Orders have been released successfully'

union select 'Order_ArchiveOrders_NoneUpdated',             'Note: None of the selected Orders are archived'
union select 'Order_ArchiveOrders_SomeUpdated',             'Note: %RecordsUpdated of %TotalRecords selected Orders are archived'
union select 'Order_ArchiveOrders_Successful',              'Note: All selected Orders (%RecordsUpdated) have been archived successfully'

union select 'Order_PrintEngravingLabels_NoneUpdated',      'Note: Engraving Labels cannot be printed for selected Order(s)'
union select 'Order_PrintEngravingLabels_SomeUpdated',      'Note: Engraving Labels printed for %RecordsUpdated of %TotalRecords selected Order(s)'
union select 'Order_PrintEngravingLabels_Successful',       'Note: Engraving Labels printed successfully for all (%RecordsUpdated) selected Order(s)'

union select 'OrderHeader_RemoveOrdersFromWave_NoneUpdated', 'Note: None of selected Orders are removed'
union select 'OrderHeader_RemoveOrdersFromWave_SomeUpdated', 'Note: %RecordsUpdated of %TotalRecords selected Orders are removed from the wave'
union select 'OrderHeader_RemoveOrdersFromWave_Successful',  'Note: All selected Orders (%RecordsUpdated) have been removed successfully'

union select 'Order_AddNote_NoneUpdated',                   'Note: None of the selected Order(s) modified'
union select 'Order_AddNote_SomeUpdated',                   'Note: Notes added for some of the selected Order(s)'
union select 'Order_AddNote_Successful',                    'Note: Notes for all selected Order(s) added successfully'

union select 'Order_ReplaceNote_NoneUpdated',               'Note: None of the selected Order(s) modified'
union select 'Order_ReplaceNote_SomeUpdated',               'Note: Notes updated for some of the selected Order(s)'
union select 'Order_ReplaceNote_Successful',                'Note: Notes for all selected Order(s) updated successfully'

union select 'Order_DeleteNote_NoneUpdated',                'Note: None of the selected Order(s) modified'
union select 'Order_DeleteNote_SomeUpdated',                'Note: Notes deleted for some of the selected Order(s)'
union select 'Order_DeleteNote_Successful',                 'Note: Notes for all selected Order(s) deleted successfully'

union select 'NoteAddOrUpdate_NoteTypeOrNoteEmpty',         'Note or Note Type is undefined'

union select 'Order_CompleteReworkSuccess',                 'Rework Order(s) completed successfully'
union select 'CompleteRework_InvalidOrderType',             'Complete Rework: Pick Ticket %1 type is invalid to complete rework'
union select 'CompleteRework_ApplicableForContractorWHOnly','Complete Rework is applicable only for Contractor Order(s)'
union select 'CompleteRework_InvalidOrderStatus',           'Complete Rework: Pick Ticket %1 status is invalid to complete rework'
union select 'CompleteRework_PicklaneNotFoundToTransferInv','No picklane found to Transfer reworked inventory'
union select 'CompleteRework_InsufficientQty',              'Insufficient quantity to complete re-work order'
union select 'ReworkOrder_InvaildStatusToClose',            'Rework Order can be closed only if order is completely picked'
union select 'ReworkOrder_OrderAlreadyClosed',              'Rework Order already closed. Please verify'

/*------------------------------------------------------------------------------*/
/* OrderDetail Entity */
/*------------------------------------------------------------------------------*/
union select 'OrderIsInvalid',                              'Invalid Order'
union select 'OrderLineIsInvalid',                          'Invalid OrderLine'
union select 'HostOrderLineIsInvalid',                      'Invalid HostOrderLine'

union select 'OD_ModifyDetails_UnitsAssignedGreaterThanToShip', 'Order %1, Line %2, SKU %3, was not updated as Units assigned is greater than Units To Ship'
union select 'OD_ModifyDetails_ToShipGreaterThanUnitsOrdered',  'Order %1, Line %2, SKU %3, was not updated as Unit To Ship is greater than Units Ordered'
union select 'OD_ModifyDetails_OrderStatusIsInvalid',           'Order %1 is in %4 status and therefore Line %2, SKU %3 cannot be modified'
union select 'OD_ModifyDetails_UnitsToShipIsRequired',          'Units to Ship is required to modify the order details'

union select 'CancelPTLine_NewUnitsToAllocateRequired',     'Please enter the New units to allocate or use Cancel remaining qty option'
union select 'CancelPTLine_NoUnitsToCancel',                'There are no units available to cancel for PickTicket %1, SKU %2'
union select 'CancelPTLine_CannotCancelPartialQty',         'Cannot cancel the line partly - unallocate any allocated units and/or cancel the total units to ship'
union select 'CancelPTLine_CannotCancelAllocatedQty',       'Cannot cancel allocated quantity. Can only cancel (%3 units) i.e. what remains to be allocated on the Order line for PickTicket %1, SKU %2'
union select 'CancelPTLine_CompletelyAllocated',            'Line is completely allocated, first unallocate the units assigned and then cancel the line'
union select 'CancelPTLine_InvalidOrderStatus',             'PickTicket %1 is in %2 status and cannot be cancelled'

union select 'OrderDetails_Modify_NoneUpdated',             'Note: None of the Order Details have been modified'
union select 'OrderDetails_Modify_SomeUpdated',             'Note: %RecordsUpdated out of %TotalRecords Order Details have been modified'
union select 'OrderDetails_Modify_Successful',              'Note: All selected (%TotalRecords) Order Details have been modified successfully'

union select 'OrderDetails_CancelPTLine_NoneUpdated',       'Note: None of the selected Order Details have been canceled'
union select 'OrderDetails_CancelPTLine_SomeUpdated',       'Note: %RecordsUpdated out of %TotalRecords selected Order Details have been canceled'
union select 'OrderDetails_CancelPTLine_Successful',        'Note: All selected (%TotalRecords) Order Details have been canceled successfully'

union select 'OrderDetails_CancelRemainingQty_NoneUpdated', 'Note: None of the selected Order Details remaining quantity have been canceled'
union select 'OrderDetails_CancelRemainingQty_SomeUpdated', 'Note: %RecordsUpdated out of %TotalRecords selected Order Details remaining quantity have been canceled'
union select 'OrderDetails_CancelRemainingQty_Successful',  'Note: All selected (%TotalRecords) Order Details have been canceled remaining quantity successfully'

union select 'OrderDetails_ModifyPackCombination_NoneUpdated',  'Note: None of the selected Order Details (%TotalRecords) are modified '
union select 'OrderDetails_ModifyPackCombination_SomeUpdated',  'Note: %RecordsUpdated of %TotalRecords Order Details have been modified'
union select 'OrderDetails_ModifyPackCombination_Successful',   'Note: All selected (%TotalRecords) Order Details have been modified successfully'

union select 'OD_ModifyPack_NoChangeToUpdate',              'Selected line %2 of Order %1 already has PackingGroup %3 and/or Pack Qty of %4 and hence not updated'
union select 'OD_ModifyPack_WaveReleased',                  'Wave %2 already released, hence PackingGroup and/or Pack Qty cannot be update for line %3 of Order %1'

union select 'OrderDetails_ModifyReworkInfo_NoneUpdated',   'Note: None of the selected Order Details (%TotalRecords) are modified '
union select 'OrderDetails_ModifyReworkInfo_SomeUpdated',   'Note: %RecordsUpdated of %TotalRecords Order Details have been modified'
union select 'OrderDetails_ModifyReworkInfo_Successful',    'Note: All selected (%TotalRecords) Order Details have been modified successfully'
union select 'ODModifyReworkInfo_SameSKU&InvClass',         'Selected line of Order %1 is already for SKU %2 and/or InventoryClass and hence not updated'

union select 'ToShipQtyIsGreaterThanOrderedQty',            'Units to ship quantity cannot be greater than units ordered quantity'

/*------------------------------------------------------------------------------*/
/*pr_RFC_Inventory*/
/*------------------------------------------------------------------------------*/
union select 'InvalidPalletTypeToMove',                     'Cannot move Pallet which is associated for an Order'
union select 'SKURemove_InventoryExists_CannotRemove',      'Cannot Remove the SKU with quantity'

/*------------------------------------------------------------------------------*/
/*RFC_ValidateLPN*/
/*------------------------------------------------------------------------------*/
union select 'LPNIsRequired',                               'LPN is Required'
union select 'LPNStatusIsInvalid',                          'Invalid LPN Status'
union select 'LPNClosedForPicking',                         'LPN is closed, pick into a new LPN'

/*------------------------------------------------------------------------------*/
/*RFC_ValidateLocation*/
/*------------------------------------------------------------------------------*/
union select 'LocationIsNotActive',                         'Location is not active and cannot be used'
union select 'LocationIsNotAPicklane',                      'This operation is only allowed on a Picklane'
union select 'LocationNotInGivenWarehouse',                 'Location does not exist in given Warehouse'

union select 'LocationAddSKU_NotAPicklane',                 'Inventory/SKUs can only be added to Picklane type Locations'
union select 'LocationAddSKU_NotStaticLocation',            'Can set up SKUs only for a static Picklane'
union select 'LocationAddSKU_NoMultipleSKUs',               'Location does not allow multiple SKUs'
union select 'LocationAddSKU_SKUAlreadyInLocation',         'Location already has the SKU being added'
union select 'LocationAddSKU_SameSKUWithDiffInvClass',      'Location already has same SKU but with different Label Code'

union select 'LocationRemoveSKU_NotAllowed',                'You do not have authorization to remove SKU from Picklane'
union select 'LocationRemoveSKU_NotAPicklane',              'Inventory/SKUs can only be removed from Picklane type Locations'
union select 'LocationRemoveSKU_AvailRes_Lines',            'SKU cannot be removed from Location. SKU has Available or Reserved Lines'
union select 'LocationRemoveSKU_DirRes_Lines',              'SKU cannot be removed from Location. SKU has Reserved or Directed Lines'
union select 'LocationRemoveSKU_NoSKUs',                    'Picklane does not have any SKUs setup to remove'
union select 'LocationRemoveSKU_SKUDoesNotExist',           'SKU does not exist in the picklane to remove'

union select 'LocationAddSKU_DynamicPicklane',              'SKU can be only added to a dynamic picklane when there is inventory'
union select 'LocationAddSKU_CasePicklane',                 'Only cases can be added to a Case storage picklane location'
union select 'LocationAddSKU_UnitPicklane',                 'Only units can be added to an unit storage picklane location'
union select 'LocationAddSKU_ReasonCodeRequired',           'A Reason code is required to add inventory, so add SKU without units and then adjust the Location Qty'
union select 'LocationAddSKU_InvaildSKUPackConfig',         'SKU pack configs are not defined, cannot add SKU to case storage Location(s)'

union select 'PicklaneSetUp_NotAPicklane',                  'Location setup is only applicable for Picklanes'
union select 'PicklaneSetUp_ReplenishUnitsOnly',            'Units Storage location will allow eaches to replenishments'
union select 'PicklaneSetUp_ReplenishCasesOnly',            'Case Storage location will allow cases to replenishments'
union select 'LocationSKUIsNotDefined',                     'SKU should be defined to configure picklane location'
union select 'PicklaneSetUp_SKUIsNotAdded',                 'Replenish levels on Picklane can be setup after SKU is added to Location'
/*------------------------------------------------------------------------------*/
/*RFC_AddSKUToLocation*/
/*------------------------------------------------------------------------------*/
union select 'CanOnlyAddSKUsToPicklanes',                   'SKU can only be added to Picklane'
union select 'InvalidQuantity',                             'Invalid Quantity'
union select 'SKUIsOfInactiveStatus',                       'New SKU scanned is of Inactive Status'
union select 'LocDoesNotAllowMultipleSKUs',                 'Location does not allow multiple SKUs'
union select 'LocationAddSKU_SKUIsInactive',                'Scanned SKU is Inactive and cannot setup a Picklane for it'
union select 'LocationAddSKU_SKUAlreadyExists',             'Scanned Location already associated with another SKU'

/*------------------------------------------------------------------------------
pr_RFC_AdjustLocation:
------------------------------------------------------------------------------*/
union select 'LocationAdjust_NoItems',                      'Cannot adjust a Picklane location which has no SKUs setup yet.'
union select 'LocationAdjust_NotAPicklane',                 'Can only adjust inventory in a Picklane Location, use Adjust LPN Qty in other situations.'
union select 'LocationAdjust_SameQuantity',                 'Quantity given to adjust is the same as existing quantity in the Location.'
union select 'LocationAdjust_NoLinesAvailable',             'No Lines available to adjust Location quantity'
union select 'LocationAdjust_ReasonCodeRequired',           'Reason code required to adjust Location quantity.'
union select 'LocationAdjust_P_CannotAdjustReservedQty',    '%1 Cases are reserved from this Location. Cannot adjust below those cases. Or, un-reserve the Location and adjust.'
union select 'LocationAdjust_CannotAdjustReservedQty',      'Cannot adjust Location quantity. %1 units in the Location is reserved for orders'

union select 'LocationDoesnotHaveSKUToAdjust',              'Location does not have SKU to Adjust'
union select 'NoAvailableInventoryToAdjust',                'Inventory is not available to Adjust'
union select 'InvalidInnerPacks',                           'Invalid cases'
union select 'LocationAdjust_NotAUnitPicklane',             'Only units can be adjust in a units storage picklane location.'
union select 'LocationAdjust_NotACasePicklane',             'Only cases can be adjust in a Case storage picklane location.'
union select 'LocationAdjust_U_CannotAdjustReservedQty',    'Cannot adjust quantity to less than the reserved'

/*------------------------------------------------------------------------------
pr_RFC_AddSKUToLPN:
------------------------------------------------------------------------------*/
union select 'LPNCannotAddSKU',                             'LPN cannot AddSKU'

/*------------------------------------------------------------------------------
pr_RFC_AdjustLPN:
------------------------------------------------------------------------------*/
union select 'SKUNotInLPN',                                 'SKU is not in LPN'
union select 'LPNAdjust_SameQuantity',                      'Quantity given to adjust is the same as existing quantity in the LPN.'
union select 'LPNAdjust_CannotAdjustReservedQuantity',      '%1 Units are reserved from this LPN. Cannot adjust below those units. Or, un-reserve the LPN and adjust.'
union select 'LPNAdjust_UnavailableLine',                   'LPN detail is not available for adjustment'
union select 'LPNAdjust_ReasonCodeRequired',                'Reason code required to adjust LPN quantity'

/*------------------------------------------------------------------------------
pr_RFC_MoveLPN:
------------------------------------------------------------------------------*/
union select 'InvalidLocationorPallet',                     'Enter a valid Location or Pallet to move the LPN'
union select 'LPNMove_WarehouseMismatch',                   'Warehouse of LPN and Location do not match, cannot move LPN into this location'
union select 'LPNMove_CanOnlyBeStaged',                     'Staged LPN can only be moved to Staging/Dock Locations'
union select 'LPNMove_EmptyLPN',                            'Cannot move an empty LPN'
union select 'LPNMove_InvalidStatus',                       'LPN status is invalid to move'
union select 'LPNMove_NoAllocatedLPNinPickableLocation',
                                                            'LPN is allocated to an Order and cannot be in a moved into a Picking Location'
union select 'LPNMove_LPNIsAllocated',                      'LPN is allocated to an Order and cannot be moved into another Location'
union select 'LPNMove_InvalidUser',                         'User does not have the permission to move LPN from a non-empty location'
union select 'LPNMove_CannotMoveAllocatedLPNToOtherWarehouses',
                                            'LPN is allocated to an Order and cannot be moved to another Warehouse'
union select 'LPNMove_BeforeReceiverClosed_NotAllowed',
                                            'LPN/LPN on Pallet is not allowed to move before its Receiver Closed'
union select 'LPNMove_BeforeReceiverClosed_InvalidLocationType',
                                            'Location type is invalid to move LPN/LPN on Pallet before its Receiver Closed'
union select 'LPNMove_BeforeReceiverClosed_InvalidWarehouse',
                                            'Location Warehouse is invalid to move LPN/LPN on Pallet before its Receiver Closed'

/*------------------------------------------------------------------------------
pr_RFC_AddLPNToPallet:
------------------------------------------------------------------------------*/
union select 'AddLPNToPallet_LPNTypeIsInvalid',             'Scanned LPN not suitable to be added to a Pallet. Type of LPN is not valid.'
union select 'AddLPNToPallet_WarehouseMismatch',            'LPN and Pallet are of different Warehouses and so cannot move LPN %1 to Pallet %2'

/*------------------------------------------------------------------------------*/
/* RFC_Putaway*/
/*------------------------------------------------------------------------------*/
union select 'LPNPA_LPNIsAllocated',                        'LPN is allocated to an Order and cannot be putaway into another location'
union select 'PALPN_ReceiverNotClosed',                     'LPN/Pallet cannot be putaway because Receiver of the LPN/Pallet is not yet closed'
union select 'PALPN_MsgInfoWithLocQty',                     '**Required %1 units, Location has space for %2 units'
union select 'PALPN_MsgInfoWithoutLocQty',                  '**Required %1 units, Location is almost full'
union select 'PALPN_MsgInfoWithPriAndSecLocQty',            'Putaway %1 units to Primary or %2 units to Secondary'
union select 'PALPN_MsgInfoUptoMinLevel',                   'Putaway max possible to Primary (minimum of %2), as much as will fit in the Location'
union select 'PALPN_MsgInfoNoDemand',                       'Putaway to Primary Only- Balance to end Cap(Reserve)'
union select 'PA_ScanValidPalletOrLocation',                'Scan valid Pallet or Location'
union select 'PA_ScannedPalletIsOfDifferentWH',             'Scanned Pallet is from Warehouse %1, log into that Warehouse to putaway the Pallet'
union select 'PA_ScannedLPNIsOfDifferentWH',                'Scanned LPN is from Warehouse %1, log into that Warehouse to putaway the LPN'
union select 'PA_ToDestinationOnly',                        'LPN  %1 is already directed to Location %2 and can only be putaway to that Location'
union select 'PA_SKUPAClassNotDefined',                     'Putaway Class is not defined for the SKU and hence system cannot find a Location'
union select 'PA_CanOnlyPAtoPicklane',                      'LPN is less than a Case pack and can only be putaway into shelving location'
union select 'PA_LPNPAClassHasNoRules',                     'LPN cannot be Putaway as it does not conform to the rules of Putaway'
union select 'PALPN_ReqUnitsHaveBeenPAAndRestUnitsUnallocated',
                                                            'Min units required has been Putaway and %2 units have been unallocated, please move LPN to some reserve Location'
union select 'PALPN_MinUnitsToCompletePA',                  'LPN has been putaway partially, atleast putaway %1 of %2 %3'
union select 'PALPN_PartialPutaway',                        '%1 %2 putaway from LPN %3 to %4'
union select 'PALPN_PutawayComplete',                       'LPN %3 with quantity %1 %2 putaway into Location %4'

union select 'PA_LPNAlreadyOnOPallet',                      'LPN is already on the scanned pallet'
union select 'PA_LPNAlreadyPutaway',                        'Putaway of this LPN already completed'
union select 'PA_LocationIsNotSetupForSKU',                 'Cannot putaway into Location that is not setup for the SKU being putaway'
union select 'PAReplenishLPN_DisplayQty',                   'Atleast %1 of %2 %3'
union select 'PALPN_DisplayQty',                            '%1 %2'
union select 'PALPN_DisplayIPsAndQty',                      '%1 %2/%3 %4'
union select 'PA_LocOnHoldCannotPutaway',                   'Location on hold, cannot putaway into the Location'
union select 'PA_LocOnHoldCannotReplenish',                 'Location on hold, cannot replenish into the Location'

union select 'CancelPutawayLPNSuccessful',                  'LPN Putaway cancelled successfully'
union select 'UpdateConflict',                              'Another update has happened that prevents your operation being completed. Please try again'
union select 'PutawaySuccessful',                           'LPN Putaway successfully'
union select 'CannotPutawayMultiSKUPallet',                 'Multi SKU Pallet cannot be putaway'
union select 'CompleteProductionSuccess',                   'Production completed successfully'
union select 'PA_AllocatedLPNCanOnlyPutawayToASuggestedLoc','Scanned LPN is allocated to an Order & can be Putaway into suggested Location only'
union select 'PA_QtyExceedsSecondaryLocMaxQty',             'Quantity being putaway exceeds the max quantity that can be putaway into secondary Location'
union select 'PAByLocation_InvalidStorageType',             'Scanned Location does not allow LPNs to be putaway to them'
union select 'CompleteVAS_NoPicklaneToAdjustInv',           'No picklane to adjust inventory'
union select 'CompleteVAS_NotEnoughInvToAdjust',            'Not enough inventory in Picklane to adjust'

/*------------------------------------------------------------------------------*/
/* RFC_PutawayLPNs */
/*------------------------------------------------------------------------------*/
union select 'CancelPutawayLPNsSuccessful',                 'LPNs Putaway cancelled successfully'
union select 'PALPNs_LPNAlreadyScanned',                    'LPN has already been scanned for Putaway'
union select 'PALPNs_DestZoneSKUPutawayClassMismatch',      'Scanned LPN did not match DestZone and SKU Putaway Class'
union select 'PALPNs_ScannedLPNsWithDiffStatuses',          'Scanned LPN  is of different status'
union select 'PALPNs_NotImplementedForAlreadyPALPNs',       'Putaway LPNs is not implemented for New LPNs & LPNs which are already Putaway'

/*------------------------------------------------------------------------------*/
/* RFC_PutawayLPNsOnPallet */
/*------------------------------------------------------------------------------*/
union select 'PALPNsOnPallet_PalletStatusInvalid',          'Pallet is not of valid status to Putaway LPNs on it'

/*------------------------------------------------------------------------------
pr_RFC_TransferInventory:
------------------------------------------------------------------------------*/
union select 'FromLPNDoesNotExist',                         'FromLPN does not exist'
union select 'SKUDoesNotExistInLPN',                        'SKU does not exist In LPN'
union select 'FromLocationDoesNotExist',                    'FromLocation does not exist'
union select 'CannotAddSKUtoNonPickLaneLoc',                'Cannot add SKU or inventory to a Location that is not a Picklane'

union select 'CannotTransferFromNonPicklaneLoc',            'Cannot transfer inventory from a Location that is not a Picklane'
union select 'CannotTransferIfLPNReceiverNotClosed',        'LPN cannot be transferred into picklane until the Receiver is closed'

union select 'SKUDoesNotExistInLocation',                   'SKU does not exist in Location'
union select 'ToLPNDoesNotExist',                           'ToLPN does not exist'
union select 'ToLocationDoesNotExist',                      'ToLocation does not exist'
union select 'SKUCanTransferIfLocTypeIsPickLane',           'SKU can transfer only if LocationType is Picklane'

union select 'NoInventoryToTransferFromLPN',                'There is no inventory associated with the LPN to transfer'
union select 'NoInventoryToTransferFromLoc',                'There is no inventory in the Location to transfer'

union select 'LPNStorageTypeMismatch_FH',                   'Cannot transfer from a Flat LPN to a Hanging LPN or Location'
union select 'LPNStorageTypeMismatch_HF',                   'Cannot transfer from a Hanging LPN to a Flat LPN or Location'
union select 'LOCStorageTypeMismatch_FH',                   'Cannot transfer from a Flat Location to a Hanging LPN or Location'
union select 'LOCStorageTypeMismatch_HF',                   'Cannot transfer from a Hanging Location to a Flat LPN or Location'
union select 'CannotTransferEmptyPallet',                   'Cannot transfer empty Pallet'

union select 'SuccessfullyTransferredPallet',               'Successfully Transferred Partial Inventory from Pallet %1 to Pallet %2'
union select 'SuccessfullyTransferredPartialPallet',        'Successfully Transferred Inventory from Pallet %1 to Pallet %2'

union select 'CannotStoreCasesInPicklaneUnitStorage',       'Cannot store Cases in Picklane unit Storage Location'
union select 'InvalidQuantityForPicklaneCaseStorage',       'Enter quantity in cases for Picklane case storage Locations'
union select 'TransferInventory_UnitPackagesAredifferent',
                                                 'Units per Case are different and hence cannot be transferred'
union select 'TransferInv_CannotMoveReceivedInvBetweenWH',
                                                 'Cannot transfer inventory from/to, which is in received, between two different Warehouses'
union select 'TransferInv_NotValidFromReceivedToPutaway',
                                                 'Cannot transfer inventory from Received to Putaway LPN'
union select 'TransferInv_LPNsWarehouseMismatch','Warehouse of LPN and Location do not match and cannot transfer inventory'
union select 'ReplenishLPN_InvalidOperation',    'Cannot transfer inventory from Replenish LPN, use Putaway instead'

/*------------------------------------------------------------------------------
pr_RFC_TransferPallet:
------------------------------------------------------------------------------*/
union select 'PalletStoreMismatch',                         'Pallets are for different Stores, Cannot transfer the inventory'
union select 'PalletStatusMismatch',                        'Status of From Pallet and To Pallet do not match, Cannot transfer the inventory'
union select 'PalletLoadMismatch',                          'Pallets are for two different Loads, Cannot transfer the inventory'

/*------------------------------------------------------------------------------*/
/* Build Inventory */
/*------------------------------------------------------------------------------*/
union select 'BuildInv_InvalidPallet',                      'Pallet is invalid'
union select 'BuildInv_PalletLocationMismatch',             'Given Pallet has different location, Please scan Location of the Pallet'
union select 'BuildInv_InvalidLocation',                    'Location is invalid'
union select 'BuildInv_InvalidExternalLPN',                 'Scanned LPN is not a vendor LPN. Please scan a valid LPN applied by Vendor'

/*------------------------------------------------------------------------------*/
/* pr_RFC_Inv_MovePallet */
/*------------------------------------------------------------------------------*/
union select 'MovePallet_Successful',                       'Pallet moved to %2'
union select 'MovePallet_Successful2',                      'Pallet moved from %1 to %2'
union select 'PalletsMerged_Successful1y',                  '%3 LPNs on Pallet moved from %1 to %2'
union select 'MovePallet_InvalidLocationorPallet',          'Enter a valid Location or Pallet to move the LPN'
union select 'MovePallet_ResvLPNsInvalidLocationType',      'Invalid location type to move Pallet with reserved LPNs'
union select 'MovePallet_CannotMoveEmptyPallet',            'Cannot move an empty pallet'
union select 'MovePallet_CannotMergeWithEmptyPallet',       'Cannot merge with an empty pallet'

/*------------------------------------------------------------------------------*/
/* pr_RFC_Inv_ExplodePrepack */
/*------------------------------------------------------------------------------*/
union select 'ToLPNIsNull',                                 'To LPN Is  Required'
union select 'ScannedSKUIsNotAPrepack',                     'Scanned SKU Is Not A Prepack'
union select 'ToLPNStatusIsInvalid',                        'LPN status must be New'
union select 'CanOnlyExplodeAvailableLPN',                  'Can Only Explode Available LPN'
union select 'CannotExplodePartialQtyIfSameLPNIsUsed',      'Cannot Explode Partial Qty If Same LPN Is Used'
union select 'CannotExplodeAnLPNWhichHasMultipleSKUs',      'Cannot Explode An LPN Which Has Multiple SKUs'

/*------------------------------------------------------------------------------*/
/* pr_RFC_Inv_DropBuildPallet */
/*------------------------------------------------------------------------------*/
union select 'DropBuildPallet_Successful',                  'Successfully dropped pallet at %1'
union select 'DropBuildPallet_AlreadyAtLocation',           'Pallet already at Location %1'

/*------------------------------------------------------------------------------*/
/*pr_RFC_Purchasing*/
/*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
RFC_ReceiveToLPN:
------------------------------------------------------------------------------*/
union select 'QuantityToReceiveCantBeNullOrZero',           'Quantity To Receive should be Greater than Zero'
union select 'InvalidLPNStatus',                            'Invalid LPN Status'

/*------------------------------------------------------------------------------
RFC_ValidateReceipt:
------------------------------------------------------------------------------*/
union select 'StatusShouldNotbeClosed',                     'Status should not be Closed'
union select 'NoUnitsToReceive',                            'There are no Units To Receive'
union select 'Recv_NotAValidWarehouseToReceive',            'Not a valid Warehouse to receive this Receipt Order'

/*------------------------------------------------------------------------------
 RF Packing:
------------------------------------------------------------------------------*/
union select 'RFPack_LPN/PickTicketWarehouseMismatch',        'Scanned LPN/PickTicket does not belong to user logged in Warehouse'
union select 'RFPack_InvalidLPNStatus',                       'Scanned LPN is not in a valid Status for Packing'
union select 'RFPack_InvalidPickTicketStatus',                'PickTicket status is not valid for Packing'
union select 'RFPack_InvalidOrderType',                       'Cannot Pack Bulk Orders'
union select 'RFPack_UseEmptyLPN/AssignedLPN',                'Scanned LPN must be either empty or assigned to the Pick Ticket'
union select 'RFPack_InvalidPackFrom',                        'Scanned Location/Pallet to pack from is invalid'
union select 'RFPack_ScannedLPNIsAssociatedWithDiffOrder',    'Scanned LPN is associated with another Order'
union select 'RFPack_InventoryInScannedLocIsNotForScannedPT', 'Location scanned to pack from is not associated to scanned Pick Ticket'
union select 'RFPack_NothingToPackAgainstScannedPT',          'There is nothing to pack against scanned Pick Ticket'
union select 'RFPack_InvalidCartPosStatus',                   'Invalid Cart Positon scanned'
union select 'RFPack_ScannedPosIsNotAssociatedWithScannedPT', 'Scanned Pick Ticket is not associated with Cart Position'

------------------------------------------------------------------------------*/
/*pr_Inventory_ValidateTransferInventory*/
/*------------------------------------------------------------------------------*/
union select 'InvalidParameters',                           'Invalid Parameters'
union select 'TransferInv_NoSufficientQty',                 'Transfer Quantity cannot be greater than from LPN/Location Quantity'
union select 'TransferInv_FromLPNUnavailable',              'LPN being transferred from does not have available inventory that can be transfered'
union select 'TransferInv_SameLPN',                         'Cannot transfer inventory from an LPN to the same LPN'
union select 'TransferInv_DifferentOrders',                 'The From/To LPNs are for different Orders and inventory cannot be transfered between them'
union select 'TransferInv_DifferentReceipts',               'The From/To LPNs are for different Receipts and inventory cannot be transfered between them'
union select 'TransferInv_ToLPNUnavailable',                'LPN being transferred to does not have available inventory that can be added to'
union select 'TransferInv_ReceiverNotClosed',               'Cannot transfer inventory. Receiver not closed'
union select 'TransferInv_SameLocation',                    'Cannot transfer inventory from a Location into the same Location'
union select 'TransferInv_FromLPNAllocated',                'Cannot transfer Inventory from an LPN reserved for an Order into a Location'
union select 'TransferInv_LPNsOwnerMismatch',               'LPNs belong to different Owners and inventory cannot be transferred between them'
union select 'TransferInv_ToLPNIsLogicalLPN',               'Requested to Transfer to an LPN, but scanned a Location'
union select 'TransferInv_LPNToStatusIsInvalid',            'Cannot transfer inventory: Status of the To LPN is not valid for transfers'
union select 'TransferInv_LPNIsAllocated',                  'LPN is allocated to an order, Please unallocate this LPN and try to transfer'
union select 'TransferInv_TransferCasesOnly',               'From LPN/Location is in Cases, so enter the quantity in cases to complete transfer'

union select 'TransferInv_NotValidFromReceivedToPutaway', 'Cannot transfer inventory from Received to Putaway LPN'
union select 'TransferInv_LPNsWarehouseMismatch',         'Warehouse of LPN and Location do not match and cannot transfer inventory'
union select 'TransferInv_CannotMoveReservedInvBetweenWH','From/To LPNs are different Warehouses and either one is reserved for an Order'
union select 'TransferInv_LPNFromStatusIsInvalid',        'Cannot transfer inventory: Status of the From LPN is not valid for transfers'
union select 'TransferInv_DifferentOrder',                'The From LPN and To LPN are not for the same Order and hence inventory cannot be transfered'
union select 'TransferInv_CannotTransferReservedLine',    'Cannot transfer reserved inventory from this LPN to an LPN/Location that is not reserved for the Order'
union select 'TransferInv_NoPermissionToTransferToUnassignedLoc',          'You do not have authorization to transfer inventory to an empty Location. Please see Supervisor'
union select 'TransferInv_LocationIsNotSetupForSKU',      'Cannot transfer inventory to a picklane that is not set up for the SKU'
union select 'TransferInv_LocationIsNotActive',           'Cannot transfer inventory. Location is in-active'
union select 'TransferInv_LocationIsSetupForDifferentSKU','SKU is not configured for the location'
union select 'TransferInv_NotSameOrder',                  'To LPN should be empty or From/To LPNs should be for the same order'
union select 'TransferInv_InventoryClassMismatch',        'Cannot transfer inventory. Inventory Class mismatch between source & destination'
union select 'TransferInv_TransferToUnavailableLPN',      'Cannot transfer inventory from Available/Reserved LPN to an unavailable LPN'
union select 'TransferInv_DestinationNotIdentified',      'Scanned destination is not a valid LPN or Location or not a Location in the current Warehouse'
union select 'TransferInv_SourceNotIdentified',           'Scanned source is not a valid LPN or Location or not a Location in the current Warehouse'
union select 'TransferInv_ReceiverNotYetClosed',          'Cannot transfer inventory until the receiver is closed'
union select 'TransferInv_ReceiverNotYetClosed',            'Cannot transfer inventory until the receiver is closed'
union select 'TransferInv_CannotTransferReservedQty',       'Cannot transfer inventory. Inventory is reserved for orders, can only transfer upto %1 units'

------------------------------------------------------------------------------*/
/* pr_ExecuteSQL */
/*------------------------------------------------------------------------------*/
union select 'SQLCannotBeNullOrEmpty',                      'Cannot execute SQL as it is empty'

------------------------------------------------------------------------------*/
/*pr_Exports_AddOrUpdate*/
/*------------------------------------------------------------------------------*/
union select 'TransTypeIsInvalid',                          'Invalid TransType'
union select 'TransTypeDoesNotExist',                       'TransType does not exist'
union select 'TransEntityIsInvalid',                        'Invalid TransEntity'
union select 'TransEntityDoesNotExist',                     'TransEntity does not exist'

------------------------------------------------------------------------------*/
/*pr_Interface_Import*/
/*------------------------------------------------------------------------------*/
union select 'RecordTypeIsInvalid',                         'Record Type %1 is not valid'
union select 'Import_InvalidAction',                        'Invalid Action code'
union select 'Import_InvalidUoM',                           'Invalid UoM'
union select 'Import_InvalidSKU',                           '%1 is not a valid SKU'
union select 'Import_InvalidUPC',                           '%1 is invalid as it is not numeric'
union select 'Import_InvalidPickTicket',                    '%1 is not a valid PickTicket'
union select 'Import_InvalidBusinessUnit',                  '%1 is not a valid BusinessUnit'
union select 'Import_SKUIsInactive',                        '%1 is an Inactive SKU'
union select 'Import_SKUIsRequired',                        'SKU is required to import record'

union select 'Import_MasterSKUIsRequired',                  'Master SKU is required for Component SKU %1'
union select 'Import_MasterSKUIsInvalid',                   '%1 is not a valid MasterSKU'
union select 'Import_ComponentSKUIsRequired',               'Component SKU is required (Master SKU: %1)'
union select 'Import_ComponentSKUIsInvalid',                '%1 is not a valid Component SKU'
union select 'Import_InvalidOrderStatus',                   '%1 is not a valid order status to Import'
union select 'Import_ComponentQtyIsInvalid',                'Qty must be greater than zero for Component SKU %1'

union select 'Import_OwnerIsRequired',                      'Ownership code is required'
union select 'Import_OwnerIsInvalid',                       '%1 is not a valid Owner'
union select 'Import_WarehouseIsRequired',                  'Warehouse is required'
union select 'Import_WarehouseIsInvalid',                   '%1 is not a valid Warehouse'
union select 'Import_InvalidSourceSystem',                  'Source System is not valid'
union select 'Import_CannotChangeSourceSystem',             'Cannot update/delete data sent from a different Source System'

/*------------------------------------------------------------------------------
pr_Imports_ValidateASNLPNDetail:
------------------------------------------------------------------------------*/
union select 'LPNAlreadyPutaway',                           'LPN already putaway'
union select 'Import_LPNIsInvalid',                         '%1 is not a valid LPN'

/*------------------------------------------------------------------------------
pr_Imports_ValidateVendor:
------------------------------------------------------------------------------*/
union select 'VendorAlreadyExists',                         'Vendor already exists'

/*------------------------------------------------------------------------------
pr_Imports_ValidateLocations:
------------------------------------------------------------------------------*/
union select 'Import_LocIsRequired',                                  'Location is required to import Locations'
union select 'LocImport_NoChangeOfLocationTypeAndStorageType',        'Cannot update Location Type and Storage Type when Location is not empty'
union select 'LocImport_CannotDeleteNonEmpty',                        'Location cannot be deleted as it is not Empty. Only empty Locations can be deleted'
union select 'LocImport_Invalid_StorageAndLocationType',              'Location cannot be inserted/updated as the given Location and Storage Type combination are not valid'

/*------------------------------------------------------------------------------
pr_Imports_ValidateReceiptHeader:
------------------------------------------------------------------------------*/
union select 'VendorIsInvalid',                             'Invalid Vendor'
union select 'ReceiptOrderIsRequired',                      'Receipt Number is required'
union select 'ReceiptOrderAlreadyExists',                   'Receipt Order already exists'
union select 'ReceiptOrderDoesNotExist',                    'Receipt Order does not exist'
union select 'Import_ROH_CannotDeleteReceipt',              'Cannot delete receipt as some inventory has already been received against it'
union select 'Import_ROH_CannotInsertUpdateClosedReceipt',  'Cannot insert/update %1 as receipt is either closed/canceled'

/*------------------------------------------------------------------------------
pr_Imports_ValidateReceiptDetail:
------------------------------------------------------------------------------*/
union select 'Import_ROD_ReceiptLineAlreadyExists',         'Receipt Line already exists'
union select 'Import_ROD_ReceiptLineDoesNotExist',          'Receipt Line cannot be identified with given information'
union select 'Import_ROD_ReceiptNumberIsRequired',          'Receipt Number is required'
union select 'Import_ROD_InvalidReceiptNumber',             '%1 is not a valid Receipt Number'
union select 'Import_ROD_CannotDeleteReceiptDetail',        'Cannot delete receipt line as some inventory has already been received against it'
union select 'Import_ROD_InvalidOwnership',                 'Owner on the Receipt detail is different that on the header'

/*------------------------------------------------------------------------------
pr_Imports_ValidateOrderHeader:
------------------------------------------------------------------------------*/
union select 'PickTicketIsRequired',                        'PickTicket is required'
union select 'PickTicketAlreadyExists',                     'PickTicket already exists'
union select 'PickTicketDoesNotExist',                      'PickTicket does not exist'
union select 'OrderStatusInvalidForDelete',                 'PickTicket cannot be deleted as it is not in an appropriate status for deleting'

/*------------------------------------------------------------------------------
pr_Imports_ValidateOrderDetail:
------------------------------------------------------------------------------*/
union select 'HostOrderLineIsRequired',                     'HostOrderLine is required'
union select 'UnitsOrderedIsInvalid',                       'Invalid UnitsOrdered'
union select 'UnitsAuthorizedToShipIsInvalid',              'Invalid Units Authorized To Ship'
union select 'OrderDetailAlreadyExists',                    'OrderDetail already exists'
union select 'Import_OD_InvalidStatusToDelete',             'Order already in fulfillment and cannot be deleted'
union select 'Import_OD_InvalidStatusToUpdate',             'Invalid status to update the OrderDetail'

/*------------------------------------------------------------------------------
pr_Imports_ValidateSKU:
------------------------------------------------------------------------------*/
union select 'InvalidBusinessUnit',                         'Given BusinessUnit is invalid'

/*------------------------------------------------------------------------------
pr_Imports_ValidateCartonTypes:
------------------------------------------------------------------------------*/
union select 'Import_CartonTypeIsRequired',                 'Carton Type is required'
union select 'Import_CartonTypeAlreadyExists',              'Carton Type already exists'
union select 'Import_CartonTypeDoesNotExist',               'Carton Type does not exist'

/*------------------------------------------------------------------------------
pr_Imports_ValidateUPC:
------------------------------------------------------------------------------*/
union select 'Import_UPCIsRequired',                        'UPC is required'
union select 'Import_UPCDoesNotExist',                      'UPC does not exist'
union select 'Import_UPCAlreadyExistsForAnotherSKU',        'UPC already exists for another SKU'

/*------------------------------------------------------------------------------
pr_Imports_Contacts:
------------------------------------------------------------------------------*/
union select 'ContactIsRequired',                           'Contact is required'
union select 'ContactAlreadyExists',                        'Contact already exists'
union select 'ContactDoesNotExist',                         'Contact does not exist'
union select 'ContactTypeIsRequired',                       'Contact Type is required'
union select 'ContactTypeIsInvalid',                        'Contact Type is invalid'

/*------------------------------------------------------------------------------
pr_Imports_InventoryAdjustments:
------------------------------------------------------------------------------*/
union select 'ImportInvAdj_WarehouseIsRequired',            'Warehouse is required for inventory adjustments'
union select 'ImportInvAdj_OwnershipIsRequired',            'Ownership is required for inventory adjustments'
union select 'ImportInvAdj_BusinessUnitIsRequired',         'BusinessUnit is required for inventory adjustments'
union select 'ImportInvAdj_InvalidOperation',               'Invalid operation'
union select 'ImportInvAdj_LPNDoesNotExistInLocation',      'LPN does not exists in Location'
union select 'ImportInvAdj_LPNDoesNotExistToReduce',        'LPN does not exist'
union select 'ImportInvAdj_InsufficientQtyinLPN',           'Insufficient LPN quantity to adjust'

/*------------------------------------------------------------------------------
Receiving:
------------------------------------------------------------------------------*/
union select 'LPNCannotBeEmpty',                            'LPN cannot be Empty'
union select 'ReceivingLocationNotSet',                     'Receiving Location is not configured'

union select 'CannotReceiveMultipleReceiptsIntoOneLPN',     'Cannot receive multiple receipts into one LPN'

union select 'SKUMismatch',                                 'Given SKU is not matching with LPN SKU'
union select 'RecvOnlyToPicklaneLoc',                       'Can only receive directly into a Picklane Location'
union select 'Recv_WarehouseMismatch',                      'Cannot receive as Location Warehouse does not match with Receipt Warehouse'
union select 'Recv_InventoryClassMismatch',                 'Receipt detail Inventory class & LPN''s Inventory class mismatch'
union select 'Recv_LocationIsRequired',                     'Receiving Location is required, please scan a valid Location'

union select 'RecvInv_ReceivedExtraQty',                    'Received quantity exceeds the ordered quantity for %1 %2'
union select 'RecvInv_ReceivedBeyondMaxQty',                'Received beyond the maximum quantity allowed for %1 %2'

/*------------------------------------------------------------------------------
Receiver:
------------------------------------------------------------------------------*/
union select 'ReceiverNumberIsRequired',                    'Receiver Number is required'
union select 'ReceiverNumberIsInvalid',                     'Invalid Receiver Number'
union select 'ReceiverIsClosed',                            'Scanned Receiver is already closed'

union select 'ReceiverCreatedSuccessfully',                 'Receiver# %1 created successfully'
union select 'ReceiverUpdatedSuccessfully',                 'Receiver# %1 updated successfully'

union select 'Receipts_AssignASNLPNs_ReceiverClosed',       'Receiver is closed and you cannot assign LPNs to it'

union select 'Receipts_AssignASNLPNs_NoneUpdated',          'Note: None of the selected Receipts are assigned'
union select 'Receipts_AssignASNLPNs_SomeUpdated',          'Note: %1 LPNs from %RecordsUpdated of %TotalRecords selected Receipts have been assigned'
union select 'Receipts_AssignASNLPNs_Successful',           'Note: %1 LPNs from all selected Receipts (%TotalRecords) have been assigned successfully'

union select 'BoLNumberIsRequired',                         'BoL number is required'

union select 'Receiver_ModifyReceiver_Successful',          'Receiver# %1 modified successfully'
union select 'Receiver_Modify_AlreadyClosed',               'Receiver already closed and cannot be modified'
union select 'Receiver_Modify_NoChanges',                   'No changes to modify the Receiver'
union select 'Receiver_Modify_CannotChangeWH',              'Receiver assigned with Inventory. Warehouse change not allowed'

union select 'Receivers_CloseReceiver_NoneUpdated',         'Note: None of the selected Receivers are Closed'
union select 'Receivers_CloseReceiver_SomeUpdated',         'Note: %RecordsUpdated of %TotalRecords selected Receivers have been closed'
union select 'Receivers_CloseReceiver_Successful',          'Note: All selected Receivers (%TotalRecords) have been closed successfully'

union select 'Receivers_PrepareForReceiving_ExecuteInBackGround',
                                                            'Selected Receiver scheduled to be prepared for Receiving in background'

union select 'Receiver_Close_AlreadyClosed',                '%1 receiver is already closed and cannot be closed again'
union select 'Receiver_Close_LPNsinIntransit',              '%1 receiver was not closed because there are intransit LPNs'
union select 'Receiver_Close_LPNsinQC',                     '%1 receiver was not closed because there are QC LPNs'
union select 'Receiver_Close_LPNsNotPutaway',               '%1 receiver was not closed because all the LPNs are not putaway'

union select 'LPNs_UnAssignLPNs_NoneUpdated',               'Note: None of the selected LPNs are unassigned'
union select 'LPNs_UnAssignLPNs_SomeUpdated',               'Note: %RecordsUpdated of %TotalRecords selected LPNs have been unassigned'
union select 'LPNs_UnAssignLPNs_Successful',                'Note: All selected LPNs (%TotalRecords) have been unassigned successfully'

union select 'CreateLPNsToReceive1',                        'Created LPN %1 with quantity %2 unit(s) of SKU %3'
union select 'CreateLPNsToReceive',                         'Created %1 LPNs from %2 to %3  with quantity %4 unit(s) of SKU %5'
union select 'CreateLPNsToReceive_Pallet1',                 'Created LPN %1 with quantity %2 unit(s) of SKU %3 onto #Pallet %4'
union select 'CreateLPNsToReceive_Pallet',                  'Created %1 LPNs from %2 to %3 with quantity %4 unit(s) of SKU %5'
union select 'ExceedingQtyToReceive',                       'You do not have permission to create/receive more inventory than ordered'
union select 'ExceedingMaxQtyToReceive',                    'You do not have permission to create/receive more inventory than maximum quantity to be received'

union select 'ReceiverWHMismatch',                          'Receiver should be for the same Warehouse'
union select 'ReceiverReceiptWHMismatch',                   'Receiver and Receipt should be for the same Warehouse'

/*------------------------------------------------------------------------------
Picking Related:
------------------------------------------------------------------------------*/
union select 'PickTicketInvalidForPicking',                 'PickTicket is not ready or valid for Picking'
union select 'NoLPNToPickForPickTicket',                    'Inventory is not available to Pick'
union select 'NoUnitsAvailToPickForPickTicket',             'Units not available to Pick'
union select 'NoUnitsAvailToPickForBatch',                  'Units not available to pick for the #PickBatch'
union select 'InvalidFromLPN',                              'Invalid From LPN'
union select 'ScannedInvalidEntity',                        'Data input was not a SKU, LPN or Location to. Please input valid data to confirm the pick'
union select 'ToLPNAlreadyPickedForOtherSKU',               'Scanned Label/Tote used for another SKU on the Order'
union select 'BatchIsNotAllocated',                         'Wave is not allocated to start picking'
union select 'PickLPNFromSuggestedLocationOnly',            'Pick LPN from suggested Location only'
union select 'CannotPickUnitsFromLPN',                      'Cannot pick units for an LPN Pick'
union select 'TaskIsRequired',                              'Task Id is required'
union select 'InvalidPickZoneForTask',                      'Task %1 is not within Zone %2'
union select 'LPNAlreadyPicked',                            'Scanned LPN already Picked'
union select 'InvalidTaskForReplenishment',                 'Invalid task for replenishment picking, please use regular picking option instead.'
union select 'TaskPickGroupMismatch',                       'Mismatch of task pick group and selected picking operation. Please use valid picking operation'
union select 'ActiveTaskOnPallet',                          'Please complete the InProgress %1 Task %2 for wave %3'
union select 'TaskWasCancelled',                            'Task already cancelled'
union select 'TaskCompletedAlready',                        'Task already completed'
union select 'TaskNotAllocated',                            'Task is not allocated to start Picking'
union select 'TaskNotConfirmed',                            'Task is not confirmed to start Picking'
union select 'TaskPickGroupNotforRF',                       'Task is to be picked by WCS/WSS and cannot be picked on RF'
union select 'TaskPickGroupCTP',                            'Task is to be executed using Confirm Pick Tasks function'

union select 'LocationDiffFromSuggested',                   'Scanned Location is different from suggested Location'
union select 'PickedUnitsGTLPNQty',                         'Picked Units greater than LPN quantity'
union select 'InvalidPickZone',                             'Invalid Pick Zone'
union select 'InvalidPickingLPN',                           'Invalid Picking LPN'
union select 'PickToEmptyLPN',                              'Pick to an empty LPN'
union select 'UnitPickSuccessful',                          'Units Picked successfully'
union select 'CannotPickToSameLPN',                         'Cannot Pick to same LPN'
union select 'CannotPickToPickLane',                        'Cannot Pick to PickLane'
union select 'LPNConfirmSuccessful',                        'LPN Confirm successful'
union select 'Picking_PalletNotEmpty',                      'Scanned Pallet is not empty. Start picking using an empty Pallet.'
union select 'LPNsonPalletNotEmpty',                        'Some positions on the Pallet are not empty, hence Pallet cannot be used for Picking'

union select 'OrderShortPicked',                            'Order short picked'
union select 'BatchDoesNotExist',                           '#PickBatch does not exist'
union select 'BatchNotAvailableForPicking',                 '#PickBatch is not available for Picking'
union select 'BatchIsCompletelyPicked',                     'There are no more units to pick for the #PickBatch'
union select 'BatchPausedSuccesfully',                      '#PickBatch paused successfully'
union select 'PalletNotAvailableForPicking',                'Pallet is not available for Picking'
union select 'PickTicketNotOnaBatch',                       'PickTicket is not on a #PickBatch'
union select 'InvalidToLPN',                                'Invalid To LPN'
union select 'Picking_ScanValidTempLabel',                  'Scan the LPN that is suggested to be picked into'
union select 'PickingSKUMismatch',                          'Attempting to pick a SKU that does not match with the SKU on the Order or the Location'

union select 'PickingToAnotherPallet',                      'Scanned PickTo position is from a different Pallet'
union select 'InvalidPickingSKU',                           'Invalid Picking SKU'
union select 'PalletUsedWithAnotherBatch',                  'Scanned Pallet is already used with another #PickBatch'
union select 'Picking_PalletAlreadyPickedForTask',          'Scanned Pallet is not empty and had been picked for a Task'
union select 'ScannedPalletIsNotAssociatedWithTask',        'Scanned pallet is not built for this Task'
union select 'LocationIsInvalidForPicking',                 'Cannot pick from this Location'
union select 'TaskDoesNotExist',                            'Task does not exist'
union select 'TaskNotReleasedForPicking',                   'Task has not been released for picking'
union select 'BatchIdentifiedButTaskNotReleasedForPicking', 'Batch identified but no tasks are released for picking'
union select 'TaskNotAvailableForPicking',                  'Task is not available for picking'
union select 'TaskIsNotAssociatedWithThisBatch',            'Task is not associated with the scanned #PickBatch'
union select 'TaskIsNotAssociatedWithThisPickTicket',       'Task is not associated with the PickTicket'
union select 'CannotPickAllInvIntoOneLabel',                'Cannot pick total inventory into one label'
union select 'DroppedPalletComplete',                       'Pallet dropped successfully'
union select 'DropPallet_InvalidLocationType',              'Cannot drop pallet/cart in scanned Location Type'
union select 'DropPallet_InvalidZoneforVAS',                'This cart can only be dropped in VAS Zone'
union select 'DropPallet_LocationFromDiffZone',             'Scanned Location from different zone than suggested'
union select 'DropPallet_NoDisqualifiedOrdersToHold',       'No Dis-Qualified to be dropped at Hold locations'
union select 'DroppedPickedLPNComplete',                    'Picked LPN dropped succesfully'
union select 'PickedQtyIsdiffThanRequiredQty',              'Picked quantity is different from required quantity'
union select 'LPNTask_UseLPNPicking',                       'Scanned Task is LPN task, please use LPN Picking functionality instead'
union select 'BulkPull_InvalidPallet',                      'Pallet is not suggested for Bulk pull'
union select 'Picking_ScanToCartPositionInvalid',           'Please use Carton/LPN to pick the inventory onto the Pallet'
union select 'Picking_ConsolidatePick_CannotPickPartialUnits',
                                                            'Cannot pick partial units, Please pick total %1 units to confirm'
union select 'Picking_ConsolidatePick_CannotShortPick',     'Cannot short pick Consolidate quantity, please choose single scan!!'
union select 'ScannedPositionFromAnotherCart',              'Scanned Cart position is from another Cart'
union select 'CannotShortPick',                             'You do not have authorization to short pick. Please see Supervisor'
union select 'Picking_LocationOnHold',                      'Picking is restricted as location is OnHold'
union select 'Picking_LocationDoestNotAllow',               'Picking is restricted as location will not allow picking operation,Contact supervisor'
union select 'TaskIsDependentOnReplenishTask',              'Scanned Task is dependent on Replenish Task'
union select 'InvalidCombinationOfPalletAndWaveOrTask',     'Invalid combination of Pallet and Wave or Task'
union select 'ELCannotPickIntoDiffPosition',                'Employee Label orders can only be picked into suggested cart positions'
union select 'ScannedPosIsReservedForEL',                   'Scanned position is reserved for an Employee'
union select 'NotALPNTask_UseBatchPicking',                 'Scanned Task is not a LPN task, Please use batch Picking function instead'
union select 'Picking_PickListSummary',                     'Total: %1 Picks for %4 units'
union select 'Picking_PickListRemaining',                   'Remaining: %1 Picks - %3 units'
union select 'BatchPicking_UnitsPickSuccessful',            'Picked %1 %2 onto Pallet/Cart %3 for Task/Wave %4/%5' -- %1 is NumPicked, %2 is PickUoM, %3 is Cart %4 is TaskId, %5 is Batch

/*------------------------------------------------------------------------------
Picking-Substitution Related:
------------------------------------------------------------------------------*/
union select 'Substitution_LPNNotAValidCandidate',          'Scanned LPN is not a valid candidate for Substitution'
union select 'Substitute_LogicalLPNCannotBeSubstituted',    'Substitution is not allowed from Picklane'
union select 'Substitute_LPNsLocationsDifferent',           'Substitution is not allowed between LPNs of two different locations'
union select 'Substitute_NotAllowedBetweenMultiSKULPNs',    'Substitution is not allowed between multi SKU LPNs'
union select 'Substitute_LPNsHasDifferentSKUs',             'Scanned LPN has a different SKU than suggested'
union select 'Substitute_LPNsQuantityMismatch',             'Cannot substitute an LPN which has a different quantity than suggested LPN'
union select 'Substitute_LPNsUnavailableLine',              'Cannot substitute an LPN which does not have available quantity'
union select 'Substitute_NewLPNCannotBeSubstituted',        'Cannot substitute a new LPN, please Putaway LPN to Location first'
union select 'Substitute_InvalidLPNStatus',                 'LPN Status is invalid to substitute'
union select 'Substitute_OwnershipMismatch',                'Mismatch Ownership, Cannot substitute LPN which has a different Ownership inventory'
union select 'Substitute_WarehouseMismatch',                'Cannot substitute LPN from a different Warehouse'
union select 'Substitute_TaskSubTypeMismatch',              'Mismatch Task sub type, Cannot substitute LPN which has a different task sub type'
union select 'SubstitutionNotPossible',                     'Scanned LPN is not valid/suitable for substitution'
union select 'Substitution_InvalidPickMode',                'Substitution is not allowed for Consolidate picking process'

/*------------------------------------------------------------------------------*/
/* LPN Reservations */
/*------------------------------------------------------------------------------*/
union select 'LPNResv_InvalidWave',                         'Wave scanned is invalid'
union select 'LPNResv_InvalidPickTicket',                   'PickTicket scanned is invalid'
union select 'LPNResv_LPNHasNoInnerPacks_ProvideQty',       'LPN does not have InnerPacks to Reserve. Provide Qty instead'
union select 'LPNResv_LPNWasNotAllocatedToAnyOrder',        'LPN was not allocated to any order'
union select 'LPNResv_LPNWasNotReservedForAnyWave',         'LPN was not reserved to any wave'
union select 'LPNResv_OldOrderStatusInvalid',               'LPN order status invalid to Unassign'
union select 'LPNResv_LPNAlreadyAllocatedToOtherOrder',     'LPN is already allocated to other order'
union select 'LPNResv_NewOrderStatusInvalid',               'Order status invalid to Assign'
union select 'LPNResv_ManyOrderMatchCriteria',              'Cannot Assign/Reassign as many orders found with the given criteria'
union select 'LPNResv_LPNQtyMismatchWithUnitsPerCarton',    'LPN quantity mismatches with Order units per carton'
union select 'LPNResv_CannotIdentifyOrder',                 'Cannot identify any/given order to assign/reassign'
union select 'LPNResv_OrderDoesNotRequireSKU',              'Order does not require this SKU'
union select 'LPNResv_LPNHasMoreUnitsThanRequired',         'LPN has more units than the required for order'
union select 'LPNResv_InvalidCombination',                  'Invalid combination'
union select 'LPNResv_AllocatedSuccessfully',               'LPN %1 (%2 units of %3) has been assigned to Order %4'
union select 'LPNResv_UnallocatedSuccessfully',             'LPN %1 (%2 units of %3) has been unassigned from Order %5'
union select 'LPNResv_ReallocatedSuccessfully',             'LPN %1 (%2 units of %3) has been reassigned from Order %5 to Order %4'
union select 'LPNResv_LPNLost',                             'Cannot reserve a lost LPN'
union select 'LPNResv_OrderNotWavedYet',                    'Cannot reserve against an order which is not waved yet'
union select 'LPNResv_InvalidOrderStatus',                  'Order status not appropriate for LPN Reservation'
union select 'LPNResv_InvalidLPNStatus',                    'Invalid LPN status to reserve'
union select 'LPNResv_LPNIPSelectedIPMismatch',             'All of the LPN Innerpacks should be reserved when batch is given'
union select 'LPNResv_WaveQtyLPNQtyMismatch',               'Wave required quantity not reserved. For the quantity to be reserved, provide PickTicket value'
union select 'LPNResv_LPNWaveOrderWaveMismatch',            'LPN picked for another batch. Order and LPN attached to different batches'
union select 'LPNResv_ReserveMoreThanOrderQuantity',        'Choosen LPN Quantity %1 units is more than Order required quantity %2'
union select 'LPNResv_ReserveMoreThanSKUQuantity',          'Choosen LPN Quantity is %1 units but only %2 units required'
union select 'LPNResv_MultiSKUFullLPNMustProvidePT',        'For multi SKU LPN, full LPN reservation must provide PickTicket'
union select 'LPNResv_MultiSKUNoPartialReservation',        'For multi SKU LPN, partial reservation is not possible'
union select 'LPNResv_SingleSKUNoPartialReservation',       'For single SKU LPN, partial reservation is prohibited under controls'
union select 'LPNResv_OrderVSLPNQuantityMismatch',          'One or many LPN SKU quantity is greater than respective Order SKU quantity'
union select 'LPNResv_LPNInventoryClassMismatch',           'Order SKU Inventory class & LPN''s Inventory class mismatch'
union select 'LPNResv_SelectedQtyNotMultipleOfLPNIP',       'Input quantity is not a multiple of LPN innerpack value'
union select 'LPNResv_LPNOwnershipMismatch',                'Given LPN Ownership mismatched with given Wave/PickTicket'
union select 'LPNResv_LPNAllocatedtoNonBulkOrder',          'LPN allocated to a Non-bulk Order cannot be Reserved for another Order'
union select 'LPNResv_AllocatedLPNCannotBeReserved',        'Allocated LPN cannot be reserved for a Wave'
union select 'LPNResv_LPNAlreadyReservedForWave',           'LPN already reserved for a Wave'
union select 'LPNResv_FixtureLPNTypeWaveTypeMismatch',      'Fixtures: LPN type does not match with wave type'
union select 'LPNResv_FixtureLPNNotProportionalToOrder',    'LPN quantity is not proportional to the Order Quantity. Please use other LPN'
union select 'LPNResv_MultiSKULPNMultipleCartons',          'Multi SKU LPN reservation cannot be reserved to multiple Ship cartons. Please use Directed allocation instead'
union select 'LPNResv_ShipCartonNeedsMultiSKULPN',          'Generated Ship Carton requires Multi SKU LPN to be reserved. Please use Directed allocation instead'
union select 'LPNResv_LPNReservedForWave',                  'LPN already reserved for the wave provided'
union select 'LPNResv_OrderAlreadyReserved',                'Given order has no units left to be reserved'
union select 'LPNResv_LPNOrderWarehouseMismatch',           'LPN Warehouse is different from Order Warehouse'
union select 'LPNResv_WaveWarehouseMismatch',               'Wave generated is for different Warehouse than LPN and Order'
union select 'LPNResv_LPNReservedForPickTicket',            'LPN already reserved for the PickTicket provided'
union select 'LPNResv_ShipCartonsPartialActivation',        'Ship Carton %1 has Qty reserved: %3, Qty not reserved %2. LPN does not satisfy Ship Carton(s) generated'
union select 'LPNResv_LPNPartialActivation',                'LPN %1 with SKU %2 has residual Qty %3 that could not be reserved with any Ship Cartons'
union select 'LPNResv_InsufficientShipCartonsGenerated',    'No/Insufficient Ship Cartons generated for PickBatchNo/PickTicket provided'
union select 'LPNResv_ReserveAgainstBulkOrder',             'Wave has a bulk order, please reserve inventory to bulk order instead of customer order'

/*------------------------------------------------------------------------------*/
/* LPN Activations */
/*------------------------------------------------------------------------------*/
/* Ship Cartons */
union select 'LPNActv_ShipCartons_WarehouseMismatch',               'Cannot activate ship carton from different Warehouse'
union select 'LPNActv_ShipCartons_InvalidLPN',                      'Invalid LPN. Please check the LPN scanned. Scan LPN, UCCBarcode or TrackingNo'
union select 'LPNActv_ShipCartons_InvalidLPNType',                  'Invalid LPN Type'
union select 'LPNActv_ShipCartons_LPNActivated',                    'LPN is already %1 or Activated'
union select 'LPNActv_ShipCartons_AlreadyActivatedandOnPallet',     'LPN is already Activated and on the Pallet'
union select 'LPNActv_ShipCartons_InvalidLPNStatus',                'Invalid LPN Status to Activate. LPN is already %1'
union select 'LPNActv_ShipCartons_InvalidOrder',                    'Invalid Order. Ship Carton not attached to any Order'
union select 'LPNActv_ShipCartons_NoInventoryToActivate',           'Cannot activate Ship Carton. There are no LPNs reserved against the wave %1'
union select 'LPNActv_ShipCartons_InvalidLocation',                 'Scanned location is not valid. Not configured on the system.'
union select 'LPNActv_ShipCartons_InvalidPallet',                   'Scanned pallet is not valid. Not configured on the system.'
union select 'LPNActv_ShipCartons_InsufficientInvToActivate',       'Insufficient Inventory Reserved. Reserved Qty: %1 and ShipCarton Qty: %2'
union select 'LPNActv_ShipCartons_ActivationUnsuccessful',          'One of the Ship Cartons could not be completely reserved'
union select 'LPNActv_ShipCartons_AllLinesCannotBeActivated',       'Ship Carton items are not completely reserved. Cannot be activated completely'
union select 'LPNActv_ShipCartons_InvalidLocationType',             'Scanned To Location cannot be Reserve/Bulk/Picklane'
union select 'LPNActv_ShipCartons_InvalidLocationStatus',           'Invalid To Location scanned. Location status is %1'
union select 'LPNActv_ShipCartons_InvalidPalletType',               'Invalid Pallet scanned. Pallet type is %1'
union select 'LPNActv_ShipCartons_InvalidPalletStatus',             'Invalid Pallet scanned. Pallet status is %1'
union select 'LPNActv_ShipCartons_PalletMismatch',                  'Pallet mismatch. Pallet scanned earlier %1, Pallet scanned now %2'

/* Auto Activation */
union select 'AutoActivation_WaveNotQualified',                     'Wave %1 excluded from Auto Activation'

/*------------------------------------------------------------------------------
  Replenishments
------------------------------------------------------------------------------*/
union select 'ReplenishOrders_ChangePriority_NoneUpdated',  'Note: Priority was not updated on any of the selected Orders'
union select 'ReplenishOrders_ChangePriority_SomeUpdated',  'Note: Priority was updated on %RecordsUpdated of the %TotalRecords selected Orders'
union select 'ReplenishOrders_ChangePriority_Successful',   'Note: Priority was updated on all (%RecordsUpdated) selected Orders'

union select 'PriorityIsRequired',                          'Priority is required and needs to be specified'

union select 'ReplenishOrders_Archive_AlreadyArchived',     'Replenish Order %1 is already Archived and hence is not updated'
union select 'ReplenishOrders_Archive_InvalidStatus',       'Replenish Orders %1 is in %2 status and cannot be archived'

union select 'ReplenishOrders_Archive_NoneUpdated',         'Note: None of the selected Orders are archived'
union select 'ReplenishOrders_Archive_SomeUpdated',         'Note: %RecordsUpdated of %TotalRecords selected Orders are archived'
union select 'ReplenishOrders_Archive_Successful',          'Note: All selected Orders (%RecordsUpdated) have been archived successfully'

union select 'ReplenishOrders_Cancel_NoneUpdated',          'Note: None of the selected Orders are Canceled'
union select 'ReplenishOrders_Cancel_SomeUpdated',          'Note: %RecordsUpdated of %TotalRecords selected Orders were canceled'
union select 'ReplenishOrders_Cancel_Successful',           'Note: All selected Orders (%RecordsUpdated) have been canceled successfully'

union select 'ReplenishOrders_Close_NoneUpdated',           'Note: None of the selected Orders are closed'
union select 'ReplenishOrders_Close_SomeUpdated',           'Note: %RecordsUpdated of %TotalRecords selected Orders are closed'
union select 'ReplenishOrders_Close_Successful',            'Note: All selected Orders (%RecordsUpdated) have been closed successfully'

union select 'RO_GenerateOrders',                           'Replenish Wave %1 (Order %2) created successfully for selected locations'

/* these don't belong here - the are for receipt orders*/
union select 'ROModify_InvalidOrders',                      ', %1 Orders were not updated due to invalid status'
union select 'ROClose_LPNsNotPutaway',                      ', %1 Orders were not closed due to some LPNs not being Putaway'

/*------------------------------------------------------------------------------*/
/* Pick Batches */
/*------------------------------------------------------------------------------*/
union select 'PlanBatch_InvalidStatus',                     'Invalid #PickBatch status to plan'

/*------------------------------------------------------------------------------*/
/* Wave Release */
/*------------------------------------------------------------------------------*/
union select 'WaveRelease_InvalidUnitWgtVolNestingFactor',  'Cannot release Wave %1, Wave having SKUs with invalid Pack Config'
union select 'WaveRelease_OnlyCustomerOrders',              'Cannot release Wave %1, Wave can only have Customer Orders'
union select 'WaveRelease_OnlyBulk_OR_Customer_Orders',     'Cannot release Wave %1, Wave can only have Customer Orders or Bulk Orders'
union select 'WaveRelease_OnlyReplenishOrders',             'Cannot release Wave %1, Wave can only have Replenish Orders'
union select 'WaveRelease_OnlyPickToShipOrders',            'Cannot release Wave %1, Wave can only have Pick To Ship Orders'
union select 'WaveRelease_NoCartonTypes',                   'Cannot release Wave %1, Some Customer Orders on the wave do not have Carton Types setup'
union select 'WaveRelease_OnlySameCustomerOrders',          'Cannot release Wave %1, Wave can only have same customer for all orders'
union select 'WaveRelease_OnlySpecificAccountOrders',       'Cannot release Wave %1, Wave can only have %2 orders'
union select 'WaveRelease_CannotHaveReplenishOrders',       'Cannot release Wave %1, Wave can have replenish order(s) only if it is a Replenish Wave(s)'
union select 'WaveRelease_CannotHaveTransferOrders',        'Cannot release Wave %1, Wave can have Transfer order(s) only if it is a Transfer Wave'
union select 'WaveRelease_CannotHaveReworkOrders',          'Cannot release Wave %1, Wave can have Rework order(s) only if it is a Rework Wave'
union select 'WaveRelease_PickBinsNotSetUpForSomeSKUs',     'Cannot release Wave %1, Picklanes are not set up for some of the SKUs on the Wave'
union select 'WaveRelease_OrderCategory1Missing',           'Cannot release Wave %1, Some Orders do not have Category1'
union select 'WaveRelease_OrdersOrUnitsExceededThresholdValue',
                                                            'Cannot release Wave %1, Wave exceeded Orders or Units threshold value'
union select 'WaveRelease_OrderVolumeExceedsThresholdValue',
                                                            'Cannot release Wave %1, Volume of some orders on the wave is high for this type of wave'
union select 'WaveRelease_InvalidShipVia',                  'Cannot release Wave %1, Some Orders have invalid Ship Via'
union select 'WaveRelease_InvalidCarrier',                  'Cannot release Wave %1, Some Orders have invalid Carrier'
union select 'WaveRelease_InvalidAddress',                  'Cannot release Wave %1, Some Orders have invalid Address'
union select 'WaveRelease_OrderMissingShipToCity',          'Cannot release Wave %1, Orders %2 does not have City specified on Ship To address'
union select 'WaveRelease_OrderHasInvalidShipToZip',        'Cannot release Wave %1, Orders %2 is shipping to US, but ShipTo Zip (%3) seems to be invalid'
union select 'WaveRelease_OrderMissingShipToState',         'Cannot release Wave %1, Orders %2 does not have State specified on Ship To address'
union select 'WaveRelease_MissingAESNumber',                'Cannot release Wave %1, Orders %2 is shipping international (to %3) and requires AESNumber to ship'
union select 'WaveRelease_MissingFreightTerms',             'Cannot release Wave %1, Orders %2 is shipping via Small Package carrier but does not have FreightTerms specified'
union select 'WaveRelease_MissingSalePrice',                'Cannot release Wave %1, Orders %2 is shipping international and requires Unit Price (for customs)'
union select 'WaveRelease_MissingPhoneNumber',              'Cannot release Wave %1, Orders %2 is shipping via %3 and requires Phone Number'
union select 'WaveRelease_MissingShipFromPhoneNo',          'Cannot release Wave %1, Order %2 is shipping via %3 and requires Ship From Phone Number'
union select 'WaveRelease_MissingShipFromContact',          'Cannot Process the Order %1, Order has ShipFrom of %2 and the address is not setup for this Ship From'
union select 'WaveRelease_MissingWarehouseContact',         'Cannot Process the Order %1, Order ships from Warehouse %2 and the address is not setup for this Warehouse'
union select 'WaveRelease_CannotShipGroundtoPR',            'Cannot release Wave %1, Orders %2 cannot be shipped via %3 to State/territory %4'
union select 'WaveRelease_HasReplenishOrders',              'Cannot release Wave %1, Wave has Replenish Order %2 on it. Please remove it.'
union select 'WaveRelease_MissingCartonTypes',              'Cannot release Wave %1, Customer Orders %2 on the wave do not have Carton Types setup'
union select 'WaveRelease_SKUwithInvalidPackConfig',        'Cannot release Wave %1, SKU %2 has invalid pack config (Unitweight: %3, UnitVolume %4)'
union select 'WaveRelease_SKUWithInvalidNestingFactor',     'Cannot release Wave %1, SKU %2 has invalid Nesting factor of %3'
union select 'WaveRelease_MissingPickBinsForSKU',           'Cannot release Wave %1, SKU %2 does not have a Pick bin setup'
union select 'WaveRelease_ODsWithInvalidUnitsPerCarton',    'Cannot release Wave %1, Order detail with SKU %2 has invalid Units/Carton %3'
union select 'WaveRelease_ODsWithoutPackingGroup',          'Cannot release Wave %1, Packing Group not defined on Order detail with SKU %2 & Host Order Line %3'
union select 'WaveRelease_OrdersWithInvalidPackCombination','Cannot release Wave %1, Packing Group %2 has invalid pack combination ratio'
union select 'WaveRelease_ShipViaInvalid',                  'Cannot release Wave %1, Orders %2 has invalid ShipVia'
union select 'WaveRelease_CarrierInvalid',                  'Cannot release Wave %1, Orders %2 is not associated with a valid Carrier to ship the order'
union select 'WaveRelease_InternationalorVASOrder',         'Cannot release Wave %1, Wave has international/VAS Order %2'

union select 'WaveRelease_NoDropLocationOrShipDate',        'Cannot release Wave %1, Drop Location or Ship Date is not specified on Wave'
union select 'WaveRelease_WarehouseMismatch',               'Cannot release Wave %1, Selected DropLocation Warehouse(%2) is not same as Wave Warehouse(%1)'
union select 'WaveRelease_CaseBinsNotSetUpForSomeSKUs',     'Cannot release Wave %1, Case bins not setup for some SKUs on Wave'
union select 'WaveRelease_AESNumberMissing',                'Cannot release Wave %1, Some Orders requires AESNumber to ship'
union select 'WaveRelease_FreightTermsMissing',             'Cannot release Wave %1, Some Orders requires FreightTerms'
union select 'WaveRelease_SalePriceMissing',                'Cannot release Wave %1, Some Orders requires UnitPrice'
union select 'WaveRelease_PhoneNumberMissing',              'Cannot release Wave %1, Some Orders requires PhoneNumbers'
union select 'WaveRelease_PRStates',                        'Cannot release Wave %1, UPSG Orders are with PR States'
union select 'WaveRelease_InvalidShipLabelFormat',          'Cannot release Wave %1, Orders %2 has invalid Ship Label Format'
union select 'WaveRelease_InvalidContentLabelFormat',       'Cannot release Wave %1, Orders %2 has invalid Content Label Format'
union select 'WaveRelease_InvalidPackingListFormat',        'Cannot release Wave %1, Orders %2 has invalid Packing List Format'

union select 'WaveRelease_PickBinsNotSetToPickUnits',       'Cannot release Wave %1, Pick bins are not set up to pick Units'
union select 'WaveRelease_NotEnoughInPickBinsToPickUnits',  'Cannot release Wave %1, Pick bins do not have enough inventory to pick Units'

union select 'WaveRelease_SLWaveWithMultiLineOrders',       'Cannot release Single Line Wave %1, some Orders on the Wave are multi line'
union select 'WaveRelease_WaveNeedsSystemReservation',      'Cannot release Wave %1, Allocation Model for Wave should be System Reservation'
union select 'WaveRelease_OrdersWithMultipleLabelCodes',    'Cannot release Wave %1, Order %2 has multiple Label Codes'
union select 'WaveRelease_OrderDetailsWithInvalidPrepackRatio',
                                                            'Cannot release Wave %1, Order Line %3, SKU %4 on Order %2 has invalid Prepack ratio %5'
/*------------------------------------------------------------------------------*/
/* Batch Picking */
/*------------------------------------------------------------------------------*/
union select 'InvalidBatchStatus',                          'Can only create a Consolidated Order for the #PickBatch if the #PickBatch is in Ready to Pick status'

union select 'PickingToWrongOrder',                         'Wrong Position: Attempting to Pick to another position'
union select 'AllocatedQtyIsGreaterThanRequiredQty',        'Allocated Quantity is greater than required quantity'

union select 'DropPalletOnlyToStagingOrDock',               'Can only drop Pallet at a Staging or Dock Location.'
union select 'CannotSubstituteAnyLPNWithAOpenLPN',          'Cannot Substitute any LPN with an open LPN'
union select 'CannotDropToPicklane',                        'Cannot drop to a PickLane Location.'
union select 'NoBatchesToPick',                             'No #PickBatches available to pick'
union select 'BatchUsedWithAnotherPallet',                  '#PickBatch is already used with another Pallet'
union select 'BusyInBatchAssignment',                       'System is busy in processing multiple requests, Please try again!'

union select 'MultipleOwnersOnBatch',                       'Cannot Create a Consolidated Order for the #PickBatch, because it has Orders for multiple owners'
union select 'MultipleWarehousesOnBatch',                   'Cannot Create a Consolidated Order for the #PickBatch, because it has Orders for multiple Warehouses'

union select 'PicksCompletedInScannedZone',                 'There are more picks to be done to complete Task %3 of Wave %2'
union select 'BatchPickComplete',                           'All picks are completed for Task %3 of Wave %2'

/*------------------------------------------------------------------------------*/
/* Pick Batches */
/*------------------------------------------------------------------------------*/
union select 'PickBatch_AddOrderDetails_NoneUpdated',       'Note: None of the selected Order Details added to #PickBatch'
union select 'PickBatch_AddOrderDetails_SomeUpdated',       'Note: %RecordsUpdated of %TotalRecords selected Order Details have been added to #PickBatch'
union select 'PickBatch_AddOrderDetails_Successful',        'Note: All selected Order Details (%RecordsUpdated) have been add to #PickBatch'

union select 'PickBatch_AddOrders_MultipleWarehouses',      'Cannot add Orders from multiple Warehouses to a #PickBatch'
union select 'PickBatch_AddOrders_MultipleGroups',          'Cannot add Orders from multiple Customer POs to same #PickBatch'
union select 'PickBatch_AddOrders_MultipleOwners',          'Cannot add Orders from multiple Owners to same #PickBatch'

union select 'BatchAlreadyConsolidated',                    '#PickBatch is already Consolidated'

union select 'PickBatch_ClearUser_Successful',              'Note: All selected #PickBatches (%RecordsUpdated) have been unassigned successfully'

union select 'Waves_ApproveToRelease_NoneUpdated',           'Note: None of the selected Waves are approved for release'
union select 'Waves_ApproveToRelease_SomeUpdated',           'Note: %RecordsUpdated of %TotalRecords selected Waves have been approved for release'
union select 'Waves_ApproveToRelease_Successful',            'Note: All selected Waves (%RecordsUpdated) have been approved for release'

union select 'Waves_ReleaseForAllocation_NoneUpdated',      'Note: None of the selected #PickBatches are released for allocation'
union select 'Waves_ReleaseForAllocation_SomeUpdated',      'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been released for allocation'
union select 'Waves_ReleaseForAllocation_Successful',       'Note: All selected #PickBatches (%RecordsUpdated) have been released for allocation successfully'
union select 'ReleaseForAllocation_InvalidWaveStatus',      'Wave %1 is in %2 status, so the Wave cannot be released now'
union select 'ReleaseForAllocation_WaveHasNoOrders',        'Wave cannot be Released as it does not have orders associated with it.'
union select 'ReleaseForAllocation_WaveNotApprovedYet',     'Wave %1 has to be verified and approved before it can be Released'

union select 'Waves_ReleaseForPicking_NoneUpdated',         'Note: None of the selected #PickBatches are released for picking'
union select 'Waves_ReleaseForPicking_SomeUpdated',         'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been released for picking'
union select 'Waves_ReleaseForPicking_Successful',          'Note: All selected #PickBatches (%RecordsUpdated) have been released for picking successfully'

union select 'Waves_PreprocessOrders_NoneUpdated',          'Note: None of the selected orders are flagged for Pre-process'
union select 'Waves_PreprocessOrders_SomeUpdated',          'Note: %RecordsUpdated of %TotalRecords selected orders have been flagged for Pre-process'
union select 'Waves_PreprocessOrders_Successful',           'Note: All selected orders (%RecordsUpdated) have been flagged for Pre-process'

union select 'Orders_Reprocess_InvalidOrderStatus',         'Order %1 is in %2 status, so the order cannot be Pre-processed now'

union select 'Wave_RFP_NotRequired',                        '%1- Not required'
union select 'Wave_RFP_NotValidTypeToRelease',              '%1- Selected type of Wave does not need to be released'
union select 'Wave_RFP_WaveStatusNotValid',                 '%1- Wave status is not valid'
union select 'Wave_RFP_WaitingOnReplenishment',             '%1- Waiting on replenishment'
union select 'Wave_RFP_LabelGenerationIncomplete',          '%1- Label generation not completed'
union select 'Wave_RFP_ShippingDocsNotExported',            '%1- Shiping documents export is not completed'
union select 'Wave_RFP_TasksNotReadyToConfirm',             '%1- Task(s) not ready to confirm for Picking'
union select 'Wave_RFP_Successful',                         'Note: All the selected waves have been released for picking successfully'

union select 'Waves_Modify_NoneUpdated',                    'Note: None of the selected #PickBatches are updated'
union select 'Waves_Modify_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been updated'
union select 'Waves_Modify_Successful',                     'Note: All selected #PickBatches (%RecordsUpdated) have been updated successfully'
union select 'Waves_Modify_SamePriority',                   'Wave %1 already is of Priority %2 and hence was not updated'
union select 'Waves_Modify_InvalidStatus',                  'Wave %1 is in %2 status, so the Wave cannot be modified now'

union select 'Waves_Reallocate_NoneUpdated',                'Note: %TotalRecords wave(s) have not been allocated as they may not have not released or already being allocated in the background'
union select 'Waves_Reallocate_SomeUpdated',                'Note: %RecordsUpdated of %TotalRecords waves successfully allocated. Remaining may not have been released or already being allocated in the background'
union select 'Waves_Reallocate_Successful',                 'Note: All selected #PickBatches (%RecordsUpdated) have been Reallocated successfully'
union select 'Waves_Reallocate_InvalidWaveStatus',          'Wave %1 is in %2 status, so the Wave cannot be Reallocated now'
union select 'Waves_Reallocate_AllocationInprogress',       'Wave %1 cannot be reallocated as allocation is in-progress, please try again after few minutes'

union select 'Waves_Cancel_NoneUpdated',                    'Note: None of the selected #PickBatches are cancelled'
union select 'Waves_Cancel_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been cancelled'
union select 'Waves_Cancel_Successful',                     'Note: All selected #PickBatches (%RecordsUpdated) have been cancelled successfully'

union select 'Waves_UnPlan_NoneUpdated',                    'Note: None of the selected #PickBatches are unplanned'
union select 'Waves_UnPlan_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been unplanned'
union select 'Waves_UnPlan_Successful',                     'Note: All selected #PickBatches (%RecordsUpdated) have been unplanned successfully'

union select 'Waves_Plan_NoneUpdated',                      'Note: None of the selected #PickBatches are planned'
union select 'Waves_Plan_SomeUpdated',                      'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been planned'
union select 'Waves_Plan_Successful',                       'Note: All selected #PickBatches (%RecordsUpdated) have been planned successfully'

union select 'InvalidBatch',                                '#PickBatch is Invalid'
union select 'CancelBatch_InvalidStatus',                   'Invalid #PickBatch status to cancel'
union select 'CancelWave_InvalidStatus',                    'Invalid Wave status to cancel'
union select 'CancelWave_AllocationInProcess',              'Cannot cancel the Wave as it is being allocated currently in the back ground. Please cancel the wave later'
union select 'CancelWave_AlreadyReleased',                  'Cannot cancel the Wave as it is already released and you do not have authorization to cancel Waves in progress'
union select 'CancelWave_UnallocateUnitsFirst',             'Cannot cancel the Wave as it is inventory allocated to the wave, So please unallocate the inventory first'
union select 'WaveCancel_Deferred',                         'Note: Selected %1 Wave is in the process of being canceled'

union select 'DropPallet_InvalidLocation',                  'Invalid Location for dropping the Pallet'
union select 'DropPallet_InvalidWarehouse',                 'Invalid Warehouse Location for dropping the Pallet'
union select 'DropPallet_EmptyPallet',                      'Cannot drop an empty Pallet into a Location'
union select 'DropPallet_InvalidOperation',                 'Operation is Invalid'
union select 'DropPallet_TasksInProgress',                  'Cannot drop pallet as few of the picks are yet to be completed'
union select 'DropPallet_NotaPickingPallet',                'Not a picking cart/pallet to drop'
union select 'DropPallet_NoTaskAssociatedWithThePallet',    'No task is associated with this pallet to drop'
union select 'DropPickedLPN_InvalidLocation',               'Invalid Location for dropping the Picked LPN'
union select 'DropPallet_InvalidPalletStatus',              'Invalid Pallet status'

union select 'PickBatch_AddOrders_NoneUpdated',             'Note: None of the selected Orders added to #PickBatch'
union select 'PickBatch_AddOrders_SomeUpdated',             'Note: %RecordsUpdated of %TotalRecords selected Orders have been added to #PickBatch'
union select 'PickBatch_AddOrders_Successful',              'Note: All selected Orders (%RecordsUpdated) have been add to #PickBatch'
union select 'ModifyBatch_InvalidStatus',                   'Cannot modify #PickBatch of this status'
union select 'PickedQtyIsGreaterThanTaskQty',               'Picked quantity is greater than the Task quantity'

union select 'Wave_RemoveOrders_CancelShipCartons',         'Cancel the Ship Carton %2 first and then remove the Order %1 from the Wave %3'
union select 'Wave_RemoveOrders_NotOnWave',                 'Order %1 is not associated with any wave to be removed from a Wave'
union select 'Wave_RemoveOrders_InvalidOrderStatus',        'Order %1 is %2 and cannot be removed from Wave %3'
union select 'Wave_RemoveOrders_InvalidWaveStatus',         'Wave %3 is in %4 status and orders cannot be removed anymore'
union select 'Wave_RemoveOrders_WaveAlreadyReleased',       'Order %1 cannot be removed from Wave %2 as Wave is already released and you do not have authorization to Remove orders from Released Waves'
union select 'Wave_RemoveOrders_AllocationInProgress',      'Orders cannot be removed from Wave %2 as allocation is in-progress, please try again after few minutes'
union select 'Wave_RemoveOrders_UnitsReserved',             'Order %1 has units assigned, unallocate those units and then remove Order from wave'
union select 'Wave_RemoveOrders_TasksOutstanding',          'Order %1 has outstanding Pick tasks, cancel them and then remove Order from wave'
union select 'Wave_RemoveOrders_OrderInReservationProcess', 'Order %1 has units assigned, unallocate those units and then remove order from wave'
union select 'Wave_RemoveOrders_BulkOrderNotValid',         'Order %1 cannot be removed from Wave %2 as it is a Bulk pull Order'
union select 'Wave_RemoveOrders_ReplenishNotValid',         'Order %1 cannot be removed from Wave %2 as it is as Replenish Order'

/* Manage Waves */
union select 'WavesCreatedSuccessfully',                    'Successfully generated %1 waves, Generated waves from %2 to %3'
union select 'WaveCreatedSuccessfully',                     'Successfully generated %1 wave - wave %2'
union select 'WavesNotCreated',                             'Unable to generate waves.'

union select 'Waves_Generate_Successful',                   'Wave %1 generated with %2 Order(s)'
union select 'Waves_Generate_SomeOrdersNotWaved',           'Note: %1 of the selected %2 Order(s) have not been waved with selected criteria'

union select 'OrderHeader_AddOrdersToWave_NoneUpdated',     'Note: None of the selected Orders(Detail)s were added to Wave'
union select 'OrderHeader_AddOrdersToWave_SomeUpdated',     'Note: %RecordsUpdated of %TotalRecords selected Orders(Detail)s have been added to Wave successfully'
union select 'OrderHeader_AddOrdersToWave_Successful',      'Note: All selected Order(Detail)s (%RecordsUpdated) have been added to Wave successfully'

union select 'Wave_AddOrders_WaveIsInvalid',                'Given input %1 is not a valid Wave'
union select 'Wave_AddOrders_WaveStatusInvalid',            'Cannot add Order(s) to Wave %1 as it is in %2 status'
union select 'Wave_AddOrders_MultipleWarehouses',           'Cannot add Orders to Wave %1 as the Orders are for multiple Warehouses'
union select 'Wave_AddOrders_MultipleGroups',               'Cannot add Orders to Wave %1 as the Orders are for multiple groups'
union select 'Wave_AddOrders_WaveGroupMismatch',            'Cannot add Order %1 to Wave %2 as Order group (%4) and Wave group (%5) are different'
union select 'Wave_AddOrders_WarehouseMismatch',            'Cannot add Order %1 to Wave %2 as Order Warehouse (%4) and Wave Warehouse (%5) are different'
union select 'Wave_AddOrders_OrderInvalidStatus',           'Cannot add Order %1 to Wave %2 as Order is in %3 status'
union select 'Wave_AddOrders_BulkOrderNotValid',            'Cannot add Bulk Order %1 to Wave %2'
union select 'Wave_AddOrders_ReplenishNotValid',            'Cannot add Replenish Order %1 to Wave %2'

/* Batch Pallet Picking */
union select 'NoPalletPicksForTheBatch',                    'No Pallet Picks available for the #PickBatches'
union select 'NoPalletsAvailToPickForBatch',                'No Pallets available to pick for the #PickBatch'
union select 'InvalidFromPallet',                           'Invalid From Pallet'
union select 'InvalidPickingPallet',                        'Invalid Picking Pallet'
union select 'PalletClosedForPicking',                      'Pallet not available for Picking'

/* Confirm Task Picks */
union select 'ConfirmTaskPicks_InValidTaskId',              'Invalid TaskId'
union select 'ConfirmTaskPicks_ToLPNRequired',              'Ship Carton is Required'
union select 'ConfirmTaskPicks_InvalidToLPN',               'Invalid Ship Carton'
union select 'ConfirmTaskPicks_ToLPNAlreadyShipped',        'Ship Carton is already Shipped'
union select 'ConfirmTaskPicks_ToLPNAlreadyPicked',         'Ship Carton is already Picked'
union select 'ConfirmTaskPicks_ToLPNInvalidStatus',         'Invalid To-LPN status'
union select 'ConfirmTaskPicks_InValidToLPNStatus',         'Ship Carton status is Invalid for Task Pick'
union select 'ConfirmTaskPicks_LPNPTMismatch',              'Scanned PickTicket and LPN PickTicket are mismatched'
union select 'ConfirmTaskPicks_TaskHasAlreadyStarted',      'Task has been already Started'
union select 'ConfirmTaskPicks_InvalidTaskStatus',          'Invalid Task Status'
union select 'ConfirmTaskPicks_OrderShippedOrCancelled',    'Order is Shipped Or Cancelled'
union select 'ConfirmTaskPicks_UserDoesNotHavePermissions', 'User Does Not have Permissions for Task Picks'

union select 'ConfirmTaskPicks_MismatchInput',              'Mismatch input when compared to actual task pick details'
union select 'ConfirmTaskPicks_InvalidInput',               'Any one or more entities in input are invalid'
union select 'ConfirmTaskPicks_Errors',                     'There are errors due to From/To LPNs. Please evaluate'

union select 'ConfirmTaskPicks_InvalidTaskStatus',          'Invalid Task Status'
union select 'ConfirmTaskPicks_InvalidTaskType',            'Invalid Task Type'
union select 'ConfirmTaskPicks_InventoryIsDependentOnReplenish',
                                                            'Inventory to be picked is dependent on Replenishment, Please complete dependent Replenish task first'
union select 'TaskPickCompleted',                           'Confirmed picking %Quantity units into Carton %LPN for PickTicket %PickTicket'

/* Close PickBatch Action */
union select 'CloseWaveStart',                              '#PickBatch %1 has been initiated to close'
union select 'CloseWave_LoadingLPNs',                       '%1 LPNs are Loading'
union select 'CloseWave_LoadedLPNs',                        '%1 of %2 LPNs are Loaded'
union select 'CloseWave_UnallocateLPNs',                    '%1 of %2 LPNs are Unallocated'
union select 'CloseWave_CancelTasks',                       '%1 of %2 Tasks have been cancelled'
union select 'CloseWave_ClearTotes',                        '%1 of %2 Totes have been cleared'
union select 'CloseWave_CloseOrderCount',                   '%1 Orders are closed'
union select 'CloseWave_Successful',                        '#PickBatch %1 is closed successfully'

/*------------------------------------------------------------------------------
pr_RFC_ReceiveASNLPN:
------------------------------------------------------------------------------*/
union select 'ASNLPNReceivedSuccessfully',                  'LPN %1 with %4 units of SKU %3 received against RO/Receiver %2'
union select 'ASNLPNPalletizedSuccessfully',                'LPN %1 with %4 units of SKU %3 received against RO/Receiver %2 onto Pallet %5'
union select 'ASNCaseDoesNotExist',                         'ASN Case does not exist'
union select 'ASNCaseStatusIsInvalid',                      'Invalid ASN Case Status'
union select 'SKUMustBeEqualToScannedSKU',                  'SKU must be same as scanned SKU'
union select 'QuantityMustBeEqualToGivenQuantity',          'Quantity must be equal to given quantity'
union select 'ASNCaseReceivedSuccessfully',                 'ASN Case received successfully'
union select 'ReceiveASNLPN_OnlySuggestedPallet',           'User does not have the permissions to receive LPN on to a different Pallet than the Pallet suggested'
union select 'ReceiveASNLPN_ReceiverIsClosed',              'Receiver is Closed, Please restart receiving to receive on to another receiver'

/*---------------------------------------------------------------------------------------
pr_CrossDock_SelectedASNs:
---------------------------------------------------------------------------------------*/

union select 'CrossDockSingleASN',                          'Cross docked %3 LPN(s) for ASN %1'
union select 'CrossDockMultipleASNs',                       'Cross docked %3 LPN(s) for %2 ASNs'
union select 'NoASNsToCrossDock',                           'None of the selected Receipt Orders qualify for Cross Docking'
union select 'NoLPNsToCrossDock',                           'There are no available LPNs on selected ASNs that can be cross docked'
union select 'NoOrdersToCrossDock',                         'There are no Orders that can accept the inventory from the selected ASNs for cross docking'

/*---------------------------------------------------------------------------------------
pr_LPNs_Generate:
---------------------------------------------------------------------------------------*/
union select 'LPNsCreatedSuccessfully',                     'Successfully created %1 LPN(s), Created LPNs from %2 to %3'

/*------------------------------------------------------------------------------
Putaway Related:
------------------------------------------------------------------------------*/
union select 'ScanLocIsNotSuggestedLocation',               'Please putaway to the suggested location or get supervisor authorization to override'
union select 'ScanLocIsNotInDestZone',                      'Scanned Location is not in Destination Zone'
union select 'LPNTypeCannotbePickLane',                     'Cannot Putaway a Picklane, please use Transfer Inventory'
union select 'LPNAndStorageTypeMismatch',                   'LPN Type and Storage Type mismatch'
union select 'NoLocationsToPutaway',                        'No Locations found to Putaway the LPN'
union select 'PALocationIsInactive',                        'Cannot putaway into an Inactive Location'
union select 'PALPNNoDestWarehouse',                        'LPN has no Warehouse specified, cannot use Directed Putaway'
union select 'LPNIsAlreadyInSameLocation',                  'LPN is already in the same Location'
union select 'LPNIsAlreadyOnSamePallet',                    'LPN is already on the scanned Pallet'
union select 'CannotPALPN_ReceiverOpen',                    'LPN cannot be Putaway as its reciever is not closed yet'
union select 'LPNPA_LPNStatusIsInvalid',                    'LPN %1 is in %2 status and cannot be Putaway'
union select 'LPNPA_ReplenishLPNStatusIsInvalid',           'Replenish LPN Status restricts the LPN from being Putaway'
union select 'LPNPA_ReworkOrderIsNotYetClosed',             'Cannot Putaway Rework LPN until Rework order is closed'

/* Pallet Putaway */
union select 'PalletIsEmpty',                               'Pallet is empty'
union select 'PalletStatusInvalid',                         'Invalid Pallet status'
union select 'NotaPutawayPallet',                           'Can only putaway a Receiving or Inventory Pallet. For other pallets use Move Pallet function'
union select 'NoLPNsOnThisPallet',                          'No LPNs on this Pallet'
union select 'NumCasesOnPalletMismatch',                    'Num LPNs on Pallet mismatch'
union select 'LPNNotOnaPallet',                             'LPN not on a pallet'
union select 'PutawayPalletComplete',                       'Pallet Putaway was successful'
union select 'NoLocationsToPutawayPallet',                  'No Locations found to Putaway the Pallet'
union select 'PA_InvalidLocationType',                      'Invalid Location type to Putaway'
union select 'LPNsonPalletButNoLocations',                  'No Locations found to putaway LPNs on Pallet'
union select 'CannotPAPallet_ReceiverOpen',                 'Pallet cannot be Putaway as one or more LPNs on it has their receiver not closed yet'

/* Location SetUp */
union select 'LocMaxQtyShouldbegrtZero',                    'Location max quantity should be greater than zero'
union select 'LocMinQtyShouldbegrtZero',                    'Location min quantity should be greater than zero'
union select 'LocMaxQtyShouldbegrtMin',                     'Location max quantity should be greater than min quantity'
union select 'LocReplenishUOMShouldbegrtCS',                'Cannot update Replenish UOM as Eaches for Picklane Case Storage Location'
/*---------------------------------------------------------------------------------------
Packing Related:
---------------------------------------------------------------------------------------*/
union select 'Packing_InvalidInput',                        'Scanned entity is invalid'
union select 'Packing_InvalidLPNWeight',                    'Weight of Packed LPN is invalid. Please check and try again'
union select 'Packing_InvalidPalletOrBatch',                'Pallet or #PickBatch does not exist to pack. Please re-enter'
union select 'Packing_OrderShipped',                        'Scanned Order is already shipped'
union select 'Packing_OrderCancelled',                      'Scanned Order is cancelled'
union select 'Packing_OrderHasOpenPicks',                   'Scanned Order has open picks to be completed'
union select 'Packing_ViolatesSCRule',                      'Scanned Order violates the ship complete rule and hence is not qualified for shipping'
union select 'Packing_PartialKitsOnOrder',                  'Order contains Kit(s), which is/are partially picked and is not qualifed for shipping'
union select 'Packing_MultiplePalletsForBatch',             'Task has multiple carts, Please scan cart to pack.'
union select 'PackingPalletRequired',                       'Please scan/enter Pallet to start Packing'
union select 'PackingPalletDoesNotExist',                   'Pallet does not exist'
union select 'Packing_InvalidPalletStatus',                 'Pallet not ready to be packed'
union select 'PalletBeingPackedByAnotherUser',              'Pallet is being packed by another User'
union select 'PackingInvalidPickBatch',                     'Pallet is not associated with any #PickBatch to Pack'
union select 'CartonTypeDoesNotExist',                      'Package Type does not exist'
union select 'CartonTypeNotAvailableForPacking',            'Package Type not available for Packing'
union select 'PackingInvalidCartonType',                    'Please choose a valid carton type'
union select 'Packing_PalletHasOutstandingPicks',           'Pallet has some outstanding pick tasks. Please complete them before packing'
union select 'PackingSKUDoesNotExist',                      'Wrong Item: Item not ordered'
union select 'ItemAlreadyPacked',                           'Extra Item: Sufficient units of this item are already packed'
union select 'PackingExcessQty',                            'Excess Quantity: Packing more than the remaining units to be packed of this item'
union select 'StartNewCarton',                              'Please start packing by starting a new package'
union select 'CloseExistingCarton',                         'Current Package info will be lost, if you Close now!!!'
union select 'PackingInvalidQuantity',                      'Invalid quantity'
union select 'PackingQtyCannotNegative',                    'Qty. cannot be negative'
union select 'PackingQtyCannotZero',                        'Qty. cannot be zero'
union select 'CannotCloseEmptyCarton',                      'Cannot close an empty package'
union select 'PackingInvalidWeight',                        'Invalid weight'
union select 'PackingWeightCannotNegative',                 'Weight cannot be negative'
union select 'PackingWeightCannotZero',                     'Weight cannot be zero'
union select 'PackingNotEnoughQtyToPack',                   'Not enough # to pack'
union select 'NewCartonAlreadyStarted',                     'New package already started'
union select 'WeightFormatAlert',                           'Decimal point correction applied, Please confirm'
union select 'OrderCompleteCloseCarton',                    'Order Complete, Close the package'
union select 'OrdersNotFoundOnCart',                        'Orders not found on the package'
union select 'OrderNotFoundOnCartPostion',                  'Order not found on the package position'
union select 'CartPostionNotRelatedToCurrentCart',          'Cart Postion not related to current cart'
union select 'OrderContainsRows',                           'Order is not completely Packed. Do you wish to close?'
union select 'PackingOrderShortPick',                       'Order is not completely Picked. Please inform your Manager'
union select 'PackingOrderIncomplete',                      'Order is not completely Picked.'
union select 'PackingOrderIncomplete_Confirm',              'Order is not completely Picked. Do you wish to Continue?'
union select 'CartonPackedForAnotherOrder',                 'Carton has been packed for another Order'
union select 'PackingSuccessful',                           'Package #%1, %2 / UCC %3 created/updated successfully for PickTicket %4.'
union select 'Packing_LeftTitle',                           '<PickTicket>'
union select 'Packing_CenterTitle',                         '<ShipVia> - <ShipViaDescription>'
union select 'Packing_RightTitle',                          'Picked <PickedPallets> Cart(s), <PickedUnits> Unit(s); Packed <PackedLPNs> LPN(s) and <PackedUnits> Unit(s)'
union select 'Packing_ShipToAddress',                       '<ShipToName>;<ShipToAddressLine1>;<ShipToCityStateZip>'
union select 'NotAPackedLPNStatus',                         'Invalid Carton Status. Can only modify Packed Cartons'
union select 'CannotPackOrderToTheCarton',                  'Cannot pack order to the carton associated to another order'
union select 'Unpack_StatusNotValidForWave',                'Wave not in picking, picked, packing, packed status to Unpack'
union select 'Unpack_PalletNotAssociatedwithWave',          'Given wave is not associated with the given pallet'
union select 'Unpack_PalletNotAssociatedwithOrder',         'Order is not associated with the given pallet'
union select 'Unpack_NeedWaveorOrdersList',                 'Neither wave not orders list provided'
union select 'Unpack_InvalidWave',                          'Given wave is invalid. Please check!'
union select 'Unpack_InvalidOrdersList',                    'Given orders list are from different batches!'
union select 'Unpack_InvalidCart',                          'Pallet to be picked into not given'
union select 'Unpack_InvalidPalletType',                    'Given pallet is not of picking cart type'
union select 'Orders_Unpack_Successful',                    'Note: %RecordsUpdated of %TotalRecords Orders are Unpacked'
union select 'Orders_Unpack_SomeUpdated',                   'Note: Some %RecordsUpdated of %TotalRecords Orders are Unpacked'
union select 'Orders_Unpack_NoneUpdated',                   'Note: None %RecordsUpdated of %TotalRecords Orders are Unpacked'
union select 'ScannedMoreThanPicked',                       'Cannot pack more units than picked'
union select 'NoPackingContents',                           'Carton contents have not been identified and cannot close the package'
union select 'GroupItemsAlreadyPacked',                     'Already packed items for Employee'
union select 'Packing_InvalidCartonType',                   'Invalid CartonType. Please select CartonType related to ShipVia'
union select 'Packing_InvalidLPNCartonTypeandWeight',       'Invalid LPN to modify Cartontype/Weight'
union select 'Packing_NothingToPack',                       'There is nothing to pack against scanned entity'
union select 'ClosePackage_ShipmentRequestFailed',          'Shipment Request failed with %1 %2. Review Transaction Record %3 for more details'
union select 'ClosePackage_ShipmentDataError',              'Shipment Details could not be identified (%1 %2). Review Transaction Record %3 for more details'

/*---------------------------------------------------------------------------------------
CycleCount Related:
---------------------------------------------------------------------------------------*/
union select 'InvalidCCBatch',                              'Invalid cycle count batch'
union select 'InvalidCCStatus',                             'Invalid cycle count status'
union select 'PickZoneIsInvalid',                           'Entered PickZone is invalid'
union select 'PickingZoneMismatch',                         'Picking zone mismatch'
union select 'NoMoreLocationsFoundOnThisTask',              'No more locations found on this task'
union select 'CycleCountCompletedOnThisBatch',              'Cycle Count completed on this Batch'
union select 'CycleCountInvalidLocationType',               'Invalid Location Type'
union select 'CycleCountLocationSKUNotAssigned',            'Location is empty, no SKU assigned to scanned location, please add SKU first'
union select 'CC_InvalidEntity',                            'Invalid value input. Scanned value should be a Pallet or LPN or SKU to cycle count'
union select 'CC_InvalidSKUOrLPN',                          'Invalid SKU or LPN'
union select 'CC_InvalidSKU',                               'Invalid SKU'
union select 'CC_InactiveSKU',                              'Inactive SKU'
union select 'CC_InvalidLPN',                               'Invalid LPN'
union select 'CC_InvalidPallet',                            'Invalid Pallet'
union select 'CC_InvalidLPNType',                           'Invalid LPN Type'
union select 'CC_LPNIsEmpty',                               'Scanned LPN is empty'
union select 'CC_ScanSKUNotLPN',                            'Please Scan SKU instead of LPN'
union select 'CC_CannotScanSKU',                            'Cannot Scan SKU, please scan LPN'
union select 'CC_CannotScanLPN',                            'Cannot Scan LPN, please scan SKU'
union select 'CC_InvalidBatch',                             'Invalid Batch'
union select 'CC_InvalidBatchStatus',                       'Invalid Batch Status'
union select 'CC_BatchCompleted',                           'Cycle count Batch Completed'
union select 'CC_PickZoneNotConfigured',                    'Location is not configured with Pick Zone and is required for Cycle Counting'
union select 'CC_PickZoneIsInvalid',                        'Location has an invalid Pick Zone and need to be configured correctly'
union select 'NoBatchesToCycleCount',                       'No Batches To Cycle Count'
union select 'NoLocationsToCycleCount',                     'No Locations To Cycle Count'
union select 'TaskIsInvalid',                               'Invalid Task'
union select 'InvalidData',                                 'Data passed from device is invalid. Please contact administrator'
union select 'CCBatchCompletedSuccessfully',                'Cycle count completed for all Locations in the Batch'
union select 'PalletAndStorageTypeMismatch',                'Storage Type mismatch, Location was not setup for Pallets'
union select 'CannotCCLessOrMorethanReservedQty',           'Cannot count higher/lower than the LPN''s (%1) reserved Qty (%2)'
union select 'CannotCCLessthanReservedQty',                 'Cannot count lower than the LPN''s (%1) reserved Qty (%2)'
union select 'NoAvailableLineToAdjustQty',                  'No available line of LPN (%1) to adjust Qty higher that reserved qty (%2)'

union select 'CC_CreateTasks_Successful1',                  'Successfully created cycle count Batch %2'
union select 'CC_CreateTasks_Successful2',                  'Successfully created %1 cycle count batches from %2 to %3.'
union select 'CC_CreateTasks_NoneCreated',                  'No Cycle count batches were created.'

union select 'CC_LPNStatusInvalid',                         'Cannot cycle count this LPN into this Location as status is invalid to be in the Location.'
union select 'CC_LPNPicked',                                'Cannot cycle count this LPN into this Location as Picked/Packed/Staged/Loaded LPNs cannot be in Inventory Locations.'
union select 'CC_LPNAlreadyShipped',                        'Cannot cycle count this LPN into this Location as it is already Shipped.'
union select 'CC_LPNVoidOrConsumed',                        'Cannot cycle count this LPN into this Location as it is Voided/Consumed. Generate new LPN for inventory.'
union select 'CC_InvalidLPNScanned',                        'Cannot cycle count LPN %1. Not found in the system. Please continue with rest'
union select 'CC_InvalidPalletScanned',                     'Cannot cycle count Pallet %1. This is either Shipped, Lost or voided'

union select 'CCCompletedSuccessfully',                     'Location %1 cycle counted successfully'
union select 'CompleteLPNAllocated_CannotChangeLPNQty',     'LPN is completely allocated. Cannot allow change of qty'
union select 'CycleCount_CancelCCTasks_Successful',         'All selected (%TotalRecords) Tasks have been cancelled'
union select 'CycleCount_CancelCCTasks_NoneUpdated',        'None of the selected Tasks are cancelled'
union select 'CycleCount_CancelCCTasks_SomeUpdated',        '%RecordsUpdated of %TotalRecords selected Tasks have been cancelled'

union select 'CCCompletedAndManagerTaskCreated',            'Location %1 Cycle counted successfully and manager batch created as well for next count'
union select 'CC_LocationNotAssignedAnySKU',                'Location is empty and does not have a SKU assigned and hence it does not need to be cycle counted. If there is inventory, then Add SKU to Location and cycle count it.'
union select 'CC_SupervisorTaskCreated',                    'Cycle Count task has been upgraded to supervisor count'
union select 'CC_L2ThresholdValueExceeded',                 'Cycle Count exceeded the threshold values, please use LPN adjustment instead'
union select 'CC_UserDoNotHavePermissions_L2CC',            'User does not have the permissions for supervisor Count'
union select 'CC_UserDoNotHavePermissions_L3CC',            'User does not have the permissions for Manager Count'

union select 'CycleCountTasks_Cancel_Successful',           'All selected (%TotalRecords) Tasks have been cancelled'
union select 'CycleCountTasks_Cancel_NoneUpdated',          'None of the selected Tasks are cancelled'
union select 'CycleCountTasks_Cancel_SomeUpdated',          '%RecordsUpdated of %TotalRecords selected Tasks have been cancelled'

union select 'CycleCountTasks_AssignToUser_NoneUpdated',    'Note: None of the selected Cycle Count Tasks are assigned'
union select 'CycleCountTasks_AssignToUser_SomeUpdated',    'Note: %RecordsUpdated of %TotalRecords selected Cycle Count Tasks have been assigned'
union select 'CycleCountTasks_AssignToUser_Successful',     'Note: All selected Cycle Count Tasks (%RecordsUpdated) have been assigned successfully'

union select 'CycleCountTasks_AssignUser_InvalidStatus',    'BatchNo %1 is not in a valid status, hence it cannot be assigned to user'

union select 'CC_CancelTask_AlreadyCompleted',              'Cycle count Task %1 already Completed. Cannot cancel task'
union select 'CC_CancelTask_AlreadyCanceled',               'Cycle count Task %1 already Cancelled. Cannot cancel task'
union select 'CycleCountTasks_Cancel',                      'Cycle Count Task %1 cancelled successfully'

/*------------------------------------------------------------------------------
Single line order packing
------------------------------------------------------------------------------*/
union select 'PackingSL_MissingInput',                      'Invalid input. Please report error to administrator'
union select 'PackingSL_InputRequired',                     'Enter valid data to process'
union select 'PackingSL_InvalidEntity',                     'Entered invalid data. Enter a valid command or Wave/PickTicket/LPN/SKU to process'
union select 'PackingSL_InvalidOrderType',                  'Entered order type is not valid to pack using this feature'
union select 'PackingSL_InvalidOrderStatus',                'Entered order is shipped or cancelled and cannot be packed'
union select 'PackingSL_IdentifyWaveToStartPacking',        'Unable to find wave to pack for the scanned entity'
union select 'PackingSL_ScannedEntitiesOnDifferentWave',    'Scanned wave is different from current packing wave. If you would like to process another wave, clear the current wave and start the next wave.'
union select 'PackingSL_ScannedSKUNotRequiredForOrder',     'SKU is not required for the current order'


/*---------------------------------------------------------------------------------------
Shipping Validation Related Messages:
---------------------------------------------------------------------------------------*/
union select 'Shipping_AccountDetailsNotAvailable',         'Cannot get Ship Label - Account Details are not available'
union select 'Shipping_ShipFromNotAvailable',               'Cannot get Ship Label - Ship From Address is not available'
union select 'Shipping_SoldToNotAvailable',                 'Cannot get Ship Label - Sold To Address is not available'
union select 'Shipping_ShipToNotAvailable',                 'Cannot get Ship Label - Ship To Address is not available'
union select 'Shipping_BillToNotAvailable',                 'Cannot get Ship Label - Bill To Address is not available'
union select 'Shipping_LPNWeightRequired',                  'Cannot get Ship Label - LPN Weight should be greater than zero'
union select 'Shipping_LPNCartonTypeRequired',              'Cannot get Ship Label - Carton Type is required on LPN'
union select 'InvalidLoadOrDock',                           'Invalid Load or dock'
union select 'MultipleLoadsForDock',                        'Dock is assigned for another load already'
/* I - represents International shipping validations */
union select 'Shipping_I_SoldShipCountriesDifferent',       'Cannot get Ship Label - Sold To and Ship To countries are different'

/*------------------------------------------------------------------------------
 Serial Nos related
------------------------------------------------------------------------------*/
union select 'SerialNos_InvalidScannedLPN',                 'Scanned LPN is invalid'
union select 'SerialNos_ScannedEmptyLPN',                   'Scanned an empty LPN'
union select 'SerialNos_InvalidLPNStatus',                  'Status of scanned LPN is invalid'
union select 'SerialNos_NoSerialNosToAssign',               'Please scan Serial number(s) to assign'
union select 'SerialNos_ScannedLPNHasValidSerialNos',       'Scanned LPN already has valid Serial numbers'
union select 'SerialNos_SomeAlreadyUsed',                   'Some of the scanned Serial numbers were already used. Ex: %1'
union select 'SerialNos_ScannedSerialNosAreMoreThanUnits',  'Scanned more Serial numbers than the number of units in the LPN'
union select 'SerialNos_AddedOrReplacedSuccessfully',       'Scanned Serial numbers are successfully assigned to LPN'
union select 'SerialNos_InputXMLIsNull',                    'No Input provided'
union select 'SerialNos_Clear_LPN',                         'LPN %LPN cleared from Serial numbers'

union select 'SerialNos_Clear_NoneUpdated',                 'None of the Serial numbers were cleared from associated LPNs'
union select 'SerialNos_Clear_SomeUpdated',                 '%RecordsUpdated of %TotalRecords selected Serial numbers have been cleared'
union select 'SerialNos_Clear_Successful',                  'All selected (%TotalRecords) Serial numbers have been cleared'

/*---------------------------------------------------------------------------------------
Shipments/Load Related:
---------------------------------------------------------------------------------------*/
union select 'LoadNumberDoesNotExist',                      'Load does not exists'
union select 'LoadIsInvalid',                               'Invalid or Unknown Load'
union select 'ShipmentIsInvalid',                           'Invalid or Unknown Shipment'
union select 'NoLPNsOnShipment',                            'No LPNs are associated with the given Shipment'
union select 'InvalidShipmentStatus',                       'Invalid Shipment Status to Ship'
union select 'LoadCancelled',                               'Load is in canceled status.'
union select 'InvalidLPNOrPallet',                          'Invalid LPN or Pallet'
union select 'PalletIsAlreadyOnALoad',                      'Pallet is already on Load %1'
union select 'LPNIsAlreadyOnALoad',                         'LPN is already on Load %1'
union select 'PalletHasMultipleShipTos',                    'Pallet has multiple ShipTos'
union select 'LoadForDifferentShipment',                    'Load is for different shipment'
union select 'BoLIsRequiredToShip',                         'BoL is required to ship the Load. Please generate the BoLs and then ship the Load'

union select 'Load_ConfirmShipped_InvalidStatus',           'Load shall have to be in Ready To Ship or Loaded status to confirm Shipped'
union select 'CannotAssignMultipleLoadsForDock',            'Cannot assign multiple Loads for Dock. Load %1 already assinged to Dock Location %2'
union select 'LoadCreate_DockLocationInvalid',              'Given Location for Dock is not a valid Location'
union select 'LoadCreate_DockLocationInvalidType',          'Given Location for Dock is not a Dock Location. Please specify a Location of type DOCK'
union select 'LoadCreate_StagingLocationInvalid',           'Given Location for Staging is not a valid Location'
union select 'LoadCreate_StagingLocationType',              'Given Location for Dock is not a Staging Location. Please specify a Location of type STAGING'

union select 'CreateTransferLoad_ShipFromShipToCannotBeSame','ShipFrom/ShipTo cannot be same for Transfer load'
union select 'CreateTransferLoad_InvalidShipToId',          'Cannot create Transfer load for the given Ship To location'
union select 'CreateTransferLoad_ShipFromIsRequired',       'Ship From on the Load is required'
union select 'CreateTransferLoad_ShipToIsRequired',         'Ship To on the Load is required'

union select 'InvalidShipmentsToShip',                      'Shipments associated with given Load are not in valid status'
union select 'InvalidLPNStatusToShip',                      'LPNs associated with the given Load are not in valid status'
union select 'InvalidLoadStatus',                           'Invalid Load Status'

union select 'Load_AddOrders_SomeUpdated',                  '%RecordsUpdated of %TotalRecords selected orders have been added to the Load %3'
union select 'Load_AddOrders_Successful',                   'All selected  %TotalRecords Orders have been added to the Load %3'
union select 'Load_AddOrders_NoneUpdated',                  'None of selected %TotalRecords orders were added the Load %3'

union select 'Load_AddOrders_ValidStatus',                  'Load should be in New or Inprocess status to add orders'
union select 'Load_AddOrders_InvalidStatus',                'Cannot add orders to Ready-To-Ship/Shipped or Cancelled Loads'
union select 'Load_AddOrders_InvalidRoutingStatus',         'Load cannot be modified as Routing is awaiting confirmation or confirmed'
union select 'Load_AddOrders_InvalidOrderStatus',           'Shipped Order cannot be added to a Load'
union select 'Load_AddOrders_ShipViaDifferent',             'ShipVia on selected Order(s) is different from Load ShipVia'
union select 'Load_AddOrders_DesiredShipDtDifferent',       'Selected Order(s) and Load have different Desired Ship Dates'
union select 'Load_AddOrders_ShipViaNull',                  ', %1 order(s) were not added as ShipVia was not specified'
union select 'Load_AddOrders_ShipFromDifferent',            'Ship From on selected Order(s) is different from Ship From on Load'
union select 'Load_AddOrders_WarehouseDifferent',           'Warehouse on selected Order(s) is different from Warehouse on Load'
union select 'Load_AddOrders_CarriersDifferent',            'Carrier on selected Order(s) is different from Load Carrier'

union select 'Load_AddShipment_OnAnotherLoad',              'Selected Shipment already on another Load'

union select 'Load_RemoveOrders_SomeRemoved',               '%RecordsUpdated of %TotalRecords selected orders have been removed from the Load %1'
union select 'Load_RemoveOrders_Successful',                'All selected  %TotalRecords Orders have been removed from the Load %1'
union select 'Load_RemoveOrders_NoneUpdated',               'None of selected %TotalRecords orders were removed from the Load %1'

union select 'Load_RemoveOrders_ValidStatus',               'Load should be in New or InProgress status to remove orders'
union select 'Load_RemoveOrders_InvalidRoutingStatus',      'Cannot remove Orders from Load as awaiting Routing confirmation'

union select 'Loads_Modify_NoneUpdated',                    'Note: None of the selected Loads are updated'
union select 'Loads_Modify_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected Loads have been updated'
union select 'Loads_Modify_Successful',                     'Note: All selected Loads (%RecordsUpdated) have been updated successfully'

union select 'Load_Modify_Successful',                      'Load %1 updated successfully'
union select 'Load_Modify_InvalidStatus',                   'Invalid status to modify the Load %1'
union select 'LoadModify_ShippedOrCanceled',                'Cannot modify a load which is Cancelled or Shipped'
union select 'LoadModify_NewLoad_CannotConfirmRouting',     'Cannot update the Load as routing confirmed as it is still new'
union select 'LoadModify_InvalidBoLNumber',                 'Please enter last 4 digits or entire 17 digits of the BoL number.'

union select 'Load_Generation_Multi_Successful',            'Loads %2 to %3 are created successfully'
union select 'Load_Generation_Successful',                  'Load %2 created successfully'
union select 'Load_Generation_Successful2',                 '%4 of the %5 selected order(s) have been added to %1 new Loads or to existing Loads successfully'
union select 'Load_Generation_Failed',                      'Generation of Loads failed'
union select 'Load_Generation_NoneUpdated',                 'None of the selected %5 Orders have been added to the Loads'

union select 'Load_ConfirmLPNShipped_Successful',           'All selected %RecordsUpdated LPNs have been confirmed as Shipped'
union select 'Load_ConfirmLPNShipped_SomeUpdated',          '%RecordsUpdated of %TotalRecords selected LPNs have been confirmed as Shipped'
union select 'Load_ConfirmLPNShipped_NoneUpdated',          'Unable to confirm the LPNs as shipped'

union select 'Load_CancelLoad_NoneUpdated',                 'None of the selected %TotalRecords Load(s) are cancelled'
union select 'Load_CancelLoad_OneUpdated',                  'Selected Load %1 cancelled successfully'
union select 'Load_CancelLoad_SomeUpdated',                 '%RecordsUpdated of %TotalRecords selected Loads are cancelled successfully'
union select 'Load_CancelLoad_Successful',                  'All selected %RecordsUpdated Loads are cancelled successfully'
union select 'Load_CancelLoad_InvalidStatus',               'Invalid status to cancel the Load %1'

union select 'Loads_ModifyApptDetails_NoneUpdated',         'Appointment details were not updated on any of the selected Loads'
union select 'Loads_ModifyApptDetails_OneUpdated',          'Appointment details were updated successfully on the selected Load'
union select 'Loads_ModifyApptDetails_SomeUpdated',         'Appointment details were updated successfully on %RecordsUpdated of %TotalRecords selected Loads'
union select 'Loads_ModifyApptDetails_Successful',          'Appointment details were updated successfully on all selected %RecordsUpdated Loads'
union select 'Loads_ModifyApptDetails_InvalidStatus',       'Load %1 is in %2 status and the appointment details cannot be changed now'

union select 'Loads_ModifyBoLInfo_NoneUpdated',             'BoL details were not updated on any of the selected Loads'
union select 'Loads_ModifyBoLInfo_OneUpdated',              'BoL details were updated successfully on the selected Load'
union select 'Loads_ModifyBoLInfo_SomeUpdated',             'BoL details were updated successfully on %RecordsUpdated of %TotalRecords selected Loads'
union select 'Loads_ModifyBoLInfo_Successful',              'BoL details were updated successfully on all selected %RecordsUpdated Loads'

union select 'LoadModify_InvalidDeliveryDate',              'Invalid delivery date'
union select 'LoadModify_InvalidDesiredShipDate',           'Invalid desired ship date'
union select 'Loads_MarkAsShipped_Successful',              'Note: All selected (%RecordsUpdated) Loads have been shipped'
union select 'Loads_MarkAsShipped_SomeUpdated',             'Note: %RecordsUpdated of %TotalRecords selected Loads have been shipped'
union select 'Loads_MarkAsShipped_NoneUpdated',             'Note: None of the selected Loads are shipped'
union select 'Load_BoLNumberAlreadyExists',                 'BoL number already exists on another load'
union select 'Loads_GenerateBoLs_Successful',               'BoLs generated for selected (%RecordsUpdated) Loads'
union select 'Loads_GenerateBoLs_SomeUpdated',              'BoLs generated for %RecordsUpdated of %TotalRecords selected Loads'
union select 'Loads_GenerateBoLs_NoneUpdated',              'No BoLs were generated for the selected Loads'
union select 'GenerateBoLs_LoadShippedOrCancelled',         'Cannot generate BoLs for the Loads which are shipped/canceled'
union select 'GenerateBoLs_NoOrdersToGenerateBoL',          'Load has no Orders in it to generate BoLs'
union select 'Load_DocumentsQueued_Successfully',           'Load Documents are queued for printing for the selected %1 Load(s)'
union select 'LoadShip_Queued',                             'Selected Load %1 have been queued for closing'
union select 'LoadShip_ErrorProcessing',                    'Load %1: %2'
union select 'Loads_AddOrders_OrdersAddedToLoad',           'Order %1 added to Load %2'
union select 'Loads_AddOrders_OrderNotWaved',               'Order %1 not yet waved and hence is not ready to be added to load'
union select 'Loads_AddOrders_OrderHasOpenpicks',           'Order %1 has open picks to be completed and hence is not qualified to be added to Load'
union select 'Loads_AddOrders_ShipViaNull',                 'Cannot add %1 order to the load because ShipVia is not specified on the order'
union select 'Loads_AddOrders_MultiShipmentOrder',          'Order %1 is a multi-shipment order, please use RF Loading to add LPNs/Pallets to the Load'

union select 'Loads_RequestForRouting',                     'Load %1 requested for routing'
union select 'Loads_RequestForRouting_Error',               'Load %1: %2'
union select 'Loads_RequestForRouting_Successful',          'Note: All selected (%RecordsUpdated) Loads have been updated for routing'
union select 'Loads_RequestForRouting_SomeUpdated',         'Note: %RecordsUpdated of %TotalRecords selected Loads have been updated for routing'
union select 'Loads_RequestForRouting_NoneUpdated',         'Note: None of the selected Loads are updated for routing'
union select 'Loads_RequestForRouting_NotValidLoadStatus',  'Load %1 status %2 not valid to request for routing'
union select 'Loads_RequestForRouting_NoOrders',            'Load %1 has no orders associated to request for routing'

union select 'Load_ActivateShipCartonsRequest_Successful',  'Ship cartons activation initiated for selected (%RecordsUpdated) Loads'
union select 'Load_ActivateShipCartonsRequest_SomeUpdated', 'Ship cartons activation initiated for %RecordsUpdated of %TotalRecords selected Loads'
union select 'Load_ActivateShipCartonsRequest_NoneUpdated', 'No ship carton activation initiated for the selected Loads'

union select 'Load_ActivateShipCartonsDone_Successful',     'Ship cartons activation completed for selected (%RecordsUpdated) Loads'
union select 'Load_ActivateShipCartonsDone_SomeUpdated',    'Ship cartons activation completed for %RecordsUpdated of %TotalRecords selected Loads'
union select 'Load_ActivateShipCartonsDone_NoneUpdated',    'No ship carton activation completed for the selected Loads'

union select 'Loads_ActivateShipCartons_InvalidStatus',     'Load %1 is %2. Please try adding to a different load and activate'
union select 'Loads_CreateLoad_Successful',                 'Load %1 created successfully'
union select 'Load_ManageLoads_CreateLoad_Successful',      'Load %1 created successfully'

union select 'Load_LoginWarehouseMismatch',                 'The scanned Warehouse is from a different Warehouse that the logged in Warehouse'

union select 'InvalidLoad',                                 'Load is invalid'
union select 'RFLoad_PalletAlreadyLoaded',                  'Pallet already loaded'
union select 'RFLoad_InvalidLPNStatus',                     'All LPNs on the pallet are not for this Load. Please remove those LPNs and try again'
union select 'RFLoad_InvalidPalletStatus',                  'Pallet is in %1 status and cannot be added to a Load'
union select 'RFLoad_EmptyPallet',                          'Cannot load an empty pallet'
union select 'RFLoad_PalletOnDifferentLoad',                'Pallet is on a different load'
union select 'RFLoad_LPNOnDifferentLoad',                   'LPN is on a different load'
union select 'RFLoad_LPNAlreadyLoaded',                     'Cannot load LPN because as it is already loaded'
union select 'RFLoad_LPNWarehouseMismatch',                 'Cannot load LPN because Warehouse of LPN and Load do not match'
union select 'RFLoad_PalletWarehouseMismatch',              'Cannot load Pallet because Warehouse of Pallet and Load do not match'
union select 'RFLoad_ScannedDockLocationInvalid',           'Scanned Dock Location is different than suggested Dock Location'
union select 'RFLoad_BulkOrderCannotBeLoaded',              'Scanned LPN/Pallet is associated with Bulk/Replenish Order which cannot be added to a Load'

/*---------------------------------------------------------------------------------------
  Shipments/UnLoad Related:
---------------------------------------------------------------------------------------*/
union select 'RFLoad_LoadAlreadyShipped',                   'Cannot load as it is already shipped'
union select 'UnLoad_InvalidLPNStatus',                     'Invalid LPN status'
union select 'Unload_InvalidPalletStatus',                  'Invalid pallet status'
union select 'Unload_LPNIsAlreadyShipped',                  'LPN already shipped'
union select 'Unload_PalletHasShippedLPNs',                 'Cannot load pallet as it has shipped LPNs on it'
union select 'UnLoad_ScannedLPNOrPalletNotOnLoad',          'Scanned LPN/Pallet is not on Load'
union select 'UnLoad_ScannedLPNOrPalletWHMismatch',         'Scanned LPN/Pallet is not the same Warehouse as of the Load'

/*---------------------------------------------------------------------------------------
pr_LPNs_Action_ReGenerateTrackingNo:
---------------------------------------------------------------------------------------*/
union select 'LPN_ReGenerateTrackingNo_InvalidLPNStatus',   'LPN %1 status is invalid'
union select 'LPN_ReGenerateTrackingNo_InvalidLPNType',     'LPN %1 is not a shipping carton to generate tracking number'
union select 'LPN_ReGenerateTrackingNo_AlreadyGenerated',   'LPN %1 TrackingNo already generated'
union select 'LPN_ReGenerateTrackingNo_InvalidCarrier',     'LPN %1 LPN does not belong to a Small Package carrier'

union select 'LPN_ReGenerateTrackingNo_NoneUpdated',        'None of the selected LPN(s) are updated'
union select 'LPN_ReGenerateTrackingNo_SomeUpdated',        '%RecordsUpdated of %TotalRecords selected LPN(s) have been updated'
union select 'LPN_ReGenerateTrackingNo_Successful',         'All selected LPN(s) (%TotalRecords) have been updated successfully'

/*---------------------------------------------------------------------------------------
Tasks Related:
---------------------------------------------------------------------------------------*/
union select 'Tasks_Cancel_NoneUpdated',                    'None of the selected Tasks are cancelled'
union select 'Tasks_Cancel_SomeUpdated',                    '%RecordsUpdated of %TotalRecords selected Tasks have been cancelled'
union select 'Tasks_Cancel_Successful',                     'All selected (%TotalRecords) Tasks have been cancelled'

union select 'Tasks_Release_NoneUpdated',                   'None of the selected Tasks are released'
union select 'Tasks_Release_SomeUpdated',                   '%RecordsUpdated of %TotalRecords selected Tasks have been released'
union select 'Tasks_Release_Successful',                    'All selected (%TotalRecords) Tasks have been released'

union select 'TasksRelease_Dependency_R',                   'Task %1 cannot be released, it is waiting on Replenishment'
union select 'TasksRelease_Dependency_S',                   'Task %1 cannot be released, not enough inventory in Location to Pick the task'

/*---------------------------------------------------------------------------------------
BoL Related:
---------------------------------------------------------------------------------------*/
union select 'BoL_CreateNew_Successful',                    'BoL generation successfully completed'
union select 'BoL_Modify_Successful',                       'BoL details modified successfully'
union select 'BoL_CarrierDetailsModify_Successful',         'BoL Carrier details modified successfully'
union select 'BoL_OrderDetailsModify_Successful',           'BoL Order details modified successfully'
union select 'BoLs_ModifyShipToAddress_Successful',         'BoL Ship To Address modified successfully'
union select 'BoL_CanOnlyChangeShipToOnMasterBoL',          'Ship To can only be changed on Master BoL to designate Consolidator address'

/*---------------------------------------------------------------------------------------
 Validate Load Ship:
---------------------------------------------------------------------------------------*/
union select 'LoadShip_FailedValidations',                  'Load cannot be shipped as some validations have failed'
union select 'LoadShip_AlreadyShipped',                     'Load has already been shipped and cannot be shipped again. Please refresh'
union select 'LoadShip_AlreadyCanceled',                    'Load has been canaceled and cannot be shipped'
union select 'LoadShip_LoadBeingShippedInBackGround',       'Load is being shipped by a Background Process'
union select 'LoadShip_LoadNotReadyToShip',                 'Load not ready to ship yet. Please check LPNs on the Load'
union select 'LoadShip_InvalidCarrierForShipping',          'Load cannot be shipped using the current Carrier.'
union select 'LoadShip_OnlyLTLLoadsCanbeShipped',           'Load can be shipped only for LTL Carriers. For Small Package carriers, ship the cartons instead'
union select 'LoadShip_ShipmentOnLoadNotReadyToShip',       'Shipment of Order %1 is not yet ready to be shipped'
union select 'LoadShip_MissingBoLInfoOnOrder',              'Order %1 on the Load missing BoL info, please regenerate BoL Info'
union select 'LoadShip_LPNsOnLoadNotReadyToShip',           'Some of the LPNs on Load are not yet ready to be shipped, hence Load cannot be shipped yet'
union select 'LoadShip_InvalidRoutingStatus',               'Routing should be confirmed (or Not Required) for a Load to be shipped'
union select 'LoadShip_LPNOrPalletNotOnLoad',               'Scanned LPN/Pallet is not on Load'
union select 'LoadShip_OrdersOnLoadWithNoUnits',            'Order %1 cannot be shipped as there are no units assigned for the Order'
union select 'LoadShip_LPNNotPacked',                       'LPN %1 of Order %2 not yet packed or staged and hence is not ready to ship'
union select 'LoadShip_LPNNotAllocated',                    'LPN %1 on the Load is not assigned/allocated to any Order'
union select 'LoadShip_UnitsStillOnCart',                   'LPN %1 of Order %2 still having units on cart'
union select 'LoadShip_PalletAndLPNsAreOnDiffLoads',        'LPN %1 on the Load is associated with Pallet %2 which is either on a different loads or the pallet is not completely loaded'
union select 'LoadShip_CannotShortShip',                    'Cannot ship the Load as Ship complete Order(s) are not yet fulfilled'
union select 'LoadShip_CannotShipEmptyLoad',                'Cannot ship Load as there are no Orders on the Load'
union select 'LoadShip_LPNMissingTrackingNo',               'LPN %1 of Order %2 is missing the tracking number and is being shipped using Small package carrier'
union select 'ShipmentsWithMultipleShipVias',               'Cannot generate BoLs as Orders on the Load have different ShipVias'
union select 'LoadShip_SomeLPNsMissingUCCBarcodes',         'Cannot ship Load as some of the LPNs on the load does not have UCCBarcode'
union select 'LoadShip_OrderHasOutstandingPicks',           'Order %1 has outstanding picks on Task %2'
union select 'LoadShip_InvalidLPNType',                     'LPN %1 on Order %2 cannot be shipped on the Load as it is not a Shipping Carton'
union select 'LoadShip_InvalidLPNStatus',                   'LPN %1 on Order %2 has invalid status to ship the load'
union select 'LoadShip_ShortShippingOrder',                 'Pick Ticket %1 is only %3 percent completed, does not meet the %2 percent ship complete requirements and therefore cannot be shipped'
union select 'LoadShip_Has_FutureShipDate',                 'Cannot ship Load before the ship date'
union select 'LoadShip_LPNMissingWeight',                   'LPN %1 of Order %2 is missing weight'
union select 'LoadShip_InvalidOrderStatus',                 'Order %1 has invalid status to ship the load'
union select 'LoadShip_LPNsAreOnDiffLoadFromPallet',        'Pallet %1 has LPN %2 which is on a different load'
union select 'LoadShip_LPNsOnOrderWithoutLoadInfo',         'LPN %1 (Pallet %3) of Order %2 is not on the Load and it is a single shipment Order'
union select 'LoadShip_LPNsOnOrderWithoutShipmentInfo',     'LPN %1 (Pallet %3) of Order %2 is not associated with any shipment and it is a single shipment Order'
union select 'LoadShip_NoLPNsOnShipment',                   'Shipment %1 has no LPNs to be shipped'
union select 'LoadShip_PalletNotLoaded',                    'Pallet %1 with %2 LPNs in %3 status needs to be loaded onto the truck'
union select 'LoadShip_LPNNotLoaded',                       'LPN %1 is in %2 status and needs to be loaded onto the truck'
union select 'LoadShip_Queued',                             'Selected Load %1 have been queued for closing'
union select 'LoadShip_ErrorProcessing',                    'Load %1: %2'
union select 'LoadShip_TrailerNumberIsRequired',            'TrailerNumber is required to ship the Load. Please update the Trailer Number on the loads and then ship the Load'

/*---------------------------------------------------------------------------------------
Picking/Cycle Count batches related:
---------------------------------------------------------------------------------------*/
union select 'SelectedBatchFromWrongWarehouse',             'Selected Batch from wrong Warehouse'
union select 'InvalidCartPosStatus',                        'Invalid Cart Position Status'
union select 'InvalidCartPosition',                         'Invalid Cart Position'
union select 'BuildCart_InvalidTaskId',                     'Invalid Task'
union select 'BuildCart_InvalidTaskStatus',                 'LPN voided - all picks may have been cancelled'
union select 'BuildCart_InvalidCart',                       'Invalid Cart'
union select 'BuildCart_InvalidCartStatus',                 'Invalid Cart status for BuildCart'
union select 'BuildCart_WrongPackingList',                  'Scanned Packing List is not for the scanned Carton. Please verify.'
union select 'BuildCart_PackingListIsRequired',             'Packing List is not scanned for the Carton and it is required'
union select 'BuildCart_ScannedPositionNotOnCart',          'Scanned position not on Cart'
union select 'BuildCart_InvalidCartType',                   'Can only build a Cart, not a pallet. Please scan an empty Cart'
union select 'BuildCart_LPNAlreadyAtPosition',              'Scanned LPN is alreayd at the scanned position on the Cart'
union select 'BuildCart_AllLPNsBuilt',                      'All LPNs on the Task are built to the cart'
union select 'BuildCart_LPNAddedSuccessfully',              'LPN added to Cart successfully'
union select 'BuildCart_PalletInUseForAnotherTask',         'Scanned Cart is built for another Task'
union select 'ScannedPositionAssociatedWithOtherLPN',       'Scanned Position associated with another LPN'
union select 'TaskAssociatedWithAnotherCart',               'Task associated with Cart %1'
union select 'ScannedLPNNotAssociatedWithThisBatch',        'Scanned LPN not associated with this Task'
union select 'NotEnoughPositionsToBuildCart',               'Cart positions are less than the LPNs to be built'
union select 'BuildCart_CartPositionInUse',                 'LPN %1 is already located at this position on the Cart'
union select 'BuildCart_TaskPendingReplenish',              'Scanned Task is a waiting Replenishment, %2'

/*---------------------------------------------------------------------------------------
Layouts Related:
---------------------------------------------------------------------------------------*/
union select 'Layouts_DoesNotExist',                        'Layout does not exist'
union select 'Layouts_CannotDeleteOthersLayouts',           'Layout was created by another user and can only be deleted by user who created it'

union select 'Layouts_DeletedSuccessfully',                 'Layout deleted successfully'
union select 'Layouts_LayoutNameAlreadyExists',             'Layout already exists with the same name'
union select 'Layouts_AddedSuccessfully',                   'Layout added successfully'
union select 'Layouts_SavedSuccessfully',                   'Layout saved successfully'
union select 'Layouts_SelectionAddedSuccessfully',          'Layout Selection added successfully'
union select 'Layouts_SelectionSavedSuccessfully',          'Layout selection saved successfully'
union select 'Layouts_DuplicateFields',                     'Layout contains duplicate Fields'

union select 'Layouts_CannotAddSystemLayout',               'User does not have permissions to add System Layout'
union select 'Layouts_CannotEditSystemLayout',              'User does not have permissions to edit System Layout'
union select 'Layouts_CannotChangeStandardLayoutCategory',  'Standard layout cannot be changed to be role or user specific'
union select 'Layouts_CannotAddStandardLayout',             'User does not have permissions to add Standard Layout'
union select 'Layouts_CannotEditStandardLayout',            'User does not have permissions to edit Standard Layout'
union select 'Layouts_CannotSaveDefaultLayout',             'Only System Admin can save Default Layouts'
union select 'Layouts_NoPermissionToCreateRoleLayout',      'User does not have permissions to add Layouts for this role'
union select 'Layouts_CannotEditOthersLayouts',             'Layout was created by another user and can only be modified by the user who created it'

union select 'Layouts_SelectionNameAlreadyExists',          'Selection already exists with the same name'
union select 'Layouts_CannotChangeLayoutType',              'Layout Type cannot be changed for System or Role Layouts'
union select 'Layouts_ZeroSelectionFilters',                'Selections with no filters are not allowed'
union select 'Layouts_NoAggregateFields',                   'Summary layout should have at least one summary field'
union select 'Layouts_NoVisibleFields',                     'Layout should have at least one field'
union select 'Layouts_NoDeleteorUpdatesinFilters',          'Delete and update keywords are not allowed in custom filters'

union select 'Layouts_Modify_NoneUpdated',                  'Note: None of the selected Layouts have been modified'
union select 'Layouts_Modify_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected Layouts have been modified'
union select 'Layouts_Modify_Successful',                   'Note: All selected (%TotalRecords) Layouts have been modified successfully'

union select 'Layouts_Delete_NoneUpdated',                  'Note: None of the selected Layouts are deleted'
union select 'Layouts_Delete_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected Layouts are deleted'
union select 'Layouts_Delete_Successful',                   'Note: All selected (%RecordsUpdated) Layouts have been deleted successfully'

/*---------------------------------------------------------------------------------------
Fields Related:
---------------------------------------------------------------------------------------*/
union select 'Fields_Edit_Successful',                      'Fields details updated successfully'

/*---------------------------------------------------------------------------------------
LayoutFields Related:
---------------------------------------------------------------------------------------*/
union select 'LayoutFields_Edit_Successful',                'Layout Field details updated successfully'

/*---------------------------------------------------------------------------------------
Ship Label Related:
---------------------------------------------------------------------------------------*/
union select 'ShipLabel_LPNNotOnAnyOrder',                  'LPN is not assigned to any Order and hence no labels can be printed'
union select 'ShipLabel_InvalidOrderType',                  'No shipping labels are required for %RecordsUpdated Orders'
union select 'ShipLabel_NoEntityFoundToPrint',              'No Entity found to Print'
union select 'ShipLabel_InvalidInput',                      'Valid input has to be given to print or view'
union select 'ShipLabel_NotaValidEntity',                   'Please enter a valid LPN, Pallet, PickTicket or Wave to print or view'
union select 'ShipLabel_ReplenishOrder',                    'No labels to print for Replenish Orders or associated LPNs'
union select 'ShipLabel_ReplenishWave',                     'No labels to print for orders on a Replenish Wave or any of their associated LPNs'
union select 'ShipLabel_InsertedLPN',                       'Ship labels inserted successfully for LPN %1'
union select 'ShipLabel_InsertedPickTicket',                'Ship labels inserted successfully for Order %2'
union select 'ShipLabel_VoidedLPN',                         'Ship labels voided for LPN %1'
union select 'ShipLabel_VoidedPickTicket',                  'Ship labels voided for Order %2'
union select 'ShipLabel_VoidedLPNs',                        'Note: %3 Ship labels are voided successfully'

/*---------------------------------------------------------------------------------------
Pick Tasks Related:
---------------------------------------------------------------------------------------*/
union select 'Tasks_AssignToUser_NoneUpdated',              'Note: None of the selected PickTasks are assigned'
union select 'Tasks_AssignToUser_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected PickTasks have been assigned'
union select 'Tasks_AssignToUser_Successful',               'Note: All selected PickTasks (%RecordsUpdated) have been assigned successfully'

union select 'Tasks_AssignUser_InvalidStatus',              'Task %1 is not a valid status, hence it cannot be assigned to user'

union select 'Tasks_UnassignUser_NoneUpdated',              'Note: None of the selected PickTasks are Unassigned'
union select 'Tasks_UnassignUser_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected PickTasks have been unassigned'
union select 'Tasks_UnassignUser_Successful',               'Note: All selected PickTasks (%RecordsUpdated) have been unassigned successfully'

union select 'Tasks_UnassignUser_NotAssigned',              'Task cannot be unassinged as it is not assigned to any user yet'
union select 'Tasks_UnassignUser_InvalidStatus',            'Task %1 is not a valid status, hence it cannot be unassigned from user'

union select 'Tasks_ConfirmPicks_NoneUpdated',              'None of the selected Tasks are confirmed for Picking'
union select 'Tasks_ConfirmPicks_SomeUpdated',              '%RecordsUpdated of %TotalRecords selected Tasks have been confirmed for Picking'
union select 'Tasks_ConfirmPicks_Successful',               'All selected (%TotalRecords) Tasks have been confirmed for Picking'

union select 'Tasks_ComfirmPicks_NoTempLabels',             'Cannot confirm picks as there are no Templabels on this task'
union select 'Tasks_ComfirmPicks_TasksNotReleased',         'Cannot confirm Picks as task is in %2 status, Please release the task before confirm'
union select 'Tasks_ComfirmPicks_InvalidStatus',            'Cannot confirm picks as task is in %2 status'
union select 'Tasks_ComfirmPicks_InvalidWaveTypes',         'Cannot confirm picks in %3 wave type'

union select 'PickTask_CancelTaskDetail_NoneUpdated',       'Note: None of the selected PickTask lines are cancelled'
union select 'PickTask_CancelTaskDetail_SomeUpdated',       'Note: %RecordsUpdated of %TotalRecords selected PickTask lines have been cancelled'
union select 'PickTask_CancelTaskDetail_Successful',        'Note: All selected PickTask lines (%RecordsUpdated) have been cancelled successfully'

union select 'PickTask_CancelTask_NoneUpdated',             'None of the selected Tasks are cancelled'
union select 'PickTask_CancelTask_SomeUpdated',             '%RecordsUpdated of %TotalRecords selected Tasks have been cancelled'
union select 'PickTask_CancelTask_Successful',              'All selected (%TotalRecords) Tasks have been cancelled'

union select 'PickTask_TaskCancel_Deferred',                'Note: Selected %1 Task is in the process of being canceled'
union select 'PickTask_CancelTask_AlreadyCanceledorCompleted',
                                                            'Cannot cancel the Task as it is already Canceled or Completed'
union select 'PickTask_CancelTask_CancelInProgress',        'Note: Selected %1 Task is already Cancel-In Progress'

union select 'PickTask_ConfirmTasksForPicking_NoneUpdated', 'None of the selected Tasks are confirmed for Picking'
union select 'PickTask_ConfirmTasksForPicking_SomeUpdated', '%RecordsUpdated of %TotalRecords selected Tasks have been confirmed for Picking'
union select 'PickTask_ConfirmTasksForPicking_Successful',  'All selected (%TotalRecords) Tasks have been confirmed for Picking'
union select 'NotEnoughInventoryToConfirmTasks',            'Not Enough Inventory to Confirm Tasks'
union select 'Task_DocumentsQueued_Successful',             'Documents Queued for Printing'

union select 'TaskDetails_Export_SomeUpdated',              '%RecordsUpdated of %TotalRecords selected records have been confirmed to Re-Export'
union select 'TaskDetails_Export_NoneUpdated',              'None of the selected records are Ready to Export'
union select 'TaskDetails_Export_Successful',               'All selected (%TotalRecords) records have been confirmed to Re-Export the data to 6rvr'

union select 'TaskDetails_Export_CompletedOrCanceled', 'Task Detail %1 not updated as it is already completed or cancelled'
union select 'TaskDetails_Export_InvalidPickMethod',   'Task Detail %1 need not be exported as it would be executed in CIMS only'
union select 'TaskDetails_Export_ReadyToExport',       'Task Detail %1 is already in queued for Export'

/*---------------------------------------------------------------------------------------
Shipping Docs Related:
---------------------------------------------------------------------------------------*/
union select 'ShippingDocs_DocumentsQueued',                'Documents Queued for printing; Job Id %1'

/*---------------------------------------------------------------------------------------
Label Formats Related:
---------------------------------------------------------------------------------------*/
union select 'LabelFormatNameIsRequired',                   'Label format name is required'
union select 'LabelFormatAlreadyExists',                    'Label format already exists'
union select 'LabelFormatDescIsRequired',                   'Label format description is required'

union select 'LabelFormats_Add_NoneUpdated',                'Note: The Label format is not added'
union select 'LabelFormats_Add_Successful',                 'Label format added successfully'

union select 'LabelFormats_Edit_NoneUpdated',               'Note: None of the selected Label formats are updated'
union select 'LabelFormats_Edit_SomeUpdated',               'Note: %RecordsUpdated of %TotalRecords selected Label formats have been updated'
union select 'LabelFormats_Edit_Successful',                'Note: All selected Label formats (%RecordsUpdated) have been updated successfully'

/*---------------------------------------------------------------------------------------
Report Formats Related:
---------------------------------------------------------------------------------------*/
union select 'ReportFormatNameIsRequired',                  'Report name is required'
union select 'ReportFormatAlreadyExists',                   'Report name already exists'
union select 'ReportFormatDescIsRequired',                  'Report description is required'

union select 'ReportFormats_Add_NoneUpdated',               'Note: The Report format is not added'
union select 'ReportFormats_Add_Successful',                'Report format added successfully'

union select 'ReportFormats_Edit_NoneUpdated',              'Note: None of the selected Report formats are updated'
union select 'ReportFormats_Edit_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected Report formats have been updated'
union select 'ReportFormats_Edit_Successful',               'Note: All selected Report formats (%RecordsUpdated) have been updated successfully'

/*---------------------------------------------------------------------------------------
Print Jobs Related:
---------------------------------------------------------------------------------------*/
union select 'PrintJobs_JobNotCompletedOrCancelled',        'Job Id - %1 is neither Completed nor Canceled to Reprint the job'

union select 'PrintJobs_ReleaseForPrinting_NoneUpdated',    'Note: None of the selected Print Jobs are released for printing'
union select 'PrintJobs_ReleaseForPrinting_SomeUpdated',    'Note: %RecordsUpdated of %TotalRecords selected PrintJobs have been released'
union select 'PrintJobs_ReleaseForPrinting_Successful',     'Note: All selected Print Jobs (%RecordsUpdated) have been released successfully'

union select 'PrintJobs_Reprint_NoneUpdated',               'Note: None of the selected Print Jobs are scheduled for reprinting'
union select 'PrintJobs_Reprint_SomeUpdated',               'Note: %RecordsUpdated of %TotalRecords selected PrintJobs have been scheduled for reprinting'
union select 'PrintJobs_Reprint_Successful',                'Note: All selected Print Jobs (%RecordsUpdated) have been scheduled for reprinting'

union select 'PrintJobs_Cancel_NoneUpdated',                'Note: None of the selected Print Jobs are canceled'
union select 'PrintJobs_Cancel_SomeUpdated',                'Note: %RecordsUpdated of %TotalRecords selected Print Jobs have been canceled'
union select 'PrintJobs_Cancel_Successful',                 'Note: All selected (%TotalRecords) Print Jobs have been canceled'
union select 'PrintJobCancel_AlreadyCompletedOrCancelled',  'Print Job %1 is already Completed Or Cancelled'

union select 'PrintJobs_InvalidPrinter',                    'Invalid printer to create print job'
union select 'PrintJobs_NoDocumentsToProcess',              'No Documents not available to process'

union select 'PrintJob_AlreadyReleased',                    'Print Job %1 is already Released'
union select 'PrintJob_OnHold',                             'Print Job %1 is on hold, cannot be released'

/*---------------------------------------------------------------------------------------
Printers Related:
---------------------------------------------------------------------------------------*/
union select 'PrinterAlreadyExists',                        'Printer already exists with that name'
union select 'PrinterDoesNotExist',                         'Printer does not exist to Edit or Delete'
union select 'PrinterNameIsrequired',                       'Printer Name is required and should be unique'
union select 'PrinterDescIsrequired',                       'Printer Description is required'

union select 'Printers_Add_Successful',                     'Printer %1 added successfully'
union select 'Printers_Edit_Successful',                    'Printer details updated successfully for Printer %1'
union select 'Printers_Delete_Successful',                  'Selected Printer(s) deleted successfully'

union select 'Printers_ResetStatus_Successful',             'Note: Status of all selected Printers has been reset successfully'
union select 'Printers_ResetStatus_SomeUpdated',            'Note: Status of %PrintersUpdated of %TotalPrinters selected printers has been reset successfully'
union select 'Printers_ResetStatus_NoneUpdated',            'Note: None of the selected Printers statuses are reset'
union select 'Printers_ResetStatus_AlreadyInReadyStatus',   'Printer %1, cannot reset as already in Ready status'

/*---------------------------------------------------------------------------------------
Tote Operations Related:
---------------------------------------------------------------------------------------*/
union select 'SelectedLPNFromWrongWarehouse',               'Selected Carton/Tote From wrong Warehouse'
union select 'PickZoneIsRequired',                          'Pick Zone is required'

/*---------------------------------------------------------------------------------------
Event Monitor Alert Mails Related:
---------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ImportCSV',                    'CIMS Data Exchange application that is scheduled to import files from Host system every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ImportCSV',                    'Alert! CIMS Data Exchange for Imports not running (#Environment)'

union select 'EMA_Message_DE-ImportPDV',                    'CIMS Data Exchange application that is scheduled to import files from Host system every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ImportPDV',                    'Alert! CIMS Data Exchange for Imports not running (#Environment)'

union select 'EMA_Message_DE-ImportXML',                    'CIMS Data Exchange application that is scheduled to import files from Host system every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ImportXML',                    'Alert! CIMS Data Exchange for Imports not running (#Environment)'

union select 'EMA_Message_DE-ImportFWF',                    'CIMS Data Exchange application that is scheduled to import files from Host system every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ImportFWF',                    'Alert! CIMS Data Exchange for Imports not running (#Environment)'

union select 'EMA_Message_DE-IMPORTEDI',                    'CIMS Data Exchange application that is scheduled to import files from Host system every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-IMPORTEDI',                    'Alert! CIMS Data Exchange for EDI Imports not running (#Environment)'

/*-------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ExportINVOH_CSV',              'CIMS Data Exchange application that is scheduled to export Onhand Inventory every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportINVOH_CSV',              'Alert! CIMS Data Exchange for Onhand Inventory Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportINVOH_PDV',              'CIMS Data Exchange application that is scheduled to export Onhand Inventory every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportINVOH_PDV',              'Alert! CIMS Data Exchange for Onhand Inventory Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportINVOH_XML',              'CIMS Data Exchange application that is scheduled to export Onhand Inventory every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportINVOH_XML',              'Alert! CIMS Data Exchange for Onhand Inventory Exports not running (#Environment)'

/*-------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ExportLMSData_FWF',            'CIMS Data Exchange application that is scheduled to export LMS Data every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportLMSData_FWF',            'Alert! CIMS Data Exchange for LMS Exports not running (#Environment)'

/*-------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ExportOpenOrders_CSV',         'CIMS Data Exchange application that is scheduled to export Open Orders to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportOpenOrders_CSV',         'Alert! CIMS Data Exchange for Open Orders has not run (#Environment)'

union select 'EMA_Message_DE-ExportOpenOrders_PDV',         'CIMS Data Exchange application that is scheduled to export Open Orders to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportOpenOrders_PDV',         'Alert! CIMS Data Exchange for Open Orders has not run (#Environment)'

union select 'EMA_Message_DE-ExportOpenOrders_XML',         'CIMS Data Exchange application that is scheduled to export Open Orders to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportOpenOrders_XML',         'Alert! CIMS Data Exchange for Open Orders has not run (#Environment)'

/*-------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ExportOpenReceipts_CSV',       'CIMS Data Exchange application that is scheduled to export Open Receipts to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportOpenReceipts_CSV',       'Alert! CIMS Data Exchange for Open Receipts has not run (#Environment)'

union select 'EMA_Message_DE-ExportOpenReceipts_PDV',       'CIMS Data Exchange application that is scheduled to export Open Receipts to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportOpenReceipts_PDV',       'Alert! CIMS Data Exchange for Open Receipts has not run (#Environment)'

union select 'EMA_Message_DE-ExportOpenReceipts_XML',       'CIMS Data Exchange application that is scheduled to export Open Receipts to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportOpenReceipts_XML',       'Alert! CIMS Data Exchange for Open Receipts has not run (#Environment)'

/*-------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ExportRecv_CSV',               'CIMS Data Exchange application that is scheduled to export Receipt Confirmations to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportRecv_CSV',               'Alert! CIMS Data Exchange for Receipt Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportRecv_PDV',               'CIMS Data Exchange application that is scheduled to export Receipt Confirmations to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportRecv_PDV',               'Alert! CIMS Data Exchange for Receipt Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportRecv_XML',               'CIMS Data Exchange application that is scheduled to export Receipt Confirmations to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportRecv_XML',               'Alert! CIMS Data Exchange for Receipt Exports not running (#Environment)'

/*-------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ExportShip_CSV',               'CIMS Data Exchange application that is scheduled to export Ship Confirmations to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportShip_CSV',               'Alert! CIMS Data Exchange for Ship Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportShip_PDV',               'CIMS Data Exchange application that is scheduled to export Ship Confirmations  to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportShip_PDV',               'Alert! CIMS Data Exchange for Ship Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportShip_XML',               'CIMS Data Exchange application that is scheduled to export Ship Confirmations  to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportShip_XML',               'Alert! CIMS Data Exchange for Ship Exports not running (#Environment)'

/*-------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ExportTrans_CSV',              'CIMS Data Exchange application that is scheduled to export transactions to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportTrans_CSV',              'Alert! CIMS Data Exchange for Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportTrans_PDV',              'CIMS Data Exchange application that is scheduled to export transactions to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportTrans_PDV',              'Alert! CIMS Data Exchange for Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportTrans_XML',              'CIMS Data Exchange application that is scheduled to export transactions to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportTrans_XML',              'Alert! CIMS Data Exchange for Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportTrans_FWF',              'CIMS Data Exchange application that is scheduled to export transactions to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportTrans_FWF',              'Alert! CIMS Data Exchange for Exports not running (#Environment)'

union select 'EMA_Message_DE-ExportTrans_EDI',              'CIMS Data Exchange application that is scheduled to export EDI transactions to host every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportTrans_EDI',              'Alert! CIMS Data Exchange to Exports not running (#Environment)'

/*-------------------------------------------------------------------------------------*/
union select 'EMA_Message_DE-ExportINVOHByOwner_CSV',       'CIMS Data Exchange application that is scheduled to export Onhand Inventory every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportINVOHByOwner_CSV',       'Alert! CIMS Data Exchange to Export Inventory is not running (#Environment)'

union select 'EMA_Message_DE-ExportINVOHByOwner_PDV',       'CIMS Data Exchange application that is scheduled to export Onhand Inventory every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportINVOHByOwner_PDV',       'Alert! CIMS Data Exchange to Export Inventory is not running (#Environment)'

union select 'EMA_Message_DE-ExportINVOHByOwner_XML',       'CIMS Data Exchange application that is scheduled to export Onhand Inventory every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ExportINVOHByOwner_XML',       'Alert! CIMS Data Exchange to Export Inventory is not running (#Environment)'

union select 'EMA_Message_DE-ImportRoutingConfimations',    'CIMS Data Exchange application that is scheduled to Import Routing confirmation every 5 minute(s) has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ImportRoutingConfimations',    'Alert! CIMS Data Exchange to Import Routing confirmation is not running (#Environment)'

union select 'EMA_Message_DE-WAVEDETAILS_FW',               'CIMS Data Exchange application that is scheduled to Export Wave Details every %RUNINTERVAL minute(s) has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-WAVEDETAILS_FW',               'Alert! CIMS Data Exchange to Export Wave Details is not running (#Environment)'

union select 'EMA_Message_DE-ROUTERINSTRUCTIONS_FW',        'CIMS Data Exchange application that is scheduled to Export Router Instructions every %RUNINTERVAL minute(s) has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ROUTERINSTRUCTIONS_FW',        'Alert! CIMS Data Exchange to Export Router Instructions is not running (#Environment)'

union select 'EMA_Message_DE-ITEMMASTERDATA_FW',            'CIMS Data Exchange application that is scheduled to Import Item Master every %RUNINTERVAL minute(s) has not run since %LASTRUNAT'
union select 'EMA_Subject_DE-ITEMMASTERDATA_FW',            'Alert! CIMS Data Exchange to Import Item Master is not running (#Environment)'

union select 'EMA_Message_ShippingDocsExport_1',            'CIMS Shipping Docs Export application instance #1 that is scheduled to export shipping docs every %RUNINTERVAL minute(s) has not run since %LASTRUNAT'
union select 'EMA_Subject_ShippingDocsExport_1',            'Alert! CIMS Shipping Docs Export instance #1 to export shipping docs is not running (#Environment)'

union select 'EMA_Message_ShippingDocsExport_2',            'CIMS Shipping Docs Export application instance #2 that is scheduled to export shipping docs every %RUNINTERVAL minute(s) has not run since %LASTRUNAT'
union select 'EMA_Subject_ShippingDocsExport_2',            'Alert! CIMS Shipping Docs Export instance #2 to export shipping docs is not running (#Environment)'

union select 'EMA_Message_ShippingDocsExport_3',            'CIMS Shipping Docs Export application instance #3 that is scheduled to export shipping docs every %RUNINTERVAL minute(s) has not run since %LASTRUNAT'
union select 'EMA_Subject_ShippingDocsExport_3',            'Alert! CIMS Shipping Docs Export instance #3 to export shipping docs is not running (#Environment)'

union select 'EMA_Message_GenerateLabels_1',                'CIMS Ship Label Generator application instance #1 that is scheduled to generate ship labels every %RUNINTERVAL minutes has not run since %LASTRUNAT'
union select 'EMA_Subject_GenerateLabels_1',                'Alert! CIMS Ship Label Generator instance #1 to generate ship labels is not running (#Environment)'

/*---------------------------------------------------------------------------------------
Interface Error Alert Mails Related:
---------------------------------------------------------------------------------------*/
union select 'InterfaceError_Alert_Subject',                'CIMS: Staging / Production Interface Errors'

/*---------------------------------------------------------------------------------------
Export Alert Mails Related:
---------------------------------------------------------------------------------------*/
union select 'ExportBatchNotCreated_Alert_Subject',         'CIMS: Export Batch not created'

/*---------------------------------------------------------------------------------------
Shipments Mails Related:
---------------------------------------------------------------------------------------*/
union select 'Shipments_Subject',                           'Track Your Shipment(s)'

/*------------------------------------------------------------------------------*/
/* Users */
/*------------------------------------------------------------------------------*/
union select 'RFUserLogoutSuccess',                         'User %1 logged out successfully. Bye %2'
union select 'RFUserLogoutFailed',                          'User %1 logged out failed'

/*------------------------------------------------------------------------------
Activity Log Related
------------------------------------------------------------------------------*/
union select 'ACT_ConfirmLPNPutaway',                       'LPN %1 Putaway to Location/Pallet %2'
union select 'ACT_CancelLPNPutaway',                        'LPN %1 Putaway cancelled'
union select 'ACT_ValidateLPNPutaway',                      'Validating LPN %1 to Putaway'
union select 'ACT_SetLocation',                             'LPN %1 updated with Location %2'

/*---------------------------------------------------------------------------------------
Bcp Utility Errors Related:
---------------------------------------------------------------------------------------*/
union select 'NoDataQuerySupplied',                         'No Query was supplied to the stored procedure to execute the BCP'
union select 'NoHeaderQuerySupplied',                       'No Header Query was supplied to add the header row in the file'
union select 'NoFileNameSupplied',                          'No File name was supplied to generate the file'

/*------------------------------------------------------------------------------
  Access & Privileges:
------------------------------------------------------------------------------*/
union select 'PermissionsModifiedSuccessfully',             'Permission(s) modified successfully'

/*------------------------------------------------------------------------------*/
/* Permissions */
/*------------------------------------------------------------------------------*/

union select 'RolePermissions_RevokePermission_Successful', 'Note: Updated (%RecordsUpdated) Permissions for Role(s) %1 successfully'
union select 'RolePermissions_GrantPermission_Successful',  'Note: Updated (%RecordsUpdated) Permissions for Role(s) %1 successfully'

/*------------------------------------------------------------------------------
  UI Setup & Configuration:
------------------------------------------------------------------------------*/
union select 'DeviceIdRequired',                            'DeviceId is required!!!'
union select 'DeviceIdUnknown',                             'DeviceId is unknown!!!'
union select 'DeviceNameExists',                            'Device Name must be unique!!!'
union select 'LabelPrinterUnknown',                         'Label Printer unknown!!!'
union select 'LabelPrinterNotActive',                       'Label Printer should be active!!!'
union select 'ReportPrinterUnknown',                        'Document Printer unknown!!!'
union select 'ReportPrinterNotActive',                      'Document Printer should be active!!!'
union select 'DeviceConfigurationSuccessful',               'Device Configuration updated successfully!!!'

/*------------------------------------------------------------------------------*/
/* User run procedures */
/*------------------------------------------------------------------------------*/

union select 'UserRunInputStringEmpty',                     'Input string is either empty or of invalid format'
union select 'UserRunNoRecordFound',                        'No Records found. Please check input string for valid values and format'


Go

/* Replace the environment name */
update #Messages
set Description = replace(Description, '#Environment', 'Dev');

/* Delete any existing Messages */
delete from Messages where MessageName not like 'AT_%';

/* Replace the #FieldName with the appropriate caption */
update M
set Description = replace(Description, '#' + dbo.fn_SubstringFromCharToChar(Description, '#', ' ', 1), F.Caption)
--output deleted.Description, inserted.Description
from #Messages M
  join Fields F on dbo.fn_SubstringFromCharToChar(M.Description, '#', ' ', 1) = F.FieldName
where (M.Description like '%#%')

/* Add the new messages */
insert into Messages (MessageName, Description, NotifyType, Status, BusinessUnit)
  select MessageName, Description, 'E' /* Error */, 'A' /* Active */, (select Top 1 BusinessUnit from vwBusinessUnits order by SortSeq)
  from #Messages;

Go
