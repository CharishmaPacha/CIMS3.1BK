/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/06  VS      Added NumLPNs (HA-2170)
  2019/10/04  MS      Added ShipVia (CID-1029)
  2019/07/21  AY      Added PickTicket and mapped UDF1 to PickTicket
  2013/05/16  PK      Added LoadNumber, BoLId, BoLNumber
  2012/10/16  AY      Changed left outer joins to joins for performance. There
                        should not be an ordershipment record anyway w/o Order or Shipment
  2012/08/30  AY      Added OrderType, OrderStatus, ShipmentStatus fields
  2012/06/18  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOrderShipments') is not null
  drop View dbo.vwOrderShipments;
Go

Create View dbo.vwOrderShipments (
  RecordId,

  OrderId,
  ShipmentId,
  LoadId,
  LoadNumber,

  BoLId,
  BoLNumber,

  OrderType,
  OrderStatus,
  PickTicket,
  ShipVia,
  ShipmentStatus,

  Account,
  SoldToId,
  ShipToId,
  NumLPNs,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  Archived,
  BusinessUnit,

  CreatedDate,
  CreatedBy,

  ModifiedDate,
  ModifiedBy
) As
select
  OS.RecordId,

  OS.OrderId,
  OS.ShipmentId,
  S.LoadId,
  S.LoadNumber,

  S.BoLId,
  S.BoLNumber,

  OH.OrderType,
  OH.Status,
  OH.PickTicket,
  OH.ShipVia,
  S.Status,

  OH.Account,
  OH.SoldToId,
  OH.ShipToId,
  S.NumLPNs,

  OS.UDF1,
  OS.UDF2,
  OS.UDF3,
  OS.UDF4,
  OS.UDF5,

  OS.Archived,
  OS.BusinessUnit,

  OS.CreatedDate,
  OS.CreatedBy,

  OS.ModifiedDate,
  OS.ModifiedBy
From
OrderShipments OS
  join OrderHeaders OH on (OS.OrderId   = OH.OrderId   )
  join Shipments     S on (S.ShipmentId = OS.ShipmentId)
;

Go
