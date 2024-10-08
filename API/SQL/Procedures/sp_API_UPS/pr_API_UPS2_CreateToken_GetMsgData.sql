/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/28  VS      pr_API_UPS2_CreateToken_GetMsgData: Bug fixed to generate the token when have multiple accounts with same account number (OBV3-2041)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_CreateToken_GetMsgData') is not null
  drop Procedure pr_API_UPS2_CreateToken_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_CreateToken_GetMsgData: This procedure build the message data to generate the tokens
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_CreateToken_GetMsgData
  (@TransactionRecordId           TRecordId,
   @MessageData                   TVarchar   output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vClientId                    TVarchar,
          @vClientSecret                TVarchar;
begin /* pr_API_UPS2_CreateToken_GetMsgData */

  select @vClientId     = SA.ClientId,
         @vClientSecret = SA.ClientSecret
  from APIOutboundTransactions APIOT
    join ShippingAccounts SA on (APIOT.EntityId = SA.RecordId)
  where (APIOT.RecordId = @TransactionRecordId);

  update APIOT
  set APIOT.AuthenticationInfo = concat(@vClientId, ':', @vClientSecret),
      APIOT.HeaderInfo         = dbo.fn_XMLNode('Root',
                                   dbo.fn_XMLNode('x-merchant-id', @vClientId))
  from APIOutboundTransactions APIOT
  where (APIOT.RecordId = @TransactionRecordId)

  /* Read the TokenAuthenticationCode and RedirectURI to be passed to API Call for Token generation */
  select @MessageData = (select grant_type = 'client_credentials'
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

end /* pr_API_UPS2_CreateToken_GetMsgData */

Go
