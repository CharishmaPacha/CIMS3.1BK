/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/11/22  AY      pr_Archive_Tasks: Use control var for number of days after which to archive
  2012/08/14  AY      pr_Archive_Tasks: Introduced
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_Tasks') is not null
  drop Procedure pr_Archive_Tasks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_Tasks:
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_Tasks
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vMessage      TDescription,

          @vArchiveDays  TInteger,
          @vArchiveDate  TDate;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Fetch the noof days from controls */
  select @vArchiveDays = dbo.fn_Controls_GetAsInteger('Archive', 'Tasks-Days', 1, @BusinessUnit, @UserId);

  select @vArchiveDate  = convert(date, getdate()-@vArchiveDays);

  /* Update all Tasks' Archives to 'Y' when its status is Canceled/Completed
     and modified date is less than a week from current date and archive status is 'N' */
  update Tasks
  set Archived = 'Y' /* Yes */
  where (Archived = 'N' /* No */) and
        (Status in ('X' /* Canceled */, 'C' /* Completed */)) and
        (ModifiedOn <= @vArchiveDate);

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_Tasks */

Go
