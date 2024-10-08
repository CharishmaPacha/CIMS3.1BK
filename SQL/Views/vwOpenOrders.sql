/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/17  SK      update where clause for performance (HA-1267)
  2014/05/24  AY      Exclude Replenish and Bulk Orders
  2014/02/03  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOpenOrders') is not null
  drop View dbo.vwOpenOrders;
Go

Create View dbo.vwOpenOrders (
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  Status,
  StatusDescription,

  WaveStatus,
  WaveNo,

  DesiredShipDate,
  CancelDate,

  SoldToId,
  ShipToId,
  ShipFrom,
  ShipVia,

  CustPO,
  Ownership,
  Warehouse,

  Account,
  AccountName,

  HostOrderLine,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,

  Lot,
  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsReserved,
  UnitsNeeded,
  UnitsShipped,
  UnitsRemainToShip,

  OH_UDF1,
  OH_UDF2,
  OH_UDF3,
  OH_UDF4,
  OH_UDF5,
  OH_UDF6,
  OH_UDF7,
  OH_UDF8,
  OH_UDF9,
  OH_UDF10,

  OD_UDF1,
  OD_UDF2,
  OD_UDF3,
  OD_UDF4,
  OD_UDF5,
  OD_UDF6,
  OD_UDF7,
  OD_UDF8,
  OD_UDF9,
  OD_UDF10,

  vwOOE_UDF1,
  vwOOE_UDF2,
  vwOOE_UDF3,
  vwOOE_UDF4,
  vwOOE_UDF5,
  vwOOE_UDF6,
  vwOOE_UDF7,
  vwOOE_UDF8,
  vwOOE_UDF9,
  vwOOE_UDF10,

  SourceSystem,
  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  distinct
  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OT.TypeDescription,
  OH.Status,
  OS.StatusDescription,

  PB.Status,
  OH.PickBatchNo,

  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.CancelDate,   101 /* mm/dd/yyyy */) as DateTime),

  coalesce(OH.SoldToId, ''),
  coalesce(OH.ShipToId, ''),
  coalesce(OH.ShipFrom, ''),
  coalesce(OH.ShipVia, ''),

  coalesce(OH.CustPO, ''),
  OH.Ownership,
  OH.Warehouse,

  coalesce(OH.Account, ''),
  OH.AccountName,

  OD.HostOrderLine,

  OD.SKUId,
  coalesce(S.SKU, ''),
  coalesce(S.SKU1, ''),
  coalesce(S.SKU2, ''),
  coalesce(S.SKU3, ''),
  coalesce(S.SKU4, ''),
  coalesce(S.SKU5, ''),

  coalesce(OD.Lot, ''),
  coalesce(OD.UnitsOrdered, 0),
  coalesce(OD.UnitsAuthorizedToShip, 0),
  coalesce(OD.UnitsAssigned, 0),
  coalesce(OD.UnitsToAllocate, 0),
  coalesce(OD.UnitsShipped, 0),
  coalesce((OD.UnitsAuthorizedToShip - OD.UnitsShipped), 0),

  coalesce(OH.UDF1, ''),
  coalesce(OH.UDF2, ''),
  coalesce(OH.UDF3, ''),
  coalesce(OH.UDF4, ''),
  coalesce(OH.UDF5, ''),
  coalesce(OH.UDF6, ''),
  coalesce(OH.UDF7, ''),
  coalesce(OH.UDF8, ''),
  coalesce(OH.UDF9, ''),
  coalesce(OH.UDF10, ''),

  coalesce(OD.UDF1, ''),
  coalesce(OD.UDF2, ''),
  coalesce(OD.UDF3, ''),
  coalesce(OD.UDF4, ''),
  coalesce(OD.UDF5, ''),
  coalesce(OD.UDF6, ''),
  coalesce(OD.UDF7, ''),
  coalesce(OD.UDF8, ''),
  coalesce(OD.UDF9, ''),
  coalesce(OD.UDF10, ''),

  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF1 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF2 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF3 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF4 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF5 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF6 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF7 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF8 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF9 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwOOE_UDF10 */

  OH.SourceSystem,
  OH.Archived,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy
from
  OrderHeaders OH
  left outer join OrderDetails OD  on (OH.OrderId      = OD.OrderId     )
  left outer join SKUs         S   on (S.SKUId         = OD.SKUId       )
  left outer join EntityTypes  OT  on (OT.TypeCode     = OH.OrderType   ) and
                                      (OT.Entity       = 'Order'        ) and
                                      (OT.BusinessUnit = OH.BusinessUnit)
  left outer join Statuses     OS  on (OS.StatusCode   = OH.Status      ) and
                                      (OS.Entity       = 'Order'        ) and
                                      (OS.BusinessUnit = OH.BusinessUnit)
  left outer join PickBatches  PB  on (PB.BatchNo = OH.PickBatchNo)
where (OH.Archived = 'N' /* No */) and
      (OH.OrderType not in ('R', 'RP', 'RU', 'B' /* Replenish or Bulk */)) and
      (OH.Status not in ('S'/* Shipped */, 'D' /* Completed */, 'X'/* Cancelled */))

Go
