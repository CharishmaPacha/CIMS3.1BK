/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/12  RV      Initial Version (CIMSV3-3532)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_AddressValidation_GetMsgData') is not null
  drop Procedure pr_API_FedEx2_AddressValidation_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_AddressValidation_GetMsgData:
   Generates Message data in the format
   required by FEDEX Address Validation. This is the highest level procedure called when the
   API outbound transactions are being prepared to invoke the external API. This
   proc formats the data for Address Validation Request as expected by FEDEX.
   The Address Validation request could be for Contact

  MessageData:
  {
     "inEffectAsOfTimestamp": "2024-04-26",
     "validateAddressControlParameters": {
       "includeResolutionTokens": "false"
     },
     "addressesToValidate": [
       {
         "address": {
           "streetLines": [
             "218 Memorial Avenue",
             "",
             ""
           ],
           "city": "West Springfield",
           "stateOrProvinceCode": "MA",
           "postalCode": "01089",
           "countryCode": "US"
         },
         "clientReferenceId": "8010-S"
       }
     ]
  }
  Document Ref: https://developer.fedex.com/api/en-in/catalog/address-validation/v1/docs.html
------------------------------------------------------------------------------*/
create procedure pr_API_FedEx2_AddressValidation_GetMsgData
  (@TransactionRecordId  TRecordId,
   @MessageData          TVarchar   output)
as
  declare @vReturnCode                    TInteger,
          @vMessageName                   TMessageName,
          @vMessage                       TMessage,
          @vRecordId                      TRecordId,
          @vRulesDataXML                  TXML,

          @vEntityType                    TTypeCode,
          @vContactId                     TRecordId,
          @vContactRefId                  TEntityKey,
          @vInEffectAsOfTimestamp         TDate,
          @vValidateAddressParametersJSON TNVarchar,
          @vAddressesToValidateJSON       TNVarchar,

          @vDebug                         TFlags,
          @vBusinessUnit                  TBusinessUnit,
          @vUserId                        TUserName

  declare @ttShipppingAccountDetails      TShipppingAccountDetails;
begin /* pr_API_FedEx2_AddressValidation_GetMsgData */
  /* Initialize */
  select @vReturnCode           = 0,
         @vMessageName          = null,
         @vRecordId             = 0;

  /* Get the Contact Id from API transaction */
    select @vContactId    = EntityId,
           @vContactRefId = EntityKey,
           @vEntityType   = EntityType,
           @vBusinessUnit = BusinessUnit
    from APIOutboundTransactions
    where (RecordId = @TransactionRecordId);

  /* Entity Type and EntityId are required */
  if (@vContactId is null) or (@vEntityType <> 'Contact')
    return;

  /*-------------------- Create hash tables --------------------*/
  select * into #ShippingAccountDetails from ShippingAccounts where (1 = 2)
  union all
  select * from ShippingAccounts where (1 <> 1);

  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Carrier', 'FEDEX'));

  /* Identify the shipping account to use and load details into #ShippingAccountDetails */
  exec pr_Carrier_GetShippingAccountDetails @vRulesDataXML, null /* ShipVia */, @vBusinessUnit, @vUserId;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  /* This can be used to request the characteristics of an address had at a particular time in history.
     This defaults to current date time */
  select @vInEffectAsOfTimestamp = format(getdate(), 'yyyy-MM-dd');

  /* Use this to request detailed information of the address components once the validation is complete.
     The details specify the changes made to each address component to resolve the address */
  select @vValidateAddressParametersJSON = (select [includeResolutionTokens] = 'false'
                                            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  select @vAddressesToValidateJSON = (select [address.streetLines]         = JSON_QUERY(CONCAT('["',
                                                                             left(AddressLine1, 35), '","',
                                                                             left(AddressLine2, 35), '","',
                                                                             left(AddressLine3, 35), '"]')),
                                             [address.city]                = City,
                                             [address.stateOrProvinceCode] = State,
                                             [address.postalCode]          = Zip,
                                             [address.countryCode]         = Country,
                                             [clientReferenceId]           = concat(ContactRefId, '-', ContactType)
                                      from Contacts
                                      where (ContactId = @vContactId)
                                      FOR JSON PATH)

  /* Update the header info with token */
  exec pr_API_FedEx2_UpdateHeaderInfo @TransactionRecordId, @vBusinessUnit;

  /* Build Message Data */
  select @MessageData =
    '{' + concat_ws(', ',
        '"inEffectAsOfTimestamp": '               + '"' + cast(@vInEffectAsOfTimestamp as  varchar(20)) + '"',
        '"validateAddressControlParameters": '    + @vValidateAddressParametersJSON,
        '"addressesToValidate": '                 + @vAddressesToValidateJSON) +
    '}';

  /* Log the Marker Details */
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'End', @@ProcId, @vContactId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log default, 'Contact', @vContactId, @vContactRefId, 'API_FedEx2_AddressValidation', @@ProcId, 'Markers_FedEx2_AddressValidation', @vUserId, @vBusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_AddressValidation_GetMsgData */

Go