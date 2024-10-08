/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/21  VS      pr_OrderHeaders_CancelPickTicket: Pass the operation to cancel the wave (OBV3-542)
                      pr_OrderHeaders_CancelPickTicket: Passed operation param to pr_PickBatch_RemoveOrders proc (OB2-2311)
                      pr_OrderHeaders_CancelPickTicket: Move validations to new proc
  2021/04/21  AY      pr_OrderHeaders_CancelPickTicket: Eliminate redundant messages (HA GoLive)
  2018/11/13  RIA     pr_OrderHeaders_CancelPickTicket: Reverted few changes to unallocate LPNs (S2GCA-373)
  2018/08/16  TK      pr_OrderHeaders_Modify: ShipVia datatype changed to TShipVia (S2GCA-135)
                      pr_OrderHeaders_CancelPickTicket: Bug Fix in cancelling PickTicket which is allocated (S2GCA-191)
  2018/04/08  SV      pr_OrderDetails_Modify, pr_OrderHeaders_AfterClose, pr_OrderHeaders_CancelPickTicket, pr_OrderHeaders_Close, pr_OrderHeaders_Modify (HPI-1842)
  2015/12/14  NY      pr_OrderHeaders_CancelPickTicket: Added validation to remove order from load before cancel it (OB-403)
  2015/10/15  RV      pr_OrderHeaders_CancelPickTicket: Modified procedure to handle as flag changes in pr_LPNs_Unallocate (FB-441).
  2015/08/13  AY/SV   pr_OrderHeaders_CancelPickTicket: Resolved the issue with unallocating the partially allocated LPNs upon
  2015/07/01  SV      pr_OrderHeaders_CancelPickTicket: Fixed the issue (not unallocating the LPNs when PTs are cancelled)
  2012/12/31  PKS     pr_OrderHeaders_CancelPickTicket: AT message insertion has been commented because it was
  2012/11/24  PKS     Added AT functionality to pr_OrderDetails_Modify, pr_OrderHeaders_CancelPickTicket, pr_OrderHeaders_Close
  2012/09/05  PKS     pr_OrderHeaders_CancelPickTicket: Cursur was removed for fetching each LPN of an Order and
  2012/08/08  VM      pr_OrderHeaders_CancelPickTicket: Does not need transaction controls as this is not called directly,
  2011/11/17  TD      pr_OrderHeaders_CancelPickTicket: New procedure.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_CancelPickTicket') is not null
  drop Procedure pr_OrderHeaders_CancelPickTicket;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_CancelPickTicket:

  1. PT has anything shipped against it, it cannot be canceled, it has to be closed only.
  2. If PT has nothing shipped against it, then allow cancel.
  3. Unallocate all LPNs that are allocated. If the above are done successfully then we need to mark the
     PT as Cancelled.
  4. Then we need to Export 'Ship' transactions - which will anyway upload zeros for unitsshipped
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_CancelPickTicket
  (@OrderId      TRecordId,
   @PickTicket   TPickTicket,
   @ReasonCode   TReasonCode = null,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @vOrderId          TRecordId,
          @vOrderXML         TXML,
          @vOrderType        TOrderType,
          @vOrderStatus      TStatus,
          @vPickBatchNo      TPickBatchNo,
          @vBatchStatus      TStatus,
          @vLPNId            TRecordId,
          @vLPN              TLPN,
          @vLPNQuantity      TQuantity,
          @vActivityDateTime TDateTime,
          @ttLPNsToUpdate    TEntityKeysTable,
          @ttTaskDetails     TEntityKeysTable;
begin
begin try
  select @ReturnCode  = 0,
         @MessageName = null;

  /* Get Order Info */
  select @vOrderId     = OrderId,
         @vOrderType   = OrderType,
         @vOrderStatus = Status,
         @vPickBatchNo = PickBatchNo
  from vwOrderHeaders
  where (((OrderId    = @OrderId)     or
          (PickTicket = @PickTicket)) and
        (BusinessUnit = @BusinessUnit));

  /* Validations */
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsRequired';
  else
  if (@vOrderId is null)
    set @MessageName = 'OrderDoesNotExist';
  else
  if (@vOrderStatus in ('S' /* Shipped */))
    set @MessageName = 'OrderAlreadyShipped'
  else
  if (@vOrderStatus in ('D' /* Completed */))
    set @MessageName = 'OrderAlreadyCompleted'
  else
  if (@vOrderStatus in ('X' /* Canceled */))
    set @MessageName = 'OrderAlreadyCanceled'
  else
  if (exists (select * from LPNs
              where ((OrderId = @vOrderId) and
                     (Status = 'S' /* Shipped */))))
    set @MessageName = 'CancelOrdersomeUnitsareShipped'
  else
  if (exists (select *
              from vwOrderShipments
              where (OrderId = @vOrderId) and
                    (coalesce(LoadId, 0) <> 0)))
    set @MessageName = 'CannotCancelOrderOnLoad';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Cancel all remaining task details */
  insert into @ttTaskDetails (EntityId, EntityKey)
    select TaskDetailId, 'TaskDetail'
    from TaskDetails
    where (OrderId = @vOrderId) and Status not in ('X', 'C');

  /* This step is used to unallocate all the LPNs which are not picked yet */
  if exists (select * from @ttTaskDetails)
    exec pr_Tasks_Cancel @ttTaskDetails, null /* TaskId */, null /* PickBatchNo */, @BusinessUnit, @UserId;

  /* Fetching all LPNs related to Order that have already been picked */
  insert into @ttLPNsToUpdate (EntityId, EntityKey)
    select distinct LPNId, LPN
    from LPNs
    where (OrderId = @vOrderId);

  /* Unallocating LPNs from Order */
  if exists (select * from @ttLPNsToUpdate)
    exec pr_LPNs_Unallocate null /* LPNId */, @ttLPNsToUpdate, 'P' /* PalletPick - @UnallocPallet */, @BusinessUnit, @UserId;

  /* Remove from the PickBatch */
  if (@vPickbatchNo is not null)
    begin
      /* Framing OrderId into XML  */
      set @vOrderXML = '<Orders><OrderHeader><OrderId>'+convert(varchar,@vOrderId)+'</OrderId></OrderHeader></Orders>';

      exec pr_PickBatch_RemoveOrders @vPickBatchNo,
                                     @vOrderXML,
                                     null, /* Flag for Cancel Batch If Empty */
                                     'OH', /* Batching Level must be 'OH' when we are canelling an order */
                                     @BusinessUnit,
                                     @UserId;
    end

  select @vOrderStatus = 'X' /* Canceled */;

  /* Mark the Order as Canceled */
  exec pr_OrderHeaders_SetStatus @vOrderId, @vOrderStatus output, @UserId;

  /* Do the necessary updates that need to be done after an order has been closed */
  exec pr_OrderHeaders_AfterClose @vOrderId, @vOrderType, @vOrderStatus, null /* LoadId */, @ReasonCode /* ReasonCode */,
                                  @BusinessUnit, @UserId, 'Y'/* GenerateExports */, 'CancelPickTicket'/* Operation */;

  /* Audit Trail */
  /* AT for Order Cancel was already logged in procedure 'pr_OrderHeaders_AfterClose',
     So AT message log has been commented here. */
  /*
  set @vActivityDateTime = current_timestamp;
  exec pr_AuditTrail_Insert @ActivityType     = 'OrderCanceled',
                            @UserId           = @UserId,
                            @ActivityDateTime = @vActivityDateTime,
                            @OrderId          = @vOrderId;
  */

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

end try
begin catch

  exec @ReturnCode = pr_ReRaiseError;
end catch;
end /* pr_OrderHeaders_CancelPickTicket */

Go
