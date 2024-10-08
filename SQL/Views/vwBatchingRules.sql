/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/10/26  SPP     Show ShipVia description from ShipVias table (CIMS-1646)
  2016/10/08  TK      Added WaveRuleGroup (HPI-838)
  2016/09/25  VM      Added Account, ShipFrom, ShipToStore (HPI-GoLive)
  2016/02/08  TD/TK   Added new fields OH_Category1 to OH_Category5 (NBD-99)
  2013/09/12  TD      Added new fields for XSC.
  2013/03/22  TD      Added MaxWeight, OrderWeightMin,OrderWeightMax,
                            MaxVolume, OrderVolumeMin, OrderVolumeMax.
  2012/06/20  PK      Added PickZone, Ownership, Warehouse.
  2011/08/09  PK      Modifed SoldTo, ShipTo to SoldToId, ShipToId.
  2011/07/28  TD      Added description and other minor changes.
  2011/07/26  YA      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBatchingRules') is not null
  drop View dbo.vwBatchingRules;
Go

Create View dbo.vwBatchingRules (
  RuleId,
  WaveRuleGroup,

  BatchingLevel,

  /* Orders Criteria */
  OrderType,
  OrderTypeDescription,
  OrderPriority,

  ShipVia,
  ShipViaDescription,
  Carrier,

  SoldToId,                     /* Future Use */
  SoldToDescription,

  ShipToId,
  ShipToDescription,          /* For future use */

  PickZone,
  Ownership,
  Warehouse,

  Account,
  ShipFrom,
  ShipToStore,

  OrderWeightMin,
  OrderWeightMax,
  OrderVolumeMin,
  OrderVolumeMax,
  OrderInnerPacks,
  OrderUnits,

  OH_UDF1,
  OH_UDF2,
  OH_UDF3,
  OH_UDF4,
  OH_UDF5,

  OH_Category1,
  OH_Category2,
  OH_Category3,
  OH_Category4,
  OH_Category5,

  /* Pick Batch attributes */
  BatchType,
  BatchTypeDescription,
  BatchPriority,

  BatchStatus,
  BatchStatusDescription,

  PickBatchGroup,

  /* OrderDetails Criteria */
  OrderDetailWeight,
  OrderDetailVolume,

  /* SKUs Related */
  PutawayClass,
  ProdCategory,
  ProdSubCategory,
  PutawayZone,

   /* Limiting Criteria */
  MaxOrders,
  MaxLines,
  MaxSKUs,
  MaxUnits,
  MaxWeight,
  MaxVolume,
  MaxLPNs,
  MaxInnerPacks,

  DestZone,
  DestZoneDescription,
  DestZoneDisplayDescription,
  DestLocation,

  /* UDFs */
  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  SortSeq,
  Status,
  StatusDescription,

  VersionId,                            /* For future Use */

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) AS
select
  BR.RuleId,
  BR.WaveRuleGroup,

  BR.BatchingLevel,

  BR.OrderType,
  OT.TypeDescription,
  BR.OrderPriority,

  BR.ShipVia,
  SV.Description,
  BR.Carrier,

  BR.SoldToId,
  ST.CustomerName,

  BR.ShipToId,
  SHT.CustomerName,

  BR.PickZone,
  BR.Ownership,
  BR.Warehouse,

  BR.Account,
  BR.ShipFrom,
  BR.ShipToStore,

  BR.OrderWeightMin,
  BR.OrderWeightMax,
  BR.OrderVolumeMin,
  BR.OrderVolumeMax,
  BR.OrderInnerPacks,
  BR.OrderUnits,

  BR.OH_UDF1,
  BR.OH_UDF2,
  BR.OH_UDF3,
  BR.OH_UDF4,
  BR.OH_UDF5,

  BR.OH_Category1,
  BR.OH_Category2,
  BR.OH_Category3,
  BR.OH_Category4,
  BR.OH_Category5,

  BR.BatchType,
  BT.TypeDescription,
  BR.BatchPriority,

  BR.BatchStatus,
  BS.StatusDescription,

  BR.PickBatchGroup,

  BR.OrderDetailWeight,
  BR.OrderDetailVolume,

  BR.PutawayClass,
  BR.ProdCategory,
  BR.ProdSubCategory,
  BR.PutawayZone,

  BR.MaxOrders,
  BR.MaxLines,
  BR.MaxSKUs,
  BR.MaxUnits,
  BR.MaxWeight,
  BR.MaxVolume,
  BR.MaxLPNs,
  BR.MaxInnerPacks,

  BR.DestZone,
  DZ.LookUpDescription,
  coalesce(BR.DestZone+'-','')+ coalesce(DZ.LookUpDescription, ''),
  BR.DestLocation,

  BR.UDF1,
  BR.UDF2,
  BR.UDF3,
  BR.UDF4,
  BR.UDF5,

  BR.SortSeq,
  BR.Status,
  S.StatusDescription,

  BR.VersionId,

  BR.BusinessUnit,
  BR.CreatedDate,
  BR.ModifiedDate,
  BR.CreatedBy,
  BR.ModifiedBy
from
  PickBatchRules BR
    left outer join EntityTypes  OT  on (BR.OrderType       = OT.TypeCode    ) and
                                        (OT.Entity          = 'Order'        ) and
                                        (OT.BusinessUnit    = BR.BusinessUnit)
    left outer join ShipVias     SV  on (BR.ShipVia         = SV.ShipVia     ) and
                                        (BR.BusinessUnit    = SV.BusinessUnit)
    left outer join Customers    ST  on (BR.SoldToId        = ST.CustomerId  )
    left outer join Customers    SHT on (BR.ShipToId        = SHT.CustomerId )
    left outer join EntityTypes  BT  on (BR.BatchType       = BT.TypeCode    ) and
                                        (BT.Entity          = 'PickBatch'    ) and
                                        (BT.BusinessUnit    = BR.BusinessUnit)
    left outer join Statuses     BS  on (BR.BatchStatus     = BS.StatusCode  ) and
                                        (BS.Entity          = 'PickBatch'    ) and
                                        (BS.BusinessUnit    = BR.BusinessUnit)
    left outer join LookUps      DZ  on (BR.DestZone        = DZ.LookUpCode  ) and
                                        (DZ.LookUpCategory  = 'PutawayZones' ) and
                                        (DZ.BusinessUnit    = BR.BusinessUnit)
    left outer join Statuses     S   on (BR.Status          = S.StatusCode   ) and
                                        (S.Entity           = 'Status'       ) and
                                        (S.BusinessUnit     = BR.BusinessUnit)
;

Go