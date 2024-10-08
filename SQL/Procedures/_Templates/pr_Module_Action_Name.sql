/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/18  AY      pr_Module_Action_Name: Model action for V3
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Module_Action_Name') is not null
  drop Procedure pr_Module_Action_Name;
Go
/*------------------------------------------------------------------------------
  Proc pr_Module_Action_Name:
------------------------------------------------------------------------------*/
Create Procedure pr_Module_Action_Name
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
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
          /* Process variables */

begin /* pr_Module_Action_Name */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = '';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Basic validations of input data or entity info */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Remove unqualified entities and insert those into #ResultMessages at the same time */
  delete from SE
  output 'E', Deleted.EntityId, 'Module_Action_ErrorName', Deleted.EntityId
  into #ResultMessages (MessageType, EntityId, MessageName, Value1)
  from #ttSelectedEntities SE
  --   join PrintJobs PJ on (PJ.PrintJobId = SE.EntityId)
  -- where (PJ.PrintJobStatus not in ('C', 'X' /* Completed, Cancelled */))

  /* Perform the actual updates */

  select @vRecordsUpdated = @@rowcount;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Entity', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, EntityKey, null, null, null, null) /* Comment */
    from #SelectedEntities;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Module_Action_Name */

Go
