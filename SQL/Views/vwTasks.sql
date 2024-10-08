/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/22  SAK     Added ModifiedOn (CIMSV3-1395)
  2020/07/29  RV      Added PrintStatus (S2GCA-1199)
  2020/05/15  TK      PickBatch to WaveType (HA-453)
  2020/01/22  AY      Added PicksFrom/PicksFor for display in UI and labels
  2019/08/23  AY      Added Start/End Location/Destination (CID-Support)
  2019/12/06  YJ      Mapped to show CreatedBy with vwPT_UDF4 (S2GCA-98) (Ported from Prod)
  2019/08/14  MJ      Added fields StopTime, PrintDate, ElapsedMins, CompletedDate and Renamed PrintedDate as PrintedDateTime (OB2-900)
  2019/08/09  AJ      Added PrintedTime (OB2-898)
  2019/06/10  AY      Added WaveType, WaveTypeDesc (CID-518)
  2019/06/05  AY      Added Task.TotalIPsCompleted, TotalIPsRemaining, TotalUnitsCompleted, TotalUnitsRemaining, NumOrders, NumLPNs, NumTempLabels
  2019/03/06  NB      Added LPNCount(CIMSV3-370)
  2018/12/10  DA      Added CartType field (HPI-2232)
  2018/11/13  VM/KSK  DurationInMin convert into float(OB2-727)
  2018/11/17  AY      Added Tasks.WaveId, WaveNo & changed join fields
  2018/11/06  MS      Added UnitsCompleted, UnitsToPick & PercentUnitsComplete(OB2-701)
  2018/10/08  MJ      Made changes to vwPT_UDF4 to get the ShipToId values (OB2-656)
  2018/10/08  VM      set DependencyFlag to empty when null to utilize for UI filter (HPI-2073)
  2018/08/30  MS      Added StatusGroup Field (OB2-606)
  2018/05/03  KSK     Show ShipToName,ShipToStore in  vwPT_UDF2,vwPT_UDF3 S2G(691)
  2018/04/30  KSK     Added IsTaskConfirmed (S2G-289)
  2018/04/18  VM      Show ShipDate in vwPT_UDF1 (S2G-669)
  2018/03/01  KSK     Added IsTaskConfirmed (S2G-289)
  2018/02/19  TD      Added PickGroup (S2G-218)
  2017/05/15  AY      Added DependentOn, StartTime, EndTime, Duration, WaveCancelDate, WaveGroup fields (CIMS-1400)
  2016/08/01  OK      Added DependencyFlags (HPI-371)
  2016/08/01  PSK     Added LabelsPrinted (HPI-408)
  2016/07/28  AY      Added BatchTypeDesc
  2016/16/02  YJ      Added field Ownership (NBD-170)
  2016/18/11  YJ      Added NumLPNPicks, NumUnitPicks (FB-791)
  2015/09/01  TK      Mapped vwPT_UDF2 -> PB.AccountName
                             vwPT_UDF3 -> PB.PickBatchGroup (ACME-322)
  2015/07/12  AY      Added PalletId, IsTaskAllocated
  2015/06/26  VS/YJ   Added: OrderCount
  2015/03/30  RV      Show PB cancel date in vwPT_UDF1 for Pick Tasks
  2014/09/12  AY      Tasks: Added TaskCategory and UDF fields
  2014/08/30  TK      Added BatchType field.
  2014/05/24  PK      Added TotalInnerPacks, TotalUnits, Warehouse, WarehouseDescription,
                        AssignedTo.
  2012/01/18  SP      Added "ScheduledDate" field.
  2012/01/04  VM      Added TaskDesc
  2011/12/29  PKS     Percentage Completed calculation corrected.
  2011/12/19  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwTasks') is not null
  drop View dbo.vwTasks;
Go

Create View dbo.vwTasks (
  TaskId,

  TaskType,
  TaskTypeDescription,
  TaskSubType,
  TaskSubTypeDescription,
  TaskDesc,
  Status,
  ScheduledDate,
  StatusDescription,
  StatusGroup,
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
  UnitsCompleted, -- deprecated, use TotalUnitsCompleted
  UnitsToPick,    -- deprecated, use TotalUnitsRemaining

  PercentUnitsComplete,
  PercentComplete,
  -- NumLPNPicks,
  -- NumUnitPicks,
  /* Counts */
  NumOrders,
  NumLPNs,
  NumTempLabels,
  NumCases,
  NumLocations,
  NumDestinatons,
  LPNCount,    -- deprecated, use NumLPNs
  OrderCount,  -- deprecated, use NumOrders

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
  BatchNo,
  BatchType,
  BatchTypeDesc,
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
  ModifiedBy,
  ModifiedOn

) As
select
  T.TaskId,

  T.TaskType,
  ETT.TypeDescription,
  T.TaskSubType,
  ESTT.TypeDescription,
  T.TaskDesc,
  T.Status,
  T.ScheduledDate,
  S.StatusDescription,
  case
    when (T.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end,
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

  T.UnitsCompleted, -- deprecated, use TotalUnitsCompleted
  T.TotalUnits - T.UnitsCompleted, /* UnitsToPick */ -- deprecated, use TotalUnitsRemaining

  case
    when coalesce(T.TotalUnits, 0) = 0 then -- avoid division by zero error
      0
    else
      cast(convert(float, T.UnitsCompleted )/convert(float, T.TotalUnits) * 100 as Decimal(5,2))
  end /* Percent UnitsComplete */,
  case
    when coalesce(T.DetailCount, 0) = 0 then -- avoid division by zero error
      null
    else
      cast(convert(float, T.CompletedCount )/convert(float, T.DetailCount) * 100 as Decimal(5,2))
  end /* Percent Complete */,
  -- T.NumLPNPicks,
  -- T.NumUnitPicks,
  /* Counts */
  T.NumOrders,
  T.NumLPNs,
  T.NumTempLabels,
  T.NumCases,
  T.NumLocations,
  T.NumDestinations,
  T.LPNCount,  -- deprecated, use NumLPNs
  T.OrderCount, -- depracated, use NumOrders

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
  T.BatchNo,
  W.BatchType,
  WT.TypeDescription,
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
  /* Picks From */ T.StartLocation + coalesce(' to ' + nullif(nullif(T.EndLocation, ''), T.StartLocation), ''),
  /* Picks For */  T.StartDestination + coalesce(' to ' + nullif(nullif(T.EndDestination, ''), T.StartDestination), ''),

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
  T.ModifiedBy,
  T.ModifiedOn
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
  left outer join EntityTypes  WT   on (WT.TypeCode         = W.BatchType     ) and
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

Go