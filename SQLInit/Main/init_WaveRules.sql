/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2021/01/14  TK      Added Status field (BK-64)
  2020/07/09  VS      Added OrderCategory in Wave Rules to Generate respective WaveType (HA-1054)
  2020/06/19  SV      Changed the structure of rules implementation (HA-565)
  2015/06/25  RV      Added rules for Bulk Pull Preferences.
  2015/02/26  TK      Added rules for Bulk Pull
  2015/02/25  TK      Added rules for Replenish Order
  2014/12/23  VM      Initial rules for SRI
  2014/12/10  TD      Added rules for replenishments.
  2014/05/08  PK      Added Replenish rules for Replenish Cases/Units.
  2014/12/10  TD      Added rules for replenishments.
  2013/10/24  NY      Added rules for all handling codes which are added newly.
  2013/06/17  TD      Added rules for Replenishments.
  2013/03/26  TD      Clean-up all the rules and added L-Large, S-Small type of batchrules.
  2012/10/30  YA      Modified SoldToId for Target.com orders.
  2012/10/12  AY      Target store 0551 should be a separate batch and rule for Walmart.Com orders
  2012/09/27  AY      Do not auto generate batches for Walmart.
  2012/08/27  PK      Updated DestZone and DestLocation for Prepacks
  2012/08/10  AY      Changed to use UDF4 for Order group
  2012/07/13  NY/VM   Revised rules to be for each Warehouse.
  2012/07/02  VM      Inactivated CrossDock rules as batching is not applicable to CD orders in case of TD
  2012/06/20  PK/AY   Revised rules to be for each owner
  2012/05/15  NY      Initial revision.
------------------------------------------------------------------------------*/

Go

delete from WaveRules;

declare @ttWaveRules TPickBatchRules;

/*------------------------------------------------------------------------------*/
/* Wave Rules */
insert into @ttWaveRules
             (OrderType, BatchingLevel, OrderPriority,  ShipVia,  SoldToId, ShipToId, Ownership, OH_Category1, BatchType,  BatchPriority,  BatchStatus,  MaxOrders,  MaxLines, MaxSKUs,  MaxUnits, MaxWeight, OrderWeightMin,   OrderWeightMax,   MaxVolume,   OrderVolumeMin, OrderVolumeMax,   OrderInnerPacks, OrderUnits, DestZone,    DestLocation,   PickBatchGroup,  OrderDetailWeight, OrderDetailVolume, PutawayZone,  SortSeqNo, Status)
/* Waving Level - OD */
      select 'C',        'OD',          null,           null,     null,     null,     null,      null,         'PTS',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OD',          null,           null,     null,     null,     null,      null,         'PTC',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OD',          null,           null,     null,     null,     null,      null,         'SLB',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OD',          null,           null,     null,     null,     null,      null,         'CP',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OD',          null,           null,     null,     null,     null,      null,         'PTLC',     null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OD',          null,           null,     null,     null,     null,      null,         'PTL',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OD',          null,           null,     null,     null,     null,      null,         'BCP',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OD',          null,           null,     null,     null,     null,      null,         'BPP',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'RW',       'OD',          null,           null,     null,     null,     null,      null,         'RW',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'MK',       'OD',          null,           null,     null,     null,     null,      null,         'MK',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'BK',       'OD',          null,           null,     null,     null,     null,      null,         'BK',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'T',        'OD',          null,           null,     null,     null,     null,      null,         'XFER',     null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'

/* Waving Level - OH */
union select 'C',        'OH',          null,           null,     null,     null,     null,      null,         'PTS',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OH',          null,           null,     null,     null,     null,      null,         'PTC',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OH',          null,           null,     null,     null,     null,      null,         'SLB',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OH',          null,           null,     null,     null,     null,      null,         'CP',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OH',          null,           null,     null,     null,     null,      null,         'PTLC',     null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OH',          null,           null,     null,     null,     null,      null,         'PTL',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OH',          null,           null,     null,     null,     null,      null,         'BCP',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'C',        'OH',          null,           null,     null,     null,     null,      null,         'BPP',      null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'RW',       'OH',          null,           null,     null,     null,     null,      null,         'RW',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'MK',       'OH',          null,           null,     null,     null,     null,      null,         'MK',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'BK',       'OH',          null,           null,     null,     null,     null,      null,         'BK',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'T',        'OH',          null,           null,     null,     null,     null,      null,         'XFER',     null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'

/* Replenish level */
union select 'RU',       'OH',          null,           null,     null,     null,     null,      null,         'RU',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'
union select 'RP',       'OH',          null,           null,     null,     null,     null,      null,         'RP',       null,           'N',          null,       null,     null,     null,     99999,     0,                99999,            99999,       0,              99999,            null,            null,       null,        null,           null,            null,              null,              null,         1,         'A'

insert into WaveRules (OrderType, BatchingLevel, OrderPriority, ShipVia, SoldToId, ShipToId,
                       OH_Category1, Ownership, Warehouse,
                       BatchType, BatchPriority, BatchStatus,
                       MaxOrders, MaxLines, MaxSKUs, MaxUnits, MaxWeight, MaxVolume,
                       OrderWeightMin, OrderWeightMax, OrderVolumeMin, OrderVolumeMax, OrderInnerPacks, OrderUnits,
                       DestZone, DestLocation, PickBatchGroup,
                       OrderDetailWeight, OrderDetailVolume,
                       PutawayZone, SortSeq, Status, BusinessUnit)
  select WR.OrderType, WR.BatchingLevel, WR.OrderPriority, WR.ShipVia, WR.SoldToId, WR.ShipToId,
         WR.OH_Category1, WR.Ownership, WH.LookUpCode,
         WR.BatchType, WR.BatchPriority, WR.BatchStatus,
         WR.MaxOrders, WR.MaxLines, WR.MaxSKUs, WR.MaxUnits, WR.MaxWeight, WR.MaxVolume,
         WR.OrderWeightMin, WR.OrderWeightMax, WR.OrderVolumeMin, WR.OrderVolumeMax, WR.OrderInnerPacks, WR.OrderUnits,
         WR.DestZone, WR.DestLocation, WR.PickBatchGroup,
         WR.OrderDetailWeight, WR.OrderDetailVolume,
         WR.PutawayZone, WR.SortSeqNo, coalesce(WR.Status, 'A' /* Active */), BU.BusinessUnit
  from @ttWaveRules WR
    join EntityTypes   E  on (WR.BatchType   = E.TypeCode)
    join BusinessUnits BU on (E.BusinessUnit = BU.BusinessUnit)
    join Lookups       WH on (E.BusinessUnit = WH.BusinessUnit)
  where (E.Entity = 'Wave') and (E.Status = 'A') and
        (WH.LookUpCategory = 'Warehouse') and (WH.Status = 'A');

Go
