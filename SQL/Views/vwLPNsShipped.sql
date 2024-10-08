/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/12/06  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLPNsShipped') is not null
  drop View dbo.vwLPNsShipped;
Go
Create View dbo.vwLPNsShipped (
  LPN,
  ShippedDate,
  Quantity,
  ActualWeight,
  CartonType,

  OrderId,
  OrderShippedDate,
  BoL,
  OrderType,

  Carrier,
  ShipVia) As
select
  L.LPN,
  convert(varchar(3), datename(M, L.ModifiedDate)) + ' ' + convert(varchar, datename(D, L.ModifiedDate)) + ', ' + convert(varchar(3), datename(DW, L.ModifiedDate)) as OrderShippedDate,
  L.Quantity,
  L.ActualWeight,
  case when len(L.CartonType) = 1 then ' ' + L.CartonType
       else L.CartonType
  end,

  L.OrderId,
  convert(varchar, OH.ModifiedDate, 106),
  L.BoL,
  OH.OrderType,

  S.Carrier,
  OH.ShipVia
from LPNs L
  left outer join OrderHeaders OH on L.OrderId = OH.OrderId
  left outer join ShipVias     S  on OH.ShipVia = S.ShipVia
where ((L.Status      = 'S') and
       (OH.OrderType  = 'E') and
       (datediff(day, L.ModifiedDate, getdate()) < 24));

Go
