/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/08/28  PK      pr_DaB_Putaway_PercentComplete: Implemented Logic.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_Putaway_PercentComplete') is not null
  drop Procedure pr_DaB_Putaway_PercentComplete;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_Putaway_PercentComplete: Returns the statistics or Receipts and
   Putaway for the given period. If EndDate is not specified, it defaults to Today
   and if StartDate has not been specified, then it default to last 7 days from
   EndDate.
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_Putaway_PercentComplete
as
  declare @ttStats table (Period TDescription, PercentComplete Integer, SortSeq TInteger);
  declare @vLPNsReceivedToday         TCount,
          @vLPNsPutawayToday          TCount,
          @vLPNsReceivedYesterday     TCount,
          @vLPNsPutawayYesterday      TCount,
          @vLPNsReceivedPreviously    TCount,
          @vLPNsPutawayPreviously     TCount,
          @vTodaysLPNsPerComplete     TCount,
          @vYesterdaysLPNsPerComplete TCount,
          @vPastLPNsPerComplete       TCount,
          @vLastOpenReceivedDate      TDate;
begin
  SET NOCOUNT ON;

  /* Get the earliest date to report from */
  select @vLastOpenReceivedDate = Min(cast(ReceivedDate as date))
  from LPNs
  where (Status = 'R' /* Received */);

  /* If earliest date is less than a week, let us alteast consider "Past" to be last week */
  if (@vLastOpenReceivedDate > cast((getdate() -7) as date))
    set @vLastOpenReceivedDate = cast((getdate() -7) as date);

  /* get the Todays Putaway LPNs count */
  select @vLPNsReceivedToday = count(*),
         @vLPNsPutawayToday  = sum(case when L.Status <> 'R' then 1 else 0 end)
  from LPNs L
  where (cast(L.ReceivedDate as date) = cast(getdate() as date));

  /* get Yesterdays Putaway LPNs count */
  select @vLPNsReceivedYesterday = count(*),
         @vLPNsPutawayYesterday  = sum(case when L.Status <> 'R' then 1 else 0 end)
  from LPNs L
  where (cast(L.ReceivedDate as date) = cast((getdate() - 1) as date));

  /* get Past Putaway LPNs count */
  select @vLPNsReceivedPreviously = count(*),
         @vLPNsPutawayPreviously  = sum(case when L.Status <> 'R' then 1 else 0 end)
  from LPNs L
  where (cast(L.ReceivedDate as date) between @vLastOpenReceivedDate and cast((getdate() - 2) as date));

  /* get Past LPNs Putaway count *
  select @vPastLPNsCount = count(distinct(LPN))
  from LPNDetails LD
    join LPNs L on (LD.LPNId = L.LPNId)
  where (L.Status = 'P' * Putaway * ) and (cast(LastPutawayDate as date) < cast((getdate() - 1) as date));
  */

  /* get the percent of the counts, Today's, Yesterday's and Past */
  select @vTodaysLPNsPerComplete    = case
                                         when (@vLPNsReceivedToday > 0) then
                                           (cast(@vLPNsPutawayToday as decimal)/cast(@vLPNsReceivedToday as decimal) * 100)
                                         else 0
                                       end,
         @vYesterdaysLPNsPerComplete = case
                                         when (@vLPNsReceivedYesterday > 0) then
                                           (cast(@vLPNsPutawayYesterday as decimal)/cast(@vLPNsReceivedYesterday as decimal) * 100)
                                         else 0
                                       end,
         @vPastLPNsPerComplete       = case
                                         when (@vLPNsReceivedPreviously > 0) then
                                           (cast(@vLPNsPutawayPreviously as decimal)/cast(@vLPNsReceivedPreviously as decimal) * 100)
                                         else 0
                                       end;

  /* get the Percent complete stats */
  insert into @ttStats
          select 'Past',      @vPastLPNsPerComplete,       1
    union select 'Yesterday', @vYesterdaysLPNsPerComplete, 2
    union select 'Today',     @vTodaysLPNsPerComplete,     3

  /* Return the stats to display on the dashboard */
  select * from @ttStats
  order by SortSeq

end /* pr_DaB_Putaway_PercentComplete */

Go
