/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/26  TK      pr_Allocation_AllocateLPN_New: Bug fix when complete LPN detail cannot be allocated
                      pr_Allocation_AllocateLPNToOrders_New: Changes to add reserved LPNDetailId instead of FromLPNDetailId (HA-658)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateLPN_New') is not null
  drop Procedure pr_Allocation_AllocateLPN_New;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateLPN_New:

  This proc is the base procedure to allocate/reserve an LPN for an Order. It
  could be used to allocate against a specific line of the order by providing
  the OrderDetailId and if the OrderDetailId is not given, then it would use the
  SKUId and identify a line to allocate the LPN against.

  If UnitsToAllocate is zero or null, then entire LPN is allocated or else only
  part of the LPN is allocated.

  Operation: We now support two inventory reservation models i.e. Immediate and
    Deferred and which one to execute may be based upon the Operation. For example
    even if normal model is Deferred, for LPN Reservation it may be Immediate.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateLPN_New
  (@LPNId                TRecordId,
   @LPNDetailId          TRecordId,
   @OrderId              TRecordId,
   @OrderDetailId        TRecordId,
   @TaskDetailId         TRecordId,
   @SKUId                TRecordId,
   @UnitsToAllocate      TInteger,
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId,
   @Operation            TOperation = 'InventoryResv',
   @ReservedLPNDetailId  TRecordId  = null output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,

          @vLPNId                     TRecordId,
          @vLPNType                   TTypeCode,
          @vLPNDetailId               TRecordId,
          @vReservedLPNDetailId       TRecordId,
          @vLPNDetailQuantity         TInteger,

          @vOrderId                   TRecordId,
          @vOrderType                 TTypeCode,
          @vOrderDetailId             TRecordId,
          @vWaveId                    TRecordId,
          @vWaveNo                    TPickBatchNo,

          @vInvResControlCategory     TCategory,
          @vInvReservationModel       TControlValue,

          @vDestLPNId                 TRecordId,
          @vDestLocationId            TRecordId,
          @vDestLocation              TLocation,

          @vActivityType              TActivityType;
begin /* pr_Allocation_AllocateLPN_New */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Fetch LPN and Order Info - if user did not pass in a SKU, then use the SKU
     of the LPN - assuming that it is a single SKU LPN */
  select @vLPNId   = LPNId,
         @vLPNType = LPNType
  from LPNs
  where (LPNId = @LPNId);

  /* Get Order info */
  select @vOrderId   = OrderId,
         @vOrderType = OrderType,
         @vWaveId    = PickBatchId,
         @vWaveNo    = PickBatchNo
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Set up Operation */
  select @Operation = case when ((@vLPNType <> 'L'/* Logical */) or (@vOrderType in ('R', 'RU', 'RP'/* Replenish */)))
                             then 'LPNResv'
                           else 'InventoryResv'
                      end -- if allocating a Carton LPN then don't create PR lines

  /* Get OrderDetail info */
  if (@OrderDetailId is not null)
    select @vOrderDetailId  = OrderDetailId,
           @vDestLocation   = DestLocation,
           @vDestLocationId = DestLocationId
    from OrderDetails
    where (OrderDetailId = @OrderDetailId);

  /* get the Logical LPN Id to log the AT */
  if (@vDestLocationId is not null)
    select @vDestLPNId = LPNId
    from LPNs
    where (LocationId = @vDestLocationId) and
          (SKUId      = @SKUId);

  /* Fetch LPN detail info */
  select @vLPNDetailId       = LPNDetailId,
         @vLPNDetailQuantity = Quantity
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Return if there is no LPN detail to Allocate */
  if (@vLPNDetailId is null)
    return;

  /* If UnitsToAllocate is null/Zero, allocate available LPN Quantity */
  select @UnitsToAllocate        = coalesce(@UnitsToAllocate, @vLPNDetailQuantity),
         @vInvResControlCategory = 'Allocation_' + @Operation,
         @vInvReservationModel   = dbo.fn_Controls_GetAsString (@vInvResControlCategory, 'InvReservationModel', 'I' /* Immediate */, @BusinessUnit, null /* UserId */);

  /* Reserve the LPNDetail */
  exec @vReturnCode = pr_LPNDetails_ReserveQty @vLPNId, @vLPNDetailId,
                                               @UnitsToAllocate,
                                               @vOrderId, @vOrderDetailId, @TaskDetailId,
                                               @SKUId, @vInvReservationModel,
                                               @BusinessUnit, @UserId,
                                               @vReservedLPNDetailId  output;

  /* Allocated LPN detail might not be the one which is passed so assign & return the allocated LPN Detail */
  /* set output variable with Reserved LPN DetailId */
  set @ReservedLPNDetailId = @vReservedLPNDetailId;

  /* We don't need to set OrderId here because when Line is added
     it should have called LPN_Recount which should have done it */
  /* OrderId would be null if the LPN is Partially allocated, so if OrderId is not null and
     if it is not a logical LPN then we would update PickBatchId on the LPN */
  /* Need to update Destlocation with the To-replenish location when the LPN got allocated to
     replenish order */
  update LPNs
  set PickBatchId  = case when OrderId is not null and LPNType <> 'L' /* Logical */ then @vWaveId else null end,
      PickBatchNo  = case when OrderId is not null and LPNType <> 'L' /* Logical */ then @vWaveNo else null end,
      DestLocation = case when @vOrderType in ('RU', 'RP', 'R' /* Replenish */) and Status = 'A' /* Allocated */ then @vDestLocation else DestLocation end,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  where (LPNId = @LPNId);

  /* Update PickTicket Hdr/ Detail */
  /* Set PickTicket Detail Allocated Quantity, also increase UATS as needed*/
  update OrderDetails
  set UnitsAssigned        += @UnitsToAllocate,
      UnitsAuthorizedToShip = case when @vOrderType in ('RU', 'RP', 'R' /* Replenish Orders */) then dbo.fn_MaxInt(UnitsAuthorizedToShip, UnitsAssigned + @UnitsToAllocate) else UnitsAuthorizedToShip end
  where (OrderDetailId = @OrderDetailId);

  /* Identify Activity Type */
  select @vActivityType = case when (@UnitsToAllocate = @vLPNDetailQuantity) and (@vLPNType <> 'L')
                                 then 'LPNAllocatedToOrderOnWave'
                               else 'UnitsAllocatedToOrderOnWave'
                          end;

  if (@vOrderType in ('RU', 'RP', 'R' /* Replenish */))
    select @vActivityType = 'Replenish_' + @vActivityType;

  /* Insert Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                            @LPNId         = @vLPNId,
                            @ToLPNId       = @vDestLPNId,
                            @LocationId    = @vDestLocationId,
                            @SKUId         = @SKUId,
                            @OrderId       = @vOrderId,
                            @OrderDetailId = @vOrderDetailId,
                            @PickBatchId   = @vWaveId,
                            @Quantity      = @UnitsToAllocate;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateLPN_New */

Go
