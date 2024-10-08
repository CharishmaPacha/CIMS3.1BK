/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/03  PK      pr_Allocation_AllocateFromDynamicPicklanes: Fix to consider Order Ownership instead of SKU Ownership.
  2018/10/25  TK      pr_Allocation_AllocateLPN: Changed procedure signature to accept TaskDetailId
                      pr_Allocation_AllocateFromDynamicPicklanes & pr_Allocation_AllocateLPNToOrders:
                        Changes to Allocation_AllocateLPN proc signature (S2GCA-390)
  2018/10/05  VM      pr_Allocation_AllocateFromDynamicPicklanes: Transaction commit for each Task (S2GCA-353)
  2018/10/05  TK      pr_Allocation_AllocateFromDynamicPicklanes: Bug fix - allocation going infinite loop (S2GCA-GoLive)
  2018/09/17  TK      pr_Allocation_AllocateFromDynamicPicklanes: Changes not to allocate inventory irrespective of LPN and Order detail Lot (S2GCA-219)
  2018/08/22  TK      pr_Allocation_AllocateFromDynamicPicklanes: Use Allocation Rules while allocation inventory (S2GCA-183)
  2018/08/09  TK      pr_Allocation_AllocateFromDynamicPicklanes: Several fixes (S2GCA-Support)
  2018/07/02  TK      pr_Allocation_GeneratePseudoPicks: Changes to defer cubing
                      pr_Allocation_AllocateFromDynamicPicklanes: Initial Revision
                      pr_Allocation_AllocateLPNToOrders: Changes to allocate only required cases and
                        allocate Units for Dynamic Replenishments (S2GCA-66)
                      pr_Allocation_AllocateWave: Changes to Replenish dynamic Locations (S2GCA-63)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateFromDynamicPicklanes') is not null
  drop Procedure pr_Allocation_AllocateFromDynamicPicklanes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateFromDynamicPicklanes: This procedure allocates inventory for Pseudo Picks
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateFromDynamicPicklanes
  (@WaveId       TRecordId,
   @Operation    TOperation,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TDescription,
          @vDebug              TFlag,
          @vActivityLogId      TRecordId,
          @vxmlData            TXML,

          @vTranCount          TCount,
          @vTaskRecordId       TRecordId,
          @vTDRecordId         TRecordId,
          @vALRecordId         TRecordId,

          @vWaveId             TRecordId,
          @vWaveNo             TWaveNo,
          @vWaveType           TTypeCode,
          @vWaveWH             TTypeCode,

          @vTaskId             TRecordId,
          @vTaskStatus         TStatus,
          @vTaskDetailId       TRecordId,
          @vNewTaskDetailId    TRecordId,
          @vOrderId            TRecordId,
          @vOrderDetailId      TRecordId,
          @vLPNId              TRecordId,
          @vLPNDetailId        TRecordId,
          @vLocationId         TRecordId,
          @vSKUId              TRecordId,
          @vTDQuantity         TQuantity,
          @vUnitsToAllocate    TQuantity,
          @vLPNAllocableQty    TQuantity,
          @vODLot              TLot,
          @vTDKeyValue         TDescription,
          @vControlCategory    TCategory,
          @vLinesNotAllocated  TInteger;

  declare @ttTasksToAllocate   TEntityKeysTable,
          @ttAllocationrules   TAllocationRulesTable;

  declare @ttTaskDetailsToAllocate  table (TaskId            TRecordId,
                                           TaskDetailId      TRecordId,
                                           OrderId           TRecordId,
                                           OrderDetailId     TRecordId,
                                           SKUId             TRecordId,
                                           ODLot             TLot,
                                           UnitsToAllocate   TQuantity,

                                           KeyValue          TDescription,
                                           Ownership         TOwnership,
                                           Warehouse         TWarehouse,

                                           RecordId          TRecordId identity(1,1));

  declare @ttAllocableLPNs  table (LPNId           TRecordId,
                                   LPNDetailId     TRecordId,
                                   SKUId           TRecordId,
                                   LocationId      TRecordId,
                                   AllocableQty    TQuantity,

                                   KeyValue        TDescription,

                                   RecordId        TRecordId identity(1, 1));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vTaskRecordId = 0,
         @vTranCount    = @@trancount;

  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  /* Get Wave info */
  select @vWaveId          = RecordId,
         @vWaveNo          = BatchNo,
         @vWaveType        = BatchType,
         @vControlCategory = 'PickBatch_' + BatchType,
         @vWaveWH          = Warehouse
  from PickBatches
  where (RecordId = @WaveId);

  /* insert Allocation rules into temp table here */
  insert into @ttAllocationRules
    select * from dbo.fn_Allocation_GetAllocationRules(@vWaveType, @Operation, @vWaveWH, @BusinessUnit)
    order by RuleGroup, SearchOrder;

  /* Get all the tasks to be allocated */
  insert into @ttTasksToAllocate(EntityId)
    select TaskId
    from Tasks
    where (WaveId = @vWaveId) and
          (IsTaskAllocated = 'N'/* No */) and
          (Status not in ('X', 'C'/* Canceled, Completed */));

  /* Loop thru each task and allocate inventory */
  while exists (select * from @ttTasksToAllocate where (RecordId > @vTaskRecordId))
    begin
      begin transaction -- begin...commit for each task

      select top 1 @vTaskRecordId = RecordId,
                   @vTaskId       = EntityId
      from @ttTasksToAllocate
      where (RecordId > @vTaskRecordId)
      order by RecordId;

      /* Initialize */
      set @vTDRecordId = 0;
      delete from @ttTaskDetailsToAllocate;
      delete from @ttAllocableLPNs;

      /* Log TaskDetails info - before allocation */
      if (charindex('L', @vDebug) > 0)   /* Log activity log */
        exec pr_ActivityLog_Task @Operation, @vTaskId, default /* TaskKeys */, default /* Entity */, @@ProcId,
                                 'Before', default /* DeviceId */, @BusinessUnit, @UserId;

      /* Get all the task details to be allocated */
      insert into @ttTaskDetailsToAllocate(TaskId, TaskDetailId, OrderId, OrderDetailId, SKUId, UnitsToAllocate,
                                           ODLot, Ownership, Warehouse, KeyValue)
        select TD.TaskId, TD.TaskDetailId, TD.OrderId, TD.OrderDetailId, TD.SKUId, TD.UnitsToPick,
               coalesce(OD.Lot, @vWaveNo), OH.Ownership, @vWaveWH, cast(TD.SKUId as varchar) + coalesce(OD.Lot, @vWaveNo) + @vWaveWH + OH.Ownership /* KeyValue */
        from TaskDetails TD
          join OrderDetails OD on (TD.OrderDetailId = OD.OrderDetailId)
          join OrderHeaders OH on (OD.OrderId       = OH.OrderId)
        where (TD.TaskId = @vTaskId) and
              (TD.UnitsToPick > 0) and
              (TD.Status not in ('X', 'C'/* Canceled, Completed */));

      /* Get the allocable LPNs matching Lot
         There may be different task details for same SKU which results in retuning LPN multiple times, get the distinct of them */
      insert into @ttAllocableLPNs(LPNId, LPNDetailId, SKUId, LocationId, AllocableQty, KeyValue)
        select distinct LOI.LPNId, LOI.LPNDetailId, LOI.SKUId, LOI.LocationId, LOI.AllocableQuantity,
                        cast(ttTDA.SKUId as varchar) + coalesce(ttTDA.ODLot, @vWaveNo) + ttTDA.Warehouse + ttTDA.Ownership /* KeyValue */
        from vwLPNOnhandInventory LOI
          join @ttTaskDetailsToAllocate ttTDA on (LOI.SKUId     = ttTDA.SKUId) and
                                                 (coalesce(LOI.Lot, '')  = coalesce(ttTDA.ODLot, '')) and -- consider LPNs only matching Lot
                                                 (LOI.Ownership = ttTDA.Ownership) and
                                                 (LOI.Warehouse = ttTDA.Warehouse)
          join @ttAllocationRules       ttAR  on (coalesce(LOI.LocationType, '') = coalesce(ttAR.LocationType,  LOI.LocationType, '')) and
                                                 (coalesce(LOI.StorageType,  '') = coalesce(ttAR.StorageType,   LOI.StorageType,  '')) and
                                                 (coalesce(LOI.PickingClass, '') = coalesce(ttAR.PickingClass,  LOI.PickingClass, '')) and
                                                 (coalesce(LOI.PickingZone,  '') = coalesce(ttAR.PickingZone,   LOI.PickingZone,  ''))
        where (LOI.AllocableQuantity > 0);

      /* We cannot allocate tasks partially, so check whether we have enough inventory to allocate whole task
         if we don't have enough inventory then skip current task and continue with next task */
      --if exists(select ttTDA.SKUId, ttTDA.Ownership, ttTDA.Warehouse
      --          from @ttTaskDetailsToAllocate ttTDA
      --            left outer join @ttAllocableLPNs ttLA on (ttTDA.KeyValue = ttLA.KeyValue)
      --          group by ttTDA.SKUId, ttTDA.Ownership, ttTDA.Warehouse
      --          having sum(UnitsToAllocate) > sum(AllocableQty))
      --  continue;

      /* Loop thru each task detail and allocate inventory */
      while exists(select * from @ttTaskDetailsToAllocate where RecordId > @vTDRecordId)
        begin
          select top 1 @vTDRecordId    = RecordId,
                       @vTaskId        = TaskId,
                       @vTaskDetailId  = TaskDetailId,
                       @vOrderId       = OrderId,
                       @vOrderDetailId = OrderDetailId,
                       @vSKUId         = SKUId,
                       @vTDQuantity    = UnitsToAllocate,
                       @vTDKeyValue    = KeyValue
          from @ttTaskDetailsToAllocate
          where (RecordId > @vTDRecordId)
          order by RecordId;

          /* Initialize */
          set @vALRecordId = 0;

          /* Loop thru each LPN and allocate inventory */
          while exists(select * from @ttAllocableLPNs where RecordId > @vALRecordId and KeyValue = @vTDKeyValue and AllocableQty > 0) and
                      (@vTDQuantity > 0)
            begin
              select top 1 @vALRecordId      = RecordId,
                           @vLPNId           = LPNId,
                           @vLPNDetailId     = LPNDetailId,
                           @vLocationId      = LocationId,
                           @vLPNAllocableQty = AllocableQty
              from @ttAllocableLPNs
              where (RecordId > @vALRecordId) and
                    (KeyValue = @vTDKeyValue) and
                    (AllocableQty > 0)
              order by RecordId;

              /* Compute Qty to allocate */
              select @vUnitsToAllocate = dbo.fn_MinInt(@vLPNAllocableQty, @vTDQuantity);

              /* Please note that, inventory reservation model here is 'I' - Immediate, so if you pass in LPN Detail and UnitsToAllocate
                 system will allocate whatever is necessary from LPN Detail, ie. allocates whole detail if quantity to allocate
                 is greater that detail quantity or split detail if detail quantity is greater than quantity allocate
                 However if the quantity to allocate is greater than detail quantity then it will error out */
              exec @vReturnCode = pr_Allocation_AllocateLPN @vLPNId, @vOrderId, @vOrderDetailId, @vTaskDetailId,
                                                            @vSKUId, @vUnitsToAllocate, @UserId, @Operation,
                                                            @vLPNDetailId output;

              /* If Task detail quantity is not equal to Units allocated then split
                 task detail and update allocated information on new task detail */
              if (@vTDQuantity <> @vUnitsToAllocate)
                begin
                  /* Split Task Detail */
                  exec pr_TaskDetails_SplitDetail @vTaskDetailId, null/* Innerpacks */, @vUnitsToAllocate,
                                                  @Operation, @BusinessUnit, @UserId,
                                                  @vNewTaskDetailId output;

                  /* Update new task detail with allocated LPN info */
                  update TaskDetails
                  set LocationId  = @vLocationId,
                      LPNId       = @vLPNId,
                      LPNDetailId = @vLPNDetailId
                  where (TaskDetailId = @vNewTaskDetailId);
                end
              else
                /* Update task detail with allocated LPN info */
                update TaskDetails
                set LocationId  = @vLocationId,
                    LPNId       = @vLPNId,
                    LPNDetailId = @vLPNDetailId
                where (TaskDetailId = @vTaskDetailId);

              /* Reduce quantity from temp table */
              update @ttAllocableLPNs
              set AllocableQty -= @vUnitsToAllocate
              where (RecordId = @vALRecordId);

              /* Reduce task detail quantity */
              set @vTDQuantity -= @vUnitsToAllocate;

              /* Reset variables */
              select @vLPNDetailId = null, @vNewTaskDetailId = null;
            end /* while allocable lpns */
        end /* while Task details */

      select @vLinesNotAllocated = count(*)
      from TaskDetails
      where (TaskId = @vTaskId) and
            (LocationId is null);

      /* Mark Task as allocated */
      if (coalesce(@vLinesNotAllocated, 0) = 0)
        update Tasks
        set @vTaskStatus    = Status,
            IsTaskAllocated = 'Y'/* Yes */,
            IsTaskConfirmed = 'Y'/* Yes */
        where (TaskId = @vTaskId);

      /* Log TaskDetails info - after allocation */
      if (charindex('L', @vDebug) > 0)   /* Log activity log */
        exec pr_ActivityLog_Task @Operation, @vTaskId, default /* TaskKeys */, default /* Entity */, @@ProcId,
                                 'After', default /* DeviceId */, @BusinessUnit, @UserId;

      commit transaction
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateFromDynamicPicklanes */

Go
