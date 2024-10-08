/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/14  VS      pr_PickBatch_SetStatus, pr_Wave_ReleaseToWSS: Passed EntityStatus Parameter (BK-910)
  2021/08/11  AY      pr_PickBatch_SetStatus : By default defer updating the wave status and always return WaveId (HA-3070)
  2021/05/24  AY      pr_PickBatch_SetStatus: Fixed issue with ReservedUnit calculation when ShipCartons are generated for PTC (BK-334)
  2021/04/20  TK      pr_Wave_InventorySummary & pr_PickBatch_SetStatus:
  2020/07/17  MS/AY   pr_PickBatch_SetStatus: Changes to update status to ReasyToPick if all units are UnAllocated in LPNReservation (HA-817)
                      pr_PickBatch_SetStatus: Changes to update LPN Counts (HA-691)
  2020/05/21  VS      pr_PickBatch_SetStatus: Show correct #Reserved count for Wave (HA-561)
  2020/05/15  TK      pr_Wave_ReleaseForAllocation & pr_PickBatch_SetStatus:
  2019/02/04  TK      pr_PickBatch_SetStatus: Changes to mark Rework wave as picked (S2GCA-480)
  2018/12/11  VS      pr_PickBatch_SetStatus: Replenishment wave marked as shipped status (OB2-682)
  2018/09/07  AY      pr_PickBatch_SetStatus: Bug fix - Wave going to Packing status when it shouldn't (S2GCA-247)
  2018/08/08  AY      pr_PickBatch_SetStatus: Update all Order Counts
  2018/08/07  TK      pr_PickBatch_UpdateCounts & pr_PickBatch_SetStatus: Changes to defer Wave Counts/Status updates (S2GCA-117)
  2018/07/21  RV      pr_PickBatch_SetStatus: Made changes to update order and units counts on Waves (S2G-1030)
  2017/04/11  RV      pr_PickBatch_SetStatus: Initialized the BusinessUnit from PickBatches (HPI-1256)
  2016/06/20  TD      pr_PickBatch_SetStatus:Considering packed and packing status units as picked units.
  2015/12/10  DK      pr_PickBatch_SetStatus: Excluded validating IsAllocated status of batch while marking status as Picked (FB-567).
  2015/10/19  AY      pr_PickBatch_SetStatus: Enhanced to make it easier to debug
  2015/05/12  TD      pr_PickBatch_SetStatus:Batch SetStatus Changes.
  2015/05/01  RV      pr_PickBatch_SetStatus: Remove the seperate calucation of Shipped and Cancel orders.
  2015/04/20  AY      pr_PickBatch_SetStatus: Mark batch as shipped when all Orders are shipped
  2015/04/14  AY      pr_PickBatch_SetStatus: Calculate Status based upon either TotalUnits or AllocatedUnits
  2015/03/23  TK      pr_PickBatch_SetStatus: Exclude LPN Detail quantities if OnHandStatus is Directed.
  2015/02/06  TK      pr_PickBatch_SetStatus: Enhanced for partially allocated Batches
  2013/12/31  TD      pr_PickBatch_SetStatus: Changes to calculate status based on the TotalUnits on the batch.
  2013/12/20  TD      pr_PickBatch_SetStatus:bug fix: Set batch status as Picking based on the taskdetail quantity.
  2013/12/09  TD      pr_PickBatch_SetStatus: Bug fix- Batch set status changed to calculate based on the
  2013/10/05  AY      pr_PickBatch_SetStatus: Revised for new model of Order Details being batched
  2013/09/16  PK      pr_PickBatch_SetStatus: Changes to update Batch Status by Calculating from Batched OrderDetails.
  2013/02/01  VM/AY   pr_PickBatch_SetStatus: If nothing got satisfied to set status, set default to 'Picking'
              AY      pr_PickBatch_SetStatus: If all Orders are staged, then Batch still ends up in Picking only
                      pr_PickBatch_SetStatus: Corrected to set status considering Staged Orders
  2012/07/23  YA      pr_PickBatch_SetStatus: Correction: (@vPickingCount > 1) => (@vPickingCount > 0)
  2012/06/22  PK      pr_PickBatch_SetStatus: Handled to update status of Batch, If the batch has a Bulk Order.
  2012/02/03  PK      pr_PickBatch_SetStatus: Recomputing of Batch Status.
  2011/11/24  YA      pr_PickBatch_SetStatus: Unassign Pallet info on Batch, if it sets back to "Ready To Pick"
  2011/08/24  PK      Added pr_PickBatch_SetStatus.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_SetStatus') is not null
  drop Procedure pr_PickBatch_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_SetStatus: This procedure sets the status of the batch to
  the given status if given or else computes the status of the batch based upon
  the orders on the batch.

  PickBatch Status can be determined based upon Allocated Units of the Batch or
  the total units. For example, if the batch has 100 units and only 98 were allocated
  and picked should it be considered as picked or picking? Similarly, if 98 were
  picked, packed and loaded, should it be considered as Loaded because all allocated
  units are Loaded or still be considered as 'Picking' because 2 units are not
  allocated yet? Different clients do it differently and hence we will use a control
  var based upon BatchType to determine which model to use.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_SetStatus
  (@PickBatchNo     TPickBatchNo,
   @BatchStatus     TStatus = '$' output,
   @ModifiedBy      TUserId = null,
   -----------------------------------------
   @PickBatchId     TRecordId = null output)
as
  declare @vReturnCode             TInteger,
          @vWaveId                 TRecordId,
          @vWaveNo                 TWaveNo,
          @vBusinessUnit           TBusinessUnit,
          @vOrderCount             TCount,
          @vOrderLineCount         TCount,
          @vBatchOrderCount        TCount,
          /* Order counts */
          @vOrdersAllocated        TCount,
          @vOrdersPicked           TCount,
          @vOrdersPacked           TCount,
          @vOrdersStaged           TCount,
          @vOrdersLoaded           TCount,
          @vOrdersShipped          TCount,
          @vOrdersOpen             TCount,
          @vShippedOrderCount      TCount,
          @vLoadedOrderCount       TCount,
          @vCanceledOrderCount     TCount,
          @vCompletedOrderCount    TCount,
          @vClosedOrderCount       TCount,
          @vBatchedCount           TCount,
          @vPickingCount           TCount,
          @vLPNPickedCount         TCount,
          @vLPNPackedCount         TCount,
          @vLPNShippedCount        TCount,
          @vStagedCount            TCount,
          @vCanceledCount          TCount,
          @vCompletedCount         TCount,
          @vClosedCount            TCount,
          @vCurrentBatchStatus     TStatus,
          @vIsBatchAllocated       TFlag,
          @vBulkPickingCount       TCount,
          @vBulkPickedCount        TCount,
          /* LPN Counts */
          @vLPNPickingCount        TCount,
          @vLPNPackingCount        TCount,
          @vLPNsAssigned           TCount,
          @vLPNsPicked             TCount,
          @vLPNsPacked             TCount,
          @vLPNsStaged             TCount,
          @vLPNsLoaded             TCount,
          @vLPNsShipped            TCount,
          /* Unit Counts */
          @vLPNAllocatedUnits      TCount,
          @vUnitsAllocated         TCount,
          @vODUnitsShipped         TCount,
          @vUnitsPicked            TCount,
          @vUnitsPacked            TCount,
          @vUnitsStaged            TCount,
          @vUnitsLoaded            TCount,
          @vUnitsShipped           TCount,
          /* Tasks */
          @vUnitsToPickOnTasks     TCount,
          @vNumPicks               TCount,
          @vNumPicksCompleted      TCount,
          @vAllocateFlags          TFlags,
          @vTotalUnits             TCount,
          @vBatchType              TTypeCode,
          @vBatchUnits             TInteger,
          @vControlCategory        TCategory,
          @BusinessUnit            TBusinessUnit,
          @ttBatchDetailCounts     TEntityStatusCounts,
          @vBatchStatusCalcByUnits TFlags,
          @vDebug                  TFlags,
          @vActivityLogId          TRecordId,
          @vMessage                TDescription,
          @xmlWaveCounts           TXml;
begin /* pr_PickBatch_SetStatus */

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  /* Get Status of the Wave */
  select @vWaveId       = WaveId,
         @PickBatchId   = WaveId, -- output the WaveId
         @vWaveNo       = WaveNo,
         @vBusinessUnit = BusinessUnit
  from Waves
  where (WaveNo = @PickBatchNo);

  /* defer Wave status updates for later */
  if (charindex('$', @BatchStatus) > 0)
    begin
      select @BatchStatus = trim('$' from @BatchStatus);

      /* invoke RequestRecalcCounts to defer Wave Status updates */
      exec pr_Entities_RequestRecalcCounts 'Wave', @vWaveId, @vWaveNo, 'S'/* RecalcOption */,
                                           @@ProcId, default /* Operation */, @vBusinessUnit, @BatchStatus /* Wave Entity Status */;

      goto ExitHandler;
    end

  /* Compute number of order lines and LPNs in various statuses */
  select @vBulkPickingCount = sum(case when (UnitsAssigned >= 0) then 1 else 0 end),
         @vBulkPickedCount  = sum(case when (NumUnits = UnitsAssigned) then 1 else 0 end)
  from OrderHeaders
  where (PickBatchId = @vWaveId) and
        (OrderType = 'B' /* Bulk */);

  if (charindex('D' /* Display */, @vDebug) > 0) select @vBulkPickingCount BulkPickingOrders, @vBulkPickedCount BulkPickedOrders;

  /* Check if everything for this order has been picked and packed */
  insert into @ttBatchDetailCounts(Entity, EntityType, EntityStatus, NumEntities)
    select 'ORD', OH.OrderType, OH.Status, count(distinct OrderId)
    from OrderHeaders OH
    where (OH.PickBatchId = @vWaveId) and
          (OrderType   <> 'B' /* BPT */)
    group by OH.OrderType, OH.Status;

  /* Check if everything for this order has been picked and packed. Count1 is ReservedUnits */
  insert into @ttBatchDetailCounts(Entity, EntityType, EntityStatus, NumLPNs, NumCases, NumUnits, Count1)
     select 'LPN', L.LPNType, L.Status, count(distinct LD.LPNId), sum(LD.InnerPacks), sum(LD.Quantity),
            sum(case when (LD.OnhandStatus = 'R' /* Reserved */) or (L.Status= 'S' /* Shipped */) then LD.Quantity else 0 end)
     from LPNDetails LD
       join LPNs          L on (LD.LPNId = L.LPNId)
     where (L.PickBatchId = @vWaveId) and
           (L.Status not in ('V', 'C' /* Voided, Consumed */)) and
           ((LD.OnhandStatus = 'R' /* Reserved */) or (L.Status in ('S', 'F' /* Shipped, New Carton */)))
     group by L.Status, L.LPNType;

  if (charindex('D' /* Display */, @vDebug) > 0) select 'BatchDetailCounts', * from @ttBatchDetailCounts;

  /* Get the count of shipped orders and Cancelled orders */
  select @vOrdersAllocated     = sum(case when (charindex(EntityStatus, 'ACPKGLSD') > 0) then NumEntities else 0 end),
         @vOrdersPicked        = sum(case when (charindex(EntityStatus, 'PKGLSD') > 0)   then NumEntities else 0 end),
         @vOrdersPacked        = sum(case when (charindex(EntityStatus, 'KGLS') > 0)     then NumEntities else 0 end),
         @vOrdersStaged        = sum(case when (charindex(EntityStatus, 'GLS') > 0)      then NumEntities else 0 end),
         @vOrdersLoaded        = sum(case when (charindex(EntityStatus, 'LS') > 0)       then NumEntities else 0 end),
         @vOrdersShipped       = sum(case when (charindex(EntityStatus, 'S') > 0)        then NumEntities else 0 end),
         @vOrdersOpen          = sum(case when (charindex(EntityStatus, 'SDX') = 0)      then NumEntities else 0 end),
         @vShippedOrderCount   = sum(case when (EntityStatus = 'S' /* Shipped */  ) then NumEntities else 0 end),
         @vCompletedOrderCount = sum(case when (EntityStatus = 'D' /* Completed */) then NumEntities else 0 end),
         @vCanceledOrderCount  = sum(case when (EntityStatus = 'X' /* Cancelled */) then NumEntities else 0 end),
         @vLoadedOrderCount    = sum(case when (EntityStatus = 'L' /* Loaded */   ) then NumEntities else 0 end)
  from @ttBatchDetailCounts
  where (Entity = 'ORD');

  /* Check if everything for this order has been picked and packed
    U- Picking, G- Packing, D-Packed, K-Picked, L-Loaded, S-Shipped , E-Staged */
  select @vLPNPickingCount   = sum(case when (charindex(EntityStatus, 'U')      > 0) then NumLPNs else 0 end),
         @vLPNPickedCount    = sum(case when (charindex(EntityStatus, 'KGDLES') > 0) then NumLPNs else 0 end),
         @vLPNPackingCount   = sum(case when (charindex(EntityStatus, 'G')      > 0) then NumLPNs else 0 end),
         @vLPNAllocatedUnits = sum(Count1), -- ReservedUnits
         @vUnitsPicked       = sum(case when (charindex(EntityStatus, 'UKGDELS')> 0) then NumUnits else 0 end),
         @vUnitsPacked       = sum(case when (charindex(EntityStatus, 'DLS')    > 0) then NumUnits else 0 end),
         @vUnitsStaged       = sum(case when (charindex(EntityStatus, 'ELS')    > 0) then NumUnits else 0 end),
         @vUnitsLoaded       = sum(case when (charindex(EntityStatus, 'LS')     > 0) then NumUnits else 0 end),
         @vUnitsShipped      = sum(case when (charindex(EntityStatus, 'S')      > 0) then NumUnits else 0 end)
  from @ttBatchDetailCounts
  where (Entity = 'LPN');

  /* Check if everything for this order has been picked and packed into shipping cartons
    U- Picking, G- Packing, D-Packed, K-Picked, L-Loaded, S-Shipped , E-Staged */
  select @vLPNsAssigned = sum(NumLPNs),
         @vLPNsPicked   = sum(case when (charindex(EntityStatus, 'KGDELS')    > 0) then NumLPNs else 0 end),
         @vLPNsPacked   = sum(case when (charindex(EntityStatus, 'GDELS')     > 0) then NumLPNs else 0 end),
         @vLPNsStaged   = sum(case when (charindex(EntityStatus, 'ELS')       > 0) then NumLPNs else 0 end),
         @vLPNsLoaded   = sum(case when (charindex(EntityStatus, 'LS')        > 0) then NumLPNs else 0 end),
         @vLPNsShipped  = sum(case when (charindex(EntityStatus, 'S')         > 0) then NumLPNs else 0 end)
  from @ttBatchDetailCounts
  where (Entity = 'LPN') and (EntityType = 'S' /* Ship Carton */);

  /* Closed orders are shipped/canceled or completed orders */
  select @vClosedOrderCount = @vShippedOrderCount + @vCanceledOrderCount + @vCompletedOrderCount;

  /* Get batch Info here */
  select @vCurrentBatchStatus = Status,
         @vIsBatchAllocated   = IsAllocated,
         @vBatchOrderCount    = NumOrders,
         @vTotalUnits         = NumUnits,
         @vNumPicks           = NumPicks,
         @vNumPicksCompleted  = NumPicksCompleted,
         @vBatchType          = BatchType,
         @vControlCategory    = 'PickBatch_' + BatchType,
         @vOrderCount         = NumOrders,
         @vOrderLineCount     = NumLines,
         @vAllocateFlags      = AllocateFlags,
         @BusinessUnit        = BusinessUnit
  from Waves
  where (WaveId = @vWaveId);

  /* Get the Total Units assigned for the Wave */
  select @vUnitsAllocated = sum(OD.UnitsAssigned),
         @vODUnitsShipped = sum(OD.UnitsShipped)
  from WaveDetails WD
    join OrderDetails OD on WD.OrderId = OD.OrderId and WD.OrderDetailId = OD.OrderDetailId
  where (WD.WaveId = @vWaveId);

  /* insert into activitylog details */
  exec pr_ActivityLog_AddMessage 'WaveStatus', @vWaveId, @vWaveNo, 'Wave', null /* Message */, @@ProcId,
                                 @ActivityLogId = @vActivityLogId output;

  /* If the Batch Status Calc By Units = T then we consider the Total Units, A - we consider AllocatedUnits */
  select @vBatchStatusCalcByUnits = dbo.fn_Controls_GetAsString(@vControlCategory, 'StatusCalcByUnits', 'T', @BusinessUnit, null /* UserId */)

  if (@vBatchStatusCalcByUnits = 'T')
    select @vBatchUnits = @vTotalUnits
  else
    select @vBatchUnits = @vLPNAllocatedUnits;

  if (charindex('D' /* Display */, @vDebug) > 0)
    begin
      select 'Wave', @vIsBatchAllocated IsAllocated, @vCurrentBatchStatus CurrentStatus, @vBatchType WaveType;
      select 'Orders', @vOrderCount Orders, @vOrderLineCount Lines, @vOrdersShipped ShippedOrders, @vCompletedOrderCount CompletedOrders,
             @vCanceledOrderCount CanceledOrders, @vOrdersStaged StagedOrders;
      select 'Tasks', @vNumPicks Picks, @vNumPicksCompleted PicksCompleted;
      select 'LPNs', @vLPNPickingCount PickingLPNs, @vLPNPickedCount PickedLPNs, @vLPNPackingCount PackingLPNs, @vLPNPackedCount PackedLPNs,
             @vLPNShippedCount ShippedLPNs;
      select 'Units', @vBatchUnits BatchUnits, @vLPNAllocatedUnits AllocatedUnits, @vUnitsPicked PickedUnits, @vUnitsPacked PackedUnits,
             @vUnitsStaged StagedUnits, @vUnitsLoaded LoadedUnits, @vUnitsShipped ShippedUnits;
    end

  if (charindex('X' /* Log the XmlData */, @vDebug) > 0)
    begin
      select @xmlWaveCounts = dbo.fn_XMLNode('Root',
                                dbo.fn_XMLNode('Wave',
                                  dbo.fn_XMLNode('IsAllocated',    @vIsBatchAllocated) +
                                  dbo.fn_XMLNode('CurrentStatus',  @vCurrentBatchStatus) +
                                  dbo.fn_XMLNode('WaveType',       @vBatchType)) +
                                dbo.fn_XMLNode('Orders',
                                  dbo.fn_XMLNode('Orders',         @vOrderCount) +
                                  dbo.fn_XMLNode('Lines',          @vOrderLineCount) +
                                  dbo.fn_XMLNode('ShippedOrders',  @vOrdersShipped) +
                                  dbo.fn_XMLNode('CompletedOrders',@vCompletedOrderCount) +
                                  dbo.fn_XMLNode('CanceledOrders', @vCanceledOrderCount) +
                                  dbo.fn_XMLNode('StagedOrders',   @vOrdersStaged) +
                                  dbo.fn_XMLNode('BatchStatus',    @BatchStatus) +
                                  dbo.fn_XMLNode('BatchOrderCount',@vBatchOrderCount)) +
                                dbo.fn_XMLNode('Tasks',
                                  dbo.fn_XMLNode('Picks',          @vNumPicks) +
                                  dbo.fn_XMLNode('PicksCompleted', @vNumPicksCompleted)) +
                                dbo.fn_XMLNode('LPNs',
                                  dbo.fn_XMLNode('PickingLPNs',    @vLPNPickingCount) +
                                  dbo.fn_XMLNode('PickedLPNs',     @vLPNPickedCount) +
                                  dbo.fn_XMLNode('PackingLPNs',    @vLPNPackingCount) +
                                  dbo.fn_XMLNode('PackedLPNs',     @vLPNPackedCount) +
                                  dbo.fn_XMLNode('ShippedLPNs',    @vLPNShippedCount)) +
                                dbo.fn_XMLNode('ShipCartons',
                                  dbo.fn_XMLNode('LPNsAssigned',   @vLPNsAssigned) +
                                  dbo.fn_XMLNode('LPNsPicked',     @vLPNsPicked) +
                                  dbo.fn_XMLNode('LPNsPacked',     @vLPNsPacked) +
                                  dbo.fn_XMLNode('LPNsStaged',     @vLPNsStaged) +
                                  dbo.fn_XMLNode('LPNsLoaded',     @vLPNsLoaded) +
                                  dbo.fn_XMLNode('LPNsShipped',    @vLPNsShipped)) +
                                dbo.fn_XMLNode('Units',
                                  dbo.fn_XMLNode('BatchUnits',     @vBatchUnits) +
                                  dbo.fn_XMLNode('AllocatedUnits', @vLPNAllocatedUnits) +
                                  dbo.fn_XMLNode('PickedUnits',    @vUnitsPicked) +
                                  dbo.fn_XMLNode('PackedUnits',    @vUnitsPacked) +
                                  dbo.fn_XMLNode('StagedUnits',    @vUnitsStaged) +
                                  dbo.fn_XMLNode('LoadedUnits',    @vUnitsLoaded) +
                                  dbo.fn_XMLNode('ShippedUnits',   @vUnitsShipped)+
                                  dbo.fn_XMLNode('TotalUnits',     @vTotalUnits) +
                                  dbo.fn_XMLNode('ShippedOrderCount',
                                                                   @vShippedOrderCount)));
    end

  /* If no Status is given, recompute the status based on the order statuses. However, if it is new Batch
     then don't change it as these status computations apply only after the Batch is released */
  if ((@BatchStatus is null) and (@vCurrentBatchStatus <> 'N' /* New */)) or
     (@BatchStatus = '*')
    begin
      /* If all units are shipped or all Orders of a batch are shipped, consider a batch as shipped */
      if ((@vLPNAllocatedUnits > 0) and (@vTotalUnits > 0) and (@vTotalUnits = @vUnitsShipped)) or
         ((@vBatchOrderCount > 0) and (@vBatchOrderCount = @vShippedOrderCount))
        set @BatchStatus = 'S' /* Shipped */
      else
      /* If the all Orders are cancelled and Num Picks equals Picks Completed then set the Batch status to Cancelled */
      if (@vOrderCount = @vCanceledOrderCount) and (@vNumPicks > 0) and (@vNumPicks = @vNumPicksCompleted)
        set @BatchStatus = 'X' /* Cancelled */;
      else
      /* If all orders are in Completed and/or Canceled status then set Batch status to Completed */
      if (@vOrderCount = @vClosedOrderCount)
        set @BatchStatus = 'D'/* Completed */;
      else
      /* All Picked units are Loaded */
      if (@vLPNAllocatedUnits > 0) and
         (@vBatchUnits = @vUnitsLoaded) and
         (@vNumPicks = @vNumPicksCompleted) and
         (@vLoadedOrderCount+@vShippedOrderCount = @vOrderCount)
        set @BatchStatus = 'O' /* Loaded */
      else
      /* All Picked units are staged */
      if (@vLPNAllocatedUnits > 0) and (@vBatchUnits = @vUnitsStaged)
        set @BatchStatus = 'G' /* Staged */
      else
      /* For a replenish batch, when all picks are completed and all LPNs putaway
         then consider replenishment as done */
      if (@vNumPicks > 0) and
         (@vNumPicks = @vNumPicksCompleted) and
         (coalesce(@vUnitsPicked, 0) = 0) and (@vBatchType in ('R', 'RU', 'RP' /* Replenish*/))
        set @BatchStatus = 'D' /* Completed */
      else
      /* For a replenish batch, when all picks are completed consider it picked */
      if (@vNumPicks > 0) and
         (@vNumPicks = @vNumPicksCompleted) and
         (@vBatchType in ('R', 'RU', 'RP', 'RW', 'MK', 'BK' /* Replenish, Rework & Make/Break Kits*/))
        set @BatchStatus = 'K' /* Picked */
      else
      /* All Picked units are packed */
      if (@vLPNAllocatedUnits > 0) and
         (@vBatchUnits = @vUnitsPacked) and
         (@vNumPicks = @vNumPicksCompleted)
        set @BatchStatus = 'C' /* Packed */
      else
      /* If all units are picked and if there is an LPN that is being packed or packed then it must be in Packing now */
      if (@vLPNAllocatedUnits > 0) and (@vBatchUnits = @vUnitsPicked) and
         ((@vLPNPackingCount > 0) or (@vUnitsPacked > 0))
        set @BatchStatus = 'A' /* Packing */
      else
      if (@vLPNAllocatedUnits > 0) and (@vBatchUnits = @vUnitsPicked) and
         (@vNumPicksCompleted = @vNumPicks)
        set @BatchStatus = 'K' /* Picked */;
      else
      /* If some units are picked, then it must be in picking */
      if (((@vLPNPickingCount > 0) or (@vUnitsPicked > 0 and @vUnitsPicked < @vBatchUnits)) or
          (((@vNumPicks > 0) and (@vNumPicksCompleted < @vNumPicks)) and
            (@vCurrentBatchStatus not in ('E', 'R' /* Released, Ready To Pick */))))
        set @BatchStatus = 'P' /* Picking */;
      else
      /* When Picks are created for and nothing picked yet */
      if (@vNumPicks > 0) and
         (@vNumPicksCompleted = 0) and
         (@vAllocateFlags = 'D'/* Done */)
        set @BatchStatus = 'R' /* Ready To Pick */;
      else
      /* If Wave uses Manual reservation, then it is ready to pick if there are still orders on it */
      if (@vNumPicks = 0) and
         (@vAllocateFlags = 'D'/* Done */) and
         (@vOrderCount > @vCanceledOrderCount)
        set @BatchStatus = 'R' /* Ready To Pick */;
      else
      /* If orders does not exists for the batch or if the orders of the Batch are in Canceled status
         then set Batch status to Canceled */
      if ((@vOrderCount = 0) or
          (@vOrderCount = @vCanceledOrderCount))
        set @BatchStatus = 'X' /* Canceled */;
    end

  if (charindex('D' /* Display */, @vDebug) > 0) return; -- if Debugging only, then exit

  update PickBatches
  set @PickBatchId    = RecordId,
      Status          = case
                          when ((@BatchStatus = 'P' /* Picking */) and (BatchType = 'U'/* Piece Picks */) and
                                (Status in ('L'/* Ready To Pull */, 'U' /* Paused */, 'P'/* Picking */, 'K' /* Picked */)) and
                                (@vBulkPickingCount = 1)) then
                            'E' /* Being Pulled */
                          when ((@BatchStatus = 'K' /* Picked */) and (BatchType = 'U'/* Piece Picks */) and
                                (Status = 'E' /* Being Pulled */) and (@vBulkPickedCount = 1)) then
                            'R'/* Ready To Pick */
                          else
                            coalesce(nullif(@BatchStatus, '*'), Status)
                        end,
      WaveStatus      = case
                          when ((@BatchStatus = 'P' /* Picking */) and (WaveType = 'U'/* Piece Picks */) and
                                (WaveStatus in ('L'/* Ready To Pull */, 'U' /* Paused */, 'P'/* Picking */, 'K' /* Picked */)) and
                                (@vBulkPickingCount = 1)) then
                            'E' /* Being Pulled */
                          when ((@BatchStatus = 'K' /* Picked */) and (WaveType = 'U'/* Piece Picks */) and
                                (WaveStatus = 'E' /* Being Pulled */) and (@vBulkPickedCount = 1)) then
                            'R'/* Ready To Pick */
                          else
                            coalesce(nullif(@BatchStatus, '*'), Status)
                        end,
      NumLPNsToPA     = case
                          when(@vBatchType in ('R', 'RU', 'RP'  /* Replenish */)) then coalesce(@vLPNPickedCount, 0)
                          else coalesce(NumLPNsToPA, 0) end,
      PalletId        = case
                          when(@BatchStatus = 'R' /* Ready to Pick */) then
                            null
                          else
                            PalletId
                        end,
      Pallet          = case
                          when(@BatchStatus = 'R' /* Ready to Pick */) then
                            null
                          else
                            Pallet
                        end,
      OrdersAllocated = @vOrdersAllocated,
      OrdersPicked    = @vOrdersPicked,
      OrdersPacked    = @vOrdersPacked,
      OrdersStaged    = @vOrdersStaged,
      OrdersLoaded    = @vOrdersLoaded,
      OrdersShipped   = @vOrdersShipped,
      OrdersOpen      = @vOrdersOpen,
      LPNsAssigned    = @vLPNsAssigned,
      LPNsPicked      = @vLPNsPicked,
      LPNsPacked      = @vLPNsPacked,
      LPNsLoaded      = @vLPNsLoaded,
      LPNsStaged      = @vLPNsStaged,
      LPNsShipped     = @vLPNsShipped,
      UnitsAssigned   = @vUnitsAllocated,
      UnitsPicked     = @vUnitsPicked,
      UnitsPacked     = @vUnitsPacked,
      UnitsStaged     = @vUnitsStaged,
      UnitsLoaded     = @vUnitsLoaded,
      /* For transfer orders when shipped we will clear order info on the LPNs, so use UnitsShipped from order details */
      UnitsShipped    = case when WaveType = 'XFER' then @vODUnitsShipped else @vUnitsShipped end,
      ModifiedBy      = coalesce(@ModifiedBy, System_User),
      ModifiedDate    = current_timestamp
  where (WaveId = @vWaveId);

  /* If Wave has bulk order we need to close after wave is shipped */
  if (@BatchStatus = 'S' /* Shipped */)
    exec pr_OrderHeaders_CloseBPT null /* Bulk OrderId */, @PickBatchId, @BusinessUnit;

  select @vMessage = @vCurrentBatchStatus + ','+  coalesce(@BatchStatus, ''); -- Old and new statuses

  /* Update activitylog details */
  exec pr_ActivityLog_AddMessage 'WaveStatus', @vWaveId, @vWaveNo, 'Wave', @vMessage, @ProcId = @@ProcId, @xmlData = @xmlWaveCounts,
                                 @ActivityLogId = @vActivityLogId output;

ExitHandler:
  return(coalesce(@vReturnCode, 0));

end /* pr_PickBatch_SetStatus */

Go
