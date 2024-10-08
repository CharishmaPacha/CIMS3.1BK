/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/27  AY      pr_Allocation_FindAllocableLPNs: Only consider active Allocation Rules
  2018/11/06  AY      fn_Allocation_GetAllocationRules, pr_Allocation_FindAllocableLPN, pr_Allocation_FindAllocableLPNs:
                        Changed to use LocationSubType and UDFs in Allocation Rules to
                        have option to allcoate from Dynamic picklanes before static picklanes (HPI-2119)
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
  2016/11/30  VM      pr_Allocation_FindAllocableLPN: Bug-fix: Corrected coalesce in join statement
  2016/10/27  ??      pr_Allocation_FindAllocableLPN: Included missing case statement (HPI-GoLive)
  2016/10/14  AY      pr_Allocation_FindAllocableLPN: Replenish from DC1 first and Gainsville after (HPI-GoLive)
  2016/04/06  AY      pr_Allocation_FindAllocableLPN: Setup FIFO, AllocateWave: Prevent Shipped/Completed waves from being allocated
  2015/10/17  VM      Move debug from pr_Allocation_AllocateInventory to pr_Allocation_FindAllocableLPN as we are passing allocation rules now (FB-440)
  2015/10/08  AY      pr_Allocation_FindAllocableLPN: Pass Allocation rules temp table
  2015/10/08  AY      pr_Allocation_FindAllocableLPN: Pass Allocation rules temp table
                      pr_PickBatch_FindAllocableLPN => pr_Allocation_FindAllocableLPN
              VM      pr_Allocation_AllocateInventory: Include PickPath and some UDFs in ttAllocableLPNs
                      pr_Allocation_FindAllocableLPN: Code cleanup and corrected to use PickPath in case of OrderByField is PickPath
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_FindAllocableLPN') is not null
  drop Procedure pr_Allocation_FindAllocableLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_FindAllocableLPN:

  This procedure will take Allocation ruleId and all the available inventory for the
  SKU.

  This will gives us the LPN which we need to allocate for the order(s).

  If SearchType = 'F' (Full) we only need to allocate LPNs that can be fully allocated i.e.
  nothing is reserved in them. If SearchType = 'P' (Partial) then we can allocate Cases or Units
  from an LPN and hence even if the LPN is already partially allocated that is fine

------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_FindAllocableLPN
  (@SKUId               TRecordId,
   @BusinessUnit        TBusinessUnit,
   @AllocationRuleGroup TDescription,
   @UnitsNeeded         TInteger,
   @LPNIdToAssign       TRecordId    output,
   @LPNDetailId         TRecordId    output,
   @UnitsToAssign       TInteger     output,
   @Debug               TFlags     = null)
as
  declare @vAllocationRuleId TRecordId;
begin /* pr_Allocation_FindAllocableLPN */
  /* Get the debug option */
  if (@Debug is null)
    exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @Debug output;

  /* Need to get the first one from the allocable inventory */
  select top 1
    @vAllocationRuleId  = AR.RuleId,
    @LPNIdToAssign      = AL.LPNId,
    @LPNDetailId        = AL.LPNDetailId,
    @UnitsToAssign      = case   /* qty in Units */
                            when (AR.QuantityCondition = 'GTEQ') and (AL.LocationType in ('R', 'B')) then
                              AL.AllocableQuantity -- If overallocating, take the entire LPN
                            when ((charindex('U' /* Units */, AL.StorageType) > 0) or
                                 (AL.UnitsPerPackage = 0)) then
                              dbo.fn_MinInt(AL.AllocableQuantity, @UnitsNeeded)
                            when (AL.UnitsPerPackage > 0) and (AR.SearchType = 'CS')/* Case */ then
                              /* If UnitsPerPackage is greater than zero then allocate units in multiples of cases
                                 always allocate a case higher than required quantity i,e. if UnitsNeeded is 40 & UnitsPerPackage is 30
                                 that gives you 1 case and 10 units, allocate 2cases(ceiling used) in this scenario */
                              dbo.fn_MinInt((AL.AllocableQuantity / AL.UnitsPerPackage),
                                            ceiling(@UnitsNeeded * 1.0/ AL.UnitsPerPackage)) * AL.UnitsPerPackage
                            when (AL.AllocableInnerPacks = 0) then  -- Allocate units if Innerpacks is zero
                              dbo.fn_MinInt(AL.AllocableQuantity, @UnitsNeeded)
                            else /* qty in casepacks */
                              dbo.fn_MinInt((AL.AllocableQuantity / coalesce(AL.UnitsPerPackage, 1)),
                                            (@UnitsNeeded / coalesce(AL.UnitsPerPackage, 1))) * coalesce(AL.UnitsPerPackage, 1)
                          end
  from #AllocableLPNs  AL
    join #AllocationRules AR on (coalesce(AR.RuleGroup,      '') = coalesce(@AllocationRuleGroup, RuleGroup,           '')) and
                                (coalesce(AL.LocationType,   '') = coalesce(AR.LocationType,      AL.LocationType,     '')) and
                                (coalesce(AL.LocationSubType,'') = coalesce(AR.LocationSubType,   AL.LocationSubType,  '')) and
                                (coalesce(AL.StorageType,    '') = coalesce(AR.StorageType,       AL.StorageType,      '')) and
                                (coalesce(AL.PickingClass,   '') = coalesce(AR.PickingClass,      AL.PickingClass,     '')) and
                                (coalesce(AL.ReplenishClass, '') = coalesce(AR.ReplenishClass,    AL.ReplenishClass,   '')) and
                                (coalesce(AL.PickZone,       '') = coalesce(AR.PickingZone,       AL.PickZone,         '')) and
                                (coalesce(AL.AL_UDF1,        '') = coalesce(AR.AR_UDF1,           AL.AL_UDF1,          '')) and
                                (coalesce(AL.AL_UDF2,        '') = coalesce(AR.AR_UDF2,           AL.AL_UDF2,          '')) and
                                (coalesce(AL.AL_UDF3,        '') = coalesce(AR.AR_UDF3,           AL.AL_UDF3,          ''))
  where (AL.ProcessFlag  = 'N' /* No */)      and

        /* When QuantityCondition = LTEQ we only allocate if all Qty in LPN can be taken i.e. we don't want to break up the LPN */
        ((coalesce(AR.QuantityCondition, '') <> 'LTEQ') or
         ((AR.QuantityCondition = 'LTEQ')  and ((AL.AllocableQuantity <= @UnitsNeeded)))) and

        /* If SearchType = F, then we can only choose an LPN which is completely allocable i.e. there no reserved units in LPN */
        ((AR.SearchType <> 'F') or ((AL.AllocableQuantity = AL.TotalQuantity) and (AL.NumLines = 1))) and

        /* If SearchType = UD we selected Directed lines else we select only Available lines */
        ((AR.SearchType <> 'UD' and AL.OnhandStatus = 'A' /* Available */) or
         (AR.SearchType = 'UD' and AL.OnhandStatus = 'D' /* Directed */)) and

         (coalesce(AL.PickingClass, '') = coalesce(AR.PickingClass, AL.PickingClass, '')) and

        /* if it is an LPN w/ inner packs, we can only choose the LPN if
           at least one innerpack qty is needed. If it is an LPN without an
          innerpack, then UnitsPerPackage would be zero and so any LPN qualifies */
        ((AL.UnitsPerPackage = 0) or -- LPN without InnerPack
         (AL.AllocableInnerPacks = 0) or
         ((AR.QuantityCondition = 'LTE1IP' /* Less than or Equal to 1 InnerPak */) and (AL.AllocableInnerPacks = 1) and (AL.AllocableQuantity <= UnitsPerPackage)) or
         ((AR.QuantityCondition = 'LT1IP'  /* Less than 1 InnerPak             */) and (AL.AllocableInnerPacks = 1) and (AL.AllocableQuantity < UnitsPerPackage)) or
         ((AR.SearchType = 'F') and (@UnitsNeeded      >= AL.AllocableQuantity)) or      -- Do not consider IPs if entire case can be allocated
         ((AR.QuantityCondition = 'GTEQ') and (AL.AllocableQuantity >= @UnitsNeeded)) or  -- Overallocate!
         (@UnitsNeeded      >= AL.UnitsPerPackage)                                     -- LPN w/ InnerPacks and we can allocate at least one InnerPack
        )
  order by AL.SortSeq;

  if (charindex('D' /* Display */, @Debug) > 0)
    select 'FindAllocableLPN',
          @SKUId SKUId, @vAllocationRuleId AllocationRuleId, @AllocationRuleGroup AllocationRuleGroup,
          @UnitsNeeded UnitsNeeded,
          @LPNIdToAssign LPNIdToAllocate,
          @LPNDetailId LPNDetaiIdToAllocate,
          @UnitsToAssign LPNQtyToAllocate;
end /* pr_Allocation_FindAllocableLPN */

Go
