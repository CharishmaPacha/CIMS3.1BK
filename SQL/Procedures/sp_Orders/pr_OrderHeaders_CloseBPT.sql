/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/03  MS      pr_OrderHeaders_CloseBPT: Changes to caller (JL-65)
  2018/11/15  TD      pr_OrderHeaders_CloseBPT:Changed datatype to avoid compatibility issues (OB2-739)
  2017/07/24  TK      pr_OrderHeaders_CloseBPT: Unallocate if there is any inventory assigned to the Orders, if the Order is being closed (HPI-1597)
  2017/04/22  RV      pr_OrderHeaders_CloseBPT: Added PickTicket and Wave to the message description.(HPI-1256)
  2017/04/07  RV      pr_OrderHeaders_CloseBPT: Intial version (HPI-1256)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_CloseBPT') is not null
  drop Procedure pr_OrderHeaders_CloseBPT;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_CloseBPT: This Procedure closes the Bulk orders on the wave
    if Wave is shipped/completed or cancelled. Caller can pass in the OrderId of
    the Bulk Order or pass in the WaveId and we would find the BulkOrderId
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_CloseBPT
  (@BulkOrderId  TRecordId,
   @PickBatchId  TRecordId,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId = 'cIMSAgent')
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vBulkOrderId      TRecordId,
          @vOrderType        TOrderType,
          @vStatus           TStatus,
          @vUnitsAssigned    TQuantity,
          @vWaveId           TRecordId,
          @vWaveNo           TPickBatchNo,
          @vWaveStatus       TStatus,

          @vValue1           TDescription,
          @vValue2           TDescription,
          @vAuditActivity    TActivityType;

  declare @ttLPNsToUnallocate TEntityKeysTable,
          @ttPalletsToRecount TRecountKeysTable;
begin
  select @vReturnCode               = 0,
         @vMessageName              = null;

  /* Get the Bulk Order from the given params */
  select @vBulkOrderId = OrderId,
         @vValue1      = PickTicket,
         @vOrderType   = OrderType,
         @vStatus      = Status,
         @vWaveId      = PickBatchId,
         @vValue2      = PickBatchNo,
         @vWaveNo      = PickBatchNo
  from OrderHeaders
  where ((OrderId      = @BulkOrderId) or
         (PickBatchId  = @PickBatchId)) and
        (OrderType    = 'B' /* Bulk */) and
        (Status not in ('S', 'D', 'X' /* Shipped/Completed/Canceled */)) and
        (BusinessUnit = @BusinessUnit);

  /* If we do not have a Bulk Order i.e. it wasn't passed in or the given
     Wave does not have Bulk Order, then exit */
  if (@vBulkOrderId is null)
    return;

  if (coalesce(@vWaveId, 0) <> 0)
    select @vWaveStatus = Status
    from PickBatches
    where (RecordId = @vWaveId);

  /* If the wave status is shipped then check if there are any units assigned to bulk order,
     if the wave is shipped we cannot pack the units assigned to bulk order anymore so unallocate them before closing the Order */
  if (@vWaveStatus = 'S'/* Shipped */)
    begin
      insert into @ttLPNsToUnallocate(EntityId, EntityKey)
        select LPNId, LPNDetailId
        from LPNDetails
        where (OrderId = @vBulkOrderId);

      if (@@rowcount > 0)
        insert into @ttPalletsToRecount (EntityId)
          select distinct PalletId
          from LPNs L
            join @ttLPNsToUnallocate LU on (L.LPNId = LU.EntityId);

      /* Unallocate if there is any inventory reserved */
      exec pr_LPNDetails_UnallocateMultiple 'CloseBPT'/* Operation */, @ttLPNsToUnallocate, null/* LPNId */, null/* LPNDetailId */, @UserId, @BusinessUnit;

      /* Update Pallet Status */
      exec pr_Pallets_Recalculate @ttPalletsToRecount, 'S'/* Set Status */, @BusinessUnit, @UserId;
    end

  select @vUnitsAssigned = sum(OD.UnitsAssigned)
  from OrderDetails OD
  where (OD.OrderId = @vBulkOrderId);

  /* Validations */
  if (@BusinessUnit is null)
    set @vMessageName = 'BusinessUnitIsRequired';
  else
  if (@vBulkOrderId is null)
    set @vMessageName = 'OrderDoesNotExist';
  else
  if (@vStatus in ('S' /* Shipped */, 'D' /* Completed */))
    set @vMessageName = 'OrderAlreadyClosed';
  else
  if (@vStatus in ('X' /* Canceled */, 'E' /* Cancel in progress */))
    set @vMessageName = 'OrderCanceledAndCannotbeClosed';
  else
  if (@vUnitsAssigned > 0)
    set @vMessageName = 'CannotCloseUnitsAssignedForBulkOrder';
  else
  if (exists(select *
             from Tasks
             where (BatchNo = @vWaveNo) and (Status not in ('X', 'C' /* Canceled, Completed */))))
    set @vMessageName = 'CloseOrderAllTasksNotCompleted';
  else
  if (@vWaveStatus <> 'S' /* Shipped */)
    set @vMessageName = 'PickBatchStatusInvalidForOrderClosing';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Mark Bulk order as completed */
  exec pr_OrderHeaders_SetStatus @vBulkOrderId, 'D' /* Completed */, @UserId;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'OrderCompleted', @UserId, null /* Audit DateTime */,
                            @OrderId = @vBulkOrderId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_CloseBPT */

Go
