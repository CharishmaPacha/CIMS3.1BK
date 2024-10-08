/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/10  AY/PK   pr_LPNs_SetPallet: Added check to consider PalletStatus not empty: Migrated from Staging (S2GCA-98)
  2018/08/06  TK      pr_LPNs_SetPallet: Changes to update pallet type as shipping if picked LPNs are added to Pallet (S2GCA-125)
  2018/01/17  OK      pr_LPNs_Void: Passed the UserId param to procedure pr_LPNs_SetPallet to avoid the runtime errors (S2G-97)
              AY      pr_LPNs_SetPallet, MoveLPN: Change to refactor code of updated LPNs on receipt as well as fixing bugs
  2016/10/13  OK      pr_LPNs_SetPallet: Restricted the updating Load and shipment on the carts (HPI-857)
  2016/10/05  AY      pr_LPNs_SetPallet: Clear Location on LPN when moved onto a Pallet (HPI-GoLive)
  2016/04/12  AY      pr_LPNs_SetPallet: Do not try to move LPN if Pallet has no location
  2016/02/18  TK      pr_LPNs_SetPallet: Allow Received LPN to add onto the Pallet (GNC-1247)
  2016/02/16  AY      pr_LPNs_SetPallet: Changed to use LPN_Move instead of SetLocation
  2015/11/13  DK      pr_LPNs_SetPallet: Made changes to update LPNs Warehouse on pallet while building pallet (FB-492).
  2015/09/02  TK      pr_LPNs_SetPallet: Allow Received LPN to be added to Inventory Pallet (ACME-332)
  2015/08/10  NY/AY   pr_LPNs_SetPallet: Bug fix to generate exports when Recv LPN is added to Putaway Pallet
                      pr_LPNs_SetPallet, Move, Void: Changes to update counts on RO correctly
  2015/03/24  TK      pr_LPNs_SetPallet: Generate exports LPN added to the pallet is of New/Lost Status
  2013/06/04  TD      pr_LPNs_SetPallet: Considering Putaway Type Pallet to validate Pallet Type.
  2013/01/30  PK      pr_LPNs_SetPallet: Bug fix for not validating the Loads if the Pallet is a Picking pallet.
  2012/10/06  AY      pr_LPNs_SetPallet: Update LPN status when added to a Pallet.
  2012/09/27  YA      pr_LPNs_SetPallet: Modified to fix an issue with setting PalletType.
  2012/09/05  AY      pr_LPNs_SetPallet: Set Type of Pallet and added new validations,
  2012/06/18  PK      pr_LPNs_SetPallet: Included Picking Pallet Type as well in Validations.
  2012/05/31  AY      pr_LPNs_SetPallet: Update Location of LPN when Pallet is changed
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_SetPallet') is not null
  drop Procedure pr_LPNs_SetPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_SetPallet:
    This proc assumes, the caller will pass a valid LPN and valid PalletId or
    null to clear the pallet. Also, assumes that the caller will take care of setting
    status of LPN.

    If Pallet is in a different location than the LPN, then move the LPN into
    where the Pallet is.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_SetPallet
  (@LPNId        TRecordId,
   @NewPalletId  TRecordId = null,
   @UserId       TUserId,
   @Operation    TOperation = null)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription,

          @vNewPallet          TPallet,
          @vLocationType       TLocationType,
          @vLPNType            TTypeCode,
          @vLPNStatus          TStatus,
          @vNewLPNStatus       TStatus,
          @vLPNSKUId           TRecordId,
          @vLPNOrderId         TRecordId,
          @vLPNShipmentId      TShipmentId,
          @vLPNLoadId          TLoadId,
          @vLPNLocationId      TRecordId,
          @vLPNPalletId        TRecordId,
          @vLPNReceiptId       TRecordId,
          @vLPNWarehouse       TWarehouse,
          @vInnerPacks         TInnerPacks,
          @vQuantity           TQuantity,
          @vReceiptId          TRecordId,

          @vPalletId           TRecordId,
          @vPalletType         TTypeCode,
          @vNewPalletType      TTypeCode,
          @vPalletStatus       TStatus,
          @vPalletSKUId        TRecordId,
          @vPalletLocationId   TRecordId,
          @vPalletNumLPNs      TCount,
          @vPalletBusinessUnit TBusinessUnit,
          @vPalletOrderId      TRecordId,
          @vPalletShipmentId   TShipmentId,
          @vPalletLoadId       TLoadId,
          @ReasonCode          TReasonCode,

          @vLPNBusinessUnit    TBusinessUnit,
          @AllowMultipleSKUs   TFlag,
          @vAllowMultipleSKUsToLoc
                               TFlag;
begin
  SET NOCOUNT ON;

  select @vNewPallet          = Pallet,
         @vPalletType         = PalletType,
         @vPalletStatus       = Status,
         @vPalletOrderId      = OrderId,
         @vPalletSKUId        = nullif(SKUId, ''),
         @vPalletBusinessUnit = BusinessUnit,
         @vPalletLocationId   = LocationId,
         @vPalletOrderId      = OrderId,
         @vPalletShipmentId   = ShipmentId,
         @vPalletLoadId       = LoadId
  from Pallets
  where (PalletId = @NewPalletId);

  select @vLPNType         = LPNType,
         @vLPNStatus       = Status,
         @vLPNBusinessUnit = BusinessUnit,
         @vLPNSKUId        = nullif(SKUId, ''),
         @vLPNLocationId   = LocationId,
         @vLPNReceiptId    = ReceiptId,
         @vLPNOrderId      = OrderId,
         @vLPNShipmentId   = ShipmentId,
         @vLPNLoadId       = LoadId,
         @vLPNPalletId     = PalletId,
         @vLPNWarehouse    = DestWarehouse
  from LPNs
  where (LPNId = @LPNId);

  select @vLocationType           = LocationType,
         @vAllowMultipleSKUsToLoc = AllowMultipleSKUs
  from Locations
  where (LocationId = @vPalletLocationId);

  /* If the LPN is not on a Pallet and if New PalletId is null then
     return back to the caller without updating any */
  if (@vLPNPalletId is null) and (@NewPalletId is null)
    goto ExitHandler;

  if (@vLPNBusinessUnit <> @vPalletBusinessUnit)
    set @MessageName = 'BusinessUnitOfLPNAndPalletMismatch'
  else
  /* Restrict user to move LPN to Location, if the SKU of LPN being moved is not same as the SKU present in Location */
  if ((@Operation = 'Putaway') and
      (@vPalletLocationId is not null) and
      (@vPalletSKUId is not null) and
      (@vAllowMultipleSKUsToLoc = 'N' /* No */) and
      (exists (select * from LPNs where LocationId = @vPalletLocationId and SKUId <> @vPalletSKUId)))
    set @MessageName = 'LocationDoesNotAllowMultipleSKUs';
  else
  if (@vLocationType = 'K' /* Picklane */)
    set @MessageName = 'InvalidLocationType'
  else
  if (@vPalletType not in ('I' /* Inventory */,
                           'R' /* Receiving */,
                           'C' /* Picking Cart */,
                           'P' /* Picking Pallet */,
                           'S' /* Shipping */,
                           'U' /* Putaway */))
    set @MessageName = 'InvalidPalletType'
  else
  /* Validate LPN Status with Pallet Type & Status */
  if (@vLPNStatus = 'K' /* Picked */) and
     (@vPalletStatus <> 'E' /* Empty */) and
     (@vPalletType not in ('C' /* Picking Cart */,
                           'P' /* Picking Pallet */,
                           'S' /* Shipping Pallet */))
    set @MessageName = 'PickedLPN-InvalidPalletType';
  else
  if (@vLPNStatus = 'R' /* Received */) and
     (@vPalletType not in ('R' /* Receiving */, 'I'/* Inventory */, 'U'/* PutawayPallet */)) and (@vPalletStatus <> 'E' /* Empty */)
    set @MessageName = 'ReceivedLPN-InvalidPalletType';
  else
  if (@vLPNLoadId <> @vPalletLoadId) and (@vPalletType <> 'P' /* Picking Pallet */) and (@vPalletStatus <> 'E' /* Empty */)
    set @MessageName = 'LPNSetPallet_LoadMismatch';
  else
  /* if Pallet is empty, then allow adding any lpn
     if pallet is not empty
     - if shipping pallet, then ensure palletorderid = lpnorderid
  */
  if (@vPalletNumLPNs > 0)
    begin
      if (@vPalletType in ('SO' /* Single Order */)) and
         (@vLPNOrderId <> @vPalletOrderId)
        set @MessageName = 'LPNSetPallet_DiffOrders';
      else
      /* if inventory or receiving pallet - and control var AllowMultiSKUPallets = N
         then ensure PalletSKUId = LPNSKUId */
      if (@vPalletType in ('I' /* Inventory */,
                           'R' /* Receiving */))
        begin
          set @AllowMultipleSKUs = dbo.fn_Controls_GetAsBoolean('Pallets', 'AllowMultipleSKUs', 'N', @vPalletBusinessUnit, @UserId);
          if (@AllowMultipleSKUs = 'N' /* No */) and
             (@vLPNSKUId <> @vPalletSKUId) or (@vLPNSKUId is null)
            set @MessageName = 'LPNSetPallet_NoMultipleSKUs';
        end
    end

  /* If error or it is a cart position, exit */
  if (@MessageName is not null) or (@vLPNType = 'A' /* Cart position */)
    goto ErrorHandler;

  /* Update LPN with New Pallet */
  update LPNs
  set PalletId      = @NewPalletId,
      Pallet        = @vNewPallet,
      @vReceiptId   = ReceiptId,
      @vInnerPacks  = InnerPacks,
      @vQuantity    = Quantity,
      ModifiedDate  = current_timestamp,
      ModifiedBy    = coalesce(@UserId, System_User)
  where (LPNId = @LPNId);

  /* If LPN is Intransit - we need to update the LPN as received and update the RO as well */
  if (@vLPNStatus = 'T' /* Intransit */)
    exec pr_LPNs_MarkAsReceived @LPNId, @vReceiptId;

  /* Update Pallet Type if it is an empty Pallet and not a Cart */
  if (@vPalletStatus = 'E' /* Empty */) and
     (@vPalletType not in ('C', 'H', 'F' /* Carts */, 'U'/* Putaway */))
    begin
      select @vNewPalletType = Case
                                 when @vLPNStatus = 'R' /* Received */ then
                                   'R' /* Receiving Pallet */
                                 /* If LPNs already picked are being added on to pallet then it sould be a shipping pallet */
                                 when (charindex(@vLPNStatus, 'KEL' /* Picked, Staged, Loaded */) <> 0) or
                                      (@vLPNLoadId > 0) then
                                   'S' /* Shipping Pallet */
                                 when (@vLPNOrderId is not null) then
                                   'P' /* Picking Pallet */
                                 else
                                   null
                               end;
    end;

  /* When first LPN is added to the Pallet, set the PalletType, OrderId, ShipmentId, LoadId */
  if (@vPalletStatus = 'E' /* Empty */)
    update Pallets
    set PalletType = coalesce(@vNewPalletType, PalletType),
        /* None of these are required as Pallets_UpdateCount below takes care of these */
        --OrderId    = @vLPNOrderId,
        --ShipmentId = case when coalesce(@vNewPalletType, PalletType) <> 'C' /* Cart */ then @vLPNShipmentId else ShipmentId end,
        --LoadId     = case when coalesce(@vNewPalletType, PalletType) <> 'C' /* Cart */ then @vLPNLoadId else LoadId end,
        Warehouse   = @vLPNWarehouse
    where (PalletId = @NewPalletId);

  /* if #EntitiesToRecalc is available, then use that */
  if (object_id('tempdb..#EntitiesToRecalc') is not null)
    begin
      /* Recount required entities */
      insert into #EntitiesToRecalc (EntityType, EntityId, RecalcOption, Status, BusinessUnit)
        select 'Pallet', @vLPNPalletId, 'CS' /* Counts & Status */, 'N', @vLPNBusinessUnit
        union all
        select 'Pallet', @NewPalletId, 'CS' /* Count & Status */, 'N', @vLPNBusinessUnit
    end

  if (@vLPNPalletId is not null) and (object_id('tempdb..#EntitiesToRecalc') is null)
    begin
      exec @ReturnCode = pr_Pallets_UpdateCount @PalletId     = @vLPNPalletId,
                                                @NumLPNs      = 1,
                                                @InnerPacks   = @vInnerPacks,
                                                @Quantity     = @vQuantity,
                                                @UpdateOption = '-' /* Subtract */;
    end

  /* Update New Pallet Counts (+NumLPNs, +InnerPacks, +Quantity) */
  if (@NewPalletId is not null) and (object_id('tempdb..#EntitiesToRecalc') is null)
    begin
      exec @ReturnCode = pr_Pallets_UpdateCount @PalletId     = @NewPalletId,
                                                @NumLPNs      = 1,
                                                @InnerPacks   = @vInnerPacks,
                                                @Quantity     = @vQuantity,
                                                @UpdateOption = '+' /* Add */;
    end

  /* If LPN is moved to a pallet, move it to the new location of the Pallet.
     Use LPN_Move instead of SetLocation as there may be updates to be done for example
     WH update on the LPN etc. */
  if (coalesce(@vLPNLocationId, '') <> coalesce(@vPalletLocationId, '')) and
     (@vPalletLocationId is not null)
--    exec pr_LPNs_SetLocation @LPNId, @vPalletLocationId;
    exec @ReturnCode = pr_LPNs_Move @LPNId,
                                    null /* LPN */,
                                    @vLPNStatus,
                                    @vPalletLocationId,
                                    null /* Location */,
                                    @vLPNBusinessUnit,
                                    @UserId;
  else
  if (@vPalletLocationId is null) /* LPN is removed from Location, so clear Location on LPN */
    exec pr_LPNs_SetLocation @LPNId, @vPalletLocationId;

  /* All of this is already being done in LPN Move */
  -- /* Generate exports if added LPN is of New/Lost Status and Pallet is of Putaway,
  --      since we update LPN Status to Putaway */
  -- if (@vLPNStatus in ('N' /* New */, 'O' /* Lost */)) and (@vPalletStatus = 'P'/* Putaway */)
  --   begin
  --     set @ReasonCode = '102';
  --
  --     exec @ReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
  --                                           @LPNId       = @LPNId,
  --                                           @ReasonCode  = @ReasonCode,
  --                                           @TransQty    = @vQuantity,
  --                                           @CreatedBy   = @UserId;
  --   end
  --
  -- /* Generate recv exports if added LPN is of Received Status and is not Putaway */
  -- if (@vLPNStatus = 'R') and (@vNewLPNStatus = 'P'/* Putaway */)
  --   begin
  --     exec @ReturnCode = pr_Exports_LPNData 'Recv' /* Receive Exports */,
  --                                           @LPNId       = @LPNId,
  --                                           @TransQty    = @vQuantity,
  --                                           @CreatedBy   = @UserId;
  --   end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_SetPallet */

Go
