/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/23  SK      pr_API_CT_Export_BatchRecords: Changes to batch and insert API records based on sourcesystem as well (BK-1025)
  if object_id('dbo.pr_API_CT_Export_BatchRecords') is null
  exec('Create Procedure pr_API_CT_Export_BatchRecords as begin return; end')
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_CT_Export_BatchRecords') is not null
  drop Procedure pr_API_CT_Export_BatchRecords;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_CT_Export_BatchRecords: This procedure is run from a SQL job
    every 5 mins to batch the CT records that are to be exported. Each batch would be
    for one specific carrier only. There will be different steps to run for different
    carriers.

    1. Pick up records from based on priority and other factors from CarrierTracking table
    2. update a batch number
    3. Insert a record into APIOutboundTransactions without the message data.
    4. Link the CT records with API Transaction.
------------------------------------------------------------------------------*/
Create Procedure pr_API_CT_Export_BatchRecords
  (@Carrier            TCarrier,
   @IntegrationName    TName,
   @SourceSystem       TName = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vCarrier                     TCarrier,
          @vSourceSystem                TName,
          @vMessageType                 TName,
          @vTransactionStatus           TStatus,
          @vAPIWorkflow                 TName,
          @vAPIBatch                    TBatch,
          @vNoOfRecords                 TCount,
          @vAPIRecordId                 TRecordId;
begin
  /* Initialize */
  select @vReturnCode         = 0,
         @vMessageName        = null,
         @vMessageType        = 'PostCarrierTracking',
         @vTransactionStatus  = 'Initial',
         @vAPIWorkflow        = 'APIJob',
         @vAPIBatch           = 0,
         @vCarrier            = @Carrier,
         @vSourceSystem       = @SourceSystem;

  /* Number of records to process */
  select @vNoOfRecords = coalesce(RecordsPerBatch, 400 /* default */)
  from APIConfiguration
  where (MessageType     = @vMessageType) and
        (IntegrationName = @IntegrationName) and
        (BusinessUnit    = @BusinessUnit);

  /* Get the records list which would be batched
     Fetch the records based on priority assigned to the records when they got inserted into
     CarrietTrackingInfo table */
  select top (@vNoOfRecords) CTI.RecordId
  into #CTI_Subset
  from CarrierTrackingInfo CTI
  where (CTI.Archived     = 'N' /* No */) and
        (CTI.ExportStatus = 'ToBeExported') and
        (CTI.Carrier      = coalesce(@vCarrier, CTI.Carrier)) and
        (CTI.SourceSystem = coalesce(@vSourceSystem, CTI.SourceSystem)) and
        (CTI.BusinessUnit = @BusinessUnit) and
        (CTI.ActivityInfo is not null)
  order by ExportPriority asc;

  /* Exit if no records are fetched */
  if (not exists(select * from #CTI_Subset)) goto ExitHandler;

  /* Get next batch number for the the outbound transactions batch */
  exec pr_Sequence_GetNext 'Seq_APIOutboundBatch', 1, null /* Userid */, @BusinessUnit, @vAPIBatch output;

  /* insert records into APIOutboundTransactions */
  insert into APIOutboundTransactions (IntegrationName, TransactionStatus, MessageType,
                                       APIWorkflow, APIBatch, BusinessUnit, CreatedBy)
    select @IntegrationName, @vTransactionStatus, @vMessageType,
           @vAPIWorkflow, @vAPIBatch, @BusinessUnit, @UserId;

  /* Update the CT Records with the API recordid value */
  select @vAPIRecordId = Scope_Identity();

  update CT
  set CT.APIRecordId  = @vAPIRecordId,
      CT.ExportStatus = 'Inprocess'
  from #CTI_Subset TT
    join CarrierTrackingInfo CT on TT.RecordId = CT.RecordId

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_CT_Export_BatchRecords */

Go
