/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_DeleteAttributes') is not null
  drop Procedure pr_Waves_DeleteAttributes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_DeleteAttributes
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_DeleteAttributes
  (@WaveId         TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName;
begin
  select @vReturnCode   = 0;

  if (@WaveId is null) return;

  /* If error, exit */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Update PickbatchAttributes to inactive */
  update WaveAttributes
  set Status = 'I',
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  where (PickBatchId = @WaveId) and
        (Status = 'X' /* Cancelled */);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_DeleteAttributes */

Go
