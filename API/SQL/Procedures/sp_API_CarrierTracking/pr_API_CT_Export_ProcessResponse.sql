/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_CT_Export_ProcessResponse') is not null
  drop Procedure pr_API_CT_Export_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_CT_Export_ProcessResponse:
    Process the response received from the client endpoint and update records
    which are exported based on the response received
------------------------------------------------------------------------------*/
Create Procedure pr_API_CT_Export_ProcessResponse
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage;
begin
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Mark all records as exported if the request has been processed successfully */
  update CT
  set CT.ExportStatus = case when API.TransactionStatus = 'Success' then 'Exported' else 'Failed' end
  from APIOutboundTransactions API
    join CarrierTrackingInfo CT on API.RecordId = CT.APIRecordId
  where (API.RecordId = @TransactionRecordId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_CT_Export_ProcessResponse */

Go
