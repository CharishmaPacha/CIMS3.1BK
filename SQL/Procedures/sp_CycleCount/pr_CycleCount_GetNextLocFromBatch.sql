/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  Renamed pr_CycleCount_FindNextLocFromBatch => pr_CycleCount_GetNextLocFromBatch: Which
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_GetNextLocFromBatch') is not null
  drop Procedure pr_CycleCount_GetNextLocFromBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_GetNextLocFromBatch:
    This proc will return the next location to be cycle counted for the given
      BatchNo and in status 'N'.
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_GetNextLocFromBatch
  (@BatchNo             TTaskBatchNo = null,
   @UserId              TUserId,
   @Location            TLocation output,
   @TaskDetailId        TRecordId output)
as
begin
  /* First, see if there is an already Inprogress Location for the user, if So,
     give that. */
  select Top 1 @Location     = Location,
               @TaskDetailId = TaskDetailId
  from vwCycleCountTaskDetails
  where (BatchNo          = @BatchNo) and
        (TaskDetailStatus = 'I' /* InProgress */) and
        (ModifiedBy        = @UserId)
  order by PickPath, Location;

  /* If there are no InProgress Locations, then return next Location on that
     BatchNo depending on its PickPath and Location. */
  if (@Location is null)
    select Top 1 @Location     = Location,
                 @TaskDetailId = TaskDetailId
    from vwCycleCountTaskDetails
    where (BatchNo          = @BatchNo) and
          (TaskDetailStatus = 'N' /* Ready To Start */)
    order by PickPath, Location;

end /* pr_CycleCount_GetNextLocationFromBatch */

Go
