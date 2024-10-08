/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/24  AJ      pr_Loads_Action_PrintDocuments: Added new proc to print Documents for load (HA-984)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_PrintDocuments') is not null
  drop Procedure pr_Loads_Action_PrintDocuments;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_PrintDocuments: Procedure to print the documents for the
    selected Loads.
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_PrintDocuments
  (@EntityXML     xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vRecordId              TRecordId,

          @vSelectedDocuments     TName,
          @vLabelPrinterName      TName,
          @vLabelPrinterName2     TName,
          @vReportPrinterName     TName,
          @vRecordsUpdated        TCount,
          @vEntityXML             xml;

begin /* pr_Loads_Action_PrintDocuments */
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null;

  /* Get the PrinterNames */
  select @vLabelPrinterName  = Record.Col.value('(Data/LabelPrinterName) [1]',  'TName'),
         @vLabelPrinterName2 = Record.Col.value('(Data/LabelPrinterName2) [1]', 'TName'),
         @vReportPrinterName = Record.Col.value('(Data/ReportPrinterName) [1]', 'TName')
  from @EntityXML.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @EntityXML = null ));

  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Insert all the entities which need to be printed */
  insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, LabelPrinterName, LabelPrinterName2, ReportPrinterName)
    select EntityType, EntityId, EntityId, 'PrintLoadDocs', @vLabelPrinterName, @vLabelPrinterName2, @vReportPrinterName
    from #ttSelectedEntities

  select @vRecordsUpdated = @@rowcount;

  /* Process the Records and insert PrintJobs */
  exec pr_Printing_EntityPrintRequest 'Load' /* Module */, 'PrintLoadDocs', 'Load', null, null, @BusinessUnit, @UserId;

  /* Insert the messages information to display in V3 application */
  insert into #ResultMessages (MessageType, MessageName, Value1)
    select 'I' /* Info */, 'Load_DocumentsQueued_Successfully', @vRecordsUpdated;

  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_PrintDocuments */

Go
