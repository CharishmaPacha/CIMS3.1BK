/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/13  SV      pr_AMF_Returns_ConfirmReceiveRMA, pr_AMF_Returns_ValidateEntity:
  2021/04/21  SV      pr_AMF_Returns_ConfirmReceiveRMA: Provided option to scan Picklane and receive the Returns Inv into it (OB2-1774)
  2021/04/20  SV      pr_AMF_Returns_ConfirmReceiveRMA: Resolved the issue with duplicate RMA exports (OB2-1754)
              SV      pr_AMF_Returns_ConfirmReceiveRMA: Changes to putaway the created Inv to the scanned PickLane Location (OB2-1774)
  2021/03/31  SV      pr_AMF_Returns_ConfirmReceiveRMA: Consolidating records based on the scanned duplicates (OB2-1758)
  2021/03/31  SV      pr_AMF_Returns_ConfirmReceiveRMA: Resolved the issue(to void the LPNs) while Scrap is selected as disposition
  2021/03/31  SV      pr_AMF_Returns_ConfirmReceiveRMA: Resolved issue with generating exports on building LPNs over Pallet (OB2-1756)
  2021/03/15  SV      pr_AMF_Returns_ConfirmReceiveRMA: Changes to create, receive and close RMA (OB2-1358)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Returns_ConfirmReceiveRMA') is not null
  drop Procedure pr_AMF_Returns_ConfirmReceiveRMA;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Returns_ConfirmReceiveRMA: Following is the summary of the this
    functionality.
  1) LPN I/P is optional. Hence if no LPN(Tote) is provided, then Carton gets created
     and successively LPNDs gets inserted.
  2) If Tote is scanned then LPNDs itself get inserted.
  3) RMA(Receipt) gets created and successively RDs gets created w.r.t the count of
     SKUs scanned.
  4) If the Disposition selected is Scrap, then the respective LPN will gets voided
     else, LPN will be moved as Inventory.
  5) The LPN can be moved to the Location once by building them over to the Pallet
     (using Build Pallet operation) and then moved to Picklanes using PutawayToPickLanes.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Returns_ConfirmReceiveRMA
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vxmlInput                 xml,

          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vScannedEntity            TEntity,
          @vScannedEntityType        TEntity;

          /* Functional variables */
  declare @vRecordId                 TRecordId,
          @vReceiptId                TRecordId,
          @vReceiptNumber            TReceiptNumber,
          @vOrderId                  TRecordId,
          @vLPNId                    TRecordId,
          @vPickTicket               TPickTicket,
          @vFirstLPNId               TRecordId,
          @vLastLPNId                TRecordId,
          @vFirstLPN                 TLPN,
          @vLastLPN                  TLPN,
          @vSKUId                    TRecordId,
          @vReceiptsUpdated          TCount,
          @vOwnership                TOwnership,
          @vWarehouse                TWarehouse,
          @vMessage                  TMessage,
          @vMessageName              TMessageName,
          @vRHTotalNumUnits          TCount,
          @vRHTotalUnitsReceived     TCount,
          @vRHTotalLPNsReceived      TCount,
          @vDefaultScrapCode         TControlValue,
          @vLocationId               TRecordId,
          @vQuantity                 TQuantity,
          @vLocation                 TLocation,
          @vToLPNId                  TRecordId,
          @vToLPNDetailId            TRecordId,
          @vAuditActivity            TActivityType,

          @vxmlEntityDetails         xml,
          @vLPNsToVoid               TXML,
          @vLPNsToCreate             TInteger;

  declare @ttScannedDetails table (EntityType    TTypeCode,  -- could be 'LPN' or 'Location'
                                   EntityId      TRecordId,  -- could be LPNId or LocationId
                                   EntityKey     TEntityKey, -- could be LPN or Location
                                   LPNId         TRecordId,
                                   LPN           TLPN,
                                   LocationId    TRecordId,
                                   Location      TLocation,
                                   SKUId         TRecordId,
                                   SKU           TSKU,
                                   Quantity      TQuantity,
                                   ReasonCode    TReasonCode,
                                   Disposition   TMessageName,
                                   RecordId      TRecordId identity(1,1));

  declare @ttReceipts         TEntityKeysTable,
          @ttLPNDetails       TLPNDetails,
          @ttReceiptDetails   TReceiptDetailImportType;

  declare @vScannedLPNInfo          TLPN,
          @vScannedSKUInfo          TSKU,
          @vScannedQuantityInfo     TQuantity,
          @vScannedReasonCodeInfo   TReasonCode,
          @vScannedDispositionInfo  TMessageName;

begin /* pr_AMF_Returns_ConfirmReceiveRMA */

  select @vxmlInput          = convert(xml, @InputXML), /* Convert input into xml var */
         @vReceiptsUpdated   = 0,
         @vRecordId          = 0;

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Create hash tables */
  if object_id('tempdb..#CreateLPNDetails') is null     select * into #CreateLPNDetails from @ttLPNDetails;
  if object_id('tempdb..#ScannedDetails') is null       select * into #ScannedDetails from @ttScannedDetails;
  if object_id('tempdb..#LPNsToReceive') is null        select * into #LPNsToReceive from @ttLPNDetails;

  /* Read the inputs */
  select @vBusinessUnit       = Record.Col.value('(SessionInfo/BusinessUnit)[1]',              'TBusinessUnit'),
         @vUserId             = Record.Col.value('(SessionInfo/UserName)[1]',                  'TUserId'      ),
         @vDeviceId           = Record.Col.value('(SessionInfo/DeviceId)[1]',                  'TDeviceId'    ),
         @vScannedEntity      = Record.Col.value('(Data/m_Entity)[1]',                         'TEntity'      ),
         @vScannedEntityType  = Record.Col.value('(Data/m_ScannedEntityType)[1]',              'TEntity'      )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* The below control value is client specific. For OB it is 321 */
  select @vDefaultScrapCode = dbo.fn_Controls_GetAsString('Receipts_RMA', 'DefaultScrapCode', '321', @vBusinessUnit, @vUserId);

  /* User will be scanning LPN or Location in the same I/P textbox.
     Hence, LPN/Location field values will be returned in EntityKey column only.
     EntityType will be evaluated and returned from pr_AMF_Returns_ValidateLPNOrLocation and sent here. */
  insert into @ttScannedDetails(EntityType, EntityId, EntityKey, SKU, Quantity, ReasonCode, Disposition)
    select nullif(Record.Col.value('EntityType[1]',      'TEntity'), ''),
           nullif(Record.Col.value('EntityId[1]',        'TRecordId'), ''),
           nullif(Record.Col.value('EntityKey[1]',       'TEntityKey'), ''),
           nullif(Record.Col.value('SKU[1]',             'TSKU'), ''),
           nullif(Record.Col.value('Quantity[1]',        'TQuantity'), ''),
           nullif(Record.Col.value('Reason[1]',          'TReasonCode'), ''),
           nullif(Record.Col.value('Disposition[1]',     'TMessageName'), '')
    from @vxmlInput.nodes('//Root/Data/ReturnData/ReturnTable') as Record(Col);

  /* Check if user scanned LPN/UCC/TrackingNo */
  if (@vScannedEntityType = 'LPN')
    begin
      select @vLPNId     = LPNId,
             @vOrderId   = OrderId,
             @vOwnership = Ownership,
             @vWarehouse = DestWarehouse
      from LPNs
      where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vScannedEntity, @vBusinessUnit, 'LTU'));
    end

  if (@vScannedEntityType = 'PickTicket')
    select @vOrderId = OrderId
    from Orderheaders
    where (PickTicket = @vScannedEntity) and (BusinessUnit = @vBusinessUnit);

  if (@vScannedEntityType = 'RMA')
    select @vReceiptId     = ReceiptId,
           @vReceiptNumber = ReceiptNumber,
           @vPickTicket    = PickTicket,
           @vOwnership     = Ownership,
           @vWarehouse     = Warehouse
    from ReceiptHeaders
    where (ReceiptNumber = @vScannedEntity) and (BusinessUnit = @vBusinessUnit);

  if (@vOrderId is not null)
    select @vPickTicket = PickTicket,
           @vOwnership  = coalesce(@vOwnership, Ownership),
           @vWarehouse  = coalesce(@vWarehouse, Warehouse)
    from OrderHeaders
    where (OrderId = @vOrderId);

  /* In RF, user may be scanning the same items again and again and we want to
     consolidate those into one LPN, so summarize here */
  insert into #ScannedDetails (EntityType, EntityId, EntityKey, SKU, Disposition, ReasonCode, Quantity)
    select EntityType, EntityId, EntityKey, SKU, Disposition, ReasonCode, sum(Quantity)
    from @ttScannedDetails
    group by EntityType, EntityId, EntityKey, SKU, Disposition, ReasonCode
    order by EntityType, EntityId, EntityKey, SKU, Disposition, ReasonCode;

  /* Update the key info */
  update #ScannedDetails
  set LPNId      = case when EntityType = 'LPN'      then EntityId  else null end,
      LPN        = case when EntityType = 'LPN'      then EntityKey else null end,
      LocationId = case when EntityType = 'Location' then EntityId  else null end,
      Location   = case when EntityType = 'Location' then EntityKey else null end;

  /* Update SKUId */
  update #ScannedDetails
  set SKUId = (select top 1 SKUId from fn_SKUs_GetScannedSKUs (SKU, @vBusinessUnit));

  /* Check how many of the records do not have an LPN so we can generate as needed */
  select @vLPNsToCreate = count(*) from #ScannedDetails where (LPNId is null);

  /* Generate Cartons if no Tote is scanned */
  if (@vLPNsToCreate > 0)
    exec @vReturnCode = pr_LPNs_Generate 'C' /* LPNType */,
                                         @vLPNsToCreate,
                                         null /* LPNFormat */,
                                         @vWarehouse /* Warehouse */,
                                         @vBusinessUnit,
                                         @vUserId,
                                         @vFirstLPNId   output,
                                         @vFirstLPN     output,
                                         @vLastLPNId    output,
                                         @vLastLPN      output;

  /* Link the created LPNs with the scanned details as needed. All the records which
     do not have LPN would have RecordIds from 1 to the number of LPNs created */
  update #ScannedDetails
  set LPNId = @vFirstLPNId + RecordId - 1
  where (LPN is null);

  /* If Users didn't scan LPN, then we are generating the LPNs and LPNIds in the earlier code. update LPN where we have LPNId */
  update SD
  set SD.LPN = L.LPN
  from #ScannedDetails SD join LPNs L on SD.LPNId = L.LPNId
  where (SD.LPNId is not null) and (SD.LPN is null);

  /* If user scans LPN, then update the LPNId */
  update SD
  set SD.LPNId = L.LPNId
  from #ScannedDetails SD join LPNs L on SD.LPN = L.LPN and L.BusinessUnit = @vBusinessUnit
  where (SD.LPNId is null) and (SD.LPN is not null);

  /* Populate #CreateLPNDetails to be able to create the Details for these LPNs */
  insert into #CreateLPNDetails (LPNId, SKUId, OnhandStatus, InnerPacks, UnitsPerPackage, Quantity, Weight, Reference, BusinessUnit)
    output Inserted.LPNId, Inserted.Reference
    into #LPNsToReceive (LPNId, Reference)
    select LPNId, SKUId, 'U', 0, 0, Quantity, 0.0, Disposition, @vBusinessUnit
    from #ScannedDetails;

  /* LPNDs will be inserted with the below procedure call. Recount of the LPNs will be taken care with in that. */
  exec pr_LPNs_CreateLPNs null, null;

  /* Update LPNs with relevant info */
  update L
  set L.PickingClass = SD.Disposition,
      L.ReasonCode   = SD.ReasonCode
  from LPNs L join #ScannedDetails SD on (L.LPNId = SD.LPNId);

  /* As we are not using #CreateLPNs to create LPNs, the below error message is formulated from pr_LPNs_CreateLPNs.
     Once we switch the code in using #CreateLPNs to create LPNs, we can remove the below statement. */
  if object_id('tempdb..#ResultMessages') is not null
    delete #ResultMessages where MessageText = 'LPN_CreateInvLPNs_NoneCreated';

  /* Generate RMA with Details and export the same to the host */
  if (@vReceiptId is null)
    exec pr_Receipts_GenerateRMA @vOwnership, @vWarehouse, @vBusinessUnit, @vUserId,
                                 @vReceiptId output, @vReceiptNumber output;

  /* Update ReceiptId over LPNs created */
  update L
  set L.ReceiptId = @vReceiptId
  from LPNs L
    join #LPNsToReceive LTR on (L.LPNId = LTR.LPNId);

  /* Update ReceiptId over LPNDetails created */
  update LD
  set LD.ReceiptId = @vReceiptId
  from LPNDetails LD
    join #LPNsToReceive LTR on (LD.LPNId = LTR.LPNId);

  /* Update RDId over LPNs based on the ReceiptId over the LPNs */
  update LD
  set LD.ReceiptDetailId = RD.ReceiptDetailId
  from LPNDetails LD
      join ReceiptDetails RD on (LD.SKUId = RD.SKUId) and (LD.ReceiptId = RD.ReceiptId)
  where (LD.ReceiptId = @vReceiptId);

  select @vRHTotalNumUnits      = sum(QtyOrdered),
         @vRHTotalUnitsReceived = sum(QtyReceived),
         @vRHTotalLPNsReceived  = sum(LPNsReceived)
  from ReceiptDetails
  where (ReceiptId = @vReceiptId);

  /* Update PickTicket and counts over the RMA created
     Currently pr_ReceiptHeaders_Recount in OB is not functionally right
     as ReceiptStats changes needed to be migrated from V3. */
  --update ReceiptHeaders
  --set PickTicket    = @vPickTicket,
  --    NumUnits      = @vRHTotalNumUnits,
  --    UnitsReceived = coalesce(@vRHTotalUnitsReceived, 0),
  --    LPNsReceived  = @vRHTotalLPNsReceived
  --from ReceiptHeaders
  --where (ReceiptId = @vReceiptId);

  /* Audit Trail */
  if (@vScannedEntityType = 'RMA')
    select @vAuditActivity = 'RMAReceived';
  else
    select @vAuditActivity = 'CreateRMA';

  exec pr_AuditTrail_Insert @vAuditActivity, @vUserId, null /* ActivityTimestamp */,
                            @ReceiptId    = @vReceiptId,
                            @Quantity     = @vScannedQuantityInfo,
                            @ReasonCode   = @vScannedReasonCodeInfo,
                            @BusinessUnit = @vBusinessUnit;

  /* Putaway the LPNs(likewise we do at pr_Receivers_PutawayInventory). Recv exports will be sent from the below call itself. */
  /* With the below call, Recv transactions for LPN TransEntity are generated. */
  exec pr_Receipts_PutawayInventory null /* ReceiverNo */, @vReceiptId, @vBusinessUnit, @vUserId;

  /* If the Disposition is Scrap(RC is 321), then we need to void that LPN.
     This means, we need to sent the +ve transactions as Recv(in the above call) and -ve transactions as it is being voided. */
  select @vLPNsToVoid = ('<ModifyLPNs>' +
                          '<Data>' +
                            '<ReasonCode>' + cast(coalesce(nullif(@vScannedReasonCodeInfo, ''), 341) as varchar) + '</ReasonCode>' +
                            '<BusinessUnit>' + @vBusinessUnit + '</BusinessUnit>' +
                            '<UserId>' + @vUserId + '</UserId>' +
                          '</Data>' +
                          (select LPNId as LPNId
                           from #LPNsToReceive
                           where (Reference = @vDefaultScrapCode)
                           for xml Path('LPNContent'), root('LPNs')) +
                         '</ModifyLPNs>');

  /* -ve transactions will be sent from here for LPN TransEntity. */
  if (@vLPNsToVoid is not null)
    begin
      /* ReasonCode is mandatory to void the LPNs if the disposition is scrap.
         If no ReasonCode is scanned by the user, then default it. */
      select @vScannedReasonCodeInfo = coalesce(nullif(@vScannedReasonCodeInfo, ''), 341);

      exec pr_LPNs_Void @vLPNsToVoid,
                        @vBusinessUnit,
                        @vUserId,
                        @vScannedReasonCodeInfo,
                        null /* ReceiverNumber */,
                        'VoidLPNs' /* Operation */,
                        @vMessage output;
    end

  insert into @ttReceipts(EntityId)
     select @vReceiptId;

  /* If user scanned a Receipt to return the units, then don't close it as they will be doing manually */
  if (@vScannedEntityType <> 'RMA')
    exec pr_ReceiptHeaders_ROClose @ttReceipts,
                                   'N' /* No */,
                                   @vBusinessUnit,
                                   @vUserId,
                                   @vReceiptsUpdated output,
                                   @vMessage output;

  /* If PickLane location is scanned instead of LPN, then putaway the created Inv to that Location.
     If the dispostion is selected as Scrap, then we don't need to putaway the Inv as its gets voided earlier in the code.*/
  while (exists(select * from #ScannedDetails where (Location is not null and Disposition <> @vDefaultScrapCode and RecordId > @vRecordId)))
    begin
      select top 1
             @vRecordId   = RecordId,
             @vLPNId      = LPNId,
             @vLocationId = LocationId,
             @vSKUId      = SKUId,
             @vQuantity   = Quantity
      from #ScannedDetails
      where (Location is not null) and
            (Disposition <> @vDefaultScrapCode) and
            (RecordId > @vRecordId)
      order by RecordId;

      /* In the current context of returns, we won't be generating any exports
         with the below call until and unless if the scanned location is from a different Warehouse.
         Generally, FromLPN will be in Putaway status.*/
      exec @vReturnCode = pr_Putaway_LPNContentsToPicklane @vLPNId         /* FromLPNId     */,
                                                           @vSKUId         /* SKUId         */,
                                                           0               /* PAInnerPacks  */,
                                                           @vQuantity      /* PAQuantity    */,
                                                           @vLocationId    /* ToLocationId  */,
                                                           @vBusinessUnit  /* BusinessUnit  */,
                                                           @vUserId        /* UserId        */,
                                                           @vToLPNId       /* ToLPNId       */,
                                                           @vToLPNDetailId /* ToLPNDetailId */;

      if (@vReturnCode = 0)
        exec pr_AuditTrail_Insert 'PutawayLPNToPicklane', @vUserId, null /* ActivityTimestamp */,
                                  @LPNId        = @vLPNId,
                                  @ToLPNId      = @vToLPNId,
                                  @SKUId        = @vSKUId,
                                  @Quantity     = @vQuantity,
                                  @ToLocationId = @vLocationId;
    end

  exec pr_ReceiptHeaders_Recount @vReceiptId;

  if (@vScannedEntityType <> 'RMA')
    if (@vFirstLPN is not null)
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(dbo.fn_Messages_Build('CreatedRMA_LPNs_Successful', @vReceiptNumber, null, null, null, null));
    else
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(dbo.fn_Messages_Build('CreatedRMA_Totes_Successful', @vReceiptNumber, null, null, null, null));
  else
    select @InfoXML = dbo.fn_AMF_BuildSuccessXML(dbo.fn_Messages_Build('Returns_ReceivedSuccessfully', @vReceiptNumber, null, null, null, null));

  /* Build the DataXML */
  select @DataXML = (select 'Done' Resolution
                     for Xml Raw(''), elements, Root('Data'));
end /* pr_AMF_Returns_ConfirmReceiveRMA */

Go

