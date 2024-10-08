/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/25  TK      pr_LPNDetails_ConfirmReservation: Changes to delete available line if confirming reservation from dynamic picklanes
  2018/08/02  VM/AY   pr_LPNDetails_ConfirmReservation: Bug fix (S2G-1058)
  2018/07/28  TK      pr_LPNDetails_ConfirmReservation: Several fixes to update LPN quantities properly (S2G-1058)
  2018/05/08  TK      pr_LPNDetails_ConfirmReservation: Raise error if there is no available inventory to confirm (S2G-719)
  2018/04/25  TK      pr_LPNDetails_ConfirmReservation & fn_LPNDetails_ComputeInnerpacks:
  2018/04/03  TK      pr_LPNDetails_ConfirmReservation: Changes to recompute Task Dependencies when task is confirmed for picking
  2018/03/28  TK      pr_LPNDetails_ConfirmReservation: Don't delete available lines (S2G-499)
  2018/02/13  TK      pr_LPNDetails_ConfirmReservation: Initial Revision (S2G-153)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_ConfirmReservation') is not null
  drop Procedure pr_LPNDetails_ConfirmReservation;
Go
/*------------------------------------------------------------------------------
  pr_LPNDetails_ConfirmReservation: This proc confirms inventory reservation for given
    pending reservation line, reduces quantity on available line and reserved quantity
    on the directed/available line
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_ConfirmReservation
  (@LPNId             TRecordId,
   @LPNDetailId       TRecordId,
   @UnitsToReserve    TQuantity)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vLDActivityLogId       TRecordId,
          @vActivityLogMessage    TDescription,

          @vALRecordId            TRecordId,
          @vRLRecordId            TRecordId,

          @vAvailLPNDetailId      TRecordId,
          @vLPNDetailId           TRecordId,

          @vLPNLocationId         TRecordId,
          @vDynamicPicklane       TFlags,

          @vLPNPrevQuantity       TQuantity,
          @vAvailQtyToDeduct      TQuantity,
          @vAvailQtyDeducted      TQuantity,
          @vReserveQtyToDeduct    TQuantity,
          @vReserveQtyDeducted    TQuantity;

  declare @ttLPNDetails       table (LPNId            TRecordId,
                                     LPNDetailId      TRecordId,
                                     LPNLine          TDetailLine,
                                     OnHandStatus     TStatus,
                                     UnitsPerPackage  TQuantity,
                                     OrigQuantity     TQuantity,
                                     Quantity         TQuantity,
                                     OrigReservedQty  TQuantity,
                                     ReservedQty      TQuantity,
                                     /* For performance reasons so we can at the end only update the processed lines */
                                     ProcessedFlag    TFlag   default 'N',

                                     RecordId         TRecordId identity(1,1));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode         = 0,
         @vALRecordId         = 0,
         @vRLRecordId         = 0,
         @vAvailQtyToDeduct   = @UnitsToReserve,
         @vReserveQtyToDeduct = @UnitsToReserve,
         @vActivityLogMessage = 'UnitsToResv: ' + cast(@UnitsToReserve as varchar);

  /* Get Current LPN Quantity which is needed to recalc task dependencies */
  select @vLPNPrevQuantity = Quantity,
         @vLPNLocationId   = LocationId
  from LPNs
  where (LPNId = @LPNId);

  /* Check if it is a Dynamic Picklane */
  select @vDynamicPicklane = case when LocationType = 'K' and LocationSubType = 'D' then 'Y' else 'N' end
  from Locations
  where (LocationId = @vLPNLocationId);

  /* Get all the LPN Details to process */
  insert into @ttLPNDetails(LPNId, LPNDetailId, LPNLine, OnHandStatus, UnitsPerPackage, OrigQuantity, Quantity, OrigReservedQty, ReservedQty)
    select LPNId, LPNDetailId, LPNLine, OnHandStatus, UnitsPerPackage, Quantity, Quantity, ReservedQty, ReservedQty
    from LPNDetails
    where (LPNId = @LPNId) and
          (OnhandStatus in ('A', 'D'/* Avail., Directed */))
    order by OnhandStatus asc, LPNLine desc;

  /* Return if no line found to reduce quantity, LPN detail Onhand Status in this case will remain as 'PR' */
  if (@@rowcount = 0)
    return;

  /*----------------------------Activity Log---------------------------------*/
  /* Start log of LPN Details into Activity log */
  exec pr_ActivityLog_LPN 'LDCR_LPNDetails_Start', @LPNId, @vActivityLogMessage, @@ProcId,
                          @ActivityLogId = @vLDActivityLogId output;

  /* Loop thru each Available line and reduce quantity until we exhaust available quantity to be deducted
     available quantity can be reduced on Available lines only */
  while (@vAvailQtyToDeduct > 0) and
        (exists (select *
                 from @ttLPNDetails
                 where (RecordId > @vALRecordId) and
                       (OnHandStatus = 'A'/* Available */)))
    begin
      select top 1 @vALRecordId       = RecordId,
                   @vAvailLPNDetailId = LPNDetailId
      from @ttLPNDetails
      where (RecordId > @vALRecordId) and
            (OnHandStatus = 'A'/* Avail. */)
      order by RecordId;

      /* If Units to Reserve is less than available line qty then reduce the qty & reserved qty
         on the Available Line */
      update @ttLPNDetails
      set @vAvailQtyDeducted = dbo.fn_MinInt(Quantity, @vAvailQtyToDeduct),
          Quantity          -= dbo.fn_MinInt(Quantity, @vAvailQtyToDeduct),
          ProcessedFlag      = 'Y'/* Yes */
      where (LPNDetailId = @vAvailLPNDetailId);

      /* Reduce the total quantity that needs to be reserved */
      select @vAvailQtyToDeduct -= @vAvailQtyDeducted;
    end

  /* Loop thru each line and reduce reserved quantity until we exhaust reserved quantity to be deducted
     Deduct reserved quantity from directed lines first and then from Available line */
  while (@vReserveQtyToDeduct > 0) and
        exists (select *
                from @ttLPNDetails
                where (RecordId > @vRLRecordId))
    begin
      select top 1 @vRLRecordId  = RecordId,
                   @vLPNDetailId = LPNDetailId
      from @ttLPNDetails
      where (RecordId > @vRLRecordId)
      order by RecordId;

      /* If Units to Reserve is less than available line qty then reduce the qty & reserved qty
         on the Available Line */
      update @ttLPNDetails
      set @vReserveQtyDeducted = dbo.fn_MinInt(ReservedQty, @vReserveQtyToDeduct),
          ReservedQty         -= dbo.fn_MinInt(ReservedQty, @vReserveQtyToDeduct),
          ProcessedFlag        = 'Y'/* Yes */
      where (LPNDetailId = @vLPNDetailId);

      /* Reduce the total quantity that needs to be reserved */
      select @vReserveQtyToDeduct -= @vReserveQtyDeducted;
    end

  /* If there is still available or reserved quantity to be deducted there might be some issue so return */
  if (@vAvailQtyToDeduct > 0) or (@vReserveQtyToDeduct > 0)
    begin
      set @vMessageName = 'NotEnoughInventoryToConfirmTasks';
      goto ErrorHandler;
    end

  /* Reserve PR line */
  update LPNDetails
  set ReservedQty  = Quantity,
      OnHandStatus = 'R'/* Reserved */
  where (LPNDetailId = @LPNDetailId);

  /* Update quantities on Available/Directed lines that were update earlier */
  update LD
  set LD.Quantity    -= (ttLD.OrigQuantity - ttLD.Quantity),
      LD.ReservedQty -= (ttLD.OrigReservedQty - ttLD.ReservedQty)
  from LPNDetails LD
    join @ttLPNDetails ttLD on (LD.LPNDetailId = ttLD.LPNDetailId)
  where (ttlD.ProcessedFlag = 'Y'/* Yes */);

  /* Update Innerpacks on LPN Details */
  update LD
  set LD.Innerpacks  = dbo.fn_LPNDetails_ComputeInnerpacks(LD.LPNDetailId, LD.Quantity, LD.UnitsPerPackage)
  from LPNDetails LD
    join @ttLPNDetails ttLD on (LD.LPNDetailId = ttLD.LPNDetailId)
  where (ttlD.ProcessedFlag = 'Y'/* Yes */);

  /* Update lines with -LPNId for debugging purpose */
  update LD
  set LPNId = (-1 * LD.LPNId)
  from LPNDetails LD
    join @ttLPNDetails ttLD on (LD.LPNDetailId = ttLD.LPNDetailId)
  where (LD.Quantity    = 0) and
        (LD.ReservedQty = 0) and
        /* Do not delete available line if it is not a dynamic picklane */
        ((LD.OnhandStatus <> 'A') or
         ((LD.OnhandStatus = 'A') and (@vDynamicPickLane = 'Y'))) and
        (ttLD.ProcessedFlag = 'Y'/* Yes */);

  /*----------------------------Activity Log---------------------------------*/
  /* End log of LPN Details into Activity log */
  exec pr_ActivityLog_LPN 'LDCR_LPNDetails_End', @LPNId, @vActivityLogMessage, @@ProcId,
                          @ActivityLogId = @vLDActivityLogId output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_ConfirmReservation */

Go
