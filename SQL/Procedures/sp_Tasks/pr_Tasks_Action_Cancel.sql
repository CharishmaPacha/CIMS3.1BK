/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/24  VS      pr_Tasks_Action_Cancel: Cancel the PickTasks in Background process if TD.Count is more than 150 (CIMSV3-1387)
  2021/11/13  VS/AY   pr_Tasks_Action_Cancel: Initial version (CIMSV3-1387)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Action_Cancel') is not null
  drop Procedure pr_Tasks_Action_Cancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Action_Cancel: Cancel the PickTasks from PickTasks page and based
   upon TaskDetails count will cancel the Tasks immediately or defer for later.

    Ex: TD.Count < 50 will cancel immediately
        TD.Count >= 50 will defer cancel
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Action_Cancel
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
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,

          @vWaveNo                     TWaveNo,
          @vxmlRulesData               TXML,
          @ttTaskInfo                  TTaskInfoTable,
          @ttTaskToCancel              TEntityKeysTable,
          @ttDeferTasksToCancel        TRecountKeysTable;
begin /* pr_Tasks_Action_Cancel */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordsUpdated = 0,
         @vRecordId       = 0;

  select @vEntity   = Record.Col.value('Entity[1]',            'TEntity'),
         @vAction   = Record.Col.value('Action[1]',            'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION(OPTIMIZE FOR (@xmlData = null));

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /*----------- Remove ineligible records -----------*/

  /* Get the invalid records into a hash table. This is to get all key values and errors at once for performance reasons */
  select T.TaskId,
  case when (T.Status in ('X', 'C' /* Canceled, Completed */))  then 'PickTask_Cancel_AlreadyCanceledorCompleted'
       when (T.Status in ('XI' /* Cancel-In Progress */))       then 'PickTask_Cancel_CancelInProgress'
  end ErrorMessage
  into #InvalidTasks
  from #ttSelectedEntities SE join Tasks T on (SE.EntityId = T.TaskId);

  /* Exclude the Tasks that have errors */
  delete from SE
  output 'E', IT.TaskId, IT.TaskId, IT.ErrorMessage
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #ttSelectedEntities SE join #InvalidTasks IT on (SE.EntityId = IT.TaskId)
  where (IT.ErrorMessage is not null);

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /*----------- Gather Task Details to Cancel -----------*/
  /* Create required hash tables */
  select * into #TaskDetailsToCancel from @ttTaskInfo;

  /* Insert all the tasks and details for the Wave, and the LPNs which are not picked yet */
  insert into #TaskDetailsToCancel (TaskId, TaskDetailId, TaskSubType, TDRemainingCount, TDCount, TDStatus, ProcessFlag,
                                    WaveId, WaveNo, OrderId, OrderDetailId, SKUId, PalletId,
                                    LPNId, LPNDetailId, TDQuantity, TempLabelId, TempLabel, TempLabelDetailId,
                                    IsLabelGenerated, IsTaskAllocated)
    select TD.TaskId, TD.TaskDetailId, T.TaskSubType, T.DetailCount - T.CompletedCount, T.DetailCount, TD.Status, 'Y',
           TD.WaveId, TD.PickBatchNo, TD.OrderId, OrderDetailId, SKUId, TD.PalletId,
           TD.LPNId, TD.LPNDetailId, TD.Quantity, TD.TempLabelId, TD.TempLabel, TD.TempLabelDetailId,
           TD.IsLabelGenerated, T.IsTaskAllocated
    from #ttSelectedEntities SE
      join Tasks         T on (T.TaskId  = SE.EntityId)
      join TaskDetails  TD on (TD.TaskId = SE.EntityId) and (TD.Status not in ('X', 'C'))
    order by TD.TaskId, TD.TaskDetailId;

  if (@@rowcount = 0) goto ExitHandler; -- if there are no task details to cancel

  /*----------- Evaluate: Defer or Process? -----------*/
  /* If there are too many tasks or too many details we may want to defer the processing and give
     response to user. Or else we may process them right now. Use rules to evaluate  */
  exec pr_RuleSets_ExecuteAllRules 'Task_DeferCancelTask' /* RuleSetType */, @vxmlRulesData, @BusinessUnit;

  /*----------- Defer some if needed -----------*/

  /* Insert Tasks info which are to be deferred */
  insert into @ttDeferTasksToCancel (EntityId, EntityKey)
    select distinct TaskId, 'Task'
    from #TaskDetailsToCancel
    where (ProcessFlag = 'D');

  if (exists(select * from @ttDeferTasksToCancel))
    begin
      /* invoke ExecuteInBackGroup to defer Cancel Tasks */
      exec pr_Entities_ExecuteInBackGround 'Task', null, null /* task */, 'UIAction' /* Process Class */,
                                           @@ProcId, 'TaskCancel'/* Operation */, @BusinessUnit, @ttDeferTasksToCancel;

      /* Update Status for all Tasks that are deferred */
      update T
      set Status       = 'XI',
          ModifiedBy   = @UserId,
          ModifiedDate = current_timestamp
      from Tasks T
        join @ttDeferTasksToCancel DTC on (T.TaskId = DTC.EntityId);

      /* report deferred Tasks back to user */
      insert into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
        select 'I', DTC.EntityId, DTC.EntityId, 'PickTask_TaskCancel_Deferred'
        from @ttDeferTasksToCancel DTC;
    end

  /*----------- Process eligible records -----------*/
  /* Remove the differ process TaskDetails from temp table */
  delete from #TaskDetailsToCancel where ProcessFlag = 'D';

  /* Get the TaskCount */
  select @vRecordsUpdated = count(distinct Taskid) from #TaskDetailsToCancel where ProcessFlag = 'Y';

  /* Cancel the PickTasks immediately */
  exec pr_TaskDetails_CancelMultiple 'Action_TaskCancel', @BusinessUnit, @UserId, 'Y' /* Recount */;

  /* Need to show the message for the immediately processed records only */
  if (@vRecordsUpdated > 0)
    exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_Action_Cancel */

Go
