/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/12/26  PK      Created pr_Tasks_MarkTaskDetailAsCompleted, pr_Tasks_UpdateCount,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_MarkTaskDetailAsCompleted') is not null
  drop Procedure pr_Tasks_MarkTaskDetailAsCompleted;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_MarkTaskDetailAsCompleted:
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_MarkTaskDetailAsCompleted
  (@TaskDetailId  TRecordId,
   @Variance      TFlags,
   @UserId        TUserId)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @vTaskId        TRecordId;
begin /* pr_Tasks_MarkTaskDetailAsCompleted */
  select @ReturnCode  = 0,
         @MessageName = null;

  /* Update TaskDetails */
  update TaskDetails
  set @vTaskId        = TaskId,
      Status          = 'C' /* CycleCount Completed */,
      Variance        = @Variance,
      TransactionDate = current_timestamp,
      ModifiedDate    = current_timestamp,
      ModifiedBy      = coalesce(@UserId, System_User)
  where (TaskDetailId = @TaskDetailId);

  /* Update Task Counts which in turn updates the status as well */
  exec @ReturnCode = pr_Tasks_UpdateCount @vTaskId, '+', 0 /* total Count */, 1 /* Completed Count */, @UserId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Tasks_MarkTaskDetailAsCompleted */

Go
