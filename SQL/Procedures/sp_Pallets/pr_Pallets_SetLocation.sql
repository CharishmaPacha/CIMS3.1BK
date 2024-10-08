/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/08  MS      pr_Pallets_SetLocation: Update default WH, if it is not in any Location (BK-274)
  2020/12/02  AY      pr_Pallets_SetStatus: Revised status computation (HA-1747)
                      pr_Pallets_SetLocation: Update Intransit LPNs conditionally (HA-1750)
  2020/10/27  MS      pr_Pallets_SetLocation: Exclude InTransit LPNs while moving LPNs to new location (JL-212)
  2017/08/27  PK      pr_Pallets_UpdateCount: Performance fixes - to call pr_Pallets_SetLocation only when LocationId on a pallet is not null (HPI-Support).
  2017/08/25  AY      pr_Pallets_SetLocation: Performance fixes - to not process empty cart positions (HPI-Support)
  2017/02/09  AY      pr_Pallets_SetLocation: Do not clear PalletId on Cart positions (HPI-1375)
  2016/09/01  NY      pr_Pallets_SetLocation: Update Warehouse on the pallet (FB-749).
  2015/02/03  TK      pr_Pallets_SetLocation: If the Pallet contains Allocated LPN then update taskDetail with new LocationId.
  2012/07/13  PKS     pr_Pallets_SetLocation: Enhanced to move LPNs on Pallet to LPN Storage Location
  2012/05/31  AY      pr_Pallets_SetLocation: Validated Storage Type
  2012/04/10  PK      pr_Pallets_SetLocation: Added @vUpdateLPNLocation parameter to update LPNs based on input paramter
  2012/02/25  AY      fn_Pallets_GetPalletId, pr_Pallets_SetLocation: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_SetLocation') is not null
  drop Procedure pr_Pallets_SetLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_SetLocation:
    This proc assumes, the caller will pass a valid LPN and valid Location or
    null to clear Location. Also, assumes that the caller will take care of setting
    status to LPN.

  @UpdateLPNLocation: Y   - Update all LPNs on the Pallet,
                      NIT - Update all but Intransit LPNs (NIT - Not InTransit)
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_SetLocation
  (@PalletId           TRecordId,
   @NewLocationId      TRecordId = null,
   @UpdateLPNLocation  TFlag     = 'Y',
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,

          @vNumLPNs         TCount,
          @vNewLocation     TLocation,
          @vNewLocationId   TRecordId,
          @vNewLocationWH   TWarehouse,
          @vLocationType    TLocationType,
          @vStorageType     TStorageType,
          @vOldLocationId   TRecordId,
          @vInnerPacks      TInnerPacks,
          @vQuantity        TQuantity,
          @vNewPalletStatus TStatus,
          @vPalletStatus    TStatus,
          @vPalletType      TTypeCode,
          @vLPNStatus       TStatus,
          @vLPNQty          TQuantity,
          @vLPNId           TRecordId,
          @vLPN             TLPN,
          @vLPNType         TTypeCode,
          @vCount           TCount,
          @vRecordId        TRecordId;

  declare @ttPalletLPNs table
          (RecordId              TRecordId  identity (1,1),
           LPNId                 TRecordId,
           LPN                   TPallet,
           LPNStatus             TStatus,
           LPNType               TTypeCode,
           SKUId                 TRecordId,
           Quantity              TQuantity)
begin
  SET NOCOUNT ON;

  /* Validation - Location Type should be other than Picklane Location */
  select @vNewLocation   = Location,
         @vLocationType  = LocationType,
         @vStorageType   = StorageType,
         @vNewLocationWH = Warehouse
  from Locations
  where (LocationId = @NewLocationId);

  if (@vLocationType = 'K' /* Picklane */)
    set @MessageName = 'CannotMovePalletintoPickLane';
  else
  if (@vStorageType not in ('A' /* Pallets */, 'LA' /* Pallets and LPNs */, 'L' /* LPN */))
    set @MessageName = 'InvalidStorageTypeToMovePallet'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* if location is of LPN Storage, then only LPNs can be moved into the Location
     i.e. LPNs on the Pallet are considered to be unloaded into the Location, not the Pallet */
  if (@vStorageType = 'L' /* LPN */)
    set @vNewLocationId = null;
  else
    set @vNewLocationId = @NewLocationId;

  /* Update Pallet with New Location. However, do not clear the WH
     of the Pallet as we filter by WH in UI and if WH is null, we would
     not see the Pallets in UI */
  update Pallets
  set @vOldLocationId = LocationId,
      @vPalletStatus  = Status,
      @vNumLPNs       = NumLPNs,
      @vInnerPacks    = InnerPacks,
      @vQuantity      = Quantity,
      LocationId      = @vNewLocationId,
      Warehouse       = coalesce(@vNewLocationWH, Warehouse)
  where (PalletId = @PalletId);

  /* When Locaton is changed, Pallet status to be updated as well.
     Same, if the Pallet was in a Lost status as it is now found */
  if (coalesce(@vOldLocationId, '') <> coalesce(@NewLocationId, '') or
     (@vPalletStatus = 'O'/* Lost */))
    exec @ReturnCode = pr_Pallets_SetStatus @PalletId = @PalletId,
                                            @UserId   = @UserId;

  /* If desired, move the LPNs into the Location as well. In many cases all LPNs are to be
     moved into the Location, but in Receiving, only Received LPNs are to be updated, so
     we use NIT (not-InTransit) to indicate to move only the non-Intransit LPNs */
  if (@UpdateLPNLocation in ('Y', 'NIT'))
    begin
      /* There should not be any zero qty LPNs on pallets. However there would be cart
         positions and we don't need to update them any way, so only process LPNs with Qty */
      insert into @ttPalletLPNs (LPNId, LPN, LPNStatus, LPNType, SKUId, Quantity)
        select LPNId, LPN, Status, LPNType, SKUId, Quantity
        from LPNs
        where (PalletId = @PalletId) and
              (Quantity > 0) and
              ((@UpdateLPNLocation = 'Y') or
               ((@UpdateLPNLocation = 'NIT') and (Status <> 'T' /* Intransit */)));

      /* Get rowcount */
      select @vCount    = @@rowcount,
             @vRecordId = 1;

      -- loop through all LPNs --
      while (@vRecordId <= @vCount)
        begin
          /* select LPN details from temp table */
          select @vLPNId     = LPNId,
                 @vLPN       = LPN,
                 @vLPNQty    = Quantity,
                 @vLPNStatus = LPNStatus,
                 @vLPNType   = LPNType
          from @ttPalletLPNs
          where (RecordId = @vRecordId);

          /* If moving into LPN storage location, clear Pallet as LPN cannot be on a pallet anymore */
          if (@vStorageType = 'L' /* LPN */) and (@vLPNType not in ('A' /* Cart */))
            exec pr_LPNs_SetPallet @vLPNId, null /* PalletId */, @UserId;

          /* Move the LPN to the scanned location and set the status of the LPN */
          if (@NewLocationId is not null)
            exec @ReturnCode = pr_LPNs_Move @vLPNId,
                                            @vLPN,
                                            @vLPNStatus,
                                            @NewLocationId,
                                            @vNewLocation,
                                            @BusinessUnit,
                                            @UserId,
                                            'E' /* UpdateOption - OnlyExports, No Location UpdateCounts, no pallet update counts */;
          else
            exec @ReturnCode = pr_LPNs_SetLocation @vLPNId, null /* Clear Location */;

          /* If the Pallet contains Allocated LPN then update taskDetail with new LocationId */
          if exists (select * from TaskDetails where LPNId = @vLPNId)
            update TaskDetails
            set LocationId = @NewLocationId
            where (LPNId = @vLPNId) and
                  (Status not in ('X'/* Canceled */, 'C'/* Completed */));

          /* Delete the record from the temp table after its is processed */
          delete from @ttPalletLPNs where RecordId = @vRecordId;

          /* select Next record from the temp table */
          select @vRecordId = @vRecordId + 1;
        end
    end
  else
    begin
      /* If @vUpdateLPNLocation is No, then update only NumPallets of the locations */
      select @vNumLPNs    = null,
             @vInnerPacks = null,
             @vQuantity   = null;
    end

  /* We used to do this in LPNMove earlier which we have now disabled and doing it only
     once at the end after all LPNs are moved */
  exec pr_Pallets_UpdateCount @PalletId, @UpdateOption = '*';

  if (@vOldLocationId is not null)
    begin
      /* Update Old Location Counts (-Pallets, -NumLPNs, -InnerPacks, -Quantity) */
      exec @ReturnCode = pr_Locations_UpdateCount @LocationId   = @vOldLocationId,
                                                  @NumPallets   = 1,
                                                  @NumLPNs      = @vNumLPNs,
                                                  @InnerPacks   = @vInnerPacks,
                                                  @Quantity     = @vQuantity,
                                                  @UpdateOption = '-' /* Subtract */;
      if (@ReturnCode > 0)
        goto ExitHandler;
    end

  /* Update New Location Counts (+NumPallets, +NumLPNs, +InnerPacks, +Quantity) */
  if (@NewLocationId is not null)
    begin
      exec @ReturnCode = pr_Locations_UpdateCount @LocationId   = @NewLocationId,
                                                  @NumPallets   = 1,
                                                  @NumLPNs      = @vNumLPNs,
                                                  @InnerPacks   = @vInnerPacks,
                                                  @Quantity     = @vQuantity,
                                                  @UpdateOption = '+' /* Add */;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Pallets_SetLocation */

Go
