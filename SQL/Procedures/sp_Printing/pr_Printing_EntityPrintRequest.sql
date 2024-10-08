/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/05  YJ      pr_Printing_EntityPrintRequest: Ported changes done by Pavan (HA-2152)
  2021/02/21  TK      pr_Printing_EntityPrintRequest & pr_Printing_CreatePrintJobs:
  2021/02/17  MS      pr_Printing_ProcessPrintList, pr_Printing_EntityPrintRequest: Changes to update PrintJobId on PrintList (BK-174)
                      pr_Printing_EntityPrintRequest: Pass PrintRequestId in rulesxml
  2020/11/12  OK      pr_Printing_EntityPrintRequest: Changes to return the Print list based on sort order (HA-1645)
  2020/08/07  MS      pr_Printing_EntityPrintRequest: Bus fix to consider RuleXml (HA-1279)
  2020/07/03  RV      pr_Printing_EntityPrintRequest: Made changes to convert print data to binary base64 (HA-894)
  2020/06/17  MS      pr_Printing_EntityPrintRequest, pr_Printing_CreatePrintJobs: Changes to execute all rules in RuleSet (HA-853)
  2020/05/23  RV      pr_Printing_EntityPrintRequest: Bug fixed to get the correct printer details based upon the printer protocol (CIMSV3-941)
  2020/05/13  TK      pr_Printing_EntityPrintRequest: Corrected Status field name (HA-86)
  2020/04/30  VM      pr_Printing_EntityPrintRequest: Added print requests logging (HA-249)
  2020/04/16  AY      pr_Printing_ProcessPrintList, pr_Printing_BuildPrintDataSet, pr_Printing_EntityPrintRequest:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_EntityPrintRequest') is not null
  drop Procedure pr_Printing_EntityPrintRequest;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_EntityPrintRequest: Procedure for the caller to request
    all the documents to be printed for the given entity or list of entities.
    If it is a single entity, then the entity can be passed in using the params
    or the list of entities can be inserted into #EntitiesToPrint.

  PrinterName: If printer name is not given, then it would be fetched from the device
               if the device id is given.
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_EntityPrintRequest
  (@Module            TName,
   @Operation         TOperation,
   @EntityType        TEntity,
   @EntityId          TRecordId,
   @EntityKey         TEntityKey,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @DeviceId          TDeviceId     = null,
   @RequestMode       TCategory     = 'QUEUED',
   @LabelPrinterName  TName         = null,
   @LabelPrinterName2 TName         = null,
   @ReportPrinterName TName         = null,
   @RulesDataXml      TXML          = null,
   @Action            TAction       = 'P' /* Print */)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vDebug             TControlValue = 'N',
          @vActivityLogId     TRecordId,
          @vErrorMsg          TMessage;

  declare @ttEntitiesToPrint  TEntitiesToPrint,
          @ttPrintList        TPrintList,
          @vRequestXML        TXML,
          @vPrintListXML      TXML,
          @vPrintResultXML    TXML,
          @vPrintRequestId    TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get debug options */
  exec pr_Debug_GetOptions @@ProcId, @Operation, @BusinessUnit, @vDebug output;

  /* Create Entities to Print object if caller has not already created one */
  if (object_id('tempdb..#EntitiesToPrint') is null) select * into #EntitiesToPrint from @ttEntitiesToPrint;

  select * into #PrintList from @ttPrintList;

  /* If Printer is not given, get the one from the device */
  if (@LabelPrinterName is null)
    select @LabelPrinterName = DefaultPrinter from Devices where (DeviceId = @DeviceId);

  select @LabelPrinterName = PrinterNameUnified from vwPrinters where (PrinterName = @LabelPrinterName) and (BusinessUnit = @BusinessUnit);

  /* If there is no printer specified, just queue the request. Later, we may setup rules
     for printers as well  */
  if (@LabelPrinterName is null) and (@RequestMode = 'IMMEDIATE') select @RequestMode = 'QUEUED';

  /* Add entity to list to print, the list may be exploded later into more entities */
  if (not exists(select * from #EntitiesToPrint)) and
     ((@EntityId is not null) or (@EntityKey is not null))
    insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, LabelPrinterName, LabelPrinterName2, ReportPrinterName, RecordId)
      select @EntityType, @EntityId, @EntityKey, @Operation, @LabelPrinterName, @LabelPrinterName2, @ReportPrinterName, 1

  /* Build RequestXML to log it into PrintRequests */
  set @vRequestXML = (select * from #EntitiesToPrint
                      for xml raw('EntityInfo'), root('EntitiesToPrint'), elements);

  /* Log Print Request */
  insert into PrintRequests (RequestOperation, RequestXML, RequestMode, BusinessUnit, CreatedBy)
    select @Operation, @vRequestXML, @RequestMode, @BusinessUnit, @UserId;

  select @vPrintRequestId = Scope_Identity();

  /* Build the xml for Rules */
  if (@RulesDataXml is null)
    select @RulesDataXML = dbo.fn_XMLNode('RootNode',
                              dbo.fn_XMLNode('Module',           @Module) +
                              dbo.fn_XMLNode('Operation',        @Operation) +
                              dbo.fn_XMLNode('Action',           @Action) +
                              dbo.fn_XMLNode('Entity',           @EntityType) +
                              dbo.fn_XMLNode('EntityId',         @EntityId) +
                              dbo.fn_XMLNode('EntityKey',        @EntityKey) +
                              dbo.fn_XMLNode('PrintRequestId',   @vPrintRequestId) +
                              dbo.fn_XMLNode('PrintJobId',       0) +
                              dbo.fn_XMLNode('BusinessUnit',     @BusinessUnit) +
                              dbo.fn_XMLNode('LabelPrinterName', @LabelPrinterName) +
                              dbo.fn_XMLNode('UserId',           @UserId));

  if (@RequestMode = 'IMMEDIATE')
    begin
      exec pr_RuleSets_ExecuteAllRules 'EntitiesToPrint_Finalize', @RulesDataXML, @BusinessUnit;

      /* Process the Entities list and arrive at the Print list with the ZPL */
      exec pr_Printing_ProcessPrintList @Module, @RulesDataXML, @BusinessUnit, @UserId;

      if (charindex('ETP', @vDebug) > 0) select * from #EntitiesToPrint;
      if (charindex('PL', @vDebug) > 0) select * from #PrintList;

      set @vPrintListXML = (select * from #PrintList
                            order by SortOrder
                            for Xml Raw('PrintListRecord'), elements XSINIL, Root('PrintList'), binary base64);

      begin try
        exec pr_CLR_ProcessDocuments @vPrintListXML, @vPrintResultXML out;

        /* If printing successful, set print request Status as Completed and log Notification */
        update PrintRequests
        set PrintRequestStatus = 'C' /* Completed */, -- based upon printResult set status
            Notifications      = @vPrintResultXML
        where PrintRequestId   = @vPrintRequestId;
      end try
      begin catch
        /* If printing failed (on any exception from CLR),
           set the print request Status to 'E' and log Notifications */
        select @vErrorMsg = ERROR_MESSAGE();

        update PrintRequests
        set PrintRequestStatus = 'E' /* Error */,
            Notifications      = @vErrorMsg
        where (PrintRequestId = @vPrintRequestId);
      end catch;
    end /* RequestMode Immediate */
  else
  /* Queue the request */
  if (@RequestMode = 'QUEUED')
    exec pr_Printing_CreatePrintJobs @vPrintRequestId, @RulesDataXML;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_EntityPrintRequest */

Go
