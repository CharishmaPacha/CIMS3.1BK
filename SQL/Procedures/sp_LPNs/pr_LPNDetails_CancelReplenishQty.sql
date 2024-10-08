/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/07/28  RV      pr_LPNDetails_CancelReplenishQty, pr_LPNDetails_Unallocate: BusinessUnit and UserId passed to activity log procedure
  2017/07/07  RV      pr_LPNDetails_CancelReplenishQty, pr_LPNDetails_Unallocate:
                        Send ProcId to pr_ActivityLog_AddMessage, pr_Markers_Log (HPI-1584)
  2017/02/20  TK      pr_LPNDetails_CancelReplenishQty: Initialize variables at the end of iteration (HPI-1345)
  2017/02/06  TK      pr_LPNDetails_CancelReplenishQty: If cancelling replenish qty is violating ship complete percentage of any order then remove it from wave (HPI-1345)
  2016/12/29  VM      pr_LPNDetails_CancelReplenishQty: Consider canceling replenish quantities until Max Qty of LPN (HPI-692)
  2016/12/28  VM      pr_LPNDetails_CancelReplenishQty: (HPI-692)
  2016/12/05  PK      pr_LPNDetails_CancelReplenishQty: Reducing quantity on the temp label for partial cancellations of replenishments (HPI-692)
              VM      pr_LPNDetails_CancelReplenishQty, pr_LPNDetails_Unallocate, pr_LPNs_UpdateOrderOnAdjust (HPI-692):
  2016/11/11  RV      pr_LPNDetails_CancelReplenishQty: If Task Detail not available to reduce the quantity against D and DR lines,
  2016/09/16  VM/AY   pr_LPNDetails_CancelReplenishQty: Cancel D line first not DR (HPI-GoLive)
              TD      pr_LPNDetails_CancelReplenishQty: Avoid previously canceled lines (HPI-GoLive)
  2016/09/12  TK      pr_LPNDetails_CancelReplenishQty: Changes to void temp labels on Task Cancel (HPI-615)
  2016/09/01  AY/RV   pr_LPNDetails_CancelReplenishQty: Fix to delete the DR line and cancel the task detail properly. (HPI-515)
  2016/08/20  TK      pr_LPNDetails_CancelReplenishQty: Bug Fix - not to reduce units assigned on order detail while we are
                      pr_LPNDetails_CancelReplenishQty: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_CancelReplenishQty') is not null
  drop Procedure pr_LPNDetails_CancelReplenishQty;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_CancelReplenishQty: When replenishment is being canceled due
    to various events (Cancel Task, Unallocate Replenishing LPN etc.), there are
    a series of updates to be done and this procedure takes care of all of those:
    1: Deletes all the Directed and Directed Reserve Lines equivalent to the
       qty being canceled.
    2: Update the corresponding replenish tasks
    3. Unallocate the qty corresponding to the Directed Reserve Line
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_CancelReplenishQty
  (@ReplenishOrderId        TRecordId,
   @ReplenishOrderDetailId  TRecordId,
   @QtyToCancel             TQuantity,
   @BusinessUnit            TBusinessUnit = null,
   @UserId                  TUserId       = null)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,

          @vMaxQtyToReduce    TQuantity,
          @vDirectedQty       TQuantity,
          @vRepQtyToReduce    TQuantity,
          @vNewTaskDetailQty  TQuantity,

          @vRecordId          TRecordId,
          @vSKUId             TRecordId,
          @vOrderId           TRecordId,
          @vOrderDetailId     TRecordId,

          @vDirectedLPNId     TRecordId,
          @vDirectedDetailId  TRecordId,

          @vDRLineOrderId     TRecordId,
          @vDRLineOrderDetailId
                              TRecordId,

          @vDRTaskId          TRecordId,
          @vDRTaskDetailId    TRecordId,

          @vTempLabelId       TRecordId,
          @vTempLabelDetailId TRecordId,
          @vTempLabelNewQty   TQuantity,

          @vDebug             TFlag,
          @vxmlData           TXML;

  declare @ttDirectedLines table (LPNId         TRecordId,
                                  LPNDetailId   TRecordId,
                                  SKUId         TRecordId,
                                  Quantity      TQuantity,
                                  OrderId       TRecordId,
                                  OrderDetailId TRecordId,

                                  RecordId     TRecordId identity(1,1));
begin
  /* Initialize variables */
  select @vMaxQtyToReduce = @QtyToCancel,
         @vRepQtyToReduce = 0,
         @vRecordId       = 0;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  /* Find the LPN Detail with the directed qty for the unallocated replenishment */
  insert into @ttDirectedLines
    select LPNId, LPNDetailId, SKUId, Quantity, OrderId, OrderDetailId
    from LPNDetails
    where (ReplenishOrderId       = @ReplenishOrderId) and
          (ReplenishOrderDetailId = @ReplenishOrderDetailId) and
          (OnHandStatus in ('D', 'DR' /* Directed, Directed Reserve */)) and
          (LPNId > 0) /* for some reason, we are getting old canceled record with - LPNid*/
    order by OnhandStatus;   -- Cancel D line first

  /*----------------------------Activity Log---------------------------------*/
  if (charindex('L', @vDebug) > 0)
    begin
      select @vxmlData = (select @ReplenishOrderId        ReplOrderId,
                                 @ReplenishOrderDetailId  ReplOrderDeatailId,
                                 @QtyToCancel             QtyToCancel
                          for XML raw('CancelReplenishQty'), elements );

      exec pr_ActivityLog_AddMessage 'LPNDetails_CancelReplenishQty', @ReplenishOrderId, null, 'PickTicket',
                                     'CancelReplenishQty_Inputs' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;

      select @vxmlData = null;
      select @vxmlData = (select * from @ttDirectedLines for XML raw('CancelReplenishQty'), elements );

      exec pr_ActivityLog_AddMessage 'LPNDetails_CancelReplenishQty', @ReplenishOrderId, null, 'PickTicket',
                                     'DirectedLines' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;
    end

  /* Loop thru all the lines and reduce their Qty. Consider MaxQtyToReduce as otherwise, there are chances of reducing quantities to negative values for some  */
  while (@vMaxQtyToReduce > 0) and
        (exists(select * from @ttDirectedLines where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId            = RecordId,
                   @vDirectedLPNId       = LPNId,
                   @vDirectedDetailId    = LPNDetailId,
                   @vSKUId               = SKUId,
                   @vDirectedQty         = Quantity,
                   @vDRLineOrderId       = OrderId,
                   @vDRLineOrderDetailId = OrderDetailId
      from @ttDirectedLines
      where (RecordId > @vRecordId)
      order by RecordId;

      select @vRepQtyToReduce = dbo.fn_MinInt(@vMaxQtyToReduce, @vDirectedQty);

      /* Reduce the Qty on D/DR line */
      exec @ReturnCode = pr_LPNs_AdjustQty @vDirectedLPNId, @vDirectedDetailId, @vSKUId, null/* SKU */,
                                           0, @vRepQtyToReduce, '-' /* Update Option  - Subtract */,
                                           'N' /* No-Export Option */, 0 /* Reason code */,
                                           null /* Reference */, @BusinessUnit, @UserId;

      /* Identify the task detail to reduce */
      select @vNewTaskDetailQty = Quantity - @vRepQtyToReduce,
             @vDRTaskId         = TaskId,
             @vDRTaskDetailId   = TaskDetailId,
             @vOrderDetailId    = OrderDetailId,
             @vOrderId          = OrderId
      from TaskDetails TD
      where (LPNDetailId = @vDirectedDetailId);

      /* In some cases we would have two LPN Details and only one TaskDetail. For example
         an R Line with 58 units and a DR line with 2 units, but TaskDetail with 60 units.
         (why that is so and to change that may be a long term goal, but this is an immediate fix)
         In this given scenario R Line and TD are related i.e. TD.LPNDetailId points to the R Line
         but there is no separate TaskDetail for the DR line.
         In the above statement, there is no task detail fetched due to this when the DR line is
         being cancelled. So, we are not trying to identify the task detail related to the R line
         to reduce qty on it.
         When the Replenish is putaway, then DR line gets merged so in normal situations it works
         out well in the end, but not when DR lines are changed */
      if (@@rowcount = 0)
        select @vNewTaskDetailQty = TD.Quantity - @vRepQtyToReduce,
               @vDRTaskId         = TaskId,
               @vDRTaskDetailId   = TD.TaskDetailId,
               @vOrderDetailId    = LD.OrderDetailId,
               @vOrderId          = LD.OrderId
        from TaskDetails TD join LPNDetails LD on (LD.LPNId = TD.LPNId)
        where (TD.LPNId         = @vDirectedLPNId) and
              (TD.OrderDetailId = @vDRLineOrderDetailId) and
              (LD.OnhandStatus  = 'R' /* Reserved */) and
              (TD.Status        = 'N' /* Ready to start */);

      /* if the TD Qty is completely reduced to zero then cancel it */
      if (@vNewTaskDetailQty = 0) and (@vDRTaskId is not null)
        exec pr_TaskDetails_Cancel @vDRTaskId, @vDRTaskDetailId, @UserId;
      else
      if (coalesce (@vDRTaskDetailId, '') <> '')
        begin
          /* Get the Temp Label DetailId and Reduce Qty on the Task detail */
          update TaskDetails
          set @vTempLabelId       = TempLabelId,
              @vTempLabelDetailId = TempLabelDetailId,
              Quantity            = @vNewTaskDetailQty
          where (TaskDetailId = @vDRTaskDetailId);

          /* Reduce Qty on the TempLabel */
          if (@vTempLabelDetailId is not null)
            begin
              /* Update Temp Label Detail line */
              update LPNDetails
              set @vTempLabelNewQty =
                  Quantity          = dbo.fn_MaxInt((Quantity - @vNewTaskDetailQty), 0)
              where (LPNId         = @vTempLabelId) and
                    (OrderDetailId = @vOrderDetailId) and
                    (LPNDetailId   = @vTempLabelDetailId);

              /* Recount Temp Label */
              exec pr_LPNs_Recount @vTempLabelId;

              /*----------------------------Activity Log---------------------------------*/
              if (charindex('L', @vDebug) > 0) and (@vTempLabelNewQty < 0)
                begin
                  select @vxmlData = null;
                  select @vxmlData = (select LPNId             LPNId,
                                             LPNDetailId       LPNDetailId,
                                             Quantity          LPNQuantity,
                                             @vTempLabelNewQty TempLabelNewQty
                                      from LPNDetails where LPNDetailId = @vTempLabelDetailId
                                      for XML raw('CancelReplenishQty'), elements );

                  exec pr_ActivityLog_AddMessage 'LPNDetails_CancelReplenishQty', @ReplenishOrderId, null, 'PickTicket',
                                                 'CancelReplenishQty_TempLabelQty' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;
                end
            end
        end

      /* Reduce Units Assigned on the Order Detail */
      update OrderDetails
      set UnitsAssigned = dbo.fn_MaxInt((UnitsAssigned - @vRepQtyToReduce), 0)
      where OrderDetailId = @vOrderDetailId;

      /* Reduce the Max Qty to be reduced */
      set @vMaxQtyToReduce -= @vRepQtyToReduce;

      /* Recount the Task */
      if (@vDRTaskId is not null)
        exec pr_Tasks_ReCount @vDRTaskId;

      /* If we are cancelling DR Qty then recount order */
      if (@vOrderId is not null)
        begin
          /* Recount the Order */
          exec pr_OrderHeaders_Recount @vOrderId;

          /* Check whether order is qualified to ship or not, if not qualified then unwave it */
          exec pr_OrderHeaders_OnDisqualifiedToShip @vOrderId, 'CancelReplenish' /* Operation */, @BusinessUnit, @UserId;

        end

      /* clear variables so that Qty won't be reduced while cancelling directed line */
      select @vNewTaskDetailQty  = 0,
             @vTempLabelDetailId = null,
             @vDRTaskId          = null,
             @vDRTaskDetailId    = null,
             @vOrderDetailId     = null,
             @vOrderId           = null;
    end

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNDetails_CancelReplenishQty */

Go
