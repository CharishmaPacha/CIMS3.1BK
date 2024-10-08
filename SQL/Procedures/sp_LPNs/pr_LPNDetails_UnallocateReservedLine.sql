/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/28  SK      pr_LPNDetails_UnallocateReservedLine: Find merge line based on InventoryKey (HA-3963)
  2018/02/14  TK      pr_LPNDetails_Unallocate: Enhanced to handle Pending Reservation line un-allocation
                      pr_LPNDetails_UnallocatePendingReserveLine: Initial Revision
                      pr_LPNDetails_UnallocateReservedLine: Initial Revision (S2G-180)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_UnallocateReservedLine') is not null
  drop Procedure pr_LPNDetails_UnallocateReservedLine;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_UnallocateReservedLine: Unallocates an LPN Detail, cancels the task detail if
    there is one. Merges the unallocated line with the available line or flips
    the unallocated line to available.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_UnallocateReservedLine
  (@LPNDetailId      TRecordId,
   @UserId           TUserId,
   @Operation        TOperation = null)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vBusinessUnit             TBusinessUnit,

          @vLPNId                    TRecordId,
          @vLPNStatus                TStatus,

          @vLPNDetailId              TRecordId,
          @vLPNDetailLot             TLot,
          @vInnerPacks               TInnerPacks,
          @vQuantity                 TQuantity,
          @vOnhandStatus             TStatus,

          @vSKUId                    TRecordId,
          @vOrderId                  TRecordId,
          @vOrderDetailId            TRecordId,
          @vReplenishOrderId         TRecordId,
          @vReplenishOrderDetailId   TRecordId,
          @vMergeLPNDetailId         TRecordId;
begin
  SET NOCOUNT ON;

  /* Fetch the details of the LPN Detail */
  select @vLPNDetailId            = LPNDetailId,
         @vLPNId                  = LPNId,
         @vInnerPacks             = InnerPacks,
         @vQuantity               = Quantity,
         @vSKUId                  = SKUId,
         @vOnhandStatus           = OnhandStatus,
         @vOrderDetailId          = OrderDetailId,
         @vOrderId                = OrderId,
         @vReplenishOrderId       = ReplenishOrderId,
         @vReplenishOrderDetailId = ReplenishOrderDetailId,
         @vLPNDetailLot           = Lot,
         @vBusinessUnit           = BusinessUnit
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Get LPN info */
  select @vLPNStatus = Status
  from LPNs
  where (LPNId = @vLPNId);

  /* If we are unallocating a Reserved Line, we need to find an Available Detail line on the same LPN
     If we are unallocating a Directed-Reserved line, then we need to find a Directed Line on the LPN
       for the same Replenish OrderId as that of the DR Line */
  select Top 1 @vMergeLPNDetailId = LPNDetailId
  from LPNDetails
  where (LPNId = @vLPNId ) and
        (SKUId = @vSKUId ) and
        (((@vOnhandStatus = 'R' /* Reserved */) and (OnhandStatus = 'A' /* Available */))
         or
         ((@vOnhandStatus = 'DR' /* directed reserved */) and
          (OnhandStatus = 'D' /* Directed */) and
          (Quantity > 0) and
          /* There could be a possibility of different replenish order D line than current LPNDetail replenish order
             and hence, the following couple of lines skip to identify the right D line.
             Impact would be multiple D lines.
             So, considering there will be only one D line for each Location, ignore(commented) to consider Replenish order */
          (ReplenishOrderId = @vReplenishOrderId) and
          (ReplenishOrderDetailId = @vReplenishOrderDetailId)
          )) and
        ((coalesce(Lot, '')) = (coalesce(@vLPNDetailLot, '')));  -- There could be details with Multiple Lot so search for Lot which is matching the detail lot which is being un-allocated

  /* If there is an Available/Directed detail for the same SKU in the LPN, then merge the
     qty with it, else just flip the existing one to available */
  if (coalesce(@vMergeLPNDetailId, 0) > 0)
    begin
      /* Add inventory to the Available (in case of R is unallocated) or Directed line (in case of DR line unallocated) */
      exec @vReturnCode = pr_LPNs_AdjustQty @vLPNId, @vMergeLPNDetailId, @vSKUId, null /* SKU */,
                                            @vInnerPacks, @vQuantity, '+' /* Update Option - Add*/,
                                            'N' /* No-Export Option */, 0 /* Reason code */,
                                            null /* Reference */, @vBusinessUnit, @UserId;

      /* Decrement the 'Reserved' line, it will be deleted as it should reduce to zero */
      exec @vReturnCode = pr_LPNs_AdjustQty @vLPNId, @vLPNDetailId, @vSKUId, null /* SKU */,
                                            @vInnerPacks, @vQuantity, '-' /* Update Option  - Subtract */,
                                            'N' /* No-Export Option */, 0 /* Reason code */,
                                            null /* Reference */, @vBusinessUnit, @UserId;
    end
  else
  /* VM_20150129: What if LPN Status is in Putaway, Reserve counts on LPN shouldn't be corrected after unallocation ??? */
  if (@vLPNStatus in ('O' /* Lost */, 'V' /* Voided */))
    begin
      /* If lost or Voided LPN, Decrement the 'Reserved' line, it will be deleted as it should reduce to zero */
      exec @vReturnCode = pr_LPNs_AdjustQty @vLPNId, @vLPNDetailId, @vSKUId, null /* SKU */,
                                            @vInnerPacks, @vQuantity, '-' /* Update Option  - Subtract */,
                                            'N' /* No-Export Option */, 0 /* Reason code */,
                                            null /* Reference */, @vBusinessUnit, @UserId;
    end
  else
    begin
      update LPNDetails
      set OnhandStatus  = case
                            when OnhandStatus = 'DR' /* Directed Reserve */ then 'D' /* Directed */
                            when OnhandStatus = 'R' /* Reserved */ then 'A' /* Available */
                            else OnhandStatus
                          end,
          ReservedQty   = 0,
          OrderId       = null,
          OrderDetailId = null,
          ModifiedDate  = current_timestamp,
          ModifiedBy    = coalesce(@UserId, System_User)
      where (LPNDetailId = @vLPNDetailId);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_UnallocateReservedLine */

Go
