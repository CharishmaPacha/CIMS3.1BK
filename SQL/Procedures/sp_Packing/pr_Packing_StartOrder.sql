/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_StartOrder') is not null
  drop Procedure pr_Packing_StartOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_StartOrder: This procedure is to be used when starting to pack
   an order from UI so that we can validate it. The input could be PickTicket or
   Cart that the Order is associated with.
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_StartOrder
  (@EntityValue        TPickTicket,
   @Pallet             TPallet,
   @BatchNo            TPickBatchNo,
   @Operation          TOperation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vOrderId               TRecordId,
          @vLPNId                 TRecordId,
          @vOrderStatus           TStatus;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  select @vOrderId = OrderId
  from OrderHeaders
  where (PickTicket = @EntityValue) and (BusinessUnit = @BusinessUnit);

  /* If PT is not given then look at LPN */
  if (@vOrderId is null)
    select @vLPNId   = LPNId,
           @vOrderId = OrderId
    from LPNs
    where (LPN = @EntityValue) and
          (BusinessUnit = @BusinessUnit);

  /* get the Order Status */
  select @vOrderStatus = Status
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Validations */
  if (@vOrderId is null)
    select @vMessageName = 'Packing_InvalidInput';
  else
  if (@vOrderStatus = 'S' /* Shipped */)
    select @vMessageName = 'Packing_OrderShipped';
  else
  if (@vOrderStatus = 'X' /* Cancelled */)
    select @vMessageName = 'Packing_OrderCancelled';
  else
  if (dbo.fn_OrderHeaders_OrderQualifiedToShip(@vOrderId, 'Packing', 'K' /* Kit Validation */) = 'N')
    select @vMessageName = 'Packing_PartialKitsOnOrder';
  else
  if (dbo.fn_OrderHeaders_OrderQualifiedToShip(@vOrderId, 'Packing', 'S' /* Ship Complete */) = 'N')
    select @vMessageName = 'Packing_ViolatesSCRule';

  if (@vMessageName is not null)
    goto ErrorHandler;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_StartOrder */

Go
