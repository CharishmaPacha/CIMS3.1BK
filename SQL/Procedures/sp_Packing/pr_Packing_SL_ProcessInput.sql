/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_SL_ProcessInput') is not null
  drop Procedure pr_Packing_SL_ProcessInput;
Go
/*------------------------------------------------------------------------------
  pr_Packing_SL_ProcessInput:
    procedure returns all details to be displayed in packing screen

  XML Structure:
  Procedure accepts parameter in the xml format as below

    Input Params:
     EntityId - Primary key of the entity i.e LPN, Wave, Pallet or PickTicket.
     Entity   - Defines what is it in EntityId ???  i.e LPN, PickTicket or wave

     <PackingSLInfo>
        <CurrentInput></CurrentInput>
        <WaveNo></WaveNo>
        <PickTicket></PickTicket>
        <SKU></SKU>
        <FromLPN></FromLPN>
        <ToLPN></ToLPN>
        <NumUnitsScanned></NumUnitsToScanned>
        <ForceClose></ForceClose>
        <Action></Action>
        <PackStation> </PackStation>
        <BusinessUnit></BusinessUnit>
        <UserId></UserId>
     </PackingSLInfo>

  <SLOrderPackingInfo>
    <Context>
        <Wave></Wave>
        <PickTicket></PickTicket>
        <FromLPN></FromLPN>
        <ToLPN></ToLPN>
        <SKU></SKU>
    </Context>
    <Options>
        <IsWeightOrCartonReq><IsWeightandCartonReq>
        <OperationStatus><OperationStatus>
    </Options>
    <WaveDisplayInfo>
        <WaveType></WaveType>
        <WaveNo></WaveNo>
        <FromLPN></FromLPN>
        <ToLPN></ToLPN>
        <NumOrders></NumOrders>
        <NumLPNs></NumLPNs>
        <NumUnits></NumUnits>
    </WaveInfo>
    <OrderDisplayInfo>
        <PickTicket></PickTicket>
        <SKU></SKU>
        <NumUnits></NumUnits>
        <ShipVia><ShipVia>
        <ShipToAddress></ShipToAddress>
    </OrderDisplayInfo>
    <SKUPackingDetails>
        <SKUPackingDetail>
            <SKU></SKU>
            <SKU1></SKU1>
            <SKU2></SKU2>
            <SKU3></SKU3>
            <SKU4></SKU4>
            <SKU5></SKU5>
            -
        </SKUPackingDetail>
        <SKUPackingDetail>
        </SKUPackingDetail>
    </SKUPackingDetails>
    <PackingCloseLPN>
      ......
      ......
    </PackingCloseLPN>

?    <Packing Instructions></Packing Instructions>
?    <Notifications></Notifications>
?    <Errors></Errors>
</SLOrderPackingInfo>

------------------------------------------------------------------------------*/

Create Procedure pr_Packing_SL_ProcessInput
  (@xmlInput   TXML,
   @xmlResult  TXML = null output)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessage,

          @vEntityValue  TEntity,
          @vEntityId     TRecordId,

          @vLPNId        TRecordId,
          @vLPN          TLPN,

          @vUnitsScanned TQuantity,

          /* Input params */
          @WaveNo        TPickBatchNo,
          @PickTicket    TPickTicket,
          @FromLPN       TLPN,
          @ToLPN         TLPN,
          @SKU           TSKU,

          @vToLPNId      TRecordId,
          @vFromLPNId    TRecordId,

          @vSKUId        TRecordId,
          @vSKU          TSKU,
          /* Wave */
          @vWaveId       TRecordId,
          @vWaveNo       TPickBatchNo,
          @vWaveType     TTypeCode,
          @vWaveStatus   TStatus,

          @vCurrWaveNo   TPickBatchNo,
          @vCurrWaveId   TRecordId,

          @vCurrOrderId  TRecordId,
          @vCurrPickTicket TPickTicket,

          /* Order */
          @vOrderId      TRecordId,
          @vPickTicket   TPickTicket,
          @vOrderType    TTypeCode,
          @vOrderStatus  TStatus,

          @vPackStation  TName,
          @vCommand      TDescription,
          @vForceClose   TFlags,
          @vAction       TDescription,

          @vCartonType   TCartonType,
          @vWeight       TWeight,
          @vReturnTrackingNo
                           TTrackingNo,

          @vUnitsToPack  TQuantity,

          @vBusinessUnit TBusinessUnit,
          @vUserId       TUserId,
          @vEntityType   TTypeCode,
          @vActivityLogId TRecordId,

          @xmlData       xml,

          @vxmlInput     TXML,
          @vShowDataToPack_Mode
                         TDescription;

  declare @vInputParams TInputParams;
begin
  select @vMessageName = null;

  if (coalesce(@xmlInput, '') <> '')
    begin
      set @xmlData = convert(xml, @xmlInput);
       /* Get the EntityValye from the xml */
      select @vEntityValue  = nullif(Record.Col.value('CurrentInput[1]',    'TDescription'), ''),
             @WaveNo        = nullif(Record.Col.value('WaveNo[1]',          'TPickBatchNo'), ''),
             @PickTicket    = nullif(Record.Col.value('PickTicket[1]',      'TPickTicket'), ''),
             @FromLPN       = nullif(Record.Col.value('FromLPN[1]',         'TLPN'), ''),
             @ToLPN         = nullif(Record.Col.value('ToLPN[1]',           'TLPN'), ''),
             @SKU           = nullif(Record.Col.value('SKU[1]',             'TSKU'), ''),
             @vUnitsScanned = nullif(Record.Col.value('NumUnitsScanned[1]', 'TPickTicket'), ''),
             @vCommand      = nullif(Record.Col.value('Command[1]',         'TDescription'), ''),
             @vAction       = nullif(Record.Col.value('Action[1]',          'TDescription'), ''),
             @vPackStation  = nullif(Record.Col.value('PackStation[1]',     'TName'), ''),
             @vCartonType   = nullif(Record.Col.value('CartonType[1]',      'TCartonType'), ''),
             @vWeight       = nullif(Record.Col.value('Weight[1]',          'TWeight'), ''),
             @vReturnTrackingNo
                            = nullif(Record.Col.value('ReturnTrackingNo[1]','TTrackingNo'),''),
             @vBusinessUnit = nullif(Record.Col.value('BusinessUnit[1]',    'TBusinessUnit'),''),
             @vUserId       = nullif(Record.Col.value('UserId[1]',          'TUserId'), '')
      from @xmlData.nodes('/PackingSLInfo') as Record(Col);
    end

  /* insert into activitylog details */
  exec pr_ActivityLog_AddMessage 'Packing_SL', null, @vEntityValue, 'PickTicket', 'ProcessInput', @@ProcId, @xmlInput,
                                 @vBusinessUnit, @vUserId, @SKU, @WaveNo, @PickTicket, @vUnitsScanned, @FromLPN,
                                 null /* DeviceId */, @ActivityLogId = @vActivityLogId output;

  if (coalesce(@xmlInput, '') = '')
    set @vMessageName = 'PackingSL_MissingInput';
  else
  if (coalesce(@vEntityValue, '') = '')
    set @vMessageName = 'PackingSL_InputRequired';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Mode - we need to show data based on the scanned entity , if user scans LPN then we need to show
     data related to LPN only, if user scanned the Order then we need to show order. If the user scanned
     Wave then we need to show complete data

     Mode - will define wave / order or LPN  */
  select @vShowDataToPack_Mode = dbo.fn_Controls_GetAsString ('Packing_SL', 'PackingMode',  'Wave',
                                                              @vBusinessUnit, @vUserId);

  /* If the user scanned close package then we can set the flag as force close*/
  if (@vEntityValue like '%CLOSE%')
    select @vForceClose = 'Y',
           @vEntityType = 'Command',
           @vAction     = coalesce(@vAction, 'CLOSELPN');

  /* Check for LPN first as most often this is what user will scan */
  select @vWaveId     = PickBatchId,
         @vWaveNo     = PickBatchNo,
         @vEntityId   = LPNId,
         @vLPNId      = LPNId,
         @vLPN        = LPN,
         @vEntityType = 'LPN'
  from LPNs
  where (LPN          = @vEntityValue) and
        (BusinessUnit = @vBusinessUnit);

  /* There might be chance to scan SKU to close carton */
  if (@vEntityType is null)
    select Top 1
           @vSKUId      = SKUId,
           @vSKU        = SKU,
           @vEntityType = 'SKU',
           @vEntityId   = SKUId
    from dbo.fn_SKUs_GetScannedSKUs (@vEntityValue, @vBusinessUnit);

  /* Check for wave number, i.e user scanned entity is pickbatch or not,
     if user scans it then get it from LPNs  */
  if (@vEntityType is null)
    select @vWaveNo     = BatchNo,
           @vWaveId     = RecordId,
           @vEntityId   = RecordId,
           @vEntityType = 'Wave'
    from PickBatches
    where ((BatchNo = @vEntityValue) and
           (BusinessUnit = @vBusinessUnit));

  /* Check for Order, i.e user scanned entity is PickTicket or not,
     if user scans it then get it from orders  */
  if (@vEntityType is null)
    select @vPickTicket  = PickTicket,
           @vOrderId     = OrderId,
           @vWaveId      = PickBatchId,
           @vWaveNo      = PickBatchNo,
           @vEntityId    = OrderId,
           @vEntityType  = 'PickTicket',
           @vOrderType   = OrderType,
           @vOrderStatus = Status
    from OrderHeaders
    where (PickTicket  = @vEntityValue) and
          (BusinessUnit = @vBusinessUnit);

  if (@ToLPN is not null)
    select @vToLPNId = LPNId
    from LPNs
    where (LPN = @ToLPN) and
          (BusinessUnit = @vBusinessUnit);

  if (@FromLPN is not null)
    select @vFromLPNId = LPNId
    from LPNs
    where (LPN = @FromLPN) and
          (BusinessUnit = @vBusinessUnit);

  if (@WaveNo is not null)
    select @vCurrWaveNo = BatchNo,
           @vCurrWaveId = RecordId
    from PickBatches
    where (BatchNo      = @WaveNo) and
          (BusinessUnit = @vBusinessUnit);

  if (@SKU is not null) and (@vSKUId is null)
    select @vSKUId = SKUId,
           @vSKU   = SKU
    from dbo.fn_SKUs_GetScannedSKUs (@SKU, @vBusinessUnit)

  /* make sure scanned entity is not an order and we have scanned
    pt value */
  if (@PickTicket is not null)
    select @vCurrOrderId    = OrderId,
           @vCurrWaveId     = PickBatchId,
           @vCurrWaveNo     = PickBatchNo,
           @vCurrPickTicket = PickTicket
    from OrderHeaders
    where (PickTicket   = @PickTicket) and
          (BusinessUnit = @vBusinessUnit);

  /* Get Order info */
  if (@vOrderId is not null)
    select @vPickTicket  = PickTicket,
           @vOrderType   = OrderType,
           @vOrderStatus = Status
    from OrderHeaders
    where (OrderId = @vOrderId);

  /* get units to pack */
  select @vUnitsToPack = UnitsToAllocate
  from OrderDetails
  where (OrderId = @vOrderId) and
        (SKUId   = @vSKUId);

  if (@ToLPN is not null) and (@vToLPNId is null)
    set @vMessageName = 'InvalidToLPN';
  else
  if (@FromLPN is not null) and (@vFromLPNId is null)
    set @vMessageName = 'InvalidFromLPN';
  else
  /* We were not able to identify the given input as Wave, PT, Order, FromLPN, ToLPN or SKU */
  if (@vEntityType is null)
    set @vMessageName = 'PackingSL_InvalidEntity';
  else
  if (@vOrderType in ('RU', 'RP', 'B'))
    set @vMessageName = 'PackingSL_InvalidOrderType';
  else
  if (@vOrderStatus in ('S', 'X' /* Shipped or Cancelled */))
    set @vMessageName = 'PackingSL_InvalidOrderStatus';
  else
  if (@WaveNo is null) and (@vEntityType = 'SKU')
    set @vMessageName = 'PackingSL_IdentifyWaveToStartPacking';
  else
  if (@vWaveNo <> @vCurrWaveNo)
    set @vMessageName = 'PackingSL_ScannedEntitiesOnDifferentWave';
  else
  /* Some times, user will scan SKU which does not exists on Order, so in this case
     we need to show the error - and , when closing the order UnitsToPAck is 0, so need to consider
     UnitsScanned as well, because we will get this when we close the package */
  if (coalesce(@vUnitsToPack, 0) = 0) and (@vSKUId is not null) and (@vCurrOrderId is not null) and
     (coalesce(@vUnitsScanned, 0) = 0)
    set @vMessageName = 'PackingSL_ScannedSKUNotRequiredForOrder';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* build xml to process the entity */
/* you are still not getting the point. There are two sets of variables here
   a. Context and b. input
   Context is the current context for packing i.e. Wave, PT, FromLPN, ToLPN, SKU they will all be null to begin with.
   Input: there in only one value user would scan, but we can figure out the rest
   say user scans FromLPN then the input values are determined for Wave Only (because of mode)
   say user enters PickTicket, then input values are determined for Wave, PT
   say user enters ToLPN, then we can determine input values for Wave, PT, ToLPN

   Context and inputs are to be validated
   Context is sent from UI and sent back to UI with updated values.

   InputVars are used for display info etc.

   Think of Context as CurrentWave, CurrentOrder, CurrentFromLPN, CurrentToLPN, CurrentSKU
   say user entered FromLPN, then we determine the CurrentWave
   say now user scanned a SKU and it is assigned to a 1 unit order and so the order is packed
     - note that we don't change CurrentOrder, nor CurrentSKU - that order is complete, there is no Current Order
   say user scanned a SKU and it is assigned to a 3 unit order
     - now CurrentOrder is the given order, CurrentSKU is the SKU - because we are locking to that order and SKU

   So, we need to have two sets of values.
*/

  if (@vShowDataToPack_Mode = 'Wave') --and (@vEntityType <> 'SKU')
    begin
      select @vEntityId   = coalesce(@vCurrWaveId, @vWaveId),
             @vEntityType = 'Wave',
             @vCurrWaveNo = coalesce(@vCurrWaveNo, @vWaveNo);
    end

  /* set force close here based on the command */
  select @vForceClose = case
                          when @vCommand like '%CLOSE%' then 'Y'
                          else coalesce(@vForceClose, 'N')
                        end;

  select @vxmlInput = (select @vEntityId     as EntityId,
                              @vEntityType   as EntityType,
                              @vToLPNId      as ToLPNId,
                              @ToLPN         as ToLPN,
                              @vFromLPNId    as FromLPNId,
                              @FromLPN       as FromLPN,
                              @vCurrWaveNo   as WaveNo,
                              @vCurrPickTicket
                                             as PickTicket,
                              @vSKUId        as SKUId,
                              @vSKU          as SKU,

                              @vUnitsScanned as UnitsScanned,
                              @vPackStation  as PackStation,
                              @vForceClose   as ForceClose,
                              @vAction       as Action,
                              @vCartonType   as CartonType,
                              @vWeight       as Weight,
                              @vReturnTrackingNo
                                             as ReturnTrackingNo,
                              @vUserId       as UserId,
                              @vBusinessUnit as BusinessUnit
                       for xml raw('RootNode'), elements)

  /* If user has scanned SKU then pack the item, we should know which wave by now */
  if (@vSKU is not null) and (@vUnitsScanned > 0)
    begin
      exec pr_Packing_SL_PackItem @vxmlInput, @xmlResult output;
    end
  else
    begin
      /* Call procedure here to get the result */
      exec pr_Packing_SL_BuildResponse @vxmlInput, null /* CloseLPNOutput */, @xmlResult output;
    end

  /* insert into activitylog details */
  exec pr_ActivityLog_AddMessage 'Packing_SL', null, @vEntityValue, 'PickTicket', 'ProcessInput', @@ProcId,
                                 @xmlResult, @ActivityLogId = @vActivityLogId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_SL_ProcessInput */

Go
