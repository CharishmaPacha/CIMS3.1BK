/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/06  TK      pr_LPNDetails_Unallocate: Unallocate only R, DR & PR lines (HA-3132)
  2021/06/24  VS      pr_LPNDetails_Unallocate: If we unallocate the Picked ShipCarton then LPNType should change to Carton (HA-2911)
  2021/01/31  TK      pr_LPNDetails_UnallocateMultiple & pr_LPNs_Void: Minor fixes noticed during dev testing (HA-1947)
  2020/09/30  TK      pr_LPNDetails_UnallocateMultiple: Recount Pallet to clear order info when all LPNs on pallet is allocated to a same order (HPI-2951)
  2018/12/17  TD      pr_LPNDetails_Unallocate:Considered staged status LPNs to unallocate (OB2-784)
  2018/12/02  AY      pr_LPNDetails_UnallocateMultiple: Change to reflect new ActivityLog_AddMessage (FB-1226)
  2018/04/16  TK      pr_LPNDetails_UnallocatePendingReserveLine: Changes to update counts on LPN before evaluating dependencies (S2G-342)
                      pr_LPNDetails_UnallocatePendingReserveLine: Changes to recompute Task Dependencies when a PR line is cancelled
  2018/03/26  OK      pr_LPNDetails_Unallocate: Added logging (S2G-XXX)
  2018/03/26  AY      pr_LPNDetails_Unallocate: Changed to not reset ReservedQty to zero as it is computed already (S2G-480)
  2018/02/24  TK      pr_LPNDetails_UnallocatePendingReserveLine: bug fix to delete PR line (S2G-151)
  2018/02/14  TK      pr_LPNDetails_Unallocate: Enhanced to handle Pending Reservation line un-allocation
                      pr_LPNDetails_UnallocatePendingReserveLine: Initial Revision
                      pr_LPNDetails_UnallocateReservedLine: Initial Revision (S2G-180)
  2017/07/28  RV      pr_LPNDetails_CancelReplenishQty, pr_LPNDetails_Unallocate: BusinessUnit and UserId passed to activity log procedure
  2017/07/18  TK      pr_LPNDetails_Unallocate: Changes to differentiate between the type of unallocation (HPI-1597)
  2017/07/07  RV      pr_LPNDetails_CancelReplenishQty, pr_LPNDetails_Unallocate:
  2017/02/22  KL      pr_LPNDetails_Unallocate: Log the AT on wave when unallocate the LPN (HPI-1321)
              AY      pr_LPNDetails_Unallocate: Change to clear TaskId on unallocate (HPI-1200)
  2017/02/17  CK/AY   pr_LPNDetails_Unallocate: Recounting LPN once after unallocating the LPNDs completely (HPI-1376)
              AY      pr_LPNDetails_UnallocateMultiple: Process all LPN Details when only LPNId is given
  2017/02/10  ??      pr_LPNDetails_Unallocate: ignore(commented) couple of lines to consider Replenish order (HPI-GoLive)
  2016/12/12  VM      pr_LPNDetails_Unallocate: Introduced activity log. Log when UnitsAssigned going negative (HPI-692)
              VM      pr_LPNDetails_CancelReplenishQty, pr_LPNDetails_Unallocate, pr_LPNs_UpdateOrderOnAdjust (HPI-692):
  2016/11/24  ??      pr_LPNDetails_Unallocate: Addition of a new check for LPN Status (HPI-GoLive)
  2016/11/22  AY      pr_LPNDetails_Unallocate: Bug fix in identifying the task detail to cancel (HPI-1087)
  2016/11/09  VM      pr_LPNDetails_Unallocate: Bug-fix: Merge the DR line quantity to its replenish order D line (HPI-1016)
  2016/08/04  TK      pr_LPNDetails_Unallocate: Merging Details on Unallocate should match Lot as well
  2016/08/03  TK      pr_LPNDetails_Unallocate: Enhanced to delete Temp Label details (HPI-418)
  2016/05/27  TK      pr_LPNDetails_Unallocate: Changes made to Directed lines if there are any
  2015/04/11  DK      pr_LPNDetails_Unallocate: Made changes to clear reserved qty when Picktask is cancelled (FB-487).
  2015/10/13  OK      pr_LPNDetails_UnallocateMultiple: Added the procedure to Unallocate multiple LPNs (FB-412)
  2015/10/09  RV      pr_LPNDetails_Unallocate: Use coalesce for Operation as it might be null for some callers (FB-427)
  2015/01/29  VM      pr_LPNDetails_Unallocate: Lost status code corrected
  2014/12/09  TD      pr_LPNs_AdjustQty, pr_LPNDetails_Unallocate: Changes to adjust directed line when
  2014/02/27  PK      pr_LPNDetails_Unallocate: Allowing to Unallocate Picked LPN.
  2014/01/22  TD      pr_LPNDetails_Unallocate: Updating OrderDetail units before cancel the task while shortpicking/Cancel.
  2014/01/09  TD      pr_LPNDetails_Unallocate: Issue fixed: Clear Order  when LPN is unallcoated completely.
              AY      pr_LPNDetails_Unallocate: Changed to unallocate from a Lost/Void LPN if it hasn't been unallocated already
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_Unallocate') is not null
  drop Procedure pr_LPNDetails_Unallocate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_Unallocate: Unallocates an LPN Detail, cancels the task detail if
    there is one. Merges the unallocated line with the available line or flips
    the unallocated line to available.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_Unallocate
  (@LPNId            TRecordId,
   @LPNDetailId      TRecordId,
   @UserId           TUserId,
   @Operation        TOperation = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vLPNId             TRecordId,
          @vLPNDetailId       TRecordId,
          @vLPNTaskId         TRecordId,
          @vLPNTaskDetailId   TRecordId,
          @vLPNStatus         TStatus,
          @vNewLPNStatus      TStatus,
          @vLPNQuantity       TQuantity,
          @vLPNDetailLot      TLot,
          @vNewLPNLine        TDetailLine,
          @vInnerPacks        TInnerPacks,
          @vQuantity          TQuantity,
          @vOnhandStatus      TStatus,
          @vSKUId             TRecordId,
          @vSKU               TSKU,
          @vOrderId           TRecordId,
          @vOrderDetailId     TRecordId,
          @vOldUnitsAssigned  TQuantity,
          @vNewUnitsAssigned  TQuantity,
          @vReplenishOrderId  TRecordId,
          @vReplenishOrderDetailId
                              TRecordId,
          @vBusinessUnit      TBusinessUnit,
          @vMergeLPNDetailId  TRecordId,
          @vTaskId            TRecordId,

          @vOrderType         TTypeCode,
          @vPickBatchId       TRecordId,

          @vLogActivity       TFlag,
          @vLDActivityLogId   TRecordId,
          @vAuditActivity     TActivityType,
          @vxmlData           TXML;
begin
  SET NOCOUNT ON;

  select @vRecordId      = 0,
         @vLogActivity   = 'Y' /* Yes */,
         /* just to differentiate between the type of unallocation */
         @vAuditActivity = case when @Operation = 'CloseBPT'
                                  then 'CloseBPT_UnallocateLPNDetail'
                                else 'UnallocateLPNDetail'
                           end;

  /* Fetch the details of the LPN Detail */
  select @vLPNDetailId            = LPNDetailId,
         @vLPNId                  = LPNId,
         @vInnerPacks             = InnerPacks,
         @vQuantity               = Quantity,
         @vSKUId                  = SKUId,
         @vOnhandStatus           = OnhandStatus,
         @vOrderDetailId          = OrderDetailId,
         @vOrderId                = OrderId,
         @vLPNDetailLot           = Lot,
         @vReplenishOrderId       = ReplenishOrderId,
         @vReplenishOrderDetailId = ReplenishOrderDetailId,
         @vBusinessUnit           = BusinessUnit
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  select @vOrderType   = OrderType,
         @vPickBatchId = PickBatchId
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Get the task detail that is related to the LPN detail being un-allocated */
  select @vLPNTaskId       = TaskId,
         @vLPNTaskDetailId = TaskDetailId
  from TaskDetails
  where (LPNDetailId = @vLPNDetailId) and
        (Status not in ('C', 'X')) and
        (OrderDetailId = @vOrderDetailId);

  /* The above may not be sufficient. What if it is a DR Line and there is no TaskDetail for it?
     We should reduce the task qty isn't it? AY */

  /* If we are unable to find the task using TaskDetail, then try using LPNId */
  if (@vLPNTaskId is null)
    select @vLPNTaskId       = TaskId,
           @vLPNTaskDetailId = TaskDetailId
    from TaskDetails
    where (LPNId = @vLPNId) and
          (Status not in ('C', 'X')) and
          (OrderDetailId = @vOrderDetailId);

  select @vLPNStatus   = Status,
         @vLPNQuantity = Quantity
  from LPNs
  where (LPNId = @vLPNId);

  /* Start log of LPN Details into ActivityLog */
  exec pr_ActivityLog_LPN 'LPNDetails_Unallocate_Start', @vLPNId, 'ACT_LPNDetails_Unallocate', @@ProcId,
                          null, @vBusinessUnit, @UserId, @vLDActivityLogId output;

  /* Validations */
  if (@LPNDetailId is null)
    set @vMessageName = 'LPNDetailIsRequired';
  else
  if (@vLPNDetailId is null)
    set @vMessageName = 'InvalidLPNDetail'
  else
  if (@vOnhandStatus not in ('R' /* Reserved */, 'DR', 'PR' /* Pending Resv */))
    set @vMessageName = 'LPNLineNotReserved'
  else
  /* If LPN is picked, then let the users unallocate the LPN, not the individual lines */
  if (@vLPNStatus not in ('N', 'D', 'P', 'U', 'A', 'K', 'L', 'E' /* Putaway or allocated or Picked, Loaded, Staged */, 'G', 'O', 'V' /* Allow Lost & Void temporarily until bug fixes are done */))
    set @vMessageName = 'AlreadyPickedUnallocateLPN'

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (@vOnhandStatus in ('R', 'DR'/* Reserved, Directed Reserve */))
    exec pr_LPNDetails_UnallocateReservedLine @vLPNDetailId, @UserId, null /* Operation */;
  else
  if (@vOnhandStatus = 'PR'/* Pending Reservation */)
    exec pr_LPNDetails_UnallocatePendingReserveLine @vLPNDetailId, @UserId, null /* Operation */;

  /* Need to recalc status as well as ReservedQty */
  exec pr_LPNs_Recount @vLPNId, @UserId, @vNewLPNStatus output;

   /* Clear OrderId on LPN */
  if (@vNewLPNStatus = 'P' /* Putaway */)
    update LPNs
    set OrderId      = null,
        --ReservedQty  = 0, already recalculated above
        LPNType      = case when ReservedQty = 0 and LPNType = 'S' then 'C' else LPNType end, /* If we unallocate the Picked ShipCarton LPN and ReservedQty is 0 after unallocate then we should change the LPNType to Carton */
        PackageSeqNo = null,
        UCCBarcode   = null,
        TrackingNo   = null,
        TaskId       = null,
        ShipmentId   = 0,
        LoadId       = 0,
        LoadNumber   = null,
        BoL          = null,
        PickBatchId  = null,
        PickBatchNo  = null,
        DestLocation = null,
        DestZone     = null,
        ModifiedDate = current_timestamp,
        ModifiedBy   = @UserId
    where (LPNId = @vLPNId);

  /* Update OrderDetails here */
  update OrderDetails
  set UnitsAssigned      = dbo.fn_MaxInt((UnitsAssigned - @vQuantity), 0),
      @vOldUnitsAssigned = UnitsAssigned,
      @vNewUnitsAssigned = UnitsAssigned - @vQuantity
  where (OrderDetailId = @vOrderDetailId);

  /* If the unallocated LPN detail is for a Replenish Order, then we need to reduce the corresponding
     directed/directed reserve qty on the location */
  if (@vOrderType in ('RU', 'RP'))
    exec pr_LPNDetails_CancelReplenishQty @vOrderId, @vOrderDetailId, @vQuantity, @vBusinessUnit, @UserId;

  /* Update TaskDetail and Task */
  /* TaskDetails cancel inturn calls Task details close
     Task Details cancel will void/delete details of temp label generated */
  if (@vLPNTaskId is not null) and (@vLPNTaskDetailId is not null)
    exec pr_TaskDetails_Cancel @vLPNTaskId, @vLPNTaskDetailId, @UserId;

  /* Set PickTicket Header Counts and Status
     Avoid when TaskCancel is the operation as pr_Tasks_Cancel procedure is already doing that */
  if (coalesce(@Operation, '') not in ('TaskCancel','PalletUnallocate'))
    exec @vReturnCode = pr_OrderHeaders_Recount @vOrderId;

  /* ------------------------------------------------------------------------*/
  /* Activity Log */
  /* ------------------------------------------------------------------------*/
  if (@vLogActivity = 'Y' /* Yes */) and (@vNewUnitsAssigned < 0)
    begin
      select @vxmlData = (select @vOrderId          OrderId,
                                 @vOrderDetailId    OrderDeatailId,
                                 @vQuantity         QtyToUnallocate,
                                 @vOldUnitsAssigned OldUnitsAssigned,
                                 @vNewUnitsAssigned NewUnitsAssigned,
                                 @vLPNId            LPNId,
                                 @vLPNDetailId      LPNDetailId,
                                 @vReplenishOrderId LPNReplenishOrderId,
                                 @vReplenishOrderId ReplenishOrderDetailId
                          for XML raw('UnallocateLPNDetail'), elements );

      exec pr_ActivityLog_AddMessage 'LPNDetails_Unallocate', @vOrderId, null, 'PickTicket',
                                     'UnallocateDetails' /* Message */, @@ProcId, @vxmlData, @vBusinessUnit, @UserId;
    end

  /* Insert Audit Trail */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @LPNId         = @vLPNId,
                            @PickBatchId   = @vPickBatchId,
                            @SKUId         = @vSKUId,
                            @OrderId       = @vOrderId,
                            @OrderDetailId = @vOrderDetailId,
                            @Quantity      = @vQuantity;

  /* End log of LPN Details into ActivityLog  */
  exec pr_ActivityLog_LPN 'LPNDetails_Unallocate_End', @vLPNId, 'ACT_LPNDetails_Unallocate', @@ProcId,
                          null, @vBusinessUnit, @UserId, @vLDActivityLogId output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_Unallocate */

Go
