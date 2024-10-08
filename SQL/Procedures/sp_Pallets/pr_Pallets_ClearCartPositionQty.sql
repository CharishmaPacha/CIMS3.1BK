/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/12/13  VIB     pr_Pallets_ClearCart: Added new validations for cart position and task status is not completed 
                      pr_Pallets_ClearCartPositionQty:Made changes to Unallocate the LPNs when clearing the cart (JLFL-814)
              TK      pr_Pallets_ClearCartPositionQty: Initial Revision
                      pr_Pallets_UnassignFromTask: Initial Revision (HPI-917)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_ClearCartPositionQty') is not null
  drop Procedure pr_Pallets_ClearCartPositionQty;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_ClearCartPositionQty: This proc clears all the inventory on the Cart positions
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_ClearCartPositionQty
  (@PalletId       TRecordId,
   @Options        TFlags,
   @ReasonCode     TReasonCode,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vRecordId       TRecordId,
          @vLPNId          TRecordId,
          @vLPN            TLPN,
          @vLPNDetailId    TRecordId,
          @vSKUId          TRecordId,
          @vSKU            TSKU,
          @vLPNDetailIPs   TInnerPacks,
          @vLPNDetailQty   TQuantity;

  declare @ttLPNDetailsToAdjust table (RecordId           TRecordId identity(1,1),
                                       LPNId              TRecordId,
                                       LPN                TLPN,
                                       LPNDetailId        TRecordId,
                                       SKUId              TRecordId,
                                       SKU                TSKU,
                                       InnerPacks         TInnerPacks,
                                       LPNDetailQuantity  TQuantity);

begin
  SET NOCOUNT ON;

  select @vReturnCode = 0,
         @vRecordId   = 0;

  /* Get the positions whose Qty needs to be adjusted */
  insert into @ttLPNDetailsToAdjust (LPNId, LPN, LPNDetailId, SKUId, SKU, InnerPacks, LPNDetailQuantity)
    select LPNId, LPN, LPNDetailId, SKUId, SKU, InnerPacks, Quantity
    from vwLPNDetails
    where (PalletId = @PalletId) and
          (Quantity > 0) and
          (LPNType  = 'A' /* Cart */);

  /* Loop thru each detail and adjust the Qty down to zero */
  while (exists (select * from @ttLPNDetailsToAdjust where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId      = RecordId,
                   @vLPNId         = LPNId,
                   @vLPN           = LPN,
                   @vLPNDetailId   = LPNDetailId,
                   @vSKUId         = SKUId,
                   @vSKU           = SKU,
                   @vLPNDetailIPs  = InnerPacks,
                   @vLPNDetailQty  = LPNDetailQuantity
      from @ttLPNDetailsToAdjust
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Adjust the LPNQuantity with new ReasonCode  */
      exec pr_LPNs_AdjustQty @vLPNId,
                             @vLPNDetailId,
                             @vSKUId,
                             @vSKU,
                             0,
                             0,
                             '='  /* Update Option - Subtract Qty */,
                             'Y'  /* Export? No */,
                             @ReasonCode,
                             null /* Reference */,
                             @BusinessUnit,
                             @UserId;

      /* Log AT on LPN adjustment */
      exec pr_AuditTrail_Insert 'LPNAdjustQty', @UserId, null /* ActivityTimestamp */,
                                @LPNId          = @vLPNId,
                                @LPNDetailId    = @vLPNDetailId,
                                @InnerPacks     = 0,
                                @Quantity       = 0,
                                @PrevInnerPacks = @vLPNDetailIPs,
                                @PrevQuantity   = @vLPNDetailQty,
                                @ReasonCode     = @ReasonCode;
    end

  /* Update counts on the pallet */
  exec pr_Pallets_UpdateCount @PalletId, null /* Pallet */, '*' /* UpdateOption */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_ClearCartPositionQty */

Go
