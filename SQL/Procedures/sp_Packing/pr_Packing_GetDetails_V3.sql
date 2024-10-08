/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/26  OK      pr_Packing_GetDetails_V3: Changes to identify the order when user scanned Cart or cart position (BK-657)
                      pr_Packing_GetDetails_V3: Get the details based upon the pack details mode (BK-636)
  2021/08/09  NB      pr_Packing_GetDetails_V3 changes to return carton info like empty weight, max weight and max units(CIMSV3-1595)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetDetails_V3') is not null
  drop Procedure pr_Packing_GetDetails_V3;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_GetDetails_V3: $$ Should be renamed as pr_Packing_StartPacking

   This procedure is invoked from V3 UI Packing on input of Entity for packing by
   user. The entity is validated and the PackingType is identified

   PackingType : Order - Packing of an individual order

    The procedure returns all the details needed to present the packing interface
    along with data for packing, for the inputs given
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetDetails_V3
  (@InputXML     TXML)
as
  declare @vxmlInput                  xml,
          @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vDebug                     TFlags,  -- use 'SE,ETP' to display temp tables
          @vEntity                    TEntity,
          @vAction                    TAction,
          @vDeviceId                  TDeviceId,
          @vLabelPrinterName          TName,
          @vReportPrinterName         TName,
          @vUserId                    TUserId,
          @vBusinessUnit              TBusinessUnit,
          @vPrintRequestId            TRecordId,
          @vOperation                 TDescription,
          @vShowLinesWithNoPickedQty  TFlag,
          @vShowComponentSKUsLines    TControlValue,
          @vRulesDataXML              TXML,
          @vRuleSetType               TRuleSetType,
          @vPackingType               TName,
          @vPackingMode               TName,
          @vPackingModesAllowed       TVarchar,
          @vPackingInputFormName      TName,
          @vPackingInputFormHtml      TVarchar,
          @vPackingModeOptionsHtml    TVarchar,
          @vCartonTypeOptionsHtml     TVarchar,
          @vPackingContextName        TName,
          @vEntityInfoType            TName,
          @vEntityInfoInput           TXML,
          @vEntityInfoDetails         TXML,
          @vEntityInfoDetailInput     TXML,
          @vEntityInfoDetailSelectionFilter xml,
          @vPackingInstructionsType   TName,
          @vPackingInstructionsSelectionFilter xml,
          @vPackingInstructionsInput  TXML,
          @vxmlPackingLayoutDetails   xml,
          @vSKUImagePath              TControlValue,
          @vPackDetailsMode           TControlValue;

  declare @ttSelectedEntities      TEntityValuesTable;
begin /* pr_Packing_GetDetails_V3 */
  select @vReturnCode  = 0,
         @vMessagename = null;

  /* Extracting data elements from XML. */
  set @vxmlInput = convert(xml, @InputXML);

  /* Capture Information */
  select @vEntity            = nullif(Record.Col.value('Entity[1]',                       'TEntity'), ''),
         @vAction            = Record.Col.value('Action[1]',                              'TAction'),
         @vUserId            = Record.Col.value('(SessionInfo/UserId)[1]',                'TUserId'),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',              'TDeviceId'),
         @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',          'TBusinessUnit'),
         @vLabelPrinterName  = Record.Col.value('(SessionInfo/DeviceLabelPrinter)[1]',    'TName'),
         @vReportPrinterName = Record.Col.value('(SessionInfo/DeviceDocumentPrinter)[1]', 'TName'),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                    'TDescription'),
         @vDebug             = Record.Col.value('(Data/Debug)[1]',                        'TFlags')
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlInput = null ) );

  select @vOperation  = coalesce(@vOperation, @vAction); -- consider Action to be operation in case operation is not passed in

  /* Remove all the lines where the PickedQuantity is 0. There is nothing to be packed */
  select @vShowLinesWithNoPickedQty = dbo.fn_Controls_GetAsBoolean('Packing', 'ShowLinesNotPicked', 'N', @vBusinessUnit, @vUserId);
  select @vShowComponentSKUsLines = dbo.fn_Controls_GetAsBoolean('Packing', 'ShowComponentSKUsLines', 'N', @vBusinessUnit, @vUserId);
  select @vSKUImagePath = dbo.fn_Controls_GetAsString('SKU', 'ImageURLPath', '' /* default */, @vBusinessUnit, @vUserId);
  select @vPackDetailsMode = dbo.fn_Controls_GetAsString('Packing', 'PackDetailsMode', 'Default', @vBusinessUnit, @vUserId);

  /* Create temp tables */
  select * into #ttSelectedEntities from @ttSelectedEntities;
  select * into #PackingDetails from vwOrderToPackDetails where 1 = 2;

  /* Build the xml for Rules */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                                           dbo.fn_XMLNode('Operation',              @vOperation) +
                                           dbo.fn_XMLNode('Action',                 @vAction) +
                                           dbo.fn_XMLNode('Entity',                 @vEntity) +
                                           dbo.fn_XMLNode('PackingType',            @vPackingType) +
                                           dbo.fn_XMLNode('ShowLinesNotPicked',     @vShowLinesWithNoPickedQty) +
                                           dbo.fn_XMLNode('ShowComponentSKUsLines', @vShowLinesWithNoPickedQty) +
                                           dbo.fn_XMLNode('PackDetailsMode',        @vPackDetailsMode) +
                                           dbo.fn_XMLNode('BusinessUnit',           @vBusinessUnit) +
                                           dbo.fn_XMLNode('UserId',                 @vUserId));

  /* This procedure inserts the records into #ttSelectedEntities temp table from Selected records */
  exec pr_Entities_GetSelectedEntities @vEntity, @vxmlInput, @vBusinessUnit, @vUserId;

  /* There are instances where input contains only key values, without entity type
     identify the entitytype and Ids for such instances */
  if (exists (select RecordId from #ttSelectedEntities where EntityType is null))
    exec pr_RuleSets_ExecuteAllRules 'IdentifyEntityType', @vRulesDataXML, @vBusinessUnit;

  /* Identify order if user scanned other than order entity */
  exec pr_RuleSets_ExecuteAllRules 'Packing_IdentifyOrder', @vRulesDataXML, @vBusinessUnit;

  /* Identify Packing Variant or Mode for the Input */
  exec pr_RuleSets_Evaluate 'Packing_IdentifyType', @vRulesDataXML, @vPackingType output;
  select @vRulesDataXML = dbo.fn_XMLStuffValue (@vRulesDataXML, 'PackingType', @vPackingType);

  /* Load the SKU+Qty to be packed into #PackingDetails */
  exec pr_RuleSets_ExecuteAllRules 'Packing_IdentifyDetails', @vRulesDataXML, @vBusinessUnit;

  /* Validations */

  if (not exists (select * from #ttSelectedEntities))
    select @vMessageName = 'Packing_InvalidInput';
  else
  if (exists (select * from #ttSelectedEntities where EntityType is null))
    select @vMessageName = 'Packing_InvalidInput';
  else
  /* If packing details do not exist, then error out */
  if (not exists(select OrderId from  #PackingDetails))
    select @vMessageName = 'Packing_NothingToPack';
  else
  if (@vLabelPrinterName is null) or ((@vLabelPrinterName not like '~LOCAL~%') and
                                      (not exists(select PrinterName from Printers
                                                  where (PrinterName  = @vLabelPrinterName) and
                                                        (PrinterType  = 'Label'           ) and
                                                        (BusinessUnit = @vBusinessUnit    ))))
    select @vMessageName = 'LabelPrinterUnknown';
  else
  if (@vReportPrinterName is null) or ((@vReportPrinterName not like '~LOCAL~%') and
                                       (not exists(select PrinterName from Printers
                                                   where (PrinterName  = @vReportPrinterName) and
                                                         (PrinterType  = 'Report'           ) and
                                                         (BusinessUnit = @vBusinessUnit     ))))
    select @vMessageName = 'ReportPrinterUnknown';

  /* If error, exit */
  if (@vMessageName is not null) exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* TODO  call Rules to validate the input and related details */
  --
  --
  --

  /* Fetch Layout Details for display of Packing Details */
  select @vPackingContextName = 'Packing_' + @vPackingType;
  exec pr_Layouts_GetLayoutDetails @vPackingContextName, 'Standard', @vUserId, @vBusinessUnit,
                                   @vxmlPackingLayoutDetails output;

  /* Determine Packing Modes allowed and default packing mode
     Packing Mode indicates whether the User scans each unit or scans SKU and confirms Qty, etc.,.
     TODO Use Rules and Conditions to determine the following */
  select @vPackingMode = 'SCANEACH';
  select @vPackingModesAllowed = 'SCANEACH,SCANANDCOUNT,COUNTANDSCAN';

  /* Identify Details to Process Entity Information Display */
  select @vEntityInfoType = @vOperation + '_EntityInfo_' + @vPackingType;
  select @vEntityInfoInput = (select @vEntityInfoType EntityType FOR XML RAW('Root'), ELEMENTS);

  exec pr_UI_GetEntityInfoDetails @vEntityInfoInput, @vUserId, @vBusinessUnit, @vEntityInfoDetails output;

  /* Build the Selection Filter for the Entity Info Detail processing */
  select @vEntityInfoDetailSelectionFilter = ( select ReferenceValueField as FieldName, 'Equals' FilterOperation, tt.EntityId FilterValue
                                               from FieldUIAttributes FA, #ttSelectedEntities tt where FA.ContextName = @vEntityInfoType For XML RAW('Filter'), ELEMENTS, ROOT('SelectionFilters') );
  select @vEntityInfoDetailInput = (select @vEntityInfoType EntityType, @vEntityInfoDetailSelectionFilter FOR XML RAW('Root'), ELEMENTS);

  /* Identify Packing Form Name for the Packing Type */
  exec pr_RuleSets_Evaluate 'Packing_IdentifyInputForm', @vRulesDataXML, @vPackingInputFormName output;

  if (@vPackingInputFormName is null) exec @vReturnCode = pr_Messages_ErrorHandler 'Packing_InputFormNotConfigured';

  select Top 1
       @vPackingInputFormHtml = RawHtml
  from UIFormDetails
  where (FormName     = @vPackingInputFormName) and
        (BusinessUnit = @vBusinessUnit        ) and
        (Visible      = 1                     )
   order by SortSeq, RecordId;

  /* If Packing Input Form does not exist, then error out */
  if (@vPackingInputFormHtml is null) exec @vReturnCode = pr_Messages_ErrorHandler 'Packing_InputFormNotFound';

  if (charindex('[PACKINGMODEOPTIONS]', @vPackingInputFormHtml) > 0)
    begin
      select @vPackingModeOptionsHtml = '';
      with PackingModeOptions as (select Value PackingMode from dbo.fn_ConvertStringToDataSet(@vPackingModesAllowed, ','))
      select @vPackingModeOptionsHtml = @vPackingModeOptionsHtml +
            '<a class="dropdown-item js-change-packing-mode" data-packingmodevalue="' + LookupCode + '" href="#"><i class="cims-ti-check mr-3 hidden"></i>' + LU.LookupDescription + '</a>'
      from Lookups LU
      join PackingModeOptions PMO on PMO.PackingMode = LU.LookupCode
      where (LU.Lookupcategory = 'PackingMode') and (Status = 'A' /* Active */);

      select @vPackingInputFormHtml = replace(@vPackingInputFormHtml, '[PACKINGMODEOPTIONS]', @vPackingModeOptionsHtml);
    end;

  if (charindex('[PACKINGCARTONTYPES]', @vPackingInputFormHtml) > 0)
    begin
      select @vCartonTypeOptionsHtml = '';
      select @vCartonTypeOptionsHtml = coalesce(@vCartonTypeOptionsHtml, '') + '<option value="' + CartonType + '">' + Description + '</option>'
      from CartonTypes
      where (Status = 'A') and (BusinessUnit = @vBusinessUnit)
      order by SortSeq, RecordId;

      select @vPackingInputFormHtml = replace(@vPackingInputFormHtml, '[PACKINGCARTONTYPES]', @vCartonTypeOptionsHtml);
    end;

  /*--------- return Data sets --------*/

  /* Return Packing Details */
  select * from #PackingDetails;

  /* Return the Entity Info Detail and Input */
  select @vPackingType PackingType, @vPackingMode PackingMode,
         @vxmlPackingLayoutDetails PackingLayoutDetails, @vPackingInputFormHtml PackingInputForm,
         @vEntityInfoDetails EntityInfoDetails, @vEntityInfoDetailInput EntityInfoDetailInput,
         '' SKUImagePath;

  /* return Packing Instructions */
  select @vPackingInstructionsType = @vOperation + '_Instructions_' + EntityType from #ttSelectedEntities;
  select @vPackingInstructionsSelectionFilter = @vEntityInfoDetailSelectionFilter; -- for now, the filter is same as entity info
  select @vPackingInstructionsInput = (select @vPackingInstructionsType EntityType, @vPackingInstructionsSelectionFilter FOR XML RAW('Root'), ELEMENTS);

  exec pr_Packing_GetInstructions @vPackingInstructionsInput, @vBusinessUnit, @vUserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_GetDetails_V3 */

Go
