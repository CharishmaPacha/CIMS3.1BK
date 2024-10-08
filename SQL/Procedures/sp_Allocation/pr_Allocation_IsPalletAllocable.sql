/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/12/01  AY      pr_Allocation_IsPalletAllocable: Use save points instead of rolling back transaction
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_IsPalletAllocable') is not null
  drop Procedure pr_Allocation_IsPalletAllocable;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_IsPalletAllocable: Given a Batch/PickTicket, this procedure
    determines if the LPNs on the Pallet can be allocated against the Order
    Details of the Batch/PickTicket. If so, it then allocates the Pallet as well.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_IsPalletAllocable
  (@PickBatchId              TRecordId  = null,
   @OrderId                  TRecordId  = null,
   @ttOrderDetailsToAllocate TOrderDetailsToAllocateTable ReadOnly,
   @PalletId                 TRecordId,
   @BusinessUnit             TBusinessUnit,
   @Result                   TFlag output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vPalletLPNDetailsCount  TCount,
          @vPickBatchNo            TPickBatchNo,
          @vLPNSKUId               TRecordId,
          @vLPNQuantity            TQuantity,
          @vLPNOwner               TOwnership,
          @vLPNWarehouse           TWarehouse,
          @vOrderDetailId          TRecordId,
          @vOrderId                TRecordId,
          @vODRecordId             TRecordId,
          @vLPNDetailRecordId      TRecordId,
          @PalletDetails           XML,
          @vUoM                    TUoM,
          @vUnitsPerCarton         TInteger,
          @vValidateUnitsPerCarton TFlag;

  declare @ttOrderDetails Table
          (RecordId             TRecordId  identity (1,1),
           OrderId              TRecordId,
           PickTicket           TPickTicket,
           OrderDetailId        TRecordId,
           Ownership            TOwnership,
           Warehouse            TWarehouse,
           SKUId                TRecordId,
           SKU                  TSKU,
           UnitsToAllocate      TQuantity,
           UnitsPerCarton       TInteger,
           SortOrder            TVarchar,
           Processed            TFlag     default 'N');

  declare @ttPalletDetails Table
          (RecordId             TRecordId  identity (1,1),
           PalletId             TRecordId,
           Pallet               TPallet,
           LPNId                TRecordId,
           LPN                  TLPN,
           LPNDetailId          TRecordId,
           SKUId                TRecordId,
           SKU                  TSKU,
           UoM                  TUoM,
           Ownership            TOwnership,
           Warehouse            TWarehouse,
           Quantity             TQuantity,
           OrderId              TRecordId,
           OrderDetailId        TRecordId,
           Processed            TFlag      default 'N');

begin /* pr_Allocation_IsPalletAllocable */
begin try
  save transaction IsPalletAllocable;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @Result       = 'N';

  /* select BatchNo */
  select @vPickBatchNo = BatchNo
  from PickBatches
  where (RecordId = @PickBatchId);

  /* Get the Control Variable to validate UnitsPerCarton and the LPNQuantity if they are not equal */
  select @vValidateUnitsPerCarton = dbo.fn_Controls_GetAsBoolean('Picking', 'ValidateUnitsperCarton', 'Y' /* Yes */, @BusinessUnit, null /* UserId */);

  /* If any one or more LPNs on the Pallet is already allocated for an Order,
     Pallet might NOT be candidate to allocate again in two cases
     1) Finding for a Pickbatch - if the allocated LPN(s) is allocated for an order, which is not related to the given Pickbatch
     or
     2) Finding for an Order - if the allocated LPN(s) is allocated for an order, which are different than the given order

     validate this in appropriate blocks below */

  if (@PickBatchId is not null)
    begin
      if (exists(select LPNId from LPNs
                 where (PalletId = @PalletId) and
                       (Status   = 'A' /* Allocated */) and
                       (OrderId not in (select OrderId from OrderHeaders where PickBatchNo = @vPickBatchNo)))) /* LPN(s) Order not of given Pickbatch */
        /* As @Result = 'N' (Not allocated) anyway, just return from procedure */
        /* Modified to redirect to error handler to handle trasactions, but incase of any DML statements above this line of code, this might not be a right way to handle */
        goto ErrorHandler;
    end
  else
  if (@OrderId is not null)
    begin
      if (exists(select LPNId from LPNs
                 where (PalletId =  @PalletId) and
                       (Status   =  'A' /* Allocated */) and
                       (OrderId  <> @OrderId))) /* LPN Order not of given Order */
        /* As @Result = 'N' (Not allocated) anyway, just return from procedure */
        /* Modified to redirect to error handler to handle trasactions, but incase of any DML statements above this line of code, this might not be a right way to handle */
        goto ErrorHandler;
    end

  /* The input table @ttOrderDetailsToAllocate has the order details to allocate, but don't rely on
     the UnitsToAllocate from it and instead fetch from OrderDetails table as the table variable
     is not updated in the loop as pallets are getting allocated */
  insert into @ttOrderDetails (OrderId, PickTicket, OrderDetailId, SKUId,
                               Ownership, Warehouse, UnitsToAllocate, UnitsPerCarton, SortOrder)
    select ODA.OrderId, OH.PickTicket, ODA.OrderDetailId, ODA.SKUId,
           OH.Ownership, OH.Warehouse, OD.UnitsToAllocate, OD.UnitsPerCarton,
           cast(OH.CancelDate as varchar(10)) + '-' + cast(OH.Priority as varchar)
    from @ttOrderDetailsToAllocate ODA
      join OrderHeaders OH on ODA.OrderId = OH.OrderId
      join OrderDetails OD on ODA.OrderDetailId = OD.OrderDetailId
    where (OD.UnitsToAllocate > 0) and
          (OH.BusinessUnit    = @BusinessUnit);

  /* Insert the Pallet Details into temp table */
  if (@PalletId is not null)
    insert into @ttPalletDetails(PalletId, Pallet, LPNId, LPN, LPNDetailId,
                                 SKUId, SKU, UoM, Ownership, Warehouse, Quantity)
      select PalletId, Pallet, LPNId, LPN, LPNDetailId, SKUId, SKU, UoM, Ownership, DestWarehouse,
             Quantity
      from vwLPNDetails
      where (PalletId     = @PalletId) and
            (BusinessUnit = @BusinessUnit);

  /* Loop through all the LPNs of the pallet to verify whether the pallet matches with the Order */
  while exists(select * from @ttPalletDetails where Processed = 'N'/* No */)
    begin
      select @vLPNQuantity    = null,
             @vLPNSKUId       = null,
             @vOrderDetailId  = null,
             @vOrderId        = null;

      /* select top 1 LPNs Quantity from PalletDetails table */
      select top 1 @vLPNQuantity       = Quantity,
                   @vLPNSKUId          = SKUId,
                   @vLPNDetailRecordId = RecordId,
                   @vLPNOwner          = Ownership,
                   @vLPNWarehouse      = Warehouse,
                   @vUoM               = UoM
      from @ttPalletDetails
      where OrderId is null
      order by Quantity desc, LPN;

      /* Find an Order to allocate the selected LPN */
      select top 1 @vOrderDetailId  = OrderDetailId,
                   @vOrderId        = OrderId,
                   @vODRecordId     = RecordId
      from @ttOrderDetails
      where (UnitsToAllocate >= @vLPNQuantity) and
            (SKUId           = @vLPNSKUId) and
            ((@vValidateUnitsPerCarton = 'N') or (@vUoM = 'PP') or (UnitsPerCarton = @vLPNQuantity)) and
            (Ownership       = @vLPNOwner) and
            (Warehouse       = @vLPNWarehouse)
      order by SortOrder;

      /* If there is no matching Order Detail for the selected LPN, then the
         Pallet is not allocable as there is at least one LPN on the Pallet
        which cannot be allocated, hence break loop and exit */
      if (@vOrderDetailId is null)
        break;

      /* Update the LPN with Order details to signify that this LPN is matched
         with this Order Detail */
      update @ttPalletDetails
      set OrderId       = @vOrderId,
          OrderDetailId = @vOrderDetailId,
          Processed     = 'Y' /* Yes */
      where (RecordId = @vLPNDetailRecordId);

      /* Update the UnitsToAllocate on OrderDetail to reflect the matching */
      update @ttOrderDetails
      set UnitsToAllocate =  (UnitsToAllocate - @vLPNQuantity)
      where (RecordId = @vODRecordId);
    end

  if (not (exists(select * from @ttPalletDetails
                  where OrderId is null)))
    begin
      /* Build XML with the Pallet details */
      select @PalletDetails = (select *
                               from @ttPalletDetails
                               for XML raw('PalletDetails'), elements );

      exec pr_Picking_AllocatePallet @PalletDetails, @PickBatchId, @PalletId;

      select @Result = 'Y';
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  --commit transaction;
end try
begin catch
  /* Unless it is an irrecoverable error, then rollback for this Pallet only. However
     if it is an error that cannot be recovered, then exit */
  if (XAct_State() <> -1)
    rollback transaction IsPalletAllocable;
  else
    exec pr_ReRaiseError;

end catch;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_IsPalletAllocable */

Go
