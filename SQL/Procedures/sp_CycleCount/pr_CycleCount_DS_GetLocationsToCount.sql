/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/09  OK      pr_CycleCount_DS_GetLocationsToCount: Changes to return the Empty picklane locations which don't have any logical LPNs (HA-2216)
  2020/09/18  MS      pr_CycleCount_DS_GetLocationsToCount:Paased LocationId in dataset to use it for ListLink
  2020/09/09  KBB     pr_CycleCount_DS_GetLocationsToCount : Added Warehouse field (HA-1406)
  2020/09/03  SK      pr_CycleCount_DS_GetLocationsToCount; Fix to conver null value to empty for SKUId such that unique id is always populated (CIMSV3-548)
  2020/07/13  MS      pr_CycleCount_DS_GetLocationsToCount: Added new proc to return locations to CC (CIMSV3-548)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_DS_GetLocationsToCount') is not null
  drop Procedure pr_CycleCount_DS_GetLocationsToCount;
Go
/*------------------------------------------------------------------------------
  Procedure pr_CycleCount_DS_GetLocationsToCount: This procedure returns all locations
   for the selected filters in CycleCountLocations page

  #ResultDataSet - TLocationsToCycleCountData
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_DS_GetLocationsToCount
  (@xmlInput     XML,
   @OutputXML    TXML = null output)
as
  declare @vCCLocationDetail  TLookUpcode,
          @vPendingCCLoc      TFlag,
          @vDebug             TFlag,
          @vSelectedSKU       TSKU,

          @vBusinessUnit      TBusinessUnit;

  declare @ttInputData as table(PickZone         TLookUpcode,
                                PutawayZone      TLookUpcode,
                                StorageType      TTypeCode,
                                LocationType     TTypeCode,
                                PendingCCLoc     TFlag,
                                CCLocationDetail TLookUpcode,
                                SKU              TSKU,
                                BusinessUnit     TBusinessUnit);
  declare @ttLocationsInfo as table(LocationId          TRecordId,
                                    SKUId               TRecordId,
                                    NumSKUs             TCount,
                                    NumLPNs             TCount,
                                    InnerPacks          TQuantity,
                                    Quantity            TQuantity,
                                    CCTaskId            TRecordId,
                                    BatchNo             TTaskBatchNo,
                                    CCTaskScheduledDate TDatetime,
                                    BusinessUnit        TBusinessUnit);
begin /* pr_CycleCount_DS_GetLocationsToCount */

  if (object_id('tempdb..#ResultDataSet')) is null return;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  /* Create table structure */
  select * into #InputData from @ttInputData;
  select * into #LocationsInfo from @ttLocationsInfo;

  /* Fetch the inputs */
  insert into #InputData(PutawayZone, PickZone, StorageType, LocationType, PendingCCLoc, CCLocationDetail, SKU, BusinessUnit)
    select Record.Col.value('(Data/PutawayZone/text())[1]',      'TLookUpCode'  ),
           Record.Col.value('(Data/PickingZone/text())[1]',      'TLookUpCode'  ),
           Record.Col.value('(Data/StorageType/text())[1]',      'TTypeCode'    ),
           Record.Col.value('(Data/LocationType/text())[1]',     'TTypeCode'    ),
           Record.Col.value('(Data/PendingCCLoc/text())[1]',     'TFlag'        ),
           Record.Col.value('(Data/CCLocationDetail/text())[1]', 'TLookUpcode'  ),
           Record.Col.value('(Data/SKU/text())[1]',              'TSKU'         ),
           Record.Col.value('(SessionInfo/BusinessUnit) [1]',    'TBusinessUnit')
    from @xmlInput.nodes('/Root') as Record(Col)
    OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  if (charindex('D' /* Display */, @vDebug) > 0) select '#InputData', * from #InputData

  /* fetch the inputs */
  select @vCCLocationDetail = CCLocationDetail,
         @vPendingCCLoc     = PendingCCLoc,
         @vSelectedSKU      = coalesce(SKU, '')
  from #InputData

  /* CC Locations can be presented just as Locations or Locations & SKU, so based upon
     the user selection, get the details to show */
  if (@vCCLocationDetail = 'LOC')
    insert into #LocationsInfo(LocationId, SKUId,  NumSKUs, NumLPNs, InnerPacks, Quantity, BusinessUnit)
      select LOC.LocationId, case when count(distinct(L.SKUId)) > 1 then null else min(L.SKUId) end, count(distinct(L.SKUId)), min(Loc.NumLPNs), sum(L.InnerPacks), sum(L.Quantity), min(ID.BusinessUnit)
      from #InputData ID
        join Locations       LOC on (coalesce(ID.LocationType, LOC.LocationType   ) = LOC.LocationType              ) and
                                    (coalesce(ID.StorageType,  LOC.StorageType    ) = LOC.StorageType               ) and
                                    (coalesce(ID.PutawayZone,  LOC.PutawayZone, '') = coalesce(LOC.PutawayZone,  '')) and
                                    (coalesce(ID.PickZone,     LOC.PickingZone, '') = coalesce(LOC.PickingZone,  ''))
        left outer join LPNs L   on (LOC.LocationId = L.LocationId)
      where (LOC.Status <> 'I' /* Inactive */)
      group by LOC.LocationId;
  else
  if (@vCCLocationDetail = 'LOCSKU')
    insert into #LocationsInfo(LocationId, SKUId, NumLPNs, InnerPacks, Quantity, BusinessUnit)
      select LOC.LocationId, L.SKUId, count(L.LPNId), sum(L.InnerPacks), sum(L.Quantity), min(ID.BusinessUnit)
      from #InputData ID
        join Locations       LOC on (coalesce(ID.LocationType, LOC.LocationType   ) = LOC.LocationType              ) and
                                    (coalesce(ID.StorageType,  LOC.StorageType    ) = LOC.StorageType               ) and
                                    (coalesce(ID.PutawayZone,  LOC.PutawayZone, '') = coalesce(LOC.PutawayZone,  '')) and
                                    (coalesce(ID.PickZone,     LOC.PickingZone, '') = coalesce(LOC.PickingZone,  ''))
        left outer join LPNs L   on (LOC.LocationId = L.LocationId)
      where (LOC.Status <> 'I' /* Inactive */)
      group by LOC.LocationId, L.SKUId;

  /* Update existing CC Details */
  update LI
  set LI.CCTaskId            = T.TaskId,
      LI.BatchNo             = T.BatchNo,
      LI.CCTaskScheduledDate = T.ScheduledDate
  from #LocationsInfo LI
    join TaskDetails TD on (LI.LocationId = TD.LocationId) and
                           (TD.Status     = 'N' /* Ready to start */)
    join Tasks T        on (TD.TaskId     = T.TaskId)
  where (T.Status in ('I' /* In Progress */, 'N' /* Ready to start */)) and
        (T.TaskType    = 'CC'/* Cycle Count */);

  if (charindex('D' /* Display */, @vDebug) > 0) select '#LocationsInfo', * from #LocationsInfo

  /* If we don't need Pending CC Locations then delete them */
  if (@vPendingCCLoc = 'N')
    delete from #LocationsInfo where (CCTaskId is not null);

  /* Insert required Locations */
  insert into #ResultDataSet(LocationId, Location, LocationType, LocationTypeDesc, StorageType, StorageTypeDesc, PutawayZone, PickZone,
                             PutawayZoneDesc, PickZoneDesc, LocationStatus, LocationStatusDesc, LocationSubType, LocationSubTypeDesc,
                             LocationRow, LocationLevel, LocationSection, Warehouse,
                             SKU, SKU1, SKU2, SKU3, SKU4, SKU5, SKU1Desc, SKU2Desc, SKU3Desc, SKU4Desc, SKU5Desc,
                             NumSKUs, NumLPNs, InnerPacks, Quantity, LocationABCClass, LastCycleCounted, PolicyCompliant,
                             DaysAfterLastCycleCount, HasActiveTask, ScheduledDate, TaskId, BatchNo, BusinessUnit, UniqueId)
    select LOC.LocationId, LOC.Location, LOC.LocationType, LOC.LocationTypeDesc, LOC.StorageType, LOC.StorageTypeDesc, LOC.PutawayZone, LOC.PickingZone,
           LOC.PutawayZoneDesc, LOC.PickingZoneDesc, LOC.LocationStatus, LOC.LocationStatusDesc, LOC.LocationSubType, LOC.LocationSubTypeDesc,
           LOC.LocationRow, LOC.LocationLevel, LOC.LocationSection, LOC.Warehouse,
           coalesce(S.SKU, 'Mixed'), S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5, S.SKU1Description, S.SKU2Description, S.SKU3Description, S.SKU4Description, S.SKU5Description,
           LI.NumSKUs, LI.NumLPNs, LI.InnerPacks, LI.Quantity, LOC.LocationABCClass, LOC.LastCycleCounted, 'N' /* No */,
           coalesce(datediff(day, LOC.LastCycleCounted, current_timestamp), 999/* Default Days */), case when (LI.CCTaskId is null) then 'N' /* No */ else 'Y' /* Yes */ end,
           LI.CCTaskScheduledDate, LI.CCTaskId, LI.BatchNo, LI.BusinessUnit, cast(LOC.LocationId as varchar(10)) + '-' + coalesce(cast(S.SKUId as varchar(10)), '')
    from vwLocations         LOC
      join #LocationsInfo    LI on (LI.LocationId  = LOC.LocationId)
      left outer join SKUs   S  on (coalesce(S.SKUId, '')     = coalesce(LI.SKUId, '')) and
                                   (S.SKU like @vSelectedSKU + '%') and
                                   (S.BusinessUnit = LI.BusinessUnit)

end  /* pr_CycleCount_DS_GetLocationsToCount */

Go
