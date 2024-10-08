/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/11  TK      pr_Allocation_AllocateLPNToOrders_New: Changes to allocate cases from LPNs (BK-181)
  2020/05/26  TK      pr_Allocation_AllocateLPN_New: Bug fix when complete LPN detail cannot be allocated
                      pr_Allocation_AllocateLPNToOrders_New: Changes to add reserved LPNDetailId instead of FromLPNDetailId (HA-658)
  2020/05/06  VS      pr_Allocation_AllocateLPN: Made changes to update the Pallets counts & status (HPI-2921)
  2018/10/25  TK      pr_Allocation_AllocateLPN: Changed procedure signature to accept TaskDetailId
                      pr_Allocation_AllocateFromDynamicPicklanes & pr_Allocation_AllocateLPNToOrders:
                        Changes to Allocation_AllocateLPN proc signature (S2GCA-390)
  2018/08/28  PK      pr_Allocation_AllocateLPN: Commented code to not to update PackageSeqNo in allocation (S2G-1093)
  2018/07/02  TK      pr_Allocation_GeneratePseudoPicks: Changes to defer cubing
                      pr_Allocation_AllocateFromDynamicPicklanes: Initial Revision
                      pr_Allocation_AllocateLPNToOrders: Changes to allocate only required cases and
                        allocate Units for Dynamic Replenishments (S2GCA-66)
  2018/05/18  TK      pr_Allocation_AllocateLPNToOrders: UnitsToAllocate should be converted to float value else the division returns only integer value (S2G-853)
  2018/05/01  TK      pr_Allocation_AllocateLPNToOrders: Overallocate to atleast a case when ordered quantity is less than a case for replenishments (S2G-CRPIssues)
  2018/04/27  TK      pr_Allocation_AllocateLPNToOrders: Changes to allocate complete units from UnitStorage Locations (S2G-723)
  2018/04/23  AY      pr_Allocation_AllocateLPNToOrders: Prevent allocation of units from an LPN with InnerPacks (S2G-723)
  2018/03/28  AY      pr_Allocation_AllocateLPN: Changed AT for Logical LPN
  2018/03/27  TK      pr_Allocation_AllocateLPN & pr_Allocation_AllocateLPNToOrders:
                        Changes to consider DestLocation instead of Location (S2G-499)
  2018/03/13  OK      pr_Allocation_AllocateLPN: Enhanced to log AT on Locgical LPN and Picklane location on Replenishment allocation (S2G-357)
  2018/03/09  TK      pr_Allocation_AllocateLPNToOrders: Changes to UnitsPerPackage appropriately (S2G-364)
  2018/03/06  VM      pr_Allocation_AllocateLPN, pr_Allocation_AllocateInventory:
                        Add activity log on LPN Details and Task Details (S2G-344)
  2018/03/03  TK      pr_Allocation_AllocateWave & pr_Allocation_AllocateLPNToOrders:
                        Changes to allocate cases and units separately (S2G-341)
  2018/03/02  TK      pr_Allocation_AllocateLPN: Changes to create PR lines only for picklanes
                      pr_Allocation_AllocateInventory: Changes to update WaveId on task details
                      pr_Allocation_AllocateLPNToOrders: Changes to increment qty on the task
                        detail if there is on for order detail
                      pr_Allocation_FindAllocableLPN: Changes to over allocate LPNs from Bulk Location
                      pr_Allocation_SumPicksFromSameLocation: Initial Revision (S2G-151)
  2018/01/24  TK      pr_Allocation_AllocateLPN: Changes to defer reservation of Inventory
                      pr_Allocation_FindAllocableLPNs: removed HPI specific code
                      pr_Allocation_AllocateLPNToOrders: Changes to Allocate_AllocateLPN procedure signature (S2G-152)
  2017/12/18  TD      pr_Allocation_AllocateLPN:Changes to update DestLocation on the allocated LPN for replen orders(CIMS-1740)
  2017/08/08  TK      pr_Allocation_AllocateInventory & fn_PickBatches_GetAllocationRules:
                        Changes to consider ReplenishClass while allocating inventory
                      pr_Picking_FindAllocableLPNs => pr_Allocation_FindAllocableLPNs
                      pr_Allocation_AllocateLPNToOrders: renamed from pr_PickBatch_AllocateLPNToOrders(HPI-1625)
  2016/09/08  TK      pr_Allocation_AllocateLPN: Initial Revision - Clone of pr_Picking_AllocateLPN (HPI-562)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateLPN') is not null
  drop Procedure pr_Allocation_AllocateLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateLPN:

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
Create Procedure pr_Allocation_AllocateLPN
  (@LPNId             TRecordId,
   @OrderId           TRecordId,
   @OrderDetailId     TRecordId,
   @TaskDetailId      TRecordId,
   @SKUId             TRecordId,
   @UnitsToAllocate   TInteger   = null,
   @UserId            TUserId    = null,
   @Operation         TOperation = 'InventoryResv',
   @LPNDetailId       TRecordId  = null output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,

          @vLPN                       TLPN,
          @vLPNDetailId               TRecordId,
          @vReservedLPNDetailId       TRecordId,
          @vLPNDetailQuantity         TInteger,
          @vLPNOwner                  TOwnership,
          @vLPNType                   TTypeCode,
          @vNumLPNs                   TCount,
          @vLPNsAssigned              TCount,
          @vOrderId                   TRecordId,
          @vStatus                    TStatus,
          @vLPNBusinessUnit           TBusinessUnit,
          @vOrderBusinessUnit         TBusinessUnit,
          @vOrderOwner                TOwnership,
          @vOrderType                 TTypeCode,
          @vOrderStatus               TStatus,
          @vOrderWarehouse            TWarehouse,
          @vValidateOwnership         TFlag,
          @vOrderTypesToExportToPanda TFlags,
          @vWarehousesToExportToPanda TFlags,
          @vPalletId                  TRecordId,
          @vPickBatchId               TRecordId,
          @vPickBatchNo               TPickBatchNo,
          @vActivityType              TActivityType,

          @vInvResControlCategory     TCategory,
          @vInvReservationModel       TControlValue,

          @vDestLPNId                 TRecordId,
          @vDestLocationId            TRecordId,
          @vDestLocation              TLocation;
begin /* pr_Allocation_AllocateLPN */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @UnitsToAllocate = nullif(@UnitsToAllocate, 0);

  /* Fetch LPN and Order Info - if user did not pass in a SKU, then use the SKU
     of the LPN - assuming that it is a single SKU LPN */
  select @vLPN             = LPN,
         @LPNId            = LPNId,
         @vLPNType         = LPNType,
         @vLPNBusinessUnit = BusinessUnit,
         @SKUId            = coalesce(@SKUId, SKUId),
         @vPalletId        = PalletId,
         @vStatus          = Status,
         @vOrderId         = OrderId,
         @vLPNOwner        = Ownership
  from LPNs
  where (LPNId = @LPNId);

  select @OrderId            = OrderId,
         @vOrderStatus       = Status,
         @vOrderBusinessUnit = BusinessUnit,
         @vLPNsAssigned      = LPNsAssigned,
         @vOrderOwner        = Ownership,
         @vOrderType         = OrderType,
         @vOrderWarehouse    = Warehouse
  from OrderHeaders
  where (OrderId = @OrderId);

  select @Operation = case when ((@vLPNType <> 'L'/* Logical */) or (@vOrderType in ('R', 'RU', 'RP'/* Replenish */)))
                             then 'LPNResv'
                           else 'InventoryResv'
                      end -- if allocating a Carton LPN then don't create PR lines

  /* OrderDetailId or SKUId are required to process the allocation request */
  if (@OrderDetailId is not null)
    select @SKUId           = coalesce(@SKUId, SKUId), --Used coalesce to do not override i/p value. I think this not required.
           @vDestLocation   = DestLocation,
           @vDestLocationId = DestLocationId
    from OrderDetails
    where (OrderDetailId = @OrderDetailId);

  /* Get PickBatchId here */
  if (@OrderDetailId is not null)
    select @vPickBatchId = PickBatchId,
           @vPickBatchNo = PickBatchNo
    from PickBatchDetails
    where (OrderDetailId = @OrderDetailId);

  /* get the DestLocation/Logical LPN details to log the AT */
  select @vDestLPNId = LPNId
  from LPNs
  where (LocationId = @vDestLocationId) and
        (SKUId      = @SKUId);

  /* Fetch the DetailId which is not associated with any Order
     Currently we are allocating direct qty. That means we have replenish orderId on line.
     So, we need to consider that */
  select top 1 @vLPNDetailId       = LPNDetailId,
               @vLPNDetailQuantity = Quantity
  from LPNDetails
  where (LPNId   = @LPNId) and
        (SKUId   = @SKUId) and
        (AllocableQty > 0) and   -- Qty to allocate is the difference between Qty & ReservedQty
        (LPNDetailId = coalesce(@LPNDetailId, LPNDetailId)) and
        (((OrderId is null) and (OnhandStatus = 'A' /* Available */)) or
         ((ReplenishOrderId is not null) and (OnhandStatus = 'D' /* Directed */))); -- if it is a directed line then it would be Replenish Order Id

  /* If UnitsToAllocate is null/Zero, allocate available LPN Quantity */
  select @UnitsToAllocate            = coalesce(@UnitsToAllocate, @vLPNDetailQuantity),
         @vInvResControlCategory     = 'Allocation_' + @Operation,
         @vValidateOwnership         = dbo.fn_Controls_GetAsBoolean('Picking',    'ValidateOwnership',   'Y' /* Yes */,   @vOrderBusinessUnit, null /* UserId */),
         @vOrderTypesToExportToPanda = dbo.fn_Controls_GetAsBoolean('Panda',      'OrderTypesToExport',  ''  /* None */,  @vOrderBusinessUnit, null /* UserId */),
         @vWarehousesToExportToPanda = dbo.fn_Controls_GetAsBoolean('Panda',      'WarehousesToExport',  ''  /* None */,  @vOrderBusinessUnit, null /* UserId */),
         @vInvReservationModel       = dbo.fn_Controls_GetAsString (@vInvResControlCategory, 'InvReservationModel', 'I' /* Immediate */, @vOrderBusinessUnit, null /* UserId */);

  /* If Order Line is not specified, then find one that can be allocated against */
  if (@OrderDetailId is null)
    select top 1 @OrderDetailId = OrderDetailId
    from OrderDetails
    where (OrderId = @OrderId) and
          (SKUId   = @SKUId  ) and
          (UnitsToAllocate >= @UnitsToAllocate)
    order by UnitsToAllocate;

  /* Validations */
  if (@LPNId is null)
    set @vMessageName = 'InvalidLPN';
  else
  if (@OrderId is null)
    set @vMessageName = 'InvalidOrder';
  else
  if (@vLPNBusinessUnit <> @vOrderBusinessUnit)
    set @vMessageName = 'BusinessUnitMismatch';
  else
  if (@UnitsToAllocate > @vLPNDetailQuantity)
    set @vMessageName = 'InsufficientQtyToAllocate';
  else
  if (@OrderDetailId is null)
    set @vMessageName = 'NoOrderDetailToAllocate';
  else
  if (@vValidateOwnership = 'Y'/* Yes */) and (@vLPNOwner <> @vOrderOwner)
    set @vMessageName = 'Allocate_LPNOrderOwnerMismatch';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Return if there is no LPN detail to Allocate */
  if (@vLPNDetailId is null)
    return;

  /* Reserve the LPNDetail */
  exec @vReturnCode = pr_LPNDetails_ReserveQty @LPNId, @vLPNDetailId,
                                               @UnitsToAllocate,
                                               @OrderId, @OrderDetailId, @TaskDetailId,
                                               @SKUId, @vInvReservationModel,
                                               @vLPNBusinessUnit, @UserId,
                                               @vReservedLPNDetailId  output;

  /* Allocated LPN detail might not be the one which is passed so assign & return the allocated LPN Detail */
  /* set output variable with Reserved LPN DetailId */
  set @LPNDetailId = @vReservedLPNDetailId;

  /* We don't need to set OrderId here because when Line is added
     it should have called LPN_Recount which should have done it */
  /* OrderId would be null if the LPN is Partially allocated, so if OrderId is not null and
     if it is not a logical LPN then we would update PickBatchId on the LPN */
  /* Need to update Destlocation with the To-replenish location when the LPN got allocated to
     replenish order */
  update LPNs
  set --PackageSeqNo = case when OrderId is not null then coalesce(nullif(PackageSeqNo, 0), coalesce(@vLPNsAssigned, 0) + 1) else PackageSeqNo end,
      PickBatchId  = case when OrderId is not null and LPNType <> 'L' /* Logical */ then @vPickBatchId else null end,
      PickBatchNo  = case when OrderId is not null and LPNType <> 'L' /* Logical */ then @vPickBatchNo else null end,
      DestLocation = case when @vOrderType in ('RU', 'RP', 'R' /* Replenish */) and Status = 'A' /* Allocated */ then @vDestLocation else DestLocation end,
      ModifiedDate = current_timestamp,
      ModifiedBy   = System_User
  where (LPNId = @LPNId);

  /* Add to Load, if Order is on Load/Shipment */
  if (@vLPNType <> 'L' /* Logical */)
    exec pr_LPNs_AddToALoad @LPNId, null /* @BusinessUnit */, 'Y' /* Yes - @LoadRecount */;

  /* Update PickTicket Hdr/ Detail */
  /* Set PickTicket Detail Allocated Quantity, also increase UATS as needed*/
  update OrderDetails
  set UnitsAssigned         = UnitsAssigned + @UnitsToAllocate,
      UnitsAuthorizedToShip = case when @vOrderType in ('RU', 'RP', 'R' /* Replenish Orders */) then dbo.fn_MaxInt(UnitsAuthorizedToShip, UnitsAssigned + @UnitsToAllocate) else UnitsAuthorizedToShip end
  where (OrderDetailId = @OrderDetailId);

  if (@vPalletId is not null)
    exec pr_Pallets_UpdateCount @vPalletId, null, '*' /* Update Counts and Pallet status */

  /* This is already being done in Finalize wave once at the end, don't need to recount and update status
     after each LPN is allocated */
  -- /* Set PickTicket Header Counts and Status */
  -- exec @vReturnCode = pr_OrderHeaders_Recount @OrderId;
  --
  -- /* There is no need to recompute status of order if it is in allocated status
  --    and there is one more LPN allocated to it */
  -- if (@vReturnCode = 0) and (@vOrderStatus <> 'A' /* Allocated */)
  --   exec @vReturnCode = pr_OrderHeaders_SetStatus @OrderId;

  if (@vReturnCode > 0)
    goto ExitHandler;

  /* Export to Panda if LPN is allocated and is for the OrderType defined in control var
     and for the Warehouses defined in control var. Not all Warehouses would have Panda
     and not all OrderTypes would be processed thru Panda */
  if (charindex(@vOrderType, @vOrderTypesToExportToPanda) > 0) and
     (charindex(@vOrderWarehouse, @vWarehousesToExportToPanda) > 0)
    exec pr_PandA_AddLPNForExport @vLPN, default /* LPNs */,
                                  default /* LabelType */, default /* Label format */,
                                  null /* PandAStation */, null /* ProcessMode */,
                                  default /* DeviceId */, @vLPNBusinessUnit, null /* UserId */;

  /* Identify Activity Type */
  select @vActivityType = case when (@UnitsToAllocate = @vLPNDetailQuantity) and (@vLPNType <> 'L')
                                 then 'LPNAllocatedToOrderOnWave'
                               else 'UnitsAllocatedToOrderOnWave'
                          end;

  if (@vOrderType in ('RU', 'RP', 'R' /* Replenish */))
    select @vActivityType = 'Replenish_' + @vActivityType;

  /* Insert Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                            @LPNId         = @LPNId,
                            @ToLPNId       = @vDestLPNId,
                            @LocationId    = @vDestLocationId,
                            @SKUId         = @SKUId,
                            @OrderId       = @OrderId,
                            @OrderDetailId = @OrderDetailId,
                            @PickBatchId   = @vPickBatchId,
                            @Quantity      = @UnitsToAllocate;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateLPN */

Go
