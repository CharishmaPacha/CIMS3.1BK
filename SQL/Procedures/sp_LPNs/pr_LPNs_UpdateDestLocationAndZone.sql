/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/21  RV      pr_LPNs_UpdateDestLocationAndZone: Include operation PrepareForReceiving to update the Location for picklanes (CID-125)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_UpdateDestLocationAndZone') is not null
  drop Procedure pr_LPNs_UpdateDestLocationAndZone;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_UpdateDestLocationAndZone: This procedure will update the passed DestZone and DestLocation on LPN.
    if DestZone and Location not passed then it will process the Putaway rules to identify the DestLocation and zone to update on LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_UpdateDestLocationAndZone
  (@LPNId           TRecordId,
   @Operation       TOperation = null,
   @DestZone        TZoneId    = null output,
   @DestLocation    TStatus    = null output)
as
  declare @vRecordId         TRecordId,
          @vReturnCode       TInteger,

          @vLPNId            TRecordId,
          @vSKUId            TRecordId,
          @vDestLocationId   TRecordId,
          @vDestLocation     TLocation,
          @vDestLocationType TLocationType,
          @vDestZone         TZoneId,
          @vUserId           TUserId,
          @vDeviceId         TDeviceId,
          @vBusinessUnit     TBusinessUnit;

begin
  select @vRecordId = 0;

  select @vLPNId        = LPNId,
         @vSKUId        = SKUId,
         @vDestLocation = DestLocation,
         @vDestZone     = DestZone,
         @vBusinessUnit = BusinessUnit
  from LPNs
  where (LPNId = @LPNId);

  /* Get the Dest Location and Dest zone for the scanned LPN based on putaway rules */
  if (@DestZone is null) and (@DestLocation is null)
    exec @vReturnCode = pr_Putaway_FindLocationForLPN @vLPNId,
                                                      @vSKUId, /* PASKUId   */
                                                      'L',     /* PA Option */
                                                      @vBusinessUnit,
                                                      @vUserId,
                                                      @vDeviceId,
                                                      @DestZone      output,
                                                      @DestLocation  output;

  /* If have identified a destination, get the info of it */
  if (@DestLocation is not null)
    select @vDestLocationId   = LocationId,
           @vDestLocationType = LocationType
    from Locations
    where (Location     = @DestLocation) and
          (BusinessUnit = @vBusinessUnit);

  if (@vDestLocationType = 'K' /* Picklane */) and (@Operation in ('PrepareForReceiving', 'Receiving'))
    exec pr_LPNs_SetDestination @vLPNId, default /* Operation */, @vDestLocationId /* DestLocId */,
                                @vDestLocation, @vDestZone;
  else
    update LPNs
    set DestZone = @DestZone
    where (LPNId = @vLPNId);

end /* pr_LPNs_UpdateDestLocationAndZone */

Go
