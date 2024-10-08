/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this procedure exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

  2021/10/14  AY      pr_Printing_GetNextPrintJobToProcess, pr_Printing_ProcessDocsRequest:
                        Changed the finalization rules to be separate so that they can be executed by themselves (OB2-2081)
  2021/04/16  RV      pr_Printing_ProcessDocsRequest: Made changes to return summary print list for shipping docs (CIMSV3-964)
  2020/12/02  RV      pr_Printing_ShippingDocs_AddPrintJob: Initial version (HA-1659)
                      pr_Printing_GetNextPrintJobToProcess, pr_Printing_UpdatePrintJobResult: Made changes to next print job
                        with out dependent on label printer if not available (HA-1659)
              RV      pr_Printing_ProcessDocsRequest: Made changes to get and insert the Warehouse with respect to the entity type (HA-1704)
  2020/08/17  VS      pr_Printing_ProcessDocsRequest: Made changes to improve the performance (HA-1322)
  2020/06/30  NB      Added pr_Printing_ProcessShippingDocs, changes to ProcessDocRequest procedure to validate
                        whether ttSelectedEntities is already created(CIMSV3-963)
              RV      pr_Printing_ProcessDocsRequest: Made changes to convert print data to base64 and return (HA-1053)
  2020/04/05  NB      pr_Printing_ProcessDocsRequest: cleanup and changes for revised implementation(CIMSV3-221)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_ProcessDocsRequest') is not null
  drop Procedure pr_Printing_ProcessDocsRequest;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_ProcessDocsRequest: Processes input print request details, and returns the list
  of print jobs or instructions for the Application to run to fulfill the print request

  XML Format will be same as pr_Entities_ExecuteActions_V3
  Details of XML Nodes and sections in relation to ProcessDocsRequest explained below

  <Root>
    <Entity></Entity>
    <Action></Action>
    <Data>
      <Operation>ShippingDocs</Operation>
      <Debug>SE,ETP</Debug>
    </Data>
    <SelectedRecords>
      <RecordDetails>
        <EntityId></EntityId>
        <EntityKey></EntityKey>
      </RecordDetails>
      <RecordDetails>
        <EntityId></EntityId>
        <EntityKey></EntityKey>
      </RecordDetails>
      <RecordDetails>
        <EntityId></EntityId>
        <EntityKey></EntityKey>
      </RecordDetails>
    </SelectedRecords>
    <SessionInfo>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
      <UserId>cims</UserId>
    </SessionInfo>
    <UIInfo>
      <ContextName></ContextName>
      <LayoutDescription></LayoutDescription>
    </UIInfo>
  </Root>

  <Entity>  This may not be present for some actions like ShippingDocs

  <SelectedRecords>
  For ShippingDocs, the SelectedRecords structure will be containing value entered by user in EntityKey node
  For Packing, the SelectedRecords structure will contain the Packed LPN value in EntityKey node
  For Actions related to printing Labels or Docs from Listings of Wave, Loads, Tasks etc.,. the SelectedRecords
  will indicate the EntityId and EntityKey values of user selected records

  <Operation>
  The Operation may or may not be given depending on type of process
  For Example: Packing and ShippingDocs will send the Operation, to apply operation specific rules, since the Action in
               these cases could be a generic name PrintDocuments
               For Entity Specific actions like PrintWaveDocuments, PrintTaskDocuments, PrintOrderDocuments, there may not
               be any operation. The Action can be used as Operation

  <UIInfo>  This will not be present for Non-Listing actions like Packing, ShippingDocs
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_ProcessDocsRequest
  (@PrintRequestInputXML TXML)
as
  declare @vPrintRequestInputXML   xml,
          @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vDebug                  TFlags,  -- use 'SE,ETP' to display temp tables

          @vEntity                 TEntity,
          @vAction                 TAction,
          @vDeviceId               TDeviceId,
          @vUserId                 TUserId,
          @vWarehouse              TWarehouse,
          @vBusinessUnit           TBusinessUnit,
          @vPrintRequestId         TRecordId,
          @vOperation              TDescription,
          @vRulesDataXML           TXML,
          @vRuleSetType            TRuleSetType,
          @vShippingDocsSummaryReq TControlValue;

  declare @ttSelectedEntities      TEntityValuesTable;
  declare @ttEntitiesToPrint       TEntitiesToPrint;
  declare @ttPrintList             TPrintList;

  /* To hold data set of the types of documents for user to filter the print list easily */
  declare @ttDocumentSelectorList table(RecordId            TRecordId    identity(1,1),
                                        KeyFieldName        TEntity,
                                        KeyFieldValue       TEntityKey,
                                        KeyFieldDescription TDescription,
                                        ParentKeyFieldName  TEntityKey,
                                        SortSeq             TSortSeq);

begin /* pr_Printing_ProcessDocsRequest */
  select @vReturnCode  = 0,
         @vMessagename = null;

  /* Extracting data elements from XML. */
  set @vPrintRequestInputXML = convert(xml, @PrintRequestInputXML);

  /* Capture Information */
  select @vEntity       = nullif(Record.Col.value('Entity[1]',             'TEntity'), ''),
         @vAction       = Record.Col.value('Action[1]',                    'TAction'),
         @vUserId       = Record.Col.value('(SessionInfo/UserId)[1]',      'TUserId'),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',    'TDeviceId'),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]','TBusinessUnit'),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',          'TDescription'),
         @vDebug        = Record.Col.value('(Data/Debug)[1]',              'TFlags')
  from @vPrintRequestInputXML.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vPrintRequestInputXML = null ) );

  select @vOperation  = coalesce(@vOperation, @vAction); -- consideration Action to be operation in case operation is not passed in

  /* Read debug settings */
  if (@vDebug is null)
    exec pr_Debug_GetOptions @@ProcId, @vAction /* @Operation */, @vBusinessUnit, @vDebug output;

  /* create ttSelectedEntities  temp table, if not already existing */
  if (object_id('tempdb..#ttSelectedEntities') is null)
    select * into #ttSelectedEntities from @ttSelectedEntities;

  /* Create temp tables */
  select * into #EntitiesToPrint from @ttEntitiesToPrint;
  select * into #PrintList from @ttPrintList;
  select * into #DocumentSelectorList from @ttDocumentSelectorList;

  /* This procedure inserts the records into #ttSelectedEntities temp table */
  if (not exists (select RecordId from #ttSelectedEntities))
    exec pr_Entities_GetSelectedEntities @vEntity, @vPrintRequestInputXML, @vBusinessUnit, @vUserId;

  if (not exists (select RecordId from #ttSelectedEntities))
    select @vMessageName = 'PrintRequest_InvalidInput';

  if (@vMessageName is not null) goto ErrorHandler;

  if (charindex('D', @vDebug) > 0) select 'Before', * from #ttSelectedEntities;

  /*****************/
  /* this is already transformed into Rules and used in ProcessShippingDocs for CIMSV3-963, when
     that change is approved, this should be removed
   */
  /*****************/

  /* There are instances where input contains only key values, without entity type
     identify the entitytype and Ids for such instances
     TODO..this should be transferred to rules
     Below should be changed to call ExecuteAllRules for IdentifyEntityType RuleSetType  */
  if (exists (select RecordId from #ttSelectedEntities where EntityType is null))
    begin
      update tt
      set EntityType = case when (L.LPN is not null)        then 'LPN'
                            when (P.Pallet is not null)     then 'Pallet'
                            when (O.PickTicket is not null) then 'Order'
                            when (W.BatchNo is not null)    then 'Wave'
                            when (LD.LoadNumber is not null) then 'Load'
                            else tt.EntityType end,
          EntityId   = coalesce(nullif(tt.EntityId, 0), L.LPNId, P.PalletId, O.OrderId, W.RecordId, LD.LoadId),
          EntityKey  = coalesce(tt.EntityKey, L.LPN, P.Pallet, O.PickTicket, W.BatchNo)
      from #ttSelectedEntities tt
        left outer join LPNs L         on (L.LPN        = tt.EntityKey) and (L.BusinessUnit = @vBusinessUnit)
        left outer join Pallets P      on (P.Pallet     = tt.EntityKey) and (P.BusinessUnit = @vBusinessUnit)
        left outer join OrderHeaders O on (O.PickTicket = tt.EntityKey) and (O.BusinessUnit = @vBusinessUnit)
        left outer join Waves W        on (W.BatchNo    = tt.EntityKey) and (W.BusinessUnit = @vBusinessUnit)
        left outer join Loads LD       on (L.LoadNumber = tt.EntityKey) and (LD.BusinessUnit = @vBusinessUnit)
      where (tt.EntityType is null);
    end

  /* It is possible the the input could be different value used instead of LPNId, in such a case, verify the value
     this is seperated as this has performance implications */
  if (exists (select RecordId from #ttSelectedEntities where EntityType is null))
    begin
        update tt
        set EntityType = case when (L.LPN is not null) then 'LPN'
                              else tt.EntityType end,
            EntityId   = coalesce(tt.EntityId, L.LPNId),
            EntityKey  = coalesce(tt.EntityKey, L.LPN)
        from #ttSelectedEntities tt
          left outer join LPNs L         on (L.LPNId = dbo.fn_LPNs_GetScannedLPN(tt.EntityKey, @vBusinessUnit, default /* Options */)) and (L.BusinessUnit = @vBusinessUnit)
        where (tt.EntityType is null);
    end

  if (charindex('D', @vDebug) > 0) select 'After', * from #ttSelectedEntities;

  /* Insert the request information into PrintRequest table
     TODO..this insert into PrintRequests will be recorded as IMMEDIATE
     However, this has to be enhanced to decide whether to print Immediately or Queue the request */
  insert into PrintRequests (RequestOperation, RequestXML, BusinessUnit, CreatedBy)
    select @vOperation, @PrintRequestInputXML, @vBusinessUnit, @vUserId;

  select @vPrintRequestId = Scope_Identity();

  /* Build the xml for Rules */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                                           dbo.fn_XMLNode('Operation',       @vOperation) +
                                           dbo.fn_XMLNode('Action',          @vAction) +
                                           dbo.fn_XMLNode('Entity',          @vEntity) +
                                           dbo.fn_XMLNode('PrintRequestId',  @vPrintRequestId) +
                                           dbo.fn_XMLNode('BusinessUnit',    @vBusinessUnit) +
                                           dbo.fn_XMLNode('UserId',          @vUserId));

  select @vRuleSetType = 'EntitiesToPrint';
  exec pr_RuleSets_ExecuteAllRules @vRuleSetType, @vRulesDataXML, @vBusinessUnit;
  exec pr_RuleSets_ExecuteAllRules 'EntitiesToPrint_Finalize', @vRulesDataXML, @vBusinessUnit;

  /* The Warehouse of the print request is not known until the entities to print are determined,
     so this is fetched after EntitiesToPrint */
  select top 1 @vWarehouse = Warehouse from #EntitiesToPrint where Warehouse is not null;

  update PrintRequests set Warehouse = @vWarehouse where (PrintRequestId = @vPrintRequestId);

  exec pr_Printing_ProcessPrintList @vOperation, @vRulesDataXML, @vBusinessUnit, @vUserId;

  if (charindex('SE',  @vDebug) > 0) select 'SE',  * from #ttSelectedEntities;
  if (charindex('ETP', @vDebug) > 0) select 'ETP', * from #EntitiesToPrint;
  if (charindex('PL', @vDebug) > 0)  select 'PL',  * from #PrintList;

  /* Update the print request id on print list records */
  update PL
  set PL.PrintRequestId = @vPrintRequestId
  from #PrintList PL;

  /* Convert binary data to base64 and update on newly added column */
  update ttPrintList
  set PrintDataBase64 = binary.PrintDataString
  from #PrintList ttPrintList
    cross apply (select PrintData '*' for xml path('')) binary (PrintDataString)
  where ttPrintList.PrintData is not null

  /* Drop PrintData column */
  alter table #PrintList drop column PrintData;

  /* Return data set with base64 data */
  select *, PrintDataBase64 as PrintData,
         case when @vDebug <> '' then
           cast(cast(PrintDataBase64 as XML ).value('.', 'varbinary(max)') AS varchar(max))
           else ''
         end PrintDataReadable
  from #PrintList
  order by SortOrder;

  exec pr_RuleSets_ExecuteAllRules 'DocumentSelector', @vRulesDataXML, @vBusinessUnit;

  if (exists (select * from #DocumentSelectorList))
    select * from #DocumentSelectorList order by SortSeq;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_ProcessDocsRequest */

Go
