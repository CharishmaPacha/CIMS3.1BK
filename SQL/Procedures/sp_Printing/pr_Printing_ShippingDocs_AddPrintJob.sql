/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/02  RV      pr_Printing_ShippingDocs_AddPrintJob: Initial version (HA-1659)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_ShippingDocs_AddPrintJob') is not null
  drop Procedure pr_Printing_ShippingDocs_AddPrintJob;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_ShippingDocs_AddPrintJob: When user invokes printing from UI
    Shipping Docs, the request may be fulfilled interactively in UI or may be by
    Print job processor depending upon the volume of data being requested.
    If it is printed immediately, then the #PrintList would be returned with the
    PrintData to UI for all possible records and on user selection, only selected
    records would be printed.
    If it is to be printed later, then the #PrintList would be returned without
    the PrintData and after the user selects the records to be printed, this
    procedure will be invoked which saves the list of selected records in the
    Print Job for print processor to print.
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_ShippingDocs_AddPrintJob
  (@PrintListInputXML      TXML,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @ResultXML              TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,

          @vPrintListInputXML     XML,
          @vPrintRequestId        TRecordId,
          @vPrintJobId            TRecordId,
          @vPrintJobType          TDescription,
          @vLabelPrinterName      TName,
          @vReportPrinterName     TName,

          @vNumLabels             TCount,
          @vNumReports            TCount,
          @vWarehouse             TWarehouse;

  declare @ttPrintList            TPrintList,
          @ttResultMessages       TResultMessagesTable,
          @ttResultData           TNameValuePairs;
begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vReturnCode        = 0,
         @vMessageName       = null,
         @vRecordId          = 0,
         @vNumLabels         = 0,
         @vNumReports        = 0,
         @vPrintListInputXML = cast(@PrintListInputXML as xml);

  if (object_id('tempdb..#ResultMessages') is null) select * into #ResultMessages from @ttResultMessages;
  if (object_id('tempdb..#ResultData') is null) select * into #ResultData from @ttResultData;
  if (object_id('tempdb..#PrintList') is null) select * into #PrintList from @ttPrintList;

  insert into #PrintList (EntityType, EntityId, EntityKey,
                          PrintRequestId, DocumentClass, DocumentSubClass,
                          DocumentType, DocumentSubType, PrinterName, SortSeqNo)
    select Record.Col.value('EntityType[1]', 'TEntity'), Record.Col.value('EntityId[1]', 'TRecordId'), Record.Col.value('EntityKey[1]', 'TEntityKey'),
           Record.Col.value('PrintRequestId[1]', 'TRecordId'), Record.Col.value('DocumentClass[1]', 'TTypeCode'), Record.Col.value('DocumentSubClass[1]', 'TTypeCode'),
           Record.Col.value('DocumentType[1]', 'TTypeCode'), Record.Col.value('DocumentSubType[1]', 'TTypeCode'), Record.Col.value('PrinterName[1]', 'TName'), Record.Col.value('SortSeqNo[1]', 'TSortSeq')
    from @vPrintListInputXML.nodes('/PrintList/PrintListRecord') as Record(Col)
    OPTION ( OPTIMIZE FOR ( @vPrintListInputXML = null ));

  select top 1 @vPrintRequestId    = min(PrintRequestId),
               @vLabelPrinterName  = min(case when (DocumentClass = 'Label') then PrinterName else null end),
               @vReportPrinterName = min(case when (DocumentClass = 'Report') then PrinterName else null end),
               @vNumLabels         = sum(case when (DocumentClass = 'Label') then 1 else 0 end),
               @vNumReports        = sum(case when (DocumentClass = 'Report') then 1 else 0 end)
  from #PrintList

  /* In future we will send printer name instead of unified name, So first find with the printer name and then with unified name */
  select @vLabelPrinterName = PrinterName
  from vwPrinters
  where (PrinterName = @vLabelPrinterName) or (PrinterNameUnified = @vLabelPrinterName);

  /* In future we will send printer name instead of unified name, So first find with the printer name and then with unified name */
  select @vReportPrinterName = PrinterName
  from vwPrinters
  where (PrinterName = @vReportPrinterName) or (PrinterNameUnified = @vReportPrinterName);

  if (coalesce(@vPrintRequestId, 0) = 0)
    select @vMessageName = 'InvalidPrintRequest';
  else
  if (@vLabelPrinterName is null) and (@vReportPrinterName is null)
    select @vMessageName = 'PrintJobs_InvalidPrinter';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    goto ErrorHandler;

  select @vWarehouse = Warehouse
  from PrintRequests
  where (PrintRequestId = @vPrintRequestId);

  /* Build the print job type based upon the documents available to print */
  select @vPrintJobType = dbo.fn_AppendStrings(case when @vNumLabels  > 0 then 'Label'  else null end, default /* delimiter */,
                                               case when @vNumReports > 0 then 'Report' else null end);

  insert into PrintJobs(PrintRequestId, PrintJobType, PrintJobOperation, PrintJobStatus, LabelPrinterName, ReportPrinterName, PrintJobInfo, NumLabels, NumReports, Warehouse, BusinessUnit)
    select @vPrintRequestId, @vPrintJobType, 'ShippingDocs', 'R' /* Ready To Print */, @vLabelPrinterName, @vReportPrinterName, @PrintListInputXML, @vNumLabels, @vNumReports, @vWarehouse, @BusinessUnit

  select @vPrintJobId = Scope_Identity();

  insert into #ResultMessages (MessageType, MessageName, Value1) select 'I' /* Info */, 'ShippingDocs_DocumentsQueued', @vPrintJobId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    insert into #ResultMessages (MessageType, MessageName) select 'E' /* Error */, @vMessageName;

  exec pr_Entities_BuildMessageResults null /* Entity */, null /* Action */, @ResultXML output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_ShippingDocs_AddPrintJob */

Go
