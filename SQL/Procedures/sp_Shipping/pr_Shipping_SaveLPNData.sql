/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/12  PKK     pr_Shipping_SaveLPNData and pr_Shipping_SaveShipmentData: Made changes to insert into Background process to update trackingNo (BK-866)
  2021/11/12  OK      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Changes to update carrier and shiplabel as null in case of error in label generation (BK-689)
  2021/10/01  OK      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData, pr_Shipping_SavePalletShipmentData: Changes to update tracking no empty when there is error (BK-632)
  2021/08/02  RV      pr_Shipping_SaveLPNData & pr_Shipping_RegenerateTrackingNumbers: Made changes to insert EntityId on ShipLabels (BK-460)
  2020/06/25  RV      pr_Shipping_GetShipmentData: Included the ZPLIMAGELABEL to fill while create shipment
                        pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Get the ZPLIMAGELABEL and save in ShipLabels table,
                        if label image type other than ZPL (HA-854)
  2020/02/24  YJ      pr_Shipping_GetShipmentData, pr_Shipping_RegenerateTrackingNumbers,
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData, pr_Shipping_ValidateToShip,
                      pr_Shipping_VoidShipLabels: Changes to update PickTicket, WaveNo, WaveId on ShipLabels (CID-1335)
  2019/11/26  HYP     pr_Shipping_SaveShipmentData/pr_Shipping_SaveLPNData and pr_Shipping_GetShipmentData:
  2019/10/18  SV      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData:
  2019/01/18  RV      pr_Shipping_GetShipmentData: Made changes to retun ManifestAction based on the rules
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Made changes to update the CarrierInterface (S2GCA-434)
  2018/08/29  RV      pr_Shipping_GetShipmentData, pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData,
                      pr_Shipping_VoidShipLabels: Made changes to decide whether the shipment is small package carrier or not from
                        IsSmallPackageCarrier flag from ShipVias table (S2GCA-131)
  2018/07/11  RV      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Updated ProcessedDateTime while saving shipping label in ShipLabels table (S2G-1021)
  2018/06/06  PK      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Added a caller to get the PrintDataStream to stuff additional info on the ZPL labels (S2G-921).
  2018/04/10  RV      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Made changes to export shipping documents for
                        export required waves (S2G-545)
  2018/02/21  RV      pr_Shipping_GetShipmentData: Few of the migrated from OB Prod. Added validation for valid LPN or PickTicket.
                      pr_Shipping_GetShipmentData: Insert/update the carton into the shiplabel table while raising error
                      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Process error status changed Error (E) to Label Generation Error (LGE)
  2018/02/18  RV      pr_Shipping_SaveLPNData: Made changes to save ZPL label as varchar (S2G-113)
  2018/02/09  RV      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Made changes to Processed status
                        based up on the response (S2G-110)
  2018/02/01  RV      pr_Shipping_GetShipmentData: Get the Label image type (ZPL/PNG) from rules and retun in Request xml to
                        get the ZPL/PNG
                      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Save Label image and ZPL save appropriate column (HPI-113)
  2017/08/21  OK      pr_Shipping_SaveLPNData: Temp bug fix to prevent ovverriding the TrackingNumber on LPN for LTL orders (HPI-1640)
  2017/04/13  NB      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData(CIMS-1259)
                        changes to update ShipLabels RequestedShipVia and ShipVia
  2017/03/22  NB      Modified  pr_Shipping_GetShipmentData (CIMS-1259)
                        to read CarrierInterface from rules, return CarrierInterface in XML.
                        Added new Carrier, ShipVia nodes in Response xml structure
                      Modified pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData
                        to read Carrier and ShipVia from Response, and update to ShipLabels.ShippingDetail
  2016/06/27  NY      pr_Shipping_SaveLPNData: Save List and Account Charges (OB-427)
  2016/05/11  RV      pr_Shipping_SaveLPNData: Update the OrderId in Ship Labels table
                      pr_Shipping_VoidShipLabels: Not allowed to void shipped labels (NBD-506)
  2016/03/23  KN      pr_Shipping_SaveLPNData: refactored code for saving additional images (NBD-163)
  2016/03/18  KN      pr_Shipping_SaveLPNData: Added code to save additional images (NBD-163)
  2016/02/10  KN      pr_Shipping_SaveLPNData added USPS.in if condition (NBD-162)
  2015/09/25  VM      pr_Shipping_SaveLPNData: Enhanced to use it for return LPN Label data saving as well (FB-386)
  2015/08/20  DK      pr_Shipping_SaveLPNData: Modified to validate LPN status before invoking 'pr_LPNs_Ship' procedure (FB-305).
  2015/05/22  RV      pr_Shipping_SaveLPNData: Split the Notification and insert/update to respective fields
  2015/04/20  DK      pr_Shipping_SaveLPNData: Made changes to get ShipVia from LPNs if Order Shipvia is not specified.
  2013/04/03  YA      pr_Shipping_SaveLPNData: Modified to accept for UPS.
  2011/10/21  NB      pr_Shipping_GetPackingListData - Fix to read ShipVia from OrderHeaders
                      pr_Shipping_SaveLPNData: Minor fix - call to pr_LPNs_Ship corrected
  2011/10/21  NB      pr_Shipping_SaveLPNData - Enhanced to Mark LPN as Shipped, based on Controls
  2011/10/13  NB      pr_Shipping_SaveLPNData: Save Notifications to ShipLabels Notifications Column
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_SaveLPNData') is not null
  drop Procedure pr_Shipping_SaveLPNData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_SaveLPNData: The purpose of this procedure is to save the
    data returned by the Carrier Webservice (including the shipping label image)
    and save to the database.

  LPN/LPNId      : Refer to the applicable LPN
  ShippingLPNData: Refers to the ShippingData received from the carrier.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_SaveLPNData
  (@LPN             TLPN      = null,
   @LPNId           TRecordId = null,
   @ShippingLPNData varchar(max))
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @vShippingLPNxml     xml,
          @vShipLabelRecordId  TRecordId,
          @vRequestedShipVia   TShipVia,
          @vShipVia            TDescription,
          @vShipFrom           TShipFrom,
          @vAccount            TAccount,
          @vAccountName        TAccountName,
          @vOwnership          TOwnership,
          @vWarehouse          TWarehouse,
          @vOrderId            TRecordId,
          @vPickTicket         TPickTicket,
          @vWaveId             TRecordId,
          @vWaveNo             TPickBatchNo,
          @vWaveType           TTypeCode,
          @vLPNStatus          TStatus,
          @vLabelType          TTypeCode,
          @vLabelImageType     TTypeCode,
          @vLabelImage         varbinary(max),
          @vZPLLabelImage      TVarchar,
          @vTrackingNo         TTrackingNo,
          @vTrackingBarcode    TTrackingNo,
          @vServiceSymbol      TCarrier,
          @vMSN                TCarrier,
          @vPackageLength      TLength,
          @vPackageWidth       TWidth,
          @vPackageHeight      THeight,
          @vTotalWeight        TWeight,
          @vTotalVolume        TVolume,
          @vListNetCharge      varchar(15),
          @vAcctNetCharge      varchar(15),
          @vReferences         TVarchar,
          @vProcessStatus      TStatus,
          @vLPNShipVia         TDescription,
          @vLPNCarrier         TDescription,
          @vBusinessUnit       TBusinessUnit,
          @vNotifications      TVarChar,
          @vUserId             TUserId,
          @vAutoShipOnLabel    TFlag,
          @vSourceStartIndex   TInteger,
          @vTraceStartIndex    TInteger,

          /* Carrier Info */
          @vIsSmallPackageCarrier
                               TFlag,
          @vCarrier            TCarrier,
          @vCarrierRulexmlData varchar(max),
          @vCarrierInterface   TCarrierInterface,
          @vNotificationSource TVarchar,
          @vNotificationTrace  TVarchar,

          @vWaveTypesToExportShippingDocs
                               TControlValue,
          @vStuffAdditionalInfoOnZPL
                               TControlValue;
begin /* pr_Shipping_SaveLPNData */
  select @ReturnCode  = 0,
         @Messagename = null;

  /* If we do not have LPNId, fetch it */
  if (@LPNId is null)
    select @LPNId = LPNId
    from LPNs
    where (LPN = @LPN);

  if (@LPNId is null)
    set @MessageName = 'LPNDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get required values to update in the Ship Labels table */
  select @vOrderId     = OrderId,
         @vTotalWeight = LPNWeight,
         @vTotalVolume = LPNVolume
  from LPNs L
  where (L.LPNId = @LPNId);

  select @vWaveId          = PickBatchId,
         @vWaveNo          = PickBatchNo,
         @vWaveType        = WaveType,
         @vPickTicket      = PickTicket,
         @vShipVia         = ShipVia,
         @vCarrier         = Carrier,
         @vShipFrom        = ShipFrom,
         @vAccount         = Account,
         @vAccountName     = AccountName,
         @vOwnership       = Ownership,
         @vWarehouse       = Warehouse,
         @vBusinessUnit    = BusinessUnit
  from vwOrderHeaders
  where (OrderId = @vOrderId);

  /* Get the valid wave types to export shipping documents to WSS,
     Get the control value to determine whether to stuff additional info on the ZPL labels or not */
  select @vWaveTypesToExportShippingDocs = dbo.fn_Controls_GetAsString('ExportShippingDocs', 'WaveTypesToExportShippingDocs', '', @vBusinessUnit, null /* UserId */),
         @vStuffAdditionalInfoOnZPL      = dbo.fn_Controls_GetAsString('ShipLabels', 'StuffAdditionalInfoOnZPL', 'N', @vBusinessUnit, null /* UserId */);

  /* Retrieve Carrier Interface  */
  select @vCarrierRulexmlData = '<RootNode>' +
                                   dbo.fn_XMLNode('Carrier',       @vCarrier) +
                                   dbo.fn_XMLNode('ShipVia',       @vShipVia) +
                                   dbo.fn_XMLNode('Account',       @vAccount) +
                                   dbo.fn_XMLNode('AccountName',   @vAccountName) +
                                   dbo.fn_XMLNode('Ownership',     @vOwnership) +
                                   dbo.fn_XMLNode('Warehouse',     @vWarehouse) +
                                   dbo.fn_XMLNode('ShipFrom',      @vShipFrom) +
                                '</RootNode>';

  exec pr_RuleSets_Evaluate 'CarrierInterface', @vCarrierRulexmlData, @vCarrierInterface output;

  /* If no rules are defined, then use DIRECT option as carrier interface */
  select @vCarrierInterface = coalesce(@vCarrierInterface, 'DIRECT')

  if (@vCarrierInterface = 'ADSI')
   begin
     exec pr_Shipping_SaveShipmentData @LPN, @LPNId, '', '', @ShippingLPNData;
     goto Exithandler;
   end

  /* convert the Data into XML */
  select @vShippingLPNxml = convert(xml, @ShippingLPNData);

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
  select @vRequestedShipVia = Record.Col.value('ShipVia[1]',          'TShipVia'),
         @vCarrierInterface = Record.Col.value('CarrierInterface[1]', 'TCarrierInterface')
  from  @vShippingLPNxml.nodes('/SHIPPINGLPNINFO/REQUEST/ORDERHEADER')  as Record(Col);

  select @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit')
  from  @vShippingLPNxml.nodes('/SHIPPINGLPNINFO/REQUEST/LPNHEADER')  as Record(Col);

  select @vLabelImageType = Record.Col.value('LabelImageType[1]', 'TTypeCode')
  from @vShippingLPNxml.nodes('/SHIPPINGLPNINFO/REQUEST/LABELATTRIBUTES')  as Record(Col);

  select @vLabelType     = Record.Col.value('LABELTYPE[1]', 'TTypeCode'),
         @vLabelImage    = case when (@vLabelImageType <> 'ZPL')
                             then dbo.fn_Base64ToBinary(Record.Col.value('IMAGELABEL[1]', 'varchar(max)'))
                           else
                             null
                           end, /* CANNOT USE TSHIPPINGLABEL OR IMAGE TYPE HERE */
         @vZPLLabelImage = case when (@vLabelImageType = 'ZPL')
                             then dbo.fn_Base64ToVarchar(Record.Col.value('IMAGELABEL[1]', 'varchar(max)'))
                           else
                             dbo.fn_Base64ToVarchar(Record.Col.value('ZPLIMAGELABEL[1]', 'varchar(max)'))
                           end,
         @vTrackingNo    = coalesce(nullif(Record.Col.value('TRACKINGNO[1]', 'TTrackingNo'), 'Tracking Number here'), ''),
         @vServiceSymbol = Record.Col.value('ServiceSymbol[1]', 'TCarrier'),
         @vMSN           = Record.Col.value('MSN[1]', 'TCarrier'),
         /* Temp solution to fetch ListNetCharge from right node for USPS */
         @vListNetCharge = case
                             when @vCarrier = 'USPS' then
                               Record.Col.value('SHIPPINGCHARGES[1]', 'varchar(15)')
                             else
                               Record.Col.value('LISTNETCHARGES[1]', 'varchar(15)')
                            end, --Here datatype needs to be changed to TMoney but to do this, we need to change the XSD/XML
         @vAcctNetCharge = Record.Col.value('ACCTNETCHARGES[1]', 'varchar(15)'),
         @vReferences    = Record.Col.value('REFERENCES[1]',     'TVarChar'),
         @vNotifications = Record.Col.value('NOTIFICATIONS[1]',  'TVarChar'),
         @vLPNShipVia    = nullif(Record.Col.value('SHIPVIA[1]', 'TDescription'), 'Ship Via here'),
         @vLPNCarrier    = nullif(Record.Col.value('CARRIER[1]', 'TDescription'), 'Carrier here')
  from  @vShippingLPNxml.nodes('/SHIPPINGLPNINFO/RESPONSE')  as Record(Col);

  select @vPackageLength = Record.Col.value('OuterLength[1]',     'TLength'),
         @vPackageWidth  = Record.Col.value('OuterWidth[1]',      'TWidth'),
         @vPackageHeight = Record.Col.value('OuterHeight[1]',     'THeight')
  from @vShippingLPNxml.nodes('/SHIPPINGINFO/REQUEST/PACKAGES/PACKAGE/CARTONDETAILS') as Record(Col);

  /* Possible values S - Shipping label, RL - Return Label
     Default it to S - Shipping label, in case caller did not send any */
  select @vLabelType = coalesce(nullif(@vLabelType, ''), 'S' /* Shipping Label */);

  /* We are using Shipvia and Carrier - interchangeably - they are diff */
  select @vCarrier = Record.Col.value('CARRIER[1]', 'TCarrier')
  from  @vShippingLPNxml.nodes('/SHIPPINGLPNINFO/REQUEST/SHIPVIA')  as Record(Col);

  select @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (Carrier = @vCarrier);

  if (@vIsSmallPackageCarrier = 'N' /* No */) /* Nothing to do */
    goto ExitHandler;

  /* Check if the Shipping label already exists for the LPN */
  select @vShipLabelRecordId = RecordId
  from ShipLabels
  where (EntityType = 'L' /* LPN */           ) and
        (EntityKey  = @LPN                    ) and
        (LabelType  = @vLabelType);

  /* Stuff some additional information on the ZPL label */
  if ((@vLabelImageType = 'ZPL') and (@vZPLLabelImage is not null) and (@vStuffAdditionalInfoOnZPL = 'Y'/* Yes */))
    exec pr_ShipLabel_CustomizeZPL @LPN, @vCarrier, @vZPLLabelImage, @vBusinessUnit, null /* UserId */, @vZPLLabelImage output;

  /* For some reason, ZPL labels are inverted, so correct it */
  select @vZPLLabelImage = replace(@vZPLLabelImage, '^POI', '^PON');

  /* If there is notification message, then parse it */
  if (coalesce(@vNotifications, '') <> '' )
    exec pr_Shipping_ParseCarrierNotifications null, @vNotifications, @vCarrier, @vRequestedShipVia, null, @vNotifications output, @vNotificationSource output, @vNotificationTrace output

  select @vProcessStatus = case
                             when ((coalesce(@vNotifications, '') <> '' ) and (coalesce(@vTrackingNo, '') = '')) then
                               'LGE' /* Label Generation Error */
                             when (charindex(@vWaveType, @vWaveTypesToExportShippingDocs) > 0) then
                               'XR' /* Export Required */
                             else
                               'LG' /* Label Generated */
                           end;

  /* Insert or Update the Shipping label */
  if (coalesce(@vShipLabelRecordId, 0) = 0)
    begin
      /* There is no existing entry for the LPN Shippng Label */
      insert into ShipLabels (EntityType, EntityId, EntityKey, PackageLength, PackageWidth, PackageHeight, PackageWeight, PackageVolume,
                              OrderId, PickTicket, WaveId, WaveNo, LabelType, Label, ZPLLabel,
                              TrackingNo, TrackingBarcode, RequestedShipVia, ShipVia, ServiceSymbol, MSN, ListNetCharge, AcctNetCharge, ProcessStatus, ProcessedDateTime, Reference, Notifications, NotificationSource, NotificationTrace, BusinessUnit)
        select 'L', @LPNId, @LPN,@vPackageLength, @vPackageWidth, @vPackageHeight, @vTotalWeight, @vTotalVolume,
               @vOrderId, @vPickTicket, @vWaveId, @vWaveNo, @vLabelType, @vLabelImage, @vZPLLabelImage,
               coalesce(@vTrackingNo, ''), coalesce(@vTrackingBarcode, ''), @vRequestedShipVia, @vLPNShipVia, @vServiceSymbol, @vMSN, cast(@vListNetCharge as money), cast(@vAcctNetCharge as money), @vProcessStatus, current_timestamp, @vReferences, @vNotifications, @vNotificationSource, @vNotificationTrace,  @vBusinessUnit;

      /* Following code extracts additional images from input xml and inserts in to shiplabels table */

      insert into ShipLabels (EntityType, EntityId, EntityKey, PackageLength, PackageWidth, PackageHeight, PackageWeight, PackageVolume,
                              OrderId, PickTicket, WaveId, WaveNo, LabelType, Label, TrackingNo,
                              RequestedShipVia, ShipVia, ServiceSymbol, MSN, ListNetCharge, AcctNetCharge,
                              ProcessStatus, ProcessedDateTime, Reference, Notifications, NotificationSource, NotificationTrace, BusinessUnit)
        select 'L', @LPNId, @LPN , @vPackageLength, @vPackageWidth, @vPackageHeight, @vTotalWeight, @vTotalVolume,
               @vOrderId, @vPickTicket, @vWaveId, @vWaveNo, 'S'+ convert(varchar,row_number() over (order by  imageList.col.query('.').value('base64Binary[1]','varchar(max)'))) , dbo.fn_Base64ToBinary( imageList.col.query('.').value('base64Binary[1]','varchar(max)')) , coalesce(@vTrackingNo, ''),
               @vRequestedShipVia, @vLPNShipVia, @vServiceSymbol, @vMSN, cast(@vListNetCharge as money), cast(@vAcctNetCharge as money),
               @vProcessStatus, current_timestamp, @vReferences, @vNotifications, @vNotificationSource, @vNotificationTrace,  @vBusinessUnit
        from @vShippingLPNxml.nodes('/SHIPPINGLPNINFO/RESPONSE/IMAGELIST/base64Binary') as imageList(col)
    end
  else
    begin
      /* Update ShipLabel, TrackingNumber and ShipVia for the existing record */
      update ShipLabels
      set TrackingNo         = @vTrackingNo,
          TrackingBarcode    = @vTrackingBarcode,
          PackageLength      = @vPackageLength,
          PackageWidth       = @vPackageWidth,
          PackageHeight      = @vPackageHeight,
          PackageWeight      = @vTotalWeight,
          PackageVolume      = @vTotalVolume,
          Label              = @vLabelImage,
          ZPLLabel           = @vZPLLabelImage,
          RequestedShipVia   = @vRequestedShipVia, /* Why do we need to do this? AY .. We have keptthis information to know against which Shipvia is this Label generated for */
          ShipVia            = @vLPNShipVia,
          ServiceSymbol      = @vServiceSymbol,
          MSN                = @vMSN,
          ListNetCharge      = cast(@vListNetCharge as money),
          AcctNetCharge      = cast(@vAcctNetCharge as money),
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

  /* Update tracking number on LPN and AutoShip of LPN should be done only when Label Type is Ship label,
     not when Return Label */
  if (@vLabelType = 'S' /* Shippping Label */)
    begin
      /* Update LPN with latest tracking no */
      update LPNs
      set TrackingNo  = @vTrackingNo,
          @vLPNStatus = Status
      where (LPNId = @LPNId);

      /* When the Shipment was created successfully online, then Mark the LPN as Shipped */
      set @vUserId = System_user;

      /* status update on Labeling the LPN and the order of the Shipped LPN */
      select  @vAutoShipOnLabel = dbo.fn_Controls_GetAsBoolean('AutoShipLPN', 'ShipOnLabel',
                                                               'N', @vBusinessUnit, @vUserId);

      if  ((@vLPNStatus       <> 'S' /* Shipped */) and
           (@vAutoShipOnLabel =  'Y' /* Yes */    ) and
           (coalesce(@vTrackingNo, '') <> '')  and
           (@vLabelImage is not null))
        exec pr_LPNs_Ship @LPNId, null, @vBusinessUnit, @vUserId;
    end

  /* Get the LPN.TrackingNumber and update on OrderHeaders */
  exec pr_Entities_ExecuteInBackGround 'Order', @vOrderId, null, default /* ProcessClass */,
                                        @@ProcId, 'UpdateTrackingNos'/* Operation */, @vBusinessUnit;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_SaveLPNData */

Go
