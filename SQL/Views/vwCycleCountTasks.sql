/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/21  KBB     Initial Revision.(CIMSV3-1024)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwCycleCountTasks') is not null
  drop View dbo.vwCycleCountTasks;
Go

Create View dbo.vwCycleCountTasks (
  TaskId,

  TaskType,
  TaskTypeDesc,
  TaskSubType,
  TaskSubTypeDesc,
  TaskStatus,
  TaskStatusDesc,
  TaskStatusGroup,
  TaskDesc,
  ScheduledDate,
  /* Task Details */
  DetailCount,
  CompletedCount,
  PercentComplete,

  /* Counts */
  NumLPNs,
  NumLocations,

  BatchNo,
  Priority,
  Warehouse,
  WarehouseDesc,
  Ownership,

  PickGroup,
  AssignedTo,

  StartTime,
  EndTime,
  StopTime,
  ElapsedMins,
  DurationInMins,
  CompletedDate,
  PrintedDateTime,
  PrintDate,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  T.TaskId,

  T.TaskType,
  ETT.TypeDescription,
  T.TaskSubType,
  ESTT.TypeDescription,
  T.Status,
  TS.StatusDescription,
  case
    when (T.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end,
  T.TaskDesc,
  T.ScheduledDate,

  /* Task Details */
  T.DetailCount,
  T.CompletedCount,
  case
    when coalesce(T.DetailCount, 0) = 0 then -- avoid division by zero error
      null
    else
      cast(convert(float, T.CompletedCount)/convert(float, T.DetailCount) * 100 as Decimal(5,2))
  end /* Percent Complete */,
  /* Counts */
  T.NumLPNs,
  T.NumLocations,

  T.BatchNo,
  T.Priority,
  T.Warehouse,
  WH.LookUpDescription,
  T.Ownership,

  T.PickGroup,
  T.AssignedTo,

  T.StartTime,
  T.EndTime,
  T.StopTime,
  T.ElapsedMins,
  cast(coalesce(T.DurationInMins, 0) as float), -- Need to convert into float/int as we need to show summaries in UI
  T.CompletedDate,
  T.PrintedDateTime,
  T.PrintDate,

  T.Archived,
  T.BusinessUnit,
  T.CreatedDate,
  T.ModifiedDate,
  T.CreatedBy,
  T.ModifiedBy
from
  Tasks T
  left outer join Statuses     TS   on (TS.StatusCode       = T.Status        ) and
                                       (TS.Entity           = 'Task'          ) and
                                       (TS.BusinessUnit     = T.BusinessUnit  )
  left outer join EntityTypes  ETT  on (ETT.TypeCode        = T.TaskType      ) and
                                       (ETT.Entity          = 'Task'          ) and
                                       (ETT.BusinessUnit    = T.BusinessUnit  )
  left outer join EntityTypes  ESTT on (ESTT.TypeCode       = T.TaskSubType   ) and
                                       (ESTT.Entity         = 'SubTask'       ) and
                                       (ESTT.BusinessUnit   = T.BusinessUnit  )
  left outer join LookUps      WH   on (WH.LookUpCategory   = 'Warehouse'     ) and
                                       (WH.LookUpCode       = T.Warehouse     ) and
                                       (WH.BusinessUnit     = T.BusinessUnit  )
where (T.TaskType = 'CC' /* Cycle Count */)

Go