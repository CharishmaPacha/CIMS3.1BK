/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/09/12  NY      pr_Tasks_UpdateCount: passing param @UserId to show cyclecounted by.
  2012/09/05  AY      pr_Tasks_UpdateCount, SetStatus: Do not update ModifiedDate/By
  2011/12/26  PK      Created pr_Tasks_MarkTaskDetailAsCompleted, pr_Tasks_UpdateCount,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_UpdateCount') is not null
  drop Procedure pr_Tasks_UpdateCount;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_UpdateCount:
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_UpdateCount
  (@TaskId         TRecordId,
   @UpdateOption   TFlag   = '=',
   @DetailCount    TCount  = null,
   @CompletedCount TCount  = null,
   @UserId         TUserId = null)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,

          @vDetailCount       TCount,
          @vCompletedCount    TCount,
          @ModifiedDate       TDateTime,
          @ModifiedBy         TUserId,
          @vCurrentMultiplier TInteger,
          @vNewMultiplier     TInteger;

begin /* pr_Tasks_UpdateCount */
  SET NOCOUNT ON;

  select @ReturnCode = 0,
         @MessageName = null;

  if (@UpdateOption = '=' /* Exact */)
    select @vCurrentMultiplier = '0',
           @vNewMultiplier     = '1';
  else
  if (@UpdateOption = '+' /* Add */)
    select @vCurrentMultiplier = '1',
           @vNewMultiplier     = '1';
  else
  if (@UpdateOption = '-' /* Subtract */)
    select @vCurrentMultiplier = '1',
           @vNewMultiplier     = '-1';

  /* Udpate Tasks */
  update Tasks
  set
    DetailCount    = coalesce((DetailCount     * @vCurrentMultiplier) +
                              (@DetailCount    * @vNewMultiplier), DetailCount),
    CompletedCount = coalesce((CompletedCount  * @vCurrentMultiplier) +
                              (@CompletedCount * @vNewMultiplier), CompletedCount)
  where (TaskId = @TaskId);

  exec @ReturnCode = pr_Tasks_SetStatus @TaskId, @UserId;

  if (@ReturnCode is not null)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Tasks_UpdateCount */

Go
