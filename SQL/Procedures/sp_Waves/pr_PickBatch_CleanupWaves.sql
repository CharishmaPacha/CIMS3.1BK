/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_CleanupWaves') is not null
  drop Procedure pr_PickBatch_CleanupWaves;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_CleanupWaves: For a given Batch/Wave, if Batch/Wave is completed 100% picks,
    then remove all Orders, which do not have any picks on the Wave, and set them back to downloaded and
    for preprocessing.

    If Batch/Wave is null, it will loop through all unarchived Waves pertaining to particualar status of waves
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_CleanupWaves
  (@PickBatchNo   TPickBatchNo,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @ReturnCode       TInteger,

          @vRecordId        TRecordId,
          @vOrderRecordId   TRecordId,
          @vValidWaveStatusesToProcess TStatus,

          @vPickBatchNo     TPickBatchNo,
          @vOrderId         TRecordId,
          @vOrderTasksCount TCount;

  declare @ttWaves        TEntityKeysTable,
          @ttOrdersOnWave TEntityKeysTable;

begin
  select @vRecordId = 0;

  /* > If Wave given, validate if 100% picks done or not. If 100% picks completed, continue process otherwise skip.
     > (or) Get all the Waves which are 100% picks completed and not archived
     > Loop through all Waves and remove orders, which do not have any open/completed picks (Other than canceled picks)
     > If any orders removed (use @@rowcount or some counter) from any wave, recount Wave with all options (TLO??)
     > Any AT required as RemoveOrders should have been doing it already ??
  */

  select @vValidWaveStatusesToProcess = dbo.fn_Controls_GetAsString('PickBatch_UnWaveOrder', 'ValidWaveStatuses', 'RPUKACGO' /* ReadyToPick to Loaded */,
                                                                    @BusinessUnit, @UserId);

  /* Collect given wave or all waves which are not archived with 100% picks completed */
  insert into @ttWaves(EntityId, EntityKey)
    select RecordId, BatchNo
    from PickBatches
    where (charindex(Status, @vValidWaveStatusesToProcess) > 0) and
          (BatchNo = coalesce(@PickBatchNo, BatchNo)) and
          (Archived = 'N') and
          (BatchType not in ('RU'));

  /* Delete from the list the Waves which have open tasks */
  delete @ttWaves
  from @ttWaves PB join TaskDetails TD on (PB.EntityKey = TD.PickBatchNo) and (TD.Status not in ('C', 'X'));

  /* Loop through all waves */
  while (exists(select * from @ttWaves where RecordId > @vRecordId))
    begin
      select top 1
             @vPickBatchNo = EntityKey,
             @vRecordId    = RecordId
      from @ttWaves
      where (RecordId > @vRecordId)
      order by RecordId;

      delete from @ttOrdersOnWave;

      /* If there are no units on the Order, then unwave it */
      insert into @ttOrdersOnWave(EntityId, EntityKey)
        select OrderId, PickTicket
        from OrderHeaders
        where (PickBatchNo = @vPickBatchNo) and
              (UnitsAssigned = 0) and (LPNsAssigned = 0);

      select @vOrderRecordId = 0;

      /* Loop through all orders on the wave */
      while (exists(select * from @ttOrdersOnWave where RecordId > @vOrderRecordId))
        begin
          select top 1
                 @vOrderId       = EntityId,
                 @vOrderRecordId = RecordId
          from @ttOrdersOnwave
          where RecordId > @vOrderRecordId
          order by RecordId;

          exec pr_PickBatch_RemoveOrder @vPickBatchNo,
                                        @vOrderId,
                                        'Y'  /* CancelBatchIfEmpty */,
                                        'OH' /* BatchingLevel */,
                                        @BusinessUnit,
                                        @UserId;

          /* Anymore updates on order ?? set back to Downloaded (O) and PreprocessFlag (N) and WaveFlag?? */
          update OrderHeaders
          set Status         = 'O' /* Downloaded */,
              PreprocessFlag = 'N' /* No, process now */,
              WaveFlag       = replace(WaveFlag, 'R', '')  /* pr_PickBatch_RemoveOrder sets to 'R' (Removed from wave, so do not automatically wave again)
                                      So reset back. */
          where OrderId = @vOrderId;
        end /* process next order */

      /* Recount Wave to calculate counts and status*/
      exec pr_PickBatch_UpdateCounts @PickBatchNo, 'O' /* Recalculate orders */
    end /* process next wave */

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_CleanupWaves */

Go
