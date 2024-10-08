/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_USPS_GetShipToAddress') is not null
  drop Procedure pr_API_USPS_GetShipToAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_USPS_GetShipToAddress: Returns the Ship To address json

------------------------------------------------------------------------------*/
Create Procedure pr_API_USPS_GetShipToAddress
  (@InputXML          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @ShipToAddress     TXML output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_USPS_GetShipToAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

    /* Build Ship To Address */
 select @ShipToAddress = (select    ToName                   = Record.Col.value('(SHIPTOADDRESS/Name)[1]',          'TName'),
                                    ToContactPerson          = Record.Col.value('(SHIPTOADDRESS/ContactPerson)[1]', 'TName'),
                                    ToPhoneNumber            = Record.Col.value('(SHIPTOADDRESS/PhoneNo)[1]',       'TPhoneNo'),
                                    ToEmailAddress           = Record.Col.value('(SHIPTOADDRESS/Email)[1]',         'TEmailAddress'),
                                    ToAddress1               = Record.Col.value('(SHIPTOADDRESS/AddressLine1)[1]',  'TAddressLine'),
                                    ToCity                   = Record.Col.value('(SHIPTOADDRESS/City)[1]',          'TCity'),
                                    ToState                  = Record.Col.value('(SHIPTOADDRESS/State)[1]',         'TState'),
                                    ToPostalCode             = Record.Col.value('(SHIPTOADDRESS/Zip)[1]',           'TZip'),
                                    ToCountryCode            = Record.Col.value('(SHIPTOADDRESS/Country)[1]',       'TCountry')
                               from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
                               for xml path)
                               OPTION (OPTIMIZE FOR ( @InputXML = null ));

select @ShipToAddress = dbo.fn_XMLGetValue(@ShipToAddress,'row')

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_USPS_GetShipToAddress */

Go
