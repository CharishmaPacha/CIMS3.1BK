/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_PrintJobDetails_SetStatus: New proc to update PrintJobDetailStatus
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintJobDetails_SetStatus') is not null
  drop Procedure pr_PrintJobDetails_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_PrintJobDetails_SetStatus:

   #ttSelectedEntities  TEntityValuesTable
------------------------------------------------------------------------------*/
Create Procedure pr_PrintJobDetails_SetStatus
  (@PrintJobId    TRecordId = null,
   @Status        TStatus   = null,
   @UserId        TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  if (coalesce(@PrintJobId, '') <> '')
    update PJD
    set PJD.PrintJobDetailStatus = coalesce(@Status, PJ.PrintJobStatus),
        PJD.ModifiedBy           = @UserId,
        PJD.ModifiedDate         = current_timestamp
    from PrintJobDetails PJD
      join PrintJobs PJ on (PJD.PrintJobId = PJ.PrintJobId)
    where (PJ.PrintJobId = @PrintJobId);
  else
    update PJD
    set PJD.PrintJobDetailStatus = coalesce(@Status, PJ.PrintJobStatus),
        PJD.ModifiedBy           = @UserId,
        PJD.ModifiedDate         = current_timestamp
    from PrintJobDetails PJD
      join PrintJobs           PJ on (PJD.PrintJobId = PJ.PrintJobId)
      join #ttSelectedEntities SE on (PJD.PrintJobId = SE.EntityId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PrintJobDetails_SetStatus */

Go
