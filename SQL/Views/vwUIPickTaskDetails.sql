/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/12  TK      Added CartonType (CID-1778)
  2021/01/22  SAK     Changed the PB.Status to ETPB.TypeDescription to display WavetypeDesc (HA-1936)
  2020/11/17  TK      Added Export Status (CID-1498)
  2020/05/15  MS      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwUIPickTaskDetails') is not null
  drop View dbo.vwUIPickTaskDetails;
Go

Create View dbo.vwUIPickTaskDetails (
  /* Task */
  TaskId,

  TaskType,
  PickTaskSubType,
  PickTaskSubTypeDesc,
  PickType,
  TaskDesc,
  TaskStatus,
  TaskStatusDesc,
  TaskStatusGroup,

  DetailCount,
  CompletedCount,
  TotalInnerPacks,
  TotalUnits,
  PercentComplete,

  BatchNo,
  PickZone,
  PickGroup,
  PutawayZone,
  TaskPriority,
  Warehouse,
  AssignedTo,
  DestZone,
  DestLocation,
  DependencyFlags,

  TaskCategory1,
  TaskCategory2,
  TaskCategory3,
  TaskCategory4,
  TaskCategory5,

  /* Task Detail */
  TaskDetailId,
  TaskDetailStatus,
  TaskDetailStatusDesc,
  TaskDetailStatusGroup,
  TransactionDate,
  DetailInnerPacks,
  DetailQuantity,
  UnitsCompleted,
  UnitsToPick,
  InnerPacksCompleted,
  InnerPacksToPick,
  DetailPercentComplete,
  PickWeight,
  PickVolume,
  IsLabelGenerated,
  PickSequence,

  DetailDestZone,
  DetailDestLocation,

  DependentOn,
  DetailDependencyFlags,
  IsTaskConfirmed,

  TDCategory1,
  TDCategory2,
  TDCategory3,
  TDCategory4,
  TDCategory5,

  /* Location */
  LocationId,
  Location,
  LocationRow,
  LocationSection,
  LocationLevel,
  LocationType,
  PickPath,
  PickPathPosition,
  PutawayPath,
  LocationPAZone,
  IsReplenishable,

  /* LPN */
  LPNId,
  LPN,
  LPNType,
  LPNQuantity,
  AlternateLPN,
  Lot,

  OnhandStatus,

  /* Temp Label */
  TempLabelId,
  TempLabel,
  PickPosition,
  CartonType,

  /* Order Header */
  OrderId,
  PickTicket,
  OrderType,
  CancelDate,
  DesiredShipDate,
  CustomerName,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

  OHUDF1,
  OHUDF2,
  OHUDF3,
  OHUDF4,
  OHUDF5,

  /* Order Detail */
  OrderDetailId,
  ODUDF1,
  ODUDF2,
  ODUDF3,
  ODUDF4,
  ODUDF5,
  UnitsAuthorizedToShip,
  UnitsToAllocate,

  /* LPN Detail */
  LPNDetailId,

  /* SKU */
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,

  UPC,
  SKUDescription,

  ShipPack,
  UnitsPerInnerPack,

  UnitWeight,
  UnitVolume,

  /* Pallet */
  PalletId,
  Pallet,

  /* Pick Batch */
  PickBatchId,
  PickBatchNo,
  BatchType,
  BatchTypeDesc,
  PickBatchStatus,
  BatchPriority,
  -- V3 fields
  WaveType,
  WaveStatus,
  WavePriority,

  NumOrders,
  NumLines,
  NumSKUs,
  NumLPNs,
  NumUnits,
  TotalAmount,
  TotalWeight,
  TotalVolume,

  SoldToId,
  ShipToId,
  ShipVia,
  BatchPickZone,
  BatchPickTicket,
  SoldToName,
  ShipToStore,

  BatchPalletId,
  BatchPallet,
  BatchAssignedTo,
  Ownership,
  PickBatchWarehouse,
  DropLocation,
  PickBatchGroup,

  PickBatchCancelDate,
  PickDate,
  ShipDate,
  Description,
  ExportStatus,

  Category1,
  Category2,
  Category3,
  Category4,
  Category5,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,
  UDF6,
  UDF7,
  UDF8,
  UDF9,
  UDF10,

  WaveId,     /* For future use */
  WaveNo,
  RuleId,
  IsAllocated,
  ScheduledDate,

  vwPT_UDF1,
  vwPT_UDF2,
  vwPT_UDF3,
  vwPT_UDF4,
  vwPT_UDF5,
  vwPT_UDF6,
  vwPT_UDF7,
  vwPT_UDF8,
  vwPT_UDF9,
  vwPT_UDF10,

  Archived,
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
  ESTT.TypeDescription,
  TD.PickType,
  T.TaskDesc,
  T.Status,
  ST.StatusDescription,
  case
    when (T.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end,

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
  T.PickGroup,
  T.PutawayZone,
  coalesce(T.Priority, PB.Priority),
  LOC.Warehouse,
  coalesce(T.AssignedTo, PB.AssignedTo),
  T.DestZone,
  T.DestLocation,
  T.DependencyFlags,

  T.TaskCategory1,
  T.TaskCategory2,
  T.TaskCategory3,
  T.TaskCategory4,
  T.TaskCategory5,

  /* Task Detail */
  TD.TaskDetailId,
  TD.Status,
  DST.StatusDescription,
  case
    when (TD.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end,
  TD.TransactionDate,
  TD.InnerPacks,
  TD.Quantity,
  coalesce(TD.UnitsCompleted, 0),
  /* Units To Pick */
  case when TD.Status = 'X' then 0
       else (coalesce(TD.Quantity, 0) - coalesce(TD.UnitsCompleted, 0))
  end,
  /* InnerPacksCompleted */
  case when S.UnitsPerInnerPack > 0 then coalesce(TD.UnitsCompleted, 0)/S.UnitsPerInnerPack
       else 0
  end,
  /* InnerPacksToPick */
  case when TD.Status = 'X' /* Canceled */ then 0
       when S.UnitsPerInnerPack > 0 then (coalesce(TD.Quantity, 0) - coalesce(TD.UnitsCompleted, 0))/S.UnitsPerInnerPack
       else 0
  end,
  /* Detail Percent Complete */
  case when TD.Status = 'X' /* Canceled */ then 100
       when coalesce(TD.Quantity, 0) > 0   then coalesce(TD.UnitsCompleted, 0)/coalesce(TD.Quantity, 0) * 100
       else 0
  end,

  (S.UnitWeight * coalesce(TD.Quantity, 0)),
  (S.UnitVolume * coalesce(TD.Quantity, 0)) *  0.000578704,
  TD.IsLabelGenerated,
  TD.PickSequence,

  TD.DestZone,
  TD.DestLocation,

  TD.DependentOn,
  TD.DependencyFlags,
  T.IsTaskConfirmed,

  TD.TDCategory1,
  TD.TDCategory2,
  TD.TDCategory3,
  TD.TDCategory4,
  TD.TDCategory5,

  /* Location */
  TD.LocationId,
  LOC.Location,
  LOC.LocationRow,
  LOC.LocationSection,
  LOC.LocationLevel,
  LOC.LocationType,
  LOC.PickPath,
  coalesce(LOC.PickPath, '') + '-' + L.LPN + '-' + S.SKU + '-' + cast(coalesce(TaskDetailId, '') as varchar),
  LOC.PutawayPath,
  LOC.PutawayZone,
  LOC.IsReplenishable,

  /* LPN */
  TD.LPNId,
  L.LPN,
  L.LPNType,
  L.Quantity,
  TLPN.AlternateLPN,
  L.Lot,

  LD.OnhandStatus,

  /* Temp Label */
  TD.TempLabelId,
  TD.TempLabel,
  TD.PickPosition,
  TLPN.CartonType,

  /* Order Header */
  TD.OrderId,
  OH.PickTicket,
  OH.OrderType,
  OH.CancelDate,
  OH.DesiredShipDate,
  OH.AccountName, --CustomerName

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

  OH.UDF1,
  OH.UDF2,
  OH.UDF3,
  OH.UDF4,
  OH.UDF5,

  /* Order Detail */
  TD.OrderDetailId,
  OD.UDF1,
  OD.UDF2,
  OD.UDF3,
  OD.UDF4,
  OD.UDF5,
  OD.UnitsAuthorizedToShip,
  OD.UnitsToAllocate,

  /* LPN Detail */
  TD.LPNDetailId,

  /* SKU */
  TD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,

  S.UPC,
  S.Description,

  S.ShipPack,
  S.UnitsPerInnerPack,

  S.UnitWeight,
  S.UnitVolume,

  /* Pallet */
  TD.PalletId,
  P.Pallet,

  /* Pick Batch */
  PB.RecordId,
  PB.BatchNo,
  PB.BatchType,
  ETPB.TypeDescription,
  PB.Priority,
  PB.WaveId,
  PB.WaveType,
  PB.WaveStatus,
  PB.Priority,

  T.OrderCount,
  PB.NumLines,
  PB.NumSKUs,
  PB.NumLPNs,
  PB.NumUnits,
  PB.TotalAmount,
  PB.TotalWeight,
  PB.TotalVolume,

  OH.SoldToId,
  OH.ShipToId,
  OH.ShipVia,
  PB.PickZone,
  OH.PickTicket,
  PB.SoldToName,
  OH.ShipToStore,

  PB.PalletId,
  PB.Pallet,
  PB.AssignedTo,
  PB.Ownership,
  PB.Warehouse,
  PB.DropLocation,
  PB.PickBatchGroup,

  PB.CancelDate,
  PB.PickDate,
  PB.ShipDate,
  S.Description,
  TD.ExportStatus,

  PB.Category1,
  PB.Category2,
  PB.Category3,
  PB.Category4,
  PB.Category5,

  PB.UDF1,
  PB.UDF2,
  PB.UDF3,
  PB.UDF4,
  PB.UDF5,
  PB.UDF6,
  PB.UDF7,
  PB.UDF8,
  cast(case when coalesce(S.UnitsPerInnerPack, 0 ) > 0 then (TD.Quantity / S.UnitsPerInnerPack)
            else TD.Quantity
       end as varchar(10)),
  PB.UDF10,

  PB.WaveId,     /* For future use */
  PB.BatchNo,
  PB.RuleId,
  PB.IsAllocated,
  /* Scheduled Date */
  case when T.Status in ('I', 'N') then cast(getdate() as date)
       when T.Status in ('C', 'X') then cast(dateadd(hh, -2, coalesce(T.ModifiedDate, T.CreatedDate)) as date)  /* WDC is in MST so reduce two hours */
       else cast(coalesce(T.ScheduledDate, T.CreatedDate) as Date)
  end,

  T.LabelsPrinted,
  cast(' ' as varchar(50)),   /* For Future Use */
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),

  T.Archived,
  T.BusinessUnit,
  T.CreatedDate,
  T.ModifiedDate,
  T.CreatedBy,
  T.ModifiedBy,
  TD.ModifiedDate,
  TD.ModifiedBy

from Tasks T
             join TaskDetails  TD   on (T.TaskId          = TD.TaskId)
  left outer join PickBatches  PB   on (T.BatchNo         = PB.BatchNo)
  left outer join SKUs         S    on (TD.SKUId          = S.SKUId)
  left outer join LPNs         L    on (TD.LPNId          = L.LPNId)
  left outer join LPNs         TLPN on (TD.TempLabelId    = TLPN.LPNId)
  left outer join LPNDetails   LD   on (TD.LPNDetailId    = LD.LPNDetailId)
  left outer join Pallets      P    on (TD.PalletId       = P.PalletId)
  left outer join Locations    LOC  on (TD.LocationId     = LOC.LocationId)
  left outer join OrderHeaders OH   on (TD.OrderId        = OH.OrderId)
  left outer join OrderDetails OD   on (TD.OrderDetailId  = OD.OrderDetailId)
  left outer join Locations    LOC2 on (OD.DestLocationId = LOC2.LocationId)
  left outer join Statuses     ST   on (ST.StatusCode     = T.Status          ) and
                                       (ST.Entity         = 'Task'            ) and
                                       (ST.BusinessUnit   = T.BusinessUnit    )
  left outer join Statuses     DST  on (DST.StatusCode    = TD.Status         ) and
                                       (DST.Entity        = 'Task'            ) and
                                       (DST.BusinessUnit  = TD.BusinessUnit   )
  left outer join EntityTypes  ESTT on (ESTT.TypeCode     = T.TaskSubType     ) and
                                       (ESTT.Entity       = 'PickTaskSubType' ) and
                                       (ESTT.BusinessUnit = T.BusinessUnit    )
  left outer join EntityTypes  ETPB on (ETPB.TypeCode     = PB.BatchType      ) and
                                       (ETPB.Entity       = 'Wave'            ) and
                                       (ETPB.BusinessUnit = PB.BusinessUnit   )
where (T.TaskType = 'PB' /* PickBatch */) and (TD.TaskDetailId is not null)
;

Go
