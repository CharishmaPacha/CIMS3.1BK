/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/01  TK      pr_Wave_ComputeWCSReleaseDependency: Consider waves whose allocation is complete (S2G-1071)
  2018/03/27  AY      pr_Wave_ComputeWCSReleaseDependency: Correct the statuses
  2018/03/12  AY      pr_Wave_ComputeWCSReleaseDependency: Revised code (S2G-242)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_ComputeWCSReleaseDependency') is not null
  drop Procedure pr_Wave_ComputeWCSReleaseDependency;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_ComputeWCSReleaseDependency: Computes WCS release dependency on Wave by evaluating
     several depedency factors, the WCSDependency is initialized as RLD when the Wave is released for allocation
     (R - Replenishments,
      L - Labels,
      D - Shipping Documents) on all the tasks
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_ComputeWCSReleaseDependency
  (@BusinessUnit    TBusinessUnit = null,
   @UserId          TUserId       = null)
as
  /* declarations */
  declare @vRecordId             TRecordId,
          @vWaveId               TRecordId,
          @vWCSDependency        TFlags,
          @vWaveDependency       TFlags,
          @vNumLPNs              TCount,
          @vShipLabelsGenerated  TCount,
          @vShipDocsExported     TCount;

  declare @ttWaves table (RecordId        TRecordId identity(1,1),
                          WaveId          TRecordId,
                          WaveNo          TPickBatchNo,
                          NumLPNs         TCount,
                          DependencyFlags TFlags,
                          WCSDependency   TFlags);
begin
  /* Initialize */
  set @vRecordId = 0;

  /* Get all the Waves which needs to be processed */
  insert into @ttWaves(WaveId, WaveNo, NumLPNs, DependencyFlags, WCSDependency)
    select RecordId, BatchNo, NumLPNs, DependencyFlags, WCSDependency
    from PickBatches
    where (Status        = 'R' /* Ready to pick */) and
          (IsAllocated   = 'Y' /* Yes */) and
          (AllocateFlags = 'D' /* Done */) and  -- Consider waves whose allocation is complete
          (BusinessUnit  = @BusinessUnit);

  /* Loop thru each Wave to get released */
  while exists (select * from @ttWaves where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId       = RecordId,
                   @vWaveId         = WaveId,
                   @vNumLPNs        = NumLPNs,
                   @vWaveDependency = DependencyFlags,
                   @vWCSDependency  = WCSDependency
      from @ttWaves
      where (RecordId > @vRecordId)
      order by RecordId;

      /* If there are no more Tasks that are waiting on Replenishments or Shorts, then
         all Replenishments are cleared, so remove the R from the WCSDependency */
      if (@vWaveDependency not in ('R', 'S'))
        select @vWCSDependency = replace(@vWCSDependency, 'R', '');

      select @vShipLabelsGenerated = sum(case when SL.ProcessStatus in ('', 'LGE', 'E', 'N' /* No Label generation error */) then 0 else 1 end),
             @vShipDocsExported    = sum(case when SL.ProcessStatus in ('XC' /* Export Completed */) then 1 else 0 end)
      from ShipLabels SL
      where (WaveId = @vWaveId) and
            (Status = 'A'/* Active */);

      /* If all Ship cartons have labels generated, then clear the L flag */
      if (@vNumLPNs = @vShipLabelsGenerated) and (@vNumLPNs > 0)
        select @vWCSDependency = replace(@vWCSDependency, 'L', '');

      /* If all Shipping documents are exported, then clear the D flag */
      if (@vNumLPNs = @vShipDocsExported) and (@vNumLPNs > 0)
        select @vWCSDependency = replace(@vWCSDependency, 'D', '');

      update @ttWaves
      set WCSDependency = @vWCSDependency
      where (RecordId = @vRecordId);

      --exec pr_ActivityLog_AddMessage 'Wave_ComputeWCSReleaseDependency', @vWaveId, null, 'Wave',
      --                               null /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;
    end

  /* Update WCSDependency on Wave */
  update W
  set W.WCSDependency = coalesce(ttw.WCSDependency, W.WCSDependency),
      W.ColorCode     = case
                           when ttw.WCSDependency = ''  then 'G' -- Dependency resolved, so show in green
                           when ttw.WCSDependency <> '' then 'R' -- Still there is dependency, show in red
                           else null -- default color
                         end,
      W.ModifiedDate  = current_timestamp
  from Waves W
    join @ttWaves ttW on (W.WaveId = ttW.WaveId);

end /* pr_Wave_ComputeWCSReleaseDependency */

Go
