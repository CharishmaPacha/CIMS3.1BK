/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/30  VS      pr_Allocation_CreatePickTasks_PTS: Recompute the PickPositions when we reallocate the wave (HA-2521)
  2021/02/16  TK      pr_Allocation_CreatePickTasks_PTS: Do not revert completed or canceled task detail status (CID-1723)
  2020/10/19  TK      pr_Allocation_CreatePickTasks_PTS: Changes to revert task status on On-Hold (HA-1587)
  2020/08/07  VS      pr_Allocation_CreatePickTasks_PTS: #PicksToProcess changed to @PicksToProcess (HA-1137)
  2020/08/05  RBV     pr_Allocation_CreatePickTasks_PTS: Made changes to update the pickzone on the task details (HA-1000)
  2020/08/05  TK      pr_Allocation_CartCubing_FindPositionToAddCarton, pr_Allocation_CreatePickTasks_PTS,
                      pr_Allocation_ProcessTaskDetails & pr_Allocation_AddDetailsToExistingTask:
                        Changes to use CartType that is defined in rules (HA-1137)
                      pr_Allocation_FinalizeTasks: Removed unnecessary code as updating dependices is being
                        done in pr_Allocation_UpdateWaveDependencies (HA-1211)
  2019/12/06  VS      pr_Allocation_CreatePickTasks, pr_Allocation_ProcessPreAllocatedCases: Create LPN Pick for Engraving Orders (CID-1187)
  2019/05/16  MS      pr_Allocation_CreatePickTasks, pr_Allocation_CreatePickTasks_New: Changes to update TaskCategories on Tasks (CID-367)
  2018/09/24  TK      pr_Allocation_CreatePickTasks: Exclude the tasks which are cancelled or completed (S2GCA-298)
  2018/05/08  TK      pr_Allocation_CreatePickTasks: Changes to consolidate task details and add to existing tasks
                      pr_Allocation_AddDetailsToExistingTask: Initial Revision (S2G-493)
  2018/04/26  TK      pr_Allocation_FinalizeWave: Changes to release tasks based upon control variable
                      pr_Allocation_CreatePickTasks: Removed code to release tasks after creation
  2018/04/09  TK      pr_Allocation_CreatePickTasks: Changes to ignore canceled tasks (S2G-568)
  2018/04/04  AY      pr_Allocation_CreatePickTasks: Create Tasks with SubType of U when details are cubed (S2G-569)
  2018/03/20  TD      pr_Allocation_CreatePickTasks, pr_PickBatch_IsValidToAddTaskDetail,
                      pr_Allocation_GetTaskStatistics: Changes to consider num picks while creating tasks (S2G-456)
  2018/03/11  AY/TK   pr_Allocation_CreatePickTasks: Changes to group task details into Tasks
                        in generic way for various wave types
              TK      pr_PickBatch_CreatePickTasks: Removed
  2018/02/20  TK      pr_Allocation_AllocateWave: Added step to update Wave & Task Dependencies
                      pr_Allocation_CreatePickTasks & pr_Allocation_CreateTaskDetails:
                        Changes to update WaveId on Tasks/Task Details (S2G-152)
  2018/02/08  TD      pr_Allocation_CreatePickTasks:Changes to update pickGroup based on the wavetype (S2G-218)
  2017/07/13  PK      pr_Allocation_CreatePickTasks: Bug fix to only consider PickPositions for PickToCart waves.
  2017/01/24  TK      pr_Allocation_CreatePickTasks: Changes to avoid duplicate entries into LPNTasks table (HPI-1261)
  2016/09/18  AY      pr_Allocation_CreatePickTasks: Change employee label logic to consider non-emp items on order (HPI-GoLive)
  2016/09/06  TK      pr_Allocation_CreatePickTasks: Changes made to limit max number of employees per task (HPI-476)
  2016/08/18  AY/TK   pr_Allocation_CreatePickTasks: LPN Picks - consider each LPN as one case
                      pr_Allocation_GetTaskStatistics: Recount Tasks before getting Statistics (HPI-487)
  2016/08/10  AY      pr_Allocation_CreatePickTasks: Update the Picking Position on Task Details
  2016/06/29  TK      pr_Allocation_CreatePickTasks: Changes made to determine Operation (HPI-162)
  2016/06/25  AY      pr_Allocation_CreateTaskDetails: New procedure (HPI-162)
                      pr_Allocation_CreatePickTasks: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_CreatePickTasks') is not null
  drop Procedure pr_Allocation_CreatePickTasks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_CreatePickTasks: This procedure is used to create pick
    tasks when a PickBatch is allocated. It loops thru all the allocated
    LPN and Unit Picks and breaks them up into Tasks considering the MaxVolume
    and MaxWeight for each task.

    If every thing went well then we will define task sub type here based on the innerpacks.
    We have 3 task sub types here. LPNs,Cases and Units.
    LPN Type- If all the LPN qty is allocated for a task then we will treat that as LPN Pick.
      For example we have 5 innerpacks on the LPN and we have allocated 5 innerpacks then we will
      treat that as LPN Task.
    Case Type - If the  Qty on the LPN is not equall to Allcoated Qty in-terms of Cases.
       For example we have 5 innerpacks on the LPN.But we have allocated 4 ot less than 4 Innerpacks.
       then we will treat that as Case Pick.

    Unit Type Pick-  this just like units picks. Less than Innerpacks.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_CreatePickTasks
  (@PickBatchId           TRecordId,
   @Operation             TOperation = null,
   @Warehouse             TWarehouse,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @Debug                 TFlags = 'N')
as
  declare @vRecordId         TRecordId,
          @vSKUId            TRecordId,
          @vLPNId            TRecordId,
          @vTempLPNId        TRecordId,
          @vLPNInnerPacks    TInnerPacks,
          @vLPNDetailId      TRecordId,
          @vOrderDetailId    TRecordId,
          @vOrderId          TRecordId,
          @vPrevOrderId      TRecordId,
          @vLocationId       TRecordId,
          @vLocation         TLocation,
          @vLocationType     TTypeCode,
          @vLocStorageType   TTypeCode,
          @vPickBatchId      TRecordId,
          @vBatchNo          TTaskBatchNo,
          @vBatchType        TTypeCode,
          @vPriority         TPriority,
          @vTaskId           TRecordId,
          @vTaskDetailId     TRecordId,
          @vTaskSubType      TTypeCode,
          @vPickBatchNo      TPickBatchNo,
          @TaskDesc          TDescription,
          @vTaskZone         TZoneId,
          @vPickWeight       TWeight,
          @vPickVolume       TVolume,
          @vWarehouse        TWarehouse,
          @vMaxWeight        TWeight,
          @vMaxVolume        TVolume,
          @vUnitsToAllocate  TQuantity,
          @vInnerPacks       TInnerPacks,
          @vValidToAddDetail TFlag,
          @vTotalWeight      TWeight,
          @vTotalVolume      TVolume,
          @vTotalCases       TInnerPacks,
          @vTotalUnits       TInnerPacks,
          @vTotalCartonVolume TVolume,
          @vTotalOrders      TCount,
          @vCartonVolume     TVolume,
          @vTotalPicks       TCount,
          @vTotalTempLabels  TCount,
          @vPreviousTaskId   TRecordId,
          @vPrevTempLabelId  TRecordId,
          @vPrevTaskZone     TZoneId,
          @vPrevTaskSubType  TTypeCode,
          @vPrevDestZone     TZoneId,
          @vPrevLocationId   TRecordId,
          @vPrevLocationType TTypeCode,
          @vNumPicksCreated  TCount,
          @vDestZone         TZoneId,
          @vOrderType        TTypeCode,
          @vMinCasesPerTask  TCount,
          @vReplLocationId   TRecordId,
          @vReplLocationType TTypeCode,
          @vTempLabelId      TRecordId,
          @TempLabelDetailId TRecordId,
          @vTempLabel        TLPN,
          @vDefaultStatus    TStatus,
          @vTDDestZone       TZoneId,
          @vIsTaskAllocated  TFlags,
          @vIsLabelGenerated TFlags,
          @vMaxTempLabels    TCount,

          @vTDCategory1      TCategory,
          @vTDCategory2      TCategory,
          @vTDCategory3      TCategory,
          @vTDCategory4      TCategory,
          @vTDCategory5      TCategory,
          @vPrevTDCategory1  TCategory,
          @vPrevTDCategory2  TCategory,
          @vTaskStatus       TStatus,
          @vControlCategory  TCategory,
          @vSplitOrder       TControlValue,
          @vOwnership        TOwnership,

          @vPickGroup        TPickGroup,

          @xmlRulesData      TXML,

          @vReleaseTasks     TFlag,
          @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessage;

  declare @ttPicksInfo       TTaskInfoTable,
          @ttPicksToProcess  TTaskInfoTable,
          @ttTaskForLabels   TEntityKeysTable,
          @ttTasksCreated    TEntityKeysTable,
          @ttTasksToRecount  TRecountKeysTable;

  declare @ttUpdatedTaskDetails table (TaskDetailId       TRecordId,
                                       TaskId             TRecordId,
                                       SKUId              TRecordId,
                                       OrderDetailId      TRecordId,
                                       TempLabelId        TRecordId,
                                       TempLabelDetailId  TRecordId,

                                       RecordId           TRecordId identity(1,1));

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select @vValidToAddDetail  = 'N' /* No */,
         @vTotalVolume       = 0,
         @vTotalWeight       = 0,
         @vTotalCases        = 0,
         @vTotalUnits        = 0,
         @vTotalCartonVolume = 0,
         @vTotalPicks        = 0,
         @vTaskId            = 0,
         @vPreviousTaskId    = 0,
         @vPrevTaskSubType   = '',
         @vPrevTempLabelId   = 0,
         @vPrevOrderId       = 0,
         @vNumPicksCreated   = 0,
         @vPrevTDCategory1   = '',
         @vPrevTDCategory2   = '';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get Batch Details */
  select @vPickBatchId     = RecordId,
         @vPickBatchNo     = BatchNo,
         @vBatchType       = BatchType,
         @vControlCategory = 'PickBatch_' + BatchType,
         @vOwnership       = Ownership
  from PickBatches
  where (RecordId = @PickBatchId);

  /* Determine Operation */
  select @Operation = case when exists (select * from TaskDetails where (PickBatchNo = @vPickBatchNo) and
                                                                        (LPNDetailId is not null    ) and
                                                                        (TempLabel is not null      ) and
                                                                        (Status not in ('X', 'C'/* Canceled, Completed */)))
                             then 'AllocationAndCubing'
                           when exists (select * from TaskDetails where (PickBatchNo = @vPickBatchNo) and
                                                                        (LPNDetailId is not null    ) and
                                                                        (Status not in ('X', 'C'/* Canceled, Completed */)))
                             then 'Allocation'
                           when exists (select * from TaskDetails where (PickBatchNo = @vPickBatchNo) and
                                                                        (LPNDetailId is null        ) and
                                                                        (TempLabel is not null      ) and
                                                                        (Status not in ('X', 'C'/* Canceled, Completed */)))
                             then 'PseudoPicks'
                           else null
                      end;

  select @vIsTaskAllocated = case when @Operation = 'PseudoPicks' then 'N'
                                  else 'Y'
                             end;

  /* Get default Task status from controls here */
  select @vTaskStatus      = dbo.fn_Controls_GetAsString (@vControlCategory, 'DefaultTaskStatus', 'O' /* On hold */, @BusinessUnit, null /* UserId */),
         @vMinCasesPerTask = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MinCasesPerTask',   '20',              @BusinessUnit, null /* UserId */),
        -- @vReleaseTasks    = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'AutoReleaseTasks',  'N' /* No */,      @BusinessUnit, null /* UserId */),
         @vSplitOrder      = dbo.fn_Controls_GetAsString (@vControlCategory, 'Task_SplitOrder',   'Y' /* Yes */,     @BusinessUnit, null /* UserId */),
         @vMaxTempLabels   = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'PseudoPick',        '8',               @BusinessUnit, null /* UserId */),
         @vDefaultStatus   = @vTaskStatus;

  /* insert task details which have not been assigned to a task into temp table for processing */
  insert into @ttPicksInfo(TaskId, TaskDetailId, PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
                           LocationId, SKUId, InnerPacks, UnitsToAllocate,
                           DestZone, TempLabelId, TempLabel, PickType,
                           TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
                           TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5)
    select TaskId, TaskDetailId, WaveId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
           LocationId, SKUId,
           /* For an LPN Pick, consider it 1 Case for task thresholds. Each LPN will be one Task Detail  */
           case when PickType = 'L' and InnerPacks = 0 then 1 else InnerPacks end, Quantity,
           DestZone, TempLabelId, TempLabel, PickType,
           TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
           TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5
    from TaskDetails TD
    where (TD.PickBatchNo = @vPickBatchNo) and
          (TD.TaskId = 0) and
          (TD.Status not in ('X'/* Canceled */)) and -- Due to some unexpected errors TDs are created but Tasks are not created, so when cancelled those TDs and tried to reallocate wave it is not allowing to ignore canceled TDs
          (TD.BusinessUnit = @BusinessUnit)
    order by TD.PickType, TD.TDCategory1, TD.TDCategory2, TD.TDCategory3, TD.TDCategory4;

  /* Update the temptable here with the additional info that is required */
  update TI
  set UnitWeight    = S.UnitWeight,
      UnitVolume    = S.UnitVolume,
      TotalWeight   = TI.UnitsToAllocate * S.UnitWeight,
      TotalVolume   = TI.UnitsToAllocate * S.UnitVolume,
      PickPath      = LOC.PickPath,
      PickZone      = LOC.PickingZone,
      LocationType  = LOC.LocationType,
      StorageType   = LOC.StorageType
     -- TaskCategory1 = CT.OuterVolume,
     -- PickType      = PickType
  from @ttPicksInfo  TI
    left outer join SKUs         S   on  (TI.SKUId       = S.SKUId)
  --left outer join LPNDetails   LD  on  (TI.LPNDetailId = LD.LPNDetailId)
    left outer join Locations    LOC on  (TI.LocationId  = LOC.LocationId)
  --left outer join CartonTypes  CT  on  (TI.Cartontype  = CT.CartonType );

  if (charindex('D', @Debug) > 0) select * from @ttPicksInfo;

  /* Invoke procedure to check whether the Task Details can be added to existing Tasks */
  insert into @ttPicksToProcess(TaskDetailId, PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
                                LocationId, SKUId, InnerPacks, UnitsToAllocate, UnitWeight, UnitVolume,
                                TotalWeight, TotalVolume, PickPath, PickZone, LocationType, StorageType,
                                DestZone, TempLabelId, TempLabel, PickType,CartType,
                                TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
                                TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5)
    exec pr_Allocation_AddDetailsToExistingTask @ttPicksInfo, @Operation, @BusinessUnit, @UserId;

  /* Task Detail groups are already setup */
  while (exists (select * from @ttPicksToProcess))
    begin
      /* get the top 1 TaskDetail */
      select top 1 @vRecordId        = RecordId,
                   @vTaskDetailId    = TaskDetailId,
                   @vOrderDetailId   = OrderDetailId,
                   @vOrderId         = OrderId,
                   @vSKUId           = SKUId,
                   @vUnitsToAllocate = UnitsToAllocate,
                   @vLPNId           = LPNId,
                   @vLPNDetailId     = LPNDetailId,
                   @vLocationId      = LocationId,
                   @vTaskZone        = PickZone,
                   @vInnerPacks      = coalesce(InnerPacks, 0),
                   @vPickWeight      = TotalWeight,
                   @vPickVolume      = TotalVolume,
                   @vTaskSubType     = PickType,
                   @vLocationType    = LocationType,
                   @vLocStorageType  = StorageType,
                   @vDestZone        = DestZone,
                   @vOrderType       = OrderType,
                   @vTempLabelId     = TemplabelId,
                   @vTempLabel       = Templabel,
                   @vTDCategory1     = coalesce(TDCategory1, ''),
                   @vTDCategory2     = coalesce(TDCategory2, ''),
                   @vTDCategory3     = coalesce(TDCategory3, ''),
                   @vTDCategory4     = coalesce(TDCategory4, ''),
                   @vTDCategory5     = coalesce(TDCategory5, '')
                  -- @vCartonVolume    = TaskCategory1
      from @ttPicksToProcess
      order by TDCategory1, TDCategory2, TDCategory3, TDCategory4, RecordId;

      /* If we have cubed the tasks, then we consider picking at the task level to be Units only. The
         task details in such cases may be for Cases or Units. For example, for PTL picks at S2G,
         we could have cases and units cubed into the same carton.
         Also, we are calling a diff proc to confirm case picks when temp labels are generated without cubing
         so we don't want cubed case picks to be using that type of confirmation */
      if (@Operation = 'AllocationAndCubing') select @vTaskSubType = 'U';

      if (charindex('D', @Debug) > 0) select 'Processing ', * from @ttPicksToProcess where RecordId = @vRecordId;

      /* Add the metrics of current task detail to the current task to get the totals */
      select @vTotalWeight = (coalesce(@vTotalWeight, 0) + coalesce(@vPickWeight, 0)),
             @vTotalVolume = (coalesce(@vTotalVolume, 0) + coalesce(@vPickVolume, 0) *  0.000578704),
             @vTotalCases  = (coalesce(@vTotalCases, 0)  + coalesce(@vInnerPacks, 0)),
             @vTotalUnits  = (coalesce(@vTotalUnits, 0)  + @vUnitsToAllocate),
             /* If order is not being split across tasks, then the next task detail would be a new order
                as all details of an order would be added up, so count this as one more order */
             @vTotalOrders = (coalesce(@vTotalOrders, 0) + case when @vSplitOrder = 'N' then 1 else 0 end),
             @vTotalPicks  = @vTotalPicks + 1;

      -- /* ??? can we calculate the carton volume and pass in to pr_PickBatch_IsValidToAddTaskDetail,
      --        so that we can easily calculate how many cartons Picking cart can hold */
      -- if (@vTempLabelId is not null) and (charindex(@vTempLabel, @vTaskGroup3) > 0)
      --   begin
      --     /* If there is a temp label id for Unit picks, then we should consider each temp label as one case */
      --     select @vTotalCartonVolume = @vTotalCartonVolume + @vCartonVolume,
      --            @vTotalCases        += case when @vTaskSubType = 'U' then 1 else 0 end;
      --   end

      if (@vPrevTDCategory1 <> @vTDCategory1)
        select @vValidToAddDetail = 'N',
               @vTaskId = 0;
      else
      /* if we do not want to split order then we wil update orderid with pickzone, so taskgroup is always
         different, so we need to consider it only when split order is no */
      if (@vPrevTDCategory2 <> @vTDCategory2) --and (@vSplitOrder = 'Y' /* Yes */)
        select @vValidToAddDetail = 'N',
               @vTaskId = 0;


      /* If TaskGroups of the current task and the processing task detail are the same, then evaluate
         to see if adding this taskdetail (or the cluster of task details i.e. TaskCategory5) would
         push the task over the thresholds */
      if (coalesce(@vTaskId, 0) <> 0)
        begin
          /* If we already have a task, check to see if we can add this pick or (cluster of picks) to it */
          exec pr_PickBatch_IsValidToAddTaskDetail @vPickBatchId, @vTotalWeight, @vTotalVolume, @vTotalCases,
                                                   @vTotalUnits, @vTotalCartonVolume, @vTotalOrders,
                                                   @vTotalPicks, @vTaskSubType,
                                                  -- @vTaskGroup1, @vTaskGroup2, @vTaskGroup5,
                                                   @vValidToAddDetail output;
        end

      /* If the task detail is not a valid to add it to the previous task then we want to add it to
           new task  */
      if (@vValidToAddDetail = 'N' /* No */)
        set @vTaskId = 0;

      /* Create a new task if there is currently not one to be added to */
      if (coalesce(@vTaskId, 0) = 0)
        begin
          exec pr_Tasks_Add 'PB',                    /* PickBatch  */
                            @vTaskSubType,           /* Task Type  */
                            @TaskDesc,
                            @vTaskStatus,            /* Status */
                            0,                       --@DetailCount
                            0,                       --@CompletedCount,
                            @vPickBatchId,
                            @vPickBatchNo,
                            @vTaskZone,              --PickZone
                            null,                    --@PutawayZone
                            @Warehouse,
                            @vPriority,
                            null,                    --scheduleddate
                            @vIsTaskAllocated,
                            @BusinessUnit,
                            @vOwnership,
                            @vTaskId output,
                            @CreatedBy = @UserId;

          /* Restart Total Volume/Weight with the task that is going to be added */
          select @vTotalWeight       = coalesce(@vPickWeight, 0),
                 @vTotalVolume       = (coalesce(@vPickVolume, 0) *  0.000578704),
                 @vTotalCases        = case when @vTaskSubType = 'U' then 1 else coalesce(@vInnerPacks, 0) end,
                 @vTotalCartonVolume = @vCartonVolume,
                 @vTotalUnits        = @vUnitsToAllocate,
                 @vTotalOrders       = 1;
        end

      /* clear temp table */
      delete from @ttUpdatedTaskDetails

      /* If the processing task detail is from a cluster, then add all the task details in that cluster.
         to the current Task. Cluster here could be a temp label or an Order. This is to ensure that
         each cluster of picks always end up on one task only */
      if (@vTDCategory5 <> '')
        update TD
        set TaskId = @vTaskId
        output inserted.TaskDetailId, @vTaskId, inserted.SKUId, inserted.OrderDetailId, inserted.TempLabelId, inserted.TempLabelDetailId
        into @ttUpdatedTaskDetails(TaskDetailId, TaskId, SKUId, OrderDetailId, TempLabelId, TempLabelDetailId)
        from TaskDetails TD join @ttPicksToProcess TI on TD.TaskDetailId = TI.TaskDetailId
        where (TI.TDCategory1 = @vTDCategory1) and (TI.TDCategory2 = @vTDCategory2) and (TI.TDCategory5 = @vTDCategory5);
      else
        update TD
        set TaskId = @vTaskId
        output inserted.TaskDetailId, @vTaskId, inserted.SKUId, inserted.OrderDetailId, inserted.TempLabelId, inserted.TempLabelDetailId
        into @ttUpdatedTaskDetails(TaskDetailId, TaskId, SKUId, OrderDetailId, TempLabelId, TempLabelDetailId)
        from TaskDetails TD join @ttPicksToProcess TI on TD.TaskDetailId = TI.TaskDetailId
        where (TI.TaskDetailId = @vTaskDetailId);

      /* Update TaskId against LPN which would be used further in printing Labels or Packing Lists

         - If it is a cubed Task then update TaskId on TempLabel
         - If it is Task without cubing and PickType is LPN Pick then update TaskId on Allocated LPN */
      if exists (select * from @ttUpdatedTaskDetails where TempLabelId is not null)
        update L
        set TaskId = @vTaskId
        from LPNs L
          join @ttUpdatedTaskDetails UTD on (L.LPNId = UTD.TempLabelId)
        where (UTD.TempLabelId is not null);
      else
        update L
        set TaskId = @vTaskId
        from LPNs L
          join TaskDetails TD on (L.LPNId = TD.TaskId)
          join @ttUpdatedTaskDetails UTD on (TD.TaskDetailId = UTD.TaskDetailId)
        where (L.LPNType not in ('L', 'A'/* LogicalLPN/Cart */)) and
              (TD.PickType = 'L'/* LPN Pick */) and
              (L.Status = 'A'/* Allocated */) and
              (UTD.TempLabelId is null);

      /* if we are generating PseudoPicks then insert created task and corresponding Templabel */
      if (@Operation in ('PseudoPicks', 'AllocationAndCubing'))
        insert into LPNTasks(PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId, LPNDetailId, BusinessUnit)
          select @vPickBatchId, @vPickBatchNo, TaskId, TaskDetailId, TempLabelId, TempLabelDetailId, @BusinessUnit
          from @ttUpdatedTaskDetails;

      /* We need this because we would be adding multiple tasks all at once and so we have to recompute */
      exec pr_Allocation_GetTaskStatistics @vTaskId, 'Y' /* Yes, Recount Task */,
                                           @vTotalWeight output, @vTotalVolume output,
                                           @vTotalCases output,  @vTotalCartonVolume output,
                                           @vTotalUnits output,  @vTotalOrders output,
                                           @vTotalPicks output,  @vTotalTempLabels output;

      /* Get the created tasks into a Temp Table */
      if not exists(select * from @ttTasksCreated where EntityId = @vTaskId)
        insert into @ttTasksCreated(EntityId)
          select @vTaskId;

      /* for each task we need to update the pickgroup */
      if (@vTaskId <> coalesce(@vPreviousTaskId, 0))
        begin
          /* Build the data for evaluation of rules to get pickgroup*/
          select @xmlRulesData = '<RootNode>' +
                                   dbo.fn_XMLNode('WaveType',  @vBatchType)   +
                                   dbo.fn_XMLNode('PickType',  @vTaskSubType) +
                                 '</RootNode>';

          /* Get the valid PickGroup for the task  */
          exec pr_RuleSets_Evaluate 'Task_PickGroup', @xmlRulesData, @vPickGroup output;

          /* Update task pick group here --TD - Need to check performance ...*/
          update Tasks
          set PickGroup = @vPickGroup
          where (TaskId = @vTaskId)
        end

      /* Set previousTaskId to current one */
      select @vPreviousTaskId   = @vTaskId,
             @vPrevTaskSubType  = @vTaskSubType,
             @vTaskStatus       = @vDefaultStatus,
             @vPrevTDCategory1  = @vTDCategory1,
             @vPrevTDCategory2  = @vTDCategory2,
             @vPrevTempLabelId  = @vTempLabelId,
             @vPrevOrderId      = @vOrderId;

      /* delete the task details from temp table which have been assigned a Task */
      delete from @ttPicksToProcess
      where TaskDetailId in (select TaskDetailId from @ttUpdatedTaskDetails);
    end

  /* Recalculate procedure don't allow TEntityKeys temp table type as parameter,
     hence insert distinct tasks into TRecountKeysTable temp table to recalculate the tasks */
  insert into @ttTasksToRecount (EntityId)
    select distinct EntityId
    from @ttTasksCreated;

  /* Update the counts on all the tasks */
  exec pr_Tasks_Recalculate @ttTasksToRecount, 'CS' /* Counts & Status */, @UserId;

  /* Build the rules data */
  select @xmlRulesData = (select @vPickBatchId  as WaveId,
                                 @vBatchNo      as WaveNo,
                                 @vBatchType    as WaveType
                          for xml raw('RootNode'), elements xsinil);

  /* Evaluate Rules & Update task categories */
  exec pr_RuleSets_ExecuteRules 'Task_UpdatePickPositions', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'Task_UpdateCategories', @xmlRulesData;

  /* Moved this code to Allocation_FinalizeWave */
  --/* Realease created tasks based on the control variable */
  --if (@vReleaseTasks = 'Y' /* Yes */)
  --  exec pr_Tasks_Release @ttTasksCreated, null /* TaskId */ , null /* Batch No */, default /* Force Release */,
  --                        @BusinessUnit, @UserId, @vMessage output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_CreatePickTasks */

Go
