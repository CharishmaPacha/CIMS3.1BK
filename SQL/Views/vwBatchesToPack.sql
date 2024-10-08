/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/14  VS      Do not allow VAS Orders in Packing page (CID-717)
  2019/04/08  OK      Excluded Rework orders in packing screen since they dont required packing process (S2GCA-582)
  2019/07/18  HYP     Added PickTicket field (CID-681)
  2019/07/18  SV      Changes to show carton with packing status during Order Packing (CID-823)
  2019/05/31  TD      Changes to show the batches to pack if those are no pallets (CID-509)
  2019/03/25  VS      Added condition for PTC and SLB (CID-211)
  2019/02/18  TK      Changes to fn_Batching_IsBulkPullBatch signature (S2GCA-465)
  2018/08/04  KSK     Added PackingByUser field (OB2-459)
                      Added Units Packed and Units To Pack fields (OB2-472)
                      Added TaskId field (OB2-474)
  2017/10/28  VM      Show ShipVia description from ShipVias table (CIMS-1646)
  2015/10/30  RV      Include the condition for New Replenish type (FB-474)
  2015/10/17  DK      Bug fix to Exclude Bulk batches (FB-440).
  2103/06/17  TD      Excluding batch type of replenishments.
  2013/05/16  YA      Modified view to show the batches in Paused status as well.
  2013/04/29  AY      Changed to show NumUnits of the Pallet and not of the Batch.
  2013/04/13  AY      Do not allow Carts in Picking status to be packed
  2013/04/06  AY      Allow packing of batches while picking is going on and allow for multiple carts for a Batch.
              TD      Added businessUnits in joins
  2013/04/04  PK      Migrated from LOEH to OB.
  2012/06/27  AA      Added where condition to not display Transfer, Replenish Batches
  2011/11/22  PKS     PalletLocation field was added.
  2011/08/09  PK      Modified SoldTo to SoldToId.
  2011/07/26  AK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBatchesToPack') is not null
  drop View dbo.vwBatchesToPack;
Go

Create View dbo.vwBatchesToPack (
  /* Pick Batch */
  PickBatchId,

  BatchNo,
  BatchType,
  BatchTypeDesc,
  Status,
  StatusDesc,
  Priority,

  PickTicket,
  NumOrders,
  NumLines,
  NumSKUs,
  NumUnits,

  SoldToId,
  SoldToDesc,
  ShipVia,
  ShipViaDesc,
  PickZone,
  PickZoneDesc,

  PalletId,
  Pallet,
  PalletStatus,
  PalletStatusDescription,
  PalletLocation,
  PalletType,
  PalletTypeDescription,
  Zone,
  ZoneDescription,
  TaskId,
  PackingByUser,

  WaveId,              /* For future use */
  RuleId,              /* For future use */

  PackStation,

  UnitsPacked,
  UnitsToPack,

  vwCTP_UDF1,
  vwCTP_UDF2,
  vwCTP_UDF3,
  vwCTP_UDF4,
  vwCTP_UDF5,
  vwCTP_UDF6,
  vwCTP_UDF7,
  vwCTP_UDF8,
  vwCTP_UDF9,
  vwCTP_UDF10,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
)
as
select
  PB.RecordId,

  PB.BatchNo,
  PB.BatchType,
  ET.TypeDescription,  /* Batch Type Description */
  PB.Status,
  S.StatusDescription,  /* Batch Status Description */
  PB.Priority,

  OH.PickTicket,

  PB.NumOrders,
  PB.NumLines,
  PB.NumSKUs,
  P.Quantity,

  PB.SoldToId,
  C.CustomerName,
  PB.ShipVia,
  SV.Description,
  PB.PickZone,
  PZ.LookUpDescription,

  PB.PalletId,
  P.Pallet,
  P.Status,
  PS.StatusDescription, /* Pallet Status Description */
  L.Location,
  P.PalletType,
  PT.TypeDescription,   /* Pallet Type Description */
  PAZ.LookUpCode,       /* Zone Code */
  PAZ.LookUpDescription,/* Zone Description */
  P.TaskId ,
  P.PackingByUser,

  PB.WaveId,
  PB.RuleId,

  'CIMS',
  OH.UnitsPacked,
  OH.UnitsAssigned - coalesce(OH.UnitsPacked, 0), /* Units To Pack */

  cast(' ' as varchar(50)), -- UDF1,
  cast(' ' as varchar(50)), -- UDF2,
  cast(' ' as varchar(50)), -- UDF3,
  cast(' ' as varchar(50)), -- UDF4,
  cast(' ' as varchar(50)), -- UDF5,
  cast(' ' as varchar(50)), -- UDF6,
  cast(' ' as varchar(50)), -- UDF7,
  cast(' ' as varchar(50)), -- UDF8,
  cast(' ' as varchar(50)), -- UDF9,
  cast(' ' as varchar(50)), -- UDF10,

  PB.BusinessUnit,
  PB.CreatedDate,
  PB.ModifiedDate,
  PB.CreatedBy,
  PB.ModifiedBy
from PickBatches PB
  left outer join Statuses      S   on (PB.Status          = S.StatusCode    ) and
                                       (S.Entity           = 'PickBatch'     ) and
                                       (S.BusinessUnit     = PB.BusinessUnit )
  left outer join EntityTypes   ET  on (PB.BatchType       = ET.TypeCode     ) and
                                       (ET.Entity          = 'PickBatch'     ) and
                                       (ET.BusinessUnit    = PB.BusinessUnit )
  left outer join Customers     C   on (PB.SoldToId        = C.CustomerId    )
  left outer join ShipVias      SV  on (PB.ShipVia         = SV.ShipVia      ) and
                                       (PB.BusinessUnit    = SV.BusinessUnit )
  left outer join LookUps       PZ  on (PB.PickZone        = PZ.LookUpCode   ) and
                                       (PZ.LookUpCategory  = 'PickZones'     ) and
                                       (PZ.BusinessUnit    = PB.BusinessUnit )
  left outer join Pallets       P   on (PB.RecordId        = P.PickBatchId   )
  left outer join OrderHeaders  OH  on (P.OrderId          = OH.OrderId      )
  left outer join Statuses      PS  on (P.Status           = PS.StatusCode   ) and
                                       (PS.Entity          = 'PALLET'        ) and
                                       (PS.BusinessUnit    = PB.BusinessUnit )
  left outer join EntityTypes   PT  on (P.PalletType       = PT.TypeCode     ) and
                                       (PT.Entity          = 'PALLET'        ) and
                                       (PT.BusinessUnit    = PB.BusinessUnit )
  left outer join Locations     L   on (P.LocationId       = L.LocationId    )
  left outer join LookUps       PAZ on (L.PutawayZone      = PAZ.LookUpCode  ) and
                                       (PAZ.LookUpCategory = 'PutawayZones'  ) and
                                       (PAZ.BusinessUnit   = PB.BusinessUnit )
where (PB.Status        in ('P' /* Picking */, 'K' /* Picked */,   'A' /* Packing */, 'U' /* Paused */)) and
      (PB.BatchType not in ('T', 'RU', 'RP', 'R', 'PTS', 'SLB', 'MK' /* PickToShip, Rework and SLB Waves not required for packing, Transfer, Replenish */)) and
      /* Exclude Bulk batches */
      ((dbo.fn_Pickbatch_IsBulkBatch(PB.RecordId) = 'N' /* No */)) and
      (P.PalletType in ('C' /* Picking Cart */)) and
      (P.Status     not in ('C' /* Picking */));

Go
