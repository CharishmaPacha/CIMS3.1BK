/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/11  PKK     pr_Tasks_Action_ConfirmPicks: Initial revision (BK-864)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Action_ConfirmPicks') is not null
  drop Procedure pr_Tasks_Action_ConfirmPicks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Action_ConfirmPicks:
         This proc is used to mark all picks as complete.
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Action_ConfirmPicks
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
          @xmlRulesData                TXML,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          /* Process variables */
          @vValidStatuses              TControlValue,
          @vValidWaveTypes             TControlValue;

declare   @ttTaskPicksInfo             TTaskDetailsInfoTable;

begin /* pr_Tasks_Action_ConfirmPicks */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = '';

  /* Fetching required data from XML */
  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Basic validations of input data or entity info */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get total count from temp table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get Controls */
  select @vValidStatuses = dbo.fn_Controls_GetAsString('Tasks_ComfirmPicks', 'ValidTaskStatuses', 'N', @BusinessUnit, @UserId),
         @vValidWaveTypes = dbo.fn_Controls_GetAsString('Tasks_ComfirmPicks', 'ValidWaveTypes', 'PTS,BPP', @BusinessUnit, @UserId);

  /* Get the invalid records into a hash table. This is to get all key values and errors at once for performance reasons */
  select T.TaskId, cast(T.Status as varchar(30)) as TaskStatus, cast(W.WaveType as varchar(30)) as WaveType,
         case when (dbo.fn_IsInList(W.WaveType, @vValidWaveTypes) = 0) then 'Tasks_ComfirmPicks_InvalidWaveTypes'
              when coalesce(TD.TempLabelId, 0) = 0                     then 'Tasks_ComfirmPicks_NoTempLabels'
              when (T.Status = 'O')                                    then 'Tasks_ComfirmPicks_TasksNotReleased'
              when (dbo.fn_IsInList(T.Status, @vValidStatuses) = 0)    then 'Tasks_ComfirmPicks_InvalidStatus'
         end ErrorMessage
  into #InvalidTasks
  from #ttSelectedEntities SE
    join Tasks T on (SE.EntityId = T.TaskId)
    join TaskDetails TD on (T.TaskId = TD.TaskId)
    join Waves W on (T.WaveId = W.WaveId);

  /* Get the descriptions for the error messages */
  update #InvalidTasks
  set TaskStatus = dbo.fn_Status_GetDescription('Task', TaskStatus, @BusinessUnit),
      WaveType   = dbo.fn_EntityType_GetDescription('Wave', wavetype, @BusinessUnit);

  /* Exclude the LPNs that are not putaway as we cannot change Ownership of LPNs that are
     assigned to any Orders */
  delete from SE
  output 'E', IT.TaskId, IT.TaskId, IT.ErrorMessage, IT.TaskStatus, IT.WaveType
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2, Value3)
  from #ttSelectedEntities SE join #InvalidTasks IT on SE.EntityId = IT.TaskId
  where (IT.ErrorMessage is not null);

  /* when picking in consolidated more, get all details of scanned SKU and confirm all the picks at once */
  insert into @ttTaskPicksInfo(PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, FromLPNId, FromLPNDetailId,
                               FromLocationId, TempLabelId, TempLabelDtlId, QtyPicked)
    select TD.PickBatchNo, TD.TaskDetailId, TD.OrderId, TD.OrderDetailId, TD.SKUId, TD.LPNId, TD.LPNDetailId,
           TD.LocationId, TD.TempLabelId, TD.TempLabelDetailId, TD.Quantity
    from TaskDetails TD
      join #ttSelectedEntities SE on (TD.TaskId = SE.EntityId)

  /* Call ConfirmPicks procedure to complete the pick */
  exec pr_Picking_ConfirmPicks @ttTaskPicksInfo, 'ConfirmTaskPick', @BusinessUnit, @UserId, default/* Debug */;

  /* Get the total Updated count */
  select @vRecordsUpdated = count(*)
  from Tasks T join #ttSelectedEntities SE on (T.TaskId = SE.EntityId)
  where T.Status = 'C' /* Completed */ ;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_Action_ConfirmPicks */

Go
