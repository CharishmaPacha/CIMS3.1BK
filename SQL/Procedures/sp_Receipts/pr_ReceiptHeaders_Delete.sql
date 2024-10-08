/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_Delete') is not null
  drop Procedure pr_ReceiptHeaders_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_Delete
  (@ReceiptId       TRecordId,
   @ReceiptNumber   TReceiptNumber)
as
begin
  SET NOCOUNT ON;

  delete
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId) or
        (ReceiptNumber = @ReceiptNumber);
end /* pr_ReceiptHeader_Delete */

Go
