/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/20  VS      pr_AMF_Logout: Made the changes to clear the login info (HA-95)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Logout') is not null
  drop Procedure pr_AMF_Logout;
Go
/*------------------------------------------------------------------------------
  Proc pr_AMF_Logout:

  InputXML Format

  <Root>
    <SessionInfo>
      <UserName></UserName>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
    </SessionInfo>
  </Root>

  OutputXML Format

  <Result>
    <Errors>
      <Messages>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        ...
        ...
      </Messages>
    </Errors>
    <Info>
      <Messages>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        ...
        ...
      </Messages>
    </Info>
  </Result>
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Logout
  (@InputXML     TXML,
   @OutputXML    TXML output)
as
  declare @vInputXML             xml,
          @vInfoXML              TXML,
          @vErrorXML             TXML,
          @vErrorMessage         TMessage,
          @vTransactionFailed    TBoolean,
          @vUserName             TUserName,
          @vPassword             TPassword,
          @vBusinessUnit         TBusinessUnit,
          @vMessagename          TMessageName,
          @vDeviceId             TDeviceId,
          @vWarehouse            TWarehouse;

begin /* pr_AMF_Logout */
begin try

  select @vInputXML = convert(xml, @InputXML);

  /* read session information */
  select  @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
          @vUserName     = Record.Col.value('UserName[1]',     'TUserName'),
          @vDeviceId     = Record.Col.value('DeviceId[1]',     'TDeviceId')
  from @vInputXML.nodes('/Root/SessionInfo') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* perform logout validation */
  exec pr_Users_RFLogout @vBusinessUnit, @vDeviceId, @vUserName, @vWarehouse, @vMessagename output;

  /* Show the Message on the screen */
  select @OutputXML = '<Result>' + dbo.fn_AMF_BuildSuccessXML(@vMessagename) + '</Result>';

end try
begin catch
  /* Capture Exception details and send in output Format */
  select @vErrorMessage = ERROR_MESSAGE();
  select @vErrorMessage =  replace(replace(replace(@vErrorMessage, '<', ''), '>', ''), '$', '');
  select @vErrorXML =  '<Errors><Messages>' +
                          dbo.fn_XMLNode('Message', dbo.fn_XMLNode('DisplayText', @vErrorMessage)) +
                       '</Messages></Errors>';

  select @OutputXML = '<Result>' + @vErrorXML + '</Result>';

end catch
end /* pr_AMF_Logout */

Go

