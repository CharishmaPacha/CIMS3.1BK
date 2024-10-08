/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_TasksDetails_TransferUnits: Delete orphan task detail from LPNTasks table (HPI-2211)
  2018/07/10  TK/AY   pr_TasksDetails_TransferUnits: Bug fix in merging Picks (S2G-GoLive)
  2018/05/25  TK      pr_TasksDetails_TransferUnits: Changes to merge to LPN details as well (S2G-493)
  2018/04/23  TK      pr_TasksDetails_TransferUnits: Minor changes (S2G-493)
  2017/07/14  RV      pr_TasksDetails_TransferUnits, pr_TasksDetails_SplitUnits: Send ProcId to pr_ActivityLog_LPN (HPI-1584)
  pr_TasksDetails_TransferUnits: Call Tasks_SetStatus with recount Flag ON as recounts.
  2017/03/04  VM      pr_TasksDetails_TransferUnits: Added (HPI-1427)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TasksDetails_TransferUnits') is not null
  drop Procedure pr_TasksDetails_TransferUnits;
Go
/*------------------------------------------------------------------------------
  Proc pr_TasksDetails_TransferUnits:
    This procedure will transfer units & innerpacks from Source task detail line to the Target task detail line
    (which are related Source & Target Picklane LPNDetailIds sent to the procedure).

    Likewise, it also transfers units & innerpacks from the related Source ToLPN detail line to the Target ToLPN detail line.

    After processing, if in case of no units left in the transfered line,
    it will delete the lines of Task Detail and related ToLPN Detail
------------------------------------------------------------------------------*/
Create Procedure pr_TasksDetails_TransferUnits
  (@SourcePicklaneLPNDetailId TRecordId,
   @TargetPicklaneLPNDetailId TRecordId,
   @IPsToTransfer             TInnerPacks,
   @QtyToTransfer             TQuantity,
   @Operation                 TOperation = null,
   @BusinessUnit              TBusinessUnit,
   @UserId                    TUserId)
As
  declare @vReturnCode           TInteger,
          @vPickBatchNo          TPickBatchNo,

          @vSourceTaskId         TRecordId,
          @vSourceTaskDetailId   TRecordId,
          @vSourceLPNDetailId    TRecordId,
          @vSourceToLPNDetailId  TRecordId,
          @vSourceTaskDetailQty  TQuantity,

          @vTargetTaskId         TRecordId,
          @vTargetTaskDetailId   TRecordId,
          @vToLPNId              TRecordId,
          @vTargetLPNId          TRecordId,
          @vTargetLPNDetailId    TRecordId,
          @vTargetToLPNDetailId  TRecordId,

          @vToLDActivityLogId    TRecordId;
begin
  SET NOCOUNT ON;

  /* Steps
     >. Get the Source task detail based on the passed in SourcePicklaneLPNDetailId
     >. Get the Target task detail based on the passed in TargetPicklaneLPNDetailId
     >. Get the Source & Target ToLPN lines based on the Source & Target Task details

     >. Transfer IPs/Units from Source Task detail to Target Task detail
     >. Transfer IPs/Units from Source ToLPN detail to Target ToLPN detail

     >. Reduce IPs/Units from Source Task detail line
     >. Reduce IPs/Units from Source ToLPN detail line
        (OR)
     >. Delete Source Task detail line, if there are no more IPs/Units on them
     >. Delete Source ToLPN detail line, if there are no more IPs/Units on them
  */
  /* We need to have both target and source LPNDetailId id not present then exit */
  if (@SourcePicklaneLPNDetailId is null) or
     (@TargetPicklaneLPNDetailId is null) or
     (@SourcePicklaneLPNDetailId = @TargetPickLaneLPNDetailId)
   goto ExitHandler;

  /* Get the Source task detail based on the passed in SourcePicklaneLPNDetailId */
  select @vSourceTaskId        = TaskId,
         @vPickBatchNo         = PickBatchNo,
         @vSourceTaskDetailId  = TaskDetailId,
         @vToLPNId             = TempLabelId, -- Usually, both Source & Target ToLPNId would be same! So taking ToLPNId in one place!
         @vSourceLPNDetailId   = LPNDetailId,
         @vSourceToLPNDetailId = TempLabelDetailId,
         @vSourceTaskDetailQty = Quantity
         --@SourceTaskDetailIPs = InnerPacks
  from TaskDetails
  where (LPNDetailId = @SourcePicklaneLPNDetailId) and
        (Status in ('N', 'I', 'O' /* New, In-progress, On-hold */));

  /* Get the Target task detail based on the passed in TargetPicklaneLPNDetailId */
  select @vTargetTaskId        = TaskId,
         @vTargetTaskDetailId  = TaskDetailId,
         @vTargetLPNId         = LPNId,
         @vTargetLPNDetailId   = LPNDetailId,
         @vTargetToLPNDetailId = TempLabelDetailId
  from TaskDetails
  where (LPNDetailId = @TargetPicklaneLPNDetailId) and
        (Status in ('N', 'I', 'O' /* New, In-progress, On-hold */));;

  begin try
    /* Start log of ToLPN Details into ActivityLog */
    exec pr_ActivityLog_LPN 'TasksDetails_TransferUnits_ToLPNDetails_Start', @vToLPNId, 'ACT_TasksDetails_TransferUnits', @@ProcId,
                            null, @BusinessUnit, @UserId, @vToLDActivityLogId output;
  end try
  begin catch
    /* do nothing */
  end catch

  /* Transfer IPs/Units from Source Task detail to Target Task detail */
  update TaskDetails
  set InnerPacks += @IPsToTransfer,
      Quantity   += @QtyToTransfer
  where (TaskDetailId = @vTargetTaskDetailId);

  /* Transfer IPs/Units from Source ToLPN detail to Target ToLPN detail */
  update LPNDetails
  set InnerPacks += @IPsToTransfer,
      Quantity   += @QtyToTransfer
  where (LPNDetailId = @vTargetToLPNDetailId);

  /* Transfer IPs/Units from Source LPN detail to Target LPN detail */
  update LPNDetails
  set InnerPacks  += @IPsToTransfer,
      Quantity    += @QtyToTransfer,
      ReservedQty += @QtyToTransfer
  where (LPNDetailId = @vTargetLPNDetailId);

  /* Reduce from Source Task detail line or delete line based on balance Source Task Detail Qty.
     Likewise, with ToLPN detail line as well */
  if ((@vSourceTaskDetailQty - @QtyToTransfer) > 0)
    begin
      /* Reduce from Source Task detail line */
      update TaskDetails
      set Quantity   -= @QtyToTransfer,
          InnerPacks -= @IPsToTransfer
      where (TaskDetailId = @vSourceTaskDetailId);

      /* Reduce from Source ToLPN detail line */
      update LPNDetails
      set Quantity   -= @QtyToTransfer,
          InnerPacks -= @IPsToTransfer
      where (LPNDetailId = @vSourceToLPNDetailId);

      /* Reduce from Source LPN detail line */
      update LPNDetails
      set Quantity    -= @QtyToTransfer,
          InnerPacks  -= @IPsToTransfer,
          ReservedQty -= @QtyToTransfer
      where (LPNDetailId = @vSourceLPNDetailId);
    end
  else
    begin
      /* Delete Source Task detail line */
      delete from TaskDetails where (TaskDetailId = @vSourceTaskDetailId);

      delete from LPNTasks where (TaskDetailId = @vSourceTaskDetailId);

      /* Delete Source ToLPN detail line */
      delete from LPNDetails  where (LPNDetailId = @vSourceToLPNDetailId);

      /* Delete Source LPN detail line */
      delete from LPNDetails  where (LPNDetailId = @vSourceLPNDetailId);
    end

  /* Recount and set the Task Status with recount flag ON as counts on both procedures (Tasks_Recount and Tasks_SetStatus) are different */
  exec pr_Tasks_ReCount @vSourceTaskId;
  exec pr_Tasks_SetStatus @vSourceTaskId, @UserId, null /* Status */, 'Y' /* Recount */;

  /* There could be a chance that SourceTaskId & TargetTaskId are different, if so, recount and set the Target Task Status as well */
  if (@vSourceTaskId <> @vTargetTaskId)
    begin
      exec pr_Tasks_ReCount @vTargetTaskId;
      exec pr_Tasks_SetStatus @vTargetTaskId, @UserId, null /* Status */, 'Y' /* Recount */;
    end

  /* Recount the ToLPN (if exists) */
  if (@vToLPNId is not null)
    exec pr_LPNs_Recount @vToLPNId;

  /* Recount the Target LPN */
  exec pr_LPNs_Recount @vTargetLPNId;

  /* Recount the Wave */
  exec pr_PickBatch_UpdateCounts @vPickBatchNo, 'T' /* T - Tasks (Options) */;

  begin try
    /* End log of ToLPN Details into ActivityLog */
    exec pr_ActivityLog_LPN 'TasksDetails_TransferUnits_ToLPNDetails_End', @vToLPNId, 'ACT_TasksDetails_TransferUnits', @@ProcId,
                            null, @BusinessUnit, @UserId, @vToLDActivityLogId output;
  end try
  begin catch
    /* do nothing */
  end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_TasksDetails_TransferUnits */

Go
