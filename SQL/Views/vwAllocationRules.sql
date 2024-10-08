/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/06  AY      Added LocationSubtype (HPI-2119)
  2017/08/07  TK      Added ReplenishClass (HPI-1625)
  2014/04/02  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwAllocationRules') is not null
  drop View dbo.vwAllocationRules;
Go

Create View dbo.vwAllocationRules (
  RecordId,

  SearchOrder,
  SearchSet,

  SearchType,

  WaveType,
  WaveTypeDescription,

  SKUABCClass,
  ReplenishClass,
  RuleGroup,

  LocationType,
  LocationTypeDescription,
  LocationSubType,
  StorageType,

  OrderType,

  PickingClass,
  PickingZone,
  PutawayClass,

  QuantityCondition,

  OrderByField,
  OrderByType,

  Status,
  StatusDescription,

  ConsiderRuleGroup,

  Warehouse,

  AR_UDF1,
  AR_UDF2,
  AR_UDF3,
  AR_UDF4,
  AR_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) AS
select
  AR.RecordId,

  AR.SearchOrder,
  AR.SearchSet,

  AR.SearchType,

  AR.WaveType,
  WT.TypeDescription,

  AR.SKUABCClass,
  AR.ReplenishClass,
  AR.RuleGroup,

  AR.LocationType,
  LT.TypeDescription,
  AR.LocationSubType,
  AR.StorageType,

  AR.OrderType,

  AR.PickingClass,
  AR.PickingZone,
  AR.PutawayClass,

  AR.QuantityCondition,

  AR.OrderByField,
  AR.OrderByType,

  AR.Status,
   S.StatusDescription,

  AR.ConsiderRuleGroup,

  AR.Warehouse,

  AR.UDF1,
  AR.UDF2,
  AR.UDF3,
  AR.UDF4,
  AR.UDF5,

  AR.Archived,
  AR.BusinessUnit,
  AR.CreatedDate,
  AR.ModifiedDate,
  AR.CreatedBy,
  AR.ModifiedBy
from
  AllocationRules AR
    left outer join EntityTypes  LT  on (AR.LocationType   = LT.TypeCode    ) and
                                        (LT.Entity         = 'Location'     ) and
                                        (LT.BusinessUnit   = AR.BusinessUnit)
    left outer join EntityTypes  WT  on (AR.WaveType       = WT.TypeCode    ) and
                                        (WT.Entity         = 'PickBatch'    ) and
                                        (WT.BusinessUnit   = WT.BusinessUnit)
    left outer join Statuses     S   on (AR.Status         = S.StatusCode   ) and
                                        (S.Entity          = 'Status'       ) and
                                        (S.BusinessUnit    = AR.BusinessUnit)
;

Go
