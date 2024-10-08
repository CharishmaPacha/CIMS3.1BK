/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/22  RKC     pr_CycleCount_Action_CancelTasks, pr_CycleCount_UpgradeToSupervisorCount, pr_CC_ModifyCCTasks:
                      pr_CycleCount_Action_CancelTasks: (CIMSV3-549, CIMSV3-1066)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_Action_CancelTasks') is not null
  drop Procedure pr_CycleCount_Action_CancelTasks;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_Action_CancelTasks: Procedure to cancel selected CC Tasks
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_Action_CancelTasks
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
         /* Temp tables */
          @ttTasksCancelled            TRecountKeysTable;
begin /* pr_Module_Action_Name */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'CycleCountTasks_Cancel';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Total tasks selected */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Basic validations of input data or entity info */
  -- None at this time

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Delete the Tasks which are already Canceled or Completed */
  delete from SE
  output 'E', cast(Deleted.EntityId as varchar(15)),
          case when T.Status = 'C' then 'CC_CancelTask_AlreadyCompleted'
               else                     'CC_CancelTask_AlreadyCanceled'
          end
  into #ResultMessages (MessageType, EntityKey, MessageName)
  from #ttSelectedEntities SE join Tasks T on (T.TaskId = SE.EntityId)
  where (T.Status in ( 'C'/* Complete */, 'X'/* Cancel */));

  /* Perform the actual updates */

  /* Updating the selected tasks' details as canceled */
  update TD
  set Status       = 'X',
      ModifiedDate = current_timestamp
  output Inserted.TaskId into @ttTasksCancelled (EntityId)
  from TaskDetails TD join #ttSelectedEntities SE on (TD.TaskId = SE.EntityId) and
                                                     (TD.Status not in ('C' /* Complete */, 'X' /* Cancel */));

  /* Recalc Task status */
  exec pr_Tasks_Recalculate @ttTasksCancelled, default, @UserId;

  /* Get count of tasks that were actually canceled */
  select @vRecordsUpdated = count(distinct EntityId) from @ttTasksCancelled;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select distinct 'CCTasks', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, EntityId, null, null, null, null) /* Comment */
    from @ttTasksCancelled;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_CycleCount_Action_CancelTasks */

Go
