/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/24  TK      pr_TaskDetails_SplitDetail: Changes to copy PickZone, PickSequence, PackingGroup & DependencyFlags for new task detail (HA-171)
  2019/04/11  TK      pr_TaskDetails_SplitDetail: Split from LPN Detail based upon operation (S2GCA-590)
  2018/09/17  TK      pr_TaskDetails_SplitDetail: Changes to insert new task detail into LPN Tasks table (S2GCA-219)
  2018/09/14  TK      pr_TaskDetails_SplitDetail: Carry WaveId & PickPosition information to new task details (S2GCA-266)
  2018/06/13  TK      pr_TaskDetails_SplitDetail: Initial Revision (S2GCA-66)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_SplitDetail') is not null
  drop Procedure pr_TaskDetails_SplitDetail;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_SplitDetail: This proc does the following

  1. Split From LPN Detail
  2. Split Temp Label Detail
  3. Add New Task Detail with Split info
  4. Reduce quantities on source task detail
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_SplitDetail
  (@TaskDetailId              TRecordId,
   @NewLineIPs                TInnerPacks,
   @NewLineQty                TQuantity,
   @Operation                 TOperation = null,
   @BusinessUnit              TBusinessUnit,
   @UserId                    TUserId,
   @NewTaskDetailId           TRecordId  output)
As
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TDescription,

          @vWaveNo                   TWaveNo,

          @vSourceTaskId             TRecordId,
          @vSourceTaskDetailId       TRecordId,
          @vSourceLPNId              TRecordId,
          @vSourceLPNDetailId        TRecordId,
          @vSourceOrderId            TRecordId,
          @vSourceOrderDetailId      TRecordId,
          @vSourceTempLabelId        TRecordId,
          @vSourceTempLabelDetailId  TRecordId,
          @vTDQuantity               TQuantity,
          @vTDInnerpacks             TInnerpacks,
          @vUnitsPerPackage          TInteger,

          @vNewFromLPNDetailId       TRecordId,
          @vNewTempLabelDetailId     TRecordId;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @NewLineIPs   = coalesce(@NewLineIPs, 0),
         @NewLineQty   = coalesce(@NewLineQty, 0);

  /* Get Task detail info to split */
  select @vSourceTaskId            = TaskId,
         @vSourceTaskDetailId      = TaskDetailId,
         @vSourceLPNId             = LPNId,
         @vSourceLPNDetailId       = LPNDetailId,
         @vSourceTempLabelId       = TempLabelId,
         @vSourceTempLabelDetailId = TempLabelDetailId,
         @vSourceOrderId           = OrderId,
         @vSourceOrderDetailId     = OrderDetailId,
         @vTDQuantity              = Quantity,
         @vTDInnerPacks            = Innerpacks
  from TaskDetails
  where (TaskDetailId = @TaskDetailId);

  /* If splitting a innerpack task detail then compute innerpacks if not provided */
  if (@vTDInnerpacks > 0) and (@NewLineQty > 0) and (@NewLineIPs = 0)
    begin
      set @vUnitsPerPackage = @vTDQuantity / @vTDInnerpacks;

      set @NewLineIPs = @NewLineQty / @vUnitsPerPackage;
    end

  /* Validations */
  if (@vSourceTaskDetailId is null)
    set @vMessageName = 'InvalidTaskDetail';
  else
  if (@vTDQuantity < @NewLineQty) or (@vTDInnerpacks < @NewLineIPs)
    set @vMessageName = 'SplitQtyMoreThanTDQty';
  else
  if (@NewLineIPs > 0) and (@NewLineQty % @vUnitsPerPackage <> 0)
    set @vMessageName = 'SplitQtyShouldBeInMultiplesOfIP';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If the task is allocated then split Allocated LPN detail */
  /* If caller is confirm picks procedure then we don't need to split from LPN Detail, as from LPN quantity will be adjusted down */
  if (@vSourceLPNDetailId is not null) and (coalesce(@Operation, '') <> 'ConfirmPicks')
    begin
      /* Split From LPN detail line - will take care of inserting new line and reducing units from source ToLPN detail as well */
      exec pr_LPNDetails_SplitLine @vSourceLPNDetailId, @NewLineIPs, @NewLineQty,
                                   @vSourceOrderId, @vSourceOrderDetailId,
                                   @vNewFromLPNDetailId output;

      /* Recount allocated LPN */
      exec pr_LPNs_Recount @vSourceLPNId;
    end

  /* If the task has temp label generated then split detail in temp label */
  if (@vSourceTempLabelDetailId is not null)
    begin
      /* Split From LPN detail line - will take care of inserting new line and reducing units from source ToLPN detail as well */
      exec pr_LPNDetails_SplitLine @vSourceTempLabelDetailId, @NewLineIPs, @NewLineQty,
                                   @vSourceOrderId, @vSourceOrderDetailId,
                                   @vNewTempLabelDetailId output;

      /* Recount Temp Label */
      exec pr_LPNs_Recount @vSourceTempLabelId;
    end

  /* Insert New task detail taking details from Source task detail.
     Take care in inserting NewPicklnaneLPNDetailId, NewLineIPs & NewLineQty for new reocord */
  insert into TaskDetails(TaskId, PickType, Status, WaveId, PickBatchNo, OrderId, OrderDetailId, SKUId, InnerPacks, Quantity,
                          LPNId, LPNDetailId, LocationId, DestZone, DestLocation, PickZone, IsLabelGenerated,
                          TempLabelId, TempLabel, TempLabelDetailId, PackingGroup, PickPosition, PickSequence,
                          TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5, DependencyFlags,
                          UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, BusinessUnit, CreatedBy)
  select TaskId, PickType, Status, WaveId, PickBatchNo, OrderId, OrderDetailId, SKUId, @NewLineIPs, @NewLineQty,
         LPNId, coalesce(@vNewFromLPNDetailId, LPNDetailId), LocationId, DestZone, DestLocation, PickZone, IsLabelGenerated,
         TempLabelId, TempLabel, @vNewTempLabelDetailId, PackingGroup, PickPosition, PickSequence,
         TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5, DependencyFlags,
         UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, @BusinessUnit, @UserId
  from TaskDetails
  where (TaskDetailId = @vSourceTaskDetailId);

  select @NewTaskDetailId = Scope_Identity();

  /* If the source task detail exists in LPN tasks, then insert new task detail into LPN Tasks table */
  if exists (select * from LPNTasks where TaskDetailId = @vSourceTaskDetailId)
    insert into LPNTasks (PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId, LPNDetailId, BusinessUnit)
    select WaveId, PickBatchNo, TaskId, @NewTaskDetailId, TempLabelId, @vNewTempLabelDetailId, @BusinessUnit
    from TaskDetails
    where (TaskDetailId = @vSourceTaskDetailId);

  /* Reduce Quantities on task detail */
  update TaskDetails
  set Quantity   -= @NewLineQty,
      InnerPacks -= @NewLineIPs
  where (TaskDetailId = @vSourceTaskDetailId);

  /* Recount the Task */
  exec pr_Tasks_ReCount @vSourceTaskId;

  /* Recount the Wave */
  exec pr_PickBatch_UpdateCounts @vWaveNo, 'T' /* T - Tasks (Options) */;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));

end /* pr_TaskDetails_SplitDetail */

Go
