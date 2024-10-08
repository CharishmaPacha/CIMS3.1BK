/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_GetAllLines') is not null
  drop Procedure pr_OrderDetails_GetAllLines;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderDetails_GetAllLines:
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_GetAllLines
  (@OrderId        TRecordId,
   @PickTicket     TPickTicket)
as
begin
  select *
  from vwOrderDetails
  where ((OrderId     = @OrderId) or
         (PickTicket  = @PickTicket))
  order by OrderDetailId;
end /* pr_OrderDetails_GetAllLines */

Go
