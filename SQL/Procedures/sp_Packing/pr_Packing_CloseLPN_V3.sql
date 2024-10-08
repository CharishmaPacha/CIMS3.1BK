/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/24  OK      pr_Packing_CloseLPN_V3, pr_Packing_CloseLPN: Changes to include PickTicket in success message notification (FBV3-1075)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_CloseLPN_V3') is not null
  drop Procedure pr_Packing_CloseLPN_V3;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_CloseLPN_V3:
    ToLPN: Is the LPN being packed - which could be new or existing. If null,
           we would generate a new ToLPN.
    Weight, Volume: ..

    #PackDetails: TPackDetails - is populated with the SKU+qty that is being
                  packed.

  The output of CloseLPN will now be an XML that has all the info to print the
  required documents (labels and reports) when the carton is closed. The format
  of the XML will be:

  <PackingCloseLPN>
      <LPNInfo>
          <LPN>C000000000</LPN>
          <Carrier>UPS/FedEx/LTL</Carrier>
          <ShipVia>UPS1</ShipVia>
          <CartonType>AA</CartonType>
          <CartonTypeDesc>UPS Letter</CartonTypeDesc>
          <Weight>12.3</Weight>
          <TrackingNo>1Z00000000</TrackingNo>
          <UCCBarcode>000000000000012</UCCBarcode>
      </LPNInfo>
      <ActionsToPerform>
          <CreateShipment>Y/N</CreateShipment>
          <PrintLabels>Y/N</PrintLabels>
          <PrintReport>Y/N</PrintReport>
      </ActionsToPerform>
      <LabelsToPrint>
          <Label>
              <LabelFormat>ShipLabel.btw</LabelFormat>
              <Printer>ZebraXYZ</Printer>
              <Copies>1</Copies>
          </Label>
          <Label>...</Label>
          ...
      </LabelsToPrint>
      <ReportsToPrint>
          <Report>
              <ReportFormat>....</ReportFormat>
              <ReportType>LPN/ORD</ReportType>
              <Copies>1</Copies>
          </Report>
          <Report>...</Report>
          ...
      </ReportsToPrint>
      <DocumentsToPrint>
          <Document>
              <DocumentName>....</DocumentName>
              <Copies>1</Copies>
          </Document>
          <Document>...</Document>
          ...
      </DocumentsToPrint>
      <Messages>
          <Line1>Carton XYZ packed... </Line1>
          <Line2>TrackingNo..., CartonType:.. Weight: </Line2>
          <Line3>Detailed error if needed ... </Line3>
      </Messages>
  </PackingCloseLPN>
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_CloseLPN_V3
  (@CartonType        TCartonType,
   @PalletId          TRecordId,
   @FromLPNId         TRecordId = null,
   @OrderId           TRecordId,
   @Weight            TWeight,
   @Volume            TVolume,
   @LPNContents       varchar(max),
   @ToLPN             TLPN,
   @ReturnTrackingNo  TTrackingNo = null,
   @PackStation       TName,
   @Action            TAction,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @OutputXML         TXML          output)
as
  declare @ReturnCode             TInteger,
          @MessageName            TMessageName,
          @vLPNType               TTypeCode,
          @vOrderStatus           TStatus,
          @vNewOrderStatus        TStatus,
          @vLPNContents           XML,
          @vBulkOrderId           TRecordId,
          @vBulkOrderDetailId     TRecordId,
          @FirstLPNIdCarton       TRecordId,
          @vRecordId              TRecordId,
          @vToLPN                 TLPN,
          @vToLPNId               TRecordId,
          @vToLPNStatus           TStatus,
          @vToLPNNewStatus        TStatus,
          @vToLPNOrderId          TRecordId,
          @vToLPNDetailId         TRecordId,
          @vToLPNUCCBarcode       TBarcode,
          @vPalletId              TRecordId,
          @vPallet                TPallet,
          @vToLPNQty              TQuantity,
          @vToLPNCartonType       TCartonType,
          @vOldCartonData         TDescription,
          @vNewCartonData         TDescription,
          @vNewLPNQty             TQuantity,
          @vLD_ReferenceLocation  TLocation,
          @vOwnership             TOwnership,
          @vWarehouse             TWarehouse,
          @vFromLPNId             TRecordId,
          @vFromLPNStatus         TStatus,
          @vFromLPNNewStatus      TStatus,
          @vFromLPNQuantity       TQuantity,
          @vFromLPNDetailId       TRecordId,
          @vSKU                   TSKU,
          @vSKUId                 TRecordId,
          @vQuantity              TQuantity,
          @vOrderId               TRecordId,
          @vPickTicket            TPickTicket,
          @vAccount               TCustomerId,
          @vShipVia               TShipVia,
          @vXmlData               TXML,
          @vCarrier               TCarrier,
          @vCarrierType           TCarrier,
          @vIsSmallPackageCarrier TFlag,
          @vIsShipCartonActivated TFlag,
          @vOrderDetailId         TRecordId,
          @vLineType              TFlag,
          @vPackDetailcount       TCount,
          @vPackSKUCount          TCount,
          @vPackedQuantity        TQuantity,
          @vPrevPackedQty         TQuantity,
          @vUnitsToPack           TQuantity,
          @vPickBatchNo           TPickBatchNo,
          @vPickBatchId           TRecordId,
          @vSoldToId              TCustomerId,
          @vShipToId              TShipToId,
          @vShipToAddressRegion   TAddressRegion,
          @vMessageName           TMessageName,
          @vSerialNo              TSerialNo,
          @vAutoShipCarriers      TControlValue,
          @vCartonType            TCartonType,
          @vCartonTypeDesc        TDescription,
          @vCartonVolume          TFloat,
          @vLabelCopies           TVarchar,
          @vPackageSeqNo          TInteger,
          @vUCCBarcode            TBarcode,
          @vUCCBarcodeSeq         TBarcode,
          @vTrackingNo            TTrackingNo,
          @vRefLocation           TLocation,
          @vLabelFormatName       TName,
          @vPickedBy              TUserId,
          @vPickedDate            TDateTime,
          @vPackedDate            TDateTime,
          @vPrinter               TName,
          @vLPNsAssigned          TCount,
          @vLPNShipmentId         TShipmentId,
          @vLPNLoadId             TLoadId,
          @vToLPNActualWeight     TWeight,
          @vPrintOrdPackingList   TFlag,
          @vPrintPackingLabels    TFlag,
          @vAuditActivity         TActivityType,
          @vMessage               TMessage,
          @vShipError             TMessage,
          @vLPNValue              TMoney,
          @vDepartment            TUDF,
          @vOHUDF1                TUDF,
          @vOHUDF2                TUDF,
          @vOHUDF3                TUDF,
          @vOHUDF4                TUDF,
          @vOHUDF5                TUDF,
          @vOHUDF6                TUDF,
          @vOHUDF7                TUDF,
          @vOHUDF8                TUDF,
          @vOHUDF9                TUDF,
          @vOHUDF10               TUDF;

  declare @vCreateShipment        TFlag,
          @vPrintLabels           TFlag,
          @vPrintReports          TFlag,
          @vPrintDocuments        TFlag,

          @vLPNInfoxml            TXML,
          @vActionsxml            TXML,
          @vLabelsxml             TXML,
          @vReportsxml            TXML,
          @vDocumentsxml          TXML,
          @vMessagesXML           TXML,
          @vOutputxml             TXML,
          @vCreateShipmentxml     TXML,

          @vMessage1              TDescription,
          @vDebug                 TFlag,
          @vDebugRecordId     TRecordId;

  declare @xmlRulesData           TXML,
          @vRulesResult           TResult,
          @vPackingListTypesToPrint
                                  TResult,
          @vCarrierPackagingType  varchar(max);

  declare @ttMarkers              TMarkers,
          @PackDetails            TPackDetails;

begin
  SET NOCOUNT ON;
begin try
  select @vDebug = dbo.fn_Controls_GetAsString('Packing', @Action, 'Y', @BusinessUnit, @UserId);

  if (charindex('Y', @vDebug) > 0)
    begin
      insert into DebugPacking (CartonType, PalletId, OrderId, Weight, Volume, LPNContents, ToLPN, PackStation, Action, BusinessUnit, UserId, OutputXML)
        select @CartonType, @PalletId, @OrderId, @Weight, @Volume, @LPNContents, @ToLPN, @PackStation, @Action, @BusinessUnit, @UserId, @OutputXML;
      select @vDebugRecordId = SCOPE_IDENTITY();

      insert into @ttMarkers (Marker) select 'Close LPN Start';
   end;

begin transaction
  select @ReturnCode    = 0,
         @MessageName   = null,
         @vLPNType      = 'S', /* Ship Carton */
         @vLPNContents  = convert(xml, @LPNContents),
         @vPackageSeqNo = null,
         @vLPNInfoxml   = '',
         @vActionsxml   = '',
         @vLabelsxml    = '',
         @vReportsxml   = '',
         @vDocumentsxml = '',
         @vMessagesxml  = '',
         @vShipError    = '';

  select @vCartonType           = CartonType,
         @vCartonTypeDesc       = Description,
         @vCartonVolume         = OuterVolume,
         @vCarrierPackagingType = CarrierPackagingType
  from CartonTypes with (NOLOCK)
  where (CartonType = @CartonType) and (Status = 'A' /* Active */) and (BusinessUnit = @BusinessUnit);

  select @vOrderId        = OrderId, /* Inialize the order id with passed in Order Id */
         @vPickBatchId    = PickBatchId,
         @vPickBatchNo    = PickBatchNo,
         @vSoldToId       = SoldToId,
         @vShipToId       = ShipToId,
         @vShipVia        = ShipVia,
         @vOrderStatus    = Status,
         @vPickTicket     = PickTicket,
         @vAccount        = Account,
         @vLPNsAssigned   = LPNsAssigned,
         @vOwnership      = Ownership,
         @vWarehouse      = Warehouse,
         @vOHUDF1         = UDF1,
         @vOHUDF2         = UDF2,
         @vOHUDF3         = UDF3,
         @vOHUDF4         = UDF4,
         @vOHUDF5         = UDF5,
         @vOHUDF6         = UDF6,
         @vOHUDF7         = UDF7,
         @vOHUDF8         = UDF8,
         @vOHUDF9         = UDF9,
         @vOHUDF10        = UDF10,
         @BusinessUnit    = BusinessUnit
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get the Ship Via on the carrier */
  select @vCarrier               = Carrier,
         @vCarrierType           = CarrierType,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from vwShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

  select @vShipToAddressRegion = AddressRegion
  from fn_Contacts_GetShipToAddress(@OrderId, @vShipToId);

  select @vPickBatchNo = coalesce(@vPickBatchNo, PickBatchNo),
         @vPallet      = Pallet
  from Pallets
  where (PalletId = @PalletId);

  /* Get configured printer for the given workstation here  */
  if (coalesce(@PackStation, '') <> '')
    begin
      select @vPrinter = MappedPrinterId
      from DevicePrinterMapping DPM
        left outer join vwPrinters P on (P.PrinterName = DPM.MappedPrinterId)
      where (DPM.PrintRequestSource = @PackStation);
    end

  /* Validations */
  /* Throw error if user didn't scan anything and trying to close LPN */
  if (@Action <> 'ModifyLPN') and
     (not exists (select * from #PackDetails))
    set @MessageName = 'NoPackingContents';
  else
  /* Make sure Order is valid, ie it is not cancelled */
  if (@vOrderStatus = 'X' /* Cancelled */)
    set @MessageName = 'CancelledOrder';
  else
  /* Make sure Order is valid, ie it is not shipped */
  if (@vOrderStatus = 'S' /* Shipped */)
    set @MessageName = 'ShippedOrder';
  else
   /* Make sure CartonType is Valid - Validate on Close only */
  if (@Action in ('CloseLPN', 'ModifyLPN')) and (@vCartonType is null)
    set @MessageName = 'PackingInvalidCartonType';
  else
  if (coalesce(@Weight, 0) > 999)
    select @MessageName = 'Packing_InvalidLPNWeight';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Verify if a Packing LPN is passed in. If not, then create a new LPN  */
  if (@ToLPN is null)
    begin
      exec @ReturnCode = pr_LPNs_Generate @vLPNType,
                                          1,                /* @NumLPNsToCreate  TCount, */
                                          null,             /* @LPNFormat */
                                          @vWarehouse,
                                          @BusinessUnit,
                                          @UserId,
                                          @vToLPNId     output,
                                          @vToLPN       output;

      if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Generate LPN';
    end
  else
    begin
      select @vToLPN             = LPN,
             @vToLPNId           = LPNId,
             @vToLPNStatus       = Status,
             @vToLPNOrderId      = OrderId,
             @vPackageSeqNo      = PackageSeqNo,
             @vToLPNQty          = Quantity,
             @vToLPNUCCBarcode   = UCCBarcode,
             @vToLPNCartonType   = CartonType,
             @vToLPNActualWeight = ActualWeight
      from LPNs
      where (LPN = @ToLPN);

      /* Calling pr_Packing_ReopenLPN to validate all the possible scenarios */
      exec pr_Packing_ReopenLPN @vToLPN, @OrderId, @PackStation, @Action, @BusinessUnit, @UserId, @vOutputxml;

      if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Packing ReOpened LPN';

      /* Validate the status LPN order id with current packing order Id * /
      / * select top 1 @vCurrentOrderId = OrderId
        from @PackDetails * /

      if (@vToLPNOrderId <> @OrderId)
        set @vMessageName = 'LPNPack_InvalidOrder';
      */
    end

  if (@vToLPNId is null)
    set @vMessageName = 'LPNIsInvalid';

  /* Need to have validation that the ToLPN and the details in temp table are for same order */

  if (@@error <> 0) or (@vMessageName is not null)
    goto ErrorHandler;

  /* Get Max Package Seq No for current order */
  if (@vPackageSeqNo is null)
    select @vPackageSeqNo = coalesce(Max(PackageSeqNo), 0) + 1
    from LPNs
    where (OrderId = @OrderId) and (LPNType not in ('A' /* Cart */, 'TO' /* Tote */));

  /* If first package, then include the line fees as well so that the lines
     will be included in the package and hence the packing list */
  if (@vPackageSeqNo = 1)
    begin
      insert into #PackDetails (SKU, UnitsPacked, OrderId, OrderDetailId, FromLPNId, FromLPNDetailId, SerialNo, LineType)
        select SKU, UnitsAuthorizedToShip, OrderId, OrderDetailId, null, null, null, LineType
        from vwOrderDetails
        where (OrderId = @OrderId) and
              (LineType = 'F' /* Fees */);

      /* Consider all Fee lines as satisfied by updating UnitAssigned */
      update OrderDetails
      set UnitsAssigned = UnitsAuthorizedToShip
      where (OrderId = @OrderId) and
            (LineType = 'F' /* Fees */);
    end

  /* Validate PackingDetails */
  exec pr_Packing_ValidatePackingDetails @FromLPNId, @vToLPNId, @BusinessUnit, @UserId;

  /* Number of records inserted */
  select @vPackDetailcount = count(*),
         @vPackSKUcount    = count(distinct SKU),
         @vPackedQuantity  = sum(UnitsPacked)
  from #PackDetails;

  if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Got the record counts';

  select @vBulkOrderId = null;
  select @vBulkOrderId = OrderId
  from OrderHeaders
  where (PickBatchNo = @vPickBatchNo) and (OrderType = 'B' /* Bulk */) and (BusinessUnit = @BusinessUnit);

  /* Initialize to enter the while loop below */
  set @vRecordId = 1;

  /* If not Ship Carton activated above then Go thru each Pack detail record and adjust the FROM LPN and TO LPN accordingly */
  while (@vRecordId <= @vPackDetailCount)
    begin
      select @vRecordId        = RecordId,
             @vFromLPNId       = FromLPNId,
             @vFromLPNDetailId = FromLPNDetailId,
             @vPalletId        = PalletId,
             @vSKU             = SKU,
             @vQuantity        = UnitsPacked,
             @vOrderId         = OrderId,
             @vOrderDetailId   = OrderDetailId,
             @vSerialNo        = SerialNo,
             @vLineType         = LineType
      from #PackDetails
      where (RecordId = @vRecordId)
      order by RecordId;

      /* If the user has scanned a UPC and there are multiple SKUs with the same UPC
         then we may not identify the right SKU, so join with LPNDetails and we can
         narrow down to the SKU */
      select top 1 @vSKU   = SS.SKU,
                   @vSKUId = SS.SKUId
      from dbo.fn_SKUs_GetScannedSKUs(@vSKU, @BusinessUnit) SS
      join LPNDetails LD on (LD.LPNId = @vFromLPNId) and (LD.SKUId = SS.SKUId);

      if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Get scanned SKUs joined with LPN Details';

      select @vRefLocation = ReferenceLocation,
             @vPickedBy    = PickedBy,
             @vPickedDate  = PickedDate
      from LPNDetails
      where (LPNDetailId = @vFromLPNDetailId);

      /* Transfer inventory from the LPN on the Cart to the LPN being packed */

      if (coalesce(@vLineType, '') <> 'F' /* Fees */)
        begin

          if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Adjust From LPN Qty started';

          /* Reduce the inventory from the LPN / Cart Position */
          exec @ReturnCode = pr_LPNs_AdjustQty @LPNId        = @vFromLPNId,
                                               @LPNDetailId  = @vFromLPNDetailId output,
                                               @SKUId        = @vSKUId,
                                               @SKU          = @vSKU,
                                               @InnerPacks   = null,
                                               @Quantity     = @vQuantity,    /* Quantity to Adjust */
                                               @UpdateOption = '-',           /* '-' - Subtract Qty */
                                               @ExportOption = 'N',           /* @ExportOption TFlag = 'Y', */
                                               @ReasonCode   = null,                             /* Reason Code - None because it is a transfer */
                                               @Reference    = null,
                                               @BusinessUnit = @BusinessUnit,
                                               @UserId       = @UserId;

          if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Adjust From LPN Qty completed';

          if (@ReturnCode > 0) or (@@error <> 0)
            goto ErrorHandler;

          /* Update From LPN Status, if need be */
          select @vFromLPNStatus   = Status,
                 @vFromLPNQuantity = Quantity,
                 @vFromLPNNewStatus = case when LPNType in ('A' /* Cart */, 'TO' /* Tote */) then 'N'/* New */ else null end
          from LPNs
          where (LPNId = @vFromLPNId);

          if (@vFromLPNQuantity = 0)
            exec pr_LPNs_SetStatus @LPNId = @vFromLPNId, @Status = @vFromLPNNewStatus;
          else
          if (@vFromLPNStatus <> 'G' /* Packing */)
            exec pr_LPNs_SetStatus @LPNId = @vFromLPNId, @Status = 'G' /* Packing */;
        end

      /* Identify if there is already an LPNDetailId in the ToLPN for the given SKU, OrderDetailId */
      select @vToLPNDetailId = null;

      select @vToLPNDetailId        = LPNDetailId,
             @vLD_ReferenceLocation = ReferenceLocation
      from LPNDetails
      where (LPNId         = @vToLPNId      ) and
            (OrderDetailId = @vOrderDetailId) and
            (SerialNo is null);

      /* Add new lpn detail to the lpn being packed */
      if (@vToLPNDetailId is null)
        begin
          exec @ReturnCode = pr_LPNDetails_AddOrUpdate @LPNId           = @vToLPNId,
                                                       @LPNLine         = null,
                                                       @CoO             = null,
                                                       @SKUId           = @vSKUId,
                                                       @SKU             = @vSKU,
                                                       @InnerPacks      = null,
                                                       @Quantity        = @vQuantity,
                                                       @ReceivedUnits   = null,
                                                       @ReceiptId       = null,
                                                       @ReceiptDetailId = null,
                                                       @OrderId         = @vOrderId,
                                                       @OrderDetailId   = @vOrderDetailId,
                                                       @OnhandStatus    = null,
                                                       @Operation       = null,
                                                       @Weight          = null,
                                                       @Volume          = null,
                                                       @Lot             = null,
                                                       @BusinessUnit    = @BusinessUnit,
                                                       @LPNDetailId     = @vToLPNDetailId output,
                                                       @CreatedBy       = @UserId         output,
                                                       @ModifiedBy      = @UserId         output;

          /* the above proc need to be enhance to take SerialNo
             Copying the reference location, PickedBy and PickedDate from FromLPNDetails */
          update LPNDetails
          set SerialNo          = @vSerialNo,
              PackedBy          = coalesce(@UserId, System_User),
              PackedDate        = current_timestamp,
              ReferenceLocation = @vRefLocation,
              PickedBy          = @vPickedBy,
              PickedDate        = @vPickedDate
          where (LPNDetailId = @vToLPNDetailId);

          if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Add Details to Dest LPN';
        end
      else
        begin
          /* increment units on an existing lpn detail to the lpn being packed */
          exec @ReturnCode = pr_LPNs_AdjustQty @LPNId        = @vToLPNId,
                                               @LPNDetailId  = @vToLPNDetailId output,
                                               @SKUId        = @vSKUId,
                                               @SKU          = @vSKU,
                                               @InnerPacks   = null,
                                               @Quantity     = @vQuantity,    /* Quantity to Adjust */
                                               @UpdateOption = '+',           /* '+' - Add Qty */
                                               @ExportOption = 'N',           /* @ExportOption TFlag = 'Y', */
                                               @ReasonCode   = null,                             /* Reason Code - None because it is a transfer */
                                               @Reference    = null,
                                               @BusinessUnit = @BusinessUnit,
                                               @UserId       = @UserId;

          /* If the LPNDetail does not already have the Reference Location in it, then append it */
          if (charindex(@vRefLocation, @vLD_ReferenceLocation) = 0)
            update LPNDetails
            set ReferenceLocation = substring(coalesce(ReferenceLocation +','+ rtrim(@vRefLocation), rtrim(@vRefLocation)),1,50)
            where (LPNDetailId = @vToLPNDetailId);

          if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Adjust Dest LPN Qty';
        end

      if (@ReturnCode > 0) or (@@error <> 0)
        goto ErrorHandler;

      /* for the orders picked via Bulk Pull process, the order details must be updated with the units packed
         these orders are in batched status, and hence units assigned has to be updated on packing */
      if (@vBulkOrderId is not null)
        begin
          update OrderDetails
          set UnitsAssigned = UnitsAssigned + @vQuantity
          where (OrderDetailId = @vOrderDetailId);

          /* Reduce Units Assigned on Bulk PT with packed units */
          update OrderDetails
          set UnitsAssigned         = dbo.fn_MaxInt((UnitsAssigned - @vQuantity), 0),
              UnitsAuthorizedToShip = UnitsAuthorizedToShip - @vQuantity
          where (OrderId = @vBulkOrderId) and (SKUId = @vSKUId) and (UnitsAssigned > 0);
        end

      /* Processed the packing detail record read, move to next Id */
      select @vRecordId = @vRecordId + 1;
    end /* while (@vRecordId <= @vPackDetailCount) */

  /* generate SSCC barcode for the LPN  */
  if (@vToLPNUCCBarcode is null)
    exec pr_ShipLabel_GetSSCCBarcode @UserId, @BusinessUnit, @vToLPN, Default /* Barcode Type */,
                                     @vUCCBarcode output;

  if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Generate SSCC barcode';

  /* CartonType update on the Packing LPN */
  update LPNs
  set @vLPNShipmentId = ShipmentId,
      @vLPNLoadId     = LoadId,
      CartonType      = coalesce(@CartonType, CartonType),
      PickBatchId     = @vPickBatchId,
      PickBatchNo     = @vPickBatchNo,
      ActualWeight    = @Weight,
      ActualVolume    = @vCartonVolume,
      Ownership       = @vOwnership,
      DestWarehouse   = @vWarehouse,
      @vPackageSeqNo  =
      PackageSeqNo    = coalesce(PackageSeqNo, @vPackageSeqNo, 1),
      @vNewLPNQty     = Quantity,
      @vTrackingNo    = TrackingNo,
      ReturnTrackingNo
                      = @ReturnTrackingNo  /* Save return Tracking no */,
      UCCBarcode      = @vUCCBarcode,
      UDF2            = LPN /* Temporary to avoid errors from FedEx */
  where (LPNId = @vToLPNId);

  select @vLPNValue = sum(OD.UnitSalePrice * OD.UnitsOrdered)
  from OrderDetails OD
    join LPNDetails LD on (OD.OrderDetailId = LD.OrderDetailId)
  where (LD.LPNId = @vToLPNId);

  /* Build xml, Evaluate rule... Fetch new ShipVia */
  select @vXmlData = dbo.fn_XMLNode('RootNode',
                       dbo.fn_XMLNode('Entity',                'LPN') +
                       dbo.fn_XMLNode('LPNId',                 @vToLPNId) +
                       dbo.fn_XMLNode('LPN',                   @vToLPN) +
                       dbo.fn_XMLNode('LPNValue',              @vLPNValue) +
                       dbo.fn_XMLNode('LPNWeight',             @Weight)  +
                       dbo.fn_XMLNode('PackageSeqNo',          @vPackageSeqNo) +
                       dbo.fn_XMLNode('OrderId',               @OrderId) +
                       dbo.fn_XMLNode('PickTicket',            @vPickTicket) +
                       dbo.fn_XMLNode('OrderStatus',           @vOrderStatus) +
                       dbo.fn_XMLNode('BulkOrderId',           @vBulkOrderId) +
                       dbo.fn_XMLNode('PickBatchNo',           @vPickBatchNo) +
                       dbo.fn_XMLNode('Action',                @Action) +
                       dbo.fn_XMLNode('Operation',             'Packing') +
                       dbo.fn_XMLNode('ShipViaServiceType',    'LPN') +
                       dbo.fn_XMLNode('ShipVia',               @vShipVia) +
                       dbo.fn_XMLNode('Carrier',               @vCarrier) +
                       dbo.fn_XMLNode('IsSmallPackageCarrier', @vIsSmallPackageCarrier) +
                       dbo.fn_XMLNode('ShipToAddressRegion',   @vShipToAddressRegion) +
                       dbo.fn_XMLNode('Printer',               '') +
                       dbo.fn_XMLNode('PackingListType',       '') +
                       dbo.fn_XMLNode('DocumentType',          '') +
                       dbo.fn_XMLNode('LabelType',             '') +
                       dbo.fn_XMLNode('OHUDF1',                @vOHUDF1) +
                       dbo.fn_XMLNode('OHUDF2',                @vOHUDF2) +
                       dbo.fn_XMLNode('OHUDF3',                @vOHUDF3) +
                       dbo.fn_XMLNode('OHUDF4',                @vOHUDF4) +
                       dbo.fn_XMLNode('OHUDF5',                @vOHUDF5) +
                       dbo.fn_XMLNode('OHUDF6',                @vOHUDF6) +
                       dbo.fn_XMLNode('OHUDF7',                @vOHUDF7) +
                       dbo.fn_XMLNode('OHUDF8',                @vOHUDF8) +
                       dbo.fn_XMLNode('OHUDF9',                @vOHUDF9) +
                       dbo.fn_XMLNode('OHUDF10',               @vOHUDF10)+
                       dbo.fn_XMLNode('BusinessUnit',          @BusinessUnit)+
                       dbo.fn_XMLNode('UserId',                @UserId));

  /* If Order Shipvia is not specified, then determine LPN Shipvia based on rules */
  if (@vShipvia = '' or @vShipVia is null)
    begin
      /* Get the Shipvia */
      exec pr_RuleSets_Evaluate 'GetShipVia' /* RuleSetType */, @vXmlData, @vShipVia output;

      /* Updating UDF4 with the returned ShipVia from rules */
      update LPNs
      set UDF4 = @vShipVia
      where (LPNId = @vToLPNId);

      /* Get the Carrier for the corresponding ShipVia */
      select @vCarrier               = Carrier,
             @vCarrierType           = CarrierType,
             @vIsSmallPackageCarrier = IsSmallPackageCarrier
      from vwShipVias
      where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

      select @vXmlData = dbo.fn_XMLStuffValue(@vXmlData, 'ShipVia', @vShipVia);
      select @vXmlData = dbo.fn_XMLStuffValue(@vXmlData, 'Carrier', @vCarrier);
      select @vXmlData = dbo.fn_XMLStuffValue(@vXmlData, 'IsSmallPackageCarrier', @vIsSmallPackageCarrier);
   end

  /* Update ToLPN as Packing/Packed */
  if (@Action in ('CloseLPN', 'ModifyLPN', 'RFPacking'))
    exec pr_LPNs_SetStatus @vToLPNId, 'D' /* Packed */;
  else
    exec pr_LPNs_SetStatus @vToLPNId, 'G' /* Packing */;

  /* if LPN is not associated with a Shipment or Load, then find one and add to it */
  if (((nullif(@vLPNShipmentId, 0)) is null) or ((nullif(@vLPNLoadId, 0)) is null)) and
     (@Action in ('CloseLPN', 'ModifyLPN'))
    exec pr_LPNs_AddToALoad @vToLPNId, @BusinessUnit, 'Y' /* Yes - @LoadRecount */, @UserId;

  /* ShipLPN only if it is closed and that too is optional, based upon the carrier */
  if (@Action in ('CloseLPN', 'ModifyLPN'))
    begin
      select @vAutoShipCarriers = dbo.fn_Controls_GetAsString('ShipLPNOnPack', 'Carriers',
                                                              '', @BusinessUnit, @UserId);

      if (charindex(@vCarrier, @vAutoShipCarriers) <> 0)
        exec pr_LPNs_Ship @vToLPNId, null, @BusinessUnit, @UserId;
    end

  /* Recount the order. It also sets status and returns new status */
  exec pr_OrderHeaders_Recount @vOrderId, null /* PT */, @vNewOrderStatus output;

  /* Recount the Bulk Order if exist */
  if (@vBulkOrderId is not null)
    exec pr_OrderHeaders_Recount @vBulkOrderId;

  /* status update on the Picking Pallet (Cart)
     If all the LPNs on the Pallet are now empty, then mark the Pallet as Empty
  */
  if (@PalletId <> 0) and
     (not exists (select LPNId
                  from LPNs
                  where (PalletId = @PalletId) and (Quantity > 0)))
    begin
      exec pr_Pallets_UpdateCount @PalletId, @UpdateOption = '*' /* UpdateOption */;

      -- We don't need to force Status of Wave, we can just recalc wave always later

      -- /* When Pallet becomes empty, it does not necessarily mean that packing is complete for
      --    the batch as it could be a multi cart batch. Hence only when there are no other pallets
      --    associated with the batch, then mark the batch as packed */
      -- if (not exists (select * from Pallets where PickBatchNo = @vPickBatchNo))
      --   exec pr_PickBatch_SetStatus @vPickBatchNo, 'C' /* Packed */, @UserId;
    end

  /* If Order status changed, recalc Batch status as well */
  if (@vNewOrderStatus <> @vOrderStatus)
    exec pr_PickBatch_SetStatus @vPickBatchNo, '$', @UserId;

  /* Clean up */
  delete from @PackDetails;

  /* Build the response */
  select @vLPNInfoxml = dbo.fn_XMLNode('LPNInfo',
                          dbo.fn_XMLNode('LPNId',             @vToLPNId) +
                          dbo.fn_XMLNode('LPN',               @vToLPN) +
                          dbo.fn_XMLNode('Carrier',           @vCarrier) +
                          dbo.fn_XMLNode('ShipVia',           @vShipVia) +
                          dbo.fn_XMLNode('CartonType',        @vCartonType) +
                          dbo.fn_XMLNode('CartonTypeDesc',    @vCartonTypeDesc) +
                          dbo.fn_XMLNode('Weight',            @Weight) +
                          dbo.fn_XMLNode('TrackingNo',        @vTrackingNo) +
                          dbo.fn_XMLNode('UCCBarcode',        @vUCCBarcode) +
                          dbo.fn_XMLNode('PickTicket',        @vPickTicket));

  /* Re-Generate the label if the CartonType or Weight (Units) changed */
  if (@Action not in ('PackLPN', 'RFPacking')) and
     ((@vToLPNQty <> @vNewLPNQty) or
      (@vToLPNCartonType <> @vCartonType) or
      (coalesce(@vTrackingNo, '') = ''))
    if (@vCarrier in ('UPS', 'FEDEX', 'USPS', 'DHL'))
      begin
        exec pr_Shipping_ValidateToShip null /* LoadId */, @OrderId, null /* PalletId */, @vToLPNId, @vShipError output;

        /* Insert the message to temptable to display in V3 application */
        if ((coalesce(@vShipError, '') <> '') and (object_id('tempdb..#ResultMessages') is not null))
          insert into #ResultMessages (MessageType, MessageText) select 'E' /* Info */, @vShipError;
      end

  select @vPrintLabels    = case when (@Action in ('CloseLPN', 'ModifyLPN')) then 'Y' else 'N' end,
         @vPrintReports   = case when (@Action in ('CloseLPN', 'ModifyLPN')) then 'Y' else 'N' end,
         @vPrintDocuments = case when (@Action in ('CloseLPN', 'ModifyLPN')) then 'Y' else 'N' end,
         @vPrinter        = coalesce(nullif(@vPrinter,''), 'Zebra9'),
         @vLabelCopies    = '1';

  /* Append Printer Name */
  select @vXmlData = dbo.fn_XMLStuffValue(@vXmlData, 'Printer', @vPrinter),
         @vXmlData = dbo.fn_XMLStuffValue(@vXmlData, 'OrderStatus', @vNewOrderStatus);

  /* Take the right 8 digits of UCC barcode */
  select @vUCCBarcodeSeq = right(@vUCCBarcode, 8);

  /* Framing result message - ToDo: Change message to be based upon contect i.e. closed or repacked etc. */
  select @vMessage = dbo.fn_Messages_Build('PackingSuccessful', @vPackageSeqNo, @vToLPN, @vUCCBarcodeSeq, @vPickTicket, null);

  /* Insert the message to temptable to display in V3 application */
  if (object_id('tempdb..#ResultMessages') is not null)
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @vMessage;

  set @vMessagesXML = dbo.fn_XMLNode('Message',
                       dbo.fn_XMLNode('ResultMessage', @vMessage) +
                       dbo.fn_XMLNode('ShipError', @vShipError));

  /* Prepare Actions */
  select @vActionsxml = (select @vCreateShipment  CreateShipment,
                                @vPrintLabels     PrintLabels,
                                @vPrintReports    PrintReports,
                                @vPrintDocuments  PrintDocuments
                         for xml raw('Actions'), elements );

  select @OutputXML =  dbo.fn_XMLNode('PackingCloseLPNInfo',
                         coalesce(@vLPNInfoxml, '')   +
                         coalesce(@vActionsxml, '')   +
                         coalesce(@vMessagesxml, ''));

  /* Set the audit activity based on the action */
  if (@vPackSKUCount = 1)
    set @vAuditActivity = 'Packing_PackLPN.SingleSKU';
  else
    set @vAuditActivity = 'Packing_PackLPN.MultipleSKUs';

  /* AuditTrail */
  /* If package is opened and closed without packing any items we do not need to create audit trail */
  if (@vSKUId is not null)
    exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                              @PickBatchId   = @vPickBatchId,
                              @OrderId       = @vOrderId,
                              @Quantity      = @vPackedQuantity,
                              @SKUId         = @vSKUId,
                              @LPNId         = @vFromLPNId,
                              @ToLPNId       = @vToLPNId;

  select @vAuditActivity = 'Packing' + @Action;
  if (@Action in ('CloseLPN', 'PackLPN'))
    exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                              @PickBatchId   = @vPickBatchId,
                              @OrderId       = @vOrderId,
                              @LPNId         = @vFromLPNId,
                              @ToLPNId       = @vToLPNId;

  set @vOldCartonData = coalesce(@vToLPNCartonType, 'None')  +', ' + coalesce(convert(varchar(8), @vToLPNActualWeight), '0');
  set @vNewCartonData = coalesce(@vCartonType, 'None') + ', ' + coalesce(convert(varchar(10), @Weight), '0.00');

  if (@Action = 'ModifyLPN')
    exec pr_AuditTrail_Insert 'ModifyCartonType', @UserId, null /* ActivityTimestamp */,
                              @OrderId       = @vOrderId,
                              @LPNId         = @vToLPNId,
                              @Note1         = @vOldCartonData,
                              @Note2         = @vNewCartonData;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  if (charindex('Y', @vDebug) > 0)
    begin
      update DebugPacking
      set OutputXML    = @OutputXML,
          ModifiedDate = current_timestamp
      where RecordId = @vDebugRecordId;

      /* If time taken for transaction is greater than 5secs then Log activitiy with Marker times */
      if exists(select * from DebugPacking where datediff(s, createddate, modifieddate) >= '5')
        exec pr_Markers_Log @ttMarkers, 'Order', @vOrderId, @vPickTicket, 'Packing', @@ProcId, null /* Message */,
                            @UserId, @BusinessUnit;
    end

  /* Processed all the Packing LPN Details.. Commit the Changes */
  commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  if ((charindex('Y', @vDebug) > 0 or (charindex('E', @vDebug) > 0)))
    begin
      if (@vDebugRecordId is null)
        insert into DebugPacking (CartonType, PalletId, OrderId, Weight, Volume, LPNContents, ToLPN, PackStation, Action, BusinessUnit, UserId, OutputXML)
          select @CartonType, @PalletId, @OrderId, @Weight, @Volume, @LPNContents, @ToLPN, @PackStation, @Action, @BusinessUnit, @UserId, @OutputXML
      else
        update DebugPacking
        set OutputXML = @OutputXML
        where RecordId = @vDebugRecordId;
    end

  exec pr_ReRaiseError;

end catch;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Packing_CloseLPN_V3 */

Go
