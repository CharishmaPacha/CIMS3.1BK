/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  AY      pr_Picking_ConfirmPicksAsShort, pr_Picking_ShortPickLPN: Use reason codes from control var (HA-1837)
  2018/08/02  AY      pr_Picking_ShortPickLPN: Prevent inventory adjustments in Shelving (OB2-415)
  2014/06/13  TD      pr_Picking_ShortPickLPN:Changes to pass LPNDetail to reduce the quantity while user
  2014/04/09  PV      pr_Picking_ShortPickLPN: Enhanced to create cycle count task
  2014/02/14  PK      pr_Picking_ShortPickLPN: Added a check to verify whether the LPN is already Lost or Voided before marking as Lost.
  2103/12/16  TD      pr_Picking_ShortPickLPN: New procedure
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ShortPickLPN') is not null
  drop Procedure pr_Picking_ShortPickLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ShortPickLPN: This procedure will be called when the user does
   a Short Pick due to inventory not being at or in the Location

    First we will unallocate all the lines reserved for any order.

    If the LPN is Picklane (Logical) type then we will update that qty to 0,
     else we will mark the LPN as Lost.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ShortPickLPN
  (@LPNId           TRecordId,
   @LPNDetailId     TRecordId   output,
   @SKUId           TRecordId = null,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ReturnCode     TInteger,
          @CCMessage      TDescription,
          @MessageName    TMessageName,
          @vMessage       TDescription,
          @vLPNLocationId TRecordId,
          @vLPNId         TRecordId,
          @vLPN           TLPN,
          @vLPNType       TTypeCode,
          @vLPNSKUId      TRecordId,
          @vLPNStatus     TStatus,
          @vQtyToAdjustOnLPNDetail
                          TQuantity,
          @vShortPick_UnallocateUnits
                          TControlValue,
          @vShortPick_AdjustQty
                          TControlValue,
          @vUpdateOption  TFlag,

          /* temp table   declarations */
          @LPNs           TEntityKeysTable;
begin /* pr_Picking_ShortPickLPN */

  select @ReturnCode  = 0,
         @MessageName = null,
         @SKUId       = nullif(@SKUId, 0);

  /* Get the control variable to reduce the quantity from short pick location */
  select @vShortPick_UnallocateUnits = dbo.fn_Controls_GetAsString('ShortPick', 'UnallocateUnits', 'CurrentPick',
                                                                   @BusinessUnit, @UserId),
         @vShortPick_AdjustQty       = dbo.fn_Controls_GetAsString('ShortPick', 'ReduceQty', 'None',
                                                                   @BusinessUnit, @UserId);

  /* Get LPN info */
  select @vLPN           = LPN,
         @vLPNType       = LPNType,
         @vLPNSKUId      = coalesce(@SKUId, SKUId),
         @vLPNStatus     = Status,
         @vLPNLocationId = LocationId
  from  vwLPNs
  where (LPNId = @LPNId);

  /* Validations */

  /* Validate at least LPN status here... LPN has to be PA or allocated */
  if (charindex(@vLPNStatus, 'SOCV' /* Shipped/Lost/Consumed/Voided */) > 0)
    set @MessageName = 'CannotPickLostOrVoidedLPN';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* When user short picks at a Picklane Location, we have three options related to the Qty
     a. Clear out entire Location
     b. Reduce Qty of Location by Current Pick Qty
     c. Do not change anything related to the Qty in the Location - default
     Seems like this code move to Logical LPN block. But we need to get the quantity before LPN Detail Unallocate */
  select @vQtyToAdjustOnLPNDetail = case
                                      when (@vShortPick_AdjustQty = 'Clear') then 0
                                      when (@vShortPick_AdjustQty = 'CurrentPick') then Quantity
                                      else 0 /* No change */
                                    end,
         @vUpdateOption           = case
                                      when (@vShortPick_AdjustQty = 'Clear') then '='
                                      when (@vShortPick_AdjustQty = 'CurrentPick') then '-'
                                      else  '+' /* Should not even call adjust qty, even if we do, it would + zero units */
                                    end
  from LPNDetails
  where LPNDetailId = @LPNDetailId;

  /* unallocate all the Lines or only the current Pick based upon control vars */
  if (@vShortPick_UnallocateUnits = 'AllPicks')
    exec pr_LPNs_Unallocate @LPNId, @LPNs, 'N' /* unallocate Pallet */, @BusinessUnit, @UserId;
  else
    /* unallocate the LPN Detail they are short picking without affecting other orders */
    exec pr_LPNDetails_Unallocate @LPNId, @LPNDetailId, @UserId, 'ShortPick';

  /* the  given LPN is not a picklane type, then we need to mark that LPN as Lost */
  if (@vShortPick_AdjustQty) = 'None'
    select @MessageName = @MessageName; -- Do Nothing!
  else
  /* If LPN, then only mark it as lost if AdjustQty directs to clear it, else do nothing with it */
  if (@vLPNType <> 'L' /* Logical/picklane */) and (@vShortPick_AdjustQty = 'Clear')
    begin
      exec pr_LPNs_Lost @LPNId, '120' /* ReasonCode */, @UserId,
                        Default /* Clear Pallet */, 'LPNShortPicked' /* Audit Activity */;
    end
  else
  /* So, the directive would be either to Clear or to adjust by Current Pick */
  if (@vLPNType = 'L' /* Logical/picklane */)
    begin
      /* When user short picks at a Picklane Location, we would want to zero out
         the qty of the location.
         Case: We are calling Unallocate procedure above, in that we are calling
         LPNAdjust , that will add or remove LPN line, so it may differ from the given
         LPNDetailId, so we need to re-get the available line to reduce the qty */

      select @LPNDetailId = LPNDetailId
      from LPNDetails
      where (LPNId = @LPNId) and
            (OnHandStatus = 'A' /* Available */) and
            (Quantity > 0);

      exec @ReturnCode = pr_LPNs_AdjustQty @LPNId,
                                           @LPNDetailId output,
                                           @vLPNSKUId,
                                           null,  /* SKU */
                                           null,
                                           @vQtyToAdjustOnLPNDetail,
                                           @vUpdateOption,   /* Update Option - Add Qty */
                                           'Y',   /* Export? Yes */
                                           121,   /* Reason Code */
                                           null,  /* Reference */
                                           @BusinessUnit,
                                           @UserId;
    end

  /* On Short pick, create cycle count task on the Location */
  if (@ReturnCode = 0)
    exec @ReturnCode = pr_Locations_CreateCycleCountTask @vLPNLocationId,
                                                         'ShortPick',
                                                         @UserId,
                                                         @BusinessUnit,
                                                         @CCMessage output;

  if (@ReturnCode > 0)
    select @MessageName = @CCMessage;

  /* TODO: We need to route the carton to Shelving location, we need to send
           it to specific zone */
  /* insert the Router Instruction into RouterInstruction table */
  --exec @ReturnCode = pr_Router_SendRouteInstruction @LPNId, @vLPN, @LPNs /* @ttPackedLPNs */,
  --                                                  'Shelving' /* @Destination */, default /* WorkId */,
  --                                                  'N' /* @ForceExport */,
  --                                                  @BusinessUnit, @UserId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Picking_ShortPickLPN */

Go
