/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptDetails_GetAllLines') is not null
  drop Procedure pr_ReceiptDetails_GetAllLines;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptDetails_GetAllLines:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptDetails_GetAllLines
  (@ReceiptId        TRecordId,
   @ReceiptNumber    TReceiptNumber)
as
begin
  select *
  from vwReceiptDetails
  where ((ReceiptId      = @ReceiptId) or
         (ReceiptNumber  = @ReceiptNumber))
  order by ReceiptDetailId;
end /* pr_ReceiptDetails_GetAllLines */

Go
