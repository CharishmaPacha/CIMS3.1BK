/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/29  RKC     Added AddressLine3 (HPI-2711)
  2013/07/29  YA      Modified to fetch records from contacts which is of BL(BoL) type
  2013/05/15  TD      Removed ShipToId as seems like it has been taken mistakenly as it is refering to ShipFromId only.
  2011/12/24  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwShipFromAddress') is not null
  drop View dbo.vwShipFromAddress;
Go

Create View dbo.vwShipFromAddress (
  ContactId,

  ContactRefId,
  ContactType,

  Name,
  AddressLine1,
  AddressLine2,
  AddressLine3,
  City,
  State,
  Zip,
  CityStateZip,
  Country,
  PhoneNo,
  Email,

  Status,
  ContactPerson,
  ContactAddrId,
  OrgAddrId,

  Reference1,
  Reference2,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,

  PickTicket,  -- To use it in Address Change for an order in UI
  Message
) As
select
  SHFR.ContactId,

  SHFR.ContactRefId,
  SHFR.ContactType,

  SHFR.Name,
  SHFR.AddressLine1,
  SHFR.AddressLine2,
  SHFR.AddressLine3,
  SHFR.City,
  SHFR.State,
  SHFR.Zip,
  SHFR.CityStateZip,
  SHFR.Country,
  SHFR.PhoneNo,
  SHFR.Email,

  SHFR.Status,
  SHFR.ContactPerson,
  SHFR.ContactAddrId,
  SHFR.OrgAddrId,

  SHFR.Reference1,
  SHFR.Reference2,

  SHFR.BusinessUnit,
  SHFR.CreatedDate,
  SHFR.ModifiedDate,
  SHFR.CreatedBy,
  SHFR.ModifiedBy,

  cast(' ' as varchar(50)), -- To use it in Address Change for an order in UI
  cast(' ' as varchar(50))
from
  Contacts SHFR
where (SHFR.ContactType in ('F' /* ShipFrom */, 'BL'/* BoL */));

Go
