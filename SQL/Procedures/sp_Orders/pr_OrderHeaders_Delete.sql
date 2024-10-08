/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Delete') is not null
  drop Procedure pr_OrderHeaders_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Delete
  (@OrderId      TRecordId,
   @PickTicket   TPickTicket)
As
begin
  SET NOCOUNT ON;

  delete
  from OrderHeaders
  where (OrderId    = @OrderId) or
        (PickTicket = @PickTicket);
end /* pr_OrderHeaders_Delete */

Go
