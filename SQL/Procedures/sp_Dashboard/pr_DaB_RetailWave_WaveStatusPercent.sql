/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/08/06  PKS     Added pr_DaB_RetailWave_WaveStatusCount
                      pr_DaB_RetailWave_WaveStatusPercent, pr_DaB_RetailWave_WaveStatus: used pr_DaB_RetailWave_WaveStatusCount
                       to get summarised information.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_RetailWave_WaveStatusPercent') is not null
  drop Procedure pr_DaB_RetailWave_WaveStatusPercent;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_RetailWave_WaveStatusPercent

------------------------------------------------------------------------------*/
Create Procedure pr_DaB_RetailWave_WaveStatusPercent
  (@PickBatchNo      TPickBatchNo)
as
  declare @vPickBatchUnits TCount;

  declare @ttStatusCounts table
    (Status    TDescription,
     DestZone  TLookupCode,
     NumCases  TCount,
     NumUnits  TCount,
     SortSeq   TCount);

begin

  select @vPickBatchUnits = NumUnits
  from PickBatches
  where (BatchNo = @PickBatchNo);

  /* Fetching data from pr_DaB_RetailWave_WaveStatusCount */
  insert into @ttStatusCounts
    exec pr_DaB_RetailWave_WaveStatusCount @PickBatchNo;

  select Status,  DestZone, sum(NumCases) Cases, sum(NumUnits) Units,
         cast(sum(NumUnits) as numeric(5,2))/@vPickBatchUnits * 100 StatusPercent, SortSeq
  from @ttStatusCounts
  group by SortSeq, Status , DestZone;
end /* pr_DaB_RetailWave_WaveStatusPercent */

Go
