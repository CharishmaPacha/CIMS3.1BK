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
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_CreatePickTasks_PTS') is not null
  drop Procedure pr_Allocation_CreatePickTasks_PTS;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_CreatePickTasks_PTS: This proc cubes picks on to cart and creates pick tasks

  Loops thru all templabels and assigns them to positions on Cart based upon the csrt dims defined,
  when the cart if and doesn't hold any templabel then it creates new task and cubes remaining picks on to cart
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_CreatePickTasks_PTS
  (@WaveId                TRecordId,
   @Operation             TOperation = null,
   @Warehouse             TWarehouse,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @Debug                 TFlags = 'N')
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessage,

          @vRecordId         TRecordId,

          @vWaveId           TRecordId,
          @vWaveNo           TWaveNo,
          @vWaveType         TTypeCode,
          @vOwnership        TOwnership,

          @vTaskId           TRecordId,
          @vTaskSubType      TTypeCode,
          @vTaskDesc         TDescription,
          @vTaskStatus       TStatus,
          @vTaskZone         TZoneId,
          @vPriority         TPriority,

          @vCartonType       TCartonType,
          @vCartonWidth      TWidth,
          @vCartonHeight     THeight,

          @vCartType         TTypeCode,
          @vShelf            TLevel,

          @vControlCategory  TCategory,
          @vDefaultStatus    TStatus,
          @vIsTaskAllocated  TFlags,
          @vIsLabelGenerated TFlags,

          @vTDCategory1      TCategory,
          @vTDCategory2      TCategory,
          @vTDCategory3      TCategory,
          @vTDCategory4      TCategory,
          @vTDCategory5      TCategory;

  declare @ttPicksInfo       TTaskInfoTable,
          @ttPicksToProcess  TTaskInfoTable,
          @ttTasksToFinalize TRecountKeysTable,
          @ttCartShelves     TCartShelves;

  declare @ttUpdatedTaskDetails table (TaskDetailId       TRecordId,
                                       TaskId             TRecordId,
                                       SKUId              TRecordId,
                                       OrderDetailId      TRecordId,
                                       TempLabelId        TRecordId,
                                       TempLabelDetailId  TRecordId,

                                       RecordId           TRecordId identity(1,1),
                                       Primary Key        (RecordId),
                                       Unique             (TaskDetailId, RecordId),
                                       Unique             (TempLabelId, RecordId));

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get Wave Info */
  select @vWaveId          = RecordId,
         @vWaveNo          = BatchNo,
         @vWaveType        = BatchType,
         @vControlCategory = 'Wave_' + BatchType,
         @vOwnership       = Ownership
  from Waves
  where (RecordId = @WaveId);

  /* Create temp table for processing */
  select * into #CartShelves from @ttCartShelves;
  /* while creating hash tables constraints won't be created so drop the columns for which constraints
     are required and re create them */
  alter table #CartShelves drop column UsedWidth, AvailableWidth;
  alter table #CartShelves add  UsedWidth         integer  Default 0,
                                AvailableWidth    As ShelfWidth - UsedWidth;

  /* Determine Operation ... $$ To do.. move to rules */
  select @Operation = case when exists (select * from TaskDetails where (WaveId = @vWaveId) and
                                                                        (LPNDetailId is not null    ) and
                                                                        (TempLabel is not null      ) and
                                                                        (Status not in ('X', 'C'/* Canceled, Completed */)))
                             then 'AllocationAndCubing'
                           when exists (select * from TaskDetails where (WaveId = @vWaveId) and
                                                                        (LPNDetailId is not null) and
                                                                        (TempLabel is null) and
                                                                        (Status not in ('X', 'C'/* Canceled, Completed */)))
                             then 'Allocation'
                           when exists (select * from TaskDetails where (WaveId = @vWaveId) and
                                                                        (LPNDetailId is null) and
                                                                        (TempLabel is not null) and
                                                                        (Status not in ('X', 'C'/* Canceled, Completed */)))
                             then 'PseudoPicks'
                           else null
                      end;

  select @vIsTaskAllocated = case when @Operation = 'PseudoPicks' then 'N'
                                  else 'Y'
                             end;

  /* Get default Task status from controls here $$ Use rules */
  select @vTaskStatus = dbo.fn_Controls_GetAsString (@vControlCategory, 'DefaultTaskStatus', 'O' /* On hold */, @BusinessUnit, null /* UserId */);

  /* insert task details which have not been assigned to a task into temp table for processing */
  insert into @ttPicksInfo(TaskId, TaskDetailId, PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
                           LocationId, SKUId, InnerPacks, UnitsToAllocate,
                           DestZone, TempLabelId, TempLabel, PickType, CartType,
                           TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
                           TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5)
    select TaskId, TaskDetailId, WaveId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
           LocationId, SKUId,
           /* For an LPN Pick, consider it 1 Case for task thresholds. Each LPN will be one Task Detail  */
           case when PickType = 'L' and InnerPacks = 0 then 1 else InnerPacks end, Quantity,
           DestZone, TempLabelId, TempLabel, PickType, CartType,
           TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
           TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5
    from TaskDetails TD
    where (TD.WaveId = @vWaveId) and
          (TD.TaskId = 0) and
          (TD.Status not in ('X'/* Canceled */)) -- Due to some unexpected errors TDs are created but Tasks are not created, so when cancelled those TDs and tried to reallocate wave it is not allowing to ignore canceled TDs
    order by TD.TDCategory1, TD.TDCategory5;

  if (charindex('D', @Debug) > 0) select * from @ttPicksInfo;

  /* Invoke procedure to check whether the Task Details can be added to existing Tasks */
  insert into @ttPicksToProcess(TaskDetailId, PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
                                LocationId, SKUId, InnerPacks, UnitsToAllocate, UnitWeight, UnitVolume,
                                TotalWeight, TotalVolume, PickPath, PickZone, LocationType, StorageType,
                                DestZone, TempLabelId, TempLabel, PickType, CartType,
                                TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
                                TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5)
    exec pr_Allocation_AddDetailsToExistingTask @ttPicksInfo, @Operation, @BusinessUnit, @UserId;

   /* Update Carton Info */
   update ttPTP
   set ttPTP.CartonType   = CT.CartonType,
       ttPTP.CartonWidth  = CT.OuterWidth,
       ttPTP.CartonHeight = CT.OuterHeight,
       ttPTP.PickZone     = LOC.PickingZone,
       ttPTP.PickPath     = LOC.PickPath,
       ttPTP.LocationType = LOC.LocationType,
       ttPTP.StorageType  = LOC.StorageType
   from @ttPicksToProcess ttPTP
     join LPNs L on (ttPTP.TemplabelId = L.LPNId)
     join CartonTypes CT on (L.CartonType     = CT.CartonType  ) and
                            (L.BusinessUnit   = CT.BusinessUnit)
     join Locations  LOC on (ttPTP.LocationId = LOC.LocationId);

  /* Load all the existing tasks carton dims */
  exec pr_Allocation_CartCubing_LoadTasks @vWaveId, null /* TaskId */, @BusinessUnit, @UserId;

  /* Task Detail groups are already setup */
  while (exists (select * from @ttPicksToProcess))
    begin
      /* Initialize variables in loop */
      select @vTaskId = null, @vShelf = null;

      /* get the top 1 TaskDetail */
      select top 1 @vRecordId        = RecordId,
                   @vTaskZone        = PickZone,
                   @vTaskSubType     = PickType,
                   @vCartType        = CartType,
                   @vTDCategory1     = coalesce(TDCategory1, ''),
                   @vTDCategory2     = coalesce(TDCategory2, ''),
                   @vTDCategory3     = coalesce(TDCategory3, ''),
                   @vTDCategory4     = coalesce(TDCategory4, ''),
                   @vTDCategory5     = coalesce(TDCategory5, ''),
                   @vCartonType      = CartonType,
                   @vCartonWidth     = CartonWidth,
                   @vCartonHeight    = CartonHeight
      from @ttPicksToProcess
      order by TDCategory1, TDCategory2, CartonWidth desc, TDCategory5, CartonType;

      if (charindex('D', @Debug) > 0) select 'Processing ', * from @ttPicksToProcess where RecordId = @vRecordId;

      /* Find out task and shelf to add Carton */
      if exists (select * from #CartShelves)
        exec pr_Allocation_CartCubing_FindPositionToAddCarton @vCartonType, @vCartType, @vTDCategory1, @vTDCategory2, @vTDCategory3,
                                                              @BusinessUnit, @UserId,
                                                              @vTaskId output, @vShelf output;

      /* Create a new task if there is currently not one to be added to */
      if (@vTaskId is null)
        begin
          /* If Cart Type is defined then use it */
          if (@vCartType is null)
            exec pr_Allocation_CartCubing_FindCartType @vWaveId, @vCartType output;

          exec pr_Tasks_Add 'PB',                    /* PickBatch  */
                            @vTaskSubType,           /* Task Type  */
                            @vTaskDesc,              /* TaskDesc */
                            @vTaskStatus,            /* Status */
                            0,                       /* DetailCount */
                            0,                       /* CompletedCount */
                            @vWaveId,
                            @vWaveNo,
                            @vTaskZone,              /* PickZone */
                            null,                    /* PutawayZone */
                            @Warehouse,
                            @vPriority,              /* Priority */
                            null,                    /* scheduleddate */
                            @vIsTaskAllocated,
                            @BusinessUnit,
                            @vOwnership,
                            @vTaskId output,
                            @CreatedBy = @UserId;

          /* Update Cart Type on Task */
          update Tasks
          set CartType = @vCartType
          where (TaskId = @vTaskId);

          /* Add newly created task to hash table to process further */
          exec pr_Allocation_CartCubing_LoadTasks null/* WaveId */, @vTaskId, @BusinessUnit, @UserId;

          /* Find out task and shelf to add Carton */
          exec pr_Allocation_CartCubing_FindPositionToAddCarton @vCartonType, @vCartType, @vTDCategory1, @vTDCategory2, @vTDCategory3,
                                                                @BusinessUnit, @UserId,
                                                                @vTaskId output, @vShelf output;
        end

      /* clear temp table */
      delete from @ttUpdatedTaskDetails

      /* If the processing task detail is from a cluster, then add all the task details in that cluster.
         to the current Task. Cluster here could be a temp label or an Order. This is to ensure that
         each cluster of picks always end up on one task only */
      update TD
      set TaskId       = @vTaskId,
          PickPosition = @vShelf
      output inserted.TaskDetailId, @vTaskId, inserted.SKUId, inserted.OrderDetailId, inserted.TempLabelId, inserted.TempLabelDetailId
      into @ttUpdatedTaskDetails(TaskDetailId, TaskId, SKUId, OrderDetailId, TempLabelId, TempLabelDetailId)
      from TaskDetails TD join @ttPicksToProcess TI on TD.TaskDetailId = TI.TaskDetailId
      where (TI.TDCategory1 = @vTDCategory1) and (TI.TDCategory2 = @vTDCategory2) and (TI.TDCategory5 = @vTDCategory5);

      /* Update cart shelves with used width and categories */
      update #CartShelves
      set UsedWidth   = case when (Shelf = @vShelf) then UsedWidth + @vCartonWidth else UsedWidth end,
          TDCategory1 = @vTDCategory1,
          TDCategory2 = @vTDCategory2
      where (TaskId = @vTaskId);

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
          select @vWaveId, @vWaveNo, TaskId, TaskDetailId, TempLabelId, TempLabelDetailId, @BusinessUnit
          from @ttUpdatedTaskDetails;

      /* Get the created tasks into a Temp Table */
      if not exists(select * from @ttTasksToFinalize where EntityId = @vTaskId)
        insert into @ttTasksToFinalize(EntityId)
          select @vTaskId;

      /* delete the task details from temp table which have been assigned a Task */
      delete from @ttPicksToProcess
      where TaskDetailId in (select TaskDetailId from @ttUpdatedTaskDetails);
    end

  /* When wave is reallocated there might be new cartons generated and they might be added to existing tasks in that case
     clear the position (update them with shelf only i,e. if it is A01 then update with A, B02 update with B) on all the picks of that task
     so that new positions will be updated on all the task details */
  update TD
  set TD.PickPosition = left(TD.PickPosition, 1)
  from TaskDetails TD
    join @ttUpdatedTaskDetails ttTD on (TD.TaskId = ttTD.TaskId);

  /* System will add picks to the existing tasks even if they are released but labels are not printed, so
     in such cases if the new picks are waiting on replenishment then we need to revert the task status to On-Hold.
     So, revert the status to On-Hold and task release will take care of whether release the task or keep them On-Hold */
  update TD
  set Status = 'O' /* On-Hold */
  from TaskDetails TD
    join @ttTasksToFinalize ttT on (TD.TaskId = ttT.EntityId)
  where (TD.Status not in ('C', 'X' /* Completed, Canceled */));

  /* Finalize all the tasks that have been created or modified above */
  exec pr_Allocation_FinalizeTasks @ttTasksToFinalize, @vWaveId, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_CreatePickTasks_PTS */

Go
