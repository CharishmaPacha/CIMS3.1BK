/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/05/04  LRA     Changes to resolve the truncate issue with data (CIMS-1326)
  2016/06/09  TK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwTasksToPick') is not null
  drop View dbo.vwTasksToPick;
Go

Create View dbo.vwTasksToPick (
  /* Task */
  TaskId,

  TaskType,
  TaskSubType,
  TaskStatus,

  DetailCount,
  CompletedCount,
  TotalInnerPacks,
  TotalUnits,
  PercentComplete,

  BatchNo,
  PickZone,
  PickSequence,
  PutawayZone,
  TaskPriority,
  Warehouse,
  TaskAssignedTo,
  DestZone,

  /* Task Detail */
  TaskDetailId,
  TaskDetailStatus,
  DetailInnerPacks,
  DetailQuantity,
  UnitsCompleted,
  UnitsToPick,
  OrderId,
  OrderDetailId,
  SKUId,
  IsLabelGenerated,

  /* Location */
  LocationId,
  Location,
  LocationType,
  PickPathPosition,
  LocPickZone,

  /* LPN */
  LPNId,
  LPN,
  LPNType,
  LPNQuantity,
  AlternateLPN,

  /* LPN Detail */
  LPNDetailId,
  OnhandStatus,

  /* Temp Label */
  TempLabelId,
  TempLabel,

  /* Pick Batch */
  PickBatchId,
  PickBatchNo,
  BatchType,
  PickBatchStatus,
  BatchPriority,
  WaveAssignedTo,

  PB_UDF1,
  PB_UDF2,
  PB_UDF3,
  PB_UDF4,
  PB_UDF5,
  PB_UDF6,
  PB_UDF7,
  PB_UDF8,
  PB_UDF9,
  PB_UDF10,

  WaveId,     /* For future use */
  RuleId,
  IsAllocated,

  vwTP_UDF1,
  vwTP_UDF2,
  vwTP_UDF3,
  vwTP_UDF4,
  vwTP_UDF5,
  vwTP_UDF6,
  vwTP_UDF7,
  vwTP_UDF8,
  vwTP_UDF9,
  vwTP_UDF10,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,
  DetailModifiedDate,
  DetailModifiedBy
)As
select
  /* Task */
  T.TaskId,

  T.TaskType,
  T.TaskSubType,
  T.Status,

  T.DetailCount,
  T.CompletedCount,
  T.TotalInnerPacks,
  T.TotalUnits,
  /* Task Percent Complete */
  case when T.DetailCount = 0 then 0
       when T.DetailCount > 0 then T.CompletedCount/T.DetailCount*100
  end,

  T.BatchNo,
  Loc.PickingZone,
  TD.PickSequence,
  T.PutawayZone,
  T.Priority,
  LOC.Warehouse,
  T.AssignedTo,
  T.DestZone,

  /* Task Detail */
  TD.TaskDetailId,
  TD.Status,
  TD.InnerPacks,
  TD.Quantity,
  coalesce(TD.UnitsCompleted, 0),
  TD.UnitsToPick,
  TD.OrderId,
  TD.OrderDetailId,
  TD.SKUId,
  TD.IsLabelGenerated,

  /* Location */
  TD.LocationId,
  LOC.Location,
  LOC.LocationType,
  LOC.PickPath,
  LOC.PickingZone,

  /* LPN */
  TD.LPNId,
  L.LPN,
  L.LPNType,
  L.Quantity,
  L.AlternateLPN,

  /* LPN Detail */
  TD.LPNDetailId,
  LD.OnhandStatus,

  /* Temp Label */
  TD.TempLabelId,
  TD.TempLabel,

  /* Pick Batch */
  PB.RecordId,
  PB.BatchNo,
  PB.BatchType,
  PB.Status,
  PB.Priority,
  PB.AssignedTo,

  PB.UDF1,
  PB.UDF2,
  PB.UDF3,
  PB.UDF4,
  PB.UDF5,
  PB.UDF6,
  PB.UDF7,
  PB.UDF8,
  PB.UDF9,
  PB.UDF10,

  PB.WaveId,     /* For future use */
  PB.RuleId,
  PB.IsAllocated,

  PB.BatchType + '-' + T.TaskSubType,   /* For Future Use */
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),

  T.BusinessUnit,
  T.CreatedDate,
  T.ModifiedDate,
  T.CreatedBy,
  T.ModifiedBy,
  TD.ModifiedDate,
  TD.ModifiedBy
from
  TaskDetails TD
    join Tasks       T    on (TD.TaskId      = T.TaskId      )
    join PickBatches PB   on (T.BatchNo      = PB.BatchNo    )
    join Locations   LOC  on (TD.LocationId  = LOC.LocationId)
    join LPNs        L    on (TD.LPNId       = L.LPNId       )
    join LPNDetails  LD   on (TD.LPNDetailId = LD.LPNDetailId)
where (T.TaskType = 'PB' /* PickBatch */) and
      (T.Archived = 'N') and
      (LD.OnHandStatus <> 'DR' /* Directed Reserve */) and
      (TD.Status not in ('C', 'X' /* Completed or Canceled */)) and
      (T.Status not in ('C', 'X' /* Completed or Canceled */)) and
      (UnitsToPick > 0)
;

Go