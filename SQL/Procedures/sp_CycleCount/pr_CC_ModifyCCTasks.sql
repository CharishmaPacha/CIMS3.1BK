/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/08/24  NY      pr_CC_ModifyCCTasks: New procedure to cancel CC tasks
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CC_ModifyCCTasks') is not null
  drop Procedure pr_CC_ModifyCCTasks;
Go
/*------------------------------------------------------------------------------
  Proc pr_CC_ModifyCCTasks:
  Sample XML:
  <Root>
  <Action>CancelCCTasks</Action>
  <Tasks>
      <TaskId></TaskId >
     ...

  </Tasks>

 </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_CC_ModifyCCTasks
  (@CCTasksContents    TXML,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Message            TMessage output)
as
  declare @vAction        TAction,
          @ReturnCode     TInteger,
          @xmlData        xml,
          @vTaskId        TRecordId,
          @vRecordId      TRecordId,
          @vTasksCount    TCount,
          @vTasksUpdated  TCount,
          @NewStatus      TStatus,
          @MessageName    TMessage  = null;

   /* Temp table to hold all the Tasks to be updated */
  declare @ttCCTasks      TEntityKeysTable;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @vRecordId   = 0;

  set @xmlData = convert(xml, @CCTasksContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    begin
      set @MessageName = 'InvalidData';
      goto ErrorHandler;
    end

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/Root') as Record(Col);

  if (@vAction = 'CancelCCTasks')
    begin
      /* Load all the Tasks into the temp table  */
      insert into @ttCCTasks (EntityId)
        select Record.Col.value('.', 'TRecordId') TaskId
        from @xmlData.nodes('/Root/Tasks/TaskId') as Record(Col);

      /* get the selected tasks count */
      select @vTasksCount = @@rowcount;

      /* Delete the Tasks which are in Cancel and Completed status */
      delete from CCT
      from @ttCCTasks CCT
      join Tasks T on (T.TaskId  = CCT.EntityId)
      where (T.Status in ( 'C'/* Complete */, 'X'/* Cancel */))

      /* Loop through all tasks and cancel any open details */
      while (exists(select * from @ttCCTasks where RecordId > @vRecordId))
        begin
          select Top 1 @vTaskId     = EntityId,
                       @vRecordId   = RecordId
          from @ttCCTasks
          where (RecordId > @vRecordId);

          /* Updating the selected tasks' details */
          update TD
          set status = 'X'
          from TaskDetails TD
          where (TD.TaskId =  @vTaskId) and
                (TD.Status not in ('C'/* Complete */, 'X'/* Cancel */));

          /* Recalc Task status */
          exec pr_Tasks_SetStatus @vTaskId, @UserId, null, 'Y';
        end

      /* Get the no. of rows updated */
      select @vTasksUpdated = count(*)
      from @ttCCTasks;
    end

  exec @Message = dbo.fn_Messages_BuildActionResponse  'CycleCount', @vAction,  @vTasksUpdated, @vTasksCount;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_CC_ModifyCCTasks */

Go
