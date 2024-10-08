/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/12  AY      Added Abs Qty change and Abs PercentQty change fields (HA-2270)
  2021/03/09  OK      Changes to return zero for PrevQuantity, Quantity1 and FinalQuantity instead of null (HA-2217)
  2020/06/26  NB      Added Location Warehouse (CIMSV3-988)
  2018/11/29  VS      Added new column TransactionDate for performance improvement(HPI-2180)
  2018/02/20  OK      Added StorageTypeDesc (S2G-245)
  2017/05/04  LRA     Changes to resolve the truncate issue with data (CIMS-1326)
  2017/03/20  OK      Added UnitCost (GNC-1476)
  2015/04/16  AY      Expanded size of Percent fields as it could be very high
  2014/08/28  YJ      Added StorageType, and case statement for PutawayZone and
                        join condition using task table.
  2013/11/10  TD      Added new UDFs.(Showing prev cases, new and diff )
  2013/06/04  AY      Changed join with SKUs on SKUId instead of SKU
  2013/05/31  VM      QtyAccuracy might contain more than 3 digits before decimal, hence corrected casting
  2012/09/20  PK      Bugfix: Show QtyAccuracy to 100% if the location was empty before and
                       after cycle count.
  2012/08/20  NY      Bugfix: Show CurrentSKUCount correctly
  2012/08/14  NY      Added Prev LPNs and LPNs change
  2012/01/20  YA      Added SKUVariance, SKUVarianceDesc
  2012/01/18  PKS     Added SKUDesc.
  2012/01/10  PKS     Added QuantityChange,
  2012/01/05  VM      Added CurrentSKUCount, OldSKUCount.
  2011/01/02  YA      Added TransactionDate.
  2011/12/19  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwCycleCountResults') is not null
  drop View dbo.vwCycleCountResults;
Go

Create View dbo.vwCycleCountResults (
  RecordId,

  TaskId,
  TaskDetailId,
  TransactionDate,
  BatchNo,

  LPNId,
  LPN,
  PrevLPNs,
  NumLPNs,
  LPNChange,

  LocationId,
  PrevLocationId,
  Location,
  LocationRow,
  LocationLevel,
  PrevLocation,
  LocationType,
  LocationTypeDesc,
  PutawayZone,
  PickZone,
  StorageType,
  StorageTypeDesc,
  PalletId,
  PrevPalletId,
  Pallet,
  PrevPallet,
  Warehouse,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  SKUDesc,
  UPC,
  UnitCost,

  Variance,

  PrevQuantity,
  Quantity1,
  FinalQuantity,

  QuantityChange1, /* QuantityChange1 - difference between prev qty and 1st count      */
  QuantityChange2, /* QuantityChange2 - difference between first count and final count */
  QuantityChange,  /* QuantityChange  - difference between prev qty and final qty      */
  AbsQuantityChange,

  PercentQtyChange1,
  PercentQtyChange2,
  PercentQtyChange,
  AbsPercentQtyChange,

  QtyAccuracy1,
  QtyAccuracy2,
  QtyAccuracy,

  PrevInnerPacks,
  InnerPacks1,
  FinalInnerPacks,

  InnerPacksChange1,
  InnerPacksChange2,
  InnerPacksChange,

  PercentIPChange1,
  PercentIPChange2,
  PercentIPChange,

  IPAccuracy1,
  IPAccuracy2,
  IPAccuracy,

  CurrentSKUCount,
  OldSKUCount,

  SKUVariance,
  SKUVarianceDesc,

  vwCCR_UDF1, /* PutawayZone */
  vwCCR_UDF2, /* Pick Area */
  vwCCR_UDF3,
  vwCCR_UDF4,
  vwCCR_UDF5,
  vwCCR_UDF6,
  vwCCR_UDF7,
  vwCCR_UDF8,
  vwCCR_UDF9,
  vwCCR_UDF10,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) as
select
  CCR.RecordId,

  CCR.TaskId,
  CCR.TaskDetailId,
  CCR.TransactionDate,
  CCR.BatchNo,

  CCR.LPNId,
  CCR.LPN,
  CCR.PrevLPNs,
  CCR.NumLPNs,

  /* LPNChange */
  (CCR.NumLPNs - CCR.PrevLPNs),

  CCR.LocationId,
  CCR.PrevLocationId,
  CCR.Location,
  L.LocationRow,
  L.LocationLevel,
  CCR.PrevLocation,
  CCR.LocationType,
  LT.TypeDescription,
  L.PutawayZone,
  CCR.PickZone,
  L.StorageType,
  ST.TypeDescription,

  CCR.PalletId,
  CCR.PrevPalletId,
  CCR.Pallet,
  CCR.PrevPallet,
  L.Warehouse,

  CCR.SKUId,
  CCR.SKU,
  SKU.SKU1,
  SKU.SKU2,
  SKU.SKU3,
  SKU.SKU4,
  SKU.SKU5,
  SKU.Description,
  SKU.UPC,
  SKU.UnitCost,

  TD.Variance,

  coalesce(CCR.PrevQuantity, 0),
  coalesce(CCR.Quantity1, 0),
  coalesce(CCR.FinalQuantity, 0),

  /* QuantityChange1 - difference between prev qty and 1st count */
  case when coalesce(CCR.Quantity1, 0) <> 0 then (CCR.Quantity1 - CCR.PrevQuantity) else 0 end,
  /* QuantityChange2 - difference between first count and final count */
  case when coalesce(CCR.Quantity1, 0) <> 0 then (CCR.FinalQuantity - CCR.Quantity1) else 0 end,
  /* QuantityChange - difference between prev qty and final qty */
  (CCR.FinalQuantity - coalesce(CCR.PrevQuantity, 0)),
  /* AbsQuantityChange - absolute difference between prev qty and final qty */
  abs(CCR.FinalQuantity - coalesce(CCR.PrevQuantity, 0)),

  /* PercentQtyChange1 */
  case
    when (coalesce(CCR.Quantity1, 0) = 0) then
      cast(0 as decimal(5,2))
    when (CCR.PrevQuantity > 0) and (CCR.Quantity1 > 0) then
       cast ((((convert(float, CCR.Quantity1) - convert(float, CCR.PrevQuantity)) / convert(float, CCR.PrevQuantity)) * 100) as  Decimal(15,2))
    else
      null
  end,
  /* PercentQtyChange2 */
  case
    when (coalesce(CCR.Quantity1, 0) = 0) then
      cast(0 as decimal(5,2))
    when (CCR.Quantity1 > 0) and (CCR.FinalQuantity > 0) then
       cast ((((convert(float, CCR.FinalQuantity) - convert(float, CCR.Quantity1)) / convert(float, CCR.Quantity1)) * 100) as  Decimal(15,2))
    else
      null
  end,
  /* PercentQtyChange */
  case
    when (CCR.PrevQuantity > 0) then
      cast ((((convert(float, CCR.FinalQuantity) - convert(float, CCR.PrevQuantity)) / convert(float, CCR.PrevQuantity)) * 100) as  Decimal(15,2))
    when (CCR.PrevQuantity = 0) and (CCR.FinalQuantity > 0) then
       cast(100 as decimal(5,2))
    else
      null
  end,
  /* AbsPercentQtyChange */
  abs(case
        when (CCR.PrevQuantity > 0) then
          cast ((((convert(float, CCR.FinalQuantity) - convert(float, CCR.PrevQuantity)) / convert(float, CCR.PrevQuantity)) * 100) as  Decimal(15,2))
        when (CCR.PrevQuantity = 0) and (CCR.FinalQuantity > 0) then
           cast(100 as decimal(5,2))
        else
          null
      end),

  /* QtyAccuracy1 */
  case
    when (coalesce(CCR.Quantity1, 0) = 0) then
      cast(100 as decimal(5,2))
    when (coalesce(CCR.PrevQuantity, 0) > 0) and (CCR.Quantity1 > 0) then
      cast ((100 - ABS((((convert(float, CCR.Quantity1) - convert(float, CCR.PrevQuantity)) / convert(float, CCR.PrevQuantity)) * 100)))  as  Decimal(15,2))
    else
      null
  end,
  /* QtyAccuracy2 */
  case
    when (coalesce(CCR.Quantity1, 0) = 0) then
      cast(100 as decimal(5,2))
    when (coalesce(CCR.Quantity1, 0) > 0) and (CCR.FinalQuantity > 0) then
      cast ((100 - ABS((((convert(float, CCR.FinalQuantity) - convert(float, CCR.Quantity1)) / convert(float, CCR.Quantity1)) * 100)))  as  Decimal(15,2))
    else
      null
  end,
  /* QtyAccuracy */
  case
    when (CCR.PrevQuantity > 0) then
      cast ((100 - ABS((((convert(float, CCR.FinalQuantity) - convert(float, CCR.PrevQuantity)) / convert(float, CCR.PrevQuantity)) * 100)))  as  Decimal(15,2))
    when (CCR.PrevQuantity = 0) and (CCR.FinalQuantity = 0) then
      cast(100 as decimal(5,2))
    else
      null
  end,

  CCR.PrevInnerPacks,
  CCR.InnerPacks1,
  CCR.FinalInnerPacks,

    /* InnerPacksChange1 - difference between prev innerpacks and 1st count */
  case when coalesce(CCR.InnerPacks1, 0) <> 0 then (CCR.InnerPacks1 - CCR.PrevInnerPacks) else 0 end,
  /* InnerPacksChange2 - difference between first count and final count */
  case when coalesce(CCR.InnerPacks1, 0) <> 0 then (CCR.FinalInnerPacks - CCR.InnerPacks1) else 0 end,
  /* InnerPacksChange - difference between prev innerpacks and final count */
  (CCR.FinalInnerPacks - coalesce(CCR.PrevInnerPacks, 0)),

  /* PercentIPChange1 */
  case
    when (coalesce(CCR.InnerPacks1, 0) = 0) then
      cast(0 as decimal(5,2))
    when (CCR.PrevInnerPacks > 0) and (CCR.InnerPacks1 > 0) then
       cast ((((convert(float, CCR.InnerPacks1) - convert(float, CCR.PrevInnerPacks)) / convert(float, CCR.PrevInnerPacks)) * 100) as  Decimal(15,2))
    else
      null
  end,
  /* PercentIPChange2 */
  case
    when (coalesce(CCR.InnerPacks1, 0) = 0) then
      cast(0 as decimal(5,2))
    when (CCR.InnerPacks1 > 0) and (CCR.FinalQuantity > 0) then
       cast ((((convert(float, CCR.FinalInnerPacks) - convert(float, CCR.InnerPacks1)) / convert(float, CCR.InnerPacks1)) * 100) as  Decimal(15,2))
    else
      null
  end,
  /* PercentIPChange */
  case
    when (CCR.PrevInnerPacks > 0) then
      cast ((((convert(float, CCR.FinalInnerPacks) - convert(float, CCR.PrevInnerPacks)) / convert(float, CCR.PrevInnerPacks)) * 100) as  Decimal(15,12))
    when (CCR.PrevInnerPacks = 0) and (CCR.FinalInnerPacks > 0) then
       cast(100 as decimal(5,2))
    else
      null
  end,

  /* IPAccuracy1 */
  case
    when (coalesce(CCR.InnerPacks1, 0) = 0) then
      cast(100 as decimal(5,2))
    when (coalesce(CCR.InnerPacks1, 0) > 0) and (CCR.FinalInnerPacks > 0) then
      cast ((100 - ABS((((convert(float, CCR.FinalInnerPacks) - convert(float, CCR.InnerPacks1)) / convert(float, CCR.InnerPacks1)) * 100)))  as  Decimal(15,2))
    else
      null
  end,
  /* IPAccuracy2 */
  case
    when (coalesce(CCR.InnerPacks1, 0) = 0) then
      cast(100 as decimal(5,2))
    when (coalesce(CCR.InnerPacks1, 0) > 0) and (CCR.FinalInnerPacks > 0) then
      cast ((100 - ABS((((convert(float, CCR.FinalInnerPacks) - convert(float, CCR.InnerPacks1)) / convert(float, CCR.InnerPacks1)) * 100)))  as  Decimal(15,2))
    else
      null
  end,
  /* IPAccuracy */
  case
    when (CCR.PrevInnerPacks > 0) then
      cast ((100 - ABS((((convert(float, CCR.FinalInnerPacks) - convert(float, CCR.PrevInnerPacks)) / convert(float, CCR.PrevInnerPacks)) * 100)))  as  Decimal(15,12))
    when (CCR.PrevInnerPacks = 0) and (CCR.FinalInnerPacks = 0) then
      cast(100 as decimal(5,2))
    else
      null
  end,

  /* CurrentSKUCount */
  case when (CCR.FinalQuantity > 0) then 1 else 0 end,
  /* OldSKUCount */
  case when (CCR.PrevQuantity > 0) then 1 else 0 end,

  /* SKUVariance */
  LU.LookUpCode,
  LU.LookUpDescription,

  cast(' ' as varchar(50)),
  cast(left(L.Location, 2) as varchar(50)), /* UDF2 */
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),

  CCR.BusinessUnit,
  CCR.CreatedDate,
  CCR.ModifiedDate,
  CCR.CreatedBy,
  CCR.ModifiedBy
from
  CycleCountResults CCR
  left outer join TaskDetails TD  on (CCR.TaskDetailId  = TD.TaskDetailId  )
  left outer join Tasks       T   on (CCR.TaskId        = T.TaskId         )
  left outer join EntityTypes LT  on (LT.TypeCode       = CCR.LocationType ) and
                                     (LT.Entity         = 'Location'       ) and
                                     (LT.BusinessUnit   = CCR.BusinessUnit )
  left outer join SKUs        SKU on (SKU.SKUId         = CCR.SKUId        )
  left outer join LookUps     LU  on (LU.LookUpCode     = CCR.SKUVariance  ) and
                                     (LU.LookUpCategory = 'Variance'       ) and
                                     (LU.BusinessUnit   = CCR.BusinessUnit )
  left outer join Locations   L   on (L.LocationId      = TD.LocationId    )
  left outer join EntityTypes ST  on (ST.TypeCode       = L.StorageType    ) and
                                     (ST.Entity         = 'LocationStorage') and
                                     (ST.BusinessUnit   = CCR.BusinessUnit );

Go
