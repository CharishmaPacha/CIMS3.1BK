/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_SL_BuildResponse') is not null
  drop Procedure pr_Packing_SL_BuildResponse;
Go
/*------------------------------------------------------------------------------
  pr_Packing_SL_BuildResponse:
    procedure returns all details to be displayed in packing screen

------------------------------------------------------------------------------*/
Create Procedure pr_Packing_SL_BuildResponse
  (@xmlInput       TXML,
   @xmlCloseLPN    TXML = null,
   @xmlResult      TXML = null output)
as
  declare @vReturnCode      TInteger,

          @vSKUId           TRecordId,
          @vSKU             TSKU,
          @vToLPN           TLPN,
          @vFromLPN         TLPN,
          @vOrderId         TRecordId,
          @vWaveNo          TPickBatchNo,
          @vPickTicket      TPickTicket,
          @vEntityId        TRecordId,
          @vEntityType      TEntity,
          @vUnitsScanned    TQuantity,
          @vBusinessUnit    TBusinessUnit,
          @vUserId          TUserId,
          @vIsWeightOrCartonReq
                            TFlags,
          @vOperationStatus TFlags,

          @xmlSKUDtlsToPack TXML,
          @xmlContext       TXML,

          @vNumPackedOrders TCount,
          @vNumUnitsPacked  TQuantity,
          @vNumSKUsPacked   TCount,

          @vForceClose      TFlags,

          @xmlOrderDtls     TXML,
          @xmlData          xml,
          @xmlOptions       TXML,
          @xmlWaveInfo      TXML,
          @xmlInstructions  TXML,
          @xmlNotifications TXML,
          @xmlErrors        TXML,
          @vMessageName     TMessage;

  declare @ttOrderDetailsToPack table (RecordId       TRecordId identity (1,1),
                                       OrderId        TRecordId,
                                       PickTicket     TPickTicket,
                                       SalesOrder     TSalesOrder,
                                      -- OrderDetailId  TRecordId,
                                      -- Palletid       TRecordId,
                                      -- Pallet         TPallet,
                                      -- LPNId          TRecordId,
                                      -- LPN            TLPN,
                                       SKUId          TRecordId,
                                       SKU            TSKU,
                                       SKU1           TSKU,
                                       SKU2           TSKU,
                                       SKU3           TSKU,
                                       SKU4           TSKU,
                                       SKU5           TSKU,
                                       UPC            TUPC,
                                       UnitWeight     TFloat,
                                       Description    TDescription,
                                       Quantity       TQuantity,
                                       PickedBy       TUserId,
                                       Ownership      TOwnership,
                                       ReferenceLocation
                                                      TLocation,
                                       UDF1           TUDF,
                                       UDF2           TUDF,
                                       UDF3           TUDF,
                                       UDF4           TUDF,
                                       UDF5           TUDF);
begin
  select @vReturnCode  = 0,
         @vMessageName = null,
         @xmlData      = convert(xml, @xmlInput);

   /* Get the data from the Inputxml */
  if (@xmlInput is not null)
      select @vEntityId     = nullif(Record.Col.value('EntityId[1]',     'TRecordId'),''),
             @vEntityType   = nullif(Record.Col.value('EntityType[1]',   'TEntity'), ''),
             @vWaveNo       = nullif(Record.Col.value('WaveNo[1]',       'TPickBatchNo'), ''),
             @vPickTicket   = nullif(Record.Col.value('PickTicket[1]',   'TPickTicket'), ''),
             @vFromLPN      = nullif(Record.Col.value('FromLPN[1]',      'TLPN'), ''),
             @vToLPN        = nullif(Record.Col.value('ToLPN[1]',        'TLPN'), ''),
             @vOrderId      = nullif(Record.Col.value('OrderId[1]',      'TRecordId'), ''),
             @vSKUId        = nullif(Record.Col.value('SKUId[1]',        'TRecordId'), ''),
             @vUnitsScanned = nullif(Record.Col.value('UnitsScanned[1]', 'TQuantity'), ''),
             @vForceClose   = nullif(Record.Col.value('ForceClose[1]',   'TFlags'), ''),
             @vBusinessUnit = nullif(Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), ''),
             @vUserId       = nullif(Record.Col.value('UserId[1]',       'TUserId'), '')
      from @xmlData.nodes('/RootNode') as Record(Col);

  if (@xmlInput is null)
    set @vMessageName = 'InvalidInput';
  else
  if (coalesce(@vEntityId, 0) = 0)
    set @vMessageName = 'EntityCannotBeNull';
  else
  if (coalesce(@vEntityType, '') = '')
    set @vMessageName = 'InvalidEntityType';

  if (@vMessageName is not null)
    goto ErrorHandler;

  select @vSKU = SKU
  from SKUs
  where (SKUId = @vSKUId);

  /* get all SKUs and qty that is available to pack */
  insert into @ttOrderDetailsToPack (SKUId, Quantity, Ownership, ReferenceLocation)
    select S.SKUId, sum(LD.Quantity), min(OH.Ownership), min(L.Location)
    from LPNDetails LD
      join LPNs         L  on (LD.LPNId  = L.LPNId)
      join OrderHeaders OH on (L.OrderId = OH.OrderId)
      join SKUs         S  on (LD.SKUId  = S.SKUId)
    where (OH.OrderType   = 'B' /* BPT */) and
          (L.Status       in ('K', 'G') /* Picked,Packing */) and
          (OH.PickBatchNo = @vWaveNo) and
          (
           ((@vEntityType = 'Wave') and (OH.PickBatchId = @vEntityId)) or
           ((@vEntityType = 'PickTicket') and (OH.OrderId = @vEntityId)) or
           ((@vEntityType = 'LPN') and (L.LPNId = @vEntityId))
          )
  group by S.SKUId;

  /* Update with SKU details */
  update TODP
  set TODP.SKU         = S.SKU,
      TODP.SKU1        = S.SKU1,
      TODP.SKU2        = S.SKU2,
      TODP.SKU3        = S.SKU3,
      TODP.SKU4        = S.SKU4,
      TODP.SKU5        = S.SKU5,
      TODP.UPC         = S.UPC,
      TODP.Description = S.Description,
      TODP.UnitWeight  = S.UnitWeight
  from @ttOrderDetailsToPack TODP
    join SKUs         S  on TODP.SKUId = S.SKUId;

  /* Build xml here to send back the result to UI for the remiaing untis
     avaiable */
  select  @xmlSKUDtlsToPack = (select *
  from @ttOrderDetailsToPack
  FOR XML RAW ('SKUPackingDetail'), ROOT ('SKUPackingDetails'), ELEMENTS XSINIL);

  /* $$$ Next order to pack is determined in Pack Item - so we just have to get the
         details of the order here and these two if statements here are unnecessary */
  /* if user is scanning first time then we need to get the next order to pack */
  if (@vPickTicket is not null)
    begin
      select @vOrderId = OrderId
      from OrderHeaders
      where (PickTicket   = @vPickTicket) and
            (BusinessUnit = @vBusinessUnit);
    end
  else    /* if the user scans SKU at first time, then we need to find out the
    order which we need to pack */
  if (@vOrderId is null) and (@vSKUId is not null)
    begin
      select top 1 @vOrderId    = OrderId,
                   @vPickTicket = PickTicket
      from vwOrderDetails
      where (PickBatchNo = @vWaveNo) and
            (SKUId = @vSKUId) and
            (UnitsToAllocate > 0) and
            (OrderType not in ('B', 'RU', 'RP')) and
            (Status not in ('S', 'X' /* Shipped or Canceled */))
      order by CreatedDate;
    end

  /* call procedure here to get the current order details / next order to pack */
  exec pr_Packing_SL_GetCurrentOrderInfo @vWaveNo, @vOrderId, @vSKUId, @xmlOrderDtls output;

  /* if there is no unitstoallocate then the Order is packed, else in Packing.
     Also, if there are no more units, then clear the PickTicket and SKU in the current context */
  select @vOperationStatus = case
                               when UnitsToAllocate = 0 or @vForceClose = 'Y' then 'Packed'
                               else 'Packing'
                             end,
         @vPickTicket      = case
                               when UnitsToAllocate = 0 or @vForceClose = 'Y' then null
                               else @vPickTicket
                             end,
         @vSKU             = case
                               when UnitsToAllocate = 0 or @vForceClose = 'Y' then null
                               else @vSKU
                             end
  from OrderDetails
  where (OrderId               = @vOrderId) and
        (SKUId                 = @vSKUId) and
        (UnitsAuthorizedToShip > 0);

  /* If user scans anything , just return back it  */
  select @xmlContext = (select @vWaveNo     as WaveNo,
                               @vPickTicket as PickTicket,
                               @vFromLPN    as FromLPN,
                               @vToLPN      as ToLPN,
                               @vSKU        as SKU
                        for xml raw('Context'), elements XSINIL);

  /* Need to send options if we need to send any thing */
  select @xmlOptions = (select @vIsWeightOrCartonReq as IsWeightOrCartonReq,
                               @vOperationStatus     as OperationStatus
                        for xml raw('Options'), elements XSINIL);

  /* Get other details for the wave here  - Order status - Packed, staged, loaded, shipped */
  select @vNumPackedOrders = sum(case when Status in ('K','G','L','S') /* Packed */then 1 else 0 end),
         @vNumUnitsPacked  = sum(UnitsAssigned)
  from OrderHeaders
  where (PickBatchNo = @vWaveNo) and
        (BusinessUnit = @vBusinessUnit) and
        (OrderType <> 'B');

  /* get packed sku count here for the wave
    if UnitsToallocate =0 means, that was completely packed,
    some times, the order may have comment SKUs, we do not include that   */
  select @vNumSKUsPacked   = count(distinct SKUId)
  from vwOrderdetails
  where ((PickBatchNo = @vWaveNo) and
         (BusinessUnit = @vBusinessUnit) and
         (UnitsToAllocate = 0) and
         (UnitsAssigned > 0) and
         (OrderType <> 'B'))

  /* Build Wave xml info */
  select @xmlWaveInfo = (select BatchTypeDesc     as WaveType,
                                BatchNo           as WaveNo,
                                NumLPNs           as NumLPNs,
                                NumOrders         as NumOrders,
                                NumUnits          as NumUnits,
                                NumSKUs           as NumSKUs,
                                @vNumPackedOrders as NumOrdersPacked,
                                @vNumSKUsPacked   as NumSKUsPacked,
                                @vNumUnitsPacked  as NumUnitsPacked
                         from vwPickBatches
                         where (BatchNo = @vWaveNo) and
                               (BusinessUnit = @vBusinessUnit)
                         for xml raw('WaveDisplayInfo'), elements XSINIL);

  /* Build out put xml here  */
  select @xmlResult = '<SLOrderPackingInfo>' +
                         coalesce(@xmlOrderDtls, '')     +
                         coalesce(@xmlSKUDtlsToPack, '') +
                         coalesce(@xmlContext, '')  +
                         coalesce(@xmlOptions, '')       +
                         coalesce(@xmlWaveInfo, '')      +
                         coalesce(@xmlCloseLPN, '')      +
                         coalesce(@xmlInstructions, '')  +
                         coalesce(@xmlNotifications, '') +
                         coalesce(@xmlErrors, '') +
                      '</SLOrderPackingInfo>';
ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_SL_BuildResponse */

Go
