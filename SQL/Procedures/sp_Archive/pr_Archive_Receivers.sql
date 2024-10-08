/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/11/04  PK      Added pr_Archive_Receivers.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_Receivers') is not null
  drop Procedure pr_Archive_Receivers;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_Receivers: Archive Closed Receivers.
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_Receivers
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

  /* Update Receivers as Archived which are already closed */
  update Receivers
  set Archived = 'Y'
  where (Archived = 'N') and
        (Status = 'C' /* Completed */) and
        (ModifiedOn <= @vArchiveDate);

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_Receivers */

Go
