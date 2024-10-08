/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/01  KSK     Added TaxId (CID-634)
  2018/03/09  YJ      Added Residential (S2G-354)
  2017/10/21  VM      Added AddressRegion and UDFs (OB-576, 577)
  2012/09/11  AY      Added Reference Fields
  2012/07/12  AY      Added field CityStateZip
  2010/10/09  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwSoldToAddress') is not null
  drop View dbo.vwSoldToAddress;
Go

Create View dbo.vwSoldToAddress (
  ContactId,

  SoldToId,
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

  TaxId,
  Reference1,
  Reference2,
  Residential,
  AddressRegion,

  SOTA_UDF1,
  SOTA_UDF2,
  SOTA_UDF3,
  SOTA_UDF4,
  SOTA_UDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  SOTA.ContactId,

  SOTA.ContactRefId,
  SOTA.ContactRefId,
  SOTA.ContactType,
  SOTA.Name,
  SOTA.AddressLine1,
  SOTA.AddressLine2,
  SOTA.AddressLine3,
  SOTA.City,
  SOTA.State,
  SOTA.Zip,
  SOTA.CityStateZip,

  SOTA.Country,
  SOTA.PhoneNo,
  SOTA.Email,

  SOTA.Status,
  SOTA.ContactPerson,
  SOTA.ContactAddrId,
  SOTA.OrgAddrId,

  SOTA.TaxId,
  SOTA.Reference1,
  SOTA.Reference2,
  SOTA.Reference2,
  SOTA.AddressRegion,

  SOTA.UDF1,
  SOTA.UDF2,
  SOTA.UDF3,
  SOTA.UDF4,
  SOTA.UDF5,

  SOTA.BusinessUnit,
  SOTA.CreatedDate,
  SOTA.ModifiedDate,
  SOTA.CreatedBy,
  SOTA.ModifiedBy
from
  Contacts SOTA
where (SOTA.ContactType = 'C' /* Customer/SoldTo */)
;

Go