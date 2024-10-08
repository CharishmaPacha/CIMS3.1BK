/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_GetAccountInfo') is not null
  drop Procedure pr_API_FedEx_GetAccountInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_GetAccountInfo: Returns the request address in jsonn as expected by UPS.

------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_GetAccountInfo
  (@ShipmentInfoXML  XML,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @AccountInfo      TVarchar output)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vAccountNumber            TAccount,
          @vMeterNumber              TMeterNumber,
          @vShippingAccountPassword  TPassword,
          @vShippingAccountAccessKey TAccessKey,
          @vAccountDetails           TVarchar,
          @vUserCredential           TVarchar;


begin /* pr_API_FedEx_GetAccountInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* Extract the Account details */
  select @vShippingAccountPassword  = Record.Col.value('(ACCOUNTDETAILS/PASSWORD)[1]',      'TPassword'),
         @vShippingAccountAccessKey = Record.Col.value('(ACCOUNTDETAILS/ACCESSKEY)[1]',     'TAccessKey'),
         @vAccountNumber            = Record.Col.value('(ACCOUNTDETAILS/ACCOUNTNUMBER)[1]', 'TAccount'),
         @vMeterNumber              = Record.Col.value('(ACCOUNTDETAILS/MeterNumber)[1]',   'TMeterNumber')
  from @ShipmentInfoXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col);

  /* Get the UserCredential */
  select  @vUserCredential =  dbo.fn_XMLNode('UserCredential',
                                            dbo.fn_XMLNode('Key',      @vShippingAccountAccessKey) +
                                            dbo.fn_XMLNode('Password', @vShippingAccountPassword));

  select @vUserCredential = '<WebAuthenticationDetail>' + @vUserCredential + '</WebAuthenticationDetail>';

  /* Get the AccountDetails */
  select @vAccountDetails = dbo.fn_XMLNode('ClientDetail',
                                            dbo.fn_XMLNode('AccountNumber', @vAccountNumber) +
                                            dbo.fn_XMLNode('MeterNumber',   @vMeterNumber));

  /* Bulid the XML for AccountDetails */
  select @AccountInfo = @vUserCredential + @vAccountDetails;


ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx_GetAccountInfo */

Go
