/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/12  TD/AY   pr_Allocation_SumPicksFromSameLocation: Changes to consider TD.Status in 'On-Hold' too: Migrated from Prod (OB2-190)
  2018/07/13  AY/PK   pr_Allocation_SumPicksFromSameLocation: fn_LPNDetails_ComputeInnerpacks added UnitsToAllocate: Migrated from Prod (S2G-727)
  2018/05/17  TK      pr_Allocation_SumPicksFromSameLocation: Changes to update innerpacks on task details (S2G-Support)
  2018/04/11  TK      pr_Allocation_AllocateWave: Added new step to generate temp LPNs
                      pr_Allocation_InsertShipLabels: Changes to consider info from LPNTasks
                      pr_Allocation_SumPicksFromSameLocation: Changes to summarize innerpacks info (S2G-619)
  2018/03/02  TK      pr_Allocation_AllocateLPN: Changes to create PR lines only for picklanes
                      pr_Allocation_AllocateInventory: Changes to update WaveId on task details
                      pr_Allocation_AllocateLPNToOrders: Changes to increment qty on the task
                        detail if there is on for order detail
                      pr_Allocation_FindAllocableLPN: Changes to over allocate LPNs from Bulk Location
                      pr_Allocation_SumPicksFromSameLocation: Initial Revision (S2G-151)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_SumPicksFromSameLocation') is not null
  drop Procedure pr_Allocation_SumPicksFromSameLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_SumPicksFromSameLocation: This proc summarizes Picks, if there are
    multiple picks from same Location which are not yet categorized
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_SumPicksFromSameLocation
  (@PicksToEvaluate      TTaskInfoTable  ReadOnly,
   @WaveId               TRecordId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vRecordId          TRecordId,
          @vTaskDetailId      TRecordId,
          @vOrderDetailId     TRecordId,
          @vLPNDetailId       TRecordId,
          @vInnerPacks        TInnerPacks,
          @vUnitsToAllocate   TQuantity;

  declare @ttPicksInfo        TTaskInfoTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* For the given picks, check if there are existing task details from the same LPN
     for the same order detail, if so, we would want to evaluate them */
  insert into @ttPicksInfo(PickBatchId, PickBatchNo, OrderId, OrderDetailId, OrderType, LPNId,
                          LPNDetailId, UnitsToAllocate, SKUId, InnerPacks,
                          PickPath, TotalWeight, TotalVolume, UnitWeight, UnitVolume,
                          DestZone, TempLabelId, TempLabel, CartonType)
  select PTE.PickBatchId, PTE.PickBatchNo, PTE.OrderId, PTE.OrderDetailId, PTE.OrderType, PTE.LPNId,
         PTE.LPNDetailId, PTE.UnitsToAllocate, PTE.SKUId, PTE.InnerPacks,
         PTE.PickPath, PTE.TotalWeight, PTE.TotalVolume, PTE.UnitWeight, PTE.UnitVolume,
         PTE.DestZone, PTE.TempLabelId, PTE.TempLabel, PTE.CartonType
  from @PicksToEvaluate PTE join TaskDetails TD on (PTE.OrderDetailId = TD.OrderDetailId) and
                                                   (PTE.LPNDetailId   = TD.LPNDetailId  )
  where (TD.WaveId = @WaveId) and
        (TD.Status in ('O', 'NC'/* On-Hold, Not-Categorized */));

  /* Update Innerpacks on the Task Details to be summarized as by this time we don't
     know how many Innperpacks/cases needs to be picked */
  update ttPI
  set ttPI.Innerpacks = dbo.fn_LPNDetails_ComputeInnerpacks(ttPI.LPNDetailId, ttPI.UnitsToAllocate, null)
  from @ttPicksInfo ttPI;

  /* Loop thru each pick and summarize so that we don't get multiple picks from same Location */
  while exists(select * from @ttPicksInfo where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId        = RecordId,
                   @vOrderDetailId   = OrderDetailId,
                   @vLPNDetailId     = LPNDetailId,
                   @vUnitsToAllocate = UnitsToAllocate,
                   @vInnerPacks      = InnerPacks
      from @ttPicksInfo
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Find out if there is any task detail from the same order detail which is not yet categorized */
      select @vTaskDetailId = TaskDetailId
      from TaskDetails
      where (OrderDetailId = @vOrderDetailId) and
            (LPNDetailId   = @vLPNDetailId  ) and
            (Status in ('O', 'NC'/* On-Hold, Not-Categorized */));

      /*  If task detail is available then increment quantity on the detail with Allocated Qty */
      if (@vTaskDetailId is not null)
        update TaskDetails
        set InnerPacks += @vInnerPacks,
            Quantity   += @vUnitsToAllocate
        where (TaskDetailId = @vTaskDetailId);
    end

  /* Return Picks which are not merged with existing task details */
  select PTE.PickBatchId, PTE.PickBatchNo, PTE.OrderId, PTE.OrderDetailId, PTE.OrderType, PTE.LPNId,
         PTE.LPNDetailId, PTE.UnitsToAllocate, PTE.SKUId, PTE.InnerPacks,
         PTE.PickPath, PTE.TotalWeight, PTE.TotalVolume, PTE.UnitWeight, PTE.UnitVolume,
         PTE.DestZone, PTE.TempLabelId, PTE.TempLabel, PTE.CartonType
  from @PicksToEvaluate PTE
    left join @ttPicksInfo PI on (PTE.OrderDetailId = PI.OrderDetailId) and
                                 (PTE.LPNDetailId   = PI.LPNDetailId)
  where (PI.LPNDetailId is null);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_SumPicksFromSameLocation */

Go
