/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/28  RV      Bug fixed to generate the token when have multiple accounts with same account number (OBV3-2040)
  2024/02/12  RV      Initial Version (CIMSV3-3397)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GenerateToken_GetMsgData') is not null
  drop Procedure pr_API_FedEx2_GenerateToken_GetMsgData;
Go
/*------------------------------------------------------------------------------
  proc pr_API_FedEx2_GenerateToken_GetMsgData: This procedure builds the message
    data to generate the token for the shipping account in APIOT.
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GenerateToken_GetMsgData
  (@TransactionRecordId  TRecordId,
   @MessageData          TVarchar   output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TMessage;
begin /* pr_API_FedEx2_GenerateToken_GetMsgData */

  /* Read the TokenAuthenticationCode and RedirectURI to be passed to API Call for Token generation */
  select @MessageData = (select grant_type    = 'client_credentials',
                                client_id     = SA.ClientId,
                                client_secret = SA.ClientSecret
                         from APIOutboundTransactions APIOT
                           join ShippingAccounts SA on (APIOT.EntityId = SA.RecordId) and (APIOT.BusinessUnit = SA.BusinessUnit)
                         where (APIOT.RecordId = @TransactionRecordId)
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

end /* pr_API_FedEx2_GenerateToken_GetMsgData */

Go
