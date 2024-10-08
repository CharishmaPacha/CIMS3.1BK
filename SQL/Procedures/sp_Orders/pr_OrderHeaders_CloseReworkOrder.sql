/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/23  TK      pr_OrderHeaders_CloseReworkOrder: Update UnitsShipped while closing rework order (HA-833)
                      pr_OrderHeaders_CloseReworkOrder: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_CloseReworkOrder') is not null
  drop Procedure pr_OrderHeaders_CloseReworkOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_CloseReworkOrder: This Procedure closes the rework order
    that has been picked and complete.

  When Kit LPNs are created then we will reduce the UATS and UnitsAssigned on the component lines
  if there are no units assigned then it means the order is complete, this procedure validates,
  marks the rework order and its wave as completed and generates ship exports
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_CloseReworkOrder
  (@OrderId        TRecordId,
   @Operation      TOperation  = null,
   @ReasonCode     TReasonCode = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,

          @vOrderId              TRecordId,
          @vOrderType            TOrderType,
          @vOrderStatus          TStatus,
          @vUnitsAssigned        TQuantity,

          @vWaveId               TRecordId,
          @vWaveNo               TWaveNo,

          @vValidOrderStatuses   TControlValue;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Order Info */
  select @vOrderId     = OrderId,
         @vOrderStatus = Status,
         @vWaveId      = PickBatchId,
         @vWaveNo      = PickBatchNo
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get Controls */
  select @vValidOrderStatuses = dbo.fn_Controls_GetAsString('CloseReworkOrder', 'ValidStatuses', 'P' /* Picked */, @BusinessUnit, @UserId);

  /* Validations */
  if (dbo.fn_IsInList(@vOrderStatus, @vValidOrderStatuses) = 0)
    set @vMessageName = 'ReworkOrder_InvaildStatusToClose';
  else
  if (@vOrderStatus = 'D'/* Completed */)
    set @vMessageName = 'ReworkOrder_OrderAlreadyClosed';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Close all the LPNs assigned for the order */
  exec pr_OrderHeaders_CloseReworkLPNs @vOrderId, @Operation, 'CNV'/* Reason - Conversion */, @BusinessUnit, @UserId;

  /* Update UnitsShipped with UnitsAssigned on the Order, as that is being considered while
     generating ship exports */
  update OrderDetails
  set UnitsShipped = UnitsAssigned
  where (OrderId = @vOrderId);

  /* Generate Exports */
  exec pr_Exports_OrderData 'Ship', @vOrderId, null /* OrderDetailId */, null /* LoadId */,
                            @BusinessUnit, @UserId;

  /* Mark Bulk order as completed */
  exec pr_OrderHeaders_SetStatus @vOrderId, 'D' /* Completed */, @UserId;

  /* Update Wave Status */
  exec pr_PickBatch_SetStatus @vWaveNo, '$' /* defer */;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'OrderCompleted', @UserId, null /* Audit DateTime */,
                            @OrderId = @vOrderId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_CloseReworkOrder */

Go
