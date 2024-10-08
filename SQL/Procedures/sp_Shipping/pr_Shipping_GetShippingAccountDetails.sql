/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/02/26  AY      pr_Shipping_GetShippingAccountDetails: Added (LL-276)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetShippingAccountDetails') is not null
  drop Procedure pr_Shipping_GetShippingAccountDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetShippingAccountDetails:
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetShippingAccountDetails
  (@xmlRulesData     TXML,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @xmlResult        TXML output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vRecordId           TRecordId,

          /* Shipping account Info */
          @vCarrier            TCarrier,
          @vShippingAccName    TAccountName,
          @vAccUserId          TUserId,
          @vAccPassword        TPassword,
          @vMasterAccount      TAccount,
          @vShipperAccountNum  TAccount,
          @vShipperMeterNumber TMeterNumber,
          @vShipperAccessKey   TAccessKey,
          @vOtherShipperDtls   TXML,
          @xmlData             xml;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the name of account to use */
  exec pr_RuleSets_Evaluate 'ShippingAccounts', @xmlRulesData, @vShippingAccName output;

  if (@vShippingAccName is null) goto ExitHandler;

  select @xmlData = convert(xml, @xmlRulesData)

  select @vCarrier = Record.Col.value('Carrier[1]', 'TCarrier')
  from @xmlData.nodes('/RootNode') as Record(Col);

  /* Get the details for the Shipping Accounts */
  select @vAccUserId          = nullif(UserId, ''),
         @vAccPassword        = nullif(Password, ''),
         @vMasterAccount      = MasterAccount,
         @vShipperAccountNum  = ShipperAccountNumber,
         @vShipperMeterNumber = ShipperMeterNumber,
         @vShipperAccessKey   = ShipperAccessKey,
         @vOtherShipperDtls   = AccountDetails
  from ShippingAccounts
  where (Carrier = @vCarrier) and
        (ShippingAcctName = @vShippingAccName) and
        (Status = 'A' /* Active */);

  /* if UserId/Password is null the get it from Master Account */
  if ((@vAccUserId is null) or (@vAccPassword is null)) and
     (@vMasterAccount is not null)
    select @vAccUserId   = UserId,
           @vAccPassword = Password
    from ShippingAccounts
    where (MasterAccount = @vMasterAccount) and
          (Carrier = @vCarrier) and
          (UserId is not null) and (Password is not null) and
          (Status = 'A' /* Active */);;

  /* Build shipping account XML */
  set @xmlResult = dbo.fn_XMLNode('ACCOUNTDETAILS',
                                          dbo.fn_XMLNode('USERID'        , @vAccUserId) +
                                          dbo.fn_XMLNode('PASSWORD'      , @vAccPassword)+
                                          dbo.fn_XMLNode('ACCOUNTNUMBER' , @vShipperAccountNum) +
                                          dbo.fn_XMLNode('METERNUMBER'   , @vShipperMeterNumber) +
                                          dbo.fn_XMLNode('ACCESSKEY'     , @vShipperAccessKey) +
                                          dbo.fn_XMLNode('ACCOUNTNAME'   , @vShippingAccName) +
                                          coalesce(@vOtherShipperDtls, ''));

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_GetShippingAccountDetails */

Go
