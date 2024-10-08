/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_Cancel') is not null
  drop Procedure pr_CycleCount_Cancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_Cancel:
    This proc will revert the statuses of the Location and its Batch.
    Batch will be reverted only when all the locations of that Batch is in status 'N'(ReadyToStart)
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_Cancel
  (@BatchNo             TTaskBatchNo,
   @Location            TLocation)
as
  declare @vLocationId   TRecordId,
          @vTaskId       TRecordId,
          @vCount        TCount;
begin
  /* Fetches Location Id and TaskId as it is required to update TaskDetails table */
  select @vLocationId = LocationId
  from Locations
  where (Location = @Location);

  select @vTaskId = TaskId
  from Tasks
  where (BatchNo = @BatchNo);

  /* Update TaskDetails by setting status to ReadyToPick */
  update TaskDetails
  set Status = 'N' /* Ready To Start */
  where (TaskId     = @vTaskId) and
        (LocationId = @vLocationId)

  /* Checks whether the batch contains any details with status complete or InProgress
     incase it finds any it will not update the status of Batch in Tasks table */
  select @vCount = count(*)
  from vwTaskDetails
  where (BatchNo  = @BatchNo) and
        (Location = @Location) and
        (Status in ('C' /* Completed */, 'I' /* In Progress */))

  /* Update tasks if the count is zero */
  if (@vCount = 0)
    update Tasks
    set Status = 'N'
    where (BatchNo = @BatchNo)
end /* pr_CycleCount_Cancel */

Go
