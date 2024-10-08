/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/06  MS      pr_Picking_OnPicked: Changes to update Pallet Status after LPN Recount for LPN Picks (BK-327)
  2021/05/04  MS      pr_Picking_OnPickedToLPN: Changes to update Pallet Status after LPN Recount (BK-319)
  2021/04/09  RV/AY   pr_Picking_OnPickedToLPN, pr_Picking_OnPicked : Made changes to update the inventory class1 based upon the rules (HA-2580)
  2021/03/02  RKC     pr_Picking_OnPicked, pr_Picking_ConfirmPicks: Made changes to update the TaskId on the picked LPNs (HA-2105)
  2021/02/24  VS      pr_Picking_OnPicked: Get Location info from TaskDetail, if not available from picked LPN (HA-2065)
  2021/02/16  TD      pr_Picking_OnPicked:update the LPN Status before we call Pallet Status (BK-190)
  2020/10/20  SK      pr_Picking_OnPicked, pr_Picking_OnPickedToLPN: Modified to include FromLPN, FromLocation and option to send pick transaction
  2020/10/19  TK      pr_Picking_OnPickedToLPN: Recount LPN instead of just updating status (HA-1588)
  2020/09/28  SK      pr_Picking_OnPicked: Pass value to insert TaskId into Audit entries
  2020/08/17  RKC     pr_Picking_OnPicked: Made changes to update the LPN Type to S for LPN picks (HA-1235)
  2020/01/24  AY      pr_Picking_OnPickedToLPN: performance optimization
  2019/12/26  TD      pr_Picking_OnPicked:Performance changes.
                      pr_Picking_OnPickedToLPN: Bug fix not to clear PalletId on Picked LPN (S2GCA-534)
  2018/04/17  OK      pr_Picking_OnPicked: Changes to send remaining open picks for LPN to Rules (S2G-Support)
  2018/04/11  AY      pr_Picking_OnPickedToLPN: Enhanced to use rules for To LPN Status
                      pr_Picking_OnPickedToLPN: Changes to update the WaveDropLocation in Routing Instructions (S2G-587)
  2018/03/28  RV      pr_Picking_OnPicked: On Picked ToLPN status decision moved to rules (S2G-503)
  2018/03/16  RV      pr_Picking_OnPicked: Made changes to do not allow multiple replenish case picks
  2016/11/13  VM      pr_Picking_ConfirmTaskPicks, pr_Picking_OnPickedToLPN, pr_Picking_ConfirmTaskPicks_LogAuditTrail: (HPI-993)
  2016/07/04  KL      pr_Picking_OnPicked: Made changes to send the update option to calling procedure pr_LPNs_SetLocation (HPI-220)
  2016/01/20  SV      pr_Picking_OnPicked: Updating the weight over LPN while picking - This gives the correct value in BoL report for LPNs and Orders (CIMS-741)
  2015/06/08  TD      pr_Picking_ConfirmUnitPick, pr_Picking_OnPicked: Changes update orderdetails, and other fields
  2014/06/07  TD      pr_Picking_OnPicked:Updating DestLocation and DestZone on the PickedLPN for the replenishments.
  2014/05/28  TD      pr_Picking_OnPicked: Ignoring import and export to the srtLPNs if the destination of the
  2014/04/29  PK      pr_Picking_OnPicked: Code optimization
  2014/04/25  PK      pr_Picking_OnPicked: Sending Exports to Router.
  2014/04/11  PK      Added pr_Picking_OnPicked.
                      pr_Picking_ConfirmLPNPick, pr_Picking_ConfirmUnitPick: Moved the logic to the new procedure pr_Picking_OnPicked.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_OnPicked') is not null
  drop Procedure pr_Picking_OnPicked;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_OnPicked:
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_OnPicked
  (@PickBatchNo      TPickBatchNo,
   @OrderId          TRecordId,
   @PalletId         TRecordId,
   @LPNId            TRecordId,
   @PickType         TTypeCode,
   @NewLPNStatus     TStatus,
   @UnitsPicked      TQuantity,
   @TaskDetailId     TRecordId,
   @ActivityType     TActivityType = 'UnitPick',
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode             TInteger,
          @vMessage                TMessage,

          @vBatchType              TTypeCode,

          /* Order */
          @vOrderId                TRecordId,
          @vOrderType              TTypeCode,
          @vOrderStatus            TStatus,
          @vNewOrderStatus         TStatus,
          @vOrderWarehouse         TWarehouse,
          @vOpenPicksForToLPN      TCount,

          /* LPN */
          @vLPNId                  TRecordId,
          @vLPN                    TLPN,
          @vDestZone               TZoneId,
          @vPalletId               TRecordId,
          @vLPNShipmentId          TRecordId,
          @vLPNLoadId              TRecordId,
          @vLPNTaskId              TRecordId,
          @vLPNTaskDetailId        TRecordId,
          @FromLocation            TLocation,
          @vFromLocationType       TTypeCode,
          @vSKUId                  TRecordId,
          @vPickBatchId            TRecordId,

          /* Audit Log */
          @FromLocationId          TRecordId,
          @FromLPNId               TRecordId,
          @vFromLPNType            TTypeCode,
          @FromLPNDetailId         TRecordId,
          @OrderDetailId           TRecordId,
          @ToLPNDetailId           TrecordId,
          @vToLPNlineQty           TQuantity,
          @vNewToLPNLineId         TRecordId,
          @ActivityDate            TDateTime,
          @vLPNLocationId          TRecordId,
          @vLPNLocation            TLocation,
          @vToLPNDetailId          TRecordId,

          /* Common */
          @vDefaultDropLocation    TLocation,
          @vWaveDropLocation       TLocation,
          @vPickingPalletId        TRecordId,
          @vNewLPNStatus           TStatus,
          @vFlag                   TFlag,
          @vIsLabelGenerated       TFlags,
          @vRecalculateLPNWeight   TFlags,
          @vAvailReserveLineId     TRecordId,
          @vIsTaskAllocated        TFlags,
          @vInsertShipLabels       TFlags,

          @xmlRulesData            TXML,

          /* Controls -- Need to move them to Rules */
          @vOrderTypesToExportToPanda  TControlvalue,
          @vWarehousesToExportToPanda  TControlvalue,
          @vBatchTypeToExportToSorter  TControlvalue,

          /* Rules */
          @vExportToRouter             TResult,
          @vExportToHost               TResult,

          /* Temp Tabel */
          @ttPickedLPNs             TEntityKeysTable;

begin /* pr_Picking_OnPicked */

  /* Get Batch info */
  select @vBatchType        = BatchType,
         @vWaveDropLocation = DropLocation
  from PickBatches
  where (BatchNo = @PickBatchNo)

  /* Get Order info */
  select @vOrderId        = OrderId,
         @vOrderType      = OrderType,
         @vOrderStatus    = Status,
         @vOrderWarehouse = Warehouse
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get LPN info */
  select @vLPNId         = LPNId,
         @vLPN           = LPN,
         @vLPNShipmentId = nullif(ShipmentId, 0),
         @vLPNLoadId     = nullif(LoadId, 0),
         @vPalletId      = PalletId,
         @vDestZone      = DestZone,
         @UnitsPicked    = coalesce(@UnitsPicked, Quantity),
         @FromLocationId = LocationId,
         @FromLPNId      = LPNId,  /* if the pick type is LPN then we will use this for audit log */
         @vPickBatchId   = PickBatchId
  from LPNs
  where (LPNId = @LPNId);

  /* Get the number of open picks for the ToLPN */
  select @vOpenPicksForToLPN = count(*)
  from TaskDetails
  where (TempLabelId = @vLPNId) and (Status not in ('X' /* Canceled */, 'C' /* Completed */));

  /* Get the LPN Tasks info */
  /* Duplicate records are being inserted in LPNTasks. Hence wrong value to ToLPNDetailId will be us updated
       in some cases. Hence with joining TaskDetails, fetching the correct values.
     For ref: This is noted in HPI-1248 and resolved against HPI-1261 */
  select @vLPNTaskId       = LT.TaskId,
         @vLPNTaskDetailId = LT.TaskDetailId,
         @ToLPNDetailId    = TD.TempLabelDetailId,
         @vDestZone        = coalesce(@vDestZone, LT.DestZone) --In perfect world this would not required..
  from vwLPNTasks LT
  join TaskDetails TD on (LT.TaskDetailId = TD.TaskDetailId) and
                         (LT.Quantity     = TD.Quantity)
  where (LT.LPNId = @LPNId) and
        (LT.TaskDetailId = coalesce(@TaskDetailId, LT.TaskDetailId));

  /* Other than task which does not haves the temp table for this type of Waves does not have the records in the
     LPNTasks table so for that type of waves we need to get the TaskId from taskdetails based on the picking LPNId */
  if (@vLPNTaskId is null) and (@PickType = 'L' /* LPN pick */)
    begin
      select distinct @vLPNTaskId  = TaskId
      from TaskDetails
      where (LPNId = @LPNId) and (status not in ('X','C'))
    end

  /* New Change - If there are two LPNTask Detail lines but after replenishments we are merging the LPNDetails but not the LPNTasks and so
     the lines might not even exists in the LPNDetails. Considering that we are verifying if the LPNDetailId exists or not and if not then
   marking the @ToLPNDetailId variable as null  */
  if (@ToLPNDetailId is not null)
    begin
      select @vToLPNDetailId = LPNDetailId
      from LPNDetails
      where (LPNDetailId = @ToLPNDetailId);

      if (@vToLPNDetailId is null)
        select @ToLPNDetailId = null;
    end

  /* Get Pallet Info */
  select @vPickingPalletId = PalletId,
         @vLPNTaskDetailId = coalesce(@vLPNTaskDetailId, @TaskDetailId)
  from Pallets
  where (PalletId = @PalletId);

  /* need to get the details from taskdetils for audit listing */
  if (@vLPNTaskDetailId is not null)
    select @FromLocationId    = LocationId,
           @FromLPNId         = LPNId,
           @FromLPNDetailId   = LPNDetailId,
           @OrderDetailId     = OrderDetailId,
           @FromLocation      = Location,
           @vFromLocationType = LocationType,
           @vSKUId            = SKUId,
           @vIsLabelGenerated = IsLabelGenerated,
           @ActivityDate      = current_timestamp
    from vwTaskDetails
    where (TaskDetailId  = @vLPNTaskDetailId);

  /* Get LPN info - Location info might have been already cleared by this time, if so get it from TaskDetail */
  select @FromLocationId = coalesce(@FromLocationId, LocationId),
         @FromLocation   = coalesce(@FromLocation, Location),
         @vFromLPNType   = LPNType
  from LPNs
  where (LPNId = @FromLPNId);

  /* for unit picks we need to get the LPNDetailId */
  if (@ToLPNDetailId is null)
    select @ToLPNDetailId = LPNDetailId,
           @vToLPNlineQty = Quantity
    from LPNDetails
    where (LPNId         = @LPNId) and
          (SKUId         = @vSKUId) and
          (OrderDetailId = @OrderDetailId);
  else /* Get line qty here from the tolpn line */
    select @vToLPNlineQty = Quantity
    from LPNDetails
    where (LPNDetailId = @ToLPNDetailId);

  /* Get task header info here */
  select @vIsTaskAllocated = IsTaskAllocated
  from Tasks
  where (TaskId = @vLPNTaskId);

  /* Get if there is any reserved line for the same SKU on the same LPN */
  select @vAvailReserveLineId = LPNDetailId
  from LPNDetails
  where (LPNId         = @LPNId    )  and
        (SKUId         = @vSKUId   )  and
        (OnHandStatus  = 'R' /* Reserve */) and
        (OrderDetailId = @OrderDetailId);

  /* Update LPN DestLocation to as replenished Location
     if the Order type is replenish Order */
  if (@vOrderType in ('RU', 'RP', 'R' /* Replenish Units, Replenish Cases */))
    exec pr_LPNs_SetDestination @LPNId, 'ReplenishPick';

  /* Build the XML for record with all data required for rules */
  select @xmlRulesData = '<RootNode>' +
                            dbo.fn_XMLNode('WaveType',         @vBatchType)   +
                            dbo.fn_XMLNode('OrderType',        @vOrderType)   +
                            dbo.fn_XMLNode('PickType',         @PickType) +
                            dbo.fn_XMLNode('IsLabelGenerated', @vIsLabelGenerated) +
                            dbo.fn_XMLNode('TaskId',           @vLPNTaskId) +
                            dbo.fn_XMLNode('OpenPicks',        @vOpenPicksForToLPN) +
                            dbo.fn_XMLNode('FromLocationType', @vFromLocationType) +
                            dbo.fn_XMLNode('FromLPNType',      @vFromLPNType) +
                            dbo.fn_XMLNode('LPNId',            @LPNId) +
                            dbo.fn_XMLNode('LPN',              @vLPN) +
                            dbo.fn_XMLNode('BusinessUnit',     @BusinessUnit) +
                            dbo.fn_XMLNode('UserId',           @UserId) +
                         '</RootNode>';

  /* Get ToLPN status */
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_Status', @xmlRulesData, @vNewLPNStatus output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_ExportToRouter', @xmlRulesData, @vExportToRouter output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_ExportToHost', @xmlRulesData, @vExportToHost output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_InsertShipLabels', @xmlRulesData, @vInsertShipLabels output;

  select @vFlag = case
                    when (@PickType = 'L' /* LPN Pick */)
                      then 'Y' /* Yes */
                    when (@PickType = 'U' /* Unit Pick */)
                      then 'N' /* No */
                    else
                      'N' /* No */
                  end;

  /* Get the control variables */
  select @vOrderTypesToExportToPanda = dbo.fn_Controls_GetAsString('Panda',  'OrderTypesToExport', ''  /* None */, @BusinessUnit, @UserId),
         @vWarehousesToExportToPanda = dbo.fn_Controls_GetAsString('Panda',  'WarehousesToExport', ''  /* None */, @BusinessUnit, @UserId),
         @vBatchTypeToExportToSorter = dbo.fn_Controls_GetAsString('Sorter', 'ExportLPN_' + @vBatchType,  'N' /* No */  , @BusinessUnit, @UserId),
         @vRecalculateLPNWeight      = dbo.fn_Controls_GetAsBoolean('Picking', 'ReCalculateWeightOnLPN', 'N' /* No */, @BusinessUnit, @UserId);

  /* Change the LPNType to S for LPN pick */
  if (@PickType = 'L' /* LPN pick */) and (@vOrderType in ('C', 'CO', 'T'))
    update LPNs
    set LPNType = 'S',
        TaskId  = case when @vOrderType = 'T' then @vLPNTaskId else TaskId end
    where (LPNId = @LPNId);

  /* Update Status, OnhandStatus of LPN */
  exec pr_LPNs_SetStatus @LPNId, @vNewLPNStatus, 'R' /* Reserved */;

  /*---- LPN Status has to be updated before it is added to Pallet so that Pallet status would be right ---- */

  /* If LPN is not on pallet, locate it onto Picking Pallet */
  if (@vPickingPalletId is not null) and (@vPickingPalletId <> coalesce(@vPalletId, 0))
    exec pr_LPNs_SetPallet @vLPNId, @vPickingPalletId, @UserId;

  /* Update weight on LPNDetail if it is LPNPick and call the LPN Recount procedure to update the weight over LPN.
     Generally, we can update directly over LPN without updating on its detail. But to be accurate we are updating
     on Detail and calling the Recount procedure */
  if (@vRecalculateLPNWeight = 'Y' and @ActivityType = 'LPNPick')
    begin
      update LD
      set LD.Weight = coalesce(S.UnitWeight * LD.Quantity, 0)
      from LPNDetails LD
        join SKUs S on (LD.SKUId = S.SKUId) and (LD.OnhandStatus = 'R')
      where (LD.LPNId = @LPNId);

      exec pr_LPNs_Recount @LPNId;
    end

  /* Update counts on the Pallet */
  if (@vPickingPalletId = @vPalletId)
    exec pr_Pallets_UpdateCount @vPickingPalletId, @UpdateOption = '*';

  /* If the LPN is not associated with a Shipment or Load, then find one and add to it */
  if ((@vLPNShipmentId is null) or (@vLPNLoadId is null)) and
     (@vOrderType not in ('B' /* Bulk Order */, 'R' /* Replenishment */))
    exec pr_LPNs_AddToALoad @vLPNId, @BusinessUnit, 'Y' /* Yes - @LoadRecount */, @UserId;

  /* Set PickTicket Header Counts and Status */
  exec @vReturnCode = pr_OrderHeaders_Recount @vOrderId;

  /* Set Order Header Counts and Status. Though this is done in AllocateLPN,
     we still need to do this again because LPN is now marked as Picked */
  exec pr_OrderHeaders_SetStatus @vOrderId, @vNewOrderStatus output;

  /* Update batch status in case order is on a batch and it's status has changed */
  if (@PickBatchNo is not null) and (@vOrderStatus <> @vNewOrderStatus)
    exec pr_PickBatch_SetStatus @PickBatchNo, Default /* Status */, @UserId;

  /* If the Pick is not Full case pick */
  if (@vFlag  = 'N' /* No */)
    begin
      /* if user trying to pick partially  and task is not allocated against to
         inventory then we need to split the line */
      if ((@vToLPNlineQty > coalesce(@UnitsPicked, 0)) and (@vIsLabelGenerated = 'Y')) /* Yes */
        begin
          exec pr_LPNDetails_SplitLine @ToLPNDetailId, 0 /* Innerpacks */,
                                       @UnitsPicked, @vOrderId, @OrderDetailId,
                                       @vNewToLPNLineId output;
        end
      else
        set @vNewToLPNLineId = @ToLPNDetailId;

      --if (@vAvailReserveLineId is not null)
        --begin
          --exec pr_LPNDetails_MergeLine @ToLPNDetailId, 0 /* Innerpacks */,
           --                            0, @vOrderId, @OrderDetailId,
           --                            'MergeReserve_Line', @vNewToLPNLineId output;
        --end

      /* Update LPNDetails onhandstatus for the picked line */
      update LPNDetails
      set OnhandStatus = 'R'
      where (LPNDetailID = @vNewToLPNLineId);

      /* If Order status is Picked then update all LPNs status which where
         Picked for the Order to picked status */
      if (@vNewOrderStatus = 'P'/* Picked */)
        update LPNs
        set Status       = 'K' /* Picked */,
            ModifiedDate = current_timestamp,
            ModifiedBy   = coalesce(@UserId, System_User)
        output Deleted.LPNId, Deleted.LPN into @ttPickedLPNs
         where ((@vPickingPalletId is null and PalletId is null) or
                (PalletId         = @vPickingPalletId)) and
                (OrderId          = @vOrderId) and
                (Status           not in ('K' /* Picked */, 'L', 'S'));

      /* Unassign the variables */
      if (@@rowcount > 0)
        select @vLPNId = null, @vLPN = null;
    end

  /* we need to update the picked by, picked date and picked from info here ..*/
  update LPNDetails
  set ReferenceLocation = substring(coalesce(ReferenceLocation + ',' + rtrim(@FromLocation), rtrim(@FromLocation)), 1, 50),
      PickedBy          = @UserId,
      @ActivityDate     =
      PickedDate        = current_timestamp
  where (LPNId = @LPNId);

  /* Insert the Picked LPN Details into SrtrLPNs if the destination is not a shipdock.
     If  the destination is ShipDock then we need to do export the details with
     pick type transactions */
  if (@vDestZone = 'SHIPDOCK')
    begin
       exec @vReturnCode = pr_Exports_LPNData 'Pick', 'LPN', null /* TransQty */,
                                              @LPNId = @vLPNId;
    end
  else
    begin
      /* Export to Panda if LPNs are picked */
      if (charindex(@vOrderType, @vOrderTypesToExportToPanda) > 0) and
         (charindex(@vOrderWarehouse, @vWarehousesToExportToPanda) > 0)
        exec pr_PandA_AddLPNForExport @vLPN /* LPN */, @ttPickedLPNs,
                                      default /* LabelType */, default /* Label format */,
                                      null /* PandAStation */, null /* ProcessMode */,
                                      default /* DeviceId */, @BusinessUnit, @UserId;

      if (@vBatchTypeToExportToSorter <> 'N' /* No */)
        begin
          exec pr_Sorter_InsertLPNDetails @vLPNId, @ttPickedLPNs, null /* Sorter Name */,
                                          @BusinessUnit, @UserId;

          /* Export the Picked LPNDetails to the Sorter if ExportToSorter is to be done on Picked */
          if (@vBatchTypeToExportToSorter in ('P' /* On Picked */))
            exec pr_Sorter_ExportLPNDetails @vLPNId, null /* Sorter Name */, @BusinessUnit, @UserId;
        end
    end

  /* Insert the Router Instruction into RouterInstruction table */
  if (@vExportToRouter = 'Y' /* Yes */)
    exec pr_Router_SendRouteInstruction @vLPNId, @vLPN, @ttPickedLPNs,
                                        @vWaveDropLocation /* Destination */, default /* WorkId */, 'N' /* @ForceExport */,
                                        @BusinessUnit, @UserId;

  /* Send Pick Transactions, if applicable
     For lpn picks given LPN is From LPN
     For unit picks the work flow is different */
  if (@vExportToHost = 'DuringPicking') and (@ActivityType = 'LPNPick')
     exec @vReturnCode = pr_Exports_LPNData 'Pick', 'LPN', null /* TransQty */,
                                            @LPNId          = @vLPNId,
                                            @FromLPNId      = @vLPNId,
                                            @FromLPN        = @vLPN,
                                            @FromLocationId = @FromLocationId,
                                            @FromLocation   = @FromLocation;

  /* AuditTrail */
  exec pr_AuditTrail_Insert @ActivityType, @UserId, @ActivityDate,
                            @BusinessUnit  = @BusinessUnit,
                            @LocationId    = @FromLocationId,
                            @LPNId         = @FromLPNId,
                            @LPNDetailId   = @FromLPNDetailId,
                            @ToLPNDetailId = @ToLPNDetailId,
                            @OrderDetailId = @OrderDetailId,
                            @Quantity      = @UnitsPicked,
                            @PalletId      = @vPalletId,
                            @ToPalletId    = @vPickingPalletId,
                            @OrderId       = @OrderId,
                            @PickBatchId   = @vPickBatchId,
                            @TaskId        = @vLPNTaskId;

  /* Execute rules for things to happen when LPN is picked */
  exec pr_RuleSets_ExecuteAllRules 'OnPicked', @xmlRulesData, @BusinessUnit;

end /* pr_Picking_OnPicked */

Go
