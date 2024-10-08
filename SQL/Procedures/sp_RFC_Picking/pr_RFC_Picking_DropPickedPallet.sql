/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/11  TK      pr_RFC_Picking_DropPickedPallet: Fixes migrated from FB to drop picked pallet into bulk drop picklanes (BK-829)
  2022/04/19  VS      pr_RFC_Picking_DropPickedPallet: do not raise CannotDropToPicklane validation for Carts (BK-800)
  2021/07/30  RV      pr_RFC_Picking_DropPickedPallet: Call the rules to convert the component SKUs to set SKUs (OB2-1947)
  2021/04/10  VS      pr_RFC_Picking_DropPickedPallet: Calculate the wave counts and status after drop the Pallet (HA-2592)
  2020/12/14  RKC     pr_RFC_Picking_DropPickedPallet: Made changes to call the pr_OrderHeaders_Recalculate (HA-1783)
  2020/09/04  TK      pr_RFC_Picking_DropPickedPallet: Changes to unload LPNs associated with disqualified orders only (HA-1175)
  2019/07/24  AY      pr_RFC_Picking_DropPickedPallet: Mark incompleted totes/LPNs as picked if not cubed and if rule
  2019/07/17  AY      pr_RFC_Picking_DropPickedPallet: Send Task Status to rules to direct drop/unload appropriately (CID-GoLive)
  2019/06/08  AY      pr_RFC_Picking_DropPickedPallet: Return additional info for navigation
  2019/06/07  VS      pr_RFC_Picking_DropPickedPallet: Made changes to drop the Partial Picked Orders to Hold Location for PTC Wave (CID-538)
  2019/05/31  VS      pr_RFC_Picking_DropPickedPallet made changes to drop the Partially picked Orders in Hold Location (CID-486)
  2018/10/12  VS      pr_RFC_Picking_ValidatePallet, pr_RFC_Picking_DropPickedPallet:
  2018/09/20  AY      pr_RFC_Picking_DropPickedPallet: Rules to validate Scanned drop location is valid or not (S2GCA-252)
  2018/09/19  TK      pr_RFC_Picking_DropPickedPallet: Changes made to get correct scanned Drop Zone (S2GCA-185)
  2018/03/22  RV      pr_RFC_Picking_DropPickedPallet: Made changes to allow to drop if there are no rules available (S2G-459)
  2018/02/20  AY      pr_RFC_Picking_DropPickedPallet: Change rules to prevent cartons being unloaded from cart when dropped
  2017/02/17  TK      pr_RFC_Picking_DropPickedPallet: Consider PutawayZone instead of Zone desc to validate pallet drop (HPI-1369)
  2017/01/19  TK      pr_RFC_Picking_DropPickedPallet: Exclude completed status while identfying Task associated with Pallet/Cart (HPI-1299)
  2016/12/08  OK      pr_RFC_Picking_DropPickedPallet: Enhanced to validate scanned drop location zone with suggested (HPI-1070)
  2016/10/12  ??      pr_RFC_Picking_DropPickedPallet: Modified check condition to consider PickBatchType 'SW','SP' (HPI-GoLive)
  2016/09/21  RV      pr_RFC_Picking_DropPickedPallet: Get the latest task sub type from pallet to determine the Drop Pallet decission rules (HPI-727)
  pr_RFC_Picking_DropPickedPallet: Allow dropping multiple carts to same Loc if it is not a picklane (HPI-GoLive)
  2016/07/17  PK      pr_RFC_Picking_DropPickedPallet: Added Packed status as well for just in case.
  2016/07/13  OK      pr_RFC_Picking_DropPickedPallet: Enhanced to log the AT on dropped Ship Cartons (HPI-247)
  2016/05/05  TK      pr_RFC_Picking_DropPickedPallet: Changed to use Rules instead of controls to decide whether Unload picked LPNs from Pallet or not (NBD-374)
  2016/03/04  TK      pr_RFC_Picking_DropPickedPallet: Drop pallet only if the LPNs are not unloaded
  2016/01/20  NY      pr_RFC_Picking_DropPickedLPN, pr_RFC_Picking_DropPickedPallet : Added validation to not to drop pallet/lpn in Inactive location (GNC-1236)
  2015/11/30  TK      pr_RFC_Picking_DropPickedPallet: Invoke Pallet set Status proc instead of directly updating pallet status(ACME-425)
  2015/11/03  TK      pr_RFC_Picking_ConfirmBatchPick & pr_RFC_Picking_DropPickedPallet:
  VM      pr_RFC_Picking_DropPickedPallet: Retain DropLocation on Batch for further picks to use (FB-452)
  2015/09/24  AY      pr_RFC_Picking_DropPickedPallet: Bug fix - attempting to move LPNs into picklanes
  2015/08/20  OK      pr_RFC_Picking_DropPickedPallet: Do not allow pallet to drop to a different Warehouse (FB-310)
  2015/07/31  TK      pr_RFC_Picking_DropPickedPallet: Enhanced to evaluate rules for selecting control category(ACME-268)
  2015/06/25  RV      pr_RFC_Picking_DropPickedPallet: Get the Bulk batch info from control variable.
  pr_RFC_Picking_DropPickedPallet: When user drops the pallet, if there are picked LPNs on the pallet
  2015/05/05  OK      pr_RFC_Picking_DropPickedPallet: Made system compatable to accept either Location or Barcode.
  pr_RFC_Picking_DropPickedPallet: Update the Pallet status to Picked on each drop
  2015/03/04  VM      pr_RFC_Picking_DropPickedPallet: Temp fix to get Batch on Pallet
  2015/04/03  TK      pr_RFC_Picking_DropPickedPallet: Update Order/Batch Status to picked if Trnsferred Qty is equal to Units Assigned in case of Bulk Pull
  2015/03/03  TK      pr_RFC_Picking_DropPickedPallet: Enhanced to update OrderId and OrderDetailId on To LPN (logical LPN).
  2014/06/12  TD      pr_RFC_Picking_DropPickedPallet:Chanegs to export picked lpndetails to sorter while
  2012/07/20  NY      pr_RFC_Picking_DropPickedPallet: corrected the validation
  2012/07/10  YA      pr_RFC_Picking_DropPickedPallet: Handling transactions in case if transactions is rolled back from subprocedure.
  2012/06/29  PK      pr_RFC_Picking_DropPickedPallet: Modified if the pallet is dropped into a picklane location, then
  2012/06/25  PK      pr_RFC_Picking_DropPickedPallet: Temp Changes related to release the Customer Orders on Batch,
  2012/06/22  PK      pr_RFC_Picking_DropPickedPallet: Updating the Customer Orders Status from Hold to Batched,
  2012/05/30  PKS/AY  pr_RFC_Picking_DropPickedPallet: When Bulk Pull order is picked, mark Batch Ready to Pick.
  2011/08/29  PK      pr_RFC_Picking_DropPickedPallet: Added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_DropPickedPallet') is not null
  drop Procedure pr_RFC_Picking_DropPickedPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_DropPickedPallet:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_DropPickedPallet
  (@DeviceId      TDeviceId,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit,
   @PalletToDrop  TPallet,
   @DropLocation  TLocation,
   @TaskId        TRecordId,
   @xmlResult     xml        output)
as
  declare @ReturnCode               TInteger,
          @MessageName              TMessageName,
          @Message                  TDescription,
          @vRecordId                TRecordId,
          @xmlResultvar             TVarchar,
          @ConfirmDropPalletMessage TMessageName,
          @vLocationId              TRecordId,
          @vLocation                TLocation,
          @vPalletId                TRecordId,
          @vPalletType              TTypeCode,
          @vPalletStatus            TStatus,
          @vPalletQty               TQuantity,
          @vPalletLocId             TRecordId,
          @vPalletLocZone           TZoneId,
          @vPalletTaskId            TRecordId,
          @vLPNId                   TRecordId,
          @vCartPos                 TLPN,
          @vLocationType            TLocationType,
          @vLocStorageType          TLocationType,
          @vLocPutawayZone          TZoneId,
          @vLocPickZone             TZoneId,
          @vTempLabelId             TRecordId,

          @vDropLocation            TLocation,
          @vLocationStatus          TStatus,
          @vXferedQty               TQuantity,
          @vNumPickedLPNs           TQuantity,
          /* Wave */
          @vWaveId                  TRecordId,
          @vPickBatchId             TRecordId,
          @vPickBatchNo             TPickBatchNo,
          @vPickBatchStatus         TStatus,
          @vPickBatchType           TTypeCode,
          @vBatchDropLoc            TLocation,
          @vWaveCategory1           TCategory,
          @vOrderId                 TRecordId,
          @vOrderType               TTypeCode,
          @vUnitsAssigned           TQuantity,
          @vDropPalletDecision      TFlags,
          @vIsBulkPullBatch         TFlag,
          @vWaveWarehouse           TWarehouse,
          @vLocationWarehouse       TWarehouse,

          @vSuggestedDropLoc        TLocation,
          @vSuggestedDropZone       TZoneId,
          @vScannedDropLocZone      TZoneId,
          @vScannedDropLocZoneDesc  TDescription,
          @vDropLocationValidation  TControlValue,

          @vValidDropLocationTypes  TTypeCode,
          @vTaskId                  TRecordId,
          @vTaskType                TTypeCode,
          @vTaskStatus              TStatus,
          @vDisQualifiedOrderCount  TCount,
          @xmlInput                 xml,
          @vxmlInput                XML,
          @vRFLogInputXML           TXML,
          @vActivityLogId           TRecordId,
          @vAuditRecordId           TRecordId,
          @xmlRulesData             TXML,
          @ttPickedLPNs             TEntityKeysTable,
          @ttDisQualifiedOrders     TEntityKeysTable,
          @ttUnloadLPNsOnPallet     TEntityKeysTable,
          @ttOrdersToUpdate         TEntityKeysTable;

begin /* pr_RFC_Picking_DropPickedPallet */
begin try
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Build xml for Logging */
  select @vRFLogInputXML =  dbo.fn_XMLNode('DROPPEDPALLETINFO',
                            dbo.fn_XMLNode('DROPPEDPALLETDETAILS',
                            dbo.fn_XMLNode('Pallet',            @PalletToDrop) +
                            dbo.fn_XMLNode('DroppedLocation',   @DropLocation)));

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @vRFLogInputXML, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @PalletToDrop, 'DroppedPalletInfo',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Get Location details */
  select @vLocation          = Location,
         @vLocationType      = LocationType,
         @vLocStorageType    = StorageType,
         @vLocationId        = LocationId,
         @vDropLocation      = Location,
         @vLocationStatus    = Status,
         @vLocationWarehouse = Warehouse,
         @vLocPutawayZone    = coalesce(PutawayZone, ''),
         @vLocPickZone       = PickingZone
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @DropLocation, @DeviceId, @UserId, @BusinessUnit));

  /* get the scanned drop location zone details */
  /* Picking_FindDropZoneAndLocation returns drop zone description and that needs to be
     compared with scanned drop zone so get the description if exists */
  select @vScannedDropLocZoneDesc = coalesce(ZoneDesc, ZoneId)
  from vwPutawayZones
  where (ZoneId = @vLocPutawayZone);

  /* Get Pallet details */
  select @vPalletId     = PalletId,
         @vPalletType   = PalletType,
         @vPickBatchId  = PickBatchId,
         @vPickBatchNo  = PickBatchNo,
         @vPalletLocId  = LocationId,
         @vPalletTaskId = TaskId
  from Pallets
  where (Pallet = @PalletToDrop) and (BusinessUnit = @BusinessUnit);

  if (@vPalletLocId is not null)
    select @vPalletLocZone = PutawayZone
    from Locations
    where (LocationId = @vPalletLocId);

  /* Temp fix - After confirm batch Pick, it is clearing PIckbatchNo, Id on Pallet and making it empty too
     we need to identify and fix there - Until that point this will help but will not harm */
  if (@vPickBatchNo is null)
    select @vPickBatchId = L.PickBatchId,
           @vPickBatchNo = L.PickBatchNo
    from LPNs L
    where (L.PalletId = @vPalletId) and (coalesce(L.PickBatchId, 0) <> 0);

  /* As we do not have the TaskId, we can can get the Task sub type of latest modified TaskId */
  select top 1 @vTaskId      = TaskId,
               @vTaskType    = TaskSubType,
               @vTaskStatus  = TaskStatus,
               @vTempLabelId = TempLabelId
  from vwTaskDetails TD
  where (TD.TaskId = @TaskId) and
        (TD.TaskStatus <> 'X' /* Cancelled */) -- we cannot exclude completed tasks because the task that is associated with the pallet could have been just completed
  order by ModifiedDate desc;

  /* Get Batch details */
  select @vWaveId          = WaveId,
         @vPickBatchType   = BatchType,
         @vPickBatchStatus = Status,
         @vBatchDropLoc    = DropLocation,
         @vWaveCategory1   = Category1,
         @vWaveWarehouse   = Warehouse
  from PickBatches
  where (BatchNo = @vPickBatchNo) and (BusinessUnit = @BusinessUnit);

  /* Get the disqualified orders */
  insert into @ttDisQualifiedOrders (EntityId)
    select distinct OH.OrderId
    from OrderHeaders OH
      join TaskDetails TD on (OH.OrderId = TD.OrderId)
    where (TD.TaskId = @TaskId) and
          (dbo.fn_OrderHeaders_OrderQualifiedToShip(OH.OrderId, null, default /* Validation Flags */)  = 'N');

  set @vDisQualifiedOrderCount = @@rowcount;

  /* Get Valid Location Types */
  select @vValidDropLocationTypes     = dbo.fn_Controls_GetAsString('Picking',      'ValidDropLocationTypes',       'SDK' /* S:Staging, D:Dock, K:PickLane */, @BusinessUnit, @UserId),
         @vIsBulkPullBatch            = dbo.fn_Pickbatch_IsBulkBatch (@vWaveId);

  /* Get the suggesed drop Location/Zone for the Pallet/Wave */
    /* Get Drop Location and Zone */
  exec pr_Picking_FindDropLocationAndZone @vPickBatchNo, @vPickBatchType, @vBatchDropLoc, @vTaskId,
                                          'BatchPicking_DropPallet' /* Operation */, @BusinessUnit, @UserId,
                                          @vSuggestedDropLoc output, @vSuggestedDropZone output;

  /* Build the data for rule evaluation */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('Operation',              'BatchPicking_DropPallet') +
                         dbo.fn_XMLNode('WaveId',                 @vWaveId                 ) +
                         dbo.fn_XMLNode('PickBatchId',            @vPickBatchId            ) +
                         dbo.fn_XMLNode('WaveType',               @vPickBatchType          ) +
                         dbo.fn_XMLNode('WaveCategory1',          @vWaveCategory1          ) +
                         dbo.fn_XMLNode('TaskId',                 @vTaskId                 ) +
                         dbo.fn_XMLNode('TaskType',               @vTaskType               ) +
                         dbo.fn_XMLNode('TaskStatus',             @vTaskStatus             ) +
                         dbo.fn_XMLNode('PalletId',               @vPalletId               ) +
                         dbo.fn_XMLNode('PalletType',             @vPalletType             ) +
                         dbo.fn_XMLNode('LocationType',           @vLocationType           ) +
                         dbo.fn_XMLNode('StorageType',            @vLocStorageType         ) +
                         dbo.fn_XMLNode('Location',               @vLocation               ) +
                         dbo.fn_XMLNode('LocPutawayZone',         @vLocPutawayZone         ) +
                         dbo.fn_XMLNode('LocPickZone',            @vLocPickZone            ) +
                         dbo.fn_XMLNode('SuggDropLoc',            @vSuggestedDropLoc       ) +
                         dbo.fn_XMLNode('SuggDropZone',           @vSuggestedDropZone      ) +
                         dbo.fn_XMLNode('ScannedLocZoneDesc',     @vScannedDropLocZoneDesc ) +
                         dbo.fn_XMLNode('BulkPullBatch',          @vIsBulkPullBatch        ) +
                         dbo.fn_XMLNode('DisQualifiedOrderCount', @vDisQualifiedOrderCount ) +
                         dbo.fn_XMLNode('BusinessUnit',           @BusinessUnit            ) +
                         dbo.fn_XMLNode('UserId',                 @UserId                  ));

  /* Determine if the LPNs on the picked pallet should be unloaded into the Location or dropped */
  exec pr_RuleSets_Evaluate 'DropOrUnloadPickedPallet', @xmlRulesData, @vDropPalletDecision output;

  /* If there are no rules to drop the pallet then default allow to drop the Pallet */
  select @vDropPalletDecision = coalesce(@vDropPalletDecision, 'D' /* Drop */);

  /* Validate scanned Drop location */
  exec pr_RuleSets_Evaluate 'DropPallet_ValidateLocation', @xmlRulesData, @vDropLocationValidation output;

  /* Validations */
  if (@vLocationId is null)
    set @MessageName = 'LocationIsInvalid';
  else
  if (@vLocationStatus = 'I' /*Inactive*/)
    set @MessageName = 'LocationIsInactive';
  else
  if (@vWaveWarehouse is not null) and  -- if user doesn't scan Wave No in Get Batch Pick screen and trying to drop pallet without picking anything then WaveWarehouse would be null
     (@vLocationWarehouse not in (select TargetValue
                                  from dbo.fn_GetMappedValues('CIMS', @vWaveWarehouse,'CIMS', 'Warehouse', 'DropLocation', @BusinessUnit) ))
    set @MessageName = 'DropPallet_InvalidWarehouse';
  else
  if (@vPalletId is null)
    set @Messagename = 'PalletIsInvalid';
  else
  if (charindex(@vLocationType, @vValidDropLocationTypes) = 0)
    set @MessageName = 'DropPallet_InvalidLocation';
  else
  if (@vLocationType = 'K' /* Picklane */) and
     /* Todo: we are only using Inventory Pallets */
     (@vPalletType   = 'P' /* Picking */) and
     (exists(select * from LPNs L
             join OrderHeaders OH on (L.OrderId    = OH.OrderId) and
                                     (L.PalletId   = @vPalletId) and
                                     (OH.OrderType not in ('B', 'RU', 'RP', 'R'/* Bulk Order, Replenish */))))
    set @MessageName = 'CannotDropToPicklane';
  else
  if (@vIsBulkPullBatch = 'Y' /* Yes */) and (nullif(@vBatchDropLoc, '') is not null) and (@vBatchDropLoc <> @vDropLocation) and (@vLocationType = 'K')
    set @MessageName = 'CannotUseADifferentLocation';
  else
  if (@vDropLocationValidation <> '' /* Validation failed */)
    set @MessageName = @vDropLocationValidation; --'DropPallet_LocationFromDiffZone';
  else
  if (@vIsBulkPullBatch = 'Y' /* Yes */) and (nullif(@vBatchDropLoc, '') is null) and (@vLocationStatus <> 'E' /* Empty */) and (@vLocationType = 'K')
    select @MessageName = 'CannotUseAnotherBatchLocation';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (object_id('tempdb..#PickedLPNs') is null) select * into #PickedLPNs from @ttPickedLPNs;

  /* Get all the picked LPNs on the Pallet */
  insert into #PickedLPNs(EntityId, EntityKey)
    select LPNId, LPN
    from LPNs
    where (PalletId = @vPalletId) and (OrderId > 0) and (Quantity > 0)

  /* Get the distinct OrderId from LPNs on the given pallet. This needs to be
     done before the LPNs are removed off the Pallet */
  insert into @ttOrdersToUpdate (EntityId)
    select distinct OrderId
    from LPNs
    where (PalletId = @vPalletId) and
          (OrderId > 0) and
          (Quantity > 0) /* Pallet have the Empty cart postions so it will get the null values for the distinct orders  */

  /* Update the LPNs Status to Picked once after the Batch Picking is done. However when we are picking without allocation
     then do not mark LPNs are picked if there are unavailable lines on LPN. If the Tasks are not cubed, then do not mark
     the LPNs are picked if there outstanding picks for the Order */
  /* ??? why we are updating LPN Status here? - safety check in case we missed updating earlier? */
  /* This is obsolete */
--  if (@vTempLabelId is not null)
--    update LPNs
--    set Status = 'K' /* Picked */
--    output Deleted.LPNId, Deleted.LPN into @ttPickedLPNs
--    where (PalletId = @vPalletId) and
--          (Status   = 'U' /* Picking */) and
--          (Quantity > 0) and
--          (LPNId not in (select TempLabelId from TaskDetails where TaskId = @vTaskId and Status not in ('C','X')))
--  else
  /* Let LPNs be marked as picked even if task not completed if we are unloading incomplete LPNs into the Location */
  if (@vDropPalletDecision in ('UA', 'UI' /* Unload All, Unload incomplete ones */))
    update LPNs
    set Status = 'K' /* Picked */
    output Deleted.LPNId, Deleted.LPN into @ttPickedLPNs
    where (PalletId = @vPalletId) and
          (Status   = 'U' /* Picking */) and
          (Quantity > 0)
  else
  /* If decision is to drop dis-qualified orders then drop only the LPNs for which orders are disqualified */
  if (@vDropPalletDecision in ('UD' /* Unload Dis-Qualified Orders */))
    update L
    set Status = 'K' /* Picked */
    output Deleted.LPNId, Deleted.LPN into @ttPickedLPNs
    from LPNs L
      join @ttDisQualifiedOrders ttDQO on (L.OrderId = ttDQO.EntityId)
    where (PalletId = @vPalletId) and
          (Status   = 'U' /* Picking */) and
          (Quantity > 0);
  else
  if (@vDropPalletDecision = 'UC' /* Unload completed */)
    update LPNs
    set Status = 'K' /* Picked */
    output Deleted.LPNId, Deleted.LPN into @ttPickedLPNs
    where (PalletId = @vPalletId) and
          (Status   = 'U' /* Picking */) and
          (Quantity > 0) and
          (OrderId not in (select OrderId from TaskDetails where TaskId = @vTaskId and Status not in ('C','X')))

  /* Unload the Picked LPNs on pallet as required */
  if (@vDropPalletDecision in ('UA', 'UC', 'UD' /* Unload */)) and
     (@vLocationType <> 'K')
    begin
      /* Get the picked LPNs into a temp table. Alternate LPN is the cart position of the LPN */
      insert into @ttUnloadLPNsOnPallet(EntityId, EntityKey)
        select LPNId, AlternateLPN
        from LPNs
        where (PalletId = @vPalletId) and
              (Status   in ('K', 'D', 'E' /* Picked, Packed, Staged */)) and
              (LPNType not in ('A' /* Cart */));

      /* When user drops the pallet, if there are picked LPNs on the pallet we can remove
         them from the pallet and just set LPN.Location to the Drop Location. We also have
         to do clear Alternate LPN as this point. */
      exec pr_Picking_UnloadLPNsFromPallet @ttUnloadLPNsOnPallet, @vLocationId, @BusinessUnit, @UserId;
    end /* Unload Picked LPNs */

  if (@vDropPalletDecision = 'UI' /* Unload incomplete LPN */) and
     (@vLocationType <> 'K')
    begin
      /* Get the Picking LPNs into a temp table. Alternate LPN is the cart position of the LPN */
      insert into @ttUnloadLPNsOnPallet(EntityId, EntityKey)
        select LPNId, AlternateLPN
        from LPNs
        where (PalletId = @vPalletId ) and
              (Status in ('U', 'F' /* Picking, New Temp label */)) and
              (LPNType not in ('A' /* Cart */));

      exec pr_Picking_UnloadLPNsFromPallet @ttUnloadLPNsOnPallet, @vLocationId, @BusinessUnit, @UserId;
    end /* Unload incomplete LPNs */

  /* Temp fix - update all counts on the pallet */
  exec pr_Pallets_UpdateCount @vPalletId, null, '*' /* Recompute */;

  /* Update PickBatch with the USER SCANED destination Location */
  /* Update PickBatches   -- This is not required anymore as rules will take care of it
  set DropLocation = coalesce(nullif(@vDropLocation, ''), DropLocation)
  where BatchNo = @vPickBatchNo; */

  /* Update Pallets with the Location if the location type is not a PickLane */
  /* Drop pallet only if the LPNs are not unloaded */
  if (@vLocationType <> 'K'/* PickLane */) and (@vDropPalletDecision = 'D'/* Drop */)
    exec pr_Pallets_SetLocation @vPalletId, @vLocationId, 'Y' /* @vUpdateLPNLocation */,
                                @BusinessUnit, @UserId;
  else
  if (@vLocationType = 'K'/* PickLane */)
    begin
     /* Transfer the Picked LPNs on the pallet to PickLane Locations (Processing) area
         'TransferAfterPicking' Operation: used to transfer OrderId/OrderDetailId to To LPNs (logical) - used in pr_RFC_TransferInventory */
      select @vxmlInput = dbo.fn_XMLNode('Root',
                            dbo.fn_XMLNode('PalletId',       @vPalletId) +
                            dbo.fn_XMLNode('Pallet',         @PalletToDrop) +
                            dbo.fn_XMLNode('LocationId',     @vLocationId) +
                            dbo.fn_XMLNode('Location',       @vDropLocation) +
                            dbo.fn_XMLNode('DeviceId',       @DeviceId) +
                            dbo.fn_XMLNode('UserId',         @UserId) +
                            dbo.fn_XMLNode('BusinessUnit',   @BusinessUnit) +
                            dbo.fn_XMLNode('Operation',      'TransferAfterPicking'));

      exec @ReturnCode = pr_Pallets_TransferToPicklane @vxmlInput, null /* xmlResult */

      /* Set Order and Batch Status to Picked if everything Picked is transfered */
      /* Get Order Total Units Assigned Qty and Location Qty and see if both are same,
         set Order status to Picked and then Batch status to Picked */
      select @vXferedQty = Quantity
      from Locations
      where Location = @vDropLocation;

      select @vOrderId       = OH.OrderId,
             @vOrderType     = OH.OrderType,
             @vUnitsAssigned = OH.UnitsAssigned
      from PickBatches PB
        join OrderHeaders OH on (PB.BatchNo = OH.PickBatchNo) and (OH.OrderType = 'B' /* Bulk Order */)
      where PB.BatchNo = @vPickBatchNo;

      /* Update the Status of the bulk Order to Picked */
      if (@vOrderType = 'B' /* Bulk Pull */) and (@vXferedQty = @vUnitsAssigned)
        begin
          exec pr_OrderHeaders_SetStatus @vOrderId, 'P' /* Picked */;
          exec pr_PickBatch_SetStatus @vPickBatchNo, 'K' /* Picked  */, @UserId;
        end
    end /* LocationType = K */

  /* Set the status of the batch after picking of bulk pull order was completed.*/
  if ((@vPickBatchType = 'U' /* Piece Pick */) and
      (@vPickBatchStatus in ('E' /* Being Pulled */, 'R' /* Ready To Pick */)) and
      (exists(select *
              from OrderHeaders
              where ((PickBatchNo = @vPickBatchNo) and
                     (OrderType   = 'B' /* Bulk Pull*/) and
                     (Status      = 'P' /* Picked */)))))
     begin
       /* Set the Batch Status to Ready to Pick if once the Bulk Pull Order is
          completely picked */
       if (@vPickBatchStatus <> 'R'/* Ready To Pick */)
         exec pr_PickBatch_SetStatus @vPickBatchNo, 'R' /* Ready to pick */, @UserId;

       /* Update the Orders on the batch to Batched Status */
       update OrderHeaders
       set Status       = 'W' /* Batched */,
           ModifiedDate = current_timestamp,
           ModifiedBy   = coalesce(@UserId, System_User)
       where (PickBatchNo = @vPickBatchNo) and
             (OrderType   <> 'B'/* Bulk Type */);
     end

  /* Update status of the Pallet - It may be Picked if all LPNs were picked or else it may be in Picking status
     or even Empty if LPNs have been unloaded before */
  exec pr_Pallets_SetStatus @vPalletId, @vPalletStatus output;

  /* Delete other than the picked LPNs as some of the LPN's status may not be picked yet */
  delete PL
  from #PickedLPNs PL
    join LPNs L on (L.LPNId = PL.EntityId)
  where (L.Status not in ('K', 'E' /* Picked, Staged */));

  /* Execute rules for any futher custom processes after dropping */
  exec pr_RuleSets_ExecuteAllRules 'DropPallet_AfterDrop', @xmlRulesData, @BusinessUnit;

  /* if there are changes on the Order Line then call OrderHeader Recalculate to update the counts & status on the PickTicket */
  if exists(select * from @ttOrdersToUpdate)
    exec pr_OrderHeaders_Recalculate @ttOrdersToUpdate, '$CS' /* compute - Counts & Status only */, @UserId, @BusinessUnit;

  /* Update the Wave status after drop the Pallet */
  exec pr_PickBatch_SetStatus @vPickBatchNo, '$S' /* Status: Calculate */, @UserId, default /* PickBatchId */;

  /* if there are any LPNs are updated as marked then we need to export them
     case:if the user partially picked and dropped the pallet then we need to
          export these details  */
  if (exists (select * from @ttPickedLPNs))
    begin
      exec pr_Picking_ExportDataOnLPNPicked @vPickBatchId, null /* LPNId */, @ttPickedLPNs,
                                            @BusinessUnit, @UserId;
    end

  /* Get Confirmation Message */
  set @ConfirmDropPalletMessage = dbo.fn_Messages_GetDescription('DroppedPalletComplete');

  /* Get Pallet Qty to determine if there is more on Pallet and to navigate accordingly on RF */
  select @vPalletQty = Quantity from Pallets where (PalletId = @vPalletId);

  /* XmlMessage to RF, after Pallet is dropped to a Location */
  set @xmlResult = (select 0                         as ErrorNumber,
                           @ConfirmDropPalletMessage as ErrorMessage,
                           @vDropPalletDecision      as DropPalletDecision,
                           @vPalletStatus            as PalletStatus,
                           @vPalletQty               as PalletQuantity
                    FOR XML RAW('DROPPEDPALLETINFO'), TYPE, ELEMENTS XSINIL, ROOT('DROPPEDPALLETDETAILS'));

  /* Update Device details */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'DroppedPickedPallet', @xmlResultvar, @@ProcId;

  /* Insert audit record for every successful transaction */
  exec pr_AuditTrail_Insert 'PickPalletDropped', @UserId, null /* ActivityTimestamp */,
                            @PalletId      = @vPalletId,
                            @LocationId    = @vLocationId,
                            @PickBatchId   = @vPickBatchId,
                            @AuditRecordId = @vAuditRecordId output;

  -- /* Insert the  audit record on LPNs once they are dropped */
  -- exec pr_AuditTrail_Insert 'LPNsOnPickPalletDropped', @UserId, null /* ActivityTimestamp */,
  --                           @BusinessUnit  = @BusinessUnit,
  --                           @Note1         = @vLocation,
  --                           @AuditRecordId = @vAuditRecordId output;

  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttUnloadLPNsOnPallet, @BusinessUnit;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Add to RF Log */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;

end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_DropPickedPallet */

Go
