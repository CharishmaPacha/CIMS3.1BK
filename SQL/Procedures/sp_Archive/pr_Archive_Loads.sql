/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/10/14  AY      pr_Archive_Loads: New
------------------------------------------------------------------------------*/

Go
if object_id ('dbo.pr_Archive_Loads') is not null
  drop Procedure pr_Archive_Loads;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_Loads:
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_Loads
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @vMessage       TDescription,
          @vArchiveDate   TDate;
begin
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vArchiveDate  = convert(date, getdate()-1);

  /* Update all Loads' Archives to 'Y' when its status is
     shipped/consumed/voided/inactive
     and modified date is less than current date and archive status is 'N' */
  update Loads
  set Archived = 'Y' /* Yes */
  where ((Archived =  'N' /* No */) and
         (Status   in ('S' /* Shipped  */,
                       'X' /* Canceled */)) and
         (ModifiedOn <= @vArchiveDate));

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_Loads */

Go
