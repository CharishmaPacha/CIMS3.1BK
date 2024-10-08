/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/02  VS/AY   pr_Picking_FindNextTaskToPickFromBatch: Changes made to issue from given task only (CID-661)
  2018/05/08  OK      pr_Picking_FindNextTaskToPickFromBatch: Changes to suggest the task for the given PickTicket (S2G-793)
                      pr_Picking_FindNextTaskToPickFromBatch: Chnages to suggest picks in the order of PickPath (S2G-CRP)
  2016/03/30  AY      pr_Picking_FindNextTaskToPickFromBatch: Ignore Task status when skipping and cycle back to first task.
  2015/10/09  DK      pr_Picking_FindNextTaskToPickFromBatch: Bug fix not to return Pallet Pick tasks during BatchPicking (FB-419).
  2015/09/03  TK      pr_Picking_FindNextTaskToPickFromBatch: Skip pick functionality enhanced for the Tasks which are un-allocated (CIMS-516)
  2015/07/31  TK      pr_Picking_FindNextTaskToPickFromBatch: Suggest picks in the order of CartPostions (ACME-266)
  2015/07/09  TK      pr_Picking_FindNextTaskToPickFromBatch: Bug fix, do not consider Shipack, as we may have to ship units less
  2015/07/02  DK      pr_Picking_FindNextTaskToPickFromBatch: Bug fix to consider the pickpath when Taskid is null (SRI-329).
  2015/01/13  VM      pr_Picking_ValidateTaskId, pr_Picking_FindNextTaskToPickFromBatch:
                      pr_Picking_FindNextTaskToPickFromBatch: Sending PickType based on the Quantity and LPNType.
                      pr_Picking_FindNextTaskToPickFromBatch: Fix to suggest tasks to pick.
  2013/11/11  TD      pr_Picking_FindNextTaskToPickFromBatch: Returns taskid based on the PickZone.
                      pr_Picking_FindNextTaskToPickFromBatch: Returning the tasks which are assigned to the user.
  2013/09/26  PK      pr_Picking_FindNextTaskToPickFromBatch: Added new procedure to suggest pick Tasks.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_FindNextTaskToPickFromBatch') is not null
  drop Procedure pr_Picking_FindNextTaskToPickFromBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_FindNextTaskToPickFromBatch: This Procedure returns the details of
  next pick i.e., LPN, Location, SKU, UnitsToPick, OrderDetailId on Batch.

  We do not need to suggest picks which LPN has lines with DR onhand Status,
  they should putaway the replenished qty before we issue that pick to the user.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_FindNextTaskToPickFromBatch
  (@UserId          TUserId,
   @DeviceId        TDeviceId,
   @BusinessUnit    TBusinessUnit,
   @PickBatchNo     TPickBatchNo,
   @PickTicket      TPickTicket,
   @PickZone        TZoneId,
   @DestZone        TLookUpCode,
   @PickGroup       TPickGroup,
   @SearchType      TFlag        = 'F',        /* Refer to Notes above, for valid values and their usage */
   @SKU             TSKU         = null,
   @Pallet          TPallet,
   @LPNToPick       TLPN         output,
   @LPNIdToPick     TRecordId    output,
   @LPNDetailId     TRecordId    output,
   @OrderDetailId   TRecordId    output,
   @UnitsToPick     TInteger     output,
   @LocToPick       TLocation    output,
   @PickType        TFlag        output,
   @TaskId          TRecordId    output,
   @TaskDetailId    TRecordId    output)
as
  declare @vInputTaskId     TRecordId,
          @vTaskId          TRecordId,
          @vTaskDetailId    TRecordId,
          @vUserId          TRecordId,
          @vTaskSubType     TTypeCode,
          @TaskSubType      TTypeCode,
          @vIsTaskAllocated TFlags,
          @vPalletId        TRecordId,
          @vPalletType      TTypeCode,
          @vSKUId           TRecordId,
          @vDeviceId        TDeviceId,
          @vPickSequence    TPickSequence

begin /* pr_Picking_FindNextTaskToPickFromBatch */
  /* Save the input params */
  select @vTaskId       = @TaskId,
         @vTaskDetailId = @TaskDetailId,
         @vInputTaskId  = @TaskId,
         @vDeviceId     = @DeviceId + '@' + @UserId;     /* Build the device id */

  /* check whether Task is Allocated or not */
  select @vIsTaskAllocated = IsTaskAllocated
  from Tasks
  where (TaskId = @vTaskId);

  /* Get Pallet details */
  select @vPalletId   = PalletId,
         @vPalletType = PalletType
  from Pallets
  where (Pallet = @Pallet) and (BusinessUnit = @BusinessUnit);

  /* Clear output params */
  select @OrderDetailId  = null,
         @LPNToPick      = null,
         @LPNIdToPick    = null,
         @LPNDetailId    = null,
         @LocToPick      = null,
         @UnitsToPick    = null,
         @PickType       = null,
         @TaskId         = null,
         @TaskDetailId   = null;

  /* get pickpath position from devices table */
  select @vPickSequence = PickSequence
  from Devices
  where (DeviceId = @vDeviceId);

  /* Get the Next pick task for the batch. TaskId and TaskDetailId will be passed in from the
     caller as we are returning it from the batch pick response to RF.
     TaskId: If the TaskId is not null and UnitsToPick is Zero then suggest the next Task to
             pick from the batch.
     TaskDetailId: If the TaskDetailId is not null and UnitsToPick is Zero then Suggest
             the next TaskDetail to pick from the batch.
     Status: If the user passed in TaskId is not null and if the UnitsToPick is zero on the task
             then suggest the a task which is in new status.
             If the user passed in TaskId is null and if there are any of the tasks related to the
             keyed in batch are in inprogress then suggest the task to pick.
             else suggest a new task to pick on the batch */

  /* See if there is anything more to be picked for the current task.
     Ordering by TaskDetailStatus ensures that if there is an inprogress taskdetail,
     it would be assigned again. If not, one of the new Tasks would be assigned */
  if (@vIsTaskAllocated = 'Y' /* Yes */)
    begin
      /* We know user requested a task, so we have to find the next task detail to pick from the task.
         First, we need to find the next pick in the pick path. */
        select Top 1
          @OrderDetailId  = OrderDetailId,
          @LPNToPick      = LPN,
          @LPNIdToPick    = LPNId,
          @LPNDetailId    = LPNDetailId,
          @LocToPick      = Location,
          @UnitsToPick    = UnitsToPick,
          @PickType       = case when ((UnitsToPick = LPNQuantity) and
                                       (LPNType <> 'L' /* picklane */)) then 'L' /* LPN Pick */ else 'U' /*Unit Pick*/ end,
          @TaskId         = TaskId,
          @TaskDetailId   = TaskDetailId,
          @vTaskSubType   = TaskSubType,
          @vSKUId         = SKUId
        from vwPickTasks
        where (TaskId = @vTaskId) and
              --(TaskSubType <> 'L' /* LPN Pick */) and
              (UnitsToPick > 0) and
              (TaskStatus not in ('C', 'X' /* Completed or Canceled */)) and
              (TaskDetailStatus not in ('C', 'X' /* Completed or Canceled */)) and
              (coalesce(OnhandStatus, '') <> 'DR' /* Direct Reserved */) and
              (PickSequence > coalesce(@vPickSequence, ''))
        order by TaskDetailStatus, PickSequence, TaskDetailId;

      /* if there are no picks found above, and if we were looking past the previous pick path position
         only, then we need to give the first one again, so that users can do
         shortpick, or they can do drop pallet. */
      if (@vPickSequence is not null) and (@TaskId is null) and (@vTaskId is not null)
        select Top 1
          @OrderDetailId  = OrderDetailId,
          @LPNToPick      = LPN,
          @LPNIdToPick    = LPNId,
          @LPNDetailId    = LPNDetailId,
          @LocToPick      = Location,
          @UnitsToPick    = UnitsToPick,
          @PickType       = case when ((UnitsToPick = LPNQuantity) and
                                       (LPNType <> 'L' /* picklane */)) then 'L' /* LPN Pick */ else 'U' /*Unit Pick*/ end,
          @TaskId         = TaskId,
          @TaskDetailId   = TaskDetailId,
          @vTaskSubType   = TaskSubType,
          @vSKUId         = SKUId
        from vwPickTasks
        where (TaskId = @vTaskId) and
            --(TaskSubType <> 'L' /* LPN Pick */) and
              (UnitsToPick > 0) and
              (TaskStatus not in ('C', 'X' /* Completed or Canceled */)) and
              (TaskDetailStatus not in ('C', 'X' /* Completed or Canceled */)) and
              (coalesce(OnhandStatus, '') <> 'DR' /* Direct Reserved */)
        order by PickSequence, TaskDetailId;
        /* Above, we do not want to sort by TaskDetailStatus. For example if there are details 1, 2, 3, 4 to be picked
           and 2 is In progress when we get to end of the skipping we should skip to 1. This scenario could happen
           because 1 is associated with DR line initially, but later it is available for picking and by this time 2 is
           already in progress */
    end

  /* if the batch is not allocated and Task created then based on the scanned pickzone
     we need to look for the available inventory and suggest LPN and Location
     to Pick for the user */
  if (@vIsTaskAllocated = 'N' /* No */)
    begin
      if (@vTaskId is not null)
        select Top 1
          @OrderDetailId  = PT.OrderDetailId,
          @LPNToPick      = L.LPN,
          @LPNIdToPick    = LD.LPNId,
          @LPNDetailId    = LD.LPNDetailId,
          @LocToPick      = LOC.Location,
          @UnitsToPick    = dbo.fn_MinInt(PT.UnitsToPick, LD.Quantity),
          @PickType       = case when ((PT.UnitsToPick = L.Quantity) and
                                       (L.LPNType <> 'L' /* picklane */))
                                 then 'L' /* LPN Pick */
                            else 'U' /*Unit Pick*/ end,
          @TaskId         = PT.TaskId,
          @TaskDetailId   = PT.TaskDetailId,
          @vTaskSubType   = PT.TaskSubType,
          @vSKUId         = PT.SKUId
        from vwPickTasks  PT
          left outer join LPNDetails LD  on (LD.SKUId       = PT.SKUId    )
          left outer join LPNs       L   on (LD.LPNId       = L.LPNId     )
          left outer join LPNs       TL  on (PT.TempLabelId = TL.LPNId    )
          left outer join Locations  LOC on (LOC.LocationId = L.LocationId)
          left outer join SKUs       S   on (LD.SKUId       = S.SKUId)
        where (PT.TaskId       = @vTaskId) and
              (PT.UnitsToPick > 0) and
              (PT.TaskStatus not in ('C', 'X' /* Completed or Canceled */)) and
              (PT.TaskDetailStatus not in ('C', 'X' /* Completed or Canceled */)) and
              (LOC.PickingZone = @PickZone          ) and
              (PickSequence > coalesce(@vPickSequence, '')) and
              (LD.OnHandStatus = 'A' /* Available */) and
              (LD.Quantity > 0)
        order by PT.TaskDetailStatus, PT.PickSequence, TL.AlternateLPN, PT.TaskDetailId;

      /* if there are no picks found, then we need to give the first one again, so that users can do
           shortpick, or they can do drop pallet. */
      if (@vPickSequence is not null) and (@TaskId is null) and (@vTaskId is not null)
        select Top 1
          @OrderDetailId  = PT.OrderDetailId,
          @LPNToPick      = L.LPN,
          @LPNIdToPick    = LD.LPNId,
          @LPNDetailId    = LD.LPNDetailId,
          @LocToPick      = LOC.Location,
          @UnitsToPick    = dbo.fn_MinInt(PT.UnitsToPick, LD.Quantity),
          @PickType       = case when ((PT.UnitsToPick = L.Quantity) and
                                       (L.LPNType <> 'L' /* picklane */))
                                 then 'L' /* LPN Pick */
                            else 'U' /*Unit Pick*/ end,
          @TaskId         = PT.TaskId,
          @TaskDetailId   = PT.TaskDetailId,
          @vTaskSubType   = PT.TaskSubType,
          @vSKUId         = PT.SKUId
        from vwPickTasks  PT
          left outer join LPNDetails LD  on (LD.SKUId       = PT.SKUId    )
          left outer join LPNs       L   on (LD.LPNId       = L.LPNId     )
          left outer join LPNs       TL  on (PT.TempLabelId = TL.LPNId    )
          left outer join Locations  LOC on (LOC.LocationId = L.LocationId)
          left outer join SKUs       S   on (LD.SKUId       = S.SKUId)
        where (PT.TaskId       = @vTaskId) and
              (PT.UnitsToPick > 0) and
              (PT.TaskStatus not in ('C', 'X' /* Completed or Canceled */)) and
              (PT.TaskDetailStatus not in ('C', 'X' /* Completed or Canceled */)) and
              (LOC.PickingZone = @PickZone          ) and
              (LD.OnHandStatus = 'A' /* Available */) and
              (LD.Quantity > 0)
        order by PT.TaskDetailStatus, PT.PickSequence, TL.AlternateLPN, PT.TaskDetailId;
    end

  /* Find the next task from the batch that is not assigned to any other user already
     - The next task that is assigned to should could be from
       a Batch that is assigned to the user
         or
       a Batch that is not assigned to any user, but the task is unassigned as well
  */
  /* If the user has not given a task to pick, then we find a task for the Wave being picked */
  if (@vInputTaskId is null)
    select top 1
      @OrderDetailId  = OrderDetailId,
      @LPNToPick      = LPN,
      @LPNIdToPick    = LPNId,
      @LPNDetailId    = LPNDetailId,
      @LocToPick      = Location,
      @UnitsToPick    = UnitsToPick,
      @PickType       = case when ((UnitsToPick = LPNQuantity) and
                                   (LPNType <> 'L' /* picklane */)) then 'L' /* LPN Pick */ else 'U' /*Unit Pick*/ end,
      @TaskId         = TaskId,
      @TaskDetailId   = TaskDetailId,
      @vTaskSubType   = TaskSubType,
      @vSKUId         = SKUId
    from vwPickTasks
    where (BatchNo                = @PickBatchNo) and
          (PickTicket             = coalesce(@PickTicket, PickTicket)) and
          (DestZone = coalesce(@DestZone, DestZone)) and
          (PickGroup like @PickGroup + '%') and
          /* Exclude Pallet Picks here as we are using Batch Pallet Picking separately */
          --(TaskSubType            <> 'P' /* Pallet Pick */) and
          (coalesce(PickZone, '') = coalesce(@PickZone, PickZone, '')) and
          (UnitsToPick            > 0) and
          (((AssignedTo = @UserId) and (TaskStatus in ('I'/* Inprogress */, 'N' /* new */))) or
          ((AssignedTo is null) and (TaskStatus = 'N'/* New */))) and
          (coalesce(OnhandStatus, '') <> 'DR' /* Direct Reserved */)
    order by TaskStatus, TaskPriority, TaskDetailStatus, PickSequence, TaskDetailId;

  /* if the task is of type case pick, then we need to summarize units in that location for the
     LPN in that Task */
  if (@vTaskSubType = 'CS' /* Case Pick */)
    select @UnitsToPick = sum((coalesce(Quantity, 0) - coalesce(UnitsCompleted, 0)))
    from TaskDetails
    where (TaskId = @TaskId) and
          (LPNId  = @LPNIdToPick) and
          (SKUId  = @vSKUId);

end /* pr_Picking_FindNextTaskToPickFromBatch */

Go
