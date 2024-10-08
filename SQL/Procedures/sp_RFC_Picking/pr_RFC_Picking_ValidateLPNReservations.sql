/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/24  TK      pr_RFC_Picking_LPNReservations & pr_RFC_Picking_ValidateLPNReservations:
  2020/02/15  TK      pr_RFC_Picking_LPNReservations & pr_RFC_Picking_ValidateLPNReservations:
  2020/02/11  TK      pr_RFC_Picking_LPNReservations & pr_RFC_Picking_ValidateLPNReservations: Exclude bulk order quantities for summary (FB-1866)
              RV      pr_RFC_Picking_LPNReservations, pr_RFC_Picking_ValidateLPNReservations: Made changes to do not return data set with zero quantity
  2020/02/01  RV      pr_RFC_Picking_ValidateLPNReservations: Bug fixed to get the order quantity to validate (FB-1811)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ValidateLPNReservations') is not null
  drop Procedure pr_RFC_Picking_ValidateLPNReservations;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ValidateLPNReservations: In the LPN Reservations screen,
   once the user enters the information i.e. Wave or PickTicket, we would need
   to validate it as well as show the detailed information of SKUs/Qtys that
   are needed to be reserved. This procedure accomplishes that.
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ValidateLPNReservations
  (@xmlInput      xml,
   @xmlOutput     xml output)
as
  declare @vReturnCode              TInteger,
          @vRecordId                TInteger,
          @vMessage                 TDescription,
          @vMessageName             TMessageName,
          @vxmlRulesData            TXML,
          @vValue1                  TDescription,

          /* Input params */
          @PickTicket               TPickTicket,
          @WaveNo                   TWaveNo,
          @CustPO                   TCustPO,
          @ShipToStore              TShipToId,
          @vReservationFor          TTypeCode,
          @vSelectedQuantity        TQuantity,
          @vSelectedInnerPacks      TQuantity,
          @vSelectedUoM             TUoM,
          @vWarehouse               TWarehouse,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId,
          @vDeviceId                TDeviceId,
          @vOption                  TFlag,

          /* Wave */
          @vWaveId                  TRecordId,
          @vWaveNo                  TWaveNo,
          @vWaveNumUnits            TQuantity,
          /* Pick Ticket */
          @vPickTicket              TPickTicket,
          @vOrderId                 TRecordId,
          @vOrderDetailId           TRecordId,
          @vOrderStatus             TStatus,
          @vOrderType               TOrderType,
          @vOrderQuantity           TCount,
          @vOrderWaveNo             TWaveNo,
          @vNumOrders               TCount,
          @vUnitsToAllocate         TCount,
          @vCustPO                  TCustPO,
          @vUnitsPerCarton          TInteger,
          @vUoM                     TUoM,
          @vSKUId                   TRecordId,
          @vPartialReservation      TFlags,
          @vValidateUnitsPerCarton  TFlags,
          @vRequireUniquePickTicket TFlags,
          @vReassignToSamePOOnly    TFlags,
          @vReassignToSameWaveOnly  TFlags,
          @vAllowPartialReservation TControlValue ,
          @vValidWarehouses         TControlValue ,
          @vIncorrectQuantityMatch  TFlags,
          @vSplitRatioIncorrect     TFlags,
          @vtempOrderId             TRecordId,
          @vtempSKUId               TRecordId,
          @vtempUnitsToAllocate     TQuantity;

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
  select  @vReturnCode       = 0,
          @vRecordId         = 0,
          @vMessage          = null,
          @vMessageName      = null,
          @vValue1           = null,
          @vOrderQuantity    = 0,
          @vxmlRulesData     = convert(varchar(max), @xmlInput);
begin try
  /* Fetch the Input Params from the XML parameter */
  select @PickTicket          = Record.Col.value('PickTicket[1]',         'TPickTicket'),
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
         @vReservationFor     = Record.Col.value('OperationVia[1]',       'TTypeCode'),
         @vPartialReservation = Record.Col.value('PartialReservation[1]', 'TFlags')
  from @xmlInput.nodes('ConfirmLPNReservations') as Record(Col);

  /* Update to null if the Input Params are empty */
  select @PickTicket   = nullif(@PickTicket,  ''),
         @vCustPO      = nullif(@CustPO,      ''),
         @ShipToStore  = nullif(@ShipToStore, ''),
         @WaveNo       = nullif(@WaveNo, '');

  /* Get the control variable to validate if the LPN Quantity is not equal to the UnitsPerCarton on Order
     RequirePT : User has to give inputs to identify one PT only. If control value is Y and user gives
                 input that matches multiple POs, then there would be an error. If control value is N
                 then any one of the PTs would be selected and LPN allocated to it */
  select @vValidateUnitsPerCarton       = dbo.fn_Controls_GetAsBoolean('Picking',        'ValidateUnitsperCarton',       'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vRequireUniquePickTicket      = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'RequireUniquePT',              'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vReassignToSamePOOnly         = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'ReassignToSamePOOnly',         'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vReassignToSameWaveOnly       = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'ReassignToSameWaveOnly',       'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vAllowPartialReservation      = dbo.fn_Controls_GetAsString('LPNReservation',  'AllowPartialReservation',      'N' /* No */, @vBusinessUnit, null /* UserId */),
         @vValidWarehouses              = dbo.fn_Controls_GetAsString('LPNReservation',  'ValidWarehouses',              ',O1,' /* O1 */,
                                                                                                                                       @vBusinessUnit, null /* UserId */);
begin transaction;
  /* Fetch Wave details if Wave is given. Assume we are reserving for Wave
     If a valid PT is also given, then we would change this to PT */
  if (@WaveNo is not null)
    select @vWaveId         = RecordId,
           @vWaveNo         = WaveNo,
           @vWaveNumUnits   = NumUnits,
           @vReservationFor = 'W' /* Wave */
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

  /* Validations */

  if ((@vOption <> 'U') and
      (coalesce(@WaveNo, '') = '') and (coalesce(@PickTicket, '') = ''))
    set @vMessageName = 'LPNResv_WaveOrPTRequired';
  else
  if (@WaveNo is not null) and (@vWaveNo is null)
    set @vMessageName = 'LPNResv_InvalidWave';
  else
  if (@PickTicket is not null) and (@vPickTicket is null)
    set @vMessageName = 'LPNResv_InvalidPickTicket';
  else
  if (@PickTicket is not null) and (@vOrderId is null)
    set @vMessageName = 'LPNResv_InvalidCombination';
  else
  if (@PickTicket is not null) and (charindex(@vOrderStatus, 'OISDX' /* Downloaded, New, Shipped, Completed, Canceled */)<>0)
    set @vMessageName = 'LPNResv_InvalidOrderStatus';

  if (@vMessageName is not null)
      goto ErrorHandler;

  /* If unique order was identified, then fetch the Order detail to allocate to
     Limitation: This doesn't work for >1 orders */
  if (@vOrderId is not null)
    select @vOrderType      = OrderType,
           @vOrderWaveNo    = PickBatchNo,
           @vReservationFor = 'PT'
    from OrderHeaders
    where (OrderId = @vOrderId);

  /* Sum up quantities by SKU for given Wave and/or Order */
  if (@vReservationFor = 'W' /* Wave */)
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
      select SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
             sum(InnerPacksToAllocate), sum(cast(UnitsToAllocate as integer)), sum(UnitsAuthorizedToShip), sum(UnitsAssigned)
      from vwPickBatchDetails
      where (OrderId = @vOrderId) and (UnitsToAllocate > 0)
      group by SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3;

  /* Collect allocable quantity of the Order(s) */
  select @vOrderQuantity = sum(QtyToReserve)
  from @ttSKUQuantities;

  /* Validations */
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (charindex(@vOrderStatus, 'OISDX' /* Downloaded, New, Shipped, Completed, Canceled */) > 0)
    set @vMessageName = 'LPNResv_NewOrderStatusInvalid';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vReservationFor = 'PT') and
     (@vRequireUniquePickTicket = 'Y' /* Yes */) and
     (@vNumOrders > 1)
    set @vMessageName = 'LPNResv_ManyOrderMatchCriteria';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vReservationFor = 'PT' /* PickTicket */) and
     (@vOrderId is null)
    set @vMessageName = 'LPNResv_CannotIdentifyOrder';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vSelectedQuantity > @vOrderQuantity) /* User input quantity is more than the quantity on the Order */
    set @vMessageName = 'LPNResv_ReserveMoreThanOrderQuantity';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vIncorrectQuantityMatch = 'Y' /* yes */)
    set @vMessageName = 'LPNResv_OrderVSLPNQuantityMismatch';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vReservationFor = 'PT' /* PickTicket */) and
     (@vWaveNo <> @vOrderWaveNo)
    set @vMessageName = 'LPNResv_OrderAndWaveMismatch';
  else
    exec pr_RuleSets_Evaluate 'LPNReservation_Validate', @vxmlRulesData, @vMessageName output;

  set @xmlOutput = (select S.SKUId,
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
                    order by RecordId
                    for XML RAW('SKUInfo'), TYPE, ELEMENTS XSINIL, ROOT('SKUDetailsToAllocate'));

ErrorHandler:
  if (@vMessageName is not null)
     exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlOutput output;
end catch;
ExitHandler:
  return(coalesce(@vReturnCode, 0));

end /* pr_RFC_Picking_ValidateLPNReservations */

Go
