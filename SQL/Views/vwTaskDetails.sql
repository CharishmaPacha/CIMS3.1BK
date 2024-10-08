/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/30  MS      Added TaskStatusGroup, TaskDetailStatusGroup Field (OB2-606)
  2019/11/29  PHK     Added TotalVolume (S2GCA-1054)
  2018/10/15  YJ      Do not migrated: Added changes to get Comments, CustPO instead of using UDF1, UDF2: Migrated from Prod (s2GCA-98)
  2018/06/18  KSK     RequestedCountDetail => RequestedCCLevel, ActualCountDetail => ActualCCLevel (S2G-974)
  2017/03/02  VM      Added TempLabelId, TempLabelDetailId
  2018/06/08  YJ      Added LPNs.UCCBarcode: Migrated from staging (S2G-727)
  2018/06/05  OK      Added RequestedCCLevel, ActualCCLevel (S2G-217)
  2018/05/06  PK/AY   Added UPC, CaseUPC & AlternateSKU (S2G-828).
  2018/04/05  AY      Added StorageType & PickType
  2018/03/28  RV      Added LocationType (S2G-503)
  2018/03/21  PK      Corrected the mapping for fields LPNNumLines, LPNEstimatedWeight, CartonType, LPNWarehouse.
  2018/03/13  RV      Corrected the TrackingNo mapping from pick LPN to ship LPN (S2G-404)
  2018/03/05  RV      Added LPNNumLines, LPNEstimatedWeight, CartonType, TrackingNo,
                        LPNWarehouse, SKUDescription, ShipPack, SKUBarcode, IsSortable (S2G-240)
  2018/03/01  KSK     Added DependencyFlags (S2G-289)
  2017/03/02  VM      Added TempLabelId, TempLabelDetailId (HPI-1415)
  2017/01/05  YJ      Added new join to populate AlternateLPN (HPI-790)
  2016/11/03  YJ      Added field DependentOn (HPI-978)
  2016/11/02  OK      Mapped DependentOn field with TDUDF (HPI-978)
  2016/09/27  YJ      Added field PickPosition (HPI-790)
  2016/09/19  TD      Added PickPosition.
  2016/08/27  TK      Added AccountName (HPI-523)
  2016/08/21  TK      Corrected Look Up category PickZone -> PickZones
  2016/08/19  TK      Added Location Ranges required for Label (HPI-484)
  2016/02/03  TD      Added UDF1 to 10 and category fields
  2016/11/29  CK      Added PickType (FB-837)
  2015/07/27  TK      Added TaskPalletId (FB-265)
  2015/07/21  YJ      Added AlternateLPN (ACME-240).
  2014/09/16  PKS     Added TaskSubType.
  2014/08/26  YJ      Added PickZoneDesc.
  2014/05/24  AK      Added DestZone, DestLocation, IsLabelGenerated and TempLabel.
  2014/04/12  PKS     Added BatchTypeDesc, InnerPacks, Quantity
  2014/03/11  PK      Added TaskType.
  2012/02/01  VM      Added TaskStatus, ScheduledDate
  2012/01/20  YA      Included SKUVariance.
  2012/01/12  YA      Included BatchNo.
  2012/01/09  YA      Added PickPath as it is reqired in DirectedCycleCount for sorting.
  2011/12/26  PK      Added SKUId, SKU.
  2011/12/19  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwTaskDetails') is not null
  drop View dbo.vwTaskDetails;
Go

Create View dbo.vwTaskDetails (
  TaskDetailId,
  TaskId,
  TaskType,
  TaskSubType,
  TaskStatus,
  TaskStatusGroup,
  BatchNo,
  BatchTypeDesc,
  PickZone,
  PickZoneDesc,
  ScheduledDate,

  Status,
  StatusDescription,
  TaskDetailStatusGroup,
  TransactionDate,

  AccountName,

  TDInnerPacks,
  TDQuantity,
  TotalVolume,
  TDInnerPacksCompleted,
  TDUnitsCompleted,
  TDPickType,

  DestZone,
  DestLocation,

  LocationId,
  Location,
  LocationType,
  LocStorageType,
  PickPath,
  LPNId,
  LPN,
  LPNDetailId,
  LPNInnerPacks,
  LPNQuantity,
  LPNNumLines,
  LPNEstimatedWeight,
  CartonType,
  AlternateLPN,
  TrackingNo,
  UCCBarcode,
  LPNWarehouse,
  /* SKU */
  SKUId,
  SKU,
  SKUDescription,
  UnitVolume,
  UnitWeight,
  ShipPack,
  SKUBarcode,
  UPC,
  CaseUPC,
  AlternateSKU,
  IsSortable,
  /* Pallet */
  PalletId,
  TaskPalletId,
  Pallet,
  PickPosition,
  DependentOn,
  DependencyFlags,

  StartLocation,
  EndLocation,
  StartDestination,
  EndDestination,
  PicksFrom,
  PicksFor,

  OrderId,
  OrderDetailId,
  PickTicket,
  SalesOrder,
  OrderType,
  ShipToStore,

  Variance,
  SKUVariance,

  IsLabelGenerated,
  TempLabelId,
  TempLabel,
  TempLabelDetailId,

  RequestedCCLevel,
  ActualCCLevel,

  TDCategory1,
  TDCategory2,
  TDCategory3,
  TDCategory4,
  TDCategory5,

  TDUDF1,
  TDUDF2,
  TDUDF3,
  TDUDF4,
  TDUDF5,
  TDUDF6,
  TDUDF7,
  TDUDF8,
  TDUDF9,
  TDUDF10,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) as
select
  TD.TaskDetailId,
  TD.TaskId,
  T.TaskType,
  T.TaskSubType,
  T.Status,
  case
    when (T.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end,
  T.BatchNo,
  ET.TypeDescription,
  T.PickZone,
  /* Pick Zone Desc */
  coalesce(LU4.LookUpDescription, T.PickZone),
  T.ScheduledDate,

  TD.Status,
  S.StatusDescription,
  case
    when (TD.Status in ('C'/* Completed */, 'X' /* Canceled */))
      then 'Closed'
    else
      'Open'
  end,
  TD.TransactionDate,

  PB.AccountName,

  TD.InnerPacks,
  TD.Quantity,
  (TD.Quantity * coalesce(SKU.UnitVolume, 0)) *  0.000578704,  /* Total Volume*/
  TD.InnerPacksCompleted,
  TD.UnitsCompleted,
  TD.PickType,

  TD.DestZone,
  TD.DestLocation,

  TD.LocationId,
  L.Location,
  L.LocationType,
  L.StorageType,
  L.PickPath,
  TD.LPNId,
  LPN.LPN,
  TD.LPNDetailId,
  LPN.InnerPacks,
  LPN.Quantity,
  TLPN.NumLines,
  TLPN.EstimatedWeight,
  TLPN.CartonType,
  TLPN.AlternateLPN,
  TLPN.TrackingNo,
  TLPN.UCCBarcode,
  TLPN.DestWarehouse,
  /* SKU */
  TD.SKUId,
  SKU.SKU,
  SKU.Description,
  SKU.UnitVolume,
  SKU.UnitWeight,
  SKU.ShipPack,
  SKU.BarCode,
  SKU.UPC,
  SKU.CaseUPC,
  SKU.AlternateSKU,
  SKU.IsSortable,
  /* Pallet */
  TD.PalletId,
  T.PalletId,
  P.Pallet,
  TD.PickPosition,
  TD.DependentOn,
  T.DependencyFlags,

  T.StartLocation,
  T.EndLocation,
  T.StartDestination,
  T.EndDestination,
  /* Picks From */
  case
    when coalesce(StartLocation, '') <> coalesce(EndLocation, '') then
       StartLocation + ' to ' + EndLocation
    else
       coalesce(StartLocation, '')
  end,
  /* Picks For */
  case
    when coalesce(StartDestination, '') <> coalesce(EndDestination, '') then
      StartDestination + ' to ' + EndDestination
    else
      coalesce(StartDestination, '')
  end,

  TD.OrderId,
  TD.OrderDetailId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OH.ShipToStore,

  TD.Variance,
  /* Variance descriptions */
  rtrim(ltrim(coalesce(       LU1.LookUpDescription, '') +
              coalesce(', ' + LU2.LookUpDescription, '') +
              coalesce(', ' + LU3.LookUpDescription, ''))),

  TD.IsLabelGenerated,
  TD.TempLabelId,
  TD.TempLabel,
  TD.TempLabelDetailId,

  TD.RequestedCCLevel,
  TD.ActualCCLevel,

  TD.TDCategory1,
  TD.TDCategory2,
  TD.TDCategory3,
  TD.TDCategory4,
  TD.TDCategory5,

  TD.UDF1,
  TD.UDF2,
  TD.UDF3,
  TD.UDF4,
  TD.UDF5,
  TD.UDF6,
  TD.UDF7,
  TD.UDF8,
  TD.UDF9,
  TD.UDF10,

  TD.BusinessUnit,
  TD.CreatedDate,
  TD.ModifiedDate,
  TD.CreatedBy,
  TD.ModifiedBy
from
  TaskDetails TD
  left outer join Tasks       T    on (TD.TaskId          = T.TaskId                     )
  left outer join Locations   L    on (TD.LocationId      = L.LocationId                 )
  left outer join SKUs        SKU  on (TD.SKUId           = SKU.SKUId                    )
  left outer join LPNs        LPN  on (TD.LPNId           = LPN.LPNId                    )
  left outer join LPNs        TLPN on (TD.TempLabelId     = TLPN.LPNId                   )
  left outer join Pallets     P    on (TD.PalletId        = P.PalletId                   )
  left outer join PickBatches PB   on (T.BatchNo          = PB.BatchNo                   )
  left outer join OrderHeaders OH  on (TD.OrderId         = OH.OrderId                   )
  left outer join Statuses    S    on (TD.Status          = S.StatusCode                 ) and
                                      (S.Entity           = 'Task'                       ) and
                                      (S.BusinessUnit     = TD.BusinessUnit              )
  left outer join EntityTypes ET   on (PB.BatchType       = ET.TypeCode   ) and
                                      (ET.Entity          = 'PickBatch'   ) and
                                      (ET.BusinessUnit    = PB.BusinessUnit)
  left outer join LookUps     LU1  on (LU1.LookUpCode     = substring(TD.Variance, 1, 1) ) and
                                      (LU1.LookUpCategory = 'Variance'                   ) and
                                      (LU1.BusinessUnit   = TD.BusinessUnit              )
  left outer join LookUps     LU2  on (LU2.LookUpCode     = substring(TD.Variance, 2, 1) ) and
                                      (LU2.LookUpCategory = 'Variance'                   ) and
                                      (LU2.BusinessUnit   = TD.BusinessUnit              )
  left outer join LookUps     LU3  on (LU3.LookUpCode     = substring(TD.Variance, 3, 1) ) and
                                      (LU3.LookUpCategory = 'Variance'                   ) and
                                      (LU3.BusinessUnit   = TD.BusinessUnit              )
  left outer join LookUps     LU4  on (LU4.LookUpCode     = T.PickZone                   ) and
                                      (LU4.LookUpCategory = 'PickZones'                  ) and
                                      (LU4.BusinessUnit   = TD.BusinessUnit              )

Go