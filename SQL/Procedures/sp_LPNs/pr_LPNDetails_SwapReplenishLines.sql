/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/15  TK      pr_LPNDetails_SwapReplenishLines: Log LPNDetails into activity log table (HPI-1676)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_SwapReplenishLines') is not null
  drop Procedure pr_LPNDetails_SwapReplenishLines;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_SwapReplenishLines: This procedure assigns directed qty of
    original Replenish Order to passed Replenish order.

  For Example: Let's say there are two Replenish Orders RO1, RO2 and two LPNs L1 and L2 are picked for Orders respectively.

    Let's say L1 & L2 are of 10 Units each then DestLocation details will be as shown below
            LPNLine  Qty    OnHandStatus   ReplenishOrder   CustomerOrder
            1        10     DR             RO1              O1
     Loc1   2        6      DR             RO2              O2
            3        4      D              RO2              -

    If user is trying to putaway L2, then we will first mark line 2 as Reserved,
    later we will split line 1 to 6 and 4 units with 4 units line as reserved.
            LPNLine  Qty    OnHandStatus   ReplenishOrder   CustomerOrder
            1        4      R              RO1              O1
     Loc1   2        6      R              RO2              O2
            3        4      D              RO2              -
            4        6      DR             RO1              O1  -- this new line is the result of splitting Line 1

    In the above scenario line 3 is an orphan line since the Inventory which has been allocated for RO2
    has been used to qualify directed qty of RO1, we need to swap Replenish Order on the lines such that
    directed qty of RO2 will be transferred to RO1 as shown below which results in deleting line 3 and creating new line 5.
            LPNLine  Qty    OnHandStatus   ReplenishOrder   CustomerOrder
            1        4      R              RO2              O1
     Loc1   2        6      R              RO2              O2
            3        4      D              RO1              -   -- Existing line will be swapped from RO2 to R01
            4        6      DR             RO1              O1  -- this new line is the result of splitting Line 1
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_SwapReplenishLines
  (@LPNId                     TRecordId,
   @SKUId                     TRecordId,
   @QtyToSwap                 TQuantity,
   @OrgReplenishOrderId       TRecordId,
   @ReplOrderIdToSwap         TRecordId,
   @ReplOrderDtlIdToSwap      TRecordId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TMessage,
          @vBusinessUnit      TBusinessUnit,
          @vUserId            TUserId,
          @vLDActivityLogId   TRecordId,

          @vLPNId             TRecordId,
          @vLPNDetailToSwap   TRecordId,
          @vTargetDetailId    TRecordId,
          @vNewLPNDetailId    TRecordId,
          @vDtlQty            TQuantity,
          @vOnhandStatus      TStatus;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vMessage     = 'RepOrderId: ' + cast(coalesce(@OrgReplenishOrderId, '0') as varchar) + ', RepOrderIdToSwap: ' + cast(coalesce(@ReplOrderIdToSwap, '0') as varchar)  +', Qty: ' + cast(@QtyToSwap as varchar);;

  /* Start log of LPN Details into activitylog */
  exec pr_ActivityLog_LPN 'LD_SwapReplenishLines_LPNDetails_Start', @LPNId, @vMessage, @@ProcId,
                          null, @vBusinessUnit, @vUserId, @vLDActivityLogId output;

  /* Get the details of LPN detail to be processed */
  select @vLPNDetailToSwap = LPNDetailId,
         @vDtlQty          = Quantity,
         @vOnHandStatus    = OnHandStatus
  from LPNDetails
  where (LPNId            = @LPNId              ) and
        (SKUId            = @SKUId              ) and
        (OnhandStatus     = 'D'/* Directed */   ) and
        (ReplenishOrderId = @OrgReplenishOrderId);

  /* Return if there is no LPN detail to swap */
  if (@@rowcount = 0) return;

  /* Check if there is an LPN detail to update Qty */
  select @vTargetDetailId = LPNDetailId
  from LPNDetails
  where (OnhandStatus           = 'D'/* Directed */    ) and
        (ReplenishOrderId       = @ReplOrderIdToSwap   ) and
        (ReplenishOrderDetailId = @ReplOrderDtlIdToSwap);

  /* If there is a line to update then just update the Qty and delete the original Line */
  if (coalesce(@vTargetDetailId, 0) > 0)  /* ** this block will delete line 1 */
    begin
      update LPNDetails
      set Quantity = Quantity + @QtyToSwap
      where (LPNDetailId = @vTargetDetailId);

      /* QtyToSwap is less than LPN Detail qty then reduce the Qty else delete the original Detail */
      if (@QtyToSwap < @vDtlQty)
        update LPNDetails
        set Quantity = Quantity - @QtyToSwap
        where (LPNDetailId = @vLPNDetailToSwap);
      else
        /* delete original line */
        exec pr_LPNDetails_Delete @vLPNDetailToSwap;
    end
  else
  /* If Qty to swap is greater than LPN detail Qty, then just update Replenish Order and Order Detail Ids */
  if (@QtyToSwap >= @vDtlQty) /* **this block will update line 3 in the example from R02 to R01 */
    update LPNDetails
    set ReplenishOrderId       = @ReplOrderIdToSwap,
        ReplenishOrderDetailId = @ReplOrderDtlIdToSwap
    where (LPNDetailId = @vLPNDetailToSwap);
  else
  /* If Qty to swap is less than LPN Detail Qty, then split original line with Qty to swap */
  if (@QtyToSwap < @vDtlQty)  /* **this block will split line 3 */
    begin
      /* split line with Qty to swap */
      exec pr_LPNDetails_SplitLine @vLPNDetailToSwap,
                                   0 /* Innerpacks */,
                                   @QtyToSwap,
                                   null/* OrderId */,
                                   null/* OrderDetailId */,
                                   @vNewLPNDetailId output;

      /* Update Replenish Order info on the newly created line */
      update LPNDetails
      set OnHandStatus           = 'D'/* Directed */,
          ReplenishOrderId       = @ReplOrderIdToSwap,
          ReplenishOrderDetailId = @ReplOrderDtlIdToSwap
      where (LPNDetailId = @vNewLPNDetailId);
    end

  /* Start log of LPN Details into activitylog */
  exec pr_ActivityLog_LPN 'LD_SwapReplenishLines_LPNDetails_End', @LPNId, @vMessage, @@ProcId,
                          null, @vBusinessUnit, @vUserId, @vLDActivityLogId output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_SwapReplenishLines */

Go
