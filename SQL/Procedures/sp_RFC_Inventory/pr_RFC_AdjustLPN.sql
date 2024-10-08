/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/16  AY      pr_RFC_AdjustLPN: Allow adjustment of picked LPNs (HA-2652)
  2021/03/13  SJ/TK   pr_RFC_AdjustLPN: Cannot adjust the quantity over ship quantity for temp LPNs (HA-2175)
  2021/02/15  TK      pr_RFC_AdjustLocation & pr_RFC_AdjustLPN: Validation to restrict user adjusting quantity less than reserved quantity (CID-1724)
  2020/12/18  RIA     pr_RFC_AdjustLPN: Changes to consider LPNDetailId and cleanup (CIMSV3-1236)
  2016/10/14  AY      pr_RFC_AdjustLPN: Allow adjusting allocated LPNs
  2016/05/24  OK      pr_RFC_AdjustLPN: Enhanced to display the Original Quantity in Audit Trail (HPI-121)
  2015/01/22  VM      pr_RFC_AdjustLPN: Allow adjusting of Cart positios (LPNs)
  2014/07/22  VM      pr_RFC_AdjustLPN: Send Reasoncode to AT to log reason
  2014/04/22  TD      pr_RFC_AdjustLocation/pr_RFC_AdjustLPN: Ensure user gives ReasonCode when adjusting Quantity.
  2014/02/28  PK      pr_RFC_AdjustLPN, pr_RFC_ValidateLPN: Added validations for not allowing to adjust allocated LPN/Line.
  2013/10/30  TD      pr_RFC_AdjustLPN:Added ReasonCode.
  2013/05/14  AY      pr_RFC_AdjustLPN: Audit trial not right when multi-SKU LPN is adjusted. Fixed it.
  2013/03/27  AY      pr_RFC_AdjustLocation & pr_RFC_AdjustLPN: Used function to fetch SKUs
  2012/11/30  PK      pr_RFC_AdjustLPN: Adjusting allocated LPN based on the control variable.
  2012/10/22  YA      pr_RFC_AdjustLPN: Validation for adjusting LPN quantity if the quantity is same previously.
  2012/09/12  YA      pr_RFC_AdjustLPN: Do not allow adjustment of Allocated LPN
  2011/03/11  VK      Added LPNDetailId to the procedure pr_RFC_AdjustLPN and changed the functionality.
  2010/12/31  VK      Made Status validations to pr_RFC_MoveLPN,pr_RFC_AdjustLPN
                      pr_RFC_AddSKUToLPN, pr_RFC_AdjustLPN, pr_RFC_TransferInventory.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_AdjustLPN') is not null
  drop Procedure pr_RFC_AdjustLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_AdjustLPN: This procedure gets called from RF and here we will perform
    some basic validations and call the core procedure to adjust the quantity.

  Adjusting Reserved qty: We shsould be able to adjust reserved qty on an LPN after
  it is picked i.e picked/packed/staged because they may find that some of the items
  are damaged or they confirmed they picked all, but realize later there is a short.
  However, for LPNs that are not picked, we do not want to adjust the qty because
  there is a task to pick that qty and user would short pick if there is not sufficient inventory.
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_AdjustLPN
  (@LPNId            TRecordId,
   @LPN              TLPN,
   @LPNDetailId      TRecordId,
   @CurrentSKUId     TRecordId,
   @CurrentSKU       TSKU,
   @NewInnerPacks    TInnerPacks, /* Future Use */
   @NewQuantity      TQuantity,
   @ReasonCode       TReasonCode = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TMessage,
          @vNote1                 TDescription,
          @DeviceId               TDeviceId,

          @vLPNDetailId           TRecordId,
          @vLPNId                 TRecordId,
          @vLPNType               TTypeCode,
          @vLPNStatus             TStatus,
          @vLPNOrderId            TRecordId,
          @vOrderDetailId         TRecordId,
          @vLPNReservedQty        TQuantity,
          @vLPNLineCount          TCount,
          @vCurrentSKUId          TRecordId,
          @vCurrentSKU            TSKU,
          @vLPNDOnhandStatus      TStatus,
          @vLPNDInnerPacks        TInnerPacks,
          @vLPNDQuantity          TQuantity,
          @vMaxQtyToAdjust        TQuantity,
          @vQtyAssigned           TQuantity,
          @vQtyToShip             TQuantity,
          @vUnitsToAllocate       TQuantity,
          @vQtyIncrement          TQuantity,

          @vActivityLogId         TRecordId,
          @xmlResult              xml;
begin
begin try
  SET NOCOUNT ON;

  select @CurrentSKUId    = nullif(@CurrentSKUId, 0),
         @LPNDetailId     = nullif(@LPNDetailId, 0),
         @ReasonCode      = nullif(@ReasonCode, ''),
         @vQtyAssigned    = 0;

  /* 1. Validate LPN,
     2. Validate SKU,
     3. Validate Quantity */
  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @vLPNId, @LPN,'LPN', 'AdjustLPN', @vMessageName, @Value1 = @vLPNId, @Value2 = @LPN, @Value3 = @NewQuantity,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Validate LPN */
  select @LPNId           = LPNId,
         @LPN             = LPN,
         @vLPNId          = LPNId,
         @vLPNType        = LPNType,
         @vLPNStatus      = Status,
         @vLPNOrderId     = OrderId,
         @vLPNReservedQty = ReservedQty
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@LPNId, @BusinessUnit, 'I' /* Options */));

  /* Validate SKU */
  if (@CurrentSKUId is not null)
    select @vCurrentSKUId = SKUId,
           @vCurrentSKU   = SKU
    from SKUs
    where (SKUId  = @CurrentSKUId);
  else
    select @vCurrentSKUId = SKUId,
           @vCurrentSKU   = SKU
    from dbo.fn_SKUs_GetScannedSKUs (@CurrentSKU, @BusinessUnit);

  /* If LPNDetailId is given, then use it, else
     select an Available LPNDetail to adjust */
  if (@LPNDetailId is null)
    select @vLPNDetailId = LPNDetailId
    from LPNDetails
    where (LPNId = @LPNId) and
          (SKUId = @vCurrentSKUId);
  else
    select @vLPNDetailId = @LPNDetailId;

  /* Get the LPN Onhand Status to validate */
  select @vLPNDOnhandStatus = OnhandStatus,
         @vLPNDInnerPacks   = InnerPacks,
         @vLPNDQuantity     = Quantity,
         @vOrderDetailId    = OrderDetailId,
         @vQtyIncrement     = @NewQuantity - Quantity
  from LPNDetails
  where (LPNDetailId = @vLPNDetailId);

  /* Get the units to be shipped */
  if (@vOrderDetailId > 0)
    select @vQtyToShip       = UnitsAuthorizedToShip,
           @vUnitsToAllocate = UnitsToAllocate
    from OrderDetails
    where (OrderDetailId = @vOrderDetailId);

  /* If the LPN detail being adjusted is assigned to an order and its onhand status is unavailable
     (this typically happens for new temp LPNs) user can only adjust a temp LPN when they have shortages
     however we cannot allow to adjust over ship qty, so do extra validations when incrementing the qty */
  if (@vOrderDetailId is not null) and (@vLPNDOnhandStatus = 'U' /* Unavailable */) and (@NewQuantity > @vLPNDQuantity)
    begin
      /* There may be multiple LPN details for single order detail, so get the sum of assigned qty */
      select @vQtyAssigned = sum(Quantity)
      from LPNDetails
      where (OrderDetailId = @vOrderDetailId) and
            (OnhandStatus = 'U' /* Unavailable */);

      /* Compute max quantity to adjust, it the total quantity assigend to the order detail excluding the
         LPN detail quantity that is being adjusted */
      select @vMaxQtyToAdjust = @vQtyToShip - (@vQtyAssigned - @vLPNDQuantity);
    end

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNOrLocationDoesNotExist';
  else
  if (@vLPNDetailId is null)
    set @vMessageName = 'LPNDetailDoesNotExist';
  else
  if (@vLPNStatus = 'T' /* In Transit */)
    set @vMessageName = 'LPNStatusIsInValid';
  else
  if (@vLPNStatus = 'A'/* Allocated */)
    set @vMessageName = 'LPNAdjust_CannotAdjustAllocatedLPN';
  else
  /* Allow adjusting of Carts as they are picked qty only */
  -- if (@vLPNType <> 'A' /* Cart */) and
  --    (@vLPNDOnhandStatus = 'R'/* Reserved */)
  --   set @vMessageName = 'LPNAdjust_CannotAdjustReservedQuantity';
  -- else
  if (@vCurrentSKUId is null)
     set @vMessageName = 'SKUDoesNotExist';
  else
  if (@vLPNDetailId is null)
     set @vMessageName = 'SKUNotInLPN';
  else
  if (@NewQuantity < 0)   /* Validate Quantity */
     set @vMessageName = 'InvalidQuantity';
  else
  if (@NewQuantity = @vLPNDQuantity)
    set @vMessageName = 'LPNAdjust_SameQuantity';
  else
  if (coalesce(@ReasonCode, '') = '')
    set @vMessageName = 'LPNAdjust_ReasonCodeRequired';
  else
  /* should allow adjustment of Picked, Packed, Staged LPNs even if reserved */
  if (@NewQuantity < @vLPNReservedQty) and (dbo.fn_IsInList(@vLPNStatus, 'KDE') = 0)
    select @vMessageName = 'LPNAdjust_CannotAdjustReservedQty', @vNote1 = @vLPNReservedQty;
  else
  /* Except in the particular scenario of incrementing qty in Temp LPN, @vMaxQtyToAdjust will be null
     and so this condition doesn't apply */
  /* If LPN is picked, packed or staged then we can allow quantity increment upto UnitsToAllocate
     If LPN is new temp, which means LDOnhandStatus is unavailable then we can allow quantity increment upto QtyToShip */
  if ((@vLPNDOnhandStatus = 'U'/* Unavailable */) and (@NewQuantity > coalesce(@vMaxQtyToAdjust, @NewQuantity))) or
     (dbo.fn_IsInList(@vLPNStatus, 'KDE' /* Picked, Packed, Staged */) > 0 and (@vQtyIncrement > @vUnitsToAllocate))
    select @vMessageName = 'LPNAdjust_CannotAdjustOverShipQty', @vNote1 = @vMaxQtyToAdjust;

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Calling Core Procedure */
  exec @vReturncode = pr_LPNs_AdjustQty @LPNId,
                                        @vLPNDetailId,
                                        @vCurrentSKUId,
                                        @vCurrentSKU,
                                        @NewInnerPacks output,
                                        @NewQuantity   output,
                                        '=' /* Update Option - Exact Qty */,
                                        'Y' /* Export? Yes */,
                                        @ReasonCode,  /* Reason Code - in future accept reason from User */
                                        null, /* Reference */
                                        @BusinessUnit,
                                        @UserId;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'LPNAdjustQty', @UserId, null /* ActivityTimestamp */,
                            @LPNId          = @LPNId,
                            @LPNDetailId    = @vLPNDetailId,
                            @OrderId        = @vLPNOrderId,
                            @InnerPacks     = @NewInnerPacks,
                            @Quantity       = @NewQuantity,
                            @PrevInnerPacks = @vLPNDInnerPacks,
                            @PrevQuantity   = @vLPNDQuantity,
                            @ReasonCode     = @ReasonCode;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1;

  /* Log the result */
  exec pr_RFLog_End null, @vMessageName, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  exec @vReturnCode = pr_ReRaiseError;

end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_AdjustLPN */

Go
