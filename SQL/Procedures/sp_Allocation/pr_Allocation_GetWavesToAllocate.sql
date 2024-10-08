/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/21  TK      pr_Allocation_AllocateWave: Pass cartonization model to evaluate rules
                      pr_Allocation_GetWavesToAllocate: Changes return CaronizationModel
                      pr_Allocation_GenerateShipCartonsForPrepacks: Initial Revision (HA-2664)
  2020/05/04  TK      pr_Allocation_GenerateShipCartons: Initial Revision
                      pr_Allocation_AllocateWave: Added step to generate ship cartons (HA-172)
                      pr_Allocation_AllocateWave &  pr_Allocation_GetWavesToAllocate:
                        Allocate inventory based upon InvAllocationModel (HA-385)
  2019/10/18  AY      pr_Allocation_AllocateWave/pr_Allocation_GetWavesToAllocate: Fix to reallocate
                        Replen wave on deadlock (CID-Support)
  2018/11/01  AY      pr_Allocation_GetWavesToAllocate: New procedure to determine list of waves to allocate and in what sequence (OB2-706)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GetWavesToAllocate') is not null
  drop Procedure pr_Allocation_GetWavesToAllocate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GetWavesToAllocate: Get the list of Waves to allocate and
   the order to allocate them in.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GetWavesToAllocate
  (@WaveNo           TWaveNo,
   @Operation        TOperation = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Debug            TFlags)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;

  declare @vValidReplenishBatchStatuses TControlValue;
  declare @ttWavesToAllocate            TWavesToAllocate;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select @vValidReplenishBatchStatuses  = dbo.fn_Controls_GetAsString('ReplenishBatch', 'ValidBatchStatuses', 'BR' /* Planned, Released */,  @BusinessUnit, @UserId);

  /* First, select replenish Waves for allocation which have not been completed earlier */
  insert into @ttWavesToAllocate(WaveId, WaveNo, WaveType, WaveStatus, Account, InvAllocationModel, CartonizationModel,
                                 IsAllocated, Warehouse, AllocPriority)
    select RecordId, BatchNo, BatchType, Status, Account, InvAllocationModel, CartonizationModel,
           'N' /* IsAllocated */, Warehouse, 1 /* first we need to allocate Replenish waves */
    from PickBatches
    where (BatchType in ('R', 'RU','RP')) and
          (BusinessUnit = @BusinessUnit) and
          (AllocateFlags = 'I' /* InProgress */) and (datediff(mi, ModifiedDate, current_timestamp) < 30) and
          (charindex(Status, @vValidReplenishBatchStatuses) > 0);

  /* Next, select replenish Waves that are yet to be allocated */
  insert into @ttWavesToAllocate(WaveId, WaveNo, WaveType, WaveStatus, Account, InvAllocationModel, CartonizationModel,
                                 IsAllocated, Warehouse, AllocPriority)
    select RecordId, BatchNo, BatchType, Status, Account, InvAllocationModel, CartonizationModel,
           'N' /* IsAllocated */, Warehouse, 1 /* first we need to allocate Replenish waves */
    from PickBatches
    where (BatchType in ('R', 'RU','RP')) and
          (BusinessUnit = @BusinessUnit) and
          (AllocateFlags = 'Y' /* Yes */) and
          (charindex(Status, @vValidReplenishBatchStatuses) > 0);

  /* Next select all other Waves which have AllocateFlag set */
  /* Insert all the details into temp table the Waves which need to be allocate */
  /* At present we will load readytoPick and picking Waves to allocate */

  /* If there are any orphan waves in Inprogress status that did not complete earlier, add them to the list
     But we don't want to try them for ever, so try them for next 30 mins only */
  insert into @ttWavesToAllocate(WaveId, WaveNo, WaveType, WaveStatus, Account, InvAllocationModel, CartonizationModel,
                                 IsAllocated, Warehouse, AllocPriority)
    select RecordId, BatchNo, BatchType, Status, Account, InvAllocationModel, CartonizationModel,
           'N' /* IsAllocated */, Warehouse, 2
    from PickBatches
    where (BatchNo      = coalesce(@WaveNo, BatchNo)) and
          (BatchType not in ('R', 'RU','RP')) and
          (BusinessUnit = @BusinessUnit) and
          (AllocateFlags = 'I' /* InProgress */) and (datediff(mi, ModifiedDate, current_timestamp) < 30) and
          (Status not in ('N', 'X', 'S', 'D' /* New, Canceled, Shipped, Completed */));

  /* We only want to allocate one wave at a time so that we don't create multiple on-demands when multiple
     waves are being allocated */
  insert into @ttWavesToAllocate(WaveId, WaveNo, WaveType, WaveStatus, Account, InvAllocationModel, CartonizationModel,
                                 IsAllocated, Warehouse, AllocPriority)
    select RecordId, BatchNo, BatchType, Status, Account, InvAllocationModel, CartonizationModel,
           'N' /* IsAllocated */, Warehouse, 3
    from PickBatches
    where (BatchNo      = coalesce(@WaveNo, BatchNo)) and
          (BatchType not in ('R', 'RU','RP')) and
          (BusinessUnit = @BusinessUnit) and
          (AllocateFlags = 'Y' /* Yes */) and
          (Status not in ('N', 'X', 'S', 'D' /* New, Canceled, Shipped, Completed */));

  /* Return the Wave to allocate */
  select WaveId, WaveNo, WaveType, WaveStatus, Account, InvAllocationModel, CartonizationModel, IsAllocated, Warehouse, AllocPriority from @ttWavesToAllocate;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_GetWavesToAllocate */

Go
