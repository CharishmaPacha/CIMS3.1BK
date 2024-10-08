/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetShipFromAddress') is not null
  drop Procedure pr_API_UPS_GetShipFromAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetShipFromAddress: Returns the ship from address json.
    Here the ship from address is the physical address that the shipment is
    shipped from and will be used for calculating the cost of shipping

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
Create Procedure pr_API_UPS_GetShipFromAddress
  (@InputXML            xml,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @ShipFromAddressJSON TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vWarehouse              TWarehouse,
          @vShipFrom               TShipFrom;
begin /* pr_API_UPS_GetShipFromAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  select @vWarehouse = Record.Col.value('(ORDERHEADER/Warehouse)[1]',     'TWarehouse'),
         @vShipFrom  = Record.Col.value('(ORDERHEADER/ShipFrom)[1]',      'TShipFrom')
  from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
  OPTION (OPTIMIZE FOR ( @InputXML = null ));

  /* If ship from and Warehouse address are same then the ship from address is the Warehouse address */
  if (@vWarehouse = @vShipFrom)
    /* Build Ship from json */
    select @ShipFromAddressJSON = (select Name                        = Record.Col.value('(SHIPFROM/Name)[1]',          'TName'),
                                          AttentionName               = Record.Col.value('(SHIPFROM/ContactPerson)[1]', 'TName'),
                                          TaxIdentificationNumber     = Record.Col.value('(SHIPFROM/TaxId)[1]',         'TTaxId'),
                                          [Phone.Number]              = Record.Col.value('(SHIPFROM/PhoneNo)[1]',       'TPhoneNo'),
                                          ShipperNumber               = Record.Col.value('(ACCOUNTDETAILS/ACCOUNTNUMBER)[1]',                                                                              'TAccount'),
                                          FaxNumber                   = Record.Col.value('(SHIPFROM/FaxNumber)[1]',     'TPhoneNo'),
                                          [Address.AddressLine]       = Record.Col.value('(SHIPFROM/AddressLine1)[1]',  'TAddressLine'),
                                          [Address.City]              = Record.Col.value('(SHIPFROM/City)[1]',          'TCity'),
                                          [Address.StateProvinceCode] = Record.Col.value('(SHIPFROM/State)[1]',         'TState'),
                                          [Address.PostalCode]        = Record.Col.value('(SHIPFROM/Zip)[1]',           'TZip'),
                                          [Address.CountryCode]       = Record.Col.value('(SHIPFROM/Country)[1]',       'TCountry')
                                   from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
                                   FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                   OPTION (OPTIMIZE FOR ( @InputXML = null ));
  else
    /* Get Warehouse address */
    exec pr_API_UPS_GetAddress null, 'F', @vWarehouse, @BusinessUnit, @UserId, @ShipFromAddressJSON out;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetShipFromAddress */

Go
