/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/29  VS      pr_API_UPS_ShipmentRequest_GetMsgData: Get the Active account for given ShippingAccount (OBV3-2041) 
  2024/03/08  RV      Revise the procedure to fetch the specific record in order to minimize latency (MBW-857)
  2023/09/03  RV      pr_API_UPS_ShipmentRequest_GetMsgData: Made changes to send the access token in the header for CIMS OAUTH integration (MBW-438)
  2023/04/11  RV      pr_API_UPS_ShipmentRequest_GetMsgData: Made changes to insert the shipment data in core procedure (CIMSV3-2537)
  2021/08/25  OK      pr_API_UPS_ShipmentRequest_GetMsgData: Changes to pass USPSEndorsement which is required for Mail Innovations (BK-506)
                      pr_API_UPS_ShipmentRequest_GetMsgData: Changes to pass InvoiceLineTotal data which is required for internation shipments (BK-382)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_ShipmentRequest_GetMsgData') is not null
  drop Procedure pr_API_UPS_ShipmentRequest_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_ShipmentRequest_GetMsgData: Generates Message data in the format
   required by UPS Shipment. This is the highest level procedure called when the
   API outbound transactions are being prepared to invoke the external API. This
   proc formats the data for Shipment Request as expected by UPS.

   The shipment request could be for an Order or a LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_ShipmentRequest_GetMsgData
  (@TransactionRecordId TRecordId,
   @MessageData         TVarchar   output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vRecordId                    TRecordId,

          @vEntityType                  TTypeCode,
          @vEntityId                    TRecordId,
          @vEntityKey                   TEntityKey,
          @vIntegrationName             TName,
          @vLPNId                       TRecordId,
          @vLPN                         TLPN,
          @vOrderId                     TRecordId,
          @vPickTicket                  TPickTicket,
          @vCurrencyCode                TTypeCode,
          @vTotalValue                  TMoney,

          @vAccessToken                 TVarchar,
          @vAPIHeaderInfo               TVarchar,

          @vShippingAccountNumber       TAccount,
          @vShippingAccountUserId       TUserId,
          @vShippingAccountPassword     TPassword,
          @vShippingAccountAccessKey    TAccessKey,
          @vShipmentPackageId           TDescription,
          @vShipmentDescription         TDescription,
          @vUSPSEndorsement             TDescription,
          @vShipmentInfoXML             XML,

          @vShipperAddressJSON          TNVarChar,
          @vShipFromAddressJSON         TNVarChar,
          @vShipToAddressJSON           TNVarChar,
          @vPaymentInformationJSON      TNVarChar,
          @vPackageInfoJSON             TNVarChar,
          @vShipmentSpecialServices     TNVarchar,
          @vShipmentInternationalDocs   TNVarchar,
          @vLabelSpecificationJSON      TNVarChar,
          @vServiceInfoJSON             TNVarChar,
          @vReturnServiceJSON           TNVarChar,

          @vRawResponse                 TVarchar,
          @vBusinessUnit                TBusinessUnit,
          @vUserId                      TUserId;

  declare @ttCommoditiesInfo            TCommoditiesInfo;

begin /* pr_API_UPS_ShipmentRequest_GetMsgData */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the APIOutbound record info */
  select @vIntegrationName = IntegrationName,
         @vEntityType      = EntityType,
         @vEntityId        = EntityId,
         @vEntityKey       = EntityKey,
         @vBusinessUnit    = BusinessUnit,
         @vUserId          = CreatedBy
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  if (@vEntityType = 'LPN')
    select @vLPNId = @vEntityId,
           @vLPN   = @vEntityKey;
  else
  if (@vEntityType = 'Order')
    select @vOrderId    = @vEntityId,
           @vPickTicket = @vEntityKey;

  /* Entity Type is Required and either EntityId/EntityKey are required */
  if (@vEntityId is null and @vEntityKey is null) or (@vEntityType is null)
    return;

  /* Create hash table to hold the xml info that is being built by GetShipmentData below */
  create table #ttShipmentInfo (ShipmentInfo varchar(max));
  select * into #CommoditiesInfo from @ttCommoditiesInfo;

  /* Get shipment data from existing procedure */
  exec pr_Shipping_GetShipmentData @vLPN, @vLPNId, @vOrderId, @vPickTicket;

  select top 1 @vShipmentInfoXML = cast(ShipmentInfo as xml) from #ttShipmentInfo;

  /* Extract the Account details */
  select @vShipmentPackageId        = Record.Col.value('(ORDERHEADER/PickTicket)[1]',       'TUserId'),
         @vShippingAccountNumber    = Record.Col.value('(ACCOUNTDETAILS/ACCOUNTNUMBER)[1]', 'TAccount'),
         @vShippingAccountUserId    = Record.Col.value('(ACCOUNTDETAILS/USERID)[1]',        'TUserId'),
         @vShippingAccountPassword  = Record.Col.value('(ACCOUNTDETAILS/PASSWORD)[1]',      'TPassword'),
         @vShippingAccountAccessKey = Record.Col.value('(ACCOUNTDETAILS/ACCESSKEY)[1]',     'TAccessKey'),
         @vCurrencyCode             = Record.Col.value('(CUSTOMS/CURRENCY)[1]',             'TTypeCode'),
         @vTotalValue               = Record.Col.value('(CUSTOMS/VALUE)[1]',                'TMoney'),
         @vShipmentDescription      = Record.Col.value('(PACKAGES/PACKAGE/CARTONDETAILS/Description)[1]',
                                                                                            'TDescription'),
         @vUSPSEndorsement          = '2' /* required for Mail Innovations */
  from @vShipmentInfoXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
  OPTION (OPTIMIZE FOR (@vShipmentInfoXML = null));

  /* Build header info as some times shipping accounts might be based upon rules, so override the default header info
     in configurations.
     For UPS OAUTH2, requires access token instead of username and password */
  if (@vIntegrationName = 'CIMSUPS2')
    begin
      /* Get Access Token Id */
      select @vAccessToken = AccessToken
      from ShippingAccounts
      where (ShipperAccountNumber = @vShippingAccountNumber) and
            (BusinessUnit         = @vBusinessUnit) and
            (AccessToken is not null) and (Status = 'A');

      select @vAPIHeaderInfo = dbo.fn_XMLNode('Root',
                                 dbo.fn_XMLNode('Authorization', 'Bearer ' + @vAccessToken));
    end
  else
    select @vAPIHeaderInfo = dbo.fn_XMLNode('Root',
                               dbo.fn_XMLNode('Username',            @vShippingAccountUserId) +
                               dbo.fn_XMLNode('Password',            @vShippingAccountPassword) +
                               dbo.fn_XMLNode('AccessLicenseNumber', @vShippingAccountAccessKey));

  /* Update the customized authentication and header info as this might be different and update the shipment data
     to use while saving response from API */
  update APIOutBoundTransactions
  set AuthenticationInfo = @vShippingAccountUserId + ':' + @vShippingAccountPassword,
      HeaderInfo         = @vAPIHeaderInfo,
      UDF1               = cast(@vShipmentInfoXML as varchar(max))
  where (RecordId = @TransactionRecordId);

  /* Build Shipper Address json */
  exec pr_API_UPS_GetShipperAddress @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vShipperAddressJSON out;

  /* Build Ship From Address json */
  exec pr_API_UPS_GetShipFromAddress @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vShipFromAddressJSON out;

  /* Build Ship To Address json */
  exec pr_API_UPS_GetShipToAddress @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vShipToAddressJSON out;

  /* Get payment info */
  exec pr_API_UPS_GetPaymentInfo @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vPaymentInformationJSON out;

  /* Get service info */
  exec pr_API_UPS_GetServiceInfo @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vServiceInfoJSON out;

  /* Get package info */
  exec pr_API_UPS_GetPackageInfo @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vPackageInfoJSON out;

  /* Get special services */
  exec pr_API_UPS_GetSpecialServices @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vShipmentSpecialServices out, @vReturnServiceJSON out;

  /* Get International docs */
  exec pr_API_UPS_GetInternationalDocs @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vShipmentInternationalDocs out;

  /* Get package info */
  exec pr_API_UPS_GetLabelSpecifications @vShipmentInfoXML, @vBusinessUnit, @vUserId, @vLabelSpecificationJSON out;

  /* Build Message Data */
  select @MessageData = '
  {
   "ShipmentRequest": {
      "Shipment": {
         "PackageID" :'              + coalesce('"' + @vShipmentPackageId +   '"', '""')   +',
         "Description":'             + coalesce('"' + @vShipmentDescription + '"', '""')   +',
         "USPSEndorsement":'         + coalesce('"' + @vUSPSEndorsement + '"',     '""')   +',
         "Shipper":'                 + coalesce(@vShipperAddressJSON,              '""')   +',
         "ShipFrom":'                + coalesce(@vShipFromAddressJSON,             '""')   +',
         "ShipTo":'                  + coalesce(@vShipToAddressJSON,               '""')   +',
         "PaymentInformation":'      + coalesce(@vPaymentInformationJSON,          '""')   +',
         "Service":'                 + coalesce(@vServiceInfoJSON,                 '""')   +','
                                     + coalesce(@vReturnServiceJSON,               '')     + '
         "Package":'                 + coalesce(@vPackageInfoJSON,                 '""')   +',
         "ShipmentServiceOptions": {'+ coalesce(@vShipmentSpecialServices,         '')     +
                                       coalesce(@vShipmentInternationalDocs,       '')     +'},
         "ItemizedChargesRequestedIndicator":"",
         "RatingMethodRequestedIndicator":"",
         "TaxInformationIndicator":"",
         "ShipmentRatingOptions":{
            "NegotiatedRatesIndicator":""
         },
         "PackageIDBarcodeIndicator":{},
         "InvoiceLineTotal": {
              "CurrencyCode": ' + '"' + coalesce(@vCurrencyCode, 'USD') +'"'             +',
              "MonetaryValue":' + '"' + cast(coalesce(@vTotalValue, 0.00) as varchar(max)) + '"'         +'
         }
      },
      "LabelSpecification":'         + coalesce(@vLabelSpecificationJSON, '""') +'
    }
  }
'
end /* pr_API_UPS_ShipmentRequest_GetMsgData */

Go
