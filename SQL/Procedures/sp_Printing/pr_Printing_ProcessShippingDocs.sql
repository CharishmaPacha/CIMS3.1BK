/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/30  NB      Added pr_Printing_ProcessShippingDocs, changes to ProcessDocRequest procedure to validate
                      Modified pr_Printing_ProcessShippingDocsRequest to call the newly added procedures (CIMSV3-221)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_ProcessShippingDocs') is not null
  drop Procedure pr_Printing_ProcessShippingDocs;
Go
/*------------------------------------------------------------------------------
  pr_Printing_ProcessShippingDocs: This is the main proc invoked from Shipping Docs
    page in UI. The reason this is a separate proc than just using pr_Printing_ProcessDocsRequest
    is because in Shipping Docs, we not only have to show and print the selected
    documents, we want to show the info of the Entity selected in an html format.
    So, this is more of a wrapper for pr_Printing_ProcessDocsRequest which alos
    returns the entity info.
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_ProcessShippingDocs
  (@PrintRequestInputXML     TXML)
as
  declare @vxmlPrintRequestInput   xml,
          @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vDebug                  TFlags,  -- use 'SE,ETP' to display temp tables

          @vEntity                 TEntity,
          @vAction                 TAction,
          @vDeviceId               TDeviceId,
          @vUserId                 TUserId,
          @vBusinessUnit           TBusinessUnit,
          @vPrintRequestId         TRecordId,
          @vOperation              TDescription,
          @vRulesDataXML           TXML,
          @vRuleSetType            TRuleSetType,
          @vEntityInfoType         TName,
          @vEntityInfoInput        TXML,
          @vEntityInfoDetails      TXML,
          @vEntityInfoDetailInput  TXML,
          @vEntityInfoDetailSelectionFilter xml;

  declare @ttSelectedEntities      TEntityValuesTable;
begin /* pr_Printing_ProcessShippingDocs */
  select @vReturnCode  = 0,
         @vMessagename = null;

  /* Extracting data elements from XML. */
  set @vxmlPrintRequestInput = convert(xml, @PrintRequestInputXML);

  /* Capture Information */
  select @vEntity       = nullif(Record.Col.value('Entity[1]',             'TEntity'), ''),
         @vAction       = Record.Col.value('Action[1]',                    'TAction'),
         @vUserId       = Record.Col.value('(SessionInfo/UserId)[1]',      'TUserId'),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',    'TDeviceId'),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]','TBusinessUnit'),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',          'TDescription'),
         @vDebug        = Record.Col.value('(Data/Debug)[1]',              'TFlags')
  from @vxmlPrintRequestInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlPrintRequestInput = null ) );

  select @vOperation  = coalesce(@vOperation, @vAction); -- consider Action to be operation in case operation is not passed in

  /* Create temp tables */
  select * into #ttSelectedEntities from @ttSelectedEntities;

  /* This procedure inserts the records into #ttSelectedEntities temp table */
  exec pr_Entities_GetSelectedEntities @vEntity, @vxmlPrintRequestInput, @vBusinessUnit, @vUserId;

  /* There are instances where input contains only key values, without entity type
     identify the entitytype and Ids for such instances */
  if (exists (select RecordId from #ttSelectedEntities where EntityType is null))
    begin
      select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                                dbo.fn_XMLNode('BusinessUnit', @vBusinessUnit));

      exec pr_RuleSets_ExecuteAllRules 'IdentifyEntityType', @vRulesDataXML, @vBusinessUnit;
    end

  if (not exists (select RecordId from #ttSelectedEntities))
    select @vMessageName = 'PrintRequest_InvalidInput';
  else
  if (exists (select RecordId from #ttSelectedEntities where EntityType is null))
    select @vMessageName = 'PrintRequest_InvalidInput';

  /* If error, exit */
  if (@vMessageName is not null) exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Identify Details to Process Entity Information Display */
  select @vEntityInfoType = @vOperation + '_EntityInfo_' + EntityType from #ttSelectedEntities;
  select @vEntityInfoInput = (select @vEntityInfoType EntityType FOR XML RAW('Root'), ELEMENTS);

  exec pr_UI_GetEntityInfoDetails @vEntityInfoInput, @vUserId, @vBusinessUnit, @vEntityInfoDetails output;

  /* Build the Selection Filter for the Entity Info Detail processing */
  select @vEntityInfoDetailSelectionFilter = ( select ReferenceValueField as FieldName, 'Equals' FilterOperation, tt.EntityId FilterValue
                                               from FieldUIAttributes FA, #ttSelectedEntities tt where FA.ContextName = @vEntityInfoType For XML RAW('Filter'), ELEMENTS, ROOT('SelectionFilters') );
  select @vEntityInfoDetailInput = (select @vEntityInfoType EntityType, @vEntityInfoDetailSelectionFilter FOR XML RAW('Root'), ELEMENTS);

  /* Return the Entity Info Detail and Input */
  select @vEntityInfoDetails EntityInfoDetails, @vEntityInfoDetailInput EntityInfoDetailInput;

  /* Identify PrintList for Shipping Docs */
  exec pr_Printing_ProcessDocsRequest @PrintRequestInputXML;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_ProcessShippingDocs */

Go
