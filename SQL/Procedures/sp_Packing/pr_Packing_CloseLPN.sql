/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/24  OK      pr_Packing_CloseLPN_V3, pr_Packing_CloseLPN: Changes to include PickTicket in success message notification (FBV3-1075)
  2020/05/28  RT      pr_Packing_GetLabelsToPrint,pr_Packing_CloseLPN: Chnages to use Printers instead of Devices (HA-683)
  2019/10/01  MS      pr_Packing_CloseLPN: Added AuditLog to log the info if the package is paused (SRI-1063)
  2018/12/23  AY      pr_Packing_CloseLPN: Cleanup logging and error handling
  2018/02/19  AY      pr_Packing_CloseLPN: Added validation to prevent user to give proper carton weight (HPI-1802)
  2016/12/06  VM      pr_Packing_CloseLPN: Changes to avoid nagative values in OD.UnitsAssigned (HPI-692)
  2016/07/26  TK      pr_Packing_CloseLPN: Consider Carrier to determine right shiplabel format (HPI-187)
              AY      pr_Packing_CloseLPN: Removed redundant code to recount and calc status of Order
  2016/07/06  KN      pr_Packing_ExecuteAction: pr_Packing_CloseLPN: Input params consolidated to xml
                      pr_Packing_CloseLPN: Added ReturnTrackingNo param
  2016/04/19  RV      pr_Packing_CloseLPN: Allow modify LPNs with out any LPN's contents
  2016/04/11  TK      pr_Packing_CloseLPN: Bug Fix -  Append configured printer name before calling get Labels to Print
                      pr_Packing_CloseLPN: Change to use pr_Packing_GetDocumentsToPrint. (CIMS-731)
  2016/04/07  TK      pr_Packing_CloseLPN: Added validation not to allow user to close package without scanning any contents
                      pr_Packing_CloseLPN: Change to use pr_Packing_GetLabelsToPrint.
  2016/02/10  KN      pr_Packing_CloseLPN added: USPS related code (NBD-162).
  2016/01/25  TK      pr_Packing_CloseLPN & pr_Packing_ReopenLPN: Enhanced to meet RF packing requirements (NBD-64)
  2015/12/23  DK      pr_Packing_CloseLPN: Enhanced to enable printing labels while packing based on rules.(FB-536).
  2015/12/11  SV      pr_Packing_CloseLPN: Handle duplicate UPCs i.e. diff SKUs having same UPC (SRI-424)
  2015/12/12  DK      pr_Packing_CloseLPN: Bug fix to reduce UnitsAuthorizedToShip on Bulk PT with packed units (FB-570).
  2015/12/07  SV      pr_Packing_CloseLPN: Handle duplicate UPCs i.e. diff SKUs having same UPC
  2015/11/15  AY      pr_Packing_CloseLPN: Return UCC Barcode of the LPN in success message
  2015/10/06  SV      pr_Packing_CloseLPN: Added a double check while closing the cartons (CIMS-634).
  2015/09/18  NY      pr_Packing_CloseLPN: Added validation to not to pack more than assigned.(SRI-384)
  2015/08/29  RV      pr_Packing_CloseLPN: Check for shipping errors to create shipment (OB-388)
  2015/08/24  VM      pr_Packing_CloseLPN: Initialize vRulesResult before each call to avoid creating unnecessary reports to print (FB-316)
  2015/08/04  DK      pr_Packing_CloseLPN: Return PrintReports as 'N' - No when there are no reports to print
  2015/07/10  RV      pr_Packing_CloseLPN: Add return packing report to xml only when it required
  2015/07/01  RV      pr_Packing_CloseLPN: Recount the Bulk Order, if exist.
  2015/06/26  RV      pr_Packing_CloseLPN: Once units packed for original orders, reduce the UnitsAssigned from Bulk PT.
  2015/05/29  SV      pr_Packing_CloseLPN: Use ModifyCarton action properly
  2015/04/06  SV      pr_Packing_CloseLPN: Made changes regarding the Shipping Rules
  2015/03/11  DK      pr_Packing_CloseLPN: :Made changes to print ReturnPackingSlip.
  2015/03/04  NB      pr_Packing_CloseLPN: introduced conditions to determine whether or not to print
                      pr_Packing_CloseLPN:Added validation to identify if the Order belongs to a Bulk Pick Batch
  2015/02/13  AK      pr_Packing_CloseLPN: Added AT code for ModifyCarton action.
  2015/01/21  TK      pr_Packing_CloseLPN: Passed the missing parameter
  2014/12/29  TK      pr_Packing_CloseLPN: Enhanced to update PickBatchId and PickBatchNo on the Packed LPN.
  2014/09/27  VM      pr_Packing_CloseLPN: Moved building ActionsXML to from top to bottom to handle PrintDocuments option
  2014/09/17  VM      pr_Packing_CloseLPN: Included to use rules to get Documents list to print and return to UI
  2014/06/16  VM      pr_Packing_CloseLPN: Use rules to get PackingList/ShippingLabel
  2014/02/25  DK      pr_Packing_CloseLPN: Use LPNType as 'S' - Shipped carton for shipping LPNs
  2013/07/22  PKS     pr_Packing_CloseLPN: Condition was modified for USPS carrier types at framing XML for Labels.
  2013/07/08  TD      pr_Packing_CloseLPN: Changes about to get  configured Printer based on the given MachineName.
  2013/06/25  PKS     pr_Packing_CloseLPN: Validation modified to avoid print only UPS
  2013/06/10  AY      pr_Packing_CloseLPN: Print USPS Label for USPS shipments
  2013/06/06  AY      pr_Packing_CloseLPN: Fix to not create new trackingno when carton already has one.
  2013/05/24  PK      pr_Packing_CloseLPN: Passing Warehouse param for LPN generation procedure.
  2013/05/13  YA/AY   pr_Packing_CloseLPN: Added audit trail.
  2013/05/06  AY      pr_Packing_CloseLPN: Added Debug
  2013/05/03  PK      pr_Packing_CloseLPN: Fix in updating LPN status
  2013/04/30  AY      pr_Packing_CloseLPN: Suppress ShipLabels, Skip LPN Packing list for single carton
  2013/04/29  AY      pr_Packing_CloseLPN: Do not count Cart Positions when generating PackageSeqNo,
  2013/04/27  VM      pr_Packing_CloseLPN: Do not CreateShipment for Peter Glenn when it is UPS
  2013/04/25  YA      pr_Packing_CloseLPN: Assigning SoldToId on CloseLPN (Fix on labels printing issue)
  2013/04/17  YA      pr_Packing_CloseLPN: Added new i/p param 'PackStation'.
  2013/04/17  PK      pr_Packing_CloseLPN: Changes to udpate Load and Shipment info on the carton if
  2013/04/16  AY      pr_Packing_CloseLPN: Enh. to return XML to drive label/report printing from SQL
  2011/11/09  TD      pr_Packing_CloseLPN: Copying the RefLoc, PickedBy and
  2011/11/07  AY      pr_Packing_CloseLPN: Handled order line types of 'F' - fees.
  2011/11/02  AA      pr_Packing_CloseLPN: Enhance to update PackageSeqNo onto
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_CloseLPN') is not null
  drop Procedure pr_Packing_CloseLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_CloseLPN:
    ToLPN: Is the LPN being packed - which could be new or existing. If null,
           we would generate a new ToLPN.
    Weight, Volume: ..
    LPNContents: ....

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
Create Procedure pr_Packing_CloseLPN
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
          @vId                    TRecordId,
          @vToLPN                 TLPN,
          @vToLPNId               TRecordId,
          @vToLPNStatus           TStatus,
          @vToLPNOrderId          TRecordId,
          @vToLPNDetailId         TRecordId,
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

  declare @vCreateShipment    TFlag,
          @vPrintLabels       TFlag,
          @vPrintReports      TFlag,
          @vPrintDocuments    TFlag,

          @vLPNInfoxml        TXML,
          @vActionsxml        TXML,
          @vLabelsxml         TXML,
          @vReportsxml        TXML,
          @vDocumentsxml      TXML,
          @vMessagesXML       TXML,
          @vOutputxml         TXML,
          @vCreateShipmentxml TXML,

          @vMessage1          TDescription,
          @vDebug             TFlag,
          @vDebugRecordId     TRecordId;

  declare @xmlRulesData       TXML,
          @vRulesResult       TResult,
          @vPackingListTypesToPrint
                              TResult,
          @vCarrierPackagingType
                              varchar(max);

  declare @PackDetails table(
    Id               TRecordId Identity(1,1),
    SKU              TSKU,
    UnitsPacked      TQuantity,
    OrderId          TRecordId,
    OrderDetailId    TRecordId,
    FromLPNId        TRecordId,
    FromLPNDetailId  TRecordId,
    PalletId         TRecordId,
    SerialNo         TSerialNo,
    LineType         TFlag);

  declare @PackingQty table(
    Id               TRecordId Identity(1,1),
    ScannedInfo      TSKU,
    SKU              TSKU,
    LPNId            TRecordId,
    Quantity         TQuantity);

  declare @QtyToPack table(
    SKU              TSKU,
    Quantity         TQuantity);

  declare @ttMarkers TMarkers;
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

  select @vCartonType     = CartonType,
         @vCartonTypeDesc = Description,
         @vCartonVolume   = OuterVolume,
         @vCarrierPackagingType
                          = CarrierPackagingType
  from CartonTypes
  where (CartonType = @CartonType) and (Status = 'A' /* Active */);

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
  where (ShipVia = @vShipVia);

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
     (((@vLPNContents is null)) or
     ((@vLPNContents is not null) and (@vLPNContents.exist('/PackingCarton') <> 1)))
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

  if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Read I/P xml';

  /* Get all the Packing details into the temp table */
  insert into @PackDetails (SKU, UnitsPacked, OrderId, OrderDetailId,
                            FromLPNId, FromLPNDetailId, PalletId, SerialNo, LineType)
    select Record.Col.value('SKU[1]',           'TSKU')      SKU,
           Record.Col.value('UnitsPacked[1]',   'TQuantity') UnitsPacked,
           Record.Col.value('OrderId[1]',       'TRecordId') OrderId,
           Record.Col.value('OrderDetailId[1]', 'TRecordId') OrderDetailId,
           Record.Col.value('LPNId[1]',         'TLPN')      LPNId,
           Record.Col.value('LPNDetailId[1]',   'TRecordId') LPNDetailId,
           L.PalletId,
           nullif(Record.Col.value('SerialNo[1]', 'TSerialNo'), '') SerialNo,
           'M' /* Merchandise Line Type */
    from  @vLPNContents.nodes('/PackingCarton/CartonDetails') as Record(Col)
      join LPNs L on (L.LPNId = Record.Col.value('LPNId[1]', 'TRecordId'))

  if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Read I/P xml Completed';

  if (@@error <> 0)
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
             @vToLPNCartonType   = CartonType,
             @vToLPNActualWeight = ActualWeight,
             @vUCCBarcode        = UCCBarcode
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
      insert into @PackDetails (SKU, UnitsPacked, OrderId, OrderDetailId, FromLPNId, FromLPNDetailId, SerialNo, LineType)
        select SKU, UnitsAuthorizedToShip, OrderId, OrderDetailId, null, null, null, LineType
        from vwOrderDetails
        where (Orderid = @OrderId) and
              (LineType = 'F' /* Fees */);

      /* Consider all Fee lines as satisfied by updating UnitAssigned */
      update OrderDetails
      set UnitsAssigned = UnitsAuthorizedToShip
      where (OrderId = @OrderId) and
            (LineType = 'F' /* Fees */);
    end

  /* Get the quantity of each sku being packed */
  insert into @PackingQty (ScannedInfo, LPNId, Quantity)
    select SKU, FromLPNId, sum(UnitsPacked)
    from @PackDetails
    group by SKU, FromLPNId;

  /* Scanned info could be SKU or UPC, get actual SKU in the context of the From LPN */
  update @PackingQty
  set SKU = SS.SKU
  from @PackingQty PQ cross apply fn_SKUs_GetScannedSKUs(PQ.ScannedInfo, @BusinessUnit) SS
    join vwLPNDetails LD on (LD.LPNId = PQ.LPNId) and (LD.SKUId = SS.SKUId);

  if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Updated SKU with cross Apply';

  /* Get the quantity of each sku on cart */
  insert into @QtyToPack (SKU, Quantity)
    select LD.SKU, sum(Quantity)
    from vwLPNDetails LD
      join @PackDetails PD on (LD.PalletId = PD.PalletId)
    where ((LD.PalletId = PD.PalletId) or (LPNId = @FromLPNId)) -- User would have scanned items from different carts
    group by LD.SKU;

  /* Do not allow to pack more units than on cart */
  if (exists(select *
              from @PackingQty PQ
                full join @QtyToPack QP on (PQ.SKU = QP.SKU)
              where coalesce(PQ.Quantity,0) > coalesce(QP.Quantity,0)))
    set @MessageName = 'ScannedMoreThanPicked';

  if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Validated to not allow pack more units than on cart';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Number of records inserted */
  select @vPackDetailcount = count(*) from @PackDetails;
  select @vPackSKUcount    = count(distinct SKU),
         @vPackedQuantity  = sum(UnitsPacked)
  from @PackDetails;

  if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Got the record counts';

  /* Initialize to enter the while loop below */
  set @vId = 1;

  /* Go thru each Pack detail record and adjust the FROM LPN and TO LPN accordingly */
  while (@vId <= @vPackDetailCount)
    begin
      select @vId               = Id,
             @vFromLPNId        = FromLPNId,
             @vFromLPNDetailId  = FromLPNDetailId,
             @vPalletId         = PalletId,
             @vSKU              = SKU,
             @vQuantity         = UnitsPacked,
             @vOrderId          = OrderId,
             @vOrderDetailId    = OrderDetailId,
             @vSerialNo         = SerialNo,
             @vLineType         = LineType
      from @PackDetails
      where (Id = @vId);

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

      /* Identify if the Order belongs to a Bulk Pick Batch */
      select @vPickBatchNo = PickBatchNo
      from OrderHeaders
      where (OrderId = @vOrderId);

      select @vBulkOrderId = null;
      select @vBulkOrderId = OrderId
      from OrderHeaders
      where ((PickBatchNo = @vPickBatchNo) and (OrderType = 'B' /* Bulk Pull*/));

      /* Transfer inventory from the LPN on the Cart to the LPN being packed */

      if (@vLineType <> 'F' /* Fees */)
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
        exec @ReturnCode = pr_LPNDetails_AddOrUpdate @LPNId            = @vToLPNId,
                                                     @LPNLine          = null,
                                                     @CoO              = null,
                                                     @SKUId            = @vSKUId,
                                                     @SKU              = @vSKU,
                                                     @InnerPacks       = null,
                                                     @Quantity         = @vQuantity,
                                                     @ReceivedUnits    = null,
                                                     @ReceiptId        = null,
                                                     @ReceiptDetailId  = null,
                                                     @OrderId          = @vOrderId,
                                                     @OrderDetailId    = @vOrderDetailId,
                                                     @OnhandStatus     = null,
                                                     @Operation        = null,
                                                     @Weight           = null,
                                                     @Volume           = null,
                                                     @Lot              = null,
                                                     @BusinessUnit     = @BusinessUnit,
                                                     @LPNDetailId      = @vToLPNDetailId output,
                                                     @CreatedBy        = @UserId         output,
                                                     @ModifiedBy       = @UserId         output;

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
        where (OrderdetailId = @vOrderDetailId);

        /* Get Bulk Order Detail Id to reduce Units Assigned on Bulk PT */
        select @vBulkOrderDetailId = OrderDetailId
        from OrderDetails
        where (OrderId = @vBulkOrderId) and (SKUId = @vSKUId) and (UnitsAssigned > 0);

        /* Reduce Units Assigned on Bulk PT with packed units */
        update OrderDetails
        set UnitsAssigned         = dbo.fn_MaxInt((UnitsAssigned - @vQuantity), 0),
            UnitsAuthorizedToShip = UnitsAuthorizedToShip - @vQuantity
        where (OrderdetailId = @vBulkOrderDetailId);
      end

    /* Processed the packing detail record read, move to next Id */
    select @vId = @vId + 1;
  end /* while (@vId <= @vPackDetailCount) */

  /* generate SSCC barcode for the LPN, if not exists */
  if(coalesce(@vUCCBarcode, '') = '')
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
  select @vXmlData = '<RootNode>' +
                      dbo.fn_XMLNode('Entity',             'LPN') +
                      dbo.fn_XMLNode('LPNId',              @vToLPNId) +
                      dbo.fn_XMLNode('LPN',                @vToLPN) +
                      dbo.fn_XMLNode('LPNValue',           @vLPNValue) +
                      dbo.fn_XMLNode('LPNWeight',          @Weight)  +
                      dbo.fn_XMLNode('PackageSeqNo',       @vPackageSeqNo) +
                      dbo.fn_XMLNode('OrderId',            @OrderId) +
                      dbo.fn_XMLNode('PickTicket',         @vPickTicket) +
                      dbo.fn_XMLNode('OrderStatus',        @vOrderStatus) +
                      dbo.fn_XMLNode('BulkOrderId',        @vBulkOrderId) +
                      dbo.fn_XMLNode('PickBatchNo',        @vPickBatchNo) +
                      dbo.fn_XMLNode('Action',             @Action) +
                      dbo.fn_XMLNode('Operation',          'Packing') +
                      dbo.fn_XMLNode('ShipViaServiceType', 'LPN') +
                      dbo.fn_XMLNode('ShipVia',            @vShipVia) +
                      dbo.fn_XMLNode('Carrier',            @vCarrier) +
                      dbo.fn_XMLNode('ShipToAddressRegion',@vShipToAddressRegion) +
                      dbo.fn_XMLNode('Printer',            '') +
                      dbo.fn_XMLNode('PackingListType',    '') +
                      dbo.fn_XMLNode('DocumentType',       '') +
                      dbo.fn_XMLNode('LabelType',          '') +
                      dbo.fn_XMLNode('OHUDF1',             @vOHUDF1) +
                      dbo.fn_XMLNode('OHUDF2',             @vOHUDF2) +
                      dbo.fn_XMLNode('OHUDF3',             @vOHUDF3) +
                      dbo.fn_XMLNode('OHUDF4',             @vOHUDF4) +
                      dbo.fn_XMLNode('OHUDF5',             @vOHUDF5) +
                      dbo.fn_XMLNode('OHUDF6',             @vOHUDF6) +
                      dbo.fn_XMLNode('OHUDF7',             @vOHUDF7) +
                      dbo.fn_XMLNode('OHUDF8',             @vOHUDF8) +
                      dbo.fn_XMLNode('OHUDF9',             @vOHUDF9) +
                      dbo.fn_XMLNode('OHUDF10',            @vOHUDF10)+
                      dbo.fn_XMLNode('BusinessUnit',       @BusinessUnit)+
                      dbo.fn_XMLNode('UserId',             @UserId)+
                     '</RootNode>';

  /* If Order Shipvia is not specified, then determine LPN Shipvia based on rules */
  if (@vShipvia = '' or @vShipVia is null)
    begin
      /* Get the Shipvia */
      exec pr_RuleSets_Evaluate 'GetShipVia' /* RuleSetType */, @vXmlData, @vShipVia output;

      /* Updating UDF4 with the returned ShipVia from rules */
      update LPNs
      set UDF4 = @vShipVia
      where (LPNId = @vToLPNId);
   end

   /* Get the Carrier for the corresponding ShipVia */
   select @vCarrier = Carrier
   from ShipVias
   where (ShipVia = @vShipVia);

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

      /* When Pallet becomes empty, it does not necessarily mean that packing is complete for
         the batch as it could be a multi cart batch. Hence only when there are no other pallets
         associated with the batch, then mark the batch as packed */
      if (not exists (select * from Pallets where PickBatchNo = @vPickBatchNo))
        exec pr_PickBatch_SetStatus @vPickBatchNo, 'C' /* Packed */, @UserId;
    end
  else
  /* If Order status changed, recalc Batch status as well */
  if (@vNewOrderStatus <> @vOrderStatus)
    exec pr_PickBatch_SetStatus @vPickBatchNo, null, @UserId;

  /* Clean up */
  delete from @PackDetails;

  /* Build the response */
  select @vLPNInfoxml = (select @vToLPN                    LPN,
                                coalesce(@vCarrier, '')    Carrier,
                                coalesce(@vShipVia, '')    ShipVia,
                                @vCartonType               CartonType,
                                @vCartonTypeDesc           CartonTypeDesc,
                                @Weight                    Weight,
                                coalesce(@vTrackingNo, '') TrackingNo,
                                coalesce(@vUCCBarcode, '') UCCBarcode,
                                @vPickTicket               PickTicket
                         for xml raw('LPNInfo'), elements );

  /* Default, create shipment is set to NO */
  select @vCreateShipment = 'N' /* No */;

  /* Re-Generate the label if the CartonType or Weight (Units) changed */
  if (@Action not in ('PackLPN', 'RFPacking')) and
     ((@vToLPNQty <> @vNewLPNQty) or
      (@vToLPNCartonType <> @vCartonType) or
      (coalesce(@vTrackingNo, '') = ''))
    if (@vCarrier in ('UPS', 'FEDEX', 'USPS', 'DHL'))
      begin
        exec pr_Shipping_ValidateToShip @OrderId, @vToLPNId, @vShipError output;

        if (coalesce(@vShipError, '') = '')
          select @vCreateShipment = 'Y' /* Yes */;
      end

  select @vPrintLabels    = case when (@Action in ('CloseLPN', 'ModifyLPN')) then 'Y' else 'N' end,
         @vPrintReports   = case when (@Action in ('CloseLPN', 'ModifyLPN')) then 'Y' else 'N' end,
         @vPrintDocuments = case when (@Action in ('CloseLPN', 'ModifyLPN')) then 'Y' else 'N' end,
         @vPrinter        = coalesce(nullif(@vPrinter,''), 'Zebra9'),
         @vLabelCopies    = '1';

  /* Append Printer Name */
  select @vXmlData = dbo.fn_XMLStuffValue(@vXmlData, 'Printer', @vPrinter),
         @vXmlData = dbo.fn_XMLStuffValue(@vXmlData, 'OrderStatus', @vNewOrderStatus);

  /* All labelling is only required if user has closed LPN */
  if (@Action in ('CloseLPN', 'ModifyLPN'))
    begin
      exec pr_Packing_GetLabelsToPrint @vXmlData, @vLabelsxml output;

      if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'GetLabelsToPrint';

      exec pr_Packing_GetDocumentsToPrint @vXmlData, @vReportsxml output, @vDocumentsxml output;

      if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'GetDocumentsToPrint';
    end

  /* Take the right 8 digits of UCC barcode */
  select @vUCCBarcodeSeq = right(@vUCCBarcode, 8);

  /* Framing result message - ToDo: Change message to be based upon contect i.e. closed or repacked etc. */
  select @vMessage = dbo.fn_Messages_Build('PackingSuccessful', @vPackageSeqNo, @vToLPN, @vUCCBarcodeSeq, @vPickTicket, null);
  set @vMessagesXML = '<Message>'                                             +
                         '<ResultMessage>' + @vMessage   + '</ResultMessage>' +
                         '<ShipError>'     + @vShipError + '</ShipError>'     +
                      '</Message>';

  /* Set print documents to yes only when there are any */
  select @vPrintDocuments = case when ((@vPrintDocuments = 'Y' /* Yes */) and (coalesce(@vDocumentsxml,'') <> '')) then 'Y' else 'N' end;

  /* Set print reports to yes only when there are any */
  select @vPrintReports = case when (coalesce(@vReportsxml,'') <> '') then 'Y' /* Yes */ else 'N' /* No */ end;

  /* Prepare Actions */
  select @vActionsxml = (select @vCreateShipment  CreateShipment,
                                @vPrintLabels     PrintLabels,
                                @vPrintReports    PrintReports,
                                @vPrintDocuments  PrintDocuments
                         for xml raw('Actions'), elements );

  select @OutputXML =  '<PackingCloseLPNInfo>'        +
                         coalesce(@vLPNInfoxml, '')   +
                         coalesce(@vActionsxml, '')   +
                         coalesce('<LabelsToPrint>'   + @vLabelsxml    + '</LabelsToPrint>', '') +
                         coalesce('<ReportsToPrint>'  + @vReportsxml   + '</ReportsToPrint>', '') +
                         coalesce('<DocumentsToPrint>'+ @vDocumentsxml + '</DocumentsToPrint>', '') +
                         coalesce(@vMessagesxml, '')  +
                       '</PackingCloseLPNInfo>';

  select @vPickBatchId = RecordId
  from PickBatches
  where (BatchNo = @vPickBatchNo) and (BusinessUnit = @BusinessUnit);

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
end /* pr_Packing_CloseLPN */

Go
