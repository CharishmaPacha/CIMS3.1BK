/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/04  VS      pr_RFC_Picking_PauseBatch: Clear the Pallet Status When we Pause the Batch (HA-1683)
  2020/06/18  RKC     pr_RFC_Picking_PauseBatch:Changes does not allow to clear pallet infroamtion on the task,if user nothing has been picked
                         to the pallet/cart and pause the cart (HA-816)
  2019/05/29  AY      pr_RFC_Picking_PauseBatch: Fix for unable to pause batch on subsequent tasks without picking
  2019/04/26  VS      pr_RFC_Picking_PauseBatch: When Task is in canceled status do not change the status pause the batch (S2GCA-623)
  2018/07/13  RV      pr_RFC_Picking_PauseBatch: Corrected Pallet tag to sync between RF and SQL to get the proper Pallet info (S2G-1036)
  2018/05/20  TK      pr_RFC_Picking_PauseBatch: Changes to accept xml inputs (S2G-840)
  2018/04/27  AY      pr_RFC_Picking_PauseBatch: Reset Pallet back to Empty when nothing is picked to it (S2G-729)
  2018/04/17  TK      pr_RFC_Picking_ConfirmBatchPick: Changes to evaluate UnitsPicked based upon PickUoM
                      pr_RFC_Picking_PauseBatch: Several fixes to clear pallet info (S2G-662)
  2017/02/20  TK      pr_RFC_Picking_ValidatePallet: Validate whether the task is associated with pallet or not if atleast one pick is completed (HPI-1369)
                      pr_RFC_Picking_PauseBatch: Bug fix in evaluating Pallet qty  (HPI-1369)
  2015/11/02  OK      pr_RFC_Picking_PauseBatch: set the pallet status based on the passing pallet (FB-450)
  2015/09/21  TK      pr_RFC_Picking_PauseBatch: Return Pallet status also (ACME-319)
  2014/02/14  PK      pr_RFC_Picking_PauseBatch: Fixed the issue of updating TaskDetail status.
  2013/12/16  TD      pr_RFC_Picking_PauseBatch:Changes to leave the batch status as Picked if the user trying to pause the
                        batch which is already in picked status.
                      pr_RFC_Picking_PauseBatch: Fix in reverting the TaskDetails, Pallet and Task status.
  2103/10/28  TD      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_PauseBatch: Changes to pick multiple uses at a time for the same
                      pr_RFC_Picking_PauseBatch: Validating the Batch status based on the control variable.
                      pr_RFC_Picking_PauseBatch: Allowing to Pause if the Batch Status is in Being Pulled as well, and
              VM      pr_RFC_Picking_PauseBatch: Use coalesce as there is no PalletId on batch when assigned user quits.
  2012/01/04  YA      pr_RFC_Picking_PauseBatch: Added Condition to check whether Batch is already assigned to that pallet.
  2011/11/07  YA      pr_RFC_Picking_PauseBatch : Modified procedure to set status for cancelling pick by checking the qty.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_PauseBatch') is not null
  drop Procedure pr_RFC_Picking_PauseBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_PauseBatch: this proc will update the status with 'U'(Paused)
   in pickbatches for the given batch no..)
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_PauseBatch
  (@xmlInput             xml,
   @xmlResult            xml  output)
as
  declare @ReturnCode               TInteger,
          @MessageName              TMessageName,
          @Message                  TDescription,

          @DeviceId                 TDeviceId,
          @UserId                   TUserId,
          @BusinessUnit             TBusinessUnit,
          @BatchNo                  TPickBatchNo,
          @Pallet                   TPallet,
          @TaskId                   TRecordId,
          @TaskDetailId             TRecordId,

          @xmlResultvar             TVarchar,
          @ConfirmPauseBatchMessage TMessageName,
          @vWaveStatus              TStatus,
          @vPickBatchId             TRecordId,
          @NewBatchStatus           TStatus,
          @NewPalletStatus          TStatus,
          @vUnitsAssigned           TQuantity,
          @vPalletId                TRecordId,
          @vBatchPalletId           TRecordId,
          @vValidWaveStatuses       TStatus,
          @vIsBatchAllocated        TDescription,
          @vTaskId                  TRecordId,
          @vTaskStatus              TStatus,
          @vTaskDetailId            TRecordId,
          @vTaskDetailStatus        TStatus,
          @vPalletQuantity          TQuantity,
          @vPalletStatus            TStatus,
          @vActivityLogId           TRecordId;

begin /* pr_RFC_Picking_PauseBatch */
begin try
  SET NOCOUNT ON;

  if (@xmlInput is not null)
    select @DeviceId     = Record.Col.value('DeviceId[1]',       'TDeviceId'),
           @UserId       = Record.Col.value('UserId[1]',         'TUserId'),
           @BusinessUnit = Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'),
           @BatchNo      = Record.Col.value('PickBatchNo[1]',    'TPickBatchNo'),
           @Pallet       = Record.Col.value('Pallet[1]',         'TPallet'),
           @TaskId       = Record.Col.value('TaskId[1]',         'TRecordId'),
           @TaskDetailId = Record.Col.value('TaskDetailId[1]',   'TRecordId')
    from @xmlInput.nodes('ConfirmBatchPause') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @Pallet, 'TaskId-Pallet',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction

  select @vPickBatchId      = RecordId,
         @vWaveStatus       = Status,
         @vBatchPalletId    = PalletId,
         @vIsBatchAllocated = IsAllocated
  from PickBatches
  where (BatchNo = @BatchNo);

  select @vPalletId = PalletId
         /* we cannot consider Pallet Qty, suppose if the temp LPNs are built onto
            pallet then we then pallet qty will be greater than zero */
        -- @vPalletQuantity = coalesce(Quantity, 0)
  from Pallets
  where Pallet = @Pallet;

  /* compute Pallet qty - have to fetch from LPNDetails as some lines may be reserved and some
     unavailable as we go thru the picking process */
  select @vPalletQuantity = sum(LD.Quantity)
  from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
  where (L.PalletId = @vPalletId) and
        (LD.OnhandStatus <> 'U' /* Un-Available */);

  /* Get taskId here for the given pallet */
  select @vTaskId           = TaskId,
         @vTaskDetailId     = TaskDetailId,
         @vTaskDetailStatus = Status
  from TaskDetails
  where (TaskDetailId = @TaskDetailId);

  /* Get the Task Status */
  select @vTaskStatus = Status
  from Tasks
  where (TaskId = @TaskId);

  /* select the valid Batch Statuses */
  select @vValidWaveStatuses = dbo.fn_Controls_GetAsString('BatchPicking', 'ValidBatchStatusToPause', 'PEKR'/* Picking, Being Pulled, Picked, ReadyToPick */, @BusinessUnit, @UserId);

  /*If the given pallet is not associated with the pallet on batch, it clears the pallet status and stops picking */
  if (coalesce(@vPalletQuantity, 0) = 0)
    exec pr_Pallets_SetStatus @vPalletId, 'E' /* Empty */, @UserId;

  /* When Task is picking inprogress at that time task is in canceled status no need to change the Task status */
  if (@vTaskStatus = 'X') goto _StopPicking;

  if (@vPickBatchId is null)
    set @MessageName = 'InvalidBatch';
  else
  if (charindex(@vWaveStatus, @vValidWaveStatuses) = 0)
    set @MessageName = 'InvalidStatus';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Determine Status of the batch.
     If any units were picked, then Pause the batch, if nothing was picked yet, revert it back */
  if (@vIsBatchAllocated = 'Y' /* Allocated */)
    begin
      select @vUnitsAssigned = sum(TD.UnitsCompleted)
      from TaskDetails TD
      where (TD.TaskId = @TaskId);
    end
  else
    begin
      select @vUnitsAssigned = sum(UnitsAssigned)
      from vwOrderDetails
      where (PickBatchNo = @BatchNo);
    end

  /* Revert TaskDetails here */
  update TaskDetails
  set Status   = case when (coalesce(UnitsCompleted, 0) = 0) and (@vTaskDetailStatus not in ('X', 'C'/* Cancelled, Completed */)) then 'N' /* Not yet started */ else Status end,
      PalletId = case when (coalesce(UnitsCompleted, 0) = 0) then null else PalletId end
  where (TaskDetailId = @vTaskDetailId);

  /* Updating task and taskDetails here */
  exec pr_Tasks_SetStatus @vTaskId, @UserId, null /* status */ , 'Y' /* recount -Yes */;

  /* When nothing has been picked to the pallet/cart, then revert Task back to Ready to Start. However,
     if the Cart has been built with the Task, then do not do this as the Cart has the cartons and labels
     applied to it */
  if (not exists(select * from LPNs L
                 where L.PalletId = @vPalletId and L.TaskId = @vTaskId and L.Quantity > 0))
    update Tasks
    set PalletId = null,
        Pallet   = null
    where (TaskId = @vTaskId) and
          (Status = 'N'/* Ready To Start */);

  /* Compute the Pallet Status when we Pause the Picking */
  exec pr_Pallets_SetStatus @vPalletId, @vPalletStatus output, @UserId;

  /* Update status of the Wave as the Wave not be in Picking anymore */
  exec pr_PickBatch_SetStatus @BatchNo, '$';

_StopPicking:
  /* Get Confirmation Message */
  set @ConfirmPauseBatchMessage = dbo.fn_Messages_GetDescription('BatchPausedSuccesfully');

  /* XmlMessage to RF, after Pallet is dropped to a Location */
  set @xmlResult = (select 0                         as ErrorNumber,
                           @ConfirmPauseBatchMessage as ErrorMessage,
                           @vUnitsAssigned           as UnitsPicked,
                           @vPalletStatus            as PalletStatus
                    FOR XML RAW('BATCHPAUSEINFO'), TYPE, ELEMENTS XSINIL, ROOT('BATCHPAUSEDETAILS'));

  /* Update Device details */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'PausedCurrentBatch', @xmlResultvar, @@ProcId;

  exec pr_AuditTrail_Insert 'PauseBatchPick', @UserId, null /* ActivityTimestamp */,
                            @PickBatchId = @vPickBatchId,
                            @PalletId    = @vPalletId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vTaskId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vTaskId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_PauseBatch */

Go
