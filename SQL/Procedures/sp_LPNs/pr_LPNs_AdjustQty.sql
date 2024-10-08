/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/17  RKC     pr_LPNs_AdjustQty: Make changes to pass the value to @vLPNId (HA-2771)
  2021/05/02  TK      pr_LPNs_AdjustQty: Don't do any updates on orders when unvailable line is adjusted (HA-2720)
  2020/04/20  TK      pr_LPNs_AdjustQty: Fix to update ReceivedCounts appropriately (HA-211)
  2019/01/07  AY      pr_LPNDetails_AddOrUpdate/pr_LPNs_AdjustQty: Reset Units/pkg (FB-1671)
  2019/05/05  AY      pr_LPNs_AdjustQty: Do not delete LPN with only directed lines (S2GCA-467)
  2018/11/21  TK      pr_LPNs_AdjustQty: Delete LPN if NumLines is equal to '1' from a dynamic picklane and
                      pr_LPNs_AdjustQty: Update ReceivedCounts when Received LPN is updated - except on Putaway (S2G-879)
  2018/05/05  TK      pr_LPNs_AdjustQty: Changes to consider SKU.UnitsPerInnerpack if UnitsPerPackage is zero (S2G-819)
  2018/03/11  TK      pr_LPNDetails_AddDirectedQty: Changes to update UnitsPerPackage & Innerpacks on Directed line
                      pr_LPNs_AdjustQty: Delete R/PR line if Quantity on them is zero (S2G-364)
  2018/03/02  TK      pr_LPNs_AdjustQty: Changes to retain LPN or LPN Detail if reserved quantity on line is greater than zero (S2G-151)
  2018/02/16  TK      pr_LPNs_AdjustQty: If the LPN being adjusted consists PR lines then recompute its dependent tasks & waves
  2017/10/05  TK      pr_LPNs_AdjustQty: If we are adjusting Directed Qty then don't reduce Qty on Location (HPI-1694)
  2016/10/31  VM      pr_LPNs_AdjustQty: Recount OH after LPNDelete/LPNDetailDelete (HPI-957)
  2016/07/14  RV      pr_LPNs_AdjustQty: Recompute the pallets to update the correct pick batch info (HPI-286)
  2016/05/27  TK      pr_LPNDetails_Unallocate: Changes made to Directed lines if there are any
                      pr_LPNDetails_CancelReplenishQty: Initial Revision
                      pr_LPNs_AdjustQty: Detail D & DR lines if the final quantity is zero (NBD-528)
  2016/04/27  AY      pr_LPNs_AdjustQty: Changed to use UnitsPerPackage from LPNDetail and not override with SKU Info
  2015/12/15  AY      pr_LPNs_AdjustQty: Prevent InnerPacks from going -ve.
  2015/10/11  AY      pr_LPNs_AdjustQty: Bug fix to not allow -1 adjustment on Static picklane LPN (CIMS-651)
  2015/09/02  AY      pr_LPNs_AdjustQty: Removed InnerPacks used to only depend upon data in the LPN.
  2015/01/12  VM      pr_LPNs_AdjustQty: Use Innerpacks and its validations only when used by client. 'N' for SRI.
                      But it has to be driven by control var.
  2014/12/09  TD      pr_LPNs_AdjustQty, pr_LPNDetails_Unallocate: Changes to adjust directed line when
  2014/07/21  TD      pr_LPNDetails_AddOrUpdate, pr_LPNs_AdjustQty: Changes to update Quantity
                        based on the location subtype.
  2014/06/26  TD      pr_LPNs_AdjustQty: Do not generate an export when quantity change is zero
  2014/05/29  TD      pr_LPNs_AdjustQty:changes to delete line when the quantity is on the reserved line.
  2014/05/06  PV      pr_LPNs_AdjustQty: Calculating InnerPacks and Quantity based on user input.
  2014/05/05  TD      pr_LPNs_AdjustQty:Avoid picklane units storage location while validating
  2014/04/04  PK      pr_LPNs_AdjustQty: Updating the received units.
                         Changed the caller of pr_LPNs_AdjustQty by including Reference param.
  2014/03/17  TD      pr_LPNs_AdjustQty:Changes to calculate Innerpacks, proper validations.
  2014/03/12  TD      pr_LPNs_AdjustQty:Changes to calculate Quantity, InnerPacks and other validations.
  2014/02/28  PK      pr_LPNs_AdjustQty: Reverted the changes of validating allocated LPN and implemented in warpper
  2014/02/04  TD      pr_LPNs_AdjustQty: raise error when user trying adjust LPN which is in LOST Location.
                      pr_LPNs_AdjustQty: Allowing to adjust only available Quantity in LPN during cycle counting.
                      pr_LPNs_AdjustQty: Enh. to call OnConsume when LPN is consumed
  2013/11/27  TD      pr_LPNs_AdjustQty: Bug fix in handling adjusting a line to zero on a multi line LPN
  2013/04/19  AY      pr_LPNs_AdjustQty: Bug fix - do not change ROD qty when LPN is being
  2013/04/17  AY      pr_LPNs_AdjustQty: Change ROD/ROH Received Qtys when LPN change
  2013/04/11  PK      pr_LPNs_AdjustQty: Changes to updating static location quantity
  2013/03/27  AY/PK   pr_LPNs_AdjustQty, pr_LPNDetails_AddOrUpdate: Enhance to handle Static vs Dynamic picklanes
  2013/01/23  PKS     pr_LPNs_AdjustQty: Join with SKUs table removed from LPNs
  2012/11/29  PK      pr_LPNs_AdjustQty: Code refactor while adjust an allocated LPN, and also allowing to
                      pr_LPNs_AdjustQty: Bug fix - Location NumLPN count were not being
  2011/09/30  AY      pr_LPNs_AdjustQty: Bug fix - When an LPN is 'deleted' the NumLPNs count on
                      pr_LPNs_AdjustQty: Delete LPN when Logical LPN becomes empty,
  2011/07/22  VM      pr_LPNs_AdjustQty (Bug-fixes): As LPNDetail might not exists, do the following
  2011/07/16  AY      pr_LPNs_AdjustQty: Changed LPNDetailId to o/p param.
  2011/01/25  AY      pr_LPNs_AdjustQty: Export trans based upon Onhand Status of LPN
                      pr_LPNs_AdjustQty: Changed to generate Export
  2010/12/03  VM      pr_LPNs_AdjustQty, pr_LPNs_AddSKU, pr_LPNs_Move:
  2010/11/25  VM      pr_LPNs_AdjustQty: Added 'UpdateOption' i/p param to consider Qty update type.
  2010/11/22  VM      pr_LPNs_AdjustQty, pr_LPNs_AddSKU, pr_LPNs_Generate, pr_LPNs_Recount: Procedures completed
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_AdjustQty') is not null
  drop Procedure pr_LPNs_AdjustQty;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_AdjustQty:
    This procedure assumes that the LPN is validated with below validations
    before calling this proc.
    1. Valid LPN
    2. Valid LPN Status
    3. Valid LPN Location

  Important: Changed to not delete LPNDetails even when Qty to goes to zero on
             the LPNDetail as we would have to keep track of UnitsReceived
             against the RO Detail.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_AdjustQty
  (@LPNId           TRecordId,
   @LPNDetailId     TRecordId output,
   @SKUId           TRecordId,
   @SKU             TSKU,
   @InnerPacks      TInnerPacks output, /* InnerPacks to Adjust */
   @Quantity        TQuantity   output, /* Quantity to Adjust */
   @UpdateOption    TFlag = '=', /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty */
   @ExportOption    TFlag = 'Y',
   @ReasonCode      TReasonCode = null,
   @Reference       TReference,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TDescription,

          @vCreatedDate        TDateTime,
          @vModifiedDate       TDateTime,
          @vLPNQuantity        TQuantity,
          @vReservedQty        TQuantity,
          @vDirectedQty        TQuantity,
          @vLPNInnerPacks      TQuantity,
          @vLPNDetailOHStatus  TStatus,
          @vUnitsPerPackage    TQuantity,
          @vFinalQuantity      TQuantity,
          @vFinalInnerPacks    TQuantity,
          @vNumLPNsChange      TCount,
          @vQuantityChange     TQuantity,
          @vInnerPacksChange   TQuantity,
          @vLPNDOnhandStatus   TStatus,
          @vReceivedUnits      TQuantity,
          @vNewReceivedUnits   TQuantity,
          @vLocationId         TRecordId,
          @vLPN                TLPN,
          @vUoM                TUoM,
          @vInventoryUoM       TUoM,
          @vLPNType            TTypeCode,
          @vLPNStatus          TStatus,
          @vNewLPNStatus       TStatus,
          @vLPNLine            TDetailLine,
          @vLPNId              TRecordId,
          @vPalletId           TRecordId,
          @vPallet             TPallet,
          @vLPNOrderId         TRecordId,
          @vLPNOrderDetailId   TRecordId,
          @vLPNLocation        TLocation,
          @vLostLocation       TLocation,
          @vReceiptId          TRecordId,
          @vReceiptDetailId    TRecordId,
          @vLoadId             TLoadId,
          @vShipmentId         TShipmentId,
          @vLocationSubType    TTypeCode,
          @vLocStorageType     TTypeCode,
          @vUpdateOption       TDescription,
          @vNumLines           TCount,
          @vNumPRLines         TCount,

          @vDebug              TFlag,
          @vLDActivityLogId    TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null,

         @vNumLPNsChange    = 0,
         @vLPNQuantity      = 0,
         @vNumPRLines       = 0,
         @vNewReceivedUnits = null,
         @vLostLocation     = dbo.fn_Controls_GetAsString('ShortPick', 'MoveToLocation', 'LOST', @BusinessUnit, @UserId);

  /* Get the debug options */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  /* Log LPN Details into activitylog before adjusting quantities */
  if (charindex('L' /* Log */, @vDebug) > 0)
    exec pr_ActivityLog_LPN 'LPN_AdjustQty_LPNDetails_Start', @LPNId, null/* Message */, @@ProcId,
                            null, @BusinessUnit, @UserId, @vLDActivityLogId output;

  /* Validatation */
  /* ##VM - SKU Validation required??? or Does not need to validate as the SKU is selected from the list (both UI and RFC) */

  /* ##VM - Shall we use a Control Var (AllowAdjustToZero) and validate based on it???
  if (@Quantity = 0)
    set @vMessageName = 'SKUQtyCannotBeNullOrZero';
  */

  /* Get the LPN Current InnerPacks, Quantity */
  select @vLPNDOnhandStatus  = OnhandStatus,
         @vLPNInnerPacks     = nullif(InnerPacks, 0),
         @vLPNQuantity       = Quantity,
         @vUnitsPerPackage   = UnitsPerPackage, -- nullif(UnitsPerPackage, 0),
         @vReservedQty       = ReservedQty,
         @vLPNOrderId        = OrderId,
         @vLPNOrderDetailId  = OrderDetailId,
         @vReceivedUnits     = ReceivedUnits,
         @vReceiptId         = ReceiptId,
         @vReceiptDetailId   = ReceiptDetailId,
         @vLPNDetailOHStatus = OnhandStatus
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Get the LPN information */
  select @vLocationId   = L.LocationId,
         @vLPNId        = L.LPNId,
         @vLPN          = L.LPN,
         @vLPNType      = L.LPNType,
         @vLPNStatus    = L.Status,
         @vPalletId     = L.PalletId,
         @vPallet       = L.Pallet,
         @vDirectedQty  = L.DirectedQty,
         @vLoadId       = L.LoadId,
         @vShipmentId   = L.ShipmentId
  from LPNs L
  where (LPNId = @LPNId);

  /* Get LPNLine count here */
  select @vNumLines   = count(*),
         @vNumPRLines = sum(case when (OnHandStatus = 'PR'/* Pending Reserve */) then 1 else 0 end)
  from LPNDetails
  where (LPNId = @LPNId);

  /* Get Location Sub Type and Location info  */
  select @vLocationSubType = LocationSubType,
         @vLPNLocation     = Location,
         @vLocStorageType  = StorageType
  from Locations
  where (LocationId = @vLocationId);

  /* Get UoM from SKU
     If there is no value find for UnitsPerPackage on LPNdetails then we need  */
  if ((@InnerPacks > 0) and (@Quantity > 0))
    select @vUnitsPerPackage = (@Quantity / @InnerPacks);

  if (@vUnitsPerPackage is null) and (@vLPNInnerPacks > 0)
    select @vUnitsPerPackage = (@vLPNQuantity / @vLPNInnerPacks);

  select @vUoM             = UoM,
         @vInventoryUoM    = InventoryUoM,
         /* If UnitsPerPackage, current LPN Qty and Innerpacks is zero, then just check whether SKU.UnitsPerInnerpack has some value and use it */
         @vUnitsPerPackage = case when InventoryUoM = 'EA'
                                    then 0
                                  when (@vUnitsPerPackage = 0) and (@vLPNInnerPacks = 0) and (@vLPNQuantity = 0)
                                    then UnitsPerInnerPack
                                  else @vUnitsPerPackage
                             end
  from SKUs
  where (SKUId = @SKUId);

  /* Set to 0 if the declared integer type values are null */
  select @vLPNInnerPacks   = coalesce(@vLPNInnerPacks, 0),
         @InnerPacks       = coalesce(@InnerPacks, 0),
         @vUnitsPerPackage = coalesce(@vUnitsPerPackage, 0),
         @Quantity         = coalesce(@Quantity, 0),
         @vPalletId        = coalesce(@vPalletId, 0);

  /* Assumptions: If user might give both InnerPacks and Quantity
                  User might give only Innerpacks, then we need to calculate Quantity,
                  User might give only Quantity then we need to calculate innerPacks */

  /* if User gives InnerPacks only, then we need to calculate Quantity */
  if ((@InnerPacks > 0) and (@Quantity = 0))
    begin
      select @Quantity = (@vUnitsPerPackage * @InnerPacks);

      /* If we are adjusting Unit Picklane, force InnerPacks = 0 */
      if (left(@vLocStorageType, 1) = 'U' /* Unit Storage */)
        select @InnerPacks = 0;
    end
  else
  if (@vLocStorageType = 'U' /* Unit Storage */)
    select @InnerPacks = 0;
  else
  /* If caller has given only Quantity but not inner pack then compute InnerPacks.
     However if LPN does not have innerpacks then don't try to compute it when qty is being reduced
     When SKU inventory UoM doesn't specify Cases (CS), then do not compute Innerpacks */
  if (@vLPNInnerPacks = 0) and
     ((@UpdateOption = '-') or (charindex('CS', coalesce(@vInventoryUoM, '')) = 0))
    select @InnerPacks = 0; -- do not change
  else
  if ((@Quantity > 0) and (@InnerPacks = 0) and (coalesce(@vUnitsPerPackage, 0) > 0))
    begin
       select @InnerPacks = (@Quantity / @vUnitsPerPackage);
    end

  /* Set Final Quantity to update */
  select @vFinalQuantity   = case @UpdateOption
                               when '=' /* Exact */ then
                                 @Quantity
                               when '+' /* Add */ then
                                 (@vLPNQuantity + @Quantity)
                               when '-' /* Subtract */ then
                                 (@vLPNQuantity - @Quantity)
                             end,
          /* Set Final InnerPacks to update */
         @vFinalInnerPacks = case @UpdateOption
                               when '=' /* Exact */ then
                                 @InnerPacks
                               when '+' /* Add */ then
                                 (@vLPNInnerPacks + @InnerPacks)
                               when '-' /* Subtract */ then
                                 (@vLPNInnerPacks - @InnerPacks)
                             end;

  /* Validations
     We cannot have -ve inventory on the LPN. However as a cluge we do pass in Qty = -1
     when we want to remove the SKU from a Static LPN, so exclude the scenario ie. allow
     FinalQty = -1 when it is a static picklane LPN and caller passed in update = and -1
     Note that in this scenario - we don't really update LPN with -1, but we instead delete the line
  */
/* Old condition
  if (((@vFinalQuantity < 0) or (@vFinalInnerPacks < 0)) and (@vLocationSubType <> 'S')) or
     ((@vFinalQuantity < -1) and (@vLocationSubType = 'S'))
*/
  if ((@vFinalQuantity < 0) or (@vFinalInnerPacks < 0)) and
     (not ((@UpdateOption = '=') and (@Quantity = -1) and (@vLPNType = 'L') and (@vLocationSubType = 'S') and (@vLPNQuantity = 0)))
    set @vMessageName = 'LPNAdjust_NoNegativeInventory';
  else
  /* if the LPN's Location is LOST then we do not allow users to adjust. */
  if (@vLPNLocation = @vLostLocation)
    set @vMessageName = 'LPNAdjust_CannotAdjustLOSTLPN';
  else
  if ((@vFinalInnerPacks > 0) and (@vFinalQuantity % @vFinalInnerPacks > 0))
    set @vMessageName = 'LPNInnerPacksAndQtyMismatch';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* FinalQuantity should never be less than zero, it is just being used that
     way as a short term fix to removing SKUs from static picklanes, so until
     that changes, we will just need this fix so that location counts do not go -ve */
  select @vQuantityChange   = case when @vFinalQuantity < 0 then
                                0
                              else
                                @vFinalQuantity - @vLPNQuantity
                              end,
         @vInnerPacksChange = case when @vFinalInnerPacks < 0 then
                                0
                              else
                                @vFinalInnerPacks - @vLPNInnerPacks
                              end,
         @vFinalInnerPacks  = case when @vFinalInnerPacks < 0 then
                                0
                              else
                                @vFinalInnerPacks
                              end;

  /* If new qty = 0 and it is a Logical LPN for a Dynamic Picklane, delete it,
     else just delete the line. However, if it is a Logical LPN and Static, do
     not delete the line either, we need to leave the SKU as is with Zero Qty
     For static locations, only way to delete the SKU from the Location is to
     give -1 in the quantity */
  /* There are chances that Reserved quantity on line would be greater than zero, if so
     retain that line don't delete LPN or LPN Detail */
  set @vUpdateOption = case
                         when (@vLPNType = 'L' /* Logical */) and
                              (@vLocationSubType = 'D' /* Dynamic */) and
                              (@vNumLines = 1) and
                              (@vFinalQuantity = 0) and
                              (@vDirectedQty = 0) then
                           'LPNDelete'
                         when (@vLPNType = 'L' /* Logical */) and
                              (@vLocationSubType = 'D' /* Dynamic */) and
                              (@vNumLines > 1) and
                              (@vFinalQuantity = 0) and
                              (@vReservedQty = 0) then
                           'LPNDetailDelete'
                         when (@vLPNType = 'L' /* Logical */) and
                              (@vLPNDOnhandStatus in ('D', 'DR')) and
                              (@vFinalQuantity = 0) and
                              (@vReservedQty = 0) then
                           'LPNDetailDelete'
                         when (@vLPNType = 'L' /* Logical */) and
                              (@vLocationSubType = 'S' /* Static */) and
                              (@vFinalQuantity = -1) and
                              (@Quantity = -1) and
                              (@vNumLines = 1) and
                              (@vReservedQty = 0) then
                           'LPNDelete'
                        when (@vLPNType = 'L' /* Logical */) and
                              (@vLocationSubType = 'S' /* Static */) and
                              (@vFinalQuantity = -1) and
                              (@Quantity = -1) and
                              (@vReservedQty = 0) then
                           'LPNDetailDelete'
                         /* The last line in static picklane should not be deleted, it should only be updated */
                         when (@vLPNType = 'L' /* Logical */) and
                              (@vLocationSubType = 'S' /* Static */) and
                              (@vNumLines = 1) then
                           'LPNDetailUpdate'
                         when (not ((@vLPNType = 'L' /* Logical */) and
                                    (@vLocationSubType = 'S' /* Static */))) and
                              (@vLPNStatus <> 'R' /* Received */) and
                              (@vFinalQuantity = 0) and
                              (@vReservedQty = 0) then
                           'LPNDetailDelete'
                         when (@vLPNDetailOHStatus in ('R', 'PR' /* Reserved, Pending Resv. */)) and
                              (@vFinalQuantity = 0) then
                           'LPNDetailDelete'
                         else
                           'LPNDetailUpdate'
                       end;

  /* If LPN is in Received status, then change the Received Units also accordingly */
  if (((@vLPNStatus = 'R' /* Received */) and
       (@vQuantityChange <> 0) and
       (@ReasonCode not in ('219' /* Putaway to Picklane */)))
      or
      ((@vReceivedUnits > 0) and (@ReasonCode = '199' /* Reverse Receipt */)))
    begin
      select @vNewReceivedUnits = @vReceivedUnits + @vQuantityChange;  --obsolete
    end

  /* Update LPN Details */
  if (@vUpdateOption = 'LPNDetailUpdate')
    begin
      exec @vReturnCode = pr_LPNDetails_AddOrUpdate @LPNId,
                                                    null           /* @LPNLine */,
                                                    null           /* @CoO */,
                                                    @SKUId,
                                                    @SKU,
                                                    @vFinalInnerPacks,
                                                    @vFinalQuantity      /* @Quantity */,
                                                    @vNewReceivedUnits   /* @ReceivedUnits */,
                                                    null           /* @ReceiptId */,
                                                    null           /* @ReceiptDetailId */,
                                                    null           /* @OrderId */,
                                                    null           /* @OrderDetailId */,
                                                    null           /* @OnhandStatus */,
                                                    'AdjustQty'    /* @Operation */,
                                                    null           /* @Weight */,
                                                    null           /* @Volume */,
                                                    null           /* @Lot */,
                                                    @BusinessUnit,
                                                    @LPNDetailId   output,
                                                    @vCreatedDate  output,
                                                    @vModifiedDate output,
                                                    @UserId        output,
                                                    @UserId        output;
    end

  if (@vReturnCode > 0)
    goto ExitHandler;

  /* Caller may or may not pass LPNDetailId, so LPNDetails_AddOrUpdate will create if nothing is passed and returns LPNDetailId,
     so get the onhand status of LPN detail */
  select @vLPNDOnhandStatus = OnhandStatus
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Adjusting quantities on the LPNs may result change in Task & Wave dependencies, if there are
     any PR lines in LPN then update recompute corresponding Task & Wave dependencies */
  if (@vNumPRLines > 0) and (@vLPNDOnhandStatus in ('A', 'D', 'PR' /* Available, Directed or Pending Reserve */))
    exec pr_LPNs_RecomputeWaveAndTaskDependencies @LPNId, @vFinalQuantity, @vLPNQuantity, 'LPNsAdjustQty';

  /* if LPN is allocated and adjusted then update the order counts. The
      LPN Adjust procedure is used to transfer inventory from one LPN to
      another during picking and packing, so in such scenarios, we should
      not adjust the Order Details - we bank on the fact that for such
      transfers, there are no exports */
  if (@vLPNOrderId is not null) and  (@ExportOption <> 'N') and (@vLPNDOnhandStatus <> 'U')
   begin
     /* Update the counts of the order and batch if the LPN is allocated */
     exec @vReturnCode = pr_LPNs_UpdateOrderOnAdjust @vLPNOrderId,
                                                     @vLPNOrderDetailId,
                                                     @vQuantityChange,
                                                     @Quantity,
                                                     @vUoM,
                                                     @BusinessUnit,
                                                     @UserId;

     if (@vReturnCode > 0)
       goto ExitHandler;
   end

  /* If the LPN is still in a Received state, then update the ROD/ROH as well */
  if (((@vLPNStatus = 'R' /* Received */) and (@ReasonCode not in ('219'/* Putaway */))) or
      ((@vReceiptId is not null) and (@ReasonCode = '199'/* Reverse Receipt */)))
   begin
     /* Update ReceivedCounts table also to reflect the change */
     exec pr_ReceivedCounts_AddOrUpdate @LPNId, @LPNDetailId, @InnerPacks, @Quantity,
                                        @vReceiptId, null /* ReceiverId */, @vReceiptDetailId,
                                        @UpdateOption = @UpdateOption,
                                        @BusinessUnit = @BusinessUnit, @UserId = @UserId;

     exec pr_ReceiptDetails_UpdateCount @vReceiptId, @vReceiptDetailId, '+', @vQuantityChange;
   end

  if (@ExportOption    =  'Y' /* Yes */) and
     (@vQuantityChange <> 0) and
     (@vLPNDOnhandStatus   in ('A' /* Available */, 'R' /* Reserved */))
    exec @vReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                           @LPNDetailId = @LPNDetailId,
                                           @TransQty    = @vQuantityChange,
                                           @ReasonCode  = @ReasonCode,
                                           @Reference   = @Reference,
                                           @CreatedBy   = @UserId;

  /* If it is a Logical LPN and does not have any SKU/Qty anymore, delete it,
     else in all other situations, just delete the LPN Detail when it has no SKU/Qty  */
  if (@vUpdateOption = 'LPNDelete')
    begin
      exec @vReturnCode = pr_LPNs_Delete @vLPNId;

      /* Reduce NumLPNs on location by 1 */
      set @vNumLPNsChange = -1;
    end
  else
  if (@vUpdateOption = 'LPNDetailDelete')
    begin
      exec @vReturnCode = pr_LPNDetails_Delete @LPNDetailId;

      /* Recount */
      exec @vReturnCode = pr_LPNs_Recount @vLPNId, @UserId, @vNewLPNStatus output;

      /* If status of LPN is consumed then decrement on NumLPNs */
      if (@vNewLPNStatus = 'C' /* Consumed */)
        begin
          set @vNumLPNsChange = -1;

          /* The LPN is consumed, so update Order, Shipment, Load counts */
          exec pr_LPNs_OnConsume @vLPNId, @vLPNOrderId, @vShipmentId, @vLoadId, @BusinessUnit, @UserId;
        end
    end

  if (@vReturnCode > 0)
    goto ExitHandler;

  /* Update Location Counts (InnerPacks, Quantity). The update Option on the
     locations should be +, if the Qty on the LPN is reduced, then the
     @vQuantityChange would have been negative */
  /* If we are adjusting directed quantity then no need to reduce quantity on Location */
  if (@vLPNDOnhandStatus not in ('D', 'DR', 'PR' /* Directed/Directed Reserve/Pending Reserve */))
    exec @vReturnCode = pr_Locations_UpdateCount @LocationId   = @vLocationId,
                                                 @NumLPNs      = @vNumLPNsChange,
                                                 @InnerPacks   = @vInnerPacksChange,
                                                 @Quantity     = @vQuantityChange,
                                                 @UpdateOption = '+';

  if (@vPalletId > 0)
    exec @vReturnCode = pr_Pallets_UpdateCount @PalletId     = @vPalletId,
                                               @Pallet       = @vPallet,
                                               @NumLPNs      = @vNumLPNsChange,
                                               @InnerPacks   = @vInnerPacksChange,
                                               @Quantity     = @vQuantityChange,
                                               @UpdateOption = '*';

  /* Though, this procedure calls pr_LPNs_UpdateOrderOnAdjust above and recount OH,
     if the UpdateOption is LPNDelete or LPNDetailDelete, it needs to recount OH again! */
  if (@vUpdateOption in ('LPNDelete', 'LPNDetailDelete') and (@vLPNOrderId is not null))
    /* Recounts the Order and updates the status of the Orders */
    exec pr_OrderHeaders_Recount @vLPNOrderId;

  if (@vReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_LPNs_AdjustQty */

Go
