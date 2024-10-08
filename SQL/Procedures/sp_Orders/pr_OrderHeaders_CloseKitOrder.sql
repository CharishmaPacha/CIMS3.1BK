/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/11  TK      pr_OrderHeaders_CloseKitOrder: Initial Revision (HA-1238)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_CloseKitOrder') is not null
  drop Procedure pr_OrderHeaders_CloseKitOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_CloseKitOrder: This Procedure closes the rework order
    that has been picked and complete.

  When Kit LPNs are created then we will reduce the UATS and UnitsAssigned on the component lines
  if there are no units assigned then it means the order is complete, this procedure validates,
  marks the rework order and its wave as completed and generates ship exports
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_CloseKitOrder
  (@OrderId        TRecordId,
   @Operation      TOperation  = null,
   @ReasonCode     TReasonCode = 0,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vOrderId          TRecordId,
          @vOrderType        TOrderType,
          @vOrderStatus      TStatus,
          @vUnitsAssigned    TQuantity,

          @vWaveId           TRecordId,
          @vWaveNo           TWaveNo;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Order Info */
  select @vOrderId     = OrderId,
         @vOrderStatus = Status,
         @vWaveId      = PickBatchId,
         @vWaveNo      = PickBatchNo
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get UnitsAssigned */
  select @vUnitsAssigned = sum(UnitsAssigned)
  from OrderDetails
  where (OrderId = @vOrderId) and
        (LineType <> 'A'/* KitAssembly */);

  /* Validations */
  if (@vOrderStatus = 'D'/* Completed */)
    set @vMessageName = 'OrderAlreadyClosed';
  else
  if (@vUnitsAssigned > 0)
    set @vMessageName = 'CloseKitOrder_UnitsStillAssigned';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Generate Ship Exports */
  exec pr_Exports_OrderData 'Ship', @vOrderId, null /* OrderDetailid */, null /* LoadId */,
                            @BusinessUnit, @UserId;

  /* Mark Bulk order as completed */
  exec pr_OrderHeaders_SetStatus @vOrderId, 'D' /* Completed */, @UserId;

  /* Update Wave Status */
  exec pr_PickBatch_SetStatus @vWaveNo;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'OrderCompleted', @UserId, null /* Audit DateTime */,
                            @OrderId = @vOrderId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_CloseKitOrder */

Go
