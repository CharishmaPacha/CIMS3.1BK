/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/04/27  TK      pr_Tasks_RecomputePrintStatus: Initial Revision (CIDV3-676)
------------------------------------------------------------------------------*/

if object_id('dbo.pr_Tasks_RecomputePrintStatus') is not null
  drop Procedure pr_Tasks_RecomputePrintStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_RecomputePrintStatus recomputes the print status on all the tasks which
    have PrintStatus of OnHold & their corresponding waves. When all ship labels are
    generated, we would update the print jobs with print status of 'ReadyToPrint'
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_RecomputePrintStatus
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ttPrintJobsReleased     TRecountKeysTable;
begin
  SET NOCOUNT ON;

  /* Create required hash tables */
  select * into #PrintJobsReleased from @ttPrintJobsReleased;

  /* Get all the tasks with print status as OnHold */
  select TaskId, WaveId, PrintStatus, BusinessUnit
  into #TasksToRecomputePrintStatus
  from Tasks
  where (TaskType = 'PB' /* PickBatch */) and
        (Status not in ('C', 'X' /* Completed, Canceled */)) and
        (PrintStatus = 'OnHold');

  /* Get all the shiplabels for the task */
  select SL.TaskId, SL.IsValidTrackingNo
  into #TaskShipLabels
  from ShipLabels SL
    join #TasksToRecomputePrintStatus TRP on (SL.TaskId = TRP.TaskId) and
                                             (SL.Archived = 'N');

  /*---------- Recompute print status on tasks ----------*/
  /* if shiplabels generated for all the ship cartons, update print status as 'ReadyToPrint'
     if there are no records in ship labels table, update print status as 'ReadyToPrint'
     if at-least one record in ship labels table has no valid trackingno, update print status as 'OnHold' */
  ;with TrackingNos as
  (
    select TRP.TaskId, sum(iif(TSL.IsValidTrackingNo = 'N', 1, 0)) InvalidTrackingNos
    from #TasksToRecomputePrintStatus TRP
      left outer join #TaskShipLabels TSL on (TRP.TaskId = TSL.TaskId)  -- left join: need to release that tasks for which there is no shiplabel
    group by TRP.TaskId
  )
  update TRP
  set PrintStatus = iif(InvalidTrackingNos > 0, 'OnHold', 'ReadyToPrint')
  from #TasksToRecomputePrintStatus TRP
    join TrackingNos TN on (TRP.TaskId = TN.TaskId);

  /* Update print status on tasks */
  update T
  set PrintStatus = TRP.PrintStatus
  from Tasks T
    join #TasksToRecomputePrintStatus TRP on (T.TaskId = TRP.TaskId);

  /*---------- Recompute print status on Waves ----------*/
  /* if all the task's print status is 'ReadyToPrint' then wave will be ReadyToPrint
     if atleast one task print status is 'OnHold' then whole wave will be 'OnHold' */
  ;with OnholdTasks as
  (
    select TRP.WaveId,
           sum(iif(T.PrintStatus = 'OnHold' and T.Status not in ('X', 'C' /* Cancelled, Completed */), 1, 0)) OnholdTasksCount
    from #TasksToRecomputePrintStatus TRP
      join Tasks T on (TRP.WaveId = T.WaveId)
    group by TRP.WaveId
  )
  update W
  set PrintStatus = case when OT.OnHoldTasksCount > 0 then 'OnHold' else 'ReadyToPrint' end
  from Waves W
    join OnholdTasks OT on (W.WaveId = OT.WaveId);

  /*---------- Release Print Jobs ----------*/

  /* Release the print jobs for Task entity */
  update PJ
  set PrintJobStatus = 'R' /* Ready to process */,
      ModifiedBy     = @UserId,
      ModifiedDate   = current_timestamp
  output inserted.PrintJobId, inserted.PrintJobStatus into #PrintJobsReleased (EntityId, UDF1)
  from PrintJobs PJ
    join #TasksToRecomputePrintStatus TRP on (TRP.PrintStatus   = 'ReadyToPrint') and
                                             (TRP.TaskId        = PJ.EntityId) and
                                             (PJ.EntityType     = 'Task') and
                                             (PJ.PrintJobStatus = 'O' /* OnHold */);

  /* Release the print jobs for Wave entity */
  update PJ
  set PrintJobStatus = 'R' /* Ready to process */,
      ModifiedBy     = @UserId,
      ModifiedDate   = current_timestamp
  output inserted.PrintJobId, inserted.PrintJobStatus into #PrintJobsReleased (EntityId, UDF1)
  from #TasksToRecomputePrintStatus TP
    join Waves W on (TP.WaveId = W.WaveId)
    join PrintJobs PJ on (W.PrintStatus     = 'ReadyToPrint') and
                         (W.WaveId          = PJ.EntityId) and
                         (PJ.EntityType     = 'Wave') and
                         (PJ.PrintJobStatus = 'O' /* OnHold */);

  /* Release print job details */
  update PJD
  set PrintJobDetailStatus = PJR.UDF1, -- PrintJob.PrintJobStatus
      ModifiedBy           = @UserId,
      ModifiedDate         = current_timestamp
  from PrintJobDetails PJD
    join #PrintJobsReleased PJR on (PJR.EntityId = PJD.PrintJobId);

end /* pr_Tasks_RecomputePrintStatus */

Go

