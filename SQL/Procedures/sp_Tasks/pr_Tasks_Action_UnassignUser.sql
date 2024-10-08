/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/09  VM      pr_Tasks_Action_UnassignUser: Do not need PickTask Id to log as this AT is shown for that Task only (OB2-1821)
  2020/07/21  SJ      pr_Tasks_Action_UnassignUser: Added new proc to clear user assignment(HA-1134)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Action_UnassignUser') is not null
  drop Procedure pr_Tasks_Action_UnassignUser;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Action_UnassignUser: This procedure is used to clear the user
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Action_UnassignUser
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML        = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction;

  declare @ttUnassignedTasks table
          (TaskId       TRecordId,
           AssignedTo   TUserId,
           RecordId     TRecordId identity(1,1));
begin /* pr_Tasks_Action_UnassignUser */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vRecordsUpdated = 0,
         @vAuditActivity  = 'AT_TaskUnassigned';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of receipts from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Eliminate tasks which are already completed or canceled */
  delete ttSE
  output 'E', T.TaskId, T.TaskId, 'Tasks_UnassignUser_CompletedOrCanceled'
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from Tasks T join #ttSelectedEntities ttSE on (T.TaskId = ttSE.EntityId)
  where (T.Status in ('C'/* Completed */, 'X' /* Cancelled */));

  /* Eliminate tasks which are not assigned to anyone */
  delete ttSE
  output 'I', T.TaskId, T.TaskId, 'Tasks_UnassignUser_NotAssigned'
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from Tasks T join #ttSelectedEntities ttSE on (T.TaskId = ttSE.EntityId)
  where (T.AssignedTo is null);

  /* Eliminate tasks which are not of valid status */
  delete ttSE
  output 'I', T.TaskId, T.TaskId, 'Tasks_UnassignUser_InvalidStatus'
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from Tasks T join #ttSelectedEntities ttSE on (T.TaskId = ttSE.EntityId)
  where (T.Status not in ('O'/* Onhold */, 'N' /* New */, 'I' /* In progress */));

  /* Update all remaining tasks in the temp table */
  update Tasks
  set AssignedTo   = null,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output deleted.TaskId, deleted.AssignedTo
  into @ttUnassignedTasks (TaskId, AssignedTo)
  from Tasks T join #ttSelectedEntities ttSE on (T.TaskId = ttSE.EntityId)
  where (T.Status in ('O'/* Onhold */, 'N' /* New */, 'I' /* In progress */));

  select @vRecordsUpdated = @@rowcount

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Task', TaskId, TaskId, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, AssignedTo, null, null, null, null) /* Comment */
    from @ttUnassignedTasks;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_Action_UnassignUser */

Go
