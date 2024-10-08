/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/13  SK      pr_Alerts_APICTOrphanRecords: Alert presence of API records for exporting CT with no link to CT (BK-1010)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_APICTOrphanRecords') is not null
  drop Procedure pr_Alerts_APICTOrphanRecords;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_APICTOrphanRecords: Alert presence of API records for exporting CT
  with no link to CT

  This will run just before API Tracking requests are sent at 9 PM server time.
  The assumption is that by this time, all CT records were exported and were marked as success.

  !!!Note!!!
  The frequency of this alert would change or this would job would become unnecessary once
  CarrierTracking info stabilizes
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_APICTOrphanRecords
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ReturnDataSet               TFlags    = 'N',
   @EmailIfNoAlert              TFlags    = 'N')
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vRecordId            TRecordId,
          @vAlertCategory       TCategory,
          @vCurrentDay          TDate;

begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0,
         @vCurrentDay    = getdate();

  /* Get API CT export records which are not processed yet but the link to CT records is gone */
  select API.RecordId, API.IntegrationName, API.EntityType, API.EntityKey,
         API.TransactionStatus, API.ProcessStatus, ProcessMessage, ResponseCode,
         API.MessageType, API.MessageData, API.RawResponse,
         API.CreatedDate RequestedDate, API.ModifiedDate ProcessedDate
  into #OrphanAPICTRecords
  from APIOutboundTransactions API with (nolock)
    left join CarrierTrackingInfo CT on API.RecordId = CT.APIRecordId
  where (API.Archived = 'N' /* No */) and
        (API.CreatedOn = @vCurrentDay) and
        (API.TransactionStatus not in ('Success', 'Fail', 'Canceled', 'Onhold')) and
        (API.Messagetype = 'PostCarrierTracking') and
        (CT.RecordId is null);

  /* If there is no data captured, then exit */
  if (@@rowcount = 0) return(0);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #OrphanAPICTRecords;
      return(0);
    end

  /* Email the results */
  if (@EmailIfNoAlert = 'Y') or (exists (select * from #OrphanAPICTRecords))
    exec pr_Email_SendQueryResults @vAlertCategory, '#OrphanAPICTRecords', null /* order by */, @BusinessUnit;

  /* Update APIOutboundTransaction AlertStatus to Alerted after sending Alerts */
  update AOT
  set AlertStatus = 'Alerted'
  from APIOutboundTransactions AOT
    join #OrphanAPICTRecords AD on (AOT.RecordId = AD.RecordId);

end /* pr_Alerts_APICTOrphanRecords */

Go
