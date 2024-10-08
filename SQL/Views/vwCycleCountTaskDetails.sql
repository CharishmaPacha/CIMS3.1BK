/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/21  KBB     Initial Revision.(CIMSV3-1024)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwCycleCountTaskDetails') is not null
  drop View dbo.vwCycleCountTaskDetails;
Go

Create View dbo.vwCycleCountTaskDetails (
  TaskDetailId,
  /* Task */
  TaskId,
  TaskType,
  TaskSubType,
  TaskSubTypeDesc,
  TaskStatus,
  TaskStatusGroup,

  BatchNo,
  PickZone,
  PickZoneDesc,
  PutawayZone,
  PutawayZoneDesc,

  /* Task Detail */
  TaskDetailStatus,
  TaskDetailStatusDesc,
  TaskDetailStatusGroup,
  TransactionDate,

  /* Location */
  LocationId,
  Location,
  LocationRow,
  LocationSection,
  LocationLevel,
  LocationType,
  PickPath,
  PutawayPath,

  SKU,
  SKUDescription,
  Ownership,
  Warehouse,

  ScheduledDate,
  TaskPriority,
  PickGroup,

  vwCCT_UDF1,
  vwCCT_UDF2,
  vwCCT_UDF3,
  vwCCT_UDF4,
  vwCCT_UDF5,
  vwCCT_UDF6,
  vwCCT_UDF7,
  vwCCT_UDF8,
  vwCCT_UDF9,
  vwCCT_UDF10,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
)As
select
  TD.TaskDetailId,
  /* Task */
  T.TaskId,

  T.TaskType,
  T.TaskSubType,
  ESTT.TypeDescription,
  T.Status,
  case
    when (T.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end,

  T.BatchNo,
  Loc.PickingZone,
  LU1.LookUpDescription,
  Loc.PutawayZone,
  LU2.LookUpDescription,

  /* Task Detail */
  TD.Status,
  DST.StatusDescription,
  case
    when (TD.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end,
  TD.TransactionDate,

  /* Location */
  TD.LocationId,
  LOC.Location,
  LOC.LocationRow,
  LOC.LocationSection,
  LOC.LocationLevel,
  LOC.LocationType,
  LOC.PickPath,
  LOC.PutawayPath,

  S.SKU,
  S.Description,
  T.Ownership,
  LOC.Warehouse,

  T.ScheduledDate,
  T.Priority,
  T.PickGroup,

  cast(' ' as varchar(50)), /* vwCCT_UDF1 */
  cast(' ' as varchar(50)), /* vwCCT_UDF2 */
  cast(' ' as varchar(50)), /* vwCCT_UDF3 */
  cast(' ' as varchar(50)), /* vwCCT_UDF4 */
  cast(' ' as varchar(50)), /* vwCCT_UDF5 */
  cast(' ' as varchar(50)), /* vwCCT_UDF6 */
  cast(' ' as varchar(50)), /* vwCCT_UDF7 */
  cast(' ' as varchar(50)), /* vwCCT_UDF8 */
  cast(' ' as varchar(50)), /* vwCCT_UDF9 */
  cast(' ' as varchar(50)), /* vwCCT_UDF10 */

  T.Archived,
  T.BusinessUnit,
  T.CreatedDate,
  T.ModifiedDate,
  T.CreatedBy,
  T.ModifiedBy

from Tasks T
             join TaskDetails  TD  on (TD.TaskId          = T.TaskId          )
  left outer join Locations    LOC on (LOC.LocationId     = TD.LocationId     )
  left outer join SKUs         S   on (S.SKUId            = LOC.SKUId         )
  left outer join Statuses     ST  on (ST.StatusCode      = T.Status          ) and
                                      (ST.Entity          = 'Task'            ) and
                                      (ST.BusinessUnit    = T.BusinessUnit    )
  left outer join Statuses     DST on (DST.StatusCode     = TD.Status         ) and
                                      (DST.Entity         = 'Task'            ) and
                                      (DST.BusinessUnit   = TD.BusinessUnit   )
  left outer join EntityTypes ESTT on (ESTT.TypeCode      = T.TaskSubType     ) and
                                      (ESTT.Entity        = 'SubTask'         ) and
                                      (ESTT.BusinessUnit  = T.BusinessUnit    )
  left outer join LookUps     LU1  on (LU1.LookUpCategory = 'PickZones'       ) and
                                      (LU1.LookUpCode     = Loc.PickingZone   ) and
                                      (LU1.BusinessUnit   = Loc.BusinessUnit  )
  left outer join LookUps     LU2  on (LU2.LookUpCategory = 'PutawayZones'    ) and
                                      (LU2.LookUpCode     = Loc.PutawayZone   ) and
                                      (LU2.BusinessUnit   = Loc.BusinessUnit  )
where (T.TaskType = 'CC' /* Cycle Count */) and (TD.TaskDetailId is not null)
;

Go
