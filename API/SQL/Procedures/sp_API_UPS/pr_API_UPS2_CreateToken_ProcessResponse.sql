/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/28  VS      pr_API_UPS2_CreateToken_ProcessResponse: Bug fixed to generate the token when have multiple accounts with same account number (OBV3-2041)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_CreateToken_ProcessResponse') is not null
  drop Procedure pr_API_UPS2_CreateToken_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_CreateToken_ProcessResponse: This proc process the create the token and
   and update against the respective shipper account when client provide clientid and secrete key
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_CreateToken_ProcessResponse
  (@TransactionRecordId           TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vEntityId                    TRecordId,
          @vEntityKey                   TEntityKey,
          @vRawResponse                 TVarchar,
          @vTokenType                   TTypeCode,
          @vTokenStatus                 TStatus,
          @vAccessToken                 TVarchar,
          @vAccessTokenIssuedAt         TName,
          @vAccessTokenIssuedDateTime   TDateTime,
          @vAccessTokenExpiresIn        TName,

          @vBusinessUnit                TBusinessUnit;
begin /* pr_API_UPS2_CreateToken_ProcessResponse */

  /* Read the Raw Response from the Transaction */
  select @vEntityId     = EntityId,
         @vEntityKey    = EntityKey,
         @vRawResponse  = RawResponse,
         @vBusinessUnit = BusinessUnit
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  select @vTokenType               = json_value(@vRawResponse, '$.token_type'),
         @vTokenStatus             = json_value(@vRawResponse, '$.status'),
         @vAccessToken             = json_value(@vRawResponse, '$.access_token'),
         @vAccessTokenIssuedAt     = json_value(@vRawResponse, '$.issued_at'),
         @vAccessTokenExpiresIn    = json_value(@vRawResponse, '$.expires_in')

  /* Convert the Unix code to date time format */
  select @vAccessTokenIssuedDateTime  = dbo.fn_UnixTimeStampToSQLDateTime(@vAccessTokenIssuedAt, 'MilliSeconds');

  /* Update the token info APIConfiguration.*/
  update ShippingAccounts
  set TokenType               = @vTokenType,
      TokenStatus             = @vTokenStatus,
      AccessToken             = @vAccessToken,
      AccessTokenIssuedAt     = @vAccessTokenIssuedDateTime,
      AccessTokenExpiresAt    = dateadd(second, cast(@vAccessTokenExpiresIn as bigint), @vAccessTokenIssuedDateTime)
  where (RecordId = @vEntityId);

end /* pr_API_UPS2_CreateToken_ProcessResponse */

Go
