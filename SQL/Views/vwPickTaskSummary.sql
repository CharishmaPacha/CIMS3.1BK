/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/16  KSK     Made changes to group the fields LocationLevel, LocationRow (S2G-1003)
  2016/09/08  SV      Passed an empty character for the fields which are defined as not null (HPI-583)
  2016/08/20  PSK     Changed the vwPTS_UDF1 name (CIMS-1027)
  2016/08/15  AY      Added vwUDFs - deprecated UDFs (CIMS-1027)
  2016/08/09  PSK     Changed the UDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2014/06/20  PKS     Added TaskDetailId
  2014/05/31  TD      Added DestZone, Used UDF1 as PickArea.
  2013/11/24  AY      Show only tasks that are not archived for performance reasons
  2013/11/13  PKS     Initial revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPickTaskSummary') is not null
  drop View dbo.vwPickTaskSummary;
Go

Create View vwPickTaskSummary (
  TaskId,
  TaskDetailId,
  TaskStatus,
  TaskStatusDesc,
  StatusSortSeq,

  DestZone,

  PickZone,
  PickZoneDesc,
  Warehouse,
  ActivityDate,

  ShipToStore,

  LocationLevel,
  LocationRow,

  AssignedTo,

  BatchNo,
  BatchType,
  BatchTypeDesc,
  CancelDate,

  PickWeight,
  PickVolume,

  InnerPacksToPick,
  InnerPacksCompleted,
  TotalInnerPacks,
  UnitsToPick,
  UnitsCompleted,
  TotalUnits,
  PercentComplete,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  vwPTS_UDF1,
  vwPTS_UDF2,
  vwPTS_UDF3,
  vwPTS_UDF4,
  vwPTS_UDF5
)
As
select
 T.TaskId,
 T.TaskDetailId,
 T.TaskStatus,
 S.StatusDescription,
 cast(S.SortSeq as varchar) + '-' + S.StatusDescription,

 T.DestZone,

 T.PickZone,
 PZ.LookUpDescription,
 T.Warehouse,
 T.ScheduledDate,

  coalesce(T.ShipToStore, ''),

 '', -- T.LocationLevel,
 '', -- T.LocationRow,

 T.AssignedTo,

 T.BatchNo,
 T.BatchType,
 ET.TypeDescription,
 T.CancelDate,

 round(sum(T.PickWeight), 0),
 round(sum(T.PickVolume), 0),

 sum(coalesce(T.InnerPacksToPick, 0)),
 sum(coalesce(T.InnerPacksCompleted, 0)),
 sum(case when T.TaskStatus in ('C', 'X') then coalesce(T.InnerPacksCompleted, 0)
          else coalesce(T.InnerPacksToPick, 0) + coalesce(T.InnerPacksCompleted, 0) end),
 sum(coalesce(T.UnitsToPick, 0)),
 sum(coalesce(T.UnitsCompleted, 0)),
 sum(case when T.TaskStatus in ('C', 'X') then coalesce(T.UnitsCompleted, 0)
          else coalesce(T.UnitsToPick, 0) + coalesce(T.UnitsCompleted, 0) end),
 Avg(T.PercentComplete),

 /* UDFs */
 T.vwPT_UDF1,              -- deprecated, do not use
 cast(' ' as varchar(50)), -- deprecated, do not use
 cast(' ' as varchar(50)), -- deprecated, do not use
 cast(' ' as varchar(50)), -- deprecated, do not use
 cast(' ' as varchar(50)), -- deprecated, do not use

 /* vwPTS_UDFs */
 cast(' ' as varchar(50)),
 cast(' ' as varchar(50)),
 cast(' ' as varchar(50)),
 cast(' ' as varchar(50)),
 cast(' ' as varchar(50))

from
  vwPickTasks T
  left outer join Statuses     S  on  (S.StatusCode      = T.TaskStatus   ) and
                                      (S.Entity          = 'Task'         )
  left outer join EntityTypes  ET  on (T.BatchType       = ET.TypeCode    ) and
                                      (ET.Entity         = 'PickBatch'    ) and
                                      (ET.BusinessUnit   = T.BusinessUnit )
  left outer join LookUps      PZ  on (T.PickZone        = PZ.LookUpCode  ) and
                                      (PZ.LookUpCategory = 'PickZones'    ) and
                                      (T.BusinessUnit    = S.BusinessUnit )
where (T.TaskType = 'PB') and
      (T.Archived = 'N') and
      (T.ScheduledDate = cast(getdate() as date))
group by  T.TaskId, T.TaskDetailId, T.TaskStatus, S.StatusDescription, cast(S.SortSeq as varchar) + '-' + S.StatusDescription,
          T.DestZone, T.PickZone, PZ.LookUpDescription, T.Warehouse, T.ScheduledDate, T.ShipToStore, T.AssignedTo,
          T.BatchNo, T.BatchType, ET.TypeDescription, T.CancelDate, T.vwPT_UDF1

Go