/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/29  RV      Added PrintStatus (S2GCA-1199)
  2020/07/27  AY      Fixed PercentUnitsCompleted computation
  2020/05/15  MS      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwUIPickTasks') is not null
  drop View dbo.vwUIPickTasks;
Go

Create View dbo.vwUIPickTasks (
  TaskId,

  TaskType,
  TaskTypeDesc,
  PickTaskSubType,
  PickTaskSubTypeDesc,
  TaskDesc,
  TaskStatus,
  TaskStatusDesc,
  TaskStatusGroup,
  ScheduledDate,
  /* Task Details */
  DetailCount,
  CompletedCount,
  /* IPs/Units */
  TotalInnerPacks,
  TotalUnits,
  TotalIPsCompleted,
  TotalUnitsCompleted,
  TotalIPsRemaining,
  TotalUnitsRemaining,

  PercentUnitsComplete,
  PercentComplete,
  /* Counts */
  NumOrders,
  NumLPNs,
  NumTempLabels,
  NumCases,
  NumLocations,
  NumDestinatons,

  LabelsPrinted,
  PrintStatus,
  IsTaskAllocated,
  IsTaskConfirmed,
  DependencyFlags,
  DependentOn,
  Ownership,

  Account,
  AccountName,
  WaveCancelDate,
  WaveShipDate,
  WaveGroup,
  WaveShipToStore,

  WaveId,
  WaveNo,
  WaveType,
  WaveTypeDesc,
  PickZone,
  PutawayZone,
  PickZoneDescription,
  PutawayZoneDescription,
  PickZones,
  Priority,
  Warehouse,
  WarehouseDescription,

  DestZone,
  DestLocation,
  PalletId,
  Pallet,
  CartType,
  PickGroup,

  AssignedTo,

  TaskCategory1,
  TaskCategory2,
  TaskCategory3,
  TaskCategory4,
  TaskCategory5,

  StartTime,
  EndTime,
  StopTime,
  ElapsedMins,
  DurationInMins,
  CompletedDate,
  PrintedDateTime,
  PrintDate,

  StartLocation,
  EndLocation,
  StartDestination,
  EndDestination,
  PicksFrom,
  PicksFor,

  OrderId,
  PickTicket,
  SalesOrder,
  SoldToId,
  SoldToName,
  ShipToId,

  vwT_UDF1,
  vwT_UDF2,
  vwT_UDF3,
  vwT_UDF4,
  vwT_UDF5,

  vwPT_UDF1,
  vwPT_UDF2,
  vwPT_UDF3,
  vwPT_UDF4,
  vwPT_UDF5,

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
  T.TaskDesc,
  T.Status,
  S.StatusDescription,
  case
    when (T.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end, -- TaskStatusGroup
  T.ScheduledDate,
  /* Task Details */
  T.DetailCount,
  T.CompletedCount,
  /* IPs & Units */
  T.TotalInnerPacks,
  T.TotalUnits,

  T.TotalIPsCompleted,
  T.TotalUnitsCompleted,
  T.TotalIPsRemaining,
  T.TotalUnitsRemaining,

  case
    when coalesce(T.TotalUnits, 0) = 0 then -- avoid division by zero error
      0
    else
      cast(convert(float, T.TotalUnitsCompleted )/convert(float, T.TotalUnits) * 100 as Decimal(5,2))
  end /* Percent UnitsComplete */,
  case
    when coalesce(T.DetailCount, 0) = 0 then -- avoid division by zero error
      null
    else
      cast(convert(float, T.CompletedCount )/convert(float, T.DetailCount) * 100 as Decimal(5,2))
  end /* Percent Complete */,
  /* Counts */
  T.NumOrders,
  T.NumLPNs,
  T.NumTempLabels,
  T.NumCases,
  T.NumLocations,
  T.NumDestinations,

  T.LabelsPrinted,
  T.PrintStatus,
  T.IsTaskAllocated,
  T.IsTaskConfirmed,
  coalesce(T.DependencyFlags, ''),
  T.DependentOn,
  T.Ownership,

  W.Account,
  W.AccountName,
  W.CancelDate,
  W.ShipDate,
  W.PickBatchGroup,
  W.ShipToStore,

  T.WaveId,
  T.BatchNo,  /* WaveNo */
  W.WaveType,
  WT.TypeDescription, /* WaveTypeDesc */
  T.PickZone,
  T.PutawayZone,
  PiZ.LookUpDisplayDescription,
  PuZ.LookUpDisplayDescription,
  T.PickZones,
  coalesce(T.Priority, W.Priority),
  T.Warehouse,
  WH.LookUpDescription,

  T.DestZone,
  T.DestLocation,
  T.PalletId,
  T.Pallet,
  T.CartType,
  T.PickGroup,

  T.AssignedTo,

  T.TaskCategory1,
  T.TaskCategory2,
  T.TaskCategory3,
  T.TaskCategory4,
  T.TaskCategory5,

  T.StartTime,
  T.EndTime,
  T.StopTime,
  T.ElapsedMins,
  cast(coalesce(T.DurationInMins, 0) as float), -- Need to convert into float/int as we need to show summaries in UI
  T.CompletedDate,
  T.PrintedDateTime,
  T.PrintDate,

  T.StartLocation,
  T.EndLocation,
  T.StartDestination,
  T.EndDestination,
  /* Picks From */ T.StartLocation + coalesce(' to ' + nullif(T.EndLocation, ''), ''),
  /* Picks For */  T.StartDestination + coalesce(' to ' + nullif(T.EndDestination, ''), ''),

  T.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.SoldToId,
  OH.SoldToName,
  OH.ShipToId,

  T.UDF1,
  T.UDF2,
  T.UDF3,
  T.UDF4,
  T.UDF5,

  cast(' ' as varchar(50)), /* vwPT_UDF1 */
  cast(' ' as varchar(50)), /* vwPT_UDF2 */
  cast(' ' as varchar(50)), /* vwPT_UDF3 */
  cast(' ' as varchar(50)), /* vwPT_UDF4 */
  cast(' ' as varchar(50)), /* vwPT_UDF5 */

  T.Archived,
  T.BusinessUnit,
  T.CreatedDate,
  T.ModifiedDate,
  T.CreatedBy,
  T.ModifiedBy
from
  Tasks T
  left outer join Waves        W    on (T.WaveId            = W.RecordId      )
  left outer join Statuses     S    on (S.StatusCode        = T.Status        ) and
                                       (S.Entity            = 'Task'          ) and
                                       (S.BusinessUnit      = T.BusinessUnit  )
  left outer join EntityTypes  ETT  on (ETT.TypeCode        = T.TaskType      ) and
                                       (ETT.Entity          = 'Task'          ) and
                                       (ETT.BusinessUnit    = T.BusinessUnit  )
  left outer join EntityTypes  ESTT on (ESTT.TypeCode       = T.TaskSubType   ) and
                                       (ESTT.Entity         = 'SubTask'       ) and
                                       (ESTT.BusinessUnit   = T.BusinessUnit  )
  left outer join EntityTypes  WT   on (WT.TypeCode         = W.WaveType      ) and
                                       (WT.Entity           = 'Wave'          ) and
                                       (WT.BusinessUnit     = T.BusinessUnit  )
  left outer join OrderHeaders OH   on (T.OrderId           = OH.OrderId      )
  left outer join LookUps      PiZ  on (PiZ.LookUpCategory  = 'PickZones'     ) and
                                       (PiZ.LookUpCode      = T.PickZone      ) and
                                       (PiZ.BusinessUnit    = T.BusinessUnit  )
  left outer join LookUps      PuZ  on (PuZ.LookUpCategory  = 'PutawayZones'  ) and
                                       (PuZ.LookUpCode      = T.PickZone      ) and
                                       (PuZ.BusinessUnit    = T.BusinessUnit  )
  left outer join LookUps      WH   on (WH.LookUpCategory   = 'Warehouse'     ) and
                                       (WH.LookUpCode       = T.Warehouse     ) and
                                       (WH.BusinessUnit     = T.BusinessUnit  )
  where (T.TaskType = 'PB');

Go