/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  -- Deprecated - Not used anymore, in V3 we use pr_CycleCount_DS_GetLocationsToCount

  2020/07/08  MS      Added new Fields StorageTypeDesc, BusinessUnit (CIMSV3-548)
  2019/11/06  SK      Added new field PolicyCompliant (GNC-2229)
  2019/10/31  YJ      Added LocationABCClass (GNC-2592)
  2014/03/11  PK      Modified to retrieve only cycle counting tasks.
  2013/04/13  PKS     Added LocationRow, LocationLevel, LocationSection fields.
  2012/09/12  VM      Modified to not to show Locations, which are not required for CC.
  2012/02/01  VM      Modified to show only Locations, which has no active tasks
  2012/01/24  PKS     Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwLocationsForCycleCount') is not null
  drop View dbo.vwLocationsForCycleCount;
Go

Create View vwLocationsForCycleCount (
  LocationId,
  Location,
  LocationType,
  StorageType,
  StorageTypeDesc,
  Status,
  LocationRow,
  LocationLevel,
  LocationSection,
  SKU,
  PickZone,
  PutawayZone,
  LocationABCClass,
  LastCycleCounted,
  PolicyCompliant,
  DaysAfterLastCycleCount,
  HasActiveCCTask,
  ScheduledDate,
  BusinessUnit
) As
select
  L.LocationId,
  L.Location,
  L.LocationType,
  L.StorageType,
  LST.TypeDescription,
  L.Status,
  L.LocationRow,
  L.LocationLevel,
  L.LocationSection,
  S.SKU,
  L.PickingZone,
  L.PutawayZone,
  L.LocationABCClass,
  L.LastCycleCounted,
  L.PolicyCompliant,
  datediff(day, L.LastCycleCounted, current_timestamp),
  case
    when (TD.TaskId is null) then
      'N' /* No */
    else
      'Y' /* Yes */
  end,
  TD.ScheduledDate,
  L.BusinessUnit
from
  Locations L
  left outer join vwTaskDetails TD  on (TD.LocationId   = L.LocationId) and
                                       (TD.Status       = 'N' /* Ready to start */) and
                                       (TD.TaskType     = 'CC'/* Cycle Count */) and
                                       (TD.TaskStatus in ('I' /* In Progress */, 'N' /* Ready to start */))
  left outer join SKUs          S   on (L.SKUId         = S.SKUId)
  left outer join EntityTypes   LST on (LST.TypeCode    = L.StorageType       ) and
                                       (LST.Entity      = 'LocationStorage'   ) and
                                       (LST.BusinessUnit= L.BusinessUnit      )

where (L.Status   <> 'I' /* Inactive */) and
      (L.LocationId <> coalesce(TD.LocationId, '')) and
      (L.LocationType in ('R' /* Reserve */, 'B' /* Bulk */, 'K' /* Picklane */, 'S'/* Staging */, 'D'/* Dock */));

Go
