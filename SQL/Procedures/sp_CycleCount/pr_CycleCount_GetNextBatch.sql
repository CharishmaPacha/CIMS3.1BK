/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/12  OK      pr_CycleCount_GetNextBatch: Changes to suggest CC batches based on priority first and then ScheduleDate (S2G-301)
  2017/01/17  OK      pr_CycleCount_GetNextBatch: Enhanced to suggest taks based on the user permission (GNC-1408)
  2012/09/24  PK      pr_CycleCount_GetNextBatch: Returning InProgress Batches if exists for the user.
  2012/07/16  AY      pr_CycleCount_GetNextBatch: Find within the User logged in Warehouse.
  2012/01/27  YA      Created new procedure pr_CycleCount_GetNextBatch: To fetch next BatchNo to be CycleCounted.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_GetNextBatch') is not null
  drop Procedure pr_CycleCount_GetNextBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_GetNextBatch:
    This proc will return the next Batch to be Cycle Counted.
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_GetNextBatch
  (@BatchNo      TTaskBatchNo output,
   @TaskId       TRecordId    output,
   @Warehouse    TWarehouse,
   @PickZone     TZoneId = null,
   @UserId       TUserId)
as
  declare @vTaskSubType TTypeCode;

begin

  /* Get the valid TaskSubType to suggest to user based on the Permission */
  select @vTaskSubType = case when dbo.fn_Permissions_IsAllowed(@UserId, 'AllowCycleCount_L2') <> 1 then 'L1' else null end;

  /* If the user scans or does not scans the batch then verify whether there are any
     batches with 'I' (InProgress) status for the particular User and return the
     batch */
  select Top 1 @BatchNo = BatchNo,
               @TaskId  = TaskId
  from Tasks
  where (BatchNo    = coalesce(@BatchNo , BatchNo)) and
        (PickZone   = coalesce(@PickZone, PickZone)) and
        (Warehouse  = @Warehouse) and
        (Status in ('I' /* In Progress */)) and
        (TaskType   = 'CC'/* Cycle Count */)  and
        (ModifiedBy = @UserId)
  order by TaskSubType desc, Priority, ScheduledDate, PickZone

  /* Fetching only those batches which are in status 'N' (Ready To Start)
     update task before assigning it to the user so that another user would
     not be assigned the same batch */

 /* If user doesn't have permissions for AllowCycleCount_L2,then we need to suggest L1 tasks only.
    If user has permission, then we need to suggest L2 tasks first, if no L2 tasks exists then
    need to suggest L1 tasks. We are achieving this by sorting the Tasks by TaskSubType Desc */

  if (@BatchNo is null)
    begin
      With BatchesToCycleCount (TaskId, Status, BatchNo, ModifiedBy)
      as (
        select Top 1 TaskId, Status, BatchNo, ModifiedBy
        from Tasks
        where (BatchNo  = coalesce(@BatchNo , BatchNo)) and
              (PickZone = coalesce(@PickZone, PickZone)) and
              (Warehouse = @Warehouse) and
              (Status in ('N'  /* Ready To Start */)) and
              (TaskType      = 'CC' /* Cycle Count */) and
              (TaskSubType   = coalesce(@vTaskSubType, TaskSubType))
        order by TaskSubType desc, Priority, ScheduledDate, PickZone
        )
      update BatchesToCycleCount
      set Status     = 'I' /* InProgress */,
          ModifiedBy = @UserId,
          @BatchNo   = BatchNo,
          @TaskId    = TaskId;
    end

end /* pr_CycleCount_GetNextBatch */

Go
