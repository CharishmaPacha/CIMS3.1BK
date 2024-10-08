/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/26  KBB     pr_Tasks_Action_AssignUser: Added New action Procedure (CIMSV3-1178)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Action_AssignUser') is not null
  drop Procedure pr_Tasks_Action_AssignUser;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Action_AssignUser: This procedure is used to Assign the users
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Action_AssignUser
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
          @vAction                     TAction,
          @vUserName                   TUserId;

  /* Temp table to hold all the Tasks that are updated */
  declare @ttAssignedTasks             TEntityKeysTable;

begin /* pr_Tasks_Action_AssignUser */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vRecordsUpdated = 0,
         @vAuditActivity  = 'AT_Taskassigned';

  select @vEntity   = Record.Col.value('Entity[1]',            'TEntity'),
         @vAction   = Record.Col.value('Action[1]',            'TAction'),
         @vUserName = Record.Col.value('(Data/AssignUser)[1]', 'TUserId')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION(OPTIMIZE FOR (@xmlData = null));

  /* Check if the UserName is passed or not */
  if (@vUserName is null)
    set @vMessageName = 'UserIsRequired';

  -- Check if given user is active

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the total count of receipts from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* If task status is of invalid status to assign to a user then delete them from #table */
  delete ttSE
  output 'E', 'Tasks_AssignUser_InvalidStatus', T.TaskId
  into #ResultMessages (MessageType, MessageName, Value1)
  from Tasks T join #ttSelectedEntities ttSE on (T.TaskId = ttSE.EntityId)
  where (T.Status not in ('O', 'N', 'I' /* Onhold, New, Inprogress */));

  /* Update all remaining tasks in the temp table. The condition is repeated
     just in case something changed in between */
  update Tasks
  set AssignedTo   = @vUserName,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output Inserted.TaskId into @ttAssignedTasks (EntityId)
  from Tasks T
    join #ttSelectedEntities TT on (T.TaskId = TT.EntityId)
  where (T.Status in ('O'/* Onhold */, 'N' /* New */, 'I' /* In progress */));

  select @vRecordsUpdated = @@rowcount;

   /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Task', EntityId, EntityId, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vUserName, null, null, null, null) /* Comment */
    from @ttAssignedTasks;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_Action_AssignUser */

Go
