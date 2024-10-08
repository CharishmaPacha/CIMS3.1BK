/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetShipperAddress') is not null
  drop Procedure pr_API_UPS_GetShipperAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetShipperAddress: Returns the ship from address json

  Ship From: OH.WH Address
  Shipper:   OH.ShipFrom address

  Regular Scenario:

  OH.ShipFrom: (Warehouse Address Ex: OB Address, OH.WH = Denver SA.ShippingAccount = OB

  drop Ship:
  Scenario 1:
  OH.ShipFrom: Group On Name/Address, OH.WH = Denver, OH.FreightTerms: 3rd Party, OH.BillToAccount
  Scenario 2:
  OH.ShipFrom: Group On Name/Address, OH.WH = Denver, OH.FreightTerms: Sender, SA.ShippingAccount = GroupOn

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
Create Procedure pr_API_UPS_GetShipperAddress
  (@InputXML           xml,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ShipperAddressJSON TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vFreightTerms           TDescription;
begin /* pr_API_UPS_GetShipperAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* Here Shipper address is printing on label, If we are not sending Ship from then consider the shipper is
     the Ship from address */
  select @ShipperAddressJSON = (select Name                        = Record.Col.value('(SHIPFROM/Name)[1]',                'TName'),
                                       AttentionName               = Record.Col.value('(SHIPFROM/ContactPerson)[1]',       'TName'),
                                       TaxIdentificationNumber     = Record.Col.value('(SHIPFROM/TaxId)[1]',               'TTaxId'),
                                       [Phone.Number]              = Record.Col.value('(SHIPFROM/PhoneNo)[1]',             'TPhoneNo'),
                                       ShipperNumber               = Record.Col.value('(ACCOUNTDETAILS/ACCOUNTNUMBER)[1]', 'TAccount'),
                                       FaxNumber                   = Record.Col.value('(SHIPFROM/FaxNumber)[1]',           'TPhoneNo'),
                                       [Address.AddressLine]       = Record.Col.value('(SHIPFROM/AddressLine1)[1]',        'TAddressLine'),
                                       [Address.City]              = Record.Col.value('(SHIPFROM/City)[1]',                'TCity'),
                                       [Address.StateProvinceCode] = Record.Col.value('(SHIPFROM/State)[1]',               'TState'),
                                       [Address.PostalCode]        = Record.Col.value('(SHIPFROM/Zip)[1]',                 'TZip'),
                                       [Address.CountryCode]       = Record.Col.value('(SHIPFROM/Country)[1]',             'TCountry')
                                from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
                                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                OPTION (OPTIMIZE FOR ( @InputXML = null ));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetShipperAddress */

Go
