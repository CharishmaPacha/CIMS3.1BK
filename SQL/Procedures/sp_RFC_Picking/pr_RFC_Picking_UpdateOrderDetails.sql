/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_UpdateOrderDetails') is not null
  drop Procedure pr_RFC_Picking_UpdateOrderDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_UpdateOrderDetails:

  This proc is the procedure to update order details with allocated quantity
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_UpdateOrderDetails
  (@SalesOrder        TSalesOrder,
   @HostOrderLine     THostOrderLine,
   @SKU               TSKU,
   @OrderedQty        TInteger,
   @ReservedQty       TInteger,
   @xmlInputParams    TXML   = null)
as
  declare @vOrderId                  TRecordId,
          @vOrderDetailId            TRecordId,
          @vSKUId                    TRecordId,

          @xmlResult                 XML,
          @vBusinessUnit             TBusinessUnit,
          @vActivityLogId            TRecordId;

begin /* pr_RFC_Picking_UpdateOrderDetails */
begin try
  SET NOCOUNT ON;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, null, null /* userid */, null /* DeviceId */,
                      null, @SalesOrder, 'SalesOrder',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  select @vOrderId      = OrderId,
         @vBusinessUnit = BusinessUnit
  from OrderHeaders
  where (SalesOrder = @SalesOrder);

  if (@vOrderId is null)
    return;

  select @vSKUId = SKUId
  from SKUs
  where (SKU = @SKU);

  select @vOrderDetailId   = OrderDetailId
  from OrderDetails
  where ((OrderId = @vOrderId) and
         ((HostOrderLine = @HostOrderLine) or (SKUId = @vSKUId)));

  if (@vOrderDetailId is null)
    return;

  update OrderDetails
  set UnitsAssigned = @ReservedQty
  where (OrderDetailId = @vOrderDetailId);

  /* Update the status of the Order */
  exec pr_OrderHeaders_SetStatus @vOrderId;

   /* convert the result into xml format */
  set @xmlResult =  (select *
                     from OrderDetails
                     where (OrderDetailId = @vOrderDetailId)
                     FOR XML RAW('orderinfo'), TYPE, ELEMENTS XSINIL, ROOT('orderdetails'));

  /* Log the result */
  exec pr_RFLog_End null, @@ProcId, @EntityId = @vOrderId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  /* Log the Error */
  exec pr_RFLog_End null, @@ProcId, @EntityId = @vOrderId, @ActivityLogId = @vActivityLogId output;

  exec pr_ReRaiseError;
end catch
end /* pr_RFC_Picking_UpdateOrderDetails */

Go
