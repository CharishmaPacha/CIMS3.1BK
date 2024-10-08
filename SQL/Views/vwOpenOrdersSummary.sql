/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/29  PK/YJ   Added CreatedDate, ModifiedDate: ported changes from prod onsite (HA-2729)
  2021/03/13  VM      Added AppointmentDateTime (HA-2275)
  2020/08/28  PK      Bug fix (HA-1267)
  2020/08/12  SK      Initial Revision (HA-1267)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOpenOrdersSummary') is not null
  drop View dbo.vwOpenOrdersSummary;
Go

Create View dbo.vwOpenOrdersSummary (
  OrderId,
  PickTicket,
  SalesOrder,

  OrderType,
  OrderStatus,
  OrderStatusDesc,

  CancelDate,
  DesiredShipDate,

  NumSKUs,
  NumLines,
  NumUnits,
  TotalSalePrice,
  TotalShipmentValue,

  SoldToId,
  ShipToId,
  ShipFrom,
  ShipVia,
  ShipViaDescription,
  CustPO,
  Ownership,
  Warehouse,
  Account,
  AccountName,
  /* LoadInfo */
  LoadNumber,
  RoutingStatus,
  LoadStatus,
  LoadStatusDesc,
  LoadDesiredShipDate,
  AppointmentDateTime,
  /* Other */
  BusinessUnit,
  CreatedDate,
  ModifiedDate
) As
select
  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,

  OH.OrderType,
  OH.Status,
  OST.StatusDescription,

  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.CancelDate,      101 /* mm/dd/yyyy */) as DateTime),

  OH.NumSKUs,
  OH.NumLines,
  OH.NumUnits,
  OH.TotalSalesAmount,
  OH.TotalShipmentValue,

  OH.SoldToId,
  OH.ShipToId,
  OH.ShipFrom,
  OH.ShipVia,
  SV.Description,
  OH.CustPO,
  OH.Ownership,
  OH.Warehouse,
  OH.Account,
  OH.AccountName,
  SH.LoadNumber,
  LD.RoutingStatus,
  LD.Status,
  LDST.StatusDescription,
  cast(convert(varchar, LD.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  LD.AppointmentDateTime,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate
from
  OrderHeaders OH
  left outer join Statuses        OST  on (OH.Status       = OST.StatusCode  ) and
                                          (OST.Entity      = 'Order'         )
  left outer join ShipVias        SV   on (OH.ShipVia      = SV.ShipVia      )
  left outer join OrderShipments  OS   on (OH.OrderId      = OS.OrderId      )
  left outer join Shipments       SH   on (OS.ShipmentId   = SH.ShipmentId   )
  left outer join Loads           LD   on (SH.LoadId       = LD.LoadId       )
  left outer join Statuses        LDST on (LD.Status       = LDST.StatusCode ) and
                                          (LDST.Entity     = 'Load'          )

where (OH.Archived = 'N' /* No */) and
      (OH.OrderType not in ('R', 'RP', 'RU', 'B' /* Replenish or Bulk */)) and
      (OH.Status not in ('S' /* Shipped */ ,'D' /* Completed */, 'X'/* Cancelled */, 'E' /* Cancellation in progress */))


Go