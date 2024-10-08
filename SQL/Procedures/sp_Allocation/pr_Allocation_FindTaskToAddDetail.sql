/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_FindTaskToAddDetail') is not null
  drop Procedure pr_Allocation_FindTaskToAddDetail;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_FindTaskToAddDetail
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_FindTaskToAddDetail
  (@Category1      TCategory,
   @Category2      TCategory,
   @Operation      TDescription,
   @TaskId         TRecordId = null output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription;
begin
  select @ReturnCode   = 0;

  /* Get TaskId here based on the picktype */
  select top 1 @TaskId = T.TaskId
  from Tasks T
  join TaskDetails TD on (T.TaskId = TD.TaskId)
  where (TD.TDCategory1 = @Category1) and
        (TD.TDCategory2 = @Category2) and
        (T.Status = 'O' /* On hold */)
  order by T.TaskId;

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));

end /* pr_Allocation_FindTaskToAddDetail */

Go
