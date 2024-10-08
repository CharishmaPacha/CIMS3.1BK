/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptDetails_Delete') is not null
  drop Procedure pr_ReceiptDetails_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptDetails_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptDetails_Delete
  (@ReceiptId        TRecordId,
   @ReceiptDetailId  TRecordId,
   @ReceiptLine      TReceiptLine)
as
begin
  SET NOCOUNT ON;

  delete
  from ReceiptDetails
  where ((ReceiptId        = @ReceiptId) and
         ((ReceiptDetailId = @ReceiptDetailId) or
          (ReceiptLine     = @ReceiptLine)));
end /* pr_ReceiptDetails_Delete */

Go
