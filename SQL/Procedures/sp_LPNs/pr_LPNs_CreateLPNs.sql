/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/31  RKC     pr_LPNDetails_AddOrUpdate, pr_LPNs_CreateLPNs: Made changes to get the update the lot as empty instead of null (Onsite support)
  2022/02/03  RKC     pr_LPNs_CreateLPNs_Validate, pr_LPNs_CreateLPNs: Made changes to validate if the user selected the Multiple UOM SKU's and tried to generate LPNs (BK-218)
  2021/08/24  KBB     pr_LPNs_CreateLPNs: Made the changes to update Reference values to ReceiptNumber (BK-518)
  2021/03/29  TK      pr_LPNs_CreateLPNs: Changes to defer counts based upon operation (HA-2471)
  2021/01/19  TK      pr_LPNDetails_AddOrUpdate & pr_LPNs_CreateLPNs: Consider SKU.DefaulCoO if nothing passed in (HA-1912)
  2020/09/12  TK      pr_LPNs_CreateLPNs: Changes to create Kit LPNs
                      pr_LPNs_CreateLPNs_TransferInventory: Code Refractoring
                      pr_LPNs_CreateLPNs_CreateKits, pr_LPNs_CreateLPNs_MaxKitsToCreate, pr_LPNs_Locate:
  2020/07/28  AY      pr_LPNs_CreateLPNs: Update Reference on Pallets (HA-1244)
  2020/07/07  OK      pr_LPNs_CreateLPNs: Changes to update the refrence on LPNs (HA-440)
  2020/07/01  TK      pr_LPNs_CreateLPNs: Changes to consume inventory while creating inventory
                      pr_LPNs_CreateLPNs_Validate: Changes to pupulate inventory to be consumed
                      pr_LPNs_CreateLPNs_TransferInventory: Initial Revision
  2020/06/26  TK      pr_LPNs_CreateLPNs & pr_LPNs_CreateLPNs_Validate: Fixes to invoke these procs from create inventory action (HA-830)
  2020/06/26  NB      pr_LPNs_CreateLPNs_Validate: changes to validate Input Warehouse, Warehouse of Receipt and Receiver(CIMSV3-987)
  2020/04/26  TK      pr_LPNs_CreateLPNs: Changes create LPNs if user sends information
  2020/03/19  TK      pr_LPNs_CreateLPNs & pr_LPNs_SplitLPN: Changes to update ReceiverId on LPNs
  2020/03/13  TK      pr_LPNs_CreateLPNs: Get the range of LPNs generated by LPN instead of LPNId (S2GCA-1110)
  2020/02/13  RT      pr_LPNs_CreateLPNs_ActivateKits: Changes to recount the LPNs after the LPNDetails are Updated
  2020/01/08  HYP     pr_LPNs_CreateLPNs: Added Audit Log on drop location (FB-1752)
  2019/12/27  RT      pr_LPNs_CreateLPNs_ActivateKits: Updates on Generated Kits and Picked Kits to process
                      pr_LPNs_CreateLPNs: Create Kits and update the post results on generated Kits
                      pr_LPNs_CreateLPNs_Validate: Evaluating Rules to validate fixture LPNs
                      pr_LPNs_CreateLPNs_MaxKitsToCreate: Validate if SKU does exists in the location, Changes to validate and create Kits to process
  2019/10/11  AY      pr_LPNs_CreateLPNs: Enhance to create LPNs for Orders (FB-1402)
  2019/10/03  RT      pr_LPNs_CreateLPNs: Uncommented the code to update the ReceivedCounts (FB-1415)
  2019/09/27  AY      pr_LPNs_CreateLPNs: Create Received LPNs (FB-1377)
                      pr_LPNs_CreateLPNs_GetDetails: To get list of SKUs to show in Receiving
  2012/04/25  YA      Added pr_LPNs_CreateLPN, pr_LPNs_CreateLPNs.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_CreateLPNs') is not null
  drop Procedure pr_LPNs_CreateLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_CreateLPNs: Procedure to create LPNs with multi-detail LPNs. There
    are various ways to create LPNs and corresponding details.

  a. Caller can pass in LPN info and LPN DetailInfo as input xml (usage: UI Create Inv LPNs)
  b. Caller can pass in LPNs and corresponding LPN Details via # tables #CreateLPNs & #CreateLPNDetails
  c. Caller can pass in only #CreateLPNDetails - with the LPNId already in there (usage: Cubing)

  In each of these approaches, the LPNs and/or details are inserted, recalculated.
  If either Receipt or Order info is passed in, it is expected to be only for one of them.

  xmlInput:

  <CreateLPNs>
    <LPNHeader>
      <LPNType></LPNType>
      <LPNStatus></LPNStatus>
      <OnhandStatus></OnhandStatus>
      <Operation></Operation>
      <ReceiptId>0</ReceiptId>
      <ReceiptNumber></ReceiptNumber>
      <ReceiverNumber></ReceiverNumber>
      <OrderId></OrderId>
      <Pallet></Pallet>
      <NumLPNsToCreate></NumLPNsToCreate>
      <Ownership></Ownership>
      <Lot></Lot>
      <Warehouse></Warehouse>
      <ReasonCode></ReasonCode>
      <Reference></Reference>
      <ExpiryDate></ExpiryDate>
      <CreatedDate></CreatedDate>
      <GeneratePallet></GeneratePallet>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
    </LPNHeader>
    <LPNDetails>
      <Detail>
        <ReceiptDetailId></ReceiptDetailId>
        <OrderDetailId></OrderDetailId>
        <SKUId></SKUId>
        <UoM></UoM>
        <Cases></Cases>
        <Quantity></Quantity>
        <UnitsPerCase></UnitsPerCase>
        <Lot></Lot>
        <CoO></CoO>
      </Detail>
      ....
      ....
      <Detail>
        <ReceiptDetailId></ReceiptDetailId>
        <OrderDetailId></OrderDetailId>
        <SKUId></SKUId>
        <UoM></UoM>
        <Cases></Cases>
        <Quantity></Quantity>
        <UnitsPerCase></UnitsPerCase>
        <Lot></Lot>
        <CoO></CoO>
      </Detail>
    </LPNDetails>
  </CreateLPNs>


  xmlOutput:

  <ResultXML>
    <Response>
      <Status>Success</Status>
      <ResponseMessage>Created LPN C000001052 created successfully</ResponseMessage>
    </Response>
    <LPNs>
      <LPN></LPN>
      <LPN></LPN>
    </LPNs>
  </ResultXML>

  Generate Pallet: Now we have added 3 options here
       1. If user selects generate then we need to generate a pallet.  Flag is -Y
       2. if user selcted Scan then he should scan the Pallet, otherwise we will
          raise an error.  Flag Is N
       3. If user selects ignore then we do not generate any Pallet, we do not
          raise any  error. Flag is I
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_CreateLPNs
 (@InputXML      TXML  = null,
  @OutputXML     TXML  = null  output)
as
  /* Declare local variables */
  declare @vMessageName           TMessageName,
          @vReturnCode            TInteger,
          @vDebugOptions          TFlags = 'N',
          @vxmlInput              XML,
          @vxmlRulesData          TXML,
          /* Input params */
          @LPNType                TTypeCode,
          @LPNStatus              TStatus,
          @NumLPNsToCreate        TCount,
          @NumLPNsPerPallet       TCount,
          @Action                 TAction,
          @GeneratePallet         TFlags,
          @SKUId                  TRecordId,
          @Pallet                 TPallet,
          @Lot                    TLot,
          @Expirydate             TDate,
          @CoO                    TCoO,
          @Ownership              TOwnership,
          @InventoryClass1        TInventoryClass,
          @InventoryClass2        TInventoryClass,
          @InventoryClass3        TInventoryClass,
          @Warehouse              TWarehouse,
          @ReasonCode             TReasonCode,
          @Reference              TReference,
          @CreatedDate            TDate,
          @Operation              TOperation,
          @ReceiverId             TRecordId,
          @ReceiptId              TRecordId,
          @OrderId                TRecordId,
          @BusinessUnit           TBusinessUnit,
          @UserId                 TUserId,
          /* output params */
          @vFirstLPNId            TRecordId,
          @vLastLPNId             TRecordId,
          @vFirstLPN              TLPN,
          @vLastLPN               TLPN,
          @vNumLPNsCreated        TCount,
          @vMessage               TMessage,
          /* Receiving */
          @vReceiverId            TRecordId,
          @vReceiverNumber        TReceiverNumber,
          @vReceiptId             TRecordId,
          @vReceiptNumber         TReceiptNumber,
          @vReceiptType           TTypeCode,
          /* Order */
          @vOrderId               TRecordId,
          @vPickTicket            TPickTicket,
          @vSalesOrder            TSalesOrder,
          @OrderDetailId          TRecordId,
          /* LPN */
          @vLPNId                 TRecordId,
          @vNumLPNDetails         TCount,
          @vQuantity              TInteger,
          /* Pallet */
          @vPalletId              TRecordId,
          @vPallet                TPallet,
          /* Variables */
          @vActivityType          TActivityType,
          @vAuditRecordId         TRecordId,
          @vOnhandStatus          TStatus,
          @vNote1                 TDescription,
          @vNote2                 TDescription,
          @vNumPalletsToCreate    TCount,
          @vFirstPalletId         TRecordId,
          @vFirstPallet           TPallet,
          @vLastPalletId          TRecordId,
          @vLastPallet            TPallet,
          @vRecountLPNs           TFlags;

  declare @ttLPNs                 TEntityKeysTable,
          @ttLPNsToRecount        TRecountKeysTable,
          @ttLPNDetails           TLPNDetails,
          @ttOrderDetails         TOrderDetails,
          @ttPallets              TRecountKeysTable,
          @ttLocations            TEntityKeysTable,
          @ttErrorInfo            TErrorInfo;
begin
begin try
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vNumLPNsCreated = 0,
         @vxmlInput       = convert(xml, @InputXML);

  /* CreateLPNs: Hash table to hold the list of LPNs created */
  if object_id('tempdb..#CreateLPNs') is null
    select * into #CreateLPNs from @ttLPNs;

  /* Create hash table to hold the details of each LPN to be created */
  if object_id('tempdb..#CreateLPNDetails') is null
    select * into #CreateLPNDetails from @ttLPNDetails;
  select * into #LPNDetails from @ttLPNDetails;
  select * into #Pallets from @ttPallets;
  select * into #ReceiveLPNDetails from @ttLPNDetails;
  select * into #KitComponentsInfo from @ttOrderDetails;
  select * into #InventoryToConsume from @ttLPNDetails;
  select * into #ErrorInfo from @ttErrorInfo;

  /* Get the XML User inputs into the local variables */
  select @LPNType          = Record.Col.value('LPNType[1]'             , 'TTypeCode'),
         @NumLPNsToCreate  = Record.Col.value('NumLPNsToCreate[1]'     , 'TInteger'),
         @NumLPNsPerPallet = Record.Col.value('NumLPNsPerPallet[1]'    , 'TInteger'),
         @GeneratePallet   = Record.Col.value('GeneratePallet[1]'      , 'TFlag'),
         @SKUId            = Record.Col.value('SKUId[1]'               , 'TRecordId'),
         @Pallet           = Record.Col.value('Pallet[1]'              , 'TPallet'),
         @Lot              = coalesce(Record.Col.value('Lot[1]'        , 'TLot'), ''),
         @CoO              = nullif(Record.Col.value('CoO[1]'          , 'TCoO'), ''),
         @ExpiryDate       = Record.Col.value('ExpiryDate[1]'          , 'TDate'),
         @Ownership        = Record.Col.value('Owner[1]'               , 'TOwnership'),
         @Warehouse        = Record.Col.value('Warehouse[1]'           , 'TWarehouse '),
         @ReasonCode       = Record.Col.value('ReasonCode[1]'          , 'TReasonCode'),
         @Reference        = Record.Col.value('Reference[1]'           , 'TReference'),
         @CreatedDate      = nullif(Record.Col.value('CreatedDate[1]'  , 'TDate'), ''),
         @Operation        = Record.Col.value('Operation[1]'           , 'TOperation'),
         @ReceiverId       = nullif(Record.Col.value('ReceiverId[1]'   , 'TRecordId'), 0),
         @ReceiptId        = nullif(Record.Col.value('ReceiptId[1]'    , 'TRecordId'), 0),
         @OrderId          = nullif(Record.Col.value('OrderId[1]'      , 'TRecordId'), 0),
         @OrderDetailId    = nullif(Record.Col.value('OrderDetailId[1]', 'TRecordId'), 0),
         @InventoryClass1  = rtrim(Record.Col.value('InventoryClass1[1]', 'TInventoryClass')),
         @InventoryClass2  = rtrim(Record.Col.value('InventoryClass2[1]', 'TInventoryClass')),
         @InventoryClass3  = rtrim(Record.Col.value('InventoryClass3[1]', 'TInventoryClass'))
  from @vxmlInput.nodes('Root/Data') as Record(Col);

  select @Action       = Record.Col.value('Action[1]',                      'TAction'),
         @BusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',  'TBusinessUnit'),
         @UserId       = Record.Col.value('(SessionInfo/UserId)[1]',        'TUserId')
  from @vxmlInput.nodes('Root') as Record(Col);

  /* Setup defaults/computed fields */
  select @LPNType          = coalesce(nullif(@LPNType, ''), 'C'),
         @NumLPNsPerPallet = coalesce(@NumLPNsPerPallet, 0),
         @CreatedDate      = coalesce(@CreatedDate, current_timestamp),
         @vRecountLPNs     = case when @Operation in ('GenerateShipCartons', 'CubeOrderDetails', 'CubeTaskDetails') then 'N' else 'Y' end;

  /* Get the details of each LPN */
  if not exists (select * from #CreateLPNDetails)
    begin
      if exists(select * from @vxmlInput.nodes('Root/Data/SKUDetail/Detail') as Record(Col))
        insert into #CreateLPNDetails (SKUId, UoM, InnerPacks, UnitsPerPackage, Quantity,
                                       ReceiptId, ReceiptDetailId, OrderId, OrderDetailId,
                                       InventoryClass1, InventoryClass2, InventoryClass3, Lot, CoO)
          select Record.Col.value('SKUId[1]'                   , 'TRecordId'),
                 Record.Col.value('UOM[1]'                     , 'TUoM'),
                 Record.Col.value('InnerPacksPerLPN[1]'        , 'TInteger'),
                 Record.Col.value('UnitsPerInnerPack[1]'       , 'TInteger'),
                 Record.Col.value('UnitsPerLPN[1]'             , 'TInteger'),
                 nullif(Record.Col.value('ReceiptId[1]'        , 'TRecordId'), 0),
                 nullif(Record.Col.value('ReceiptDetailId[1]'  , 'TRecordId'), 0),
                 nullif(Record.Col.value('OrderId[1]'          , 'TRecordId'), 0),
                 nullif(Record.Col.value('OrderDetailId[1]'    , 'TRecordId'), 0),
                 @InventoryClass1, @InventoryClass2, @InventoryClass3,
                 Record.Col.value('Lot[1]'                     , 'TLot'),
                 nullif(Record.Col.value('CoO[1]'              , 'TCoO'), '')
          from @vxmlInput.nodes('Root/Data/SKUDetail/Detail') as Record(Col);
      else
        insert into #CreateLPNDetails (SKUId, UoM, InnerPacks, UnitsPerPackage, Quantity,
                                   ReceiptId, ReceiptDetailId, OrderId, OrderDetailId,
                                       InventoryClass1, InventoryClass2, InventoryClass3, Lot, CoO)
      select Record.Col.value('SKUId[1]'                   , 'TRecordId'),
                 Record.Col.value('UoM[1]'                     , 'TUoM'),
             Record.Col.value('InnerPacksPerLPN[1]'        , 'TInteger'),
             Record.Col.value('UnitsPerInnerPack[1]'       , 'TInteger'),
             Record.Col.value('UnitsPerLPN[1]'             , 'TInteger'),
             nullif(Record.Col.value('ReceiptId[1]'        , 'TRecordId'), 0),
             nullif(Record.Col.value('ReceiptDetailId[1]'  , 'TRecordId'), 0),
             nullif(Record.Col.value('OrderId[1]'          , 'TRecordId'), 0),
             nullif(Record.Col.value('OrderDetailId[1]'    , 'TRecordId'), 0),
                 @InventoryClass1, @InventoryClass2, @InventoryClass3,
             Record.Col.value('Lot[1]'                     , 'TLot'),
             nullif(Record.Col.value('CoO[1]'              , 'TCoO'), '')
      from @vxmlInput.nodes('Root/Data') as Record(Col);
    end

  select @vNumLPNDetails = count(*) from #CreateLPNDetails;

  /*-------------------- begin --------------------*/
  exec pr_ActivityLog_AddMessage 'CreateLPNs', null, null, null, null, @@ProcId, @InputXML;

  begin transaction

  /*------------- Prepare LPN Details -------------*/
  /* We do this ahead of time because these may be validated */

  /* Calculate OnhandStatus of Detail */
  select @vOnhandStatus = 'U' /* Unavailable */;

  update #CreateLPNDetails
  set Quantity = InnerPacks * UnitsPerPackage
  where (Quantity = 0) and (InnerPacks > 0) and (UnitsPerPackage > 0);

  update CLD
  set SKU             = S.SKU,
      Weight          = coalesce(Quantity * S.UnitWeight, 0.0),
      Volume          = coalesce(Quantity * S.UnitVolume, 0.0),
      Lot             = coalesce(Lot, @Lot, ''),
      CoO             = coalesce(CoO, @CoO, S.DefaultCoO),
      InnerPacks      = coalesce(InnerPacks, 0),
      UoM             = coalesce(CLD.UoM, case when CLD.InnerPacks = 0 then 'EA' else 'CS' end),
      UnitsPerPackage = case when InnerPacks > 0 then Quantity/InnerPacks
                             else coalesce(UnitsPerPackage, 0)
                        end
  from #CreateLPNDetails CLD join SKUs S on CLD.SKUId = S.SKUId;

  if (charindex('D', @vDebugOptions) > 0) select 'Create LPNs: Details' as Msg, * from #CreateLPNDetails

  /*--------------- Get Kit Components info --------------*/
  /* If user is trying to create kits then get the Kits Component info */
  if (@Action = 'Orders_CreateKits')
    insert into #KitComponentsInfo (WaveId, WaveNo, OrderId, PickTicket, OrderDetailId, HostOrderLine, ParentHostLineNo, SKUId, KitSKUId,
                                    UnitsOrdered, UnitsToShip, UnitsAssigned, UnitsPerCarton, KitsOrdered, KitsAllocated)
      select OH.PickBatchId, OH.PickBatchNo, OD.OrderId, OH.PickTicket, OD.OrderDetailId, OD.HostOrderLine, nullif(OD.ParentHostLineNo, ''), OD.SKUId, KOD.SKUId,
             OD.UnitsOrdered, OD.UnitsAuthorizedToShip, OD.UnitsAssigned, OD.OrigUnitsAuthorizedToShip / KOD.UnitsOrdered /* UnitsPerCarton */,
             KOD.UnitsOrdered, OD.UnitsAssigned / (OD.OrigUnitsAuthorizedToShip / KOD.UnitsOrdered)/* KitsAllocated */
      from OrderHeaders OH
        join OrderDetails KOD on (KOD.OrderId = OH.OrderId)
        join OrderDetails OD  on (OD.OrderId = OH.OrderId) and
                                 (OD.ParentHostLineNo = KOD.HostOrderLine)
      where (OH.OrderId = @OrderId) and
            (KOD.OrderDetailId = @OrderDetailId) and
            (KOD.LineType = 'A' /* KitAssembly */) and
            (OD.UnitsAuthorizedToShip > 0);

  if (charindex('D', @vDebugOptions) > 0) select 'Create LPNs: Kit Components' as Msg, * from #KitComponentsInfo

 /*------------- Validate -------------*/

  /* Validate the LPN Info and LPN Details - raises an exception if there are errors */
  /* Skip validations if the caller has passed in #CreateLPNDetails with LPNs created/generated earlier */
  if (not exists (select * from #CreateLPNDetails where LPNId is not null))
    exec pr_LPNs_CreateLPNs_Validate @vxmlInput;

  if (@ReceiptId is not null)
    select @vReceiptType   = ReceiptType,
           @vReceiptId     = ReceiptId,
           @vReceiptNumber = ReceiptNumber
    from ReceiptHeaders
    where (ReceiptId = @ReceiptId);

  if (@ReceiverId is not null)
    select @vReceiverId     = ReceiverId,
           @vReceiverNumber = ReceiverNumber
    from Receivers
    where (ReceiverId = @ReceiverId);

  if (@OrderId is not null)
    select @vOrderId    = OrderId,
           @vPickTicket = PickTicket,
           @vSalesOrder = SalesOrder
    from OrderHeaders
    where (OrderId = @OrderId);

  /*------------- Create the LPNs -------------*/

  /* If LPNs and LPN Details are given then just insert them into hash table to proceed further */
  if (exists (select * from #CreateLPNs)) and
     (exists (select * from #CreateLPNDetails where LPNId is null))
    begin
      /* Get all the LPN Details to be inserted/created */
      insert into #LPNDetails(LPNId, OnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
                              ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Weight, Volume, Lot, CoO,
                              BusinessUnit, CreatedBy)
        select L.EntityId, @vOnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
               ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Weight, Volume, Lot, CoO,
               @BusinessUnit, @UserId
        from #CreateLPNs L, #CreateLPNDetails LD;
    end
  else
  /* If LPNs are not given but LPN Details are given and those have LPNDetailId then insert them into hash table
     to proceed further */
  if (not exists (select * from #CreateLPNs)) and
     (exists(select * from #CreateLPNDetails where LPNId is not null))
    begin
      /* Get all the LPN Details to be inserted/created */
      insert into #LPNDetails(LPNId, OnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
                              ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Weight, Volume, Lot, CoO,
                              Reference, BusinessUnit, CreatedBy)
        select LPNId, OnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
               ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Weight, Volume, Lot, CoO,
               Reference, BusinessUnit, CreatedBy
        from #CreateLPNDetails LD;

      /* Get the LPNs to recount further */
      insert into #CreateLPNs (EntityId, EntityKey) select distinct LPNId, LPN from #CreateLPNDetails;
    end
  else
  /* If LPNs are not given and LPN Details doesn't have LPNId then generate LPNs and insert them into hash table
     to proceed further */
  if not exists (select * from #CreateLPNs)
    begin
      /* Generate LPNs */
      exec pr_LPNs_Generate @LPNType, @NumLPNsToCreate, null /* LPNFormat */, @Warehouse, @BusinessUnit, @UserId,
                            @vFirstLPNId output, @vFirstLPN output, @vLastLPNId output, @vLastLPN output,
                            @vNumLPNsCreated out;

      /* If not all LPNs can be created, then error out */
      if (@vNumLPNsCreated < @NumLPNsToCreate)
        begin
          select @vMessageName = 'CreateLPNs_NotEnoughLPNs', @vNote1 = @vNumLPNsCreated;
          goto ErrorHandler;
        end

      /* Get all the LPNs created */
      insert into #CreateLPNs(EntityId, EntityKey)
        select LPNId, LPN
        from LPNs
        where (LPN between @vFirstLPN and @vLastLPN) and
              (LPNType      = @LPNType) and
              (BusinessUnit = @BusinessUnit) and
              (CreatedBy    = @UserId);

      /* Get all the LPN Details to be inserted/created */
      insert into #LPNDetails(LPNId, OnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
                              ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Weight, Volume, Lot, CoO,
                              BusinessUnit, CreatedBy)
        select L.EntityId, @vOnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
               ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Weight, Volume, Lot, CoO,
               @BusinessUnit, @UserId
        from #CreateLPNs L, #CreateLPNDetails LD;
    end

  /*------------- Update with additional info  on LPNs -------------*/
  update L
  set Ownership       = coalesce(@Ownership,        Ownership),
      DestWarehouse   = coalesce(@Warehouse,        DestWarehouse),
      Lot             = coalesce(@Lot,              Lot),
      CreatedDate     = coalesce(@CreatedDate,      CreatedDate),
      ExpiryDate      = coalesce(@ExpiryDate,       ExpiryDate),
      ReasonCode      = coalesce(@ReasonCode,       ReasonCode),
      Reference       = coalesce(@Reference,        Reference),
      ReceiptId       = coalesce(@vReceiptId,       ReceiptId),
      ReceiptNumber   = coalesce(@vReceiptNumber,   ReceiptNumber),
      ReceiverId      = coalesce(@vReceiverId,      ReceiverId),
      ReceiverNumber  = coalesce(@vReceiverNumber,  ReceiverNumber),
      OrderId         = coalesce(@vOrderId,         OrderId),
      PickTicketNo    = coalesce(@vPickTicket,      PickTicketNo),
      SalesOrder      = coalesce(@vSalesOrder,      SalesOrder),
      InventoryClass1 = coalesce(@InventoryClass1,  InventoryClass1),
      InventoryClass2 = coalesce(@InventoryClass2,  InventoryClass2),
      InventoryClass3 = coalesce(@InventoryClass3,  InventoryClass3),
      Status          = case when @vReceiptId is not null and @vReceiptType = 'R' /* Returns */ then 'R' /* Received */
                             when @vReceiptId is not null then 'T' /* InTransit */
                             when @vOrderId is not null then 'F' /* New-Temp */
                             else Status
                        end
  from LPNs L
    join #CreateLPNs ttL on (L.LPNId = ttL.EntityId);

  /* Evaluate Rules and update the required info to specific fields */
  select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('LPNType',    @LPNType   ) +
                            dbo.fn_XMLNode('Ownership',  @Ownership ) +
                            dbo.fn_XMLNode('Warehouse',  @Warehouse ) +
                            dbo.fn_XMLNode('ReasonCode', @ReasonCode) +
                            dbo.fn_XMLNode('Reference',  @Reference ));

  exec pr_RuleSets_ExecuteAllRules 'CreateLPNs_OnCreateOfLPNs', @vxmlRulesData, @BusinessUnit;

  /*------------- Generate Pallets -------------*/
  if ((@GeneratePallet = 'Y' /* Yes */) or (@NumLPNsPerPallet > 0))
    begin
      select @NumLPNsPerPallet    = coalesce(nullif(@NumLPNsPerPallet, 0), @NumLPNsToCreate), -- if NumLPNsPerPallet is not defined then add all LPNs to single pallet
             @vNumPalletsToCreate = ceiling(@NumLPNsToCreate * 1.0 / @NumLPNsPerPallet);

      /* Create as Inventory pallet, will be changed to Receiving/Picking pallet based upon LPN info in Recount
         Ownership of Pallet updated as well in Recount */
      exec pr_Pallets_GeneratePalletLPNs 'I', @vNumPalletsToCreate, null /* PalletFormat */,
                                         0 /* LPNsPerPallet */, null /* LPN Type */, null /* LPN Format */,
                                         @Warehouse, @BusinessUnit, @UserId,
                                         @FirstPalletId = @vFirstPalletId output, @FirstPallet = @vFirstPallet output,
                                         @LastPalletId = @vLastPalletId output, @LastPallet = @vLastPallet output;

      /* Capture pallets generated to palletize LPNs */
      insert into #Pallets (EntityId, EntityKey)
        select PalletId, Pallet
        from Pallets
        where (Pallet between @vFirstPallet and @vLastPallet) and
              (PalletType   = 'I' /* Inventory */) and
              (BusinessUnit = @BusinessUnit) and
              (CreatedBy    = @UserId);
    end
  else
  /* User has scanned pallet than palletize LPNs */
  if (@GeneratePallet = 'N'/* No */) and (@Pallet is not null)
    begin
      /* get Pallet info */
      select @vPalletId        = PalletId,
             @vPallet          = Pallet,
             @NumLPNsPerPallet = @NumLPNsToCreate -- by default, when a pallet is scanned then add all LPNs to scanned pallet
      from Pallets
      where (Pallet = @Pallet) and
            (BusinessUnit = @BusinessUnit);

      /* Insert pallet to recount later */
      insert into #Pallets (EntityId, EntityKey) select @vPalletId, @vPallet;
    end

  /* Palletize LPNs */
  if exists (select * from #Pallets)
    update LPNs
    set PalletId = P.EntityId,
        Pallet   = P.EntityKey
    from LPNs L join #CreateLPNs TL on L.LPNId = TL.EntityId
      join #Pallets P on ceiling(TL.RecordId * 1.0/ @NumLPNsPerPallet) = P.RecordId;

  /*------------- Add LPN Details -------------*/
  /* If there is no inventory to consume then just add LPN Details with unavailable status */
  if not exists (select * from #InventoryToConsume)
    begin
      insert into LPNDetails(LPNId, OnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
                             ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Weight, Volume, Lot, CoO,
                             Reference, BusinessUnit, CreatedBy)
        output Inserted.LPNId, Inserted.LPNDetailId, Inserted.ReceiptId, Inserted.ReceiptDetailId, Inserted.Reference
        into #ReceiveLPNDetails (LPNId, LPNDetailId, ReceiptId, ReceiptDetailId, Reference)
        select LPNId, OnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
               ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Weight, Volume, Lot, CoO,
               Reference, BusinessUnit, CreatedBy
        from #LPNDetails;

      /* Update hash table with LPNDetailId created above which can be used later */
      if (exists (select * from #CreateLPNDetails where LPNId is not null))
        update CLD
        set LPNDetailId = RLD.LPNDetailId
        from #CreateLPNDetails CLD
          join #ReceiveLPNDetails RLD on (CLD.Reference = RLD.Reference);
    end
  else
  if (@Action = 'Orders_CreateKits')
    exec pr_LPNs_CreateLPNs_CreateKits @vxmlInput;
  else
    /* If there is inventory to consume invoke proc that transfers inventory from source LPNs to newly created LPNs */
    exec pr_LPNs_CreateLPNs_TransferInventory @vxmlInput;

  /*------------- Recount LPNs -------------*/
  if exists (select * from #CreateLPNs) and (@vRecountLPNs = 'Y' /* Yes */)
    begin
      /* Get all the LPNs to Recount */
      insert into @ttLPNsToRecount(EntityId) select EntityId from #CreateLPNs;
      exec pr_LPNs_Recalculate @ttLPNsToRecount, 'C' /* Update Counts */, @UserId;
    end

  /*------------- Recalc Pallets -------------*/
  if exists (select * from #Pallets)
    begin
      /* Update Reference on Pallets */
      if (coalesce(@Reference, '') <> '')
        update P
        set Reference = @Reference
        from Pallets P join #Pallets P1 on P.PalletId = P1.EntityId;

      /* Get all the Pallets to Recount */
      insert into @ttPallets (EntityId, EntityKey) select EntityId, EntityKey from #Pallets;
      exec pr_Pallets_Recalculate @ttPallets, default, @BusinessUnit, @UserId;
    end

  /*------------- Update Received Counts and Receipts -------------*/
  if (@Operation = 'Receiving')
    begin
      exec pr_ReceivedCounts_InsertCreatedLPNs @ReceiverId, @ReceiptId, @Operation, @BusinessUnit, @UserId; -- insert from ReceiveLPNDetails
      exec pr_ReceiptHeaders_Recount @ReceiptId;
    end

  if (charindex('D', @vDebugOptions) > 0)
    begin
      select * from LPNs where LPNId between @vFirstLPNId and @vLastLPNId;
      select * from LPNDetails where LPNId between @vFirstLPNId and @vLastLPNId;
    end

  if (@vNumLPNsCreated = 1)
    exec @vMessage = dbo.fn_Messages_Build 'LPN_CreateInvLPNs_Successful1', Default, @vFirstLPN;
  else
  if (@vNumLPNsCreated > 1)
    exec @vMessage = dbo.fn_Messages_Build 'LPN_CreateInvLPNs_Successful2', @vNumLPNsCreated, @vFirstLPN, @vLastLPN;
  else
    exec @vMessage = dbo.fn_Messages_Build 'LPN_CreateInvLPNs_NoneCreated';

  /* Determine the Activity Type and Audit info */
  select @vActivityType = case when exists (select * from #CreateLPNDetails where LPNId is not null) then null  -- If LPNs are passed then AT may have created before or it may not be required
                               when exists (select * from #InventoryToConsume) and (@Action <> 'Orders_CreateKits') then null  -- If LPNs are created by consuming inventory then AT may have created before or it may not be required
                               when @vReceiptId is not null then 'CreateLPNs_ReceiptLPNs'
                               when @vOrderId is not null then 'CreateLPNs_OrderLPNs'
                               when @vNumLPNsCreated > 1 then 'CreateLPNs_InvLPNs'
                               when @vNumLPNsCreated = 1 then 'CreateLPNs_InvLPN'
                               else null
                          end,
         @vNote1        = case when @vNumLPNsCreated = 1 then @vFirstLPN
                               else @vFirstLPN + ' to ' + @vLastLPN
                          end,
         @vNote2        = case when @vNumLPNDetails > 1 then 'Multiple SKUs'
                               else 'SKU ' + (select SKU from #CreateLPNDetails)
                          end,
         @vQuantity     = (select sum(Quantity) from #CreateLPNDetails);

  /* Audit Trail */
  if (@vActivityType is not null)
    begin
      exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                                @ReceiptId     = @vReceiptId,
                                @ReceiverId    = @vReceiverId,
                                @OrderId       = @vOrderId,
                                @SKUId         = @SKUId,
                                @Quantity      = @vQuantity,
                                @Note1         = @vNote1,
                                @Note2         = @vNote2,
                                @ReasonCode    = @ReasonCode,
                                @BusinessUnit  = @BusinessUnit,
                                @AuditRecordId = @vAuditRecordId output;

      /* Get the LPNs into a temp table to process the Audit entrities */
      insert into @ttLPNs(EntityId, EntityKey) select EntityId, EntityKey from #CreateLPNs;

      /* Get the LPN's Location info to link AT */
      insert into @ttLocations (EntityId, EntityKey)
        select distinct LOC.LocationId, LOC.Location
        from #CreateLPNs ttL
          join LPNs L on (L.LPNId = ttL.EntityId)
          join Locations Loc on (Loc.LocationId = L.LocationId)

      /* Link AT record with required entities */
      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttLPNs, @BusinessUnit;
      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Location', @ttLocations, @BusinessUnit;
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @OutputXML = (select @vFirstLPNId         FirstLPNId,
                              @vLastLPNId          LastLPNId,
                              @vFirstLPN           FirstLPN,
                              @vLastLPN            LastLPN,
                              @vFirstPalletId      FirstPalletId,
                              @vLastPalletId       LastPalletId,
                              @BusinessUnit        BusinessUnit,
                              @UserId              UserId,
                              @vMessage            Message
                       FOR XML PATH('Results'));

  /* If LPNs created then return the data to print the labels */
  if (@vNumLPNsCreated > 0)
    insert into #ResultData (FieldName, FieldValue)
            select 'FirstLPNId', cast(@vFirstLPNId as varchar)
      union select 'FirstLPN', @vFirstLPN
      union select 'LastLPNId', cast(@vLastLPNId as varchar)
      union select 'LastLPN', @vLastLPN;

  /* Inserted the messages information to display in V3 application */
  if (object_id('tempdb..#ResultMessages') is not null)
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @vMessage;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_CreateLPNs */

Go
