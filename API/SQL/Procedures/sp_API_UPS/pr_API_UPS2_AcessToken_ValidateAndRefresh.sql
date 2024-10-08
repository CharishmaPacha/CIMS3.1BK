/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/09/12  RV      pr_API_UPS2_GenerateToken_Request, pr_API_UPS2_AcessToken_ValidateAndRefresh: Initial Version (MBW-465)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_AcessToken_ValidateAndRefresh') is not null
  drop Procedure pr_API_UPS2_AcessToken_ValidateAndRefresh;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_AcessToken_ValidateAndRefresh:
    Validate the shipping accounts access takens validity and generate if expires or lessthan the input threshold seconds.
    We can call this procedure in SQL job to validate and refresh the tokens

  Important Note: We can't run this procedure in a transaction. Why because once the access token is generated, we are saving
   the refresh token and using the latest refresh token to generate the access token. If we run API calls within a transaction we may
   generate the token and not update with the latest refresh token. We can't refresh the access token with old refresh tokens.
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_AcessToken_ValidateAndRefresh
  (@BufferSecondsToRefresh int   = 300,
   @APIWorkFlow            TName = 'CLR',
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vOperation                   TOperation;

  declare @ttAccessTokensToRefresh   TEntityValuesTable;;
begin /* pr_API_UPS2_AcessToken_ValidateAndRefresh */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vOperation    = 'RefreshAccessToken';

  /* Create temp table if not exists */
  if (object_id('tempdb..#APITransactionsToProcess') is null) select * into #APITransactionsToProcess from @ttAccessTokensToRefresh;

  /* Fetch the shipping accounts to refresh the tokens, which are crossed the given threshold seconds
     Note: We are getting the UTC date time stamp from UPS, so compare with the current UTC time stamp */
  insert into @ttAccessTokensToRefresh(RecordId, EntityId, EntityKey)
    select RecordId, RecordId, ShipperAccountNumber
    from ShippingAccounts
    where (Carrier   = 'UPS') and
          (TokenType = 'Bearer') and
          (@BufferSecondsToRefresh > datediff(second, GETUTCDATE(), AccessTokenExpiresAt)) and
          (BusinessUnit = @BusinessUnit);

  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityId, EntityKey, TransactionStatus , ProcessStatus, APIWorkflow, BusinessUnit)
    output inserted.RecordId, inserted.APIWorkFlow, inserted.RecordId
    into #APITransactionsToProcess (EntityId, EntityType, RecordId)
    select 'CIMSUPSOAUTH2', 'RefreshToken', EntityId, EntityKey, 'Initial', 'Initial', @APIWorkFlow, @BusinessUnit
    from @ttAccessTokensToRefresh

  /* If work flow is CLR then process the records immediately */
  if (@APIWorkFlow = 'CLR')
    exec pr_API_OutboundCLRProcessor null /* APIRecordId */, @vOperation, @BusinessUnit, @UserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS2_AcessToken_ValidateAndRefresh */

Go
