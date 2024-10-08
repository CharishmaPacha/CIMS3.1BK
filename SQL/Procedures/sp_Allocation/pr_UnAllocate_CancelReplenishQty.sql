/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/05  TK      pr_UnAllocation_LPNDetails, pr_UnAllocate_CancelReplenishQty,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UnAllocate_CancelReplenishQty') is not null
  drop Procedure pr_UnAllocate_CancelReplenishQty;
Go
/*------------------------------------------------------------------------------
  Proc pr_UnAllocate_CancelReplenishQty:
    This Procedure cancels replenish quantity in the Location if an LPN detail
    allocated for Replenish order is unallocated

  1. If Directed line doesn't have any reserved quantity and unallocated quantity matches with the
     quantity on D line then delete the D line
  2. If Directed line has reserved quantity against it or unallocated quantity is less than the
     quantity on D line then reduce the quantity on the D line

  #LPNDetails -> TLPNDetails
------------------------------------------------------------------------------*/
Create Procedure pr_UnAllocate_CancelReplenishQty
  (@Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          @vProcName              TName,

          @vOrderId               TRecordId,
          @vOrderDetailId         TRecordId,
          @vSKUId                 TRecordId,

          @vQuantity              TQuantity;
begin /* pr_UnAllocate_CancelReplenishQty */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vProcName    = object_name(@@ProcId);

  /*-------------- Cancel Replenish Qty ---------------*/
  /* If the unallocated LPN detail is for a Replenish Order, then we need to reduce the corresponding
     directed/directed reserve qty on the location */
  select OrderId, OrderDetailId, sum(Quantity) as Quantity,
         row_number() over (order by OrderId, OrderDetailId) as RecordId
  into #ODsToCancelReplenQty
  from #LPNDetails
  where (OrderType in ('R', 'RU', 'RP' /* Replenish */)) and
        (ProcessedFlag = 'Y' /* Yes */)
  group by OrderId, OrderDetailId;

  /* Find the LPN Details with the directed qty for the canceled replenishments */
  select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.Quantity, LD.ReservedQty, OD.Quantity as ReplenQty,
         row_number() over (order by LPNId) as RecordId
  into #DirectedLines
  from LPNDetails LD
    join #ODsToCancelReplenQty OD on (LD.ReplenishOrderId = OD.OrderId) and
                                     (LD.ReplenishOrderDetailId = OD.OrderDetailId)
  where (LD.OnhandStatus = 'D' /* Directed*/) and
        (LD.LPNId > 0) /* for some reason, we are getting old canceled record with - LPNId */
  order by OnhandStatus;   -- Cancel D line first

  /* Reduce quantity on directed line */
  update LD
  set Quantity    -= DL.ReplenQty,
      ModifiedBy   = @UserId,
      ModifiedDate = current_timestamp
  from LPNDetails LD
    join #DirectedLines DL on (LD.LPNDetailId = DL.LPNDetailId);

  /* Delete directed lines if quanity and reserved quantity on them goes to zero */
  delete LD
  from LPNDetails LD
    join #DirectedLines DL on (LD.LPNDetailId = DL.LPNDetailId)
  where (LD.Quantity = 0) and
        (LD.ReservedQty = 0);

  /*--------------- Recounts ---------------*/
  /* Recount required entities */
  insert into #EntitiesToRecalc (EntityType, EntityId, RecalcOption, Status, ProcedureName, BusinessUnit)
    select distinct 'LPN', LPNId, 'C' /* Counts */, 'N', @vProcName, @BusinessUnit from #DirectedLines;

  /*-------------- Recompute Task/Wave dependencies ---------------*/
  /* When directed quantity is reduced, dependencies on the task details from those LPNs may change
     so we need to recompute task & wave dependencies, capture all the tasks details that needs to be recomputed */
  insert into #TDsToRecomputeDependencies (EntityId)
    select TD.TaskDetailId
    from TaskDetails TD
      join Tasks T on (TD.TaskId = T.TaskId)
      join #DirectedLines DL on (TD.LPNId = DL.LPNId)
    where (TD.Status in ('N', 'O')) and
          (charindex(TD.DependencyFlags, 'MNR') > 0) and
          (T.Archived = 'N') and -- for performance
          (T.Status in ('O', 'N' /* OnHold, ReadyToStart */)) and
          (T.IsTaskConfirmed = 'N'/* No */);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_UnAllocate_CancelReplenishQty */

Go
