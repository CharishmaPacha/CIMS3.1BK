/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/11  TK      pr_Reservation_IdentifyWaveOrPickTicket & pr_Reservation_ValidateWaveOrPickTicket:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_ValidateWaveOrPickTicket') is not null
  drop Procedure pr_Reservation_ValidateWaveOrPickTicket;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_ValidateWaveOrPickTicket: In the LPN Reservations screen,
   once the user enters the information i.e. Wave or PickTicket, we would need
   to validate it as well as show the detailed information of SKUs/Qtys that
   are needed to be reserved. This procedure accomplishes that.
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_ValidateWaveOrPickTicket
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
          @vEntityToReserve         TEntity,
          @vSelectedQuantity        TQuantity,
          @vWarehouse               TWarehouse,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId,
          @vDeviceId                TDeviceId,
          @vOption                  TFlag,

          /* Wave */
          @vWaveId                  TRecordId,
          @vWaveNo                  TWaveNo,
          @vWaveType                TTypeCode,
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
          @vAllowPartialReservation TControlValue,
          @vValidWarehouses         TControlValue,
          @vSplitRatioIncorrect     TFlags;

  declare @ttOrderDetails           TOrderDetails;
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
         @vOption             = Record.Col.value('Option[1]',             'TFlag'),
         @vBusinessUnit       = Record.Col.value('BusinessUnit[1]',       'TBusinessUnit'),
         @vUserId             = Record.Col.value('UserId[1]',             'TUserId'),
         @vDeviceId           = Record.Col.value('DeviceId[1]',           'TDeviceId')
  from @xmlInput.nodes('ConfirmLPNReservations') as Record(Col);

  /* Update to null if the Input Params are empty */
  select @PickTicket   = nullif(@PickTicket,  ''),
         @vCustPO      = nullif(@CustPO,      ''),
         @ShipToStore  = nullif(@ShipToStore, ''),
         @WaveNo       = nullif(@WaveNo, '');

  /* Create Required hash tables */
  if object_id('tempdb..#OrderDetails') is null
    select * into #OrderDetails from @ttOrderDetails;

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
  /* Identify the Entity to be reserved */
  exec pr_Reservation_IdentifyWaveOrPickTicket @xmlInput, @vEntityToReserve out,
                                               @vWaveId out, @vWaveNo out,
                                               @vOrderId out, @vPickTicket out;

  /* Get Wave Info */
  if (@vWaveId is not null)
    select @vWaveId    = W.WaveId,
           @vWaveNo    = W.WaveNo,
           @vWaveType  = W.WaveType,
           @vWarehouse = W.Warehouse
    from Waves W
    where (W.WaveId = @vWaveId);

  /* Get order info */
  if (@vOrderId is not null)
    select @vOrderId     = OH.OrderId,
           @vOrderType   = OH.OrderType,
           @vOrderStatus = OH.Status,
           @vWaveId      = coalesce(@vWaveId, OH.PickBatchId),
           @vOrderWaveNo = coalesce(@vWaveNo, OH.PickBatchNo)
    from OrderHeaders OH
    where (OH.OrderId = @vOrderId);

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
  if (@PickTicket is not null) and (charindex(@vOrderStatus, 'OISDX' /* Downloaded, New, Shipped, Completed, Canceled */) <> 0)
    set @vMessageName = 'LPNResv_InvalidOrderStatus';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (charindex(@vOrderStatus, 'OISDX' /* Downloaded, New, Shipped, Completed, Canceled */) > 0)
    set @vMessageName = 'LPNResv_NewOrderStatusInvalid';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vEntityToReserve = 'PickTicket') and
     (@vRequireUniquePickTicket = 'Y' /* Yes */) and
     (@vNumOrders > 1)
    set @vMessageName = 'LPNResv_ManyOrderMatchCriteria';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vEntityToReserve = 'PickTicket') and
     (@vOrderId is null)
    set @vMessageName = 'LPNResv_CannotIdentifyOrder';
  else
  if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
     (@vEntityToReserve = 'PickTicket' /* PickTicket */) and
     (@vWaveNo <> @vOrderWaveNo)
    set @vMessageName = 'LPNResv_OrderAndWaveMismatch';
  else
  -- /* Some customers may want to reserve directly against PTs, so not enabling this yet AY 2021/03/11 */
  -- if (@vOption in ('A', 'R' /* Allocate or Reallocate */)) and
  --    (@vEntityToReserve = 'PickTicket') and
  --    (exists (select * from OrderHeaders where PickBatchId = @vWaveId and OrderType = 'B' /* Bulk */ and OrderId <> @vOrderId))
  --   set @vMessageName = 'LPNResv_ReserveAgainstBulkOrder';
  --else
    exec pr_RuleSets_Evaluate 'LPNReservation_Validate', @vxmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
    goto ErrorHandler;

  select @xmlOutput = (select @vEntityToReserve  as EntityToReserve,
                              @vWaveId           as WaveId,
                              @vWaveNo           as WaveNo,
                              @vOrderId          as OrderId,
                              @vPickTicket       as PickTicket
                       for XML RAW('LPNReservationInfo'), ELEMENTS);

ErrorHandler:
  if (@vMessageName is not null)
     exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlOutput output;
end catch;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_ValidateWaveOrPickTicket */

Go
