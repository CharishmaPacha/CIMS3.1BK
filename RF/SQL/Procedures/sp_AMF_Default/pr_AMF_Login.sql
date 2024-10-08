/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/28  NB      pr_AMF_Login changes to return User Display Name(CIMSV3-1507)
  2020/09/27  RIA     pr_AMF_Login: Changes to fetch SKUImagePath to save in the seeion which is used to show images when necessary (CIMSV3-733)
  2020/04/07  NB      pr_AMF_Login: changes to save Warehouse into Session(HA-108)
  2019/04/18  NB      pr_AMF_Login: Changes to validate default Warehouse for user(AMF-41)
  2019/01/02  NB      Added pr_AMF_Login(CIMSV3-351)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Login') is not null
  drop Procedure pr_AMF_Login;
Go
/*------------------------------------------------------------------------------
  Proc pr_AMF_Login:
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Login
  (@InputXML     TXML,
   @OutputXML    TXML output)
as
  declare @vInputXML             xml,
          @vrfcProcInputxml      xml,
          @vrfcProcOutputxml     xml,
          @vTransactionFailed    TBoolean,
          @vxmlData              xml,
          @vDataXML              TXML,
          @vUIInfoXML            TXML,
          @vInfoXML              TXML,
          @vErrorXML             TXML,
          @vSKUImagePath         TXML,
          @vErrorMessage         TMessage,
          @vMessageName          TMessageName,
          @vUserName             TUserName,
          @vUserDisplayName      TDescription,
          @vPassword             TPassword,
          @vBusinessUnit         TBusinessUnit,
          @vDeviceId             TDeviceId,
          @vWarehouse            TWarehouse,
          @vCultureName          TName;
begin /* pr_AMF_Login */
begin try
  select @vInputXML = convert(xml, @InputXML);

  /* read session information */
  select @vUserName     = Record.Col.value('UserName[1]',    'TUserId'),
         @vPassword     = Record.Col.value('Password[1]',    'TPassword'),
         @vDeviceId     = Record.Col.value('DeviceId[1]',    'TDeviceId')
  from @vInputXML.nodes('/Root/SessionInfo') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* Assuming UserName is unique, fetch the BusinessUnit for the UserName record */
  select @vBusinessUnit = BusinessUnit
  from Users
  where (UserName = @vUserName);

  exec pr_Users_RFLogin @vUserName, @vPassword, @vBusinessUnit, @vDeviceId, @vWarehouse,  @vrfcProcOutputxml output;
  select @vTransactionFailed = case when (@vrfcProcOutputxml is null) then 0 else dbo.fn_AMF_TransactionFailed(@vrfcProcOutputxml) end;
  /* If the transaction was successful, transform V2 format response into AMF Format Data element */
  if (@vTransactionFailed <= 0)
    begin
      select @vCultureName = CultureName,
             @vWarehouse   = DefaultWarehouse
      from Users
      where (UserName = @vUserName) and (BusinessUnit = @vBusinessUnit);

      if (@vWarehouse is null)
        begin
          select @vMessageName = 'DefaultWHUndefined';
          goto ErrorHandler;
        end

      select @vUserDisplayName = Name
      from vwUsers
      where (UserName = @vUserName) and (BusinessUnit = @vBusinessUnit);

      /* Fetch the ImagePath from controls as we are saving them in controls which
         will be client specific and will be a one time change if needed */
      select @vSKUImagePath = dbo.fn_Controls_GetAsString('SKU', 'ImageURLPath', '' /* default */, @vBusinessUnit, @vUserName);

      /* We will be sending the required fields to save for the session using the
         SessionKey_ as prefix and it will be saved/handled by framework and we can access every where */
      select @vxmlData = (select @vUserName         as UserName,
                                 @vUserDisplayName  as SessionKey_UserDisplayName,
                                 @vDeviceId         as DeviceId,
                                 @vBusinessUnit     as BusinessUnit,
                                 @vWarehouse        as SessionKey_Warehouse,
                                 @vSKUImagePath     as SessionKey_SKUImagePath,
                                 @vCultureName      as CultureName
                              for xml raw('Data'), elements);

      select @vDataXML = convert(varchar(max), @vxmlData);
      select @vInfoXML = dbo.fn_AMF_BuildSuccessXML('Login Successful. Welcome');
    end
  else
  /* If the transaction has failed, and build the error XML for AMF from the V2 Format */
  if (@vTransactionFailed > 0)
    begin
      select @vErrorXML  = dbo.fn_AMF_BuildErrorXML(@vrfcProcOutputxml);
    end

  select @OutputXML = '<Result>' + coalesce(@vDataXML, '') + coalesce(@vInfoXML, '' ) + coalesce(@vErrorXML, '' ) + '</Result>';

ErrorHandler:
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
  /* Capture Exception details and send in AMF Format */
  select @vErrorMessage = ERROR_MESSAGE();
  select @vErrorMessage =  replace(replace(replace(@vErrorMessage, '<', ''), '>', ''), '$', '');
  select @vErrorXML =  '<Errors><Messages>' +
                          dbo.fn_XMLNode('Message', dbo.fn_XMLNode('DisplayText', @vErrorMessage)) +
                       '</Messages></Errors>';

   select @OutputXML = '<Result>' + @vErrorXML + '</Result>';
end catch
end /* pr_AMF_Login */

Go

