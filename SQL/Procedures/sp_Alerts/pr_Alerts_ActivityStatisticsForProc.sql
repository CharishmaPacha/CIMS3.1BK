/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/31  VS/AY   pr_Alerts_ActivityStatisticsForProc: Added new proc to send ActionStatistics (HA-2399)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_ActivityStatisticsForProc') is not null
  drop Procedure pr_Alerts_ActivityStatisticsForProc;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_ActivityStatisticsForProc: Returns the statistics for the given Proc
   from ActivityLog along with count, avg etc. for the requested duration

  Usage:

  To Get stats for UI Actions where average is more than 3 seconds
  exec pr_Alerts_ActivityStatisticsForProc 'pr_Entities_ExecuteAction_V3', 'UI Actions', 0, 200, 2000, 'HA', 'cIMSAgent', 'Y', 'N'

  To Get stats for RF Actions where average is more than 1 second
  exec pr_Alerts_ActivityStatisticsForProc 'pr_AMF_ExecuteAction', 'RF Actions', 0, 100, 1000, 'HA', 'cIMSAgent', 'Y', 'N'
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_ActivityStatisticsForProc
  (@ProcName               TName,
   @AlertCategory          TCategory,
   @PeriodDays             TInteger = null,
   @ShowAvgAboveXMSeconds  TInteger = 100,
   @ShowMaxAboveYMSeconds  TInteger = 2000,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @ReturnDataSet          TFlags    = 'N',
   @EmailIfNoAlert         TFlags    = 'N')
as

  declare @vStartDate         TDate,
          @vEndDate           TDate;
begin
  SET NOCOUNT ON;

  /* Drop the temp table if already exists */
  if object_id('tempdb..#ActivityLog') is not null drop table #ActivityLog;

  select @vEndDate   = getdate(),
         @vStartDate = dateadd(day, -1 * @PeriodDays, @vEndDate);

  /* Get the stats of the given proc for the selected period */
  select datediff_big(millisecond, isnull(AL.StartTime, 0), isnull(AL.EndTime, 0)) Duration, AL.*
  into #ActivityLog
  from CurrActivityLog AL with (nolock)
  where (ProcName like @ProcName +'%') and
        (ActivityDate between @vStartDate and @vEndDate);

  /* if there is no activity, return */
  if not exists(select * from #ActivityLog) return;

  /* If action timed out, duration would be -ve, so set to 5 mins for statistics */
  update #ActivityLog set Duration = 300000 where Duration < 0;

  /* Calculate the stats */
  select Operation, count(*) as NumberOfOccurences, min(Duration) MinDuration, max(Duration) MaxDuration,
         cast(sum(Duration)/count(*) as decimal(38,0)) AvgDuration, ceiling(stdev(Duration)) StdDeviation
  into #ActivityStatistics
  from #ActivityLog
  group by Operation;

  /* select the stats of interest */
  select top 100 * into #FinalActivityStatistics from #ActivityStatistics
  where (AvgDuration > @ShowAvgAboveXMSeconds) or (MaxDuration > @ShowMaxAboveYMSeconds)
  order by AvgDuration desc

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #FinalActivityStatistics
      return(0);
    end

  /* Send email if there is data to report */
  if (@EmailIfNoAlert = 'Y') or (exists(select * from #FinalActivityStatistics))
    exec pr_Email_SendQueryResults @AlertCategory, '#FinalActivityStatistics', null /* order by */, @BusinessUnit;

end /* pr_Alerts_ActivityStatisticsForProc */

Go
