/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/05/21  YA      pr_Archive_ReceiptOrders: New
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_ReceiptOrders') is not null
  drop Procedure pr_Archive_ReceiptOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_ReceiptOrders: Archive ROs shipped X days ago. X should be a control var.
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_ReceiptOrders
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vArchiveDays  TInteger,
          @vArchiveDate  TDate;

begin
  /* Fetch the noof days from controls */
  select @vArchiveDays = dbo.fn_Controls_GetAsInteger('Archive', 'Receipts-Days', 10, @BusinessUnit, @UserId);

  select @vArchiveDate = convert(date, getdate() - @vArchiveDays);

  /* Update Receipts and set it Archived for those Receipts which are shipped some days ago */
  update ReceiptHeaders
  set Archived = 'Y'
  where (Status in ('E'/* Received */, 'C'/* Closed */)) and
        (ModifiedOn <= @vArchiveDate);

end /* pr_Archive_ReceiptOrders */

Go
