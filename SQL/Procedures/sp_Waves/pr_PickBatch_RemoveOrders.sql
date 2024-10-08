/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/18  VS      pr_PickBatch_Cancel, pr_PickBatch_Modify, pr_PickBatch_RemoveOrder, pr_PickBatch_RemoveOrders,
  2021/05/05  TK      pr_PickBatch_RemoveOrders: Do not remove orders from wave if allocation is in progress (HA-2746)
  2021/03/27  TK      pr_PickBatch_RemoveOrders: Changes to reduce quantity on bulk order
  2021/03/23  RV      pr_PickBatch_RemoveOrders: Made changes to unallocate the picked LPN, which doesn't have picks (HA-2375)
  2021/03/21  RKC     pr_PickBatch_RemoveOrders: Made changes does not allow user to remove orders from other then New status waves (HA-2368)
  2018/08/20  AY      pr_PickBatch_AfterRelease, pr_PickBatch_RemoveOrders: Send export to host of PT Status change (S2GCA-200)
  2018/06/07  VM      pr_PickBatch_Cancel, pr_PickBatch_RemoveOrders: set BatchingLevel to be EnforceBatchingLevel when retreived from controls (S2G-914)
  2018/03/30  TK      pr_PickBatch_RemoveOrders: Allow removing orders from wave even if there are open tasks (S2G-530)
  2015/10/25  NY      pr_PickBatch_RemoveOrders: Added  control var Remove_Order to remove the orders(LL-235)
  2015/05/21  TK      pr_PickBatch_RemoveOrders: We always needs to Cancel TaskDetails instead of cancelling task,
  2015/01/28  TK      pr_PickBatch_RemoveOrders: remove orders from PickBatch which started picking
  2014/07/29  TK      pr_PickBatch_RemoveOrders: Updated to clear Wave number on Orders.
  2014/07/24  TK      pr_PickBatch_RemoveOrders: Added new temp table to insert distinct values into @ttOrdersToUpdate.
  2014/06/10  VM      pr_PickBatch_RemoveOrders: Set the batch status to 'New' if all orders are removed and CancelBatch is No
  pr_PickBatch_RemoveOrders: Sending Order details to the sorter once after the order is removed
  2014/01/21  TD      pr_PickBatch_RemoveOrders: Changes to log audit trail while removing orders from batch.
  2013/11/22  NY      pr_PickBatch_RemoveOrders:Logging AT for each order removal.
  2013/10/23  TD      pr_PickBatch_RemoveOrders:Looping all orders to set status.
  2012/11/20  TD      pr_PickBatch_RemoveOrders: Implemented cancel batch functionality based on
  2012/10/03  PKS     pr_PickBatch_RemoveOrders: AuditEntity changed to PickTicket from Order
  2012/06/30  SP      Placed the transaction controls in 'pr_PickBatch_Modify' and 'pr_PickBatch_RemoveOrders'.
  2012/05/29  PKS     pr_PickBatch_RemoveOrders: Changes migrated from FH.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_RemoveOrders') is not null
  drop Procedure pr_PickBatch_RemoveOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_RemoveOrders: Procedure to remove an entire Order or some
    OrderDetails from a Batch. Note that an Order could be on multiple batches,
    so it only removes the details from the given batch.

  Validations;
    Do not allow Orders/OrderDetails to be removed form Released Waves
      except with special permissions
    Do not allow removal if there are ship cartons which are not canceled

  Sample XML for @Orders.
  <Orders xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <OrderHeader>
      <OrderId>862</OrderId>
    </OrderHeader>
    <OrderHeader>
      <OrderId>863</OrderId>
    </OrderHeader>
    .....
    .....
  </Orders>
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_RemoveOrders
  (@WaveNo             TWaveNo,
   @Orders             TXML,
   @CancelWaveIfEmpty  TFlag,
   @WavingLevel        TDescription,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Operation          TOperation)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,

          @vOrderId                    TRecordId,
          @vOrderDetailId              TRecordId,
          @vQuantity                   TCount,
          @vNumOrders                  TCount,
          @vOrders                     XML,
          /* Wave info */
          @vWaveId                     TRecordId,
          @vWaveType                   TTypeCode,
          @vWaveStatus                 TStatus,
          @IsWaveAllocated             TFlag,
          @vWaveAllocateFlag           TFlags,
          @vNumOrdersRemoved           TCount,
          /* Audit info */
          @vAuditRecordId              TRecordId,
          @vModifiedDate               TDateTime,
          @vAuditActivity              TActivityType,
          @vWavingLevel                TDescription,
          @vEnforceWavingLevel         TDescription,
          @vValidWaveStatusesToRemove  TControlValue,
          @vControlCategory            TCategory,
          @vSorterIntegration          TControlValue,
          @vCancelWaveIfEmpty          TControlValue,
          @vExportStatusOnUnWave       TControlValue,
          @vValue1                     TDescription,
          @vValue2                     TDescription,
          @vValue3                     TDescription;

  declare @ttOrders                    TEntityKeysTable,
          @ttTasks                     TEntityKeysTable,
          @ttOrdersUnWaved             TOrderDetails,
          @ttOrdersToUpdate            TEntityKeysTable,
          @ttDeletedDetails            TEntityKeysTable,
          @ttLPNDetailsToUnallocate    TEntityKeysTable;
begin
begin try
  begin transaction;
  select @vOrders      = convert(xml, @Orders),
         @vWavingLevel = @WavingLevel;

  /* Create required hash tables */
  select * into #OrdersUnWaved from @ttOrdersUnWaved;

  /* If user does not provide any input then we need to get it from controls */
  if (coalesce(@WavingLevel, '') = '')
    begin
      /* Get batching level from controls here */
      select @WavingLevel         = dbo.fn_Controls_GetAsString('GenerateBatches', 'BatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */),
             @vEnforceWavingLevel = dbo.fn_Controls_GetAsString('GenerateBatches', 'EnforceBatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */);

      /* If EnforceWavingLevel is defined, it should be the final WavingLevel */
      if (coalesce(@vEnforceWavingLevel, '') <> '')
        select @vWavingLevel = @vEnforceWavingLevel;
    end

  /* Get Wave info.. */
  select @vWaveType         = BatchType,
         @vWaveStatus       = Status,
         @vWaveId           = RecordId,
         @IsWaveAllocated   = IsAllocated,
         @vWaveAllocateFlag = AllocateFlags
  from Waves
  where (WaveNo = @WaveNo) and (BusinessUnit = @BusinessUnit);

  select @vControlCategory = 'PickBatch_' + @vWaveType;

  select @vSorterIntegration         = dbo.fn_Controls_GetAsString(@vControlCategory, 'SorterIntegration', 'N' /* No */, @BusinessUnit, null /* UserId */),
         @vValidWaveStatusesToRemove = dbo.fn_Controls_GetAsString('Wave_RemoveOrder', 'ValidWaveStatuses', 'NRPUKACS'/* New, ReadyToPick, Picking,
                                                                        Paused, Picked, Packing, Packed, Staged */, @BusinessUnit, null/* UserId */),
         @vCancelWaveIfEmpty         = dbo.fn_Controls_GetAsString(@vControlCategory, 'CancelBatchIfEmpty', 'N' /* No */, @BusinessUnit, null /* UserId */),
         @vExportStatusOnUnWave      = dbo.fn_Controls_GetAsString(@vControlCategory, 'ExportStatusOnUnwave', 'N' /* No */, @BusinessUnit, null /* UserId */);

  if (@vWavingLevel = 'OH')
    begin
      insert into @ttOrders(EntityId)
        select distinct Record.Col.value('(OrderId/text())[1]',  'TRecordId')
        from @vOrders.nodes('Orders/OrderHeader') as Record(Col);

      /* set activity here for Audit Trail */
      select @vAuditActivity  = 'PickBatchOrderRemoved';
    end
  else
    begin
      insert into @ttOrders(EntityId)
        select Record.Col.value('(OrderDetailId/text())[1]',       'TRecordId')
        from @vOrders.nodes('Orders/OrderDetails') as Record(Col);

      /* set activity here for Audit Trail */
      select @vAuditActivity  = 'PickBatchRemoveOrderDetails';
    end

  /* Users who have permission to Remove orders can remove orders from new Waves.
     No users can ever Remove orders from other than Valid statuses defined in controls */
  if (@vWaveStatus <> 'N' /* New */) and
     (charindex(@vWaveStatus, @vValidWaveStatusesToRemove) = 0)
    set @vMessageName = 'Wave_RemoveOrders_InvalidWaveStatus';
  else
  if (@vWaveAllocateFlag = 'I' /* InProgress */)  and (coalesce(@Operation, 'Wave_RemoveOrder') <> 'UnWaveDisQualifiedOrders')
    select @vMessageName = 'Wave_RemoveOrders_AllocationInProgress', @vValue2 = @WaveNo;
  else
  /* Even if the Wave status is valid, only users with special permission can remove orders
     from release waves else raise an error */
  if (@vWaveStatus <> 'N' /* New */) and (coalesce(@Operation, 'Wave_RemoveOrder') <> 'UnWaveDisQualifiedOrders') and
     (charindex(@vWaveStatus, @vValidWaveStatusesToRemove) <> 0) and -- this condition for readbility as it is already checked above
     (dbo.fn_Permissions_IsAllowed(@UserId, 'Waves.Pri.RemoveOrdersFromReleasedWave') <> '1')
    set @vMessageName = 'Wave_RemoveOrders_WaveAlreadyReleased';
  else
  /* Even if user is trying to remove orders from a wave, no matter what the status of the wave is
     we have to ensure that the user has canceled the ship cartons first */
  if (@vWavingLevel = 'OH') and
     (exists (select * from @ttOrders ttO join LPNs L on ttO.EntityId = L.OrderId
              where L.status = 'F' /* New Temp */))
    set @vMessageName = 'Wave_RemoveOrders_CancelShipCartons';
  else
  /* Even if user is trying to remove orders form a wave, no matter what the status of the wave is
     we have to ensure that the user has canceled the ship cartons first */
  if (@vWavingLevel = 'OD') and
     (exists (select * from @ttOrders ttO
              join OrderDetails OD on ttO.EntityId = OD.OrderDetailId
              join LPNDetails LD on (OD.OrderId = LD.OrderId) and (OD.OrderDetailId = OD.OrderDetailId)
              join LPNs L on LD.LPNId = L.LPNId
              where (L.status = 'F' /* New Temp */)))
    set @vMessageName = 'Wave_RemoveOrders_CancelShipCartons';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If there are any open tasks for any of the Orders then don't UnWave/Remove them */
  /* We are canceling open tasks below, so this is not required, if we don't want to allow
     user to remove order if there are any open tasks than this needs to handeled properly */
 -- delete ttO
 -- from @ttOrders ttO
 --   join TaskDetails TD on (ttO.EntityId = TD.OrderId)
 -- where TD.Status not in ('X', 'C' /* Canceled, Completed */)

  /* Delete details from PickBatchDetails based on batching Level */
  if (@vWavingLevel = 'OH' /* Order Header */)
    begin
      delete from PickBatchDetails
      output Deleted.OrderId, Deleted.OrderDetailId
      into @ttDeletedDetails(EntityId, EntityKey)
      where (OrderId in (select EntityId from @ttOrders) and
            (PickBatchNo = @WaveNo));

      /* Insert distinct deleted OrderId(s) into @ttOrdersToUpdate */
      insert into @ttOrdersToUpdate(EntityId)
        select distinct EntityId from @ttDeletedDetails;

      insert into #OrdersUnWaved (OrderId, WaveId) select EntityId, @vWaveId from @ttOrdersToUpdate;
    end
  else
    begin
      delete from PickBatchDetails
      output Deleted.OrderDetailId into @ttOrdersToUpdate(EntityId)
      where (OrderDetailId in (select EntityId from @ttOrders) and
            (PickBatchNo = @WaveNo));
    end

  /* Void Temp labels */
  exec pr_OrderHeaders_VoidTempLabels @ttOrdersToUpdate, 'UnwaveOrders', @BusinessUnit, @UserId;

  /* Note: We are not unallocating the already picked LPN, which doesn't have picks, So need to un allocate them */
  insert into @ttLPNDetailsToUnallocate
    select LPNId, LPNDetailId
    from @ttOrders OH
      join LPNDetails LD on (OH.EntityId = LD.OrderId);

  exec pr_LPNDetails_UnallocateMultiple '' /* Operation */,
                                        @ttLPNDetailsToUnallocate,
                                        null /* @LPNId */,
                                        null /* @LPNDetailId */, @BusinessUnit, @UserId;

  /* begin loop to call Order set status  */
  while (exists (select * from @ttOrdersToUpdate))
    begin
      select @vOrderDetailId = null,
             @vOrderId       = null;

      if (@vWavingLevel = 'OD' /* OrderDetail */)
        begin
          /* select the top 1 order detail here  */
          select top 1 @vOrderDetailId = EntityId
          from @ttOrdersToUpdate;

          select @vOrderId  = OrderId,
                 @vQuantity = UnitsOrdered
          from OrderDetails
          where OrderDetailId = @vOrderDetailId;

          /* Remove the order info from sorter table */
          if (@vSorterIntegration = 'Y'/* Yes */)
            exec pr_Sorter_DeleteWaveDetails @vWaveId, @vOrderId, @vOrderDetailId,
                                             @BusinessUnit, @UserId;
        end
      else
        begin   /* if batching level is Order Headers then get Orderid here */
          /* select Order here  */
          select top 1 @vOrderId = EntityId
          from @ttOrdersToUpdate;

          /* Remove the order info from sorter table */
          if (@vSorterIntegration = 'Y'/* Yes */)
            exec pr_Sorter_DeleteWaveDetails @vWaveId, @vOrderId, null /* OrderDetailId */,
                                             @BusinessUnit, @UserId;

          /* Remove Batch Number on the order */
          update OrderHeaders
          set PrevWaveNo  = PickBatchNo,
              PickBatchId = null,
              PickBatchNo = null,
              WaveFlag    = 'R' /* Removed from wave, so do not automatically wave again */
          where (OrderId = @vOrderId);

          /* Send PT Status update to Host that Order is unwaved */
          if (@vExportStatusOnUnWave = 'Y' /* Yes */)
            exec pr_Exports_OrderData 'PTStatus', @vOrderId, null /* OrderDetailid */, null /* LoadId */,
                                      @BusinessUnit, @UserId, 141 /* Order Unwaved */;
        end

      /* Call Order set status */
      if (@vOrderId is not null)
        exec pr_OrderHeaders_SetStatus @vOrderId, 'N' /* Status */, @UserId;

      /* Audit Trail */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, @vModifiedDate,
                                @OrderId       = @vOrderId,
                                @OrderDetailId = @vOrderDetailId,
                                @PickBatchId   = @vWaveId,
                                @Quantity      = @vQuantity,
                                @AuditRecordId = @vAuditRecordId output;

      /* delete the Order once after the Order is processed */
      delete from @ttOrdersToUpdate
      where (EntityId = case when @vWavingLevel = 'OH' then @vOrderId else @vOrderDetailId end);
    end

  /* If batch is allocated, then cancel Task Details */
  if (@IsWaveAllocated <> 'N')
    begin
      /* Get all the tasks and details for the pickbatch which are in New status
         We always needs to Cancel TaskDetails instead of cancelling task, Task
         may contain Details of other Orders */
      insert into @ttTasks(EntityId, EntityKey)
        select distinct TD.TaskDetailId, 'TaskDetail'
        from Tasks T
             join  TaskDetails TD on (T.TaskId   = TD.TaskId)
             join  @ttOrders   O  on (O.EntityId = case when @WavingLevel = 'OH' then TD.OrderId else TD.OrderDetailId end)
        where ((T.BatchNo = @WaveNo)  and
               (TD.Status in ('NC', 'O', 'N' /* Not-Categorized, On-Hold, New */)));

      /* Cancel the selected Tasks */
      exec pr_Tasks_Cancel @ttTasks, null /* TaskId */, @WaveNo, @BusinessUnit, @UserId;
    end

  /* Invoke proc to finalize unwave orders */
  exec pr_OrderHeaders_FinalizeUnWave @Businessunit, @UserId;

  /* Update the summary fields and counts on the batch */
  exec pr_PickBatch_UpdateCounts @WaveNo, 'O' /* Summarize Order Info */;

  /* Get the remainging no.of orders on the Wave */
  select @vNumOrders = case when @vWavingLevel = 'OH' then NumOrders else NumLines end
  from Waves
  where (WaveId = @vWaveId);

  /* Cancel the batch if No of orders on batch is zero, and if user confirms to cancel the batch then
     we call pr_PickBatch_Cancel procedure to mark the batch as 'X' (Cancelled) */
  if (coalesce(@vNumOrders, 0) = 0) or ((coalesce(@CancelWaveIfEmpty, @vCancelWaveIfEmpty) = 'Y' /* Yes */) and (coalesce(@vNumOrders, 0) = 0))
    exec pr_PickBatch_Cancel @WaveNo, @UserId, @BusinessUnit, @Operation, null;

  /* Finally we need to call the pick batch status to update the status */
  exec pr_PickBatch_SetStatus @WaveNo;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2, @vValue3;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;

end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_RemoveOrders */

Go
