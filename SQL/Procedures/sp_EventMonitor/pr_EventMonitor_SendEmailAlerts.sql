/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/12/08  NY      pr_EventMonitor_SendEmailAlerts: Modified message name (HPI-GoLive)
  pr_EventMonitor_SendEmailAlerts: Enhanced to build event alert message
  2015/03/26  NB      Added pr_EventMonitor_Validate and pr_EventMonitor_SendEmailAlerts
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_EventMonitor_SendEmailAlerts') is not null
  drop Procedure pr_EventMonitor_SendEmailAlerts;
Go
/*------------------------------------------------------------------------------
  Proc pr_EventMonitor_SendEmailAlerts:
------------------------------------------------------------------------------*/
Create Procedure pr_EventMonitor_SendEmailAlerts
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ReturnCode         TInteger,
          @vEventRecordId     TRecordId,
          @vEventType         TEntity,
          @vEventName         TName,
          @vLastRunAt         TDateTime,
          @vAlertInterval     TInteger,
          @vAlertMessage      TVarChar,
          @vAlertSubject      TVarChar,
          @vSupportEmail      TVarChar,
          @vClientEmail       TVarChar,
          @vEventDetails      TVarchar,
          @vTrackEvent        TFlags,
          @vProfileName       TName,
          @vSubject           TDescription,
          @vBody              TVarchar,
          @vEmailId           TVarchar,
          @vRecordId          TRecordId,
          @ttEventsFailed     TEntityKeysTable;
begin
  select @vEventRecordId = null,
         @ReturnCode     = 0,
         @vProfileName = dbo.fn_Controls_GetAsString('DBMail', 'ProfileName', @BusinessUnit + '_DBMail', @BusinessUnit, @UserId);

  /* Call Validate procedure to validate if there are event monitor records for
     which alerts need to be sent */
  exec pr_EventMonitor_Validate;

  /* Find all the event monitor records to process  */
  insert into @ttEventsFailed (EntityId, EntityKey)
  select RecordId, EventName
  from EventMonitor
  where (TrackEvent  <> 'N' /* No */   ) and -- consider all event monitor entries which are setup to be tracked
        (AlertType    = 'E' /* Email */) and
        (AlertSent    = 'T' /* Alert to be sent */) and
        (BusinessUnit = @BusinessUnit)
  order by RecordId;

  /* Iterate through each record and process */
  select @vRecordId = 0;
  while (exists (select * from @ttEventsFailed where RecordId > @vRecordId))
    begin
      /* Get next record to processs */
      select top 1 @vRecordId      = RecordId,
                   @vEventRecordId = EntityId
      from @ttEventsFailed
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Fetch event details */
      select @vEventType     = EventType,
             @vEventName     = EventName,
             @vLastRunAt     = LastRunAt,
             @vAlertInterval = AlertInterval,
             @vSupportEmail  = SupportEmail,
             @vClientEmail   = ClientEmail,
             @vEventDetails  = EventDetails,
             @vTrackEvent    = TrackEvent
      from EventMonitor
      where (RecordId = @vEventRecordId);

      /* Get the Message Body and Subject from Messages table */
      select @vAlertMessage = dbo.fn_Messages_GetDescription('EMA_Message_'+@vEventName),
             @vSubject      = dbo.fn_Messages_GetDescription('EMA_Subject_'+@vEventName);

      select @vAlertMessage = replace(@vAlertMessage, '%LASTRUNAT', convert(varchar, @vLastRunAt));
      select @vAlertMessage = replace(@vAlertMessage, '%RUNINTERVAL', convert(varchar, @vAlertInterval));
      select @vAlertSubject = replace(@vSubject, '%EVENTNAME', @vEventName);

      /* Initialize */
      select @vBody     = @vAlertMessage,
             @vSubject  = @vAlertSubject,
             @vEmailId  = @vSupportEmail;

      if (@vTrackEvent = 'C' /* 'Tracked and Client Intimation' */)
        set @vEMailId = @vEMailId + ',' + @vClientEmail;

      /* send db mail with the failed event details */
      exec msdb.dbo.sp_send_dbmail @profile_name = @vProfileName,
                                   @recipients   = @vEmailId,
                                   @subject      = @vSubject,
                                   @body_format  = 'HTML',
                                   @body         = @vBody;

    end
end /* pr_EventMonitor_SendEmailAlerts */

Go
