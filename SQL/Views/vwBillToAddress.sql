/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/29  RKC     Added AddressLine3 (HPI-2711)
  2013/07/22  AY      Change ShipToId -> BillToId
  2012/12/24  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBillToAddress') is not null
  drop View dbo.vwBillToAddress;
Go

Create View dbo.vwBillToAddress (
  ContactId,

  BillToId,
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
  BTA.ContactId,

  BTA.ContactRefId,
  BTA.ContactRefId,
  BTA.ContactType,
  BTA.Name,
  BTA.AddressLine1,
  BTA.AddressLine2,
  BTA.AddressLine3,
  BTA.City,
  BTA.State,
  BTA.Zip,
  coalesce(BTA.City+', ', '') + coalesce(BTA.State+' ', '') + coalesce(BTA.Zip, ''),
  BTA.Country,
  BTA.PhoneNo,
  BTA.Email,

  BTA.Status,
  BTA.ContactPerson,
  BTA.ContactAddrId,
  BTA.OrgAddrId,

  BTA.Reference1,
  BTA.Reference2,

  BTA.BusinessUnit,
  BTA.CreatedDate,
  BTA.ModifiedDate,
  BTA.CreatedBy,
  BTA.ModifiedBy,

  cast(' ' as varchar(50)), -- To use it in Address Change for an order in UI
  cast(' ' as varchar(50))
from
  Contacts BTA
where (BTA.ContactType in ('B' /* BillTo */));
;

Go