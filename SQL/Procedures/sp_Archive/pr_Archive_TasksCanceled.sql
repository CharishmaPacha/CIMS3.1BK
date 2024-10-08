/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_TasksCanceled') is not null
  drop Procedure pr_Archive_TasksCanceled;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_TasksCanceled: To archive canceled tasks immediately
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_TasksCanceled
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vMessage      TDescription;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Update all Tasks' Archives to 'Y' when its status is Canceled/Completed
     and modified date is less than a week from current date and archive status is 'N' */
  update Tasks
  set Archived = 'Y' /* Yes */
  where (Archived = 'N' /* No */) and
        (Status in ('X' /* Canceled */));

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_TasksCanceled */

Go
