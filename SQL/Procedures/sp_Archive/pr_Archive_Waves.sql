/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/02  SAK     pr_Archive_Waves: Added new parameters (UserId and BusinessUnit) (HA-659)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_Waves') is not null
  drop Procedure pr_Archive_Waves;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_Waves:
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_Waves
  (@UserId       TUserId,
   @BusinessUnit TBusinessUnit)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vMessage      TDescription,
          @vArchiveDate  TDate;
begin
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vArchiveDate  = convert(date, getdate()-1);

  /* Update all Waves' Archive to 'Y' when its status is
     shipped/Canceled
     and modified date is less than current date and archive status is 'N' */
  update Waves
  set Archived = 'Y' /* Yes */
  where ((Archived = 'N' /* No */) and
         (Status in ('S' /* Shipped*/, 'X' /* Canceled */, 'D' /* Completed */)) and
         (ModifiedOn <= @vArchiveDate));

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_Waves */

Go
