/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/01/19  OK      pr_PrintJobs_Action_ReleaseForPrinting: Changes to consider SPL generation instead of Wave Print status
  2021/05/06  SAK     pr_PrintJobs_Action_ReleaseForPrinting: Added validation to restrict the release if PriotJob was OnHold (BK-269)
  2021/02/10  MS      pr_Printing_CreatePrintJobs: Changes to update Counts on PrintJobDetails (BK-156)
                      pr_PrintJobs_Action_Cancel, pr_PrintJobs_Action_Reprint
                      pr_PrintJobs_Action_ReleaseForPrinting: Changes to cancel PrintJobDetails
                      pr_PrintJobDetails_SetStatus: New proc to update PrintJobDetailStatus
  2020/12/17  VS      pr_PrintJobs_Action_ReleaseForPrinting: Update Task.PrintStatus at TaskLevel (CIMSV3-1244)
  2020/12/03  RT      pr_PrintJobs_Action_ReleaseForPrinting: Updating the PrintJobs to ReadyToPrint having Order Type as Entity (HA-1602)
  2020/11/25  VS      pr_PrintJobs_Action_ReleaseForPrinting: Update the Task.PrintFlag as queued to know the status of Task Label after Printjob completed (S2GCA-1397)
  2020/07/30  RV      pr_PrintJobs_Action_ReleaseForPrinting: Made changes to update PrintJob status based upon the Tasks and Wave
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintJobs_Action_ReleaseForPrinting') is not null
  drop Procedure pr_PrintJobs_Action_ReleaseForPrinting;
Go
/*------------------------------------------------------------------------------
  Proc pr_PrintJobs_Action_ReleaseForPrinting: Updates jobs in NR (not ready) status
    to R (ready to process) status and sets the printer names
------------------------------------------------------------------------------*/
Create Procedure pr_PrintJobs_Action_ReleaseForPrinting
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML    = null output)
as
  declare @vMessageName        TMessage,
          @vReturnCode         TInteger,
          @vMessage            TMessage,

          @vPrintJobsCount     TCount,
          @vPrintJobsReleased  TCount,
          @vLabelPrinterName   TName,
          @vLabelPrinterName2  TName,
          @vReportPrinterName  TName;
begin /* pr_PrintJobs_Action_ReleaseForPrinting */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    set @vMessageName = 'InvalidData';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the selected PrintJobs count */
  select @vPrintJobsCount = count(*) from #ttSelectedEntities;

  select @vLabelPrinterName  = Record.Col.value('LabelPrinterName[1]',  'TName'),
         @vLabelPrinterName2 = Record.Col.value('LabelPrinterName2[1]', 'TName'),
         @vReportPrinterName = Record.Col.value('ReportPrinterName[1]', 'TName')
  from @xmlData.nodes('/Root/Data') as Record(Col);

  /* Delete the PrintJobs from the list which are in OnHold Status */
  delete from SE
  output 'E', 'PrintJob_OnHold', Deleted.EntityId
  into #ResultMessages (MessageType, MessageName, Value1)
  from #ttSelectedEntities SE
    join PrintJobs PJ on (PJ.PrintJobId = SE.EntityId)
  where (PJ.PrintJobStatus = 'O' /* OnHold */)

  /* Delete the PrintJobs from the list which are already released */
  delete from SE
  output 'E', 'PrintJob_AlreadyReleased', Deleted.EntityId
  into #ResultMessages (MessageType, MessageName, Value1)
  from #ttSelectedEntities SE
    join PrintJobs PJ on (PJ.PrintJobId = SE.EntityId)
  where (PJ.PrintJobStatus not in ('NR' /* Not Ready */, 'E'))

  /* Updating the selected Print Jobs */
  update PJ
  set PrintJobStatus     = case when dbo.fn_ShipLabel_AreSPGLabelsGenerated (null /* ProcessBatch */, W.WaveId /* WaveId */, null /* TaskId */, null /* OrderId */, null /* LPNId */, @BusinessUnit) = 'N'
                                then 'O' /* Onhold */
                                else 'R' /* Ready To Process */
                           end,
      LabelPrinterName   = @vLabelPrinterName,
      LabelPrinterName2  = @vLabelPrinterName2,
      ReportPrinterName  = @vReportPrinterName,
      ModifiedDate       = current_timestamp
  from PrintJobs PJ
    join #ttSelectedEntities SE on (PJ.PrintJobId = SE.EntityId) and (PJ.EntityType = 'Wave')
    left outer join Waves W on (W.WaveId = PJ.EntityId);

  select @vPrintJobsReleased = @@rowcount;

  /* Update the Tasks as Queued */
  update T
  set LabelsPrinted = 'Q' /* Queued */,
      PrintStatus   = 'Queued',
      ModifiedDate  = current_timestamp
  from #ttSelectedEntities PJTR
    join PrintJobs PJ on (PJ.PrintJobId = PJTR.EntityId) and (PJ.EntityType = 'Wave')
    join Tasks T on (T.WaveId = PJ.EntityId)
  where (T.Status <> 'X' /* Cancel */);

  /* Updating the selected Print Jobs */
  update PJ
  set PrintJobStatus     = case when dbo.fn_ShipLabel_AreSPGLabelsGenerated (null /* ProcessBatch */, null /* WaveId */, PJ.EntityId /* TaskId */, null /* OrderId */, null /* LPNId */, @BusinessUnit) = 'N'
                                then 'O' /* Onhold */
                                else 'R' /* Ready To Process */
                           end,
      LabelPrinterName   = @vLabelPrinterName,
      LabelPrinterName2  = @vLabelPrinterName2,
      ReportPrinterName  = @vReportPrinterName,
      ModifiedDate       = current_timestamp
  from PrintJobs PJ
    join #ttSelectedEntities SE on (PJ.PrintJobId = SE.EntityId) and (PJ.EntityType = 'Task')
    left outer join Tasks T on (T.TaskId = PJ.EntityId);

  select @vPrintJobsReleased += @@rowcount;

  /* Update the Tasks as Queued at Task Level */
  update T
  set LabelsPrinted = 'Q' /* Queued */,
      PrintStatus   = 'Queued',
      ModifiedDate  = current_timestamp
  from #ttSelectedEntities PJTR
    join PrintJobs PJ on (PJ.PrintJobId = PJTR.EntityId) and (PJ.EntityType = 'Task')
    join Tasks T on (T.TaskId = PJ.EntityId)
  where (T.Status <> 'X' /* Cancel */);

  /* Update the selected Print Jobs and set PrintJobStatus to Ready To Print for Order type of Entities */
  update PJ
  set PrintJobStatus     = case when dbo.fn_ShipLabel_AreSPGLabelsGenerated (null /* ProcessBatch */, null /* WaveId */, null /* TaskId */, PJ.EntityId /* OrderId */, null /* LPNId */, @BusinessUnit) = 'N'
                                then 'O' /* Onhold */
                                else 'R' /* Ready To Process */
                           end,
      LabelPrinterName   = @vLabelPrinterName,
      LabelPrinterName2  = @vLabelPrinterName2,
      ReportPrinterName  = @vReportPrinterName,
      ModifiedDate       = current_timestamp
  from PrintJobs PJ
    join #ttSelectedEntities SE on (PJ.PrintJobId = SE.EntityId) and (PJ.EntityType = 'Order')

  select @vPrintJobsReleased += @@rowcount;

  /* Set PrintJobDetails status */
  exec pr_PrintJobDetails_SetStatus null, null, @UserId

  exec pr_Messages_BuildActionResponse 'PrintJobs', 'ReleaseForPrinting', @vPrintJobsReleased, @vPrintJobsCount;

  return(coalesce(@vReturnCode, 0));
end /* pr_PrintJobs_Action_ReleaseForPrinting */

Go
