/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/07/11  YJ      pr_Archive_ShipLabels: Added new procedure to archive ShipLabels (FB-974)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_ShipLabels') is not null
  drop Procedure pr_Archive_ShipLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_ShipLabels: Archive all shiplabels, if LPNs of them are archived
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_ShipLabels
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,

          @vArchiveDays  TInteger,
          @vArchiveDate  TDate;

begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Fetch the noof days from controls */
  select @vArchiveDays = dbo.fn_Controls_GetAsInteger('Archive', 'ShipLabels-Days', 90, @BusinessUnit, @UserId);

  select @vArchiveDate  = convert(date, getdate()-@vArchiveDays);

  update SL
  set SL.Archived = 'Y' /* Yes */
  from ShipLabels SL
    join LPNs L on (SL.EntityKey = L.LPN)
  where (SL.Archived   = 'N' /* No */ ) and
        (SL.CreatedOn <= @vArchiveDate) and
        (L.Archived    = 'Y' /* Yes */);

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_ShipLabels */

Go
