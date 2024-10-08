/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/24  TK      pr_Picking_ValidateTaskId: Validate whether the Task is allocated and confirmed or not (S2GCA-158)
  2018/04/17  VM      pr_Picking_ValidateTaskId: Set a proper message when Pallet has any other active task (S2G-660)
  2016/02/19  TD      pr_Picking_ValidateTaskId:Changes to return batchno if we pass null as batchno.
  2015/01/13  VM      pr_Picking_ValidateTaskId, pr_Picking_FindNextTaskToPickFromBatch:
  2014/09/04  TK      pr_Picking_ValidateTaskId: Added new validation 'TaskNotReleasedForPicking'.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ValidateTaskId') is not null
  drop Procedure pr_Picking_ValidateTaskId;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ValidateTaskId: User could have given a TaskId and we could have
   selected a TaskId that is active, so validate based upon what user has given.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ValidateTaskId
  (@UserTaskId       TRecordId,
   @SelectedTaskId   TRecordId,
   @PickGroup        TPickGroup,
   @PickPallet       TPallet,
   @PickTicket       TPickTicket  = null,
   @ValidTaskId      TRecordId    = null output,
   @PickBatchNo      TPickBatchNo = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vNote1             TDescription,
          @vNote2             TDescription,
          @vNote3             TDescription,

          @vTaskId            TRecordId,
          @vTaskStatus        TStatus,
          @vPickBatchNo       TPickBatchNo,
          @vTaskSubType       TTypeCode,
          @vTaskSubTypeDesc   TDescription,
          @vTaskPickGroup     TPickGroup,

          @vOrderId           TRecordId,
          @vBatchPallet       TPallet,
          @vUnitsToPick       TQuantity,
          @vIsBatchAllocated  TFlag,
          @vIsTaskConfirmed   TFlags,
          @vIsTaskAllocated   TFlags;
begin /* pr_Picking_ValidateTaskId */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the Task Information */
  select @vTaskId          = TaskId,
         @vTaskStatus      = Status,
         @vPickBatchNo     = BatchNo,
         @vTaskSubType     = TaskSubType,
         @vTaskSubTypeDesc = TaskSubTypeDescription,
         @vTaskPickGroup   = PickGroup,
         @vIsTaskAllocated = IsTaskAllocated,
         @vIsTaskConfirmed = IsTaskConfirmed
  from vwTasks
  where (TaskId = @SelectedTaskId);

  /* Get the order info */
  select @vOrderId = OrderId
  from OrderHeaders
  where (PickTicket = @PickTicket);

  /* Verify whether the given Task exists */
  if (@vTaskId is null)
    set @vMessageName = 'TaskDoesNotExist';
  else
  /* Verify whether the given Task is released for picking or not */
  if (@vTaskStatus = 'O' /* On Hold */)
    set @vMessageName = 'TaskNotReleasedForPicking';
  else
  if (@vTaskStatus  = 'C')
    set @vMessageName = 'TaskCompletedAlready';
  else
  if (@vTaskStatus  = 'X')
    set @vMessageName = 'TaskWasCancelled';
  else
  if (@vIsTaskAllocated = 'N'/* No */) -- Pseudo Picks, TaskAllocated would be NR - Not required
    set @vMessageName = 'TaskNotAllocated';
  else
  if (@vIsTaskConfirmed = 'N'/* No */)
    set @vMessageName = 'TaskNotConfirmed';
  else
  /* Validate this only if user has not given TaskId and we have selected the active task from
     the pallet */
  if (@PickGroup is not null) and (@PickGroup not like @vTaskPickGroup) and (@UserTaskId is null)
    begin
      select @vMessageName = 'ActiveTaskOnPallet',
             @vNote1       = @vTaskSubTypeDesc,
             @vNote2       = @SelectedTaskId,
             @vNote3       = @vPickBatchNo;
    end
  else
  if (@PickGroup is not null) and (@PickGroup not like @vTaskPickGroup)
    select @vMessageName = 'TaskPickGroupMismatch'
  else
  /* Verify whether the given Task Status is valid or not */
  if (@vTaskStatus not in ('N' /* Ready To Pick */, 'I' /* In progress */))
    set @vMessageName = 'TaskNotAvailableForPicking';
  else
  --if (@vTaskSubType = 'L' /* LPN Task */)
  --  set @vMessageName = 'LPNTask_UseLPNPicking';
  --else
  if (@PickBatchNo is not null) and (@PickBatchNo <> @vPickBatchNo)
    set @vMessageName = 'TaskIsNotAssociatedWithThisBatch';
  else
  if (@PickTicket is not null) and
     (not (exists(select * from TaskDetails
                  where (OrderId = @vOrderId) and
                        (TaskId = @vTaskId))))
    set @vMessageName = 'TaskIsNotAssociatedWithThisPickTicket';

  /* if the Pickbatchno is null then we need to return it which is from
     task headers */
  if (@PickBatchNo is null)
    set @PickBatchNo = @vPickBatchNo;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1, @vNote2, @vNote3;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ValidateTaskId */

Go
