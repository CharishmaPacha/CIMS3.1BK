/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/20  MS      pr_DaB_RetailWave_WaveStatusCount, pr_DaB_Putaway_ReceivedPutawayInPeriod: Use LPNStatusDesc (HA-604)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_Putaway_ReceivedPutawayInPeriod') is not null
  drop Procedure pr_DaB_Putaway_ReceivedPutawayInPeriod;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_Putaway_ReceivedPutawayInPeriod: Returns the statistics or Receipts and
   Putaway for the given period. If EndDate is not specified, it defaults to Today
   and if StartDate has not been specified, then it default to last 7 days from
   EndDate.
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_Putaway_ReceivedPutawayInPeriod
  (@StartDate      TDate = null,
   @EndDate        TDate = null)
as
  declare @ttLPNStats table (ReceivedDate    TDate,
                             ReceivedDateStr Tvarchar,
                             Status          TStatus,
                             LPNs            TCount,
                             InnerPacks      TCount,
                             Quantity        TCount);
begin
  SET NOCOUNT ON;

  select @EndDate   = coalesce(@EndDate, current_timestamp+1);
  select @StartDate = coalesce(@StartDate, dateadd(d, -21, @EndDate));

  /* Return the following: LPNs, Cases, Units in Received status,
                           LPNs, Cases, Units Putaway today */

  insert into @ttLPNStats
  select cast(ReceivedDate as date),
         convert(varchar(6), cast(ReceivedDate as date), 100),
         LPNStatusDesc,
         count(*) LPNs, sum(InnerPacks) InnerPacks, sum(Quantity) Quantity
  from vwLPNs
  where (Status in ('R', 'P', 'C' /* Received or Putaway or consumed */)) and
        (ReceivedDate between @StartDate and @EndDate)
  group by cast(ReceivedDate as date), LPNStatusDesc;

  /* Consider all LPNs as consumed to be Putaway */
  update @ttLPNStats
  set Status = 'Putaway'
  where Status = 'Consumed';

  select * from @ttLPNStats
  order by ReceivedDate, Status desc;

end /* pr_DaB_Putaway_ReceivedPutawayInPeriod */

Go
