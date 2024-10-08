/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetSoldToAddress') is not null
  drop Procedure pr_API_UPS_GetSoldToAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetSoldToAddress: Returns the Ship To address json

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
Create Procedure pr_API_UPS_GetSoldToAddress
  (@InputXML          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @SoldToAddressJSON TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_UPS_GetSoldToAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

    /* Build Ship from json */
  select @SoldToAddressJSON = (select Name                                  = Record.Col.value('(SOLDTOADDRESS/Name)[1]',          'TName'),
                                      AttentionName                         = Record.Col.value('(SOLDTOADDRESS/ContactPerson)[1]', 'TName'),
                                      TaxIdentificationNumber               = Record.Col.value('(SOLDTOADDRESS/TaxId)[1]',         'TTaxId'),
                                      [Phone.Number]                        = Record.Col.value('(SOLDTOADDRESS/PhoneNo)[1]',       'TPhoneNo'),
                                      FaxNumber                             = Record.Col.value('(SOLDTOADDRESS/FaxNumber)[1]',     'TPhoneNo'),
                                      EmailAddress                          = Record.Col.value('(SOLDTOADDRESS/Email)[1]',         'TEmailAddress'),
                                      [Address.AddressLine]                 = JSON_QUERY(CONCAT('["',
                                                                              Record.Col.value('(SOLDTOADDRESS/AddressLine1)[1]',  'TAddressLine'), '","',
                                                                              Record.Col.value('(SOLDTOADDRESS/AddressLine2)[1]',  'TAddressLine'), '","',
                                                                              Record.Col.value('(SOLDTOADDRESS/AddressLine3)[1]',  'TAddressLine'), '"]')),
                                      [Address.City]                        = Record.Col.value('(SOLDTOADDRESS/City)[1]',          'TCity'),
                                      [Address.StateProvinceCode]           = Record.Col.value('(SOLDTOADDRESS/State)[1]',         'TState'),
                                      [Address.PostalCode]                  = Record.Col.value('(SOLDTOADDRESS/Zip)[1]',           'TZip'),
                                      [Address.CountryCode]                 = Record.Col.value('(SOLDTOADDRESS/Country)[1]',       'TCountry'),
                                      /* ResidentialAddressIndicator: This field is a flag to indicate if the receiver is a residential location
                                         True if ResidentialAddressIndicator tag exists.*/
                                      [Address.ResidentialAddressIndicator] = case when (Record.Col.value('(SOLDTOADDRESS/Residential)[1]',   'TFlag') = 'Y') then '' else null end
                               from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
                               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                               OPTION (OPTIMIZE FOR ( @InputXML = null ));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetSoldToAddress */

Go
