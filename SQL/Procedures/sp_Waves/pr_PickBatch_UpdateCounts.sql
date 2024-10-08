/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/15  MS      pr_PickBatch_UpdateCounts: Changes to update ShipDate on wave (HA-2358)
  2020/07/30  KBB     pr_PickBatch_UpdateCounts: Use coalesce while validating WH count (HA-1027)
  2020/07/09  AY      pr_PickBatch_UpdateCounts: Bug fix in calculating Account
  2020/06/01  TK      pr_PickBatch_UpdateCounts: Changes to update NumTasks
  2020/04/28  TK      pr_PickBatch_AddOrder, pr_PickBatch_CreateBatch & pr_PickBatch_UpdateCounts:
                        Fixed Wave generation issues (HA-86)
  2019/06/05  AY      pr_PickBatch_UpdateCounts: Code optimization
  2018/08/07  TK      pr_PickBatch_UpdateCounts & pr_PickBatch_SetStatus: Changes to defer Wave Counts/Status updates (S2GCA-117)
  2018/04/30  KSK     pr_PickBatch_UpdateCounts: Added UDF4 and UDF5 (S2G-691)
  2017/07/05  AY      pr_PickBatch_UpdateCounts: Reset order counts on Wave when all orders are removed (HPI-1215)
  2016/07/15  DK      pr_PickBatch_UpdateCounts: Made changes to update NumUnits on Pickbatch based on control value (HPI-273).
  2015/07/18  AY      pr_PickBatch_UpdateCounts: Revamped to compute based on need only and to calc Tasks as well (XX-?)
  2014/06/12  TD      pr_PickBatch_UpdateCounts:Changes to update NumLPNs based on LPNs.
              AY      pr_PickBatch_UpdateCounts: Do not reset Batch priority as it could be changed by users
  2013/03/21  TD      pr_PickBatch_UpdateCounts: Updating TotalWeight, TotalVolume to PickBatch.
  2012/09/13  AY      pr_PickBatch_UpdateCounts: Update NumLPNs
  2012/09/10  AY      pr_PickBatch_UpdateCounts: UDF2/CancelDate should be the Minimum Cancel
  2012/08/10  AA      pr_PickBatch_UpdateCounts: Added columns CustPO, CancelDate and TotalAmount
  2012/06/27  NY      pr_PickBatch_AddOrder: calling directly pr_PickBatch_UpdateCounts to update counts
  2012/06/26  AY      pr_PickBatch_UpdateCounts: Fixed NumSKUsOnOrders by calculating from OrderDetails
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_UpdateCounts') is not null
  drop Procedure pr_PickBatch_UpdateCounts;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_UpdateCounts: Updates the summary fields and counts on the
  PickBatch. For performance reasons, we do not want to summarize the same info
  again and again. The number of orders etc. would not change so much of this
  information does not need to be summarized again.

  Options: O - Summarize Order Info
           T - Summarize Task Info
           L - Summarize LPN Info

  By default Options is null, which means that based upon the status of the Batch
  the Options are set. To force calculation of one for more sets, then Options
  can be passed in as TL or OTL or OT etc.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_UpdateCounts
  (@PickBatchNo      TPickBatchNo,
   @Options          TFlags          = null,
   @PickBatchGroup   TWaveGroup      = null,
   @BusinessUnit     TBusinessUnit   = null)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,

          @vSoldToCount      TCount,
          @vSoldToId         TCustomerId,
          @vShipToCount      TCount,
          @vShipToId         TShipToId,
          @vShipDate         TDateTime,
          @vShipViaCount     TCount,
          @vShipVia          TShipVia,
          @vPickZoneCount    TCount,
          @vPickZone         TLookUpCode,
          @vWarehouseCount   TCount,
          @vWarehouse        TWarehouse,
          @vOwnerCount       TCount,
          @vOwner            TOwnership,
          @vCustPOCount      TCount,
          @vCustPO           TCustPO,
          @vAccountCount     TCount,
          @vAccount          TName,
          @vAccountNameCount TCount,
          @vAccountName      TName,
          @vCategory1Count   TCount,
          @vCategory1        TName,
          @vCategory2Count   TCount,
          @vCategory2        TName,
          @vCategory3Count   TCount,
          @vCategory3        TName,
          @vCategory4Count   TCount,
          @vCategory4        TName,
          @vCategory5Count   TCount,
          @vCategory5        TName,
          @vUDF1count        TCount,
          @vUDF1             TName,
          @vUDF2count        TCount,
          @vUDF2             TName,
          @vUDF3count        TCount,
          @vUDF3             TName,
          @vUDF4Count        TCount,
          @vUDF4             TName,
          @vUDF5Count        TCount,
          @vUDF5             TName,
          @vCancelDate       TDateTime,
          @vOrderPriority    TPriority,
          @vNumOrders        TCount,
          @vNumLinesOnOrders TCount,
          @vNumSKUsOnOrders  TCount,
          @vNumLPNsOnOrders  TCount,
          @vNumLPNsOnBatch   TCount,
          @vNumUnitsOnOrders TCount,
          @vNumUnitsReserved TCount,
          @vNumUnitsPreAlloc TCount,
          @vNumInnerPacks    TCount,
          @vNumTasks         TCount,
          @vNumPicks         TCount,
          @vNumPicksCompleted TCount,
          @vSalesAmount      TMoney,
          @vTotalWeight      TWeight,
          @vTotalVolume      TVolume,
          @vWaveId           TRecordId,
          @vWaveNo           TWaveNo,
          @vWaveStatus       TStatus,
          @vWaveType         TTypeCode,
          @vWaveUnitCalcMethod
                             TControlValue,
          @vControlCategory  TCategory,
          @vOptions          TFlags,
          @vBusinessUnit     TBusinessUnit;
begin
  /* By default use @Options */
  select @vOptions = coalesce(@Options, '');

  /* Get Status of the Wave */
  select @vWaveId          = RecordId,
         @vWaveNo          = BatchNo,
         @vWaveStatus      = Status,
         @vWaveType        = BatchType,
         @vControlCategory = 'PickBatch_' + BatchType,
         @vBusinessUnit    = coalesce(@BusinessUnit, BusinessUnit)
  from PickBatches
  where (BatchNo = @PickBatchNo);

  /* defer Wave update counts for later */
  if (charindex('$', @Options) > 0)
    begin
      /* invoke RequestRecalcCounts to defer Wave count updates */
      exec pr_Entities_RequestRecalcCounts 'Wave', @vWaveId, @vWaveNo, 'C'/* RecalcOption */,
                                           @@ProcId, default /* Operation */, @vBusinessUnit;

      goto ExitHandler;
    end

  --select @Status = coalesce(@Options, dbo.fn_Controls_GetAsString(@vControlCategory, 'RecountOrders', 'OLT' /* Orders/LPNs/Tasks */, @BusinessUnit, null /* UserId */));
  select @vWaveUnitCalcMethod = dbo.fn_Controls_GetAsString('PickBatch', 'WaveUnitCalcMethod', 'UnitsOnOrders' , @BusinessUnit, null /* UserId */);

  /* If no directive is given to compute, then Other than compute Order info only until wave has started */
  if (@Options is null) and
     (charindex(@vWaveStatus, 'NBLE' /* New, Planned, Ready to Pull, Released */) <> 0)
    select @vOptions += 'O'; /* Recompute Orders */

  /* If no directive is given to compute, then Other than New, Planned, Shipped recalc LPN/Task Info */
  if (@Options is null) and
     (charindex(@vWaveStatus, 'NBS' /* New, Planned */) = 0)
    select @vOptions += 'TL'; /* Recompute Task/LPN counts */

  /* select the counts of SoldTo, ShipTo, ShipVia and PickZone from OrderDetails
     to update Pickbatches table */
  if (charindex('O', @vOptions) <> 0)
    begin
      select @vSoldToCount      = count (distinct SoldToId),
             @vSoldToId         = min(SoldToId),
             @vShipToCount      = count (distinct ShipToId),
             @vShipToId         = min(ShipToId),
             @vShipDate         = min(ShipDate),
             @vShipViaCount     = count (distinct ShipVia),
             @vShipVia          = min(ShipVia),
             @vPickZoneCount    = count (distinct coalesce(PickZone, '')),
             @vPickZone         = min(PickZone),
             @vWarehouseCount   = count (distinct Warehouse),
             @vWarehouse        = min(Warehouse),
             @vOwnerCount       = count (distinct Ownership),
             @vOwner            = min(Ownership),
             @vCustPOCount      = count (distinct CustPO),
             @vCustPO           = min(CustPO),
             @vAccountCount     = count (distinct Account),
             @vAccount          = min(Account),
             @vAccountNameCount = count (distinct AccountName),
             @vAccountName      = min(AccountName),
             @vCategory1Count   = count (distinct OrderCategory1),
             @vCategory1        = min(OrderCategory1),
             @vCategory2Count   = count (distinct OrderCategory2),
             @vCategory2        = min(OrderCategory2),
             @vCategory3Count   = count (distinct OrderCategory3),
             @vCategory3        = min(OrderCategory3),
             @vCategory4Count   = count (distinct OrderCategory4),
             @vCategory4        = min(OrderCategory4),
             @vCategory5Count   = count (distinct OrderCategory5),
             @vCategory5        = min(OrderCategory5),
             @vUDF1Count        = count (distinct UDF1),
             @vUDF1             = min(UDF1),
             @vUDF2Count        = count (distinct UDF2),
             @vUDF2             = min(UDF2),
             @vUDF3Count        = count (distinct UDF3),
             @vUDF3             = min(UDF3),
             @vUDF4Count        = count (distinct UDF4),
             @vUDF4             = min(UDF4),
             @vUDF5Count        = count (distinct UDF5),
             @vUDF5             = min(UDF5),
             @vCancelDate       = min(CancelDate),
             @vOrderPriority    = min(Priority),
             @vNumOrders        = count(distinct OrderId),
             @vNumLinesOnOrders = count(OrderDetailId),
             @vNumLPNsOnOrders  = sum(NumLPNs),
             @vNumUnitsOnOrders = sum(UnitsAuthorizedToShip),
             @vNumUnitsReserved = sum(UnitsAssigned),
             @vNumUnitsPreAlloc = sum(dbo.fn_MaxInt(UnitsPreallocated, UnitsAssigned)),
             @vNumInnerPacks    = sum(case when UnitsPerInnerPack > 0 then UnitsAuthorizedToShip/UnitsPerInnerPack else 0 end), /* UnitsPerInnerPack is set to be non-zero in vwPickBatchDetails */
             @vSalesAmount      = sum(Case
                                       when UoM = 'EA' then
                                        (UnitsAuthorizedToShip * ProductCost)
                                      else
                                        (UnitsAuthorizedToShip * UnitsPerCarton * ProductCost)
                                  end),
             @vTotalWeight      = sum(UnitsAuthorizedToShip * UnitWeight),
             @vTotalVolume      = sum(UnitsAuthorizedToShip * UnitVolume),
             @vNumSKUsOnOrders  = count (distinct SKUId)
      from vwPickBatchDetails
      where (PickBatchNo = @PickBatchNo) and
            (OrderType   <> 'B' /* Bulk Pull */);

      /* If there are no orders on the wave anymore, then reset the counts to zero. Leaving them as null
         would mean that the counts are not changed and the previous values are retained */
      if not exists(select * from PickBatchDetails where (PickBatchNo = @PickBatchNo))
        select @vNumOrders        = 0,
               @vNumLinesOnOrders = 0,
               @vNumUnitsOnOrders = 0,
               @vNumInnerPacks    = 0;
    end

  /* At GNC, we cannot estimate the number of LPNs or InnerPacks, so use the actual counts.
     Also, if an LPN has no inner packs, assume it is atleast one Case/InnerPack
     We may enhance this to be based upon control var at a later time as this may not be
     suitable to all clients */
  if (charindex('L', @vOptions) <> 0)
    select @vNumLPNsOnBatch = count(*),
           @vNumInnerPacks  = sum(case when InnerPacks > 0 then InnerPacks else 1 end)
    from LPNs
    where (PickBatchNo = @PickBatchNo);

  /* If task counts are to be computed, then do so */
  if (charindex('T', @vOptions) <> 0)
    begin
      select @vNumTasks = count(distinct TaskId)
      from Tasks
      where (WaveId = @vWaveId) and
            (Status <> 'X'/* Canceled */);

      select @vNumPicks          = sum (case when Status not in ('X') then 1 else 0 end) ,
             @vNumPicksCompleted = sum (case when Status in ('C') then 1 else 0 end)
      from TaskDetails
      where (WaveId = @vWaveId);
    end

  /* Update PickBatches table with the retrived values of SoldTo, ShipTo,
     PickZone from OrderHeaders table and update the counts of NumOrders, NumLines,
     NumSKUs, NumUnits as well...
     Updated ShipVia with Mixed if there are more than one shipvia for a batch  */
  update PickBatches
  set SoldToId          = case when @vSoldToCount     = 1 then @vSoldToId
                               when coalesce(@vSoldToCount, 0) = 0 then SoldToId
                               else null end,
      ShipToId          = case when @vShipToCount     = 1 then @vShipToId
                               when coalesce(@vShipToCount, 0) = 0 then ShipToId
                               else null end,
                          /* Until it is released, Update it. On release, user can change it */
      ShipDate          = case when (charindex(@vWaveStatus, 'NBL') <> '0') then @vShipDate
                               else ShipDate end,
      ShipVia           = case when @vShipViaCount     = 1 then @vShipVia
                               when coalesce(@vShipViaCount, 0) = 0 then ShipVia
                               else 'Mixed' end,
      PickZone          = case when @vPickZoneCount     = 1 then @vPickZone
                               when coalesce(@vPickZoneCount, 0) = 0 then PickZone
                               else 'Mixed' end,
      Warehouse         = case when @vWarehouseCount     = 1 then @vWarehouse
                               when coalesce(@vWarehouseCount, 0) = 0 then Warehouse
                               else 'Mixed' end,
      Ownership         = case when @vOwnerCount     = 1 then @vOwner
                               when coalesce(@vOwnerCount, 0) = 0 then Ownership
                               else 'Mixed' end,
      Account           = case when @vAccountCount = 1 then @vAccount
                               when coalesce(@vAccountCount, 0) = 0 then Account
                               else 'Multiple' end,
      AccountName       = case when @vAccountNameCount = 1 then @vAccountName
                               when coalesce(@vAccountNameCount, 0) = 0 then AccountName
                               else 'Multiple' end,
      CustPO            = case when @vCustPOCount = 1 then @vCustPO
                               when coalesce(@vCustPOCount, 0) = 0 then CustPO
                               else 'Multiple' end,
      Category1         = case when @vCategory1Count = 1 then @vCategory1
                               when coalesce(@vCategory1Count, 0) = 0 then Category1
                               else 'Multiple' end,
      Category2         = case when @vCategory2Count = 1 then @vCategory2
                               when coalesce(@vCategory2Count, 0) = 0 then Category2
                               else 'Multiple' end,
      Category3         = case when @vCategory3Count = 1 then @vCategory3
                               when coalesce(@vCategory3Count, 0) = 0 then Category3
                               else 'Multiple' end,
      Category4         = case when @vCategory4Count = 1 then @vCategory4
                               when coalesce(@vCategory4Count, 0) = 0 then Category4
                               else 'Multiple' end,
      Category5         = case when @vCategory5Count = 1 then @vCategory5
                               when coalesce(@vCategory5Count, 0) = 0 then Category5
                               else 'Multiple' end,
      UDF1              = case when @vUDF1Count = 1 then @vUDF1
                               when @vUDF1 is null  then UDF1
                               else 'Mixed' end,
      UDF2              = case when @vUDF2Count = 1 then @vUDF2
                               when @vUDF2 is null  then UDF2
                               else 'Mixed' end,
      UDF3              = case when @vUDF3Count = 1 then @vUDF3
                               when @vUDF3 is null  then UDF3
                               else 'Mixed' end,
      UDF4              = case when @vUDF4Count = 1 then @vUDF4
                               when @vUDF4 is null  then UDF4
                               else 'Mixed' end,
      UDF5              = case when @vUDF5Count = 1 then @vUDF5
                               when @vUDF5 is null  then UDF5
                               else 'Mixed' end,
      PickBatchGroup    = coalesce(@PickBatchGroup, PickBatchGroup),
      CancelDate        = cast(@vCancelDate as date),
      Priority          = coalesce(Priority, @vOrderPriority), /* First time if Priority is null then we update with OrderPriority */
      NumOrders         = coalesce(@vNumOrders, NumOrders),
      NumLines          = coalesce(@vNumLinesOnOrders, NumLines, 0),
      NumSKUs           = coalesce(@vNumSKUsOnOrders, NumSKUs, 0),
      NumLPNs           = coalesce(@vNumLPNsOnBatch, NumLPNs, 0),
      NumInnerPacks     = coalesce(@vNumInnerPacks, NumInnerPacks, 0),
      NumUnits          = case when (@vWaveUnitCalcMethod = 'PreAllocation') then
                                 coalesce(@vNumUnitsPreAlloc, NumUnits, 0)
                               else
                                 coalesce(@vNumUnitsOnOrders, NumUnits, 0)
                          end,
      UnitsAssigned     = coalesce(@vNumUnitsReserved, UnitsAssigned, 0),
      NumTasks          = coalesce(@vNumTasks, NumTasks, 0),
      NumPicks          = coalesce(@vNumPicks, NumPicks, 0),
      NumPicksCompleted = coalesce(@vNumPicksCompleted, NumPicksCompleted, 0),
      TotalAmount       = coalesce(@vSalesAmount, TotalAmount, 0),
      TotalWeight       = coalesce(@vTotalWeight, TotalWeight, 0.0),
      TotalVolume       = coalesce(@vTotalVolume, TotalVolume, 0) * 0.000578704 /* convert to cubic feet */
  where (RecordId = @vWaveId);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_UpdateCounts */

Go
