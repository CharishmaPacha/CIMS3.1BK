/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateFromPrePacks') is not null
  drop Procedure pr_Allocation_AllocateFromPrePacks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateFromPrePacks:
    This purpose of this proc is to allocate units from pre-packs and explode
    them as needed. So, if the order requires individual units but we only have
    pre-packs in stock, then we would automatically explode the pre-packs and
    allocate the individual units from within the LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateFromPrePacks
  (@PickBatchId  TRecordId,
   @Operation    TDescription,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @AllocSKU     TSKU = null)
as
  declare @ReturnCode            TInteger,
          @MessageName           TMessageName,
          @Message               TDescription,

          @vRecordId             TRecordId,
          @vPickBatchId          TRecordId,
          @vPickBatchNo          TPickBatchNo,
          @vPickBatchType        TTypeCode,
          @vOrderDetailId        TRecordId,
          @vOrderId              TRecordId,
          @vSKUId                TRecordId,
          @vPrevSKUId            TRecordId,
          @vPrePackSKUId         TRecordId,
          @vPrevPrePackSKUId     TRecordId,
          @vLPNId                TRecordId,
          @vSKU                  TSKU,
          @vLPNToAllocate        TLPN,
          @vLPNIdToAllocate      TRecordId,
          @vLPNDetailId          TRecordId,
          @vLocToAllocate        TLocation,
          @vSKUToAllocate        TSKU,
          @vUnitsAllocated       TQuantity,
          @vUnitsToAllocate      TQuantity,
          @vInnerPacks           TInnerpacks,
          @MaxPrePacksToBreak    TQuantity,
          @vBusinessUnit         TBusinessUnit,
          @vWarehouse            TWarehouse,
          @ttTaskInfo            TTaskInfoTable,
          @vAllocationRecId      TRecordId,
          @vAllocationRuleId     TRecordId,
          @ttAllocationrules     TAllocationRulesTable,
          @ttAllocableLPNs       TAllocableLPNsTable,
          @vSearchSet            TDescription,
          @vLocationType         TTypeCode,
          @vSKUABCClass          TFlag,
          @vSearchType           TTypeCode,
          @vPickZone             TZoneId,
          @vPickingClass         TPickingClass,
          @vStorageType          TTypeCode,
          @vRuleGroup            TDescription,
          @vDestZone             TZoneId,
          @vLPNQtyToAllocate     TQuantity,
          @vLPNDetailIdToAllocate TRecordId,
          @vAllocationRuleGroup  TDescription,
          @vOrderTypetoAllocate  TTypeCode,
          @vQtyAllocated         TQuantity,
          @vDebug                TControlValue,
          @vOwnership            TOwnership,
          @vLot                  TLot,

          @vExplodedLPNId        TRecordId,
          @vPrevExplodedLPNId    TRecordId,
          @vMaxPrePacksToExplode TQuantity,
          @vPrePacksExploded     TQuantity;

  declare @ttOrderDetailsToAllocate    TOrderDetailsToAllocateTable,
          @ttSKUOrderDetailsToAllocate TSKUOrderDetailsToAllocate,
          @ttAllocableLPNsExploded     TAllocableLPNsTable;

begin
  SET NOCOUNT ON;

  select @ReturnCode         = 0,
         @MessageName        = null,
         @vRecordId          = 0,
         @vPrevSKUId         = 0,
         @vPrevPrePackSKUId  = 0,
         @vPrevExplodedLPNId = 0,
         @vDebug             = dbo.fn_Controls_GetAsString('Allocation', 'Debug', 'N' /* No */, @BusinessUnit, null /* UserId */);

  /* get Batch Info */
  select @vPickBatchId   = RecordId,
         @vPickBatchType = BatchType,
         @vWarehouse     = Warehouse,
         @vPickBatchNo   = BatchNo,
         @vSearchSet     = BatchType + '_PP'
         -- @vSearchSet     = case
         --                     when @Operation = 'Replenish' then
         --                       BatchType + '_REP'
         --                     when @Operation = 'BPTAllocation' then
         --                       BatchType + '_BO'  /* BPTOrder set */
         --                     when BatchType in ('R', 'RP', 'RU' /* Replenish Cases, Units */) then
         --                       BatchType
         --                     else
         --                       BatchType + '_CO' /* Client Order set */
         --                   end
  from PickBatches
  where (RecordId     = @PickBatchId ) and
        (BusinessUnit = @BusinessUnit);

  /* Assuming all the validation will be done from caller side...*/
  if (@vPickBatchNo is null)
    goto ExitHandler;

  /* insert Allocation rules into temp table here */
  insert into @ttAllocationRules
    select * from dbo.fn_Allocation_GetAllocationRules(@vPickBatchType, @vSearchSet, @vWarehouse, @BusinessUnit);

  if (@vDebug = 'Y') select 'Allocate PP: Rules', * from @ttAllocationRules order by RecordId;

  /* Get all the details for the batch which need to be allocated into the temp table
     Reduce the UnitsToAllocate so that it is in multiples of innerpacks */
  insert into @ttOrderDetailsToAllocate
    select * from dbo.fn_PickBatches_GetOrderDetailsToAllocate(@vPickBatchId, @vPickBatchType, @vOrderTypetoAllocate, @Operation);

  if (@vDebug = 'Y') and (@AllocSKU is not null) delete from @ttOrderDetailsToAllocate where SKU <> @AllocSKU;
  if (@vDebug = 'Y') select 'Allocate PP: OrderDetailsToAllocate', * from @ttOrderDetailsToAllocate

  /* insert all the summarized (based on SKU, destzone) data into temp table */
  insert into @ttSKUOrderDetailsToAllocate(SKUId, PrePackSKUId, DestZone, ABCClass, Ownership, Lot, UnitsToAllocate)  -- Add PrepackSKUId
    select SKUId, MasterSKUId, DestZone, SKUABCClass, Ownership, Lot, sum(UnitsToAllocate)
    from @ttOrderDetailsToAllocate ttOD
      join vwSKUPrePacks SPP on (ttOD.UDF4  = SPP.MasterSKU) and
                                (ttOD.SKUId = SPP.ComponentSKUId)
    group by MasterSKUId, SKUId, DestZone, SKUABCClass, Ownership, Lot;

  if (@vDebug = 'Y') select 'Allocate PP: SKUOrderDetailsToAlloc', * from @ttSKUOrderDetailsToAllocate;

  /* Loop thru each SKU and allocate inventory */
  while (exists (select *
                 from @ttSKUOrderDetailsToAllocate
                 where RecordId > @vRecordId))
    begin
      /* select the next SKU to process */
      select top 1 @vRecordId            = RecordId,
                   @vSKUId               = SKUId,
                   @vPrePackSKUId        = PrePackSKUId,
                   @vSKUABCClass         = ABCClass,
                   @vUnitsToAllocate     = UnitsToAllocate,
                   @vDestZone            = DestZone,
                   @vOwnership           = Ownership,
                   @vLot                 = Lot,
                   @vAllocationRecId     = 0,
                   @vAllocationRuleGroup = 0,
                   @vExplodedLPNId       = 0
      from @ttSKUOrderDetailsToAllocate
      where (RecordId > @vRecordId)
      order by RecordId;

      if (@vPrevPrePackSKUId <> @vPrePackSKUId)
        begin
          /* once SKU has been gone thru, then we need to delete LPNs from temp table */
          delete from @ttAllocableLPNs;

          /* Insert all the availabe LPNs for the SKU into temp table  */
          insert into @ttAllocableLPNs(PickZone, Location, LocationType, StorageType, PickPath, LPNId, LPN, LPNDetailId, NumLines, OnhandStatus,
                                       SKUId, SKU, SKUABCClass, AllocableInnerPacks, AllocableQuantity, TotalQuantity, UnitsPerPackage,
                                       ExpiryInDays, ExpiryMonth, ExpiryDate, ExpiryWindow, ProcessFlag, PickingClass,
                                       AL_UDF1, AL_UDF2, AL_UDF3, AL_UDF4, AL_UDF5)
            exec pr_Allocation_FindAllocableLPNs @vPrePackSKUId, @vWarehouse, @vPickBatchType, @vSearchSet, null /* searchType */,
                                                 null /* Allocation Group */, @vOwnership, @vLot, @vPickBatchId;

          /* exec Procedure to get max number of PrePacks to Break */
          exec pr_Allocation_MaxPrePacksToBreak @ttSKUOrderDetailsToAllocate, @vSKUId, @vPrepackSKUId, @vMaxPrePacksToExplode output;

          /* Explode Prepack LPNs temporarily and save to process further */
          insert into @ttAllocableLPNsExploded(PickZone, Location, LocationType, StorageType, PickPath, LPNId, LPN, LPNDetailId, NumLines, OnhandStatus,
                                               SKUId, SKU, SKUABCClass, AllocableInnerPacks, AllocableQuantity, TotalQuantity, UnitsPerPackage,
                                               ExpiryInDays, ExpiryMonth, ExpiryDate, ExpiryWindow, ProcessFlag, PickingClass,
                                               AL_UDF1, AL_UDF2, AL_UDF3, AL_UDF4, AL_UDF5)
            select PickZone, Location, LocationType, StorageType, PickPath, LPNId, LPN, LPNDetailId, NumLines, OnhandStatus,
                   SPP.ComponentSKUId, SPP.ComponentSKU, SKUABCClass, AllocableInnerPacks * SPP.ComponentQty,
                   AllocableQuantity * SPP.ComponentQty, TotalQuantity * SPP.ComponentQty, UnitsPerPackage * SPP.ComponentQty,
                   ExpiryInDays, ExpiryMonth, ExpiryDate, ExpiryWindow, ProcessFlag, PickingClass,
                   AL_UDF1, AL_UDF2, AL_UDF3, AL_UDF4, AL_UDF5
            from @ttAllocableLPNs AL
              join vwSKUPrePacks SPP on (AL.SKUId = SPP.MasterSKUId) and
                                        (SPP.Status = 'A'/* Active */)

          if (@vDebug = 'Y') select 'Allocable LPNs', * from @ttAllocableLPNs;
        end

      select @vPrevPrePackSKUId = @vPrePackSKUId;

      /* Process the allocation rules for the current SKU */
      while (exists (select *
                     from @ttAllocationrules
                     where (RecordId > @vAllocationRecId) and
                           (RuleGroup   <> @vAllocationRuleGroup) and
                           ((SKUABCClass is null) or (SKUABCClass = @vSKUABCClass))))
         begin
           /* Get next ruleId here */
           select top 1
             @vAllocationRecId     = RecordId,
             @vAllocationRuleId    = RuleId,
             @vAllocationRuleGroup = RuleGroup,
             @vSearchSet           = SearchSet,
             @vSearchType          = SearchType  --We will use PickingClass one we defined it clearly
           from @ttAllocationrules
           where (RecordId    >  @vAllocationRecId    ) and
                 (RuleGroup   <> @vAllocationRuleGroup) and
                 ((SKUABCClass is null) or (SKUABCClass = @vSKUABCClass))
           order by RecordId;

           /* If there are no rules then break */
           if (@@rowcount = 0) break;

           update @ttAllocableLPNsExploded
           set ProcessFlag = 'N' /* No */
           where (AllocableQuantity > 0) and
                 (ProcessFlag = 'Y');

           /* While there are more units to be allocated, find an LPN at a time and allocate it */
           while (@vUnitsToAllocate > 0)
             begin
               select @vLPNQtyToAllocate = null, @vLPNIdToAllocate = null, @vLPNDetailIdToAllocate = null, @vPrePacksExploded = 0;

               exec pr_Allocation_FindAllocableLPN @vSKUId, @BusinessUnit, @ttAllocationRules, @vAllocationRuleGroup,
                                                   @ttAllocableLPNsExploded, @vUnitsToAllocate,
                                                   @vLPNIdToAllocate       output,
                                                   @vLPNDetailIdToAllocate output,
                                                   @vLPNQtyToAllocate      output;

               /* if there is no LPN found then we need to break and continue with the next rule(outer loop) */
               if (coalesce(@vLPNIdToAllocate, 0) = 0)
                 break;

               /* Explode LPN which needs to be allocated */
               if (@vLPNIdToAllocate <> @vPrevExplodedLPNId) and (@vMaxPrePacksToExplode > 0)
                 exec pr_Allocation_ExplodePrePack @vLPNIdToAllocate, @vPrePackSKUId, @BusinessUnit, @UserId,
                                                   @vMaxPrePacksToExplode, @vPrePacksExploded output;

               /* Get the Exploded LPN DetailId to Allocate */
               select @vLPNDetailIdToAllocate = LPNDetailId
               from LPNDetails
               where (LPNId = @vLPNIdToAllocate) and
                     (SKUId = @vSKUId) and
                     (OnhandStatus = 'A');

               set @vPrevExplodedLPNId = @vLPNIdToAllocate;

               insert into @ttTaskInfo(PickBatchNo, OrderId, OrderDetailId, OrderType, LPNId, LPNDetailId, UnitsToAllocate, SKUId, DestZone)
                 exec pr_Allocation_AllocateLPNToOrders @vPickBatchNo, @vLPNIdToAllocate, @vLPNDetailIdToAllocate, @vLPNQtyToAllocate,
                                                        @vSKUId, @Operation, @vDestZone, @vAllocationRuleId, @vQtyAllocated output, @vWarehouse, @BusinessUnit, @UserId;

               select @vQtyAllocated = coalesce(@vQtyAllocated, 0);

               /* Reduce the unitstoallocate */
               select @vUnitsToAllocate      -= @vQtyAllocated,
                      @vMaxPrePacksToExplode -= @vPrePacksExploded;

               update @ttAllocableLPNsExploded
               set ProcessFlag        = 'Y' /* Yes */,
                   AllocableQuantity -= @vQtyAllocated
               where (LPNId = @vLPNIdToAllocate) and
                     (SKUId = @vSKUId);

               /* Update picking class in temp table (LPNDetails is already updated in ExplodePrePack above) so that
                  the next component SKU is allocated from this LPN. Note that we search for LPNs to allocate
                  in Temp table only */
               update @ttAllocableLPNsExploded
               set PickingClass = 'BP'
               where (LPNId = @vLPNIdToAllocate);
             end  /* End of UnitsToAllocate Inv */

         end  /* End of the Allocation Rules Loop */

      /* Reset values here  */
      select @vSKU             = null,
             @vUnitsToAllocate = null,
             @vSKUId           = null,
             @vLPNToAllocate   = null,
             @vLPNIdToAllocate = null,
             @vLocToAllocate   = null,
             @vSKUToAllocate   = null,
             @vUnitsAllocated  = null,
             @vLPNDetailId     = null;

    end  /* End of SKUs loop */

  if (@vDebug = 'Y') select 'pr_Allocation_AllocateInventory: @ttTaskInfo', * from @ttTaskInfo;

  /* For all the LPNs allocated, create the pick tasks */
  exec pr_PickBatch_CreatePickTasks @vPickBatchId, @ttTaskInfo, 'Allocation' /* Operation */, @vWarehouse, @BusinessUnit, @UserId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Allocation_AllocateFromPrePacks */

Go
