/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved.

  Revision History:

  Date        Person  Comments

  2016/07/11  AY      Added IsLastPickFromLocation
  2015/02/06  AY      Add E-Com prefix to cases going to Shelving as users are getting confused between Replenish and ECom Cases
  2015/01/13  AY      Default Innerpacks to 1
  2014/08/28  PKS     Initial revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBatchLPNLabels') is not null
  drop View dbo.vwBatchLPNLabels;
Go
/* Deprecated, not used anymore */
Create View dbo.vwBatchLPNLabels (
  /* LPN information */
  LPN,
  LPNType,
  LPNStatus,
  PackageSeqNo,
  ExpiryDate,

  /* LPN Qty */
  InnerPacks,
  Quantity,
  ReservedQty,
  UnitsPerInnerPack,

  DestWarehouse,
  DestZone,
  DestLocation,

  /* SKU */
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UPC,
  SKUDescription,
  UOM,
  InnerPacksPerLPN,

  /* Location and Storage information */
  Location,
  LocationType,
  StorageType,
  PickingZone,

  /* PickBatch Information */
  PickBatchId,
  PickBatchNo,
  PickBatchTypeDesc,
  PickedFromLocation,
  PickedBy,

  /* Task information */
  TaskId,
  TaskType,
  TaskTypeDescription,
  TaskSubType,
  TaskSubTypeDescription,

  TaskTotalInnerPacks,

  /* Other Order Fields */
  CustPO,
  ShipToStore,
  ShipTo,
  CustAccountName,
  IsLastPickFromLocation,

  /* LPN UDFs */
  LPN_UDF1,
  LPN_UDF2,
  LPN_UDF3,
  LPN_UDF4,
  LPN_UDF5,

  /* SKU UDFs */
  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,
  SKU_UDF5,

  /* View UDFs */
  vwBLL_UDF1,
  vwBLL_UDF2,
  vwBLL_UDF3,
  vwBLL_UDF4,
  vwBLL_UDF5
) As
select
  L.LPN,
  L.LPNType,
  L.Status,
  L.PackageSeqNo,
  L.ExpiryDate,

  L.InnerPacks,
  L.Quantity,
  L.ReservedQty,
  L.Quantity/nullif(L.InnerPacks, 0),

  L.DestWarehouse,
  L.DestZone,
  TD.DestLocation,

  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.UPC,
  S.Description,
  S.UOM,
  S.InnerPacksPerLPN,

  LOC.Location,
  LOC.LocationType,
  LOC.StorageType,
  LOC.PickingZone,

  L.PickBatchId,
  L.PickBatchNo,
  ET.TypeDescription,
  LD.ReferenceLocation,
  LD.PickedBy,

  T.TaskId,
  T.TaskType,
  ETT.TypeDescription,
  T.TaskSubType,
  ESTT.TypeDescription,
  T.TotalInnerPacks,

  OH.CustPO,
  OH.ShipToStore,
  OH.ShipToId,
  OH.AccountName,
  'N', -- L.IsLastPickFromLocation,

  L.UDF1,
  L.UDF2,
  L.UDF3,
  L.UDF4,
  L.UDF5,

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,

  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50))
from
 LPNTasks LPNT
  left outer join Tasks            T    on (LPNT.TaskId       = T.TaskId       )
  Left outer join TaskDetails      TD   on (TD.TaskDetailId   = LPNT.TaskDetailId)
  left outer join vwLPNs           L    on (LPNT.LPNId        = L.LPNId        )
  left outer join LPNDetails       LD   on (LPNT.LPNDetailId  = LD.LPNDetailId )
  left outer join OrderHeaders     OH   on (TD.OrderId        = OH.OrderId     )
  left outer join SKUs             S    on (LD.SKUId          = S.SKUId        )
  left outer join PickBatches      PB   on (T.BatchNo         = PB.BatchNo     )
  left outer join Locations        LOC  on (TD.LocationId     = LOC.LocationId )
  left outer join EntityTypes      ET   on (PB.BatchType      = ET.TypeCode    ) and
                                           (ET.Entity         = 'PickBatch'    ) and
                                           (ET.BusinessUnit   = PB.BusinessUnit)
  left outer join EntityTypes      ETT  on (ETT.TypeCode      = T.TaskType     ) and
                                           (ETT.Entity        = 'Task'         ) and
                                           (ETT.BusinessUnit  = T.BusinessUnit )
  left outer join EntityTypes      ESTT on (ESTT.TypeCode     = T.TaskSubType  ) and
                                           (ESTT.Entity       = 'SubTask'      ) and
                                           (ESTT.BusinessUnit = T.BusinessUnit )
Go
