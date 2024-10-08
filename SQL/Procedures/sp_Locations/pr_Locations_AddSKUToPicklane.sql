/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/07  AY      pr_Locations_AddSKUToPicklane: Use contact_ws while building UniqueId (HA-2727)
  2020/10/20  PK      pr_Locations_AddSKUToPicklane: AddSKU_MaxScanQty control default value increased
  2020/07/29  TK      pr_Locations_AddSKUToPicklane & pr_Locations_AdjustSKUQuantity: Changes to consider InventoryClasses (HA-1246)
  2018/12/06  AY      pr_Locations_AddSKUToPicklane: Update SKU Primary Location only when added to Static picklanes (HPI-2226)
  2018/12/26  TK      pr_Locations_AddSKUToPicklane: Bug fix in identifying ownerhsip correctly (S2GMI-44)
  2018/09/27  TK      pr_Locations_AddSKUToPicklane: Used coalesce for Lot (S2GCA-309)
  2018/09/14  TK      pr_Locations_AddSKUToPicklane & pr_Locations_AdjustSKUQuantity:
                      pr_Locations_AddSKUToPicklane: If LPNId is passed then do not generate new LPN, adjust quantity on the LPN
  2018/03/14  TK      pr_Locations_AddSKUToPicklane & pr_Locations_GenerateLogicalLPN: Changes to preprocess Logical LPN after adding SKU (S2G-367)
  2016/06/04  TK      pr_Locations_AddSKUToPicklane & pr_Locations_RemoveSKUFromPicklane:
  2016/01/20  TD      pr_Locations_AddSKUToPicklane:Changes to update Ownership on LPNs
  2015/10/23  TD      pr_Locations_AddSKUToPicklane:reset LPN to null, as we are getting it in later.
  2015/04/28  TK      pr_Locations_AddSKUToPicklane: use separate procedure to generate Logical LPN
  2013/06/25  PK      pr_Locations_AddSKUToPicklane: Fixed the issue of not retrieving Logical Picklane LPNs which has SKU as null.
  2013/05/24  PK      pr_Locations_AddOrUpdate, pr_Locations_AddSKUToPicklane: Passing Warehouse
  2013/04/16  AY      pr_Locations_AddSKUToPicklane: Changed to use AllowMultipleSKUs of location and not control var
  2013/01/24  PKS     pr_Locations_AddSKUToPicklane: Bug fixed at Quantity Validation to allow Qty value upto MaxQty.
  2013/01/23  PKS     pr_Locations_AddSKUToPicklane: Recalculate Location Qty and Status after SKU is added.
  2013/01/21  YA      pr_Locations_AddSKUToPicklane: Validate not to allow quantity below 1 and over 9999.
  2012/08/27  AY      pr_Locations_AddSKUToPicklane: Marked Location as updated
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_AddSKUToPicklane') is not null
  drop Procedure pr_Locations_AddSKUToPicklane;
Go
/*------------------------------------------------------------------------------
  Proc pr_Location_AddSKUToPicklane: Picklanes by default are created with no
    LPNs or SKUs i.e. just the Locations are created. This procedure is to used
    when Qty of any SKU is to be added to the Picklane. If the SKU already
    exists in the Picklane (i.e. an LPN exists in the Location with the particular
    SKU) then the Qty in that LPN is adjusted. However, if there is no LPN of the
    particular SKU in the Pickalane, then the LPN is added and the SKU set up
    with the given quantity.

  Note: For Static locations we should be able to add with zero quantity.
        Also, to remove static SKUs, we allow Quantity of -1.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_AddSKUToPicklane
  (@SKUId                TRecordId,
   @LocationId           TRecordId,
   @InnerPacks           TInnerPacks,
   @Quantity             TQuantity,
   @Lot                  TLot       = null,
   @Ownership            TOwnership = null,
   @InventoryClass1      TInventoryClass = '',
   @InventoryClass2      TInventoryClass = '',
   @InventoryClass3      TInventoryClass = '',
   @UpdateOption         TFlag = '=',
   @ExportOption         TFlag = 'Y',
   @UserId               TUserId,
   @ReasonCode           TReasonCode = '223',
   @LPNId                TRecordId = null output,
   @LPNDetailId          TRecordId = null output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription,

          @vLocation           TLocation,
          @vLocationType       TLocationType,
          @vLocationSubType    TLocationType,
          @vLocStorageType     TLocationtype,
          @vLocPickingZone     TLookUpCode,
          @vMaxScanQty         TInteger,
          @vLocBusinessUnit    TBusinessUnit,
          @vWarehouse          TWarehouse,
          @vSKU                TSKU,
          @vLPN                TLPN,
          @vLPNSKUId           TRecordId,
          @vLPNQuantity        TQuantity,
          @vAllowMultipleSKUs  TControlValue,
          @vSKUBusinessUnit    TBusinessUnit,
          @vSKUOwnership       TOwnership,
          @vOwnership          TOwnership,
          @vControlCategory    TCategory;
begin
  SET NOCOUNT ON;

  select @Quantity    = coalesce(@Quantity, 0),
         @InnerPacks  = coalesce(@InnerPacks, 0);
         /* If LPNId is passed in then we shouldn't generate new logical LPN instead, we need to adjust its quantity */
         --@LPNId       = null,
         --@LPNDetailId = null;

  /* Get the details from Locations */
  select  @vLocation          = Location,
          @vLocationType      = LocationType,
          @vLocationSubType   = LocationSubType,
          @vLocStorageType    = StorageType,
          @vLocPickingZone    = PickingZone,
          @vWarehouse         = Warehouse,
          @vLocBusinessUnit   = BusinessUnit,
          @vAllowMultipleSKUs = AllowMultipleSKUs
  from Locations
  where (LocationId  = @LocationId);

  /* Get SKU details from SKUs */
  select @vSKU             = SKU,
         @vSKUBusinessUnit = BusinessUnit,
         @vSKUOwnership    = Ownership
  from SKUs
  where (SKUId = @SKUId);

  /* Get LPN in the Location which already has the SKU (or no SKU assigned)
     Removed the condition of (SKUId is null) from where condition, as Picklanes
     will never have SKUId as null */
  /* Find the LPN which matching the Ownership and Lot if provided */
  select @LPNId     = LPNId,
         @vLPN      = LPN,
         @vLPNSKUId = SKUId
  from LPNs
  where (LocationId = @LocationId) and
        (SKUId      = @SKUId) and
        (Ownership  = coalesce(@Ownership, @vSKUOwnership)) and
        (coalesce(Lot, '') = coalesce(@Lot, '')) and
        (InventoryClass1 = @InventoryClass1) and
        (InventoryClass2 = @InventoryClass2) and
        (InventoryClass3 = @InventoryClass3);

  /* Get the control vars */
  select @vOwnership       = coalesce(@Ownership, @vSKUOwnership),
         @vControlCategory = 'Location_' + @vLocationType,
         @vMaxScanQty      = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'AddSKU_MaxScanQty', 9999999, @vLocBusinessUnit, @UserId);

  /* Validations */
  if (@vSKU is null)
    set @MessageName = 'InvalidSKU'
  else
  if (@vLocation is null)
    set @MessageName = 'InvalidLocation'
  else
  if (@vLocationType <> 'K' /* Picklane */)
    set @MessageName = 'CannotAddSKUtoNonPickLaneLoc';
  else
  if ((@vLocStorageType = 'U' /* Units */) and (@Quantity = 0) and (@InnerPacks > 0))
    set @MessageName = 'CannotStoreCasesInPicklaneUnitStorage';
  else
  if ((@vLocStorageType = 'P' /* Cases */) and (@Quantity > 0) and (@InnerPacks = 0))
    set @MessageName = 'InvalidQuantityForPicklaneCaseStorage';
  else
  /* Validate not to allow quantity below 1 and over the qty provided in controls for MaxQty */
  if ((@vLocationSubType = 'D' /* Dynamic */) and (@Quantity <= 0) and (@InnerPacks <= 0)) or
     ((@vLocationSubType = 'S' /* Static  */) and (@Quantity < -1) and (@InnerPacks <= -1)and (@vLPNQuantity = 0)) or
     (@Quantity > @vMaxScanQty)
    set @MessageName = 'InvalidQuantity';
  else
  if (@vAllowMultipleSKUs = 'N' /* No */) and
     (@LPNId is null) and /* There is currently no LPN with the SKU in the location */
     (exists(select * from LPNs where LocationId = @LocationId and SKUId <> @SKUId and BusinessUnit = @vLocBusinessUnit))  /* But there is another SKU */
    set @MessageName = 'LocationAddSKU_NoMultipleSKUs';
  else
  if (@Quantity = -1) and (@vLocationSubType = 'S') and (@LPNId is null)
    set @MessageName = 'LocationRemoveSKU_SKUDoesNotExist';
  else
  if (@vLocBusinessUnit <> @vSKUBusinessUnit)
    set @MessageName = 'BusinessUnitMismatch'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* At this point, we know that either the Location already has the SKU or
     that we are allowed to add a new SKU to the Location */

  /* If we have no LPN, it means that there is no LPN of the SKU in the Picklane
     and we need to create one */
  if (@LPNId is null)
    begin
      exec @ReturnCode = pr_Locations_GenerateLogicalLPN 'L' /* Logical Carton */, 1 /* NumberOfLPNs */,
                                                         'P' /* LPNStatus - Putaway */,
                                                         @LocationId,
                                                         @vLocation,
                                                         @vSKU,
                                                         @Lot,
                                                         @vWarehouse,
                                                         @vOwnership,
                                                         @vLocBusinessUnit,
                                                         @UserId,
                                                         @LPNId output;

      /* Update InventoryClass on LPN */
      update LPNs
      set UniqueId        = concat_ws('-', @vLocation, @vSKU, @InventoryClass1, @InventoryClass2, @InventoryClass3, @Lot),
          InventoryClass1 = @InventoryClass1,
          InventoryClass2 = @InventoryClass2,
          InventoryClass3 = @InventoryClass3
      where (LPNId = @LPNId);
    end
  else
    begin
      /* This is a temporary change as we already have LPNs created for
         Loehmanns with no SKUs */
      /* Not sure why we are doing this here, this code is already in place in proc
         Locations_GenerateLogicalLPN, I think we can eliminate this code

         For now added Lot as well for uniqueness */
      update LPNs
      set UniqueId  = concat_ws('-', @vLocation, @vSKU, @InventoryClass1, @InventoryClass2, @InventoryClass3, @Lot),
          Ownership = coalesce(@Ownership, @vSKUOwnership, Ownership)
      where (LPNId = @LPNId);

      select @LPNDetailId = LPNDetailId
      from LPNDetails
      where (LPNId = @LPNId) and
            (SKUId = @SKUId) and
            (OnhandStatus = 'A' /* Available */);
    end

  /* Either the LPN already exists or we have just created it, now we need to
     Adjust the qty in the LPN */
  exec @Returncode = pr_LPNs_AdjustQty @LPNId,
                                       @LPNDetailId output,
                                       @SKUId,
                                       null,         /* SKU */
                                       @InnerPacks  output,
                                       @Quantity    output,
                                       @UpdateOption /* Update Option - Add Qty */,
                                       @ExportOption,
                                       @ReasonCode   /* Reason Code: New Inventory in Picklane */,
                                       null,         /* Reference */
                                       @vLocBusinessUnit,
                                       @UserId;

  /* Pre-processing the newly created LPN without having SKU set up doesn't make any sense,
     preprocess LPN after adding SKU to establish Putaway and Picking Class */
  exec pr_LPNs_PreProcess @LPNId, default, @vLocBusinessUnit;

  /* Updating Location Status */
  exec @ReturnCode = pr_Locations_SetStatus @LocationId = @LocationId;

  /* Mark the Location as updated */
  update Locations
  set ModifiedBy   = @UserId,
      ModifiedDate = current_timestamp
  where (LocationId = @LocationId);

  /* Update Primary Location details on the SKU only if it was a static location */
  if (@vLocationSubType = 'S' /* Static */)
    update SKUs
    set PrimaryLocationId = @LocationId,
        PrimaryLocation   = @vLocation,
        PrimaryPickZone   = @vLocPickingZone
    where (SKUId = @SKUId);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_AddSKUToPicklane */

Go
