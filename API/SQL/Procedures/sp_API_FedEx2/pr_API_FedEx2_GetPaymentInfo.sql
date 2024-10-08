/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/04/10  RV/VS   Added ResponsibleParty node for Third_Party Service (SRIV3-502)
  2024/02/12  RV      Initial Version (CIMSV3-3395)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetPaymentInfo') is not null
  drop Procedure pr_API_FedEx2_GetPaymentInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetPaymentInfo: Returns the payment info json.
  Document Ref: https://developer.fedex.com/api/en-in/catalog/ship/v1/docs.html#operation/Create%20Shipment
  Valid Payment Types as per the document: SENDER/RECIPIENT/THIRD_PARTY/COLLECT

  Sample output:
  "shippingChargesPayment": {
    "paymentType": "SENDER",
    "payor": {
      "responsibleParty": {
        "address": {
          "streetLines": [
            "6300 Valley View St",
            ""
          ],
          "city": "Buena Park",
          "stateOrProvinceCode": "CA",
          "postalCode": "90620",
          "countryCode": "US",
          "residential": false
        },
        "contact": {
          "personName": "John Taylor",
          "emailAddress": "sample@company.com",
          "phoneNumber": "1234567890",
          "phoneExtension": "",
          "companyName": "Manhattan Beachwear",
          "faxNumber": "fax number"
        },
        "accountNumber": {
          "value": "740561073"
        }
      }
    }
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetPaymentInfo
  (@ChargesType        TDescription, -- ShippingCharges or Duties
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @AccountInfoJSON    TNVarchar output,
   @PaymentInfoJSON    TNVarchar output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          /* Order info */
          @vFreightTerms          TDescription,
          @vBillToAccount         TBillToAccount,
          @vShipFrom              TContactRefId,
          @vShipToId              TContactRefId,
          @vBillToContactType     TTypeCode,
          @vBillToAddress         TContactRefId,
          /* Payor contact */
          @vPayorContactType      TTypeCode,
          @vPayorContactRefId     TContactRefId,
          /* Shipping Account */
          @vShipperAccount        TDescription,
          @vPaymentType           TDescription,
          @vPayorAccount          TDescription,
          @vPayorAddressJSON      TNVarchar;
begin /* pr_API_FedEx2_GetPaymentInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  exec pr_Markers_Save 'FedEx_GetPaymentInfo', @@ProcId;

  select @vFreightTerms  = FreightTerms,
         @vBillToAccount = BillToAccount,
         @vShipFrom      = ShipFrom,
         @vShipToId      = ShipToId
  from #OrderHeaders;

  select @vBillToContactType = BillToContactType,
         @vBillToAddress     = BillToContact
  from #CarrierShipmentData;

  /* Identify the valid PaymentType based on FreightTerms.
     Map CIMS FreightTerms to FedEx accepted values. If there is no mapping setup, then
     we do not want to default and instead have an error be raised */
  select @vPaymentType = dbo.fn_GetMappedValueDefault ('CIMS', @vFreightTerms, 'FEDEX', 'FreightTerms',
                                                       'UNKNOWN' /* Default */, @ChargesType /* Operation */, @BusinessUnit);

  /* The shipping account being used is loaded into #ShippingAccountDetails, so get the accountnumber */
  select @vShipperAccount = ShipperAccountNumber from #ShippingAccountDetails;

  /* Get payor account based upon the payment type */
  select @vPayorAccount = case when (@vPaymentType = 'SENDER') then @vShipperAccount
                               when (@vPaymentType in ('THIRD_PARTY', 'RECIPIENT')) then @vBillToAccount
                               else @vShipperAccount
                          end;

  /* If Sender, use ShipFrom Contact,
     if 3rd Party then BillToAddress,
     if Receiver then use BillToContactType/BillToAddress - based upon availability of info and client
        choice, this could be BillTo/SoldTo/ShipTo address */
  if (@vPaymentType = 'SENDER')
    select @vPayorContactType = 'F' /* ShipFrom */, @vPayorContactRefId = @vShipFrom
  else
  if (@vPaymentType in ('THIRD_PARTY', 'RECIPIENT'))
    select @vPayorContactType = @vBillToContactType, @vPayorContactRefId = @vBillToAddress

  select @AccountInfoJSON = (select value = @vShipperAccount
                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  /* Build Payment Address json */
  exec pr_API_FedEx2_GetAddress null /* ContactId */, @vPayorContactType, @vPayorContactRefId, @vPayorAccount, null,
                                'No' /* ArrayRequired */, @BusinessUnit, @UserId, @vPayorAddressJSON out;

  select @PaymentInfoJSON = (select paymentType              = @vPaymentType,
                                    [payor.responsibleParty] = JSON_QUERY(@vPayorAddressJSON)
                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetPaymentInfo */

Go
