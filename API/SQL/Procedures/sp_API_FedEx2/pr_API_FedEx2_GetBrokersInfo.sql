/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/12  RV      Initial Version (CIMSV3-3434)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetBrokersInfo') is not null
  drop Procedure pr_API_FedEx2_GetBrokersInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetBrokersInfo: Get the Brokerinfo to print on the
    Commercial Invoice document. FedEx by default provides the brokerage service
    in which case nothing would be sent in the request. This is the case with
    most of our customers. But if our client chooses to, they can designate to
    use their own broker by setting up a contact for example like  FEDEX-FR (FR - France)
    and then we would consider that as a designated broker for that country.

  https://www.fedex.com/en-us/shipping/international/brokerage.html

  Sample:
  [
    {
        "broker": {
            "address": {
                "streetLines": [
                    "10 FedEx Parkway",
                    "Suite 302"
                ],
                "city": "Beverly Hills",
                "stateOrProvinceCode": "CA",
                "postalCode": "90210",
                "countryCode": "US",
                "residential": false
            },
            "contact": {
                "personName": "John Taylor",
                "emailAddress": "sample@company.com",
                "phoneNumber": "1234567890",
                "phoneExtension": 91,
                "companyName": "Fedex",
                "faxNumber": 1234567
            },
            "accountNumber": {
                "value": "Your account number"
            },
            "tins": [
                {
                    "number": "number",
                    "tinType": "FEDERAL",
                    "usage": "usage",
                    "effectiveDate": "2000-01-23T04:56:07.000+00:00",
                    "expirationDate": "2000-01-23T04:56:07.000+00:00"
                }
            ],
            "deliveryInstructions": "deliveryInstructions"
        },
        "type": "IMPORT"
    }
]
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetBrokersInfo
 (@BusinessUnit       TBusinessUnit,
  @UserId             TUserId,
  @RootNode           TDescription,
  @BrokerInfoJSON     TNVarchar output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vBRAddressId                TRecordId,
          @vAccountNumber              TName,
          @vBrokerContactRefId         TContactRefId,
          @vBrokerContactJSON          TNVarchar,
          @vCarrier                    TCarrier,
          @vShipVia                    TShipVia,
          @vShipToCountry              TCountry,
          @vShipToAddressRegion        TAddressRegion,
          @vInternationalDocsRequired  TString,
          @vClearanceFacility          TControlValue;

begin /* pr_API_FedEx2_GetBrokersInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the Clearance facility */
  select @vClearanceFacility = dbo.fn_Controls_GetAsString('FEDEX_IPD', 'ClearanceFacility', 'IDSI', @BusinessUnit, @UserId);

  select @vCarrier                   = Carrier,
         @vShipVia                   = ShipVia,
         @vShipToCountry             = ShipToCountry,
         @vShipToAddressRegion       = ShipToAddressRegion,
         @vInternationalDocsRequired = InternationalDocsRequired
  from #CarrierShipmentData;

  if (@vShipVia = 'FEDEXIPD')
    select @vBrokerContactRefId = @vClearanceFacility;
  else
  if (dbo.fn_IsInList('CI', @vInternationalDocsRequired) > 0)
    select @vBrokerContactRefId = concat(@vCarrier, '-', @vShipToCountry);

  /* Get the Broker contact info based on State */
  select @vBRAddressId   = ContactId,
         @vAccountNumber = Reference1 /* AccountNumber # */
  from Contacts
  where (ContactType = 'BR') and (ContactRefId = @vBrokerContactRefId);

  /* If there is no Broker contact available then exit */
  if (@vBRAddressId is null) return;

  exec pr_API_FedEx2_GetAddress @vBRAddressId, 'BR' /* Broker */, null /* ContactRefId */, @vAccountNumber /* Acct # */, null /* Root Node */, 'Yes' /* TINsRequired */,
                                @BusinessUnit, @UserId, @vBrokerContactJSON out;

  select @BrokerInfoJSON = (select broker = JSON_QUERY(@vBrokerContactJSON),
                                   type   = 'IMPORT'
                            FOR JSON PATH);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetBrokersInfo */

Go
