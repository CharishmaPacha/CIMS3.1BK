/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/06  TK      pr_Printing_ProcessPrintList: Print List post process updates should be a different Rule Set (BK-348)
  2021/03/21  RV      pr_Printing_ProcessPrintList and pr_Printing_ProcessPrintList_New: Ported changes done by Pavan (Go Live)
  2021/03/17  OK/MS   pr_Printing_ProcessPrintList: Bug fix to do not null the print data if somelabels are missing in order (HA-2312)
  2021/03/15  PK      pr_Printing_ProcessPrintList: Ported changes done by Pavan (HA-2287)
  2021/02/23  RV      pr_Printing_ProcessPrintList: Made changes to concatenate the ZPL string with respect to the order (HA-2034)
  2021/02/17  MS      pr_Printing_ProcessPrintList, pr_Printing_EntityPrintRequest: Changes to update PrintJobId on PrintList (BK-174)
  2020/01/05  MS      pr_Printing_ProcessPrintList: Changes to print commercial invoice (HA-1850)
  2020/12/29  PK      pr_Printing_ProcessPrintList: pr_Shipping_ShipManifest_GetData was returning XML but the variable @vPrintDataStream is varchar
  2020/11/16  RV      pr_Printing_ProcessPrintList: Made changes to process selected print list from Shipping Docs
  2020/11/11  RV      pr_Printing_ProcessPrintList: Made changes to process the print list based upon the PrintDataFlag (HA-1660)
  2020/10/10  MS      pr_Printing_ProcessPrintList: Changes to get NumCopies from PrintList (HA-1510)
  2020/09/29  RV      pr_Printing_GetPrintDataStream, pr_Printing_ProcessPrintList: Added markers (HA-1476)
  2020/07/13  MS      pr_Printing_ProcessPrintList: Bug fix to update PrinterName (HA-1090)
  2020/06/25  AJ      pr_Printing_ProcessPrintList: Made changes to print ShippingManifest, BOL and PL from Loads page (HA-984)
  2020/06/23  RV      pr_Printing_ProcessPrintList: Made changes to conver to base64 to handle the special characters (HA-894)
  2020/05/29  MS      pr_Printing_ProcessPrintList: Changes to append Additional Content for Labels (HA-660)
  2020/05/24  AY      pr_Printing_ProcessPrintList: Changes to get ShipLabels.ZPLData
  2020/04/16  AY      pr_Printing_ProcessPrintList, pr_Printing_BuildPrintDataSet, pr_Printing_EntityPrintRequest:
  2020/04/05  NB      Added pr_Printing_ProcessPrintList (CIMSV3-221)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_ProcessPrintList') is not null
  drop Procedure pr_Printing_ProcessPrintList;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_ProcessPrintList: Evaluates the rules, to process the printlist
   for information in #ttEntitiesToPrint
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_ProcessPrintList
  (@Module        TName,
   @RulesDataXML  TXML,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vDebug             TControlValue = 'N';

  declare @vRuleSetType       TRuleSetType,
          @vEntityType        TEntity,
          @vEntityId          TRecordId,
          @vEntityKey         TEntityKey,

          @vDocumentClass      TName,
          @vDocumentSubClass   TName,
          @vDocumentType       TTypeCode,
          @vDocumentSubType    TTypeCode,
          @vDocumentFormat     TName,
          @vDocToPrintXML      TXML,
          @vPrintDataStream    TVarchar,
          @vNumCopies          TInteger,
          @vAdditionalContent  TName,
          @vAdditionalZPLData  TVarchar,
          @vCharIndex          TInteger,
          @vCreateShipment     TFlags,
          @vSortOrder          TSortOrder,
          @vSMRequestXML       TXML,
          @vBoLRequestXML      TXML;

  declare @ttMarkers           TMarkers;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vSortOrder   = '';

  /* Create required hash tables if they does not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  /* Functionality */
  /* TODO ..iterate through #ttEntitiesToPrint, invoke respective RuleSets to process details
     The rules will insert into #PrintList table */

  select @vRuleSetType = 'PrintList_' + @Module;
  exec pr_RuleSets_ExecuteAllRules @vRuleSetType, @RulesDataXML, @BusinessUnit;
  exec pr_RuleSets_ExecuteAllRules 'PrintList_PostProcess', @RulesDataXML, @BusinessUnit;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Print List prepared', @@ProcId;

  /* If the rules fail to do some updates, we still need to recover and print */
  update #PrintList
  set SortOrder = coalesce(SortOrder, ''),
      Action    = coalesce(Action, 'P');

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

      if (charindex('D', @vDebug) <> 0)
        begin print @vDocumentFormat; print @vEntityId; print @vDocumentClass; Print @vDocumentSubClass end;

      if (@vDocumentFormat like 'CaseContent%')
        exec pr_ContentLabel_GetPrintDataStream @vEntityId, @vDocumentFormat, @BusinessUnit, @vPrintDataStream out;
      else
      /* If it is ZPL Small package label, then get the data stream from Ship Label */
      if (@vDocumentClass = 'Label') and (@vDocumentSubClass = 'ZPL') and(@vDocumentType = 'SPL')
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
                                               @vDocumentFormat  as DocumentFormat
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

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_ProcessPrintList */

Go
