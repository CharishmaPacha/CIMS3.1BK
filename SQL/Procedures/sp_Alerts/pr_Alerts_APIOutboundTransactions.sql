/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_APIOutboundTransactions') is not null
  drop Procedure pr_Alerts_APIOutboundTransactions;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_APIOutboundTransactions: The procedure to read all Failed / Fatal transactions and
  send email and update to the AlertStatus to Alerted.
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_APIOutboundTransactions
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @EntityId                    TRecordId = null,
   @EntityStatus                TStatus,
   @ReturnDataSet               TFlags    = 'N',
   @EmailIfNoAlert              TFlags    = 'N')
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vRecordId            TRecordId,
          @vAlertCategory       TCategory,
          @vPreviousDate        TDateTime;

begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0,
         @vPreviousDate  = convert(date, getdate() - 1);

  /* Get the failed status APIOutboundTransactions into hash tables to send alerts for more than one hour */
  select RecordId, IntegrationName, EntityType, EntityKey, TransactionStatus, ProcessStatus,  ResponseCode,
         MessageType, MessageData, RawResponse
  into #FailedAPIOutboundTransactions
  from APIOutboundTransactions
  where (TransactionStatus = @EntityStatus) and
        (AlertStatus = 'ToBeSent')
  union
  select RecordId, IntegrationName, EntityType, EntityKey, TransactionStatus, ProcessStatus,  ResponseCode,
         MessageType, MessageData, RawResponse
  from APIOutboundTransactions
  where (ProcessStatus in ('Fail', 'Canceled')) and
        (AlertStatus = 'ToBeSent');

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
    exec pr_Email_SendQueryResults @vAlertCategory, '#FailedAPIOutboundTransactions', null /* order by */, @BusinessUnit;

  /* Update APIOutboundTransaction AlertStatus to Alerted after sending Alerts */
  update AOT
  set AlertStatus = 'Alerted'
  from APIOutboundTransactions AOT
    join #FailedAPIOutboundTransactions AD on (AOT.RecordId = AD.RecordId);

end /* pr_Alerts_APIOutboundTransactions */

Go
