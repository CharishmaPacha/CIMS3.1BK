/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/08  AY      pr_RFC_CC_CompleteLocationCC: Users CCing LPNs with zero qty causing issues (HA GoLive)
  2021/02/16  SK      pr_RFC_CC_CompleteLocationCC: Bug fix to be able to get SKUId for Scannedd LPN from different Location (HA-2000)
  2021/02/15  PK      pr_RFC_CC_CompleteLocationCC: Bug fix to not to generate duplicate Inventory change transactions when LPN is lost (HA-2000)
  2020/10/19  SK      pr_RFC_CC_CompleteLocationCC: Fixes for updating previous quantities (HA-1597)
  2020/01/09  SK      pr_RFC_CC_CompleteLocationCC: Update Prev Location values missing in the CC Result (CIMSV3-1066)
  2020/08/31  AY      pr_RFC_CC_StartLocationCC, pr_RFC_CC_CompleteLocationCC: Several fixes to update tasks (CIMSV3-1064)
  2019/03/12  SV      pr_RFC_CC_CompleteLocationCC: Improved the performance by ignoring a unwanted join (OB2-837)
  2018/08/10  CK      pr_RFC_CC_CompleteLocationCC: Enhanced to allow user to scan either SKU or UPC (OB2-537)
  2018/03/08  OK      pr_RFC_CC_CompleteLocationCC, pr_RFC_CC_StartLocationCC: Enhanced to complete the open cycle count task if user did Non directed CC and Location has any open task (S2G-335)
  2018/02/20  OK      pr_RFC_CC_CompleteLocationCC: Enhanced to update the Previous and New InnerPack values after CC for Cycle count statistics (S2G-245)
  2018/02/13  AY      pr_RFC_CC_CompleteLocationCC: Fix issue with duplicate entries in CC Results for multi SKU picklane (S2G-207)
  2018/01/24  AY/OK   pr_RFC_CC_CompleteLocationCC: Setup LPN on Picklane CC for existing SKUs in Location so that the old and new match up correctly (S2G-130)
  2018/01/22  AY      pr_RFC_CC_CompleteLocationCC: Enable CC for Bulk Locations (S2G-131)
  2018/01/17  OK      pr_RFC_CC_CompleteLocationCC: Bug fix for run time casting error while confirming cycle count (S2G-120)
  2018/01/15  TD      pr_RFC_CC_CompleteLocationCC:Changes to clear from onhold once after the location was cyclecounted -CIMS-1717
  2017/01/18  OK      pr_RFC_CC_CompleteLocationCC: Enhanced to allow Supervisor counts can be done by any role who has permissions (GNC-1408)
  2017/12/27  AY      pr_RFC_CC_CompleteLocationCC: Change to use new RF Logging procedures
  2017/01/03  TK      pr_RFC_CC_CompleteLocationCC: Ignore unavailable lines while calculating Quantities (HPI-1228)
  2016/11/25  OK      pr_RFC_CC_CompleteLocationCC: Bug fix to update proper PrevQty, InnerPacks if new SKU is scanned while CC (FB-833)
  2016/09/23  SV      pr_RFC_CC_CompleteLocationCC: Bug Fix - Not able to CC the Location when selecting empty Location (HPI-751)
  2016/09/11  PK      pr_RFC_CC_CompleteLocationCC: Bug fix to not to consider Lost status LPNs quantities in the previous quantities info.
  2016/08/05  SV      pr_RFC_CC_CompleteLocationCC: Updating the counts over the Location once after CycleCounting it (HPI-324)
  2016/02/29  TK      pr_RFC_CC_CompleteLocationCC: Bug fix - Pallet CC doesn't move pallet to new location when LPNs are not scanned (NBD-177)
  2015/12/11  SV      pr_RFC_CC_CompleteLocationCC, pr_RFC_CC_ValidateEntity: Handle duplicate UPCs i.e. diff SKUs having same UPC (SRI-422)
  2015/11/17  OK      pr_RFC_CC_CompleteLocationCC: Changes to process location contents first and then Scanned contents (FB-340)
  2015/06/03  SV      pr_RFC_CC_CompleteLocationCC: Resolved the issue of AT log.
              TK      pr_RFC_CC_CompleteLocationCC: Changes made to use fn_Locations_GetScannedLocation
  2015/04/03  TK      pr_RFC_CC_CompleteLocationCC: Restrict to log Audit Trail twice
  2014/08/01  TD      pr_RFC_CC_CompleteLocationCC:Passing Proper values to create tasks.
  2014/05/19  PV      pr_RFC_CC_CompleteLocationCC: Issue fix with calculating quantity for picklane units location.
  2014/05/13  TD      pr_RFC_CC_CompleteLocationCC: Passing innerpacks to log audit trail.
  2014/05/05  TD      pr_RFC_CC_CompleteLocationCC:Changes to do cycle count for Picklane case storage Locations.
  2014/03/20  TD      pr_RFC_CC_CompleteLocationCC:Changes to handle with Innerpacks.
  2014/01/28  NY      pr_RFC_CC_CompleteLocationCC: Updating Prev Qty with LPN Quantity insted of Loc Qty.
  2014/01/11  AY      pr_RFC_CC_CompleteLocationCC: CC of Staging/Dock Locations does not mark LPNs in those as lost
  2014/01/08  PK      pr_RFC_CC_CompleteLocationCC: Considering Bulk Location as well.
                      pr_RFC_CC_ValidateEntity: Fix for returning LPNDetails if it is allocated partially.
  2013/11/05  PK      pr_RFC_CC_CompleteLocationCC: Updating the ScannedUnits by multiplying with SKUs UnitPerInnerpack.
  2013/03/15  PKS     pr_RFC_CC_CompleteLocationCC: Used function fn_SKUs_GetSKU to fetch SKU Information
  2013/03/03  PKS     pr_RFC_CC_CompleteLocationCC: output XML was framed for Location Cycle Count.
  2012/09/20  PK      pr_RFC_CC_CompleteLocationCC: Bug fix for begin rollback transactions.
  2012/09/05  AY      pr_RFC_CC_CompleteLocationCC: Cycle counting of empty Locations
                        had no statistics, audit trial was not right, Locations with
                        invalid counts - fixed them all.
  2012/08/13  NY/AY   pr_RFC_CC_CompleteLocationCC: Several corrections for correct
                        Cycle Count statistics and Audit messages
  2012/01/17  VM      pr_RFC_CC_CompleteLocationCC: Insert SKU as well into CycleCountResults table.
  2012/01/09  YA      Added 'pr_RFC_CC_StartDirectedLocCC' for Directed CycleCount.
                        Modified 'pr_RFC_CC_CompleteLocationCC' to create Task and TaskDetails for Non-DirectedCC.
  2011/12/26  PK      pr_RFC_CC_CompleteLocationCC : Called pr_Tasks_MarkTaskDetailAsCompleted
                        to update Location and Task if cycle counted Location has task.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CC_CompleteLocationCC') is not null
  drop Procedure pr_RFC_CC_CompleteLocationCC;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CC_CompleteLocationCC:

  Xml structure which is sent from RF to Database:

  1. If the location type is Picklane then the below xml will not have LPN tag.
  2. If the location type is Reserve then the xml will be returned as below.

  <?xml version="1.0" encoding="utf-16"?>
  <CONFIRMCYCLECOUNTDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <Location></Location>
    <SubTaskType></SubTaskType>
    <BatchNo></BatchNo>
    <CCLOCDETAILS>
      <LOCATIONINFO>
        <Pallet></Pallet>
        <LPN></LPN>
        <SKU></SKU>
        <NumLPNs></NumLPNs>
        <Quantity></Quantity>
      </LOCATIONINFO>
      ....
      <LOCATIONINFO>
        <Pallet></Pallet>
        <LPN></LPN>
        <SKU></SKU>
        <NumLPNs></NumLPNs>
        <Quantity></Quantity>
      </LOCATIONINFO>
    </CCLOCDETAILS>
 </CONFIRMCYCLECOUNTDETAILS>

  ttCCSummary.SortSeqNo: When users cycle count a location, it may only allow as single
    SKU and so to ensure that the data is processed without issues we have to first
    delete the existing SKU on the location and then add the new one. To ensure this
    order is conformed to, we have added SortSeqNo and process the details in that order.
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CC_CompleteLocationCC
  (@xmlLocCCInfo        xml,
   @xmlResult           xml    output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @vDebug              TFlags,
          @Message             TDescription,
          @ConfirmMessage      TMessageName,

          @vLocation           TLocation,
          @Location            TLocation,
          @vLocationId         TRecordId,
          @vLocationType       TTypeCode,
          @vLocStorageType     TStorageType,
          @vLocationSKU        TSKU,
          @vLocationSKUQty     TQuantity,
          @vInnerpacks         TInnerpacks,
          @vPickZone           TZoneId,
          @vMaxRecordId        TRecordId,
          @vCount              TRecordId,

          @vSumScannedSKUQty   TQuantity,
          @vSumLocationSKUQty  TQuantity,
          @vSumScannedSKUCases TInnerPacks,
          @vSumLocSKUCases     TQuantity,
          @vSKU                TSKU,
          @vSKUId              TRecordId,

          @vCurrentCount       TCount,
          @vNewLocationQty     TCount,
          @vNewLocationCases   TCount,
          @vSKUMisplaced       TFlag,
          @vFoundNewSKU        TFlag,
          @vCountChanged       TFlag,
          @vVariance           TFlags,
          @vTaskId             TRecordId,
          @vTaskDetailId       TRecordId,
          @TaskDetailId        TRecordId,
          @vBatchNo            TTaskBatchNo,
          @vCCLocationWasEmpty TFlag,
          @vCCLocationIsEmpty  TFlag,

          @vLPN                TLPN,
          @vLPNId              TRecordId,
          @vLPNDetailId        TRecordId,
          @vLPNStatus          TStatus,
          @vLPNLocationId      TRecordId,
          @vLogicalLPNId       TRecordId,

          @vPallet             TPallet,
          @vPalletId           TRecordId,
          @vPalletLocationId   TRecordId,
          @vPalletStatus       TStatus,

          @vNumLPNs            TCount,
          @vLPNMoved           TFlag,
          @vAdjustedLPN        TFlag,
          @vAddedSKUToLPN      TFlag,
          @vLPNLost            TFlag,
          @vPalletLost         TFlag,
          @vPalletConfirmed    TFlag,
          @vPalletMoved        TFlag,
          @vLPNChangedOnPallet TFlag,

          @vSubTaskType        TFlag,
          @xmlLocationInfo     xml,
          @vLocationXML        TXML,
          @LPNCCDetails        xml,
          @SKUCCDetails        xml,
          @PalletCCDetails     xml,
          @vCCOptionsXML       TXML,
          @vLocationInfo       varchar(max),
          @xmlResultvar        varchar(max),

          @vStatusFlag         TFlag,
          @vEscalateMessage    TMessage,

          @vAuditActivity      TActivityType,
          @vActivityLogId      TRecordId,

          @vRequestedCCLevel   TTypeCode,
          @vActualCCLevel      TTypeCode,

          @vBusinessUnit       TBusinessUnit,
          @vUserId             TUserId,
          @vDeviceId           TDeviceId,

          @ttCountedPalletsNoLPNs
                               TEntityKeysTable;

  /* Holds the details of the inventory counted by the user */
  declare @ttScannedCCDetails Table
          (RecordId            TRecordId  identity (1,1),
           ScannedSKU          TSKU,
           ScannedSKUId        TRecordId,
           ScannedLPN          TLPN,
           ScannedLPNId        TRecordId,
           ScannedPallet       TPallet,
           ScannedPalletId     TRecordId,
           NumLPNs             TCount,
           ScannedQty          TQuantity,
           ScannedInnerPacks   TQuantity,
           LPNPrevLocationId   TRecordId,
           LPNPrevLocation     TLocation,
           PrevQuantity        TQuantity,
           PrevInnerPacks      TQuantity,
           LPNStatus           TStatus)

  /* Holds the Location Contents prior to the cycle count */
  declare @ttLocationContents Table
          (RecordId            TRecordId  identity (1,1),
           LocationSKU         TSKU,
           SKUId               TRecordId,
           LPN                 TLPN,
           LPNId               TRecordId,
           Pallet              TPallet,
           PalletId            TRecordId,
           NumLPNs             TCount,
           PreviousQty         TQuantity,
           PreviousInnerPacks  TInnerPacks,
           LPNPrevLocation     TLocation,
           LPNStatus           TStatus)

  /* Holds consolidated info */
  declare @ttCCSummary TCCSummaryInfo;

begin
begin try
  SET NOCOUNT ON;

  select @vSKUMisplaced       = '',
         @vFoundNewSKU        = '',
         @vCountChanged       = '',
         @vLPNMoved           = '',
         @vAdjustedLPN        = '',
         @vAddedSKUToLPN      = '',
         @vLPNLost            = '',
         @vPalletLost         = '',
         @vPalletMoved        = '',
         @vLPNChangedOnPallet = '',
         @vAuditActivity      = 'CCLocation',
         @vCCLocationIsEmpty  = 'N', /* Cycle counted a Location as Empty */
         @vCCLocationWasEmpty = 'N';

  /* xmlLocCCInfo XMLParameter includes fields of Location, its ScannedSkus and new quantity,
     these fields will come from RF. Capture this XMLData in to a temptable with 5 major fields as
     'LocationSku': Skus in that particular Location,
     'ScannedSku':  Newly scanned SKUs,
     'OldQty':      Already present quantity,
     'NewQty':      Newly entered or adjusted qty,
     'AdjustQty':   Difference of both SKUs(OldQty - NewQty).
     Then depending upon the data in the temptable we need to perform actions
     like AdjustQty or AddSkuToLocation.*/

  /* fetch Location and LocationId from XML and store it in variable @vLocation and @vLocationId */
  select @vLocation          = Record.Col.value('Location[1]',          'TLocation'),
         @vSubTaskType       = Record.Col.value('SubTaskType[1]',       'TFlag'),
         @vBatchNo           = Record.Col.value('BatchNo[1]',           'TTaskBatchNo'),
         @vTaskId            = Record.Col.value('TaskId[1]',            'TRecordId'),
         @vTaskDetailId      = Record.Col.value('TaskDetailId[1]',      'TRecordId'),
         @vActualCCLevel     = Record.Col.value('ActualCCLevel[1]',     'TTypeCode'),
         @vBusinessUnit      = Record.Col.value('BusinessUnit[1]',      'TBusinessUnit'),
         @vUserId            = Record.Col.value('UserId[1]',            'TUserId'),
         @vDeviceId          = Record.Col.value('DeviceId[1]',          'TDeviceId')
  from @xmlLocCCInfo.nodes('CONFIRMCYCLECOUNTDETAILS') as Record(Col)

  /* Being the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlLocCCInfo, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vLocationId, @vLocation, 'Location',
                      @Value1 = @vBatchNo, @Value2 = @vTaskId, @Value3 = @vSubTaskType,
                      @ActivityLogId = @vActivityLogId output;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  begin transaction;

  /* Fetching LocationType is required to post in CycleCountResults */
  select @vLocationId     = LocationId,
         @vLocation       = Location,
         @vLocationType   = LocationType,
         @vLocStorageType = StorageType,
         @vPickZone       = PickingZone
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @vLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* validations */
  if (@vLocationId is null)
    select @MessageName = 'InvalidLocation'
  else
  if (@xmlLocCCInfo is null)
    select @MessageName = 'InvalidData';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* For Ad-hoc or Non-Directed cycle counting, there would be no cycle count
     tasks - however these are necessary for maintaining statistics and reports.
     Therefore, create task for the Location cycle counted */
  if (@vSubTaskType in ('N' /* Non-Directed */, 'PE' /* Picking Empty */, 'PN' /* Picking NonEmpty */) and (coalesce(@vTaskDetailId, 0) = 0))
    exec pr_CycleCount_CreateTaskForNonDirectedCount @vLocationId, @vLocation, @vPickZone,
                                                     @vBusinessUnit, @vUserId,
                                                     @vTaskId output, @vTaskDetailId output, @vRequestedCCLevel output;

  /* Fetch the Cycle Count Task and details. At this point whether it is
     Directed or Non-Directed Cycle count, there should always be a Task. In case
     of a Non-Directed Cycle count, we would have just created the task in above section */
  select @vTaskDetailId = TaskDetailId,
         @vTaskId       = TaskId,
         @vBatchNo      = BatchNo
  from vwTaskDetails
  where (LocationId   = @vLocationId)   and
        (TaskId       = @vTaskId)       and
        (TaskDetailId = @vTaskDetailId) and
        (BusinessUnit = @vBusinessUnit) and
        (Status in ('N' /* Not yet started */, 'I'/* Inprogress */));

  /* In the below stmts we can observe group by stmts. The reason to add is if we are CCing
     a location which is having "A" and "R" detail lines, then we need to consolidate the info
     as we are updating @ttCCSummary table by joining @ttLocationContents table. */
  /* PK-20210215: Have to include LA storage type as well to avoid sending duplicate exports when the LPN is not scanned in the location,
                  Since we are inserting LocationContents in the temp table and if we don't insert  Pallet info then it is inserting two records,
                  one with Pallet and another one without pallet and causing to generate 2 invch transactions */
  if (@vLocationType = 'R'/* Reserve */) and (@vLocStorageType in ('A'/* Pallets */, 'LA'/* Pallets & LPNs */))
    begin
      /* Populate the temp table with Pallet and its LPN details Inventory before Cycle Count */
      insert into @ttLocationContents (PalletId, Pallet, LPNId, LPN, SKUId, LocationSKU, PreviousQty, PreviousInnerPacks)
        select LD.PalletId, LD.Pallet, LD.LPNId, LD.LPN, LD.SKUId, LD.SKU, sum(LD.Quantity), sum(coalesce(LD.InnerPacks, 0))
        from vwLPNDetails LD
        where (LD.LocationId = @vLocationId) and
              (LD.OnhandStatus in ('A', 'R' /* Available/Reserved */))
        group by LD.PalletId, LD.Pallet, LD.LPNId, LD.LPN, LD.SKUId, LD.SKU;
    end
  else
  if (@vLocationType in ('R', 'B', 'S', 'D'/* Reserve, Bulk, Staging, Dock */)) -- other storage types of Reserve
    begin
      /* Populate the temp table with Inventory before Cycle Count */
      insert into @ttLocationContents (LPNId, LPN, SKUId, LocationSKU, PreviousQty, PreviousInnerPacks,
                                       LPNPrevLocation, LPNStatus)
        select LPNId, LPN, SKUId, SKU, sum(Quantity), sum(coalesce(InnerPacks, 0)),
               min(Location), min(LPNStatus)
        from vwLPNDetails
        where (LocationId = @vLocationId) and
              (OnhandStatus in ('A', 'R' /* Available/Reserved */))
        group by LPNId, LPN, SKUId, SKU;
    end
  else
  if (@vLocationType = 'K' /* PickLane */)
    begin
      insert into @ttLocationContents (LPNId, LPN, SKUId, LocationSKU, PreviousQty, PreviousInnerPacks)
        select LPNId, LPN, SKUId, SKU, sum(Quantity), sum(coalesce(InnerPacks, 0))
        from vwLPNDetails
        where (LocationId = @vLocationId) and --Fetch vLocation from i/p XML
              (OnhandStatus in ('A', 'R' /* Available/Reserved */))
        group by LPNId, LPN, SKUId, SKU;
    end

  if (not exists(select * from @ttLocationContents))
    select @vCCLocationWasEmpty = 'Y';

  /* Populate the temp table with scanned data */
  insert into @ttScannedCCDetails (ScannedSKU, ScannedSKUId, ScannedLPN, ScannedLPNId, ScannedPallet, ScannedPalletId, NumLPNs, ScannedQty, ScannedInnerPacks)
    select Record.Col.value('SKU[1]',        'TSKU'),
           Record.Col.value('SKUId[1]',      'TRecordId'),
           Record.Col.value('LPN[1]',        'TLPN'),
           Record.Col.value('LPNId[1]',      'TRecordId'),
           Record.Col.value('Pallet[1]',     'TPallet'),
           Record.Col.value('PalletId[1]',   'TRecordId'),
           Record.Col.value('NumLPNs[1]',    'TCount'),
           Record.Col.value('Quantity[1]',   'TQuantity'),
           Record.Col.value('InnerPacks[1]', 'TQuantity')
    from @xmlLocCCInfo.nodes('CONFIRMCYCLECOUNTDETAILS/CCLOCDETAILS/LOCATIONINFO') as Record(Col)
    where (Record.Col.value('Quantity[1]', 'TQuantity') > 0);

  /*---------------------------*/
  /* Update Scanned Entity Ids */
  update SCCD
  set ScannedSKUId    = case when ScannedSKUId <> '' then ScannedSKUId else S.SKUId end,
      ScannedLPNId    = case
                          when ScannedLPNId <> '' then ScannedLPNId
                          else dbo.fn_LPNs_GetScannedLPN(ScannedLPN, @vBusinessUnit, 'L' /* LPN */)
                        end,
      ScannedPalletId = case
                          when ScannedPalletId <> '' then ScannedPalletId
                          else dbo.fn_Pallets_GetPalletId(ScannedPallet, @vBusinessUnit)
                        end
  from @ttScannedCCDetails SCCD
    left join SKUs S on SCCD.ScannedSKU = S.SKU and S.BusinessUnit = @vBusinessUnit;

  /* If the user is CC Pallet without scanning LPNs then retrieve LPNs on the pallet scanned */
  if (@vLocStorageType in ('A', 'LA'/* Pallets, Pallets & LPNs */))
    begin
      /* Get the Pallets which have been confirmed with right number of LPNs
         The location may have several pallets and some scanned with LPNs and some without
         delete all the Pallets scanned without LPNs */
      insert into @ttCountedPalletsNoLPNs (EntityId, EntityKey)
        select ScannedPalletId, ScannedPallet
        from @ttScannedCCDetails
        where (nullif(ScannedLPN, '') is null) and
              (nullif(ScannedPallet, '') is not null);

      delete from @ttScannedCCDetails
      where ScannedPallet in (select EntityKey from @ttCountedPalletsNoLPNs);

      /* Insert the LPNs from the Pallets that we just counted without the LPNs */
      insert into @ttScannedCCDetails (ScannedSKU, ScannedSKUId, ScannedLPN, ScannedLPNId, ScannedPallet, ScannedPalletId, NumLPNs, ScannedQty, ScannedInnerPacks)
        select L.SKU, L.SKUId, L.LPN, L.LPNId, P.Pallet, P.PalletId, P.NumLPNs, L.Quantity, L.InnerPacks
        from Pallets P join vwLPNs L on (P.PalletId = L.PalletId)
        where (P.Pallet in (select EntityKey from @ttCountedPalletsNoLPNs));
    end

  /* If the Location StorageType is Units then there is no need to compute scannedQty */
  if ((@vLocStorageType not like 'U%' /* Units */) and (@vLocStorageType not like 'P%' /* Package */))
    begin
      update CCD
      set CCD.ScannedQty = (coalesce(CCD.ScannedInnerPacks, 0) * (case when S.UnitsPerInnerPack = 0 then 1 else S.UnitsPerInnerPack end))
      from @ttScannedCCDetails CCD left outer join SKUs S on (CCD.ScannedSKU = S.SKU)
      where (coalesce(CCD.ScannedQty, 0) = 0);

      /* If nothing has been scanned, then Location is currently empty */
      if (not exists(select * from @ttScannedCCDetails  where (coalesce(ScannedQty, 0) > 0) ))
        select @vCCLocationIsEmpty = 'Y';
    end
  else
    begin
      /* For Picklanes, Update LPN to be the Location for all existing SKUs being CCed */
      update CCD
      set ScannedLPN   = LC.LPN,
          ScannedLPNId = coalesce(ScannedLPNId, LC.LPNId)
      from @ttScannedCCDetails CCD
        cross apply dbo.fn_SKUs_GetScannedSKUs (CCD.ScannedSKU, @vBusinessUnit) S
      join @ttLocationContents LC on (LC.LPN = @vLocation) and (LC.LocationSKU = S.SKU);
    end

  /* For the scanned LPNs, Update the previous qty.
     For a Lost LPN we should not consider previous qty as it is found and prev qty should be considered zero. */
  update CCD
  set CCD.LPNPrevLocationId = L.LocationId,
      CCD.LPNPrevLocation   = L.Location,
      CCD.PrevQuantity      = case when coalesce(L.LocationId, 0) <> @vLocationId then 0 else LD.Quantity end,
      CCD.PrevInnerPacks    = case when coalesce(L.LocationId, 0) <> @vLocationId then 0 else LD.InnerPacks end
  from @ttScannedCCDetails CCD
    join LPNs       L  on (CCD.ScannedLPNId = L.LPNId)
    join LPNDetails LD on (L.LPNId          = LD.LPNId) and (LD.SKUId = CCD.ScannedSKUId);

  /* insert into the scanned details into a table for future reference or if requires any research */
  insert into CycleCountScannedDetails (TaskId, TaskDetailId, BatchNo, LocationId, Location, ScannedSKUId, ScannedSKU, ScannedLPNId, ScannedLPN,
                                        ScannedPalletId, ScannedPallet, NumLPNs, ScannedQty, ScannedInnerPacks, LPNPrevLocationId,
                                        LPNPrevLocation, PrevQuantity, PrevInnerPacks, LPNStatus)
    select @vTaskId, @vTaskDetailId, @vBatchNo, @vLocationId, @vLocation, ScannedSKUId, ScannedSKU, ScannedLPNId, ScannedLPN,
           ScannedPalletId, ScannedPallet, NumLPNs, ScannedQty, ScannedInnerPacks, LPNPrevLocationId,
           LPNPrevLocation, PrevQuantity, PrevInnerPacks, LPNStatus
    from @ttScannedCCDetails;

  /* delete/exclude the lines from the scanned CC counts if they have scanned the quantity as 0 */
  delete from @ttScannedCCDetails where ScannedQty = 0

  /* Insert the Scanned information into temp table */
  insert into @ttCCSummary (Pallet, LPN, SKU, NumLPNs, PreviousQty, PreviousInnerPacks, NewQty, NewInnerPacks,
                            LPNPrevLocation, LPNStatus, PalletScan, Deleted, SortSeq)
    select SCCD.ScannedPallet, SCCD.ScannedLPN, SS.SKU,
           /* NumLPNs */
           case when (coalesce(SCCD.ScannedLPN, '') <> '') and (@vLocationType <> 'K') then 1 else SCCD.NumLPNs end,
           SCCD.PrevQuantity, SCCD.PrevInnerPacks, SCCD.ScannedQty, coalesce(SCCD.ScannedInnerPacks, 0),
           SCCD.LPNPrevLocation, SCCD.LPNStatus,
           /* PalletScan */
           case when (coalesce(SCCD.ScannedPallet, '') <> '') and (SCCD.ScannedQty = 0) then 'Y' else 'N' end,
           'N' /* Deleted */, 2 /* SortSeq */
    from @ttScannedCCDetails SCCD cross apply dbo.fn_SKUs_GetScannedSKUs(SCCD.ScannedSKU, @vBusinessUnit) SS

  /* If the LPN was already in the Location prior to cycle count, then set PrevLPN = 1
     as it was previously there */
  update @ttCCSummary
  set PrevLPNs = case when LC.LPN is not null and @vLocationType <> 'K' then 1 else PrevLPNs end
  from @ttCCSummary CC join @ttLocationContents LC on ((CC.LPN = LC.LPN) and
                                                       (CC.SKU = LC.LocationSKU));

  /* Update the Pallet Scan records with the PrevLPN counts */
  with PalletLPNs (Pallet, LPNsCount) as
  (select Pallet, count(*) from @ttLocationContents group by Pallet)

  update CC
  set PrevLPNs = LPNsCount
  from @ttCCSummary CC join PalletLPNs PL on (CC.Pallet = PL.Pallet) and (PalletScan = 'Y');

  /* Insert the LPNs/SKU in the location that are not scanned during cycle count */
  insert into @ttCCSummary (Pallet, LPN, SKU, NumLPNs, PreviousQty, PreviousInnerPacks, NewQty, LPNPrevLocation, LPNStatus, Deleted, PrevLPNs, SortSeq)
    select LC.Pallet, LC.LPN, LC.LocationSKU, 0, LC.PreviousQty,  LC.PreviousInnerPacks, 0, @vLocation, 'P' /* Putaway */, 'N',
           case when LC.LPN is not null and @vLocationType <> 'K' then 1 else 0 end, 1 /* SortSeq - We have to process location contents which are not scanned first */
    from @ttLocationContents LC
    where not exists (select *
                      from @ttCCSummary CC
                      where (LC.LocationSKU = CC.SKU) and
                            (LC.LPN         = CC.LPN));

  /* This procedure returns whether user cycle counting the location units and value variance within the threshold values */
  exec pr_CC_EscalateCountLevel @ttCCSummary, @vLocationId, @vTaskId, @vBatchNo, @vUserId, @vBusinessunit,
                                @vStatusFlag      output,
                                @vEscalateMessage output;

  /* If @vStatusFlag is 'N' then skip the updates on CycleCounting, as we created Supervisor Count task  */
  if (@vStatusFlag <> 'Y')
    goto CCNextLocation;

  /* Iterate thru the list of LPNs and process them - this is particularly
     needed for LPNs which were not earlier in the location and now have been
     scanned into the Location or they were earlier in the location but not
     scanned now i.e. Lost */

  select @vCount        = count(*),
         @vCurrentCount = sum(PreviousQty)
  from @ttCCSummary;

  /* Update SKU Ids */
  update CCS
  set SKUId = S.SKUId
  from @ttCCSummary CCS cross apply dbo.fn_SKUs_GetScannedSKUs (CCS.SKU, @vBusinessUnit) S;

  /* Update pallet ids */
  update CCS
  set PalletId = P.PalletId
  from @ttCCSummary CCS join Pallets P on CCS.Pallet = P.Pallet and P.BusinessUnit = @vBusinessUnit
  where (CCS.Pallet > '');

  /* Update LPN ids */
  if (@vLocationType <> 'K' /* Pick lane */)
    update CCS
    set LPNId = L.LPNId
    from @ttCCSummary CCS join LPNs L on CCS.LPN = L.LPN and L.BusinessUnit = @vBusinessUnit
    where (CCS.LPNId is null);

  /* Update Logical LPN ids */
  if (@vLocationType = 'K' /* Pick lane */)
    update CCS
    set LPNId = L.LPNId
    from @ttCCSummary CCS
      join LPNs L on CCS.LPN = L.LPN and CCS.SKUId = L.SKUId and L.BusinessUnit = @vBusinessUnit
    where (CCS.LPNId is null);

  while (@vCount > 0)
    begin
      select @vPalletId = null, @vPallet = null;

      /* select top 1 Pallet which is not lost, because we are first processing the pallets
         which are not lost */
      select top 1 @vPalletId = PalletId, @vPallet = Pallet
      from @ttCCSummary
      where (Deleted = 'N') and (coalesce(Pallet, '') <> '') and (NewQty > 0);

      /* If @vPallet is null then find the pallets if there are any in temp table, like Lost Pallets */
      if (coalesce(@vPallet, '') = '')
        select top 1 @vPalletId = PalletId, @vPallet = Pallet
        from @ttCCSummary
        where (Deleted = 'N') and (coalesce(Pallet, '') <> '')
        order by SortSeq, Pallet;

      /* If not Pallet CC, Pick the first SKU & LPN to process */
      if (coalesce(@vPallet, '') = '')
        select top 1 @vSKU          = SKU,
                     @vLPN          = LPN,
                     @vLPNId        = LPNId,
                     @vLogicalLPNId = case when  (@vLocationType = 'K') then LPNId else null end
        from @ttCCSummary
        where Deleted = 'N'
        order by SortSeq, LPN, SKU;

      /* Find out what the new and old quantities are, this will be used only for PickLane Locations Cycle Counting */
      select @vSumScannedSKUQty   = sum(NewQty),
             @vSumLocationSKUQty  = sum(PreviousQty),
             @vSumScannedSKUCases = sum(NewInnerPacks),
             @vSumLocSKUCases     = sum(PreviousInnerPacks)
      from @ttCCSummary
      where (SKU = @vSKU) and
            (coalesce(LPN, '') = coalesce(@vLPN, ''));

      if (@vPalletId is not null)
        begin
           /* If the Scanned Pallet is of another location, get the Pallet Details and insert those details into summary temp table */
           insert into @ttCCSummary (Pallet, LPN, SKU, NumLPNs, PreviousQty, NewQty, LPNPrevLocation, LPNStatus, Deleted, SortSeq)
             select L.Pallet, L.LPN, LD.SKU, 0, LD.Quantity, 0, LD.Location, 0, 'N', 0 /* SortSeq */
             from vwLPNs L
               join vwLPNDetails LD on (L.LPNId = LD.LPNId)
             where (not exists (select *
                                from @ttCCSummary
                                where (LPN = LD.LPN) and
                                      (SKU = LD.SKU) and
                                     (Pallet = @vPallet))) and
                   (L.Pallet = @vPallet);

          /* Build XML with the details */
          select @PalletCCDetails = (select *
                                     from @ttCCSummary
                                     where (Pallet = @vPallet)
                                     FOR XML RAW('LOCATIONPALLETINFO'), TYPE, ELEMENTS XSINIL, ROOT('CYCLECOUNTLOCATION'));

          /* Pass the built xml and required information to update Location with
             the latest scanned details */
          exec @ReturnCode = pr_CC_CompletePalletCC @vPalletId,
                                                    @vLocationId,
                                                    @PalletCCDetails,
                                                    @vBusinessUnit,
                                                    @vUserId,
                                                    @vPalletLost         output,
                                                    @vPalletMoved        output,
                                                    @vLPNMoved           output,
                                                    @vAdjustedLPN        output,
                                                    @vAddedSKUToLPN      output,
                                                    @vLPNLost            output,
                                                    @vLPNChangedOnPallet output,
                                                    @vPalletConfirmed    output;

          /* when Pallet is confirmed but not LPNs on pallet cycle counted, then
             we want to show the Prev and New Qty of the LPNs as same so that there
             will not appear any UnitsChange in statistics, also, we do not want
             to show the LPN as counted as the Pallet record will show that */
          update @ttCCSummary
          set Deleted = 'Y',
              NewQty   = case when @vPalletConfirmed = 'Y' then PreviousQty else NewQty end,
              NumLPNs  = case when @vPalletConfirmed = 'Y' and PalletScan = 'N' then 0 else NumLPNs end,
              PrevLPNs = case when @vPalletConfirmed = 'Y' and PalletScan = 'N' then 0 else PrevLPNs end
          where (Pallet = @vPallet);
        end
      else
      if (@vLPNId is not null) and ((@vLocStorageType not like 'U%'/* Units */) and (@vLocStorageType not like 'P%'/* Packages */))
        begin
          /* Build XML with the details */
          select @LPNCCDetails = (select *
                                  from @ttCCSummary
                                  where (LPN = @vLPN)
                                  FOR XML RAW('LOCATIONLPNINFO'), TYPE, ELEMENTS XSINIL, ROOT('CYCLECOUNTLOCATION'));

          /* Pass the built xml and required information to update Location with
             the latest scanned details */
          exec @ReturnCode = pr_CC_CompleteLPNCC @vLPNId,
                                                 @vLocationId,
                                                 @vPalletId,
                                                 @LPNCCDetails,
                                                 @vBusinessUnit,
                                                 @vUserId,
                                                 @vLPNMoved           output,
                                                 @vAdjustedLPN        output,
                                                 @vAddedSKUToLPN      output,
                                                 @vLPNLost            output,
                                                 @vLPNChangedOnPallet output;

          update @ttCCSummary
          set Deleted = 'Y'
          where (LPN = @vLPN);

        end
      else
      if ((@vLocStorageType like 'U%'/* Units */) or (@vLocStorageType like 'P%'/* Packages */))
        begin
          /* Build XML with the details */
          select @SKUCCDetails = (select coalesce(@vLocationId,         '') as LocationId,
                                         coalesce(@vLocation,           '') as Location,
                                         coalesce(@vSKUId,              '') as SKUId,
                                         coalesce(@vSKU,                '') as SKU,
                                         coalesce(@vInnerpacks,         '') as Innerpacks,
                                         coalesce(@vSumScannedSKUQty,   '') as SumScannedSKUQty,
                                         coalesce(@vSumLocationSKUQty,  '') as SumLocationSKUQty,
                                         coalesce(@vSumScannedSKUCases, '') as SumScannedSKUCases,
                                         coalesce(@vSumLocSKUCases,     '') as SumLocationSKUCases
          FOR XML RAW('LOCATIONSKUINFO'), TYPE, ELEMENTS XSINIL, ROOT('CYCLECOUNTLOCATION'));

           /* Pass the built xml to update Location with the latest scanned details */
          exec @ReturnCode = pr_CC_CompleteSKUCC @SKUCCDetails,
                                                 @vBusinessUnit,
                                                 @vUserId,
                                                 @vSKUMisplaced output,
                                                 @vFoundNewSKU  output,
                                                 @vCountChanged output;

          /* Delete the SKU that is processed */
          update @ttCCSummary
          set Deleted = 'Y'
          where (SKU = @vSKU);
        end

        /* Resetting Count for while loop */
        select @vCount = count(*)
        from @ttCCSummary
        where (Deleted = 'N');

        select @vSKUId        = null,
               @vSKU          = null,
               @vLPNId        = null,
               @vLPN          = null,
               @vPalletId     = null,
               @vPallet       = null,
               @vLogicalLPNId = null;
    end

  /* Update the Location with Last Cycle counted date. If Location has invalid
     counts, correct them now! */
  update Locations
  set NumPallets         = case when NumPallets  < 0 then 0 else NumPallets end,
      NumLPNs            = case when NumLPNs  < 0 then 0 else NumLPNs end,
      Quantity           = case when Quantity < 0 then 0 else Quantity end,
      InnerPacks         = case when InnerPacks < 0 then 0 else InnerPacks end,
      AllowedOperations  = replace(AllowedOperations, 'N', ''), /* Clear On hold on Location */
      @vNumLPNs          = NumLPNs,
      @vNewLocationQty   = Quantity,
      @vNewLocationCases = InnerPacks,
      LastCycleCounted   = current_timestamp,
      ModifiedBy         = coalesce(@vUserId, System_User)
  where (LocationId = @vLocationId);

  /* Update task detail as completed - will update the Task header appropriately as well */
  if (@vTaskDetailId is not null)
    begin
      select @vVariance = coalesce(@vSKUMisplaced,       '') +
                          coalesce(@vFoundNewSKU,        '') +
                          coalesce(@vCountChanged,       '') +
                          coalesce(@vLPNMoved,           '') +
                          coalesce(@vAdjustedLPN,        '') +
                          coalesce(@vAddedSKUToLPN,      '') +
                          coalesce(@vLPNLost,            '') +
                          coalesce(@vPalletLost,         '') +
                          coalesce(@vPalletMoved,        '') +
                          coalesce(@vLPNChangedOnPallet, '');

      exec @ReturnCode = pr_Tasks_MarkTaskDetailAsCompleted @vTaskDetailId, @vVariance, @vUserId;

      /* Update the TaskDetail with count level */
      update TaskDetails
      set ActualCCLevel = @vActualCCLevel
      where (TaskDetailId = @vTaskDetailId);
    end

  /* Save results of the cycle count for statistical reporting (Since we are deleting SKUDetails from @ttSKUUpdate
     every time we are done with using it, i have placed this before deleting the records with some modifications)*/
  insert into CycleCountResults (TaskId, TaskDetailId, BatchNo, LPNId, LPN,
                                 LocationId, PrevLocationId, Location, PrevLocation,
                                 LocationType, PickZone, PalletId, Pallet,
                                 SKUId, SKU, PrevQuantity, PrevInnerPacks, NewQuantity, NewInnerPacks, PrevLPNs, NumLPNs,
                                 BusinessUnit)
  select @vTaskId, @vTaskDetailId, coalesce(@vBatchNo, '0'), L.LPNId, SU.LPN,
         @vLocationId, dbo.fn_Locations_GetScannedLocation(null, SU.LPNPrevLocation, @vDeviceId, @vUserId, @vBusinessUnit), @vLocation, SU.LPNPrevLocation,
         @vLocationType, @vPickZone, SU.PalletId, SU.Pallet,
         S.SKUId, S.SKU, sum(SU.PreviousQty), sum(SU.PreviousInnerPacks), sum(SU.NewQty), sum(SU.NewInnerPacks), sum(PrevLPNs), sum(NumLPNs),
         @vBusinessUnit
  from @ttCCSummary SU
       left outer join SKUs S on (S.SKU = SU.SKU)
       left outer join LPNs L on (L.LPNId = SU.LPNId)
  group by S.SKUId, S.SKU, L.LPNId, SU.LPN, SU.PalletId, SU.Pallet, SU.LPNPrevLocation;

  /* If there are no records in CC Summary, it means that the Location was empty
     to begin with and user cycle counted as empty again. */
  if (@vCCLocationWasEmpty = 'Y' and @vCCLocationIsEmpty = 'Y')
    begin
      insert into CycleCountResults (TaskId, TaskDetailId, BatchNo,
                                     LocationId, Location, LocationType, PickZone,
                                     PrevQuantity, NewQuantity, PrevLPNs, NumLPNs,
                                     BusinessUnit)
        select @vTaskId, @vTaskDetailId, coalesce(@vBatchNo, '0'),
               @vLocationId, @vLocation, @vLocationType, @vPickZone,
               0, 0, 0, 0, @vBusinessUnit;
    end

  /* Determine how to Log in activity */
  select @vAuditActivity = case
                             when (@vCCLocationWasEmpty = 'Y') and
                                  (@vCCLocationIsEmpty  = 'Y')
                               then 'CCLocationConfirmedEmpty'
                             when (@vCCLocationIsEmpty = 'Y')
                               then 'CCLocationEmpty'
                             else
                               'CCLocation_'+@vLocStorageType
                           end;

  /* Audit Trail */
  if (@vPalletId is null or @vLPNId is null) -- If not empty logging in pr_CC_CompletePalletCC or pr_CC_CompleteLPNCC
    exec pr_AuditTrail_Insert @vAuditActivity, @vUserId, null /* ActivityTimestamp */,
                              @LocationId = @vLocationId,
                              @LPNId      = @vLogicalLPNId,
                              @NumLPNs    = @vNumLPNs,
                              @InnerPacks = @vNewLocationCases,
                              @Quantity   = @vNewLocationQty;

CCNextLocation:

  /* Call 'pr_CycleCount_FindNextLocFromBatch' in case of directed CycleCount */
  if (@vSubTaskType = 'D' /* Directed */)
    begin
      exec pr_CycleCount_GetNextLocFromBatch @vBatchNo,
                                             @vUserId,
                                             @Location     output,
                                             @TaskDetailId output;

      set @vLocation = @Location;

      if (@vLocation is not null)
        /* Call pr_RFC_CC_StartLocationCC with returned Location
           - which return all the details of the Location fetched as @xmlResult */
        exec pr_RFC_CC_StartLocationCC @vLocation,
                                       @TaskDetailId,
                                       @vBusinessUnit,
                                       @vUserId,
                                       @vDeviceId,
                                       @xmlResult  output;
      else
        begin
          /* XmlMessage to RF, after Location is Cycle Counted */
          exec pr_BuildRFSuccessXML 'CCBatchCompletedSuccessfully' /* @MessageName */, @xmlResult output, @vLocation;
        end
    end
  else
  if ((@vSubTaskType = 'N' /* Non-Directed */) and (@vStatusFlag = 'Y'))
    exec pr_BuildRFSuccessXML 'CCCompletedSuccessfully' /* @MessageName */, @xmlResult output, @vLocation;
  else
    /* If Supervisor count task is created then display the proper message to user */
    exec pr_BuildRFSuccessXML @vEscalateMessage /* @MessageName */, @xmlResult output, @vLocation;

  /* It is mandatory to update the counts of the Location once after CCing it */
  exec pr_Locations_UpdateCount @vLocationId, @vLocation;

  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @vDeviceId, @vUserId, 'CompleteLocationCC', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Update activitylog with Result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_BuildRFErrorXML @xmlResult output;
end catch;

  return(coalesce(@ReturnCode, 0));
end /*  pr_RFC_CC_CompleteLocationCC */

Go
