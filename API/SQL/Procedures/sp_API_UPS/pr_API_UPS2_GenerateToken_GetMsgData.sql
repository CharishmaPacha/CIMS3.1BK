/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/28  VS      pr_API_UPS2_GenerateToken_GetMsgData: Bug fixed to generate the token when have multiple accounts with same account number (OBV3-2041)
  2023/09/08  RV      pr_API_UPS2_GenerateToken_GetMsgData, pr_API_UPS2_GenerateToken_ProcessResponse,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_GenerateToken_GetMsgData') is not null
  drop Procedure pr_API_UPS2_GenerateToken_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_GenerateToken_GetMsgData: This procedure build the message data to generate the tokens
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_GenerateToken_GetMsgData
  (@TransactionRecordId           TRecordId,
   @MessageData                   TVarchar   output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage;
begin /* pr_API_UPS2_GenerateToken_GetMsgData */

  /* Read the TokenAuthenticationCode and RedirectURI to be passed to API Call for Token generation */
  select @MessageData = (select grant_type   = 'authorization_code',
                                code         = SA.TokenAuthenticationCode,
                                redirect_uri = SA.RedirectURI
                         from APIOutboundTransactions APIOT
                           join ShippingAccounts SA on (APIOT.EntityId = SA.RecordId)
                         where (APIOT.RecordId = @TransactionRecordId)
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

end /* pr_API_UPS2_GenerateToken_GetMsgData */

Go
