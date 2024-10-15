/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/01  VIB     pr_Carrier_Response_SaveShipmentData: Corrected input parameter order where OnTrackingNoGenerate proc called (CIMSV3-3446)
  2023/10/09  RV      pr_Carrier_Response_SaveShipmentData: Changed the operation from UpdateTrackingNos to SummarizeShipLabelInfo (JLCA-1137)
  2023/09/28  RV      pr_Carrier_Response_SaveShipmentData: Made changes to do not override the Total packages as already evaluated while inserting (MBW-512)
  2023/08/10  RV      pr_Carrier_GetShipmentData, pr_Carrier_Response_SaveShipmentData: Made changes populate the hash table instead of xml (JLFL-320)
  2023/04/11  VS      pr_Carrier_Response_SaveShipmentData: Get the BillToAccount (JLFL-297)
  2023/03/31  VS      pr_Carrier_Response_SaveShipmentData: Made changes to add BillToAccount (JLFL-297)
  2022/12/23  VS      pr_Carrier_Response_SaveShipmentData: Added PackageWeight and Volume (OBV3-1363)
  2022/11/03  VS      pr_Carrier_Response_SaveShipmentData: If we didn't get LabelType then that should be empty (OBV3-1397)
  2022/10/21  VS      pr_Carrier_ProcessStatus, pr_Carrier_Response_SaveShipmentData: If we get any error save the error info in Notifications (CIMSV3-1780)
  pr_Carrier_Response_SaveShipmentData: Initial version (CIMSV3-1780)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_Response_SaveShipmentData') is not null
  drop Procedure pr_Carrier_Response_SaveShipmentData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_Response_SaveShipmentData: The purpose of this procedure is to save the
    data returned by the Carrier Webservice (including the shipping label image)
    and save to the database. Since we are using API for carrier, we would need to
    pass in the TransactionRecordId to retrieve and update info from the request

  LPN/LPNId      : Refer to the applicable LPN
  ShippingLPNData: Refers to the ShippingData received from the carrier.
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_Response_SaveShipmentData
  (@TransactionRecordId TRecordId,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vActivityLogId         TRecordId,
          /* Audit & Response */
          @vAuditActivity         TActivityType,
          @ttAuditTrailInfo       TAuditTrailInfo,
          @vAuditRecordId         TRecordId,
          @vRecordId              TRecordId,
          @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vLPNStatus             TStatus,
          @vOrderId               TRecordId,
          @vWaveType              TTypeCode,
          @vIsUsDomestic          TFlags,

          @vRequestXML            xml,
          @vBillToAccount         TAccount,
          @vProcessStatus         TStatus,
          @vBusinessUnit          TBusinessUnit,
          @vIsSmallPackageCarrier TFlag,
          @vCarrier               TCarrier,
          @vNotifications         TVarChar,
          @vUserId                TUserId,
          @vSeverity              TStatus,
          @vDebug                 TFlag;

  declare @ttUpdatedShipLabels table
          (EntityId               TRecordId,
           EntityKey              TEntityKey,
           OldTrackingNo          TTrackingNo,
           NewTrackingNo          TTrackingNo,
           RecordId               TRecordId identity(1,1));

  declare @ttMarkers              TMarkers;

begin /* pr_Carrier_Response_SaveShipmentData */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vUserId        = system_user,
         @vAuditActivity = 'AT_ShipLabelModified';

  /* Get the Notification to evaluate status, Order/Carrier info
     All packages are for same Order and Carrier, so getting from one record is enough */
  select top 1
         @vNotifications  = Notifications,
         @vCarrier        = Carrier,
         @vOrderId        = OrderId,
         @vBusinessUnit   = BusinessUnit
  from #Packages;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'pr_Carrier_Response_SaveShipmentData_Start';

  select @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (Carrier = @vCarrier) and (BusinessUnit = @vBusinessUnit);

  if (@vIsSmallPackageCarrier = 'N' /* No */) /* Nothing to do */
    goto ExitHandler;

  /* Temp fix: We have a bug where we encounter issues converting JSON to XML and raising exceptions when special characters are present.
     We have a task to fix this, as well as to retrieve information from the # table */      
  /* Get Raw response and shipment request from APIoutbound transaction */    
  --select @vRequestXML = MessageData
  --from APIOutboundTransactions
  --where (RecordId = @TransactionRecordId);

  select @vRequestXML = replace(convert(varchar(max),@vRequestXML), '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="http://fedex.com/ws/ship/v26">', '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">');

  /* Get the Package service: Domestic or International */
  select @vIsUsDomestic = IsUsDomestic from #PackageInfo;

  /* Populate Order/Wave info on Packages */
  update PKG
  set PickTicket       = OH.PickTicket,
      WaveId           = OH.PickBatchId,
      WaveNo           = OH.PickBatchNo,
      WaveType         = W.WaveType,
      @vWaveType       = W.WaveType,
      RequestedShipVia = OH.ShipVia,
      TotalPackages    = OH.LPNsAssigned
  from #Packages PKG
    join OrderHeaders OH on (OH.OrderId = PKG.OrderId)
    join Waves W         on (W.WaveId   = OH.PickBatchId);

  /* Get the Process Status */
  exec pr_Carrier_ProcessStatus @vNotifications, @vCarrier, @vWaveType, @vBusinessUnit, @vProcessStatus output;

  /* Get Carton Dims */
  update PKG
  set PackageLength = PD.PackageLength,
      PackageHeight = PD.PackageHeight,
      PackageWidth  = PD.PackageWidth,
      PackageWeight = PD.PackageWeight,
      PackageVolume = PD.PackageVolume
  from #Packages PKG
    join #PackageDims PD on (PKG.EntityId = PD.LPNId);

  /* Currently for Fedex we are generating ReturnLabels along with ShipLabels(if OH.ReturnLabelRequired is 'Y').
     So, ShipLabel record is created with LabelType S, RL. In return after generating Tracking#, new records
     are created with LabelType S, RL individually, leaving behind the intial record.
     Solution to manage the intial record:
       update the intial record with LabelType as 'S', along with Tracking# and insert the new record with LabelType as 'RL' */
  update PKG
  set ShipLabelRecordId = SL.RecordId,
      LabelType         = iif(PKG.LabelType = 'S,RL', 'S', SL.LabelType)
  from ShipLabels SL
    join #Packages PKG on SL.EntityId = PKG.EntityId
  where (SL.EntityType = 'L'     /* LPN */) and
        (coalesce(SL.TrackingNo, '') = '' ) and
        (SL.Status = 'A'                  ) and
        (SL.BusinessUnit = @vBusinessUnit);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ShippingInfo_GetLabelInfo_Completed';
  if (charindex('D', @vDebug) > 0) select '#Packages', ShipLabelRecordId, TrackingNo, * from #Packages

  /* If Shiplabel already does not exist then pr_API_FedEx_ShipmentRequest_ProcessResponse insert else update */
  insert into ShipLabels (EntityType, EntityId, EntityKey, PackageLength, PackageWidth, PackageHeight, PackageWeight, PackageVolume,
                          OrderId, PickTicket, TotalPackages, WaveId, WaveNo, LabelType, Label, ZPLLabel, BillToAccount,
                          TrackingNo, TrackingBarcode, Barcode, RequestedShipVia, ShipVia, Carrier, CarrierInterface, ServiceSymbol, MSN,
                          ListNetCharge, AcctNetCharge, InsuranceFee, ProcessStatus, ProcessedDateTime, Reference, Notifications, NotificationSource, NotificationTrace, BusinessUnit)
    select 'L', EntityId, EntityKey, PackageLength, PackageWidth, PackageHeight, PackageWeight, PackageVolume,
           OrderId, PickTicket, TotalPackages, WaveId, WaveNo, coalesce(LabelType,''), Label, ZPLLabel, BillToAccount,
           coalesce(TrackingNo, ''), coalesce(TrackingBarcode, ''), Barcode, RequestedShipVia, ShipVia, Carrier, CarrierInterface, ServiceSymbol, MSN,
           ListNetCharge, AcctNetCharge, InsuranceFee, @vProcessStatus, current_timestamp, cast(Reference as varchar(max)), Notifications, NotificationSource, NotificationTrace,  @vBusinessUnit
  from #Packages
  where ShipLabelRecordId is null;

  /* Update ShipLabel, TrackingNumber and ShipVia for the existing record */
  update SL
  set LabelType          = coalesce(PKG.LabelType, SL.LabelType),
      TrackingNo         = coalesce(PKG.TrackingNo,''),
      TrackingBarcode    = PKG.TrackingBarcode,
      PackageLength      = PKG.PackageLength,
      PackageWidth       = PKG.PackageWidth,
      PackageHeight      = PKG.PackageHeight,
      PackageWeight      = PKG.PackageWeight,
      PackageVolume      = PKG.PackageVolume,
      Barcode            = PKG.Barcode,
      Label              = PKG.Label,
      ZPLLabel           = PKG.ZPLLabel,
      BillToAccount      = PKG.BillToAccount,
      RequestedShipVia   = PKG.RequestedShipVia, /* Why do we need to do this? AY .. We have kept this information to know against which Shipvia is this Label generated for */
      ShipVia            = PKG.ShipVia,
      CarrierInterface   = PKG.CarrierInterface,
      ServiceSymbol      = PKG.ServiceSymbol,
      MSN                = PKG.MSN,
      ListNetCharge      = PKG.ListNetCharge,
      AcctNetCharge      = PKG.AcctNetCharge,
      InsuranceFee       = PKG.InsuranceFee,
      ProcessStatus      = @vProcessStatus,
      ProcessedDateTime  = current_timestamp,
      AlertSent          = case
                             when (@vProcessStatus = 'LGE') then 'T' /* To be sent */
                             else AlertSent
                           end,
      Reference          = convert(varchar(max), PKG.Reference),
      Notifications      = PKG.Notifications,
      NotificationSource = PKG.NotificationSource,
      NotificationTrace  = PKG.NotificationTrace,
      ModifiedDate       = current_timestamp
  output inserted.EntityId, inserted.EntityKey, deleted.TrackingNo, inserted.TrackingNo
  into @ttUpdatedShipLabels (EntityId, EntityKey, OldTrackingNo, NewTrackingNo)
  from ShipLabels SL
    join #Packages PKG on (PKG.ShipLabelRecordId = SL.RecordId)

  /* International FEDEX multi package shipment generating labels for individual packages but freight charges
     returning in last package only so we need to calculate and distribute to each package */
  if (@vCarrier = 'FEDEX') and (@vIsUsDomestic = 'false' /* International Package */)
    exec pr_Carrier_DistributeFreightAmongstPackages @vCarrier;

  /* Update tracking number on LPN and AutoShip of LPN should be done only when Label Type is Ship label, not when Return Label */
  exec pr_Carrier_OnTrackingNoGenerate @vBusinessUnit, @vUserId;

  /* Get the LPN.TrackingNumber and update on OrderHeaders */
  exec pr_Entities_ExecuteInBackGround 'Order', @vOrderId, null, default /* ProcessClass */,
                                        @@ProcId, 'SummarizeShipLabelInfo'/* Operation */, @vBusinessUnit;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId,EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'LPN', EntityId, EntityKey, @vAuditActivity, @vBusinessUnit, @vUserId,
           dbo.fn_Messages_Build(@vAuditActivity, EntityKey, OldTrackingNo, NewTrackingNo, null, null) /* Comment */
    from @ttUpdatedShipLabels;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'pr_Carrier_Response_SaveShipmentData_End';
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'Shipping', null, null, 'SaveShipmentData', @@ProcId, 'Markers_SaveShipmentData';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Carrier_Response_SaveShipmentData */

Go
