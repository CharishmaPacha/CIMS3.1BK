/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/03  PK      pr_OrderHeaders_AfterClose: Passing in LoadId to insert order shipped AT on Load (HA-1387)
  2020/04/24  VS      pr_OrderHeaders_AfterClose: Generate the Exports for Transfer Orders (HA-110)
  2018/07/06  RV      pr_OrderHeaders_AfterClose: Made changes to send Shipment confirmation mails based upon the control value (S2G-997)
  2018/04/08  SV      pr_OrderDetails_Modify, pr_OrderHeaders_AfterClose, pr_OrderHeaders_CancelPickTicket, pr_OrderHeaders_Close, pr_OrderHeaders_Modify (HPI-1842)
  2017/07/12  TK      pr_OrderHeaders_AfterClose: Added Operation to the signature and changed respective callers to pass Operation (CIMS-1467)
  2013/10/25  PK      pr_OrderHeaders_AfterClose: Generating PTCancel exports when an order is canceled.
                         already implemented in pr_OrderHeaders_AfterClose procedure.
  2012/12/28  VM      pr_OrderHeaders_Close, pr_OrderHeaders_AfterClose: Handled log AT in one place
  2012/11/02  NY      pr_OrderHeaders_AfterClose:Added parameter @GenerateExports and set Default value 'Yes'
  2012/03/29  AY      pr_OrderHeaders_AfterClose: Moved all code for changes to be done
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_AfterClose') is not null
  drop Procedure pr_OrderHeaders_AfterClose;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_AfterClose: Procedure to be used to do all necessary
    updates/inserts when an Order has been closed i.e. Shipped/Completed or Canceled.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_AfterClose
  (@OrderId          TRecordId,
   @OrderType        TEntity     = null,
   @OrderStatus      TStatus     = null,
   @LoadId           TLoadId     = null,
   @ReasonCode       TReasonCode = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @GenerateExports  TFlag = 'Y' /* Yes */,
   @Operation        TOperation = null)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,

          @vTransType     TTypeCode,
          @vOrderId       TRecordId,
          @vOrderType     TOrderType,
          @vPickTicket    TPickTicket,
          @vStatus        TStatus,
          @vLPNId         TRecordId,
          @vLPNQuantity   TQuantity,
          @vPickBatchNo   TPickBatchNo,

          /* Controls */
          @vOrderTypesToShip     TDescription,
          @vOrderTypesToComplete TFlags,

          @vShipmentConfirmationAlert
                                 TControlValue,

          @vAuditActivity TActivityType,
          @vAuditDatetime TDateTime;
begin
  select @vReturnCode                 = 0,
         @vMessageName                = null,
         @vOrderTypesToShip          = dbo.fn_Controls_GetAsString('OrderClose', 'Ship', 'CET'/* Customer, Ecom, Transfer */, @BusinessUnit, null/* UserId */),
         @vOrderTypesToComplete      = dbo.fn_Controls_GetAsString('OrderClose', 'Complete', 'O'/* Out reserve */, @BusinessUnit, null/* UserId */),
         @vShipmentConfirmationAlert = dbo.fn_Controls_GetAsString('Shipping',   'ShipmentConfirmationAlert', 'N'/* No */, @BusinessUnit, null/* UserId */);

  /* Get Order Info */
  select @vOrderId       = OrderId,
         @vPickTicket    = PickTicket,
         @vOrderType     = OrderType,
         @vStatus        = Status,
         @vPickBatchNo   = PickBatchNo,
         @vAuditDatetime = ModifiedDate
  from OrderHeaders
  where (OrderId = @OrderId);

  select @vAuditActivity = case when @vStatus = 'S' /* Shipped   */ then 'OrderShipped'
                                when @vStatus = 'D' /* Completed */ then 'OrderCompleted'
                                when @vStatus = 'X' /* Canceled  */ then 'OrderCanceled'
                           end,
         @vTransType     = case when @vStatus = 'X' /* Canceled */ then 'PTCancel'
                                when @vStatus = 'S' /* Shipped */  then 'Ship'
                           end;

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, @vAuditDatetime,
                            @OrderId = @vOrderId, @LoadId = @LoadId,
                            @ReasonCode = @ReasonCode;

  /* Update the Batch status */
  if (@Operation <> 'LPNs_Ship')
    exec pr_PickBatch_SetStatus @vPickBatchNo, null /* Status */, @ModifiedBy = @UserId;

  /* If E-Comm Order is shipped or cancelled, then export, if Canceled we
     upload as 'Shipped' with 0 unitsshipped on order details.
  */
  if ((charindex(@vOrderType, @vOrderTypesToShip) <> 0) and
      (charindex(@vStatus, 'SX' /* Shipped/Canceled */) <> 0)) and
      (@GenerateExports = 'Y' /* Yes */)
    exec pr_Exports_OrderData @vTransType, @vOrderId, null /* OrderDetailid */, @LoadId,
                              @BusinessUnit, @UserId, @ReasonCode;
  else
  if ((charindex(@vOrderType, @vOrderTypesToComplete) <> 0) and
      (charindex(@vStatus, 'DX' /* completed/Canceled */) <> 0)) and
      (@GenerateExports = 'Y' /* Yes */)
    exec pr_Exports_OrderData 'Xfer', @vOrderId, null /* OrderDetailid */, @LoadId,
                              @BusinessUnit, @UserId, @ReasonCode;

  /* insert into process alerts table to send shipment notifications based upon the control value */
  if (@vStatus = 'S'/* Shipped */) and (@vShipmentConfirmationAlert = 'Y' /* Yes */)
    exec pr_ProcessAlert_AddOrUpdate default, default, default, 'Shipping' /* Category */,
                                     'ShipConfirmation' /* Sub-Category */, 'Order' /* Entity */,
                                     @vOrderId, @vPickTicket, @BusinessUnit = @BusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_AfterClose */

Go
