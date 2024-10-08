/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/09/11  RV      pr_API_UPS2_GenerateToken_ProcessResponse, pr_API_UPS2_RefreshToken_ProcessResponse: Bug fixed to update the
                       expiry dates properly (MBW-465)
  2023/09/08  RV      pr_API_UPS2_GenerateToken_GetMsgData, pr_API_UPS2_GenerateToken_ProcessResponse,
                       pr_API_UPS2_RefreshToken_GetMsgData, pr_API_UPS2_RefreshToken_ProcessResponse: Initial Version
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_RefreshToken_ProcessResponse') is not null
  drop Procedure pr_API_UPS2_RefreshToken_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_RefreshToken_ProcessResponse: This proc update token info against
   the respective shipper account
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_RefreshToken_ProcessResponse
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
          @vRefreshToken                TVarchar,
          @vRefreshTokenIssuedAt        TName,
          @vRefreshTokenIssuedDateTime  TDateTime,
          @vRefreshTokenExpiresIn       TName,

          @vBusinessUnit                TBusinessUnit;
begin /* pr_API_UPS2_RefreshToken_ProcessResponse */

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
         @vAccessTokenExpiresIn    = json_value(@vRawResponse, '$.expires_in'),
         @vRefreshToken            = json_value(@vRawResponse, '$.refresh_token'),
         @vRefreshTokenIssuedAt    = json_value(@vRawResponse, '$.refresh_token_issued_at'),
         @vRefreshTokenExpiresIn   = json_value(@vRawResponse, '$.refresh_token_expires_in');

  /* Convert the Unix code to date time format */
  select @vAccessTokenIssuedDateTime  = dbo.fn_UnixTimeStampToSQLDateTime(@vAccessTokenIssuedAt, 'MilliSeconds'),
         @vRefreshTokenIssuedDateTime = dbo.fn_UnixTimeStampToSQLDateTime(@vRefreshTokenIssuedAt, 'MilliSeconds');

  /* Update the session id to APIConfiguration.UDF2 for GetSessionId Message Type */
  update ShippingAccounts
  set TokenType               = @vTokenType,
      TokenStatus             = @vTokenStatus,
      AccessToken             = @vAccessToken,
      AccessTokenIssuedAt     = @vAccessTokenIssuedDateTime,
      AccessTokenExpiresAt    = dateadd(second, cast(@vAccessTokenExpiresIn as bigint), @vAccessTokenIssuedDateTime),
      RefreshToken            = @vRefreshToken,
      RefreshTokenIssuedAt    = @vRefreshTokenIssuedDateTime,
      RefreshTokenExpiresAt   = dateadd(second, cast(@vRefreshTokenExpiresIn as bigint), @vRefreshTokenIssuedDateTime)
  where (ShipperAccountNumber = @vEntityKey) and (BusinessUnit = @vBusinessUnit);

end /* pr_API_UPS2_RefreshToken_ProcessResponse */

Go
