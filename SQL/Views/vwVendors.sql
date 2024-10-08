/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/29  RKC     Added AddressLine3 (HPI-2711)
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2011/01/14  VK      Added StatusDescription and ContactName fields.
  2010/10/20  AR      Added more fields and corrected some
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwVendors') is not null
  drop View dbo.vwVendors;
Go

Create View dbo.vwVendors (
  RecordId,

  VendorId,
  VendorName,
  Status,
  StatusDescription,
  VendorContactRefId,

  ContactName,
  ContactPerson,
  VendorContactId,
  AddressLine1,
  AddressLine2,
  AddressLine3,
  City,
  State,
  Country,
  Zip,
  PhoneNo,
  Email,
  ContactAddrId,
  OrgAddrId,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  V.RecordId,

  V.VendorId,
  V.VendorName,
  V.Status,
  S.StatusDescription,
  V.VendorContactId,

  CON.Name,
  CON.ContactPerson,
  CON.ContactRefId,
  CON.AddressLine1,
  CON.AddressLine2,
  CON.AddressLine3,
  CON.City,
  CON.State,
  CON.Country,
  CON.Zip,
  CON.PhoneNo,
  CON.Email,
  CON.ContactAddrId,
  CON.OrgAddrId,

  V.BusinessUnit,
  V.CreatedDate,
  V.ModifiedDate,
  V.CreatedBy,
  V.ModifiedBy
from
  Vendors V
  left outer join Contacts CON on (V.VendorContactId = CON.ContactId )
  left outer join Statuses S   on (V.Status          = S.StatusCode  ) and
                                  (S.Entity          = 'Status'      ) and
                                  (S.BusinessUnit    = V.BusinessUnit);

Go
