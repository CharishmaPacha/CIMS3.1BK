/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/03/31  AY      pr_LPNs_SetLocation: Clear destination of LPN when LPN is voided or consumed
  2016/08/05  SV      pr_LPNs_SetLocation: Marked the default value for @UpdateOption to update the counts over Location (HPI-324)
  2015/09/29  AY      pr_LPNs_SetLocation: Added UpdateOptions to control update counts on Location
                      pr_LPNs_SetLocation: Clear Destlocation of LPN when it is moved into that
  2014/04/26  AY      pr_LPNs_SetLocation: Accept new param Location instead of Id
                      pr_LPNs_SetLocation: Validate against Storage Type of Location
                      Added pr_LPNs_SetLocation;
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_SetLocation') is not null
  drop Procedure pr_LPNs_SetLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_SetLocation:
    This proc assumes, the caller will pass a valid LPN and valid Location or
    null to clear Location. Also, assumes that the caller will take care of setting
    status to LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_SetLocation
  (@LPNId          TRecordId,
   @NewLocationId  TRecordId = null,
   @NewLocation    TLocation = null,
   @UpdateOption   TFlags    = 'L')
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,

          @vLPN               TLPN,
          @vNewLocation       TLocation,
          @vNewDestZone       TZoneId,
          @vDestLocation      TLocation,
          @vNewDestLocation   TLocation,
          @vDestLocationId    TRecordId,
          @vDestLocationType  TLocationType,
          @vLocationType      TLocationType,
          @vStorageType       TStorageType,
          @vOldLocationId     TRecordId,
          @vPalletId          TRecordId,
          @vLPNStatus         TStatus,
          @vInnerPacks        TInnerPacks,
          @vQuantity          TQuantity,
          @vClearDestination  TFlags,
          @vBusinessUnit      TBusinessUnit;
begin
  SET NOCOUNT ON;

  /* Get LPN Info */
  select @vLPN             = LPN,
         @vPalletId        = PalletId,
         @vNewDestZone     = DestZone,
         @vDestLocation    = DestLocation,
         @vNewDestLocation = DestLocation,
         @vLPNStatus       = Status,
         @vBusinessUnit    = BusinessUnit
  from LPNs
  where (LPNId = @LPNId);

  /* If caller has given Location only but not Id, then get the Id */
  if (@NewLocationId is null) and (@NewLocation is not null)
    select @NewLocationId = LocationId
    from Locations
    where (Location = @NewLocation) and (BusinessUnit = @vBusinessUnit);

  select @vNewLocation   = Location,
         @vLocationType  = LocationType,
         @vStorageType   = StorageType
  from Locations
  where (LocationId = @NewLocationId);

  /* If the LPN was already destined to a Location then we ought to check it */
  if (@vDestLocation is not null)
    select @vDestLocationId   = LocationId,
           @vDestLocationType = LocationType
    from Locations
    where (Location     = @vDestLocation) and
          (BusinessUnit = @vBusinessUnit);

  /* Validation - Location Type should be other than Picklane Location */

  if (@vLocationType = 'K' /* Picklane */)
    set @MessageName = 'CannotMoveLPNintoPickLane';
  else
  /* LPN that is not on a pallet can only be moved into L or LA, if on pallet
     it can be moved into A Location as well */
  if not ((@vStorageType in ('L' /* LPNs */, 'LA' /* Pallets and LPNs */)) or
          ((@vStorageType in ('A' /* Pallets */)) and (@vPalletId is not null)))
    set @MessageName = 'InvalidStorageTypeToMoveLPN'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* If LPN has reached the respective destination then clear the destination. User can possibly
     put into another Reserve/Bulk Location by overriding the destlocation. However, if DestLocationType
     is picklane, we don't want user to override */
  /* If LPN is Consumed/Voided/Lost we need to clear the destlocation*/
  select @vClearDestination = case when (@vNewLocation = @vDestLocation) then 'Y'
                                   when (@vDestLocationType in ('R', 'B')) and
                                        (@vLocationType     in ('R', 'B')) then 'Y'
                                   when (@vLPNStatus in ('V', 'C', 'O' /* Void, Consumed, Lost */)) then 'Y'
                                   else 'N'
                              end;

  if (@vClearDestination = 'Y')
    begin
      select @vNewDestZone     = null,
             @vNewDestLocation = null;
    end

  /* Update LPN with New Location */
  update LPNs
  set @vOldLocationId = LocationId,
      @vInnerPacks    = InnerPacks,
      @vQuantity      = Quantity,
      LocationId      = @NewLocationId,
      Location        = @vNewLocation,
      DestZone        = @vNewDestZone,
      DestLocation    = @vNewDestLocation,
      ModifiedDate    = current_timestamp
  where (LPNId = @LPNId);

  if (@vOldLocationId is not null) and
     (charindex('L', @UpdateOption) <> 0)
    begin
      /* Update Old Location Counts (-NumLPNs, -InnerPacks, -Quantity) */
      exec @ReturnCode = pr_Locations_UpdateCount @LocationId   = @vOldLocationId,
                                                  @NumLPNs      = 1,
                                                  @InnerPacks   = @vInnerPacks,
                                                  @Quantity     = @vQuantity,
                                                  @UpdateOption = '-' /* Subtract */;

      if (@ReturnCode > 0)
        goto ExitHandler;
    end

  /* Update New Location Counts (+NumLPNs, +InnerPacks, +Quantity) */
  if (@NewLocationId is not null) and
     (charindex('L', @UpdateOption) <> 0)
    begin
      exec @ReturnCode = pr_Locations_UpdateCount @LocationId   = @NewLocationId,
                                                  @NumLPNs      = 1,
                                                  @InnerPacks   = @vInnerPacks,
                                                  @Quantity     = @vQuantity,
                                                  @UpdateOption = '+' /* Add */;
    end

  /* If the Dest Location on LPN was cleared for some reason, then we have to re-calculate
     status of it as it may have to go from 'Reserved' back to Empty */
  if (@vDestLocation is not null) and (@vNewDestLocation is null)
    exec pr_Locations_SetStatus @vDestLocationId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_SetLocation */

Go
