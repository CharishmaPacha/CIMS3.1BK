/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_DeleteAttributes') is not null
  drop Procedure pr_PickBatch_DeleteAttributes;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_DeleteAttributes
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_DeleteAttributes
  (@PickBatchId    TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription;
begin
  select @ReturnCode   = 0;

  if (@PickBatchId is null)
    return;

  /* Update PickbatchAttributes to inactive */
  update PickBatchAttributes
  set Status = 'I',
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  where (PickBatchId = @PickBatchId) and
        (Status = 'X' /* Cancelled */);

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));

end /* pr_PickBatch_DeleteAttributes */

Go
