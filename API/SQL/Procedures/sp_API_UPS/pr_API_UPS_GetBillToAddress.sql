/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetBillToAddress') is not null
  drop Procedure pr_API_UPS_GetBillToAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetBillToAddress: Returns the Ship To address json

  Sample output:
  {
   "Name":"Otay",
   "AttentionName":"Otay",
   "Phone":{
      "Number":"9999999999"
   },
   "ShipperNumber":"F95314",
   "Address":{
      "AddressLine":"6060 BUSINESS CENTER CT",
      "City":"SAN DIEGO",
      "StateProvinceCode":"CA",
      "PostalCode":"92154",
      "CountryCode":"US"
   }
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_GetBillToAddress
  (@InputXML          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @BillToAddressJSON TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_UPS_GetBillToAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

    /* Build Ship from json */
  select @BillToAddressJSON = (select Name                                  = Record.Col.value('(BILLTOADDRESS/Name)[1]',          'TName'),
                                      AttentionName                         = Record.Col.value('(BILLTOADDRESS/ContactPerson)[1]', 'TName'),
                                      TaxIdentificationNumber               = Record.Col.value('(BILLTOADDRESS/TaxId)[1]',         'TTaxId'),
                                      [Phone.Number]                        = Record.Col.value('(BILLTOADDRESS/PhoneNo)[1]',       'TPhoneNo'),
                                      FaxNumber                             = Record.Col.value('(BILLTOADDRESS/FaxNumber)[1]',     'TPhoneNo'),
                                      EmailAddress                          = Record.Col.value('(BILLTOADDRESS/Email)[1]',         'TEmailAddress'),
                                      [Address.AddressLine]                 = JSON_QUERY(CONCAT('["',
                                                                              Record.Col.value('(BILLTOADDRESS/AddressLine1)[1]',  'TAddressLine'), '","',
                                                                              Record.Col.value('(BILLTOADDRESS/AddressLine2)[1]',  'TAddressLine'), '","',
                                                                              Record.Col.value('(BILLTOADDRESS/AddressLine3)[1]',  'TAddressLine'), '"]')),
                                      [Address.City]                        = Record.Col.value('(BILLTOADDRESS/City)[1]',          'TCity'),
                                      [Address.StateProvinceCode]           = Record.Col.value('(BILLTOADDRESS/State)[1]',         'TState'),
                                      [Address.PostalCode]                  = Record.Col.value('(BILLTOADDRESS/Zip)[1]',           'TZip'),
                                      [Address.CountryCode]                 = Record.Col.value('(BILLTOADDRESS/Country)[1]',       'TCountry'),
                                      [Address.ResidentialAddressIndicator] = Record.Col.value('(BILLTOADDRESS/Residential)[1]',   'TFlag')
                               from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
                               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                               OPTION (OPTIMIZE FOR ( @InputXML = null ));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetBillToAddress */

Go
