/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/25  MS      pr_Tasks_Action_PrintDocuments: Cchanges to sugnature as per new format (CIMSV3-984)
  2020/06/17  MS      pr_Tasks_Action_PrintDocuments: Added new proc to print Task Documents (HA-853)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Action_PrintDocuments') is not null
  drop Procedure pr_Tasks_Action_PrintDocuments;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Action_PrintDocuments: Procedure to print Task Documents
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Action_PrintDocuments
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML    = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vRecordId              TRecordId,

          @vLabelPrinterName      TName,
          @vLabelPrinterName2     TName,
          @vReportPrinterName     TName,
          @vRecordsUpdated        TCount;

begin /* pr_Tasks_Action_PrintDocuments */
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null;

  /* Get the PrinterNames */
  select @vLabelPrinterName  = Record.Col.value('(Data/LabelPrinterName) [1]',  'TName'),
         @vLabelPrinterName2 = Record.Col.value('(Data/LabelPrinterName2) [1]', 'TName'),
         @vReportPrinterName = Record.Col.value('(Data/ReportPrinterName) [1]', 'TName')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ));

  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Insert all the entities which need to be printed */
  insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, LabelPrinterName, LabelPrinterName2, ReportPrinterName)
    select EntityType, EntityId, EntityId, 'PrintTasks', @vLabelPrinterName, @vLabelPrinterName2, @vReportPrinterName
    from #ttSelectedEntities

  /* Process the Records and insert PrintJobs */
  exec pr_Printing_EntityPrintRequest 'Tasks' /* Module */, 'PrintTasks', 'Task', null, null, @BusinessUnit, @UserId;

  /* Insert the messages information to display in V3 application */
  insert into #ResultMessages (MessageType, MessageName, Value1)
    select 'I' /* Info */, 'Task_DocumentsQueued_Successful', @vRecordsUpdated;

  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_Action_PrintDocuments */

Go
