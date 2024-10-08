/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/11/07  YAN     Updating upper(SHTA.State) for SHTA.State (portback from BK onsite prod) (BK-75)
  2021/12/17  OK      Used upper keyword to return Country in uppercase (OB2-2252)
  2019/12/06  PHK     Removed NullIf condition for ContactPerson (CID-1213)
  2019/08/29  RKC     Added AddressLine3 (HPI-2711)
  2019/07/05  KSK     Added TaxId (CID-632)
  2018/03/09  YJ      Added Residential (S2G-354)
  2017/12/06  VM      Handle empty values in ContactPerson (OB-642)
  2015/04/28  AY      Added CountryCode and used Lookups and mapping to get the right code
  2015/09/21  AY      If no ContactPerson is given, use Org name
  2015/06/29  AY      Added AddressRegion and UDFs
  2012/08/30  AY      Temporary fix to pick up both SoldTo/ShipTo addresses for ShipTo
  2012/07/12  AY      Added field CityStateZip
  2012/01/31  YA      Added PickTicket, and Message as it is needed for mapping to LINQ datasource
                        in Orders page while updating address.
  2010/10/09  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwShipToAddress') is not null
  drop View dbo.vwShipToAddress;
Go

Create View dbo.vwShipToAddress (
  ContactId,

  ShipToId,
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
  CountryCode,
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

  SHTA_UDF1,
  SHTA_UDF2,
  SHTA_UDF3,
  SHTA_UDF4,
  SHTA_UDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,

  PickTicket,  -- To use it in Address Change for an order in UI
  Message
) As
select
  SHTA.ContactId,

  SHTA.ContactRefId,
  SHTA.ContactRefId,
  SHTA.ContactType,
  SHTA.Name,
  SHTA.AddressLine1,
  SHTA.AddressLine2,
  SHTA.AddressLine3,
  SHTA.City,
  upper(SHTA.State),
  SHTA.Zip,
  SHTA.CityStateZip,
  upper((select TargetValue from dbo.fn_GetMappedValues ('CIMS', coalesce(LU.LookUpCode, SHTA.Country), 'CIMS', 'Country', '', SHTA.BusinessUnit))),
  upper(SHTA.Country),
  SHTA.PhoneNo,
  SHTA.Email,

  SHTA.Status,
  coalesce(SHTA.ContactPerson, ''),
  SHTA.ContactAddrId,
  SHTA.OrgAddrId,

  SHTA.TaxId,
  SHTA.Reference1,
  SHTA.Reference2,
  SHTA.Residential,
  SHTA.AddressRegion,

  SHTA.UDF1,
  SHTA.UDF2,
  SHTA.UDF3,
  SHTA.UDF4,
  SHTA.UDF5,

  SHTA.BusinessUnit,
  SHTA.CreatedDate,
  SHTA.ModifiedDate,
  SHTA.CreatedBy,
  SHTA.ModifiedBy,

  cast(' ' as varchar(50)), -- To use it in Address Change for an order in UI
  cast(' ' as varchar(50))
from
  Contacts SHTA
  left outer join vwLookUps LU On (LU.LookUpCategory = 'Country') and
                                  (SHTA.Country      = LU.LookUpDescription)
where (SHTA.ContactType in ('S' /* ShipTo */));

Go
