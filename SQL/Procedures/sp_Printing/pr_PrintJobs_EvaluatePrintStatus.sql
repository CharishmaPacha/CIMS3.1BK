/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_PrintJobs_EvaluatePrintStatus: Added to evaluate PrintStatus of Print jobs
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintJobs_EvaluatePrintStatus') is not null
  drop Procedure pr_PrintJobs_EvaluatePrintStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_PrintJobs_EvaluatePrintStatus: Print jobs are created but sometimes
    there are dependencies and they are not ready to be printed yet. Example:
    Carrier labels for Small package shipments have to be generated before they
    can be printed. Once the dependency is possibly resolved, we need to re-evaluate
    the print jobs and release them from onhold.

    This procedure will evaluate the print jobs for the given entities and updates
    the Print Status of print jobs based on Shiplabels generated for that entity.
    If LPN entities are passed then it will look for all the print jobs for those LPN entities.
    Also it will try to evaluate the higher entity print jobs.

  #PrintJobsToEvaluate   : Future use, not defined yet
  #ttEntitiesToEvaluate  : TEntityKeysTable
------------------------------------------------------------------------------*/
Create Procedure pr_PrintJobs_EvaluatePrintStatus
  (@BusinessUnit         TBusinessUnit,
   @UserId               TUserId)
as
  declare @vMessageName          TMessage,
          @vReturnCode           TInteger,
          @vMessage              TMessage;

  declare @ttPrintJobsToProcess  TEntityKeysTable;

begin /* pr_PrintJobs_EvaluatePrintStatus */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* return if neither Entities nor Print jobs are passed to evalaute */
  if ((object_id('tempdb..#ttPrintJobsToEvaluate') is null) and (object_id('tempdb..#ttEntitiesToEvaluate') is null))
    return;

  /* Create temp tables */
  select * into #PrintJobsToProcess from @ttPrintJobsToProcess;

  /* If PrintJobs are passed to evalaute status then get them */
  if (object_id('tempdb..#ttPrintJobsToEvaluate') is not null)
    insert into #PrintJobsToProcess(EntityId)
      select PrintJobId from #ttPrintJobsToEvaluate;

  /* If caller passed Entities to evaluate then identify the associated Print jobs */
  if (object_id('tempdb..#ttEntitiesToEvaluate') is not null)
    begin
      /* If Wave Entity is passed then fetch all associated Orders */
      insert into #ttEntitiesToEvaluate (EntityId, EntityKey, EntityType)
        select distinct OH.OrderId, OH.PickTicket, 'Order'
        from OrderHeaders OH
          join #ttEntitiesToEvaluate ETE on (ETE.EntityId = OH.PickBatchId) and
                                            (ETE.EntityType = 'Wave') and
                                            (OH.OrderType not in ('B', 'RU'));

      /* Get all the Orders if tasks are passed */
      insert into #ttEntitiesToEvaluate (EntityId, EntityType)
        select distinct TD.OrderId, 'Order'
        from TaskDetails TD
          join #ttEntitiesToEvaluate ETE on (ETE.EntityId = TD.TaskId) and (ETE.EntityType = 'Task')

      /* Get all the LPNs of orders */
      insert into #ttEntitiesToEvaluate (EntityId, EntityKey, EntityType)
        select distinct L.LPNId, L.LPN, 'LPN'
        from LPNS L
          join #ttEntitiesToEvaluate ETE on (ETE.EntityId = L.OrderId) and (ETE.EntityType = 'Order')

      /* LPN Entities */
      update ETE
      set LPN        = L.LPN,
          OrderId    = L.OrderId,
          WaveId     = L.PickBatchId,
          WaveNo     = L.PickBatchNo,
          TaskId     = L.TaskId
      from #ttEntitiesToEvaluate ETE join LPNs L on (ETE.EntityType = 'LPN') and (ETE.EntityId = L.LPNId);

      /* Order Entities */
      update ETE
      set PickTicket = OH.PickTicket,
          WaveId     = OH.PickBatchId,
          WaveNo     = OH.PickBatchNo
      from #ttEntitiesToEvaluate ETE join OrderHeaders OH on (ETE.EntityType = 'Order') and (ETE.EntityId = OH.OrderId);

      /* Task Entities */
      update ETE
      set TaskId     = T.TaskId,
          WaveId     = T.WaveId,
          WaveNo     = T.BatchNo
      from #ttEntitiesToEvaluate ETE join Tasks T on (ETE.EntityType = 'Task') and (ETE.EntityId = T.TaskId);

      /* Wave Entities */
      update ETE
      set WaveId     = W.RecordId,
          WaveNo     = W.WaveNo
      from #ttEntitiesToEvaluate ETE join Waves W on (ETE.EntityType = 'Wave') and (ETE.EntityId = W.WaveId);

      /* Identify Print jobs for Wave entities */
      insert into #PrintJobsToProcess(EntityId)
        select distinct PJ.PrintJobId
        from #ttEntitiesToEvaluate ETE
          join PrintJobs PJ on (PJ.EntityId = ETE.WaveId)
        where (PJ.PrintJobStatus = 'O' /* OnHold */) and (PJ.Archived = 'N') and (PJ.EntityType = 'Wave');

      /* Identify Print jobs for Order entities */
      insert into #PrintJobsToProcess(EntityId)
        select distinct PJ.PrintJobId
        from #ttEntitiesToEvaluate ETE
          join PrintJobs PJ on (PJ.EntityId = ETE.OrderId)
        where (PJ.PrintJobStatus = 'O' /* OnHold */) and (PJ.Archived = 'N') and (PJ.EntityType = 'Order');

      /* Identify Print jobs for Task entities */
      insert into #PrintJobsToProcess(EntityId)
        select distinct PJ.PrintJobId
        from #ttEntitiesToEvaluate ETE
          join PrintJobs PJ on (PJ.EntityId = ETE.TaskId)
        where (PJ.PrintJobStatus = 'O' /* OnHold */) and (PJ.Archived = 'N') and (PJ.EntityType = 'Task');

      /* Identify Print jobs for LPN entities */
      insert into #PrintJobsToProcess(EntityId)
        select distinct PJ.PrintJobId
        from #ttEntitiesToEvaluate ETE
          join PrintJobs PJ on (PJ.EntityId = ETE.LPNId)
        where (PJ.PrintJobStatus = 'O' /* OnHold */) and (PJ.Archived = 'N') and (PJ.EntityType = 'LPN');
    end

 /* If there are no PrintJobs found to evaluate then quit the process */
  if (not exists (select * from #PrintJobsToProcess))
    return;

  /* Evaluate and update the PrintJob status of LPN Entity print jobs */
  update PJ
  set PJ.PrintJobStatus = case when dbo.fn_ShipLabel_AreSPGLabelsGenerated ( null /* ProcessBatch */, null /* WaveId */, null /* TaskId */, null /* OrderId */, PJ.Entityid /* LPNId */, @BusinessUnit) = 'Y'
                               then 'R' /* Ready to process */ else PrintJobStatus end,
      PJ.ModifiedDate   = current_timestamp
  from PrintJobs PJ
    join #PrintJobsToProcess PJP on (PJP.EntityId = PJ.PrintJobId) and (PJ.EntityType = 'LPN')

  /* Evaluate and update the PrintJob status of Order Entity print jobs */
  update PJ
  set PJ.PrintJobStatus = case when dbo.fn_ShipLabel_AreSPGLabelsGenerated( null /* ProcessBatch */, null /* WaveId */, null /* TaskId */, PJ.Entityid /* OrderId */, null /* LPNId */, @BusinessUnit) = 'Y'
                               then 'R' /* Ready to process */ else PrintJobStatus end,
      PJ.ModifiedDate   = current_timestamp
  from PrintJobs PJ
    join #PrintJobsToProcess PJP on (PJP.EntityId = PJ.PrintJobId) and (PJ.EntityType = 'Order')

  /* Evaluate and update the PrintJob status of Task Entity print jobs */
  update PJ
  set PJ.PrintJobStatus = case when dbo.fn_ShipLabel_AreSPGLabelsGenerated( null /* ProcessBatch */, null /* WaveId */, PJ.EntityId /* TaskId */, null /* OrderId */, null /* LPNId */, @BusinessUnit) = 'Y'
                               then 'R' /* Ready to process */ else PrintJobStatus end,
      PJ.ModifiedDate   = current_timestamp
  from PrintJobs PJ
    join #PrintJobsToProcess PJP on (PJP.EntityId = PJ.PrintJobId) and (PJ.EntityType = 'Task')

  /* Evaluate and update the PrintJob status of Wave Entity print jobs */
  update PJ
  set PJ.PrintJobStatus = case when dbo.fn_ShipLabel_AreSPGLabelsGenerated( null /* ProcessBatch */, PJ.Entityid /* WaveId */, null /* TaskId */, null /* OrderId */, null /* LPNId */, @BusinessUnit) = 'Y'
                               then 'R' /* Ready to process */ else PrintJobStatus end,
      PJ.ModifiedDate   = current_timestamp
  from PrintJobs PJ
    join #PrintJobsToProcess PJP on (PJP.EntityId = PJ.PrintJobId) and (PJ.EntityType = 'Wave')

  return(coalesce(@vReturnCode, 0));
end /* pr_PrintJobs_EvaluatePrintStatus */

Go
