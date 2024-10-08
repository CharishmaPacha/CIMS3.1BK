/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/27  SJ      pr_ReplenishOrders_Action_Archive: Added Proc (HA-376)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReplenishOrders_Action_Archive') is not null
  drop Procedure pr_ReplenishOrders_Action_Archive;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReplenishOrders_Action_Archive: Procedure to archive replenish orders.
    Archive is a process normally done as a nightly job, but if users wanted to
    archive the completed ones during the day, they could use the action to do so
------------------------------------------------------------------------------*/
Create Procedure pr_ReplenishOrders_Action_Archive
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
begin /* pr_ReplenishOrders_Action_Archive */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = '';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of orders from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If selected Records alredy archived delete them from #table */
  delete ttSE
  output 'E', 'ReplenishOrders_Archive_AlreadyArchived', OH.PickTicket
  into #ResultMessages (MessageType, MessageName, Value1)
  from OrderHeaders OH join #ttSelectedEntities ttSE on (OH.OrderId = ttSE.EntityId)
  where (OH.Archived  = 'Y'); /* Don't need to archive the already archived orders  */

  /* If any of the Orders have invalid status then exclude them */
  delete ttSE
  output 'E', 'ReplenishOrders_Archive_InvalidStatus', OH.PickTicket, OH.Status
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from OrderHeaders OH join #ttSelectedEntities ttSE on (OH.OrderId = ttSE.EntityId)
  where (OH.Status not in ('S', 'D', 'X', 'V' /* Shipped/Completed/Canceled/Invoiced */));

  /* Get the status desc - more optimal way of doing rather than using vwOH above */
  update #ResultMessages
  set Value2 = dbo.fn_Status_GetDescription ('Order', Value2, @BusinessUnit)
  where (MessageName = 'ReplenishOrders_Archive_InvalidStatus');

  /* Update the Orders table */
  update OH
  set Archived = 'Y' /* Yes */
  from OrderHeaders OH
    join #ttSelectedEntities TOH on(OH.OrderId = TOH.EntityId);

  set @vRecordsUpdated = @@rowcount;

  /* No Audit trial is required for this action */

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_ReplenishOrders_Action_Archive */

Go
