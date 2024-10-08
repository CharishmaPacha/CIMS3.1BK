/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/12/02  PKS     Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwOrderAddress') is not null
  drop View dbo.vwOrderAddress;
Go

Create View vwOrderAddress (
  OrderId,

  SoldToId,
  SoldName,
  SoldAddressLine1,
  SoldAddressLine2,
  SoldCity,
  SoldState,
  SoldZip,
  SoldCountry,
  SoldPhoneNo,

  ShipToId,
  ShipName,
  ShipAddressLine1,
  ShipAddressLine2,
  ShipCity,
  ShipState,
  ShipZip,
  ShipCountry,
  ShipPhoneNo
) As
select
  OH.OrderId,

  SoldAdd.SoldToId,
  SoldAdd.Name,
  SoldAdd.AddressLine1,
  SoldAdd.AddressLine2,
  SoldAdd.City,
  SoldAdd.State,
  SoldAdd.Zip,
  SoldAdd.Country,
  SoldAdd.PhoneNo,

  ShipAdd.ShipToId,
  ShipAdd.Name,
  ShipAdd.AddressLine1,
  ShipAdd.AddressLine2,
  ShipAdd.City,
  ShipAdd.State,
  ShipAdd.Zip,
  ShipAdd.Country,
  ShipAdd.PhoneNo
from OrderHeaders OH
  left outer join vwShiptoAddress ShipAdd on (OH.ShipToId = ShipAdd.ShipToId)
  left outer join vwSoldToAddress SoldAdd on (OH.SoldToId = SoldAdd.SoldToId)

Go
