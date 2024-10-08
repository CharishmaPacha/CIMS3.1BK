/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/28  VS      pr_API_UPS2_CreateToken_GetMsgData: Bug fixed to generate the token when have multiple accounts with same account number (OBV3-2041)
  2023/09/08  RV      pr_API_UPS2_GenerateToken_GetMsgData, pr_API_UPS2_GenerateToken_ProcessResponse,
                       pr_API_UPS2_RefreshToken_GetMsgData, pr_API_UPS2_RefreshToken_ProcessResponse: Initial Version
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_RefreshToken_GetMsgData') is not null
  drop Procedure pr_API_UPS2_RefreshToken_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_RefreshToken_GetMsgData: This procedure build the message data to refresh the tokens
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_RefreshToken_GetMsgData
  (@TransactionRecordId           TRecordId,
   @MessageData                   TVarchar   output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vRefreshToken                TVarchar;
begin /* pr_API_UPS2_RefreshToken_GetMsgData */

  /* Read the token and Signature to be passed to API Call for Request Session */
  select @MessageData = (select grant_type    = 'refresh_token',
                                refresh_token = SA.RefreshToken
                         from APIOutboundTransactions APIOT
                           join ShippingAccounts SA on (APIOT.EntityId = SA.RecordId)
                         where (APIOT.RecordId = @TransactionRecordId)
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

end /* pr_API_UPS2_RefreshToken_GetMsgData */

Go
