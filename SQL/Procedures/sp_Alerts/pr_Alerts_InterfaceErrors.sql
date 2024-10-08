/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/29  PK/YJ   pr_Alerts_InterfaceErrors: ported changes from prod onsite (HA-2729)
  2021/03/20  SK      pr_Alerts_InterfaceErrors: Migrations (HA-148)
  2020/09/24  SAK     pr_Alerts_InterfaceErrors: made changes as V3 standards (HA-1075)
  2020/08/12  MS      pr_Alerts_InterfaceErrors: Corrected Status name (HA-283)
  2020/05/11  VS      pr_Alerts_InterfaceErrors: Made changes to improve the performance of interface alerts (FB-1989)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_InterfaceErrors') is not null
  drop Procedure pr_Alerts_InterfaceErrors;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_InterfaceErrors: Alert to send email when entities which are
  modified in 30 days.

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last 30 minutes
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
Create Procedure pr_Alerts_InterfaceErrors
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

  declare @vHTML              TVarchar,
          @vSubject           TDescription,
          @vBody              TVarchar,
          @vEmailId           TControlValue,
          @vProfileName       TName,
          @vRecordType        TRecordType,
          @ttRecordTypes      TEntityKeysTable,
          @vFieldList         TVarchar,
          @vFieldCaptions     TVarchar,
          @vTable             TVarchar;

  declare @ttInterfaceLogs table
           (ILRecordId         TRecordId,
            SourceReference    TName,
            RecordType         TRecordTypes,
            Status             TDescription,
            RecordsProcessed   TCount,
            RecordsFailed      TCount,
            KeyData            TReference,
            ResultText         As ltrim(replace(replace(replace(replace(replace(ResultXML, '<Errors><Error>',   ''),
                                                                                           '</Error></Errors>', ''),
                                                                                           '</Error><Error>',   ', '),
                                                                                           '<Error>',           ''),
                                                                                           '</Error>',          '')),
            ResultXML          TXML,
            RecordId           TRecordId Identity(1,1),
            Primary Key        (RecordId));
begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId) -- pr_ will be trimmed by pr_Email_SendDBAlert

  /* get control value and Messages here */
  select @vSubject     = null,
         @vRecordId    = 0,
         @vBody        = '';

  /* Define temporary tables */
  select * into #InterfaceErrors from @ttInterfaceLogs

  /* update InterfaceLog.AlertSent as Not required if the Status is success */
  update IL
  set IL.AlertSent = 'I' /* Ignore, Not Required */
  from InterfaceLog IL
  where (IL.Status = 'S' /* Success */) and (IL.AlertSent = 'T' /* To be sent */);

  /* Update InterfaceLog.AlertSent to T if AlertSent is null */
  update IL
  set IL.AlertSent = 'T' /* To be sent */
  from InterfaceLog IL
  where (IL.AlertSent is null) and (IL.Status <> 'S' /* Success */);

  /* insert the failed records into temp table */
  insert into @ttInterfaceLogs (ILRecordId, SourceReference, RecordType, Status,
                                RecordsProcessed, RecordsFailed, KeyData, ResultXML)
    select distinct IL.RecordId, IL.SourceReference, coalesce(IL.RecordTypes, ''), IL.InterfaceLogStatusDesc,
                    IL.RecordsProcessed, IL.RecordsFailed, ILD.KeyData, ILD.ResultXML
    from vwInterfaceLog IL         with (nolock)
      join InterfaceLogDetails ILD with (nolock) on (IL.RecordId = ILD.ParentLogId) and (ILD.Status = 'E' /* Error */)
    where (IL.AlertSent = 'T' /* To be sent */) and (ILD.Status = 'E' /* Error */)
    order by coalesce(IL.RecordTypes, ''), IL.RecordId;

  /* If there are no records to alert, return */
  if (@@rowcount = 0) return;

  /* get the inserted records count */
  insert into @ttRecordTypes (EntityKey)
    select distinct(RecordType) from @ttInterfaceLogs;

  /* Loop through each recordType and email to the group */
  while (exists(select * from @ttRecordTypes where RecordId > @vRecordId))
    begin
      /* select the top 1 RecordType */
      select top 1 @vRecordId   = RecordId,
                   @vRecordType = EntityKey,
                   @vSubject    = @vSubject + ' ' + @vRecordType
      from @ttRecordTypes
      where (RecordId > @vRecordId)
      order by RecordId;

      /* delete records from temp table */
      delete from #InterfaceErrors

      if (@vRecordType = 'FILE')
        begin
          /* insert the records into temp table */
          insert into #InterfaceErrors (SourceReference, ResultText)
            select SourceReference, ResultText
            from @ttInterfaceLogs
            where (Status in ('P', 'F' /* Processing, Failed */)) and
                  (RecordType = @vRecordType)
            order by ILRecordId
        end
      else
        begin
          /* insert the records into temp table */
          insert into #InterfaceErrors (ILRecordId, SourceReference, RecordType, Status, RecordsProcessed, RecordsFailed, KeyData, ResultText)
            select ILRecordId, SourceReference, RecordType, Status, RecordsProcessed, RecordsFailed, coalesce(KeyData, '') as KeyData, ResultText
            from @ttInterfaceLogs
            where (Status in ('P', 'F' /* Processing, Failed */)) and
                  (RecordType = @vRecordType)
            order by ILRecordId
        end

      /* build the html Email body using the #table */
      exec pr_HashTableToHTML '#InterfaceErrors', null, @vHTML output;

      /* Build the Email Header based up on record types and add to Email body */
      select @vBody = @vBody + '<br>' + dbo.fn_HTML_PrepareBody('Failed ' + @vRecordType + ' records', @vHTML, default);

      /* Mark the log as alert sent */
      update IL
      set IL.AlertSent = 'Y' /* Yes */
      from InterfaceLog IL
        join @ttInterfaceLogs TIL on (IL.RecordId = TIL.ILRecordId)
      where (IL.RecordTypes = @vRecordType);
    end

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #InterfaceErrors;
      return(0);
    end

  /* Send email if there is data to report */
  if (@EmailIfNoAlert = 'Y') or (exists(select * from #InterfaceErrors))
    exec pr_Email_SendQueryResults @AlertCategory = @vAlertCategory,
                                   @TableName     = null,
                                   @BusinessUnit  = @BusinessUnit,
                                   @UserId        = @UserId,
                                   @EmailSubject  = @vSubject,
                                   @EmailBody     = @vBody;

end /* pr_Alerts_InterfaceErrors */

Go
