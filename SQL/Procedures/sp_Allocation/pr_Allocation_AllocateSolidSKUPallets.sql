/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/12/01  VM      Mixed SKU Pallet Allocation changes (FB-826)
                        pr_Allocation_AllocatePallets => pr_Allocation_AllocateSolidSKUPallets.
                        pr_Allocation_AllocateWave: Changes due to modified rule name and newly added rule.
                        pr_Allocation_CreatePalletPick: Introduced.
                        pr_Allocation_AllocateMixedSKUPallets: Introduced.
                        fn_PickBatches_GetOrderDetailsToAllocate: Return Warehouse as well.
                        pr_Allocation_FindAllocablePallets: Introduced.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateSolidSKUPallets') is not null
  drop Procedure pr_Allocation_AllocateSolidSKUPallets;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateSolidSKUPallets:
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateSolidSKUPallets
  (@WaveId         TRecordId,
   @WaveNo         TPickBatchNo = null,
   @PickTicket     TPickTicket  = null,
   @Operation      TOperation   = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @Debug          TFlags = 'N' /* No */)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,

          @vWaveId          TRecordId,
          @vWaveNo          TPickBatchNo,
          @vWaveStatus      TStatus,
          @vWaveType        TTypeCode,
          @vWaveWarehouse   TWarehouse,
          @vOrderId         TRecordId,
          @vTaskId          TRecordId,
          @vPickTicket      TPickTicket,
          @vSKUId           TRecordId,
          @vOwnership       TOwnership,
          @vPalletId        TRecordId,
          @vPallet          TPallet,
          @vUnitsToAllocate TQuantity,
          @PalletAllocated  TFlag,
          @vPalletQuantity  TQuantity,
          @vDetailCount     TInteger,
          @vReleaseTasks    TFlag,
          @Message          TMessage;

  declare @ttOrderDetailsToAllocate TOrderDetailsToAllocateTable,
          @ttTasksCreated           TEntityKeysTable;

  declare @ttOrderDetails Table
          (SKUId             TRecordId,
           Ownership         TOwnership,
           UnitsToAllocate   TQuantity);

  declare @ttPallets Table
          (PalletId          TRecordId,
           Pallet            TPallet,
           SKUId             TRecordId,
           SKU               TSKU,
           Ownership         TOwnership,
           Quantity          TQuantity);

begin /* pr_Allocation_AllocateSolidSKUPallets */
  select @vReturnCode     = 0,
         @vMessageName    = null;

  /* Get the Pick Batch Details */
  select @vWaveId        = RecordId,
         @vWaveNo        = BatchNo,
         @vWaveStatus    = Status,
         @vWaveType      = BatchType,
         @vWaveWarehouse = Warehouse
  from PickBatches
  where (RecordId = @WaveId) or
        (BatchNo  = @WaveNo);

  /* Get Order Details  */
  select @vOrderId    = OrderId,
         @vPickTicket = PickTicket
  from OrderHeaders
  where (PickTicket   = @PickTicket  ) and
        (BusinessUnit = @BusinessUnit);

  /* Get default Task status from controls here */
  select @vReleaseTasks = dbo.fn_Controls_GetAsBoolean('Tasks', 'AutoReleaseTasks', 'N' /* No */, @BusinessUnit, null /* UserId */);

  /* Get all the details for the batch which need to be allocated into the temp table
     Reduce the UnitsToAllocate so that it is in multiples of innerpacks */
  insert into @ttOrderDetailsToAllocate
    select * from dbo.fn_PickBatches_GetOrderDetailsToAllocate(@vWaveId, @vWaveType, null, @Operation)
    where (@vOrderId is null) or (OrderId = @vOrderId);

  if (charindex('D', @Debug) > 0) select 'Allocate Pallets: OrderDetailsToAllocate', * from @ttOrderDetailsToAllocate

  /* Get the SKUs on the batch or PT that need to be allocated */
  insert into @ttOrderDetails (SKUId, Ownership, UnitsToAllocate)
    select ODA.SKUId, ODA.Ownership, sum(ODA.UnitsToAllocate)
    from @ttOrderDetailsToAllocate ODA
    group by ODA.SKUId, ODA.Ownership;

  /* begin Loop */
  while (exists(select * from @ttOrderDetails))
    begin
      /* Clear the variables */
      select @vSKUId           = null,
             @vUnitsToAllocate = null;

      /* Find the next SKU to allocate pallets for */
      select top 1 @vSKUId           = SKUId,
                   @vOwnership       = Ownership,
                   @vUnitsToAllocate = UnitsToAllocate
      from @ttOrderDetails
      order by SKUId;

      /* Clear temp table */
      delete from @ttPallets;

      /* Find the pallets of the SKU that are potential candidates for allocation */
      insert into @ttPallets (PalletId, Pallet, SKUId, SKU, Ownership, Quantity)
        select PalletId, Pallet, SKUId, SKU, Ownership, Quantity
        from vwPallets
        where (Status   = 'P' /* Putaway */) and
              (LocationType in ('R' /* Reserve */, 'B' /* Bulk */)) and
              (SKUId    = @vSKUId) and
              (Quantity <= @vUnitsToAllocate) and
              (Ownership = @vOwnership) and
              (Warehouse = @vWaveWarehouse);

      if (charindex('D', @Debug) > 0) select 'Allocate Pallets: Potential Pallet', * from @ttPallets;

      /* begin Loop on Pallets */
      while (exists (select * from @ttPallets))
        begin
          /* Clear the variables */
          select @vPallet         = null,
                 @vPalletId       = null,
                 @vPalletQuantity = 0;

          /* select Top 1 Pallet which has the Ordered SKUId and the Ordered Qty */
          select top 1 @vPallet         = Pallet,
                       @vPalletId       = PalletId,
                       @vSKUId          = SKUId,
                       @vPalletQuantity = Quantity
          from @ttPallets
          where (Quantity  <= @vUnitsToAllocate) and
                (SKUId      = @vSKUId) and
                (Ownership  = @vOwnership)
          order by Quantity desc, PalletId;

          /* If there are no more Pallets to allocate, then break so that the
             next SKU can be processed */
          if (@vPallet is null)
            break;

          /* Try to allocate the found pallet */
          exec pr_Allocation_IsPalletAllocable @vWaveId,
                                               @vOrderId,
                                               @ttOrderDetailsToAllocate,
                                               @vPalletId,
                                               @BusinessUnit,
                                               @PalletAllocated output;

          /* If the pallet was allocated, then reduce the unitstoallocate and
             attempt another pallet */
          if (@PalletAllocated = 'Y')
            begin
              /* Create Task for Allocated Pallet */
              insert into Tasks(TaskType, TaskSubType, Status, BatchNo, PalletId, PickZone,
                                Warehouse, IsTaskAllocated, BusinessUnit, CreatedBy)
                select 'PB'/* Picking */, 'P'/* PalletPick */, 'O'/* Status */, @vWaveNo, @vPalletId, PickingZone,
                       Warehouse, 'Y'/* IsTaskAllocated */, @BusinessUnit, coalesce(@UserId, System_User)
                from vwPallets
                where (PalletId = @vPalletId);

              set @vTaskId = SCOPE_IDENTITY();

              /* Update Task Details */
              insert into TaskDetails(TaskId, Status, OrderId, PalletId, SKUId, LocationId,
                                      InnerPacks, Quantity, BusinessUnit, CreatedBy)
                select @vTaskId, 'O'/* OnHold */, OrderId, PalletId, SKUId, LocationId,
                       InnerPacks, Quantity, BusinessUnit, @UserId
                from vwPallets
                where (PalletId = @vPalletId);

              set @vDetailCount = @@rowcount;

              /* Update the counts, status of the Task Header */
              exec pr_Tasks_SetStatus @vTaskId, @UserId, null, 'Y' /* Recount */;

              /* Get the created tasks into a Temp Table */
              if not exists (select * from @ttTasksCreated where EntityId = @vTaskId)
                insert into @ttTasksCreated(EntityId)
                  select @vTaskId;

              /* Update Counts on the PickBatch */
              update PickBatches
              set NumPicks = NumPicks + @vDetailCount
              where (RecordId = @vWaveId);

              /* Re-compute Units to Allocate */
              set @vUnitsToAllocate -= @vPalletQuantity;
            end

          /* delete the Pallet from temp table after it is processed */
          delete from @ttPallets
          where (Pallet = @vPallet);
        end

      /* delete the SKU from temp table after it is processed */
      delete from @ttOrderDetails
      where (@vSKUId = SKUId);
    end

  /* Release created tasks based on the control variable */
  if (@vReleaseTasks = 'Y' /* Yes */)
    exec pr_Tasks_Release @ttTasksCreated, null /* TaskId */ , null /* Batch No */, default /* Force Release */,
                          @BusinessUnit, @UserId, @Message output;

  /* For all the Pallets allocated, create the pick tasks */
  --exec pr_PickBatch_CreatePickTasks @vPickBatchId, @ttTaskInfoTable, 'AP' /* AllocatePallet */, @vWarehouse, @vBusinessUnit, @vUserId;

ErrorHandler:
  exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateSolidSKUPallets */

Go
