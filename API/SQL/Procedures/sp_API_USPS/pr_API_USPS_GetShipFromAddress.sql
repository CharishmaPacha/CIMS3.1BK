/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_USPS_GetShipFromAddress') is not null
  drop Procedure pr_API_USPS_GetShipFromAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_USPS_GetShipFromAddress: Returns the ship from address json.
    Here the ship from address is the physical address that the shipment is
    shipped from and will be used for calculating the cost of shipping

  Sample output:

------------------------------------------------------------------------------*/
Create Procedure pr_API_USPS_GetShipFromAddress
  (@InputXML            xml,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @ShipFromAddress     TXML output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vWarehouse              TWarehouse,
          @vShipFrom               TShipFrom;
begin /* pr_API_USPS_GetShipFromAddress */
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
    select @ShipFromAddress     = (select FromName                    = Record.Col.value('(SHIPFROM/Name)[1]',          'TName'),
                                          FromPhone                   = Record.Col.value('(SHIPFROM/PhoneNo)[1]',       'TPhoneNo'),
                                          FromAddress                 = Record.Col.value('(SHIPFROM/AddressLine1)[1]',  'TAddressLine'),
                                          FromCity                    = Record.Col.value('(SHIPFROM/City)[1]',          'TCity'),
                                          FromState                   = Record.Col.value('(SHIPFROM/State)[1]',         'TState'),
                                          FromPostalCode              = Record.Col.value('(SHIPFROM/Zip)[1]',           'TZip'),
                                          FromCountryCode             = Record.Col.value('(SHIPFROM/Country)[1]',       'TCountry')
                                   from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
                                   for xml path)
                                   OPTION (OPTIMIZE FOR ( @InputXML = null ));
  else
    /* Get Warehouse address */
    exec pr_API_USPS_GetAddress null, 'F', @vWarehouse, @BusinessUnit, @UserId, @ShipFromAddress out;

select @ShipFromAddress = dbo.fn_XMLGetValue(@ShipFromAddress,'row')

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_USPS_GetShipFromAddress */

Go
