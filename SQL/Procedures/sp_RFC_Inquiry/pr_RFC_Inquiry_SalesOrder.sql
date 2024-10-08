/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inquiry_SalesOrder') is not null
  drop Procedure pr_RFC_Inquiry_SalesOrder;
Go

Create Procedure pr_RFC_Inquiry_SalesOrder
  (@PickTicket  TPickTicket,
   @Order       TSalesOrder)
As
begin
  /* TODO Validate with PT is valid */
  /* TODO Validate with OrderNo is valid */


  /* TODO When PT is not null, Fetch only the PT Hdr Info */
  /* TODO When PT is null and OrderNo is not null, Fetch all the PT Hdrs for the given OrderNo  */

  /* TODO When PT is not null, Fetch only the PT Lines for the PT */
  /* TODO When PT is null and OrderNo is not null, Fetch all the PT Lines for the given OrderNo  */

  /* TODO return the PT Hdr/ Lines in a preset manner to the caller */
  return;
end

Go
