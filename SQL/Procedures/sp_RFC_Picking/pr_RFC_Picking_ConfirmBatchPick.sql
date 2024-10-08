/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/09  RKC     pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmBatchPick_2: Passed TaskDetailId param to pr_Picking_ValidateSubstitution (BK-819)
  2021/11/23  RIA     pr_RFC_Picking_ConfirmBatchPick: Changes to retain user selected mode (BK-679)
  2021/10/22  RT      pr_RFC_Picking_ConfirmBatchPick: Validate UnitsToPick when User select Consolidate scan and confirm all picks at once
  2021/08/11  VS      pr_RFC_Picking_ConfirmBatchPick: Update the wave status in the defer mode (HA-3070)
  2020/06/25  RT      pr_RFC_Picking_ConfirmBatchPick: Update the CoO LookupCode instead of Description (CID-1824)
  2020/10/06  MS      pr_RFC_Picking_ConfirmBatchPick: Changes to suggest Skipped Picks at the end (HA-1449)
  2020/08/07  MS      pr_RFC_Picking_ConfirmBatchPick: Changes to generate & Print Temp Labels for Transfers while Picking (HA-1273)
  2020/05/15  TK      pr_RFC_Picking_ConfirmBatchPick: Use confirm picks proc for units picks & commented unnecessary code (HA-543)
  2019/09/03  RIA     pr_RFC_Picking_ConfirmBatchPick: Changes to validate CoO (CID-1015)
  2019/06/21  VS      pr_RFC_Picking_ConfirmBatchPick: Added Validation to Prevent picking to Cart positions (CID-586)
  2019/06/14  VS      pr_RFC_Picking_ConfirmBatchPick: User Scan Tote/Cart Position should be picked into Tote (CID-566)
  2018/09/12  TK      pr_RFC_Picking_ConfirmBatchPick: Do not validate scanned entity if user short picks (S2GCA-245)
  2018/07/18  TK      pr_RFC_Picking_ConfirmBatchPick: Alternate LPN is now postition so don't consider scanned LPN only
  2018/05/10  RV      pr_RFC_Picking_ConfirmBatchPick: Bug fixed to get valid SKU picked while setup multiple SKU to the same picklane (S2G-672)
  2018/04/17  TK      pr_RFC_Picking_ConfirmBatchPick: Changes to evaluate UnitsPicked based upon PickUoM
  2018/04/09  OK      pr_RFC_Picking_ConfirmBatchPick: Enhanced to use the ConfirmPicks procedure for UnitPicks (S2G-587)
  2018/04/05  TK      pr_RFC_Picking_ConfirmBatchPick: Validate if user in trying to pick into other than new LPN (S2G-542)
  2018/04/03  OK      pr_RFC_Picking_ConfirmBatchPick: Changes to do not override the UnitsCompleted value for LPN Picks (S2G-570)
  2018/03/21  OK      pr_RFC_Picking_ConfirmBatchPick: changed the caller for LPNPick procedure as per the signature (S2G-469)
  2018/03/20  AY      pr_RFC_Picking_ConfirmBatchPick_2 & pr_RFC_Picking_ConfirmBatchPick: Invalid SKU Error in Case Picking resolved (S2G-445)
  2018/02/05  TD      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmLPNPick:
  2017/06/30  CK      pr_RFC_Picking_ConfirmBatchPick: Log the additional audit record for Available quantity while short picking (FB-953)
  2017/05/24  SV      pr_RFC_Picking_ConfirmBatchPick: Bug Fix, for the emp orders, restricting the user not to pick the items into other than
  2017/05/16  SV      pr_RFC_Picking_ConfirmBatchPick: Bug fix for Batch Status progression based on NumPicks and NumPicksCompleted (HPI-1166)
  2017/04/12  TK      pr_RFC_Picking_ValidateTaskPicks, pr_RFC_Picking_ConfirmBatchPick & pr_RFC_Picking_ConfirmBatchPick_2
  2017/02/08  ??      pr_RFC_Picking_ConfirmBatchPick: Modified check to get PickType (HPI-PostGoLive)
  2017/02/07  VM/PK   pr_RFC_Picking_ConfirmBatchPick: Do not use pr_RFC_Picking_ConfirmBatchPick_2 (multi unit pick) for Namebadges (HPI-PostGoLive)
  2017/01/09  TK      pr_RFC_Picking_ConfirmBatchPick: Consider OrderCategory3 to validate Employee Labels (HPI-GoLive)
  2016/12/12  AY      pr_RFC_Picking_ConfirmBatchPick: Patch to handle unmerged TDs (HPI-GoLive)
  2016/12/05  AY      pr_RFC_Picking_ConfirmBatchPick: Bug fix handling picking from multi-sku LPN with same SKU repeated.
  2016/11/15  TD      pr_RFC_Picking_ConfirmBatchPick_2: Passing ToLPNId to pr_Tasks_MarkAsCompleted.
  2016/10/28  ??      pr_RFC_Picking_ConfirmBatchPick_2: Added check condition to use LPNDetailId, and more cosmetic changes (HPI-865)
  2016/10/12  PK      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick: Enabled MultipleOrderDetails for all PP type of waves.
                      pr_RFC_Picking_ConfirmBatchPick_2: Removed check condition (@ShortPick = 'Y') To Avoid Short picking
  2016/09/26  SV/MV   pr_RFC_Picking_ConfirmBatchPick: Short pick should be based on permission (HPI-763)
  2016/09/16  RV      pr_RFC_Picking_ConfirmBatchPick: Added parameter UserId to pr_Picking_SwapLPNsDataForSubstitution to Log AT for LPN Substitution (HPI-685)
  2016/08/18  TK      pr_RFC_Picking_ConfirmBatchPick: Added validation not to allow to pick into position which is associated for an employee (HPI-477)
  2016/08/10  PK      pr_RFC_Picking_ConfirmBatchPick: Added validation to not to allow to pick into different position other than the suggested one.
  2016/06/21  TK      pr_RFC_Picking_ConfirmBatchPick: Enhanced Short pick option to be permission based (NBD-595)
  2016/04/27  OK      pr_RFC_Picking_ConfirmBatchPick: Added the validations to restrict Invalid LPNTypes to Pick (NBD-391)
  2016/02/17  TD      pr_RFC_Picking_ConfirmBatchPick:NBD-172, validation to pictoLPNs based on the wavetypes.
  2016/01/29  TK      pr_RFC_Picking_ConfirmBatchPick: Pass in TaskId and TaskDetailId  to validate pallet as we will get that info from Confirm Bacth Picking (FB-597)
  2016/01/26  PK      pr_RFC_Picking_ConfirmBatchPick: Bug fix to not to update picking class on logical LPNs (LL-265/266).
  2015/12/11  SV      pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmUnitPick: Handle duplicate UPCs i.e. diff SKUs having same UPC (SRI-422)
  2015/12/04  RV      pr_RFC_Picking_ConfirmBatchPick: Validate to required Picking cart position while LPN picking using cart type (FB-483)
  2015/11/07  VM      pr_RFC_Picking_ConfirmBatchPick: Allow unit picking from Multi-SKU LPNs (FB-502)
  2015/11/03  TK      pr_RFC_Picking_ConfirmBatchPick & pr_RFC_Picking_DropPickedPallet:
  2015/10/19  AY      pr_RFC_Picking_ConfirmBatchPick: Calc Batch Status after LPNs and Pallets are updated to reflect most recent status (FB-457)
  2015/08/19  DK      pr_RFC_Picking_ConfirmBatchPick: Bug fix to update LPN Picking Class only when LPNType is not a PickLane (FB-330)
  2015/07/24  DK      pr_RFC_Picking_ConfirmBatchPick: Bug fix to allow picking in to scanned position(FB-242).
  2015/07/17  DK      pr_RFC_Picking_ConfirmBatchPick: Enhanced to allow picking on Pallets(FB-226).
  2015/07/16  TK      pr_RFC_Picking_ConfirmBatchPick: Consider PickUoM to Calculate Units Picked.
  2015/07/01  PK      pr_RFC_Picking_ConfirmBatchPick: Bug fix to allow short picking.
  2015/07/01  TK      pr_RFC_Picking_ConfirmBatchPick: Consider Multiples of ShipPack.
  2015/06/26  TK      pr_RFC_Picking_ConfirmBatchPick: Do not cancel the task detail, if short picked and just skip that detail.
  2015/06/18  VM/TK   pr_RFC_Picking_ConfirmBatchPick: Exclude replenish picking LPNs to transfer units to Cart
  2015/06/15  TK      pr_RFC_Picking_ConfirmBatchPick: Mark the LPN as picked only if all the details are Reserved.
                      pr_RFC_Picking_ConfirmBatchPick: Message must be proper if there is nothing to pick in the scanned zone for incomplete picks.
  2015/06/08  TK      pr_RFC_Picking_ConfirmBatchPick: if Task is not allocated do not consider Allocation Units &
  2015/03/23  TK      pr_RFC_Picking_ConfirmBatchPick: Avoid updating num picks completed for LPN picks as ConfirmLPNPick proc handles it.
  2015/03/20  TK      pr_RFC_Picking_ConfirmBatchPick: Need to consider @PickType for replenishments as LPN is directly moved to cart. Other fixes
  2015/03/17  TK      pr_RFC_Picking_ConfirmBatchPick: Do not transfer quantity if they are picking LPNs for Replenish batches
  2015/02/26  VM      pr_RFC_Picking_ConfirmBatchPick: Changes to allow substitution of LPNs even
  2015/02/04  VM      pr_RFC_Picking_ConfirmBatchPick: Changes for substitution for LPN picks
  2015/01/25  VM      pr_RFC_Picking_ConfirmBatchPick: Set UnitsPicked based on UseInnerPacks
  2015/01/20  TK      pr_RFC_Picking_ConfirmBatchPick: we are not allowing to Pick LPN other than Suggested LPn for now
  2015/01/13  VM      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick:
  2014/09/01  PK      pr_RFC_Picking_ConfirmBatchPick: Handling Packs.
  2014/07/24  TD      pr_RFC_Picking_ConfirmBatchPick:Changed params to handle with xmls, mark location as
  2014/07/18  TD      pr_RFC_Picking_ConfirmBatchPick:Changes to pick tasks based on the Location Level.
  2014/07/01  TD      pr_RFC_Picking_ConfirmBatchPick:Changes to pick one type of sku into one temp label
  2014/05/29  TD      pr_RFC_Picking_ConfirmBatchPick:Changes to validate TOLPN based on the control var,
  2014/05/28  PK      pr_RFC_Picking_ConfirmBatchPick: Calculating quantity based on the TaskSubType.
  2014/04/09  PV      pr_RFC_Picking_ConfirmBatchPick,pr_RFC_Picking_ConfirmLPNPick, pr_RFC_Picking_ConfirmUnitPick
  2014/02/28  NY      pr_RFC_Picking_ConfirmBatchPick : Added check to not to pick lpn from staging location
  2014/02/28  PK      pr_RFC_Picking_ConfirmBatchPick: Picking each pick into a new LPN temp label.
  2013/12/23  TD      pr_RFC_Picking_ConfirmBatchPick:update NumpicksCompleted.
  2013/12/19  TD      pr_RFC_Picking_ConfirmBatchPick: Changes to pass valid quantity to log in short Picking.
  2013/12/13  TD      pr_RFC_Picking_ConfirmBatchPick:Changes to mark LPN as lost if the user trying to shortpick
  2013/12/03  TD      pr_RFC_Picking_ConfirmBatchPick: bug fix: if the user picked the different lpn form suggested
  2013/11/27  TD      pr_RFC_Picking_ConfirmBatchPick: Fix- If the user did shoerPick for the invalid status LPN.
  2013/11/25  TD      pr_RFC_Picking_ConfirmBatchPick: Changes to avoid substution of LPN.
  2013/11/12  PK      pr_RFC_Picking_ConfirmBatchPick: Restricting users not to pick more than the Task Quantity.
  2013/10/04  PK      pr_RFC_Picking_ConfirmBatchPick: Passing in newly added params to pr_Picking_FindNextTaskToPickFromBatch.
  2013/10/03  PK      pr_RFC_Picking_ConfirmBatchPick: Updating UnitsPicked by mulitplying with UnitsPerInnerpack assuming user picked cases.
  2013/09/29  PK      pr_RFC_Picking_ConfirmBatchPick: Updating TaskDetails Completed Count with Pick Quantity on each pick.
  2013/09/26  PK      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick: Changes to suggest the Picks from tasks if the batch is allocated.
  2013/09/25  PK      pr_RFC_Picking_ConfirmBatchPick: Added TaskId and TaskDetailId.
  2103/09/06  TD      pr_RFC_Picking_ConfirmBatchPick:Changes to hide templabel, create a label internally.
  2013/04/04  PK      pr_RFC_Picking_ConfirmBatchPick: Passing in Partial Picks flag to pr_Picking_FindNextPickFromBatch
  2013/03/06  NY      pr_RFC_Picking_ConfirmBatchPick: Used the correct control SetBatchStatusToPickedOnNoMoreInv.
  2012/11/28  PK      pr_RFC_Picking_ConfirmBatchPick: Handling transaction controls.
  2012/11/20  PK      pr_RFC_Picking_ConfirmBatchPick: Reverted the changes and implemented the changes of
  2012/11/05  PK      pr_RFC_Picking_ConfirmBatchPick: Updating Batch status based on the control variable.
                      pr_RFC_Picking_ConfirmBatchPick: Handle short Pick of LPN
  2012/06/15  PK      pr_RFC_Picking_ConfirmBatchPick: Updating the generated LPN Temp Labels with the picking pallet.
                      pr_RFC_Picking_ConfirmBatchPick: Modified to Pick LPNs as well.
  2012/05/15  PK      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick: Migrated from FH related to LPN/Piece Pick.
  2011/12/05  VM      pr_RFC_Picking_ConfirmBatchPick: Allow ShortPick when there is no inventory eventhough suggested
  2011/11/28  PK      pr_RFC_Picking_ConfirmBatchPick: Update OrderHeaders - ShortPick field if ShortPicked.
  2011/11/19  AY      pr_RFC_Picking_ConfirmBatchPick: Prevent picking to Picklane!
  2011/11/11  TD      pr_RFC_Picking_ConfirmBatchPick(pr_Picking_ConfirmUnitPick),
  2011/10/26  AY      pr_RFC_Picking_ConfirmBatchPick: Prevent Over picking!
  2011/10/12  PK      pr_RFC_Picking_ConfirmBatchPick: Handling UPC/SKU.
  2011/09/11  TD      Added @ShortPick  parameter to pr_RFC_Picking_ConfirmBatchPick.
  2011/08/26  PK      pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_GetBatchPick
  2011/08/04  DP      pr_RFC_Picking_ConfirmBatchPick: Implemented the procedure
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ConfirmBatchPick') is not null
  drop Procedure pr_RFC_Picking_ConfirmBatchPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ConfirmBatchPick:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ConfirmBatchPick
  (@xmlInput             xml,
   @xmlResult            xml  output)
As
  declare @DeviceId                            TDeviceId,
          @UserId                              TUserId,
          @BusinessUnit                        TBusinessUnit,
          @PickBatchNo                         TPickBatchNo,
          @vWaveType                           TTypeCode,
          @PickZone                            TZoneId,
          @PickTicket                          TPickTicket,
          @SuggestedLPNPickingClass            TPickingClass,
          @PickedLPNPickingClass               TPickingClass,
          @PickingPallet                       TPallet,
          @vPalletType                         TTypeCode,
          @OrderDetailId                       TRecordId,
          @FromSKU                             TSKU,
          @FromLPN                             TLPN,
          @vFromLPNId                          TRecordId,
          @FromLPNId                           TRecordId,
          @vFromLPNDetailId                    TRecordId,
          @LPNDetailId                         TRecordId,
          @CoO                                 TCoO,
          @PickType                            TLookUpCode,
          @OrgPickType                         TLookUpCode,
          @TaskId                              TRecordId,
          @vTaskId                             TRecordId,
          @TaskDetailId                        TRecordId,
          @ToLPN                               TLPN,
          @ScannedEntity                       TEntityKey,
          @SKUPicked                           TSKU,
          @LPNPicked                           TLPN,
          @PickUoM                             TUoM,
          @vShipPack                           TInteger,
          @UnitsPicked                         TInteger,
          @PickedFromLocation                  TLocation,
          @ShortPick                           TFlag,
          @EmptyLocation                       TFlags,
          @ConfirmEmptyLocation                TFlags,
          @DestZone                            TLookUpCode,
          @Operation                           TOperation,
          @PickingType                         TDescription,

          @ValidPickZone                       TZoneId,
          @LPNLocationId                       TLocation,
          @PickedLocationId                    TLocation,
          @LPNLocation                         TLocation,
          @LPNPalletId                         TPallet,
          @SKUId                               TRecordId,
          @PickedSKUId                         TRecordId,
          @PickedLPNId                         TRecordId,
          @vOrderSKUId                         TRecordId,
          @LPNSKUId                            TSKU,
          @LPNSKU                              TSKU,
          @LPNInnerPacks                       TInteger,
          @LPNQuantity                         TInteger,
          @vLPNAvailableQty                    TInteger,
          @ValidFromLPN                        TLPN,
          @vToLPNAlternateLPN                  TLPN,
          @vLPNLotNo                           TLot,
          @vLPNType                            TTypeCode,
          @vToLPNStatus                        TStatus,
          @vToLPNNumLines                      TCount,
          @vToLPNType                          TTypeCode,
          @vToLPNPalletId                      TRecordId,
          @vLPNStatus                          TStatus,
          @ValidToLPN                          TLPN,
          @vToLPNId                            TRecordId,
          @ToLPNOrderId                        TRecordId,
          @ToLPNPalletId                       TRecordId,
          @ToLPNType                           TTypeCode,
          @ToLPNStatus                         TStatus,
          @PickingPalletId                     TRecordId,
          @PickedLPNSKUId                      TRecordId,
          @NextLPNToPickFrom                   TLPN,
          @NextLPNIdToPickFrom                 TRecordId,
          @NextLPNDetailId                     TRecordId,
          @NextLocationToPick                  TLocation,
          @SKUToPick                           TSKU,
          @UnitsToPick                         TInteger,
          @vUnitsPicked                        TInteger,
          @ValidPickTicket                     TPickTicket,
          @OrderId                             TRecordId,
          @vOrderId                            TRecordId,
          @OrderStatus                         TStatus,
          @ValidPickBatchNo                    TPickBatchNo,
          @PickBatchId                         TRecordId,
          @ValidPickingPallet                  TPallet,
          @vBusinessUnit                       TBusinessUnit,
          @ActivityType                        TActivityType,
          @vBatchStatus                        TStatus,
          @vSetBatchStatusToPickedOnNoMoreInv  TFlag,
          @vPickBatchId                        TRecordId,
          @vLDReservedQty                      TQuantity,
          @vNumPicksCompleted                  TCount,
          /* Tasks Related */
          @vTaskLPNId                          TRecordId,
          @vTaskDetailSKUId                    TRecordId,
          @vTaskDetailStatus                   TStatus,
          @vTaskSubType                        TTypeCode,
          @vIsTaskAllocated                    TFlag,
          @vValidTempLPNId                     TRecordId,
          @vTaskDestZone                       TZoneId,
          @vTaskLocationId                     TRecordId,
          @vTaskPickZone                       TZoneId,
          @vTaskCategory1                      TCategory,

          /* Substitution related */
          @vAllowSubstitution                  TFlag,
          @vOrgFromLPNId                       TRecordId,
          @vOrgValidFromLPN                    TLPN,
          @ValidLPNToSubstitute                TLPN,
          @vSubstituteLPNId                    TRecordId,
          @vSubstituteLPN                      TLPN,

          /* @OrderDetailId                    TRecordId, */
          @UnitsAuthorizedToShip               TInteger,
          @UnitsAssigned                       TInteger,
          @vUnitsToAllocate                    TInteger,
          @vUnitsPerInnerPack                  TInteger,
          @ConfirmBatchPickMessage             TVarchar,
          @LocToPick                           TLocation,
          @vPickType                           TLookUpCode,

          @vWarehouse                          TWarehouse,
          @vGenerateTempLabel                  TControlValue,
          @vConfirmedAllCases                  TFlags,

          @vTDUnitsCompleted                   TQuantity,
          @vTDUnitsToPick                      TQuantity,
          @vTDUnitToPickForOD                  TQuantity,

          @vBatchType                          TTypeCode,
          @vAccount                            TCustomerId,

          @PickGroup                           TPickGroup,
          @PickMode                            TControlValue,

          @vIsBatchAllocated                   TFlag,
          @vIsTempLabelGenerated               TFlag,
          @vPrintLabel                         TFlag,
          @vPickMultiSKUCategory               TCategory,
          @vIsMultiSKUTote                     TFlags,
          @vAllowPickMultipleSKUsintoLPN       TControlValue,
          @vCCOperation                        TDescription,
          @xmlRulesData                        TXML,
          @vValidToLPNTypesToPick              TDescription,
          @ttPickedLPNs                        TEntityKeysTable,
          @vPickPosition                       TLPN,
          @vNote1                              TDescription,
          @vNote2                              TDescription,
          @vCategory3                          TCategory,

          @vActivityLogId                      TRecordId,
          @vConfirmBatchPick                   TFlag,
          @SKUIdPicked                         TRecordId,

          @vxmlConfirmLPNPickInput             TXML,
          @vRulesDataXML                       TXML,
          @vResultXML                          TXML,
          @vDeviceId                           TDeviceId,
          @ttTaskPicksInfo                     TTaskDetailsInfoTable;

  declare @vReturnCode                         TInteger,
          @vMessageName                        TMessageName,
         -- @CCMessage                           TDescription,
          @Message                             TDescription,
          @xmlResultvar                        TVarchar;
begin /* pr_RFC_Picking_ConfirmBatchPick */
begin try
  SET NOCOUNT ON;

  if (@xmlInput is not null)
    select @DeviceId             = Record.Col.value('DeviceId[1]',             'TDeviceId'),
           @UserId               = Record.Col.value('UserId[1]',               'TUserId'),
           @BusinessUnit         = Record.Col.value('BusinessUnit[1]',         'TBusinessUnit'),
           @PickBatchNo          = nullif(Record.Col.value('PickBatchNo[1]',   'TPickBatchNo'), ''),
           @PickZone             = nullif(Record.Col.value('PickZone[1]',      'TZoneId'), ''),
           @PickTicket           = nullif(Record.Col.value('PickTicket[1]',    'TPickTicket'), ''),
           @PickingPallet        = Record.Col.value('PickingPallet[1]',        'TPallet'),
           @OrderDetailId        = Record.Col.value('OrderDetailId[1]',        'TRecordId'),
           @FromSKU              = Record.Col.value('FromSKU[1]',              'TSKU'),
           @FromLPN              = Record.Col.value('FromLPN[1]',              'TLPN'),
           @FromLPNId            = Record.Col.value('FromLPNId[1]',            'TRecordId'),
           @LPNDetailId          = Record.Col.value('FromLPNDetailId[1]',      'TRecordId'),
           @CoO                  = Record.Col.value('CoO[1]',                  'TCoO'),
           @PickType             = Record.Col.value('PickType[1]',             'TTypeCode'),
           @TaskId               = Record.Col.value('TaskId[1]',               'TRecordId'),
           @TaskDetailId         = Record.Col.value('TaskDetailId[1]',         'TRecordId'),
           @ToLPN                = nullif(Record.Col.value('ToLPN[1]',         'TLPN'), ''),
           @ScannedEntity        = nullif(Record.Col.value('ScannedEntity[1]', 'TEntityKey'), ''),
           @SKUPicked            = nullif(Record.Col.value('SKUPicked[1]',     'TSKU'), ''),
           @LPNPicked            = Record.Col.value('LPNPicked[1]',            'TLPN'),
           @UnitsPicked          = Record.Col.value('UnitsPicked[1]',          'TInteger'),
           @PickedFromLocation   = Record.Col.value('PickedFromLocation[1]',   'TLocation'),
           @PickUoM              = Record.Col.value('PickUoM[1]',              'TUoM'),
           @ShortPick            = Record.Col.value('ShortPick[1]',            'TFlag'),
           @EmptyLocation        = Record.Col.value('LocationEmpty[1]',        'TFlags'),
           @ConfirmEmptyLocation = Record.Col.value('ConfirmLocationEmpty[1]', 'TFlags'),
           @DestZone             = Record.Col.value('DestZone[1]',             'TLookUpCode'),
           @Operation            = Record.Col.value('Operation[1]',            'TDescription'),
           @PickingType          = Record.Col.value('PickingType[1]',          'TDescription'),
           @PickGroup            = Record.Col.value('PickGroup[1]',            'TPickGroup'),
           @PickMode             = Record.Col.value('PickMode[1]',             'TControlValue')
    from @xmlInput.nodes('ConfirmBatchPick') as Record(Col);

  /* Setup DeviceId */
  select @vDeviceId = @DeviceId + '@' + @UserId;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @vDeviceId,
                      @TaskId, @PickingPallet, 'TaskId-Pallet',
                      @Value1 = @PickBatchNo, @Value2 = @FromLPN, @Value3 = SKUPicked, @Value4 = @UnitsPicked, @Value5 = @PickedFromLocation,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Make null if empty strings are passed */
  select @ActivityType       = 'BatchUnitPick' /* BatchUnitPick */,
         @vConfirmedAllCases = 'N' /* No */,
         @vIsMultiSKUTote    = 'N' /* No */,
         @vNumPicksCompleted = 0,
         @ShortPick          = coalesce(@ShortPick, 'N'),
         @PickMode           = coalesce(@PickMode, 'Consolidated'),
         @vAllowSubstitution = dbo.fn_Controls_GetAsBoolean('BatchPicking', 'AllowSubstitution', 'N'/* No */, @BusinessUnit, @UserId);

  /* Validate scanned entity and get the SKU/LPN/Picked from location */
  /* If user short picks, then there is not need to validate scanned entity as user may short pick without scanning any entity */
  if (@ShortPick = 'N'/* No */)
    exec pr_Picking_ValidateScannedEntity @xmlInput, @SKUPicked output, @LPNPicked output, @PickedFromLocation output, @vMessageName output;

  /* Validate PickBatchNo if given by user */
  if (@PickBatchNo is not null)
    exec pr_Picking_ValidatePickBatchNo @PickBatchNo,
                                        @PickingPallet,
                                        @ValidPickBatchNo output,
                                        @vWaveType        output;

  /* Verify whether the given PickZone is valid, if provided only */
  if (@PickZone is not null)
    exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  /* Validating the Pallet */
  exec pr_Picking_ValidatePallet @PickingPallet, 'U' /* Pallet in Use */,
                                 @PickBatchNo,
                                 @ValidPickingPallet output,
                                 @TaskId output, @TaskDetailId output;

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null) goto ErrorHandler;

  /* Verify whether the given LPN is the same as suggested */
  /* Verify whether the given LPN Location is the proper, as per the system */

  /* select LPN Information */
  select @LPNLocationId  = LocationId,
         @LPNPalletId    = PalletId,
         @vFromLPNId     = LPNId,
         @LPNSKUId       = SKUId,
         @LPNSKU         = SKU,
         @LPNInnerPacks  = InnerPacks,
         @SuggestedLPNPickingClass
                         = PickingClass,
         @LPNQuantity    = Quantity,
         @vLPNAvailableQty
                         = Quantity - ReservedQty,
         @ValidFromLPN   = LPN,
         @vLPNType       = LPNType,
         @LPNLocation    = Location,
         @vLPNStatus     = Status,
         @vBusinessUnit  = BusinessUnit,
         @vWarehouse     = DestWarehouse,
         @PickedLPNId    = LPNId -- @PickedLPN is nothing but the LPN the inventory is picked from
  from vwLPNs
  where ((LPNId        = @FromLPNId) and
         (BusinessUnit = @BusinessUnit));

  /* Get the Substitute LPN info */
  select @vSubstituteLPNId  = LPNId,
         @vSubstituteLPN    = LPN
  from LPNs
  where (LPN = @LPNPicked) and
        (BusinessUnit = @BusinessUnit)

  /* Get Pallet info */
  select @PickingPalletId = PalletId,
         @vPalletType     = PalletType
  from Pallets
  where (Pallet       = @PickingPallet) and
        (BusinessUnit = @BusinessUnit);

  /* We want to give the option to the user to scan LPN or SKU for Unit Picking, hence we need to map it correctly now */

  /* Get SKUId of the scanned SKUs */
  if (@SKUPicked is not null)
    select @PickedSKUId = SS.SKUId,
           @SKUIdPicked = SS.SKUId,
           @SKUPicked   = SS.SKU
    from dbo.fn_SKUs_GetScannedSKUs (@SKUPicked, @BusinessUnit) SS
      join LPNDetails LD on (LD.LPNId = @vFromLPNId);

  /* Get the LookupCode instead of Description to update on the Details */
  select @CoO = LookUpCode
  from vwLookUps
  where ((LookUpCode         = @CoO)  or
         (LookUpDescription  = @CoO)) and
         (BusinessUnit       = @BusinessUnit) and
         (LookUpCategory     = 'CoO');

  /* Validating the SKU */
  if (@SKUPicked <> @FromSKU)
     set @vMessageName = 'SKUIsInvalid';
  else
  /* Validating whether User has permissions to do short pick. */
  if ((@ShortPick = 'Y'/* Yes */) and
    (dbo.fn_Permissions_IsAllowed(@UserId, 'RFAllowShortPick') <> '1' /* 1 - True, 0 - False */))
    select @vMessageName = 'CannotShortPick';
  else
  /* Validate if user tries to short pick a Consolidate quantity, as it contains multiple detail lines */
  if (@ShortPick = 'Y'/* Yes */) and
     (@PickMode = 'Consolidated')
    set @vMessageName = 'Picking_ConsolidatePick_CannotShortPick';

  if (@vMessageName is not null) goto ErrorHandler;

  /* temporary, for the moment, do not allow substitution when picking from multi-SKU LPNs - we need to re-evaluate this */
  if (@LPNSKUId is null) set @vAllowSubstitution = 'N';

  /* If Units are from Multiple SKU line LPNs (not logical - logical will have one LPN each for each SKU),
     We need to get the SKU from LPNDetails */
  if (@LPNSKU is null) and
     (@PickType = 'U' /* Units */) and  --> To be safe
     (@vLPNType <> 'L' /* Logical */)   -- May be multi-SKU LPN (not logical)
    begin
      /* If the same SKU is repeated then we should try to get the LPNDetail closest to the qty being picked */
      select @vFromLPNDetailId = LPNDetailId,
             @LPNSKUId         = SKUId,
             @LPNSKU           = SKU,
             @LPNInnerPacks    = InnerPacks,
             @LPNQuantity      = Quantity
      from vwLPNDetails
      where (LPNId     = @FromLPNId) and
            (SKU       = @SKUPicked) and -- change this to a function to send FromLPNId, SKUPicked, TaskDetailId and find LPN Detail
            (Quantity >= @UnitsPicked)
      order by Quantity;

      /* If we are not able to find the LPN Detail above - which shoulfn't happen, then use the old code - this is just
         to make sure the new code introduced above is working fine */
      if (@vFromLPNDetailId is null)
        select @LPNSKUId         = SKUId,
               @LPNSKU           = SKU,
               @LPNInnerPacks    = InnerPacks,
               @LPNQuantity      = Quantity
        from vwLPNDetails
        where (LPNId     = @FromLPNId) and
              (SKU       = @SKUPicked);
    end;

  /* Below task sku id and this skuid are validated, hence there is no issue, if users scans another existing sku
     on the same LPN */

  /* If user has scanned cart position, but there is a tote in it, then pick to the tote instead */
  select @ToLPN = TL.LPN
  from LPNs CPL join LPNs TL on (CPL.AlternateLPN = TL.LPN) /* Cart Postion.AlternateLPN = Tote.LPN */
  where (CPL.LPN          = @ToLPN) and
        (CPL.LPNType      = 'A' /* Cart Position */) and
        (CPL.Pallet       = @ValidPickingPallet) and
        (CPL.BusinessUnit = @BusinessUnit);

  /* We might need to add conditions here */
  select @ToLPN              = LPN,
         @vToLPNType         = LPNType,
         @vToLPNPalletId     = PalletId,
         @vToLPNAlternateLPN = AlternateLPN
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@ToLPN, @BusinessUnit, 'LTU' /* Options */));

  /* select OrderId, SKUId to validate while picking and placing
      the Order into LPN */
  select @vOrderId         = OD.OrderId,
         @vOrderSKUId      = OD.SKUId,
         @vUnitsToAllocate = OD.UnitsToAllocate
  from OrderDetails OD
  where (OD.OrderDetailId = @OrderDetailId);

  /* Substitution
     - Assumption - User scans substituted LPN only, not SKU even when to pick units from LPN */
  /* For Units picks, RF sends scanned LPN/SKU in @SKUPicked not @LPNPicked, hence set @LPNPicked as
     user might be scanning substituted LPN and we are getting it in @SKUPicked
     -- Do this only when picking units from LPN and not from Picklane */
  if ((@vLPNType <> 'L' /* <-From LPN Type - LPN Pick or Units from LPN pick */) and (@ShortPick = 'N'/* No */))
    begin
      if (@LPNPicked is null) and (@SKUPicked is not null) and
         (@SKUPicked <> @ValidFromLPN) and (@SKUPicked <> @LPNSKU /* FromLPN SKU */)
        select @LPNPicked = @SKUPicked;

      /* 1. VM: Now, any LPN Pick or Units from LPN pick are eligible for Substitution - (2015/2/25) */
      if (@ValidFromLPN /* Suggested */ <> @LPNPicked /* Scanned */) and (@vAllowSubstitution = 'Y' /* Yes */)
          -- and (@LPNSKU <> @LPNPicked) - What if they scan SKU. Can be worked on later.
        begin
          exec pr_Picking_ValidateSubstitution @FromLPNId, @vSubstituteLPNId, @TaskDetailId, @PickMode, @ValidLPNToSubstitute output;

          if (@ValidLPNToSubstitute is not null)
            begin
              exec pr_Picking_SwapLPNsDataForSubstitution @ValidFromLPN, @ValidLPNToSubstitute, @TaskDetailId /* Picking Task detail */, @UserId;

              /* Keep original data - can be used for future - may be for Audit trail */
              select @vOrgFromLPNId        = @FromLPNId,
                     @vOrgValidFromLPN     = @ValidFromLPN;
                     --@vOrgFromLPNDetailId  = @LPNDetailId;

              /* Get Substituted LPN Information further validations (regular for picking)
                 after it is confirmed as valid candiate for substitution */
              select @FromLPNId      = LPNId, -- This is for further validations and process
                     @LPNLocationId  = LocationId,
                     @LPNPalletId    = PalletId,
                     @LPNSKUId       = SKUId,
                     @LPNSKU         = SKU,
                     @LPNInnerPacks  = InnerPacks,
                     @LPNQuantity    = Quantity,
                     @ValidFromLPN   = LPN,
                     @vLPNType       = LPNType,
                     @LPNLocation    = Location,
                     @vLPNStatus     = Status,
                     @vBusinessUnit  = BusinessUnit,
                     @vWarehouse     = DestWarehouse,
                     @PickedLPNId    = LPNId -- @PickedLPN is nothing but the LPN the inventory is picked from
              from vwLPNs
              where ((LPN          = @ValidLPNToSubstitute) and
                     (BusinessUnit = @BusinessUnit));
            end
          else
            begin
              /* Though, pr_Picking_ValidateSubstitution throws an error. Handling validation once again here, just in case */
              set @vMessageName = 'Substitution_LPNNotAValidCandidate'; /* we are not allowing to Pick LPN other than Suggested LPn for now */

              /* If Error, then return Error Code/Error Message */
              if (@vMessageName is not null) goto ErrorHandler;
            end
        end
    end /* Substitution */

  /* Get the Task Details */
  select @vTDUnitsToPick        = UnitsToPick,
         @vTaskLPNId            = LPNId,
         @vTaskDetailSKUId      = SKUId,
         @vIsTempLabelGenerated = IsLabelGenerated,
         @vTaskDestZone         = DestZone,
         @vPickMultiSKUCategory = 'PickMultiSKUIntoSameTote_' + coalesce(DestZone, ''),
         @vTaskLocationId       = LocationId,
         @vPickPosition         = PickPosition
  from TaskDetails
  where (TaskId       = @TaskId) and
        (TaskDetailId = @TaskDetailId) and
        (BusinessUnit = @BusinessUnit);

  /* In some cases, for what ever reason we are not merging TaskDetails together and hence users get an error
     that the AllocatedUnits > ToPickQty i.e. LD.Quantity > TD.UnitsToPick. Below is patch until core issue
     is fixed. For example if we have two task Details of 35 and 3 units, but only 1 LD of 38 units we should skip
     this error even if we are picking only the TD of 35 units because in the end we will pick all 38. Therefore
     we are getting the total To pick for OD and checking if exceeds the LD qty instead of verifying directly with TD.UnitsToPick */
  select @vTDUnitToPickForOD = sum(UnitsToPick)
  from TaskDetails
  where (TaskId = @TaskId) and
        (OrderDetailId = @OrderDetailId) and
        (Status not in ('C', 'X'));

  /* Get the Task Info */
  select @vTaskId          = T.TaskId,
         @vTaskSubType     = T.TaskSubType,
         @vIsTaskAllocated = T.IsTaskAllocated,
         @vWaveType        = PB.BatchType,
         @vTaskPickZone    = T.PickZone,
         @vTaskCategory1   = T.TaskCategory1
  from Tasks T
    join PickBatches PB on (PB.BatchNo = T.BatchNo)
  where (T.TaskId       = @TaskId) and
        (T.BusinessUnit = @BusinessUnit);

  if (@vTaskSubType = 'CS') and
     (@ToLPN        = 'LocationLPN')
    begin
      select @vTDUnitsToPick = sum(Quantity - coalesce(UnitsCompleted, 0))
      from TaskDetails
      where (TaskId = @TaskId) and
            (LPNId  = @vTaskLPNId) and
            (SKUId  = @vOrderSKUId);
    end

  /* If the user was asked to Pick the LPN, but only decides to pick part of it then
     change it to a Unit Pick */
  if ((@vWaveType <> 'RU' /* Replenish Units */) and
      (((@PickType = 'L' /* LPN Pick */) and ((@UnitsPicked < @LPNQuantity) or (@vPalletType = 'C' /* Cart */))) or
      (@vLPNType = 'L' /* picklane */)))
    select @OrgPickType = @PickType,
           @PickType = 'U' /* Unit Pick */;

  /* Set value here to that confirmed all the units at a time or not
    there is no point if the task subtype is unit pick and the user scans ALL.
    because we will not generate labels for unit pick sub task type  */
  if (@ToLPN in ('TaskDetail', 'LocationLPN')) and (@vTaskSubType <> 'U' /* unitpick */)
    begin
      select @vConfirmedAllCases = 'Y' /* Yes */,
             @ValidToLPN         = @ToLPN
    end

  /* ToLPN: Get control variables */
  select @vGenerateTempLabel = dbo.fn_Controls_GetAsString('BatchPicking_' + @vWaveType, 'GenerateTempLabel', 'N',
                                                           @BusinessUnit, @UserId),
         @vPrintLabel        = dbo.fn_Controls_GetAsString('BatchPicking_' + @vWaveType, 'PrintLabel', 'N',
                                                           @BusinessUnit, @UserId);

  /* If the user forced to pick all temp labels at one time then we no need to get to lpn details */
  if (@vConfirmedAllCases <> 'Y')
    begin
      /* Here we need to create a new LPN if the User does not scan the ToLPN and  Generatetemp Label is Yes */
      if ((@ShortPick  = 'N' /* No */) and
         (coalesce(@ToLPN, '') = '')  and
         (@PickType = 'U' /* Unit Pick */) and
         (@vGenerateTempLabel in ('C', 'S' /* Carton, Ship Carton */)) and
         (@vIsTempLabelGenerated <> 'Y' /* Yes */))
        begin
          exec @vReturnCode = pr_LPNs_Generate @vGenerateTempLabel, /* @LPNType  - C or S */
                                               1,                   /* @NumLPNsToCreate   */
                                               null,                /* @LPNFormat         */
                                               @vWarehouse,
                                               @BusinessUnit,
                                               @UserId,
                                               @vToLPNId     output,
                                               @ToLPN        output;
        end

      /* Set @ToLPN as last cart position (desc by modifieddate) used by the order earlier */
      if ((@PickType = 'L' /* LPN Pick */) or (@OrgPickType = 'L' /* LPN */)) and (@ShortPick = 'N' /* No */) and
         (/* @vXferUnitsFromFullLPNToCartPosition */ 'Y' = 'Y' /* Yes */) and (@vPalletType = 'C' /* Picking Cart */)
        begin
          /* Get the cart position for which the current order is taken to or set it to first cart position, which is empty */
          if (@ToLPN is null)
            select @ToLPN = LPN
            from LPNs
            where (PalletId = @PickingPalletId) and
                  (OrderId  = @vOrderId)        and
                 (LPNType  = 'A' /* Cart */) /* select the cart postion instead of LPN which is picked onto a cart */
            order by ModifiedDate desc  /* to get the last cart position used by order */;

          /* if the order does not associate with any cart position, pick the units to any new cart position */
          if (@ToLPN is null)
            select top 1 @ToLPN = LPN
            from LPNs
            where (PalletId = @PickingPalletId) and
                  (Status   = 'N' /* New */)
            order by LPN
        end

      /* Get the npick to LPN details here
         User may scan tote/ TempLabel LPN number / UCCBarcode of the LPN ...*/
      select @vToLPNId           = LPNId,
             @ValidToLPN         = LPN,
             @vToLPNStatus       = Status,
             @vToLPNNumLines     = NumLines,
             @ToLPNPalletId      = PalletId,
             @ToLPNOrderId       = OrderId,
             @SKUId              = SKUId,
             @ToLPNType          = LPNType,
             @vToLPNAlternateLPN = AlternateLPN,
             @ToLPNStatus        = Status
      from LPNs
      where (((LPN         = @ToLPN) or
              (UCCBarcode  = @ToLPN))and
             (BusinessUnit = @BusinessUnit));

      /* we need to ensure that user scans the pre generated labels for
         the Case/LPN task subtypes
         So we need to get the LPNId from the LPNTasks to validate */
      if (@vIsTempLabelGenerated = 'Y' /* yes */)
        begin
          select @vValidTempLPNId = LPNId
          from LPNTasks
          where (TaskDetailId = @TaskDetailId) and
                (LPNId        = @vToLPNId);
        end
    end

  /* Todo: Need to validate based on LOT as well */
  /* User will pick all cases at once and will confirm one time, so they will
     scan as ALL instead of each label */
  if (@LPNPicked is not null)
    select @PickedLPNId           = LPNId,
           @PickedSKUId           = SKUId,
           @PickedLocationId      = LocationId,
           @PickedLPNPickingClass = PickingClass
    from LPNs
    where ((LPN          = @LPNPicked) and
           (SKUId        = coalesce(@PickedSKUId, SKUId)) and /* There might be multiple SKUs setup with same picklane */
           (BusinessUnit = @BusinessUnit));

  if (@PickTicket is not null)
    select @ValidPickTicket = PickTicket
    from OrderHeaders
    where (PickTicket   = @PickTicket) and
          (BusinessUnit = @BusinessUnit);

  /* Get whether the batch is allocated or not */
  select @vIsBatchAllocated = IsAllocated,
         @vPickBatchId      = WaveId
  from PickBatches
  where (BatchNo      = @ValidPickBatchNo) and
        (BusinessUnit = @BusinessUnit);

  /* Get the UnitsPerInnerPack of SKU */
  select @vUnitsPerInnerPack = coalesce(UnitsPerPackage, 0),
         @vLDReservedQty     = Quantity
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Get the SKU ShipPack */
  select @vShipPack = ShipPack
  from SKUs
  where (SKUId = @PickedSKUId);

  /* Build the data for evaluation of rules */
  select @xmlRulesData = '<RootNode>' +
                           dbo.fn_XMLNode('WaveType',      @vWaveType) +
                           dbo.fn_XMLNode('AlternateLPN',  @vToLPNAlternateLPN) +
                           dbo.fn_XMLNode('TaskSubType',   @vTaskSubType) +
                           dbo.fn_XMLNode('TaskPickZone',  @vTaskPickZone) +
                           dbo.fn_XMLNode('TaskCategory1', @vTaskCategory1) +
                        '</RootNode>'

  /* Return the value of valid ToLPNTypes to pick into based on the batchtype,
    if it returns value as ALL then there is no need to validate   */
  exec pr_RuleSets_Evaluate 'ValidLPNTypesToPickTo', @xmlRulesData, @vValidToLPNTypesToPick output;

  /* Compute the real UnitsPicked as the user entered PickedQty could be Cases or Units */
  select @vUnitsPicked = case when (@ShortPick = 'Y')    then 0 /* Zero */
                              when (@vTaskSubType = 'U' /* Unit Pick */) and (@PickUoM = 'IP' /* InnerPacks */) then (@UnitsPicked * coalesce(nullif(@vShipPack, 0), 1))
                              when (@vTaskSubType = 'U' /* Unit Pick */) and (@PickUoM = 'CS' /* InnerPacks */) then (@UnitsPicked * coalesce(nullif(@vUnitsPerInnerPack, 0), 1))
                              when (@vTaskSubType = 'U' /* Unit Pick */) then @UnitsPicked
                              when (@vTaskSubType = 'L' /* LPN Pick  */) and ('N' /* UseInnerPacks  - Use control var */ = 'N') then @UnitsPicked
                              else (@UnitsPicked * coalesce(nullif(@vUnitsPerInnerPack, 0), 1))
                         end;

  /* Calculate and get the Summarized counts to Process the validations and update with appropriate summarized counts
     when we get Multiple OrderDetails with same SKU */
  if (@PickMode = 'Consolidated')
    begin
      /* when picking in consolidated more, get all details of scanned SKU and confirm all the picks at once */
      insert into @ttTaskPicksInfo(PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, PalletId, FromLPNId, FromLPNDetailId,
                                   FromLocationId, TempLabelId, TempLabelDtlId, QtyPicked, ToLPNId)
        select PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, @PickingPalletId, LPNId, LPNDetailId,
               LocationId, TempLabelId, TempLabelDetailId, Quantity, @vToLPNId
        from TaskDetails
        where (TaskId     = @TaskId) and
              (OrderId    = @vOrderId) and
              (SKUId      = @SKUIdPicked) and
              (LPNId      = @PickedLPNId) and
              (coalesce(TempLabelId, '') = coalesce(@vValidTempLPNId, TempLabelId, '')) and
              (Status not in ('C' /* Completed */, 'X' /* Cancelled */));

      /* Get the sum UnitsToAllocate of a SKU when Picking in Consolidate Mode */
      select @vUnitsToAllocate = sum(OD.UnitsToAllocate)
      from OrderDetails OD
      where (OD.OrderId = @vOrderId) and
            (OD.SKUId   = @SKUIdPicked);

      /* Get the summary of all the picks being confirmed */
      select @vTDUnitsToPick = sum(coalesce(QtyPicked, 0)),
             @vUnitsPicked   = @UnitsPicked
      from @ttTaskPicksInfo;
    end

  if (@vTaskDestZone = 'PTL') and (@vTaskSubType = 'U' /* Unit pick */)
    begin
      /* Get the control value to pick the multiple SKUs into single tote or not */
      select @vAllowPickMultipleSKUsintoLPN = dbo.fn_Controls_GetAsString('BatchPicking', @vPickMultiSKUCategory, 'Y'/* Default -Y */,
                                                                          @BusinessUnit, @UserId);

      if (@vAllowPickMultipleSKUsintoLPN = 'N' /* No */)
         /* check if the  user picked other SKUs into the scanned tote/label  */
        if (exists (select * from
                    LPNDetails
                    where (LPNId = @vToLPNId and
                          (SKUId <> @PickedSKUId))))
          select @vIsMultiSKUTote = 'Y' /* Yes */;
    end

  /* As we know that, for short pick there is no need to scan any thing like sku,location..*/
  if (@ShortPick = 'N')
    begin
      /* Why to validate From LPN only when Short Pick = 'N' - Please see below comments in else condition (ShortPick = 'Y') */
      if (@ValidFromLPN is null)
        set @vMessageName = 'InvalidFromLPN';
      else
      if (@PickMode = 'Consolidated') and
         (@vUnitsPicked <> @vTDUnitsToPick)
        begin
          select @vMessageName = 'Picking_ConsolidatePick_CannotPickPartialUnits',
                 @vNote1       = dbo.fn_Str(@vTDUnitsToPick);
        end
      else
      /* If Picking to a cart and there is no ToLPN given, then raise an error. ToLPN is required for unit picking */
      if (nullif(@ToLPN, 'LocationLPN') is null) and
         (nullif(@ValidToLPN, 'LocationLPN') is null) and
         (@vPalletType ='C' /* Picking Cart */) and
         (@PickType = 'U' /* Unit Pick */)
        set @vMessageName = 'InvalidToLPN';
      else
      /* Picking LPNs to Pallet, would not have ToLPN, so skip the validation in that scenario */
      if ((((@ToLPN is not null) and (@ValidToLPN is null)) or
           ((@vGenerateTempLabel = 'N') and (@ValidToLPN is null))) and
          (@vConfirmedAllCases = 'N' /* No */) and
          ((@PickType <> 'L') or (@vPalletType ='C' /*Picking Cart */)))
        set @vMessageName = 'InvalidToLPN';
      /* If to LPN is Cart position then ensure that the picking Pallet should be CartType and that should be on same pallet */
      if ((@vToLPNType = 'A' /* Cart Position */) and (@vPalletType <> 'C' /* Picking Cart */))
        set @vMessageName = 'Picking_ScanToCartPositionInvalid';
      else
      /* Validate if user scanned different Cart Position than Picking cart */
      if ((@vToLPNType = 'A' /* Cart Position */) and
          (coalesce(@vToLPNPalletId, 0) <> @PickingPalletId))
        set @vMessageName = 'ScannedPositionFromAnotherCart';
      else
      /* Validate if user scanned a Tote that is built to another Picking cart */
      if (@vToLPNType in ('TO' /* Tote */)) and
         (coalesce(@vToLPNPalletId, 0) <> 0) and
         (coalesce(@vToLPNPalletId, 0) <> @PickingPalletId)
        set @vMessageName = 'ScannedToteFromAnotherCart';
      else
      /* Need to ensure user scans generated temp Label */
      if (@vIsTempLabelGenerated = 'Y' /* yes */) and
         (@vConfirmedAllCases <> 'Y') and
         (@vValidTempLPNId is null)
        set @vMessageName = 'Picking_ScanValidTempLabel';
      else
      /* NFU - New, New Temp, Picking */
      if (dbo.fn_LPNs_ValidateStatus(@vToLPNId, @ToLPNStatus, 'NFU') <> 0) and
         (@ToLPNType <> 'A'/* Cart */)
        set @vMessageName = 'LPNClosedForPicking';
      else
      if (@LPNPicked is not null) and (@PickedLPNId is null)
        set @vMessageName = 'InvalidPickingLPN';
      else
      if (@PickedSKUId is null)
        set @vMessageName = 'InvalidPickingSKU';
      else
      if ((@ToLPN is not null) and (@ToLPNType = 'L' /* PickLane */))
        set @vMessageName = 'CannotPickToPickLane';
      else
      /* validating ToLPN, if we did not setup rule then rule will return as ALL,
         then no need to validate , we do not want to break existing functionality for other clients */
      if (@vTaskSubType = 'U' /* Unit pick */) and
         (coalesce(@vValidToLPNTypesToPick, 'ALL') <> 'ALL') and
         (charindex(@ToLPNType, @vValidToLPNTypesToPick) = 0)
        set @vMessageName = 'InvalidToLPN';
      else
      if ((@PickType  = 'L' /* LPN */) and (@vTaskLPNId <> @PickedLPNId) and
          (@vIsBatchAllocated <> 'N' /* No */))
        set @vMessageName = 'LPNDiffFromSuggested';
      else
      /* If user is picking to a new LPN then make sure it is an empty LPN */
      if (@vToLPNId is not null) and (@vToLPNStatus = 'N'/* New */) and
         (@vToLPNNumLines > 0)
        set @vMessageName = 'PickToEmptyLPN';
      else
      if ((@SuggestedLPNPickingClass = 'OL' or @PickedLPNPickingClass = 'OL' /* Opened LPN */) and (@SuggestedLPNPickingClass <> @PickedLPNPickingClass))
        set @vMessageName = 'CannotSubstituteAnyLPNWithAOpenLPN';
      else
      if (@LPNLocation <> coalesce(@PickedFromLocation, @LPNLocation)) and (@PickType <> 'L')
        set @vMessageName = 'LocationDiffFromSuggested';
      else
      if (@vUnitsPicked > @LPNQuantity)
        set @vMessageName = 'PickedUnitsGTLPNQty';
      else
      if (@PickMode <> 'Consolidated') and
         (@vLDReservedQty > @vTDUnitToPickForOD) and
         (@vIsBatchAllocated = 'Y') and (@vTaskSubType = 'U') and
         (@vIsTaskAllocated = 'Y'/* Yes */)
        set @vMessageName = 'AllocatedQtyIsGreaterThanRequiredQty';
      else
      if (@vUnitsPicked > @vUnitsToAllocate) and (@vIsBatchAllocated = 'N')
        set @vMessageName = 'PickedUnitsGTRequiredQty';
      else
      if ((@ToLPNOrderId is not null) and
          (@vOrderId <> coalesce(@ToLPNOrderId, @vOrderId)))
        set @vMessageName = 'PickingToWrongOrder';
      else
      if ((@PickedSKUId is not null) and ((@PickedSKUId <> @vOrderSKUId) or (@PickedSKUId <> @LPNSKUId)))
        set @vMessageName = 'PickingSKUMismatch';
      else
      if (@PickingPalletId <> @ToLPNPalletId)
        set @vMessageName = 'PickingToAnotherPallet';
      else
      if (@vUnitsPicked > @vTDUnitsToPick)
        begin
          select @vMessageName = 'PickedQtyIsGreaterThanRequiredQty',
                 @vNote1      = dbo.fn_Str(@vTDUnitsToPick);
        end
      else
      if (@vTaskSubType = 'CS') and
         (@ToLPN = 'LocationLPN') and (@vUnitsPicked <> @vTDUnitsToPick)
        set @vMessageName = 'PickedQtyIsdiffThanRequiredQty';
      else
      if (dbo.fn_LPNs_ValidateStatus(@FromLPNId, @vLPNStatus, 'KES') = 0)
        set @vMessageName = 'LPNAlreadyPicked';
      else
      if (@vIsTempLabelGenerated = 'Y') and
         (@vTaskSubType = 'CS' /* Case Pick */) and
         (@UnitsPicked >  1) and
         (@ToLPN not in ('TaskDetail', 'LocationLPN'))
        set @vMessageName = 'CannotPickAllInvIntoOneLabel';
      else
      if (@vTaskSubType = 'U' /* Unit Pick */) and
         (@vAllowPickMultipleSKUsintoLPN = 'N' /* No */) and
         (@vIsMultiSKUTote = 'Y' /* Yes */)
        set @vMessageName = 'ToLPNAlreadyPickedForOtherSKU';
      else
      if (@LPNLocationId <> @PickedLocationId)
        set @vMessageName = 'PickLPNFromSuggestedLocationOnly'; /* we are not allowing to Pick LPN other than Suggested LPn for now */
      else
      if ((@PickType = 'L'/* LPN Pick */) and (@UnitsPicked <> @vTDUnitsToPick))
        set @vMessageName = 'CannotPickUnitsFromLPN';
      else
      if ((@CoO <> '') and
          (not exists (select *
                   from vwLookUps
                   where ((LookUpCode        = @CoO)  or
                          (LookUpDescription = @CoO)) and
                         (BusinessUnit       = @BusinessUnit) and
                         (LookUpCategory     = 'CoO'))))
         /* if user entered valid CoO then this will not be null */
         set @vMessageName = 'InvalidCoO';
      else
        exec pr_RuleSets_Evaluate 'Picking_Validations', @xmlRulesData, @vMessageName output;

      /* If Error, then return Error Code/Error Message */
      if (@vMessageName is not null) goto ErrorHandler;
    end

 -- This is being validated above
 -- /* Validating whether User has permissions to do short pick. */
 -- if ((@ShortPick = 'Y'/* Yes */) and
 --     (dbo.fn_Permissions_IsAllowed(@UserId, 'RFAllowShortPick') <> '1' /* 1 - True, 0 - False */))
 --   set @vMessageName = 'CannotShortPick';

 -- /* If Error, then return Error Code/Error Message */
 -- if (@vMessageName is not null) goto ErrorHandler;

  /* If PickTicket is null, get the PickTicket from the OrderDetails table with the
     given OrderDetailId */
  if (@ValidPickTicket is null)
    select @ValidPickTicket = PickTicket
    from OrderHeaders OH
      join OrderDetails OD on (OH.OrderId = OD.OrderId)
    where (OD.OrderDetailId = @OrderDetailId);

  if (@PickType = 'L' /* LPN */)
    begin
      /* If user did short pick then we dont have PickedLPN so pass FromLPN as PickedLPN. So below procedure will be
         taking care of creating CC tasks for the picking location */
      select @LPNPicked = case when @ShortPick = 'Y' then @ValidFromLPN else @LPNPicked end;

      /* Build the XML */
      select @vxmlConfirmLPNPickInput = cast ((select @vDeviceId          as DeviceId,
                                                      @UserId             as UserId,
                                                      @PickTicket         as PickTicket,
                                                      @OrderDetailId      as OrderDetailId,
                                                      @ValidPickZone      as ValidPickZone,
                                                      @LPNPicked          as LPNPicked,
                                                      @PickedFromLocation as PickedFromLocation,
                                                      @PickingPallet      as PickingPallet,
                                                      @ShortPick          as ShortPick,
                                                      @TaskId             as TaskId,
                                                      @TaskDetailId       as TaskDetailId
                                               for xml raw('ConfirmLPNPick'), elements) as varchar(max));

      /* Call ConfirmLPNPick */
      exec @vReturnCode = pr_RFC_Picking_ConfirmLPNPick @vxmlConfirmLPNPickInput, @xmlResultvar output;

      /* convert the returned varchar to xml */
      select @xmlResult = convert(xml, @xmlResultvar);

      if (@vReturnCode > 0) goto ErrorHandler;
    end
  else
   /* Confirm all the consolidated units at once,
     when user is picking multiple task details at a time, instead of picking each task detail */
  if (@ShortPick = 'N') and (@PickMode = 'Consolidated')
    begin
     /* Call ConfirmPicks procedure to complete the pick */
      exec pr_Picking_ConfirmPicks @ttTaskPicksInfo, 'ConfirmTaskPick', @BusinessUnit, @UserId, default/* Debug */;
    end
  else
 if (@ShortPick = 'N') -- and PickType = 'U'
    begin
      insert into @ttTaskPicksInfo(PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, PalletId, FromLPNId, FromLPNDetailId,
                                   FromLocationId, TempLabelId, TempLabelDtlId, QtyPicked, ToLPNId)
        select TD.PickBatchNo, TD.TaskDetailId, TD.OrderId, TD.OrderDetailId, TD.SKUId, @PickingPalletId, TD.LPNId, TD.LPNDetailId,
               TD.LocationId, TD.TempLabelId, TD.TempLabelDetailId, @vUnitsPicked /* Units Picked */, @vToLPNId
        from TaskDetails TD
        where (TD.TaskDetailId = @TaskDetailId);

      /* Call ConfirmPicks procedure to complete the pick */
      exec pr_Picking_ConfirmPicks @ttTaskPicksInfo, 'ConfirmTaskPick', @BusinessUnit, @UserId, default/* Debug */;

      /* Temporary fix - This is not right ** TODO - Need to identify the right place and fix it. However, this wont harm now */
      update LPNs
      set PickingClass = 'OL' /* Open LPN */
      where (LPN = @ValidFromLPN) and
            (LPNType <> 'L' /* Logical Picklane */);
    end
  else
  if (@ShortPick = 'Y') -- and PickType = 'U'
    begin
      /* There are some situations, where 2 or more pickers are suggested to pick
         from the same location and if the first picker (who reaches the location first),
         picked the required (lets say he requires all available in this situation) and
         when the 2nd or other pickers comes to this location to pick and found there
         is no available inventory by that time, they need to be able to choose 'ShortPick'
         option and go ahead with remaining batch order(s) picks.
         (12/5) - Currently not allowing to Short Pick and showing message "Invalid From LPN"
         - This is due to the first picker picks all inventory, the LPN (logical) is deleted
           along with its detail lines, hence for the second or other pickers, the LPN is not available.

         ** Other situation could be - Location is adjusted by some user while the picker is directed to pick just before that

         Solution: Check the From LPN, if not null then adjust, else proceed with other picks in the batch
      */
      if (@ValidFromLPN is not null)
        begin
          /* Update OrderHeaders by setting ShortPick flag to 'Y' if it is ShortPicked */
          update OrderHeaders
          set ShortPick = 'Y'
          where (OrderId = @vOrderId);

          /* currently @vUnitsToAllocate is untsToAllocate value on the line, if the total units
            allocated then UntisToallcoate is 0, so we need to send remaig units to pick for the task line if
            the batch is allocated  */
          if (@vIsBatchAllocated <> 'N' /* No */)
            set @vUnitsToAllocate = @vTDUnitsToPick
          else
            set @vUnitsToAllocate = @LPNQuantity;

          /* System thinks there is inventory in a location and directed user to pick it,
             but the user did not find any inventory to pick, so clear the LPN */

          /* call the LPN to short pick */
          exec pr_Picking_ShortPickLPN @FromLPNId, @LPNDetailId, @LPNSKUId, @vBusinessUnit, @UserId;

          /* Log audit here */
          exec pr_AuditTrail_Insert 'OrderShortPicked', @UserId, null /* ActivityTimestamp */,
                                    @OrderId       = @vOrderId,
                                    @OrderDetailId = @OrderDetailId,
                                    @LocationId    = @LPNLocationId,
                                    @Quantity      = @vUnitsToAllocate,
                                    @LPNId         = @FromLPNId,
                                    @PickBatchId   = @vPickBatchId,
                                    @PalletId      = @PickingPalletId;

          if (@vLPNAvailableQty > 0)
            /* As above short pick AT logs only the order allocated qty, log another short pick AT for LPN with Avaiable Quantity */
            exec pr_AuditTrail_Insert 'LPNShortPickedWithAvailableQty', @UserId, null /* ActivityTimestamp */,
                                      @LocationId = @LPNLocationId,
                                      @LPNId      = @FromLPNId,
                                      @Quantity   = @vLPNAvailableQty;

         -- We are not getting return code & @CCMessage any where
         -- if (@vReturnCode > 0)
         --   begin
         --     select @vMessageName = @CCMessage;
         --     goto ErrorHandler;
         --   end
        end
    end

  /* If the location was supposed to empty after the pick, then mark the location as counted or
     issue a cycle count based upon users' confirmation */
  if (@ShortPick = 'N'/* No */) and
     (@EmptyLocation = 'Y')
    begin
      select @vCCOperation = case
                               when @ConfirmEmptyLocation = 'Y' then 'ConfirmEmpty'
                               when @ConfirmEmptyLocation = 'N' then 'ConfirmNonEmpty'
                             end

      /* call the procedure here to update Location as cc or create a task for that */
      /* @vTaskLocationId -> @LPNLocationId : Both are the same, but in case if Task is not
         Allocated then LocationId on the Task will be null so passing Picked LPN LocationId*/
      exec pr_Picking_CCPickedLocation  @LPNLocationId, @vCCOperation, @BusinessUnit,
                                        @UserId, @DeviceId;
    end

  if (@vIsBatchAllocated = 'Y')
    begin
      /* Find the next Pick Task or Pick from Task for the Batch */
      exec pr_Picking_FindNextTaskToPickFromBatch @UserId,
                                                  @DeviceId,
                                                  @BusinessUnit,
                                                  @PickBatchNo,
                                                  @PickTicket,
                                                  @ValidPickZone,
                                                  @DestZone,
                                                  @PickGroup,
                                                  'P' /* Partial Picks - Units */,
                                                  null,
                                                  @PickingPallet,
                                                  @NextLPNToPickFrom   output,
                                                  @NextLPNIdToPickFrom output,
                                                  @NextLPNDetailId     output,
                                                  @OrderDetailId       output,
                                                  @UnitsToPick         output,
                                                  @LocToPick           output,
                                                  @vPickType           output,
                                                  @TaskId              output,
                                                  @TaskDetailId        output;

      /* Update taskDetail Status here */
      if (coalesce(@TaskDetailId, 0) <> 0)
        update TaskDetails
        set Status   = 'I' /* InProgress */,
            PalletId = @PickingPalletId
        where (TaskDetailId = @TaskDetailId);
    end
  else
    begin
      /* Find the next Pick from the Batch */
      exec pr_Picking_FindNextPickFromBatch @PickBatchNo,
                                            @ValidPickZone,
                                            'P' /* Partial Picks - Units */,
                                            null,
                                            @NextLPNToPickFrom   output,
                                            @NextLPNIdToPickFrom output,
                                            @NextLPNDetailId     output,
                                            @OrderDetailId       output,
                                            @UnitsToPick         output,
                                            @LocToPick           output,
                                            @vPickType           output;
    end

  /* if there are more units to pick, then build response for next pick to send to device */
  if (@NextLPNToPickFrom is not null)
    begin
      /* Prepare response for the Pick to send to RF Device */
      exec pr_Picking_BatchPickResponse @ValidPickingPallet,
                                        null /* @PalletId */,
                                        null /* @Pallet */,
                                        @NextLPNIdToPickFrom,
                                        @NextLPNToPickFrom,
                                        @NextLPNDetailId,
                                        @OrderDetailId,
                                        @UnitsToPick,
                                        @LocToPick,
                                        @vPickType,
                                        @PickGroup,
                                        @TaskId,
                                        @TaskDetailId,
                                        @BusinessUnit,
                                        @UserId,
                                        @xmlResult output;

      /* We need to retain the user selected pick mode */
      select @vResultXML = convert(varchar(max), @xmlResult);
      select @vResultXML = dbo.fn_XMLStuffValue(@vResultXML, 'PickMode', @PickMode);
      select @xmlResult = convert(xml, @vResultXML);
    end
  else
    begin
      /* When last pick is done, it say "completed' which is not correct.
         There may be more picks in the task in that case we should not say completed,
         we should say that no more picks in current zone. */
      if exists (select *
                 from TaskDetails
                 where (TaskId = @vTaskId) and
                       (Status not in ('C', 'X' /* Completed/Canceled */)))
        set @ConfirmBatchPickMessage = dbo.fn_Messages_Build('PicksCompletedInScannedZone', @PickZone, @PickBatchNo, @vTaskId, default, default);
      else
        set @ConfirmBatchPickMessage = dbo.fn_Messages_Build('BatchPickComplete', @PickZone, @PickBatchNo, @vTaskId, default, default);

      /* Update the LPNs Status to Picked once after the Batch Picking is done */
      update LPNs
      set Status = 'K' /* Picked */
      output Deleted.LPNId, Deleted.LPN into @ttPickedLPNs
      where (PalletId = @PickingPalletId) and
            (Status   = 'U' /* Picking */) and
            (Quantity > 0) and
            (LPNId not in (select distinct LPNId from vwLPNDetails where PalletId = @PickingPalletId and OnhandStatus = 'U' /* Unavailable */));

      /* Update the Pallet status to Picked only if all the LPNs on the Pallet are
         in Picked Status */
      if not exists (select *
                     from LPNs
                     where (PalletId = @PickingPalletId) and
                           (Quantity > 0               ) and
                           (Status <> 'K'/* Picked */ ))
        exec pr_Pallets_SetStatus @PickingPalletId, 'K' /* Picked */, @UserId;

      /* Updating Status for Batch if the picking is Complete for the Batch */
      exec pr_PickBatch_SetStatus @PickBatchNo, '$' /* Recalc later */, @UserId, @PickBatchId output;

      /* if there are any LPNs are updated as marked then we need to export them */
      if (exists (select * from @ttPickedLPNs))
        exec pr_Picking_ExportDataOnLPNPicked @PickBatchId, null /* LPNId */, @ttPickedLPNs, @BusinessUnit, @UserId;

      /* Log the Audit Trail once after the Batch is Picked */
      exec pr_AuditTrail_Insert 'PickBatchCompleted', @UserId, null /* ActivityTimestamp */,
                                @PickBatchId = @PickBatchId,
                                @PalletId    = @PickingPalletId;

      set @xmlResult = (select 0                        as ErrorNumber,
                               @ConfirmBatchPickMessage as ErrorMessage
                        FOR XML RAW('BATCHPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('BATCHPICKDETAILS'));
    end

  /* Built and send required info to validate in Rules */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Module',           'Picking') +
                            dbo.fn_XMLNode('Operation',        'BatchPicking') +
                            dbo.fn_XMLNode('Entity',           'LPN') +
                            dbo.fn_XMLNode('EntityId',         @vToLPNId) +
                            dbo.fn_XMLNode('EntityKey',        @ToLPN) +
                            dbo.fn_XMLNode('WaveType',         @vWaveType) +
                            dbo.fn_XMLNode('BusinessUnit',     @BusinessUnit) +
                            dbo.fn_XMLNode('UserId',           @UserId));

  /* Print Generated Temp LPN */
  if ((coalesce(@vToLPNId, 0) <> 0) and (@vPrintLabel = 'Y'))
    exec pr_Printing_EntityPrintRequest 'Picking', 'BatchPicking', 'LPN', @vToLPNId, @ToLPN, @BusinessUnit, @UserId,
                                        @vDeviceId, 'IMMEDIATE', default /* PrinterName */, null, null, @vRulesDataXml;

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @vDeviceId, @UserId, @ActivityType, @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1, @vNote2;

  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  /* Handling transactions in case if it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_ConfirmBatchPick */

Go
