/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/03  AY      Fixed InnerPack fields 0 they should be zero, if they don't apply
  2019/06/11  AY      Added Wave fields (V3)
  2019/05/29  YJ      Added fields TaskCategory1 to 5, TDCategory1 to 5, OrderCategory1 to 5 (CID-481)
  2018/11/13  AY      Added condition to not select tasks without details (HPI=2088)
  2018/10/24  VM      PickPathPosition: Include TaskDetailId to not to loop through between same tasks while skip pick (OB2-681)
  2018/08/31  MS      Added TaskStatusGroup, TaskDetailStatusGroup Field (OB2-606)
  2018/05/29  DK      Enhanced to improve perfomance of vwPickTasks by using join instead of left join with TaskDetails (S2G-859)
  2018/03/27  TK      Changes to consider DestLocation instead of Location on OrderDetail (S2G-511)
  2018/03/14  VM      (S2G-411)
                      Added DetailDestZone, DetailDestLocation, DetailDependencyFlags
                      Corrected IsTaskConfirmed position
  2018/03/12  AJ      Added DestLocation field (S2G-383)
  2018/03/05  KSK     Added DependencyFlags, WaveId, IsTaskConfirmed (S2G-289)
  2018/02/18  TD      Added PickGroup (S2G-218)
  2017/01/05  YJ      Added new join to poulate AlternateLPN (HPI-790)
  2017/05/04  LRA     Changes to resolve the truncate issue with data (CIMS-1326)
  2017/02/12  PK      Mapped Tasks LabelsPrinted field to vwPT_UDF1.
  2016/11/29  CK      Added PickType (FB-837)
  2016/11/03  YJ      Added field DependentOn (HPI-978)
  2016/11/02  OK      Mapped vwPT_UDF2 field with DependentOn field from TaskDetails (HPI-978)
  2016/11/02  YJ      Changed mapping for Description field (972)
  2016/09/17  PSK     Added PickPosition field.(HPI-691)
  2016/05/16  OK      Changed NumOrders field to get the value from Tasks instead of getting from PickBatches (NBD-522)
  2015/09/02  TK      Mapped CustomerName with Account Name on the Order Header.
  2015/08/24  OK      Fixed to use the Task AssignedTo (if exists) instead of Batch AssignedTo (FB-324)
  2015/07/14  AY      Added TempLabelId, TempLabel, PickBatchId
  2015/06/18  OK      Added AlternateLPN.
  2014/06/17  TD      Added OnhandStatus, to ignore suggest pick with DR onhand status while picking.
  2014/05/08  AY      Added TotalInnerPacks, TotalUnits, PercentComplete (renamed earlier one as well)
  2014/04/18  TD      Added DestZone, IsLabelgenerated fields.
  2014/01/24  NY      Added new fields task detail modified date and modified by.
  2013/12/06  NY      Changed CancelDate to PickBatchCancelDate.
  2013/11/27  TD      Added LPNType.
  2013/11/12  AY      Changed AssignedTo to be of the Task and added BatchAssignedTo
              PK      Passing in PB.AssignedTo in AssignedTo, if PB.AssignedTo is null
                       then passing in T.AssignedTo.
  2013/10/03  TD      PB.UDF9 - Calculating No of Cases.
  2013/09/29  PK      Added AssignedTo, IsAllocated, UnitsCompleted, UnitsToPick.
  2013/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPickTasks') is not null
  drop View dbo.vwPickTasks;
Go

Create View dbo.vwPickTasks (
  /* Task */
  TaskId,

  TaskType,
  TaskSubType,
  TaskSubTypeDesc,
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
  PB.Status,
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
             join TaskDetails  TD  on (T.TaskId         = TD.TaskId)
  left outer join PickBatches  PB  on (T.BatchNo        = PB.BatchNo)
  left outer join SKUs         S   on (TD.SKUId         = S.SKUId)
  left outer join LPNs         L   on (TD.LPNId         = L.LPNId)
  left outer join LPNs        TLPN on (TD.TempLabelId   = TLPN.LPNId)
  left outer join LPNDetails   LD  on (TD.LPNDetailId   = LD.LPNDetailId)
  left outer join Pallets      P   on (TD.PalletId      = P.PalletId)
  left outer join Locations    LOC on (TD.LocationId    = LOC.LocationId)
  left outer join OrderHeaders OH  on (TD.OrderId       = OH.OrderId)
  left outer join OrderDetails OD  on (TD.OrderDetailId = OD.OrderDetailId)
  left outer join Locations   LOC2 on (OD.DestLocationId = LOC2.LocationId)
  left outer join Statuses     ST  on (ST.StatusCode    = T.Status       ) and
                                      (ST.Entity        = 'Task'         ) and
                                      (ST.BusinessUnit  = T.BusinessUnit )
  left outer join Statuses     DST on (DST.StatusCode   = TD.Status      ) and
                                      (DST.Entity       = 'Task'         ) and
                                      (DST.BusinessUnit = TD.BusinessUnit)
  left outer join EntityTypes ESTT on (ESTT.TypeCode       = T.TaskSubType   ) and
                                      (ESTT.Entity         = 'SubTask'       ) and
                                      (ESTT.BusinessUnit   = T.BusinessUnit  )
where (T.TaskType = 'PB' /* PickBatch */) and (TD.TaskDetailId is not null)
;

Go