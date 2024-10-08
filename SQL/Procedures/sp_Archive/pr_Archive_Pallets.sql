/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/10/03  SP      pr_Archive_Pallets: Added new Procedure to archive pallets.
------------------------------------------------------------------------------*/

Go

if object_id ('dbo.pr_Archive_Pallets') is not null
  drop Procedure pr_Archive_Pallets;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_Pallets:
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_Pallets
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vMessage      TDescription,
          @vArchiveDate  TDate;
begin
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vArchiveDate  = convert(date, getdate()-1);

  /* Update all Pallets' Archives to 'Y' when its status is
     shipped/consumed/voided/inactive
     and modified date is less than current date and archive status is 'N' */
  update Pallets
  set Archived = 'Y' /* Yes */
  where ((Archived =  'N' /* No */) and
         (Status   in ('S' /* Shipped  */,
                       'V' /* Voided   */,
                       'I' /* Invoice */)) and
         (ModifiedOn <= @vArchiveDate));

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_Pallets */

Go
