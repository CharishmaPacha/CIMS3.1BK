/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/11/21  SP      pr_Archive_Exports: Added new Procedure to archive exports.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_Exports') is not null
  drop Procedure pr_Archive_Exports;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_Exports:
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_Exports
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @vArchiveDate   TDate;
begin
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vArchiveDate = convert(date, getdate() - 1);

  /* Update all Export's by setting Archives to 'Y' when its status is Yes */
  update Exports
  set Archived = 'Y' /* Yes */
  where (Archived = 'N' /* No */) and
        (Status   = 'Y' /* Yes */) and
        (ModifiedOn <= @vArchiveDate);

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_Exports */

Go
