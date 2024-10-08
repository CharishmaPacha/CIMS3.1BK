/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/02/16  TK      pr_RFC_Packing_StartPackage: Return Packed LPN Contents in result xml (FB-619)
  2016/02/01  TK      pr_RFC_Packing_StartPackage: Enhanced to meet NON-VAS Packing requirements (FB-614)
  2016/01/20  TK      pr_RFC_Packing_StartPackage & pr_RFC_Packing_ClosePackage: Final Revision
  2015/12/10  TK      pr_RFC_Packing_StartPackage: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Packing_StartPackage') is not null
  drop Procedure pr_RFC_Packing_StartPackage;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Packing_StartPackage: This procedure validates Scanned PickTicket and LPN,
     On success we will return the SKUs to be packed along with options.

    @xmlInput XML Structure:
    <STARTPACKAGE>
      <PickTicket></PickTicket>
      <LPN></LPN>
      <PackFrom></PackFrom>
      <CartonType></CartonType>
      <Action>RFPacking</Action>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
      <Warehouse></Warehouse>
      <UserId></UserId>
    </STARTPACKAGE>

    @xmlOutput XML Structure:
    <PACKAGEDETAILS>
      <PickTicket></PickTicket>
      <LPN></LPN>
      <CartonType></CartonType>
      <ORDERCONTENTS>
        <SKUDETAILS>
          <SKU></SKU>
          <SKU1></SKU1>
          <SKU2></SKU2>
          <SKU3></SKU3>
          <SKU4></SKU4>
          <SKU5></SKU5>
          <UPC></UPC>
          <LPNId></LPNId>
          <LPNDetailId></LPNDetailId>
          <OrderId></OrderId>
          <OrderDetailId></OrderDetailId>
          <UnitsAuthorizedToShip></UnitsAuthorizedToShip>
          <UnitsToPack></UnitsToPack>
          <UnitsPacked></UnitsPacked>
        </SKUDETAILS>
        .......
        .......
        <SKUDETAILS>
          <SKU></SKU>
          <SKU1></SKU1>
          <SKU2></SKU2>
          <SKU3></SKU3>
          <SKU4></SKU4>
          <SKU5></SKU5>
          <UPC></UPC>
          <LPNId></LPNId>
          <LPNDetailId></LPNDetailId>
          <OrderId></OrderId>
          <OrderDetailId></OrderDetailId>
          <UnitsAuthorizedToShip></UnitsAuthorizedToShip>
          <UnitsToPack></UnitsToPack>
          <UnitsPacked></UnitsPacked>
        </SKUDETAILS>
      </ORDERCONTENTS>
      <PACKEDCARTONCONTENTS>
        <CARTONDETAILS>
          <SKU></SKU>
          <UPC></UPC>
          <Qty></Qty>
        <CARTONDETAILS>
      </PACKEDCARTONCONTENTS>
      <SUMMARY>
        <UnitsInCarton></UnitsInCarton>
        <NumSKUsInCarton></NumSKUsInCarton>
      </SUMMARY>
      <OPTIONS>
        <DefaultQty>0</DefaultQty>
        <EnableQty>Y</EnableQty>
        <CaptureWeight>Y</CaptureWeight>
      </OPTIONS>
    </PACKAGEDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Packing_StartPackage
  (@xmlInput       xml,
   @xmlResult      xml   output)
As
  declare @PickTicket          TPickTicket,
          @vPickTicket         TPickTicket,
          @vPTType             TTypeCode,
          @vPTStatus           TStatus,
          @vPTWH               TWarehouse,
          @vOrderId            TRecordId,
          @vDisplayPT          TPickTicket,

          @vWaveId             TRecordId,
          @vWaveType           TTypeCode,
          @vWaveDropLoc        TLocation,

          @vPackFrom           TLPN,
          @LPN                 TLPN,
          @vToLPN              TLPN,
          @vToLPNId            TRecordId,
          @vToLPNStatus        TStatus,
          @vToLPNQty           TQuantity,
          @vToLPNOrderId       TRecordId,
          @vToLPNWH            TWarehouse,
          @CartonType          TCartonType,

          @vCartPosId          TRecordId,
          @vCartPosOrderId     TRecordId,
          @vCartPosStatus      TStatus,
          @vCartPosPickTicket  TPickTicket,

          @PackFrom            TLPN,
          @vFromLocationId     TRecordId,
          @vPalletId           TRecordId,

          @vControlCategory    TCategory,

          @vDefaultQty         TControlValue,
          @vQtyEnabled         TControlValue,
          @vCaptureWeight      TControlValue,

          @vNumSKUsInCarton    TInteger,
          @vNumUnitsInCarton   TInteger,

          @vValidLPNStatuses   TControlValue,
          @vValidPTStatuses    TControlValue,

          @BusinessUnit        TBusinessUnit,
          @UserId              TUserId,
          @DeviceId            TDeviceId,
          @Warehouse           TWarehouse,

          @vMessageName        TMessageName,
          @vReturnCode         TInteger,
          @vActivityLogId      TRecordId,

          @xmlSKUDetails       TXML,
          @xmlOptions          TXML,
          @vPackingCriteria    TXML,
          @xmlSummary          TXML,
          @xmlPackedLPNContents TXML;

  declare @ttNameValuePairs    TNameValuePairs;

  declare  @ttOrderContents table (SKUId          TRecordId,
                                   SKU            TSKU,
                                   SKU1           TSKU,
                                   SKU2           TSKU,
                                   SKU3           TSKU,
                                   SKU4           TSKU,
                                   SKU5           TSKU,

                                   UPC            TUPC,

                                   LPNId          TRecordId,
                                   LPNDetailId    TRecordId,

                                   OrderId        TRecordId,
                                   OrderDetailId  TRecordId,

                                   UnitsAuthorizedToShip
                                                  TQuantity,
                                   UnitsToPack    TQuantity,
                                   UnitsPacked    TQuantity,

                                   RecordId       TRecordId identity(1, 1));

  declare @ttPackedLPNContents table (SKU       TSKU,
                                      UPC       TUPC,
                                      Qty       TQuantity,

                                      RecordId  TRecordId identity(1, 1));

begin /* pr_RFC_Packing_StartPackage */
begin try
  SET NOCOUNT ON;

  /* Get the XML User inputs into the local variables */
  select @PickTicket   = Record.Col.value('PickTicket[1]'           , 'TPickTicket'),
         @LPN          = Record.Col.value('LPN[1]'                  , 'TLPN'),
         @PackFrom     = nullif(Record.Col.value('PackFrom[1]'      , 'TLPN'), ''),
         @CartonType   = nullif(Record.Col.value('CartonType[1]'    , 'TCartonType'), ''),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]'         , 'TBusinessUnit'),
         @Warehouse    = Record.Col.value('Warehouse[1]'            , 'TWarehouse'),
         @UserId       = Record.Col.value('UserId[1]'               , 'TUserId'),
         @DeviceId     = Record.Col.value('DeviceId[1]'             , 'TDeviceId')
  from @xmlInput.nodes('STARTPACKAGE') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @BusinessUnit, @UserId, @DeviceId, @@ProcId,
                      @vOrderId, @PickTicket, 'Order', @Value1 = @PackFrom, @Value2 = @LPN,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* get the scanned LPN details */
  select @vToLPNId      = LPNId,
         @vToLPN        = LPN,
         @vToLPNStatus  = Status,
         @vToLPNOrderId = OrderId,
         @vToLPNWH      = DestWarehouse,
         @vToLPNQty     = Quantity
  from LPNs
  where ((LPN          = @LPN        ) or
         (UCCBarcode   = @LPN        ) or
         (TrackingNo   = @LPN        )) and
        (BusinessUnit = @BusinessUnit);

  /* get the Pack From details
     Pack From: It would be a Picking cart position or a Bulk Drop Location
     I. If user scans cart position, we would verify whether the cart position is associated with the PT or not.
          If yes, then we would Pass in OrderId and PalletId get Packing Details
     II. If user scans BulkDrop Location, we would validate if the scanned PT's drop Location is same
           as scanned Location or not. If yes, we would pass in OrderId and get Packing Details */
  if (@PackFrom is not null)
    begin
      /* Check if it is a Location */
      select @vFromLocationId = LocationId,
             @vPackFrom       = Location
      from Locations
      where (Location     = @PackFrom    ) and
            (BusinessUnit = @BusinessUnit);

      /* if PackFrom is not location, then see if the user scanned a Cart */
      if (@vFromLocationId is null)
        begin
          select @vPackFrom          = LPN,
                 @vCartPosId         = LPNId,
                 @vPalletId          = PalletId,
                 @vCartPosStatus     = Status,
                 @vCartPosOrderId    = OrderId,
                 @vCartPosPickTicket = PickTicket
          from vwLPNs
          where (LPN          = @PackFrom    )and
                (BusinessUnit = @BusinessUnit);
        end
    end

  /* If PT is given by user, use it, else use the PT of the cart position */
  select @vPickTicket = coalesce(@PickTicket, @vCartPosPickTicket);

  /* get the scanned PickTicket details */
  select @vOrderId     = OrderId,
         @vPickTicket  = PickTicket,
         @vPTType      = OrderType,
         @vPTStatus    = Status,
         @vWaveId      = PickBatchId,
         @vDisplayPT   = PickBatchNo + '/' + PickTicket,
         @vPTWH        = Warehouse
  from OrderHeaders
  where (PickTicket   = @vPickTicket ) and
        (BusinessUnit = @BusinessUnit);

  /* get the Wave Details */
  select @vWaveType    = BatchType,
         @vWaveDropLoc = DropLocation
  from PickBatches
  where (RecordId = @vWaveId);

  /* create the return table from vwOrderToPackDetails structure */
  select * into #PackingDetails from vwOrderToPackDetails where 1 = 2;

  /* set the control category */
  select @vControlCategory = 'RFPacking_' + @vWaveType;

  /* get the control values */
  select @vValidLPNStatuses = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidLPNStatusToPack', 'NKGD'/* New, Picked, Packing, Packed */,
                                                          @BusinessUnit, @UserId),
         @vValidPTStatuses  = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidPTStatusToPack', 'WAP'/* Waved, Allocated, Picked */,
                                                          @BusinessUnit, @UserId),
         @vDefaultQty       = dbo.fn_Controls_GetAsString(@vControlCategory, 'DefaultQty', '0',
                                                          @BusinessUnit, @UserId),
         @vQtyEnabled       = dbo.fn_Controls_GetAsString(@vControlCategory, 'QtyEnabled?', 'Y'/* Yes */,
                                                          @BusinessUnit, @UserId),
         @vCaptureWeight    = dbo.fn_Controls_GetAsString(@vControlCategory, 'CaptureWeight?', 'N'/* No */,
                                                          @BusinessUnit, @UserId);

  /* Validations */
  if (@vToLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vOrderId is null)
    set @vMessageName = 'PickTicketDoesNotExist';
  else
  /* If packing from Location, then ensure it is the correct location i..e check whether scanned PT drop Lcoation is same as scanned */
  if (@vFromLocationId is not null) and (@vWaveDropLoc <> @vPackFrom)
    set @vMessageName = 'RFPack_InventoryInScannedLocIsNotForScannedPT';
  else
  if ((@vToLPNWH not in (select TargetValue
                         from dbo.fn_GetMappedValues('CIMS', @Warehouse,'CIMS', 'Warehouse', 'RFPacking', @BusinessUnit))))
     or
     ((@vPTWH not in (select TargetValue
                      from dbo.fn_GetMappedValues('CIMS', @Warehouse,'CIMS', 'Warehouse', 'RFPacking', @BusinessUnit))))
    set @vMessageName = 'RFPack_LPN/PickTicketWarehouseMismatch';
  else
  if (@vPTType = 'B'/* Bulk */)
    set @vMessageName = 'RFPack_InvalidOrderType';
  else
  if (charindex(@vToLPNStatus, @vValidLPNStatuses) = 0)
    set @vMessageName = 'RFPack_InvalidLPNStatus';
  else
  if (charindex(@vPTStatus, @vValidPTStatuses) = 0)
    set @vMessageName = 'RFPack_InvalidPickTicketStatus';
  else
  if (@vToLPNQty > 0) and (@vToLPNStatus = 'N'/* New */)
    set @vMessageName = 'RFPack_UseEmptyLPN/AssignedLPN';
  else
  if (@vToLPNOrderId is not null) and (@vToLPNOrderId <> @vOrderId)
    set @vMessageName = 'RFPack_ScannedLPNIsAssociatedWithDiffOrder';
  else
  if (@PackFrom is not null) and (@vPackFrom is null)
    set @vMessageName = 'RFPack_InvalidPackFrom';
  else
  if (@vCartPosOrderId is not null) and (@vCartPosOrderId <> @vOrderId)
    set @vMessageName = 'RFPack_ScannedPosIsNotAssociatedWithScannedPT';
  else
  if (@vCartPosStatus is not null) and (@vCartPosStatus not in ('K','G' /* Picked, Packing */))
    set @vMessageName = 'RFPack_InvalidCartPosStatus';
  else
  if (@vPackFrom is null) and
     (not exists(select *
                 from OrderHeaders
                 where (PickBatchId = @vWaveId) and (OrderType = 'B'/* Bulk */)))
    set @vMessageName = 'RFPack_PackFromIsMandatory';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Build the packing criteria */
  insert into @ttNameValuePairs
    select 'ORDERID', @vOrderId
    union
    select 'PALLETID', @vPalletId;

  /* Build I/P xml to get packing details */
  set @vPackingCriteria = dbo.fn_XMLNode('InputParams', (select FieldName  as Name,
                                                                FieldValue as Value
                                                          from @ttNameValuePairs
                                                          FOR XML raw('ParamInfo'), elements));

  /* insert packing details into a temp table */
  insert into #PackingDetails
    exec pr_Packing_GetDetailsToPack @vPackingCriteria;

  /* If GetDetailsToPack returns nothing then exit throwing an error message */
  if (@@rowcount = 0)
    begin
      set @vMessageName = 'RFPack_NothingToPackAgainstScannedPT';
      goto ErrorHandler;
    end

  /* there may be some units already packed in the LPN, compute Units to be packed */
  insert into @ttOrderContents
    select PD.SKUId, PD.SKU, PD.SKU1, PD.SKU2, PD.SKU3, PD.SKU4, PD.SKU5, PD.UPC,
           PD.LPNId, PD.LPNDetailId, PD.OrderId, PD.OrderDetailId,
           PD.UnitsAuthorizedToShip, PD.PickedQuantity as UnitsToPack,
           coalesce(LD.Quantity, 0) as UnitsPacked
    from #PackingDetails PD
      left outer join LPNDetails LD on (LD.LPNId         = @vToLPNId       ) and
                                       (PD.OrderDetailId = LD.OrderDetailId);

  /* get the Packed LPN Contents */
  insert into @ttPackedLPNContents(SKU, UPC, Qty)
    select SKU, UPC, Quantity
    from vwLPNDetails
    where (LPNId = @vToLPNId);

  /* compute the summary values of scanned LPN */
  select @vNumSKUsInCarton  = count(distinct SKUId),
         @vNumUnitsInCarton = sum(Quantity)
  from LPNDetails
  where (LPNId = @vToLPNId) and
        (Quantity > 0     ) and
        (OnHandStatus = 'R'/* Reserved */);

  /* Build inner XMLs */
  set @xmlSKUDetails = (select *
                        from @ttOrderContents
                        for XML raw('SKUDETAILS'), elements );

  set @xmlPackedLPNContents = (select *
                               from @ttPackedLPNContents
                               for XML raw('CARTONDETAILS'), elements)

  set @xmlSummary = (select coalesce(@vNumUnitsInCarton, 0) as UnitsInCarton,
                            coalesce(@vNumSKUsInCarton, 0)  as NumSKUsInCarton
                     for XML raw('SUMMARY'), elements);

  set @xmlOptions = (select @vDefaultQty    as  DefaultQty,
                            @vQtyEnabled    as  EnableQty,
                            @vCaptureWeight as  CaptureWeight
                     for XML raw('OPTIONS'), elements );

  /* Build XML Result */
  set @xmlResult = (select '<PACKAGEDETAILS>' +
                               dbo.fn_XMLNode('PickTicket'    ,  @vDisplayPT) +
                               dbo.fn_XMLNode('LPN'           ,  @vToLPN) +
                               dbo.fn_XMLNode('CartonType'    ,  @CartonType) +
                               dbo.fn_XMLNode('ORDERCONTENTS' ,  @xmlSKUDetails) +
                               dbo.fn_XMLNode('PACKEDCARTONCONTENTS' ,  @xmlPackedLPNContents) +
                               coalesce(@xmlSummary,  '') +
                               coalesce(@xmlOptions, '') +
                           '</PACKAGEDETAILS>');

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the Result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the Error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

end catch;
end /* pr_RFC_Packing_StartPackage */

Go
