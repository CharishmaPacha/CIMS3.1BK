/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/03  TK      pr_RFC_Picking_LPNReservations: Clear location info on LPNs on Picked (HA-786)
  2020/05/31  TK      pr_RFC_Picking_LPNReservations: Fix partial reservation issues (HA-732)
  2020/05/26  TK      pr_RFC_Picking_LPNReservations: Changes to pr_Allocation_AllocateLPN_New proc signature (HA-658)
  2020/05/24  TK      pr_RFC_Picking_LPNReservations & pr_RFC_Picking_ValidateLPNReservations:
  2020/03/02  SK      pr_RFC_Picking_LPNReservations: Changes to consider Warehouse from wave and not use a static value (FB-1947)
  2020/03/02  SK      pr_RFC_Picking_LPNReservations: Changes to make sure partial reservation works fine for wave (FB-1951)
  2020/02/20  SK      pr_RFC_Picking_LPNReservations: Get total order quantities and temp LPN quantities
  2020/02/18  PHK     pr_RFC_Picking_LPNReservations: Port back changes from Prod onsite (FB-992)
  2020/02/15  TK      pr_RFC_Picking_LPNReservations & pr_RFC_Picking_ValidateLPNReservations:
  2020/02/11  TK      pr_RFC_Picking_LPNReservations & pr_RFC_Picking_ValidateLPNReservations: Exclude bulk order quantities for summary (FB-1866)
  2020/02/10  TK      pr_RFC_Picking_LPNReservations: Changes made to consider AllocableQty insetad of Quantity while allocating LPN (FB-1815)
  2020/02/04  TK      pr_RFC_Picking_LPNReservations: Bug fix to handle situations where ship carton isn't pregenerated (FB-UATSupport)
              RV      pr_RFC_Picking_LPNReservations, pr_RFC_Picking_ValidateLPNReservations: Made changes to do not return data set with zero quantity
  2020/01/29  TK      pr_RFC_Picking_ValidateLPNReservation & pr_RFC_Picking_LPNReservations:
  2020/01/28  TK      pr_RFC_Picking_LPNReservations: Changes to do status updates properly (FB-1797)
                      pr_RFC_Picking_LPNReservations: Changes to return the balance SKUs with units to pick (FB-1667)
  2019/12/12  SK      pr_RFC_Picking_LPNReservations: More inputs for additional validations (FB-1657)
  2019/11/26  SK      pr_RFC_Picking_LPNReservations: Corrected Qty for Audit log & included some debug points (FB-1658)
  2019/10/18  SK      pr_RFC_Picking_LPNReservations: Enhance LPN Reservation (FB-1442)
  2019/01/09  SV      pr_RFC_Picking_LPNReservations: Changes not to validate LPN WaveNo during RF-Unassign action (OB2-336)
  2018/11/23  RT      pr_RFC_Picking_LPNReservations: Added Validation for LPN to Pick (FB-1200)
  2018/10/25  TK      pr_RFC_Picking_LPNReservations: Changes to Allocation_AllocateLPN proc signature (S2GCA-390)
  2018/01/29  TK      pr_RFC_Picking_LPNReservations: Changes to Allocation_AllocateLPN signature changes (S2G-152)
  2017/02/22  SV      pr_RFC_Picking_LPNReservations: Updating the Pallet count and status if we are not confirming LPN as Picked after Allocation (HPI-1101)
  2017/02/03  ??      pr_RFC_Picking_LPNReservations: Added change to update LPNs Lot number to allocate to the order (HPI-GoLive)
  2016/12/13  AY      pr_RFC_Picking_LPNReservations: Handle reservation of multi-SKU LPNs (HPI-GoLive)
  2016/11/28  YJ      pr_RFC_Picking_LPNReservations: Added missing message descriptions for LPN Reservations (HPI-1062)
  2016/10/14  YJ      pr_RFC_Picking_LPNReservations: Added changes for carton to be marked as picked, and added UnitsToAllocate for where clause (HPI-865)
  2016/10/10  VM      pr_RFC_Picking_LPNReservations:
  2016/10/05  ??      pr_RFC_Picking_LPNReservations: Modified check condition to consider UnitsToAllocate (HPI-GoLive)
              AY      pr_RFC_Picking_LPNReservations: Mark LPN as picked or else nothing an be done (HPI-GoLive)
  2015/12/10  DK      pr_RFC_Picking_LPNReservations: Added a call to Batch status procedure (FB-567).
  2015/12/01  VM/RV   pr_RFC_Picking_LPNReservations: Pallet re calculate after LPN reservation (FB-552)
  2015/11/21  AY      pr_RFC_Picking_LPNReservations: Enhancements and code optimization (FB-528)
  2015/11/19  VM      pr_RFC_Picking_LPNReservations:
                      pr_RFC_Picking_LPNReservations: Modified procedure to handle as flag changes in pr_LPNs_Unallocate (FB-441)
  2013/09/16  PK      pr_RFC_Picking_LPNReservations: Changes related to the change of Order Status Code.
  2012/10/25  YA      pr_RFC_Picking_LPNReservations: Removed unnecessary params for coalesce
              VM      pr_RFC_Picking_LPNReservations: Added a required validation and corrected messages and other minor format changes
  2012/10/24  VM      pr_RFC_Picking_LPNReservations: set default values as 'N' for ValidateUnitsperCarton
  2012/10/22  PK      pr_RFC_Picking_LPNReservations: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_LPNReservations') is not null
  drop Procedure pr_RFC_Picking_LPNReservations;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_LPNReservations:

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
Create Procedure pr_RFC_Picking_LPNReservations
  (@xmlInput     xml,
   @xmlResult    xml output)
as
  declare @ReturnCode               TInteger,
          @vActivationReturnCode    TInteger,
          @MessageName              TMessageName,
          @Message                  TDescription,
          @vInputXML                TXML, -- TXML version of xmlInput
          @vxmlInput                xml,  -- Input modified with addition of missing values
          @vSKUDetailsToAllocate    xml,
          @vStrSKUDetailsToAllocate TXML,
          @vStrOutputXML            TXML,
          @vxmlRulesData            TXML,

          @vPalletId                TRecordId,
          @LPN                      TLPN,
          @PickTicket               TPickTicket,
          @WaveNo                   TPickBatchNo,
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
          @vLPNWarehouse            TWarehouse,
          @vLPNWaveNo               TPickBatchNo,
          @vLPNType                 TTypeCode,
          @vLPNInnerPacks           TInnerPacks,
          @vLPNNumLines             TCount,
          @vLPNOwner                TOwnership,
          @vSplitLPN                TLPN,
          @vLDRecordId              TRecordId,
          @vOldOrderId              TRecordId,
          @vOldWaveId               TRecordId,
          @vOrderId                 TRecordId,
          @vOrderDetailId           TRecordId,
          @vOrderType               TOrderType,
          @vOrderLPNId              TRecordId,
          @vInventoryClass1         TInventoryClass,
          @vInventoryClass2         TInventoryClass,
          @vInventoryClass3         TInventoryClass,
          @vUnitsAssigned           TQuantity,
          @vOrderOwner              TOwnership,
          @vNumOrders               TCount,
          @vSKUId                   TRecordId,
          @vUnitsPerInnerPack       TInteger,
          @vAuditActivity           TActivityType,
          @ConfirmLPNReservation    TVarChar,
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

          @vOperationVia            TOperation,
          @vSelectedQuantity        TQuantity,
          @vSelectedInnerPacks      TInnerPacks,
          @vSelectedUoM             TUoM,
          @vQtyToReserve            TQuantity,
          @vBatchNumUnits           TQuantity,
          @vPartialReservation      TFlags,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId,
          @vDeviceId                TDeviceId,
          @vValidWarehouses         TControlValue ,
          @vActivatePreGeneratedCartons
                                    TFlag,

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
          @ttWavesList      TEntityKeysTable;

  declare @ttNotes  table (Note1    TDescription,
                           Note2    TDescription,
                           Note3    TDescription,
                           Note4    TDescription,
                           Note5    TDescription);

  declare @ttWaveInvInfo table (RecordId                TRecordId Identity(1,1),
                                WaveId                  TRecordId,
                                SKUId                   TRecordId,
                                SKU                     TSKU,
                                InventoryClass1         TInventoryClass,
                                InventoryClass2         TInventoryClass,
                                InventoryClass3         TInventoryClass,
                                IPsToReserve            TInnerPacks,
                                QtyToReserve            TInteger,
                                QtyOrdered              TInteger,
                                QtyReserved             TInteger)

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

  select @vOperationVia       = null,
         @MessageName         = null,
         @ReturnCode          = 0,
         @vPartialReservation = null,
         @vInputXML           = convert(varchar(max), @xmlInput);

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @vBusinessUnit, @vDebug output;

  /* Temporary tables to store LPN details & Order details with additional information  */
  select * into #LPNDetails from @ttLPNDetails;
  alter table   #LPNDetails drop column AllocableQty;
  alter table   #LPNDetails add AllocableQty as (Quantity - ReservedQty);

  select * into #OrderDetails from @ttOrderDetails;
  select * into #Validations  from @ttValidations;
  select * into #Notes        from @ttNotes;

  /* Fetch the Input Params from the XML parameter */
  select @LPN                 = Record.Col.value('LPN[1]',                'TLPN'),
         @PickTicket          = Record.Col.value('PickTicket[1]',         'TPickTicket'),
         @CustPO              = Record.Col.value('CustPO[1]',             'TCustPO'),
         @ShipToStore         = Record.Col.value('Store[1]',              'TShipToId'),
         @Option              = Record.Col.value('Option[1]',             'TFlag'),
         @WaveNo              = Record.Col.value('PickBatchNo[1]',        'TPickBatchNo'),
         @vSelectedInnerPacks = Record.Col.value('SelectedInnerPacks[1]', 'TQuantity'),
         @vSelectedQuantity   = Record.Col.value('SelectedQuantity[1]',   'TQuantity'),
         @vSelectedUoM        = Record.Col.value('SelectedUOM[1]',        'TUoM'),
         @vBusinessUnit       = Record.Col.value('BusinessUnit[1]',       'TBusinessUnit'),
         @vUserId             = Record.Col.value('UserId[1]',             'TUserId'),
         @vDeviceId           = Record.Col.value('DeviceId[1]',           'TDeviceId')
  from @xmlInput.nodes('ConfirmLPNReservations') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @LPN, 'LPN',
                      @Value1 = @WaveNo, @Value2 = @PickTicket, @Value3 = @CustPO, @Value4 = @ShipToStore,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Update to null if the Input Params are empty */
  select @PickTicket          = nullif(@PickTicket,  ''),
         @vCustPO             = nullif(@CustPO,      ''),
         @ShipToStore         = nullif(@ShipToStore, ''),
         @WaveNo              = nullif(@WaveNo, ''),
         @vSelectedInnerPacks = nullif(@vSelectedInnerPacks, ''),
         @vSelectedQuantity   = nullif(@vSelectedQuantity, ''),
         @vNumOrders          = null;

  /* Fetching of LPN Info */
  select @vLPNId         = L.LPNId,
         @vLPN           = L.LPN,
         @vLPNType       = L.LPNType,
         @vLPNStatus     = L.Status,
         @vSKUId         = L.SKUId,
         @vPalletId      = L.PalletId,
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

  /* Flag if operation is through wave or PT */
  if (@WaveNo is not null) and (@vCustPO is null) and (@ShipToStore is null) and (@PickTicket is null)
    begin
      select @vOperationVia = 'W' /* Wave given */;

      select @vWaveId    = W.WaveId,
             @vWaveNo    = W.WaveNo,
             @vWaveType  = W.WaveType,
             @vWaveOwner = W.Ownership,
             @vWarehouse = W.Warehouse
      from Waves W
      where (W.WaveNo = @WaveNo) and (W.BusinessUnit = @vBusinessUnit);
    end
  else
  if (@PickTicket is not null)
    select @vOperationVia = 'PT' /* PickTicket given */;
  else
  /* Even if PickTicket is not given, identify PickTicket based upon other entities */
  if (@PickTicket is null) and
     ((@WaveNo is not null) or (@vCustPO is not null) or (@ShipToStore is not null))
    begin
      select @vOperationVia = 'PT' /* PickTicket given */;

      /* If user has not given specific Order then we have to identify the Order
         this LPN can be allocated to */
      select @PickTicket = OH.PickTicket
      from OrderHeaders OH
      where (OH.PickBatchNo               = coalesce(@WaveNo, OH.PickBatchNo)) and
            (coalesce(OH.CustPO, '')      = coalesce(@vCustPO,      OH.CustPO, '')) and
            (coalesce(OH.ShipToStore, '') = coalesce(@ShipToStore,  OH.ShipToStore, '')) and
            (BusinessUnit                 = @vBusinessUnit) and
            (charindex(OH.Status, 'ONSDX' /* Downloaded, New, Shipped, Completed, Canceled */) = 0) and
            (OH.Archived                  = 'N');
    end

  /* fetch wave details if PickTicket given or fetched */
  if (@vOperationVia = 'PT')
    begin
      select @vWaveNo     = OH.PickBatchNo,
             @vWaveId     = OH.PickBatchId,
             @vOrderId    = OH.OrderId,
             @vOrderType  = OH.OrderType,
             @vOrderOwner = OH.Ownership,
             @vWaveType   =  W.WaveType,
             @vWarehouse  =  W.Warehouse
      from OrderHeaders OH
        join Waves W on OH.PickBatchId = W.WaveId
      where (OH.PickTicket = @PickTicket) and (OH.BusinessUnit = @vBusinessUnit);
    end

  /* Fetch controls */
  select  @vConfirmLPNAsPickedOnAllocate = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'ConfirmLPNAsPickedOnAllocate', 'N' /* No */, @vBusinessUnit, null /* UserId */),
          @vValidWarehouses = dbo.fn_Controls_GetAsString('LPNReservation',  'ValidWarehouses', ',,' /* O1 */, @vBusinessUnit, null /* UserId */);

  select @vActivatePreGeneratedCartons = case when dbo.fn_IsInList(@vWarehouse, @vValidWarehouses) > 0 then 'Y' else 'N' end;

  /* User can input:
      Quantity in Cases i.e., InnerPacks value OR
      Quantity in Eaches i.e., Quantity value */
  if (@vLPNNumLines = 1) and (@vSelectedQuantity is null) and (coalesce(@vSelectedInnerPacks, 0) <> 0)
    begin
      select @vSelectedQuantity = (@vSelectedInnerPacks * UnitsPerPackage)
      from LPNDetails
      where LPNId = @vLPNId;

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
                                  else 'N'
                                end;

  /* Fetching LPN Details */
  insert into #LPNDetails (LPNId, LPNDetailId, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                           ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO,
                           InventoryClass1, InventoryClass2, InventoryClass3)
    select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
           LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId, LD.Lot, LD.CoO,
           L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
    from LPNDetails LD
      join LPNs L on (LD.LPNId = L.LPNId)
    where LD.LPNId = @vLPNId;

  /* Restrict the LPN quantity if partial reservation is allowed */
  if (@vPartialReservation = 'Y' /* yes */)
    update #LPNDetails set Quantity = @vSelectedQuantity where LPNId = @vLPNId;

  /* Fetch OrderDetails based on the Wave or PickTicket given with only the SKU(s) we have in FromLPN */
  if (@vOperationVia = 'W' /* Wave number given */)
    begin
      /* Get the wave inventory requirement join with LPN details of the LPN that is being reserved */
      insert into @ttWaveInvInfo (WaveId, SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, IPsToReserve, QtyToReserve, QtyReserved)
        select WI.WaveId, WI.SKUId, WI.SKU, WI.InventoryClass1, WI.InventoryClass2, WI.InventoryClass3, WI.IPsToReserve, WI.QtyToReserve, WI.QtyReserved
        from #LPNDetails LD
          cross apply dbo.fn_Wave_GetInventoryInfo(@vWaveId, LD.SKUId, LD.InventoryClass1, LD.InventoryClass2, LD.InventoryClass3) WI;

      /* WaveInvInfo has counts summarized by SKU, insert them into order details to process further */
      insert into #OrderDetails (WaveId, WaveNo, SKUId, InventoryClass1, InventoryClass2, InventoryClass3, UnitsToAllocate)
        select WaveId, @vWaveNo, SKUId, InventoryClass1, InventoryClass2, InventoryClass3, QtyToReserve
        from @ttWaveInvInfo;
    end

  if (@vOperationVia = 'PT' /* PickTicket given */)
    insert into #OrderDetails (WaveId, WaveNo, PickTicket, OrderId, OrderDetailId, SKUId, UnitsToShip,
                               UnitsToAllocate, UnitsPerCarton, InventoryClass1, InventoryClass2, InventoryClass3)
      select OH.PickBatchId, OH.PickBatchNo, OH.PickTicket, OD.OrderId, OD.OrderDetailId, OD.SKUId, OD.UnitsAuthorizedToShip,
             OD.UnitsToAllocate, OD.UnitsPerCarton, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3
      from OrderDetails OD
        join OrderHeaders OH on OD.OrderId = OH.OrderId
        join #LPNDetails LD on OD.SKUId = LD.SKUId and
                               OD.InventoryClass1 = LD.InventoryClass1 and
                               OD.InventoryClass2 = LD.InventoryClass2 and
                               OD.InventoryClass3 = LD.InventoryClass3
      where (OH.PickTicket   = @PickTicket) and
            (OH.BusinessUnit = @vBusinessUnit);

  /* Get waves list to be recounted later */
  insert into @ttWavesList (EntityId, EntityKey)
    select distinct WaveId, WaveNo from #OrderDetails;

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
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'OperationVia',       @vOperationVia);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'Warehouse',          @vLPNWarehouse);
  select @vInputXML = dbo.fn_XMLAddNameValue(@vInputXML, 'ConfirmLPNReservations', 'Option',             @Option);

  /* Validations */
  select @vxmlInput = convert(xml, @vInputXML);

  exec pr_Picking_ValidateLPNReservations @vxmlInput;

  /* Log the final input xml */
  if (charindex('I', @vDebug) > 0) exec pr_RFLog_Begin @vxmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                                                       null /* EntityId */, null /* EntityKey */, null /* Entity */,
                                                       'FinalXMLBeforeValidation' /* Operation */;

  /* Ship Cartons Activation */
  if (@vActivatePreGeneratedCartons = 'Y' /* yes */) and (@vOperationVia = 'PT' /* PickTicket */)
    exec @vActivationReturnCode = pr_LPNs_ActivatePreGeneratedLabels @vxmlInput;

  /* Get the Available Quantity, still not activated */
  select @vQtyToReserve = sum(AllocableQty) from #LPNDetails where (LPNId = @vLPNId);

  /* Log the flag and final quantity post activation */
  if (charindex('L', @vDebug) > 0)
    begin
      select @Message = 'Partial: ' + @vPartialReservation + '; QtyLeft: ' + convert(varchar(10), @vQtyToReserve);
      exec pr_ActivityLog_AddMessage 'PostActivation', null, null, null, @Message, @@ProcId, null, @vBusinessUnit, @vUserId;
    end

  /* Validations: Post Activation */
  select @vxmlRulesData       = replace(@vInputXML, 'ConfirmLPNReservations', 'RootNode'),
         @vxmlRulesData       = replace(@vxmlRulesData, 'FIXTURES', 'FX');

  /* Process following validations only if Activate Pre-Generated labels procedure returned zero */
  if (@vActivationReturnCode = 0)
    exec pr_RuleSets_Evaluate 'LPNReservation_ValidatePostActivation', @vxmlRulesData, @MessageName output

  if (@MessageName is not null)
      goto ErrorHandler;

  /* Split LPN for Partial Reservation */
  if (@Option in ('A', 'R' /* Allocate, Reallocate */)) and
     (@vPartialReservation = 'Y' /* yes */) and (@vQtyToReserve > 0)
    begin
      exec pr_LPNs_SplitLPN @FromLPN       = @vLPN,
                            @SplitQuantity = @vQtyToReserve,
                            @BusinessUnit  = @vBusinessUnit,
                            @UserId        = @vUserId,
                            @ToLPN         = @vSplitLPN output;

      /* Delete the Original from LPN from the temp table */
      delete from #LPNDetails
      where LPNId = @vLPNId;

      /* Re-fetch all details after the split */
      select @vLPNId         = L.LPNId,
             @vLPNStatus     = L.Status,
             @vSKUId         = L.SKUId,
             @vPalletId      = L.PalletId,
             @vOldOrderId    = L.OrderId,
             @vLPNQuantity   = L.Quantity,
             @vLPNInnerPacks = L.InnerPacks,
             @vLPNWarehouse  = L.DestWarehouse,
             @vLPNWaveNo     = L.PickBatchNo
      from LPNs L
      where (L.LPN          = @vSplitLPN) and
            (L.BusinessUnit = @vBusinessUnit);

      /* Fetch the new split LPN Details */
      insert into #LPNDetails (LPNId, LPNDetailId, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                               ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO,
                               InventoryClass1, InventoryClass2, InventoryClass3)
        select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
               LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId, LD.Lot, LD.CoO,
               L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
        from LPNDetails LD
          join LPNs L on (LD.LPNId = L.LPNId)
        where LD.LPNId = @vLPNId;
    end

  /* If a wave is given, assumption is that the entire quantity is reserved and so the LPN is
     directly attached to the wave and no other updates are required */
  if ((@Option in ('A', 'R' /* Allocate, Reallocate */)) and
      (@vOperationVia = 'W' /* Wave number given */))
    begin
      update LPNs
      set PickBatchId = @vWaveId,
          PickBatchNo = @vWaveNo
        --  Status      = 'K' /* Picked */   -- We cannot directly update status to picked, need to call set status
      where LPNId = @vLPNId;

      /* Clear location on LPNs */
      exec pr_LPNs_SetLocation @vLPNId, null /* LocationId */, null /* Location */;

      /* Update LPN status to Picked */
      exec pr_LPNs_SetStatus @vLPNId, 'K'/* Picked */;

      select @vAuditActivity = 'LPNReservedForWave';
    end
  else
  /* Updating Order on LPN */
  if ((@vOldOrderId is not null) and (@Option = 'U' /* Unallocate */))
    begin
      exec @ReturnCode = pr_LPNs_Unallocate @LPNId         = @vLPNId,
                                            @UnallocPallet = 'P' /* PalletPick - Unallocate Pallet */,
                                            @BusinessUnit  = @vBusinessUnit,
                                            @UserId        = @vUserId;

      if (@ReturnCode > 0)
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
        --  Status      = 'P' /* Putaway */   -- We cannot directly update status to putaway, need to call set status
      where LPNId = @vLPNId;

      /* Update LPN status to Picked */
      exec pr_LPNs_SetStatus @vLPNId, 'P' /* Putaway */, 'A'/* OnHand - Available */;

      select @vAuditActivity = 'LPNUnReservedForWave';
    end

  /* Allocating LPN to new Wave/PT */
  /* This is regular process where if PickTicket is given, LPN is allocated based on order */
  if (@Option <> 'U' /* Unallocate */) and
     ((@vOrderId is not null) or (@Option in ('A', 'R' /* Allocate, Reallocate */))) and
     (@vOperationVia = 'PT')
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
          where RecordId > @vLDRecordId and
                AllocableQty > 0
          order by RecordId;

          select @vOrderDetailId = OrderDetailId
          from #OrderDetails
          where (OrderId = @vOrderId) and
                (SKUId   = @vSKUId) and
                (InventoryClass1 = @vInventoryClass1) and
                (InventoryClass2 = @vInventoryClass2) and
                (InventoryClass3 = @vInventoryClass3);

          exec @ReturnCode = pr_Allocation_AllocateLPN_New @vLPNId,
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

          select @vSKUId = null, @vLPNDQuantity = null, @vLPNDetailId = null, @vReservedLPNDetailId = null;
        end

      /* This would mean, that there are multiple LPNDetails that are processed i.e., Multi SKU LPN */
      if (@vLDRecordId > 1)
        select @vOrderDetailId = null;

      if (@ReturnCode > 0)
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
  if (@Option = 'A'/* Allocated/Assigned */)
    set @ConfirmLPNReservation = 'LPNAllocatedSuccessfully';
  else
  if (@Option = 'U'/* Unallocated/Unassigned */)
    set @ConfirmLPNReservation = 'LPNUnallocatedSuccessfully';
  else
  if (@Option = 'R'/* Re-allocated/Re-assigned */)
    set @ConfirmLPNReservation = 'LPNReallocatedSuccessfully';

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
     (@vOperationVia = 'PT' /* PickTicket given */) and
     (@vQtyToReserve > 0)
    begin
      /* Call ConfirmLPNPick */
      exec pr_Picking_ConfirmLPNPick @vOrderId, @vOrderDetailId, @vLPNId,
                                     @vBusinessUnit, @vUserId, null /* @PickingPalletId */;

      /* Clear location on LPNs */
      exec pr_LPNs_SetLocation @vLPNId, null /* LocationId */, null /* Location */;

      exec pr_Pallets_UpdateCount @vPalletId, default, '*' /* Recalc */, @UserId = @vUserId;

      exec pr_Pallets_SetStatus @vPalletId, default /* New status */, @vUserId;
    end

  /* Recount & Status update */
  exec pr_PickBatch_Recalculate @ttWavesList, '$CS' /* defer status */, @vUserId, @vBusinessUnit;

  /* Call the pr_BuildRFSuccessXML to build the success message to display it in RF */
  exec pr_BuildRFSuccessXML @ConfirmLPNReservation, @xmlResult output;

  /* Following will be the dataset which will get binded over the RF GridLookup */
  if (@vOperationVia = 'W')
    begin
      /* Get the wave counts summarized by SKU */
      insert into @ttSKUQuantities(SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, IPsToReserve, QtyToReserve, QtyOrdered, QtyReserved)
        select SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, IPsToReserve, QtyToReserve, QtyOrdered, QtyReserved
        from dbo.fn_Wave_GetInventoryInfo(@vWaveId, null, null, null, null)
        where (QtyToReserve > 0)
        order by RecordId;

    end
  else
    insert into @ttSKUQuantities(SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, IPsToReserve, QtyToReserve, QtyOrdered, QtyReserved)
      select SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, sum(InnerPacksToAllocate),
             sum(cast(UnitsToAllocate as integer)), sum(UnitsAuthorizedToShip), sum(UnitsAssigned)
      from vwPickBatchDetails
      where (OrderId = @vOrderId) and (UnitsToAllocate > 0)
      group by SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3
      order by SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3;


  /* Build Result xml */
  set @vSKUDetailsToAllocate = (select S.SKUId,
                                       S.SKU,
                                       S.DisplaySKU,
                                       S.DisplaySKUDesc,
                                       S.UPC,

                                       InventoryClass1,
                                       InventoryClass2,
                                       InventoryClass3,

                                       /* used by v2 RF */
                                       IPsToReserve as Cases,
                                       QtyToReserve as Quantity,
                                       QtyReserved  as ReservedQuantity,

                                       /* user by v3 RF */
                                       IPsToReserve,
                                       QtyToReserve,
                                       QtyOrdered,
                                       QtyReserved
                                from @ttSKUQuantities ttSQ
                                  join SKUs S on (ttSQ.SKUId = S.SKUId)
                                order by ttSQ.RecordId
                                for XML RAW('SKUInfo'), TYPE, ELEMENTS, ROOT('SKUDetailsToAllocate'));

  /* Conversion in the following statements are required as we need to add the dataset with the result returned from pr_BuildRFSuccessXML */
  select @vStrSKUDetailsToAllocate = convert(varchar(max), @vSKUDetailsToAllocate);
  select @vStrOutputXML = convert(varchar(max), @xmlResult);

  /* Add the dataset xml to the result returned from pr_BuildRFSuccessXML */
  select @vStrOutputXML = dbo.fn_XMLAddNode(@vStrOutputXML, 'SUCCESSDETAILS', @vStrSKUDetailsToAllocate);

  /* Converting the result as xml to retun */
  select @xmlResult = convert(xml, @vStrOutputXML);

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
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @vNote1, @vNote2, @vNote3, @vNote4, @vNote5;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
end/* pr_RFC_Picking_LPNReservations */

Go
