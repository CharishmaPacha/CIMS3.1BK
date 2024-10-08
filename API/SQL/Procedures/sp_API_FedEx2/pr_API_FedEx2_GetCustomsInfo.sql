/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/20  RV      Initial Version (CIMSV3-3434)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetCustomsInfo') is not null
  drop Procedure pr_API_FedEx2_GetCustomsInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetCustomsInfo: Returns the CustomInfo in JSON Format for FEDEX.

  Sample JSON expecting by FedEx:

  {
    "regulatoryControls": "NOT_IN_FREE_CIRCULATION",
    "commercialInvoice": {
      "originatorName": "originator Name",
      "comments": [
        "optional comments for the commercial invoice"
      ],
      "customerReferences": [
      {
        "customerReferenceType": "INVOICE_NUMBER",
        "value": "3686"
      }
      ],
      "taxesOrMiscellaneousCharge": {
        "amount": 12.45,
        "currency": "USD"
      },
      "taxesOrMiscellaneousChargeType": "COMMISSIONS",
      "freightCharge": {
        "amount": 12.45,
        "currency": "USD"
      },
      "packingCosts": {
        "amount": 12.45,
        "currency": "USD"
      },
      "handlingCosts": {
        "amount": 12.45,
        "currency": "USD"
      },
      "declarationStatement": "declarationStatement",
      "termsOfSale": "FCA",
      "specialInstructions": "specialInstructions\"",
      "shipmentPurpose": "REPAIR_AND_RETURN",
      "emailNotificationDetail": {
        "emailAddress": "neena@fedex.com",
        "type": "EMAILED",
        "recipientType": "SHIPPER"
      }
    },
    "freightOnValue": "OWN_RISK",
    "dutiesPayment": {
      "payor": {
        "responsibleParty": {
          "address": {
            "streetLines": [
              "10 FedEx Parkway",
              "Suite 302"
            ],
          "city": "Beverly Hills",
          "stateOrProvinceCode": "CA",
          "postalCode": "38127",
          "countryCode": "US",
          "residential": false
        },
        "contact": {
          "personName": "John Taylor",
          "emailAddress": "sample@company.com",
          "phoneNumber": "1234567890",
          "phoneExtension": "phone extension",
          "companyName": "Fedex",
          "faxNumber": "fax number"
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
          },
          {
            "number": "number",
            "tinType": "FEDERAL",
            "usage": "usage",
            "effectiveDate": "2000-01-23T04:56:07.000+00:00",
            "expirationDate": "2000-01-23T04:56:07.000+00:00"
          }
        ]
      }
    },
    "billingDetails": {
      "billingCode": "billingCode",
      "billingType": "billingType",
      "aliasId": "aliasId",
      "accountNickname": "accountNickname",
      "accountNumber": "Your account number",
      "accountNumberCountryCode": "US"
    },
    "paymentType": "SENDER"
  },
  "commodities": [
    {
      "unitPrice": {
        "amount": 12.45,
        "currency": "USD"
      },
      "additionalMeasures": [
        {
          "quantity": 12.45,
          "units": "KG"
        }
      ],
      "numberOfPieces": 12,
      "quantity": 125,
      "quantityUnits": "Ea",
      "customsValue": {
        "amount": "1556.25",
        "currency": "USD"
      },
      "countryOfManufacture": "US",
      "cIMarksAndNumbers": "87123",
      "harmonizedCode": "0613",
      "description": "description",
      "name": "non-threaded rivets",
      "weight": {
        "units": "KG",
        "value": 68
      },
      "exportLicenseNumber": "26456",
      "exportLicenseExpirationDate": "2024-02-16T09:08:32Z",
      "partNumber": "167",
      "purpose": "BUSINESS",
      "usmcaDetail": {
        "originCriterion": "A"
      }
    }
  ],
  "isDocumentOnly": true,
  "importerOfRecord": {
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
      "phoneExtension": "000",
      "phoneNumber": "XXXX345671",
      "companyName": "Fedex"
    },
    "accountNumber": {
      "value": "Your account number"
    },
    "tins": [
      {
        "number": "123567",
        "tinType": "FEDERAL",
        "usage": "usage",
        "effectiveDate": "2000-01-23T04:56:07.000+00:00",
        "expirationDate": "2000-01-23T04:56:07.000+00:00"
      }
    ]
  },
  "generatedDocumentLocale": "en_US",
  "exportDetail": {
    "exportComplianceStatement": "12345678901234567"
  },
  "totalCustomsValue": {
    "amount": 12.45,
    "currency": "USD"
  },
  "insuranceCharge": {
    "amount": 12.45,
    "currency": "USD"
  }
}
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetCustomsInfo
  (@LoadId                     TRecordId,
   @BusinessUnit               TBusinessUnit,
   @UserId                     TUserId,
   @CommoditiesReq             TFlags,
   @CustomsClearanceDetailJSON TVarchar output)
as
  declare @vReturnCode                        TInteger,
          @vMessageName                       TMessageName,
          -- Order info
          @vPickTicket                        TPickTicket,
          @vShipFrom                          TContactRefId,
          @vShipFromName                      TName,
          @vOHAESNumber                       TAESNumber,
          @vTotalCustomsValueJSON             TNVarChar,
          @vShipToCountry                     TCountry,
          -- Load Info
          @vLoadAESNumber                     TAESNumber,
          @vAccountInfoJSON                   TNVarchar,
          @vPaymentInfoJSON                   TNVarchar,
          --CommercialInvoice doc Info
          @vBrokerInfoJSON                    TNVarchar,
          @vContact                           TVarchar,
          @vCommoditiesJSON                   TNVarchar,
          @vCommercialInvoiceJSON             TNVarchar,
          @vDefaultExportCompliance           TVarchar,
          @vExportDetialJSON                  TNVarchar;

  declare @ttMarkers                          TMarkers;

begin /* pr_API_FedEx2_GetCustomsInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Extract the customs value */
  select @vPickTicket  = PickTicket,
         @vShipFrom    = ShipFrom,
         @vOHAESNumber = AESNumber
  from #OrderHeaders;

  /* Get Ship From */
  select @vShipFromName = Name
  from vwShipFromAddress
  where (ContactRefId = @vShipFrom) and (BusinessUnit = @BusinessUnit);

  /* AES number to be used is from Loads for IPD and from Orders for others. For IPD, the AES number is for
     the entire shipment and saved in ClientLoad (since we do not have AES on the Load) */
  select @vLoadAESNumber = ClientLoad
  from Loads
  where (LoadId = @LoadId) and (LoadType = 'FEDEXIPD');

  /* Get Default Export Compliance Statement value from controls */
  select @vDefaultExportCompliance = dbo.fn_Controls_GetAsString('Shipping_FedEx', 'ExportCompliance', '30.37(f)', @BusinessUnit, @UserId);

  /* Get the Brokers info to print on Commercial Invoice document */
  if exists (select * from #CarrierShipmentdata where dbo.fn_IsInList('CI', InternationalDocsRequired) > 0)
    exec pr_API_FedEx2_GetBrokersInfo @BusinessUnit, @UserId, 'Brokers', @vBrokerInfoJSON out;

  /* Get the Invoice Number in Commercial Invoice document */
  select @vCommercialInvoiceJSON = (select [originatorName]       = @vShipFromName,
                                           [comments]             = JSON_QUERY('[' + CIComments + ']'),
                                           [customerReferences]   = JSON_QUERY('[{"customerReferenceType": "INVOICE_NUMBER",
                                                                                                  "value": "'+ @vPickTicket +'"}]'),
                                           [declarationStatement] = CIDeclaration,
                                           [termsOfSale]          = TermsOfSale,
                                           [specialInstructions]  = CISpecialInstructions,
                                           [shipmentPurpose]      = Purpose
                                    from #CarrierShipmentData
                                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  exec pr_API_FedEx2_GetPaymentInfo 'DutiesPayment', @BusinessUnit, @UserId, @vAccountInfoJSON out, @vPaymentInfoJSON out;

  /* Here, we get the commodities of entire shipment, so we do not pass in the LPN Info */
  if (@CommoditiesReq = 'Yes')
    exec pr_API_FedEx2_GetCommoditiesInfo null /* LPNId */, @BusinessUnit, @UserId, @vCommoditiesJSON out;

  select @vExportDetialJSON = (select exportComplianceStatement = coalesce(@vLoadAESNumber, @vOHAESNumber, @vDefaultExportCompliance)
                               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  select @vTotalCustomsValueJSON = (select [amount]   = cast(sum(LineValue) as numeric(8,2)),
                                           [currency] = max(Currency)
                                    from #CommoditiesInfo
                                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  select @CustomsClearanceDetailJSON = (select brokers           = JSON_QUERY(@vBrokerInfoJSON),
                                               commercialInvoice = JSON_QUERY(@vCommercialInvoiceJSON),
                                               dutiesPayment     = JSON_QUERY(@vPaymentInfoJSON),
                                               commodities       = JSON_QUERY(@vCommoditiesJSON),
                                               exportDetail      = JSON_QUERY(@vExportDetialJSON),
                                               totalCustomsValue = JSON_QUERY(@vTotalCustomsValueJSON)
                                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetCustomsInfo */

Go
