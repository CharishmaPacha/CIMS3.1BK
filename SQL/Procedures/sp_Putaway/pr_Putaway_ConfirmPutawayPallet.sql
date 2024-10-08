/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/08/28  AY      pr_Putaway_ConfirmPutawayPallet: Fixed issue with counts on Location
  2012/06/04  PK      pr_Putaway_ConfirmPutawayPallet: Updating Old and New Location Statuses and Counts,
                      pr_Putaway_ConfirmPutawayPallet.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_ConfirmPutawayPallet') is not null
  drop Procedure pr_Putaway_ConfirmPutawayPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_Putaway_ConfirmPutawayPallet:
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_ConfirmPutawayPallet
  (@PalletId            TRecordId,
   @PutawayZone         TLookUpCode,
   @PutawayLocation     TLocation,
   @ScannedLocation     TLocation,
   @PutawayInnerPacks   TInnerPacks,
   @PutawayQuantity     TQuantity,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @DeviceId            TDeviceId)
as
  /*declare variables here..*/
  declare @ReturnCode            TInteger,
          @vPalletId             TRecordId,
          @vPallet               TPallet,
          @vNumLPNs              TCount,
          @vPalletQuantity       TQuantity,
          @vLPNId                TRecordId,
          @vLPN                  TLPN,
          @vLPNQty               TQuantity,
          @vLPNStatus            TStatus,
          @vScannedLocationId    TRecordId,
          @vScannedLocation      TLocation,
          @vScannedLocationType  TTypeCode,
          @vPalletStatus         TStatus,
          @vPalletType           TTypeCode,
          @vNewPalletStatus      TStatus,
          @vCount                TCount,
          @vRecordId             TRecordId,
          @vExportOption         TFlag,
          @vMessageName          TMessageName;

  declare @ttPutawayPalletLPNs Table
          (RecordId              TRecordId  identity (1,1),
           LPNId                 TRecordId,
           LPN                   TPallet,
           LPNStatus             TStatus,
           SKUId                 TRecordId,
           Quantity              TQuantity)

begin /* pr_Putaway_ConfirmPutawayPallet */

  select @vPalletId       = PalletId,
         @vPallet         = Pallet,
         @vPalletQuantity = Quantity,
         @vNumLPNs        = NumLPNs,
         @vPalletStatus   = Status,
         @vPalletType     = PalletType
  from Pallets
  where (PalletId     = @PalletId) and
        (BusinessUnit = @BusinessUnit);

  select @vScannedLocationId   = LocationId,
         @vScannedLocation     = Location,
         @vScannedLocationType = LocationType
  from Locations
  where (Location     = @ScannedLocation) and
        (BusinessUnit = @BusinessUnit);

  insert into @ttPutawayPalletLPNs (LPNId, LPN, LPNStatus, SKUId, Quantity)
    select LPNId, LPN, Status, SKUId, Quantity
    from LPNs
    where (PalletId     = @PalletId) and
          (BusinessUnit = @BusinessUnit);

  /* Get rowcount */
  select @vCount    = @@rowcount,
         @vRecordId = 1;

  /* Set the status, if the Pallet is Received/Puataway Pallet */
  if (@vPalletStatus in ('R' /* Received */, 'P' /* Putaway */)) and
     (@vPalletType = 'R' /* Receiving Pallet */) and
     (@vScannedLocationType in ('R' /* Reserve */, 'B' /* Bulk */))
    set @vNewPalletStatus = 'P' /* Putaway */;
  else
    set @vNewPalletStatus = @vPalletStatus;

  /* Set Location for the Pallet */
  exec @ReturnCode = pr_Pallets_SetLocation @vPalletId, @vScannedLocationId, 'N' /* No - UpdateLocation */,  @BusinessUnit, @UserId;

  -- loop through all LPNs --
  while (@vRecordId <= @vCount)
    begin
      /* AY: Could we use LPN Move instead of this?
         PK: We can use LPN Move, but for each LPN, location update count will be called
             and how ever at the end we need to set location for the pallet, so we are
             calling Location update count in it and setting Location for the LPNs as well in it.
             So I found some performace issue for calling sub procedures multiple times
            and decided to go in this way */

      /* select LPN details from temp table */
      select @vLPNId              = LPNId,
             @vLPN                = LPN,
             @vLPNQty             = Quantity,
             @vLPNStatus          = LPNStatus
      from @ttPutawayPalletLPNs
      where RecordId = @vRecordId;

      /* Move the LPN to the scanned location and set the status of the LPN */
      exec @ReturnCode = pr_LPNs_Move @vLPNId,
                                      @vLPN,
                                      @vLPNStatus,
                                      @vScannedLocationId,
                                      @vScannedLocation,
                                      @BusinessUnit,
                                      @UserId,
                                      'EL' /* UpdateOption: Exports and Location UpdateCounts */;

     /* Delete the record from the temp table after its is processed */
     delete from @ttPutawayPalletLPNs where RecordId = @vRecordId;

     /* select Next record from the temp table */
     select @vRecordId = @vRecordId + 1;
    end

  /* Update Pallet status */
  exec @ReturnCode = pr_Pallets_SetStatus @vPalletId;

  /* Update Location status */
  exec @ReturnCode = pr_Locations_SetStatus @vScannedLocationId;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Putaway_ConfirmPutawayPallet */

Go
