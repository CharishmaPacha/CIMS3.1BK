/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_AccessToken_ValidateAndCreate') is not null
  drop Procedure pr_API_UPS2_AccessToken_ValidateAndCreate;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_AccessToken_ValidateAndCreate:
    Validate the shipping accounts access tokens and create if expires or lessthan the input threshold seconds.
    We can call this procedure in SQL job to validate and create the tokens
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_AccessToken_ValidateAndCreate
  (@BufferSecondsToRefresh int   = 1800,
   @APIWorkFlow            TName = 'CLR',
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vOperation                   TOperation;

  declare @ttAccessTokensToCreate   TEntityValuesTable;;
begin /* pr_API_UPS2_AccessToken_ValidateAndCreate */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vOperation    = 'CreateToken';

  /* Create temp table if not exists */
  if (object_id('tempdb..#APITransactionsToProcess') is null) select * into #APITransactionsToProcess from @ttAccessTokensToCreate;

  /* Fetch the shipping accounts to create the tokens, which are crossed the given threshold seconds
     Note: We are getting the UTC date time stamp from UPS, so compare with the current UTC time stamp */
  insert into @ttAccessTokensToCreate(RecordId, EntityId, EntityKey)
    select RecordId, RecordId, ShipperAccountNumber
    from ShippingAccounts
    where (Carrier   = 'UPS') and
          (ClientId is not null) and
          (ClientSecret is not null) and
          ((datediff(second, GETUTCDATE(), AccessTokenExpiresAt) < @BufferSecondsToRefresh) or AccessTokenExpiresAt is null) and
          (BusinessUnit = @BusinessUnit);

  /* If Token already exists and doesn't need refresh, do nothing */
  if (@@rowcount = 0) return;

  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityId, EntityKey, TransactionStatus , ProcessStatus, APIWorkflow, BusinessUnit)
    output inserted.RecordId, inserted.APIWorkFlow, inserted.RecordId
    into #APITransactionsToProcess (EntityId, EntityType, RecordId)
    select 'CIMSUPSOAUTH2', 'CreateToken', EntityId, EntityKey, 'Initial', 'Initial', @APIWorkFlow, @BusinessUnit
    from @ttAccessTokensToCreate

  /* If work flow is CLR then process the records immediately */
  if (@APIWorkFlow = 'CLR')
    exec pr_API_OutboundCLRProcessor null /* APIRecordId */, @vOperation, @BusinessUnit, @UserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS2_AccessToken_ValidateAndCreate */

Go
