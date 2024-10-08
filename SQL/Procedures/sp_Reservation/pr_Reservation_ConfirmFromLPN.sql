/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/18  TK      pr_Reservation_ConfirmFromLPN: Create LPN as carton type when picking from picklanes (HA-2909)
  2021/05/25  RKC     pr_Reservation_ConfirmFromLPN: Made changes to recounts pallets & Locations after LPNs split (HA-2797)
  2021/05/17  RKC     pr_Reservation_ConfirmFromLPN: For Logical LPNs, need to create a new LPN and mark it as picked (HA-2771)
  2021/04/02  SK      pr_Reservation_ActivateLPNs, pr_Reservation_ConfirmFromLPN: Included markers (HA-2070)
  2021/01/06  RKC     pr_Reservation_ConfirmFromLPN: Made changes to update the Picking Class on LPN as OL on partial reservation (HA-1811)
  2020/12/22  TK      pr_Reservation_ConfirmFromLPN & pr_Reservation_ValidateLPN:
                      pr_Reservation_ConfirmFromLPN, pr_Reservation_ValidateLPN: Introduce inventory key to tables (HA-1583)
  2020/10/08  AY      pr_Reservation_ConfirmFromLPN: Print label on confirmation (HA-1542)
  2020/10/09  TK      pr_Reservation_ConfirmFromLPN: Clear pallet info on picked LPN (HA-1547)
  2020/09/11  AJM     pr_Reservation_ConfirmFromLPN: Made changes to display values in message (HA-1098)
  2020/07/15  MS      pr_Reservation_ConfirmFromLPN: Changes to UnAllocate LPN (HA-1100)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_ConfirmFromLPN') is not null
  drop Procedure pr_Reservation_ConfirmFromLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_ConfirmFromLPN:

  This procedure is used to Allocate/Reallocate/Unallocate LPN

  @Option  = 'A' - Allocate LPN to the given PT or identify PT with CustPO etc.
  @Option  = 'U' - Unallocate LPN from Order
  @Option  = 'R' - Reallocate LPN from another PT to the given PT (or identify PT with CustPO etc.)

  Parameters:    LPN is required for all options, apart from that the following
                 combinations could be used to specify the PickTicket to allocate to
  UnAllocate:    LPN is sufficient to unallocate, none of other params are used
  Allocate  :    LPN is required and the following combinations are valid to uniquely identify PickTicket
                 - PickTicket
                 - PickBatchNo
                 - CustPO & Store
                 - PickBatchNo & Store
  Reallocate:    - Pick Ticket
                 - Store (CustPO or PickBatch of the LPN could be used)
                 - CustPO & Store
                 - PickBatch & Store

  @xmlInput Contains
    <ConfirmLPNReservations>
      <LPN></LPN>
      <PickTicket></PickTicket>
      <CustPO></CustPO>
      <Store></Store>
      <Option></Option>
      <PickBatchNo></PickBatchNo>
      <SelectedQuantity></SelectedQuantity>
      <SelectedUoM></SelectedUoM>
      <SelectedInnerPacks></SelectedInnerPacks>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
      <DeviceId></DeviceId>
    </ConfirmLPNReservations>
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_ConfirmFromLPN
  (@xmlInput     xml,
   @xmlResult    xml output)
as
  declare @vReturnCode              TInteger,
          @vActivationReturnCode    TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TDescription,
          @vInputXML                TXML, -- TXML version of xmlInput
          @vxmlInput                xml,  -- Input modified with addition of missing values
          @vSKUDetailsToAllocate    xml,
          @vStrSKUDetailsToAllocate TXML,
          @vStrOutputXML            TXML,
          @vxmlRulesData            TXML,

          @WaveNo                   TPickBatchNo,
          @PickTicket               TPickTicket,
          @LPN                      TLPN,
          @Pallet                   TPallet,
          @CustPO                   TCustPO,
          @ShipToStore              TShipToId,
          @Option                   TFlag,

          @vWarehouse               TWarehouse,
          @vLPN                     TLPN,
          @vLPNId                   TRecordId,
          @vLPNStatus               TStatus,
          @vLPNQuantity             TQuantity,
          @vLPNDQuantity            TQuantity,
          @vLPNDetailId             TRecordId,
          @vReservedLPNDetailId     TRecordId,
          @vLPNPalletId             TRecordId,
          @vLPNWarehouse            TWarehouse,
          @vLPNWaveNo               TPickBatchNo,
          @vLPNType                 TTypeCode,
          @vLPNInnerPacks           TInnerPacks,
          @vLPNNumLines             TCount,
          @vLPNOwner                TOwnership,
          @vSplitLPNId              TRecordId,
          @vSplitLPN                TLPN,
          @vLDRecordId              TRecordId,
          @vOldOrderId              TRecordId,
          @vOldWaveId               TRecordId,

          @vPalletId                TRecordId,
          @vPallet                  TPallet,

          @vOrderId                 TRecordId,
          @vPickTicket              TPickTicket,
          @vOrderDetailId           TRecordId,
          @vOrderType               TOrderType,
          @vOrderLPNId              TRecordId,
          @vInventoryClass1         TInventoryClass,
          @vInventoryClass2         TInventoryClass,
          @vInventoryClass3         TInventoryClass,
          @vUnitsAssigned           TQuantity,
          @vOrderOwner              TOwnership,
          @vSKUId                   TRecordId,
          @vSKU                     TSKU,
          @vUnitsPerInnerPack       TInteger,
          @vAuditActivity           TActivityType,
          @vConfirmLPNReservation   TMessage,
          @vValidLPNStatuses        TControlValue,
          @vWaveNo                  TPickBatchNo,
          @vWaveId                  TRecordId,
          @vWaveType                TTypeCode,
          @vWaveOwner               TOwnership,
          @vCustPO                  TCustPO,
          @vUnitsPerCarton          TInteger,
          @vValidateUnitsPerCarton  TFlags,
          @vRequireUniquePickTicket TFlags,
          @vReassignToSamePOOnly    TFlags,
          @vReassignToSameWaveOnly  TFlags,
          @vConfirmLPNAsPickedOnAllocate
                                    TFlag,

          @vEntityToReserve         TEntity,
          @vSelectedQuantity        TQuantity,
          @vSelectedInnerPacks      TInnerPacks,
          @vSelectedUoM             TUoM,
          @vQtyToReserve            TQuantity,
          @vBatchNumUnits           TQuantity,
          @vPartialReservation      TFlags,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId,
          @vDeviceId                TDeviceId,
          @DeviceId                 TDeviceId,
          @vValidWarehouses         TControlValue ,
          @vActivatePreGeneratedCartons
                                    TFlag,
          @vPrintLabel              TFlag,
          @vRulesDataXML            TXML,

          @vNote1                   TDescription,
          @vNote2                   TDescription,
          @vNote3                   TDescription,
          @vNote4                   TDescription,
          @vNote5                   TDescription,
          @vDebug                   TFlags,
          @vActivityLogId           TRecordId;

  declare @ttOrderDetails   TOrderDetails,
          @ttLPNDetails     TLPNDetails,
          @ttValidations    TValidations,
          @ttWavesList      TEntityKeysTable,
          @ttMarkers        TMarkers;

  declare @ttNotes  table (Note1    TDescription,
                           Note2    TDescription,
                           Note3    TDescription,
                           Note4    TDescription,
                           Note5    TDescription);

  declare @ttSKUQuantities table (RecordId             TRecordId Identity(1,1),
                                  SKUId                TRecordId,
                                  SKU                  TSKU,
                                  InventoryClass1      TInventoryClass,
                                  InventoryClass2      TInventoryClass,
                                  InventoryClass3      TInventoryClass,

                                  IPsToReserve         TInnerPacks,
                                  QtyToReserve         TInteger,
                                  QtyOrdered           TInteger,
                                  QtyReserved          TInteger);
begin
begin try
  SET NOCOUNT ON;

  select @vMessageName = null,
         @vReturnCode  = 0,
         @vInputXML    = convert(varchar(max), @xmlInput);

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @vBusinessUnit, @vDebug output;

  /* Temporary tables to store LPN details & Order details with additional information  */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  select * into #LPNDetails from @ttLPNDetails;
  alter table   #LPNDetails drop column AllocableQty;
  alter table   #LPNDetails add AllocableQty as (Quantity - ReservedQty);
  alter table   #LPNDetails add InventoryKey as cast(SKUId as varchar) + '-' +
                                                coalesce(Warehouse, '') + '-' +
                                                coalesce(Ownership, '') + '-' +
                                                coalesce(BusinessUnit, '') + '-' +
                                                rtrim(coalesce(InventoryClass1, '')) + '-' +
                                                rtrim(coalesce(InventoryClass2, '')) + '-' +
                                                rtrim(coalesce(InventoryClass3, ''));

  select * into #OrderDetails from @ttOrderDetails;
  alter table   #OrderDetails add BusinessUnit varchar(10);
  alter table   #OrderDetails add InventoryKey as cast(SKUId as varchar) + '-' +
                                                  coalesce(Warehouse, '') + '-' +
                                                  coalesce(Ownership, '') + '-' +
                                                  coalesce(BusinessUnit, '') + '-' +
                                                  rtrim(coalesce(InventoryClass1, '')) + '-' +
                                                  rtrim(coalesce(InventoryClass2, '')) + '-' +
                                                  rtrim(coalesce(InventoryClass3, ''));

  select * into #Validations  from @ttValidations;
  select * into #Notes        from @ttNotes;

  /* Fetch the Input Params from the XML parameter */
  select @WaveNo              = Record.Col.value('PickBatchNo[1]',        'TPickBatchNo'),
         @vWaveId             = Record.Col.value('WaveId[1]',             'TRecordId'),
         @PickTicket          = Record.Col.value('PickTicket[1]',         'TPickTicket'),
         @vOrderId            = Record.Col.value('OrderId[1]',            'TRecordId'),
         @CustPO              = Record.Col.value('CustPO[1]',             'TCustPO'),
         @ShipToStore         = Record.Col.value('Store[1]',              'TShipToId'),
         @Option              = Record.Col.value('Option[1]',             'TFlag'),
         @Pallet              = Record.Col.value('Pallet[1]',             'TPallet'),
         @LPN                 = Record.Col.value('LPN[1]',                'TLPN'),
         @vSelectedInnerPacks = Record.Col.value('SelectedInnerPacks[1]', 'TQuantity'),
         @vSelectedQuantity   = Record.Col.value('SelectedQuantity[1]',   'TQuantity'),
         @vSelectedUoM        = Record.Col.value('SelectedUOM[1]',        'TUoM'),
         @vEntityToReserve    = Record.Col.value('EntityToReserve[1]',    'TEntity'),
         @vBusinessUnit       = Record.Col.value('BusinessUnit[1]',       'TBusinessUnit'),
         @vUserId             = Record.Col.value('UserId[1]',             'TUserId'),
         @DeviceId            = Record.Col.value('DeviceId[1]',           'TDeviceId')
  from @xmlInput.nodes('ConfirmLPNReservations') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @LPN, 'LPN',
                      @Value1 = @WaveNo, @Value2 = @PickTicket, @Value3 = @CustPO, @Value4 = @ShipToStore,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Update to null if the Input Params are empty */
  select @WaveNo              = nullif(@WaveNo, ''),
         @PickTicket          = nullif(@PickTicket,  ''),
         @vSelectedInnerPacks = nullif(@vSelectedInnerPacks, ''),
         @vSelectedQuantity   = nullif(@vSelectedQuantity, ''),
         @vDeviceId           = @DeviceId + '@' + @vUserId;

  /* Identify the Entity to be reserved */
  --exec pr_Reservation_IdentifyWaveOrPickTicket @xmlInput, @vEntityToReserve out,
  --                                             @vWaveId out, @vWaveNo out,
  --                                             @vOrderId out, @vPickTicket out;


  /* Get order info */
  if (@vOrderId is not null)
    select @vWaveId     = coalesce(@vWaveId, OH.PickBatchId),
           @vWaveNo     = coalesce(@vWaveNo, OH.PickBatchNo),
           @vPickTicket = OH.PickTicket,
           @vOrderId    = OH.OrderId,
           @vOrderType  = OH.OrderType,
           @vOrderOwner = OH.Ownership
    from OrderHeaders OH
    where (OH.OrderId = @vOrderId);

  /* Get Wave Info */
  if (@vWaveId is not null)
    select @vWaveId    = W.WaveId,
           @vWaveNo    = W.WaveNo,
           @vWaveType  = W.WaveType,
           @vWaveOwner = W.Ownership,
           @vWarehouse = W.Warehouse
    from Waves W
    where (W.WaveId = @vWaveId);

  /* Get scanned Pallet info */
  if (@Pallet is not null)
    select @vPalletId = PalletId,
           @vPallet   = Pallet
    from Pallets
    where (Pallet = @Pallet) and (BusinessUnit = @vBusinessUnit);

  /* Fetching of LPN Info */
  select @vLPNId         = L.LPNId,
         @vLPN           = L.LPN,
         @vLPNType       = L.LPNType,
         @vLPNStatus     = L.Status,
         @vSKUId         = L.SKUId,
         @vLPNPalletId   = L.PalletId,
         @vOldOrderId    = L.OrderId,
         @vOldWaveId     = L.PickBatchId,
         @vLPNNumLines   = L.NumLines,
         @vLPNInnerPacks = L.InnerPacks,
         @vLPNQuantity   = L.Quantity,
         @vLPNWarehouse  = L.DestWarehouse,
         @vLPNWaveNo     = L.PickBatchNo,
         @vLPNOwner      = L.Ownership
  from LPNs L
  where (L.LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @vBusinessUnit, 'IL' /* Options */));

  /* Fetching LPN Details */
  /* There are instances when user will try to allocate an LPN that is partially reserved, so in this scenario LPN will have
     both available and reserved lines so when reserving the LPN try to process the available lines only */
  if (@Option = 'A' /* Allocate */)
    insert into #LPNDetails (LPNId, LPNDetailId, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                             ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO,
                             Warehouse, Ownership, BusinessUnit, InventoryClass1, InventoryClass2, InventoryClass3)
      select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
             LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId, LD.Lot, LD.CoO,
             L.DestWarehouse, L.Ownership, L.BusinessUnit, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
      from LPNDetails LD
        join LPNs L on (LD.LPNId = L.LPNId) and (LD.OrderId is null)
      where LD.LPNId = @vLPNId;
  else
    insert into #LPNDetails (LPNId, LPNDetailId, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                             ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO,
                             Warehouse, Ownership, BusinessUnit, InventoryClass1, InventoryClass2, InventoryClass3)
      select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
             LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId, LD.Lot, LD.CoO,
             L.DestWarehouse, L.Ownership, L.BusinessUnit, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
      from LPNDetails LD
        join LPNs L on (LD.LPNId = L.LPNId)
      where LD.LPNId = @vLPNId;

  /* Get the SKU for logging */
  select @vSKU = SKU
  from SKUs
  where (SKUId = @vSKUId);

  /* User can input:
      Quantity in Cases i.e., InnerPacks value OR
      Quantity in Eaches i.e., Quantity value */
  if (@vLPNNumLines = 1) and (@vSelectedQuantity is null) and (coalesce(@vSelectedInnerPacks, 0) <> 0)
    begin
      select @vSelectedQuantity = (@vSelectedInnerPacks * UnitsPerPackage)
      from LPNDetails
      where (LPNId = @vLPNId);

      select @vSelectedQuantity = case
                                    when @vSelectedQuantity = 0 then @vLPNQuantity
                                    else @vSelectedQuantity
                                  end;
    end
  else
    select @vSelectedQuantity = coalesce(nullif(@vSelectedQuantity, 0), @vLPNQuantity);

  /* Applicable only for Single SKU LPN */
  select @vPartialReservation = case
                                  when (@vLPNNumLines = 1) and (@vSelectedQuantity < @vLPNQuantity) then 'Y'
                                  when (@vLPNNumLines = 1) and (@vSelectedInnerPacks < @vLPNInnerPacks) then 'Y'
                                  /* Consider all Reservation from Logical LPN as Partial as we need to create a new LPN and have it marked as picked */
                                  when @vLPNType = 'L' /* Logical LPN */ then 'Y'
                                  /* When an LPN is partially allocated it will have both available & reserved lines so NumLines will be greater than zero,
                                     even if NumLines is greater that '1' but SKUId is not null then it is a single SKU LPN so allow partial reservation */
                                  when (@vLPNNumLines > 1) and (@vSKUId is not null) then 'Y'
                                  else 'N'
                                end;

  /* Restrict the LPN quantity if partial reservation is allowed */
  if (@vPartialReservation = 'Y' /* yes */)
    update #LPNDetails set Quantity = @vSelectedQuantity where (LPNId = @vLPNId);

  /* Get all the order details to be reserved for the given wave or pick ticket
     executing following procedure will insert required order details into #OrderDetails table */
  exec pr_Reservation_GetOrderDetailsToReserve @vEntityToReserve, @vWaveId, @vOrderId;

  /* Fetch controls */
  select @vConfirmLPNAsPickedOnAllocate = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'ConfirmLPNAsPickedOnAllocate', 'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vValidWarehouses = dbo.fn_Controls_GetAsString('LPNReservation',  'ValidWarehouses', ',,' /* O1 */, @vBusinessUnit, null /* UserId */),
         @vPrintLabel      = dbo.fn_Controls_GetAsString('BatchPicking_' + @vWaveType, 'PrintLabel', 'N', @vBusinessUnit, @vUserId);

  select @vActivatePreGeneratedCartons = case when dbo.fn_IsInList(@vWarehouse, @vValidWarehouses) > 0 then 'Y' else 'N' end;

  /* Replace the values if modified */
  select @vInputXML = dbo.fn_XMLStuffValue(@vInputXML, 'SelectedInnerPacks', @vSelectedInnerPacks);
  select @vInputXML = dbo.fn_XMLStuffValue(@vInputXML, 'SelectedQuantity',   @vSelectedQuantity);

  /* Including Operation node & Warehouse into XML input */
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'OrderType',          @vOrderType);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'OrderId',            @vOrderId);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'OrderLPNId',         @vOrderLPNId);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'OldOrderId',         @vOldOrderId);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'LPNId',              @vLPNId);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'LPNType',            @vLPNType);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'LPNWaveId',          @vOldWaveId);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'WaveId',             @vWaveId);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'WaveType',           @vWaveType);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'PartialReservation', @vPartialReservation);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'EntityToReserve',    @vEntityToReserve);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'Warehouse',          @vLPNWarehouse);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'Option',             @Option);

  /* Validations */
  select @vxmlInput = convert(xml, @vInputXML);

  exec pr_Reservation_ValidateLPN @vxmlInput;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_Reservation_ValidateLPN_End', @@ProcId;

  /* Log the final input xml */
  if (charindex('I', @vDebug) > 0) exec pr_RFLog_Begin @vxmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                                                       null /* EntityId */, null /* EntityKey */, null /* Entity */,
                                                       'FinalXMLBeforeValidation' /* Operation */;

  /* Ship Cartons Activation */
  if (@vActivatePreGeneratedCartons = 'Y' /* yes */) and (@vEntityToReserve = 'PickTicket' /* PickTicket */)
    begin
      exec @vActivationReturnCode = pr_Reservation_ActivateLPNs @vxmlInput;

      if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_Reservation_ValidateLPN_End', @@ProcId;
    end

  /* Get the Available Quantity, still not activated */
  select @vQtyToReserve = sum(AllocableQty) from #LPNDetails where (LPNId = @vLPNId);

  /* Log the flag and final quantity post activation */
  if (charindex('L', @vDebug) > 0)
    begin
      select @vMessage = 'Partial: ' + @vPartialReservation + '; QtyLeft: ' + convert(varchar(10), @vQtyToReserve);
      exec pr_ActivityLog_AddMessage 'PostActivation', null, null, null, @vMessage, @@ProcId, null, @vBusinessUnit, @vUserId;
    end

  /* Validations: Post Activation */
  select @vxmlRulesData = replace(@vInputXML, 'ConfirmLPNReservations', 'RootNode');

  /* Process following validations only if Activate Pre-Generated labels procedure returned zero */
  if (@vActivationReturnCode = 0)
    exec pr_RuleSets_Evaluate 'LPNReservation_ValidatePostActivation', @vxmlRulesData, @vMessageName output

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Split LPN for Partial Reservation */
  if (@Option in ('A', 'R' /* Allocate, Reallocate */)) and
     (@vPartialReservation = 'Y' /* yes */) and (@vQtyToReserve > 0)
    begin
      select top 1 @vLPNDetailId = LPNDetailId
      from #LPNDetails
      where (LPNId = @vLPNId) and
            (Quantity >= @vQtyToReserve) and
            (AllocableQty > 0);

      exec pr_LPNs_SplitLPN @FromLPN         = @vLPN,
                            @FromLPNDetailId = @vLPNDetailId,
                            @SplitQuantity   = @vQtyToReserve,
                            @Options         = 'LOC,P', /* Need to recounts Pallets & locations */
                            @BusinessUnit    = @vBusinessUnit,
                            @UserId          = @vUserId,
                            @ToLPNId         = @vSplitLPNId output,
                            @ToLPN           = @vSplitLPN output,
                            @ToLPNType       = 'C' /* Carton */;

      if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_LPNs_SplitLPN_End', @@ProcId;

      /* Delete the Original from LPN from the temp table */
      delete from #LPNDetails where (LPNId = @vLPNId);

      /* After partial allocation need to revise the Picking class on the From LPN */
      update LPNs
      set PickingClass = 'OL' /* Open LPN */
      where (LPNId = @vLPNId) and
            (PickingClass in ('PL', 'FL')) and
            (LPNType <> 'L' /* Logical Picklane */);

      /* Re-fetch all details after the split */
      select @vLPNId         = L.LPNId,
             @vLPNStatus     = L.Status,
             @vSKUId         = L.SKUId,
             @vLPNPalletId   = L.PalletId,
             @vOldOrderId    = L.OrderId,
             @vLPNQuantity   = L.Quantity,
             @vLPNInnerPacks = L.InnerPacks,
             @vLPNWarehouse  = L.DestWarehouse,
             @vLPNWaveNo     = L.PickBatchNo
      from LPNs L
      where (L.LPNId = @vSplitLPNId);

      /* Fetch the new split LPN Details */
      insert into #LPNDetails (LPNId, LPNDetailId, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                               ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO,
                               InventoryClass1, InventoryClass2, InventoryClass3)
        select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
               LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId, LD.Lot, LD.CoO,
               L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
        from LPNDetails LD
          join LPNs L on (LD.LPNId = L.LPNId)
        where (LD.LPNId = @vLPNId);
    end

  /* If a wave is given, assumption is that the entire quantity is reserved and so the LPN is
     directly attached to the wave and no other updates are required */
  if ((@Option in ('A', 'R' /* Allocate, Reallocate */)) and
      (@vEntityToReserve = 'Wave' /* Wave number given */))
    begin
      update LPNs
      set PickBatchId = @vWaveId,
          PickBatchNo = @vWaveNo
      where (LPNId = @vLPNId);

      /* Update LPN status to Picked */
      exec pr_LPNs_SetStatus @vLPNId, 'K'/* Picked */;

      select @vAuditActivity = 'LPNReservedForWave';
    end
  else
  /* Updating Order on LPN */
  if ((@Option = 'U' /* Unallocate */) and (@vOldOrderId is not null))
    begin
      exec @vReturnCode = pr_LPNs_Unallocate @LPNId         = @vLPNId,
                                             @LPNsToUpdate  = default,
                                             @UnallocPallet = 'P' /* PalletPick - Unallocate Pallet */,
                                             @BusinessUnit  = @vBusinessUnit,
                                             @UserId        = @vUserId;

      if (@vReturnCode > 0)
        goto ErrorHandler;

      /* VM: We are logging AT in Unallocate, so it might not need here
         Also, it is good to have AT in internal procedure only  - Handled below while logging */
      set @vAuditActivity = 'LPNUnallocated';
    end
  else
  if (@Option = 'U' /* Unallocate */) and (@vOldWaveId is not null)
    begin
      update LPNs
      set PickBatchId = null,
          PickBatchNo = null
      where (LPNId = @vLPNId);

      /* Update LPN status to Picked */
      exec pr_LPNs_SetStatus @vLPNId, 'P' /* Putaway */, 'A'/* OnHand - Available */;

      select @vAuditActivity = 'LPNUnReservedForWave';
    end

  /* Allocating LPN to new Wave/PT */
  /* This is regular process where if PickTicket is given, LPN is allocated based on order */
  if (@Option <> 'U' /* Unallocate */) and
     ((@vOrderId is not null) or (@Option in ('A', 'R' /* Allocate, Reallocate */))) and
     (@vEntityToReserve = 'PickTicket')
    begin
      select @vLDRecordId = 0;

      while (exists (select * from #LPNDetails where RecordId > @vLDRecordId and AllocableQty > 0))
        begin
          select top 1 @vLDRecordId    = RecordId,
                       @vLPNDetailId   = LPNDetailId,
                       @vSKUId         = SKUId,
                       @vLPNDQuantity  = Quantity,
                       @vInventoryClass1 = InventoryClass1,
                       @vInventoryClass2 = InventoryClass2,
                       @vInventoryClass3 = InventoryClass3
          from #LPNDetails
          where (RecordId > @vLDRecordId) and
                (AllocableQty > 0)
          order by RecordId;

          select @vOrderDetailId = OrderDetailId
          from #OrderDetails
          where (OrderId = @vOrderId) and
                (SKUId   = @vSKUId) and
                (InventoryClass1 = @vInventoryClass1) and
                (InventoryClass2 = @vInventoryClass2) and
                (InventoryClass3 = @vInventoryClass3);

          if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_Allocation_AllocateLPN_New_Begin', @@ProcId;

          exec @vReturnCode = pr_Allocation_AllocateLPN_New @vLPNId,
                                                            @vLPNDetailId,
                                                            @vOrderId,
                                                            @vOrderDetailId,
                                                            0 /* TaskDetailId */,
                                                            @vSKUId,
                                                            @vLPNDQuantity,
                                                            @vBusinessUnit,
                                                            @vUserId,
                                                            null /* Operation */,
                                                            @vReservedLPNDetailId out;

          if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_Allocation_AllocateLPN_New_End', @@ProcId;

          select @vSKUId = null, @vLPNDQuantity = null, @vLPNDetailId = null, @vReservedLPNDetailId = null;
        end

      /* This would mean, that there are multiple LPNDetails that are processed i.e., Multi SKU LPN */
      if (@vLDRecordId > 1)
        select @vOrderDetailId = null;

      if (@vReturnCode > 0)
        goto ErrorHandler;

      /* Set the audit activity */
      if (@vAuditActivity is null)
        set @vAuditActivity = 'LPNAllocatedToOrder';
      else
        set @vAuditActivity = 'LPNReAllocatedToOrder';
    end
  else
    set @vOrderId = @vOldOrderId;

  /* Calculate status of the Order */
  exec pr_OrderHeaders_SetStatus @vOrderId;

  /* Set Success Messages based on the option */
  select @vConfirmLPNReservation = case when (@Option = 'A'/* Allocated/Assigned */)       then 'LPNResv_AllocatedSuccessfully'
                                        when (@Option = 'U'/* Unallocated/Unassigned */)   then 'LPNResv_UnallocatedSuccessfully'
                                        when (@Option = 'R'/* Re-allocated/Re-assigned */) then 'LPNResv_ReallocatedSuccessfully'
                                   end;

  /* Insert Audit Trail */
  if (@vAuditActivity <> 'LPNUnallocated') --VM: Restricting as we are already logging AT in Unallocate procedure
    exec pr_AuditTrail_Insert  @vAuditActivity,
                               @vUserId,
                               null           /* ActivityTimestamp */,
                               @LPNId         = @vLPNId,
                               @SKUId         = @vSKUId,
                               @OrderId       = @vOrderId,
                               @OrderDetailId = @vOrderDetailId,
                               @PrevOrderId   = @vOldOrderId,
                               @Quantity      = @vSelectedQuantity;

  if (@Option in ('A', 'R' /* Allocate, Reallocate */)) and
     (@vConfirmLPNAsPickedOnAllocate = 'Y' /* Yes */) and
     (@vEntityToReserve = 'PickTicket' /* PickTicket given */) and
     (@vQtyToReserve > 0)
    begin
      /* Call ConfirmLPNPick */
      exec pr_Picking_ConfirmLPNPick @vOrderId, @vOrderDetailId, @vLPNId,
                                     @vBusinessUnit, @vUserId, null /* @PickingPalletId */;
    end

  /* Built and send required info to validate in Rules */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Module',           'Picking') +
                            dbo.fn_XMLNode('Operation',        'LPNReservation') +
                            dbo.fn_XMLNode('Entity',           'LPN') +
                            dbo.fn_XMLNode('EntityId',         @vLPNId) +
                            dbo.fn_XMLNode('EntityKey',        @vLPN) +
                            dbo.fn_XMLNode('WaveType',         @vWaveType) +
                            dbo.fn_XMLNode('BusinessUnit',     @vBusinessUnit) +
                            dbo.fn_XMLNode('UserId',           @vUserId));

  /* Print Generated Temp LPN */
  if ((coalesce(@vLPNId, 0) <> 0) and (@vPrintLabel = 'Y'))
    exec pr_Printing_EntityPrintRequest 'Picking', 'LPNReservation', 'LPN', @vLPNId, @vLPN, @vBusinessUnit, @vUserId,
                                        @vDeviceId, 'IMMEDIATE', default /* PrinterName */, null, null, @vRulesDataXml;

  /* When allocating or reallocating, if user scans pallet then palletize the LPN or clear location info */
  if (@Option in ('A', 'R' /* Allocate, Reallocate */))
    begin
      /* Call set pallet which will add LPN onto pallet and clear location & previous pallet info on it */
      if (@vPalletId is not null)
        exec pr_LPNs_SetPallet @vLPNId, @vPalletId, @vUserId;
      else
        begin
          /* Clear location info if user didn't scan a pallet */
          exec pr_LPNs_SetLocation @vLPNId, null /* LocationId */, null /* Location */;

          /* Clear pallet info on the LPN if it was on a Pallet */
          if (@vLPNPalletId is not null)
            exec pr_LPNs_SetPallet @vLPNId, null /* clear pallet */, @vUserId;
        end
    end

  /* Update counts/status on Pallet if LPN was on a pallet */
  if (@vLPNPalletId is not null)
    exec pr_Pallets_UpdateCount @vLPNPalletId, default, '*' /* Recalc */, @UserId = @vUserId;

  /* Recount & Status update for Waves */
  insert into @ttWavesList (EntityId, EntityKey) select distinct WaveId, WaveNo from #OrderDetails;
  exec pr_PickBatch_Recalculate @ttWavesList, '$CS' /* defer status */, @vUserId, @vBusinessUnit;

  -- This is done in AMF_Info

  /* After the LPN is successfully allocated, compute SKU quantities again
     executing following procedure will insert required order details into #OrderDetails & #DataTableSKUDetails table */
  --exec pr_Reservation_GetOrderDetailsToReserve @vEntityToReserve, @vWaveId, @vOrderId;

  /* Converting the result as xml to retun */
  select @xmlResult = convert(xml, @vStrOutputXML);

  /* Call the pr_BuildRFSuccessXML to build the success message to display it in RF */
  exec pr_BuildRFSuccessXML @vConfirmLPNReservation, @xmlResult output, @vLPN, @vSelectedQuantity, @vSKU, @vPickTicket;

ErrorHandler:
  /* Get Note: 1-5 values if available */
  select @vNote1 = Note1,
         @vNote2 = Note2,
         @vNote3 = Note3,
         @vNote4 = Note4,
         @vNote5 = Note5
  from #Notes
  where (Note1 is not null) or (Note2 is not null) or (Note3 is not null) or (Note4 is not null) or (Note5 is not null)

  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1, @vNote2, @vNote3, @vNote4, @vNote5;

  /* Log the result */
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'LPN', @vLPNId, null, 'Reservation', @@ProcId, 'Markers_Reservation_ConfirmFromLPN';
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
end/* pr_Reservation_ConfirmFromLPN */

Go
