/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/21  VM      pr_Alerts_WavesNotAllocated: Included to show ReleasedDate as well (OB2-642)
                      pr_Alerts_WavesNotAllocated: Consider only waves which went through allocation process (S2G-CRP)
  2018/03/13  AY      pr_Alerts_WavesNotAllocated: Changed to only alert for 1 hr after modified date
  2018/03/13  VM      Added pr_Alerts_WavesNotAllocated (S2G-391)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_WavesNotAllocated') is not null
  drop Procedure pr_Alerts_WavesNotAllocated;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_WavesNotAllocated:
    Evaluates all released waves for allocation.
    Sends alert, if there are any waves, which are not allocated even though if there is inventory

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last X minutes
  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only
  @EntityId
    - If passed, ignores all other entities by considering the passed in EntityId
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_WavesNotAllocated
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
As
  declare  @vAlertCategory   TCategory,
           @vEmailSubject    TDescription,
           @vEmailBody       varchar(max),
           @vFieldCaptions   varchar(max),
           @vFieldValuesXML  varchar(max);

  declare @ttWaveInvSummary  TPickBatchSummary,
          @ttAlertData       TPickBatchSummary; /* We may use several other fields in future. Hence, defined datatype as TPickBatchSummary */

  declare @ttReleasedWaves Table
            (WaveNo           TPickBatchNo,
             WaveType         TTypeCode,
             WaveStatus       TStatus,
             ReleaseDateTime  TDatetime
             Primary Key (WaveNo));

  declare @vWaveNo          TPickBatchNo,
          @vWaveType        TTypeCode,
          @vWaveStatus      TStatus,
          @vReleaseDateTime TDatetime;
begin
  select @vAlertCategory = Object_Name(@@ProcId) -- pr_ will be trimmed by pr_Email_SendDBAlert,

  select BatchNo as WaveNo, SKUId, SKU, UnitsAuthorizedToShip, UnitsAssigned, UnitsNeeded, UnitsAvailable
  into #WavesNotAllocated from @ttAlertData;

  alter table #WavesNotAllocated
  Add WaveType        varchar(20),
      WaveStatus      varchar(20),
      ReleaseDateTime datetime;

  /* Take all released waves into a temp table to evaluate them */
  insert into @ttReleasedWaves(WaveNo, WaveType, WaveStatus, ReleaseDateTime)
    select WaveNo, WaveType, WaveStatus, ReleaseDateTime
    from Waves with (nolock)
    where (WaveStatus    = 'R' /* Released */) and
          (AllocateFlags = 'D' /* Done */) and -- verify only waves which went through allocation
          (datediff(mi, ReleaseDateTime, getdate()) <= @ShowModifiedInLastXMinutes) and
          (WaveId = coalesce(@EntityId, WaveId));

  select @vWaveNo = 0;

  /* Loop through all released waves and identify the waves, which are not allocated even though there is inventory
     by verifying their summaries */
  while exists(select * from @ttReleasedWaves where WaveNo > @vWaveNo)
    begin
      select top 1
             @vWaveNo          = WaveNo,
             @vWaveType        = WaveType,
             @vWaveStatus      = WaveStatus,
             @vReleaseDateTime = ReleaseDateTime
      from @ttReleasedWaves
      where (WaveNo > @vWaveNo)
      order by WaveNo;

      /* Get summary of the wave
         -  The below insert statement is cloned from pr_PickBatch_BatchSummary.
            Hence, if there are more fields added, we could bring the code again and use them for o/p to show in alert */
      insert into @ttWaveInvSummary (Line, HostOrderLine, OrderDetailId, CustSKU, CustPO, ShipToStore,
                                     SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, Description,
                                     UnitsPerCarton, UnitsPerInnerPack, UnitsOrdered , UnitsAuthorizedToShip,
                                     UnitsAssigned, UnitsNeeded, UnitsAvailable, UnitsShort,
                                     UnitsPicked, UnitsPacked, UnitsLabeled, UnitsShipped,
                                     LPNsOrdered, LPNsToShip, LPNsAssigned, LPNsNeeded,
                                     LPNsAvailable, LPNsShort, LPNsPicked, LPNsPacked, LPNsLabeled, LPNsShipped,
                                     UDF1, UDF2, UDF3, UDF4, UDF5)
        exec pr_PickBatch_InventorySummary @vWaveNo;

      /* Identify if the wave is not allocated even though inventory exists. If so, store its summary details into temp table */
      insert into #WavesNotAllocated(WaveNo, WaveType /* WaveType */, WaveStatus /* Used for WaveStatus */, ReleaseDateTime /* ReleasedDate */, SKUId, SKU,
                                         UnitsAuthorizedToShip, UnitsAssigned, UnitsNeeded, UnitsAvailable)
        select @vWaveNo, @vWaveType, @vWaveStatus, @vReleaseDateTime, SKUId, SKU,
               sum(UnitsAuthorizedToShip), sum(UnitsAssigned), sum(UnitsAuthorizedToShip) - sum(UnitsAssigned), Min(UnitsAvailable)
        from @ttWaveInvSummary
        group by SKUId, SKU
        having ((sum(UnitsAuthorizedToShip) - sum(UnitsAssigned)) /* UnitsNeeded */ > 0) and
               (Min(UnitsAvailable) > 0)
        order by SKU;

      /* Clean up temp table for next wave to use */
      delete from @ttWaveInvSummary;
    end

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #WavesNotAllocated;
      return(0);
    end

  /* Email the results */
  if (exists (select * from #WavesNotAllocated))
    exec pr_Email_SendQueryResults @vAlertCategory, '#WavesNotAllocated', null /* order by */, @BusinessUnit;
end /* pr_Alerts_WavesNotAllocated */

Go
