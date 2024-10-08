/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/04/12  RV      pr_API_UPS_GetShipToAddress: Made changes to print ShipToStore on SPL for GTI account orders (BK-1045)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetShipToAddress') is not null
  drop Procedure pr_API_UPS_GetShipToAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetShipToAddress: Returns the Ship To address json

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
Create Procedure pr_API_UPS_GetShipToAddress
  (@InputXML          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @ShipToAddressJSON TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vAccount                TCustomerId;
begin /* pr_API_UPS_GetShipToAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  select @vAccount = Record.Col.value('(ORDERHEADER/Account)[1]', 'TCustomerId')
  from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
  OPTION (OPTIMIZE FOR ( @InputXML = null ));

  /* Build Ship from json, print ShipToStore on SPL for GTI account */
  if (@vAccount = 'GTI')
    select @ShipToAddressJSON = (select Name                                  = Record.Col.value('(SHIPTOADDRESS/ContactPerson)[1]', 'TName'),
                                        AttentionName                         = Record.Col.value('(ORDERHEADER/ShipToStore)[1]',     'TShipToStore'),
                                        TaxIdentificationNumber               = Record.Col.value('(SHIPTOADDRESS/TaxId)[1]',         'TTaxId'),
                                        [Phone.Number]                        = Record.Col.value('(SHIPTOADDRESS/PhoneNo)[1]',       'TPhoneNo'),
                                        FaxNumber                             = Record.Col.value('(SHIPTOADDRESS/FaxNumber)[1]',     'TPhoneNo'),
                                        EmailAddress                          = Record.Col.value('(SHIPTOADDRESS/Email)[1]',         'TEmailAddress'),
                                        [Address.AddressLine]                 = JSON_QUERY(CONCAT('["',
                                                                                Record.Col.value('(SHIPTOADDRESS/AddressLine1)[1]',  'TAddressLine'), '","',
                                                                                Record.Col.value('(SHIPTOADDRESS/Name)[1]',          'TName'), '","',
                                                                                Record.Col.value('(SHIPTOADDRESS/AddressLine2)[1]',  'TAddressLine'), '"]')),
                                        [Address.City]                        = Record.Col.value('(SHIPTOADDRESS/City)[1]',          'TCity'),
                                        [Address.StateProvinceCode]           = Record.Col.value('(SHIPTOADDRESS/State)[1]',         'TState'),
                                        [Address.PostalCode]                  = Record.Col.value('(SHIPTOADDRESS/Zip)[1]',           'TZip'),
                                        [Address.CountryCode]                 = Record.Col.value('(SHIPTOADDRESS/Country)[1]',       'TCountry'),
                                        /* ResidentialAddressIndicator: This field is a flag to indicate if the receiver is a residential location
                                           True if ResidentialAddressIndicator tag exists.*/
                                        [Address.ResidentialAddressIndicator] = case when (Record.Col.value('(SHIPTOADDRESS/Residential)[1]',   'TFlag') = 'Y') then '' else null end
                                 from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
                                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                 OPTION (OPTIMIZE FOR ( @InputXML = null ));
  else
    select @ShipToAddressJSON = (select Name                                  = Record.Col.value('(SHIPTOADDRESS/Name)[1]',          'TName'),
                                        AttentionName                         = Record.Col.value('(SHIPTOADDRESS/ContactPerson)[1]', 'TName'),
                                        TaxIdentificationNumber               = Record.Col.value('(SHIPTOADDRESS/TaxId)[1]',         'TTaxId'),
                                        [Phone.Number]                        = Record.Col.value('(SHIPTOADDRESS/PhoneNo)[1]',       'TPhoneNo'),
                                        FaxNumber                             = Record.Col.value('(SHIPTOADDRESS/FaxNumber)[1]',     'TPhoneNo'),
                                        EmailAddress                          = Record.Col.value('(SHIPTOADDRESS/Email)[1]',         'TEmailAddress'),
                                        [Address.AddressLine]                 = JSON_QUERY(CONCAT('["',
                                                                                Record.Col.value('(SHIPTOADDRESS/AddressLine1)[1]',  'TAddressLine'), '","',
                                                                                Record.Col.value('(SHIPTOADDRESS/AddressLine2)[1]',  'TAddressLine'), '","',
                                                                                Record.Col.value('(SHIPTOADDRESS/AddressLine3)[1]',  'TAddressLine'), '"]')),
                                        [Address.City]                        = Record.Col.value('(SHIPTOADDRESS/City)[1]',          'TCity'),
                                        [Address.StateProvinceCode]           = Record.Col.value('(SHIPTOADDRESS/State)[1]',         'TState'),
                                        [Address.PostalCode]                  = Record.Col.value('(SHIPTOADDRESS/Zip)[1]',           'TZip'),
                                        [Address.CountryCode]                 = Record.Col.value('(SHIPTOADDRESS/Country)[1]',       'TCountry'),
                                        /* ResidentialAddressIndicator: This field is a flag to indicate if the receiver is a residential location
                                           True if ResidentialAddressIndicator tag exists.*/
                                        [Address.ResidentialAddressIndicator] = case when (Record.Col.value('(SHIPTOADDRESS/Residential)[1]',   'TFlag') = 'Y') then '' else null end
                                 from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
                                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                 OPTION (OPTIMIZE FOR ( @InputXML = null ));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetShipToAddress */

Go
