/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/30  TK      pr_Tasks_MarkUnitsAsPicked: Bug fix to consider IsLabelGenerated flag instead of IsAllocated (HPI-162)
  2015/08/04  TK      pr_Tasks_MarkUnitsAsPicked: If Task is not allocated then don't consider From LPN on the TaskDetail (ACME-266)
  2015/06/12  TK      pr_Tasks_MarkUnitsAsPicked: Consider only units picked instead of all the units in the TempLabel
  2015/06/08  TD      Added new procedure pr_Tasks_MarkUnitsAsPicked.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_MarkUnitsAsPicked') is not null
  drop Procedure pr_Tasks_MarkUnitsAsPicked;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_MarkUnitsAsPicked:  This procedure is do the neccessary updates
    when units are picked against one or more task details.

  Possibilities are:
    - The Task is a Pseudo pick or the Task has already been allocated.
    - User could be confirming only one task detail or multiple. If user confirms
      all picks from the location for the task, then all task details are completed
      at once.

  Assumptions:
    - Task Details already have temp label
    - The Temp labels has unavailable lines

  updates done;
    - From LPN: If task is allocated, then reserved line is deleted
                If task was not allocated, then available line on from LPN is reduced
    - To LPN: Updated from Unavailable to Reserved

------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_MarkUnitsAsPicked
  (@TaskId           TRecordId    = null,
   @TaskDetailId     TRecordId,
   @Operation        TDescription,
   @TempLabel        TLPN      = null,
   @Status           TStatus   = null,
   @OnhandStatus     TStatus   = null,
   @FromLPNId        TRecordId,
   @UnitsPicked      TQuantity,
   @PickingPalletId  TRecordId = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
As
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vPickedQty           TQuantity,
          @vFromLPNId           TRecordId,
          @vLPNSKUId            TRecordId,
          @vPickedSKUId         TRecordId,
          @vTempLabel           TLPN,
          @vTempLabelId         TRecordId,
          @vTempLabelLineQty    TQuantity,
          @vFromLPNDetailId     TRecordId,
          @vFromLPNDetailQty    TQuantity,
          @vPickBatchNo         TPickBatchNo,
          @vOrderId             TRecordId,
          @vRecordId            TRecordId,
          @vLocationId          TRecordId,
          @vPrevLPNDetailId     TRecordId,
          @vTotalPickedQty      TQuantity,
          @vRowCount            TCount,
          @vUnPickedLines       TCount,
          @vTaskSubType         TTypeCode,
          @vIsTaskAllocated     TFlags,
          @vIsLabelGenerated    TFlags,
          @ttOrders             TEntityKeysTable,
          @ttLPNs               TEntityKeysTable;

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

  /* Get total quantity and LPNId here from task details for the given TaskdetailId.
     All these values are the same for all task details that would be confirmed, so
     retrieving from one of the task details does not matter */
  select @vFromLPNId        = LPNId,
         @vFromLPNDetailId  = LPNDetailId,
         @vPickedSKUId      = SKUId,
         @vPickBatchNo      = BatchNo,
         @vLocationId       = LocationId,
         @vIsLabelGenerated = IsLabelGenerated
  from vwTaskDetails
  where (TaskDetailId = @TaskDetailId);

  /* get task header info here */
  select @vIsTaskAllocated = IsTaskAllocated,
         @vTaskSubType     = TaskSubType
  from Tasks
  where (TaskId = @TaskId);

  /* If the Task does not have the From LPN, then use the passed in one to get the info */
  select @vFromLPNId  = case when @vIsTaskAllocated = 'Y'  then coalesce(@vFromLPNId, LPNId)
                             else LPNId
                        end,
         @vLocationId = case when @vIstaskAllocated = 'Y' then coalesce(@vLocationId, LocationId)
                             else LocationId
                        end
  from LPNs
  where (LPNId = @FromLPNId);

  /* If the TaskDetail does not have From LPNDetailId then, get the available
     line from the FromLPN */
  if (@vFromLPNDetailId is null)
    select top 1 @vFromLPNDetailId  = LPNDetailId,
                 @vFromLPNDetailQty = Quantity
    from LPNDetails
    where (LPNId =  @vFromLPNId) and
          (SKUId =  @vPickedSKUId) and
          (OnhandStatus = 'A')
    order by Quantity desc;

  /* Get ToLPNLabel Id here */
  select @vTempLabelId = LPNId
  from LPNs
  where (LPN = @TempLabel) and (BusinessUnit = @BusinessUnit);

  if (@vTempLabelId is null)
    select @vMessageName = 'NoTempLabelToConfirmPick';
  else
  if (@vIsTaskAllocated = 'N') and (@vFromLPNDetailQty < @UnitsPicked)
    select @vMessageName = 'InsufficientQtyToPick';

  /* assumption: all other validations are handled by caller procedure */
  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If the task was not allocated, then earlier it was not determined where the pick would be from
     but since user has now chosen to pick from a zone, we need to update task detail to reflect
     the From LPN, From Location and LPNDetailId */
  if (@vIsTaskAllocated = 'N')
    update Taskdetails
    set LPNId       = @vFromLPNId,
        LPNDetailId = @vFromLPNDetailId,
        LocationId  = @vLocationId
    where (TaskDetailId = @TaskDetailId);

  /* Get all the Temp labels which need to be confirmed as picked and their associated info */
  insert into @ttLPNsToProcess(TempLabelId, TempLabel, FromLPNId, FromLPNDetailId,
                              SKUId, OrderId, OrderDetailId, Quantity)
    select LT.LPNId, LT.LPN, TD.LPNId, TD.LPNDetailId, TD.SKUId,
           TD.OrderId, TD.OrderDetailId, coalesce(@UnitsPicked, LT.Quantity) /* If UnitsPicked is not given, then consider that full qty is picked */
    from vwLPNTasks LT
      join Taskdetails  TD on (LT.TaskDetailId = TD.TaskDetailId)
    where (TD.TaskId     = @TaskId) and
          (TD.LocationId = @vLocationId) and
          (TD.SKUId      = @vPickedSKUId) and
          (TD.LPNId      = @vFromLPNId) and
          (LT.Status     in ('F' /* temp label */, 'U')) and
          ((@TaskDetailId is null) or (TD.TaskDetailId = @TaskDetailId)) and
          ((@vTempLabel is null) or (LT.LPN = @vTempLabel)) and
          (LT.BusinessUnit = @BusinessUnit)
    order by TD.LPNDetailId;

  select @vRowCount  = @@rowcount;

  if (@vRowCount = 0)
    goto ExitHandler;

  /* get un picked line count to decide the ToLPN Status */
  select @vUnPickedLines = count(*)
  from LPNDetails
  where (LPNId        = @vTempLabelId) and
        (Onhandstatus = 'U') and
        (OrderDetailId is not null);

  select @vTempLabelLineQty = Quantity
  from LPNDetails
  where (LPNId        = @vTempLabelId) and
        (SKUId        = @vPickedSKUId) and
        (Onhandstatus = 'U') and
        (OrderDetailId is not null);

  /* Unless specific values have been given, set the Status/OnhandStatus */
  if (@Operation = 'Picking')
    select @Status       = case
                             when @vTempLabelLineQty > @UnitsPicked then 'U' /* Picking */
                             when (@vIsLabelGenerated = 'Y') and (@vUnPickedLines > 1) then 'U' /* Picking */
                             else coalesce(@Status, 'K' /* Picked */)
                           end,
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
                       @vPickedSKUId     = SKUId,
                       @vOrderId         = OrderId,
                       @vTempLabelId     = TempLabelId
          from @ttLPNsToProcess
          where (RecordId > @vRecordId)
          order by RecordId;

          /* Do everything that needs to be done once a Temp Label has been picked */
          exec pr_Picking_OnPicked @vPickBatchNo, @vOrderId, @PickingPalletId,
                                   @vTempLabelId, null /* pickType */, @Status,
                                   @vPickedQty /* UnitsPicked */, @TaskDetailId /* TaskDetailId */, 'UnitPick',
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
                                                    @vPickedSKUId,
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
                                            @vPickedSKUId,
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
end /* pr_Tasks_MarkUnitsAsPicked */

Go
