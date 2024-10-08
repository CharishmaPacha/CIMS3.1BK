/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_SL_PackItem') is not null
  drop Procedure pr_Packing_SL_PackItem;
Go
/*------------------------------------------------------------------------------
  pr_Packing_SL_PackItem:
    procedure returns all details to be displayed in packing screen - write up
  proper comments on what this procedure would do

 input xml, output xml : define structures

------------------------------------------------------------------------------*/
Create Procedure pr_Packing_SL_PackItem
  (@xmlInput      TXML,
   @xmlResult     TXML = null output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @vLPNType            TTypeCode;

  declare @vCreateShipment     TFlag,
          @vPrintLabels        TFlag,
          @vPrintReports       TFlag,
          @vPrintDocuments     TFlag,

          @vToLPN              TLPN,

          @vUnitsScanned       TQuantity,
          @vPackStation        TName,
          @vBusinessUnit       TBusinessUnit,
          @vUserId             TUserId,
          @vAction             TDescription,
          @vForceClose         TFlags = null,

          @vSKUId              TRecordId,
          @vSKU                TSKU,

          @vOrderId            TRecordId,
          @vPickTicket         TPickTicket,
          @vOrderStatus        TStatus,
          @vOrderType          TTypeCode,
          @vOrderDetailId      TRecordId,
          @vUnitsRemToPack     TQuantity,
          @vWaveId             TRecordId,
          @vWaveNo             TPickBatchNo,

          @vFromLPNId          TRecordId,
          @vFromLPN            TLPN,
          @vFromLPNDetailId    TRecordId,
          @vSKUExistsInLPN     TFlags,
          @vBPTOrderId         TRecordId,

          @vPalletId           TRecordId,

          @vCartonType         TCartonType,
          @vWeight             TWeight,

          @vReturnTrackingNo
                               TTrackingNo,
          @vUnitsToPack        TQuantity,
          @vUnitsRemProcess    TQuantity,
          @vFromLPNDetailQty   TQuantity,
          @vOrderDetailUnits   TQuantity,

          @vLPNContents        TXML,
          @vOutputXML          TXML,
          @vxmlCurOrderDetails TXML,
          @vCloseLPNOutputXML  TXML,
          @vxmlInput           TXML,
          @xmlData             XML,

          @vMessage1           TDescription,
          @vDebug              TFlag,
          @vDebugRecordId      TRecordId;

  declare @xmlRulesData        TXML,
          @vRulesResult        TResult,
          @vPackingListTypesToPrint
                               TResult;
  declare @ttPackDetails table
          (SKU             TSKU,
           UnitsScanned    TQuantity,
           OrderId         TRecordId,
           OrderDetailId   TRecordId,
           FromLPNId       TRecordId,
           FromLPNDetailId TRecordId,

           Recordid        TRecordID identity(1,1));

  declare @ttOrderDetails table
          (OrderId         TRecordId,
           OrderDetailId   TRecordId,
           UnitsToAllocate TQuantity,

           SKUId           TRecordId,
           RecordId        TRecordID identity(1,1));

begin
  SET NOCOUNT ON;

  select @ReturnCode      = 0,
         @MessageName     = null,
         @vSKUExistsInLPN = 'N' /* No */,
         @vForceClose     = coalesce(@vForceClose, 'N'),
         @xmlData         = convert(xml, @xmlInput);

   /* Get the details from the xml */
  if (@xmlInput is not null)
    select @vWaveNo       = nullif(Record.Col.value('WaveNo[1]',       'TPickBatchNo'), ''),
           @vPickTicket   = nullif(Record.Col.value('PickTicket[1]',   'TPickTicket'), ''),
           @vFromLPN      = nullif(Record.Col.value('FromLPN[1]',      'TLPN'), ''),
           @vToLPN        = nullif(Record.Col.value('ToLPN[1]',        'TLPN'), ''),
           @vSKU          = nullif(Record.Col.value('SKU[1]',          'TSKU'), ''),
           @vOrderId      = nullif(Record.Col.value('OrderId[1]',      'TRecordId'), ''),
           @vUnitsScanned = nullif(Record.Col.value('UnitsScanned[1]', 'TQuantity'), ''),
           @vPackStation  = nullif(Record.Col.value('PackStation[1]',  'TName'), ''),
           @vAction       = nullif(Record.Col.value('Action[1]',       'TDescription'), ''),
           @vCartonType   = nullif(Record.Col.value('CartonType[1]',   'TCartonType'), ''),
           @vWeight       = nullif(Record.Col.value('Weight[1]',       'TWeight'), ''),
           @vReturnTrackingNo
                          = nullif(Record.Col.value('ReturnTrackingNo[1]','TTrackingNo'),''),
           @vForceClose   = nullif(Record.Col.value('ForceClose[1]',   'TFlags'), ''),
           @vBusinessUnit = nullif(Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), ''),
           @vUserId       = nullif(Record.Col.value('UserId[1]',       'TUserId'), '')
    from @xmlData.nodes('/RootNode') as Record(Col);

  /* If the user has scanned a UPC/SKU then get the valid SKUId here  */
  select top 1 @vSKU   = SKU,
               @vSKUId = SKUId
  from dbo.fn_SKUs_GetScannedSKUs(@vSKU, @vBusinessUnit);

  if (coalesce(@vPickTicket, '') <> '')
    select @vOrderId = OrderId
    from OrderHeaders
    where (PickTicket   = @vPickTicket) and
          (BusinessUnit = @vBusinessUnit);

   /* identify the next order for the scanned SKU , if user not scanned the PT */
  if ((@vOrderId is null) and (@vWaveNo is not null))
    exec pr_Packing_SL_GetNextOrderToPack @vWaveNo, @vSKUId, @vUnitsScanned, @vOrderId output;

  /* Get OrderId and its details by scanned PickTicket */
  select @vOrderId     = OrderId,
         @vPickTicket  = PickTicket,
         @vOrderStatus = Status,
         @vOrderType   = OrderType,
         @vWaveId      = PickBatchId,
         @vWaveNo      = coalesce(@vWaveNo, PickBatchNo)
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Validate input data here */
  if (@xmlInput is null)
    set @MessageName = 'InvalidPackingDetails';
  else
  if (@vOrderId is null)
    set @MessageName = 'SKUNotRequiredForAnyOrder';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* We need to check, if the user did scan from LPN, then we need to verify
     the scanned sku really exits in the LPN or not */
  if (@vFromLPN is not null)
    begin
      select @vFromLPNId = LPNId,
             @vFromLPN   = LPN,
             @vPalletId  = PalletId
      from LPNs
      where (LPN = @vFromLPN) and
            (BusinessUnit = @vBusinessUnit);

      select @vSKUExistsInLPN  = 'Y' /* Yes */ ,
             @vFromLPNDetailId = LPNDetailId,
             @vUnitsRemProcess = @vUnitsScanned - dbo.fn_MinInt(Quantity, @vUnitsScanned)
      from LPNDetails
      where (LPNId = @vFromLPNId) and
            (SKUId = @vSKUId)  and
            (OnhandStatus ='R' /* Reserved */) and
            (Quantity > 0);
    end

  /* if the caller did not send the from lpn, then identify it here */
  if (@vFromLPNId is null)
    begin
      select @vBPTOrderId      = OrderId,
             @vUnitsRemProcess = @vUnitsScanned
      from OrderHeaders
      where (PickBatchId = @vWaveId) and
            (OrderType   = 'B' /* Bulk pull */);

      /* reset value */
      select @vFromLPNDetailQty = 0;

      /* get all details which we need to pack */
      insert into @ttOrderDetails(OrderId, OrderDetailId, SKUId, UnitsToAllocate)
      select OrderId, OrderDetailId, SKUId, UnitsToAllocate
        from OrderDetails
        where (OrderId = @vOrderId) and
              (SKUId   = @vSKUId) and
              (UnitsToAllocate > 0);

      /* some times we have picked units on multiple lpns, so
        we need to smmarize the data accordingly  */
      while (@vUnitsRemProcess > 0)
        begin
          /* Get from LPN here to reduce the qty from this */
          if (@vFromLPNDetailQty = 0)
          select top 1 @vFromLPNId        = LPNId,
                       @vSKUExistsInLPN   = 'Y',
                       @vFromLPNDetailId  = LPNDetailId,
                       @vFromLPNDetailQty = Quantity
          from vwLPNDetails
          where (OrderId = @vBPTOrderId) and
                (PickBatchId = @vWaveId) and
                (OnhandStatus = 'R' /* Reserved */) and
                (LPNStatus   <> 'A' /* Allocated */) and
                (Quantity > 0) and
                (SKUId = @vSKUId) and
                (LPNDetailId not in (select FromLPNDetailId from @ttPackDetails))
          order by Quantity Desc;

          /* get top 1 detail to allocate */
          select top 1 @vOrderDetailUnits = UnitsToAllocate,
                       @vOrderDetailId    =  OrderDetailId
          from @ttOrderDetails
          where (OrderId = @vOrderId) and
                (SKUId   = @vSKUId) and
                (UnitsToAllocate > 0)

          /* Get minimum units to process */
          select @vUnitsToPack = dbo.fn_MinInt(@vFromLPNDetailQty, @vUnitsScanned);
          select @vUnitsToPack = dbo.fn_MinInt(@vUnitsToPack, @vOrderDetailUnits);

          /* There are no more UnitsToPack, exit */
          if (@vUnitsToPack = 0) break;

          insert into @ttPackDetails (SKU, UnitsScanned, OrderId, OrderDetailId,
                                      FromLPNId, FromLPNDetailId)
            select @vSKU, @vUnitsToPack, @vOrderId, @vOrderDetailId,
                   @vFromLPNId, @vFromLPNDetailId;

            /* Update orderdteail here - once those were packed then reduce it */
            update @ttOrderDetails
            set UnitsToAllocate = UnitsToAllocate - @vUnitsToPack
            where OrderDetailId = @vOrderDetailId;

          /* Update here for remaining units to process */
            select @vUnitsRemProcess  -= @vUnitsToPack,
                   @vFromLPNDetailQty -= @vUnitsToPack;
        end

      select @vPalletId = PalletId,
             @vFromLPN  = LPN
      from LPNs
      where (LPNId = @vFromLPNId);
    end

  if (@vFromLPNId is not null) and (@vSKUExistsInLPN = 'N')
    set @MessageName = 'SKUDoesNotExistsInScannedLPN';
  else
  if (@vUnitsRemProcess > 0)
    select @MessageName = 'PackingSL_PackingMoreThanPickedQty';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get remaining units to allocate for the order */
  select @vUnitsRemToPack = UnitsToAllocate,
         @vOrderDetailId  = OrderDetailId
  from OrderDetails
  where (OrderId = @vOrderId) and
        (SKUId   = @vSKUId) and
        (UnitsToAllocate > 0);

  /* Update orderdetail here to send data to close LPN */
  update @ttPackDetails
  set OrderDetailid = @vOrderDetailId
  where OrderDetailId is null;

  -- /* need to set the flag here to force close the order if scanned units is less than
  --    required */
  -- if (@vUnitsRemToPack > @vUnitsScanned)
  --   set @vForceClose = coalesce(@vForceClose, 'Y');

  /* if user wants to close the carton or order is completely packed then we need to
     call the procedure to close the lpn */
  if ((@vUnitsRemToPack = @vUnitsScanned) or (@vForceClose = 'Y' /* Yes */))
    begin
      /* build LPN content xml here */
      select @vLPNContents = '<PackingCarton>' +
                              (select SKU              SKU,
                                      UnitsScanned     UnitsPacked,
                                      OrderId          OrderId,
                                      OrderDetailId    OrderDetailId,
                                      FromLPNId        LPNId,
                                      FromLPNDetailId  LPNDetailId
                               from @ttPackDetails
                               for xml raw('CartonDetails'), elements ) +
                             '</PackingCarton>';

      /* Call procedure close packing procedure here */
      exec pr_Packing_CloseLPN @vCartonType, @vPalletId, @vFromLPNId, @vOrderId,
                               @vWeight,  null /* Volume */, @vLPNContents,
                               @vToLPN, @vReturnTrackingNo, @vPackStation,
                               @vAction, @vBusinessUnit, @vUserId, @vCloseLPNOutputXML output;
    end


  /* build xml to process the entity */
  select @vxmlInput = (select @vWaveId       as EntityId,
                              'Wave'         as EntityType,
                              @vSKUId        as SKUId,

                              @vPickTicket   as PickTicket,
                              @vForceClose   as ForceClose,
                              @vWaveNo       as WaveNo,

                              @vPickTicket   as PickTicket,
                              @vWaveNo       as WaveNo,

                              @vUserId       as UserId,
                              @vBusinessUnit as BusinessUnit
                       for xml raw('RootNode'), elements)

  /* Call procedure here to get partially packed order details to continue, we
    need to send this info to UI */
  exec pr_Packing_SL_BuildResponse @vxmlInput, @vCloseLPNOutputXML, @xmlResult output;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Packing_SL_PackItem */

Go
