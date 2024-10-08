/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/04  PHK     pr_Printing_GetLabelsPrintData: Added new LabelType TDL to print details labels(CID-1179)
  2019/08/16  AY      pr_Printing_GetLabelsPrintData: New proc to get data for
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_GetLabelsPrintData') is not null
  drop Procedure pr_Printing_GetLabelsPrintData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_GetLabelsPrintData: Master procedure that prepares the xml
    for the entire set of labels to print for the given entities.

  @LabelsToPrint:
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_GetLabelsPrintData
  (@LabelsToPrint   XML          = null,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @ResultXML       TXML = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vDebug             TFlags,
          @vRecordId          TInteger,
          @vDocument          TTypeCode, /* Type of the Label that is PL or PTag */

          @vEntityId          TRecordId,
          @vEntity            TEntity,
          @vEntityKey         TEntity,
          @vLabelType         TTypeCode,
          @vImageType         TTypeCode,
          @vZPLData           TVarchar,
          @vAdditionalZPLData TVarchar,
          @vLabelFormatName   TName,
          @vAdditionalContent TName,
          @vAdditioalZPLData  TVarchar,
          @vCharIndex         TInteger,

          @vPrinterName       TName,
          @vPrinterMake       TMake,
          @vPrinterPort       TName,
          @vPrinterConfigXML  XML,

          @vInputXML          TXML,
          @vRulesDataXML      TXML,
          @vActivityLogId     TRecordId;

  declare @ttLabelsListToPrint  TLabelListToPrint;

begin /* pr_Printing_GetLabelsPrintData */
  select @vReturnCode  = 0,
         @vMessagename = null,
         @vRecordId    = 0,
         @vDebug       = 'N',
         @vInputXML    = convert(varchar(max), @LabelsToPrint);

  exec pr_ActivityLog_AddMessage 'GetLabelsPrintData', null, null, null, null, @@ProcId, @vInputXML, @ActivityLogId = @vActivityLogId out;

  /* Create Hash table of list of labels to print */
  select * into #ttLabelsListToPrint from @ttLabelsListToPrint;

  /* Get the Entities and DocumentTypes to print for eah of those */
  insert into #ttLabelsListToPrint (InputRecordId, Entity, EntityId, EntityKey, LabelType, ImageType, LabelFormat, ZPLData,
                                    PrinterName, PrinterPort, PrintBatch, NumCopies, SortSeqNo, SortOrder)
    select Record.Col.value('RecordId[1]',           'TRecordId'),
           Record.Col.value('Entity[1]',             'TEntity'),
           Record.Col.value('EntityId[1]',           'TRecordId'),
           Record.Col.value('EntityKey[1]',          'TEntityKey'),
           Record.Col.value('LabelType[1]',          'TTypeCode'),
           Record.Col.value('ImageType[1]',          'TTypeCode'),
           Record.Col.value('LabelFormat[1]',        'TName'),
           Record.Col.value('ZPLData[1]',            'TVarchar'),
           Record.Col.value('PrinterName[1]',        'TName'),
           Record.Col.value('PrinterPort[1]',        'TName'),
           Record.Col.value('PrintBatch[1]',         'TInteger'),
           Record.Col.value('NumCopies[1]',          'TInteger'),
           coalesce(Record.Col.value('SortSeqNo[1]', 'TSortSeq'), 0),
           Record.Col.value('SortOrder[1]',          'TSortOrder')
    from @LabelsToPrint.nodes('/ShippingLabelsToPrint/Label') as Record(Col)
    order by Record.Col.value('SortSeqNo[1]',        'TSortSeq');

  /* We only need to process ZPL labels, so ignore others */
  update #ttLabelsListToPrint
  set Status = case when ImageType = 'ZPL' then 'N' else 'I' /* Ignore */ end;

  /* Get info from labelformats to see if there is additional Content to be appended */
  update LLTP
  set AdditionalContent = LF.AdditionalContent
  from #ttLabelsListToPrint LLTP join LabelFormats LF on (LLTP.LabelFormat = LF.LabelFormatName) and
                                                         (LF.BusinessUnit = @BusinessUnit);

  /* Get the appropriate Printer Port for ZPL Printing */
  update LLTP
  set PrinterName = P.PrinterNameUnified, /* Update with PrinterNameUnified which have PortNo in it, as the Printer could be IP or Windows Printer  */
      PrinterPort = P.PrinterPort
  from #ttLabelsListToPrint LLTP join vwPrinters P on (LLTP.PrinterName = P.PrinterName);

  /* Setup LPN if one is not given and we only have LPNId and we are not always populating LPNId in ShipLabels */
  update LLTP
  set EntityKey = L.LPN
  from #ttLabelsListToPrint LLTP join LPNs L on (LLTP.EntityId = L.LPNId) and
                                                (LLTP.Entity = 'LPN') and
                                                (coalesce(LLTP.EntityKey, '') = '');

  /* Update ZPL for all SPL Labels and corresponding Status.
     If there is no Shiplabel record, then status = 'M' - Missing Shipping label
     If there is a Shiplabel record but no valid tracking no then 'LE'- Label Error
     If there is a valid Shiplabel record and there is no label modifications to do then update as P - Processed
     If there is a valid ShipLabel record, but there is additional content then leave it as N to be processed down below
  */
  update LLTP
  set InputRecordId = SL.RecordId,
      ZPLData       = SL.ZPLLabel,
      Status        = case when SL.RecordId is null then 'M' /* missing ship label */
                           when IsValidTrackingNo = 'N' then 'LE' /* Label Error generating tracking no */
                           when (coalesce(SL.ZPLLabel, '') <> '') and
                                (coalesce(AdditionalContent, '') = '') then 'P' /* processed */
                           else LLTP.Status
                      end
  from #ttLabelsListToPrint LLTP left outer join ShipLabels SL on (LLTP.EntityKey       = SL.EntityKey) and
                                                                  (LLTP.ImageType       = 'ZPL') and
                                                                  (LLTP.LabelType       = 'SPL') and
                                                                  (SL.BusinessUnit      = @BusinessUnit) and
                                                                  (SL.Status            = 'A')
  where (LLTP.LabelType = 'SPL');

  /* Execute rules to modify labels based upon conditions */
  exec pr_RuleSets_ExecuteAllRules 'LabelsGetPrintData_PreUpdate', @vRulesDataXML, @BusinessUnit;

  if (charindex('D', @vDebug) > 0) select * from #ttLabelsListToPrint;

  /* Process each document type and entity and accumulate the data if there any other ZPLs to generate */
  while (exists (select * from #ttLabelsListToPrint where RecordId > @vRecordId and Status = 'N'))
    begin
      select top 1
             @vEntityId          = EntityId,
             @vEntity            = Entity,
             @vEntityKey         = EntityKey,
             @vLabelType         = LabelType,
             @vImageType         = ImageType,
             @vRecordId          = RecordId,
             @vLabelFormatName   = LabelFormat,
             @vZPLData           = ZPLData,
             @vAdditionalContent = AdditionalContent
      from #ttLabelsListToPrint
      where (RecordId > @vRecordId) and (Status = 'N')
      order by RecordId;

      /* Generate ZPL for the particular label */
      if (@vLabelType = 'CL')
        exec pr_ContentLabel_GetPrintDataStream @vEntityId, @vLabelFormatName, @BusinessUnit, @vZPLData out;
      else
      if (@vLabelType in ('SL'))
        exec pr_ShipLabel_GetPrintDataStream @vEntityId, @vLabelFormatName, @BusinessUnit, @vZPLData out;
      else
      /* For all other labels, use the generic printing methods */
      if (@vLabelType <> 'SPL' /* Small Package Label */)
        exec pr_Printing_GetPrintDataStream @vEntity, @vEntityId, @vEntityKey, @vLabelFormatName, null /* Label SQL Statement */, null /* Operation */, @BusinessUnit, @UserId, @vZPLData out;

      /* SPL labels may have additional data to be augmented like PTS_4x8 label is UPS/FedEx Label +
         Picking label at the bottom */
      if (@vAdditionalContent <> '')
        begin
          select @vAdditionalZPLData = null;

          exec pr_ShipLabel_GetPrintDataStream @vEntityId, @vAdditionalContent, @BusinessUnit, @vAdditionalZPLData out;

          /* Get the ZPL end value charater index to stuff the additional info */
          select @vCharIndex = charindex('^XZ', @vZPLData);

          /* Update the ZPL label with the gathered information */
          select @vZPLData = stuff(@vZPLData, @vCharIndex, 0, @vAdditionalZPLData);
        end

      /* Save ZPL for current record */
      update #ttLabelsListToPrint
      set ZPLData = @vZPLData,
          Status  = 'P' /* Processed */
      where (RecordId = @vRecordId);
    end /* while end */

  /* Execute rules to modify labels based upon conditions */
  exec pr_RuleSets_ExecuteAllRules 'LabelsGetPrintData_PostUpdate', @vRulesDataXML, @BusinessUnit;

  /* If we do not have ZPL, convert labels to BTW */
  update #ttLabelsListToPrint
  set ImageType = 'BTW'
  where (ImageType = 'ZPL') and (coalesce(ZPLData, '') = '') and (Status = 'N');

  /* Build the final xml */
  set @ResultXML = (select * from #ttLabelsListToPrint
                    for xml raw('Label'), root('LabelsToPrint'), elements);

  /* Return the Dataset */
  select Entity, EntityId, EntityKey, LabelType, ImageType, LabelFormat, ZPLData, PrinterName, PrinterPort
  from #ttLabelsListToPrint
  order by SortOrder, RecordId;

  exec pr_ActivityLog_AddMessage 'GetLabelsPrintData', null, null, null, null, @@ProcId, @ResultXML, @ActivityLogId = @vActivityLogId out;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_GetLabelsPrintData */

Go
