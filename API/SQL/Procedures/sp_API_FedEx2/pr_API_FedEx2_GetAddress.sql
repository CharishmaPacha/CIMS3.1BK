/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/04/10  RV/VS   Company name is not accepting more than 35 Characters (SRIV3-502)
  2024/03/23  VS      Get the Default PhoneNo (SRIV3-450)
  2024/02/12  RV      Initial Version (CIMSV3-3395)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetAddress') is not null
  drop Procedure pr_API_FedEx2_GetAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetAddress: Returns the address json for the given contact
    type and contact ref id.
    RootNode:      Add the root node if caller send
    ArrayRequired: For some addresses required addresses in array format.

  Sample output:
  {
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
          "phoneExtension": "91",
          "phoneNumber": "XXXX567890",
          "companyName": "Fedex"
      },
      "tins": [
          {
              "number": "XXX567",
              "tinType": "FEDERAL",
              "usage": "usage",
              "effectiveDate": "2000-01-23T04:56:07.000+00:00",
              "expirationDate": "2000-01-23T04:56:07.000+00:00"
          }
      ]
   }
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetAddress
  (@ContactId     TRecordId,
   @ContactType   TTypeCode,
   @ContactRefId  TContactRefId,
   @AccountNumber TDescription,
   @RootNode      TDescription,
   @ArrayRequired TFlags,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @AddressJSON   TNVarchar        output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vDefaultEmailId        TControlValue,
          @vDefaultPhoneno        TControlValue,
          @vAddressRegion         TAddressRegion,
          @vTinType               TName,
          @vTaxId                 TTaxId,
          @vTins                  TVarchar,
          @vAccountNumberInfo     TVarchar;
begin /* pr_API_FedEx2_GetAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vTinType     = 'BUSINESS_STATE';

  exec pr_Markers_Save 'FedEx_GetAddress', @@ProcId, @ContactType;

  /* Get the Default EmailId */
  select @vDefaultEmailId = dbo.fn_Controls_GetAsString('ShipLabels', 'DefaultEmailId', '', @BusinessUnit, @UserId),
         @vDefaultPhoneno = dbo.fn_Controls_GetAsString('ShipLabels', 'DefaultPhoneNo', '', @BusinessUnit, @UserId);

  /* Get ContactId if not sent from caller */
  if (@ContactId is null)
    select @ContactId      = ContactId,
           @vTaxId         = TaxId,
           @vAddressRegion = AddressRegion
    from Contacts
    where (ContactRefId = @ContactRefId) and (ContactType = @ContactType) and (BusinessUnit = @BusinessUnit);

  /* Here Shipper address is printing on label, If we are not sending Ship from then consider the shipper is
     the Ship from address */
  select @AddressJSON = (select [address.streetLines]         = JSON_QUERY(CONCAT('["',
                                                                AddressLine1, '","',
                                                                AddressLine2, '","',
                                                                AddressLine3, '"]')),
                                [address.city]                = City,
                                [address.stateOrProvinceCode] = State,
                                [address.postalCode]          = Zip,
                                [address.countryCode]         = Country,
                                [address.residential]         = iif (Residential = 'Y', 'true', 'false'),
                                [contact.personName]          = coalesce(nullif(ContactPerson, ''), Name),
                                [contact.emailAddress]        = coalesce(nullif(replace(Email, '+', ''), ''), @vDefaultEmailId),
                                [contact.phoneExtension]      = '',
                                [contact.phoneNumber]         = coalesce(nullif(replace(PhoneNo, '+', ''), ''), @vDefaultPhoneno),
                                [contact.companyName]         = left(Name, 35),
                                [tins]                        = JSON_QUERY(CONCAT('[{',
                                                                '"number":        "', TaxId, '",',
                                                                '"tinType":       "', @vTinType, '",',
                                                                '"usage":         "",',
                                                                '"effectiveDate": ""',
                                                                 '}]')),
                                [accountNumber.value]         = @AccountNumber
                         from Contacts
                         where (ContactId = @ContactId)
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  -- ToDo: Including Account Number always was giving errors previously. Need to verify that.
  -- ToDo: Can Tins be included always along with address always? Previously, it was required only for IPD

  if (@ArrayRequired = 'Yes')
    select @AddressJSON = concat('[', @AddressJSON, ']');

  if (@AddressJSON is not null) and (coalesce(@RootNode, '') <> '')
    select @AddressJSON = concat('"' + @RootNode + '":', @AddressJSON);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetAddress */

Go
