/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/27  TD      pr_API_UPS_AddressValidation_GetMsgData:Passing the address data in Uppercase(BK-997)
  2022/07/29  RV      pr_API_UPS_AddressValidation_GetMsgData: Made changes to accept API RecordId
  2022/04/22  RT      pr_API_UPS_AddressValidation_GetMsgData: Procedure to prepare the Address validation Input format
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_AddressValidation_GetMsgData') is not null
  drop Procedure pr_API_UPS_AddressValidation_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_AddressValidation_GetMsgData: Generates Message data in the format
   required by Street level Address Validation. This is the highest level procedure called when the
   API outbound transactions are being prepared to invoke the external API. This
   proc formats the data for Address Validation.

   Note: we have request format in the below document
   D:/SVN/CIMS 3.0/branches/Dev3.0/Documents/Manuals/Developer Manuals/Address Validation RESTful API Developer Guide.pdf

   The shipment request will be ContactId and ContactRefId.
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_AddressValidation_GetMsgData
  (@TransactionRecordId TRecordId,
   @MessageData         TVarchar   output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vRecordId                    TRecordId,

          @vContactId                   TRecordId,
          @vContactRefId                TContactRefId,

          @vEntityType                  TTypeCode,
          @vAPIHeaderInfo               TVarchar,

          @vShippingAccountUserId       TUserId,
          @vShippingAccountPassword     TPassword,
          @vShippingAccountAccessKey    TAccessKey;

begin /* pr_API_UPS_AddressValidation_GetMsgData */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

    select @vContactId    = EntityId,
           @vContactRefId = EntityKey,
           @vEntityType   = EntityType
    from APIOutBoundTransactions
    where (RecordId = @TransactionRecordId);

  /* Entity Type is Required and either EntityId/EntityKey are required */
  if (@vContactId is null and @vContactRefId is null) or (@vEntityType <> 'Contact')
    return;

  /* Get the details for the Shipping Accounts */
  select top 1
         @vShippingAccountUserId    = nullif(UserId,   ''),
         @vShippingAccountPassword  = nullif(Password, ''),
         @vShippingAccountAccessKey = ShipperAccessKey
  from ShippingAccounts
  where (Carrier = 'UPS') and
        (Status  = 'A' /* Active */);

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
      HeaderInfo         = @vAPIHeaderInfo
  where (RecordId = @TransactionRecordId) and
        (TransactionStatus in ('Initial', 'ReadyToSend', 'InProcess'));

  /* Build Message Data */
  select @MessageData = '
  {
     "XAVRequest":
     {
        "AddressKeyFormat":
        {
           "ConsigneeName":'                + coalesce('"' + Name         +   '"', '""')   +',
           "BuildingName":'                 + '""' +',
           "AddressLine":'                  + JSON_QUERY(upper(concat('["', AddressLine1, '","',
                                                                            AddressLine2, '","',
                                                                            AddressLine3, '"]'))) +',
           "Region":'                       + coalesce('"' + upper(CityStateZip) +   '"', '""')   +',
           "Urbanization":'                 + '""'  +',
           "CountryCode":'                  + coalesce('"' + case when Country = 'USA' then 'US'
                                                               else upper(Country)
                                                             end          +   '"', '""')   +'
        }
     }
  }'
  from Contacts
  where (ContactType  = 'S') and
        (ContactId    = @vContactId);
end /* pr_API_UPS_AddressValidation_GetMsgData */

Go
