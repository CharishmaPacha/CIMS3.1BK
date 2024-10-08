/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/05  TK      pr_Allocation_CartCubing_FindPositionToAddCarton, pr_Allocation_CreatePickTasks_PTS,
                      pr_Allocation_ProcessTaskDetails & pr_Allocation_AddDetailsToExistingTask:
                        Changes to use CartType that is defined in rules (HA-1137)
                      pr_Allocation_FinalizeTasks: Removed unnecessary code as updating dependices is being
                        done in pr_Allocation_UpdateWaveDependencies (HA-1211)
  2018/07/10  TK/AY   pr_Allocation_AddDetailsToExistingTask: Bug fix in merging Picks (S2G-GoLive)
  2018/05/25  TK      pr_Allocation_AddDetailsToExistingTask: Fixed bug to merge Picks from Same LPN (S2G-493)
  2018/05/08  TK      pr_Allocation_CreatePickTasks: Changes to consolidate task details and add to existing tasks
                      pr_Allocation_AddDetailsToExistingTask: Initial Revision (S2G-493)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AddDetailsToExistingTask') is not null
  drop Procedure pr_Allocation_AddDetailsToExistingTask;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AddDetailsToExistingTask: This proc find the Task Details matching
    with Merge Criteria and adds details to the Task
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AddDetailsToExistingTask
  (@PicksInfo          TTaskInfoTable  ReadOnly,
   @Operation          TOperation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vRecordId            TRecordId,
          @vTaskId              TRecordId,
          @vTargetLPNDetailId   TRecordId,
          @vSrcLPNDetailId      TRecordId,
          @vSrcInnerpacks       TInnerpacks,
          @vSrcQuantity         TQuantity,
          @vTDMergeCriteria1    TCategory,
          @vTDMergeCriteria2    TCategory;

  declare @ttPicksInfo          TTaskInfoTable,
          @ttTasksToRecount     TRecountKeysTable;
begin /* pr_Allocation_AddDetailsToExistingTask */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Capture all the Picks to process them */
  insert into @ttPicksInfo(TaskId, TaskDetailId, PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
                           LocationId, SKUId, InnerPacks, UnitsToAllocate, UnitWeight, UnitVolume,
                           TotalWeight, TotalVolume, PickPath, PickZone, LocationType, StorageType,
                           DestZone, TempLabelId, TempLabel, PickType, CartType,
                           TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
                           TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5)
    select TaskId, TaskDetailId, PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
           LocationId, SKUId, InnerPacks, UnitsToAllocate, UnitWeight, UnitVolume,
           TotalWeight, TotalVolume, PickPath, PickZone, LocationType, StorageType,
           DestZone, TempLabelId, TempLabel, PickType, CartType,
           TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
           TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5
    from @PicksInfo
    order by TaskDetailId desc;

  /* If there are no Task Details that matches with the TDCriteria1 then none of the details can be added to existing Tasks
     if there are any task details matching with TDMergeCriteria1 then they would ba added to the Task they are matched with.
     And if the details were added to existing task have details matching with MergeCriteria2 then they will be merged in next step  */


  /* If there is a Task Detail with same merge criteria1 then add them to the that Task */
  update ttPI
  set ttPI.TaskId = TD.TaskId
  from @ttPicksInfo ttPI
    join TaskDetails TD on (TD.TDMergeCriteria1 = ttPI.TDMergeCriteria1)
    join Tasks       T  on (TD.TaskId = T.TaskId)
  where (T.Status in ('O', 'N'/* OnHold, Ready To Start */)) and
        (T.LabelsPrinted = 'N'/* No */) and
        (T.Archived = 'N') and
        (TD.TDMergeCriteria1 is not null);

  /* Update Task Id on task details */
  /* Task Details should be updated with TaskId before they are merged else
     we will create a new task detail which is already merged */
  update TD
  set TD.TaskId = ttPI.TaskId
  output Inserted.TaskId into @ttTasksToRecount (EntityId)
  from TaskDetails TD
    join @ttPicksInfo ttPI on (TD.TaskDetailId = ttPI.TaskDetailId)
  where (ttPI.TaskId <> 0);

  /* If the details were added to existing task then need to find out picks from same LPN and then merge them */
  while exists (select * from @ttPicksInfo where RecordId > @vRecordId and  TaskId <> 0)
    begin
      select top 1 @vRecordId          = RecordId,
                   @vTaskId            = TaskId,
                   @vSrcLPNDetailId    = LPNDetailId,
                   @vSrcInnerpacks     = InnerPacks,
                   @vSrcQuantity       = UnitsToAllocate,
                   @vTDMergeCriteria1  = TDMergeCriteria1,
                   @vTDMergeCriteria2  = TDMergeCriteria2,
                   @vTargetLPNDetailId = null
      from @ttPicksInfo
      where (RecordId > @vRecordId) and
            (TaskId <> 0)
      order by RecordId;

      /* Find out if there is a similar Task Detail to merge */
      select top 1 @vTargetLPNDetailId = LPNDetailId
      from TaskDetails
      where (TaskId           = @vTaskId          ) and
            (LPNDetailId      <> @vSrcLPNDetailId ) and  -- other than source LPNDetailId
            (TDMergeCriteria1 = @vTDMergeCriteria1) and
            (TDMergeCriteria2 = @vTDMergeCriteria2) and
            (TDMergeCriteria2 is not null) and
            (Status in ('O', 'N'/* OnHold, Ready To Start */))
      order by TaskDetailId;

      /* If there is a task detail which is matching with current task detail merge criteria 2 and in the same task
         then merge them */
      if (@vTargetLPNDetailId is not null)
        exec pr_TasksDetails_TransferUnits @vSrcLPNDetailId, @vTargetLPNDetailId, @vSrcInnerpacks, @vSrcQuantity, @Operation, @BusinessUnit, @UserId;
    end

  /* Update the counts on all the tasks */
  exec pr_Tasks_Recalculate @ttTasksToRecount, 'CS' /* Counts & Status */, @UserId;

  /* Return the Task Details which are not added to existing Tasks, which will be processed further to create new tasks */
  select TaskDetailId, PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
         LocationId, SKUId, InnerPacks, UnitsToAllocate, UnitWeight, UnitVolume,
         TotalWeight, TotalVolume, PickPath, PickZone, LocationType, StorageType,
         DestZone, TempLabelId, TempLabel, PickType, CartType,
         TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
         TDMergeCriteria1, TDMergeCriteria2, TDMergeCriteria3, TDMergeCriteria4, TDMergeCriteria5
  from @ttPicksInfo
  where (TaskId = 0);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AddDetailsToExistingTask */

Go
