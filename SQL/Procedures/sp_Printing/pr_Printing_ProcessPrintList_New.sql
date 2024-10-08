/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/21  RV      pr_Printing_ProcessPrintList and pr_Printing_ProcessPrintList_New: Ported changes done by Pavan (Go Live)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_ProcessPrintList_New') is not null
  drop Procedure pr_Printing_ProcessPrintList_New;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_ProcessPrintList_New: Evaluates the rules, to process the printlist
   for information in #ttEntitiesToPrint (This temp procedure used to processing the print
   list from Print jobs, this will remove once perminent changes done)
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_ProcessPrintList_New
  (@Module        TName,
   @RulesDataXML  TXML,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TMessage,
          @vRecordId          TRecordId,
          @vDebug             TControlValue = 'N';

  declare @vRuleSetType       TRuleSetType,
          @vEntityType        TEntity,
          @vEntityId          TRecordId,
          @vEntityKey         TEntityKey,

          @vTRecordId          TRecordId,
          @vTZPLString         TVarchar,

          @vDocumentClass      TName,
          @vDocumentSubClass   TName,
          @vDocumentType       TTypeCode,
          @vDocumentSubType    TTypeCode,
          @vDocumentFormat     TName,
          @vDocumentSchema     TVarchar,
          @vPrintDataFlag      TVarchar,
          @vDocToPrintXML      TXML,
          @vPrintDataStream    TVarchar,
          @vPrintJobId         TInteger,
          @vNumCopies          TInteger,
          @vAdditionalContent  TName,
          @vAdditionalZPLData  TVarchar,
          @vCharIndex          TInteger,
          @vCreateShipment     TFlags,
          @vPrinterName        TName,
          @vPrinterIP          TName,
          @vPrinterPort        TName,
          @vOperation          TOperation,
          @vSortOrder          TSortOrder,
          @vSMRequestXML       TXML,
          @vBoLRequestXML      TXML,
          @vxmlRulesDataXML    xml;

  declare @ttPrintList         TPrintList,
          @ttMarkers           TMarkers;
begin
  SET NOCOUNT ON;

begin try
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vSortOrder   = '',
         @vTRecordId   = 0;

  /* Convert string to xml to parse */
  set @vxmlRulesDataXML = convert(xml, @RulesDataXML);

  /* Create required hash tables if they does not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  select @vPrintJobId = Record.Col.value('PrintJobId[1]', 'TRecordId'),
         @vOperation  = Record.Col.value('Operation[1]',  'TOperation')
  from @vxmlRulesDataXML.nodes('/RootNode') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlRulesDataXML = null ));

  /* Functionality */
  /* TODO ..iterate through #ttEntitiesToPrint, invoke respective RuleSets to process details
     The rules will insert into #PrintList table */

  select @vRuleSetType = 'PrintList_' + @Module;
  exec pr_RuleSets_ExecuteAllRules @vRuleSetType, @RulesDataXML, @BusinessUnit;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Print List prepared', @@ProcId;

  /* If the rules fail to do some updates, we still need to recover and print */
  update #PrintList
  set SortOrder  = coalesce(SortOrder, ''),
      Action     = coalesce(Action, 'P'),
      PrintJobId = @vPrintJobId;

  /* Get info from labelformats to see if there is additional Content to be appended */
  update PL
  set AdditionalContent = LF.AdditionalContent
  from #PrintList PL join LabelFormats LF on (PL.DocumentFormat = LF.LabelFormatName) and
                                             (LF.BusinessUnit   = @BusinessUnit)
  where (PL.PrintDataFlag = 'Required');

  /* Populate printer info - temp fix */
  update PL
  set PrinterName = coalesce(P.PrinterNameUnified, PL.PrinterName)
  from #PrintList PL join vwPrinters P on (PL.PrinterName = P.PrinterName)
  where (PL.PrintDataFlag = 'Required');

  if (charindex('D', @vDebug) <> 0) select 'PrintList Before', * from #PrintList;
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Loop start', @@ProcId;

  while exists (select * from #PrintList where RecordId > @vRecordId and PrintDataFlag = 'Required')
    begin
      select top 1
             @vRecordId          = RecordId,
             @vSortOrder         = SortOrder,
             @vEntityType        = EntityType,
             @vEntityId          = EntityId,
             @vEntityKey         = EntityKey,
             @vDocumentClass     = DocumentClass,
             @vDocumentSubClass  = DocumentSubClass,
             @vDocumentType      = DocumentType,
             @vDocumentSubType   = DocumentSubType,
             @vDocumentFormat    = DocumentFormat,
             @vNumCopies         = NumCopies,
             @vPrintDataStream   = null,
             @vAdditionalContent = AdditionalContent,
             @vCreateShipment    = null
      from #PrintList
      where (RecordId      > @vRecordId) and
            (PrintDataFlag = 'Required')
      order by RecordId;

      select @vMessage = concat_ws(' ', @vDocumentType, @vDocumentClass, @vDocumentSubClass, @vDocumentFormat,
                                   @vEntityType, @vEntityId, @vEntityKey);

      if (charindex('D', @vDebug) <> 0) print @vMessage;

      if (@vDocumentFormat like 'CaseContent%')
        exec pr_ContentLabel_GetPrintDataStream @vEntityId, @vDocumentFormat, @BusinessUnit, @vPrintDataStream out;
      else
      /* If it is ZPL Small package label, then get the data stream from Ship Label */
      if (@vDocumentClass = 'Label') and (@vDocumentSubClass = 'ZPL') and (@vDocumentType = 'SPL')
        begin
          select @vPrintDataStream = ZPLLabel
          from ShipLabels
          where (Status = 'A') and (EntityId = @vEntityId);

          select @vPrintDataStream = replace(@vPrintDataStream, '^XA', '^XA' +
                                                                       '^PW' + cast(812 as varchar) +
                                                                       '^LL' + cast(1624 as varchar) +
                                                                       '^ML' + cast(1800 as varchar));

          if (@vPrintDataStream is null) select @vCreateShipment = 'M';
        end
      else
      if (@vDocumentClass = 'Label')
        exec pr_Printing_GetPrintDataStream @vEntityType, @vEntityId, @vEntityKey,
                                            @vDocumentFormat, null /* Label SQL Stmt */,
                                            @Module /* Operation */, @BusinessUnit, @UserId,
                                            @vPrintDataStream out, @vNumCopies;
      else
      if (@vDocumentClass = 'Report') and (@vDocumentSubClass = 'RDLC')
        begin
          if (@vDocumentType in ('PL' /* Packing List */, 'CI' /* Commercial Invoice */))
            begin
              select @vDocToPrintxml = (select @vEntityType      as Entity,
                                               @vEntityId        as EntityId,
                                               @vEntityKey       as EntityKey,
                                               @vDocumentType    as DocType,
                                               @vDocumentSubType as DocSubType,
                                               @vDocumentFormat  as DocumentFormat,
                                               @vRecordId        as PrintListRecordId,
                                               @vPrintJobId      as PrintJobId
                                        for xml raw('DocToPrint'), elements);

              exec pr_Shipping_GetPackingListData_New @vDocToPrintXML, null, @BusinessUnit, @UserId, @vPrintDataStream out;
            end

         if (@vDocumentType = 'SM') /* Shipping Manifest */
           begin
             select @vSMRequestXML = (select @vEntityId        as LoadId,
                                             @vEntityKey       as LoadNumber
                                      for xml raw('LoadNumbers'), elements);

             exec pr_Shipping_ShipManifest_GetData @vSMRequestXML, @BusinessUnit, @UserId, null, @vPrintDataStream out;
           end

         if (@vDocumentType = 'BL') /* BoL Report */
           begin
             /* Buid the Request XML */
             select @vBoLRequestXML = dbo.fn_XMLNode('PrintVICSBoL',
                                        dbo.fn_XMLNode('Loads',
                                          dbo.fn_XMLNode('LoadId', @vEntityId)) +
                                          dbo.fn_XMLNode('BusinessUnit', @BusinessUnit) +
                                          dbo.fn_XMLNode('BoLTypesToPrint', 'MU'));

             exec pr_Shipping_GetBoLData @vBoLRequestXML, @vPrintDataStream output;
           end
        end

      /* Some labels may have additional data to be augmented like PTS_4x8 label is UPS/FedEx Label +
         Picking label at the bottom, so get the additional data and add at the end */
      if ((@vDocumentClass = 'Label') and (@vAdditionalContent <> ''))
        begin
          select @vAdditionalZPLData = null;

          exec pr_Printing_GetPrintDataStream @vEntityType, @vEntityId, @vEntityKey,
                                              @vAdditionalContent, null /* Label SQL Stmt */,
                                              @Module /* Operation */, @BusinessUnit, @UserId,
                                              @vAdditionalZPLData out;

          /* Get the ZPL end value charater index to stuff the additional info before ^XZ */
          select @vCharIndex = charindex('^XZ', @vPrintDataStream);

          /* Update the ZPL label with the gathered information */
          select @vPrintDataStream = stuff(@vPrintDataStream, @vCharIndex, 0, @vAdditionalZPLData);
        end

      /* Save the print data stream to Print list */
      update #PrintList
      set PrintDataFlag  = 'Processed',
          PrintData      = cast(@vPrintDataStream as varbinary(max))
          --CreateShipment = @vCreateShipment This will be updated from Rules
      where (RecordId = @vRecordId);
    end

  if (@vOperation in ('ShippingDocs', 'PrintLoadDocs'))
    goto SkipPTConsolidateToPrint;

  update ttPL
  set UDF1      = L.OrderId,
      UDF2      = L.PickTicketNo
  from #PrintList ttPL join LPNs L on (ttPL.EntityId  = L.LPNId) and
                                      (ttPL.EntityType = 'LPN');

  select * into #ttDistintPTToConsolidate from @ttPrintList;

  /* Get distinct PickTickets from the list of LPNs in print list to send one ZPL per PickTicket to UI */
  insert into #ttDistintPTToConsolidate (EntityType, PrintJobId, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType, DocumentFormat, DocumentSchema, PrintDataFlag, PrinterName, PrinterPort, SortSeqNo)
    select distinct 'Order', PrintJobId, UDF1, UDF2, DocumentClass, DocumentSubClass,  DocumentType, DocumentSubType, DocumentFormat, DocumentSchema, PrintDataFlag, PrinterName, PrinterPort, row_number() over(order by UDF1)
    from #PrintList
    where (DocumentSubClass = 'ZPL') and (UDF1 is not null) and (PrintDataFlag = 'Processed') and (Action = 'P')
    group by PrintJobId, UDF1, UDF2, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType, DocumentFormat, DocumentSchema, PrintDataFlag, PrinterName, PrinterPort

  while (exists (select * from #ttDistintPTToConsolidate where RecordId > @vTRecordId))
    begin
      /* select top 1 record from temptable to process */
      select top 1 @vTRecordId        = RecordId,
                   @vPrintJobId       = PrintJobId,
                   @vEntityType       = EntityType,
                   @vEntityId         = EntityId,
                   @vEntityKey        = EntityKey,
                   @vDocumentClass    = DocumentClass,
                   @vDocumentSubClass = DocumentSubClass,
                   @vDocumentType     = DocumentType,
                   @vDocumentSubType  = DocumentSubType,
                   @vDocumentFormat   = DocumentFormat,
                   @vDocumentSchema   = DocumentSchema,
                   @vPrintDataFlag    = PrintDataFlag,
                   @vPrinterName      = PrinterName,
                   @vPrinterPort      = PrinterPort
      from #ttDistintPTToConsolidate
      where RecordId > @vTRecordId
      order by RecordId;

      /* Concatenate ZPL string for PickTicket */
      select @vTZPLString = coalesce(@vTZPLString, '') + cast(coalesce(PrintData, '') as varchar(max))
      from #PrintList
      where (DocumentSubClass = 'ZPL') and (UDF1 = @vEntityId) and (PrintDataFlag = 'Processed') and (Action = 'P')
      order by SortOrder, SortSeqNo;

      /* Delete individual records from the temp table for each LPN for the PickTicket */
      delete
      from #PrintList
      where (DocumentSubClass = 'ZPL') and (PrintDataFlag = 'Processed') and (UDF1 = @vEntityId) and (Action = 'P');

      /* Insert one record per PickTicket into table with the whole ZPL stream */
      insert into #PrintList (EntityType, PrintJobId, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType, DocumentFormat, DocumentSchema, PrintDataFlag, PrintData, PrinterName, PrinterPort, SortOrder, SortSeqNo, Action)
        select 'Order', @vPrintJobId, @vEntityId, @vEntityKey, @vDocumentClass, @vDocumentSubClass, @vDocumentType, @vDocumentSubType, @vDocumentFormat, @VDocumentSchema, @vPrintDataFlag, cast(@vTZPLString as varbinary(max)), @vPrinterName, @vPrinterPort, cast(@vEntityId as varchar(max)) + '_' + cast(@vTRecordId as varchar(max)), @vTRecordId, 'P';

      /* Clear variables */
      select @vTRecordId = null, @vEntityKey = null, @vEntityId = null,
             @vDocumentClass = null, @vDocumentSubClass = null, @vPrinterName = null,
             @vPrinterPort = null, @vTZPLString = null;
    end /* while */

SkipPTConsolidateToPrint:

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Loop end', @@ProcId;

  /* set the description of the records, if not already set */
  update tt
  set Description = tt.EntityKey + ',' + L.LookupDescription
  from #PrintList tt
  join LookUps L on (L.LookupCategory = 'DocumentType') and (L.LookupCode = tt.DocumentType)
  where (Description is null);

  if (charindex('D', @vDebug) <> 0) select 'PrintList After', * from #PrintList;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'End', @@ProcId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, null, null, null, 'ProcessPrintList', @@ProcId, 'Markers_ProcessPrintList';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
  select @vMessage = ERROR_MESSAGE() + coalesce(' ' + @vMessage, '');

  raiserror(@vMessage, 16, 1);
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_ProcessPrintList_New */

Go
