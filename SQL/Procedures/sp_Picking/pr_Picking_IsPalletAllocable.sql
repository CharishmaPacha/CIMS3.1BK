/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/07/24  TK      pr_Picking_IsPalletAllocable: Create PickTasks for Pallet Allocation Initial Revision(FB-265)
  2012/10/31  PK/AY   pr_Picking_IsPalletAllocable: Changes of considering UnitsPerCarton
  2012/09/30  VM      pr_Picking_IsPalletAllocable: Do not allocate the pallets in which any one/more LPNs
  2012/09/24  PK      pr_Picking_AllocateLPN, pr_Picking_IsPalletAllocable: Ignoring Ownership while
  2012/08/12  PK      Added pr_Picking_AllocatePallet, pr_Picking_IsPalletAllocable, pr_Picking_FindPallet and corrected the
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_IsPalletAllocable') is not null
  drop Procedure pr_Picking_IsPalletAllocable;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_IsPalletAllocable: Given a Batch/PickTicket, this procedure
    determines if the LPNs on the Pallet can be allocated against the Order
    Details of the Batch/PickTicket. If so, it then allocates the Pallet as well.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_IsPalletAllocable
  (@PickBatchId   TRecordId  = null,
   @OrderId       TRecordId  = null,
   @PalletId      TRecordId,
   @BusinessUnit  TBusinessUnit,
   @Result        TFlag output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vPalletLPNDetailsCount  TCount,
          @vPickBatchNo            TPickBatchNo,
          @vLPNSKUId               TRecordId,
          @vLPNQuantity            TQuantity,
          @vLPNOwner               TOwnership,
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
           Quantity             TQuantity,
           OrderId              TRecordId,
           OrderDetailId        TRecordId,
           Processed            TFlag      default 'N');

begin /* pr_Picking_IsPalletAllocable */
begin try
  begin transaction;

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
     Pallet might not be candidate to allocate again in two cases
     1) Finding for a Pickbatch - if the allocated LPN(s) is allocated for an order, which is not related to the given Pickbatch
     or
     2) Finding for an Order - if the allocated LPN(s) is allocated for an order, which are different than the given order

     validate this in appropriate blocks below */

  /* Insert the Orders on the Batch which are to be allocated into temp table  */
  if (@PickBatchId is not null)
    begin
      if (exists(select LPNId from LPNs
                 where (PalletId = @PalletId) and
                       (Status   = 'A' /* Allocated */) and
                       (OrderId not in (select OrderId from OrderHeaders where PickBatchNo = @vPickBatchNo)))) /* LPN(s) Order not of given Pickbatch */
        /* As @Result = 'N' (Not allocated) anyway, just return from procedure */
        /* Modified to redirect to error handler to handle trasactions, but incase of any DML statements above this line of code, this might not be a right way to handle */
        goto ErrorHandler;

      insert into @ttOrderDetails (OrderId, PickTicket, OrderDetailId, SKUId,
                                   Ownership, UnitsToAllocate, UnitsPerCarton, SortOrder)
        select OH.OrderId, OH.PickTicket, OD.OrderDetailId, OD.SKUId,
               OH.Ownership, OD.UnitsToAllocate, OD.UnitsPerCarton,
               cast(OH.CancelDate as varchar(10)) + '-' + cast(OH.Priority as varchar)
        from OrderHeaders OH join OrderDetails OD on OH.OrderId = OD.OrderId
        where (OH.PickBatchNo     = @vPickBatchNo) and
              (OD.UnitsToAllocate > 0) and
              (OH.BusinessUnit    = @BusinessUnit);
    end
  else
  /* Insert the Orders into temp table  */
  if (@OrderId is not null)
    begin
      if (exists(select LPNId from LPNs
                 where (PalletId =  @PalletId) and
                       (Status   =  'A' /* Allocated */) and
                       (OrderId  <> @OrderId))) /* LPN Order not of given Order */
        /* As @Result = 'N' (Not allocated) anyway, just return from procedure */
        /* Modified to redirect to error handler to handle trasactions, but incase of any DML statements above this line of code, this might not be a right way to handle */
        goto ErrorHandler;

      insert into @ttOrderDetails (OrderId, PickTicket, OrderDetailId, SKUId,
                                   Ownership, UnitsToAllocate, UnitsPerCarton, SortOrder)
        select OH.OrderId, OH.PickTicket, OD.OrderDetailId, OD.SKUId,
               OH.Ownership, OD.UnitsToAllocate, OD.UnitsPerCarton,
               cast(OH.CancelDate as varchar(10)) + '-' + cast(OH.Priority as varchar)
        from OrderHeaders OH join OrderDetails OD on OH.OrderId = OD.OrderId
        where (OH.OrderId         = @OrderId) and
              (OD.UnitsToAllocate > 0) and
              (OH.BusinessUnit    = @BusinessUnit);
    end

  /* Insert the Pallet Details into temp table */
  if (@PalletId is not null)
    insert into @ttPalletDetails(PalletId, Pallet, LPNId, LPN, LPNDetailId,
                                 SKUId, SKU, UoM, Ownership, Quantity)
      select PalletId, Pallet, LPNId, LPN, LPNDetailId, SKUId, SKU, UoM, Ownership, Quantity
      from vwLPNDetails
      where (PalletId     = @PalletId) and
            (BusinessUnit = @BusinessUnit);

  /* Loop through all the LPNs of the pallet to verify wether the pallet matches with the Order */
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
            ((@vValidateUnitsPerCarton = 'N') or (@vUoM = 'PP') or (UnitsPerCarton = @vLPNQuantity)) /* and
            (Ownership       = @vLPNOwner) */
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

  commit transaction;
end try
begin catch
  rollback transaction;
  --If there are any issues with current Pallet, just skip it and continue to look for next pallet
end catch;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_IsPalletAllocable */

Go
