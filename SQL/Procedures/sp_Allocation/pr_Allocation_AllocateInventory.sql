/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/28  TK      pr_Allocation_GetAllocableLPNs, pr_Allocation_GetAllocationRules, pr_Allocation_PrepareAllocableLPNs &
                        pr_Allocation_GetOrderDetailsToAllocate & pr_Allocation_PrepareToAllocateInventory: Initial Revision
                      pr_Allocation_AllocateInventory: Code revamp - WIP Changes (HA-86)
  2018/04/05  TK      pr_Allocation_AllocateInventory: Do not alter serach set for replenishments (S2G-582)
                      pr_Allocation_AllocateWave: Bug fix to avoid allocating Replenish wave when multiple waves are released for allocation (S2G-577)
  2018/03/29  TK      pr_Allocation_AllocateInventory: Do not change operation on to allocate directed quantity (S2G-499)
  2018/03/23  SV      pr_Allocation_AllocateInventory: Changes to make the inventory available for allocating other Orders in case
                        of a LPN having multiple available lines of the same SKU (FB-1115)
  2018/03/06  VM      pr_Allocation_AllocateLPN, pr_Allocation_AllocateInventory:
                        Add activity log on LPN Details and Task Details (S2G-344)
  2018/03/02  TK      pr_Allocation_AllocateLPN: Changes to create PR lines only for picklanes
                      pr_Allocation_AllocateInventory: Changes to update WaveId on task details
                      pr_Allocation_AllocateLPNToOrders: Changes to increment qty on the task
                        detail if there is on for order detail
                      pr_Allocation_FindAllocableLPN: Changes to over allocate LPNs from Bulk Location
                      pr_Allocation_SumPicksFromSameLocation: Initial Revision (S2G-151)
  2017/10/21  TK      pr_Allocation_AllocateInventory: Get Allocation Rules in order of RuleGroup (HPI-1713)
  2017/08/08  TK      pr_Allocation_AllocateInventory & fn_PickBatches_GetAllocationRules:
                        Changes to consider ReplenishClass while allocating inventory
                      pr_Picking_FindAllocableLPNs => pr_Allocation_FindAllocableLPNs
                      pr_Allocation_AllocateLPNToOrders: renamed from pr_PickBatch_AllocateLPNToOrders(HPI-1625)
  2017/07/20  TK      pr_Allocation_AllocateWave, pr_Allocation_AllocateInventory & pr_Allocation_CreateTaskDetails:
                        Added markers to check time delays (HPI-1608)
  2016/12/01  TK      pr_Allocation_AllocateInventory: Changes to Picking_FindAllocableLPNs proc to pass in WaveId (HPI-1125)
  2016/08/10  TK      pr_Allocation_AllocateWave & pr_Allocation_AllocateInventory:
                        Enhanced to allocate Bulk Pick Ticket against directed qty (HPI-442)
  2015/10/17  VM      Move debug from pr_Allocation_AllocateInventory to pr_Allocation_FindAllocableLPN as we are passing allocation rules now (FB-440)
  2015/10/08  AY      pr_Allocation_FindAllocableLPN: Pass Allocation rules temp table
                      pr_PickBatch_FindAllocableLPN => pr_Allocation_FindAllocableLPN
              VM      pr_Allocation_AllocateInventory: Include PickPath and some UDFs in ttAllocableLPNs
                      pr_Allocation_FindAllocableLPN: Code cleanup and corrected to use PickPath in case of OrderByField is PickPath
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateInventory') is not null
  drop Procedure pr_Allocation_AllocateInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateInventory:
    This proc is to used to allocate Inventory (Full/Partial LPNs) for the PickBatches/Orders.
    This Procedure will take the BatchNo is input and get all the order details
    that need to be allocated. It searches for the Inventory for the each line of
    Order detail, and will find and allocate each full/partial LPN. Finally, it
    would also send that info to Create Tasks procedure which would break up the
    allocations as PickTasks/TaskDetails.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateInventory
  (@WaveId                TRecordId,
   @TransactionScope      TTransactionScope,
   @Operation             TOperation,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @AllocSKU              TSKU = null)
as
  declare @vReturnCode                   TInteger,
          @vMessageName                  TMessageName,
          @vMessage                      TDescription,
          @vDebug                        TFlags,

          @vWaveId                       TRecordId,
          @vWaveNo                       TPickBatchNo,
          @vWaveType                     TTypeCode,
          @vOwnership                    TOwnership,
          @vWarehouse                    TWarehouse,
          @vBusinessUnit                 TBusinessUnit,

          @vAllocationRecId              TRecordId,
          @vAllocationRuleId             TRecordId,
          @vAllocationRuleGroup          TDescription,
          @vSearchSet                    TDescription,

          @vSKURecordId                  TRecordId,
          @vSKUId                        TRecordId,
          @vSKU                          TSKU,
          @vKeyValue                     TDescription,
          @vUnitsToAllocate              TQuantity,

          @vLPNIdToAllocate              TRecordId,
          @vLPNDetailIdToAllocate        TRecordId,
          @vLPNQtyToAllocate             TQuantity,
          @vQtyAllocated                 TQuantity;

  declare @ttTaskInfo                    TTaskInfoTable,
          @ttAllocableLPNs               TAllocableLPNsTable,
          @ttAllocationRules             TAllocationRulesTable,
          @ttOrderDetailsToAllocate      TOrderDetailsToAllocateTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vSKURecordId = 0,
         @vSearchSet   = @Operation;

  /* Get Debug Options */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  /* get Wave Info */
  select @vWaveId    = RecordId,
         @vWaveNo    = BatchNo,
         @vWaveType  = BatchType,
         @vWarehouse = Warehouse
  from Waves
  where (RecordId  = @WaveId);

  /* Create required hash tables */
  select * into #AllocableLPNs             from @ttAllocableLPNs;
  select * into #AllocationRules           from @ttAllocationRules;
  select * into #OrderDetailsToAllocate    from @ttOrderDetailsToAllocate;
  select * into #SKUOrderDetailsToAllocate from @ttOrderDetailsToAllocate;
  select * into #TaskInfo                  from @ttTaskInfo;

  /* Prepare hash tables for allocation */
  exec pr_Allocation_PrepareToAllocateInventory @vWaveId, @Operation, @BusinessUnit, @UserId;

  /* Get Allocation rules, executing following procedure will insert Allocation Rules into #ttAllocationRules table */
  exec pr_Allocation_GetAllocationRules @vWaveType, @vSearchSet, @vWarehouse, @BusinessUnit, @vDebug;

  /* Get all the order details to be allcoated for the given wave
     executing following procedure will insert required order details into #ttOrderDetailsToAllocate table */
  exec pr_Allocation_GetOrderDetailsToAllocate @vWaveId, @Operation, @BusinessUnit, @UserId, @vDebug;

  /* insert all the summarized (based on SKU, destzone) data into temp table */
  insert into #SKUOrderDetailsToAllocate (SKUId, Warehouse, DestZone, Ownership, Lot,
                                          InventoryClass1, InventoryClass2, InventoryClass3, UnitsToAllocate)
    select SKUId, Warehouse, DestZone, Ownership, Lot,
           InventoryClass1, InventoryClass2, InventoryClass3, sum(UnitsToAllocate)
    from #OrderDetailsToAllocate
    group by SKUId, Warehouse, DestZone, Ownership, Lot, InventoryClass1, InventoryClass2, InventoryClass3;

  if (charindex('D' /* Display */, @vDebug) > 0) select 'Allocate Inv: SKUOrderDetailsToAlloc', * from #SKUOrderDetailsToAllocate;

  /* Loop thru each SKU and allocate inventory */
  while (exists (select * from #SKUOrderDetailsToAllocate where RecordId > @vSKURecordId))
    begin
      /* Reset variables */
      select @vUnitsToAllocate = null, @vAllocationRuleGroup = '';

      /* select the next SKU to process */
      select top 1 @vSKURecordId     = RecordId,
                   @vSKUId           = SKUId,
                   @vKeyValue        = KeyValue,
                   @vUnitsToAllocate = UnitsToAllocate
      from #SKUOrderDetailsToAllocate
      where (RecordId > @vSKURecordId)
      order by RecordId;

      /* If this procedure handles the transactions, then start one for each SKU */
      if (@TransactionScope = 'Procedure')
        begin transaction; -- Start a new transaction for the current SKU

      delete from #TaskInfo; -- Clear temp table

      /* Get all the LPNs that can be allocated, GetAllocableLPNs procedure will insert all the LPNs
         that can be allocated as per the criteria defined into #AllocableLPNs table */
      exec pr_Allocation_GetAllocableLPNs @vWaveId, @vSKURecordId, @vWarehouse, @Operation, @BusinessUnit, @vDebug;

      /* If not LPNs found then continue with next SKU */
      if not exists(select * from #AllocableLPNs)
        continue;

      /* Process the allocation rules for the current SKU */
      while (exists (select *
                     from #Allocationrules
                     where (RuleGroup > @vAllocationRuleGroup)))
         begin
           /* Get next ruleId here */
           select top 1 @vAllocationRuleGroup = RuleGroup
           from #Allocationrules
           where (RuleGroup > @vAllocationRuleGroup)
           order by RecordId;

           /* Prepare Allocable LPNs for allocation */
           exec pr_Allocation_PrepareAllocableLPNs @vWaveId, @vAllocationRuleGroup, @vKeyValue, @Operation, @BusinessUnit, @UserId, @vDebug;

           /* While there are more units to be allocated and there exists LPNs which can be allocated
              find an LPN at a time and allocate it */
           while (@vUnitsToAllocate > 0) and exists (select * from #AllocableLPNs where ProcessFlag = 'N'/* Need to be processed */)
             begin
               select @vLPNQtyToAllocate = null, @vLPNIdToAllocate = null, @vLPNDetailIdToAllocate = null;

               exec pr_Allocation_FindAllocableLPN @vSKUId, @BusinessUnit, @vAllocationRuleGroup,
                                                   @vUnitsToAllocate,
                                                   @vLPNIdToAllocate       output,
                                                   @vLPNDetailIdToAllocate output,
                                                   @vLPNQtyToAllocate      output,
                                                   @vDebug;

               /* If there is no LPN found then we need to break and continue with the next rule */
               if (@vLPNIdToAllocate is null)
                 break;

               exec pr_Allocation_AllocateLPNToOrders_New @vWaveId, @vLPNIdToAllocate, @vLPNDetailIdToAllocate, @vLPNQtyToAllocate,
                                                          @vSKUId, @vKeyValue, @Operation, @vAllocationRuleGroup, @vQtyAllocated output,
                                                          @BusinessUnit, @UserId, @vDebug;

               select @vQtyAllocated = coalesce(@vQtyAllocated, 0);

               /* Reduce the UnitsToAllocate */
               set @vUnitsToAllocate -= @vQtyAllocated;

               /* There is chance that a LPN can have multiple lines of the same SKU. So, during allocation,
                  we should be marking ProcessFlag as "Y" only the LPND lines which are allocated at the current moment.
                  Such that remaining LPND lines will be available for other Orders allocation. */
               update #AllocableLPNs
               set ProcessFlag = 'Y' /* Yes */,
                   AllocableQuantity -= @vQtyAllocated
               where (LPNId = @vLPNIdToAllocate) and
                     (LPNDetailId = @vLPNDetailIdToAllocate);
             end  /* End of UnitsToAllocate Inv */
         end  /* End of the Allocation Rules Loop */

      /* Create Task Details */
      exec pr_Allocation_CreateTaskDetails @vWaveId, default /* Task info */, @Operation, @vWarehouse, @BusinessUnit, @UserId;

      /* If this procedure handles the transactions, then commit for each SKU */
      if (@TransactionScope = 'Procedure') and (@@trancount > 0)
        commit;
    end  /* End of SKUs loop */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateInventory */

Go
