/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/09  VM      pr_Alerts_AlertName: Latest changes included (S2G-489)
  2018/03/18  VM      pr_Alerts_AlertName: Params to pass to pr_Email_SendDBAlert changed as per latest params order (S2G-391)
  2018/03/14  AY      pr_Alerts_AlertName: Added template for alerts
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_AlertName') is not null
  drop Procedure pr_Alerts_AlertName;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_AlertName: Alert to send email when ....
  Ensure we set up controls for the alert with Alert_AlertName as category

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last X minutes
  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only
  @EntityId
    - If passed, ignores all other entities by considering the passed in EntityId

  EmailIfNoAlert - N: Would not send any email if there is nothing to alert
                   Y: Would send an email even if there is nothing to alert.
                      A job could be setup to do this once a month so that we know
                      that the job is active and running
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_AlertName
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @EntityId                    TRecordId = null,
   @ReturnDataSet               TFlags    = 'N',
   @EmailIfNoAlert              TFlags    = 'N')
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vAlertCategory     TCategory;

begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0;

  /* Get the data to be alerted upon into # table */
  select EntityId, EntityKey
  into #AlertData
  from ---
  where ---  and
  (datediff(mi, ModifiedDate, getdate()) <= @ShowModifiedInLastXMinutes) and
  (<ReplacewithEntityIdField> = coalesce(@EntityId, <ReplacewithEntityIdField>))
  group by ---;

  /* If there is no data captured, then exit */
  if (@@rowcount = 0) return(0);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #ttAlertData;
      return(0);
    end

  /* Email the results */
  if (@EmailIfNoAlert = 'Y') or (exists (select * from #AlertData))
    exec pr_Email_SendQueryResults @vAlertCategory, '#AlertData', null /* order by */, @BusinessUnit;

end /* pr_Alerts_AlertName */

Go
