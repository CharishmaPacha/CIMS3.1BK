/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_CIMS_UpdateEventRun') is not null
  drop Procedure dbo.pr_API_CIMS_UpdateEventRun;
Go
/*------------------------------------------------------------------------------
  pr_API_CIMS_UpdateEventRun
  
  procedure processes the request for updating the event monitor with the given event details
  
  procedure reads the RequestInput(this is an XML, in this case) from the APIInboundTransactions table for the input TransactionRecordId
  the procedure pr_EventMonitor_UpdateLastRun is invoked to process the input, and record the lastrun date time
  The XML in RequestInput consists of the EventName for which the lastrun should be updated
  
  This procedure is executed when CIMS API is called with the update-event-run message  
------------------------------------------------------------------------------*/
Create Procedure pr_API_CIMS_UpdateEventRun
  (@TransactionRecordId   TRecordId)
as
  declare @vIntegrationName TName,
          @vMessageType     TName,
          @vRequestInput    TVarchar,
          @vBusinessUnit    TBusinessUnit,
          @vLookupCategory  TCategory,
          @vResponse        TVarchar,
          @vMessage         TMessage;
begin /* pr_API_CIMS_UpdateEventRun */
begin try
  select @vIntegrationName = IntegrationName,
         @vMessageType     = MessageType,
         @vRequestInput    = RawInput,
         @vBusinessUnit    = BusinessUnit
  from APIInboundTransactions
  where (RecordId = @TransactionRecordId);
  
  exec pr_EventMonitor_UpdateLastRun @vRequestInput;
                    
  update APIInboundTransactions
  set ResponseCode      = '200', /* Processed Ok */
      Response          = 'Update Event Run Processed',
      TransactionStatus = 'Success'
  where (RecordId = @TransactionRecordId);
                    
end try
begin catch
  /* Current Implementation of Message handlers adds some special characters to the message. These will interfere with forming
     a proper xml string. Hence, remove any special characters from the message before building the result xml with the error message */
  select @vMessage = replace(replace(replace(ERROR_MESSAGE(), '$', ''), '<', ''), '>', '');

  update APIInboundTransactions
  set ResponseCode      = '505', /* Internal Server Error */
      Response          = @vMessage,
      TransactionStatus = 'Fail'
  where (RecordId = @TransactionRecordId);

end catch
  
end /* pr_API_CIMS_UpdateEventRun */

Go
