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

if object_id('dbo.pr_Allocation_CreatePalletPick') is not null
  drop Procedure pr_Allocation_CreatePalletPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_CreatePalletPick: This procedure is used to create pick tasks...
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_CreatePalletPick
  (@PalletId       TRecordId,
   @WaveNo         TPickBatchNo,
   @Operation      TOperation = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @Debug          TFlags = 'N' /* No */)
as
  declare @vReleaseTasks    TFlag,
          @vTaskId          TRecordId,
          @vDetailCount     TInteger,
          @vRecordId        TRecordId,

          @vReturnCode      TInteger,
          @vMessage         TMessage,

          @ttTasksCreated   TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* ------------------------------------------------------------------------*/
  /* Initialize variables */
  /* ------------------------------------------------------------------------*/
  select @vReturnCode  = 0,
         @vRecordId    = 0;

  /* ------------------------------------------------------------------------*/
  /* Get Control variables */
  /* ------------------------------------------------------------------------*/
  select @vReleaseTasks = dbo.fn_Controls_GetAsBoolean('Tasks', 'AutoReleaseTasks', 'N' /* No */, @BusinessUnit, @UserId);

  /* ------------------------------------------------------------------------*/
  /* Create Task for Allocated Pallet */
  /* ------------------------------------------------------------------------*/
  insert into Tasks(TaskType, TaskSubType, Status, BatchNo, PalletId, PickZone,
                    Warehouse, IsTaskAllocated, BusinessUnit, CreatedBy)
    select 'PB'/* Picking */, 'P'/* PalletPick */, 'O'/* Status */, @WaveNo, @PalletId, PickingZone,
           Warehouse, 'Y'/* IsTaskAllocated */, @BusinessUnit, coalesce(@UserId, System_User)
    from vwPallets
    where (PalletId = @PalletId);

  set @vTaskId = SCOPE_IDENTITY();

  /* ------------------------------------------------------------------------*/
  /* Create Task Details */
  /* ------------------------------------------------------------------------*/
  insert into TaskDetails(TaskId, Status, OrderId, PalletId, SKUId, LocationId,
                          InnerPacks, Quantity, BusinessUnit, CreatedBy)
    select @vTaskId, 'O'/* OnHold */, OrderId, PalletId, SKUId, LocationId,
           InnerPacks, Quantity, BusinessUnit, @UserId
    from vwPallets
    where (PalletId = @PalletId);

  set @vDetailCount = @@rowcount;

  /* ------------------------------------------------------------------------*/
  /* Update counts & statuses */
  /* ------------------------------------------------------------------------*/

  /* Update counts, status of the Task Header */
  exec pr_Tasks_SetStatus @vTaskId, @UserId, null, 'Y' /* Recount */;

  /* Get the created tasks into a Temp Table */
  if not exists (select * from @ttTasksCreated where EntityId = @vTaskId)
    insert into @ttTasksCreated(EntityId)
      select @vTaskId;

  /* Update Counts on the PickBatch */
  update PickBatches
  set NumPicks = NumPicks + @vDetailCount
  where (BatchNo = @WaveNo);

  /* ------------------------------------------------------------------------*/
  /* Release created tasks based on the control variable */
  /* ------------------------------------------------------------------------*/
  if (@vReleaseTasks = 'Y' /* Yes */)
    exec pr_Tasks_Release @ttTasksCreated, null /* TaskId */ , null /* Batch No */, default /* Force Release */,
                          @BusinessUnit, @UserId, @vMessage output;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_CreatePalletPick */

Go
