/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/20  MS      pr_DaB_RetailWave_WaveStatusCount, pr_DaB_Putaway_ReceivedPutawayInPeriod: Use LPNStatusDesc (HA-604)
  2014/08/06  PKS     Added pr_DaB_RetailWave_WaveStatusCount
                      pr_DaB_RetailWave_WaveStatusPercent, pr_DaB_RetailWave_WaveStatus: used pr_DaB_RetailWave_WaveStatusCount
                       to get summarised information.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_RetailWave_WaveStatus') is not null
  drop Procedure pr_DaB_RetailWave_WaveStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_RetailWave_WaveStatus

------------------------------------------------------------------------------*/
Create Procedure pr_DaB_RetailWave_WaveStatus
  (@PickBatchNo      TPickBatchNo)
as
  declare @ttStatusCounts table
    (Status    TDescription,
     DestZone  TLookupCode,
     NumCases  TCount,
     NumUnits  TCount,
     SortSeq   TCount);
begin
  /* Fetching data from pr_DaB_RetailWave_WaveStatusCount */
  insert into @ttStatusCounts
    exec pr_DaB_RetailWave_WaveStatusCount @PickBatchNo;

  select Status,  DestZone, sum(NumCases) Cases, sum(NumUnits) Units, SortSeq
  from @ttStatusCounts
  group by SortSeq, Status , DestZone;
end /* pr_DaB_RetailWave_WaveStatus */

Go
