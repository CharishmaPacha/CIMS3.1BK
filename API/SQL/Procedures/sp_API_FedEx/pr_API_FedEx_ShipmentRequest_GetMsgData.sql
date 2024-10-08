/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_ShipmentRequest_GetMsgData') is not null
  drop Procedure pr_API_FedEx_ShipmentRequest_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_ShipmentRequest_GetMsgData: Generates Message data in the format
   required by FedEx Shipment. This is the highest level procedure called when the
   API outbound transactions are being prepared to invoke the external API. This
   proc formats the data for Shipment Request as expected by FedEx.

   The shipment request could be for an Order or a LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_ShipmentRequest_GetMsgData
  (@IntegrationName    TName,
   @MessageType        TName,
   @EntityType         TTypeCode,
   @EntityId           TRecordId,
   @EntityKey          TEntityKey,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @MessageData        TVarchar   output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vRecordId                    TRecordId,

          @vLPNId                       TRecordId,
          @vLPN                         TLPN,
          @vOrderId                     TRecordId,
          @vPickTicket                  TPickTicket,

          @vAPIHeaderInfo               TVarchar,

          @vShippingAccountUserId       TUserId,
          @vShippingAccountPassword     TPassword,
          @vShippingAccountAccessKey    TAccessKey,
          @vShipmentPackageId           TDescription,
          @vShipmentDescription         TDescription,
          @vPackagingType               TDescription,
          @vServiceType                 TDescription,
          @vShipmentInfoXML             XML,

          @vAccount                     TCustomerId,
          @vAccountName                 TName,
          @vAccountNumber               TRecordId,
          @vShipToId                    TShipToId,
          @vSoldToId                    TCustomerId,
          @vShipFrom                    TShipFrom,
          @vShipFromContactId           TRecordId,
          @vShipToContactId             TRecordId,
          @vBillToContactId             TRecordId,
          @vBillToAddress               TBillToAccount,
          @vFreightTerms                TDescription,

          @vShipperAddress              TVarchar,
          @vReceiptAddress              TVarchar,
          @vRawResponse                 TVarchar,
          @vPaymetnInfo                 TVarchar,
          @vLabelSpecification          TVarchar,
          @vAccountInfo                 TVarchar,
          @CustomsClearanceDetail       TVarchar,
          @PackageInfo                  TVarchar,
          @vBusinessUnit                TBusinessUnit;

begin /* pr_API_UPS_ShipmentRequest_GetMsgData */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  if (@EntityType = 'LPN')
    begin
      select @vLPNId = @EntityId,
             @vLPN   = @EntityKey;

      select @vOrderId = OrderId
      from LPNs
      where LPNId = @vLPNId;
    end
  else
  if (@EntityType = 'Order')
    begin
      select @vOrderId    = @EntityId,
             @vPickTicket = @EntityKey;
    end

  /* Entity Type is Required and either EntityId/EntityKey are required */
  if (@EntityId is null and @EntityKey is null) or (@EntityType is null)
    return;

  /* Get the OrderInfo */
  select @vAccount           = OH.Account,
         @vAccountName       = OH.AccountName,
         @vShipFrom          = OH.ShipFrom,
         @vShipFromContactId = SF.ContactId,
         @vShipToId          = OH.ShipToId,
         @vShipToContactId   = ST.ContactId,
         @vSoldToId          = OH.SoldToId,
         @vBillToAddress     = OH.BillToAddress,
         @vBillToContactId   = BT.ContactId,
         @vFreightTerms      = OH.FreightTerms
  from OrderHeaders OH
    left join Contacts SF on (SF.ContactType = 'F' /* ShipFrom */) and (SF.ContactRefId = OH.ShipFrom) and (SF.BusinessUnit = @BusinessUnit)
    left join Contacts ST on (SF.ContactType = 'S' /* ShipTo */) and (ST.ContactRefId = OH.ShipToId) and (ST.BusinessUnit = @BusinessUnit)
    left join Contacts BT on (BT.ContactType = 'B' /* BillTo */) and (BT.ContactRefId = OH.ShipToId) and (BT.BusinessUnit = @BusinessUnit)
  where (OH.OrderId = @vOrderId);

  /* Create hash table to hold the xml info that is being built by GetShipmentData below */
  create table #ttShipmentInfo (ShipmentInfo varchar(max));

  /* Get shipment data from existing procedure */
  insert into #ttShipmentInfo exec pr_Shipping_GetShipmentData @vLPN, @vLPNId, @vOrderId, @vPickTicket;

  select top 1 @vShipmentInfoXML = cast(ShipmentInfo as xml) from #ttShipmentInfo;

  /* Extract the Account details */
  select @vShipmentPackageId        = Record.Col.value('(ORDERHEADER/PickTicket)[1]',       'TUserId'),
         @vShippingAccountUserId    = Record.Col.value('(ACCOUNTDETAILS/USERID)[1]',        'TUserId'),
         @vShippingAccountPassword  = Record.Col.value('(ACCOUNTDETAILS/PASSWORD)[1]',      'TPassword'),
         @vShippingAccountAccessKey = Record.Col.value('(ACCOUNTDETAILS/ACCESSKEY)[1]',     'TAccessKey'),
         @vAccountNumber            = Record.Col.value('(ACCOUNTDETAILS/ACCOUNTNUMBER)[1]', 'TAccount'),
         @vShipmentDescription      = Record.Col.value('(PACKAGES/PACKAGE/CARTONDETAILS/Description)[1]',   'TDescription'),
         @vPackagingType            = Record.Col.value('(PACKAGES/PACKAGE/CARTONDETAILS/PackagingType)[1]', 'TDescription'),
         @vServiceType              = Record.Col.value('(SHIPVIA/ServiceLevel)[1]', 'TDescription')
  from @vShipmentInfoXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
  OPTION (OPTIMIZE FOR (@vShipmentInfoXML = null));

  /* Build header info as some times shipping accounts might be based upon rules, so override the default header info
     in configurations */
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
  where (IntegrationName          = @IntegrationName)          and
        (MessageType              = @MessageType)              and
        (coalesce(EntityType, '') = coalesce(@EntityType, '')) and
        (coalesce(EntityId,   '') = coalesce(@EntityId,   '')) and
        (coalesce(EntityKey,  '') = coalesce(@EntityKey,  '')) and
        (TransactionStatus in ('Initial', 'ReadyToSend', 'InProcess'));

  exec pr_API_FedEx_GetAccountInfo    @vShipmentInfoXML, @BusinessUnit, @UserId, @vAccountInfo out;

  exec pr_API_FedEx_GetAddress @vShipFromContactId, 'F' /* ShipFrom */, @vShipFrom, @BusinessUnit, @UserId, 'Shipper', @vAccountNumber, @vShipperAddress out;

  exec pr_API_FedEx_GetAddress @vShipToContactId, 'S' /* ShipTo */, @vShipToId, @BusinessUnit, @UserId, 'Recipient', @vAccountNumber, @vReceiptAddress out;

  exec pr_API_FedEx_GetPaymentInfo @vBillToContactId, 'B' /* BillTo */, @vBillToAddress, @vShipmentInfoXML, @vAccountNumber, @vFreightTerms, @BusinessUnit, @UserId, @vPaymetnInfo out;

  exec pr_API_FedEx_GetCustomInfo  @vShipmentInfoXML, @BusinessUnit, @UserId, @CustomsClearanceDetail out;

  exec pr_API_FedEx_GetLabelSpecifications @vShipmentInfoXML, @BusinessUnit, @UserId, @vLabelSpecification out;

  exec pr_API_FedEx_GetPackageInfo @vShipmentInfoXML, @BusinessUnit, @UserId, @PackageInfo out;

  /* Build Message Data */
  select @MessageData = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="http://fedex.com/ws/ship/v26">
                          <soapenv:Header>
                           <soapenv:Body>
                            <ProcessShipmentRequest>' +
                             @vAccountInfo +
                             '<TransactionDetail>
                               <CustomerTransactionId>IFSS_ISR</CustomerTransactionId>
                              </TransactionDetail>
                              <Version>
                               <ServiceId>ship</ServiceId>
                               <Major>26</Major>
                               <Intermediate>0</Intermediate>
                               <Minor>0</Minor>
                              </Version>' +
                              '<RequestedShipment>' +
                                '<DropoffType>REGULAR_PICKUP</DropoffType>'+             --DropoffType
                                dbo.fn_XMLNode('ServiceType', @vServiceType) +
                                dbo.fn_XMLNode('PackagingType', @vPackagingType) +
                                @vShipperAddress +
                                @vReceiptAddress +
                                @vPaymetnInfo    +
                                @CustomsClearanceDetail +
                                @vLabelSpecification +
                                '<RateRequestTypes>LIST</RateRequestTypes>' +            --RateRequestTypes
                                @PackageInfo +
                              '</RequestedShipment>' +
                            '</ProcessShipmentRequest>'+
                           '</soapenv:Body>
                          </soapenv:Header>
                         </soapenv:Envelope>';

end /* pr_API_UPS_ShipmentRequest_GetMsgData */

Go
