/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_USPS_ShipmentRequest_GetMsgData') is not null
  drop Procedure pr_API_USPS_ShipmentRequest_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_USPS_ShipmentRequest_GetMsgData: Generates Message data in the format
   required by USPS Shipment. This is the highest level procedure called when the
   API outbound transactions are being prepared to invoke the external API. This
   proc formats the data for Shipment Request as expected by UPS.

   The shipment request could be for an Order or a LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_API_USPS_ShipmentRequest_GetMsgData
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
          @vShipmentInfoXML             XML,

          @vShipFromAddress             TVarchar,
          @vShipToAddress               TVarchar,
          @vDomesticLabel               TVarchar,
          @vInternationalLabel          TVarchar,

          @vRawResponse                 TVarchar,
          @vBusinessUnit                TBusinessUnit;

begin /* pr_API_USPS_ShipmentRequest_GetMsgData */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  if (@EntityType = 'LPN')
    select @vLPNId = @EntityId,
           @vLPN   = @EntityKey;
  else
  if (@EntityType = 'Order')
    select @vOrderId    = @EntityId,
           @vPickTicket = @EntityKey;

  /* Entity Type is Required and either EntityId/EntityKey are required */
  if (@EntityId is null and @EntityKey is null) or (@EntityType is null)
    return;

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
         @vShipmentDescription      = Record.Col.value('(PACKAGES/PACKAGE/CARTONDETAILS/Description)[1]',
                                                                                            'TDescription')
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


  /* Build Ship From Address */
  exec pr_API_USPS_GetShipFromAddress @vShipmentInfoXML, @BusinessUnit, @UserId, @vShipFromAddress out;

  /* Build Ship To Address */
  exec pr_API_USPS_GetShipToAddress @vShipmentInfoXML, @BusinessUnit, @UserId, @vShipToAddress out;

  /* Build Message Data */
  select @MessageData = '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"xmlns:xsd="http://www.w3.org/2001/XMLSchema"xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
                          <soap:Body>
                           <GetPostageLabel xmlns="www.envmgr.com/LabelService"
                                            LabelType="Default"
                                            LabelSize="4x6"
                                            ImageFormat="ZPLII"
                                            LabelTemplate="string">
                           <LabelRequest Test="YES"
                                                       LabelType="Default"
                                         LabelSize="4x6"
                                         ImageFormat="ZPLII">
                           <MailClass>Priority</MailClass>
                           <WeightOz>16</WeightOz>
                           <RequesterID>d4652f6f-6205-4dbc-b0e8-dd08e6e30110</RequesterID>
                           <AccountID>3002548</AccountID>
                           <PassPhrase>July2021!</PassPhrase>
                           <PartnerCustomerID>100</PartnerCustomerID>
                           <PartnerTransactionID>200</PartnerTransactionID>' +
                           @vShipToAddress +
                           @vShipFromAddress +
                           '</LabelRequest>
                                 </GetPostageLabel>
                          </soap:Body>
                         </soap:Envelope>'

  /* Build Message Data */
  select @MessageData = '
  <?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
    <GetPostageLabel xmlns="www.envmgr.com/LabelService"
                    LabelType="Default"
                    LabelSize="4x6"
                    ImageFormat="ZPLII"
                    LabelTemplate="string">
<LabelRequest Test="YES"
                            LabelType="Default"
                    LabelSize="4x6"
                    ImageFormat="ZPLII">
  <MailClass>Priority</MailClass>
  <WeightOz>16</WeightOz>
  <RequesterID>d4652f6f-6205-4dbc-b0e8-dd08e6e30110</RequesterID>
  <AccountID>3002548</AccountID>
  <PassPhrase>July2021!</PassPhrase>
  <PartnerCustomerID>100</PartnerCustomerID>
  <PartnerTransactionID>200</PartnerTransactionID>
  <ToName>Jane Doe</ToName>
  <ToAddress1>278 Castro Street</ToAddress1>
  <ToCity>Mountain View</ToCity>
  <ToState>CA</ToState>
  <ToPostalCode>94041</ToPostalCode>
  <FromCompany>Endicia, Inc.</FromCompany>
  <FromName>John Doe</FromName>
  <ReturnAddress1>1990 Grand Ave</ReturnAddress1>
  <FromCity>El Segundo</FromCity>
  <FromState>CA</FromState>
  <FromPostalCode>90245</FromPostalCode>
</LabelRequest>
                </GetPostageLabel>
  </soap:Body>
</soap:Envelope>
'
end /* pr_API_USPS_ShipmentRequest_GetMsgData */

Go
