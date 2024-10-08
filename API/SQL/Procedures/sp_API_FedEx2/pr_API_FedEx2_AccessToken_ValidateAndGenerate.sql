/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/12  RV      Initial Version (CIMSV3-3395 & CIMSV3-3397)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_AccessToken_ValidateAndGenerate') is not null
  drop Procedure pr_API_FedEx2_AccessToken_ValidateAndGenerate;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_AccessToken_ValidateAndGenerate:
    Validate the shipping accounts access tokens and create if expires or lessthan the input threshold seconds.
    We can call this procedure in SQL job to validate and generate the tokens.
    FedEx token will expire for every 3599 seconds (60 mins)
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_AccessToken_ValidateAndGenerate
  (@BufferSecondsToRefresh int   = 1800,
   @APIWorkFlow            TName = 'CLR',
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TMessage,

          @vOperation                  TOperation;

  declare @ttAccessTokensToCreate   TEntityValuesTable;;
begin /* pr_API_FedEx2_AccessToken_ValidateAndGenerate */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vOperation    = 'GenerateToken';

  /* Create temp table if not exists */
  if (object_id('tempdb..#APITransactionsToProcess') is null) select * into #APITransactionsToProcess from @ttAccessTokensToCreate;

  /* Fetch the shipping accounts to create the tokens, which are crossed the given threshold seconds */
  insert into @ttAccessTokensToCreate(RecordId, EntityId, EntityKey)
    select RecordId, RecordId, ShipperAccountNumber
    from ShippingAccounts
    where (Carrier   = 'FEDEX') and
          (ClientId is not null) and
          (ClientSecret is not null) and
          ((datediff(second, current_timestamp, AccessTokenExpiresAt) < @BufferSecondsToRefresh) or AccessTokenExpiresAt is null) and
          (BusinessUnit = @BusinessUnit);

  /* If Tokens already exist and doesn't need refresh, do nothing */
  if (@@rowcount = 0) return;

  /* Initiate token generation for each Shipping Account */
  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityId, EntityKey, TransactionStatus , ProcessStatus, APIWorkflow, BusinessUnit)
    output inserted.RecordId, inserted.APIWorkFlow, inserted.RecordId
    into #APITransactionsToProcess (EntityId, EntityType, RecordId)
    select 'CIMSFEDEX2OAUTH', 'GenerateToken', EntityId, EntityKey, 'Initial', 'Initial', @APIWorkFlow, @BusinessUnit
    from @ttAccessTokensToCreate

  /* If work flow is CLR then process the records immediately */
  if (@APIWorkFlow = 'CLR')
    exec pr_API_OutboundCLRProcessor null /* APIRecordId */, @vOperation, @BusinessUnit, @UserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_AccessToken_ValidateAndGenerate */

Go
