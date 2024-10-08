/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetAddress') is not null
  drop Procedure pr_API_UPS_GetAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetAddress: Returns the request address in jsonn as expected by UPS.

  Sample output:
  {
   "Name":"Otay",
   "AttentionName":"Otay",
   "Phone":{
      "Number":"9999999999"
   },
   "Address":{
      "AddressLine":"6060 BUSINESS CENTER CT",
      "City":"SAN DIEGO",
      "StateProvinceCode":"CA",
      "PostalCode":"92154",
      "CountryCode":"US"
   }
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_GetAddress
  (@ContactId     TRecordId,
   @ContactType   TTypeCode,
   @ContactRefId  TContactRefId,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @AddressJSON   TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_UPS_GetAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  if (@ContactId is null)
    select @ContactId = ContactId
    from Contacts
    where (ContactType = @ContactType) and (ContactRefId = @ContactRefId) and (BusinessUnit = @BusinessUnit);

  /* Build Address as JSON */
  select @AddressJSON = (select Name                                  = Name,
                                AttentionName                         = ContactPerson,
                                TaxIdentificationNumber               = TaxId,
                                [Phone.Number]                        = PhoneNo,
                                FaxNumber                             = '',
                                EmailAddress                          = Email,
                                [Address.AddressLine]                 = JSON_QUERY(CONCAT('["',
                                                                        AddressLine1, '","',
                                                                        AddressLine2, '","',
                                                                        AddressLine3, '"]')),
                                [Address.City]                        = City,
                                [Address.StateProvinceCode]           = State,
                                [Address.PostalCode]                  = Zip,
                                [Address.CountryCode]                 = Country,
                                /* ResidentialAddressIndicator: This field is a flag to indicate if the receiver is a residential location
                                   True if ResidentialAddressIndicator tag exists. */
                                [Address.ResidentialAddressIndicator] = case when (Residential ='Y') then '' else null end
                         from Contacts
                         where (ContactId = @ContactId)
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetAddress */

Go
