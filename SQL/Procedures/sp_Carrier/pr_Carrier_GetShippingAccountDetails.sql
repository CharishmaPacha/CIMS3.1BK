/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/17  AY      pr_Carrier_GetShippingAccountDetails: Changed to get all details for Shipping Account (CIMSV3-3395)
  2022/11/15  RKC     pr_Carrier_GetShippingAccountDetails: Bug fix (OBV3-1443)
  2022/10/26  AY/VS   pr_Carrier_GetShippingAccountDetails: New version to load details into # table (OBV3-1301)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_GetShippingAccountDetails') is not null
  drop Procedure pr_Carrier_GetShippingAccountDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_GetShippingAccountDetails: Identifies the shipper account to
    use and loads the data into #ShipperAccountDetails. Rules can give all the
    criteria to select an account or we can also give the ShipVia, but one or
    other is required.

  #ShippingAccountDetails : TShipppingAccountDetails
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_GetShippingAccountDetails
  (@xmlRulesData     TXML     = null,
   @ShipVia          TShipVia = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
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
         @vRecordId    = 0,
         @xmlData      = cast(@xmlRulesData as XML);

  /* if Shipvia is givne, identify the carrier */
  if (@ShipVia is not null)
    select @vCarrier = Carrier
    from ShipVias
    where (ShipVia = @ShipVia) and (BusinessUnit = @BusinessUnit)
  else
    select @vCarrier = Record.Col.value('Carrier[1]', 'TCarrier')
    from @xmlData.nodes('/RootNode') as Record(Col);

  /* if RulesData is not given, then build it with atleast the ShipVia & Carrier */
  if (@xmlRulesData is null)
    select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                             dbo.fn_XMLNode('ShipVia', coalesce(@ShipVia, '')) +
                             dbo.fn_XMLNode('Carrier', @vCarrier));

  /* Get the name of account to use */
  exec pr_RuleSets_Evaluate 'ShippingAccounts', @xmlRulesData, @vShippingAccName output;

  if (@vCarrier is null)
    select @vMessageName = 'CarrierIsRequired';
  else
  if (@vShippingAccName is null)
    select @vMessageName = 'CannotIdentifyShippingAcct';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @xmlData = convert(xml, @xmlRulesData);

  /* Get the details for the specific Shipping Account to be used */
  insert into #ShippingAccountDetails
    select * from ShippingAccounts
    where (Carrier = @vCarrier) and
          (ShippingAcctName = @vShippingAccName) and
          (Status = 'A' /* Active */);

  /* if UserId/Password is null the get it from Master Account if there is one */
  update SAD
  set UserId   = MSA.UserId,
      Password = MSA.Password
  from #ShippingAccountDetails SAD
    join ShippingAccounts MSA on (MSA.Carrier       = SAD.Carrier) and
                                 (MSA.MasterAccount = SAD.MasterAccount) and
                                 (MSA.Status        = 'A' /* Active */) and
                                 (MSA.UserId is not null) and (MSA.Password is not null)
  where ((coalesce(SAD.UserId, '') = '') or (coalesce(SAD.Password, '') = '')) and
        (SAD.MasterAccount is not null);

  /* Don't know why it can't be null, but that is what we had before, so
     continuing to do the same */
  update #ShippingAccountDetails
  set AccountDetails = coalesce(@vOtherShipperDtls, '');

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Carrier_GetShippingAccountDetails */

Go
