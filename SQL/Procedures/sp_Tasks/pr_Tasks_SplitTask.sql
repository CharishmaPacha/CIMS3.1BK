/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_SplitTask') is not null
  drop Procedure pr_Tasks_SplitTask;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_SplitTask: This procedure splits an existing line by
    moving the Split InnerPacks/Qty to a new line. Optionally, if Order info is
    given, the new line is associated with that.
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_SplitTask
  (@TaskDetailId     TRecordId,
   @SplitInnerPacks  TInnerPacks,
   @SplitQuantity    TQuantity,
   @SubType          TTypeCode,
   @DestZone         TZoneId,
   @Operation        TDescription,
   @UserId           TUserId,
  ------------------------------------------
   @NewTaskId        TRecordId output,
   @NewTaskDetailId  TRecordId output)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,

          @vFromTaskId    TRecordId,
          @vNewTaskId     TRecordId,
          @vTaskSubType   TTypeCode,
          @vTaskStatus    TStatus,
          @vBusinessUnit  TBusinessUnit,
          @vWarehouse     TWarehouse,
          @vBatchNo       TPickBatchNo,
          @vOrderId       TRecordId,
          @vOrderDetailId TRecordId,
          @vSKUId         TRecordId,
          @vLocationId    TRecordId,
          @vLPNId         TRecordId,
          @vLPNDetailId   TRecordId;

begin
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @SplitInnerPacks = coalesce(@SplitInnerPacks, 0),
         @SplitQuantity   = coalesce(@SplitQuantity,   0),
         @vTaskStatus     = 'O' /* onhold */;

  if (@TaskDetailId is null)
    set @vMessageName = 'NoTaskDetailToSplit';
  else
  /* Qty */
  if (coalesce(@SplitQuantity, 0) = 0)
    set @vMessageName = 'QuantityCantBeZeroOrNull';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get details for task */
  select @vOrderId = OrderId,
         @vOrderDetailId = OrderDetailId,
         @vBatchNo = BatchNo,
         @vBusinessUnit = BusinessUnit,
         @vWarehouse = Warehouse,
         @vLPNId   = LPNId,
         @vLPNDetailId = LPNDetailId,
         @vLocationId = LocationId,
         @vSKUId = SKUId,
         @vFromTaskId = TaskId
  from vwPickTasks
  where (TaskDetailId = @TaskDetailId);

 if (@Operation = 'Ecom-SplitCaseTask')
   begin
     /* Create new task here  of type Case type and replensih Task subtype*/
     exec pr_Tasks_Add 'PB', /* PickBatch  */ @SubType,/* Task Type  */
                        null /*TaskDesc */, @vTaskStatus, /* Status */ 1, --@DetailCount
                        0 /* @CompletedCount */, @vBatchNo,
                        null, /* PickZone */ null, --@PutawayZone
                        @vWarehouse, null, /* Priority */
                        null,/* scheduleddate */ @vBusinessUnit,
                        @vNewTaskId output, @CreatedBy = @UserId;

     /* Create a new line for  newly created task  */
     insert into TaskDetails(TaskId, Status, OrderId, OrderDetailId, LPNId, LPNDetailId, SKUId,
                             LocationId, InnerPacks, Quantity, BusinessUnit, CreatedBy)
       select @vNewTaskId, @vTaskStatus, @vOrderId, @vOrderDetailId, @vLPNId, @vLPNDetailId, @vSKUId,
              @vLocationId, @SplitInnerPacks, @SplitQuantity, @vBusinessUnit, @UserId;

     update Tasks
     set DestZone  = @DestZone
     where (TaskId = @vNewTaskId)

     /* Recount here */
     exec pr_Tasks_ReCount @vNewTaskId;

     select @vNewTaskId = null;
   end

 /* Create new task here - We need to create a unit pick type here for the above Task  */
 exec pr_Tasks_Add 'PB', /* PickBatch  */ 'U',/* Task Type  */
                    null /*TaskDesc */, @vTaskStatus, /* Status */ 1, --@DetailCount
                    0 /* @CompletedCount */, @vBatchNo,
                    null, /* PickZone */ null, --@PutawayZone
                    @vWarehouse, null, /* Priority */
                    null,/* scheduleddate */ @vBusinessUnit,
                    @vNewTaskId output, @CreatedBy = @UserId;

  /* Create a new line for  newly created task  */
  insert into TaskDetails(TaskId, Status, OrderId, OrderDetailId, LPNId, LPNDetailId, SKUId,
                          LocationId, InnerPacks, Quantity, DestZone, BusinessUnit, CreatedBy)
    select @vNewTaskId, @vTaskStatus, @vOrderId, @vOrderDetailId, @vLPNId, @vLPNDetailId, @vSKUId,
           @vLocationId, @SplitInnerPacks, @SplitQuantity, @DestZone, @vBusinessUnit, @UserId;

  /* select newly created taskid and taskdetail here */
  select @NewTaskDetailId = Scope_Identity(),
         @NewTaskId       = @vNewTaskId;

  /* Reduce the Original Line Quantity and relevant fields accordingly */
  update TaskDetails
  set InnerPacks   = InnerPacks - @SplitInnerPacks,
      Quantity     = Quantity - @SplitQuantity,
      ModifiedDate = current_timestamp,
      ModifiedBy   = coalesce(@UserId, System_User)
  where TaskDetailId = @TaskDetailId;

  update Tasks
  set DestZone = @DestZone
  where (TaskId = @vNewTaskId);

  /* Recount Task -From Task*/
  exec pr_Tasks_ReCount @vFromTaskId;

  /* Recount Task New  Task*/
  exec pr_Tasks_ReCount @vNewTaskId;

  if (@vReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_SplitTask */

Go
