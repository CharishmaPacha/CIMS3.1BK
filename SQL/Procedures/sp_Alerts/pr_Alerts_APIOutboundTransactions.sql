/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/07/02  RV      pr_Alerts_APIOutboundTransactions: Made changes to accept transaction and process statuses as parameters (HA-4201)
  2022/11/30  RKC     pr_Alerts_APIOutboundTransactions: Added ProcessMessage, CreatedDate, ModifiedDate (OBV3-1531)
  2022/07/26  PHK     pr_Alerts_APIOutboundTransactions: Migrated from CID and Made neccessary correction to it (BK-862)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_APIOutboundTransactions') is not null
  drop Procedure pr_Alerts_APIOutboundTransactions;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_APIOutboundTransactions: The procedure to read APIOT records
  with respect to the parameters is to send an email and update the AlertStatus to Alerted.
  In some scenarios, we need to consider the CreatedDate, while in other scenarios
  we consider the ModifiedDate.

  For example, if the record's Transactions are stuck in Inprocess, we do not need
  to send an alert immediately, as it takes some time to process.

  Also some times need to send the alerts even the AlertStatus is in NotRequired
  Alert Status also may in NotRequired.

  In some scenarios, alerts need to be sent irrespective of whether the record is Archived.
  For example, if the record's TransactionStatus is Fatal, the record may be Archived immediately.
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_APIOutboundTransactions
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowCreatedInLastXMinutes   TInteger  = 15,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @EntityId                    TRecordId = null,
   @TransactionStatus           TStatus,
   @ProcessStatus               TStatus,
   @Archived                    TFlag     = 'N',
   @AlertStatus                 TStatus   = 'ToBeSent',
   @ReturnDataSet               TFlags    = 'N',
   @EmailIfNoAlert              TFlags    = 'N')
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,
          @vAlertCategory              TCategory,
          @vStartTimeThreshold         TDateTime,
          @vModifiedTimeThreshold      TDateTime;

begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0,
         @vStartTimeThreshold = dateadd(minute, coalesce(@ShowCreatedInLastXMinutes, 15), getdate()),
         @vModifiedTimeThreshold = dateadd(minute, coalesce(@ShowCreatedInLastXMinutes, 1440), getdate());

  /* Get the failed status APIOutboundTransactions into hash tables to send alerts for more than one hour */
  select RecordId, IntegrationName, EntityType, EntityKey, TransactionStatus, ProcessStatus, ProcessMessage, ResponseCode,
         MessageType, CreatedDate RequestedDate, ModifiedDate ProcessedDate
  into #FailedAPIOutboundTransactions
  from APIOutboundTransactions
  where (TransactionStatus = @TransactionStatus) and
        (AlertStatus       = @AlertStatus) and
        (Archived          = coalesce(@Archived, Archived)) and
        (StartTime         < @vStartTimeThreshold) and
        (ModifiedDate      < @vModifiedTimeThreshold)
  union
  select RecordId, IntegrationName, EntityType, EntityKey, TransactionStatus, ProcessStatus,  ProcessMessage, ResponseCode,
         MessageType, CreatedDate RequestedDate, ModifiedDate ProcessedDate
  from APIOutboundTransactions
  where (ProcessStatus = @ProcessStatus) and
        (AlertStatus   = @AlertStatus) and
        (Archived      = coalesce(@Archived, Archived)) and
        (StartTime     < @vStartTimeThreshold) and
        (ModifiedDate  < @vModifiedTimeThreshold);

  /* If there is no data captured, then exit */
  if (@@rowcount = 0) return(0);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #FailedAPIOutboundTransactions;
      return(0);
    end

  /* Email the results */
  if (@EmailIfNoAlert = 'Y') or (exists (select * from #FailedAPIOutboundTransactions))
    exec pr_Email_SendQueryResults @vAlertCategory, '#FailedAPIOutboundTransactions', null /* Order By */, @BusinessUnit;

  /* Update APIOutboundTransaction AlertStatus to Alerted after sending Alerts */
  update AOT
  set AlertStatus = 'Alerted'
  from APIOutboundTransactions AOT
    join #FailedAPIOutboundTransactions AD on (AOT.RecordId = AD.RecordId);

end /* pr_Alerts_APIOutboundTransactions */

Go
