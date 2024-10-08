/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/12  RV      Initial Version (CIMSV3-3395)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_UpdateHeaderInfo') is not null
  drop Procedure pr_API_FedEx2_UpdateHeaderInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_UpdateHeaderInfo: Access token expires for every certain amount of time,
   so get the latest token from shipping accounts and update on respective APIOT reord
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_UpdateHeaderInfo
  (@TransactionRecordId TRecordId,
   @BusinessUnit        TBusinessUnit)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordid                   TRecordId,

          @vAccessToken                TVarchar,
          @vAPIHeaderInfo              TXML;
begin /* pr_API_FedEx2_UpdateHeaderInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordid     = 0;

  /* Get the AccessToken for the Shipping Account being used */
  select @vAccessToken = coalesce(RefreshToken, AccessToken)
  from #ShippingAccountDetails;

  /* Build the xml with required nodes */
  select @vAPIHeaderInfo = dbo.fn_XMLNode('Root',
                             dbo.fn_XMLNode('x-customer-transaction-id', @TransactionRecordId) +
                             dbo.fn_XMLNode('x-locale', 'en_US') +
                             dbo.fn_XMLNode('Authorization', 'Bearer ' + @vAccessToken));

  update APIOutBoundTransactions
  set HeaderInfo = @vAPIHeaderInfo
  where (RecordId = @TransactionRecordId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_UpdateHeaderInfo */

Go
