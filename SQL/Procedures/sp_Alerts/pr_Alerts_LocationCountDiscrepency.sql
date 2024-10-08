/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/20  VM      pr_Alerts_LocationCountDiscrepency: Ignore alerts for the locations which has recently updated LPNs (S2G-GoLive)
  2018/05/23  AY      pr_Alerts_LocationCountDiscrepency: Disregard Conveyor Locations as well
  2017/05/09  TK      Added pr_Alerts_LocationCountDiscrepency (HPI-1638)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_LocationCountDiscrepency') is not null
  drop Procedure pr_Alerts_LocationCountDiscrepency;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_LocationCountDiscrepency:
    Evaluates the current counts on Locations.
    Sends alert, if there are any discrepencies

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last X minutes
  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only
  @EntityId
    - If passed, ignores all other entities by considering the passed in EntityId
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_LocationCountDiscrepency
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
As
  declare  @vAlertCategory   TCategory;

  declare @ttAlertData table (Location              TLocation,
                              LocationType          TDescription,
                              StorageType           TDescription,
                              Status                TStatus,
                              NumPallets            TCount,
                              NumLPNs               TCount,
                              NumUnits              TCount,
                              ActualPallets         TCount,
                              ActualLPNs            TCount,
                              ActualUnits           TCount,
                              Discrepency           TDescription,

                              RecordId              TRecordId identity(1, 1));
begin
  select @vAlertCategory   = Object_Name(@@ProcId)  -- pr_ will be trimmed by pr_Email_SendDBAlert

  select * into #LocationCountDiscrepency from @ttAlertData;

  /* select locations modified in the last 6 mins as the alert is scheduled to run every 5 mins,
     we should get the locations only once and not repeatedly */
  select LocationId, Location, LocationTypeDesc, replace(StorageTypeDesc, '&', ' and ') StorageTypeDesc, Status,
         NumPallets, NumLPNs, Quantity
  into #Locations
  from vwLocations with (nolock)
  where (LocationType not in ('S', 'D', 'C' /* Staging, Dock, Conveyor */)) and
        (Status not in ('I', 'D' /* Inactive, Deleted */)) and
        (datediff(mi, ModifiedDate, getdate()) <= @ShowModifiedInLastXMinutes) and
        (LocationId = coalesce(@EntityId, LocationId));

  with LocationActualPalletCount as
  (
    select P.LocationId, count(P.PalletId) AcutalPallets
    from Pallets P with (nolock) join #Locations LOC on P.LocationId = LOC.LocationId
    group by P.LocationId
  ),
  LocationActualLPNUnitsCount as
  (
    select L.LocationId, count(distinct L.LPNId) ActualLPNs, sum(LD.Quantity) ActualUnits
    from
      LPNs L with (nolock)
      join #Locations LOC on (LOC.LocationId = L.LocationId)
      join LPNDetails LD with (nolock)  on (L.LPNId = LD.LPNId)
    where (L.Archived = 'N') and
          (LD.OnhandStatus in ('A', 'R'))
    group by L.LocationId
  ),
  /* Find out the latest modified LPNs in the location, which are modified within certain minutes.
     If there are, we should ignore to send alert as we defer Location counts and system is showing discrepancies of LPN/Units counts during that period */
  LocationActualLPNModifiedRecently as
  (
    select L.LocationId, count(distinct L.LPNId) ActualLPNsModifiedRecentlyCount
    from LPNs L with (nolock)
      join #Locations LOC on (LOC.LocationId = L.LocationId)
    where (L.Archived = 'N') and
          (datediff(mi, L.ModifiedDate, getdate()) <= 10 /* in minutes */)
    group by L.LocationId
  )
  insert into #LocationCountDiscrepency (Location, LocationType, StorageType, Status, NumPallets, NumLPNs, NumUnits,
                                         ActualPallets, ActualLPNs, ActualUnits, Discrepency)
  select LLC.Location, LLC.LocationType, LLC.StorageType, LLC.Status, LLC.NumPallets, LLC.NumLPNs, LLC.NumUnits,
         coalesce(LP.ActualPallets, 0), LU.ActualLPNs, LU.ActualUnits,
         case when (LLC.NumPallets <> LP.ActualPallets) then 'Incorrect Pallet Count'
              when (LLC.NumLPNs    <> LU.ActualLPNs   ) then 'Incorrect LPN Count'
              when (LLC.NumUnits   <> LU.ActualUnits  ) then 'Incorrect Units'
         end
  from #Locations LLC
               join LocationActualLPNModifiedRecently  LM on (LLC.LocationId = LM.LocationId)
    left outer join LocationActualPalletCount          LP on (LLC.LocationId = LP.LocationId)
    left outer join LocationActualLPNUnitsCount        LU on (LLC.LocationId = LU.LocationId)
  where (LM.ActualLPNsModifiedRecentlyCount = 0) and
        ((LLC.NumPallets <> LP.ActualPallets) or
         (LLC.NumLPNs    <> LU.ActualLPNs   ) or
         (LLC.NumUnits   <> LU.ActualUnits  ))
  order by LLC.LocationType, LLC.StorageType, LLC.Location;

  /* If there is no data captured, then exit */
  if (@@rowcount = 0) return(0);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #LocationCountDiscrepency;
      return(0);
    end

  /* Email the results */
  if (exists (select * from #LocationCountDiscrepency))
    exec pr_Email_SendQueryResults @vAlertCategory, '#LocationCountDiscrepency', null /* order by */, @BusinessUnit;

end /* pr_Alerts_LocationCountDiscrepency */

Go
