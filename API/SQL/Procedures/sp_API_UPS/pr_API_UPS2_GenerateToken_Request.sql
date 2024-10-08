/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/09/12  RV      pr_API_UPS2_GenerateToken_Request, pr_API_UPS2_AcessToken_ValidateAndRefresh: Initial Version (MBW-465)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_GenerateToken_Request') is not null
  drop Procedure pr_API_UPS2_GenerateToken_Request;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_GenerateToken_Request:
    This procedure is one time purpose to generate the token. UPS allow only
    single time to generate the access token for the Authentication Code.

  Important Note: We can't run this procedure in a transaction. Because once the access token is generated, We can't
   generate access tokens multiple times with the same authentication code.  If we run API calls within a transaction we may
   generate the token and not update with the token.
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_GenerateToken_Request
  (@APIWorkFlow            TName = 'CLR',
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vOperation                   TOperation;

  declare @ttAccessTokensToRefresh   TEntityValuesTable;;
begin /* pr_API_UPS2_GenerateToken_Request */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vOperation    = 'GenerateToken';

  /* Create temp table if not exists */
  if (object_id('tempdb..#APITransactionsToProcess') is null) select * into #APITransactionsToProcess from @ttAccessTokensToRefresh;

  /* Fetch the shipping accounts to generate the access tokens
     Note: UPS is not allowing multiple times to generate with the same Authentication Code */
  insert into @ttAccessTokensToRefresh(RecordId, EntityId, EntityKey)
    select RecordId, RecordId, ShipperAccountNumber
    from ShippingAccounts
    where (Carrier   = 'UPS') and
          (TokenAuthenticationCode is not null) and
          (AccessToken is null) and
          (BusinessUnit = @BusinessUnit);

  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityId, EntityKey, TransactionStatus , ProcessStatus, APIWorkflow, BusinessUnit)
    output inserted.RecordId, inserted.APIWorkFlow, inserted.RecordId
    into #APITransactionsToProcess (EntityId, EntityType, RecordId)
    select 'CIMSUPSOAUTH2', 'GenerateToken', EntityId, EntityKey, 'Initial', 'Initial', @APIWorkFlow, @BusinessUnit
    from @ttAccessTokensToRefresh

  /* If work flow is CLR then process the records immediately */
  if (@APIWorkFlow = 'CLR')
    exec pr_API_OutboundCLRProcessor null /* APIRecordId */, @vOperation, @BusinessUnit, @UserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS2_GenerateToken_Request */

Go
