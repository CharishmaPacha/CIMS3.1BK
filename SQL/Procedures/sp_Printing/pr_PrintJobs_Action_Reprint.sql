/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintJobs_Action_Reprint') is not null
  drop Procedure pr_PrintJobs_Action_Reprint;
Go
/*------------------------------------------------------------------------------
  Proc pr_PrintJobs_Action_Reprint: To updates jobs in R - Ready To Process status
    which are already completed and cancelled
------------------------------------------------------------------------------*/
Create Procedure pr_PrintJobs_Action_Reprint
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML    = null output)
as
  declare @vMessageName        TMessage,
          @vReturnCode         TInteger,
          @vMessage            TMessage,

          @vPrintJobsCount     TCount,
          @vPrintJobsUpdated   TCount,
          @vLabelPrinterName   TName,
          @vLabelPrinterName2  TName,
          @vReportPrinterName  TName;

begin /* pr_PrintJobs_Reprint */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    set @vMessageName = 'InvalidData';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the Input Printer */
  select @vLabelPrinterName  = Record.Col.value('LabelPrinterName[1]',  'TName'),
         @vLabelPrinterName2 = Record.Col.value('LabelPrinterName2[1]', 'TName'),
         @vReportPrinterName = Record.Col.value('ReportPrinterName[1]', 'TName')
  from @xmlData.nodes('/Root/Data') as Record(Col);

  /* Get the selected PrintJobs count */
  select @vPrintJobsCount = count(*) from #ttSelectedEntities;

  /* Delete the PrintJobs from the list which are either not complete or cancelled */
  delete from SE
  output 'E', Deleted.EntityId, 'PrintJobs_JobNotCompletedOrCancelled', Deleted.EntityId
  into #ResultMessages (MessageType, EntityId, MessageName, Value1)
  from #ttSelectedEntities SE
    join PrintJobs PJ on (PJ.PrintJobId = SE.EntityId)
  where (PJ.PrintJobStatus not in ('C', 'X' /* Completed, Cancelled */))

  /* Updating the selected Print Jobs */
  update PJ
  set LabelPrinterName   = @vLabelPrinterName,
      LabelPrinterName2  = @vLabelPrinterName2,
      ReportPrinterName  = @vReportPrinterName,
      PrintJobStatus     = 'R', /* Ready To Process */
      Archived           = 'N'
  from PrintJobs PJ join #ttSelectedEntities SE on PJ.PrintJobId = SE.EntityId;

  select @vPrintJobsUpdated = @@rowcount;

  /* Set PrintJobDetails status */
  exec pr_PrintJobDetails_SetStatus null, null, @UserId

  exec pr_Messages_BuildActionResponse 'PrintJobs', 'Reprint',  @vPrintJobsUpdated, @vPrintJobsCount;

  return(coalesce(@vReturnCode, 0));
end /* pr_PrintJobs_Action_Reprint */

Go
