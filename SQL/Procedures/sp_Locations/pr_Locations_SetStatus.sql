/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/11  AY      pr_Locations_SetStatus: Optimized for LocationCounts (HA-3078)
  2017/12/06  TD      pr_Locations_SetStatus:Changes to calculate status based on the max LPNs
  2017/04/18  TD      pr_Locations_SetStatus:Changes to consider only received status LPNS.
  2017/03/31  AY      pr_Locations_SetStatus: Locations' status reverts from Reserve to Empty (GNC-1512)
  2016/03/15  OK      pr_Locations_UpdateCount, pr_Locations_SetStatus: Get the Transient Locations from control var for Counts and setting status (NBD-283)
  2016/03/09  AY      pr_Locations_SetStatus: Set different status for Staging/Dock/Conv. Locations
                      pr_Locations_SetStatus : Recalculate status only for active locations(GNC-1236)
  2014/07/04  AY      pr_Locations_SetStatus: Changed to use Reserved Status
  2014/03/11  TD      pr_Locations_SetStatus: bug fix: Update Location status based on the Quantity.
                      pr_Locations_SetStatus: Use coalesce for TotalQuantity
  2010/12/10  VM      Added pr_Locations_SetStatus and modified pr_Locations_UpdateCount to call new procedure.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_SetStatus') is not null
  drop Procedure pr_Locations_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_SetStatus:
    This procedure is used to change/set the 'Status' of the Location.

    Status:
     . If status is provided, it updates directly with the given status
     . If status is not provided - it calculates the status updates.
     . If status is given as *, then compute, but do not recalculate Quantity again

The option * is included for performance reasons. Most often we only call Location_UpdateCounts
which in turn calls Locations_SetStatus. We would have just calculated the counts
but we calculate them again, so it is unnecessary. So, if we trust the counts then
system should use the counts to compute the status.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_SetStatus
  (@LocationId  TRecordId,
   @Status      TStatus = null output)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vMessage         TDescription,

          @vIgnoreLocationsToSetStatus
                            TControlValue,

          @vLocation        TLocation,
          @vLocationType    TTypeCode,
          @vMaxPallets      TCount,
          @vMaxLPNs         TCount,
          @vMaxInnerPacks   TCount,
          @vMaxUnits        TCount,
          @vMaxVolume       TVolume,
          @vMaxWeight       TWeight,

          @vLPNsInLoc       TCount,
          @vDirectedPallets TCount,
          @vDirectedLPNs    TCount,
          @vDirectedIPs     TCount,
          @vDirectedUnits   TCount,
          @vDirectedVol     TVolume,
          @vDirectedWeight  TWeight,

          @vPalletsInLoc    TCount,
          @vIPsInLoc        TCount,
          @vUnitsInLoc      TCount,
          @vVolumeInLoc     TVolume,
          @vWeightInLoc     TWeight,

          @vStatus          TStatus,
          @vBusinessUnit    TBusinessUnit;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the BusinessUnit */
  select @vBusinessUnit  = BusinessUnit,
         @vLocation      = Location,
         @vLocationType  = LocationType,
         @vMaxPallets    = MaxPallets,
         @vMaxLPNs       = MaxLPNs,
         @vMaxInnerPacks = MaxInnerPacks,
         @vMaxUnits      = MaxUnits,
         @vMaxVolume     = MaxVolume,
         @vMaxWeight     = MaxWeight
  from Locations
  where (LocationId = @LocationId);

  /* Get the transient locations from Control var to set the Status to 'N' - Not Applicable */
  select @vIgnoreLocationsToSetStatus = dbo.fn_Controls_GetAsString('Location', 'IgnoreLocationsToSetStatus', 'C' /* Conveyor */, @vBusinessUnit /* BusinessUnit */, System_User);

  /* Calculate Status, if not provided or * - needs to recalculate */
  if (coalesce(@Status, '*') = '*' )
    begin
      select @vPalletsInLoc  = count(distinct PalletId),
             @vLPNsInLoc     = count(*),
             @vIPsInLoc      = sum(InnerPacks),
             @vUnitsInLoc    = sum(Quantity),
             @vVolumeInLoc   = sum(LPNVolume),
             @vWeightInLoc   = sum(LPNWeight)
      from LPNs
      where (LocationId =  @LocationId) and
            (Status     <> 'I'/* Inactive */);

      /* Get LPNs count which are heading into the location i.e these are ready to putaway into the location,
         so typically these LPNs will be in received status  */
      select @vDirectedPallets = count(distinct PalletId),
             @vDirectedLPNs    = count(*),
             @vDirectedIPs     = coalesce(sum(coalesce(InnerPacks, 0)), 0),
             @vDirectedUnits   = coalesce(sum(coalesce(Quantity, 0)), 0),
             @vDirectedVol     = sum(LPNVolume),
             @vDirectedWeight  = sum(LPNWeight)
      from LPNs
      where (DestLocation = @vLocation) and
            (BusinessUnit = @vBusinessUnit) and
            (coalesce(Location, '') <> @vLocation); -- Just a safety check!

      /*========================================================================
        Location Status: To explain the concept below LPNs are used, but this
                         applies for Pallets, IPs, Qty, Vol & Weight as well.

        Full     - If the current LPNs in locations is greater than or equal to the MaxLPNs defined on the location
        Reserved - If current LPNs in location and LPNs which are heading into the
                   location is greater than or equal to the MaxLPNs defined on the location
        Available - if current LPNs in location and LPNs coming to this locations is less than MaxLPNs
                    defined on the location.
        Empty     - None of the other conditions met, so Location must be empty LPNs heading to the locations and no LPNs currently in location

        Same applicable for all other limits and these rules will applicable for Reserve/Bulk only
      ==========================================================================*/

      select @vStatus        = case
                                 when (@vPalletsinLoc >= @vMaxPallets   ) or
                                      (@vLPNsInLoc    >= @vMaxLPNs      ) or
                                      (@vIPsInLoc     >= @vMaxInnerPacks) or
                                      (@vUnitsInLoc   >= @vMaxUnits     ) or
                                      (@vVolumeInLoc  >= @vMaxVolume    ) or
                                      (@vWeightInLoc  >= @vMaxWeight    ) then 'F' /* Full */
                                 when ((@vPalletsInLoc + @vDirectedPallets) >= @vMaxPallets   ) or
                                      ((@vLPNsInLoc    + @vDirectedLPNs)    >= @vMaxLPNs      ) or
                                      ((@vIPsInLoc     + @vDirectedIPs)     >= @vMaxInnerPacks) or
                                      ((@vUnitsInLoc   + @vDirectedUnits)   >= @vMaxUnits     ) or
                                      ((@vVolumeInLoc  + @vDirectedVol)     >= @vMaxVolume    ) or
                                      ((@vWeightInLoc  + @vDirectedWeight)  >= @vMaxWeight    ) then 'R' /* Reserved */
                                 when ((coalesce(@vUnitsInLoc, 0) + coalesce(@vDirectedUnits, 0)) > 0) then 'U' /* Available / InUse */
                                 else 'E' /* Empty */
                               end
    end

  /* Update Location */
  update Locations
  set Status       = case
                       when Status = 'I' /* Inactive */ then Status -- do not change
                       when (charindex(LocationType, @vIgnoreLocationsToSetStatus) > 0) then 'N' /* Not-Applicable */
                       when (coalesce(@Status, '*') = '*') then @vStatus
                       else
                         coalesce(@Status, Status)
                     end,
      /* If we have computed them above, we might as well save them */
      NumPallets   = coalesce(@vPalletsInLoc, NumPallets),
      NumLPNs      = coalesce(@vLPNsInLoc,    NumLPNs),
      InnerPacks   = coalesce(@vIPsInLoc,     InnerPacks),
      Quantity     = coalesce(@vUnitsInLoc,   Quantity),
      Weight       = coalesce(@vWeightInLoc,  Weight),
      Volume       = coalesce(@vVolumeInLoc,  Volume),
      ModifiedDate = current_timestamp,
      ModifiedBy   = System_User
  where (LocationId = @LocationId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_SetStatus */

Go
