/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/10/26  SPP     Show ShipVia description from ShipVias table (CIMS-1646)
  2016/08/17  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2015/02/24  NB/DK   Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBulkOrdersToPack') is not null
  drop View dbo.vwBulkOrdersToPack;
Go

Create View dbo.vwBulkOrdersToPack (
  LPNId,

  LPN,
  LPNType,
  LPNTypeDescription,
  Status,
  StatusDescription,

  CoO,
  InnerPacks,
  Quantity,
  SKUCount,

  PalletId,
  Pallet,
  LocationId,
  Location,
  Ownership,

  ShipmentId,
  LoadId,
  ASNCase,

  OrderId,
  PickTicket,
  SalesOrder,
  PickBatchId,
  PickBatchNo,
  ShipVia,
  ShipViaDescription,
  DesiredShipDate,
  CancelDate,
  OrderPriority,
  OrderStatus,
  OrderStatusDescription,
  OrderShortPick,
  OrderComplete,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

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

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  /* Place holders for any new fields, if required */
  vwUDF1,
  vwUDF2,
  vwUDF3,
  vwUDF4,
  vwUDF5,

  BusinessUnit
)
as
select
  L.LPNId,

  L.LPN,
  L.LPNType,
  LT.TypeDescription,
  L.Status,
  ST.StatusDescription,

  L.CoO,
  L.InnerPacks,
  L.Quantity,
  0,

  L.PalletId,
  P.Pallet,
  L.LocationId,
  L.Location,
  L.Ownership,

  L.ShipmentId,
  L.LoadId,
  L.ASNCase,

  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  P.PickBatchId,
  OH.PickBatchNo,
  OH.ShipVia,
  SV.Description,   /* ShipVia Description */
  OH.DesiredShipDate,
  null,              /* OH.CancelDate  TO BE ADDED TO THE ORDER HEADERS TABLE */
  OH.Priority,
  OH.Status,
  OS.StatusDescription, /* Order Status Description */
  OH.ShortPick,
  case when (OH.Status = 'C' /* Picking */) then
         'N' /* Order Not Picked Completely */
       when (OH.Status = 'P' /* Picked */) then
         'Y' /* Order Picked Completely */
  else
    null
  end,

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
  OH.UDF6,
  OH.UDF7,
  OH.UDF8,
  OH.UDF9,
  OH.UDF10,

  L.UDF1,
  L.UDF2,
  L.UDF3,
  L.UDF4,
  L.UDF5,

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  L.BusinessUnit

from OrderHeaders      OH
  left outer join LPNs              L   on  (L.OrderId         = OH.OrderId     ) and
                                            (L.LPNType not in ('S' /* ShipCarton */, 'C' /* Carton */))
  left outer join Pallets           P    on (L.PalletId        = P.PalletId     )
  left outer join EntityTypes       LT   on (LT.TypeCode       = L.LPNType      ) and
                                            (LT.Entity         = 'LPN'          ) and
                                            (LT.BusinessUnit   = L.BusinessUnit )
  left outer join Statuses          ST   on (L.Status          = ST.StatusCode  ) and
                                            (ST.Entity         = 'LPN'          ) and
                                            (ST.BusinessUnit   = L.BusinessUnit )
  left outer join ShipVias          SV   on (OH.ShipVia        = SV.ShipVia     ) and
                                            (OH.BusinessUnit   = SV.BusinessUnit)
  left outer join Statuses          OS   on (OH.Status         = OS.StatusCode  ) and
                                            (OS.Entity         = 'Order'        ) and
                                            (OS.BusinessUnit   = L.BusinessUnit )
;

Go
