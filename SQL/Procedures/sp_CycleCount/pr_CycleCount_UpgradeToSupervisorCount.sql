/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/20  OK      pr_CycleCount_UpgradeToSupervisorCount: Refactored the code related to upgrading supervisor code into a new procedure (S2G-711)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_UpgradeToSupervisorCount') is not null
  drop Procedure pr_CycleCount_UpgradeToSupervisorCount;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_UpgradeToSupervisorCount:
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_UpgradeToSupervisorCount
  (@TaskId                TRecordId,
   @LocationId            TRecordId,
   @UserId                TUserId,
   @Businessunit          TBusinessUnit,
   @SupervisorTaskCreated TRecordId output)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vRecordId                 TRecordId,

          @vCurrentTaskPriority      TPriority,
          @vCurrentTaskScheduledDate TDate,

          @vTaskCreated              TRecordId,
          @vLastTaskCreated          TRecordId,
          @vCreatedTasksCount        TCount,
          @vMessage                  TMessage,

          @vLocationInfoXML          xml,
          @vLocationOptionsXML       xml,
          @vXMLInput                 TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
     @vRecordId    = 0;

  /* Cancel the TaskDetail line */
  update TaskDetails
  set Status = 'X' /* Cancel */
  where (TaskId     = @TaskId) and
        (LocationId = @LocationId);

  /* Recount the task */
  exec pr_Tasks_SetStatus @TaskId, @UserId, default /* Status */, 'Y' /* Recount */;

  /* Build the XML for task creation - We will enhance this by using pr_Locations_CreateCycleCountTask later */
  set @vLocationInfoXML = (select LocationId  as 'LocationId',
                                  Location    as 'Location',
                                  PickingZone as 'PickZone'
                           from Locations
                           where (LocationId = @LocationId)
                           for xml raw('LOCATIONINFO'), elements);

  /* Get the current task details */
  select @vCurrentTaskPriority      = Priority,
         @vCurrentTaskScheduledDate = ScheduledDate
  from Tasks
  where (TaskId = @TaskId)

  /* Supervisor count task Priority and ScheduledDate should be the same as user count task, else use defaults */
  set @vLocationOptionsXML = '<OPTIONS>' +
                                dbo.fn_XMLNode('Priority',      coalesce(@vCurrentTaskPriority, '5')) +
                                dbo.fn_XMLNode('ScheduledDate', coalesce(@vCurrentTaskScheduledDate, current_timestamp)) +
                                dbo.fn_XMLNode('SubTaskType',   'L2') +  /* Supervisor count */
                             '</OPTIONS>'

  select @vXMLInput = dbo.fn_XMLNode('CYCLECOUNTTASKS', (convert(varchar(max), @vLocationInfoXML) + convert(varchar(max), @vLocationOptionsXML)));

  /* Call Procedure to create the CC task */
  exec @vReturnCode =  pr_CycleCount_CreateTasks @vXMLInput,
                                                 @BusinessUnit,
                                                 @UserId,
                                                 @SupervisorTaskCreated output,
                                                 @vLastTaskCreated  output,
                                                 @vCreatedTasksCount  output,
                                                 @vMessage     output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_CycleCount_UpgradeToSupervisorCount */

Go
