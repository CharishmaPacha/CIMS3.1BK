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

if object_id('dbo.pr_DaB_RetailWave_WaveStatusCount') is not null
  drop Procedure pr_DaB_RetailWave_WaveStatusCount;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_RetailWave_WaveStatusCount

------------------------------------------------------------------------------*/
Create Procedure pr_DaB_RetailWave_WaveStatusCount
  (@PickBatchNo      TPickBatchNo)
as
  declare @vPickBatchId    TRecordId,
          @vPickBatchType  TTypeCode,
          @vTaskNumCases   TCount,
          @vTaskNumUnits   TCount;

  declare @ttStatusCounts table
    (Status    TDescription,
     DestZone  TLookupCode,
     NumCases  TCount,
     NumUnits  TCount,
     SortSeq   TCount);

  declare @ttLPNCounts table
    (Status      TTypeCode,
     StatusDesc  TDescription,
     LPNType     TTypeCode,
     DestZone    TLookupCode,
     Location    TLocation,
     NumCases    TCount,
     NumUnits    TCount,
     DaBStatus   TDescription,
     SortSeq     TInteger);
begin
  SET NOCOUNT ON;

  select @vPickBatchId   = RecordId,
         @vPickBatchType = BatchType
  from PickBatches
  where (BatchNo = @PickBatchNo);

  /* Calculate the number of cases for tasks for which Labels have not yet been generated */
  with TaskSum(TaskId, SubType, Cases, Qty, PickWeight, PickVol, CasesByWeight, CasesByVol, EstCases)
  as
  (
    select TaskId, TaskSubType, sum(DetailInnerPacks) Cases, sum(DetailQuantity) Qty, sum(PickWeight) Weight, sum(PickVolume) Vol,
    ceiling(sum(PickWeight)/100) CasesByWeight, ceiling(sum(PickVolume)/3240) CasesByVolume,
    dbo.fn_MaxInt(ceiling(sum(PickWeight)/100), ceiling(sum(PickVolume)/3240)) EstCases
    from vwPicktasks
    where (BatchNo = @PickBatchNo) and --(IsLabelGenerated = 'N') and
          (TaskStatus not in ('C', 'X' /* Completed, Canceled */))
    group by TaskId, TaskSubType
  )
  select @vTaskNumCases = sum(case when SubType = 'CS' or SubType = 'L' then Cases else EstCases end),
         @vTaskNumUnits = sum(Qty)
  from TaskSum;

  /* Summarize all LPNs on the Wave by Status, DestZone, Location */
  insert into @ttLPNCounts (Status, StatusDesc, LPNType, DestZone, Location, NumCases, NumUnits)
    select L.Status, L.LPNStatusDesc, L.LPNType, coalesce(L.DestZone, ''), coalesce(L.Location, ''),
           sum(coalesce(nullif(L.InnerPacks, 0), 1)), sum(L.Quantity)
    from vwLPNs L
    where (L.PickBatchId = @vPickBatchId) and
          (Status not in ('F', 'C' /* New Temp, Consumed */))
    group by L.Status, L.LPNStatusDesc, L.LPNType, L.DestZone, L.Location;

  /* All full cases and totes that are picked and not already at sorters should be
     shown as picked on the dashboard */
  update @ttLPNCounts
  set DabStatus = 'Picked',
      SortSeq   = 4
  where (LPNType in ('C', 'TO')) and (Status = 'K') and
        (Location not in ('PTL', 'SORT-RETAIL', 'SORT-ECOM'));

  /* Cases/Totes which are at PTL or Sorters are considered ready to Induct */
  update @ttLPNCounts
  set DabStatus = 'To Induct',
      SortSeq   = 5
  where (LPNType in ('C', 'TO')) and
        (Status = 'K') and
        --(DestZone in ('PTL', 'SORT-RETAIL', 'SORT-ECOM')) and
        (Location in ('PTL', 'SORT-RETAIL', 'SORT-ECOM'));

/*
  insert into @ttStatusCounts
    select 'Inducted', '', sum(NumCases), sum(NumUnits), 6
    from @ttLPNCounts
    where (LPNType in ('C', 'TO')) and
          (Status = 'K') and
          (DestZone not in ('PTL', 'SORT-RETAIL', 'SHIPDOCK', 'NON-CONV', ''));
*/

  /* Outbound carton that is not Loaded or shipped is considered as Sorted
     However, for ECom they would be directed to Packing area, so consider
     those at To Pack */
  update @ttLPNCounts
  set DabStatus = 'Sorted', -- case when @vPickBatchType like 'ECOM%' then 'To Pack' else 'Sorted' end,
      SortSeq   = 7
  where (LPNType = 'S') and (Status not in ('L', 'S' /* Loaded, Shipped */));

  /* Cases/Totes which are already loaded into the Truck */
  update @ttLPNCounts
  set DabStatus = 'Loaded',
      SortSeq   = 8
  where (LPNType in ('C', 'S')) and (Status in ('L' /* Loaded */));

  /* Cases/Totes which are already shipped */
  update @ttLPNCounts
  set DabStatus = 'Shipped',
      SortSeq   = 9
  where (LPNType in ('C', 'S')) and (Status in ('S' /* Shipped */));

  /* If cases have been diverted to Overflow staging, then show the same */
  update @ttLPNCounts
  set DabStatus = 'Overflow',
      SortSeq   = 20
  where Location = 'Overflow';

  /* If we have missed any scenario, this is catch all to make sure we don't exclude them */
  update @ttLPNCounts
  set DabStatus = Status, SortSeq = 30
  where DabStatus is null;

  /* Tasks that are not yet completed are considered as To Pick */
  insert into @ttStatusCounts
    select 'To Pick', '', @vTaskNumCases, @vTaskNumUnits, 2;

  /* Now that all cases are classified, insert the same into Status Counts */
  insert into @ttStatusCounts
    select DabStatus, '', sum(NumCases), sum(NumUnits), min(SortSeq)
    from @ttLPNCounts
    group by DabStatus;

  with AllStatuses(Status, SortSeq)
  as (
          select 'Picked',    4
    union select 'To Induct', 5
    union select 'Sorted',    7
    union select 'Loaded',    8
    union select 'Shipped',   9
  )
  insert into @ttStatusCounts (Status, SortSeq)
    select A.Status, A.SortSeq from AllStatuses A left outer join @ttStatusCounts SC on A.Status = SC.Status
    where SC.Status is null

  /* Returning LPN info data set. */
  select *
  from @ttStatusCounts;
end /* pr_DaB_RetailWave_WaveStatusCount */

Go
