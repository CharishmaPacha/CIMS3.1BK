/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/11  TK      pr_Allocation_AllocateLPNToOrders_New: Changes to allocate cases from LPNs (BK-181)
  2020/05/26  TK      pr_Allocation_AllocateLPN_New: Bug fix when complete LPN detail cannot be allocated
                      pr_Allocation_AllocateLPNToOrders_New: Changes to add reserved LPNDetailId instead of FromLPNDetailId (HA-658)
  2018/10/25  TK      pr_Allocation_AllocateLPN: Changed procedure signature to accept TaskDetailId
                      pr_Allocation_AllocateFromDynamicPicklanes & pr_Allocation_AllocateLPNToOrders:
                        Changes to Allocation_AllocateLPN proc signature (S2GCA-390)
  2018/07/02  TK      pr_Allocation_GeneratePseudoPicks: Changes to defer cubing
                      pr_Allocation_AllocateFromDynamicPicklanes: Initial Revision
                      pr_Allocation_AllocateLPNToOrders: Changes to allocate only required cases and
                        allocate Units for Dynamic Replenishments (S2GCA-66)
  2018/05/18  TK      pr_Allocation_AllocateLPNToOrders: UnitsToAllocate should be converted to float value else the division returns only integer value (S2G-853)
  2018/05/01  TK      pr_Allocation_AllocateLPNToOrders: Overallocate to atleast a case when ordered quantity is less than a case for replenishments (S2G-CRPIssues)
  2018/04/27  TK      pr_Allocation_AllocateLPNToOrders: Changes to allocate complete units from UnitStorage Locations (S2G-723)
  2018/04/23  AY      pr_Allocation_AllocateLPNToOrders: Prevent allocation of units from an LPN with InnerPacks (S2G-723)
  2018/03/27  TK      pr_Allocation_AllocateLPN & pr_Allocation_AllocateLPNToOrders:
                        Changes to consider DestLocation instead of Location (S2G-499)
  2018/03/09  TK      pr_Allocation_AllocateLPNToOrders: Changes to UnitsPerPackage appropriately (S2G-364)
  2018/03/03  TK      pr_Allocation_AllocateWave & pr_Allocation_AllocateLPNToOrders:
                        Changes to allocate cases and units separately (S2G-341)
  2018/03/02  TK      pr_Allocation_AllocateLPN: Changes to create PR lines only for picklanes
                      pr_Allocation_AllocateInventory: Changes to update WaveId on task details
                      pr_Allocation_AllocateLPNToOrders: Changes to increment qty on the task
                        detail if there is on for order detail
                      pr_Allocation_FindAllocableLPN: Changes to over allocate LPNs from Bulk Location
                      pr_Allocation_SumPicksFromSameLocation: Initial Revision (S2G-151)
  2018/01/24  TK      pr_Allocation_AllocateLPN: Changes to defer reservation of Inventory
                      pr_Allocation_FindAllocableLPNs: removed HPI specific code
                      pr_Allocation_AllocateLPNToOrders: Changes to Allocate_AllocateLPN procedure signature (S2G-152)
  2017/08/08  TK      pr_Allocation_AllocateInventory & fn_PickBatches_GetAllocationRules:
                        Changes to consider ReplenishClass while allocating inventory
                      pr_Picking_FindAllocableLPNs => pr_Allocation_FindAllocableLPNs
                      pr_Allocation_AllocateLPNToOrders: renamed from pr_PickBatch_AllocateLPNToOrders(HPI-1625)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateLPNToOrders') is not null
  drop Procedure pr_Allocation_AllocateLPNToOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateLPNToOrders:

------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateLPNToOrders
  (@PickBatchNo            TPickBatchNo,
   @LPNId                  TRecordId,
   @LPNDetailId            TRecordId,
   @LPNQuantity            TQuantity,
   @SKUId                  TRecordId,
   @Operation              TDescription,
   @DestZone               TZoneId,
   @AllocationRuleId       TRecordId,
   @UnitsAllocated         TQuantity  output,
   @Warehouse              TWarehouse,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vLPNAvailableQuantity    TQuantity,
          @vInnerPacks              TInnerPacks,

          @vLPNDetailId             TRecordId,
          @vTempLPNDetailId         TRecordId,
          @vTaskDetailId            TRecordId,
          @vOrderId                 TRecordId,
          @vOrderDetailId           TrecordId,
          @vOrderType               TTypeCode,
          @vUnitsToAllocate         TQuantity,
          @vSKUId                   TRecordId,
          @vDestZone                TName,
          @vRecordId                TRecordId,
          @vLPNInnerPacks           TInteger,
          @vUnitsPerPackage         TInteger,
          @vPickBatchId             TRecordId,
          @vQtyToAllocate           TQuantity,
          @vCasesToAllocate         TQuantity,
          @vQuantityCondition       TTypecode,
          @vLocationId              TRecordId,
          @vLocation                TLocation,
          @vPickBatchType           TTypeCode,
          @vRLPNDetailId            TRecordId,

          /* Controls */
          @vDebug                   TFlags;

  declare @ttOrderDetailsToAllocate table
          (RecordId          TRecordId identity (1,1),
           OrderId           TRecordId,
           OrderDetailId     TRecordId,
           OrderType         TTypeCode,
           SKUId             TRecordId,
           CasesToAllocate   TQuantity,
           UnitsToAllocate   TQuantity,
           DestZone          TName,
           DestLocationId    TRecordId,
           DestLocation      TLocation,
           LocationId        TRecordId,
           Location          TLocation
           Primary Key       (RecordId))

  declare @ttAllocatedOrderDetails table
          (PickBatchId       TRecordId,
           PickBatchNo       TPickBatchNo,
           OrderId           TRecordId,
           OrderDetailId     TRecordId,
           OrderType         TTypeCode,
           LPNId             TRecordId,
           LPNDetailId       TRecordId,
           UnitsAllocated    TQuantity,
           SKUId             TRecordId,
           DestZone          TName)

begin /* pr_Allocation_AllocateLPNToOrders */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @UnitsAllocated = 0,
         @vLPNDetailId   = @LPNDetailId;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  /* Assumption -caller will pass all the values. if not pass please
     get the values based on the given input */

  /* Get unitsperInnerPack here */
  select @vLPNInnerPacks   = InnerPacks,
         @vUnitsPerPackage = UnitsPerPackage
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Get PickBatchId */
  select @vPickBatchId   = RecordId,
         @vPickBatchType = BatchType
  from Pickbatches
  where (BatchNo = @PickBatchNo);

  /* Get the Quantity Condition */
  select @vQuantityCondition = QuantityCondition
  from AllocationRules
  where (RecordId = @AllocationRuleId);

  if (@vPickBatchType in ('RU', 'RP', 'R'/* Replenish */))
    begin
      insert into @ttOrderDetailsToAllocate (OrderId, OrderDetailId, OrderType, SKUId, CasesToAllocate, UnitsToAllocate, DestZone, DestLocationId, DestLocation, LocationId, Location)
        select OrderId, OrderDetailId, OrderType, SKUId,
               Case
                 when (@Operation in ('AllocateUnitsForDynamicReplenishments')) then 0 /* No cases, only units */
                 when (@Operation in ('AllocateCasesForDynamicReplenishments')) and (@vUnitsPerPackage > 0) then (UnitsToAllocate / @vUnitsPerPackage) /* Allocate only what is required */
                 /* UnitsToAllocate should be converted to float value else the division returns only integer value */
                 when @vUnitsPerPackage > 0 then ceiling((UnitsToAllocate * 1.0) / @vUnitsPerPackage) else 0
               end /* Cases to Allocate */,
               Case
                 when (@Operation in ('AllocateUnitsForDynamicReplenishments')) then UnitsToAllocate /* No cases, only units */
                 when @vUnitsPerPackage >= 1 then UnitsToAllocate % @vUnitsPerPackage else UnitsToAllocate
               end /* Units to Allocate */,
               DestZone, DestLocationId, DestLocation, LocationId, Location
        from vwPickBatchDetailsToAllocate
        where (PickBatchId = @vPickBatchId) and
              (SKUId       = @SKUId)     and
              (coalesce(DestZone, '') = coalesce(@DestZone, '')) and
    --          (Location is not null)     and       -- why Location will be there on OD if it is not a Replenish Order??
              (OrderType   <> 'B');
    end
  else
  /* insert SKU details into temp table */
  if (@Operation in ('BPTAllocation', 'AllocateDirectedQtyForBulk'))
    begin
      insert into @ttOrderDetailsToAllocate (OrderId, OrderDetailId, OrderType, SKUId, CasesToAllocate, UnitsToAllocate, DestZone, DestLocation, DestLocationId, LocationId, Location)
        select OrderId, OrderDetailId, OrderType, SKUId,
               Case
                 when @vUnitsPerPackage >= 1 then UnitsToAllocate / @vUnitsPerPackage else 0
               end /* Cases to Allocate */,
               Case
                 when @vUnitsPerPackage >= 1 then UnitsToAllocate % @vUnitsPerPackage else UnitsToAllocate
               end /* Units to Allocate */,
               DestZone, DestLocation, DestLocationId, LocationId, Location
        from vwPickBatchDetailsToAllocate
        where (PickBatchId = @vPickBatchId) and
              (SKUId       = @SKUId)    and
              (coalesce(DestZone, '') = coalesce(@DestZone, '')) and
              (OrderType   = 'B');
    end
  else
    begin    /* if that is not BPT allocation then we need to allocate inventory in case picks only */
      insert into @ttOrderDetailsToAllocate (OrderId, OrderDetailId, OrderType, SKUId, CasesToAllocate, UnitsToAllocate, DestZone, DestLocation, DestLocationId, LocationId, Location)
        select OrderId, OrderDetailId, OrderType, SKUId,
               Case
                 when (@Operation in ('AllocateAvailableUnits', 'AllocateDirectedUnits', 'AllocateAvailableQty', 'AllocateDirectedQty')) then 0 /* No cases, only units */
                 when (@vUnitsPerPackage  = 0) then 0 /* If the LPN does not have Inner Packs, then CasesToAllocate should be zero */
                 when @vUnitsPerPackage >= 1 then UnitsToAllocate / @vUnitsPerPackage
                 else 0
               end /* CasesToAllocate */,
               Case
                   when (@Operation in ('AllocateAvailableCases', 'AllocateDirectedCases')) then 0  /* No units, only cases */
                   when ((@vUnitsPerPackage = 0) or (@Operation in ('AllocateAvailableQty', 'AllocateDirectedQty'))) then UnitsToAllocate
                   when @vUnitsPerPackage > 1 then UnitsToAllocate % @vUnitsPerPackage
                   else 0
               end /* UnitsToAllocate */,
               DestZone, DestLocation, DestLocationId, LocationId, Location
        from vwPickBatchDetailsToAllocate
        where (PickBatchId = @vPickBatchId) and
              (SKUId       = @SKUId)  and
              (coalesce(DestZone, '')  = coalesce(@DestZone, '')) and
              (OrderType   <> 'B' /* Bulk Pull */);
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

  --if (charindex('D', @vDebug) > 0) select * from @ttOrderDetailsToAllocate;

  /*************  Allocate Cases **************/
  while (exists (select *
                 from @ttOrderDetailsToAllocate
                 where ((coalesce(CasesToAllocate, 0) > 0) and
                        (RecordId     > @vRecordId))) and
                        (@vLPNInnerPacks > 0) and
                        (@LPNQuantity > 0))
    begin
      /* get one by one here */
      select Top 1
         @vRecordId        = RecordId,
         @vOrderId         = OrderId,
         @vOrderDetailId   = OrderDetailId,
         @vOrderType       = OrderType,
         @vSKUId           = SKUId,
         @vCasesToAllocate = CasesToAllocate,
         @vDestZone        = DestZone,
         @vLocationId      = DestLocationId,
         @vLocation        = DestLocation,
         @vTaskDetailId    = null
      from @ttOrderDetailsToAllocate
      where (coalesce(CasesToAllocate, 0) > 0) and
            (RecordId > @vRecordId)
      order by RecordId;

      /* Calculate Qty to allocate */
      select @vQtyToAllocate   = case
                                   when @vUnitsPerPackage >= 1 then @vCasesToAllocate * @vUnitsPerPackage
                                   else @vUnitsToAllocate
                                 end,
             @vTempLPNDetailId = null;

      /* If the Qty to allocate is greater than the LPN Qty, then reduce it */
      select @vQtyToAllocate = dbo.fn_MinInt(@vQtyToAllocate, @LPNQuantity);

      /* If we found an LPN to allocate then allocate it i.e update LPN, LPNDetail, OrderDetail & OrderHeader.
         If we are not allocating a complete LPN, then this procedure would split the LPN detail and reserve the
         line that needs to be allocated */
      exec @vReturnCode = pr_Allocation_AllocateLPN @LPNId, @vOrderId, @vOrderDetailId, 0 /* Task Detail Id */,
                                                    @vSKUId, @vQtyToAllocate, @UserId, default/* Operation */,
                                                    @vLPNDetailId output;

      if (@vReturnCode = 0)
        begin
          select @LPNQuantity    = (@LPNQuantity - @vQtyToAllocate),
                 @UnitsAllocated = (@UnitsAllocated + @vQtyToAllocate);

          /* Insert all details to temp table */
          insert into @ttAllocatedOrderDetails(PickBatchId, PickBatchNo, OrderId, OrderDetailId, OrderType, LPNId, LPNDetailId, UnitsAllocated, SKUId, DestZone)
            select @vPickBatchId, @PickBatchNo, @vOrderId, @vOrderDetailId, @vOrderType, @LPNId, @vLPNDetailId, @vQtyToAllocate, @SKUId, @vDestZone;

          /* reset values here */
          select @vLPNDetailId = null;
        end

      /* create a directed line if the LPN is allocated */
      if (@vOrderType in ('R', 'RU', 'RP'/* Replenish, Replenish Units, Replenish Cases */))
        begin
           /* call procedure here to add one directed line to the existing LPN */
          exec pr_LPNDetails_AddDirectedQty @SKUId, @vLocationId, null /* innerpacks */,
                                            @vQtyToAllocate, @vOrderId, @vOrderDetailId, @BusinessUnit,
                                            @vRLPNDetailId output;

          select @vRLPNDetailId = null;
        end
    end

  /* initialize record here */
  select @vRecordId = 0;

  /*************  Allocate Units **************/
  while (exists (select *
                  from @ttOrderDetailsToAllocate
                  where (coalesce(UnitsToAllocate, 0) > 0)) and
                        (@vLPNInnerPacks = 0) and -- can only allocate units from an LPN which is not in InnerPacks
                        (@LPNQuantity > 0))
    begin
      /*  we will loop thru unit allocation. If QtyCondition is not specified in
          allocation rules then it means there is no criteria on the qty and
          hence null should be treated as '' (not LTEQ as it was before) */
      select Top 1
         @vRecordId        = RecordId,
         @vOrderId         = OrderId,
         @vOrderDetailId   = OrderDetailId,
         @vOrderType       = OrderType,
         @vSKUId           = SKUId,
         @vUnitsToAllocate = UnitsToAllocate,
         @vDestZone        = DestZone,
         @vLocationId      = DestLocationId,
         @vLocation        = DestLocation,
         @vTaskDetailId    = null
      from @ttOrderDetailsToAllocate
      where (coalesce(UnitsToAllocate, 0) > 0) and
            ((coalesce(@vQuantityCondition, '') <> 'LTEQ')   or
             (UnitsToAllocate >= @LPNQuantity))
            --(@RecordId > @vRecordId)
      order by OrderId, case when @vQuantityCondition = 'LTEQ'
                             then UnitsToAllocate
                        end desc, RecordId;

      select @vTempLPNDetailId = null,
             @vUnitsToAllocate = case when @vQuantityCondition = 'GTEQ' then @LPNQuantity -- If overallocating, take entire LPN
                                      else dbo.fn_MinInt(@LPNQuantity, @vUnitsToAllocate)
                                 end;

      /* We need to allocate the available units */
      if (@vUnitsToAllocate is not null)
        exec @vReturnCode = pr_Allocation_AllocateLPN @LPNId, @vOrderId, @vOrderDetailId, 0 /* TaskDetail Id */,
                                                      @vSKUId, @vUnitsToAllocate, @UserId, null/* Operation */,
                                                      @vLPNDetailId output;

      /* set here Quantity remainig and Quantity allocated  */
      select @LPNQuantity    = (@LPNQuantity - @vUnitsToAllocate),
             @UnitsAllocated = (@UnitsAllocated + @vUnitsToAllocate);

      /* Insert all details to temp table */
      if (@vUnitsToAllocate is not null)
        insert into @ttAllocatedOrderDetails(PickBatchId, PickBatchNo, OrderId, OrderDetailId, OrderType, LPNId, LPNDetailId, UnitsAllocated, SKUId, DestZone)
          select @vPickBatchId, @PickBatchNo, @vOrderId, @vOrderDetailId, @vOrderType, @LPNId, @vLPNDetailId, @vUnitsToAllocate, @SKUId, @vDestZone;

      /* Update temp table with allocated units */
      update @ttOrderDetailsToAllocate
      set UnitsToAllocate = UnitsToAllocate - @vUnitsToAllocate,
          @vLPNDetailId   = null
      where (RecordId = @vRecordId);

      /* create a directed line if the LPN is allocated */
      if (@vOrderType in ('R', 'RU', 'RP'/* Replenish, Replenish Units, Replenish Cases */))
        begin
          /* call procedure here to add one directed line to the existing LPN */
          exec pr_LPNDetails_AddDirectedQty @SKUId, @vLocationId, null /* innerpacks*/,
                                            @vUnitsToAllocate, @vOrderId, @vOrderDetailId, @BusinessUnit,
                                            @vRLPNDetailId output;

          select @vRLPNDetailId = null;
        end
    end  /* End of the details to allcoate loop - units to allcoate */

  select PickBatchId,
         PickBatchNo,
         OrderId,
         OrderDetailId,
         OrderType,
         LPNId,
         LPNDetailId,
         UnitsAllocated,
         SKUId,
         DestZone
  from @ttAllocatedOrderDetails
  order by OrderId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateLPNToOrders */

Go
