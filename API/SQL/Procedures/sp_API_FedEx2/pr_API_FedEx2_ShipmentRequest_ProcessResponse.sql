/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/09/25  RV      Bug fixed to get the OrderId properly (OBV3-2139)
  2024/09/20  RV      Bug fixed to get the package sequence number properly (OBV3-2134)
  2024/05/31  VS      Made changes to improve the performance (FBV3-1752)
  2024/05/22  VS      Made changes to improve the performance (FBV3-1750)
  2024/03/20  RV      Included the PAYOR_LIST_PACKAGE and PAYOR_ACCOUNT_PACKAGE while fetching the shipment rates (JLFL-980)
  2024/03/09  RV      Rename the caller procedure pr_API_FedEx2_Response_SaveDocuments (CIMSV3-3478)
  2024/02/17  RV      Initial version (CIMSV3-3396)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_ShipmentRequest_ProcessResponse') is not null
  drop Procedure pr_API_FedEx2_ShipmentRequest_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  *+|Proc pr_API_FedEx2_ShipmentRequest_ProcessResponse: Once FedEx API is invoked, we would get
    a response back from FedEx which would be saved in the APIOutboundTransaction
    table and the RecordId passed to this procedure for processing the response.

    This procedure parses the shipment response and saves the shipment data. This procedure
    processes the repsonse for ShipmentRequest API call only and the assumption is that
    there would always be only one package per request.

  Document Ref: https://developer.fedex.com/api/en-us/catalog/ship/docs.html
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_ShipmentRequest_ProcessResponse
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vBusinessUnit                TBusinessUnit,
          @vUserId                      TUserId,

          @vShipmentRequestJSON         TNVarchar,
          @vNotification                TVarChar,
          @vNotificationDetails         TVarChar,
          @vReference                   XML,
          @vListNetCharge               TMoney,
          @vAcctNetCharge               TMoney,

          @vLabelType                   TTypeCode,

          @vEntityId                    TRecordId,
          @vEntityKey                   TEntityKey,
          @vEntityType                  TTypeCode,
          @vOrderId                     TRecordId,
          @vPickTicket                  TPickTicket,
          @vPackagesCount               TCount,
          @vTrackingNo                  TTrackingNo,
          @vRequestedShipVia            TShipVia,
          @vLPNId                       TRecordId,
          @vLPN                         TLPN,
          @vPackageSeqNo                TInteger,

          @vRawResponseJSON             TNVarchar,
          @vDocumentId                  TRecordId,
          @vShippingData                TXML,
          @vTotalPackages               TCount,
          @vTotalWeight                 TWeight,
          @vTotalVolume                 TVolume,
          @vSeverity                    TStatus,
          @vNotifications               TVarchar,
          @vCarrier                     TCarrier,
          @vServiceType                 TDescription,
          @vIsUsDomestic                TFlags;

  declare @ttCarrierResponseData        TCarrierResponseData,
          @ttCartonDetails              TCarrierCartonDetails,
          @ttPackageInfo                TCarrierPackageInfo,
          @ttPackageLabels              TCarrierPackageLabels,
          @ttPackageRating              TCarrierRatingInfo,
          @ttShipmentRating             TCarrierRatingInfo,
          @ttDocuments                  TCarrierDocuments,
          @ttNotifications              TCarrierResponseNotifications;

  declare @ttLPNs table
          (LPNId                        TRecordId,
           LPN                          TLPN,
           Status                       TStatus,
           OrderId                      TRecordId,
           PickTicket                   TPickTicket,
           PackageSeqNo                 TInteger,
           CartonType                   TCartonType,
           LPNWeight                    TWeight,
           LPNVolume                    TVolume,
           BusinessUnit                 TBusinessUnit);

begin /* pr_API_FedEx_ShipmentRequest_ProcessResponse */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vCarrier       ='FEDEX',
         @vNotification  = '',
         @vTotalPackages = 1,
         @vUserId        = 'CIMSFedEx2API';

  /* #Packages holds all the info related to the packages and
     #PackageDims hold the dims for each package as sent in the request
     #Notifications hold the carrier response Notifications */
  if (object_id('tempdb..#LPNs')           is null) select * into #LPNs           from @ttLPNs;
  if (object_id('tempdb..#Packages')       is null) select * into #Packages       from @ttCarrierResponseData;
  if (object_id('tempdb..#PackageDims')    is null) select * into #PackageDims    from @ttCartonDetails;
  if (object_id('tempdb..#Notifications')  is null) select * into #Notifications  from @ttNotifications;
  if (object_id('tempdb..#PackageRating')  is null) select * into #PackageRating  from @ttPackageRating;
  if (object_id('tempdb..#PackageInfo')    is null) select * into #PackageInfo    from @ttPackageInfo;
  if (object_id('tempdb..#PackageLabels')  is null) select * into #PackageLabels  from @ttPackageLabels;
  if (object_id('tempdb..#ShipmentRating') is null) select * into #ShipmentRating from @ttShipmentRating;
  if (object_id('tempdb..#Documents')      is null) select * into #Documents      from @ttDocuments;

  /* Get Raw response and shipment request from APIOutbound transaction */
  select @vRawResponseJSON    = RawResponse,
         @vEntityId           = EntityId,
         @vEntityKey          = EntityKey,
         @vEntityType         = EntityType,
         @vBusinessUnit       = BusinessUnit
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  /* Populate LPN Info into temp table based upon the entity type */
  if (@vEntityType = 'Order')
    insert into #LPNs (LPNId, LPN, Status, OrderId, PickTicket, PackageSeqNo, CartonType,
                       LPNWeight, LPNVolume, BusinessUnit)
      select LPNId, LPN, Status, OrderId, PickTicketNo, PackageSeqNo, CartonType,
             LPNWeight, LPNVolume, BusinessUnit
      from LPNs
      where (OrderId = @vEntityId);
  else
    insert into #LPNs (LPNId, LPN, Status, OrderId, PickTicket, PackageSeqNo, CartonType,
                       LPNWeight, LPNVolume, BusinessUnit)
      select LPNId, LPN, Status, OrderId, PickTicketNo, PackageSeqNo, CartonType,
             LPNWeight, LPNVolume, BusinessUnit
    from LPNs
    where (LPNId = @vEntityId);

  /* Fetch the OrderId.*/
  select top 1 @vOrderId = OrderId from #LPNs;

  select @vPickTicket       = PickTicket,
         @vRequestedShipVia = ShipVia,
         @vTotalPackages    = LPNsAssigned
  from OrderHeaders
  where (OrderId = @vOrderId);

  /*-------------------- Package Dimensions --------------------*/
  /* There may be multiple cartons for an order, so get all the cartons' information */
  insert into #PackageDims(LPNId, LPN, PackageLength, PackageWidth, PackageHeight, PackageWeight, PackageVolume)
    select L.LPNId, L.LPN, CT.OuterLength, CT.OuterWidth, CT.OuterHeight, L.LPNWeight, L.LPNVolume
    from #LPNs L
      join CartonTypes CT on (L.CartonType = CT.CartonType) and (L.BusinessUnit = CT.BusinessUnit);

  /*-------------------- #Packages --------------------*/
  /* This is the list of LPNs with all info collected from Response and
     consolidated to do a single update on the LPNs table */
  insert into #Packages(EntityId, EntityKey, LPNId, LPN, LPNStatus, PackageSeqNo,
                        OrderId, PickTicket, TotalPackages, TrackingBarcode, Barcode, Carrier, ShipVia, RequestedShipVia, CarrierInterface,
                        ServiceSymbol, MSN, InsuranceFee, BusinessUnit)
  select LPNId, LPN, LPNId, LPN, Status, PackageSeqNo, OrderId, PickTicket, @vTotalPackages,
         null, /* TODO When Smart post TRACKINGBARCODE: This needs to updated from the service response */
         null, /* BARCODE: Future */
         @vCarrier,
         @vServiceType,
         @vRequestedShipVia,
         'CIMSFEDEX2',
         null, /* ServiceSymbol: This needs to updated from the service response */
         null, /* MSN: This needs to updated from the service response, */
         null, /* InsuranceFee: This needs to updated from the service response */
         BusinessUnit
  from #LPNs;

  /*-------------------- Package Info --------------------*/
  /* Extract the info from PieceRespones for each package */
  insert into #PackageInfo(PackageSequenceNumber, TrackingNumber, MasterTrackingNo, Reference1Type, Reference1Value, Reference2Type, Reference2Value,
                           Reference3Type, Reference3Value, IsUsDomestic, Carrier, RecordId)
    select PackageSequenceNumber, TrackingNumber, MasterTrackingNo, Reference1Type, Reference1Value, Reference2Type, Reference2Value,
           Reference3Type, Reference3Value, IsUsDomestic, @vCarrier, row_number() over (order by (select null)) RecordId
    from OPENJSON(@vRawResponseJSON, '$.output.transactionShipments[0].pieceResponses')
    with
    (
      PackageSequenceNumber    TInteger       '$.packageSequenceNumber',
      TrackingNumber           TTrackingNo    '$.trackingNumber',
      MasterTrackingNo         TTrackingNo    '$.masterTrackingNumber',
      Reference1Type           TString        '$.customerReferences[0].customerReferenceType',
      Reference1Value          TString        '$.customerReferences[0].value',
      Reference2Type           TString        '$.customerReferences[1].customerReferenceType',
      Reference2Value          TString        '$.customerReferences[1].value',
      Reference3Type           TString        '$.customerReferences[2].customerReferenceType',
      Reference3Value          TString        '$.customerReferences[2].value',
      IsUsDomestic             TFlags
     );

  /* Discussion Point: We can't navigate back and get the value while populating the #PackageInfo, can we decide based upon the Contact? */
  update PKI
  set PKI.IsUsDomestic = JSON_VALUE(@vRawResponseJSON, '$.output.transactionShipments[0].completedShipmentDetail.usDomestic')
  from #PackageInfo PKI

  /*-------------------- Labels --------------------*/
  insert into #PackageLabels(PackageSequenceNumber, TrackingNumber, PackageDocumentsJSON, LabelType, LabelImageType, LabelImage,
                             Carrier, RecordId)
    select PackageSequenceNumber, TrackingNumber, PackageDocumentsJSON, LabelType, LabelImageType, LabelImage,
           @vCarrier, row_number() over (order by (select null)) RecordId
    from OPENJSON (@vRawResponseJSON, '$.output.transactionShipments[0].pieceResponses')
    with
    (
      PackageSequenceNumber    Tinteger       '$.packageSequenceNumber',
      TrackingNumber           TTrackingNo    '$.trackingNumber',
      PackageDocumentsJSON     TNVarchar      '$.packageDocuments' as json
    )
    as PackageLabels
    CROSS APPLY OPENJSON(PackageLabels.PackageDocumentsJSON)
    with
    (
      LabelType                TString        '$.contentType',
      LabelImageType           TVarchar       '$.docType',
      LabelImage               TVarchar       '$.encodedLabel'
    );

  /*-------------------- Package Rating --------------------*/
  /* Get the PackageRateDetails into a hash table */
  insert into #PackageRating(PackageSequenceNumber, TrackingNumber, PackageRatingJSON, RateType ,RatedWeightMethod,
                             BillingWeight_Value, DimWeight_Value, BaseCharge_Amount, NetFreight_Amount, TotalSurcharges_Amount, NetCharge_Amount)
    select PackageSequenceNumber, TrackingNumber, PackageRatingJSON, RateType ,RatedWeightMethod,
           BillingWeight_Value, DimWeight_Value, BaseCharge_Amount, NetFreight_Amount, TotalSurcharges_Amount, NetCharge_Amount
    from OPENJSON(@vRawResponseJSON, '$.output.transactionShipments[0].completedShipmentDetail.completedPackageDetails')
    with
    (
      PackageSequenceNumber    Tinteger       '$.sequenceNumber',
      TrackingNumber           TTrackingNo    '$.trackingIds[0].trackingNumber',
      PackageRatingJSON        TNVarchar      '$.packageRating.packageRateDetails' as json
    )
    as PackageRateDetails
    CROSS APPLY OPENJSON(PackageRateDetails.PackageRatingJSON)
    with
    (
      RateType                 TString        '$.rateType',
      RatedWeightMethod        TString        '$.ratedWeightMethod',
      BillingWeight_Value      TFloat         '$.billingWeight.value',
      DimWeight_Value          TFloat         '$.dimWeight.value', -- Not getting this node
      BaseCharge_Amount        TMoney         '$.baseCharge',
      NetFreight_Amount        TMoney         '$.netFreight',
      TotalSurcharges_Amount   TMoney         '$.totalSurcharges',
      NetCharge_Amount         TMoney         '$.netCharge'
    );

  /*-------------------- Shipment Rating --------------------*/
  /* TotalNeCharge : This shipments total charges including freight, surchanges, duties and taxes
     Get the ShipmentRateDetails into a hash table
     Note: For international shipments, we receive the freight charges at the shipment level,
     including freight charges in both the source country’s currency and the destination currency.
     Since the source country rate details are provided first in the array, we will consider only
     the source country's freight terms currency */
  insert into #ShipmentRating(RateType, RatedWeightMethod, BillingWeight_Value, NetCharge_Amount)
    select RateType, RatedWeightMethod, BillingWeight_Value, NetCharge_Amount
    from OPENJSON (@vRawResponseJSON, '$.output.transactionShipments[0].completedShipmentDetail.shipmentRating.shipmentRateDetails')
    with
    (
      RateType               TString     '$.rateType',
      RatedWeightMethod      TString     '$.ratedWeightMethod',
      BillingWeight_Value    TFloat      '$.totalBillingWeight.value',
      NetCharge_Amount       TMoney      '$.totalNetCharge'
    );

  /*-------------------- Documents --------------------*/
  insert into #Documents(DocumentType, ImageType, CopiesToPrint, Image)
    select DocumentType, ImageType, CopiesToPrint, Image
    from OPENJSON(@vRawResponseJSON,'$.output.transactionShipments[0].shipmentDocuments')
    with
    (
      DocumentType      TString       '$.contentType',
      ImageType         TVarchar      '$.docType',
      CopiesToPrint     TInteger      '$.copiesToPrint',
      Image             TVarchar      '$.encodedLabel'
    );

  /*-------------------- Notifications --------------------*/
  exec pr_API_FedEx2_Response_GetNotifications @vRawResponseJSON, @vBusinessUnit, @vUserId, @vSeverity out, @vNotifications out, @vNotificationDetails out;

  /*-------------------- Link #Packages with #PackageInfo --------------------*/

  /* update Package Info with LPNId and LPN - This is the key match to identify
     which LPN is which PackageSeqNo and hence which Tracking No. We could also
     use CustomerReference which would have LPN too. When there is only one package
     we would not have PI.PackageSequenceNumber */
  update PI
  set LPNId = L.LPNId,
      LPN   = L.LPN
  from #PackageInfo PI join #LPNs L on (coalesce(PI.PackageSequenceNumber, L.PackageSeqNo) = L.PackageSeqNo);

  /* Update TrackingNo on #Packages so that this will be used in all subsequent joins */
  update PKG
  set TrackingNo = PI.TrackingNumber
  from #Packages PKG join #PackageInfo PI on (PKG.LPNId = PI.LPNId);

  /*-------------------- Update #PackageLabels and #PackageRating --------------------*/
  /* Update Package labels */
  update PL
  set LPNId          = P.LPNId,
      LPN            = P.LPN,
      LabelType      = case when PL.LabelType = 'LABEL'      then 'S' /* Shiplabel */ else PL.LabelType end,
      LabelImageType = case when PL.LabelImageType = 'ZPLII' then 'ZPL'               else LabelImageType end
  from #PackageLabels PL join #Packages P on (PL.TrackingNumber = P.TrackingNo);

  /* Update Package Rating */
  update PR
  set LPNId = P.LPNId,
      LPN   = P.LPN
  from #PackageRating PR join #Packages P on (PR.TrackingNumber = P.TrackingNo);

  /* If Severity is not equal Error then the request is success, otherwise error in shipment request */
  if (coalesce(@vSeverity, '') not in ('ERROR', 'FAULT'))
    begin
      /* update the list net charges for each package */
      update PKG
      set ListNetCharge = PR.NetCharge_Amount,
          Reference     = PackageRatingJSON
      from #Packages PKG
        join #PackageRating PR on (PKG.LPNId = PR.LPNId) and (PR.RateType = 'PAYOR_LIST_PACKAGE');

      /* update the account net charges for each package */
      update PKG
      set AcctNetCharge = PR.NetCharge_Amount,
          Reference     = coalesce(Reference, PackageRatingJSON)
      from #Packages PKG
        join #PackageRating PR on (PKG.LPNId = PR.LPNId) and (PR.RateType = 'PAYOR_ACCOUNT_PACKAGE');

      /* Retrieve the shipment level AcctNetCharges and ListNetCharges */
      /* Note: Previously, the FedEx API sent the rateType as PAYOR_LIST_SHIPMENT under shipment rating.
         Now, it has been changed to PAYOR_LIST_PACKAGE in the response. Not sure in prod how we will get, but
         we won't get both in the same node, So included both */
      select @vListNetCharge = NetCharge_Amount from #ShipmentRating where (RateType in ('PAYOR_LIST_SHIPMENT', 'PAYOR_LIST_PACKAGE'));
      select @vAcctNetCharge = NetCharge_Amount from #ShipmentRating where (RateType in ('PAYOR_ACCOUNT_SHIPMENT', 'PAYOR_ACCOUNT_PACKAGE'));

      /* If packages do not have rates, then update the shipment rates on the first
         package - these would be distributed to other packages later */
      /* This is not handled thru pr_Carrier_DistributeFreightAmongstPackages */
      --update PKG
      --set ListNetCharge = coalesce(ListNetCharge, @vListNetCharge),
      --    AcctNetCharge = coalesce(AcctNetCharge, @vAcctNetCharge)
      --from #Packages PKG
      --where (PKG.PackageSeqNo = 1);

      /* Prepare the labels by transforming Base64 to appropriate image or ZPL */
      exec pr_Carrier_PrepareLabels @vBusinessUnit, @vUserId;

      /* Update the Packages with the Tracking info and ShipLabel. Other labels
         will be saved from #PackageLabels */
      update PKG
      set Label              =  PL.RotatedLabelImage,
          ZPLLabel           =  PL.ZPLLabel,
          LabelType          =  PL.LabelType,
          Carrier            =  PL.Carrier,
          CarrierInterface   = 'CIMSFEDEX2'
      from #Packages PKG
        left join #PackageLabels PL on (PL.LabelType = 'S')
      where (PKG.EntityId = PL.LPNId);

      /* Save #Documents */
      exec pr_API_FedEx2_Response_SaveDocuments 'Order', @vOrderId, @vPickTicket, @vBusinessUnit, @vUserId;
    end

  /* Save the notifications for the package */
  update #Packages
  set Notifications      = @vNotifications,
      NotificationSource = @vNotificationDetails,
      Carrier            = coalesce(Carrier, 'FEDEX');

  /* Save the shipment response in ship labels table */
  exec pr_Carrier_Response_SaveShipmentData @TransactionRecordId, @vBusinessUnit, @vUserId;

  /* Update APIOT to reflect Transaction Status */
  if (@vSeverity in ('Error', 'Failure', 'Fault'))
    update APIOT
    set TransactionStatus = 'Fail',
        Response          = @vNotifications
    from APIOutboundTransactions APIOT
    where (RecordId = @TransactionRecordId);

  /* Drop the tables */
  drop table #Packages
  drop table #PackageDims
  drop table #PackageRating
  drop table #PackageInfo
  drop table #PackageLabels
  drop table #ShipmentRating
  drop table #Documents

end try
begin catch

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_ShipmentRequest_ProcessResponse */

Go
