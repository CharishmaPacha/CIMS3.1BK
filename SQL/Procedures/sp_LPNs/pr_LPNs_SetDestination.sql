/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/15  TD      pr_LPNs_SetDestination :Changes to use DestLocationId from OrderDetails (S2G-432)
                      pr_LPNs_SetDestination: Corrections to clear DestLocation
  2014/07/05  AY      pr_LPNs_SetDestination: Enh. to update DestZone and set status on DestLocation
  2014/06/08  AY      pr_LPNs_SetDestination: Set destination of LPN as appropriate
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_SetDestination') is not null
  drop Procedure pr_LPNs_SetDestination;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_SetDestination:
    This proc assumes, the caller will pass a valid LPN and valid Location or
    null to clear Location. Also, assumes that the caller will take care of setting
    status to LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_SetDestination
  (@LPNId          TRecordId,
   @Operation      TOperation = null,
   @DestLocationId TRecordId  = null,
   @DestLocation   TLocation  = null,
   @DestZone       TZoneId    = null)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,

          @vDestLocationId    TRecordId,
          @vDestLocation      TLocation,
          @vDestZone          TZoneId,
          @vDestLocationType  TLocationType,
          @vBusinessUnit      TBusinessUnit;
begin
  SET NOCOUNT ON;

  select @vDestLocationId = @DestLocationId,
         @vDestLocation   = @DestLocation,
         @vDestZone       = @DestZone;

  /* If it is replenish, then determine the destination from Task -> OrderDetail.Location */
  if (@Operation = 'ReplenishPick') and (@vDestLocationId is null)
    begin
      /* For a Replenish Pick where we generate a temp label for each Case to be picked
         like at GNC, get the related DestLocation */
      select @vDestLocationId = OD.DestLocationId,
             @vDestLocation   = OD.DestLocation,
             @vBusinessUnit   = OD.BusinessUnit
      from LPNTasks LT join TaskDetails TD on LT.TaskDetailId = TD.TaskDetailId
        join OrderDetails OD on OD.OrderDetailId = TD.OrderDetailId
      where (LT.LPNId = @LPNId);

      /* For LPN Picks, there would not be an entry in LPNTasks, so get directly from OrderDetail */
      if (@vDestLocationId is null)
        begin
          select @vDestLocationId = OD.DestLocationId,
                 @vDestLocation   = OD.DestLocation
          from OrderDetails OD
            join LPNDetails  LD on LD.OrderDetailId = OD.OrderDetailId
          where (LD.LPNId = @LPNId);
        end

      /* select picking zone of the Location here */
      select @vDestZone         = PutawayZone,
             @vDestLocationType = LocationType
      from Locations
      where (LocationId = @vDestLocationId);
   end

  /* If intent is to clear Destination on LPN, then get the details of the Location to update it */
  if (@Operation = 'ClearDestination')
    begin
      select @vDestLocation = L.DestLocation,
             @vBusinessUnit = L.BusinessUnit
      from LPNs L
      where (L.LPNId = @LPNId);
    end

  /* if we only have the Location, then get the LocationId to update the status */
  if (@vDestLocationId is null) and (@vDestLocation is not null)
    begin
      if (@vBusinessUnit is null)
        select @vBusinessUnit from LPNs where LPNId = @LPNId;

      select @vDestLocationId   = LocationId,
             @vDestLocationType = LocationType,
             @vDestZone         = coalesce(@vDestZone, PutawayZone)
      from Locations
      where (Location = @vDestLocation) and (BusinessUnit = @vBusinessUnit);
    end
  else
  if (@vDestLocationId is not null)
    select @vDestLocation     = Location,
           @vDestZone         = coalesce(@vDestZone, PutawayZone), -- select putaway zone of the Dest Location
           @vDestLocationType = LocationType
    from Locations
    where (LocationId = @vDestLocationId);

  /* If clearing destination on the LPN then clear the fields to be updated. This has
     to be done only after Location details are retrieved above so that we can
     correctly compute status later */
  if (@Operation = 'ClearDestination')
    select @vDestZone     = null,
           @vDestLocation = null;

  /* Update LPNs with the Dest zone and Location */
  update LPNs
  set DestZone     = @vDestZone,
      DestLocation = @vDestLocation
  where (LPNId = @LPNId);

  /* If needed, Update the status of the Location to Reserved */
  if (@vDestLocationType in ('R', 'B' /* Reserve, Bulk */))
    exec pr_Locations_SetStatus @vDestLocationId, '*';

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_SetDestination */

Go
