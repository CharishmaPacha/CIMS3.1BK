/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/05/12  TD      Added pr_Tasks_GenerateTempLabelsForEcomWave.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_GenerateTempLabelsForEcomWave') is not null
  drop Procedure pr_Tasks_GenerateTempLabelsForEcomWave;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_GenerateTempLabelsForEcomWave: This procedure will only used to
       generate Ecom Waves.

  The objective of this procedure is to take all the tasks that have been created
  for the E-Com wave and for each order decide which tasks are to be packed into
  which temp label.
  for example, if an order has 25 units to be picked - we have to cartonize the
  the order i.e. if all 25 would be packed into 1 carton or if they should be packed
  into multiple cartons and if multiple cartons which SKUs would be packed into
  which carton.

  Cases and InnerPacks are the same and we use them interchangeably
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_GenerateTempLabelsForEcomWave
  (@PickBatchNo    TPickBatchNo = null,
   @Tasks          TEntityKeysTable readonly,
   @TaskId         TRecordId    = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vRecordId           TRecordId,
          @vTaskId             TRecordId,
          @vPrevTaskId         TRecordId,
          @vTaskDetailId       TRecordId,
          @vTaskSubType        TTypeCode,
          @vDestZone           TZoneId,
          @vWarehouse          TWarehouse,
          @vLPNId              TRecordId,
          @vLPNDetailId        TRecordId,
          @vTempLPNId          TRecordId,
          @vTempLPN            TLPN,
          @vPrevBatchNo        TPickBatchNo,
          @vPickType           TTypeCode,
          @vNewTaskId          TRecordId,
          @vNewTaskDetailId    TRecordId,
          @vSplitUnitPickQty   TQuantity,
          @vUPSplitTaskDetailId TRecordId,  --UnitPickSplitTaskDetailId
          @vQtyNeeded           TQuantity,
          @vQtyAvailable        TQuantity,

          @vTaskOrderId        TRecordId,
          @vTaskOrderDetailId  TRecordId,
          @vPrevTaskOrderId    TRecordId,

          @vLPNSeqNo           TLPN,
          @vTDRecordId         TRecordId,
          @vSKUId              TRecordId,
          @vNumCases           TCount,
          @vTaskDetailQty      TQuantity,
          @vQtyPerTempLabel    TQuantity,
          @vCasesPerTempLabel  TQuantity,
          @vTaskCaseQTYToAllocate
                               TQuantity,
          @vTaskUnitQtyToAllocate
                               TQuantity,
          @vOrderRemUnitsToAllocate
                               TQuantity,
          @vProcessedFlag      TFlags,
          @vQtyToAllocate      TQuantity,
          @vOrderId            TRecordId,
          @vOrderDetailId      TRecordId,
          @vQtyToSplit         TQuantity,
          @vOrderType          TTypeCode,
          @vTempLPNDetailId    TRecordId,
          @vPickBatchNo        TPickBatchNo,
          @vPickBatchId        TRecordId,
          @vSplitUnitTask      TFlags,
          @ttLPNTasks          TLPNTasksTable,
          @ttTasks             TEntityKeysTable,
          @ttLabelsToGenerate  TLPNsToGenerate;

  declare @ttTaskDetails table
           (RecordId       TRecordId identity(1, 1),
            BatchNo        TPickBatchNo,
            TaskId         TRecordId,
            TaskDetailId   TRecordId,
            LPNId          TRecordId,
            LPNDetailId    TRecordId,
            SKUId          TRecordId,
            NumCases       TCount,
            Quantity       TQuantity,
            QtyAssigned    TCount default 0,
            QtyRemaining   As Quantity - QtyAssigned,
            OrderId        TRecordId,
            OrderDetailId  TRecordId,
            DestZone       TZoneId,
            Warehouse      TWarehouse,
            PickType       TTypeCode,
            Primary Key    (RecordId));

  declare @ttOrderDetails table
           (OrderDetailId   TRecordId,
            OrderId         TRecordId,
            SKUId           TRecordId,
            UnitsToAllocate TQuantity,
            QtySplit        TQuantity default 0,
            ProcessedFlag   TFlags)

begin /* pr_Tasks_GenerateTempLabels */
  SET NOCOUNT ON;

  /* set default values here */
  select @vPrevBatchNo             = '',
         @vCasesPerTempLabel       = 1,
         @vTaskUnitQtyToAllocate   = 0,
         @vOrderRemUnitsToAllocate = 0,
         @vLPNSeqNo                = 1,
         @vPrevTaskId              = 0,
         @vPrevTaskOrderId         = 0,
         @vSplitUnitTask           = 'N' /* No */;

  /* Based upon caller input TaskId or List of tasks, retrieve the list
    of Tasks that have to be processed i.e. ignoring the ones already
    processed. If a Task has already been processed, IsLabelGenerated would be 'Y' */
  if (coalesce(@TaskId, 0) > 0)
    begin
      insert into @ttTasks (EntityId)
        select distinct TaskId
        from vwPickTasks
        where ((TaskId   = @TaskId             ) and
               (TaskType = 'PB' /* PickBatch */) and
               (IsLabelGenerated = 'N' /* No */) and
               (BusinessUnit = @BusinessUnit)  );
    end
  else
    begin
      insert into @ttTasks (EntityId)
        select distinct TD.TaskId
        from @Tasks TT
        join vwPickTasks TD on (TD.TaskId = TT.Entityid)
        where ((TD.TaskType = 'PB' /* PickBatch */) and
               (TD.IsLabelGenerated = 'N' /* No */) and
               (TD.BusinessUnit = @BusinessUnit   ));
    end

  /* if there are none, then exit */
  if (@@rowcount = 0) return;

  /* Get PickBatchId */
  select @vPickBatchId = RecordId
  from PickBatches
  where (BatchNo      = @vPickBatchNo) and
        (BusinessUnit = @BusinessUnit)

  /* insert all details into temp table to create temp labels
     This is only for LPN Type and Case type picks */     -- why only LPN and Case Pick
  insert into @ttTaskDetails (BatchNo, TaskId, TaskDetailId, LPNId, LPNDetailId,
                              SKUId, NumCases, Quantity, OrderId, OrderDetailId,
                              DestZone, Warehouse, PickType)
    select PT.BatchNo, PT.TaskId, PT.TaskDetailId, PT.LPNId, PT.LPNDetailId, PT.SKUId,
           PT.DetailInnerPacks, PT.DetailQuantity, PT.OrderId, PT.OrderDetailId,
           PT.DestZone, PT.Warehouse, PT.TaskSubType
    from vwPickTasks PT
    join @ttTasks TT on TT.EntityId = PT.TaskId
    where (coalesce(PT.IsLabelGenerated, 'N') = 'N' /* No */) and OrderType = 'B'
    order by PT.SKUId, PT.TaskSubType;

  if (@@rowcount = 0)
    return;

  /* loop through taskdetails and generate a temp table for each one */
  while (exists(select * from @ttTaskDetails where (QtyRemaining > 0)))
    begin
      /* get the top 1 record from the temp table */
      select top 1 @vRecordId          = RecordId,
                   @vTaskId            = TaskId,
                   @vTaskDetailId      = TaskDetailId,
                   @vNumCases          = NumCases,
                   @vTaskDetailQty     = QtyRemaining,
                   @vLPNId             = LPNId,
                   @vLPNDetailId       = LPNDetailId,
                   @vSKUId             = SKUId,
                   @vDestZone          = DestZone,
                   @vWarehouse         = Warehouse,
                   @vTaskOrderId       = OrderId,
                   @vTaskOrderDetailId = OrderDetailId,
                   @vPickBatchNo       = BatchNo,
                   @vQtyPerTempLabel   = case
                                           when NumCases > 0 then (Quantity / NumCases)
                                           else QtyRemaining
                                         end,
                   @vPickType           = PickType
      from @ttTaskDetails
      where (QtyRemaining > 0)
      order by PickType, RecordId; -- what is PickType and why is it ordered here by pick type?

      /* Get Order type */
      select @vOrderType             = OrderType,
             @vTaskCaseQtyToAllocate = @vQtyPerTempLabel
      from OrderHeaders
      where (OrderId = @vTaskOrderId);

      /* insert all the order details for the E-Com orders of this SKU into
         temp table for assignment of the TaskUnits to the individual Order Details */
      delete from @ttOrderDetails;

      insert into @ttOrderDetails(OrderDetailId, OrderId, SKUId, UnitsToAllocate, ProcessedFlag)
        select OrderDetailId, OrderId, SKUId, UnitsToAllocate, 'N'
        from vwOrderDetails
        where (PickbatchNo = @PickBatchNo)   and
              (SKUId       = @vSKUId)        and
              (OrderId     <> @vTaskOrderId) and
              (UnitsToAllocate > 0);

      /* We need to generate temp labels for each case, so we need
        to loop that until all cases done */
      while ((@vNumCases > 0) or ((@vNumCases = 0 /* Unit Pick */) and @vPickType = 'U'))
        begin
         -- if (@vNumCases > 0)
          --  select @vLPNSeqNo += 1;
                -- @vDestZone = @vTaskDestZone;
          if (@vOrderType = 'B' /* Bulk PickTicket */)
            begin
              while (exists (select * from @ttOrderDetails where UnitsToAllocate > 0))
                begin
                  select top 1
                    @vOrderId           = OrderId,
                    @vOrderDetailId     = OrderDetailId,
                    @vQtyNeeded         = UnitsToAllocate,
                    @vProcessedFlag     = ProcessedFlag,
                    @vCasesPerTempLabel = 0
                  from @ttOrderDetails
                  where (UnitsToAllocate > 0)
                  order by ProcessedFlag, UnitsToAllocate desc, OrderDetailId;

                  /* we need to reset the value here ..
                     If the picktype is Unit pick then we will go with the input qty from
                    above. i.e vCaseQTYToAllocate */
                  if ((@vTaskCaseQtyToAllocate > 0) and (@vPickType = 'U'))
                    set @vTaskUnitQtyToAllocate = 0;

                  if (@vTaskCaseQtyToAllocate = 0) and (@vOrderRemUnitsToAllocate > 0)
                    select top 1
                      @vTaskUnitQtyToAllocate = QtyRemaining,
                      @vNewTaskId             = TaskId,
                      @vNewTaskDetailId       = TaskDetailId
                    from @ttTaskDetails
                    where (BatchNo  = @vPickBatchNo) and
                          (SKUId    = @vSKUId) and
                          (PickType = 'U') and
                          (QtyRemaining > 0);

                  /* if both are zero then break the loop */
                  if (@vTaskUnitQtyToAllocate = 0) and (@vTaskCaseQtyToAllocate = 0) and
                     (@vNumCases > 1) and (@vOrderRemUnitsToAllocate > 0)
                    begin
                      /* call procedure here to split task */
                      exec pr_Tasks_SplitTask @vTaskDetailId, 1, @vQtyPerTempLabel,
                                              'RP' /* Replenish pick */, 'Shelving' /* Dest Zone */,
                                              'Ecom-SplitCaseTask', @UserId,
                                              @vNewTaskId output, @vNewTaskDetailId output;

                      /* insert newly created unit type task into temp table */
                      insert into @ttTaskDetails(BatchNo, TaskId, TaskDetailId, LPNId, LPNDetailId,
                                                 SKUId, NumCases, Quantity, OrderId, OrderDetailId,
                                                 DestZone, Warehouse, PickType)
                        select @vPickBatchNo, @vNewTaskId, @vNewTaskDetailId, @vLPNId, @vLPNDetailId,
                               @vSKUId, 0, @vQtyPerTempLabel, @vTaskOrderId, @vTaskOrderDetailId,
                               @vDestZone, @vWarehouse, 'U';

                      /* select here from newly created one */
                      select top 1 @vTaskUnitQtyToAllocate = QtyRemaining
                      from @ttTaskDetails
                      where (TaskDetailId = @vNewTaskDetailId) and
                            (SKUId        = @vSKUId);

                      /* reduce the qty and innerpacks from the original task */
                      update @ttTaskDetails
                      set  NumCases -= 1,
                           Quantity -= @vQtyPerTempLabel
                      where Taskdetailid = @vTaskDetailId;

                      select @vNumCases -= 1;
                    end

                  /* select quantity here from where it is.. i.e from newly created task line or from case qty */
                  if (((@vOrderRemUnitsToAllocate > 0) or (@vQtyNeeded> 0)) and
                      @vTaskUnitQtyToAllocate > 0 and
                      @vTaskCaseQtyToAllocate = 0)
                    begin
                      select @vQtyAvailable = @vTaskUnitQtyToAllocate;
                    end
                  else
                      select @vQtyAvailable = @vTaskCaseQtyToAllocate;

                  /* get min qty to split */
                  select @vQtyToSplit = dbo.fn_MinInt(@vQtyNeeded, @vQtyAvailable);

                  if (@vQtyToSplit = 0)
                    break;

                 -- if (@vTaskCaseQtyToAllocate = 0) and (@vQtyNeeded = 0) and (@vpickType = 'CS')
                  --  select @vLPNSeqNo += 1;

                  /* insert all details into temp table here */
                  insert into @ttLabelsToGenerate(LPNSeqNo, LPNType, SKUId, OrderId, OrderDetailId, PickBatchid, PickBatchNo,
                                                  InnerPacks, Quantity, TaskId, TaskDetailId, OnHandStatus, Status,
                                                  FromLPNId, DestZone)
                    select @vLPNSeqNo, 'C', @vSKUId, @vOrderId, @vOrderDetailId, @vPickBatchId, @vPickBatchNo,
                           @vCasesPerTempLabel, @vQtyToSplit, case when @vNewTaskId is not null then @vNewTaskId else  @vTaskId end,
                           case when @vNewTaskDetailId is not null then @vTaskDetailId else  @vTaskDetailId end,
                           'U' /* Unavailable */, 'F' /* temp label  */, @vLPNId, @vDestZone;

                  /* Update TaskDetails temp table here */
                  update @ttTaskDetails
                  set QtyAssigned = QtyAssigned + @vQtyToSplit
                  where (TaskDetailId = case when @vNewTaskDetailId > 0 then @vNewTaskDetailId else @vTaskDetailId end);

                  /* We will have New TaskDetailId is Greater than 0 that means the picktype is
                    Unit Pick, so we need to split the task at that time */
                  if ((@vNewTaskDetailId > 0) or (@vPickType = 'U'))
                    begin
                      /* Update temp with units  assigned and Quantity with the split qty,
                         becuae we need to create a new task for the remainig qty */
                      update @ttTaskDetails
                      set @vUPSplitTaskDetailId = TaskDetailId,
                          @vSplitUnitPickQty    = Quantity - @vQtyToSplit,
                          Quantity              = @vQtyToSplit,
                          QtyAssigned           = @vQtyToSplit
                      where (TaskDetailId = coalesce(@vNewTaskDetailId, @vTaskDetailId));

                      /* Resret to null, we will generate a new one here */
                      select @vNewTaskDetailId = null;

                      /* if there is any thing to split then we need to create a new
                        Task here */
                      if (@vSplitUnitPickQty > 0)
                        begin
                          /* splet task here with the remainig qty */
                          exec pr_Tasks_SplitTask @vUPSplitTaskDetailId, 1, @vSplitUnitPickQty,
                                                  'U' /* Replenish pick */, 'Shelving' /* Dest Zone */,
                                                  'Ecom-SplitUnitTask', @UserId,
                                                  @vNewTaskId output, @vNewTaskDetailId output;

                          /* insert newly generated task details tep table for next picks  */
                          insert into @ttTaskDetails(BatchNo, TaskId, TaskDetailId, LPNId, LPNDetailId,
                                                     SKUId, NumCases, Quantity, OrderId, OrderDetailId,
                                                     DestZone, Warehouse, PickType)
                            select @vPickBatchNo, @vNewTaskId, @vNewTaskDetailId, @vLPNId, @vLPNDetailId,
                                   @vSKUId, 0, @vSplitUnitPickQty, @vTaskOrderId, @vTaskOrderDetailId,
                                   @vDestZone, @vWarehouse, 'U';
                        end
                    end

                  /* reset values here */
                  select @vNewTaskDetailId = null, @vNewTaskId = null, @vQtyAvailable = 0;

                  /* Update temp table here */
                  update @ttOrderDetails
                  set QtySplit                 += @vQtyToSplit,
                      @vOrderRemUnitsToAllocate = UnitsToAllocate - @vQtyToSplit,
                      UnitsToAllocate           = UnitsToAllocate - @vQtyToSplit,
                      ProcessedFlag             = case
                                                    when UnitsToAllocate = @vQtyToSplit then 'Y'
                                                    else 'I' /* InProgress */
                                                  end
                  where (OrderDetailId = @vOrderDetailId);

                  /* Reduce the Qty taken from the Case */
                  if (@vTaskCaseQtyToAllocate > 0)
                      select @vTaskCaseQtyToAllocate -= @vQtyToSplit,
                             @vQtyNeeded             -= @vQtyToSplit;
                  else
                  /* Reduce the Qty taken from the Uni Pics */
                  if (@vTaskUnitQtyToAllocate > 0 and @vTaskCaseQtyToAllocate = 0)
                      select @vTaskUnitQtyToAllocate -= @vQtyToSplit,
                             @vQtyNeeded             -= @vQtyToSplit;

                  if (@vTaskCaseQtyToAllocate = 0) and (@vQtyNeeded = 0) and
                     (@vpickType = 'CS') and (@vTaskUnitQtyToAllocate = 0)
                    begin
                      select @vLPNSeqNo += 1;
                      break;
                    end
                end
            end
          else
            begin
              /* loop thru until we generate all the temp labels for the no of cases */
              select @vLPNSeqNo += 1;

              insert into @ttLabelsToGenerate(LPNSeqNo, LPNType, SKUId, OrderId, OrderDetailId, PickBatchid, PickBatchNo,
                                              InnerPacks, Quantity, TaskId, TaskDetailId, OnHandStatus, Status, FromLPNId, DestZone)
                 select @vLPNSeqNo, 'C', @vSKUId, @vOrderId, @vOrderDetailId, @vPickBatchId, @vPickBatchNo,
                        @vCasesPerTempLabel, @vQtyPerTempLabel, @vTaskId, @vTaskDetailId,
                        'U' /* Unavailable */, 'F' /* temp label  */, @vLPNId, @vDestZone;
            end

          /* unassign the variables */
          select @vTempLPNDetailId  = null,         @vTempLPNId = null,
                 @vTempLPN = null,                  @vTaskCaseQTYToAllocate = @vQtyPerTempLabel,
                 @vPrevTaskOrderId = @vTaskOrderId, @vNumCases  -= 1; /* Need to decrement by 1 each time */
        end

      /* delete the record from the temp table once after it is processed */
      delete from @ttTaskDetails where RecordId = @vRecordId;

      /* unassign the variables */
      select @vPrevTaskId = @vTaskId,  @vLPNDetailId   = null,          @vLPNId   = null,
             @vOrderId    = null,      @vOrderDetailId = null,          @vSKUId   = null,
             @vDestZone   = null,      @vPrevbatchNo   = @vPickBatchNo, @vTaskId  = null;

      /* Update Order details here */
      update OD
      set UnitsAssigned = OD.UnitsAssigned + TOD.QtySplit
      from OrderDetails OD
      join @ttOrderDetails TOD on TOD.OrderDetailId = OD.OrderDetailId;

    end

   /* call procedure here to create lpns -temp labels */
    exec pr_LPNs_CreateTempLabels @ttLabelsToGenerate, 'EcomLabelCreation', @vWarehouse, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_GenerateTempLabelsForEcomWave */

Go
