/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/21  TK      pr_Allocation_AllocateWave: Pass cartonization model to evaluate rules
                      pr_Allocation_GetWavesToAllocate: Changes return CaronizationModel
                      pr_Allocation_GenerateShipCartonsForPrepacks: Initial Revision (HA-2664)
  2020/10/06  TK      pr_Allocation_AllocateWave: Create pick tasks based upon Pick Method
                      pr_Allocation_GenerateAPITransaction: Initial Revision (CID-1489)
  2020/06/08  TK      pr_Allocation_AllocateWave: Changes to allocate OnDemand Wave (HA-971)
  2020/05/07  TK      pr_Allocation_AddPrintServiceRequests: Initial Revision
                      pr_Allocation_AllocateWave: Added step to add print requests (HA-178)
  2020/05/04  TK      pr_Allocation_GenerateShipCartons: Initial Revision
                      pr_Allocation_AllocateWave: Added step to generate ship cartons (HA-172)
                      pr_Allocation_AllocateWave &  pr_Allocation_GetWavesToAllocate:
                        Allocate inventory based upon InvAllocationModel (HA-385):
  2020/04/15  TK      pr_Allocation_AllocateWave: Changes to cube order details & task details (HA-171)
  2019/10/18  AY      pr_Allocation_AllocateWave/pr_Allocation_GetWavesToAllocate: Fix to reallocate
                        Replen wave on deadlock (CID-Support)
  2019/10/07  TK      pr_Allocation_AllocateWave: Changes to Cubing execute proc signature
                      pr_Allocation_FinalizeWave: Changes to resequence packageseqno (CID-883)
  2018/08/20  RV      pr_Allocation_AllocateWave: Passing Allocation step as an Operation instead of Operation (OB2-553)
  2018/07/02  TK      pr_Allocation_AllocateWave: Changes to Replenish dynamic Locations (S2GCA-63)
  2018/04/11  TK      pr_Allocation_AllocateWave: Added new step to generate temp LPNs
                      pr_Allocation_InsertShipLabels: Changes to consider info from LPNTasks
                      pr_Allocation_SumPicksFromSameLocation: Changes to summarize innerpacks info (S2G-619)
  2018/04/05  TK      pr_Allocation_AllocateInventory: Do not alter serach set for replenishments (S2G-582)
                      pr_Allocation_AllocateWave: Bug fix to avoid allocating Replenish wave when multiple waves are released for allocation (S2G-577)
  2018/03/30  TK      pr_Allocation_AllocateWave: Added step to Unwave disqualified orders
                      pr_Allocation_UnwaveDisQualifiedOrders: Initial Revision (S2G-530)
  2018/03/17  TK      pr_Allocation_AllocateWave: There multiple ondemand waves which would be generated for a Wave, allocated all of them (S2G-385)
  2018/03/17  TK      pr_Allocation_AllocateWave: Changed pr_PickBatch_UpdateDependencies to pr_Wave_UpdateDependencies
  2018/03/03  TK      pr_Allocation_AllocateWave & pr_Allocation_AllocateLPNToOrders:
                        Changes to allocate cases and units separately (S2G-341)
  2018/02/28  RV      pr_Allocation_AllocateWave: Included new step to insert carton into ShipLabels table (S2G-255)
  2018/02/20  TK      pr_Allocation_AllocateWave: Added step to update Wave & Task Dependencies
                      pr_Allocation_CreatePickTasks & pr_Allocation_CreateTaskDetails:
                        Changes to update WaveId on Tasks/Task Details (S2G-152
  2017/10/11  TK      pr_Allocation_AllocateWave: Update Allocate Flags on Wave to 'Done' on successful allocation (HPI-1651)
  2017/09/08  AY/TK   pr_Allocation_AllocateWave: Change to allcoate all waves with larger units to commit by operation (HPI-1664)
  2017/08/17  RV      pr_Allocation_AllocateWave, pr_PickBatch_ReAllocateBatches: Made changes to not allocate waves manually
                        if already allocation starts (HPI-1476)
  2017/07/21  TK      pr_Allocation_AllocateWave: Changes to commit eacch step at a time & added new step to process Task Details
                      pr_Allocation_ProcesstaskDetails: Initial revision (HPI-1608)
  2017/07/20  TK      pr_Allocation_AllocateWave, pr_Allocation_AllocateInventory & pr_Allocation_CreateTaskDetails:
                        Added markers to check time delays (HPI-1608)
  2017/01/16  ??      pr_Allocation_AllocateWave: Added activitylog (HPI-GoLive)
  2016/12/01  VM      Mixed SKU Pallet Allocation changes (FB-826)
                        pr_Allocation_AllocatePallets => pr_Allocation_AllocateSolidSKUPallets.
                        pr_Allocation_AllocateWave: Changes due to modified rule name and newly added rule.
                        pr_Allocation_CreatePalletPick: Introduced.
                        pr_Allocation_AllocateMixedSKUPallets: Introduced.
                        fn_PickBatches_GetOrderDetailsToAllocate: Return Warehouse as well.
                        pr_Allocation_FindAllocablePallets: Introduced.
  2016/08/10  TK      pr_Allocation_AllocateWave & pr_Allocation_AllocateInventory:
                        Enhanced to allocate Bulk Pick Ticket against directed qty (HPI-442)
  2016/07/04  TK      pr_Allocation_ProcessPreAllocatedCases: Inital Revision
                      pr_Allocation_AllocateWave: Included new step to allocate Pre-Reserved cases (HPI-226)
  2016/06/07  TK      pr_Allocation_AllocateWave: Bug fix to ignore the waves for which Allocate Wave rules are not set up (HPI-163)
  2016/05/10  TK      pr_Allocation_AllocateWave: If OnDemand replenish wave is generated the process all the waves again so that
                        duplicate replenish orders wouldn't be generated (NBD-485)
  2015/11/20  DK      pr_Allocation_AllocateWave: Enhanced to get the Replenish batch statuses from controls (FB-499).
  2015/11/10  AY      pr_Allocation_AllocateWave: Turn off AllocationFlag on wave when done.
  2015/07/08  TK      pr_Allocation_AllocateWave: Added Transactions (ACME-278)
  2015/07/18  AY      pr_Allocation_AllocateWave: Update wave counts option added (Acme-231.12)
  2015/07/07  TK      pr_Allocation_AllocateWave: Initial Revision (ACME-52)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateWave') is not null
  drop Procedure pr_Allocation_AllocateWave;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateWave:
    This procedure will take Wave number as input and will allocate inventory,
    and this will create BPT and after that will allcoate the inventory for BPT.

    Once the allocation is done for inventory then if there is any inventory shortage
    then we will create replenishments and will do allocation for that BPT.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateWave
  (@WaveNo       TWaveNo,
   @Operation    TOperation,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @Debug        TFlags = null)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription,
          @vTranCount            TCount,
          @vDebug                TControlValue,

          @vWaveId               TRecordId,
          @vWaveNo               TWaveNo,
          @ReplenishWaveNo       TWaveNo,
          @vWaveType             TTypeCode,
          @vWaveStatus           TStatus,
          @vPickMethod           TPickMethod,
          @vWarehouse            TWarehouseId,
          @vAccount              TAccount,
          @vIsWaveAllocated      TFlags,
          @vWaveNumPicks         TCount,
          @vWaveNumUnits         TQuantity,
          @vWaveCategory1        TCategory,
          @vWaveAttributeId      TRecordId,
          @vWavePlanned          TFlag,
          @vWaveReplenished      TFlag,
          @vInvAllocationModel   TDescription,
          @vCartonizationModel   TDescription,
          @vActivityLogId        TRecordId,
          @vExportSrtData        TControlValue,
          @vRecordId             TRecordId,
          @vTransactionScope     TTransactionScope,
          @vErrorMsg             TMessage,

          @vRuleRecordId         TRecordId,
          @vRuleId               TRecordId,
          @vRuleSetId            TRecordId,
          @vRuleSetName          TName,
          @vOperation            TOperation,
          @vSQL                  TNVarChar,
          @vXMLData              TXML,
          @xmlData               TXML;

  declare @ttRules               TRules,
          @ttWavesToAllocate     TWavesToAllocate;
begin
begin try

  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vWaveId       = 0,
         @vRecordId     = 0,
         @vRuleRecordId = 0,
         @vTranCount    = @@trancount;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;
  select @vDebug = coalesce(@Debug, @vDebug);

  /* Create hash table to capture ondemand waves to be allocated */
  select WaveId, WaveNo, WaveType, WaveStatus, IsAllocated, InvAllocationModel, Warehouse, AllocPriority into #ReplenishWavesToAllocate from @ttWavesToAllocate;

  /* First, select replenish Waves for allocation */
  insert into @ttWavesToAllocate(WaveId, WaveNo, WaveType, WaveStatus, Account, InvAllocationModel, CartonizationModel, IsAllocated, Warehouse, AllocPriority)
    exec pr_Allocation_GetWavesToAllocate @WaveNo, @Operation, @BusinessUnit, @UserId, @Debug;

  if (charindex('D', @vDebug) > 0) select * from @ttWavesToAllocate order by AllocPriority, RecordId;

  /* Loop thru each Wave and allocate inventory */
  while (exists(select *
                from @ttWavesToAllocate
                where (IsAllocated = 'N')))
    begin
      /* get Wave Info */
      select top 1 @vRecordId           = RecordId,
                   @vWaveId             = WaveId,
                   @vWaveType           = WaveType,
                   @vWarehouse          = Warehouse,
                   @vWaveNo             = WaveNo,
                   @vWaveStatus         = WaveStatus,
                   @vAccount            = Account,
                   @vIsWaveAllocated    = IsAllocated,
                   @vInvAllocationModel = InvAllocationModel,
                   @vCartonizationModel = CartonizationModel
      from @ttWavesToAllocate
      where (IsAllocated = 'N')
      order by AllocPriority, RecordId;

      select @vWaveNumPicks  = NumPicks,
             @vWaveNumUnits  = NumUnits,
             @vWaveCategory1 = Category1,
             @vPickMethod    = PickMethod
      from PickBatches
      where (RecordId = @vWaveId);

      select @vTransactionScope = 'EachOperation';

      if (charindex('D', @vDebug) > 0) select 'Next Wave', @vWaveNo Wave, @vWaveType Type, @vWaveStatus Status, @vIsWaveAllocated IsAllocated;

      /* Get details from WaveAttributes */
      select @vWaveAttributeId = RecordId,
             @vWaveReplenished = IsReplenished,
             @vActivityLogId   = null
      from PickBatchAttributes
      where (PickBatchId = @vWaveId);

     /* Build xml to evaluate Rules */
     select @vXMLData = dbo.fn_XMLNode('RootNode',
                          dbo.fn_XMLNode('WaveId',               @vWaveId) +
                          dbo.fn_XMLNode('WaveType',             @vWaveType) +
                          dbo.fn_XMLNode('WaveStatus',           @vWaveStatus) +
                          dbo.fn_XMLNode('Warehouse',            @vWarehouse) +
                          dbo.fn_XMLNode('WaveNo',               @vWaveNo)  +
                          dbo.fn_XMLNode('Account',              @vAccount) +
                          dbo.fn_XMLNode('PickMethod',           @vPickMethod) +
                          dbo.fn_XMLNode('IsAllocated',          @vIsWaveAllocated) +
                          dbo.fn_XMLNode('IsReplenished',        @vWaveReplenished) +
                          dbo.fn_XMLNode('InvAllocationModel',   @vInvAllocationModel) +
                          dbo.fn_XMLNode('CartonizationModel',   @vCartonizationModel) +
                          dbo.fn_XMLNode('NumPicks',             @vWaveNumPicks) +
                          dbo.fn_XMLNode('WaveNumUnits',         @vWaveNumUnits) +
                          dbo.fn_XMLNode('WaveCategory1',        @vWaveCategory1));

     /* Update Allocate Flags as 'I' to do not allocate any users manually */
     update PickBatches
     set AllocateFlags = 'I' /* InProgress */
     where (RecordId = @vWaveId);

     /* Initialize */
     delete from @ttRules;

     /* If we are doing all operations under one transaction, then begin the transaction here */
     if (@vTransactionScope = 'AllOperations') and (@vTranCount = 0)
       begin transaction;

     /* Find the RuleSet to apply for this wave using the params passed in - most often the wave type is
        the determining factor */
     exec pr_RuleSets_Find 'AllocateWave', @vXMLData, @vRuleSetId output, @vRuleSetName output;

     /* Get the rules into Temp table */
     insert into @ttRules(RuleId, RuleSetId, RuleSetName, TransactionScope)
       exec pr_Rules_GetRules @vRuleSetName;

     /* Exclude the Wave if there is no RuleSet found */
     if (@vRuleSetName is null) or (@@rowcount = 0)
       begin
         update @ttWavesToAllocate set IsAllocated = 'X'/* Excluded */ where WaveId = @vWaveId;

         if (@@trancount > 0) and (@vTranCount = 0)
           commit transaction; -- commit transaction if there is any open transaction

         continue;
       end

     /* Loop through the rules and process each one in sequence */
     while (exists(select * from @ttRules where RecordId > @vRuleRecordId))
       begin
         select top 1 @vRuleRecordId     = RecordId,
                      @vRuleId           = RuleId,
                      @vRuleSetId        = RuleSetId,
                      @vTransactionScope = coalesce(TransactionScope, 'EachOperation'),
                      @vOperation        = null,
                      @ReplenishWaveNo   = null,
                      @vActivityLogId    = null
         from @ttRules
         where RecordId > @vRuleRecordId
         order by RecordId;

         /* Process the rule and see if the rule is applicable */
         exec pr_Rules_Process @vRuleSetId, @vRuleId, @vXMLData, @vOperation output;

         /* If rule is not applicable, then process the next rule */
         if (@vOperation is null) continue;

         /* insert into activitylog details, before starting the transaction so that we
            can see which step is running at the time */
         exec pr_ActivityLog_AddOrUpdate 'Wave', @vWaveId, @vWaveNo, 'WaveAllocation',
                                         @vOperation, Default/* xmldata */, Default /* xmlresult */, Default /* DeviceId */,
                                         @UserId, @vActivityLogId output;

         if (@vTransactionScope = 'EachOperation') and (@vTranCount = 0)
           begin transaction  -- begin-Commit for each operation

         if (charindex('D', @vDebug) > 0) select @vOperation Operation, @vRuleId RuleId;

         /* Call proc to remove orders from wave if they cannot be shipped complete */
         if (@vOperation = 'UnWaveIncompleteOrders')
           exec pr_Allocation_PrepWaveForAllocation @vWaveId, @BusinessUnit, @UserId, 'U' /* Unwave */;

         /* call proc to Cube the Order Details and create PickTasks without allocating inventory */
         if (@vOperation = 'GeneratePseudoPicks')
           exec pr_Allocation_GeneratePseudoPicks @vWaveId, @vOperation, @BusinessUnit, @UserId;

         /* call procedure here to allocate available/directed cases/units. When we say
            Available/Directed Qty (instead of cases or units) it means we could just do both in one run */
         if (@vOperation like 'AllocateInv_%')
           exec pr_Allocation_AllocateInventory @vWaveId, @vTransactionScope, @vOperation/* Action */, @BusinessUnit, @UserId;

         if (@vOperation = 'AllocateFromPrePacks')
           exec pr_Allocation_AllocateFromPrePacks @vWaveId, null /* Action */, @BusinessUnit, @UserId;

         /* call procedure here to allocate solid SKU pallets */
         if (@vOperation = 'AllocateSolidSKUPallets')
           exec pr_Allocation_AllocateSolidSKUPallets @vWaveId, null /* WaveNo */, null /* PickTicket */, null /* Operation */,
                                                      @BusinessUnit, @UserId;

         /* call procedure here to allocate mixed SKU pallets */
         if (@vOperation = 'AllocateMixedSKUPallets')
           exec pr_Allocation_AllocateMixedSKUPallets @vWaveId, null /* WaveNo */, null /* PickTicket */, null /* Operation */,
                                                      @BusinessUnit, @UserId;

         /* call procedure here to allocate solid SKU pallets */
         if (@vOperation = 'AllocateSolidSKUPalletsForBulk')
             exec pr_Allocation_AllocateSolidSKUPallets @vWaveId, null /* WaveNo */, null /* PickTicket */, 'BPTAllocation' /* Operation */,
                                                        @BusinessUnit, @UserId;

         /* call procedure here to allocate mixed SKU pallets */
         if (@vOperation = 'AllocateMixedSKUPalletsForBulk')
           exec pr_Allocation_AllocateMixedSKUPallets @vWaveId, null /* WaveNo */, null /* PickTicket */, 'BPTAllocation' /* Operation */,
                                                      @BusinessUnit, @UserId;

         /* call procedure to allocate pre-allocated cases */
         if (@vOperation = 'AllocatePreAllocatedCases')
           exec pr_Allocation_ProcessPreAllocatedCases @vWaveId, null /* Action */, @BusinessUnit, @UserId, @vDebug;

         /* we need to create BPT and allocate the BPT. If BPT already exists for the Wave it will
           just allocate it only */
         if (@vOperation = 'CreateConsolidatedPT')
           exec pr_Allocation_CreateConsolidatedPT @vWaveId, 'AB' /* Allocate Wave */, @BusinessUnit, @UserId;

         /* Allocate Bulk PT - either Available Qty or Directed Qty as noted by Operation */
         if (@vOperation in ('AllocateAvailableQtyForBulk', 'AllocateDirectedQtyForBulk'))
           exec pr_Allocation_AllocateInventory @vWaveId, @vTransactionScope, @vOperation, @BusinessUnit, @UserId;

         /* If the Wave is not replenished, then generate OnDemand Order
            For a replenish Waves we do not need. */
         if (@vOperation in ('GenerateOnDemandOrders', 'ReplenishDynamicLocations'))
           begin
             /* reset hash table */
             delete from #ReplenishWavesToAllocate;

             if (@vOperation = 'GenerateOnDemandOrders')
               exec pr_Replenish_GenerateOndemandOrders @vWaveNo, @BusinessUnit, @UserId, @ReplenishWaveNo output;
             else
             if (@vOperation = 'ReplenishDynamicLocations')
               exec pr_Replenish_GenerateOrdersForDynamicLocations @vWaveId, @vOperation, @BusinessUnit, @UserId;

             /* Get all the On-Demand waves that needs to be re-allocated */
             insert into @ttWavesToAllocate(WaveId, WaveNo, WaveType, WaveStatus, IsAllocated, InvAllocationModel, Warehouse, AllocPriority)
               select WaveId, WaveNo, WaveType, WaveStatus, IsAllocated, InvAllocationModel, Warehouse, AllocPriority from #ReplenishWavesToAllocate;

             /* If Ondemand Replenish wave is generated then break the loop and allocate replenish wave first and then try to
                allocate original wave so that directed lines will be reserved against original wave */
             if (@@rowcount > 0)
               begin
                 /* Reset RecordId so that it will start allocating form first wave again, if the one is not allocated */
                 set @vRecordId = 0;

                 if (charindex('D', @vDebug) > 0) select * From @ttWavesToAllocate order by AllocPriority, RecordId;

                 /* Update activitylog details */
                 exec pr_ActivityLog_AddOrUpdate 'Wave', @vWaveId, @vWaveNo, 'WaveAllocation',
                                                 @vOperation, Default /* xmldata */, Default /* xmlresult */, Default /* DeviceId */,
                                                 @UserId, @vActivityLogId output;

                 break;
               end
           end

         if (@vOperation = 'ExportDataToSorter')
         --  exec pr_Sorter_InsertWaveDetails @vWaveId, null /* Sorter Name */,
         --                                   @BusinessUnit, @UserId;
           set @vReturnCode = @vReturnCode; -- do nothing

         /* If Cubing is required, then do so */
         if (@vOperation in ('CubeOrderDetails', 'CubeTaskDetails'))
           exec pr_Cubing_Execute @vWaveId, @vTransactionScope, @vOperation, @BusinessUnit, @UserId, @vWarehouse, @vDebug;

         /* Unwave dis-qualified orders */
         if (@vOperation = 'UnWaveDisQualifiedOrders')
           exec pr_Allocation_UnwaveDisQualifiedOrders @vWaveId, @vOperation, @BusinessUnit, @UserId;

         /* Process the task details created which are created earlier */
         if (@vOperation like 'ProcessTaskDetails%')
           exec pr_Allocation_ProcessTaskDetails @vWaveId, @vOperation, @vWarehouse, @BusinessUnit, @UserId;

         /* At appropriate point, create the pick tasks from all the task details created */
         if (@vOperation = 'CreatePickTasks')
           exec pr_Allocation_CreatePickTasks @vWaveId, @vOperation, @vWarehouse, @BusinessUnit, @UserId, @vDebug;

         /* At appropriate point, create the pick tasks from all the task details created */
         if (@vOperation = 'CreatePickTasks_PTS')
           exec pr_Allocation_CreatePickTasks_PTS @vWaveId, @Operation, @vWarehouse, @BusinessUnit, @UserId, @Debug;

         /* At appropriate point, create the pick tasks from all the task details created */
         if (@vOperation = 'CreatePickTasks_New')
           exec pr_Allocation_CreatePickTasks_New @vWaveId, @Operation, @vWarehouse, @BusinessUnit, @UserId, @vDebug;

         /* Generate ship cartons for the customer orders on the wave */
         if (@vOperation = 'GenerateShipCartons')
           exec pr_Allocation_GenerateShipCartons @vWaveId, @vTransactionScope, @vOperation, @BusinessUnit, @UserId, @vDebug;

         /* Generate ship cartons for the customer orders on the wave */
         if (@vOperation = 'GenerateShipCartonsForPrepacks')
           exec pr_Allocation_GenerateShipCartonsForPrepacks @vWaveId, @vTransactionScope, @vOperation, @BusinessUnit, @UserId, @vDebug;

         /* Update Dependencies on Wave & its corresponding Tasks, Task Details */
         if (@vOperation = 'UpdateWaveDependencies')
           exec pr_Allocation_UpdateWaveDependencies @vWaveId, @BusinessUnit, @UserId;

         /* Insert Cartons into ShipLabel table to generate tracking numbers */
         if (@vOperation = 'InsertShipLabels')
           exec pr_Allocation_InsertShipLabels @vWaveId, @vOperation, @BusinessUnit, @UserId;

         if (@vOperation = 'GenerateTempLabels')
           exec pr_Tasks_GenerateTempLabels @vWaveNo, default, null/* TaskId */, @BusinessUnit, @UserId;

         /* Add Print requests for the wave */
         if (@vOperation like 'Print%')
           exec pr_Allocation_AddPrintServiceRequests @vWaveId, @vOperation, @BusinessUnit, @UserId;

           /* We are having too many steps in allocation and so now we are establishing a method to call
              any stored procedure as part of allocation process. If the Operation starts with _ then
              the appropriate stored procedure would be called */
         if (substring(@vOperation, 1, 1) = '_')
           begin
             set @vSQL = 'exec pr_Allocation' + @vOperation + ' ' +
                                                cast(@vWaveId as varchar)  + ', ''' +
                                                @vOperation     + ''', ''' +
                                                @BusinessUnit   + ''', ''' +
                                                @UserId         + ''', ''' +
                                                coalesce(@vDebug, 'N') + '''';

             exec sp_executesql @vSQL;
           end

         if (@vOperation = 'FinalizeWaveAllocation')
           begin
             exec pr_Allocation_FinalizeWave @vWaveId, @vWaveNo, @BusinessUnit, @UserId;

             /* Update temp table so that the wave would not be processsed again */
             update @ttWavesToAllocate set IsAllocated = 'Y' where WaveId = @vWaveId;
           end

         /* insert into activitylog details */
         exec pr_ActivityLog_AddOrUpdate 'Wave', @vWaveId, @vWaveNo, 'WaveAllocation',
                                         @vOperation, Default /* xmldata */, Default /* xmlresult */, Default /* DeviceId */,
                                         @UserId, @vActivityLogId output;

         if (@vTransactionScope = 'EachOperation') and (@vTranCount = 0)
           commit transaction;

       end /* End rule, process next rule */

       if (@@trancount > 0) and (@vTranCount = 0)
         commit transaction;

    end  /* End wave, process next wave */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
  if (@@trancount > 0) and (@vTranCount = 0) rollback transaction;

  select @vErrorMsg = ERROR_MESSAGE();

  /* insert into activitylog details */
  exec pr_ActivityLog_AddOrUpdate 'Wave', @vWaveId, @vWaveNo, 'WaveAllocation',
                                  @vOperation, Default /* xmldata */, @vErrorMsg /* xmlresult */, Default /* DeviceId */,
                                  @UserId, @vActivityLogId output;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateWave */

Go
