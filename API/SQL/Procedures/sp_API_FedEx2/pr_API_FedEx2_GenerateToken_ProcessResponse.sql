/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/28  RV      Bug fixed to generate the token when have multiple accounts with same account number (OBV3-2040)
  2024/02/17  RV      Initial version (CIMSV3-3396)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GenerateToken_ProcessResponse') is not null
  drop Procedure pr_API_FedEx2_GenerateToken_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GenerateToken_ProcessResponse: This proc processes the
   generated token by updating it in the respective shipper account
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GenerateToken_ProcessResponse
  (@TransactionRecordId           TRecordId)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TMessage,

          @vEntityId                   TRecordId,
          @vEntityKey                  TEntityKey,
          @vRawResponse                TVarchar,
          @vTokenType                  TTypeCode,
          @vAccessToken                TVarchar,
          @vAccessTokenExpiresIn       TName,
          @vBusinessUnit               TBusinessUnit;
begin /* pr_API_FedEx2_GenerateToken_ProcessResponse */

  /* Read the Raw Response from the Transaction */
  select @vEntityId     = EntityId,
         @vEntityKey    = EntityKey,
         @vRawResponse  = RawResponse,
         @vBusinessUnit = BusinessUnit
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  select @vTokenType            = json_value(@vRawResponse, '$.token_type'),
         @vAccessToken          = json_value(@vRawResponse, '$.access_token'),
         @vAccessTokenExpiresIn = json_value(@vRawResponse, '$.expires_in');

  /* Update the token info APIConfiguration.*/
  update ShippingAccounts
  set TokenType               = @vTokenType,
      AccessToken             = @vAccessToken,
      AccessTokenIssuedAt     = current_timestamp,
      AccessTokenExpiresAt    = dateadd(second, cast(@vAccessTokenExpiresIn as bigint), current_timestamp)
  where (RecordId = @vEntityId);

end /* pr_API_FedEx2_GenerateToken_ProcessResponse */

Go
