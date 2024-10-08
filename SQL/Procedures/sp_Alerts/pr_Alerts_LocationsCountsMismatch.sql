/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/25  SJ      pr_Alerts_LocationsCountsMismatch: Added new proc for location counts mismatch (HA-2696)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_LocationsCountsMismatch') is not null
  drop Procedure pr_Alerts_LocationsCountsMismatch;
Go
/*------------------------------------------------------------------------------
  pr_Alerts_LocationsCountsMismatch: This procedure is used to get the list of
  locations whose counts are not accurate, fix the same and send the alert.

  exec pr_Alerts_LocationsCountsMismatch 'R', 'A01', 'HA', 'cIMSAgent', 'Y', 'N'
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_LocationsCountsMismatch
  (@LocationType       TTypeCode,
   @Location           TLocation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ReturnDataSet      TFlags    = 'N',
   @EmailIfNoAlert     TFlags    = 'N')
as
  declare @vRecordId    TRecordId,
          @vLocationId  TRecordId,
          @vLocation    TLocation;

  declare @ttLocationsList Table (RecordId         TRecordId identity(1,1),
                                  LocationId       TRecordId,
                                  Location         TLocation,
                                  LocationType     TDescription,
                                  StorageType      TDescription,
                                  Status           TStatus,

                                  NumPallets       TCount,
                                  NumLPNs          TCount,
                                  InnerPacks       TInnerpacks,
                                  NumUnits         TCount,

                                  ActualPallets    TCount,
                                  ActualLPNs       TCount,
                                  ActualInnerPacks TInnerpacks,
                                  ActualUnits      TCount,
                                  ActualStatus     TStatus);
begin
  select @vRecordId = 0,
         @Location  = coalesce(@Location + '%', '%');

  /* create # table with @ttLocationsList table structure */
  if (object_id('tempdb..#LocationsList') is null)
    select * into #LocationsList from @ttLocationsList;

  /* Get the All locations list which haves the greater than units or numLPNs or pallets */
  insert into #LocationsList(LocationId, Location, LocationType, StorageType, Status, NumPallets, NumLPNs, InnerPacks, NumUnits)
    select LocationId, Location, LocationType, StorageType, Status, NumPallets, NumLPNs, InnerPacks, Quantity
    from Locations with (nolock)
    where (LocationType = @LocationType) and
          (Status not in ('D', 'I' /* Deleted, Inactive */)) and
          (Location like @Location);

  /* Loop through all locations and recalculate the counts & status */
  while exists(select * from #LocationsList where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId   = RecordId,
                   @vLocationId = LocationId,
                   @vLocation   = Location
      from #LocationsList
      where (RecordId > @vRecordId)
      order by RecordId;

      exec pr_Locations_UpdateCount @vLocationId, @vLocation;
    end

  /* update the Actual count on the #table for comparison */
  update ttLoc
  set ActualPallets    = Loc.NumPallets,
      ActualLPNs       = Loc.NumLPNs,
      ActualInnerPacks = Loc.InnerPacks,
      ActualUnits      = Loc.Quantity,
      ActualStatus     = Loc.Status
  from #LocationsList ttLoc
    join Locations Loc with (nolock) on (ttLoc.LocationId = Loc.LocationId);

  /* Get the Locations which has mismatch counts with actual count */
  select Location, LocationType, StorageType, Status, NumPallets, NumLPNs, InnerPacks, NumUnits,
         ActualPallets, ActualLPNs, ActualInnerPacks, ActualUnits, ActualStatus,
         'Incorrect ' + concat_ws(', ',
                          case when (NumPallets <> ActualPallets)    then 'Pallet count' end,
                          case when (NumLPNs    <> ActualLPNs   )    then 'LPN count'    end,
                          case when (InnerPacks <> ActualInnerPacks) then 'InnerPacks'   end,
                          case when (NumUnits   <> ActualUnits  )    then 'Units'        end,
                          case when (Status     <> ActualStatus )    then 'Status'       end)
             as Discrepency
  into #LocationsCountsMismatch
  from #LocationsList
  where (NumPallets <> ActualPallets   ) or
        (NumLPNs    <> ActualLPNs      ) or
        (InnerPacks <> ActualInnerPacks) or
        (NumUnits   <> ActualUnits     ) or
        (Status     <> ActualStatus    );

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #LocationsCountsMismatch;
      return(0);
    end

  /* Send email if there is data to report */
  if (@EmailIfNoAlert = 'Y') or (exists(select * from #LocationsCountsMismatch))
    exec pr_Email_SendQueryResults 'Alert_LocationsCountsMismatch', @TableName = '#LocationsCountsMismatch', @BusinessUnit =  @BusinessUnit;

end /* pr_Alerts_LocationsCountsMismatch */

Go
