/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/11  RT      pr_TaskDetails_Action_Export: Procedure to send APIOutboundTrans against the Order when user ReExport the data
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_Action_Export') is not null
  drop Procedure pr_TaskDetails_Action_Export;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_Action_Export: If the picking method is not CIMSRF, then
    the tasks would be executed by an external system and in some cases we may
    need to manually export the tasks. The actual export is done using a trigger
    which depends upon which system to export to.
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_Action_Export
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription,
          @vRecordId             TRecordId,
          /* Audit & Response */
          @vAuditActivity        TActivityType,
          @ttAuditTrailInfo      TAuditTrailInfo,
          @vRecordsUpdated       TCount,
          @vTotalRecords         TCount,
          /* Input variables */
          @vEntity               TEntity,
          @vAction               TAction;

  declare @ttTaskDetailsUpdated  TEntityKeysTable;
begin /* pr_TaskDetails_Action_Export */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_TaskDetail_Export'

  select @vEntity      = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction      = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* delete tasks which are already completed or canceled */
  delete ttSE
  output 'E', TD.TaskDetailId, TD.TaskId, 'TaskDetails_Export_CompletedOrCanceled'
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from TaskDetails TD join #ttSelectedEntities ttSE on (TD.TaskDetailId = ttSE.EntityId)
  where (TD.Status in ('C'/* Completed */, 'X' /* Cancelled */));

  /* Delete the tasks with PickMethod CIMSRF as this is applicable for 6rvr as of now */
  delete ttSE
  output 'I', TD.TaskDetailId, TD.TaskId, 'TaskDetails_Export_InvalidPickMethod'
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from TaskDetails TD
    join #ttSelectedEntities ttSE on (TD.TaskDetailId = ttSE.EntityId)
    join Waves W on (W.WaveId = TD.WaveId)
  where (W.PickMethod = 'CIMSRF');

  /* Delete TaskDetails that are already ReadyToExport */
  delete ttSE
  output 'I', TD.TaskDetailId, TD.TaskId, 'TaskDetails_Export_ReadyToExport'
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from TaskDetails TD join #ttSelectedEntities ttSE on (TD.TaskDetailId = ttSE.EntityId)
  where (TD.ExportStatus = 'ReadyToExport');

  /* Update the remaining TaskDetails */
  update TD
  set ExportStatus = 'ReadyToExport',
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output Inserted.TaskDetailId, Inserted.TaskId
  into @ttTaskDetailsUpdated(EntityId, EntityKey)
  from TaskDetails TD
    join #ttSelectedEntities ttSE on (TD.TaskDetailId = ttSE.EntityId);

  select @vRecordsUpdated = @@rowcount;

  /* Insert Audit Trail against the Task */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Task', EntityKey, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, EntityId, null, null, null, null) /* Comment */
    from @ttTaskDetailsUpdated;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_TaskDetails_Action_Export */

Go
