/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/01  AY      pr_Printing_CreatePrintJobs: Save all the fields from # table (HA Mock GoLive)
  2021/02/21  TK      pr_Printing_EntityPrintRequest & pr_Printing_CreatePrintJobs:
  2021/02/10  MS      pr_Printing_CreatePrintJobs: Changes to update Counts on PrintJobDetails (BK-156)
  2021/01/22  MS      pr_Printing_CreatePrintJobs: Enhanced changes to use PrintJobDetails
                      pr_Printing_CreatePrintJobs: Pass the Operation to compute proper PrintJob Status (HA-1375)
  2020/09/05  PK      pr_Printing_CreatePrintJobs: Added Warehouse field while inserting in PrintJobs table (HA-1233)
  2020/08/28  PK      pr_Printing_CreatePrintJobs: Inserting NumLabels, NumReports & stock sizes for reports & labels in PrintJobs (HA-1017)
  2020/06/24  VS      pr_Printing_CreatePrintJobs: Insert PrintJob Status as 'NR' if it is null (HA-1028)
  2020/06/17  MS      pr_Printing_EntityPrintRequest, pr_Printing_CreatePrintJobs: Changes to execute all rules in RuleSet (HA-853)
  2020/05/21  VS      pr_Printing_CreatePrintJobs: Intial version (HA-331)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_CreatePrintJobs') is not null
  drop Procedure pr_Printing_CreatePrintJobs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_CreatePrintJobs: Processes a print request and creates one or
    more print jobs for the same. Based upon the rules, if the print job has
    several entities to print, then it may break up into multiple print jobs
    with each print job having some entities to print.
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_CreatePrintJobs
  (@PrintRequestId    TRecordId,
   @RulesDataXML      TXML = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vDebug             TFlags,

          @vEntityId          TRecordId,
          @vEntityKey         TEntityKey,
          @vEntityType        TEntity,
          @vModule            TName,
          @vOperation         TOperation,
          @vWaveId            TRecordId,
          @vWaveType          TTypeCode,
          @vLabelsCount       TCount,
          @vPrintRequestXml   TXML,
          @vRequestXml        XML,
          @vBusinessUnit      TBusinessUnit,
          @vRulesDataXML      TXML;

  declare @ttEntitiesToPrint  TEntitiesToPrint,
          @ttCreatedPrintJobs TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vRulesDataXML = @RulesDataXML;

  /* Create Temp tables */
  select * into #PrintJobs        from PrintJobs           where 1 = 2;
  select * into #CreatedPrintJobs from @ttCreatedPrintJobs;
  select * into #PrintJobdetails  from PrintJobDetails     where 1 = 2;
  alter table #PrintJobs drop column BusinessUnit;
  alter table #PrintJobdetails add SeqIndex integer, PrintJobNumber integer;

  if (object_id('tempdb..#EntitiesToPrint') is null) select * into #EntitiesToPrint from @ttEntitiesToPrint;

  /* Get the Request PrintRequest Xml */
  select @vPrintRequestXml = RequestXML,
         @vBusinessUnit    = BusinessUnit
  from PrintRequests
  where (PrintRequestId = @PrintRequestId);

  /* convert into Xml */
  set @vRequestXml = convert(xml, @vPrintRequestXml);

  /* Read the EntityKey and EntityId values */
  select @vEntityType   = Record.Col.value('EntityType[1]',      'TEntity'),
         @vEntityId     = Record.Col.value('EntityId[1]',        'TRecordId'),
         @vEntityKey    = Record.Col.value('EntityKey[1]',       'TEntityKey'),
         @vOperation    = Record.Col.value('Operation[1]',       'TOperation')
  from @vRequestXml.nodes('/EntitiesToPrint/EntityInfo') as Record(Col);

  /* Get the Operation */
  select @vModule       = Record.Col.value('Module[1]',          'TName'),
         @vOperation    = Record.Col.value('Operation[1]',       'TOperation')
  from @vRequestXml.nodes('/Root/Data') as Record(Col);

  /* Get debug options */
  exec pr_Debug_GetOptions @@ProcId, @vOperation, @vBusinessUnit, @vDebug output;

  /* Add entity to list to print, the list may be exploded later into more entities */
  if (not exists(select * from #EntitiesToPrint))
    insert into #EntitiesToPrint(EntityType, EntityId, EntityKey, Operation)
      select @vEntityType, @vEntityId, @vEntityKey, @vOperation

  /* Build the xml for Rules */
  if (@RulesDataXML is null)
    select @RulesDataXML = dbo.fn_XMLNode('RootNode',
                             dbo.fn_XMLNode('Operation',      @vOperation) +
                             dbo.fn_XMLNode('EntityId',       @vEntityId)  +
                             dbo.fn_XMLNode('EntityKey',      @vEntityKey) +
                             dbo.fn_XMLNode('EntityType',     @vEntityType) +
                             dbo.fn_XMLNode('PrintRequestId', @PrintRequestId));

  /* Rules evaluate the #EntitiesToPrint and generate #PrintJobs and/or #PrintJobDetails */
  exec pr_RuleSets_ExecuteAllRules 'PrintJobs_Outbound' /* RuleSetType */, @RulesDataXML, @vBusinessUnit;

  if (charindex('D', @vDebug) > 0)
    begin
      select '#EntitiesToPrint', * from #EntitiesToPrint;
      select '#PrintJobDetails', * from #PrintJobDetails;
      select '#PrintJobs',       * from #PrintJobs;
    end

  /* Insert the records into PrintJobs */
  if (exists (select * from #PrintJobs))
    insert into PrintJobs(PrintRequestId, PrintJobType, PrintJobStatus, PrintJobOperation, EntityType, EntityId, EntityKey, NumLabels, NumReports,
                          NumOrders, NumCartons, Count1, Count2, LabelStockSizes, ReportStockSizes, TotalDocuments, Reference1, Reference2, LabelPrinterName, LabelPrinterName2,
                          ReportPrinterName, Warehouse, BusinessUnit)
      output Inserted.PrintJobId, Inserted.PrintRequestId into #CreatedPrintJobs
      select @PrintRequestId, PrintJobType, coalesce(PrintJobStatus, 'NR'), PrintJobOperation, EntityType, EntityId, EntityKey, NumLabels, NumReports,
             NumOrders, NumCartons, Count1, Count2, LabelStockSizes, ReportStockSizes, TotalDocuments, Reference1, Reference2, LabelPrinterName, LabelPrinterName2,
             ReportPrinterName, Warehouse, @vBusinessUnit
      from #PrintJobs
      order by PrintJobId;

  if (charindex('D', @vDebug) > 0) select '#CreatedPrintJobs',* from #CreatedPrintJobs;

  /* If there are #PrintJobDetails, linke them to the Print jobs created above */
  if exists(select top 1 * from #PrintJobDetails where (PrintRequestId = @PrintRequestId))
    begin
      /* Update PrintJobId on PrintJobDetails */
      update PJD
      set PJD.PrintJobId           = CPJ.EntityId,
          PJD.PrintJobDetailStatus = PJ.PrintJobStatus
      from #PrintJobDetails PJD
        join #CreatedPrintJobs CPJ on (PJD.PrintJobNumber = CPJ.RecordId) and
                                      (PJD.PrintRequestId = CPJ.EntityKey)
        join #PrintJobs         PJ on (PJD.ParentEntityKey = PJ.EntityKey);

      /* Insert PrintJobDetails */
      insert into PrintJobDetails(PrintRequestId, PrintJobId, PrintJobType, PrintJobOperation, ParentEntityId, ParentEntityType, ParentEntityKey,
                                  PrintJobDetailStatus, EntityId, EntityType, EntityKey, Count1, Count2, Count3,
                                  RunningCount1, RunningCount2, RunningCount3, BusinessUnit)
        select PrintRequestId, PrintJobId, PrintJobType, PrintJobOperation, ParentEntityId, ParentEntityType, ParentEntityKey,
               coalesce(PrintJobDetailStatus, 'NR'), EntityId, EntityType, EntityKey, Count1, Count2, Count3,
               RunningCount1, RunningCount2, RunningCount3, BusinessUnit
        from #PrintJobDetails
        order by EntityId;

      /* Finalize the updates required on PrintJobDetails & Printjobs */
      exec pr_RuleSets_ExecuteAllRules 'PrintJobs_Finalize' /* RuleSetType */, @RulesDataXML, @vBusinessUnit;
    end

end /* pr_Printing_CreatePrintJobs */

Go
