/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/01  AY      Changes to handle incorrect residential flag on address (CIMSV3-3836)
  2024/08/27  RV      Made changes to get the message data for all the packages of the order (CIMSV3-3792)
  2024/05/07  VS      pr_API_FedEx_ShipmentRequest_GetMsgData: Build the xmlRulesData to get the appropriate ShippingAccount (CIDV3-743)
  2024/04/26  VS      Made changes to modify the address.flag for GroundHomeDelivery service (HA-4001)
  2024/04/20  VS      Made changes to get the PackageCount from ShipLabels table instead of OrderHeaders.LPNsAssigned (OBV3-2042)
  2024/02/12  RV      Initial Version (CIMSV3-3395)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_ShipmentRequest_GetMsgData') is not null
  drop Procedure pr_API_FedEx2_ShipmentRequest_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_ShipmentRequest_GetMsgData:
   Generates Message data in the format
   required by FEDEX Shipment. This is the highest level procedure called when the
   API outbound transactions are being prepared to invoke the external API. This
   proc formats the data for Shipment Request as expected by FEDEX.
   The shipment request could be for LPN

  Document Ref: https://developer.fedex.com/api/en-us/catalog/ship/docs.html
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_ShipmentRequest_GetMsgData
  (@TransactionRecordId  TRecordId,
   @MessageData          TVarchar   output)
as
  declare @vReturnCode                      TInteger,
          @vMessageName                     TMessageName,
          @vMessage                         TMessage,
          @vRecordId                        TRecordId,
          @vRulesDataXML                    TXML,
          -- LPN Info
          @vLPNId                           TRecordId,
          @vLPN                             TLPN,
          @vOrderId                         TRecordId,
          @vPickTicket                      TPickTicket,
          @vPackageSeqNo                    TInteger,
          @vMasterTrackingNo                TTrackingNo,
           -- Ship Via
          @vServiceType                     TDescription,
          @vCarrier                         TCarrier,
          @vSmartPostIndiciaType            TDescription,
          @vSmartPostHubId                  TDescription,
          @vSmartPostEndorsement            TDescription,
          -- Order Info
          @vAccount                         TCustomerId,
          @vAccountName                     TName,
          @vShipToId                        TShipToId,
          @vShipToAddressRegion             TAddressRegion,
          @vSoldToId                        TCustomerId,
          @vShipFrom                        TShipFrom,
          @vBillToAddress                   TBillToAccount,
          @vFreightTerms                    TDescription,
          @vOrderShipVia                    TShipVia,
          @vAccountNumber                   TAccount,
          @vBillToAccount                   TBillToAccount,
          @vWarehouse                       TWarehouse,
          @vTotalWeight                     TWeight,
          @vOwnership                       TOwnership,

          -- Processing variables
          @vEntityId                        TRecordId,
          @vEntityKey                       TEntityKey,
          @vEntityType                      TTypeCode,
          @vShipTimestamp                   TString,
          @vShipmentInfo                    TXML,
          @vRateRequestTypesJSON            TDescription,
          @vPackagingType                   TDescription,
          @vPackageTotalWeight              TWeight,
          @vPickupType                      TDescription,
          @vCurrency                        TTypeCode,
          @vShipAction                      TAction,
          @vProcessingOptionType            TTypeCode,
          @vOneLabelAtTime                  TStatus,
          @vLabelResponseOptions            TTypeCode,

          @vTotalDeclaredValueJSON          TNVarchar,
          @vShipperAddressJSON              TNVarchar,
          @vSoldToAddressJSON               TNVarchar,
          @vRecipientAddressJSON            TNVarchar,
          @vSpecialServiceTypesJSON         TNVarchar,
          @vSpecialServiceDetailsJSON       TNVarchar,
          @vPaymentInfoJSON                 TNVarchar,
          @vLabelSpecificationsJSON         TNVarchar,
          @vShippingDocsSpecificationsJSON  TNVarchar,
          @vCustomsClearanceDetailJSON      TNVarchar,
          @vPackagesJSON                    TNVarchar,
          @vAccountInfoJSON                 TNVarchar,
          @vSmartPostDetailJSON             TNVarchar,
          @vServiceDetail                   TVarchar,
          @CustomsClearanceDetail           TVarchar,
          @vPackageCount                    TInteger,
          @vMasterTrackingJSON              TVarchar,
          @vInternationalDocsRequired       TVarchar,
          @vAlwaysResidentialServices       TControlValue,
          @vNotResidentialServices          TControlValue,
          @vDebug                           TFlags,
          @vBusinessUnit                    TBusinessUnit,
          @vUserId                          TUserId;

  declare @ttCommodities                    TCommoditiesInfo,
          @ttLPNs                           TEntityKeysTable,
          @ttCarrierShipmentData            TCarrierShipmentData,
          @ttMarkers                        TMarkers;

begin /* pr_API_FEDEX2_ShipmentRequest_GetMsgData */
  /* Initialize */
  select @vReturnCode           = 0,
         @vMessageName          = null,
         @vRecordId             = 0,
         @vPickupType           = 'USE_SCHEDULED_PICKUP', /* Need to discuss and confirm */
         @vRateRequestTypesJSON = '["LIST", "PREFERRED"]',
         @vShipAction           = 'CONFIRM',
         @vProcessingOptionType = 'ALLOW_ASYNCHRONOUS',
         @vOneLabelAtTime       = 'true',
         @vLabelResponseOptions = 'LABEL';

  /* Entity could be an Order or LPN */
  select @vEntityId   = EntityId,
         @vEntityKey  = EntityKey,
         @vEntityType = EntityType,
         @vBusinessUnit = BusinessUnit
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  /* If invalid recordid, exit */
  if (@@rowcount = 0)  return;

  /* Assuming that the entity type is Order, we will generate all labels at once */
  if (@vEntityType = 'Order')
    select @vOneLabelAtTime = 'false';

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  /*-------------------- Create hash tables --------------------*/
  /* Create #OrderHeaders if it doesn't exist. Need to do below so that OrderId is not an identity column */
  if (object_id('tempdb..#OrderHeaders') is null)
    select * into #OrderHeaders from OrderHeaders where 1 = 2
    union all
    select * from OrderHeaders where 1 <> 1;

  if (object_id('tempdb..#CommoditiesInfo') is null) select * into #CommoditiesInfo from @ttCommodities;
  if (object_id('tempdb..#CommoditySummary') is null) select * into #CommoditySummary from @ttCommodities;
  if (object_id('tempdb..#ttLPNs') is null) select * into #ttLPNs from @ttLPNs;
  if (object_id('tempdb..#CarrierPackageInfo') is null)
    begin
      select * into #CarrierPackageInfo
      from LPNs where 1=2
        union all
      select * from LPNs where (1<>1);

      exec pr_PrepareHashTable 'TCarrierPackagesInfo', '#CarrierPackageInfo';
    end

  select * into #CarrierShipmentdata from @ttCarrierShipmentData;
  select * into #ShippingAccountDetails from ShippingAccounts where (1 = 2)
  union all
  select * from ShippingAccounts where (1 <> 1);

  /* The Residential flag is by default defined at the address level. However, for many clients the info
     on the address is not dependable and so we go by the service type. i.e. Some services are considered
     as residential always. On the contrary, sometimes address is flagged as residential even though it is
     not so for other than residential services we would want to override the flag at address level.ABORT
     ResidentialServices    - should be CSV of services
     NonResidentialServices - can be CSV of services, ALLOTHERS - meaning anything other than above or
                              '' meaning we use the info on the address as usual */
  select @vAlwaysResidentialServices = dbo.fn_Controls_GetAsString('Shipping_FedEx', 'ResidentialServices', 'GROUND_HOME_DELIVERY', @vBusinessUnit, @vUserId);
  select @vNotResidentialServices    = dbo.fn_Controls_GetAsString('Shipping_FedEx', 'NonResidentialServices', 'ALLOTHERS', @vBusinessUnit, @vUserId); -- ALL except the above ones

  /* Get the order info */
  if (@vEntityType = 'Order')
    select @vOrderId = OrderId
    from OrderHeaders
    where (OrderId = @vEntityId);
  else
  if (@vEntityType = 'LPN')
    select @vLPNId        = LPNId,
           @vOrderId      = OrderId,
           @vPackageSeqNo = PackageSeqNo
    from LPNs
    where (LPNId = @vEntityId);

  /* Initialize */
  insert into #CarrierShipmentData (Carrier, LPNId, OrderId)
    select 'FedEx', @vLPNId, @vOrderId;

  /* Loads the Shipment Data into hash tables */
  exec pr_Carrier_GetShipmentData @vLPNId, @vOrderId, null, @vShipmentInfo output;

  /* Get the OrderInfo */
  select @vAccount            = OH.Account,
         @vAccountName        = OH.AccountName,
         @vWarehouse          = OH.Warehouse,
         @vShipFrom           = OH.ShipFrom,
         @vSoldToId           = OH.SoldToId,
         @vShipToId           = OH.ShipToId,
         @vBillToAddress      = OH.BillToAddress,
         @vBillToAccount      = OH.BillToAccount,
         @vFreightTerms       = OH.FreightTerms,
         @vOrderShipVia       = OH.ShipVia,
         @vOwnership          = OH.Ownership,
         @vPackageCount       = LPNsAssigned,
         @vPackageTotalWeight = TotalWeight,
         @vCurrency           = Currency
  from #OrderHeaders OH;

  /* Get the AddressRegion */
  select @vServiceType               = CarrierServiceCode,
         @vCarrier                   = Carrier,
         @vSmartPostIndiciaType      = SmartPostIndiciaType,
         @vSmartPostHubId            = SmartPostHubId,
         @vSmartPostEndorsement      = SmartPostEndorsement,
         @vShipToAddressRegion       = ShipToAddressRegion,
         @vInternationalDocsRequired = InternationalDocsRequired,
         @vShipTimeStamp             = Format(FutureShipDate, 'yyyy-MM-dd')
  from #CarrierShipmentData

  /* Extract the Account details */
  select top 1 @vPackagingType = PackageType
  from #CarrierPackageInfo

  /* Get Master Tracking info while generating one label at time. If there should be and and there isn't then exit as it may not have
     been generated yet */
  if (@vOneLabelAtTime = 'true' and @vPackageSeqNo <> 1)
    begin
      exec @vReturnCode = pr_API_FedEx2_MasterTrackingInfo @TransactionRecordId, @vOrderId, @vLPNId, @vBusinessUnit, @vUserId,
                                                           @vPackageCount out, @vMasterTrackingJSON out;

      if (@vReturnCode > 1) goto ExitHandler;
    end

  /* Build Rules data */
  select @vRulesDataXML =  dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('ShipToId',         @vShipToId) +
                            dbo.fn_XMLNode('SoldToId',         @vSoldToId) +
                            dbo.fn_XMLNode('Carrier',          @vCarrier) +
                            dbo.fn_XMLNode('ShipVia',          @vOrderShipVia) +
                            dbo.fn_XMLNode('Account',          @vAccount) +
                            dbo.fn_XMLNode('AccountName',      @vAccountName) +
                            dbo.fn_XMLNode('Ownership',        @vOwnership) +
                            dbo.fn_XMLNode('Warehouse',        @vWarehouse) +
                            dbo.fn_XMLNode('ShipFrom',         @vShipFrom));

  /* Identify the shipping account to use and load details into #ShippingAccountDetails */
  exec pr_Carrier_GetShippingAccountDetails @vRulesDataXML, @vOrderShipVia, @vBusinessUnit, @vUserId;

  /* Build Shipper Address json */
  exec pr_API_FedEx2_GetAddress null /* ContactId */, 'F' /* ShipFrom */, @vWarehouse, @vAccountNumber, null,
                                'No' /* ArrayRequired */, @vBusinessUnit, @vUserId, @vShipperAddressJSON out;

  /* Build SoldTo Address json */
  exec pr_API_FedEx2_GetAddress null /* ContactId */, 'C' /* SoldTo */, @vSoldToId, @vAccountNumber, null,
                                'No' /* ArrayRequired */, @vBusinessUnit, @vUserId, @vSoldToAddressJSON out;

  /* Build recipients (ShipTo) Address json */
  exec pr_API_FedEx2_GetAddress null /* ContactId */, 'S' /* ShipTo */, @vShipToId, @vAccountNumber, null,
                                'Yes' /* ArrayRequired */, @vBusinessUnit, @vUserId, @vRecipientAddressJSON out;

  /* Based upon the control vars, override the residential flag at the address level by
     the service types - more detailed explanation above */
  if (dbo.fn_IsInList(@vServiceType, @vAlwaysResidentialServices) > 0)
    select @vRecipientAddressJSON = JSON_MODIFY(@vRecipientAddressJSON, '$[0].address.residential', 'true')
  else
  if (@vNotResidentialServices = 'ALLOTHERS') or (dbo.fn_IsInList(@vServiceType, @vNotResidentialServices) > 0)
    select @vRecipientAddressJSON = JSON_MODIFY(@vRecipientAddressJSON, '$[0].address.residential', 'false')

  /* Build Payment info json */
  exec pr_API_FedEx2_GetPaymentInfo 'ShippingChargesPayment', @vBusinessUnit, @vUserId, @vAccountInfoJSON out, @vPaymentInfoJSON out;

  /* Build Smart Post json */
  exec pr_API_FedEx2_GetSmartPostDetail @vBusinessUnit, @vUserId, @vSmartPostDetailJSON out;

  /* Build Label Specifications json */
  exec pr_API_FedEx2_GetLabelSpecifications @vBusinessUnit, @vUserId, 'PrintedLabelOrigin' /* Options */, @vLabelSpecificationsJSON out;

  /* Request the shipping documents for Last Package */
  if (@vPackageSeqNo = @vPackageCount)
    exec pr_API_FedEx2_GetDocumentSpecifications @vInternationalDocsRequired, @vBusinessUnit, @vUserId, @vShippingDocsSpecificationsJSON out;

  /* Build Special Services and details json */
  exec pr_API_FedEx2_GetShipmentSpecialServices @vInternationalDocsRequired, @vBusinessUnit, @vUserId, @vSpecialServiceTypesJSON out, @vSpecialServiceDetailsJSON out;

  /* Get customs info */
  exec pr_API_FedEx2_GetCustomsInfo null /* LoadId */, @vBusinessUnit, @vUserId, 'Yes' /* CommoditiesRequired */, @vCustomsClearanceDetailJSON out;

  /* Build the packages json */
  exec pr_API_FedEx2_GetPackageInfo @vBusinessUnit, @vUserId, 'Yes' /* Commodities Required */, @vTotalDeclaredValueJSON out, @vPackagesJSON out

  /* Get the PackageCount from ShipLabels instead of OH.LPNsAssigned because for International and FEDXSP MultiPackages
     needs to generate the labels as single Packages only, For this change in init_Rules_Shiplabels updating TotalPackagesCount as 1 */
  select @vPackageCount = coalesce(SL.TotalPackages, @vPackageCount)
  from ShipLabels SL
  where (SL.EntityId = @vLPNId) and (SL.Status = 'A');

  /* If Order is Repacked, After Packed the Order Reallocated, Picked and Packed more units then those will be consider as separate Packages so we need to send PackageSeqNo as 1 */
  if (@vPackageSeqno > @vPackageCount) and (@vPackageSeqNo <> 1)
    select @vPackageCount = 1,
           @vPackagesJSON = JSON_MODIFY(@vPackagesJSON, '$[0].sequenceNumber', '1');

  /* Update the header info with token */
  exec pr_API_FedEx2_UpdateHeaderInfo @TransactionRecordId, @vBusinessUnit;

  /* Build Message Data */
  select @MessageData =
    '{"requestedShipment": ' +
      '{' + concat_ws(', ',
        '"shipDatestamp": '                 + '"' + @vShipTimeStamp     + '"',
        '"totalDeclaredValue": '            + @vTotalDeclaredValueJSON,
        '"shipper": '                       + @vShipperAddressJSON,
        '"soldto": '                        + @vSoldToAddressJSON,
        '"recipients": '                    + @vRecipientAddressJSON,
        '"pickupType": '                    + '"' + @vPickupType         + '"',
        '"serviceType": '                   + '"' + @vServiceType        + '"',
        '"packagingType": '                 + '"' + @vPackagingType      + '"',
        '"totalWeight": '                   + '"' + format(@vPackageTotalWeight, 'F1') + '"', -- single decimal digit
        '"shippingChargesPayment":'         + @vPaymentInfoJSON,
        '"shipmentSpecialServices": '       + @vSpecialServiceTypesJSON,
        '"customsClearanceDetail": '        + @vCustomsClearanceDetailJSON,
        '"smartPostInfoDetail": '           + @vSmartPostDetailJSON,
        '"labelSpecification": '            + @vLabelSpecificationsJSON,
        '"shippingDocumentSpecification": ' + @vShippingDocsSpecificationsJSON,
        '"rateRequestType": '               + @vRateRequestTypesJSON,
        '"preferredCurrency": '             + '"' + @vCurrency           + '"',
        '"totalPackageCount": '             + '"' + cast(@vPackageCount as varchar(20))       + '"',
        '"masterTrackingId": '              + @vMasterTrackingJSON,
        '"requestedPackageLineItems": '     + @vPackagesJSON +
      '}',
      '"labelResponseOptions": '            + '"' + @vLabelResponseOptions + '"',
      '"accountNumber": '                   + @vAccountInfoJSON,
      '"shipAction": '                      + '"' + @vShipAction           + '"',
      '"processingOptionType": '            + '"' + @vProcessingOptionType + '"',
      '"oneLabelAtATime": '                 + '"' + @vOneLabelAtTime       + '"') +
    '}';

  /* Log the Marker Details */
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'End_FedEx_ShipmentRequest', @@ProcId, @vLPNId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log default, 'LPN', @vLPNId, @vLPN, 'API_FedEx_ShipmentRequest', @@ProcId, 'Markers_FedEx_ShipmentRequest', @vUserId, @vBusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_ShipmentRequest_GetMsgData */

Go
