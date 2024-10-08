/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/29  RKC     Added AddressLine3 (HPI-2711)
  2011/01/14  VK      Added StatusDescription field.
  2010/10/20  AR      Added more fields and order changed
  2010/10/18  VM      CUST => CON - Alias name changed for consistency purpose (see vwVendors)
  2010/10/14  PK      Added Some more fields from contacts table.
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwCustomers') is not null
  drop View dbo.vwCustomers;
Go

Create View dbo.vwCustomers (
  RecordId,

  CustomerId,
  CustomerName,
  Status,
  StatusDescription,
  CustomerContactId,
  CustContactRefId,
  CustAddressLine1,
  CustAddressLine2,
  CustAddressLine3,
  CustCity,
  CustState,
  CustZip,
  CustCountry,
  CustPhoneNo,
  CustEmail,

  CustContactPerson, /* Name of the Primary Contact */
  CustContactAddrId, /* Contact Id of Primary Contact */
  CustOrgAddrId,

  BillToContactId,
  BillToContactRefId,
  BillToAddressLine1,
  BillToAddressLine2,
  BillToCity,
  BillToState,
  BillToZip,
  BillToCountry,
  BillToPhoneNo,
  BillToEmail,

  BillToContactPerson, /* Name of the BillTo Contact */
  BillToContactAddrId, /* Contact Id of the BillTo Contact */
  BillToOrgAddrId,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  CU.RecordId,

  CU.CustomerId,
  CU.CustomerName,
  CU.Status,
  S.StatusDescription,
  CU.CustomerContactId,
  CON.ContactRefId,
  CON.AddressLine1,
  CON.AddressLine2,
  CON.AddressLine3,
  CON.City,
  CON.State,
  CON.Zip,
  CON.Country,
  CON.PhoneNo,
  CON.Email,

  CON.ContactPerson,
  CON.ContactAddrId,
  CON.OrgAddrId,

  CU.CustomerBillToId,
  BT.ContactRefId,
  BT.AddressLine1,
  BT.AddressLine2,
  BT.City,
  BT.State,
  BT.Zip,
  BT.Country,
  BT.PhoneNo,
  BT.Email,

  BT.ContactPerson,
  BT.ContactAddrId,
  BT.OrgAddrId,

  CU.UDF1,
  CU.UDF2,
  CU.UDF3,
  CU.UDF4,
  CU.UDF5,

  CU.BusinessUnit,
  CU.CreatedDate,
  CU.ModifiedDate,
  CU.CreatedBy,
  CU.ModifiedBy

from
  Customers CU
  left outer join Contacts  CON  on (CON.ContactId  = CU.CustomerContactId)
  left outer join Contacts  BT   on (BT.ContactId   = CU.CustomerBillToId )
  left outer join Statuses  S    on (S.StatusCode   = CU.Status           ) and
                                    (S.Entity       = 'Status'            ) and
                                    (S.BusinessUnit = CU.BusinessUnit     )
;

Go
