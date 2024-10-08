/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/20  AY      pr_PickBatch_AfterRelease, pr_PickBatch_RemoveOrders: Send export to host of PT Status change (S2GCA-200)
  2016/07/25  TK      pr_PickBatch_AfterRelease: Do not revert the Wave Status to 'New' if there are no open Picks (HPI-365)
  2015/09/11  PK      pr_PickBatch_AfterRelease: Changes to sent email alerts on wave shorts (FB-380)
  2015/07/15  RV      pr_PickBatch_AfterRelease: Changed condition when revert the batch status as new (FB-253) .
  2014/04/11  PK      pr_PickBatch_ReAllocateBatches: Calling pr_PickBatch_AfterRelease to export the details
  2014/03/04  TD      Added new Proc pr_PickBatch_AfterRelease.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_AfterRelease') is not null
  drop Procedure pr_PickBatch_AfterRelease;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_AfterRelease: This procedure will create a bulk pick ticket and
    will import and export the sorter ave details once the batch is released.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_AfterRelease
  (@PickBatchId     TRecordId,
   @PickBatchNo     TPickBatchNo,
   @ExportSrtData   TFlag = 'N',
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TDescription,
          @vTasksCount              TCount,
          @ttOrdersOnWave           TEntityKeysTable,
          @vOrderId                 TRecordId,
          @vRecordId                TRecordId,
          @vExportStatusToHost      TFlags,
          @vEmailWaveShortsSummary  TFlags;
begin
  select @vRecordId = 0;

  /* Get the control value whether to send email alerts for wave short summary or not */
  select @vEmailWaveShortsSummary = dbo.fn_Controls_GetAsString('WaveAfterRelease', 'EmailWaveShortSummary', 'N' /* No */, @BusinessUnit, @UserId);
  select @vExportStatusToHost     = dbo.fn_Controls_GetAsString('WaveAfterRelease', 'ExportStatusToHost', 'N' /* No */, @BusinessUnit, @UserId);

  -- /* if we need to create a bulk PickTicket for this batch then we need to call
  --    create bulk PickTicket */
  -- if (@CreateBPT = 'Y' /* Yes */)
  --   exec pr_Allocation_CreateConsolidatedPT @PickBatchId, 'AR' /* Operation - After Release */,
  --                                          @BusinessUnit, @UserId;

  if (@ExportSrtData = 'O' /* On release */)
    begin
      /* insert data into our local staging tables */
      --exec pr_Sorter_InsertWaveDetails @PickBatchId, null /* Sorter Name */,
      --                                 @BusinessUnit, @UserId;

      /* insert data into WCS staging tables */
   --   exec pr_Sorter_ExportWaveDetails @PickBatchId, null /* Sorter Name */,
   --                                    @BusinessUnit, @UserId;

      /* Update pickBatch details here */
      update PickBatchDetails
      set Status = 'E' /* Exported */
      where PickBatchId = @PickBatchId;
    end

  /* Export status of the Orders to Host, if control var says so */
  if (@vExportStatusToHost = 'Y'/* Yes */)
    insert into @ttOrdersOnWave (EntityId, EntityKey)
      select OrderId, PickTicket from OrderHeaders where (PickBatchId = @PickBatchId)

  while exists (select * from @ttOrdersOnWave where RecordId > @vRecordId)
    begin
      select top 1 @vOrderId  = EntityId,
                   @vRecordId = RecordId
      from @ttOrdersOnWave
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Send PT Status update to Host that Order is on Released Wave */
      exec pr_Exports_OrderData 'PTStatus', @vOrderId, null /* OrderDetailid */, null /* LoadId */,
                                @BusinessUnit, @UserId, 140 /* Wave Released */;
    end

  /* Don't know why we are doing this and it is not necessary to revert the Status from 'Ready To Pick' to 'New' if there are no Tasks created */
  --set @vTasksCount = 0;

  --/* Get the tasks count except Cancelled */
  --select @vTasksCount = count(*)
  --from Tasks
  --where (BatchNo = @PickBatchNo) and (Status <> 'X' /* Cancelled */);

  --/* If there is no Inventory then no tasks will create, so if there is no tasks
  --   created for the batch then we have to revert the batch status as new. */
  --if (@vTasksCount = 0)
  --  begin
  --    update PickBatches
  --    set status = 'N' /* New */
  --    where (RecordId = @PickBatchId) and
  --          (AllocateFlags = 'N' /* Already allocated */) and
  --          (Status in ('R' /* Released */));
  --  end

  -- /* Email Wave Shorts report */
  -- if (@vEmailWaveShortsSummary = 'Y'/* Yes */)
  --   exec pr_Alerts_WaveShortsSummary @PickBatchNo, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_AfterRelease */

Go
