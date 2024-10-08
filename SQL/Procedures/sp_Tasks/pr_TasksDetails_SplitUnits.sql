/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/03  TK      pr_TasksDetails_SplitUnits: Changes to update WaveId and PickPosition on new task detail (HPI-2630)
  2018/12/04  TK      pr_TasksDetails_SplitUnits: Changes to insert new task detail into LPNTasks table
  2017/07/14  RV      pr_TasksDetails_TransferUnits, pr_TasksDetails_SplitUnits: Send ProcId to pr_ActivityLog_LPN (HPI-1584)
  2017/03/09  VM      pr_TasksDetails_SplitUnits: Added (HPI-1447)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TasksDetails_SplitUnits') is not null
  drop Procedure pr_TasksDetails_SplitUnits;
Go
/*------------------------------------------------------------------------------
  Proc pr_TasksDetails_SplitUnits:
    This procedure splits units & innerpacks of Source task detail line to be intact with split From LPN Details
    Likewise, it also splits units & innerpacks from the related Source ToLPN detail line.
------------------------------------------------------------------------------*/
Create Procedure pr_TasksDetails_SplitUnits
  (@SourcePicklaneLPNDetailId TRecordId,
   @NewPicklaneLPNDetailId    TRecordId,
   @NewLineIPs                TInnerPacks,
   @NewLineQty                TQuantity,
   @Operation                 TOperation = null,
   @BusinessUnit              TBusinessUnit,
   @UserId                    TUserId)
As
  declare @vPickBatchNo          TPickBatchNo,

          @vSourceTaskId         TRecordId,
          @vSourceTaskDetailId   TRecordId,
          @NewTaskDetailId       TRecordId,
          @vSourceTaskDetailQty  TQuantity,

          @vSourceOrderId        TRecordId,
          @vSourceOrderDetailId  TRecordId,

          @vSourceToLPNId        TRecordId,
          @vSourceToLPNDetailId  TRecordId,
          @vNewToLPNDetailId     TRecordId,

          @vToLDActivityLogId    TRecordId;
begin
  SET NOCOUNT ON;

  /* Steps
     >. Get the Source task detail, ToLPN detail based on the passed in SourcePicklaneLPNDetailId (Use 'Update' to reduce units)
     >. Split Source ToLPN detail to New ToLPN detail and recount LPN.

     >. Recounts of Task and Wave
  */

  /* Get the Source task detail based on the passed in SourcePicklaneLPNDetailId
     and also, reduce NewLineIPs and NewLineQty from Source Task detail line */
  update TaskDetails
  set Quantity              -= @NewLineQty,
      InnerPacks            -= @NewLineIPs,
      @vPickBatchNo          = PickBatchNo,
      @vSourceTaskId         = TaskId,
      @vSourceTaskDetailId   = TaskDetailId,
      @vSourceToLPNId        = TempLabelId,
      @vSourceToLPNDetailId  = TempLabelDetailId
  where (LPNDetailId = @SourcePicklaneLPNDetailId) and
        (Status in ('N', 'I', 'O' /* New, In-progress, On-hold */));

  if (@vSourceToLPNDetailId is not null)
    begin
      /* Start log of ToLPN Details into ActivityLog */
      exec pr_ActivityLog_LPN 'TasksDetails_SplitUnits_ToLPNDetails_Start', @vSourceToLPNId, 'ACT_TasksDetails_SplitUnits', @@ProcId,
                              null, @BusinessUnit, @UserId, @vToLDActivityLogId output;

      /* Get Order info of Source ToLPN Detail to pass it to SplitLine procedure */
      select @vSourceOrderId       = OrderId,
             @vSourceOrderDetailId = OrderDetailId
      from LPNDetails
      where (LPNDetailId = @vSourceToLPNDetailId);

      /* Split ToLPN detail line - will take care of inserting new line and reducing units from source ToLPN detail as well */
      exec pr_LPNDetails_SplitLine @vSourceToLPNDetailId, @NewLineIPs, @NewLineQty,
                                   @vSourceOrderId, @vSourceOrderDetailId,
                                   @vNewToLPNDetailId output;

      /* Recount ToLPN */
      exec pr_LPNs_Recount @vSourceToLPNId;

      /* End log of ToLPN Details into ActivityLog */
      exec pr_ActivityLog_LPN 'TasksDetails_SplitUnits_ToLPNDetails_End', @vSourceToLPNId, 'ACT_TasksDetails_SplitUnits', @@ProcId,
                              null, @BusinessUnit, @UserId, @vToLDActivityLogId output;
    end

  /* Insert New task detail taking details from Source task detail.
     Take care in inserting NewPicklnaneLPNDetailId, NewLineIPs & NewLineQty for new reocord */
  insert into TaskDetails(TaskId, PickType, Status, WaveId, PickBatchNo, OrderId, OrderDetailId, SKUId, InnerPacks, Quantity,
                          LPNId, LPNDetailId, LocationId, DestZone, DestLocation, IsLabelGenerated,
                          TempLabelId, TempLabel, TempLabelDetailId, PickPosition,
                          TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
                          UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, BusinessUnit, CreatedBy)
  select TaskId, PickType, Status, WaveId, PickBatchNo, OrderId, OrderDetailId, SKUId, @NewLineIPs, @NewLineQty,
         LPNId, @NewPicklaneLPNDetailId, LocationId, DestZone, DestLocation, IsLabelGenerated,
         TempLabelId, TempLabel, @vNewToLPNDetailId, PickPosition,
         TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
         UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, BusinessUnit, @UserId
  from TaskDetails
  where (TaskDetailId = @vSourceTaskDetailId);

  select @NewTaskDetailId = Scope_Identity();

  /* If the source task detail exists in LPN tasks, then insert new task detail into LPN Tasks table */
  if exists (select * from LPNTasks where TaskDetailId = @vSourceTaskDetailId)
    insert into LPNTasks (PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId, LPNDetailId, BusinessUnit)
      select WaveId, PickBatchNo, TaskId, @NewTaskDetailId, TempLabelId, @vNewToLPNDetailId, @BusinessUnit
      from TaskDetails
      where (TaskDetailId = @vSourceTaskDetailId);

  /* Recount the Task */
  exec pr_Tasks_ReCount @vSourceTaskId;

  /* Recount the Wave */
  exec pr_PickBatch_UpdateCounts @vPickBatchNo, 'T' /* T - Tasks (Options) */;

end /* pr_TasksDetails_SplitUnits */

Go
