/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/19  VM      pr_LPNs_UpdateOrderOnAdjust: Call changes in updating counts on Wave (CIMSV3-2715)
              VM      pr_LPNDetails_CancelReplenishQty, pr_LPNDetails_Unallocate, pr_LPNs_UpdateOrderOnAdjust (HPI-692):
                      Added pr_LPNs_UpdateOrderOnAdjust.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_UpdateOrderOnAdjust') is not null
  drop Procedure pr_LPNs_UpdateOrderOnAdjust;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_UpdateOrderOnAdjust:

  This procedure will update the counts of the order and batch if the allocated
    LPN is adjusted.
-------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_UpdateOrderOnAdjust
  (@OrderId         TRecordId,
   @OrderDetailId   TRecordId,
   @QuantityChange  TQuantity,
   @NewQuantity     TQuantity,
   @UoM             TUoM,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ReturnCode              TInteger,
          @MessageName             TMessageName,

          @vLPNId                  TRecordId,
          @vOrderId                TRecordId,
          @vOrderDetailId          TRecordId,
          @vPickBatchNo            TPickBatchNo,
          @vUnitsOrdered           TQuantity,
          @vUnitsAuthorizedToShip  TQuantity,
          @vUnitsAssigned          TQuantity,
          @vUnitsPerCarton         TQuantity,
          @OrderToUpdate           TEntityKeysTable,
          @vValidateUnitsPerCarton TFlag;
begin
  SET NOCOUNT ON;

  /* Get Order header information */
  select @vOrderId      = OrderId,
         @vPickBatchNo  = PickBatchNo
  from vwOrderHeaders
  where (OrderId = @OrderId);

  /* Get the Order detail information */
  select @vOrderDetailId         = OrderDetailId,
         @vUnitsAuthorizedToShip = UnitsAuthorizedToShip,
         @vUnitsAssigned         = UnitsAssigned,
         @vUnitsPerCarton        = UnitsPerCarton
  from OrderDetails
  where (OrderDetailId = @OrderDetailId);

  /* Get the Control Variable to validate UnitsPerCarton and the LPNQuantity if they are not equal */
  select @vValidateUnitsPerCarton = dbo.fn_Controls_GetAsBoolean('Picking', 'ValidateUnitsperCarton', 'Y' /* Yes */, @BusinessUnit, @UserId);

  /* Validations */
  /* 1. if the user adjusts the qty greater than the Units Authorized to ship, then raise the error */
  if ((@vUnitsAssigned + @QuantityChange) > @vUnitsAuthorizedToShip)
    set @MessageName = 'AdjAllocLPN_AdjQtyIsGreaterThanOrderedQty';
  else
  if (@vValidateUnitsPerCarton = 'Y'/* Yes */) and
     ((@UoM <> 'PP'/* Prepack */) and (@vUnitsPerCarton <> @NewQuantity))
    set @MessageName = 'AdjAllocLPN_LPNQtyMismatchWithUnitsPerCarton';

  /* if message name is not null then raise the error */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* if the Order is not null then update the order */
  if (@vOrderId is not null)
    begin
      /* Reduce Order Units assigned with old LPN Qty and increase with LPN latest qty */
      update OrderDetails
      set UnitsAssigned = dbo.fn_MaxInt((UnitsAssigned + @QuantityChange), 0)
      where (OrderDetailId = @vOrderDetailId);

      /* Insert the Order into temp table */
      insert into @OrderToUpdate (EntityId)
        select @vOrderId;

      /* Recounts the Order and updates the status of the Orders */
      exec pr_OrderHeaders_Recalculate @OrderToUpdate, 'C', @UserId;
    end

  /* if the batch no is not null then update the batch info */
  if (@vPickBatchNo is not null)
    begin
      /* Batch update counts after the order counts are updated */
      exec pr_PickBatch_UpdateCounts @vPickBatchNo;

      /* Update the Status of the batch once after the counts on the batch is updated */
      exec pr_PickBatch_SetStatus @vPickBatchNo;
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_UpdateOrderOnAdjust */

Go
