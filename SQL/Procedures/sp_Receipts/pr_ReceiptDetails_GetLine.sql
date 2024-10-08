/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptDetails_GetLine') is not null
  drop Procedure pr_ReceiptDetails_GetLine;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptDetails_GetLine:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptDetails_GetLine
  (@ReceiptId        TRecordId,
   @ReceiptNumber    TReceiptNumber,
   @ReceiptDetailId  TRecordId,
   @ReceiptLine      TReceiptLine)
as
begin
  select *
  from vwReceiptDetails
  where (((ReceiptId      = @ReceiptId) or
          (ReceiptNumber  = @ReceiptNumber)) and
         ((ReceiptDetailId = @ReceiptDetailId) or
          (ReceiptLine     = @ReceiptLine)))
  order by ReceiptDetailId;
end /* pr_ReceiptDetails_GetLine */

Go
