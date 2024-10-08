/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/13  MS      pr_Entities_ExecuteAction: Consider Receipt as Entity (Migrated from Trunk) (JL-247)
  2020/05/31  TK      pr_Entities_ExecuteAction: Action to remove orders from wave (HA-696)
  2020/05/27  RV      pr_Entities_ExecuteAction: Entity - OrderDetail: Made changes to insert selected entities into temp table
  2020/05/20  TK      pr_Entities_ExecuteAction: For V3 'ReleaseForAllocation' -> 'Waves_ReleaseForAllocation' (HA-608)
  2020/04/03  MS      pr_Entities_ExecuteAction: Changes to consider entity as Task (CIMSV3-561)
  2020/03/28  AY      pr_Entities_ExecuteAction: Fix in modifying receiver (JL-160)
  2020/03/26  RV      pr_Entities_ExecuteAction: Receivers - Close: Made changes to do not build duplicate receivers (JL-161)
  2020/03/16  MS      pr_Entities_ExecuteAction: Changes to Modify Orders (CIMSV3-424)
  2020/02/20  MS      pr_Entities_ExecuteAction: Changes to get ReceiptNumber in xml (JL-102)
  2020/01/23  RT      pr_Entities_ExecuteAction: Included new action PrepareForSorting (JL-88)
  2020/01/21  RIA     pr_Entities_ExecuteAction: Changes to insert values (JL-74)
  2020/01/02  RT      pr_Entities_ExecuteAction: Made changes to get the ReceiptNumber and process through Background Process
  2019/06/07  RT      pr_Entities_ExecuteAction: Included pr_Entities_ExecuteInBackGround to defer the receipts and display the message (CID-510)
  2019/03/25  AY      pr_Entities_ExecuteAction: Changed to create temp table only when required (CIMSV3-417)
  2019/02/22  RV      pr_Entities_ExecuteAction: Added action to prepare for receiving for Receipts and Receivers (CID-125)
                      pr_Entities_ExecuteAction: Revised operations for Confirm Picks and Confirm Tasks for Picking (S2GCA-469)
  2019/02/20  RV      pr_Entities_ExecuteAction: Added action to select LPNs for QC for Receipts (CID-123)
  2019/02/16  AY      pr_Entities_ExecuteAction: Map V3 to V2 (CIMSV3-219)
  2019/02/12  HB      pr_Entities_ExecuteAction: Added action to select LPNs for QC (CID-80)
  2018/11/05  TK      pr_Entities_ExecuteAction: Oprerations for Location Entity (HPI-2116)
  2018/09/28  CK      pr_Entities_ExecuteAction: Added action to modify carton Group for skus (HPI-2044)
  2018/09/25  SPP     pr_Entities_ExecuteAction: Modify the action name from close order to closePickTicket (CIMS-1941)
  2018/07/26  NB      pr_Entities_ExecuteAction_V3: enhanced to process action CreateInventory(CIMSV3-299)
  2018/06/29  NB      pr_Entities_ExecuteAction_V3: enhanced to add new action GenerateWavesviaSelectedRules(CIMSV3-153)
                      pr_Entities_ExecuteAction, pr_Entities_ExecuteAction_V3: changed calling code for pr_Entities_GetSelectedEntities procedure (CIMSV3-152)
                      pr_Entities_ExecuteAction, pr_Entities_ExecuteAction_V3: Modified caller to GetSelectedEntities procedure (CIMSV3-152)
  2018/03/05  RV      pr_Entities_ExecuteAction: Added PickBatches -> ReleaseForPicking (S2G-240)
  2018/02/20  NB      Modified pr_Entities_ExecuteAction_V3: Added code to handle AddOrdersToWave action(CIMSV3-153)
  2018/02/19  CK      pr_Entities_ExecuteAction: Added code to handle ReleaseForAllocation for Waves (S2G-104)
  2018/02/18  NB      Modified pr_Entities_ExecuteAction_V3: Added code to handle generate waves by rules action(CIMSV3-153)
  2018/02/16  NB      Modified pr_Entities_ExecuteAction_V3: Added code to handle generate waves by custom settings action(CIMSV3-153)
  2018/02/16  TK      pr_Entities_ExecuteAction: Made changes to input xml to work for receiver actions (CIMSV3-212)
  2018/01/30  TK      pr_Entities_ExecuteAction: Changes to execute Confirm Tasks for Picking action (S2G-153)
  2018/01/18  SV      pr_Entities_ExecuteAction, pr_Entities_GetSelectedEntities:
  2018/01/11  RV      pr_Entities_ExecuteAction: Enhanced to support ReOpen/Close Receipt actions for V3 (CIMSV3-176)
  2018/01/08  DK      pr_Entities_ExecuteAction: Enhanced to support CancelPTLine action for V3 (CIMSV3-178)
  2018/01/08  NB      Added pr_Entities_ExecuteAction_V3(CIMSV3-204)
  2018/01/06  YJ      pr_Entities_ExecuteAction: Enhanced to support ActivateLocations, DeactivateLocations action for Locations page (CIMSV3-174)
  2018/01/05  OK      pr_Entities_ExecuteAction: Enhanced to support Close Receivers actions for V3 (CIMSV3-176)
  2017/12/29  TK      pr_Entities_ExecuteAction: Enhanced to support LPNs actions for V3
  2017/12/19  NB      pr_Entities_ExecuteAction: Added comments explaining input xml format
  2016/06/23  TK      pr_Entities_ExecuteAction: Action to print Engraving Labels
  2016/06/10  MV      pr_Entities_ExecuteAction: Added Action to allow user to modify Receipt Details (FB-706)
  2016/06/03  RV      pr_Entities_ExecuteAction: Added Pallet entity to clear the user from cart (NBD-573)
  2016/01/19  KL      pr_Entities_ExecuteAction: New action - RemoveZeroQtySKUs from LPNs page (OB-407).
  2015/12/15  KL      pr_Entities_ExecuteAction: Added CCTasks->CancelCCTasks (CIMS-501)
  2015/03/09  SK      pr_Entities_ExecuteAction: Included logic to unpack Batch or Order (CIMS-584).
  2013/11/28  AY      pr_Entities_ExecuteAction:At present all Task actions call modify,
  2013/08/22  NY      pr_Entities_ExecuteAction: Included Close RO and Open RO actions.
  2013/07/29  SP      pr_Entities_ExecuteAction: Included Activate and Deactivate Location actions.
  2013/04/25  PKS     pr_Entities_ExecuteAction: Modify OrderHeaders related entities are added.
  2012/12/28  PKS     pr_Entities_ExecuteAction: replace the root node with the ModifyLoads node
  2012/12/07  YA      pr_Entities_ExecuteAction: Included code to cancel batches.
  2012/11/06  PKS     Procedure name was changed from pr_Entities_Modify to pr_Entities_ExecuteAction
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entities_ExecuteAction') is not null
  drop Procedure pr_Entities_ExecuteAction;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entities_ExecuteAction:
    A common wrapper procedure to execute an action from UI on any entity.

  ------------------------------------------------------------------------------------------
    IN THE CASE OF CIMS V3 (See down below for V2 specific information )
  ------------------------------------------------------------------------------------------
  @EntityXML format should be like below:

  For action 'Activate' or 'Deactivate'Location:
   <Root>
    <Action>ActionId</Action>
    <Entity>EntityType</Entity>
    <SelectedRecords>...<SelectedRecords>
    <RecordFilters>..</RecordFilters>
    <SelectionFilters>...</SelectionFilters>
    <Data>...</Data>
    <Options>...</Options>
    <SessionInfo>..</SessionInfo>
  </Root>

  <Action>ActionId</Action> - ActionId to process, requested from the application or caller
  <Entity>EntityType</Entity> - Entity Type of the records to be processed
                                Ex: LPN for LPNs, Location for Locations, etc.,.
  ------------------------------------------------------------------------------------------
  <SelectedRecords>...<SelectedRecords>
  This node will carry the details of EntityKeys and/or EntityIds related to the records to be processed
  This node is present in the Xml when the user is attempting to operate on records in a Listing layout
  The format with EntityKeys will be as below

  <SelectedRecords>
    <RecordDetails>
      <EntityId>43825</EntityId>
      <EntityKey>00000990040000036344</EntityKey>
    </RecordDetails>
    <RecordDetails>
      <EntityId>43826</EntityId>
      <EntityKey>00000999570002425835</EntityKey>
    </RecordDetails>
  </SelectedRecords>

  In the above example, each <Recorddetails> node represents the EntityId and EntityKey values for
  the selected records. There will be as many RecordDetails as the number of Selected Records

  ------------------------------------------------------------------------------------------
  <RecordFilters>..</RecordFilters>
  This node will carry the details of records which should be process. This node is present in the Xml
  when the user is attempting to operate on records in a Summary Layout
  The format will be as below

  <RecordFilters>
    <RecordFilter>
      <Filter>
        <FieldName>Location</FieldName>
        <FilterOperation>Equals</FilterOperation>
        <FilterValue>1A-02-A-01</FilterValue>
        ..
        ..
      </Filter>
      <Filter>
        <FieldName>StatusDescription</FieldName>
        <FilterOperation>Equals</FilterOperation>
        <FilterValue>Putaway</FilterValue>
        ..
        ..
      </Filter>
    </RecordFilter>
    <RecordFilter>
      <Filter>
        <FieldName>Location</FieldName>
        <FilterOperation>Equals</FilterOperation>
        <FilterValue>1A-02-B-03</FilterValue>
        ..
        ..
      </Filter>
      <Filter>
        <FieldName>StatusDescription</FieldName>
        <FilterOperation>Equals</FilterOperation>
        <FilterValue>Putaway</FilterValue>
        ..
        ..
      </Filter>
    </RecordFilter>
  </RecordFilters>

  <RecordFilters> node can have one or more <RecordFilter> node. each <RecordFilter> corresponds to one
  record in the summary layout, and the operation must be performed entity records matching the records
  Every <RecordFilter> shall have one or more <Filter> nodes
  A <Filter> node shall have the following nodes to be used. Other nodes within the <Filter> can be ignored for now
        <FieldName>Location</FieldName>
        <FilterOperation>Equals</FilterOperation>
        <FilterValue>1A-02-A-01</FilterValue>
  FieldName applies to the column which the filter applies to
  FilterOperation defines the condition to apply to the fieldname
  FilterValue applies to the value to compare with in the condition
  the example should be translated to a where clause "Location = '1A-02-A-01' "

  All filters in <RecordFilter> node should be processed similarly to build a sql where clause
  ------------------------------------------------------------------------------------------
  <SelectionFilters>...</SelectionFilters>
  This node will carry the details of conditions to apply while identifying the records to process.
  This node is mostly present in the Xml for both listing and summary layout operations.
  The format will be as below
  <SelectionFilters>
    <Filter>
      <FilterType>L</FilterType>
      <FieldName>Archived</FieldName>
      <FilterOperation>Equals</FilterOperation>
      ...
      ...
    </Filter>
    <Filter>
      <FieldName>OnhandStatus</FieldName>
      <FilterOperation>NotEquals</FilterOperation>
      <FilterValue>U</FilterValue>
      ...
      ...
    </Filter>
  </SelectionFilters>

  Similar to <RecordFilter>, the <Filter> within <SelectionFilters> should be processed to build a sql where clause

  The whereclause related to each <RecordFilter> are combined with the where clause from <SelectionFilters> to identify
  the records which must be processed for the action performed. This process should be repeated and applied to each <RecordFilter>'
  node under the <RecordFilters>
  ------------------------------------------------------------------------------------------
    <Data>...</Data>

    Data node will contain the inputs from the user. This values within this node will be dynamic in nature
    and are specific to the action performed.
    For Example: for ChangeSKU action, the Data node shall be as below
    <Data>
      <SKU>120570</SKU>
    </Data>
    Here SKU node value is the new SKU to update to the suggested records
  ------------------------------------------------------------------------------------------
    <Options>...</Options>

    Options node will contain any odditional inputs apart from the data related.
    For Example: Users may sometime select one record, but later suggest to apply the operation to all the records
    from the options form. In which case, the Xml will have the Options node as below.
      <Options>
        <ApplyToAllRecords>TRUE</ApplyToAllRecords>
      </Options>
      ApplyToAllRecords = TRUE indicates that the operation shall be performed on all the recods matching the input selection filters
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
    IN THE CASE OF V2
  ------------------------------------------------------------------------------------------
  @EntityXML format should be like below:

  For action 'Activate' or 'Deactivate'Location:
   <Root>
    <Action>Activate</Action>
    <Entity>Location</Entity>
    <Locations>
      <LocationId>431017</LocationId>
      <LocationId>431018</LocationId>
      <LocationId>431019</LocationId>
    </Locations>

For action Create Receiver:
    <Root>
       <Entity>Receiver</Entity>
       <Action>CreateReceiver</Action>
       <Data>
          <BoLNo></BoLNo>
          <ContainerNo></ContainerNo>
          <Reference1></Reference1>
          <Reference2></Reference2>
          <Reference3></Reference3>
          <Reference4></Reference4>
          <UDF1></UDF1>
          <UDF2></UDF2>
          <UDF3></UDF3>
          <UDF4></UDF4>
          <UDF5></UDF5>
       </Data>
    </Root>

  For action Order details Modify:
    <Root>
      <Entity>OrderDetails</Entity>
      <Action></Action>
      <data>
        <ToShip></ToShip>
      </data>
      <OrderDetails>
        <OrderDetail>
          <OrderDetailId></OrderDetailId>
        </OrderDetail>
      </OrderDetails>
    </Root>

  For action Loads - Generate BoLs:
    <Root>
      <Entity>Loads</Entity>
      <Action>GenerateBoLs</Action>
      <data>
        <Regenerate></Regenerate>
      </data>
      <Loads>
          <LoadId></LoadId>
      </Loads>
    </Root>

  For action PickBatch_Cancel:
    <Root>
      <Entity>PickBatches</Entity>
      <Action>CancelBatch</Action>
      <Batches>
        <BatchNo></BatchNo>
        <BatchNo></BatchNo>
      </Batches>
    </Root>

  For action Wave_Unpack or OrderHeaders_Unpack:
    <Root>
        <Entity>Wave</Entity>
        <Action>Unpack</Action>
        <PickCart></PickCart>
        <Waves>
          <WaveNo></WaveNo>
        </Waves>
        <Orders>
          <OrderId></OrderId>
          <OrderId></OrderId>
        </Orders>
    </Root>

Samples:
<Root>
  <Entity>Batches</Entity>
  <Action>CancelBatch</Action>
  <Batches>
    <BatchNo>0829092</BatchNo>
    <BatchNo>0829560</BatchNo>
  </Batches>
</Root>

For Taskcancellation:
Samples:
<Root>
  <Entity>Tasks</Entity>
  <Action>CancelTask</Action>
  <Tasks>
    <TaskId>1</TaskId>
    <TaskId>2</TaskId>
  </Tasks>
</Root>


Generic xml from V3 app:

<Root>
  <Entity>LPN</Entity>
  <Action>ChangeSKU</Action>
  <SelectedRecords>
    <EntityKey>101731</EntityKey>
  </SelectedRecords>
  <Data>
    <SKU>ED1765NV-2X</SKU>
  </Data>
  <Options>
    <ApplyToAllRecords>TRUE</ApplyToAllRecords>
  </Options>
  <UIInfo>
    <LayoutDescription>Standard</LayoutDescription>
    <ContextName>List.LPNs</ContextName>
  </UIInfo>
  <SessionInfo>
    <UserId>rfcadmin</UserId>
    <BusinessUnit>SCT</BusinessUnit>
  </SessionInfo>
</Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Entities_ExecuteAction
  (@EntityXML     TXML,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @xmlResult     TXML           = null output)
as
  declare @ReturnCode            TInteger = 0,
          @MessageName           TMessageName,
          @Message               TDescription,

          @vEntity               TEntity,
          @xmlData               xml,
          @vAction               TAction,

          @vActivityLogId        TRecordId,
          @vApplyToAllRecords    TFlags,
          @vSKU                  TSKU,
          @vReasonCode           TReasonCode,
          @vReceiptId            TRecordId,
          @vReceiptNumber        TReceiptNumber,
          @vReceiverNumber       TReceiverNumber,
          @vReceiverId           TRecordId,
          @vSelectedEntitiesXML  TXML,
          @vReceiverXML          xml;

  declare @ttSelectedEntities    TEntityValuesTable;

begin
  /* Extracting data elements from XML. */
  set @xmlData = convert(xml, @EntityXML);

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col);

  if (@BusinessUnit is null) or (@UserId is null)
    select @BusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
           @UserId       = Record.Col.value('UserId[1]', 'TUserId')
    from @xmlData.nodes('/Root/SessionInfo') as Record(Col);

  select @vSKU            = Record.Col.value('SKU[1]',              'TSKU'),
         @vReasonCode     = Record.Col.value('ReasonCode[1]',       'TReasonCode'),
         @vReceiverNumber = Record.Col.value('ReceiverNumber[1]',   'TReceiverNumber')
  from @xmlData.nodes('/Root/Data') as Record(Col);

  /* Execute action V3 is called by V3 which inserts the selected records into #ttSelectedEntities */
  if object_id('tempdb..#ttSelectedEntities') is not null
    insert into @ttSelectedEntities (EntityId, EntityKey, RecordId) select EntityId, EntityKey, RecordId from #ttSelectedEntities;

  /* Log the request */
  exec pr_ActivityLog_AddMessage @vAction, null /* Entity Id */, null /* EntityKey */, @vEntity,
                                 null /* Message */, @@ProcId, @Entityxml, @BusinessUnit, @UserId,
                                 @ActivityLogId = @vActivityLogId output;

  /* Create #ttSelectedEntities table to work in V2, as directly use temp table in core proc */
  if object_id('tempdb..#ttSelectedEntities') is not null
    select * into #ttSelectedEntities from @ttSelectedEntities;

  /* Routing the execution to the corresponding procedure based on Entity and Action */
  if (@vEntity in ('OrderDetail', 'OrderDetails'))
    begin

      /* Insert the records to process with temp table in core procedures */
      insert into #ttSelectedEntities(EntityId)
        select Record.Col.value('OrderDetailId[1]', 'TRecordId') as EntityId
        from @xmlData.nodes('/Root/OrderDetails/OrderDetail') as Record(Col);

      if (@vAction in ('ModifyOrderDetails', 'CancelPTLine'))
        begin
          exec @ReturnCode = pr_OrderDetails_Modify @xmlData, @BusinessUnit, @UserId,
                                                    @xmlResult output;
        end

      if (@ReturnCode >0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('Load', 'Loads')) and
     (@vAction = 'MarkAsShipped')
    begin
      /* Replace the root node with the ModifyLoads node */
      select @EntityXML = replace(@EntityXML, 'Root', 'ModifyLoads'),
             @xmlData   = convert(xml, @EntityXML);

      exec @ReturnCode = pr_Load_Modify @xmlData,
                                        @BusinessUnit,
                                        @UserId,
                                        @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('Load', 'Loads')) and
     (@vAction = 'GenerateBoLs')
    begin
      /* Replace the root node with the ModifyLoads node */
      select @EntityXML = replace(@EntityXML, 'Root', 'ModifyLoads'),
             @xmlData   = convert(xml, @EntityXML);

      exec @ReturnCode = pr_Load_Modify @xmlData,
                                        @BusinessUnit,
                                        @UserId,
                                        @xmlResult output;
      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity = 'Receiver')
    begin
      /* Get the receiver number from the input xml */
      select @vReceiverNumber = Record.Col.value('ReceiverNo[1]', 'TReceiverNumber')
      from @xmlData.nodes('/Root/Data') as Record(Col);

      /* Get the ReceiverId */
      select @vReceiverId = ReceiverId
      from Receivers
      where (ReceiverNumber = @vReceiverNumber) and (BusinessUnit = @BusinessUnit);

      if (@vAction = 'CreateReceiver')
        begin
          exec @ReturnCode = pr_Receivers_Create @xmlData, @BusinessUnit, @UserId,
                                                 @xmlResult output;
        end
      else
      if (@vAction = 'ModifyReceiver')
        begin
          exec @ReturnCode = pr_Receivers_Modify @xmlData, @BusinessUnit, @UserId,
                                                 @xmlResult output;
        end
      else
      if (@vAction = 'AssignASNLPNs')
        begin
          exec @ReturnCode = pr_Receivers_AssignASNLPNs @xmlData, @BusinessUnit, @UserId,
                                                        @xmlResult output;
        end
      else
      if (@vAction = 'UnAssignLPNs')
        begin
          exec @ReturnCode = pr_Receivers_UnAssignLPNs @xmlData, @BusinessUnit, @UserId,
                                                       @xmlResult output;
        end
      else
      if (@vAction = 'CloseReceiver')
        begin
          exec @ReturnCode = pr_Receivers_Close @xmlData, @BusinessUnit, @UserId,
                                                @xmlResult output;
        end
      else
      if (@vAction = 'PrepareForReceiving')
        begin
          /* Execute the BackGroud process to defer receipts in PrepareForReceiving */
          exec pr_Entities_ExecuteInBackGround 'Receiver', @vReceiverId /* EntityId */, @vReceiverNumber /* EntityKey */, @Operation = 'PrepareForReceiving', @BusinessUnit = @BusinessUnit;

          /* Get the Message to display in the UI */
          set @xmlResult = dbo.fn_Messages_GetDescription('Receivers_PrepareForReceiving_ExecuteInBackGround');
        end
      else
      if (@vAction = 'SelectLPNsForQC')
        exec @ReturnCode = pr_QCInbound_SelectLPNs null /* ReceiptId */, null /* ReceiptNumber */, null /* ReceiverId */, @vReceiverNumber, default /* LPNs */,
                                                     null /* Operation */, @BusinessUnit, @UserId, @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('Wave', 'PickBatches')) and
     (@vAction in ('CancelBatch', 'Waves_Cancel', 'PlanBatch', 'Waves_Plan', 'UnplanBatch', 'Waves_Unplan', 'CloseBatch'  ,
                   'Waves_ReleaseForAllocation', 'ReleaseForAllocation', 'Waves_ReleaseForPicking', 'ReleaseForPicking',
                   'Waves_Modify', 'ModifyPriority', 'Waves_Reallocate', 'ReallocateBatch'))
    begin
      /* Replace the root node with the ModifyPickBatches node */
      select @EntityXML = replace(@EntityXML, 'Root', 'ModifyPickBatches');

      /* call the pr_PickBatch_Modify procedure which will futher loop and call
      pr_PickBatch_Cancel and cancels all the batches one by one */
      exec @ReturnCode = pr_PickBatch_Modify @BusinessUnit,
                                             @UserId,
                                             @EntityXML,
                                             @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('OrderHeader', 'OrderHeaders')) and
     (@vAction in ('ModifyShipVia', 'CancelPickTicket', 'ClosePickTicket', 'ModifyPickTicket', 'CloseOrder', 'ModifyShipDetails', 'RemoveOrdersFromWave'))
    begin
      /* This change needed in V2, Since OrderHeaders_Modify expects different tags */
      select @EntityXML = dbo.fn_XMLRenameTag(@EntityXML, 'Root', 'ModifyOrders'),
             @EntityXML = dbo.fn_XMLRenameTag(@EntityXML, 'Data', 'OrderData');

      exec @ReturnCode = pr_OrderHeaders_Modify @EntityXML,
                                                @BusinessUnit,
                                                @UserId,
                                                @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('OrderHeader', 'OrderHeaders')) and
     (@vAction = 'PrintEngravingLabels')
    begin
      exec @ReturnCode = pr_OrderHeaders_GetEngravingLabelsToPrint @EntityXML,
                                                                   @BusinessUnit,
                                                                   @UserId,
                                                                   @xmlResult output;
      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('Location', 'Locations')) /* YJ: Need to discuss on this */
  /* As far now, for the Location page actions we are not calling this procedure and
     invoking this below block of code. For those actions we are calling pr_Locations_Modify directly */
    begin
      /* If caller is V3 then replace the SelectedRecords node with Data Node */
      if exists (select * from @ttSelectedEntities)
        begin
          select @vSelectedEntitiesXML = cast((select EntityId as LocationId
                                               from @ttSelectedEntities
                                               order by EntityId
                                               for xml path(''), elements, root('Locations')) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
          select @EntityXML = replace(@EntityXML, 'Root', 'ModifyLocations');
        end

      /* call the pr_Location_Modify procedure to activate or deactivate location */
      exec pr_Locations_Modify @EntityXML, @BusinessUnit, @UserId,
                               @xmlResult output;
    end
  else
  -- /* The below is a special case where user wants to remove zero SKUs from static picklanes locations during off-season
  --    and hence, they wanted to remove SKUs using logical LPNs from LPNs page */
  -- if (@vEntity = 'PicklaneLPNs'/* Picklane LPNs */) and
  --    (@vAction = 'RemoveZeroQtySKUs')
  --   begin
  --     /* Replace the root node with the RemoveZeroQtySKUs node */
  --     select @EntityXML = replace(@EntityXML, 'Root', 'RemoveSKUs');
  --
  --     /* Remove SKUs */
  --     exec @ReturnCode = pr_Locations_RemoveSKUs @EntityXML,
  --                                                @BusinessUnit,
  --                                                @UserId,
  --                                                @xmlResult output;
  --
  --     if (@ReturnCode > 0)
  --       goto ErrorHandler;
  --   end
  -- else
  if (@vEntity in ('Receipt', 'Receipts', 'ReceiptOrder'))
    begin
      /* Get ReceiptId from the input xml */
      select @vReceiptId     = Record.Col.value('ReceiptId[1]',     'TRecordId'),
             @vReceiptNumber = Record.Col.value('ReceiptNumber[1]', 'TReceiptNumber')
      from @xmlData.nodes('/Root/Receipts') as Record(Col);

      /* If caller is V3 then replace the SelectedRecords node with Data Node */
      if exists (select * from @ttSelectedEntities)
        begin
          select @vSelectedEntitiesXML = cast((select EntityId as ReceiptId
                                               from @ttSelectedEntities
                                               order by EntityId
                                               for xml path(''), elements, root('Receipts')) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
        end

      if (@vAction = 'PrepareForReceiving')
        begin
          /* Execute the BackGround process to defer receipts in PrepareForReceiving */
          exec pr_Entities_ExecuteInBackGround 'ReceiptHdr', @vReceiptId /* EntityId */, @Operation = 'PrepareForReceiving', @BusinessUnit = @BusinessUnit;

          /* Get the Message to display in the UI */
          set @xmlResult = dbo.fn_Messages_GetDescription('Receipts_PrepareForReceiving_ExecuteInBackGround');
        end
      else
      if (@vAction = 'PrepareForSorting')
        begin
          exec @ReturnCode = pr_Receipts_PrepareForSortation @EntityXML, null /* Operation */, @BusinessUnit, @UserId,
                                                             @MessageName output, @xmlResult output;
        end
      else
      if (@vAction = 'SelectLPNsForQC')
        exec @ReturnCode = pr_QCInbound_SelectLPNs @vReceiptId, null /* ReceiptNumber */, null /* ReceiverId */, null /* ReceiverNumber */, default /* LPNs */,
                                                   null /* Operation */, @BusinessUnit, @UserId, @xmlResult output;
      else
        begin
          /* Replace the root node with the ModifyReceiptOrders node */
          select @EntityXML = replace(@EntityXML, 'Root', 'ModifyReceiptOrders');

          /* Call pr_ReceiptHeaders_Modify procedure to modify RH */
          exec pr_ReceiptHeaders_Modify @EntityXML, @BusinessUnit, @UserId,
                                        @xmlResult output;
        end

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('PickTask', 'Tasks', 'Task')) and
     (@vAction in ('AssignTaskToUser','AssignTaskDetailToUser', 'CancelTask', 'CancelTaskDetail', 'ReleaseTask', 'ConfirmTaskForPicking'))/* All Actions - AssignUser, CancelTask, CancelTaskDetail, ReleaseTask */
    begin
      /* Replace the root node with the ModifyTasks node */
      select @EntityXML = replace(@EntityXML, 'Root', 'ModifyTasks');

      /* call the pr_Tasks_Modify procedure which will further loop and call
      pr_Tasks_Cancel and cancels all the tasks one by one */
      exec @ReturnCode = pr_Tasks_Modify @BusinessUnit,
                                         @UserId,
                                         @EntityXML,
                                         @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity = 'CCTasks') and
     (@vAction in ('CancelCCTasks'))
    begin
      exec @ReturnCode = pr_CC_ModifyCCTasks @EntityXML,
                                             @BusinessUnit,
                                             @UserId,
                                             @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('Wave', 'OrderHeaders')) and
     (@vAction  = 'Unpack')
    begin
      /* Unpack wave(s) or order(s) */
      exec @ReturnCode = pr_Packing_Unpack @xmlData,
                                           @BusinessUnit,
                                           @UserId,
                                           @MessageName output,
                                           @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity = 'Returns') and
     (@vAction = 'ValidateReturns')
    begin
      /* Create Returns */
      exec @ReturnCode = pr_Returns_ValidateReturnPackage @xmlData,
                                                          @BusinessUnit,
                                                          @UserId,
                                                          @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity = 'Returns') and
     (@vAction = 'CreateReturns')
    begin
      /* Create Returns */
      exec @ReturnCode = pr_Returns_CreateReturns @xmlData,
                                                  @BusinessUnit,
                                                  @UserId,
                                                  @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity = 'Pallet')
    begin
      /* If caller is V3 then replace the SelectedRecords node with Data Node */
      if exists (select * from @ttSelectedEntities)
        begin
          select @vSelectedEntitiesXML = cast((select EntityId  as PalletId,
                                                      EntityKey as Pallet
                                               from @ttSelectedEntities
                                               order by EntityId
                                               for xml path(''), elements, root('Pallets')) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
        end

       /* Replace the root node with the ModifyPallets node */
      select @EntityXML = replace(@EntityXML, 'Root', 'ModifyPallets');

      /* Clear User From Cart */
      exec @ReturnCode = pr_Pallets_Modify @EntityXML,
                                           @BusinessUnit,
                                           @UserId,
                                           @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity in ('ReceiptDetails', 'ReceiptDetails')) and (@vAction = 'ModifyReceiptDetails')
    begin
      /* Replace the root node with the ModifyReceiptDetails node */
      select @EntityXML = replace(@EntityXML, 'Root', 'ModifyReceiptDetails');

      /* Update ReceiptDetails */
      exec @ReturnCode = pr_ReceiptDetails_Modify @EntityXML,
                                                  @BusinessUnit,
                                                  @UserId,
                                                  @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity = 'Role') and (@vAction = 'ModifyEntityFilterConfig')
    begin
      /* Update ReceiptDetails */
      exec @ReturnCode = pr_Roles_EntityFilterConfig_Modify @xmlData,
                                                            @BusinessUnit,
                                                            @UserId,
                                                            @xmlResult output;

      if (@ReturnCode > 0)
        goto ErrorHandler;
    end
  else
  if (@vEntity = 'LPN')
    begin
      select @EntityXML = replace(@EntityXML, 'Root', 'ModifyLPNs');

      if (@vAction = 'VoidLPNs')
        begin
          exec pr_LPNs_Void @EntityXML, @BusinessUnit, @UserId, @vReasonCode,
                            @vReceiverNumber, @vAction, @xmlResult output;
        end
      else
        begin
          exec pr_LPNs_Modify @UserId, @EntityXML, @BusinessUnit, @xmlResult output;
        end
    end
  else
  if (@vEntity in ('SKU', 'SKUs')) -- V2 & V3 have diff notation in this regard
    begin
      /* Replace the root node with the ModifySKUs node */
      select @EntityXML = replace(@EntityXML, 'Root', 'ModifySKUs');

      /* Modify SKus */
      exec @ReturnCode = pr_SKUs_Modify  @EntityXML,
                                         @BusinessUnit,
                                         @UserId,
                                         @xmlResult output;

      if (@ReturnCode >0)
        goto ErrorHandler;
    end

  /* Log the response */
  exec pr_ActivityLog_AddMessage @vAction, null /* Entity Id */, null /* EntityKey */, @vEntity,
                                 @Message, @@ProcId, @xmlResult, @BusinessUnit, @UserId,
                                 @ActivityLogId = @vActivityLogId;

ErrorHandler:
  if (@MessageName is not null)
    begin
      select @MessageName = dbo.fn_Messages_GetDescription(@MessageName),
             @ReturnCode  = 1;
      raiserror(@MessageName, 16, 1);
    end
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Entities_ExecuteAction */

Go
