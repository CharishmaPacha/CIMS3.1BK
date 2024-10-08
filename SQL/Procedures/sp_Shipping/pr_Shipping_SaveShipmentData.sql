/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/12  PKK     pr_Shipping_SaveLPNData and pr_Shipping_SaveShipmentData: Made changes to insert into Background process to update trackingNo (BK-866)
  2021/11/12  OK      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Changes to update carrier and shiplabel as null in case of error in label generation (BK-689)
  2021/10/01  OK      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData, pr_Shipping_SavePalletShipmentData: Changes to update tracking no empty when there is error (BK-632)
  2021/06/10  RV      pr_Shipping_SaveShipmentData: Made changes to update entity key on ship labels table (CIMSV3-1453)
  2021/06/07  RV      pr_Shipping_SaveShipmentData: Made changes to update entity id on ship labels table (CIMSV3-1453)
  2020/06/25  RV      pr_Shipping_GetShipmentData: Included the ZPLIMAGELABEL to fill while create shipment
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Get the ZPLIMAGELABEL and save in ShipLabels table,
                        if label image type other than ZPL (HA-854)
  2020/05/28  RV      pr_Shipping_SaveShipmentData: Made changes to extract EntityKey from container as per response from CIMSSI
  2020/05/23  RT      pr_Shipping_GetShipmentData,pr_Shipping_SaveShipmentData: Mireated changes from S2G (HA-179)
  2020/02/24  YJ      pr_Shipping_GetShipmentData, pr_Shipping_RegenerateTrackingNumbers,
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData, pr_Shipping_ValidateToShip,
                      pr_Shipping_VoidShipLabels: Changes to update PickTicket, WaveNo, WaveId on ShipLabels (CID-1335)
  2019/12/05  TK      pr_Shipping_GetShipmentData, pr_Shipping_SaveShipmentData & fn_Shipping_GetCartonDetails:
                        Changes to get proper carton dimensions (S2GCA-1068)
  2019/11/26  HYP     pr_Shipping_SaveShipmentData/pr_Shipping_SaveLPNData and pr_Shipping_GetShipmentData:
                        Made changes to capture TrackingBarcode (FB-1546)
  2019/10/18  SV      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData:
                        Changes to save ServiceSymbol and MSN from ADSI interface (S2GCA-1010)
  2019/01/18  RV      pr_Shipping_GetShipmentData: Made changes to retun ManifestAction based on the rules
                        pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Made changes to update the CarrierInterface (S2GCA-434)
  2018/08/29  RV      pr_Shipping_GetShipmentData, pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData,
                      pr_Shipping_VoidShipLabels: Made changes to decide whether the shipment is small package carrier or not from
                        IsSmallPackageCarrier flag from ShipVias table (S2GCA-131)
  2018/07/13  RV      pr_Shipping_SaveShipmentData: Get the total weights from LPNs instead of Orders (S2G-1038)
  2018/07/11  RV      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Updated ProcessedDateTime while saving shipping label in ShipLabels table (S2G-1021)
  2018/07/10  RV      pr_Shipping_SaveShipmentData: Made changes to update net changes split with respect to the weight for multipackages (S2G-1004)
  2018/06/06  PK      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Added a caller to get the PrintDataStream to stuff additional info on the ZPL labels (S2G-921).
  2018/05/30  RV      pr_Shipping_SaveShipmentData: Made changes to update ProcessStatus propely while getting error (S2G-873)
  2018/04/10  RV      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Made changes to export shipping documents for
                        export required waves (S2G-545)
  2018/02/21  RV      pr_Shipping_GetShipmentData: Few of the migrated from OB Prod. Added validation for valid LPN or PickTicket.
                      pr_Shipping_GetShipmentData: Insert/update the carton into the shiplabel table while raising error
                      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Process error status changed Error (E) to Label Generation Error (LGE)
  2018/02/09  RV      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Made changes to Processed status
                        based up on the response (S2G-110)
  2018/02/01  RV      pr_Shipping_GetShipmentData: Get the Label image type (ZPL/PNG) from rules and retun in Request xml to
                        get the ZPL/PNG
                      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Save Label image and ZPL save appropriate column (HPI-113)
  2017/08/18  DK      pr_Shipping_SaveShipmentData: Bug fix to handle special characters from inputxml (FB-1004).
  2017/05/04  DK      pr_Shipping_SaveShipmentData: Enhanced to save Shipvia on order (CIMS-1259)
  2017/04/20  NB      pr_Shipping_SaveShipmentData(CIMS-1259)
                        LPN is the seond param for pr_LPNs_Ship procedure
  2017/04/14  NB      pr_Shipping_SaveShipmentData(CIMS-1259)
                        changes to read and update ShipLabels.ZPLLabel field
  2017/04/13  NB      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData(CIMS-1259)
                        changes to update ShipLabels RequestedShipVia and ShipVia
  2017/03/22  NB      Modified  pr_Shipping_GetShipmentData (CIMS-1259)
                        to read CarrierInterface from rules, return CarrierInterface in XML.
                        Added new Carrier, ShipVia nodes in Response xml structure
                      Modified pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData
                        to read Carrier and ShipVia from Response, and update to ShipLabels.ShippingDetail
  2016/08/09  KN      pr_Shipping_SaveShipmentData: Considering shiplabels table also (HPI-740)
  2016/08/09  KN      pr_Shipping_SaveShipmentData: Modified code for updating "Reference" from "RESPONSE" node (HPI-560)
  2016/08/03  KN      pr_Shipping_SaveShipmentData: Modified code for updating "Listnetcharges" and "Accnetcharges" from "RESPONSE" node (HPI-518)
  2016/08/03  RV      pr_Shipping_SaveShipmentData: Added new procedure to save the multiple ship label data for the small package carriers (HPI-414)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_SaveShipmentData') is not null
  drop Procedure pr_Shipping_SaveShipmentData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_SaveShipmentData: The purpose of this procedure is to save the
    data returned by the Carrier Webservice (including the shipping label image)
    and save to the database.

  LPN/LPNId      : Refer to the applicable LPN
  ShippingLPNData: Refers to the ShippingData received from the carrier.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_SaveShipmentData
  (@LPN          TLPN        = null,
   @LPNId        TRecordId   = null,
   @PickTicket   TPickTicket = null,
   @OrderId      TRecordId   = null,
   @ShippingData varchar(max))
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,

          @vRecordId           TRecordId,
          @vShippingLPNxml     xml,
          @vShipLabelRecordId  TRecordId,
          @vOrderHeaderShipVia TShipVia,
          @vRequestedShipVia   TShipVia,
          @vLPNShipVia         TDescription,
          @vMappedLPNShipvia   TShipVia,
          @vLPN                TLPN,
          @vPackageLength      TLength,
          @vPackageWidth       TWidth,
          @vLPNId              TRecordId,
          @vPackageHeight      THeight,
          @vLPNStatus          TStatus,
          @vLPNShippedCount    TInteger,
          @vLPNOrderId         TRecordId,
          @vOrderId            TRecordId,
          @vPickTicket         TPickTicket,
          @vWaveId             TRecordId,
          @vWaveNo             TPickBatchNo,
          @vWaveType           TTypeCode,
          @vLabelType          TTypeCode,
          @vLabelImageType     TTypeCode,
          @vLabelImage         varbinary(max),
          @vZPLLabelImage      TVarchar,
          @vTrackingNo         TTrackingNo,
          @vTrackingBarcode    TTrackingNo,
          @vServiceSymbol      TCarrier,
          @vMSN                TCarrier,
          @vBarcode            TVarChar,
          @vNumLPNs            TInteger,
          @vTotalWeight        TWeight,
          @vTotalVolume        TVolume,

          @vTotalPackages      TCount,
          @vTotalListNetCharge TMoney,
          @vTotalAcctNetCharge TMoney,
          @vListNetCharge      TMoney,
          @vAcctNetCharge      TMoney,
          @vRemainderListNetCharge
                               TMoney,
          @vRemainderAcctNetCharge
                               TMoney,
          @vInsuranceFee       TMoney,
          @vReferences         TVarchar,

          @vProcessStatus      TStatus,
          @vBusinessUnit       TBusinessUnit,
          @vIsSmallPackageCarrier
                               TFlag,
          @vCarrier            TCarrier,
          @vCarrierInterface   TCarrierInterface,
          @vNotifications      TVarChar,
          @vUserId             TUserId,
          @vAutoShipOnLabel    TFlag,
          @vSourceStartIndex   TInteger,
          @vTraceStartIndex    TInteger,
          @vNotificationSource TVarchar,
          @vNotificationTrace  TVarchar,
          @vWaveTypesToExportShippingDocs
                               TControlValue,
          @vStuffAdditionalInfoOnZPL
                               TControlValue,
          @vDebug              TFlag;

  declare @ttShipLabel table
          (RecordId       TRecordId identity(1,1),
           EntityId       TRecordId,
           EntityKey      TEntityKey,
           OrderId        TRecordId,
           TotalPackages  TCount,
           LabelType      TTypeCode,
           Label          TShippingLabel,
           ZPLLabel       TVarchar,
           TrackingNo     TTrackingNo,
           TrackingBarcode TTrackingNo,
           Barcode        TVarChar,
           Carrier        TDescription,
           ShipVia        TDescription,
           ServiceSymbol  TCarrier,
           MSN            TCarrier,
           ListNetCharge  TMoney,
           AcctNetCharge  TMoney,
           InsuranceFee   TMoney,
           Reference      TVarChar,
           BusinessUnit   TBusinessUnit
           );

declare @ttCartonDetails table
         (LPN               TLPN,
          PackageLength     TLength,
          PackageWidth      TLength,
          PackageHeight     TLength,

          unique(LPN));

declare    @ttMarkers     TMarkers;
begin /* pr_Shipping_SaveShipmentData */
  select @ReturnCode  = 0,
         @Messagename = null,
         @vRecordId   = 0;

  /* Validations */
  if (coalesce(@ShippingData, '') = '')
    set @MessageName = 'InvalidShippingData';

  if (@MessageName is not null)
    goto ErrorHandler;

  select @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (Carrier = @vCarrier);

  if (@vIsSmallPackageCarrier = 'N' /* No */) /* Nothing to do */
    goto ExitHandler;

  /* convert the Data into XML, remove XML headers */
  select @vShippingLPNxml =  convert(XML, replace(cast(@ShippingData as nvarchar(max)), '<?xml version="1.0" encoding="UTF-8"?>', '<?xml version="1.0" encoding="UTF-16"?>'));

  /*
                     '<RESPONSE>' +
                     '<LabelType>S</LabelType>' +   -- S-Shipping label; RL-Return Label
                     '<IMAGELABEL>Image Label Here </IMAGELABEL>' +
                     '<TRACKINGNO>Tracking Number here</TRACKINGNO>' +
                     '<RATE>Rate here</RATE>' +
                     '<SHIPPINGCHARGES>Shipping Charges here</SHIPPINGCHARGES>' +
                     '<ROUTECODE>Route code here</ROUTECODE>' +
                     '<NOTIFICATIONS>Messages here </NOTIFICATIONS>'
                     '</RESPONSE>';

   Read the response node from the received xml
   identify specific nodes and update them to the database as applicable

  */

  select @vOrderId          = Record.Col.value('OrderId[1]',          'TRecordId'),
         @vCarrierInterface = Record.Col.value('CARRIERINTERFACE[1]', 'TCarrierInterface'),
         @vRequestedShipVia = Record.Col.value('ShipVia[1]',          'TShipVia'),
         @vBusinessUnit     = Record.Col.value('BusinessUnit[1]',     'TBusinessUnit'),
         @vTotalPackages    = Record.Col.value('NumLPNs[1]',          'TCount')
  from @vShippingLPNxml.nodes('/SHIPPINGINFO/REQUEST/ORDERHEADER')  as Record(Col);

  /* There may be multiple cartons for an order, so get all the cartons information */
  insert into @ttCartonDetails(LPN, PackageLength, PackageWidth, PackageHeight)
    select Record.Col.value('LPN[1]',                 'TLPN'),
           Record.Col.value('OuterLength[1]',         'TLength'),
           Record.Col.value('OuterWidth[1]',          'TWidth'),
           Record.Col.value('OuterHeight[1]',         'THeight')
    from @vShippingLPNxml.nodes('/SHIPPINGINFO/REQUEST/PACKAGES/PACKAGE/CARTONDETAILS') as Record(Col);

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'pr_Shipping_SaveShipmentData_Start';

  select @vLabelType     = Record.Col.value('LABELTYPE[1]',     'TTypeCode'),
         @vNotifications = Record.Col.value('NOTIFICATIONS[1]', 'TVarChar')
  from @vShippingLPNxml.nodes('/SHIPPINGINFO/RESPONSE')  as Record(Col);

  /* We are using Shipvia and Carrier - interchangeably - they are diff */
  select @vCarrier = Record.Col.value('CARRIER[1]', 'TCarrier')
  from @vShippingLPNxml.nodes('/SHIPPINGINFO/REQUEST/SHIPVIA')  as Record(Col);

  select @vLabelImageType = Record.Col.value('LabelImageType[1]', 'TTypeCode')
  from @vShippingLPNxml.nodes('/SHIPPINGINFO/REQUEST/LABELATTRIBUTES')  as Record(Col);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ShippingInfo_LableAttributes_Extracted';

  select @vWaveId      = PickBatchId,
         @vWaveNo      = PickBatchNo,
         @vWaveType    = WaveType,
         @vPickTicket  = PickTicket
  from vwOrderHeaders
  where (OrderId = @vOrderId);

  /* Get the valid wave types to export shipping documents to WSS,
     Get the control value to determine whether to stuff additional info on the ZPL labels or not */
  select @vWaveTypesToExportShippingDocs = dbo.fn_Controls_GetAsString('ExportShippingDocs', 'WaveTypesToExportShippingDocs', '', @vBusinessUnit, null /* UserId */),
         @vStuffAdditionalInfoOnZPL      = dbo.fn_Controls_GetAsString('ShipLabels', 'StuffAdditionalInfoOnZPL', 'N', @vBusinessUnit, null /* UserId */);

  /* We are appending 'Error' keyword for error message in all shipping services (exception handling). So, using it verify the error.
     Note: UPS returns empty if shipment successfully created
           FedEx returns success message if shipment successfully created */
  select @vProcessStatus = case
                             when (charindex('Error', @vNotifications) > 0) then
                               'LGE' /* Label Generation Error */
                             when (charindex(@vWaveType, @vWaveTypesToExportShippingDocs) > 0) then
                               'XR' /* Export Required */
                             else
                               'LG' /* Label Generated */
                           end;

  /* If there is notification message, then parse it */
  if (coalesce(@vNotifications, '') <> '' )
    exec pr_Shipping_ParseCarrierNotifications null, @vNotifications, @vCarrier, @vRequestedShipVia, null, @vNotifications output, @vNotificationSource output, @vNotificationTrace output

  /* Insert all packages into temp table */
  insert into @ttShipLabel(EntityId, EntityKey, TotalPackages, Label, ZPLLabel, TrackingNo, TrackingBarcode, Barcode, Carrier, ShipVia, ServiceSymbol, MSN, InsuranceFee, Reference)
    select Record.Col.value('CONTAINERID[1]',         'TRecordId'),
           Record.Col.value('CONTAINER[1]',           'TEntityKey'),
           @vTotalPackages,
           Case
             when @vLabelImageType in ('PNG', 'PDF') then /* in the case of USPS the format is set to PDF, with ADSI Interface this is returned as PNG by default */
               dbo.fn_Base64ToBinary(Record.Col.value('IMAGELABEL[1]', 'varchar(max)')) /* cannot use domain TSHIPPINGLABEL OR IMAGE TYPE HERE */
             else
               null
           end,
           Case
             when @vLabelImageType = 'ZPL' then
               dbo.fn_Base64ToVarchar(Record.Col.value('IMAGELABEL[1]', 'varchar(max)')) /* cannot use domain TSHIPPINGLABEL OR IMAGE TYPE HERE */
             else
               null
           end,
           coalesce(nullif(Record.Col.value('TRACKINGNO[1]', 'TTrackingNo'), 'Tracking Number here'), ''),
           Record.Col.value('TRACKINGBARCODE[1]', 'TTrackingNo'),
           Record.Col.value('BARCODE[1]',         'TVarChar'),
           nullif(Record.Col.value('CARRIER[1]',  'TDescription'), 'Carrier here'),
           nullif(Record.Col.value('SHIPVIA[1]',  'TDescription'), 'Ship Via here'),
           Record.Col.value('ServiceSymbol[1]',   'TCarrier'),
           Record.Col.value('MSN[1]',             'TCarrier'),
           Record.Col.value('InsuranceFee[1]',    'TMoney'),
           Record.Col.value('REFERENCES[1]',      'TVarChar')
    from @vShippingLPNxml.nodes('/SHIPPINGINFO/RESPONSE/PACKAGES/PACKAGE') as Record(Col);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ShippingInfo_Packages_Extracted';

  /* Capturing Total ListNetCharges and Total AccNetCharges from response node since it is common for all packages
     fetch charges and update rows in shiplabel temp table */
  select @vTotalListNetCharge = Record.Col.value('LISTNETCHARGES[1]', 'TMoney'),
         @vTotalAcctNetCharge = Record.Col.value('ACCTNETCHARGES[1]', 'TMoney'),
         @vReferences         = Record.Col.value('REFERENCES[1]',     'TVarChar')
  from @vShippingLPNxml.nodes('/SHIPPINGINFO/RESPONSE') as Record(Col)

  /* Get the total LPNs weight & volume to use further */
  select @vTotalWeight = sum(L.LPNWeight),
         @vTotalVolume = sum(L.LPNVolume)
  from @ttShipLabel ttSL
    join LPNs L on (L.LPN = ttSL.EntityKey);

  /* Get Number of LPNs from response -> No.of records are No.of LPNs */
  select @vNumLPNs = count(*)
  from @ttShipLabel

  /* For MultiPackage Shipment, need to split the charges */
  if (@vNumLPNs > 1)
    begin
      /* Share total charges to each LPN by calculating LPN charges based on Order total weight and LPN weight */
      update ttSL
      set ttSL.ListNetCharge = round((L.LPNWeight / @vTotalWeight) * @vTotalListNetCharge, 2),
          ttSL.AcctNetCharge = round((L.LPNWeight / @vTotalWeight) * @vTotalAcctNetCharge, 2),
          ttSL.Reference     = @vReferences
      from @ttShipLabel ttSL
        join LPNs L on (L.LPN = ttSL.EntityKey);

      /* Get the remainder values to add it to any one of the charges of LPN of the shipment */
      select @vRemainderListNetCharge = @vTotalListNetCharge - sum(ListNetCharge),
             @vRemainderAcctNetCharge = @vTotalAcctNetCharge - sum(AcctNetCharge)
      from @ttShipLabel

      /* Add remainder values to the charges of first LPN of the shipment */
      update @ttShipLabel
      set ListNetCharge += @vRemainderListNetCharge,
          AcctNetCharge += @vRemainderAcctNetCharge
      from @ttShipLabel
      where (RecordId = 1);
    end
  else
    /* If it is a single package (not a MultiPackage Shipment) - total charges apply to one LPN only */
    update @ttShipLabel
    set ListNetCharge = @vTotalListNetCharge,
        AcctNetCharge = @vTotalAcctNetCharge,
        Reference     = @vReferences

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ShippingInfo_Charges_Extracted';

  /* Possible values S - Shipping label, RL - Return Label
     Default it to S - Shipping label, in case caller did not send any */
  select @vLabelType = coalesce(nullif(@vLabelType, ''), 'S' /* Shipping Label */);

  while (exists(select EntityKey from @ttShipLabel where RecordId > @vRecordId))
    begin
      /* select top 1 here */
      select top 1 @vLPNId         = EntityId,
                   @vLPN           = EntityKey,
                   @vTotalPackages = TotalPackages,
                   @vLabelImage    = Label,
                   @vZPLLabelImage = ZPLLabel,
                   @vTrackingNo    = TrackingNo,
                   @vTrackingBarcode = TrackingBarcode,
                   @vBarcode       = Barcode,
                   @vListNetCharge = ListNetCharge,
                   @vAcctNetCharge = AcctNetCharge,
                   @vServiceSymbol = ServiceSymbol,
                   @vMSN           = MSN,
                   @vInsuranceFee  = InsuranceFee,
                   @vRecordId      = RecordId,
                   @vReferences    = Reference,
                   @vLPNShipVia    = ShipVia,
                   @vCarrier       = Carrier
      from @ttShipLabel
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get Carton Dims */
      select @vPackageLength = PackageLength,
             @vPackageHeight = PackageHeight,
             @vPackageWidth  = PackageWidth
      from @ttCartonDetails
      where (LPN = @vLPN);

      /* Check if the Shipping label already exists for the LPN */
      select @vShipLabelRecordId = RecordId
      from ShipLabels
      where (EntityType = 'L' /* LPN */ ) and
            (EntityKey  = @vLPN         ) and
            (LabelType  = @vLabelType);

      /* Stuff some additional information on the ZPL label */
      if ((@vLabelImageType = 'ZPL') and (@vZPLLabelImage is not null) and (@vStuffAdditionalInfoOnZPL = 'Y'/* Yes */))
        exec pr_ShipLabel_CustomizeZPL @vLPN, @vCarrier, @vZPLLabelImage, @vBusinessUnit, null /* UserId */, @vZPLLabelImage output;

      /* For some reason, ZPL labels are inverted, so correct it */
      select @vZPLLabelImage = replace(@vZPLLabelImage, '^POI', '^PON');

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ShippingInfo_GetLabelInfo_Completed';

      /* If Shiplabel already does not exist then insert else update */
      if (coalesce(@vShipLabelRecordId, 0) = 0)
        begin
          /* There is no existing entry for the LPN Shippng Label */
          insert into ShipLabels (EntityType, EntityId, EntityKey, PackageLength, PackageWidth, PackageHeight, PackageWeight, PackageVolume,
                                  OrderId, PickTicket, TotalPackages, WaveId, WaveNo, LabelType, Label, ZPLLabel,
                                  TrackingNo, TrackingBarcode, Barcode, RequestedShipVia, ShipVia, Carrier, CarrierInterface, ServiceSymbol, MSN,
                                  ListNetCharge, AcctNetCharge, InsuranceFee, ProcessStatus, ProcessedDateTime, Reference, Notifications, NotificationSource, NotificationTrace, BusinessUnit)
            select 'L', @vLPNId, @vLPN, @vPackageLength, @vPackageWidth, @vPackageHeight, @vTotalWeight, @vTotalVolume,
                   @vOrderId, @vPickTicket, @vTotalPackages, @vWaveId, @vWaveNo, @vLabelType, @vLabelImage, @vZPLLabelImage,
                   coalesce(@vTrackingNo, ''), coalesce(@vTrackingBarcode, ''), @vBarcode, @vRequestedShipVia, @vLPNShipVia, @vCarrier, @vCarrierInterface, @vServiceSymbol, @vMSN,
                   @vListNetCharge, @vAcctNetCharge, @vInsuranceFee, @vProcessStatus, current_timestamp, @vReferences, @vNotifications, @vNotificationSource, @vNotificationTrace,  @vBusinessUnit;

          /* Following code extracts additional images from input xml and inserts in to shiplabels table */
          insert into ShipLabels (EntityType, EntityId, EntityKey, PackageLength, PackageWidth, PackageHeight,PackageWeight, PackageVolume,
                                  OrderId, PickTicket, TotalPackages, WaveId, WaveNo, LabelType, Label,
                                  TrackingNo, Barcode, RequestedShipVia, ShipVia, Carrier, CarrierInterface, ServiceSymbol, MSN,
                                  ListNetCharge, AcctNetCharge, ProcessStatus, ProcessedDateTime, Reference, Notifications, NotificationSource, NotificationTrace, BusinessUnit)
            select 'L', @vLPNId, @vLPN , @vPackageLength, @vPackageWidth, @vPackageHeight, @vTotalWeight, @vTotalVolume,
                   @vOrderId, @vPickTicket, @vTotalPackages, @vWaveId, @vWaveNo, 'S'+ convert(varchar,row_number() over (order by  imageList.col.query('.').value('base64Binary[1]','varchar(max)'))) , dbo.fn_Base64ToBinary( imageList.col.query('.').value('base64Binary[1]','varchar(max)')) ,
                   coalesce(@vTrackingNo, ''), @vBarcode, @vRequestedShipVia, @vLPNShipVia, @vCarrier, @vCarrierInterface, @vServiceSymbol, @vMSN,
                   cast(@vListNetCharge as money), cast(@vAcctNetCharge as money), @vProcessStatus, current_timestamp, @vReferences, @vNotifications, @vNotificationSource, @vNotificationTrace,  @vBusinessUnit
            from @vShippingLPNxml.nodes('/SHIPPINGINFO/RESPONSE/IMAGELIST/base64Binary') as imageList(col)
        end
      else
        begin
          /* Update ShipLabel, TrackingNumber and ShipVia for the existing record */
          update ShipLabels
          set TotalPackages      = @vTotalPackages,
              TrackingNo         = @vTrackingNo,
              TrackingBarcode    = @vTrackingBarcode,
              PackageLength      = @vPackageLength,
              PackageWidth       = @vPackageWidth,
              PackageHeight      = @vPackageHeight,
              PackageWeight      = @vTotalWeight,
              PackageVolume      = @vTotalVolume,
              Barcode            = @vBarcode,
              Label              = @vLabelImage,
              ZPLLabel           = @vZPLLabelImage,
              RequestedShipVia   = @vRequestedShipVia, /* Why do we need to do this? AY .. We have kept this information to know against which Shipvia is this Label generated for */
              ShipVia            = @vLPNShipVia,
              CarrierInterface   = @vCarrierInterface,
              ServiceSymbol      = @vServiceSymbol,
              MSN                = @vMSN,
              ListNetCharge      = @vListNetCharge,
              AcctNetCharge      = @vAcctNetCharge,
              InsuranceFee       = @vInsuranceFee,
              ProcessStatus      = @vProcessStatus,
              ProcessedDateTime  = current_timestamp,
              AlertSent          = case
                                     when (@vProcessStatus = 'LGE') then 'T' /* To be sent */
                                     else AlertSent
                                   end,
              Reference          = @vReferences,
              Notifications      = @vNotifications,
              NotificationSource = @vNotificationSource,
              NotificationTrace  = @vNotificationTrace,
              ModifiedDate       = current_timestamp
          where (ShipLabels.RecordId = @vShipLabelRecordId);
        end

       if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ShippingInfo_LabelInsertorUpdate_Completed';

      /* Update tracking number on LPN and AutoShip of LPN should be done only when Label Type is Ship label,
         not when Return Label */
      if (@vLabelType = 'S' /* Shippping Label */)
        begin
          /* Update LPN with latest tracking no */
          update LPNs
          set TrackingNo  = @vTrackingNo,
              @vLPNStatus = Status
          where (LPN = @vLPN);

          if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ShippingInfo_TrackingNoUpdationOnLPN_Completed';

          /* When the Shipment was created successfully online, then Mark the LPN as Shipped */
          set @vUserId = System_user;

          /* status update on Labeling the LPN and the order of the Shipped LPN */
          select  @vAutoShipOnLabel = dbo.fn_Controls_GetAsBoolean('AutoShipLPN', 'ShipOnLabel',
                                                               'N', @vBusinessUnit, @vUserId);

          if ((@vLPNStatus       <> 'S' /* Shipped */) and
              (@vAutoShipOnLabel =  'Y' /* Yes */    ) and
              (coalesce(@vTrackingNo, '') <> '')  and
              (@vLabelImage is not null)) -- $$ Could be ZPL is available?
            exec pr_LPNs_Ship null /* @LPNId */, @vLPN, @vBusinessUnit, @vUserId;
        end

      /* Reinitializing the variable */
      select @vShipLabelRecordId = null;
    end /* While loop end */

  /* Get the LPN.TrackingNumber and update on OrderHeaders */
  exec pr_Entities_ExecuteInBackGround 'Order', @vOrderId, null, default /* ProcessClass */,
                                        @@ProcId, 'UpdateTrackingNos'/* Operation */, @vBusinessUnit;

    if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'pr_Shipping_SaveShipmentData_End';

    if (charindex('M', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'Shipping', @LPNId, @LPN, 'SaveShipmentData', @@ProcId, 'Markers_SaveShipmentData';

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_SaveShipmentData */

Go
