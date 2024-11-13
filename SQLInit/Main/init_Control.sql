/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2023/08/22  GAG     Added Controls for BuildInvLPN (CIMSV3-3035)
  2024/10/02  AY/RV   Added Shipping_FedEx-ResidentialServices and Shipping_FedEx-NonResidentialServices
                       Removed Shipping_FedEx-AllHomeDeliveryIsResidential (CIMSV3-3836)
  2024/08/21  RV      Added AddressValidation-ExportOnAddressError (CIMSV3-3532)
  2024/07/02  RV      Added Alerts_APIOutboundTransactions-Subject (HA-4201)
  2023/03/27  LAC     Added Wave_PreprocessOrder (BK-1036)
  2022/11/02  VM      Change all controls visible to -1, which needs to be ignored to sync up in redgate comparison (CIMSV3-2384)
  2022/10/07  AY      Archive/CarrierTrackingInfo-Days; Changed to 2 (BK-920)
  2022/08/17  PKK     Added Tasks_ComfirmPicks (BK-864)
  2022/08/09  VS      Added USPSF,USPSP in SmallPackageLoadTypes control (BK-890)
  2022/07/29  RV      Added UPS_ShipToAddressValidation - RevertOrderToDownload (BK-882)
  2022/06/13  VS      Added UpdateInvSnapShot, ExportInvSnapshot (FBV3-1203)
  2022/05/04  RKC     Added CrossLocationSubstitution, CrossWarehouseSubstitution under BatchPicking (BK-819)
  2022/04/13  VS      Added PickBatch_BKPP wave controls (BK-800)
  2022/03/10  PHK     Added Import_File_SKU to import SKUs from UI via CVS file (HA-109)
  2022/02/23  VS      Added DefaultEmailId for ShipLabels category (CIMSV3-1780)
  2021/12/08  NB      Added UI Control to Root Category, FolderPath_UI to ExportToExcel(CIMSV3-810)
  2021/11/11  KBB     Added InventoryChanges (BK-642)
  2021/11/01  RV      Added APIInboundTransactions-Days and APIOutboundTransactions-Days (BK-510)
  2021/10/13  RV      Added Packing - PackDetailsMode (BK-636)
  2021/10/11  RKC     Added Alerts_ListOfOrdersToShip control to send email alert (BK-638)
  2021/10/07  AY      Picklane Location inquiry fixed RFInquiry_Location_K (CIMSV3-1666)
  2021/10/07  VS      Added 'Imports' controls (HA-3084)
  2021/09/18  TK      Do not ship LPN on pack (BK-597)
  2021/08/27  RIA     Added control for LPNShipCartonActivate - PromptPallet (BK-541)
  2021/08/25  OK      Added Small Package load type in SmallPackageLoadTypes (BK-497)
  2021/08/18  VS      Added control for ShipCompleteThreshold (BK-475)

  2021/08/11  RV      Added PackingList-ShowComponentSKUsLines (BK-484)
  2021/08/02  VS      Added TransferToDBMethod (HA-3032)
  2021/08/04  RIA     Changed RFMaxRecordsPerRun to RFNumLinesToDisplay
                      Added AdjustLocation, AdjustLPN, ManagePicklane, TransferLocation, TransferLPN (HA-2938)
  2021/07/29  RV      Added ConvertToSetSKUs - ValidOrderStatus and ValidLPNStatus (OB2-1948)
  2021/07/29  RV      Added Packing-ShowComponentSKUsLines (OB2-1959)
  2021/07/09  SK      Added controls for Productivity (HA-2972)
  2021/06/21  RIA     Added RFDataTableMaxRecords (HA-2878)
  2021/05/05  SV      Added SendInvChTransForRecv (OB2-1791)
  2021/05/19  TK      Added CarrierTrackingInfo-Days under Archive category (BK-291)
  2021/05/19  OK      Added control ThresholdTimeToRegenerate (HA-2774)
  2021/05/06  VS      Added control for Small Package Loads (BK-275)
  2021/04/28  RIA     Added RFInquiry_Location_R, RFInquiry_Location_K (OB2-1767)
  2021/04/22  RIA     Added control for PromptPallet (HA-2684)
  2021/04/20  SV      Added controls for RMA Returns (OB2-1358)
  2021/04/03  RKC     Import_OD: Changed the control code for DeleteNonExistingRecord (HA-2489)
  2021/03/24  VS      Added Alert_AllocationStatistics (CIMSV3-1047)
  2021/03/21  RKC     Changed the control code for ValidWaveStatuses (HA-2368)
  2021/03/18  SK      LPNShipCartonCancel: new control for LPN status (HA-2319)
  2021/03/11  SV      Added controls for Receipts - Returns (OB2-1358)
  2021/03/07  OK      Added control ValidUnavailableLPNStatuses (HA-2176)
  2021/03/06  OK      Added control StatusCalcMethod (HA-2095)
  2021/03/06  TK/VS   Changes dataset name for Import_File_LRI from LoadRoutingInfo to LRI (HA-2141)
  2021/03/02  VS      Changed the AutoShipLPN - ShipOnLabel control changed to 'N' (BK-250)
  2021/03/02  SK      Updated controls for Loading (HA-1990)
  2021/02/26  RIA     Added controls for LPNShipCartonCancel (HA-2087)
  2021/02/25  TK      PickingConfig_UnitPickSingleScanGenTempLabel: DefaultQty should be UnitsToPick (BK-229)
  2021/02/20  AY      Added controls for BCP, BPP and RW Waves (HA-2031)
  2021/02/16  TK      Added UseSKUDimension under Cubing category (HA-1964)
  2021/02/09  RKC     Added controls for Import_File_INV (CIMSV3-1323)
  2021/02/05  RKC     Added new controlcode as ValidPalletTypes under DropPallet (HA-1960)
  2021/02/03  RKC     Changed the control for Import_File_* (CIMSV3-1351)
  2021/02/03  PK      Added controls for LPN_Temp (HA-1970)
  2021/01/27  SK      Changed waves types for 'AutoConfirmWaves' (HA-1952)
  2021/01/20  RKC/SV  Added controls for Import_File_LRI (HA-1926)
  2021/01/19  RKC     Added control for waves status calculation (HA-1859)
  2021/01/11  SK      Added RequestRoutingValidStatus (HA-1896)
  2021/01/04  SK      Added DefaultProcess for CycleCount (HA-1841)
  2020/12/28  AY      Added LPNShipCartonActivate-ValidPalletStatus (HA-1790)
  2020/11/29  RIA     Added Putaway_LPNsOnPallet (CIMSV3-727)
  2020/11/17  RKC     Changed the Control Values for OrderClose_T (HA-1662)
  2020/11/12  SV      Added InterfaceLog-Days (HA-1309)
  2020/11/11  SK      Added Cyclecount control to define blind or default cycle count (HA-1567)
  2020/10/28  RKC     Changed the Control value for OrderClose_C (HA-1631)
  2020/10/21  SV/SK   Added Import_File_LOC for Location imports from UI. Setup generic paths (CIMSV3-1120)
  2020/10/23  MS      Made changes to 'ValidActionCodes' control values (CIMSV3-1146)
  2020/10/22  SK      Added new internal recipient (HA-1598)
  2020/10/21  SV      Added Import_File_LOC for Location imports from UI (CIMSV3-1120)
  2020/10/20  TK      Added controls for valid LPN status for OrderClose (HA-1350)
  2020/10/08  AY      Renamed PickBatch_T to PickBatch_Xfer
  2020/10/07  RIA     Added AddSKU_MaxScanQty control for location type picklane (HA-1497)
  2020/09/29  AY      Added control for Image URL as ImageURLPath (CIMSV3-733)
  2020/09/03  SK      Added control codes GenerateTempLabel, PrintLabel for BCP/BPP (HA-1386)
  2020/08/27  TK      Added control to auto release tasks (HA-1211)
                      Added control to move reserved inventory (HA-1307)
  2020/08/17  NB      Migrated controls for Import_File & Import_File_SPL from CID SQL (HA-320)
  2020/08/13  MS      Added ShippingManifestMaster Controls (HA-1304)
  2020/08/07  MS      Added controls for BatchPicking_XFER, PickingConfig_UnitPickSingleScanGenTempLabel (HA-1273)
  2020/07/16  SK      Added new category for CC reason codes DefaultReasonCodes (CIMSV3-788)
  2020/07/07  NB      Added new Control Categories (CIMSV3-1011)
  2020/06/24  SK      Added new Control Category AutoActivation (HA-906)
  2020/06/15  TK      Allocate Replenish Wave with Released status (HA-948)
  2020/06/11  VS      Added Exports_ShipTransferOrder Control Codes (HA-110)
  2020/06/08  RIA     Added Mode as control for Receiving (HA-491)
  2020/06/08  TK      Added missing controls that are required for On-Demand replenishments (HA-871)
  2020/05/30  AY      Added control var to consider BCP as Wave with Bulk PT
  2020/05/27  TK      Changed control to cancel Released status waves (HA-646)
  2020/05/23  SK      Added new category LPNShipCartonActivate for ship cartons activation (HA-640)
  2020/05/15  TK      Batch picking controls migrated from CID (HA-543)
  2020/05/10  TK      Remove NextSeqNo for GenerateShipLabels (HA-468)
  2020/05/05  VS      Changed SendConsolidatedExports control to send consolidated exports based on RO Type (HA-339)
  2020/04/28  SPP\PK  Modified controlvalue from LPN to N for ExportRODOnClose (HA-296) (Ported from Prod)
  2020/04/28  VS      Added PutawayType control(HA-288)
  2020/04/22  MS      Enabled control to Generate batches & Correction to support email (HA-266)
  2020/04/16  AY      Moved CreateLPN to be specific to RO Type (HA-187)
  2020/04/07  VM      Added AllowNewInvBeforeReceiverClose (HA-118)
  2020/03/29  MS      Added control System Versoin (CIMSV3-786)
  2020/03/23  RIA     Added IsPalletizationRequired (CIMSV3-652)
  2020/03/18  MS      Added MovePallet,ValidPalletStatuses (JL-132)
  2020/02/10  MS      Changes to SKUDimensions conrol values (JL-76)
  2020/02/05  MS      Change the control value for ValidateUnitsPerPackage (JL-93)
  2020/01/27  MS      Added controls for PalletVolume & StdLPNsPerPallet (JL-58)
  2019/05/03  VS      Added Default as PickQty in Num Picked (CID-333)
  2019/02/08  VS      Added HoldQCorReleaseQC control for ReleaseQC or HoldQC (CID-68)
  2019/03/26  VS      Control Added for Totes (CID-208)
  2019/01/08  RV      Added ManifestExportBatch -> NextSeqNo (S2GCA-434)
  2018/12/12  TK      Added MaxQtyToReplenish under OnDemandReplenish category (HPI-2245)
  2018/11/23  RT      Added LPNReservation - ValidLPNStatuses (FB-1200)
  2018/10/05  SV      Added the suggested positions for categories PickingConfig_UnitPickSingleScan (S2GCA-355)
  2018/09/14  TK      On ShortPick, mark LPN as unallocate and create a cyclecount task (S2GCA-245)
  2018/08/30  DK      Removed controls related to Reference 1,2 and 3 as we are using rules (HPI-2010)
  2018/08/21  TK      Added necessary controls to generate PT status exports (S2GCA-200)
  2018/08/16  TK      Added Shipping InProgress status as valid for Load ship (S2GCA-190)
  2018/08/16  CK      Added control RFInquiry_Location for Location Inquiry (OB2-456)
  2018/08/07  TK      Allow Staged Status pallet for Loading (S2GCA-117)
  2018/07/31  VM      Added Alert_OpenOrdersSummary (S2G-1066)
  2018/07/27  RT      Added Controls for VICSBoLMaster for Standard, L1 and EA (S2GCA-112)
  2018/07/23  TK      Added Enable Single SKU controls (S2GCA-99)
  2018/07/23  RV      Added Shipping - SenderTaxId (S2G-919)
  2018/07/12  RV      Added TransferToDifferentWHPickLane and TransferToDifferentWHLPN (S2G-1034)
  2018/07/06  RV      Added Shipping - ShipmentConfirmationAlert (S2G-997)
  2018/06/19  MJ      Added SKUShipPackUpdate (S2G-967)
  2018/06/06  PK      Added StuffAdditionalInfoOnZPL (S2G-921)
  2018/06/01  RV      Added Shipping-WeightUOM (S2G-602)
  2018/05/08  RT      Added controls for OrderClose (S2G-630)
  2018/05/20  TK      Added AssignDockForMultipleLoads (S2G-747)
  2018/05/14  AJ      Changed Controlvalue for AlternateSKU (S2G-844)
  2018/05/08  AY      Added Generate_AddToExistingLoads (S2G-830)
  2018/05/07  RV      Added ShipLabels-IsReturnLabelRequired (S2G-827)
  2018/05/02  AY      Loading-ValidLPNStatus: Added packed (S2G-779)
  2018/05/01  AY      Added controls for Pro number generation (S2G-115)
  2018/04/27  AJ      Added Controls for CancelBatch with all active wave types (S2G-708)
  2018/04/24  RT      Added controls for Tractor Supply co orders (DropShip_XXXXXX)(SRI-860)
  2018/04/19  AJ      Added RegenerateTrackingNo (S2G-549)
  2018/04/16  KSK     Added AllowNonStandardPackConfig (S2G-541)
  2018/04/13  MJ      Added SKUCaseUPCUpdate (S2G-528)
  2018/04/12  RV      Modified PickingConfig_CasePick_Multiple to show case quantity (S2G-624)
  2018/04/10  RV      Added ExportShippingDocs-WaveTypesToExportShippingDocs to export shipping documents for export required waves (S2G-545)
  2018/04/06  AY/RV   Refactor the Picking configuration controls (S2G-579)
  2018/03/30  RV      Added UnitPick_SingleOrderPick (S2G-534)
  2018/03/24  VM      Added Alert_LPNCountsMismatch (S2G-486)
  2018/03/23  VM      Added Alert_LogicalLPNCountsMismatch (S2G-477)
                      Recipient control removed for all alert controls as without it, system uses defalut support group in proc (S2G-391)
  2018/03/22  RT      Added controls to setup Picklane Location for InActive SKU(S2G-454)
  2018/03/21  RV      Added CasePick_Multiple (S2G-421)
  2018/03/20  TD      Added controls for MaxPicksPerTask_U (S2G-456)
  2018/03/20  SV      Added AcceptExternalLPN code for for category Receiving_PO (S2G-452)
  2018/03/14  TK      Added UnallocatePartialLPN & DefaultQty (S2G-396)
  2018/03/12  VM      Added Alert_WavesNotAllocated (S2G-391)
  2018/03/12  VM      Added Alert_OrphanDLines (S2G-391)
  2018/03/10  VM      Added Alert_CIMSSupport, Alert_LocationCountDiscrepency, Alert_MisMatchOfODUnitsAssigned and their controls (S2G-391)
  2018/03/07  RV      Added WaveReleaseForPicking -> ValidWaveTypes
                            WaveReleaseForPicking -> ValidWaveStatuses (S2G-240)
  2018/03/02  AY/SV   Receiving-IsReceiverRequired has more expanded values to allow auto creation of Receiver.
                      Added LPNLocation_RIP, ConsiderLocWHForLPN anc made control value of LPNLocation_PO to default (S2G-337)
  2018/03/02  AY      Receiving-Default Qty should be string as it is an option (S2G-338)
  2018/02/25  DK      Added ExportRouterBatch -> NextSeqNo (S2G-208)
  2018/02/20  RV      Added ExportShippingDocs -> NextSeqNo (S2G-268)
  2018/02/14  CK      Added SKU -> UPCsRequired (S2G-155)
  2018/02/11  RV      Added GenerateShipLabels -> MaxLabelsToGenerate (S2G-110)
  2018/02/07  CK      Added SKUIPDimensionUpdate, SKUIPWeightUpdate, SKUIPWeightUpdate, ABCClassUpdate (S2G-18)
  2018/01/24  TK      Added InvReservationModel control (S2G-152)
  2018/01/22  KK      Added Controls for Cyclecount bulk storage Locations(S2G-133)
  2017/12/21  RA      Added control ExportToExcel for Batch no purpose (CIMS-1659)
  2017/09/04  NB      Added GridPageSizeV3 control set(CIMSV3-11)
  2016/11/10  KN      Added FedexShipLabelLogging , UPSShipLabelLogging (HPI-1032)
  2016/08/30  YJ      Added controls for Receipts for Over Receipt Percent (HPI-512)
  2016/07/28  KL      Added controls for Replenish Wave (HPI-360)
  2016/07/28  PSK     Added control related to ShipToPhoneNo (CIMS-1024).
  2016/07/15  DK      Added new control WaveUnitCalcMethod for PickBatch Category(HPI-273).
  2016/06/16  PSK     Changed the receiver control(CIMS-963).
  2016/06/01  PSK     Added new Controls PickBatch_ReleasePickBatch and PickBatch_ReallocateBatch (CIMS-921).
  2016/06/03  RV      Added ClearCartUser to validate statuses to clear the user from cart (NBD-573)
  2016/05/25  KL      Added controls for Cancel Replenish Orders when cancel replenish wave (NBD-529)
  2016/05/24  SV      Added new control EnableUoM for TransferInventory category (NBD-534)
  2016/05/11  TK      Added UnitPick_MultiScan, UnitPick_SingleScan, LPNPickToCart, LPNPickToPallet (NBD-459)
  2016/05/03  DK      Added Control for ExportByReceiver (NBD-435)
  2016/04/18  RV      Added AutoReleaseTasks to all Wave types (NBD-363)
  2016/04/06  TK      Allow Picking and Picked Status Replenish waves to Allocate
  2016/04/05  KL      Added Controls for Import details on the SKU (SRI-482)
  2016/04/01  DK      Added Control Enable ReasonCodes under Transfer Inventory (FB-646).
  2016/03/30  KL      Added SKUDimensionUpdate under SKU's (SRI-482)
  2016/03/21  TK      Added XMLResultRequired unders imports (HPI-25)
  2016/03/15  OK      Added InventorySnapshot related control variable (CIMS-823)
  2016/03/15  OK      Added IgnoreLocationsToSetStatus (NBD-283)
  2016/03/15  OK      Added BoLRequired control for all Carriers (NBD-281)
  2016/03/10  RV      Added AddMsgHeaderNode under OnhandInventory to add the message header (CIMS-809)
  2016/03/10  TK      Added ValidActionCodes for imports (NBD-243)
  2016/03/02  NY      Added PickPath, Putawaypath (SRI-446)
  2016/03/02  TK      Added AllowStagingLocations under CycleCount (FB-599)
  2016/02/23  PK      Added WHXferAsInvCh (SRI-472)
  2016/02/25  TK      Added Controls for RFPutawayLPNs (GNC-1247)
  2016/02/17  OK      Changed the Receiver Number format (CIMS-778)
  2016/01/30  SV      Added ModifyOrder (FB-609)
  2016/01/28  AY      Allow Multiple SKUs configured by Location Type
  2016/01/25  TK      Added controls for Packing_CloseLPN, Packing_RFPacking (NBD-64)
  2016/01/20  SV      Added ReCalculateWeightOnLPN (CIMS-741)
  2016/01/18  TD      Added new controlcode Task_SplitOrder.
  2016/01/13  TK      Added controls for RF Packing (ACME-64)
  2015/12/05  TK      Added controls for MinMaxReplenish & OnDemandReplenish (ACME-419)
  2015/12/04  RV      Added control ExportByLoad under ExportData (FB-560)
  2015/12/03  VM      Added LPNReservation->ConfirmLPNAsPickedOnAllocate, RequireUniquePT, ReassignAcrossCustPOs, ReassignAcrossWaves (FB-541)
  2015/11/20  RV      Added Picking->ConfirmEmptyLocation (FB-505)
              DK      Added control ValidBatchStatuses under ReplenishBatch (FB-499).
              VM      Added Reservation->ConfirmLPNAsPickedOnAllocate (FB-528)
  2015/11/16  SV      Added UpdateOD_OrderStatusInvalid (SRI-416)
  2015/10/30  RV      Added controls for Putaway of SKUPAClassRequired (FB-474)
  2015/10/30  TK      Added ConfirmQtyMode under CycleCount(ACME-379)
  2015/10/28  YJ      Added controls for ReplenishOrder (FB-400)
  2015/10/25  NY      Added Remove_Order(LL-235)
  2015/10/22  NY      Added PalletTareWeight, Volume.
  2015/10/14  PK      Added BayMaxLength
  2015/10/08  TD      Changed replenish order format.
  2015/09/30  OK      Added the controls for Export.return (FB-388).
  2015/09/11  PK      Added Control for WaveShortsSummary (FB-380)
  2015/09/25  TK      Added Controls for Activity Log(ACME-348)
  2015/09/25  OK      Added the controls for return type receipts (FB-388).
  2015/09/22  TK      Added ConfirmPAToDiffLoc under Putaway category (ACME-343)
  2015/09/09  RV      Added IsLabelPrinterConfigRequired for Label Print (FB-379)
  2015/09/10  TK      Added Control 'GenerateLoadForWave' (ACME-328)
  2015/09/09  YJ      Added Controls for Carton Types (ACME-312)
  2015/09/08  YJ      Added Control for Loading (ACME-311)
  2015/09/03  SV      Added 'Import_RecordProcessType' (FB-356)
  2015/08/10  RV      Added Default UOM for Locaitons (FB-296).
  2015/08/08  YJ      Added CancelPTLine to allow Allow partial line cancel
  2015/08/05  VM      Added LPN_Ship controls (FB-288)
                      Reorganize a control to be in sequence
  2015/07/29  TK      Added PickBatch_UnitPick, PickBatch_LPNPalletPick (ACME-268)
  2015/06/04  TK      Added Inv_TransferInventory controls
  2015/06/01  OK      Added PutawayBeforeClose,ScanPreference,PutawayInventoryOnClose controls
  2015/05/29  SV      Added CreateInvLPN-SKUPrePackQtyLimitation
                      Included Location Controls
  2015/05/27  RV      Added Interface Log and Mail_ProfileName controls.
  2015/05/25  DK      Added BuildPallet-ShowConfirmationMessage
  2015/05/13  RV      Updated Import_ASNLD : LPN Status Updated Recieved to InTransit.
  2015/04/23  PK      Added BPT_Allocate for Bulk Pull Preference Batch.
  2015/03/31  DK      Added UseInnerPacks control.
  2015/03/24  NY      Added Packing Status - 'TransferInventory-InvalidToLPNStatuses'
  2015/03/25  DK      Added ValidLPNStatusToClose.
  2015/03/24  NB      Added 'Packing' - 'ShowLinesNotPicked'
  2015/03/17  RV      Added Remove_SKU control.
  2015/03/09  PK      Added GenerateExportsOnPPExplode.
  2015/02/27  TK      Added BPT_Allocate for Bulk Pull Batch
  2015/02/26  TK      Added PB_CreateBPT for Bulk Pull Batch
  2015/02/20  AK      Added AllowMultipleSKUs control for Location.
  2015/01/29  VM      Introduced 'BatchPicking' - 'AllowSubstitution'
  2015/01/29  VM      Introduced 'Allocation' - 'Debug'
  2015/01/25  VM      Added UseSKUStandardQty, UseFLThresholdQty
  2015/01/23  TK      Added controls for 'System' and 'Tasks'
              DK      Added UseInnerPacks control.
  2015/01/13  VM      GenerateTempLabel-Generate Temporary Label - Do not require for SRI
                      set CompanyId for SSCCBarcode and UCCBarcode
                      LogicalLPNFormat: Not required
  2015/01/12  TK      Changed DefaultUoM value to 'EA'
  2015/01/06  SV      Added UPS and FEDEX controls
  2015/01/03  AK      Updated control value of CreateLPN.
  2014/12/28  DK      Added SKUDimensionsRequired, SKUCubeWeightRequired, SKUPackInfoRequired and PalletTieHighRequired.
  2014/12/26  TK      Updated control value of Pallet_C.
  2014/11/28  DK      Added DefaultUoM and EnableUoM for Inv_AddSKUToLPN
  2014/11/21  SV      Added DropShip controls for Cabelas
  2014/11/18  PKS     Added ValidateLPNPutaway
  2014/10 27  AK      Added BatchNoLength.
  2014/10/07  PKS     Added ActivityLog
  2014/09/10  AK      Excluded the ControlValue Ready To Pick (R) from Cancel Batch.
  2014/07/23  TK      Added Pallet_T and changed Pallet_PC to Pallet_C.
  2014/07/21  PK      Added ValidateInactiveSKU.
  2014/07/18  VM      Commented Delete statements as it is accidentally applying by developers
  2014/07/05  AK      Added ReserveLocSubType control in locations
  2014/06/18  PV      Added controlcode DeleteOD_OrderStatusInvalid
  2014/06/13  TD      Added PB_Release.
  2014/06/04  TD      Added AllocateInventory under PB_Release.
  2014/05/19  TD      Added UoMEnabled for cyclecount.
  2014/04/30  TD      Added EnablePickToLPN.
  2014/04/29  PK      Added Router, Sorter.
  2014/04/29  TD      Added ValidateSKUPackage.
  2014/04/23  TD      Added CycleCount_KP, PLThreshold, FLThreshold.
  2014/04/25  PK      Added ExportOrderHeaders, ExportOrderDetails.
  2014/04/25  DK      Added 'SendConsolidatedExports' in Receiver Control Catergory.
  2014/04/23  TD      Added CycleCount_KP.
  2014/04/21  TD      Added MaxCases control code.
  2014/04/18  TD      Added GenerateTempLabel.
  2014/04/11  TD      Added Exports (IntegrationType)
  2014/04/09  PV      Added CCTaskPriority, CreateCC for ShortPick
  2014/04/10  TD      Added PickBatch sorter dafault values. (PickBatch_)
  2014/04/05  NY      Added ExportROHOnClose,ExportRODOnClose
  2014/03/28  PK      Added LPN_Adjust.
  2014/03/18  PKS     Added AllowMultiSKUPallet in Receiving_A
  2014/03/18  TD      Added ValidateUnitsPackage.
  2014/03/17  PKS     Added ConfirmQtyRequired, ConfirmSKURequired in Receiving_A and
                      IsPackingSlipRequired changed to IsReceiverNumberRequired
  2014/03/13  TD      Added Inv_Adjustments,PicklaneLocSubtype.
  2014/03/05  PK      Added PicksLeftForDisplay in BatchPicking.
  2014/03/03  DK      Added Receiver Controls
  2014/01/28  NY      Added Archive controls.
  2014/01/07  AY      Added SyncLPNWithLocationWarehouse
  2013/12/10  NY      Added Missing Controls.
  2013/11/29  NY      Added Controls for category Loading and UnLoading.
  2013/11/08  TD      Added CancelPTLine.
  2013/10/28  NY      Added OrderShip/Complete.
  2013/10/24  PK      Added Picking - ValidPalletStatuses.
  2013/10/19  PK      Added OrderClose - Transfer.
  2103/10/17  TD      Added PalletTareWeight
  2013/09/24  TD      Added EnforceBatchingLevel.
  2013/09/19  TD      Added GenerateTempLabel.
  2013/09/13  TD      Added GenerateBatches.
  2013/08/31  NY      Added Layouts-Custom Layout RecordId.
  2013/08/21  AY      Added Inventory-AllowMultiSKULPNs
  2013/08/04  AY      Added SKU-MultipleUPCs and revised descriptions
  2013/07/31  NY      Added Import_UPC controls.
  2013/06/17  TD      Added Replenish type controls.
  2103/06/04  TD      Added  new Pallet Type Pallet_U.
  2103/05/21  TD      Added TLP Specific controls(Cycle count).
  2013/05/16  TD      Added new controls for GenerateLPNs.
  2013/05/03  AY      ValidBatchStatusToPick: Added new variable to control which batches can be picked
  2013/04/19  LN      Added new controls for Pallets to Generate Pallets.
  2013/03/26  TD      Added new control for SKU which is about SKU-Inquiry.
  2013/03/20  TD      Added imports related controls.
  2013/03/06  NY/VM   Added 'BatchPicking' - SetBatchStatusToPickedOnNoMoreInv.
  2013/02/08  SP      Added ModifyBatch.
  2013/02/07  YA      Added AutoGenerateBatches
  2013/01/28  PKS     PickBatch Format changes migrated from LOEH, Year was added (<YY>).
  2013/01/25  YA/TD   Added Palletized control code in VICSBoL control category
  2013/01/24  PKS     Year (YY) is added to Load Format
  2013/01/21  YA      Added AddSKU_MaxScanQty control for Picklane
  2013/01/05  VM      Device License's: Increased from 50 to 99
  2012/12/28  AA      Added Screen Height Ranges for GridPageSize
  2012/11/29  PK      Added AdjustAllocatedLPN.
  2012/11/12  AA      Added MaxLabelsToPrintForEachRequest for ShipLabels
  2012/11/05  PK      Added 'BatchPicking' - 'ValidBatchStatusToPause'.
  2012/10/26  YA      Added control for 'CancelBatch'
  2012/10/24  VM      Added 'Picking' - 'ValidateUnitsperCarton'
  2012/10/23  PKS     Added BoLPrefix for 'Load' control category.
  2012/10/12  AY      Updated Shipping - Valid statuses as per TD's operations.
                      Changed to allow change of SKU on Lost LPNs
                      Changed to allow closing of Staged Orders - for TD.
  2012/09/25  PK      Added ValidateOwnership.
  2012/09/20  YA      Added ControlCategory 'TransferInventory'.
  2012/08/29  YA      Added ControlCode 'RecordsPerBatch' to ControlCategory 'ExportBatch'.
  2012/08/28  PK      Added ValidLoadStatus
  2012/08/08  PK      Added Cycle Counting Controls specific to Location Storage Type.
  2012/07/27  PK      Added ScanPalletLPNs, Devices.
  2012/07/23  YA      DropLocation changed from 'C01-PANDA-IN' to 'CO1-PANDA-IN'.
  2012/07/17  NY      Added Warehouse - MoveBetweenWarehouses
  2012/07/13  PKS     Added Control Category 'ChangeSKU'.
  2012/06/29  PK      Added Picking - DropLocationTypes, and CycleCount Controls for both
                       PickLane and Reserve Type Locations.
  2012/06/28  PKS     Added UCCSeqNo category.
  2012/06/19  TD      Added LoadNumber- To create next Load Number.
                            ValidLPNStatus,ValidShipmentStatus.
  2012/06/13  NY      Added Control for Orders with Control Category OrderClose
  2012/06/04  PK      Added BuildPallet_I, BuildPallet_R control vars for
                        InvalidLPNTypes and InvalidLPNStatuses
  2012/06/01  PKS     VoidLPNs: Allow voiding of Putaway LPNs
  2012/05/22  PKS     As per Vijay advise Pallet types (Pallet_S,Pallet_P,Pallet_R) were removed.
  2012/05/10  PK      Added Controls for PickTicketNo generation
  2012/04/16  AY      Changed Row-Section lengths, Pallet Seq No length for TD
  2012/02/01  VM      Added Controls for BatchPicking.
  2011/01/02  YA      Changed SeqNoMaxLength to 4 for TaskBatch.
  2011/12/26  PK      Added TaskBatch.
  2011/12/13  YA      Added Controls for CycleCount.
  2011/12/07  YA      Added Controls for Putaway with control code 'ValidateLPNsOnPallet'.
  2011/11/25  TD      Added Controls for return Hanging/Flat carts
  2011/10/21  NB      Added AutoShipLPN - ShipOnLabel
  2011/10/05  AY      Added TransactionKey seqno variables.
  2011/10/03  NB      Added Shipping-TrailerNumber Control Option
  2011/08/17  NB      Pallet Generation - Added new control variables
  2011/08/12  AY      ExportBatch - NextSeqNo: Added new control variable
  2011/08/03  PK      Added PickBatch - BatchFormat, NextSeqNo, SeqNoMaxLength.
  2011/07/27  VM      Added Picklane-AllowMultipleSKUs
  2011/07/18  DP      Added control for Putaway.
  2011/07/17  VM      Initial revision for Loehmanns
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/*                                  Core                                      */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Database Alerts */
/*----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
/* Alert_DBA */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_DBA';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,                      DataType,  Visible)
      select 'DBProfileName',              'Database mail profile name',                      'CIMS',                            'S',       0
union select 'Recipients',                 'All recipient email ids',                         'dbacims.support@cloudimsystems.com', 'S',    0
union select 'TestRecipient',              'CIMS DBA email id',                               'dbacims.support@cloudimsystems.com', 'S',    0


exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_CIMSSupport */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_CIMSSupport';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,                      DataType,  Visible)
      select 'DBProfileName',              'Database mail profile name',                      'FFIDBEmail',                      'S',       0
union select 'Recipients',                 'All recipient email ids',                         'cims.dev@cloudimsystems.com',     'S',       0
union select 'TestRecipient',              'CIMS dev email id',                               'cims.dev@cloudimsystems.com',     'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* InventoryChanges Source Value is missing Default mail send to aashil */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alerts_InventoryChanges';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,                      DataType,  Visible)
      -- DBProfileName is required as it uses default support profile
      select 'Recipients',                 'All recipient email ids',                         'cims.dev@cloudimsystems.com',     'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_AllocationStatistics */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_AllocationStatistics';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Subject',                    'Allocation Statistics',                           'Allocation Statistics', 'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alerts_ListOfOrdersToShip */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alerts_ListOfOrdersToShip';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      -- DBProfileName & Recipeints not required as it uses default support profile and support group, if not set
      select 'Recipients',                 'All recipient email ids',                         'cims.dev@cloudimsystems.com',
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_LocationCountDiscrepency */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_LocationCountDiscrepency';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      -- DBProfileName & Recipeints not required as it uses default support profile and support group, if not set
      select 'Subject',                    'Subject of the email',                            'Mismatch of Location v Pallets v LPNs v Units',
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_LogicalLPNCountsMismatch */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_LogicalLPNCountsMismatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      -- DBProfileName & Recipeints not required as it uses default support profile and support group, if not set
      select 'Subject',                    'Subject of the email',                            'Mismatch of Logical LPN Counts',
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_LPNCountsMismatch */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_LPNCountsMismatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      -- DBProfileName & Recipeints not required as it uses default support profile and support group, if not set
      select 'Subject',                    'Subject of the email',                            'Mismatch of LPN Counts',
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_MisMatchOfODUnitsAssigned */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_MisMatchOfODUnitsAssigned';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      -- DBProfileName & Recipeints not required as it uses default support profile and support group, if not set
      select 'Subject',                    'Subject of the email',                            'Mismatch of OD UnitsAssigned v FromLPNQty v ToLPNQty',
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_OpenOrdersSummary */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_OpenOrdersSummary';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      -- DBProfileName & Recipeints not required as it uses default support profile and support group, if not set
      select 'Subject',                    'Subject of the email',                            'Open Orders Summary',
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_OrphanDLines */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_OrphanDLines';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      -- DBProfileName & Recipeints not required as it uses default support profile and support group, if not set
      select 'Subject',                    'Subject of the email',                            'Orphan D Lines',
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alert_WavesNotAllocated */

declare @Controls TControlsTable, @ControlCategory TCategory = 'Alert_WavesNotAllocated';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      -- DBProfileName & Recipeints not required as it uses default support profile and support group, if not set
      select 'Subject',                    'Subject of the email',                            'Waves not allocated',
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Archive';

insert into @Controls
            (ControlCode,                    Description,                                       ControlValue,            DataType,  Visible)
      select 'Receipts-Days',                'Archive Receipts',                                '1',                     'I',       1
union select 'Tasks-Days',                   'Archive Completed/Cancelled Tasks',               '1',                     'I',       1
union select 'ShipLabels-Days',              'Archive ShipLabels',                              '60',                    'I',       1
union select 'PrinJobs-Days',                'Archive PrintJobs',                               '1',                     'I',       1
union select 'InterfaceLog-Days',            'Archive success records of InterfaceLog',         '1',                     'I',       1
union select 'InterfaceLogError-Days',       'Archive error records of InterfaceLog',           '60',                    'I',       1
/* CarrierTrackingInfo will be archived 2 days after it is delivered to ensure we don't have  timing issues with exports */
union select 'CarrierTrackingInfo-Days',     'Archive delivered Carrier Tracking Info',         '2',                     'I',       1
union select 'APIInboundTransactions-Days',  'Archive processed API Inbound transactions',      '1',                     'I',       1
union select 'APIOutboundTransactions-Days', 'Archive processed API Outbound transactions',     '1',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Alerts APIOTsStruckInInprocess */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Alerts_APIOutboundTransactions';

insert into @Controls
            (ControlCode,                  Description,                              ControlValue,              DataType,  Visible)
      select 'Subject',                    'Subject of the email',                   '!!!IMPORTANT!!! API failures ~Timestamp~',
                                                                                                                         'S',       1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'DBA';

/* The lettered control code is for disk space alert to give out the description of the Drive on the DB server */
insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DiskSpaceYellowLimit',       'Max free disk space limit to alert dba',          '50',                    'I',       0
union select 'DiskSpaceRedLimit',          'Max free disk space limit to alert support',      '25',                    'I',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Devices';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DeviceCount',                'Licensed Device Count',                           99999,                   'I',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Controls settings for generation of unique DeviceIds for DeviceType PC */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Devices_PC';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Device SeqNo',                               '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Length Of Sequence Number',                       '10',                    'I',       0
union select 'Format',                     'Format of PC Device Ids',                         'PC<SeqNo>',             'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Controls settings for generation of unique DeviceIds for DeviceType RF */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Devices_RF';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Device SeqNo',                               '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Length Of Sequence Number',                       '10',                    'I',       0
union select 'Format',                     'Format of RF Device Ids',                         'RF<SeqNo>',             'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* RootPath */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'RootPath';

insert into @Controls
            (ControlCode,                  Description,                                 ControlValue,                                DataType,  Visible)
      select 'DB',                         'Root path for DB server',                   'P:\cIMS\Test\',                              'S',       1
union select 'UI',                         'Root path for UI server',                   'P:\cIMS\Test\',                              'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* System */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'System';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'UseInnerPacks',              'Use InnerPacks',                                  'N',                     'B',       1
union select 'IsLabelPrinterConfigRequired',
                                           'Is Label printer configuration required?',        'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/******************************************************************************/
/*                                Contacts                                    */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Mail_ProfileName */
declare @Controls TControlsTable, @ControlCategory TCategory = 'DBMail';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ProfileName',                'Mail Profile Name in the DB',                     'CIMS' ,                 'S',       1
union select 'ShipNotificationProfile',    'Ship Notification Mail Profile Name in the DB',   'ShipNotification' ,     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* DropShip_XXXXXX_Cabela - This code can vary from one to another client as per their contactrefid used for Cabelas */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'DropShip_XXXXXX_Cabela';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'SoldToId',                   'Sold To Customer',                                'XXXXXX',                'S',       0
union select 'UPSAC',                      'UPS Account Number',                              '000000',                'S',       1
union select 'FEDXAC',                     'FEDX Account Number',                             '',                      'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* DropShip_XXXXXX_TSC - This code can vary from one to another client as per their contactrefid used for Tractor Supply Co */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'DropShip_XXXXXX_TSC';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,           DataType,  Visible,  Status)
      select 'SoldToId',                   'Sold To Customer',                                'XXXXXX',               'S',       0,        ''
union select 'UPSAC',                      'UPS Account Number',                              '000000',               'S',       1,        ''
union select 'FEDXAC',                     'FEDX Account Number',                             '',                     'S',       1,        'I'

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Default */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Default';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ShipToPhoneNo',              'Default ShipTo PhoneNo',                          '18007299050',           'S',       1
union select 'BusinessUnit',               'Default BusinessUnit',                            'HPI',                   'S',       1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Address Validation Method */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'AddressValidation';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AVMethod',                   'Default Address Validation Method',               '%Carrier%',             'S',       1
union select 'RevertOrderToDownload',      'Revert Order To Download when invalid address',   'N',                     'S',       1
union select 'AddressValidationRequired',  'Is AddressValidation required?',                  'Yes',                   'S',       1
union select 'ExportOnAddressError',       'Revert Order To Download when invalid address',   'N',                     'B',       1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* UPS Address Validation */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'UPS_ShipToAddressValidation';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'RevertOrderToDownload',      'Revert Order To Download when invalid address',   'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* SSCC Barcode parameters                                                    */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'SSCCBarcode';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'CompanyId',                  'Manufacturer Code',                               '0602173',               'I',       1
union select 'NextSeqNo',                  'Next UCC SeqNo',                                  '1',                     'I',       -1
union select 'PackageType',                'Package Type',                                    '0',                     'I',       1
union select 'SeqNoMaxLength',             'SeqNo Maximum Length',                            '9',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*---------------------------------------------------------------------------*/
/* SCC14_0715209 */
/*---------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'SCC14_0715209';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next UCC SeqNo',                                  '1',                     'I',       -1
union select 'SeqNoMaxLength',             'SeqNo Maximum Length',                            '5',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* UCCSeqNo */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'UCCSeqNo';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PackageType',                'PackageType',                                     '0',                     'I',       1
union select 'ManufacturerCode',           'Manufacturer Code',                               '0',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*---------------------------------------------------------------------------*/
/* Parmeters for UCC128 labels of company 0000000 */
/*---------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'UCC128_0000000';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next UCC SeqNo',                                  '1',                     'I',       -1
union select 'SeqNoMaxLength',             'SeqNo Maximum Length',                            '9',                     'I',       1
/* when MaxSeqNo = 0, Seqeunces are used */
union select 'MaxSeqNo',                   'Max LPN SeqNo',                                   '0',                     'I',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/******************************************************************************/
/*                          Default Reason Codes                              */
/******************************************************************************/
/*----------------------------------------------------------------------------*/
/* Default Reason Codes */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'DefaultReasonCodes';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultCC',                  'CC Default Reason Code',                          '100',                   'S',       1
union select 'CCLost',                     'CC Reason Code for any Entity Lost',              '101',                   'S',       1
union select 'CCMove',                     'CC Reason Code for any Entity Move',              '102',                   'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/*--------------------------- Interface-Imports ------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Imports ResultXml: N - Never, A - All Records, E - Errors only

   For S2G, we need to send the xmlResult to acknowledge its CIMSDE for all the
    processed records in CIMS at that instance. Hence the controlvalue is set to "A"*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Imports';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'XMLResultRequired?',         'Result XML Required?',                            'A',                     'S',       0
/*----------------------------------------------------------------------------*/
/* IsDESameServer: Whether cIMSDE is in same server or not  */
/*----------------------------------------------------------------------------*/
union select 'IsDESameServer',             'Is the CIMSDE is on same server',                 'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_ASNLD - ASNLPNs. I -Insert, U-update, X- DoNothing, E- Error*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_ASNLD';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing ASNLPN Details',                     'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing ASNLPN Details',              'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing ASNLPN Details',              'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'AddReceipts',                'insert Receipt and Details',                      'N',                     'S',       1
union select 'ValidateReceipt',            'Validate receipt while importing ASNLPNs',        'N',                     'S',       1
union select 'LPNStatus',                  'Default LPN Status',                              'T',                     'S',       1
union select 'ValidateUnitsPerPackage',    'Validate Units per package while importing',      'Y',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_ASNLH - ASNLPNs. I -Insert, U-update, X- DoNothing, E- Error*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_ASNLH';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing ASNLPNs',                            'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing ASNLPNs',                     'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing ASNLPNs',                     'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'ValidateVendor',             'validate vendor while importing ASNLPNs',         'N',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_CNT  - Address Contacts. I -Insert, U-update, X- DoNothing, E- Error */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_CNT';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing Address Contacts',                   'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing Contacts',                    'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing Contacts',                    'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_CT  - Carton Types. I -Insert, U-update, X- DoNothing, E- Error */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_CT';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing Carton Types',                       'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing Carton Types',                'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing Carton Types',                'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_OD - Order Details. I -Insert, U-update, X- Nothing, E- Error  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_OD';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing Order Details',                      'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing Order Details',               'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing Order Details',               'IG', /* Ignore */       'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'DeleteOD_OrderStatusInvalid','Valid order status for deleting order details',
                                                                                              'ON',                    'S',       1
union select 'UpdateOD_OrderStatusInvalid','Invalid order status for updating order details',
                                                                                              'XDS',                   'S',       1
union select 'ODUniqueKey',                'What is the uniqueness on the OD Import',         'PTHostOrderLine',       'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_OH - Orders. I -Insert, U-update, X- Nothing, E- Error  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_OH';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing Orders',                             'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing Orders',                      'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing Orders',                      'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'Recv_LastProcessedRecordId', 'Recv Last Processed RecordId',                    '1',                     'I',       -1
union select 'InvCh_LastProcessedRecordId','InvCh Last Processed RecordId',                   '1',                     'I',       -1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_RD - ReceiptDetails. I -Insert, U-update, X- DoNothing, E- Error  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_RD';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing ReceiptDetails',                     'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing ReceiptDetails',              'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing ReceiptDetails',              'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_RecordProcessType */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_RecordProcessType';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Sequential',                 'Sequential processing of records',                '',                      'S',       1
/* Example to use:
      select 'Sequential',                 'Sequential processing of records',                'SKU, SMP, SPP, RH, ROH',
                                                                                                                       'S',       1
*/

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_RH  - ReceiptHeaders. I -Insert, U-update, X- DoNothing, E- Error  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_RH';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing ReceiptHeaders',                     'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing ReceiptHeaders',              'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing ReceiptHeaders',              'E',                     'S',       1
union select 'ModifyNonExistingRecord',    'Close/Reopen Non Existing ReceiptHeaders',        'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D,DR,C,R',          'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_SKU - SKUs. Control Values may be - I -Insert, U-update, X- Nothing, E- Error */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_SKU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing SKUs',                               'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing SKUs',                        'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing SKUs',                        'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_SMP  - SKUPrePacks. I -Insert, U-update, X- DoNothing, E- Error*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_SMP';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing SKUPrePacks',                        'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing SKUPrePacks',                 'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing SKUPrePacks',                 'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_UPC  - UPCs. I -Insert, U-update, X- DoNothing, E- Error*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_UPC';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing UPCs',                               'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing UPCs',                        'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing UPCs',                        'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'N',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Import_VEN  - Vendors. I -Insert, U-update, X- DoNothing, E- Error  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_VEN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing Vendors',                            'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing Vendors',                     'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing Vendors',                     'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Import_NOTE - Notes. I -Insert, U-update, X- DoNothing, E- Error*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_NOTE';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddExistingRecord',          'Add Existing NOTES',                              'U',                     'S',       1
union select 'UpdateNonExistingRecord',    'Update Non Existing NOTES',                       'I',                     'S',       1
union select 'DeleteNonExistingRecord',    'Delete Non Existing NOTES',                       'E',                     'S',       1
union select 'ValidActionCodes',           'Valid Action codes',                              'I,U,D',                 'S',       1
union select 'Debug',                      'Log all import data for Debugging',               'A',                     'S',       1
union select 'RecordsPerRun',              'Number of records per run to import',             '500',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Import_File - Default Path */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_File';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FilePath_UI',                'File Path in UI Server',                          'P:\SCT\HA\cIMS\Prod\Data\ImportFiles\Xfer',
                                                                                                                       'S',       1
union select 'RootPath_DB',                'Root Path for DB',                                'P:\SCT\HA\cIMS\Dev\',   'S',       1
union select 'DefaultPath_DB',             'Default File Path in DB Server',                  'Data\ImportFiles\Xfer\','S',       1
union select 'ErrorLog_DB',                'Error Log',                                       'Data\ImportFiles\Logs\','S',       1
union select 'TemplatePath',               'Template Path',                                   'P:\SCT\HA\cIMS\Prod\Data\ImportFiles\Templates',
                                                                                                                       'S',       1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Import_File - FileType is SPL */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_File_SPL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FilePath_UI',                'File Path in UI Server',                          'P:\SCT\HA\cIMS\Prod\Data\ImportFiles\Xfer',
                                                                                                                       'S',       1
union select 'TemplateFileName',           'Template File Name',                              'SKUPriceList.csv',      'S',       1
union select 'DataSetName',                'Data set that is used being imported',            'SKUPriceList',          'S',       0
union select 'TableName',                  'Actual Table data is being imported into',        'SKUPriceList',          'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Import_File - FileType is Location */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_File_LOC';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FilePath_UI',                'File Path in UI Server',                          'P:\SCT\HA\cIMS\Prod\Data\ImportFiles\Xfer',
                                                                                                                       'S',       1
union select 'TemplateFileName',           'Template File Name',                              'Locations.csv',         'S',       1
union select 'KeyFieldName',               'Entity Field Name',                               'Location',              'S',       0
union select 'DataSetName',                'Data set that is used being imported',            'Locations',             'S',       0
union select 'TableName',                  'Actual Table data is being imported into',        'Locations',             'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Import_File - FileType is Load Routing Info */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_File_LRI';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FilePath_UI',                'File Path in UI Server',                          'P:\SCT\HA\cIMS\Prod\Data\ImportFiles\Xfer',
                                                                                                                       'S',       1
union select 'TemplateFileName',           'Template File Name',                              'LoadRoutingInfo.csv',   'S',       1
union select 'KeyFieldName',               'Entity Field Name',                               'CustPO',                'S',       0
union select 'DataSetName',                'Data set that is used being imported',            'LRI',                   'S',       0
union select 'TableName',                  'Actual Table data is being imported into',        'LoadRoutingInfo',       'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
/* Import_File - FileType is Create Inventory */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_File_INV';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FilePath_UI',                'File Path in UI Server',                          'P:\SCT\HA\cIMS\Prod\Data\ImportFiles\Xfer',
                                                                                                                       'S',       1
union select 'TemplateFileName',           'Template File Name',                              'Inventory.csv',         'S',       1
union select 'KeyFieldName',               'Entity Field Name',                               'SKU',                   'S',       0
union select 'DataSetName',                'Data set that is used being imported',            'Inventory',             'S',       0
union select 'TableName',                  'Actual Table data is being imported into',        'INV',                   'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Import_File - FileType is SKU */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Import_File_SKU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FilePath_UI',                'File Path in UI Server',                          'TempData\ImportFiles\Xfer\',
                                                                                                                       'S',       1
union select 'TemplateFileName',           'Template File Name',                              'SKUs.csv',              'S',       1
union select 'KeyFieldName',               'Entity Field Name',                               'SKU',                   'S',       0
union select 'DataSetName',                'Data set that is used being imported',            'SKUs',                  'S',       0
union select 'TableName',                  'Actual Table data is being imported into',        'SKUs',                  'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*--------------------------- Interface-Exports ------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Exports */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Exports';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'IntegrationType',            'Export Integration',                              'DB',                    'S',       1
union select 'WHXferAsInvCh',              'Export WH Xfer as InvCh transaction',             'Y',                     'B',       1
union select 'TransferToDBMethod',         'Transfer Data to CIMSDE DB method (SQLData/XML',  'SQLDATA',               'S',       1
union select 'Recv_LastProcessedRecordId', 'Recv Last Processed RecordId',                    '1',                     'I',       -1
union select 'InvCh_LastProcessedRecordId','InvCh Last Processed RecordId',                   '1',                     'I',       -1
union select 'WHXfer_LastProcessedRecordId','WHXFer Last Processed RecordId',                 '1',                     'I',       -1
union select 'GenerateBatchesFromDE',      'Generate Batches From DE',                        'Y',                     'B',       1
union select 'EmailId',                    'Support Group EmailId',                           'cims.dev@cloudimsystems.com',
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Exports Transfer Order */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Exports_ShipTransferOrder';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'WHXferAsInvCh',              'Export WH Xfer as InvCh transaction',             'Y',                     'B',       1
union select 'InTransitWH',                'InTransit Warehouse Code',                        'INT',                   'S',       1
union select 'InTransitLocation',          'InTransit Location Code for 04 WH',               'INTRANSIT',             'S',       1
union select 'LPNStatusOnShip',            'InTransit LPN Status',                            'T',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Exports */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Export Batch SeqNo',                         '1',                     'I',       -1
union select 'RecordsPerBatch',            'Max no of records per batch',                     '1000',                  'I',       1
union select 'AddMsgHeaderNode',           'Add Message Header Node',                         'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Controls for Export Rouuter batch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportRouterBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Export Batch SeqNo',                         '1',                     'I',       -1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Export Data */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportData';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ExportByLoad',               'Is Export by Load?',                              'N',                     'B',       1
union select 'ExportByReceiver',           'Is Export by Receiver?',                          'N',                     'B',       1
union select 'ExportChargeType',           'Type of charge to inclue in exports',             'LISTNETCHARGES',        'S',       1
union select 'SeparateShipTrans',          'Send separate ship exports?',                     'N',                     'B',       1
union select 'CanSplitLoad',               'Split transactions in Load?',                     'Y',                     'B',       1
union select 'CanSplitOrder',              'Split transactions in Order?',                    'N',                     'B',       1


exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Exports Receipt Details Close*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportRODOnClose';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PO',                         'Export Receipt Details when Receipt is Closed',   'N',                     'S',       1
union select 'T',                          'Export Receipt Details when Receipt is Closed',   'LPN+RODZero' /* Other possible cases are -- 'ROD', ROD-Zero*/,
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Exports Receipt Headers Close*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportROHOnClose';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PO',                         'Export Receipt Header when Receipt is Closed',    'Y',                     'S',       1
union select 'T',                          'Export Receipt Header when Receipt is Closed',    'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* ExportOnHandInv */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportOnHandInv';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Export Detail SeqNo',                        '1',                     'I',       -1
union select 'RecordsPerBatch',            'Max no of records per Export',                    '1000',                  'I',       1
union select 'AddMsgHeaderNode',           'Add Message Header Node',                         'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* UpdateInvSnapShot */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'UpdateInvSnapShot';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LastProcessedRecordId',      'Last Processed record',                           '1',                     'I',       -1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Exports Order Details
   S- Short Ship, Y - Shipped, C - Remaining */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportOrderDetails';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Ship',                       'Export Order Details when Order is shipped',       'Y',                     'S',       1
union select 'PTCancel',                   'Export Order Details when Order is canceled',      'C',                     'S',       1
union select 'PTStatus',                   'Export Order Details for Pick Ticket Status?',     'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Exports Order Headers */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportOrderHeaders';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Ship',                       'Export Order Header when Order is shipped',       'Y',                     'S',       1
union select 'PTCancel',                   'Export Order Header when Order is canceled',      'Y',                     'S',       1
union select 'PTStatus',                   'Export Order Header for Pick Ticket Status?',     'Y',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Exports Receipts */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Export.Return';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ReceiptDetails',             'Export Receipt Headers',                          'Y' ,                    'S',       1
union select 'ReceiptHeaders',             'Export Receipt Details',                          'Y',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/*-------------------------------- Putaway -----------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Replenish Putaway */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ReplenishPutaway';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatus',             'Valid LPN Status for putaway',                    'K',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Putaway */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Putaway';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ConfirmQtyRequired',         'Confirm Qty of LPN on Putaway',                   'Y',                     'B',       1
union select 'ConfirmQtyRequiredForUnitsPA',
                                           'Confirm Qty of Units on Putaway',                 'Y',                     'B',       1
union select 'ConfirmPAToDiffLoc',         'Confirm PA To Diff Loc required',                 'Y'/* Yes */,            'B',       1
union select 'ValidateLPNsOnPallet',       'Validate LPNs On Pallet',                         'N',                     'B',       1
union select 'UnallocatePartialLPN',       'Unallocate Partial Putaway LPN',                  'N'/* No */,             'B',       1
union select 'DefaultQty',                 'Default Qty to display',                          'LPNQty'/* LPN Qty */,   'S',       1
union select 'ScanOption',                 'Scan Option',                                     'L' /* LPN */,           'S',       1
union select 'RestrictSKUToPAZone',        'Restrict SKUs to be Putaway into their Zones only',
                                                                                              'N',                     'S',       1
union select 'MaxLPNWeightForRacks',       'Max LPN Weight For Rack',                         '2000',                  'I',       1
union select 'MaxUnitWeightForRacks',      'Max Unit Weight For Racks',                       '30',                    'I',       1
union select 'SKUPAClassRequired',         'Is SKU PA Class Required for Putway?',            'N', /* No */            'B',       1
union select 'EnableConfirmQtyCheckScreen','Enable Quanity Check Screen',                     'Y'/* Yes */,            'B',       1
union select 'ValidLPNStatus',             'Valid LPN Status for putaway',                    'TNRP',                  'S',       1
                                                                                              /* InTransit/New/Received/Putaway */
union select 'PutawayType',                'Putaway Type - DIRECTED, SUGGESTED',              'SUGGESTED',             'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Receiving Putaway LPNs */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PutawayLPNs_ReceivingPA';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PutawaySequence',            'Putaway Sequence',                                'LIFO',                  'S',       1
union select 'ConfirmScanLPN',             'Scan LPN to Confirm',                             'N',                     'B',       1
union select 'ConfirmQtyRequired',         'Confirm Qty of LPN on Putaway',                   'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Replenish Putaway LPNs */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PutawayLPNs_ReplenishPA';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PutawaySequence',            'Putaway Sequence',                                'LIFO',                  'S',       1
union select 'ConfirmScanLPN',             'Scan LPN to Confirm',                             'N',                     'B',       1
union select 'ConfirmQtyRequired',         'Confirm Qty of LPN on Putaway',                   'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Putaway LPNs on Pallet */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Putaway_LPNsOnPallet';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidPalletStatuses',        'Valid Pallet Statuses for Putaway',               'BRP',                   'S',       1
union select 'ValidPalletTypes',           'Valid Pallet Types for Putaway',                  'RICU',                  'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/*------------------------------- Receiving ----------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Receipts */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receipts';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LPNLocation',                'Default LPN Location',                            'RECVDOCK001',           'S',       1
union select 'LPNLocation_RIP',            'Default LPN Receiving Location',                  'RIP',                   'S',       1
union select 'OverReceiptPercent',         'Over Receipt Percentage',                         '5',                     'I',       1
union select 'ExportROCloseROOpen',        'Export ROClose and ROOpen transaction to host system',
                                                                                              'Y',                     'B',       1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* RFC Receive To Location  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ReceiveToLocation';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Mode',                       'Mode of Receive To Location',                     'SuggestedMode',         'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* RFC Receive To LPN  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ReceiveToLPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AcceptExternalLPN',          'Allow Receiving External LPN',                    'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Receive To LPN default validation controls */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ReceiveToLPN_Default';

insert into @Controls
            (ControlCode,                  Description,                                 ControlValue,            DataType,  Visible)
      select 'Prefix',                     'Prefix of scanned LPN',                     '',                      'S',       1
union select 'Length',                     'Length of scanned LPN',                     '10',                    'I',       1
union select 'Range',                      'Range of scanned LPN',                      '',                      'S',       1
union select 'Pattern',                    'Pattern of scanned LPN',                    '[a-z]%',                'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Receipts - Returns */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receipts_Return';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Receipts SeqNo',                             '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Length Of Sequence Number',                       '8',                     'I',       1
union select 'Format',                     'Format of Return RO Number',                      'RO<SeqNo>',             'S',       1
union select 'ValidOrderTypes',            'Valid Order types to accept returns',             'W',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Receipts - RMA Returns */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receipts_RMA';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Receipts SeqNo',                             '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Length Of Sequence Number',                       '8',                     'I',       1
union select 'Format',                     'Format of Return RO Number',                      'RMA<SeqNo>',            'S',       1
union select 'DefaultScrapCode',           'Default Scrap Code',                              '321',                   'S',       1
union select 'SendInvChTransForRecv',      'Send InvCh trans rather than Recv',               'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Receiver */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receiver';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ReceiverFormat',             'Receiver Format',                                 'R<YY><MM><DD><SeqNo>',  'S',       1
union select 'NextSeqNo',                  'Next Receiver SeqNo',                             '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Maximum Length Of Sequence Number',               '2',                     'I',       1
union select 'SendConsolidatedExports',    'Send Consolidated Exports based on ReceiptType',  'PO,A,M,T',              'S',       1
union select 'PutawayInventoryOnClose',    'Putaway LPNs on close of Receiver',               'N',                     'B',       1
union select 'PutawayBeforeClose',         'Putaway before closing receiver',                 'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Receiving_A - ASN's */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receiving_A';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'IsLocationRequired',         'Is it required to enter Location',                'Y',                     'B',       1
union select 'IsPalletizationRequired',    'Is it required to Palletize the LPN',             'Y',                     'B',       1
union select 'IsReceiverRequired',         'Is it required to enter Receiver Number',         'AUTO',                  'S',       1
union select 'AllowMultiSKULPN',           'Allow Multiple SKUs in an LPN',                   'N',                     'S',       1
union select 'AllowMultiSKUPallet',        'Allow Multiple SKUs in a Pallet',                 'N',                     'S',       1
union select 'IsCustPORequired',           'Is it required to enter CustPO',                  'O',                     'S',       1
union select 'ReceiveToWarehouse',         'Receive to RH.WH or LOC.WH?',                     'LOC',                   'S',       1
union select 'ReceiveToDiffWarehouse',     'Allow receipt to a different Warehouse',          'N',                     'B',       1
union select 'ConfirmQtyRequired',         'Confirm Qty of LPN on Receiving',                 'Y',                     'B',       1
union select 'ConfirmSKURequired',         'Confirm SKU on LPN on Receiving',                 'Y',                     'B',       1
union select 'OverReceiptPercent',         'Over-receipt percentage',                         '5',                     'I',       1
union select 'AcceptExternalLPN',          'Accept receiving to an externally generated LPN', 'N',                     'S',       1
union select 'CreateLPN',                  'Create An LPN',                                   'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Receiving_M - Manufacturing */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receiving_M';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'IsLocationRequired',         'Is it required to enter Location',                'Y',                     'B',       1
union select 'IsPalletizationRequired',    'Is it required to Palletize the LPN',             'Y',                     'B',       1
union select 'IsReceiverRequired',         'Is it required to enter Receiver Number',         'AUTO',                  'S',       1
union select 'IsPackingSlipRequired',      'Is it required to enter Packing Slip',            'Y',                     'S',       1
union select 'AllowMultiSKULPN',           'Allow Multiple SKUs in an LPN',                   'N',                     'S',       1
union select 'IsCustPORequired',           'Is it required to enter CustPO',                  'O',                     'S',       1
union select 'ReceiveToWarehouse',         'Receive to RH.WH or LOC.WH?',                     'LOC',                   'S',       1
union select 'ReceiveToDiffWarehouse',     'Allow receipt to a different Warehouse',          'N',                     'B',       1
union select 'OverReceiptPercent',         'Over-receipt percentage',                         '5',                     'I',       1
union select 'AcceptExternalLPN',          'Accept receiving to an externally generated LPN', 'N',                     'S',       1
union select 'CreateLPN',                  'Create An LPN',                                   'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Receiving_PO - Purchase Order */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receiving_PO';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                'STD',                   'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'IsLocationRequired',         'Is it required to enter Location',                'N',                     'B',       1
union select 'IsPalletizationRequired',    'Is it required to Palletize the LPN',             'Y',                     'B',       1
union select 'IsReceiverRequired',         'Is it required to enter Receiver Number',         'AUTO',                  'S',       1
union select 'IsPackingSlipRequired',      'Is it required to enter Packing Slip',            'N',                     'S',       1
union select 'AllowMultiSKULPN',           'Allow Multiple SKUs in an LPN',                   'N',                     'S',       1
union select 'AcceptExternalLPN',          'Allow Receiving External LPN',                    'N',                     'B',       1
union select 'IsCustPORequired',           'Is it required to enter CustPO',                  'O',                     'S',       1
union select 'ReceiveToWarehouse',         'Receive to RH.WH or LOC.WH?',                     'LOC',                   'S',       1
union select 'ReceiveToDiffWarehouse',     'Allow receipt to a different Warehouse',          'N',                     'B',       1
union select 'OverReceiptPercent',         'Over-receipt percentage',                         '5',                     'I',       1
union select 'CreateLPN',                  'Create An LPN',                                   'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Receiving_R - Returns */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receiving_R';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'IsLocationRequired',         'Is it required to enter Location',                'Y',                     'B',       1
union select 'IsPalletizationRequired',    'Is it required to Palletize the LPN',             'Y',                     'B',       1
union select 'IsReceiverRequired',         'Is it required to enter Receiver Number',         'AUTO',                  'S',       1
union select 'IsPackingSlipRequired',      'Is it required to enter Packing Slip',            'Y',                     'S',       1
union select 'AllowMultiSKULPN',           'Allow Multiple SKUs in an LPN',                   'N',                     'S',       1
union select 'IsCustPORequired',           'Is it required to enter CustPO',                  'O',                     'S',       1
union select 'ReceiveToWarehouse',         'Receive to RH.WH or LOC.WH?',                     'LOC',                   'S',       1
union select 'ReceiveToDiffWarehouse',     'Allow receipt to a different Warehouse',          'N',                     'B',       1
union select 'OverReceiptPercent',         'Over-receipt percentage',                         '5',                     'I',       1
union select 'AcceptExternalLPN',          'Accept receiving to an externally generated LPN', 'N',                     'S',       1
union select 'CreateLPN',                  'Create An LPN',                                   'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Receiving - Transfer */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Receiving_T';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'IsLocationRequired',         'Is it required to enter Location',                'Y',                     'B',       1
union select 'IsPalletizationRequired',    'Is it required to Palletize the LPN',             'Y',                     'B',       1
union select 'IsReceiverRequired',         'Is it required to enter Receiver Number',         'AUTO',                  'S',       1
union select 'IsPackingSlipRequired',      'Is it required to enter Packing Slip',            'Y',                     'S',       1
union select 'AllowMultiSKULPN',           'Allow Multiple SKUs in an LPN',                   'N',                     'S',       1
union select 'IsCustPORequired',           'Is it required to enter CustPO',                  'O',                     'S',       1
union select 'ReceiveToWarehouse',         'Receive to RH.WH or LOC.WH?',                     'RH',                    'S',       1
union select 'ReceiveToDiffWarehouse',     'Allow receipt to a different Warehouse',          'N',                     'B',       1
union select 'OverReceiptPercent',         'Over-receipt percentage',                         '5',                     'I',       1
union select 'AcceptExternalLPN',          'Accept receiving to an externally generated LPN', 'N',                     'S',       1
union select 'CreateLPN',                  'Create An LPN',                                   'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Inquiry: RF Location Inquiry  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'RFInquiry_Location';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DetailLevel',                'Detail Level',                                    'SummaryBySKU',          'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Inquiry: RFInquiry_Location_R -Reserve */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'RFInquiry_Location_R';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DetailLevel',                'Detail Level',                                    'SKU-Pallet',            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Inquiry: RFInquiry_Location_K -Picklane */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'RFInquiry_Location_K';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DetailLevel',                'Detail Level',                                    'SKUDetails',            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/*------------------------------- Inventory ----------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Inventory: RF Adjust Location  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'AdjustLocation';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DetailLevel',                'Adjust Location DataTable Display Level',         'SKUOnhand',             'S',       1
union select 'RFNumLinesToDisplay',        'Num Records to show in the UI',                   '10',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Inventory: RF Adjust LPN  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'AdjustLPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DetailLevel',                'Adjust LPN DataTable Display Level',              'SKUOnhand',             'S',       1
union select 'RFNumLinesToDisplay',        'Num Records to show in the UI',                   '10',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* AutoShipLPN */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'AutoShipLPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ShipOnLabel',                'Mark LPN as Shipped when Labeled',                'N',                     'B',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Carton MaxWeight and Volume */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Carton';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MaxWeight',                  'Carton Max Weight',                               '24',                    'I',       1
union select 'MaxVolume',                  'Carton Max Volume',                               '24',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Change SKU */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ChangeSKU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Valid Statuses to Change SKU',                    'PRTNO' /* Putaway, Received, Intransit, New, Lost */,
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LPN Controls =>   Create InventoryLPN */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CreateInvLPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'SKUPrePackQtyLimitation',    'SKUPrePack Qty Limitation',                       'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LPN Controls =>   Build InventoryLPN */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BuildInvLPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InventoryClassesUsed',       'List of Inventory Classes used during Build Inv', 'InvClass1',             'S',       1
union select 'AcceptExternalLPN',          'Allow Receiving External LPN',                    'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/update */;

Go
/*----------------------------------------------------------------------------*/
/* Genearate LPNs(Positions)  I  - C-Carton, H-Hanging, I-Inventory,R-Receiving */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'GenerateLPNs';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'GenerateLPNsForPallet',      'Create LPNs for Pallet',                          'CHIR',                  'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Inventory */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Inventory';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MoveBetweenWarehouses',      'Allow Inventory move between Warehouses',         'N',                     'B',       1
union select 'TransferToDifferentWHPickLane',
                                           'Allow Transfer Inventory to Picklane in different Warehouse',
                                                                                              'N',                     'B',       1
union select 'TransferToDifferentWHLPN',   'Allow Transfer Inventory to LPN in different Warehouse',
                                                                                              'N',                     'B',       1
union select 'AllowNewInvBeforeReceiverClose',
                                           'Allow new inventory before its Receiver close',   'N',                     'B',       1
union select 'AdjustAllocatedLPN',         'Allow to Adjust Allocated LPN',                   'N',                     'B',       1
union select 'AllowMultiSKULPNs',          'Allow multiple SKU LPNs in Inventory?',           'N',                     'B',       1
union select 'SyncLPNWithLocationWarehouse',
                                           'Update LPN''s Warehouse with that of Location when LPN is moved into a Location?',
                                                                                              'Y',                     'B',       1
union select 'GenerateExportsOnPPExplode', 'Generate Exports on Prepack Explode',             'Y',                     'B',       1
union select 'TransferToInactiveLoc',      'Allow transfer for Inactive Location',            'N'/* No */,             'B',       1
union select 'TransferToUnassignedLoc',    'Allow transfer for Unassigned Location',          'Y'/* Yes */,            'B',       1
union select 'ValidLPNStatusToGenerateExports',
                                           'Valid From LPN Statuses to generate Exports',     'NRP' /* New, Received, Putaway */,
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Inventory Snapshot */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'InventorySnapshot';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Inventory SnapshotId',                       '1',                     'I',       -1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Inv_Adjustments */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Inv_Adjustments';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultUoM',                 'Default UoM',                                     'EA',                    'S',       1
union select 'EnableUoM',                  'Enable UOM',                                      'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Inv_AddSKUToLPN */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Inv_AddSKUToLPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultUoM',                 'Default UoM',                                     'EA',                    'S',       1
union select 'EnableUoM',                  'Enable UOM',                                      'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Inv_TransferInventory */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Inv_TransferInventory';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultUoM',                 'Default UoM',                                     'EA',                    'S',       1
union select 'EnableUoM',                  'Enable UOM',                                      'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Inventory: RF Manage Picklane  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ManagePicklane';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DetailLevel',                'Manage Picklane DataTable Display Level',         'LPNList',               'S',       1
union select 'RFNumLinesToDisplay',        'Num Records to show in the UI',                   '10',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Inventory: RF Transfer Location  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'TransferLocation';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DetailLevel',                'Transfer Location DataTable Display Level',       'SKUOnhand',             'S',       1
union select 'RFNumLinesToDisplay',        'Num Records to show in the UI',                   '10',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Inventory: RF Transfer LPN  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'TransferLPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DetailLevel',                'Transfer LPN DataTable Display Level',            'SKUOnhand',             'S',       1
union select 'RFNumLinesToDisplay',        'Num Records to show in the UI',                   '10',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Load */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Load';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BoLPrefix',                  'Default prefix for BoL Number',                   '0715209005254',         'S',       1
union select 'Generate_AddToExistingLoads','When generating Loads, add PickTickets to existing Loads',
                                                                                              'N',                     'S',       1
union select 'AssignDockForMultipleLoads', 'Assign Dock for multiple Loads',                  'Y',                     'S',       1
union select 'RequestRoutingValidStatus',  'Valid statuses to Request for routing',           'I,R',                   'S',       1
union select 'SmallPackageLoadTypes',      'Small Package Load Types',                        'FDEG,FDEN,UPSE,UPSN,USPS,USPSF,USPSP,SMPKG',
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LoadNumber */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LoadNumber';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LoadFormat',                 'Load Number Format',                              'LD<YY><MM><DD><SeqNo>', 'S',       1
union select 'NextSeqNo',                  'Next Load SeqNo',                                 '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Maximum Length Of Load Sequence No',              '3',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location Controls  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LocationFormat',             'Default Location Format',                         '<LocationType>-<Row>-<Level>-<Section>',
                                                                                                                       'S',       1
union select 'RowMaxLength',               'Location Row Max Length',                         '2',                     'I',       1
union select 'SectionMaxLength',           'Location Section Max Length',                     '3',                     'I',       1
union select 'LevelMaxLength',             'Location Level Max Length',                       '1',                     'I',       1
union select 'BayMaxLength',               'Location Bay Max Length',                         '2',                     'I',       1
union select 'AllowMultipleSKUs',          'Default AllowMultipleSKUs',                       'Y',                     'S',       1
union select 'ScanPreference',             'Scan Preference',                                 'L',                     'S',       1
union select 'PicklaneLocSubType',         'Location subtype for Picklane Locations',         'PU',                    'S',       1
union select 'ReserveLocSubType',          'Location subtype for Reserve Locations',          'LA',                    'S',       1
union select 'PickPath',                   'Default PickPath Format',                         '<LocationType><Row>-<Bay>-<Level>-<Section>',
                                                                                                                       'S',       1
union select 'PutawayPath',                'Default PutawyPath Format',                       '<LocationType><Row>-<Bay>-<Level>-<Section>',
                                                                                                                       'S',       1
union select 'IgnoreLocationsToSetStatus', 'Transient Locations to set status',               'C'/* Conveyor, Staging, Dock */,
                                                                                                                       'S',       1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_B */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_B';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AllowMultipleSKUs',          'Allow Multiple SKUs in Bulk',                     'N',                     'S',       1
union select 'ValidStorageType',           'Valid Storage Type for Bulk Locations',           'L,A,LA',                'S',       1
union select 'DefaultSubType',             'Valid Sub Type for Bulk Locations',               'D',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_C */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_C';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStorageType',           'Valid Storage Type for Conveyor Locations',       'L',                      'S',       1
union select 'DefaultSubType',             'Valid Sub Type for Conveyor Locations',           'D',                      'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_D */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_D';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStorageType',           'Valid Storage Type for Dock Locations',           'LA',                    'S',       1
union select 'DefaultSubType',             'Valid Sub Type for Dock Locations',               'D',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_K */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_K';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AllowMultipleSKUs',          'Allow Multiple SKUs in Picklanes',                'N',                     'S',       1
union select 'ValidStorageType',           'Valid Storage Type for PickLane Locations',       'P,U',                   'S',       1
union select 'DefaultSubType',             'Valid Sub Type for PickLane Locations',           'S',                     'S',       1
union select 'AddSKU_MaxScanQty',          'Add SKU to Location - Maximum Scan Quantity in RF device',
                                                                                              '99999',                 'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_R */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_R';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AllowMultipleSKUs',          'Allow Multiple SKUs in Reserve',                  'Y',                     'S',       1
union select 'ValidStorageType',           'Valid Storage Type for Reserve Locations',        'L,A,LA',                'S',       1
union select 'DefaultSubType',             'Valid Sub Type for Reserve Locations',            'D',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_S */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_S';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStorageType',           'Valid Storage Type for Staging Locations',        'LA',                    'S',       1
union select 'DefaultSubType',             'Valid Sub Type for Staging Locations',            'D',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_UOM_B */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_UOM_B';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LocationDefaultUOM',         'Default UOM for Bulk Locations',                  'CS',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_UOM_K */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_UOM_K';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LocationDefaultUOM',         'Default UOM for PickLane Locations',              'EA',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Location_UOM_R */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Location_UOM_R';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LocationDefaultUOM',         'Default UOM for Reserve Locations',               'CS',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LPN Controls  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LPNFormat',                  'LPN Format',                                      '<LPNType><SeqNo>',      'S',       1
union select 'LogicalLPNFormat',           'Logical LPN Format',                              'Z<SeqNo>',              'S',       1
union select 'NextSeqNo',                  'Next LPN SeqNo',                                  '1',                     'I',       -1
/* when MaxSeqNo = 0, Seqeunces are used */
union select 'MaxSeqNo',                   'Max LPN SeqNo',                                   '0',                     'I',       0
union select 'SeqNoMaxLength',             'Maximum Length Of Sequence Number',               '9',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LPN Controls =>   AdjustLPN */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPN_Adjust';

insert into @Controls
            (ControlCode,                   Description,                                       ControlValue,             DataType,  Visible)
      select 'LPNInvalidStatus',            'LPN Invalid Statuses',                            'SOCVT',                  'S',       1
union select 'ValidUnavailableLPNStatuses', 'Valid unavailable LPN Statuses to adjust',        'RN', /* Received,New */  'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LPN Controls =>   Create InventoryLPNs */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPN_INV';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LPNFormat',                  'LPN Format',                                      'I<SeqNo>',              'S',       1
union select 'LogicalLPNFormat',           'Logical LPN Format',                              'Z<SeqNo>',              'S',       1
union select 'NextSeqNo',                  'Next LPN SeqNo',                                  '1',                     'I',       -1
/* when MaxSeqNo = 0, Seqeunces are used */
union select 'MaxSeqNo',                   'Max LPN SeqNo',                                   '0',                     'I',       0
union select 'SeqNoMaxLength',             'Maximum Length Of Sequence Number',               '9',                     'I',       1
union select 'AllowNonStandardPackConfig', 'Allow non-standard case configuration',           'N' /* No */,            'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LPN_Ship Controls  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPN_Ship';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LPNFormat',                  'LPN Format',                                      '<LPNType><SeqNo>',      'S',       1
union select 'LogicalLPNFormat',           'Logical LPN Format',                              '<LPNType><SeqNo>',      'S',       1
union select 'NextSeqNo',                  'Next LPN SeqNo',                                  '1',                     'I',       -1
/* when MaxSeqNo = 0, Seqeunces are used */
union select 'MaxSeqNo',                   'Max LPN SeqNo',                                   '0',                     'I',       0
union select 'SeqNoMaxLength',             'Maximum Length Of Sequence Number',               '9',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* LPN_Tote Controls  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPN_Tote';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LPNFormat',                  'LPN Format',                                      '<LPNType><SeqNo>',      'S',       1
union select 'NextSeqNo',                  'Next LPN SeqNo',                                  '1',                     'I',       -1
/* when MaxSeqNo = 0, Seqeunces are used */
union select 'MaxSeqNo',                   'Max LPN SeqNo',                                   '0',                     'I',       0
union select 'SeqNoMaxLength',             'Maximum Length Of Sequence Number',               '4',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* LPN_Temp Controls  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPN_Temp';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'LPNFormat',                  'LPN Format',                                      '<LPNType><SeqNo>',      'S',       1
/* when MaxSeqNo = 0, Seqeunces are used */
union select 'MaxSeqNo',                   'Max LPN SeqNo',                                   '0',                     'I',       0
union select 'SeqNoMaxLength',             'Maximum Length Of Sequence Number',               '9',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* LPN Reservation */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPNReservation';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'RequireUniquePT',            'Assign only when LPN is required by one PickTicket in given criteria',
                                                                                              'N',                     'B',       1
union select 'ConfirmLPNAsPickedOnAllocate','Confirm LPN as Picked after Allocation',         'N',                     'B',       1
union select 'ReassignAcrossCustPOs',      'Reassign across Customer POs',                    'N',                     'B',       1
union select 'ReassignAcrossWaves',        'Reassign across Waves',                           'N',                     'B',       1
union select 'ReassignToSamePOOnly',       'Reassign to same Customer PO only',               'N',                     'B',       1
union select 'ReassignToSameWaveOnly',     'Reassign to same Wave only',                      'N',                     'B',       1
union select 'ValidLPNStatuses',           'Valid LPN Status',                                'PKDE' /* Putaway, Picked, Packed, Staged*/,
                                                                                                                       'S',       1
union select 'AllowPartialReservation',    'Allow Partial reservation of LPN',                'Y',                     'B',       1
union select 'PromptPallet',               'Prompt user to scan Pallet',                      'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LPN Activation: Ship Cartons */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPNShipCartonActivate';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvalidToLPNStatuses',       'Not valid To LPN Status',                         'C,V,O,S,E,L,I',         'S',       1
union select 'ValidToLPNTypes',            'Valid LPN Types',                                 'S',                     'S',       1
union select 'ActivatedToLPNStatus',       'Activated LPN Statuses',                          'K,D,E,L',               'S',       1
union select 'InvalidLocationTypes',       'Not valid Location types',                        'C',                     'S',       1
union select 'InvalidLocationStatus',      'Not valid Location statuses',                     'I,E,D,N',               'S',       1
union select 'InvalidPalletType',          'Not valid Pallet Types',                          'C,T,U',                 'S',       1
union select 'InvalidPalletStatus',        'Not valid Pallet Statuses',                       '',                      'S',       1
union select 'ValidPalletStatus',          'Valid Pallet Statuses',                           'D,SG',                  'S',       1
union select 'AutoConfirmWaves',           'Wave types to auto confirm',                      'BCP,BPP',               'S',       1
union select 'PromptPallet',               'Prompt user to scan Pallet',                      'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Ship Cartons: Cancel */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPNShipCartonCancel';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatus',             'Valid LPN Statuses',                              'K,D,E',                 'S',       1
union select 'AutoConfirmWaves',           'Wave types to auto confirm',                      'BCP,BPP',               'S',       1
union select 'ValidStatuses',              'Valid LPN Statuses for voiding Ship Cartons',     'F',                     'S',       1
union select 'ValidTypes',                 'Valid LPN Types for voiding Ship Cartons',        'S',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Auto Activation */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'AutoActivation';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MaxWavesToProcess',          'Maximum waves to consider to process at a time',  '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* LPNType */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPNType';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ReusableTypes',              'Reusable Types',                                  'FHA',                   'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Onhand Inventory - Mode can be LPN, WH or SPPEXP*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'OnhandInventory';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Mode',                       'Mode of Onhand Inventory',                        'WH',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Remove_SKU */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Remove_SKU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'RemoveSKUFromLocation',      'Remove SKU From Location',                        'N' ,                    'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* SKU */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'SKU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'UPCUsed',                    'Use UPC to identify SKUs',                        'Y' /* Yes */,           'S',       1
union select 'CaseUPCUsed',                'Use CaseUPC to identify SKUs',                    'N' /* No */,            'S',       1
union select 'MultipleUPCs',               'Have multiple UPCs per SKU',                      'N' /* No */,            'S',       1
union select 'BarcodeUsed',                'SKUs have a different barcode',                   'N' /* No */,            'S',       1
union select 'AlternateSKUUsed',           'Use Alternate SKU identifier?',                   'N' /* No */,            'S',       1
union select 'ValidateInactiveSKU',        'Validate Inactive SKUs',                          'Y' /* No */,            'S',       1
union select 'SKUDimensionsRequired',      'Validate SKU Dimensions',                         'N' /* No */,            'S',       1
union select 'SKUCubeWeightRequired',      'Validate SKU Cube Weight',                        'N' /* No */,            'S',       1
union select 'SKUPackInfoRequired',        'Validate SKU PackInfo',                           'N' /* No */,            'S',       1
union select 'PalletTieHighRequired',      'Validate Pallet TieHigh',                         'N' /* No */,            'S',       1
union select 'UseSKUStandardQty',          'Use SKU Standard Qty',                            'Y',                     'B',       1

-- Below not used, has been split into different control vars for Weight & Cube
--union select 'SKUCubeWeightUpdate',      'SKU Cube weights are managed by CIMS or HOST',    'CIMS',                  'S',       1

union select 'SKUDimensionUpdate',         'SKU Unit Dimensions are managed by CIMS or HOST', 'CIMS,HOST',             'S',       1
union select 'SKUCubeUpdate',              'SKU Unit Volume are managed by CIMS or HOST',     'CIMS,HOST',             'S',       1
union select 'SKUWeightUpdate',            'SKU Unit Weight information managed by CIMS or HOST',
                                                                                              'CIMS,HOST',             'S',       1
union select 'SKUIPDimensionUpdate',       'SKU Case Dimensions are managed by CIMS or HOST',
                                                                                              'CIMS,HOST',             'S',       1
union select 'SKUIPCubeUpdate',            'SKU Case Volume information managed by CIMS or HOST',
                                                                                              'CIMS,HOST',             'S',       1
union select 'SKUIPWeightUpdate',          'SKU Case Weight information managed by CIMS or HOST',
                                                                                              'CIMS,HOST',             'S',       1

union select 'SKUPackInfoUpdate',          'SKU Pack information managed by CIMS or HOST',    'CIMS,HOST',             'S',       1
union select 'SKUShipPackUpdate',          'SKU ShipPack managed by CIMS or HOST',            'CIMS,HOST',             'S',       1
union select 'PalletTieHighUpdate',        'SKU Pallet Tie/High information managed by CIMS or HOST',
                                                                                              'CIMS,HOST',             'S',       1
union select 'PutawayClassUpdate',         'Putaway class managed by CIMS or HOST',           'CIMS,HOST',             'S',       1
union select 'ReplenishClassUpdate',       'Replenish class managed by CIMS or HOST',         'CIMS,HOST',             'S',       1
union select 'ABCClassUpdate',             'ABC class managed by CIMS or HOST',               'CIMS,HOST',             'S',       1
union select 'SKUCaseUPCUpdate',           'SKU CaseUPC managed by CIMS or HOST',             'CIMS,HOST',             'S',       1
union select 'SKUAlternateSKUUpdate',      'SKU AlternateSKU managed by CIMS or HOST',        'CIMS,HOST',             'S',       0
union select 'UPCsRequired',               'UPC/CaseUPC are required',                        'U' /* UPC, Case UPC */, 'S',       1
union select 'ImageURLPath',               'Static path of the images url',                   'https://cimswms.net/resources/photos/',
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Inactive SKUs */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'SKU_Inactive';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'SetupPickLane',              'Allow Setup of PickLane for Inactive SKU',        'N' /* No */,           'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Transfer Inventory */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'TransferInventory';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvalidFromLPNStatuses',     'Invalid From LPN Status',                         'CFISTLV',               'S',       1
union select 'InvalidToLPNStatuses',       'Invalid To LPN Status',                           'CISTLV',                'S',       1
union select 'ValidateUnitsPackage',       'Validate Units Per Package',                      'Y',                     'S',       1
union select 'EnableReasonCodes',          'Enable ReasonCodes',                              'Y',                     'S',       1
union select 'EnableUoM',                  'Enable UOM',                                      'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Void LPN Controls */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'VoidLPNs';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Valid Statuses to Void LPN',                      'RONFPT' /* Received, Lost, New, New Temp, Putaway, InTransit */,
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Reverse Receiving Controls */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ReverseReceiving';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Valid Statuses to Reverse Receipt LPN',           'P' /* Putaway */,       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/*------------------------------ Cycle Count ---------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* CycleCount */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'L1MaxUnitVariance',          'Level 1 Max Unit Variance',                       '80',                    'I',       1
union select 'L1MaxValueVariance',         'Level 1 Max Value Variance',                      '400',                   'I',       1
union select 'L2MaxUnitVariance',          'Level 2 Max Unit Variance',                       '1000',                  'I',       1
union select 'L2MaxValueVariance',         'Level 2 Max Value Variance',                      '5000',                  'I',       1
union select 'RestrictSKUToPAZone',        'Restrict SKUs to be Putaway into their Zones only',
                                                                                              'N',                     'S',       1
union select 'AllowStagingLocations',      'Allow Staging Locations to Cycle Count',          'Y'  /* Yes */,          'S',       1
union select 'DefaultProcess',             'Default process of cyclecount PI or CC',          'CC' /* CycleCounting */,'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CycleCount Controls - Dock */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_DL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'SKUPrompt',                  'SKU Prompt (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'S',                     'S',       1
union select 'UoMEnabled',                 'UoM Enabled?',                                    'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CycleCount Controls - PickLane - Case storage */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_KP';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'SKUPrompt',                  'SKU Prompt (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'S',                     'S',       1
union select 'UoMEnabled',                 'UoM Enabled?',                                    'N',                     'B',       1
union select 'ConfirmQtyMode',             'Confirm Qty Mode LPNs/IPs?',                      'I'/* Inner Packs/Cases */,
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CycleCount Controls - PickLane - Unit Storage */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_KU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'SKUPrompt',                  'SKU Prompt (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'S',                     'S',       1
union select 'UoMEnabled',                 'UoM Enabled?',                                    'N',                     'B',       1
union select 'ConfirmQtyMode',             'Confirm Qty Mode LPNs/IPs/EA?',                   'D'/* Default */,        'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CycleCount Controls - PickLane */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_KUH';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'SKUPrompt',                  'SKU Prompt (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'S',                     'S',       1
union select 'ConfirmQtyMode',             'Confirm Qty Mode LPNs/IPs/EA?',                   'D'/* Default */,        'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CycleCount Controls - Reserve Location with Pallets Storage Type */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_RA';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'ScanSKU',                    'Scan SKU   (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'LS',                    'S',       1
union select 'ScanPalletLPNs',             'Require Scan Pallet LPNs',                        'N',                     'B',       1
union select 'UoMEnabled',                 'UoM Enabled?',                                    'N',                     'B',       1
union select 'ConfirmQtyMode',             'Confirm Qty Mode LPNs/IPs/EA?',                   'D'/* Default */,        'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CycleCount Controls - Reserve Location with LPNs Storage Type */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_RL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'ScanSKU',                    'Scan SKU   (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'L',                     'S',       1
union select 'ScanPalletLPNs',             'Require Scan Pallet LPNs',                        'N',                     'B',       1
union select 'ConfirmQtyMode',             'Confirm Qty Mode LPNs/IPs/EA?',                   'D'/* Default */,        'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CycleCount Controls - Reserve Location with LPNs and Pallets Storage Type */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_RLA';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'ScanSKU',                    'Scan SKU   (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'LS',                    'S',       1
union select 'ScanPalletLPNs',             'Require Scan Pallet LPNs',                        'N',                     'B',       1
union select 'UoMEnabled',                 'UoM Enabled?',                                    'N',                     'B',       1
union select 'ConfirmQtyMode',             'Confirm Qty Mode LPNs/IPs/EA?',                   'D'/* Default */,        'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CycleCount Controls - Staging */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_SL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'SKUPrompt',                  'SKU Prompt (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'S',                     'S',       1
union select 'UoMEnabled',                 'UoM Enabled?',                                    'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* CycleCount Controls - Bulk Location with LPNs Storage Type */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_BL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'ScanSKU',                    'Scan SKU   (Scan or select)',                     'Scan',                  'S',       1
union select 'AllowEntity',                'Allow Entity',                                    'L',                     'S',       1
union select 'ScanPalletLPNs',             'Require Scan Pallet LPNs',                        'N',                     'B',       1
union select 'ConfirmQtyMode',             'Confirm Qty Mode LPNs/IPs/EA?',                   'D'/* Default */,        'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* CycleCount Controls - For CC Pallet Depth 4 */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CycleCount_PD4';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Determines the default quantity to be shown',     'LPN',                   'S',       1
union select 'InputQtyPrompt',             'Flag to determine to show quantity panel',        'Y',                     'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Disable controls based on Inactive LocationType */
/*----------------------------------------------------------------------------*/
update C
set Status = 'I' /* Inactive */
from Controls C
  join Entitytypes E on C.ControlCategory like 'CycleCount_' + E.TypeCode + '%'
where (E.Status = 'I'  /* Inactive */) and
      (E.Entity = 'Location')

/* Disable controls based on Inactive StorageType */
update C
set Status = 'I' /* Inactive */
from Controls C join Entitytypes E on C.ControlCategory like 'CycleCount_%' + E.TypeCode
where (E.Status = 'I' /* Inactive */) and
      (E.Entity = 'LocationStorage')

Go

/*----------------------------------------------------------------------------*/
/*-------------------------------- Picking -----------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Allocation */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Allocation';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'UseFLThresholdQty',          'Use full LPN threshold value',                    'Y',                     'B',       1
union select 'FLThreshold',                'Default Full LPN threshold value',                '80',                    'I',       1
union select 'PLThreshold',                'Default Partail LPN threshold value',             '40',                    'I',       1
union select 'Debug',                      'Show results on Debug points',                    'N',                     'S',       0
union select 'CreateTaskDetailsFirst',     'Create Task Details first',                       'Y',                     'S',       0
union select 'AutoReleaseTasks',           'Auto Release Tasks?',                             'N',                     'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

declare @Controls TControlsTable, @ControlCategory TCategory = 'Allocation_LPNResv';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvReservationModel',        'Reserve Inventory after Allocation?',             'I' /* Immediate */,     'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

declare @Controls TControlsTable, @ControlCategory TCategory = 'Allocation_InventoryResv';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvReservationModel',        'Reserve Inventory after Allocation?',             'D'/* Defer */,          'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Cubing */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Cubing';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'UseSKUDimensions',           'Use SKU Dimensions to cube?',                     'Y',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Batch Picking */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BatchPicking';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'ValidBatchStatusToPick',     'Valid Batch Statuses To Pick',                    'RLPUEKAC',              'S',       1
union select 'ValidBatchStatusToPause',    'Valid Batch Statuses To Pause',                   'PEKU',                  'S',       1
union select 'SetBatchStatusToPickedOnNoMoreInv',
                                           'Set Batch Status to Picked when no more Inv available',
                                                                                              'N',                     'B',       1
union select 'GenerateTempLabel',          'Generate Temporary Label',                        'N' /* No */,            'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'Y' /* Yes*/,            'S',       1
union select 'PicksLeftForDisplay',        'Picks Left for Display',                          'TD', /* TD - TaskDetails, T - Tasks, U - Units */
                                                                                                                       'S',       1
union select 'AllowSubstitution',          'Allow Substitution',                              'Y',                     'B',       1
union select 'L_PickOption',               'Scan option to pick from for LPN task',           'LSU',                   'S',       1
union select 'CS_PickOption',              'Scan option to pick from in Case pick task',      'SUO',                   'S',       1
union select 'U_PickOption',               'Scan option to pick from in Case pick task',      'SU',                    'S',       1
union select 'MaskPickFromLPN',            'Mask Pick From LPN',                              'N',                     'S',       1
union select 'MaskPickSKU',                'Mask Pick SKU',                                   'N',                     'S',       1
union select 'CrossLocationSubstitution',  'Cross Location LPNs Substitution ?',              'N',                     'S',       1
union select 'CrossWarehouseSubstitution', 'Cross Warehouse LPNs Substitution ?',             'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking : Single Line Wave */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BatchPicking_SL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '0',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'GenerateTempLabel',          'Generate Temporary Label',                        'N' /* No */,            'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'Y' /* Yes*/,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking : Pick to Cart Wave */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BatchPicking_PC';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '0',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'GenerateTempLabel',          'Generate Temporary Label',                        'N' /* No */,            'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'Y' /* Yes*/,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking : Replenish Wave */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BatchPicking_RU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '0',                     'I',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'GenerateTempLabel',          'Generate Temporary Label',                        'N' /* No */,            'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'N' /* Yes*/,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking : Transfers Wave */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BatchPicking_XFER';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'GenerateTempLabel',          'Generate Temporary Label',                        'S', /* N-No or C-Carton or S-Ship Carton */
                                                                                                                       'S',       1
union select 'PicksLeftForDisplay',        'Picks Left for Display',                          'TD', /* TD - TaskDetails, T - Tasks, U - Units */
                                                                                                                       'S',       1
union select 'PrintLabel',                 'Label Print Required',                            'Y' /* Yes */,           'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking : Bulk Case Pick - BCP */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BatchPicking_BCP';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'GenerateTempLabel',          'Generate Temporary Label',                        'C', /* N-No or C-Carton or S-Ship Carton */
                                                                                                                       'S',       1
union select 'PrintLabel',                 'Label Print Required',                            'N' /* No */,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking : Bulk Pick Pack - BPP */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BatchPicking_BPP';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'GenerateTempLabel',          'Generate Temporary Label',                        'C', /* N-No or C-Carton or S-Ship Carton */
                                                                                                                       'S',       1
union select 'PrintLabel',                 'Label Print Required',                            'N' /* No */,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Build Pallet */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BuildPallet';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ShowConfirmationMessage',    'Show Confirmation Message',                       'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Build Inventory Pallet */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Inventory, Getting Invalid LPN Statuses/Types */
declare @Controls TControlsTable, @ControlCategory TCategory = 'BuildPallet_I';  /* Category defined as BuildPallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvalidLPNStatuses',         'Invalid LPNs Statuses Check',                     'SIHVC',                 'S',       1
union select 'InvalidLPNTypes',            'Invalid LPNs Type',                               'LAS',                   'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Build Picking Pallet */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Picking, Getting Invalid LPN Statuses/Types */
declare @Controls TControlsTable, @ControlCategory TCategory = 'BuildPallet_P';  /* Category defined as BuildPallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvalidLPNStatuses',         'Invalid LPNs Statuses Check',                     'SIHVC',                 'S',       1
union select 'InvalidLPNTypes',            'Invalid LPNs Type',                               'LA',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Build Receiving Pallet */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Receiving, Getting Invalid LPN Statuses/Types */
declare @Controls TControlsTable, @ControlCategory TCategory = 'BuildPallet_R';  /* Category defined as BuildPallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvalidLPNStatuses',         'Invalid LPNs Statuses Check',                     'SIHVCEDGKA',            'S',       1
union select 'InvalidLPNTypes',            'Invalid LPNs Type',                               'LAS',                   'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Build Shipping Pallet */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Shipping, Getting Invalid LPN Statuses/Types */
declare @Controls TControlsTable, @ControlCategory TCategory = 'BuildPallet_S';  /* Category defined as BuildPallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvalidLPNStatuses',         'Invalid LPNs Statuses Check',                     'SIHVC',                 'S',       1
union select 'InvalidLPNTypes',            'Invalid LPNs Type',                               'LA',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Move Pallet */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'MovePallet';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidPalletStatuses',        'Valid statuses to move the pallet',               'B,R,P,A,K,SG,L,O,T',    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Drop Pallet */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'DropPallet';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,              DataType,  Visible)
      select 'ValidStatuses',              'Valid Statuses To Drop',                          'CKDSG'/* Picking, Picked, Packed, Staged */,
                                                                                                                         'I',       1
union select 'ValidPalletTypes',           'Valid Pallet Types To Drop',                      'PCTS'/* Picking Pallet, Picking Cart, Trolley, Shipping Pallet */,
                                                                                                                         'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Order - Convert to set SKUs */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ConvertToSetSKUs';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,              DataType,  Visible)
      select 'ValidOrderStatus',           'Valid Order Statuses To Convert to Sets',         'PKSL' /* Picked, Packed, Staged, Loaded */,
                                                                                                                         'S',       1
      select 'ValidLPNStatus',             'Valid LPN Statuses To Convert to Sets',           'KGDEL' /* Picked, Packing, Packed, Staged, Loaded */,
                                                                                                                         'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Pallets */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallets';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AllowMultipleSKUs',          'Allow Multiple SKUs',                             'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet_RS */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_RS';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletVolume',               'Volume of the Pallet',                            '80',                    'I',       1
union select 'StdLPNsPerPallet',           'Standard LPNs per Pallet',                        '50',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet_OS */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_OS';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletVolume',               'Volume of the Pallet',                            '120',                   'I',       1
union select 'StdLPNsPerPallet',           'Standard LPNs per Pallet',                        '80',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PalletTypes */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PalletTypes';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PickCarts',                  'Pick Carts',                                      'CTH',                   'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Picking Cart */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_C';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Returns Picking Cart Format',                     'C<SeqNo>',              'S',       1
union select 'NextSeqNo',                  'Next Cart SeqNo',                                 '1',                     'I',       -1
union select 'MaxSeqNo',                   'Max Cart SeqNo',                                  '0',                     'I',       1
union select 'PalletSeqNoMaxLength',       'Cart SeqNo Max. Length',                          '3',                     'I',       1
union select 'PalletLPNFormat',            'Cart Position Format',                            '<PalletNo>-<SeqNo>',    'S',       1
union select 'LPNSeqNoMaxLength',          'Cart Position SeqNo Max. Length',                 '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Clear Cart User */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Trolley */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_ClearCartUser';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Valid statuses to allow clear user on cart',      'KGDE' /* Picked, Packing, Packed, Empty */,
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Flat */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_F';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Returns Flat Cart Format',                        'RF<SeqNo>',             'S',       1
union select 'NextSeqNo',                  'Next Cart SeqNo',                                 '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Cart SeqNo Max. Length',                          '3',                     'I',       1
union select 'PalletLPNFormat',            'Cart Position Format',                            '<PalletNo>-<SeqNo>',    'S',       1
union select 'LPNSeqNoMaxLength',          'Cart Position SeqNo Max. Length',                 '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Hanging */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_H';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Returns Hanging Cart Format',                     'RH<SeqNo>',             'S',       1
union select 'NextSeqNo',                  'Next Cart SeqNo',                                 '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Cart SeqNo Max. Length',                          '3',                     'I',       1
union select 'PalletLPNFormat',            'Cart Position Format',                            '<PalletNo>-<SeqNo>',    'S',       1
union select 'LPNSeqNoMaxLength',          'Cart Position SeqNo Max. Length',                 '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Inventory */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_I';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Inventory Pallet Format',                         'P<SeqNo>',              'S',       1
union select 'NextSeqNo',                  'Next Pallet SeqNo',                               '1',                     'I',       -1
/* MaxSeqNo = 0 means we use Sequences and not controls */
union select 'MaxSeqNo',                   'Max Pallet SeqNo',                                '0',                     'I',       1
union select 'PalletSeqNoMaxLength',       'Pallet SeqNo Max. Length',                        '6',                     'I',       1
union select 'PalletLPNFormat',            'Pallet Position Format',                          '<PalletNo>-<SeqNo>',    'S',       0
union select 'LPNSeqNoMaxLength',          'Pallet Position SeqNo Max. Length',               '2',                     'I',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type MultipleOrders */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_MO';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Returns MultipleOrders Cart Format',              'MO<SeqNo>',             'S',       1
union select 'NextSeqNo',                  'Next Cart SeqNo',                                 '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Cart SeqNo Max. Length',                          '3',                     'I',       1
union select 'PalletLPNFormat',            'Cart Position Format',                            '<PalletNo>-<SeqNo>',    'S',       1
union select 'LPNSeqNoMaxLength',          'Cart Position SeqNo Max. Length',                 '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Picking Pallet */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_P';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Returns Picking Pallet Cart Format',              'P<SeqNo>',              'S',       1
union select 'NextSeqNo',                  'Next Pallet SeqNo',                               '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Cart SeqNo Max. Length',                          '3',                     'I',       1
union select 'PalletLPNFormat',            'Cart Position Format',                            '<PalletNo>-<SeqNo>',    'S',       1
union select 'LPNSeqNoMaxLength',          'Cart Position SeqNo Max. Length',                 '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Receiving Pallet */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_R';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Returns Receiving Pallet Cart Format',            'R<SeqNo>',              'S',       1
union select 'NextSeqNo',                  'Next Pallet SeqNo',                               '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Cart SeqNo Max. Length',                          '3',                     'I',       1
union select 'PalletLPNFormat',            'Cart Position Format',                            '<PalletNo>-<SeqNo>',    'S',       1
union select 'LPNSeqNoMaxLength',          'Cart Position SeqNo Max. Length',                 '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Shipping Pallet */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_S';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Returns Shipping Pallet Cart Format',             'S<SeqNo>',              'S',       1
union select 'NextSeqNo',                  'Next Pallet SeqNo',                               '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Pallet SeqNo Max. Length',                        '3',                     'I',       1
union select 'PalletLPNFormat',            'Pallet Position Format',                          '<PalletNo>-<SeqNo>',    'S',       1
union select 'LPNSeqNoMaxLength',          'Pallet Position SeqNo Max. Length',               '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type SingleOrder */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_SO';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Returns SingleOrder Cart Format',                 'SO<SeqNo>',             'S',       1
union select 'NextSeqNo',                  'Next Cart SeqNo',                                 '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Cart SeqNo Max. Length',                          '3',                     'I',       1
union select 'PalletLPNFormat',            'Cart Position Format',                            '<PalletNo>-<SeqNo>',    'S',       1
union select 'LPNSeqNoMaxLength',          'Cart Position SeqNo Max. Length',                 '2',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type Trolley */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_T';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Putaway Pallet Format',                           'T<SeqNo>',              'S',       1
union select 'NextSeqNo',                  'Next Pallet SeqNo',                               '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Pallet SeqNo Max. Length',                        '4',                     'I',       1
union select 'PalletLPNFormat',            'Pallet Position Format',                          '<PalletNo>-<SeqNo>',    'S',       0
union select 'LPNSeqNoMaxLength',          'Pallet Position SeqNo Max. Length',               '2',                     'I',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Pallet Generation */
/*----------------------------------------------------------------------------*/
/* Pallet Type - Carts of type PutAway */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Pallet_U';  /* Category defined as Pallet_ + PALLETTYPE */

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletFormat',               'Putaway Pallet Format',                           'PA<SeqNo>',             'S',       1
union select 'NextSeqNo',                  'Next Pallet SeqNo',                               '1',                     'I',       -1
union select 'PalletSeqNoMaxLength',       'Pallet SeqNo Max. Length',                        '6',                     'I',       1
union select 'PalletLPNFormat',            'Pallet Position Format',                          '<PalletNo>-<SeqNo>',    'S',       0
union select 'LPNSeqNoMaxLength',          'Pallet Position SeqNo Max. Length',               '2',                     'I',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* PB_CreateBPT */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PB_CreateBPT';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BP',                         'Create BPT for Bulk Batches',                     'Y',                     'S',       1
union select 'BPP',                        'Create BPT for Bulk Pick & Pack',                 'Y',                     'S',       1
union select 'BCP',                        'Create BPT for Bulk Case Pick',                   'Y',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PB_Release */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PB_Release';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ExportSrtrData',             'Export Sorter Details while Batch release',       'Y',                     'S',       1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BatchFormat',                'Default PickBatch Format',                        '<YY><MM><DD><SeqNo>',   'S',       1
union select 'NextSeqNo',                  'Next PickBatch SeqNo',                            '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Maximum Length Of Sequence Number',               '3',                     'I',       1
union select 'BatchNoLength',              'Total length of the BatchNo',                     '7',                     'I',       1
union select 'WaveUnitCalcMethod',         'Wave Unit Calc Method',                           'UnitsOnOrders',         'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch_LPNPalletPick */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_LPNPalletPick';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'UnloadPickedLPNsIntoLocation',
                                           'Unload Picked LPNs into Location',                'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch_ReallocateBatch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_ReallocateBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvalidStatusesToReallocate','Invalid Statuses to Reallocate',                  'XSD', /* Canceled, Shipped, Completed */
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch_ReleasePickBatch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_ReleasePickBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatusesToRelease',     'Valid Statuses to Release',                       'NBRPUKAC', /* Statuses other than Ready To Pull, Being Pulled, Staged, Loaded, Canceled, Shipped, Completed */
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* WaveReleaseForPicking */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'WaveReleaseForPicking';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidWaveTypes',             'Valid Waves types to Release for Picking',        'AUTO,CF,ZC', /* Auto/ Cold Fusion/ Zone C */
                                                                                                                       'S',       1
union select 'ValidWaveStatuses',          'Valid Waves statuses to Release for Picking',     'R', /* Ready To Pick */
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Pre-process Order on the wave */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Wave_PreprocessOrder';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidOrderStatus',           'Valid statuses for the Orders to pre-process',    'O,N,W' /* Downloaded, New, Waved */,
                                                                                                                       'S',       1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/update */;

Go

/*----------------------------------------------------------------------------*/
/* Remove_Order */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Wave_RemoveOrder';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidWaveStatuses',          'Valid Waves statuses to Remove orders from wave', 'NERPUKACGO' ,           'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch_Xfer -- for Transfer Waves */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_Xfer';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MaxVolume',                  'Max Volume per Task (cu. ft.)',                   '80',                    'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task ',                            '500',                   'I',       1
union select 'MaxCases',                   'Max Cases per Task ',                             '20',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task ',                             '2000',                  'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MaxTempLabels',              'Max Temp labels per Task ',                       '8',                     'I',       1
union select 'MaxPicksPerTask_L',          'Max Picks per LPN Task ',                         '2',                     'I',       1
union select 'MaxPicksPerTask_CS',         'Max Picks per CasePick Task ',                    '999',                   'I',       1
union select 'MaxPicksPerTask_U',          'Max Picks per UnitPick Task ',                    '999',                   'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '5',                     'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '30',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '20',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
union select 'AutoReleaseTasks',           'Auto Release Created Tasks',                      'Y' /* Yes */,           'B',       1
--union select 'DefaultDestination',         'Default Destination for Retail Wave',             'SORT-RETAIL',           'S',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'Y',                     'S',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1
union select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1
union select 'PromptOnRelease',            'Prompt for Ship Date & Drop Location on release of multiple waves',
                                                                                              'O', /* Optional */      'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* PickBatch_RU */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_RU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PromptOnRelease',            'Prompt for Ship Date & drop Lcoation on wave release',
                                                                                              'D', /* Disable */       'S',       0
union select 'MaxVolume',                  'Max Volume per Task',                             '10000',                 'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task',                             '500',                   'I',       1
union select 'MaxCases',                   'Max Cases per Task',                              '20',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task',                              '800',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MaxPicksPerTask_L',          'Max Picks per LPN Task ',                         '2',                     'I',       1
union select 'MaxPicksPerTask_CS',         'Max Picks per CasePick Task ',                    '999',                   'I',       1
union select 'MaxPicksPerTask_U',          'Max Picks per UnitPick Task ',                    '999',                   'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '20',                    'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '30',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '20',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
union select 'AutoReleaseTasks',           'Auto Release Created Tasks',                      'Y' /* Yes */,           'B',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'Y',                     'S',       1
union select 'CancelBatchIfEmpty',         'Cancel Batch if Empty?',                          'Y',                     'B',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1
union select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch_PTS */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_PTS';
insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MaxVolume',                  'Max Volume per Task ',                            '5500',                  'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task ',                            '50',                    'I',       1
union select 'MaxCases',                   'Max Cases per Task ',                             '50',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task ',                             '350',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '5',                     'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '50',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '50',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
--union select 'DefaultDestination',         'Default Destination for Retail Wave',             'SORT-RETAIL',         'S',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'N',                     'S',       1
union select 'ScanPackingList',            'Scan Packing List',                               'N',                     'S',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1
union select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch_PTC */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_PTC';
insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MaxVolume',                  'Max Volume per Task ',                            '5500',                  'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task ',                            '50',                    'I',       1
union select 'MaxCases',                   'Max Cases per Task ',                             '50',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task ',                             '350',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '5',                     'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '50',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '50',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
--union select 'DefaultDestination',         'Default Destination for Retail Wave',             'SORT-RETAIL',         'S',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'N',                     'S',       1
union select 'ScanPackingList',            'Scan Packing List',                               'N',                     'S',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1
union select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch_SLB */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_SLB';
insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MaxVolume',                  'Max Volume per Task ',                            '5500',                  'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task ',                            '50',                    'I',       1
union select 'MaxCases',                   'Max Cases per Task ',                             '50',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task ',                             '350',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '5',                     'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '50',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '50',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
--union select 'DefaultDestination',         'Default Destination for Retail Wave',             'SORT-RETAIL',         'S',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'N',                     'S',       1
union select 'ScanPackingList',            'Scan Packing List',                               'N',                     'S',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1
union select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* PickBatch_LTL */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_LTL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PromptOnRelease',            'Prompt for Ship Date & drop Lcoation on wave release',
                                                                                              'O', /* Optional */      'S',       0
union select 'MaxVolume',                  'Max Volume per Task',                             '10000',                 'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task',                             '500',                   'I',       1
union select 'MaxCases',                   'Max Cases per Task',                              '20',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task',                              '800',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MaxPicksPerTask_L',          'Max Picks per LPN Task ',                         '2',                     'I',       1
union select 'MaxPicksPerTask_CS',         'Max Picks per CasePick Task ',                    '999',                   'I',       1
union select 'MaxPicksPerTask_U',          'Max Picks per UnitPick Task ',                    '999',                   'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '20',                    'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '30',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '20',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
union select 'AutoReleaseTasks',           'Auto Release Created Tasks',                      'Y' /* Yes */,           'B',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'Y',                     'S',       1
union select 'CancelBatchIfEmpty',         'Cancel Batch if Empty?',                          'Y',                     'B',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1
union select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* BCP: Case Pick */
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_BCP';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1
union select 'MaxVolume',                  'Max Volume per Task',                             '10000',                 'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task',                             '500',                   'I',       1
union select 'MaxCases',                   'Max Cases per Task',                              '20',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task',                              '800',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MaxPicksPerTask_L',          'Max Picks per LPN Task ',                         '2',                     'I',       1
union select 'MaxPicksPerTask_CS',         'Max Picks per CasePick Task ',                    '999',                   'I',       1
union select 'MaxPicksPerTask_U',          'Max Picks per UnitPick Task ',                    '999',                   'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '20',                    'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '30',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '20',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
union select 'AutoReleaseTasks',           'Auto Release Created Tasks',                      'Y' /* Yes */,           'B',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'Y',                     'S',       1
union select 'CancelBatchIfEmpty',         'Cancel Wave if Empty?',                           'Y',                     'B',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* BPP: Pick & Pack */
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_BPP';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1
union select 'MaxVolume',                  'Max Volume per Task',                             '10000',                 'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task',                             '500',                   'I',       1
union select 'MaxCases',                   'Max Cases per Task',                              '20',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task',                              '800',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MaxPicksPerTask_L',          'Max Picks per LPN Task ',                         '2',                     'I',       1
union select 'MaxPicksPerTask_CS',         'Max Picks per CasePick Task ',                    '999',                   'I',       1
union select 'MaxPicksPerTask_U',          'Max Picks per UnitPick Task ',                    '999',                   'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '20',                    'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '30',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '20',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
union select 'AutoReleaseTasks',           'Auto Release Created Tasks',                      'Y' /* Yes */,           'B',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'Y',                     'S',       1
union select 'CancelBatchIfEmpty',         'Cancel Wave if Empty?',                           'Y',                     'B',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* BKPP: Bulk Pick and Pack */
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_BKPP';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1
union select 'MaxVolume',                  'Max Volume per Task',                             '10000',                 'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task',                             '500',                   'I',       1
union select 'MaxCases',                   'Max Cases per Task',                              '20',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task',                              '800',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MaxPicksPerTask_L',          'Max Picks per LPN Task ',                         '2',                     'I',       1
union select 'MaxPicksPerTask_CS',         'Max Picks per CasePick Task ',                    '999',                   'I',       1
union select 'MaxPicksPerTask_U',          'Max Picks per UnitPick Task ',                    '999',                   'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '20',                    'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '30',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '20',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
union select 'AutoReleaseTasks',           'Auto Release Created Tasks',                      'Y' /* Yes */,           'B',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'Y',                     'S',       1
union select 'CancelBatchIfEmpty',         'Cancel Wave if Empty?',                           'Y',                     'B',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1
union select 'PrintJobLevel',              'Split wave across multiple printjobs',            'Order',                 'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* RW: Rework */
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_RW';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1
union select 'MaxVolume',                  'Max Volume per Task',                             '10000',                 'I',       1
union select 'MaxCartonVolume',            'Max Carton Volume per Task',                      '45000',                 'I',       1
union select 'MaxWeight',                  'Max Weight per Task',                             '500',                   'I',       1
union select 'MaxCases',                   'Max Cases per Task',                              '20',                    'I',       1
union select 'MaxUnits',                   'Max Units per Task',                              '800',                   'I',       1
union select 'MaxOrders',                  'Max Orders per Task ',                            '30',                    'I',       1
union select 'MaxPicksPerTask_L',          'Max Picks per LPN Task ',                         '2',                     'I',       1
union select 'MaxPicksPerTask_CS',         'Max Picks per CasePick Task ',                    '999',                   'I',       1
union select 'MaxPicksPerTask_U',          'Max Picks per UnitPick Task ',                    '999',                   'I',       1
union select 'MinCasesPerTask',            'Min Cases per Task for Picklane location',        '20',                    'I',       1
union select 'AvgUnitsPerOrder',           'Average Units Per Order for a SKU',               '30',                    'I',       1
union select 'UnitsPerLine',               'Units Per Line for a SKU',                        '20',                    'I',       1
union select 'NumSKUOrdersPerBatch',       'Num Order on Pickbatch for a SKU',                '5',                     'I',       1
union select 'AutoReleaseTasks',           'Auto Release Created Tasks',                      'Y' /* Yes */,           'B',       1
union select 'Task_SplitOrder',            'Split order across mulitple tasks',               'Y',                     'S',       1
union select 'CancelBatchIfEmpty',         'Cancel Wave if Empty?',                           'Y',                     'B',       1
union select 'ExportStatusOnUnwave',       'Export Status of PT when removed from Wave?',     'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* RWC: Contractor Rework */
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_RWC';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'StatusCalcByUnits',          'Wave status calculation units (R-Reserved, T-Total)',
                                                                                              'R'/* Reserved Units */, 'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* PickBatch_UnitPick */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickBatch_UnitPick';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'UnloadPickedLPNsIntoLocation',
                                           'Unload Picked LPNs into Location',                'Y',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* CancelBatch_LTL */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CancelBatch_LTL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'LTL Wave:Valid Statuses to cancel',               'NR',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* CancelBatch_PTL */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CancelBatch_PTL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Pick To Label Wave:Valid Statuses to cancel',     'NR',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* CancelBatch_PTLC */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CancelBatch_PTLC';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Pick To Label/Case Wave:Valid Statuses to cancel','NR',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* CancelBatch_RU */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CancelBatch_RU';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Replenish Units Wave:Valid Statuses to cancel',   'NR',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* CancelBatch_RP */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CancelBatch_RP';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Replenish Cases Wave:Valid Statuses to cancel',   'NR',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Picking */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Picking';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DropLocation',               'Default Drop Location on Picking',                'CO1-PANDA-IN',          'S',       1
union select 'ValidDropLocationTypes',     'Valid Drop Location Types',                       'SDKC' /* Staging, Dock, PickLane, Conveyor  */,
                                                                                                                       'S',       1
union select 'ValidateOwnership',          'Validate Ownership for LPN and Order',            'N' /* No */,            'B',       1
union select 'ValidateUnitsperCarton',     'Validate units per LPN with LPN Qty',             'N' /* No */,            'B',       1
union select 'ValidPalletStatuses',        'Validate Pallet Statuses',                        'ECKPA' /* Empty, Picking, Picked, Putaway, Allocated */,
                                                                                                                       'S',       1
union select 'ValidatePickLocationType',   'Validate Picking Location Types',                 'BKR' /* Bulk, PickLane,  Reserve */,
                                                                                                                       'S',       1
union select 'IsOrderTasked',              'Is Order Tasked',                                 'Y' /* Yes */,           'B',       1
union select 'MarkTempLabelOnDrop',        'Mark temp label as picked on drop picked LPN',    'Y' /* Yes */,           'S',       1
union select 'EnforceScanLPNTask',         'Enforce scan each task while LPN picking',        'Y' /* Yes */,           'S',       1
union select 'ConfirmEmptyLocation',       'Show Confirm Empty Location?',                    'Y' /* Yes */,           'B',       1
union select 'ReCalculateWeightOnLPN',     'Recalculate weight over LPN?',                    'N' /* Yes */,            'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Picklane */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Picklane';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AllowMultipleSKUs',          'Allow Multiple SKUs',                             'Y',                     'B',       1
union select 'AddSKU_MaxScanQty',          'Add SKU to Location - Maximum Scan Quantity in RF device',
                                                                                              '9999',                  'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Short Pick */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ShortPick';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'CreateCC',                   'Creates Cycle Count Task On Short Pick',          'Y' ,                    'B',       1
union select 'CCTaskPriority',             'Default prority for CC Task On Short Pick',       '1' ,                    'I',       1
union select 'ReduceInventory',            'Reduce Inventory On Short Pick',                  'Y'/* Yes */,            'I',       1
union select 'OnShortPick',                'On Short Pick Operations: U-Unallocate, L-Lost, H-Onhold, C-Create CC',
                                                                                              'UC',                    'S',      1
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Batch Picking : Case Pick - Multiple. This picking configuration is for
   Case picking operation where user would pick multiple cases at once from a
   Location. User would be prompted to pick all cases at once to a single New LPN
   by confirming scan of From LPN followed by the ToLPN.
*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickingConfig_CasePick_Multiple';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                'UnitsToPick',           'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'PickEntityCaption',          'Scan entity caption',                             'LPN',                   'S',       1
union select 'SuggPickToCaption',          'Suggested Pick To caption',                       '',                      'S',       1
union select 'ScanPickToCaption',          'Scan Pick To caption',                            'Pick Carton',           'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'Y' /* Yes*/,            'S',       1
union select 'EnableSKUSingleScan',        'Enable SKU Single Scan',                          'N' /* No */,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Batch Picking : LPN Pick To Pallet. This picking configuration is for
   Case picking operation where user would pick multiple cases at once  from a
   Location
*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickingConfig_LPNPickToPallet';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                'UnitsToPick',           'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'PickEntityCaption',          'Scan entity caption',                             'LPN',                   'S',       1
union select 'SuggPickToCaption',          'Suggested Pick To caption',                        '',                     'S',       1
union select 'ScanPickToCaption',          'Scan Pick To caption',                             '',                     'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'N' /* No */,            'S',       1
union select 'EnableSKUSingleScan',        'Enable SKU Single Scan',                          'N' /* No*/,             'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* UnitPicking */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickingConfig_Default';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                'UnitsToPick',           'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'ConfirmPick',                'Confirm Pick',                                    'SKU',                   'S',       1
union select 'SuggPickToCaption',          'Suggested Pick To caption',                       '',                      'S',       1
union select 'ScanPickToCaption',          'Scan Pick To caption',                            '',                      'S',       1
union select 'AutoInitializeToLPN',        'Intialize ToLPN with suggested?',                 'Y' /* Yes */,           'S',       1
union select 'KeepPalletInfoForNextPick',  'Keep Pallet info for next pick',                  'Y' /* Yes */,           'S',       1
union select 'EnableSKUSingleScan',        'Enable SKU Single Scan',                          'N' /* No */,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Batch Picking Configuration: Multi Scan Unit Pick configurations */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickingConfig_UnitPickMultiScan';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                '1',                     'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'N',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'MultiScanPick',         'S',       1
union select 'SuggPickToCaption',          'Suggested Pick To caption',                        '',                     'S',       1
union select 'ScanPickToCaption',          'Scan Pick To caption',                             '',                     'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'Y' /* Yes*/,            'S',       1
union select 'AutoInitializeToLPN',        'Intialize ToLPN with suggested?',                 'Y' /* Yes */,           'S',       1
union select 'KeepPalletInfoForNextPick',  'Keep Pallet info for next pick',                  'Y' /* Yes */,           'S',       1
union select 'EnableSKUSingleScan',        'Enable SKU Single Scan',                          'N' /* No */,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking Configuration: Single Scan Unit Pick configurations for Transfers */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickingConfig_UnitPickSingleScanGenTempLabel';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                'UnitsToPick',           'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'ScanPickToCaption',          'Scan Pick To caption',                            '',                      'S',       1
union select 'ScanPickToCaption',          'Scan Pick To caption',                            '',                      'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'N' /* No */,            'S',       1
union select 'AutoInitializeToLPN',        'Intialize ToLPN with suggested?',                 'N' /* No */,            'S',       1
union select 'KeepPalletInfoForNextPick',  'Keep Pallet info for next pick',                  'Y' /* Yes */,           'S',       1
union select 'EnableSKUSingleScan',        'Enable SKU Single Scan',                          'Y' /* Yes */,           'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking Configuration: Single Scan Unit Pick configurations */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickingConfig_UnitPickSingleScan';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                'PickQty',               'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'SuggPickToCaption',          'Suggested Pick To caption',                       'Position/Tote',         'S',       1
union select 'ScanPickToCaption',          'Scan Pick To caption',                            'Scan Position/Tote',    'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'Y' /* Yes*/,            'S',       1
union select 'AutoInitializeToLPN',        'Intialize ToLPN with suggested?',                 'N' /* No */,            'S',       1
union select 'KeepPalletInfoForNextPick',  'Keep Pallet info for next pick',                  'Y' /* Yes */,           'S',       1
union select 'EnableSKUSingleScan',        'Enable SKU Single Scan',                          'Y' /* Yes*/,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Batch Picking Configuration: When we are picking units to a single shipping
   carton which is cubed , this configuration would be used. User would
   confirm pick by scanning the SKU and entering the qty. In this config, no
   ToLPN is required as user is picking.
*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickingConfig_PicksForSingleCarton';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'DefaultQty',                 'Default Quantity',                                'PickQty',               'S',       1
union select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'PickMode',                   'Batch Picking Mode',                              'UnitScanPick',          'S',       1
union select 'PickEntityCaption',          'Scan entity caption',                             'LPN',                   'S',       1
union select 'SuggPickToCaption',          'Suggested Pick To caption',                        '',                     'S',       1
union select 'ScanPickToCaption',          'Scan Pick To caption',                             '',                     'S',       1
union select 'EnablePickToLPN',            'Enable PickToLPN',                                'N' /* No */,            'S',       1
union select 'AutoInitializeToLPN',        'Intialize ToLPN with suggested?',                 'Y' /* Yes */,           'S',       1
union select 'KeepPalletInfoForNextPick',  'Keep Pallet info for next pick',                  'Y' /* Yes */,           'S',       1
union select 'EnableSKUSingleScan',        'Enable SKU Single Scan',                          'N' /* No */,            'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/*-------------------------------- Packing -----------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* RF Packing - RFPacking_WaveType */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'RFPacking_W';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatusToPack',       'Valid LPN Statuses to Pack',                      'NKGD'/* New, Picked, Packing, Packed */,
                                                                                                                       'S',       1
union select 'ValidPTStatusToPack',        'Valid Pick Ticket Statuses to Pack',              'WAP'/* Waved, Allocated, Picked */,
                                                                                                                       'S',       1
union select 'DefaultQty',                 'Default Packing Qty',                             '0',                     'S',       1
union select 'QtyEnabled?',                'Enable Qty to Pack?',                             'Y'/* Yes */,            'S',       1
union select 'CaptureWeight?',             'Capture LPN Weight after Packing?',               'N'/* No */,             'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Packing */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Packing';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'QtyEnabled',                 'Quantity Enabled?',                               'Y',                     'B',       1
union select 'ValidLPNStatuses',           'Valid LPN Statuses to pack',                      'GDA',                   'S',       1
union select 'PackDetailsMode',            'Mode of Packing Details',                         'Default',               'S',       1
union select 'ShowLinesNotPicked',         'Packing - Display Lines with No Units',           'Y',                     'B',       0
union select 'ShowComponentSKUsLines',     'Packing - Display Component lines',               'N',                     'B',       0
union select 'ValidUnpackWaveStatus',      'Eligible statuses for unpacking Waves',           'PKAC',                  'S',       0
union select 'ValidUnpackOrderStatus',     'Eligible statuses for unpacking Orders',          'CPK',                   'S',       0
union select 'ValidUnpackLPNStatus',       'Eligible statuses for unpacking LPNs',            'D',                     'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Packing Related - Packing_Action */
/*----------------------------------------------------------------------------*/
/* Packing_CloseLPN */
declare @Controls TControlsTable, @ControlCategory TCategory = 'Packing_CloseLPN';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatuses',           'Valid LPN Statuses to pack',                      'GDA',                   'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Packing_RFPacking */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Packing_RFPacking';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatuses',           'Valid LPN Statuses to pack',                      'ND'/* New/Packed */,    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Packing List */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PackingList';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ShowComponentSKUsLines',     'PackingList - Display Component lines',           'N',                     'B',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/* Marika packing list page threshold */
declare @Controls TControlsTable, @ControlCategory TCategory = 'PackingList_Marika';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FP_FPTH',                    'First Page - Full page Threshold',                '30',                    'N',       0
union select 'FP_PPTH',                    'First Page - Partial Page Threshold',             '12',                    'N',       0
union select 'RP_FPTH',                    'Remaining Pages - Full page Threshold',           '36',                    'N',       0
union select 'RP_PPTH',                    'Remaining Pages - Partial Page Threshold',        '18',                    'N',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/* Zobha packing list page threshold */
declare @Controls TControlsTable, @ControlCategory TCategory = 'PackingList_Zobha';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FP_FPTH',                    'First Page - Full page Threshold',                '30',                    'N',       0
union select 'FP_PPTH',                    'First Page - Partial Page Threshold',             '12',                    'N',       0
union select 'RP_FPTH',                    'Remaining Pages - Full page Threshold',           '36',                    'N',       0
union select 'RP_PPTH',                    'Remaining Pages - Partial Page Threshold',        '18',                    'N',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Shipping Manifest */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ShippingManifestMaster';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'FirstPageNumRows',          'Packing list first page records count',            '10',                    'N',       0
union select 'RemainingPageNumRows',      'Packing list remaining page records count',        '30',                    'N',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* BoL Standard Report first page num rows threshold */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'VICSBoLMaster';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'RowsToPrintOnFirstPage',     'BoL Report first page records count',             '5',                     'N',       0
union select 'RowsOnNormalSupplementPage', 'BoL Report Supplement page records count',        '14',                    'N',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/*------------------------------- Printing -----------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* BoL */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BoL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PalletTareWeight',           'Pallet Tare Weight',                              '35',                    'I',       1
union select 'PalletVolume',               'Pallet Tare Volume',                              '7680',                  'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* BoLNumber */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BoLNumber';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BoLFormat',                  'BoL Number Format',                               'B<MM><DD><SeqNo>',      'S',       1
union select 'NextSeqNo',                  'Next BoL SeqNo',                                  '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Maximum Length Of BoL Sequence No',               '3',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Max Labels To Print For Each Request */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ShipLabels';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MaxLabelsToPrintForEachRequest',
                                           'Max Labels print for each request',               '200',                   'I',       1
union select 'IsReturnLabelRequired',      'Is Return Label required?',                       'N',                     'S',       1
union select 'StuffAdditionalInfoOnZPL',   'Stuff Addtional Info on ZPL label?',              'N',                     'S',       1
union select 'DefaultPhoneNo',             'Default PhoneNo',                                 '0000000000',            'S',       1
union select 'DefaultEmailId',             'Default Email Id',                                'cims.dev@cloudimsystems.com',
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Controls for Generate label batch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'GenerateShipLabels';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'MaxLabelsToGenerate',        'Max records per instance to generate labels',     200,                     'I',       1
union select 'ThresholdTimeToRegenerate',  'Threshold time (Mins) to regenerate the labels which are stuck in GI status',
                                                                                              15,                      'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Controls for Export Shipping Documents batch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportShippingDocs';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Shipping Docs Export Batch SeqNo',            '1',                     'I',       -1
union select 'WaveTypesToExportShippingDocs',
                                           'Valid wave types to export shipping Docs to WCS',  'XYZ',                   'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Controls for Manifest Export Batch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ManifestExportBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Manifest Export Batch SeqNo',                '1',                     'I',       -1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* VICSBoL */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'VICSBoL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NMFCCode',                   'NMFC Code',                                       '49880',                 'S',       1
union select 'NMFCClass',                  'Item Class',                                      '100',                   'S',       1
union select 'NMFCCommodityDesc',          'Item Description',                                'Apparel',               'S',       1
union select 'CompanyId',                  '7 Digit CompanyId (Prefix Zeros)',                '0887430',               'S',       1
union select 'Palletized',                 'Default value of Palletized ',                    'Y',                     'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* VICSBoL Sequence No */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'VICSBoLSequence';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next VICS BoL SeqNo',                             '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Length Of Sequence Number',                       '9',                     'I',       0
union select 'MaxSeqNo',                   'Maximum value of Sequence Number - will reset after that',
                                                                                              '999999999',             'I',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/*--------------------------------- Sales ------------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* MinMax Replenishments */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'MinMaxReplenish';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Replenish_CreateBatch',      'Create Replenish Batch?',                         'Y',                     'B',       1
union select 'Replenish_AddOrdersToPriorbatches',
                                           'Add Orders to Existing Replenish Batch?',         'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Modify Batch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ModifyBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'InvalidBatchStatus',         'Invalid Batch Status',                            'XSD', /* Canceled, Shipped, Completed */
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Modify Order */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ModifyOrder';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidOrderStatus',           'Valid Order Status',                              'ONIAWCPKRGL'/* Statuses other than Cancelled, Shipped */,
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Replenish Batch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ReplenishBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'CreateBatch',                'Create Replenish Batch?',                         'Y',                     'B',       1
union select 'ValidBatchStatuses',         'Valid Batch Statuses to Allocate',                'BERPK',                 'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Replenish Order */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ReplenishOrder';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'OrderFormat',                'Default Order Format',                            'R<YY><MM><DD><SeqNo>',  'S',       1
union select 'NextSeqNo',                  'Next PickBatch SeqNo',                            '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Maximum Length Of Sequence Number',               '3',                     'I',       1
union select 'InvalidStatusesToClose',     'InValid Statuses to close Replenish Orders',      'NW',                    'S',       1
union select 'InvalidStatusesToCancel',    'InValid Statuses to Cancel Replenish Orders',     'IACPDX',                'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* OnDemand Replenishments */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'OnDemandReplenish';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Replenish_CreateBatch',      'Create Replenish Batch?',                         'Y',                     'B',       1
union select 'Replenish_AddOrdersToPriorbatches',
                                           'Add Orders to Existing Replenish Batch?',         'N',                     'B',       1
union select 'Replenish_AddLocationsToPriorOrders',
                                           'Add Locations to Existing Orders?',               'N',                     'B',       1
union select 'Replenish_CreateIndependentReplWave',
                                           'Create Independent Replenish Wave?',              'N',                     'B',       0
union select 'MaxQtyToReplenish',          'Max. Quantity to be Replenished',                 'L',/* D - Qty On Demand, L - Location Capacity */
                                                                                                                       'S',       0
exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* OrderClose Ship or Complete? */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'OrderClose';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Complete',                   'Order Types to Mark as Complete',                 'O', /* Out Reserve */   'S',       0
union select 'Ship',                       'Order Types to Mark as Ship',                     'CET', /* C-Customer, E-ECom, T-Transfer */
                                                                                                                       'S',       0
union select 'StatusCalcMethod',           'Order Status calculation method (UnitsAllocated, UnitsToShip, ShipCompletePercent)',
                                                                                              'UnitsAllocated',        'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Customer Order Options */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'OrderClose_C';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatusToClose',      'Valid LPN Status To Close',                       'DELS', /* Packed/Loaded/Staged/Shipped */
                                                                                                                       'S',       1
union select 'ValidOrderStatusToClose',    'Valid Order Status To Close',                     'WCPKGL', /* P-Picked, K-Packed, W-Waved, C-Picking, G- Staged L- Loaded */
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Transfer Order Controls */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'OrderClose_T';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatusToClose',      'Valid LPN Status To Close',                       'DELST', /* Packed/Loaded/Staged Shipped InTransit */
                                                                                                                       'S',       1
union select 'ValidOrderStatusToClose',    'Valid Order Status To Close',                     'WICPKGL', /* I - Inprogress, P-Picked, K-Packed, W-Waved, C-Picking, G- Staged L- Loaded */
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/*------------------------------- Shipping -----------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Loading */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Loading';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatus',             'Valid LPN Status',                                'E,K,D',                 'S',       1
union select 'ValidPalletStatus',          'Valid Pallet Status',                             'SG,K,D',                'S',       1
union select 'ValidLoadStatuses',          'Valid Load Status',                               'NIRML',                 'S',       1
union select 'FluidLoading',               'Fluid Loading',                                   'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Modify ShipDetails */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ModifyShipDetails';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidOrderStatus',           'Valid statuses for the Orders to modify',         'ONIAWCP'/* Downloaded, New, InProgress, Allocated, Waved, Picking, Picked */,
                                                                                                                       'S',       1
union select 'PreprocessOnShipViaChange',  'Preprocess order again on ShipVia change (Y/N)',  'Y',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Ship - VM: Above 'ExportOrderHeaders', 'ExportOrderDetails'
             category and control code should be reveresed as well to be consistent with below
             BUT WILL CHANGE LATER */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Ship';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ExportLPNs',                 'Export LPNs',                                     'Y' ,                    'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Shipping
   LPNs: S - Shipped, L - Loaded, D - Packed, K - Picked, E - Staged
   Loads: R - Ready To Load, L - Ready To Ship
   Shipments: S - Shipped, L - Loaded, D - Packed, G - Staged */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Shipping';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'TrailerNumber',              'Next Trailer Number',                             '1',                     'I',       1
union select 'ValidLPNStatus',             'Valid LPN Status',                                'SLDKEA',                'S',       1
union select 'ValidShipmentStatus',        'Valid Shipment Status',                           'SLDGNAI',               'S',       1
union select 'ValidLoadStatus',            'Valid Load Status',                               ',L,R,I,SI,',            'S',       1
union select 'AutoAssignLPNs',             'Auto Assign LPNs',                                'Y',                     'B',       1
union select 'PalletShipLabel',            'Print Pallet ship Label only',                    'N',                     'S',       1
union select 'PalletTareWeight',           'PalletTare Weight',                               '35',                    'I',       1
union select 'PalletTareVolume',           'Pallet Tare Volume',                              '7680',                  'I',       1
union select 'SingleLoadOrders',           'Load orders in single load only',                 'Y',                     'B',       1
union select 'FedexShipLabelLogging',      'Enable FedEx ShipLabel Logging',                  'Y',                     'B',       1
union select 'UPSShipLabelLogging',        'Enable UPS ShipLabel Logging',                    'Y',                     'B',       1
union select 'RegenerateTrackingNo',       'Regenerate Tracking Number',                      'AFUKGDEL',              'S',       1
union select 'WeightUOM',                  'Unit of measure of Weight',                       'LB',                    'S',       1
union select 'ShipmentConfirmationAlert',  'Send shipment confirmation mail',                 'N' /* No */,            'B',       1
union select 'SenderTaxId',                'Sender tax ID',                                   '123456789',             'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* ShipLPNOnPack */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ShipLPNOnPack';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'Carriers',                   'Ship LPNs of Carriers LPN after Packing',         '',                      'S',       0
union select 'CarriersIntegration',        'Carrier Integration Done',                        'N',                     'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* UnLoading  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'UnLoading';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatus',             'Valid LPN Status',                                'L',                     'S',       1
union select 'ValidPalletStatus',          'Valid Pallet Status',                             'L',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Shipping_FedEx */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Shipping_FedEx';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BoLRequired',                'BOL required for FedEx Carrier',                  'N',                     'B',       1
union select 'ExportCompliance',           'Default Export Compliance',                       '30.37(f)',              'S',       1
union select 'ResidentialServices',        'Residential Services',                            'GROUND_HOME_DELIVERY',  'S',       1
union select 'NonResidentialServices',     'Non Residential Services',                        'ALLOTHERS',             'S',       1
union select 'ETDRequired',                'Electronic Trade Documents Required?',            'No',                    'S',       1
union select 'IsLogoRequired',             'Is Logo Required?',                               'Yes',                   'S',       1
union select 'IsSignatureRequired',        'Is Signature Required?',                          'No',                    'S',       1
union select 'CIRequiredforStates',        'List of States for which Commercial Invoice is required?',
                                                                                              'PR',                    'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Shipping_LTL */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Shipping_LTL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BoLRequired',                'BOL required for LTL Carrier',                    'Y',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Shipping_UPS */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Shipping_UPS';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BoLRequired',                'BOL required for UPS Carrier',                    'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Shipping_USPS */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Shipping_USPS';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BoLRequired',                'BOL required for USPS Carrier',                   'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* ProNumber_FXFE */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ProNumber_FXFE';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AutoGenerate',               'Automatically Generate Pro Number',               'Y',                     'S',       1
union select 'NextSeqNo',                  'Next ProNo in sequence',                          '466679049',             'I',       -1
union select 'MaxSeqNo',                   'Max ProNo in sequence',                           '466679248',             'I',       1
union select 'SeqNoMaxLength',             'SeqNo Maximum Length',                            '9',                     'I',       1
union select 'RecycleSeqNo',               'Can we recycle the sequence if we reach max?',    'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* ProNumber_DAFG */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ProNumber_DAFG';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AutoGenerate',               'Automatically Generate Pro Number',               'Y',                     'S',       1
union select 'NextSeqNo',                  'Next ProNo in sequence',                          '00036628656',           'I',       -1
union select 'MaxSeqNo',                   'Max ProNo in sequence',                           '00036628855',           'I',       1
union select 'SeqNoMaxLength',             'SeqNo Maximum Length',                            '11',                    'I',       1
union select 'RecycleSeqNo',               'Can we recycle the sequence if we reach max?',    'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* ProNumber_XPOL */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ProNumber_XPOL';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AutoGenerate',               'Automatically Generate Pro Number',               'Y',                     'S',       1
union select 'NextSeqNo',                  'Next ProNo in sequence',                          '001',                   'I',       -1
union select 'MaxSeqNo',                   'Max ProNo in sequence',                           '999',                   'I',       1
union select 'SeqNoMaxLength',             'SeqNo Maximum Length',                            '3',                     'I',       1
union select 'RecycleSeqNo',               'Can we recycle the sequence if we reach max?',    'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* UnLoading  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'UnLoading';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidLPNStatus',             'Valid LPN Status',                                'L',                     'S',       1
union select 'ValidPalletStatus',          'Valid Pallet Status',                             'L',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/*---------------------------- User Productivity -----------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Productivity';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NoDaysFrom',                 'No of days back from current date',               30,                      'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go


/*----------------------------------------------------------------------------*/
/*---------------------------- Miscellaneous ---------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'AutoGenerateBatches';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'AddOrdersToPriorBatches',    'Add orders to prior batches',                     'N',                     'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* BPT Allocate

AllocateInventory - N- No, O- OnRelease, Y-Yes, J-By a Job */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'BPT_Allocate';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BP',                         'Allocate Inventory for BPT on Bulk Batches',      'AR' /* After Release */,'S',       1
union select 'BPP',                        'Allocate Inventory for BPT on Bulk Pull Prefernce Batches',
                                                                                              'AR' /* After Release */,'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Cancel Batch */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CancelBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Valid Cancel Batch Status',                       'NR'/* New, Ready To Pick*/,
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CancelPickTicket';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'E',                          'E-Commerce',                                      'IPKWC', /* I-New, P-Picked, K-Packed, W-Batched, C-Picking*/
                                                                                                                       'S',       0
union select 'T',                          'Transfer',                                        'ICP',   /* I-New,  C-Picking, P-Picked */
                                                                                                                       'S',       0
union select 'O',                          'Out-Reserve',                                     'ICP',   /* I-New,  C-Picking, P-Picked */
                                                                                                                       'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* CancelPTLine Controls */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'CancelPTLine';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidStatuses',              'Cancel PTLine valid Statuses',                    'NIWAC', /* N-New, P-, I-InProgress, W-Batched, A-Allocated, C-Picking */
                                                                                                                       'S',       1
union select 'AllowPartialLineCancel',     'Allow cancellatiion of partial line',             'Y',  /* Yes */          'B',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Grid Page Size */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'GridPageSize';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select '0-680',                      'Screen height range 0-680',                       15,                      'I',       1
union select '681-767',                    'Screen height range 681-767',                     16,                      'I',       1
union select '768-768',                    'Screen height range 768-768',                     17,                      'I',       1
union select '769-809',                    'Screen height range 769-809',                     18,                      'I',       1
union select '810-1023',                   'Screen height range 810-9999',                    25,                      'I',       1
union select '1024-9999',                  'Screen height range 810-9999',                    35,                      'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Grid Page Size for CIMS V3 */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'GridPageSizeV3';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select '0-680',                      'Screen height range 0-680',                       20,                      'I',       1
union select '681-767',                    'Screen height range 681-767',                     25,                      'I',       1
union select '768-768',                    'Screen height range 768-768',                     25,                      'I',       1
union select '769-809',                    'Screen height range 769-809',                     30,                      'I',       1
union select '810-1023',                   'Screen height range 810-9999',                    40,                      'I',       1
union select '1024-9999',                  'Screen height range 810-9999',                    50,                      'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* GenerateBatches */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'GenerateBatches';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BatchingLevel',              'Generate Batches based on Orders or Details',     'OH',                    'S',       1
union select 'EnforceBatchingLevel',       'Enforce Batch Generation with Order Details Or Headers',
                                                                                              'OH',                    'S',       1
union select 'AddWavedOrdersToLoad',       'Add Waved Orders to the Load',                    'N'/* No */,             'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* InterfaceLog */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'InterfaceLog';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'EmailId',                    'Support Group EmailId',                           'support@cloudimsystems.com',
                                                                                                                       'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickTicket';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PickTicketFormat',           'Default Pick Ticket format',                      '<OrderType><SeqNo>',    'S',       1
union select 'NextSeqNo',                  'Next task Pick Ticket seqNo',                     '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Maximum length of sequence number',               '6',                     'I',       1
union select 'ShipCompleteThreshold',      'Ship complete Threshold value',                   '365',                   'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'PickTicket_B';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'PickTicketFormat',           'Default Pick Ticket format',                      '<OrderType><SeqNo>',    'S',       1
/* Sequence number is the default one for all PTs, so don't need a specific one for Bulk Pull */

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Archive Data into External DB */
declare @Controls TControlsTable, @ControlCategory TCategory = 'PurgeData';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ExternalDB',                 'Purge Data into External DB',                     'CIMSArchive' ,          'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Router';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ExportLPN_RETAIL',           'Export Retail wave to Router',                    'N',                     'S',       1
union select 'ExportLPN_ECOM-M',           'Export ECom multi line wave to Router',           'N',                     'S',       1
union select 'ExportLPN_ECOM-SPL',         'Export ECom Special wave to Router',              'N',                     'S',       1
union select 'ExportLPN_PTLONLY',          'Export PTL wave to Router',                       'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Sorter';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ExportLPN_RETAIL',           'Export Retail wave to Sorter',                    'N',                     'S',       1
union select 'ExportLPN_ECOM-S',           'Export ECom Single line wave to Sorter',          'N',                     'S',       1
union select 'ExportLPN_ECOM-M',           'Export ECom multi line wave to Sorter',           'N',                     'S',       1
union select 'ExportLPN_ECOM-SPL',         'Export ECom Special wave to Sorter',              'N',                     'S',       1
union select 'ExportLPN_PTLONLY',          'Export PTL wave to Sorter',                       'N',                     'S',       1
union select 'ExportLPN_RFLONLY',          'Export PTL wave to Sorter',                       'N',                     'S',       1
union select 'ExportWaveDetails_RETAIL',   'Export Wave details for Retail Batches',          'N',                     'S',       1
union select 'ExportWaveDetails_ECOM-S',   'Export Wave details for Ecom single Order Batches',
                                                                                              'N',                     'S',       1
union select 'ExportWaveDetails_ECOM-M',   'Export Wave details for Ecom Multi Order Batches','N',                     'S',       1
union select 'ExportWaveDetails_ECOM-SPL', 'Export Wave details for Ecom Special Order Batches',
                                                                                              'N',                     'S',       1
union select 'ExportWaveDetails_RU',       'Export Wave details for Replenish Unit Batches',  'N',                     'S',       1
union select 'ExportWaveDetails_RP',       'Export Wave details for Replenish Case Batches',  'N',                     'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Tasks';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'GenerateTempLabel',          'Generate temp label',                             'X' /* on Release */,    'B',       1
union select 'AutoReleaseTasks',           'Auto Release Created Tasks',                      'N' /* No */,            'B',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'TaskBatch';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'BatchFormat',                'Default task batch format',                       '<MM><DD><SeqNo>',       'S',       1
union select 'NextSeqNo',                  'Next task batch seqNo',                           '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Maximum length of sequence number',               '4',                     'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Tasks_ComfirmPicks';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'ValidTaskStatuses',          'Valid task statuses to confirm picks',            'N',                     'S',       1
union select 'ValidWaveTypes',             'Valid wave types to confirm picks',               'PTS',                   'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Layouts - Custom LayoutRecord */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'UserLayout';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Layout SeqNo',                               '1000',                  'I',       -1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'WebAppConfig';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'GridPageSize',               'Display Records per page',                        '10',                    'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/******************************************************************************/
/*                                 PandA                                      */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Panda';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'OrderTypesToExport',         'OrderTypes To Export',                            '',                      'S',       1
union select 'WarehousesToExport',         'Warehouses To Export',                            '',                      'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* SoftAllocation Controls  */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'SoftAlloc_LogResults';
insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Batch No',                                   1,                       'I',       -1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* ExportToExcel */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'ExportToExcel';

insert into @Controls
            (ControlCode,         Description,                            ControlValue,  DataType,  Visible)
      select 'NextSeqNo',         'Next ExportToExcel SeqNo',             '1',           'I',       -1
union select 'FolderPath_DB',     'Folder for XL generated by DB Proc',   'TempData\ExportToExcel\',
                                                                                         'S',       1
union select 'FolderPath_UI',     'Folder for XL accessed by UI',         'TempData\ExportToExcel\',
                                                                                         'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* Wave After Release Options */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'WaveAfterRelease';
insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,                    Visible)
      select 'EmailWaveShortSummary',      'Email Wave Short summary report',                 'N',                     'S',                         1
union select 'ExportStatusToHost',         'Export Wave Status to Host',                      'N',                     'S',                         1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* LPN_QCHoldorRelease */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'LPN_QCHoldorRelease';

insert into @Controls
            (ControlCode,         Description,                            ControlValue,  DataType,  Visible)
      select 'LPNQCValidStatus',  'LPN Valid Statuses',                   'RTP',         'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go

/*----------------------------------------------------------------------------*/
/* System */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'System';

insert into @Controls
            (ControlCode,         Description,                            ControlValue,  DataType,  Visible)
      select 'Version',           'Application Version',                   'V3',         'S',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
