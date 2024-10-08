/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/22  TK      pr_Reservation_ConfirmFromLPN & pr_Reservation_ValidateLPN:
                      pr_Reservation_ValidateLPN: Included InventoryClasses (HA-1723)
                      pr_Reservation_ConfirmFromLPN, pr_Reservation_ValidateLPN: Introduce inventory key to tables (HA-1583)
  2020/07/20  MS      pr_Reservation_ValidateLPN: Changes to validate InventoryClass (HA-1099)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_ValidateLPN') is not null
  drop Procedure pr_Reservation_ValidateLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_ValidateLPN:
    This procedure is invoked when the LPNs is scanned in LPN reservation screen and
    validates the scanned LPN against the entity being reserved to make sure that the
    right LPN is being reserved against the wave or PickTicket
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_ValidateLPN
  (@xmlInput            xml)
as
  declare @vReturnCode              TInteger,
          @vRecordId                TInteger,
          @vMessage                 TDescription,
          @vMessageName             TMessageName,
          @vxmlRulesData            TXML,
          @vValue1                  TDescription,
          @vValue2                  TDescription,
          /* Input params */
          @LPN                      TLPN,
          @PickTicket               TPickTicket,
          @WaveNo                   TWaveNo,
          @CustPO                   TCustPO,
          @ShipToStore              TShipToId,
          @vEntityToReserve         TEntity,
          @vSelectedQuantity        TQuantity,
          @vSelectedInnerPacks      TQuantity,
          @vSelectedUoM             TUoM,
          @vWarehouse               TWarehouse,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId,
          @vDeviceId                TDeviceId,
          @vOption                  TFlag,
          /* LPN */
          @vLPNId                   TRecordId,
          @vLPNStatus               TStatus,
          @vLPNInnerPacks           TInnerpacks,
          @vLPNQuantity             TQuantity,
          @vLPNWaveId               TRecordId,
          @vLPNWaveNo               TWaveNo,
          @vLPNOrderId              TRecordId,
          @vLPNNumDetails           TInteger,
          @vLPNSKUId                TRecordId,
          @vLPNUnitsPerInnerPack    TInteger,
          @vLPNOwner                TOwnership,
          @vLPNWarehouse            TWarehouse,
          @vLPNDetailQuantity       TQuantity,
          /* Wave */
          @vWaveId                  TRecordId,
          @vWaveNo                  TWaveNo,
          @vWaveNumUnits            TQuantity,
          @vWaveOwner               TOwnership,
          @vWaveWarehouse           TWarehouse,
          /* Pick Ticket */
          @vPickTicket              TPickTicket,
          @vOrderId                 TRecordId,
          @vOrderDetailId           TRecordId,
          @vOrderStatus             TStatus,
          @vOrderType               TOrderType,
          @vOrderQuantity           TCount,
          @vOrderWaveNo             TWaveNo,
          @vOrderOwner              TOwnership,
          @vOrderWarehouse          TWarehouse,
          @vNumOrders               TCount,
          @vNumUnits                TCount,
          @vUnitsAssigned           TCount,
          @vUnitsToAllocate         TCount,
          @vCustPO                  TCustPO,
          @vUnitsPerCarton          TInteger,
          @vUoM                     TUoM,
          @vOldOrderId              TRecordId,
          @vOldOrderStatus          TStatus,
          @vSKUId                   TRecordId,
          @vSKUQuantityRequired     TQuantity,
          @vValidLPNStatuses        TControlValue,
          @vPartialReservation      TFlags,
          @vValidateUnitsPerCarton  TFlags,
          @vRequireUniquePickTicket TFlags,
          @vReassignToSamePOOnly    TFlags,
          @vReassignToSameWaveOnly  TFlags,
          @vConfirmLPNAsPickedOnAllocate
                                    TFlag,
          @vAllowPartialReservation TFlags,
          @vValidWarehouses         TFlags,
          @vMultiSKULPN             TCount,
          @vInventoryClassMatch     TFlags,
          @vSplitRatioIncorrect     TFlags,
          @vtempOrderId             TRecordId,
          @vtempSKUId               TRecordId,
          @vtempUnitsToAllocate     TQuantity,
          @vtempLPNDetailQuantity   TQuantity,
          @vtempLPNInnerPacks       TInnerpacks;

  declare @ttSKUQuantities table (RecordId               TRecordId Identity(1,1),
                                  SKUId                  TRecordId,
                                  InventoryKey           TKeyValue,
                                  TotalUnitsToAllocate   TQuantity);
begin
  select  @vReturnCode       = 0,
          @vRecordId         = 0,
          @vMessage          = null,
          @vMessageName      = null,
          @vValue1           = null,
          @vMultiSKULPN      = 0,
          @vOrderQuantity    = 0;

  select @vxmlRulesData     = replace(convert(varchar(max), @xmlInput), 'ConfirmLPNReservations', 'RootNode');
  select @vxmlRulesData     = replace(@vxmlRulesData, 'FIXTURES', 'FX');

  /* Create table structure */
  select * into #SKUQuantities from @ttSKUQuantities

  /* Fetch the Input Params from the XML parameter */
  select @LPN                 = Record.Col.value('LPN[1]',                'TLPN'),
         @PickTicket          = Record.Col.value('PickTicket[1]',         'TPickTicket'),
         @CustPO              = Record.Col.value('CustPO[1]',             'TCustPO'),
         @ShipToStore         = Record.Col.value('Store[1]',              'TShipToId'),
         @WaveNo              = Record.Col.value('PickBatchNo[1]',        'TPickBatchNo'),
         @vSelectedInnerPacks = Record.Col.value('SelectedInnerPacks[1]', 'TQuantity'),
         @vSelectedQuantity   = Record.Col.value('SelectedQuantity[1]',   'TQuantity'),
         @vSelectedUoM        = Record.Col.value('SelectedUOM[1]',        'TUoM'),
         @vOption             = Record.Col.value('Option[1]',             'TFlag'),
         @vBusinessUnit       = Record.Col.value('BusinessUnit[1]',       'TBusinessUnit'),
         @vUserId             = Record.Col.value('UserId[1]',             'TUserId'),
         @vDeviceId           = Record.Col.value('DeviceId[1]',           'TDeviceId'),
         @vEntityToReserve    = Record.Col.value('EntityToReserve[1]',    'TEntity'),
         @vPartialReservation = Record.Col.value('PartialReservation[1]', 'TFlags')
  from @xmlInput.nodes('ConfirmLPNReservations') as Record(Col);

  /* Update to null if the Input Params are empty */
  select @WaveNo       = nullif(@WaveNo,      ''),
         @PickTicket   = nullif(@PickTicket,  ''),
         @CustPO       = nullif(@CustPO,      ''),
         @ShipToStore  = nullif(@ShipToStore, '')

  /* Get the control variable to validate if the LPN Quantity is not equal to the UnitsPerCarton on Order
     RequirePT : User has to give inputs to identify one PT only. If control value is Y and user gives
                 input that matches multiple POs, then there would be an error. If control value is N
                 then any one of the PTs would be selected and LPN allocated to it */
  select @vValidateUnitsPerCarton       = dbo.fn_Controls_GetAsBoolean('Picking',        'ValidateUnitsperCarton',       'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vRequireUniquePickTicket      = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'RequireUniquePT',              'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vConfirmLPNAsPickedOnAllocate = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'ConfirmLPNAsPickedOnAllocate', 'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vReassignToSamePOOnly         = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'ReassignToSamePOOnly',         'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vReassignToSameWaveOnly       = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'ReassignToSameWaveOnly',       'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vValidLPNStatuses             = dbo.fn_Controls_GetAsString ('LPNReservation', 'ValidLPNStatuses',              'PKDE' /* Putaway, Picked, Packed, Staged*/,
                                                                                                                                       @vBusinessUnit, null /* UserId */),
         @vAllowPartialReservation      = dbo.fn_Controls_GetAsString('LPNReservation',  'AllowPartialReservation',      'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vValidWarehouses              = dbo.fn_Controls_GetAsString('LPNReservation',  'ValidWarehouses',              ',O1,' /* O1 */,
                                                                                                                                       @vBusinessUnit, null /* UserId */);
  /* Fetch LPN info from the LPNDetails that are already loaded */
  select @vLPNId      = LPNId,
         @vOldOrderId = OrderId
  from #LPNDetails;

  /* Fetch Wave details if Wave is given */
  if (@WaveNo is not null)
    select @vWaveId        = RecordId,
           @vWaveNo        = BatchNo,
           @vWaveNumUnits  = NumUnits,
           @vWaveOwner     = Ownership,
           @vWaveWarehouse = Warehouse
    from Waves
    where (WaveNo = @WaveNo) and (BusinessUnit = @vBusinessUnit);

  /* Use PickTicket Number if given to find the PT To allocate to, if any other details are given
     then they should match with the PT */
  if (@PickTicket is not null)
    select @vOrderId     = OrderId,
           @vOrderStatus = Status,
           @vPickTicket  = @PickTicket,
           @vNumOrders   = 1
    from OrderHeaders
    where (PickTicket                = @PickTicket) and
          (PickBatchNo               = coalesce(@vWaveNo, PickBatchNo)) and
          (coalesce(CustPO, '')      = coalesce(@vCustPO, CustPO, '')) and
          (coalesce(ShipToStore, '') = coalesce(@ShipToStore, ShipToStore, '')) and
          (BusinessUnit              = @vBusinessUnit);

  /* Get LPN Info */
  select @vLPNWaveId     = PickBatchId,
         @vLPNOrderId    = OrderId,
         @vLPNStatus     = Status,
         @vLPNNumDetails = NumLines,
         @vLPNSKUId      = SKUId,
         @vLPNWaveNo     = PickBatchNo,
         @vLPNInnerPacks = InnerPacks,
         @vLPNOwner      = Ownership,
         @vLPNWarehouse  = DestWarehouse
  from LPNs
  where (LPNId = @vLPNId);

  /* If LPN is already allocated to an order then some customers want to restrict re-assignment to another Order
     of the same PO and some customers don't care - so use control variable and if it is to be restricted then
     override input CustPO to the current CustPO. Same applies to wave as well */
  if (@vOldOrderId is not null)
    select @vOldOrderStatus = Status,
           @vCustPO         = case when @vReassignToSamePOOnly   = 'N' /* No */ then @CustPO else CustPO end,
           @vWaveNo         = case when @vReassignToSameWaveOnly = 'N' /* No */ then @WaveNo else PickBatchNo end
    from OrderHeaders
    where (OrderId = @vOldOrderId);

  /* Short Validations */
  if (coalesce(@PickTicket, '') <> '') and (@vOrderId is null)
    set @vMessageName = 'PickTicketIsInvalid';
  else
  if (@PickTicket is not null) and (charindex(@vOrderStatus, 'OISDX' /* Downloaded, New, Shipped, Completed, Canceled */)<>0)
    set @vMessageName = 'LPNResv_InvalidOrderStatus';
  else
  if (@LPN is not null) and (charindex(@vLPNStatus, @vValidLPNStatuses) = 0)
    set @vMessageName = 'LPNResv_InvalidLPNStatus'

  if (@vMessageName is not null)
      goto ErrorHandler;

  /* If intent is to reserve for PT and it was not given by user, then we have to
     identify the Order this LPN can be allocated to. If it is single SKU LPN, it can be partially
     allocated else we check to make sure OD requires the entire qty in the LPN
     for each SKU */
  if (@vOrderId is null) and (@vEntityToReserve = 'PickTicket' /* PickTicket */)
    begin
      select @vOrderId   = Min(OH.OrderId),
             @vNumOrders = count(*)
      from OrderHeaders OH
        join OrderDetails OD on (OH.OrderId = OD.OrderId)
        join #LPNDetails LD on OD.SKUId = LD.SKUId and ((@vLPNNumDetails = 1) or (OD.UnitsToAllocate >= LD.Quantity))
      where (OH.PickBatchNo               = coalesce(@vWaveNo, OH.PickBatchNo)) and
            (coalesce(OH.CustPO, '')      = coalesce(@vCustPO, OH.CustPO, '')) and
            (coalesce(OH.ShipToStore, '') = coalesce(@ShipToStore, OH.ShipToStore, '')) and
            (charindex(OH.Status, 'ONSDX' /* Downloaded, New, Shipped, Completed, Canceled */) = 0) and
            (OH.Archived                  = 'N');
    end

  /* Collect NumOrders from #OrderDetails table
     Sum up quantity of the Order(s)  */
  select @vOrderQuantity = sum(UnitsToAllocate)
  from #OrderDetails;

  /* If unique order was identified, then fetch the Order detail to allocate to
     Limitation: This doesn't work for >1 orders */
  if (@vOrderId is not null)
    select @vOrderType      = OrderType,
           @vOrderWaveNo    = PickBatchNo,
           @vWaveId         = coalesce(@vWaveId, PickBatchId),
           @vNumUnits       = NumUnits,
           @vUnitsAssigned  = UnitsAssigned,
           @vOrderOwner     = Ownership,
           @vOrderWarehouse = Warehouse
    from OrderHeaders
    where (OrderId = @vOrderId);

  /* Sum up quantities by SKU for order detais */
  insert into #SKUQuantities(SKUId, InventoryKey, TotalUnitsToAllocate)
    select SKUId, InventoryKey, sum(UnitsToAllocate)
    from #OrderDetails
    group by SKUId, InventoryKey;

  /* Validate if Quantity being reserved is greater than the quantity required */
  select @vLPNDetailQuantity   = sum(LD.Quantity),
         @vSKUQuantityRequired = sum(ttSQ.TotalUnitsToAllocate)
  from #LPNDetails LD
    left outer join #SKUQuantities ttSQ on LD.InventoryKey = ttSQ.InventoryKey;

  /* Inventory class should be matched with OrderDetails, return Y if matched
    Note: The following will only work for Single SKU LPN's, if the LPN has multiple SKUs
    we should have to validate those in Rules, based on client requirement */
  select @vInventoryClassMatch = 'Y' /* yes */
  from #LPNDetails LD
    join #SKUQuantities ttSQ on (LD.InventoryKey = ttSQ.InventoryKey);

  /* Fetch UnitsPerInnerPack qty for a single line LPN */
  if (@vLPNNumDetails = 1)
    select @vLPNUnitsPerInnerPack = UnitsPerPackage
    from LPNDetails
    where LPNId = @vLPNId;

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vOption = 'U' /* Unallocate */) and (@vEntityToReserve = 'PickTicket') and
     (@vLPNStatus <> 'A' /* Allocated */) and (@vOldOrderId is null)
    set @vMessageName = 'LPNResv_LPNWasNotAllocatedToAnyOrder';
  else
  if (@vOption = 'U' /* Unallocate */) and (@vEntityToReserve = 'Wave') and
     (@vLPNWaveId is null)
    set @vMessageName = 'LPNResv_LPNWasNotReservedForAnyWave';
  else
  if (@vOption in ('U', 'R' /* Unallocate or Reallocate */)) and
     (charindex(@vOldOrderStatus, 'SDX' /* Shipped, Completed, Canceled */) > 0)
    set @vMessageName = 'LPNResv_OldOrderStatusInvalid';
  else
  if (@vOption = 'A' /* Allocate */) and
     (@vOldOrderId is not null)
    set @vMessageName = 'LPNResv_LPNAlreadyAllocatedToOtherOrder';
  else
  if (@vOption in ('A' /* Allocate */)) and
     (@vLPNWaveId > 0) and
     (@vLPNWaveId = @vWaveId)
    set @vMessageName = 'LPNResv_LPNAlreadyReservedForWave';
  else
  if (@vOption in ('A' /* Allocate */)) and
     (@vUnitsAssigned > 0) and
     (@vUnitsAssigned = @vNumUnits)
    set @vMessageName = 'LPNResv_OrderAlreadyReserved';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (charindex(@vOrderStatus, 'OISDX' /* Downloaded, New, Shipped, Completed, Canceled */) > 0)
    set @vMessageName = 'LPNResv_NewOrderStatusInvalid';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vEntityToReserve = 'PickTTicket') and
     (@vRequireUniquePickTicket = 'Y' /* Yes */) and
     (@vNumOrders > 1)
    set @vMessageName = 'LPNResv_ManyOrderMatchCriteria';
  else
  if (@vValidateUnitsPerCarton = 'Y' /* Yes */) and
     (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vLPNNumDetails = 1) and
     (@vLPNQuantity <> @vUnitsPerCarton) and
     (@vUoM <> 'PP ' /* Prepacks */ )
    set @vMessageName = 'LPNResv_LPNQtyMismatchWithUnitsPerCarton';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vEntityToReserve = 'PickTicket' /* PickTicket */) and
     (@vOrderId is null)
    set @vMessageName = 'LPNResv_CannotIdentifyOrder';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vLPNNumDetails = 1) and
     (not exists (select * from #SKUQuantities where SKUId = @vLPNSKUId)) -- check if the SKU is required for Order/Wave
    set @vMessageName = 'LPNResv_OrderDoesNotRequireSKU';
  --else
  --if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
  --   (dbo.fn_IsInList('O1', @vValidWarehouses) = 0) and
  --   (@vOrderDetailId is not null) and (@vLPNQuantity > @vUnitsToAllocate)
  --  set @vMessageName = 'LPNResv_LPNHasMoreUnitsThanRequired'; /* this dicrepancy is now evaluated below */
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (((@vEntityToReserve = 'PickTicket' /* PickTicket */) and (@vLPNOwner <> @vOrderOwner)) or
      ((@vEntityToReserve = 'Wave' /* Wave */) and (@vLPNOwner <> @vWaveOwner)))
    set @vMessageName = 'LPNResv_LPNOwnershipMismatch';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vLPNWarehouse <> @vOrderWarehouse)
    set @vMessageName = 'LPNResv_LPNOrderWarehouseMismatch'
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vLPNWarehouse <> @vWaveWarehouse)
    set @vMessageName = 'LPNResv_WaveWarehouseMismatch'
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vLPNNumDetails = 1) and /* single SKU LPN */  --Can this be for multi sku too?
     (coalesce(@vSelectedQuantity, '') <> '') and --For pre validation, this value is not passed and 0 can be valid value
     (@vSelectedQuantity > @vOrderQuantity) /* User input quantity is more than the quantity on the Order */
    select @vMessageName = 'LPNResv_ReserveMoreThanOrderQuantity',
           @vValue1      = cast(@vSelectedQuantity as varchar(20)),
           @vValue2      = cast(@vOrderQuantity    as varchar(20));

  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (coalesce(@vSelectedQuantity, '') <> '') and --For pre validation, this value is not passed and 0 can be valid value
     (@vSKUQuantityRequired is not null) and
     (@vLPNDetailQuantity > @vSKUQuantityRequired)
    begin
      select @vMessageName = 'LPNResv_ReserveMoreThanSKUQuantity',
             @vValue1      = cast(@vLPNDetailQuantity   as varchar(20)),
             @vValue2      = cast(@vSKUQuantityRequired as varchar(20));
    end
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (coalesce(@vInventoryClassMatch, '') <> 'Y' /* yes */)
    set @vMessageName = 'LPNResv_LPNInventoryClassMismatch';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vLPNNumDetails = 1) and
     (@vLPNUnitsPerInnerPack > 0) and
     ((@vSelectedQuantity % @vLPNUnitsPerInnerPack) <> 0)
    set @vMessageName = 'LPNResv_SelectedQtyNotMultipleOfLPNIP';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (coalesce(nullif(@vSelectedInnerPacks, ''), 0) <> 0) and
     (coalesce(@vLPNInnerPacks, 0) = 0)
    set @vMessageName = 'LPNResv_LPNHasNoInnerPacks_ProvideQty'
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vLPNNumDetails > 1) and (@vLPNSKUId is null) and
     (@vPartialReservation = 'Y' /* Yes */)
    set @vMessageName = 'LPNResv_MultiSKUNoPartialReservation';
  --else
  --if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
  --   (@vEntityToReserve = 'Wave') and
  --   (@vLPNNumDetails > 1)
  --  set @vMessageName = 'LPNResv_MultiSKUFullLPNMustProvidePT
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vLPNNumDetails = 1) and
     (@vAllowPartialReservation = 'N' /* No */) and
     (@vPartialReservation = 'Y' /* yes */)
    set @vMessageName = 'LPNResv_SingleSKUNoPartialReservation';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vEntityToReserve = 'PickTicket') and
     (@vLPNWaveNo <> @vOrderWaveNo)
    set @vMessageName = 'LPNResv_LPNWaveOrderWaveMismatch';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vEntityToReserve = 'Wave') and
     (@vOldOrderId <> 0)
    set @vMessageName = 'LPNResv_AllocatedLPNCannotBeReserved';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vEntityToReserve = 'PickTicket') and
     (@vOldOrderId <> 0) and
     (@vOrderType <> 'B' /* Bulk */)
    set @vMessageName = 'LPNResv_LPNAllocatedtoNonBulkOrder';
  else
    exec pr_RuleSets_Evaluate 'LPNReservation_Validate', @vxmlRulesData, @vMessageName output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2;

ExitHandler:
  return(coalesce(@vReturnCode, 0));

end /* pr_Reservation_ValidateLPN */

Go
