/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/07/18  TD      pr_Tasks_MarkTempLabelAsPicked:Changes to handle picks on location level.
  2014/05/29  TD      pr_Tasks_MarkTempLabelAsPicked:Changes to update FromLPN Quantity.
  2014/04/24  TD      Added pr_Tasks_MarkTempLabelAsPicked.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_MarkTempLabelAsPicked') is not null
  drop Procedure pr_Tasks_MarkTempLabelAsPicked;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_MarkTempLabelAsPicked: This procedure is used while picking a
   task when there have been temp labels generated ahead of time for the task.
   i.e. in Batch Picking, one of the options is to print the labels ahead of
   time if the users are picking cases which is called a Pick & Stick operation,
   i.e. as they pick each case, they stick the label (shipping label or whatever)
   to the case that is picked.

   We also now have the feature to let users confirm pick multiple cases at the
   same time. There could be a pick of an entire LPN which may have say 24 cases,
   there could be a Task to pick 8 cases from an LPN for different orders
   (8 different task details). In the latter scenario, user may still pick each
   individual case as well.

   This procedure is used to take the users's input and complete the pick i.e.
   mark the Temp Label as picked and if necessary reduce the inventory from
   the original LPN

  @TempLabel : The invididual TempLable that is being picked. In case user is
               confirming multiple, it could be 'All' - All temp labels associated
               with the given task, "LocationLPN" - confirm pick of all templabels
               from the LPN in the location or "TaskDetail" - confirm pick of all
               cases from the given task detail or "LPN" i.e. all from the LPN like
               in an LPN pick.

  @Operation: Currently only "Picking".

  @Status and @OnHandStatus: To be passed in if there is specific values to be used
              for updating the temp labels - else they are updated as Picked/Reserved.

  @PickingPalletId: If provided, the temp labels will be update with this PalletId
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_MarkTempLabelAsPicked
  (@TaskId           TRecordId    = null,
   @TaskDetailId     TRecordId,
   @Operation        TDescription,
   @TempLabel        TLPN      = null,
   @Status           TStatus   = null,
   @OnhandStatus     TStatus   = null,
   @PickingPalletId  TRecordId = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
As
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vPickedQty       TQuantity,
          @vFromLPNId       TRecordId,
          @vLPNSKUId        TRecordId,
          @vTempLabel       TLPN,
          @vTempLabelId     TRecordId,
          @vFromLPNDetailId TRecordId,
          @vPickBatchNo     TPickBatchNo,
          @vOrderId         TRecordId,
          @vRecordId        TRecordId,
          @vLocationId      TRecordId,
          @vPrevLPNDetailId TRecordId,
          @vTotalPickedQty  TQuantity,
          @vRowCount        TCount,
          @ttOrders         TEntityKeysTable,
          @ttLPNs           TEntityKeysTable;

  declare @ttLPNsToProcess table
          (RecordId        TRecordId identity (1,1),
           TempLabelId     TRecordId,
           TempLabel       TLPN,
           FromLPNId       TRecordId,
           FromLPNDetailId TRecordId,
           SKUId           TRecordId,
           OrderId         TRecordId,
           OrderDetailId   TRecordId,
           Quantity        TQuantity,
           Primary Key     (RecordId))
begin
  SET NOCOUNT ON;

  /* Even if there are multiple Picks being confirmed by the user, they
     are always from one LPN and same SKU and FromLocation and of course
     one PickBatch */

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vRecordId        = 0,
         @vTotalPickedQty  = 0,
         @vPrevLPNDetailId = null,
         @vTempLabel       = @TempLabel;

  if (@TempLabel is null)
    select @vMessageName = 'NoTempLabelToConfirmPick';

  /* assumption: all other validations are handled by caller procedure */
  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get total quantity and LPNId here from task details for the given TaskdetailId.
     All these values are the same for all task details that would be confirmed, so
     retrieving from one of the task details does not matter */
  select @vFromLPNId   = LPNId,
         @vLPNSKUId    = SKUId,
         @vPickBatchNo = BatchNo,
         @vLocationId  = LocationId
  from vwTaskDetails
  where (TaskDetailId = @TaskDetailId);

  /*if the user scans the LPN i.e if LPN pick we will mark all the cases as picked
    if the user scans TaskDetail level we will mark all the templabels for that taskdetail
     as picked
    if the user scans Location then we need to mark all the labels as picked for that
      location  */
  if (@TempLabel <> 'TaskDetail')
    set @TaskDetailId = null;

  /* TempLabel could be the specific LPN or one of the option literal value,
    if the templabel is not a user scanned LPN then clear the TempLabel */
  if (@TempLabel in ('TaskDetail', 'LPN', 'LocationLPN'))
    set @vTempLabel = null;

  /* Get all the Temp labels which need to be confirmed as picked and their associated info */
  insert into @ttLPNsToProcess(TempLabelId, TempLabel, FromLPNId, FromLPNDetailId,
                              SKUId, OrderId, OrderDetailId, Quantity)
    select LT.LPNId, LT.LPN, TD.LPNId, TD.LPNDetailId, TD.SKUId,
           TD.OrderId, TD.OrderDetailId, LT.Quantity
    from vwLPNTasks LT
    join Taskdetails  TD on (LT.TaskDetailId = TD.TaskDetailId)
    where (TD.TaskId     = @TaskId) and
          (TD.LocationId = @vLocationId) and
          (TD.SKUId      = @vLPNSKUId) and
          (TD.LPNId      = @vFromLPNId) and
          (LT.Status     = 'F' /* temp label */) and
          ((@TaskDetailId is null) or (TD.TaskDetailId = @TaskDetailId)) and
          ((@vTempLabel is null) or (LT.LPN = @vTempLabel)) and
          (LT.BusinessUnit = @BusinessUnit)
    order by TD.LPNDetailId;

  select @vRowCount  = @@rowcount;

  if (@vRowCount = 0)
    goto ExitHandler;

  /* Unless specific values have been givne, ste the Status/OnhandStatus */
  if ((@Operation = 'Picking') and (@Status is null))
    select @Status       = 'K' /* Picked */,
           @OnhandStatus = 'R' /* Reserved */;

  if (@Operation = 'Picking')
    begin
      /* Load all the Orders into temp table for recount*/
      insert into @ttOrders(EntityId)
        select distinct OrderId
        from @ttLPNsToProcess;

      /* Loop thru all the templabels here to update them as picked and send data
         to sorter and router as needed */
      while (exists (select *
                     from @ttLPNsToProcess where RecordId > @vRecordId))
        begin
          select top 1 @vRecordId        = RecordId,
                       @vPickedQty       = Quantity,
                       @vFromLPNId       = FromLPNId,
                       @vFromLPNDetailId = FromLPNDetailId,
                       @vLPNSKUId        = SKUId,
                       @vOrderId         = OrderId,
                       @vTempLabelId     = TempLabelId
          from @ttLPNsToProcess
          where (RecordId > @vRecordId)
          order by RecordId;

          /* Do everything that needs to be done once a Temp Label has been picked */
          exec pr_Picking_OnPicked @vPickBatchNo, @vOrderId, @PickingPalletId,
                                   @vTempLabelId, null /* pickType */, @Status,
                                   null /* UnitsPicked */, null /* TaskDetailId */, 'UnitPick',
                                   @BusinessUnit, @UserId;

          /* If we have come across a new FromLPNDetail, then process the previous one and
              and reduce the total picked Qty. This is to just unnecessary updates when confirming
              multiple picks from the same LPNDetail
           case 2 - When there is only one pick to confirm we need to do this as well
           case 3 - We need to do this on the last FromLPNDetail as well
           both Case 2/3 are satisfied with the condition RecordId = RowCount */
          if (@vFromLPNDetailId <> @vPrevLPNDetailId)
            begin
              /* Adjust the From detail down by the picked quantity */
              exec @vReturnCode = pr_LPNs_AdjustQty @vFromLPNId,
                                                    @vPrevLPNDetailId output,
                                                    @vLPNSKUId,
                                                    null,
                                                    null,
                                                    @vTotalPickedQty,   /* Quantity to Adjust */
                                                    '-', /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty */
                                                    'N',
                                                    0    /* Reason Code */,
                                                    null /* Reference */,
                                                    @BusinessUnit,
                                                    @UserId;

              select @vTotalPickedQty = @vPickedQty;
            end
            /* If it is the same LPNDetail as before, accumulate the picked Qty */
            if (@vPrevLPNDetailId = @vFromLPNDetailId) or (@vPrevLPNDetailId is null)
              select @vTotalPickedQty += @vPickedQty

          /* Assign here with FromLPNDetailId  */
          select @vPrevLPNDetailId = @vFromLPNDetailId;
        end /* End of while loop */

      /* Adjust the From detail down by the picked quantity the last line */
      exec @vReturnCode = pr_LPNs_AdjustQty @vFromLPNId,
                                            @vPrevLPNDetailId output,
                                            @vLPNSKUId,
                                            null,
                                            null,
                                            @vTotalPickedQty,   /* Quantity to Adjust */
                                            '-', /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty */
                                            'N',
                                            0    /* Reason Code */,
                                            null /* Reference */,
                                            @BusinessUnit,
                                            @UserId;

      /* Recalc the counts on all the Orders that were processed */
      exec pr_OrderHeaders_Recalculate @ttOrders, 'C' /* Recount */, @UserId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_MarkTempLabelAsPicked */

Go
