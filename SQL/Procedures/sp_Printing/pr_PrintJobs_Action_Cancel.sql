/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/05  RV      pr_PrintJobs_Action_Cancel: Made changes to reset the printer while cancel the print job (HA-2059)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintJobs_Action_Cancel') is not null
  drop Procedure pr_PrintJobs_Action_Cancel;
Go
/*------------------------------------------------------------------------------
Proc pr_PrintJobs_Action_Cancel: Cancel the jobs as given in #ttSelectedEntities
------------------------------------------------------------------------------*/
Create Procedure pr_PrintJobs_Action_Cancel
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML    = null output)
as
  declare @vMessage           TDescription,
          @vReturnCode        TInteger,
          @vUpdatedRecords    TRecordId,
          @vTotalRecords      TRecordId;

  declare @ttPrintersToUpdate table(PrintJobId     TRecordId,
                                    PrintJobStatus TStatus,
                                    PrinterName    TName);

begin /* pr_PrintJobs_Action_Cancel */

  /* Load all the PrintJobs into the temp table  */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  delete ttSE
  output 'E', 'PrintJobCancel_AlreadyCompletedOrCancelled', Deleted.EntityId
  into #ResultMessages (MessageType, MessageName, Value1)
  from PrintJobs P join #ttSelectedEntities ttSE on (P.PrintJobId = ttSE.EntityId)
  where (P.PrintJobStatus in ('C'/* Completed */, 'X'/* Canceled */));

  update PrintJobs
  set PrintJobStatus = 'X' /* Canceled */
  output inserted.PrintJobId, deleted.PrintJobStatus, inserted.LabelPrinterName into @ttPrintersToUpdate(PrintJobId, PrintJobStatus, PrinterName)
  from PrintJobs P
    join #ttSelectedEntities ttSE on (P.PrintJobId = ttSE.EntityId)
  where (P.PrintJobStatus not in ('C'/* Completed */, 'X'/* Canceled */));

  set @vUpdatedRecords = @@rowcount;

  /* Set PrintJobDetails status */
  exec pr_PrintJobDetails_SetStatus null, null, @UserId

  /* When PrintJob canceled, bring Label Printer status back to Ready */
  update P
  set PrintStatus = 'Ready'
  from Printers P
    join @ttPrintersToUpdate PTU on (P.PrinterName = PTU.PrinterName)
  where (PTU.PrintJobStatus = 'IP' /* In Progress */);

  exec pr_Messages_BuildActionResponse 'PrintJob' , 'PrintJobs_Cancel',  @vUpdatedRecords, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_PrintJobs_Action_Cancel */

Go
