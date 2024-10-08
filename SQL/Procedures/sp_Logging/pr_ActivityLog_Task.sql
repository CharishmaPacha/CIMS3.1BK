/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ActivityLog_Task') is not null
  drop Procedure pr_ActivityLog_Task;
Go
/*------------------------------------------------------------------------------
  Proc pr_ActivityLog_Task: To Log Task or TaskDetails related details of given operation
  ------------------------------------------------------------------------------*/
Create Procedure pr_ActivityLog_Task
  (@Operation      TDescription,
   @TaskId         TRecordId,
   @ttTasks        TEntityKeysTable ReadOnly,
   @Entity         TEntity       = 'Task',
   @ProcId         TInteger      = 0,
   @Message        TDescription  = null,
   @DeviceId       TDeviceId     = null,
   @BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = 'CIMS',
   @ActivityLogId  TRecordId     = null output)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vxmlLogData   TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the Task or Task Details info for logging */
  if (exists (select * from @ttTasks)) and (@Entity = 'Tasks')
    select @vxmlLogData = (select T.* from @ttTasks ttT join Tasks T on (ttT.EntityId = T.TaskId)
                           for XML raw('Tasks'), elements);
  else
  if (exists (select * from @ttTasks)) and (@Entity = 'TaskDetails')
    select @vxmlLogData = (select TD.* from @ttTasks ttTD join TaskDetails TD on (ttTD.EntityId = TD.TaskDetailId)
                           for XML raw('TaskDetails'), elements);
  else
  if (@Entity = 'Task')
    select @vxmlLogData = (select T.* from Tasks T where (T.TaskId = @TaskId)
                           for XML raw('Tasks'), elements);
  else
    select @vxmlLogData = (select TD.* from TaskDetails TD where (TD.TaskId = @TaskId)
                           for XML raw('TaskDetails'), elements);

  /* insert into activitylog details */
  exec pr_ActivityLog_AddMessage @Operation, @TaskId, null, @Entity,
                                 @Message, @ProcId, @vxmlLogData, @BusinessUnit, @UserId,
                                 @ActivityLogId = @ActivityLogId output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ActivityLog_Task */

Go
