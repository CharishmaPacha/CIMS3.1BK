/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/21  VM/AY   pr_PickBatch_GenerateBatches: Set BatchingLevel based on requested Entity (OB2-1805)
  2020/10/20  TK      pr_PickBatch_GenerateBatches: Release waves based upon the status selected while wave generation (HA-951)
  2020/09/19  MS      pr_PickBatch_GenerateBatches: Made changes to display success message with detailed info
  2020/06/09  VS      pr_PickBatch_GenerateBatches: Show the Info and Error message when wave is created with Released status (HA-671)
  2020/06/06  AY      Removed code to create BPT on Wave Release
                      pr_PickBatch_GenerateBatches: Generate the batches and commit and then Release as release can fail (HA-671)
  2020/06/05  VS      pr_PickBatch_GenerateBatches, pr_Wave_ReleaseForAllocation: When wave is create with Released Status validate the Wave (HA-671)
  2020/05/27  VS      pr_PickBatch_ReleaseBatches, pr_PickBatch_GenerateBatches, pr_Wave_ReleaseForAllocation: Need to InventoryAllocationModel When we create wave with Released status (HA-668)
              TK      pr_PickBatch_GenerateBatches: MarkersAdd -> Markers_Log
                      pr_PickBatch_Modify: For V3 'ReleaseForAllocation' -> 'Waves_ReleaseForAllocation' (HA-608)
  2020/05/15  VS      pr_PickBatch_GenerateBatches:Fixed the issue in wave generation while selecting multiple Orders(HA-559)
  2018/05/30  SV/VM   pr_PickBatch_GenerateBatches: Included logic to handle combination of BatchingLevel-EnforceBatchingLevel as OD-OH (S2G-891)
  2018/04/30  TK      pr_PickBatch_GenerateBatches & pr_PickBatch_AddOrders: Added transactions (S2G-730)
  2018/03/06  RT      pr_PickBatch_SetUpWaveToReleaseToWSS: Setup Wave to Release to WSS by evaluating the Wave based on UDF1
                      pr_PickBatch_GenerateBatches: Updating UDF2 based on the UpdateWaveInfo Rule(S2G-242)
  2017/07/28  RV      pr_PickBatch_GenerateBatches, pr_PickBatch_ReleaseBatches: BusinessUnit and UserId passed to activity log procedure
  2017/07/07  RV      pr_PickBatch_GenerateBatches, pr_ActivityLog_AddMessage: Procedure id is passed to logging procedure to
  2016/12/21  MV      pr_PickBatch_GenerateBatches: Return the result as a message (HPI-644)
  2016/07/13  TK      pr_PickBatch_GenerateBatches: Consider sort seq of Waving rules
  2016/01/25  TD      pr_PickBatch_GenerateBatches:Changes to consider Ownership while generating waves.
  2015/10/21  TK      pr_PickBatch_GenerateBatches: Bug fix, Start Batch Id must be '0', it cannot be null(ACME-376)
  2103/10/18  TD      pr_PickBatch_GenerateBatches:Bug fix: based on the  Batching Level.
  2103/10/16  TD      pr_PickBatch_GenerateBatches: changes to generate batches based on the system rules.
  2013/09/24  TD      pr_PickBatch_GenerateBatches: Changes about to batch OrderDetails based on the Orders.
  2013/09/17  TD      pr_PickBatch_AutoGenerateBatches, pr_PickBatch_GenerateBatches, pr_PickBatch_AddOrder,
  2013/04/06  TD      pr_PickBatch_GenerateBatches:Bug Fix. Sending 0 values instead of null for volume and weight.
  pr_PickBatch_AutoGenerateBatches, pr_PickBatch_GenerateBatches: Changes related to consider the
  2013/02/06  YA      pr_PickBatch_GenerateBatches: Modified fetch the AddToPriorBatch value from Controls, and modified
  2012/07/10  NY      pr_PickBatch_GenerateBatches: Passing Warehouse while creating Pick Batches.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_GenerateBatches') is not null
  drop Procedure pr_PickBatch_GenerateBatches;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_GenerateBatches:
  Using the rules and the list of Orders to be batched, generate the batches.

  AddToPriorBatches - When 'Y' the given orders could be added to batches
                      created earlier as well. If 'N' then all the given orders
                      would be added to new batches only.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_GenerateBatches
  (@BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @Rules             TXML,
   @Orders            TXML,
   @AddToPriorBatches TFlag,
   @Message           TDescription = null output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vRuleCount               TCount,
          @vCurrentRule             TRecordId,
          @vRuleId                  TRecordId,
          @vWaveRuleGroup           TDescription,
          @vOrderType               TTypeCode,
          @vOrderPriority           TPriority,
          @vShipVia                 TShipVia,
          @vSoldToId                TCustomerId,
          @vShipToId                TShipToId,
          @vPickZone                TZoneId,
          @vBatchType               TTypeCode,
          @vBatchPriority           TPriority,
          @vBatchStatus             TStatus,
          @vPickBatchGroup          TWaveGroup,
          @vMaxOrdersPerBatch       TCount,
          @vMaxLinesPerBatch        TCount,
          @vMaxSKUsPerBatch         TCount,
          @vMaxUnitsPerBatch        TCount,
          @vMaxWeightPerBatch       TCount,
          @vMaxVolumePerBatch       TCount,
          @vMaxLPNs                 TCount,
          @vMaxInnerPacks           TCount,
          @vBatchesUpdated          TCount,
          @vOrderId                 TRecordId,
          @vOrderDetailId           TRecordId,
          @vPickTicket              TPickTicket,
          @vLines                   TCount,
          @vUnitsOrdered            TCount,
          @vSKUs                    TCount,
          @vOrderCount              TCount,
          @vCurrentRecord           TRecordId,
          @vOrdersProcess           TInteger,
          @vCurrentBatchId          TRecordId,
          @vCurrentBatchNo          TPickBatchNo,
          @vNumOrdersOnBatch        TCount,
          @vNumLinesOnBatch         TCount,
          @vNumSKUsOnBatch          TCount,
          @vNumUnitsOnBatch         TCount,
          @vNumLinesOnOrder         TCount,
          @vNumSKUsOnOrder          TCount,
          @vNumUnitsOnOrder         TCount,
          @vNumLPNsOnOrder          TCount,
          @vNumCasesOnOrder         TCount,
          @vOrderWeight             TWeight,
          @vOrderVolume             TVolume,
          @vOrders                  XML,
          @vxmlElement              TName,
          @vStartBatchId            TRecordId,
          @vWarehouse               TWarehouse,
          @vOwnership               TOwnership,
          @vBatchingLevel           TControlValue,
          @vEnforceBatchingLevel    TControlValue,
          @vPickBatchDetailId       TRecordId,
          @vFirstWave               TWaveNo,
          @vLastWave                TWaveNo,
          @vTotalWaves              TCount,
          @vDebug                   TFlags = 'N',
          @vActivityLogId           TRecordId,
          @vWaveWCSDependencyFlags  TFlags,
          @xmlRulesData             TXML;

  declare @ttSelectedOrdersToWave   TEntityKeysTable,
          @ttBatchingRules          TPickBatchRules,
          @ttMarkers                TMarkers;

  declare @ttOrdersToBatch Table
          (OrderId             TRecordId,
           OrderDetailId       TRecordId,
           PickTicket          TPickTicket,
           PickZone            TZoneId,
           Status              TStatus,
           Priority            TPriority,
           Lines               TCount,
           SKUs                TCount,
           Units               TCount,
           OrderWeight         TWeight,
           OrderVolume         TVolume,
           OrderLPNs           TCount,
           OrderCases          TCount,
           Warehouse           TWarehouse,
           Ownership           TOwnership,
           PickBatchGroup      TWaveGroup,
           RecordId            TRecordId identity (1,1));

  declare @ttWavesCreated Table
          (RecordId       TRecordId identity (1,1),
           WaveId         TRecordId,
           WaveNo         TWaveNo,
           WavePriority   TPriority,
           WaveStatus     TStatus);

  /* Temp table to store OrderId/OrderDetailId to handle the logic.in some cases */
  declare @ttOrdersOrDetails TEntityKeysTable;

  declare @ttWavesToRelease  TEntityKeysTable;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Create hash tables */
  if object_id('tempdb..#WavesCreated') is null  select * into #WavesCreated from @ttWavesCreated;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'PickBatches_Generation_Start';

  if (charindex('L' /* Log */, @vDebug) > 0)
    begin
      if (@Rules is not null)
        exec pr_ActivityLog_AddMessage 'WaveGenerationRules', null, null, 'Wave', 'Rules' /* Message */, @@ProcId, @Rules /* xmlData */, @BusinessUnit, @UserId;

      exec pr_ActivityLog_AddMessage 'WaveGeneration', null, null, 'Wave', 'Orders' /* Message */, @@ProcId, @Orders /* xmlData */, @BusinessUnit, @UserId, @ActivityLogId = @vActivityLogId output;
    end

  /* Fetch the control variable to create based on the Orderheader level or detail level */
  select @vBatchingLevel        = dbo.fn_Controls_GetAsString('GenerateBatches', 'BatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */),
         @vEnforceBatchingLevel = dbo.fn_Controls_GetAsString('GenerateBatches', 'EnforceBatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */);

  /* if user does not provide any option then we need to get the value from controls */
  if (coalesce(@AddToPriorBatches, 'D') = 'D' /* Default */)
    begin
      /* Fetch the control variable to add orders to the same batch or not */
      select @AddToPriorBatches = dbo.fn_Controls_GetAsBoolean('AutoGenerateBatches', 'AddOrdersToPriorBatches', 'N' /* No */, @BusinessUnit, null /* UserId */);
    end

  /* convert Orders xml data from varchar datatype to xml data type */
  select @vOrders  = convert(xml, @Orders);
  /* If the Batching Level Is OD and user sends OrderHeader level XML then we need to reset batching Level to OH */
  select @vxmlElement = cast(@vOrders.query('local-name((/Orders/*)[1])') as varchar);

  /* if the the xml element is OrderHeader and batching level is OD the nwe need to set it back to OH */
  if ((@vxmlElement = 'OrderHeader') and (@vBatchingLevel = 'OD' /* Order Detail */))
    set @vBatchingLevel = 'OH' /* Order Header */;

   /* If the batching level is Order Header level and Enforcing is to batch based on the Detail Level then we need to send details only */
  if (@Orders is null)
    begin
      /* The user can select Order Headers or Order Details to Wave, so determine what the user selected based upon the EntityType */
      select top 1 @vBatchingLevel = case when EntityType in ('OrderDetail') then 'OD' else 'OH' end
      from #ttSelectedEntities;

      insert into @ttSelectedOrdersToWave(EntityId)
        select EntityId from #ttSelectedEntities;
    end;
  else
  /* VM_20210521: For v3 model all of above is not necessary as we always send orders in #ttSelectedEntities.
       As OB uses OD BatchingLevel (from controlvar) and below is not executed,
       it will not work in v3 unless BatchingLevel is set to OH.
       So, we introduced to update BatchingLevel to OH further below these conditions

       Later we need to design on using OrderDetails page in Manage Waves page and generate batches */
  if ((@vBatchingLevel = 'OH') and (@vEnforceBatchingLevel = 'OD' /* Order Details */))
    begin
      insert into @ttOrdersOrDetails(EntityId)
        select Record.Col.value('(OrderId/text())[1]', 'TRecordId')
        from @vOrders.nodes('/Orders/OrderHeader') as Record(Col)
        OPTION ( OPTIMIZE FOR ( @vOrders = null ) );

      /* Insert  OrderDetails for the selected Orders into temp table */
      insert into @ttSelectedOrdersToWave(EntityId)
        select OD.OrderDetailId
        from @ttOrdersOrDetails OH
        join vwOrderDetailsToBatch OD on (OH.EntityId = OD.OrderId);

        /*  setting batching level here back to Order Detail */
        select @vBatchingLevel = 'OD' /* Order Details*/;
    end
  else
  /* If the batching level is OH and enforce would could be empty or OH if above condition failed. Then send Orders. */
  if (@vBatchingLevel = 'OH')
    begin
      insert into @ttSelectedOrdersToWave(EntityId)
        select Record.Col.value('(OrderId/text())[1]', 'TRecordId')
        from @vOrders.nodes('/Orders/OrderHeader') as Record(Col)
        OPTION ( OPTIMIZE FOR ( @vOrders = null ) );
    end
  else
  /* If the batching level is Order Detail level and Enforcing is Header Level then get find Orders for the given details */
  if ((@vBatchingLevel = 'OD') and (@vEnforceBatchingLevel = 'OH' /* Order Details */))
    begin
      insert into @ttOrdersOrDetails(EntityId)
        select Record.Col.value('(OrderDetailId/text())[1]', 'TRecordId')
        from @vOrders.nodes('/Orders/OrderDetails') as Record(Col)
        OPTION (OPTIMIZE FOR (@vOrders = null));

      insert into @ttSelectedOrdersToWave(EntityId)
        select distinct OD.OrderId
        from @ttOrdersOrDetails TOD
        join OrderDetails OD on (OD.OrderDetailId = TOD.EntityId);

        /*  Setting batching level to Order Header to send Orders for the given details */
        select @vBatchingLevel = 'OH' /* OrderHeaders */;
    end
  else
    begin
      insert into @ttSelectedOrdersToWave(EntityId)
        select Record.Col.value('(OrderDetailId/text())[1]', 'TRecordId')
        from @vOrders.nodes('/Orders/OrderDetails') as Record(Col)
        OPTION ( OPTIMIZE FOR ( @vOrders = null ) );
    end

  /* Points for developing procedure
     1. Create a temptable for batching rules
     2. Insert the records which has status active into temp table from vwBatchingRules
     3. Loop through each rule and process each rule
        1. select Orders and process each order
        2. Check Batch, if batch is null then create a new batch
        3. Add Order to Batch
  */

  /* Get all active batching rules to process - sorting by SortSeq is important
     as the rules have to be processed in the particular sequence only */
  /* Note: If you add any other new fields to this table please follow the same order in function and here.
     Because we simply write a select statement here, if you do not follow then you should do nightout for support. */
  /* Used Markers to trace out the execution time. */

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_PickBatches_GetBatchingRules';

  insert into @ttBatchingRules
    select *
    from dbo.fn_PickBatches_GetBatchingRules(@Rules, @BusinessUnit)
    order by SortSeqNo;

  select @vRuleCount    = @@rowcount,
         @vCurrentRule  = 1,
         @vStartBatchId = 0;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'End_PickBatches_GetBatchingRules';

  ---Loop through all rules---
  while (@vCurrentRule <= @vRuleCount)
    begin
      select @vRuleId            = RuleId,
             @vWaveRuleGroup     = WaveRuleGroup,
             @vBatchingLevel     = coalesce(BatchingLevel, @vBatchingLevel),
             @vBatchType         = BatchType,
             @vMaxOrdersPerBatch = MaxOrders,
             @vMaxLinesPerBatch  = MaxLines,
             @vMaxSKUsPerBatch   = MaxSKUs,
             @vMaxUnitsPerBatch  = MaxUnits,
             @vMaxWeightPerBatch = MaxWeight,
             @vMaxVolumePerBatch = MaxVolume,
             @vMaxLPNs           = MaxLPNs,
             @vMaxInnerPacks     = MaxInnerPacks,
             @vBatchPriority     = BatchPriority,
             @vBatchStatus       = BatchStatus
      from @ttBatchingRules
      where (RecordId = @vCurrentRule);

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Processing Rule '+cast(@vRuleId as varchar);

      /* Fetch all the orders that need to be batched as per the rule being processed */
      if (@vBatchingLevel = 'OH' /* OrderHeaders */)
        begin
          insert into @ttOrdersToBatch
            select * from dbo.fn_PickBatches_GetOrdersToBatch(@ttSelectedOrdersToWave, @ttBatchingRules, @vCurrentRule, @BusinessUnit);
        end
      else
        begin /* if batching level is */
          insert into @ttOrdersToBatch
            select * from dbo.fn_PickBatches_GetOrderDetailsToBatch(@ttSelectedOrdersToWave, @ttBatchingRules, @vCurrentRule, @BusinessUnit);
        end

      select @vOrderCount    = @@rowcount,
             @vOrdersProcess = 1;

     if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Processing Orders '+cast(@vOrderCount as varchar);

        -- Loop through all orders --
        while (@vOrdersProcess <= @vOrderCount)
          begin
            /* select next order/orderdetail to add to batch from temp table */
            select Top 1 @vCurrentRecord     = RecordId,
                         @vOrderId           = OrderId,
                         @vOrderDetailId     = OrderDetailId,
                         @vPickTicket        = PickTicket,
                         @vNumLinesOnOrder   = Lines,
                         @vNumSKUsOnOrder    = SKUs,
                         @vNumUnitsOnOrder   = Units,
                         @vOrderWeight       = coalesce(OrderWeight, 0.0),
                         @vOrderVolume       = coalesce(OrderVolume, 0.0),
                         @vPickZone          = PickZone,
                         @vCurrentBatchId    = null,
                         @vCurrentBatchNo    = null,
                         @vOrderPriority     = Priority,
                         @vWarehouse         = Warehouse,
                         @vOwnership         = Ownership,
                         @vPickBatchGroup    = PickBatchGroup,
                         @vNumLPNsOnOrder    = coalesce(OrderLPNs, 0),
                         @vNumCasesOnOrder   = coalesce(OrderCases, 0)
            from @ttOrdersToBatch
            order by RecordId;

            if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Starting Order '+ coalesce(cast(@vOrderId as varchar(10)), '');

            if (charindex('D' /* Display */, @vDebug) > 0)
              begin
                select 'Waves to consider', * from PickBatches where ((@AddToPriorBatches = 'Y') or
                      (@vStartBatchId > 0 and (RecordId >= @vStartBatchId))) and
                     (Archived = 'N');
                select @vMaxOrdersPerBatch, @vMaxLinesPerbatch, @vMaxUnitsPerBatch, @vMaxInnerPacks, @vMaxWeightPerBatch, @vMaxVolumePerBatch;
                select @vOrderId 'Order', @vNumLinesOnOrder OrderLines, @vNumSKUsOnOrder OrderSKUs, @vNumUnitsOnOrder OrderUnits, @vNumCasesOnOrder OrderCases, @vNumLPNsOnOrder OrderLPNs,
                       @vPickBatchGroup PBGroup, @vWaveRuleGroup WaveRuleGroup,
                       @AddToPriorBatches AddToPriorBatches, @vStartBatchId StartBatch;
              end

            /* Find a batch to add the order/orderdetail. If 'AddToPriorBatches is 'N' then
               we have to find a batch that has been created in this run only */
            select top 1 @vCurrentBatchId = RecordId,
                         @vCurrentBatchNo = BatchNo
            from PickBatches
            where (Warehouse = @vWarehouse) and
                  (coalesce(Ownership, '') = coalesce(@vOwnership, Ownership, '')) and
                  (coalesce(PickBatchGroup, '') = coalesce(@vPickBatchGroup, '')) and
                  --(RuleId    = @vRuleId) and
                  (WaveRuleGroup = coalesce(@vWaveRuleGroup, WaveRuleGroup)) and
                  (NumOrders < @vMaxOrdersPerBatch) and
                  ((NumLines + @vNumLinesOnOrder) <= @vMaxLinesPerBatch) and
                  ((NumSKUs  + @vNumSKUsOnOrder)  <= @vMaxSKUsPerBatch)  and
                  ((NumUnits + @vNumUnitsOnOrder) <= @vMaxUnitsPerBatch) and
                  --((NumLPNs  + @vNumLPNsOnOrder) <= @vMaxLPNs) and
                  ((NumInnerPacks  + @vNumCasesOnOrder) <= @vMaxInnerPacks) and
                  ((TotalWeight + @vOrderWeight   <= @vMaxWeightPerBatch)) and
                  ((TotalVolume + @vOrderVolume   <= @vMaxVolumePerBatch)) and
                  (Status = 'N' /* New */) and
                  ((@AddToPriorBatches = 'Y') or
                   (@vStartBatchId > 0 and (RecordId >= @vStartBatchId)));

            if (charindex('D' /* Display */, @vDebug) > 0) select @vCurrentBatchId 'BatchId', @vCurrentBatchNo 'BatchNo';
            if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Found Batch '+coalesce(@vCurrentBatchNo, '');

            /* If no Batch is found above, then create a new batch */
            if (@vCurrentBatchNo is null)
              exec pr_PickBatch_CreateBatch @vBatchType,
                                            @vRuleId,
                                            @BusinessUnit,
                                            @UserId,
                                            @vCurrentBatchNo output,
                                            @vCurrentBatchId output;

            if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'PickBatch_AddOrder_Start';

            /* Add Order to batch, Update batch Status, Order Status etc. */
            exec pr_PickBatch_AddOrder @vCurrentBatchId, @vCurrentBatchNo, @vOrderId, @vOrderDetailId, @vBatchingLevel,
                                        Default /* Update Counts */, @vPickBatchGroup, @UserId;

            /* Inserting BatchNo into Temp table to update status in PickBatches */
            insert into #WavesCreated
              select @vCurrentBatchId, @vCurrentBatchNo, @vBatchPriority, @vBatchStatus;

            /* delete the processed order from temp table */
            delete from @ttOrdersToBatch where RecordId = @vCurrentRecord;

            /* Prepare to process next order */
            select @vOrdersProcess = @vOrdersProcess + 1,
                   @vStartBatchId  = coalesce(nullif(@vStartBatchId, 0), @vCurrentBatchId)
          end

      /* Prepare to process next rule */
      select @vCurrentRule = @vCurrentRule + 1;
    end

  /* Build the data for evaluation of rules to get Wave release dependency flags to export data to WSS */
  select @xmlRulesData = '<RootNode>' +
                            dbo.fn_XMLNode('BatchType',  @vBatchType) +
                            dbo.fn_XMLNode('Operation',  'WaveGeneration') +
                         '</RootNode>';

  /* Get the valid UDF2 for the task  */
  exec pr_RuleSets_Evaluate 'SetWCSDependency', @xmlRulesData, @vWaveWCSDependencyFlags output;

  /* Update the status of the batches and their priority */
  update PB
  set PB.Status        = coalesce(WC.WaveStatus, PB.Status),
      PB.Priority      = coalesce(WC.WavePriority, Priority),
      PB.WCSDependency = coalesce(@vWaveWCSDependencyFlags, WCSDependency)
  from PickBatches as PB join #WavesCreated WC on (PB.BatchNo = WC.WaveNo);

  /* Get the first and last wave */
  select @vFirstWave  = (select top 1 WaveNo from #WavesCreated order by RecordId),
         @vLastwave   = (select top 1 WaveNo from #WavesCreated order by RecordId desc),
         @vTotalWaves = (select count(distinct WaveNo) from #WavesCreated);

  if (@vTotalWaves > 1)
    exec @Message = dbo.fn_Messages_Build 'WavesCreatedSuccessfully', @vTotalWaves, @vFirstWave, @vLastWave;
  else
  if (@vTotalWaves = 1)
    exec @Message = dbo.fn_Messages_Build 'WaveCreatedSuccessfully', @vTotalWaves, @vFirstWave, @vLastWave;
  else
    exec @Message = dbo.fn_Messages_Build 'WavesNotCreated';

  if (charindex('D' /* Display */, @vDebug) > 0) select 'Waves Created', * from #WavesCreated;

  /* Commit the waves that are generated, Releasing of them is not dependendent upon generating them */
  commit transaction;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'PickBatch_ReleaseBatches_Prepare';

  /* Waves generated with New Status while Auto Waving */
  /* WaveStatus in the #WavesCreated table would be the status that is selected by user while generating waves via custom rules or
     it will be specified in the waving rules.
     So while generating waves via custom rules or via rules definied, if status is select as 'Released' then release them */
  insert into @ttWavesToRelease (EntityId, EntityKey)
    select distinct WaveId, WaveNo
    from #WavesCreated
    where (WaveStatus in ('E' /* Released */));

  if (@@rowcount > 0)
    exec pr_Wave_ReleaseForAllocation @ttWavesToRelease, null, @UserId, @BusinessUnit, @BatchesUpdated = @vBatchesUpdated output;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'PickBatches_Generation_End';

  if (charindex('M', @vDebug) > 0)
    exec pr_Markers_Log @ttMarkers, 'PickBatch', @vCurrentBatchId, @vCurrentBatchNo, 'PickBatch_GenerateBatches', @@ProcId, 'Markers_PickBatch_GenerateBatches';

  /* Log at end to capture total time taken */
  if (charindex('L', @vDebug) > 0) exec pr_ActivityLog_AddMessage 'WaveGeneration', null, null, 'Wave', 'Orders' /* Message */, @@ProcId, @ActivityLogId = @vActivityLogId;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;

end catch;

end /* pr_PickBatch_GenerateBatches */

Go
