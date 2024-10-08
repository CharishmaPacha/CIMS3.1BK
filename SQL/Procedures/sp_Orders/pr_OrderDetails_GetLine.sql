/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_GetLine') is not null
  drop Procedure pr_OrderDetails_GetLine;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderDetails_GetLine:
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_GetLine
  (@OrderId        TRecordId,
   @PickTicket     TPickTicket,
   @OrderDetailId  TRecordId,
   @OrderLine      TOrderLine)
as
begin
  select *
  from vwOrderDetails
  where (((OrderId      = @OrderId) or
          (PickTicket   = @PickTicket)) and
         ((OrderDetailId = @OrderDetailId) or
          (OrderLine     = @OrderLine)))
  order by OrderDetailId;
end /* pr_OrderDetails_GetLine */

Go
