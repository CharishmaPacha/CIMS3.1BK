/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/03/26  NB      Added pr_EventMonitor_Validate and pr_EventMonitor_SendEmailAlerts
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_EventMonitor_Validate') is not null
  drop Procedure pr_EventMonitor_Validate;
Go

/*------------------------------------------------------------------------------
  Proc pr_EventMonitor_Validate:

  Procedure identifies if there are any eventmonitor entries which should be alerted,
  considering the lastrun timestamp and alert interval
------------------------------------------------------------------------------*/
Create Procedure pr_EventMonitor_Validate
as
begin /* pr_EventMonitor_Validate */
  /* set all alertsent status to Ignore, before validate for the event monitor records being tracked */
  update EventMonitor
  set AlertSent = 'I' /* Ignore record while sending alerts */
  where (TrackEvent <> 'N' /* No */); -- consider all event monitor entries which are setup to be tracked

  /*
     Evaluate all EventMonitor records setup for tracking to verify whether the interval between
     last run time and current time exceeds the defined alert interval
  */
  update EventMonitor
  set AlertSent = 'T' /* Alert to be sent */
  where (TrackEvent <> 'N' /* No */) and -- consider all event monitor entries which are setup to be tracked
        (datediff(minute, LastRunAt, current_timestamp) > AlertInterval);
end /* pr_EventMonitor_Validate */

Go
