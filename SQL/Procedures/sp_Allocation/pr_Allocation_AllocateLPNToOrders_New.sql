/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/11  TK      pr_Allocation_AllocateLPNToOrders_New: Changes to allocate cases from LPNs (BK-181)
  2020/05/26  TK      pr_Allocation_AllocateLPN_New: Bug fix when complete LPN detail cannot be allocated
                      pr_Allocation_AllocateLPNToOrders_New: Changes to add reserved LPNDetailId instead of FromLPNDetailId (HA-658)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateLPNToOrders_New') is not null
  drop Procedure pr_Allocation_AllocateLPNToOrders_New;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateLPNToOrders_New: This procedure allocated inventory from the LPNs.

    Allocation will be done based on the Operation as follows
    1. Allocates inventory in multiples of cases and residual units if any will be allocated as units
    2. Allocated inventory in units irrespective of whether LPN has cases or units
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateLPNToOrders_New
  (@WaveId                 TRecordId,
   @LPNId                  TRecordId,
   @LPNDetailId            TRecordId,
   @LPNQuantity            TQuantity,
   @SKUId                  TRecordId,
   @KeyValue               TDescription,
   @Operation              TDescription,
   @AllocationRuleGroup    TDescription,
   @UnitsAllocated         TQuantity  output,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @Debug                  TFlags   = null)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vRecordId                  TRecordId,

          @vOrderId                   TRecordId,
          @vOrderDetailId             TRecordId,
          @vOrderType                 TTypeCode,
          @vUnitsToAllocate           TQuantity,

          @vReservedLPNDetailId       TRecordId,
          @vRLPNDetailId              TRecordId,
          @vLPNInnerPacks             TInteger,
          @vUnitsPerPackage           TInteger,

          @vWaveId                    TRecordId,
          @vWaveNo                    TWaveNo,
          @vQtyToAllocate             TQuantity,
          @vCasesToReserve            TQuantity,
          @vQuantityCondition         TTypecode,

          @vDestLocationId            TRecordId,
          @vDestLocation              TLocation,
          @vDestZone                  TZoneId;
begin /* pr_Allocation_AllocateLPNToOrders_New */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @UnitsAllocated = 0;

  /* Get UnitsPerPackage here */
  select @vLPNInnerPacks   = AllocableInnerPacks,
         @vUnitsPerPackage = UnitsPerPackage
  from #AllocableLPNs
  where (LPNDetailId = @LPNDetailId);

  /* All rules in a particular rule group should similar quantity condition, it cannot have multiple
     combinations of Quantity Condition*/
  /* Get the Quantity Condition */
  select top 1 @vQuantityCondition = QuantityCondition
  from #AllocationRules
  where (RuleGroup = @AllocationRuleGroup);

  /* Update Cases or Units to be reserved based upon the operation
     Please go thru init_Rules_AllocateWave which details the explanation about each operation */
  update #OrderDetailsToAllocate
  set CasesToReserve = case when (@Operation like '%Units%') then 0 /* No cases, only units */
                            when (@Operation like '%Qty%') then 0 /* No cases, only units */
                            when (@vUnitsPerPackage = 0) then 0 /* If the LPN does not have Inner Packs, then CasesToAllocate should be zero */
                            when (@vUnitsPerPackage > 0) then UnitsToAllocate / @vUnitsPerPackage  /* only Cases */
                            else 0
                       end /* CasesToReserve */,
      UnitsToReserve = case when (@Operation like '%Cases%') then 0  /* No units, only cases */
                            when (@Operation like '%Units%') and (@vUnitsPerPackage > 0) then UnitsToAllocate % @vUnitsPerPackage  /* only residual units, excluding cases */
                            when (@Operation like '%Qty%') then UnitsToAllocate /* only units */
                            when (@vUnitsPerPackage = 0) then UnitsToAllocate /* only units */
                            when (@vUnitsPerPackage > 0) then UnitsToAllocate % @vUnitsPerPackage /* only residual units, excluding cases */
                            else 0
                       end /* UnitsToReserve */
  where (KeyValue = @KeyValue);

  if (charindex('D', @Debug) > 0) select * from #OrderDetailsToAllocate;

  /*************  Allocate Cases **************/
  while (exists (select *
                 from #OrderDetailsToAllocate
                 where ((coalesce(CasesToReserve, 0) > 0) and
                        (RecordId > @vRecordId))) and
                        (@vLPNInnerPacks > 0) and
                        (@LPNQuantity > 0))
    begin
      /* Reset variables */
      select @vReservedLPNDetailId = null, @vRLPNDetailId = null;

      /* get one by one here */
      select top 1 @vRecordId        = RecordId,
                   @vWaveId          = WaveId,
                   @vWaveNo          = WaveNo,
                   @vOrderId         = OrderId,
                   @vOrderDetailId   = OrderDetailId,
                   @vOrderType       = OrderType,
                   @vCasesToReserve  = CasesToReserve,
                   @vDestZone        = DestZone,
                   @vDestLocationId  = DestLocationId,
                   @vDestLocation    = DestLocation
      from #OrderDetailsToAllocate
      where (coalesce(CasesToReserve, 0) > 0) and
            (RecordId > @vRecordId)
      order by RecordId;

      /* Calculate Qty to allocate */
      select @vQtyToAllocate = @vCasesToReserve * @vUnitsPerPackage;

      /* If the Qty to allocate is greater than the LPN Qty, then reduce it */
      select @vQtyToAllocate = dbo.fn_MinInt(@vQtyToAllocate, @LPNQuantity);

      /* Allocate LPN  */
      exec @vReturnCode = pr_Allocation_AllocateLPN_New @LPNId, @LPNDetailId, @vOrderId, @vOrderDetailId, 0 /* Task Detail Id */,
                                                        @SKUId, @vQtyToAllocate, @BusinessUnit, @UserId, default/* Operation */,
                                                        @vReservedLPNDetailId output;

      if (@vReturnCode <> 0)
        goto ErrorHandler;

      /* insert info required to create task details */
      insert into #TaskInfo(WaveId, WaveNo, SKUId, OrderId, OrderDetailId, OrderType, LPNId, LPNDetailId,
                            UnitsToAllocate, DestZone, DestLocation, DestLocationId)
        select @vWaveId, @vWaveNo, @SKUId, @vOrderId, @vOrderDetailId, @vOrderType, @LPNId, @vReservedLPNDetailId,
               @vQtyToAllocate, @vDestZone, @vDestLocation, @vDestLocationId;

      /* If inventory is allocated against a replenish order then add directed quantity to the destination location */
      if (@vOrderType in ('R', 'RU', 'RP'/* Replenish */))
        exec pr_LPNDetails_AddDirectedQty @SKUId, @vDestLocationId, null /* innerpacks */,
                                          @vQtyToAllocate, @vOrderId, @vOrderDetailId, @BusinessUnit,
                                          @vRLPNDetailId output;

      /* set Quantity remainig and Quantity allocated  */
      select @LPNQuantity    -= @vQtyToAllocate,
             @UnitsAllocated += @vQtyToAllocate;

      /* Update temp table with allocated units */
      update #OrderDetailsToAllocate
      set CasesToReserve  -= (@vQtyToAllocate / @vUnitsPerPackage),
          UnitsToAllocate -= @vQtyToAllocate
      where (RecordId = @vRecordId);
    end

  set @vRecordId = 0;

  /*************  Allocate Units **************/
  while (exists (select *
                 from #OrderDetailsToAllocate
                 where (coalesce(UnitsToReserve, 0) > 0) and
                       ((coalesce(@vQuantityCondition, '') <> 'LTEQ')   or
                        (UnitsToReserve >= @LPNQuantity)) and
                       (@vLPNInnerPacks = 0) and -- can only allocate units from an LPN which is not in InnerPacks
                       (@LPNQuantity > 0)))
    begin
      /* Reset variables */
      select @vReservedLPNDetailId = null, @vRLPNDetailId = null;

      /*  we will loop thru unit allocation. If QtyCondition is not specified in
          allocation rules then it means there is no criteria on the qty and
          hence null should be treated as '' (not LTEQ as it was before) */
      select top 1 @vRecordId        = RecordId,
                   @vWaveId          = WaveId,
                   @vWaveNo          = WaveNo,
                   @vOrderId         = OrderId,
                   @vOrderDetailId   = OrderDetailId,
                   @vOrderType       = OrderType,
                   @vUnitsToAllocate = UnitsToReserve,
                   @vDestZone        = DestZone,
                   @vDestLocationId  = DestLocationId,
                   @vDestLocation    = DestLocation
      from #OrderDetailsToAllocate
      where (coalesce(UnitsToReserve, 0) > 0) and
            ((coalesce(@vQuantityCondition, '') <> 'LTEQ')   or
             (UnitsToReserve >= @LPNQuantity))
      order by OrderId, case when @vQuantityCondition = 'LTEQ'
                             then UnitsToAllocate
                        end desc, RecordId;

      /* Calculate Qty to allocate */
      select @vUnitsToAllocate = case when @vQuantityCondition = 'GTEQ' then @LPNQuantity -- If overallocating, take entire LPN
                                      else dbo.fn_MinInt(@LPNQuantity, @vUnitsToAllocate)
                                 end;

      if (@vUnitsToAllocate is null)
        continue;

      /* Allocate LPN  */
      exec @vReturnCode = pr_Allocation_AllocateLPN_New @LPNId, @LPNDetailId, @vOrderId, @vOrderDetailId, 0 /* TaskDetail Id */,
                                                        @SKUId, @vUnitsToAllocate, @BusinessUnit, @UserId, null /* Operation */,
                                                        @vReservedLPNDetailId output;

      if (@vReturnCode <> 0)
        goto ErrorHandler;

      /* insert info required to create task details */
      insert into #TaskInfo(WaveId, WaveNo, SKUId, OrderId, OrderDetailId, OrderType, LPNId, LPNDetailId,
                            UnitsToAllocate, DestZone, DestLocation, DestLocationId)
        select @vWaveId, @vWaveNo, @SKUId, @vOrderId, @vOrderDetailId, @vOrderType, @LPNId, @vReservedLPNDetailId,
               @vUnitsToAllocate, @vDestZone, @vDestLocation, @vDestLocationId;

      /* If inventory is allocated against a replenish order then add directed quantity to the destination location */
      if (@vOrderType in ('R', 'RU', 'RP'/* Replenish */))
        exec pr_LPNDetails_AddDirectedQty @SKUId, @vDestLocationId, null /* innerpacks*/,
                                          @vUnitsToAllocate, @vOrderId, @vOrderDetailId, @BusinessUnit,
                                          @vRLPNDetailId output;

      /* set Quantity remainig and Quantity allocated  */
      select @LPNQuantity    -= @vUnitsToAllocate,
             @UnitsAllocated += @vUnitsToAllocate;

      /* Update temp table with allocated units */
      update #OrderDetailsToAllocate
      set UnitsToAllocate -= @vUnitsToAllocate,
          UnitsToReserve  -= @vUnitsToAllocate
      where (RecordId = @vRecordId);
    end /* End of the details to allcoate loop - units to allcoate */

  /* Reset quantities on #OrderDetailsToAllocate table, they will be updated based upon
     the operation in the next iteration as needed */
  update #OrderDetailsToAllocate
  set CasesToReserve = 0,
      UnitsToReserve = 0
  where (KeyValue = @KeyValue);

  if (charindex('D' /* Display */, @Debug) > 0) select '#TaskInfo' as TaskInfo, * from #TaskInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateLPNToOrders_New */

Go
