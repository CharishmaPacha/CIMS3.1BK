/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/20  VS      pr_PickBatch_ReAllocateBatches: Changes migrated from S2GCA (HA-988)
  2018/08/07  TK      pr_PickBatch_ReAllocateBatches: Changes to revert UATS to original UATS (S2GCA-Support)
  2018/05/11  OK      pr_PickBatch_ReAllocateBatches: Enhanced to reallocate the inventory based on control var (S2G-581)
  2018/04/11  OK      pr_PickBatch_ReAllocateBatches: Enhanced to reallocate the inventory based on control var (S2G-581)
  2017/08/17  RV      pr_Allocation_AllocateWave, pr_PickBatch_ReAllocateBatches: Made changes to not allocate waves manually
  2015/02/23  TK      pr_PickBatch_ReAllocateBatches: Need to update Allocate Flags to 'Y' on clicking Re-Allocate Batch action.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_ReAllocateBatches') is not null
  drop Procedure pr_PickBatch_ReAllocateBatches;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_ReAllocateBatches: Reallocate the batches specified in the
    input table param.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_ReAllocateBatches
  (@PickBatches      TEntityKeysTable ReadOnly,
   @UserId           TUserId,
   @BusinessUnit     TBusinessUnit,
   @BatchesUpdated   TCount output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vRecordId            TRecordId,
          @vPickBatchId         TRecordId,
          @vBatchNo             TPickBatchNo,
          @vBatchType           TTypeCode,
          @ttPickBatches        TEntityKeysTable,
          @vBatchesUpdated      TCount,
          @vModifiedDate        TDateTime,
          @vAuditRecordId       TRecordId,
          @vCreateBPT           TFlag,
          @vExportSrtrDetails   TControlValue,
          @vAllocateInventory   TControlValue;

declare @ttBatchControls table (BatchType    TTypeCode,
                                CreateBPT    TFlag)
begin
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* insert controls into temp table */
  insert into @ttBatchControls(BatchType, CreateBPT)
    select ControlCode, ControlValue
    from dbo.fn_Controls_GetControls('PB_CreateBPT', @BusinessUnit);

  /* insert the given data into temp table and exclude the waves which already allocation is in progress */
  insert into @ttPickBatches(EntityId, EntityKey)
    select PB.RecordId,
           Entitykey
    from @PickBatches  TPB
    join PickBatches PB on (TPB.EntityKey = PB.BatchNo) and
                             (PB.Status        <> 'N' /* New */) and
                             (PB.AllocateFlags <> 'I' /* InProgress */);

  /* Get the count of batches to reallocate */
  select @BatchesUpdated  = @@rowcount;

  /* Loop thru all the selected batches */
  while (exists (select *
                 from @ttPickBatches where RecordId > @vRecordId))
    begin
      select @vBatchNo    = null,
             @vPickBatchId = null;

      /* select Top 1 BatchNo from temp table */
      select Top 1 @vBatchNo  = EntityKey,
                   @vRecordId = RecordId
      from @ttPickBatches
      where (RecordId > @vRecordId)
      order by RecordId;

      /* SelectPickBatch Id */
      select @vPickBatchId = PB.RecordId,
             @vBatchType   = PB.BatchType,
             @vCreateBPT   = BC.CreateBPT
      from PickBatches PB
        left outer join @ttBatchControls BC on (BC.BatchType = PB.BatchType)
      where (BatchNo = @vBatchNo);

      /* Get the control variable */
      select @vExportSrtrDetails = dbo.fn_Controls_GetAsString('Sorter', 'ExportWaveDetails_' +@vBatchType, 'Y', @BusinessUnit, null /* UserId */),
             @vAllocateInventory = dbo.fn_Controls_GetAsString('PickBatch_' +@vBatchType, 'AllocateOnReallocate', 'J' /* By Job */,  @BusinessUnit, null /* UserId */);

     /* For Replenish waves, if nothing is allocated then we will update UnitsAuthorizedToShip with UnitsAssigned so on
        reallocate we need to update UATS back to Original UATS */
     /* For ReplenishWave we will do over allocation so when we reallocate the Wave we are trying update UnitsAssigned value with OrigUnitsAuthourzedToShip
        and update will be failed in this case so we added below condition
         where (OD.UnitsAssigned < OD.UnitsAuthorizedToShip) */
     if (@vBatchType in ('R', 'RU', 'RP'/* Replenish */))
       update OD
       set OD.UnitsAuthorizedToShip = OD.OrigUnitsAuthorizedToShip
       from OrderDetails OD
         join OrderHeaders OH on (OD.OrderId = OH.OrderId)
       where (OH.PickBatchId = @vPickBatchId) and
             (OD.UnitsAssigned < OD.OrigUnitsAuthorizedToShip);

      /* Update the AllocateFlags to Yes, so that it will allocate through job or below statement */
      update PickBatches
      set AllocateFlags = 'Y'  /* Yes */
      where (RecordId = @vPickBatchId);

      update PickBatchAttributes
      set IsReplenished = 'N'
      where PickBatchId = @vPickBatchId and
            IsReplenished = 'Y'

      /* If we to allocate immediately upon reallocate, then do so. Otherwise Inventory will get allocate on next job run */
      if (charindex(@vAllocateInventory, 'R' /* ReAllocate */) > 0)
        exec pr_Allocation_AllocateWave @vBatchNo, null /* Operation */, @BusinessUnit, @UserId;

      /* Neither of these are needed to be done on re-allocate.
         After Release - Create BPT and Wave Short Summary are done but those should be done in allocation.
         SetStatus is already handled in AllocateWave */

      -- /* After allocating the inventory insert the allocated inventory into the sorter table
      --    and also create BulkPT */
      -- exec pr_PickBatch_AfterRelease @vPickBatchId, @vBatchNo, @vCreateBPT, @vExportSrtrDetails,
      --                                @BusinessUnit, @UserId;
      --
      -- /* The batch status would have to be reverted if there is new inventory allocated, so call SetStatus */
      -- exec pr_PickBatch_SetStatus @vBatchNo;

      /* Log Audit trail */
      exec pr_AuditTrail_Insert 'PickBatchReAllocation', @UserId, @vModifiedDate,
                                @PickBatchId   = @vPickBatchId,
                                @AuditRecordId = @vAuditRecordId output;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_ReAllocateBatches */

Go

