/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/29  RKC     pr_Imports_OrderHeaders_Addresses:Added AddressLine3 (HPI-2711)
                      pr_Imports_OrderHeaders:Pass the UDF19 value to ShipToAddressLine3
                      pr_Imports_Contacts:Added AddressLine3
                      pr_Imports_ContactsClearDuplicates :Added AddressLine3
  2017/04/11  DK      pr_Imports_OrderHeaders, pr_Imports_OrderHeaders_Addresses, pr_Imports_AddOrUpdateAddresses, pr_Imports_ContactsClearDuplicates,
                      pr_Imports_ContactsClearDuplicates: Added to remove duplicates for Contacts. (LL-206)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ContactsClearDuplicates') is not null
  drop Procedure pr_Imports_ContactsClearDuplicates;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_ContactsClearDuplicates
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ContactsClearDuplicates
 (@Addresses  TContactImportType  READONLY)
as
  declare @ttAddresses TContactImportType;
begin
  /* Remove duplicates by selecting the latest record in sequence

     Assumption: The sequence with which the records are sent is the sequence in which
                 the recordId is assigned */
  insert into @ttAddresses(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, AddressLine3, City, State,
                           Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2, Residential, ContactPerson,
                           BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
                           InputXML)
    select ContactRefId, ContactType, Name, AddressLine1, AddressLine2, AddressLine3, City, State,
           Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2, Residential, ContactPerson,
           BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
           InputXML
    from @Addresses
    where RecordId in (select max(RecordId) from @Addresses group by ContactRefId, ContactType, BusinessUnit)

  /* Return the rows to be inserted */
  select ContactRefId, ContactType, Name, AddressLine1, AddressLine2, AddressLine3, City, State,
         Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2, Residential, ContactPerson,
         BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
         InputXML
  from @ttAddresses
  order by RecordId;
end /* pr_Imports_ContactsClearDuplicates */

Go
