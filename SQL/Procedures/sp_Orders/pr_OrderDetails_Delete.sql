/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_Delete') is not null
  drop Procedure pr_OrderDetails_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderDetails_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_Delete
  (@OrderId        TRecordId,
   @OrderDetailId  TRecordId,
   @OrderLine      TDetailLine)
as
begin
  SET NOCOUNT ON;

  delete
  from OrderDetails
  where ((OrderId        = @OrderId) and
         ((OrderDetailId = @OrderDetailId) or
          (OrderLine     = @OrderLine)));
end /* pr_OrderDetails_Delete */

Go
