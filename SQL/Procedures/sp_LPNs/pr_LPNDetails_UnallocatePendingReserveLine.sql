/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/16  TK      pr_LPNDetails_UnallocatePendingReserveLine: Changes to update counts on LPN before evaluating dependencies (S2G-342)
                      pr_LPNDetails_UnallocatePendingReserveLine: Changes to recompute Task Dependencies when a PR line is cancelled
  2018/02/24  TK      pr_LPNDetails_UnallocatePendingReserveLine: bug fix to delete PR line (S2G-151)
                      pr_LPNDetails_UnallocatePendingReserveLine: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_UnallocatePendingReserveLine') is not null
  drop Procedure pr_LPNDetails_UnallocatePendingReserveLine;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_UnallocatePendingReserveLine: This procedure takes care of
    the required updates when a PR line is unallocated:
    a. Reduces the Qty of the PR line from the Reserved Qty of a Directed Line or
       Available line in the LPN. It first reduces as much as it can to directed line
       and then remaining from an Available line
   b. Deletes the PR Line
   c. Deletes any A/R lines if Qty & ReservedQty are both zero.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_UnallocatePendingReserveLine
  (@LPNDetailId      TRecordId,
   @UserId           TUserId,
   @Operation        TOperation = null)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vBusinessUnit       TBusinessUnit,
          @vRLRecordId         TRecordId,

          @vLPNId              TRecordId,
          @vLPNStatus          TStatus,
          @vLPNQuantity        TQuantity,

          @vPRLPNDetailId      TRecordId,
          @vRLLPNDetailId      TRecordId,
          @vLPNDetailLot       TLot,
          @vQtyToUnallocate    TQuantity,
          @vQtyUnallocated     TQuantity,
          @vOnhandStatus       TStatus,

          @vSKUId              TRecordId,
          @vOrderId            TRecordId,
          @vOrderDetailId      TRecordId,
          @vMergeLPNDetailId   TRecordId;

  declare @ttLPNDetails       table (LPNId          TRecordId,
                                     LPNDetailId    TRecordId,
                                     LPNLine        TDetailLine,
                                     OnHandStatus   TStatus,
                                     Quantity       TQuantity,
                                     ReservedQty    TQuantity,

                                     ProcessedFlag  TFlag   default 'N',

                                     RecordId       TRecordId identity(1,1));
begin
  SET NOCOUNT ON;

  /* Fetch the details of the PR LPN Detail */
  select @vPRLPNDetailId   = LPNDetailId,
         @vLPNId           = LPNId,
         @vQtyToUnallocate = Quantity
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Get LPN info */
  select @vLPNStatus   = Status,
         @vLPNQuantity = Quantity
  from LPNs
  where (LPNId = @vLPNId);

  /* Get all the Available/Directed LPN Details to process */
  insert into @ttLPNDetails(LPNId, LPNDetailId, LPNLine, OnHandStatus, Quantity, ReservedQty)
    select LPNId, LPNDetailId, LPNLine, OnHandStatus, Quantity, ReservedQty
    from LPNDetails
    where (LPNId = @vLPNId) and
          (OnHandStatus in ('A', 'D'/* Avail., Directed */))
    order by OnHandStatus desc, LPNLine desc; -- Process Directed lines first

  set @vRLRecordId = 0;

  /* Loop thru each line and reduce reserved quantity until we exhaust reserved quantity to be unallocated.
     Deduct reserved quantity from directed lines first and then from Available line */
  while (@vQtyToUnallocate > 0) and
        (exists (select *
                 from @ttLPNDetails
                 where (RecordId > @vRLRecordId)))
    begin
      select top 1 @vRLRecordId    = RecordId,
                   @vRLLPNDetailId = LPNDetailId
      from @ttLPNDetails
      where (RecordId > @vRLRecordId)
      order by RecordId;

      /* Reduce Reserved Qty */
      update @ttLPNDetails
      set @vQtyUnallocated = dbo.fn_MinInt(ReservedQty, @vQtyToUnallocate),
          ReservedQty     -= dbo.fn_MinInt(ReservedQty, @vQtyToUnallocate),
          ProcessedFlag    = 'Y'/* Yes */
      where (LPNDetailId = @vRLLPNDetailId);

      /* Reduce from the total quantity that needs to be unallocated */
      select @vQtyToUnallocate -= @vQtyUnallocated;
    end

  /* Update reserved quantities on Available/Directed lines */
  update LD
  set LD.ReservedQty = ttLD.ReservedQty
  from LPNDetails LD
    join @ttLPNDetails ttLD on (LD.LPNDetailId = ttLD.LPNDetailId)
  where (ProcessedFlag = 'Y'/* Yes */);

  /* Need to recount the LPN and recalc all relevant tasks as there is less reserved qty now */

  /* Delete unallocated PR line */
  delete LD
  from LPNDetails LD
  where (LPNDetailId = @vPRLPNDetailId);

  /* Delete lines if quantity on them is zero */
  delete LD
  from LPNDetails LD
  where (LPNId = @vLPNId) and
        (Quantity    = 0) and
        (ReservedQty = 0) and
        (OnhandStatus <> 'A');

  /* Need to have reseved quantities to be updated here so that we can recompute dependencies correctly */
  exec pr_LPNs_Recount @vLPNId;

  /* Update dependencies of the Tasks - Needs to be done after LPN Recount above */
  if (exists (select * from LPNDetails where LPNId = @vLPNId and Onhandstatus = 'PR'))
    exec pr_LPNs_RecomputeWaveAndTaskDependencies @vLPNId, null /* Current Qty*/, @vLPNQuantity, 'UnallocatePRLine';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_UnallocatePendingReserveLine */

Go
