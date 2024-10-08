/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/29  RKC     pr_Imports_OrderHeaders_Addresses:Added AddressLine3 (HPI-2711)
  2017/04/12  NB      pr_Imports_OrderHeaders, pr_Imports_OrderHeaders_Addresses(CIMS-1289)
  2017/04/11  DK      pr_Imports_OrderHeaders, pr_Imports_OrderHeaders_Addresses, pr_Imports_AddOrUpdateAddresses, pr_Imports_ContactsClearDuplicates,
  2016/04/05  OK      pr_Imports_OrderHeaders: Refactor the code as pr_Imports_OrderHeaders_Addresses to import contacts (CIMS-862)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderHeaders_Addresses') is not null
  drop Procedure pr_Imports_OrderHeaders_Addresses;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_OrderHeaders_Addresses: The procedure takes all the addresses
    given in the Orderheaders and imports them after eliminating duplicates.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderHeaders_Addresses
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @ttOrderAddresses     TContactImportType,
          @ttOrderAddressImport TContactImportType;
begin
  SET NOCOUNT ON;

  /* Importing Address Fields to local Temp Table*/
  insert into @ttOrderAddresses(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, City, State,
                                Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2,
                                BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
                                InputXML)
    select SoldToId, 'C' /* Customer */, SoldToName, SoldToAddressLine1, SoldToAddressLine2, SoldToCity,
           SoldToState, SoldToCountry, SoldToZip, SoldToPhoneNo, SoldToEmail, SoldToAddressReference1,
           SoldToAddressReference2, BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
           null --InputXML
    from #OrderHeadersImport
    where (RecordAction <> 'E') and
          (SoldToName is not null)  -- Add/Update customer address only if SoldToName is passed in the XML
    order by RecordId    --Required to maintain order from the previous table

  insert into @ttOrderAddresses(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, AddressLine3, City, State,
                                Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2, Residential, ContactPerson,
                                BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
                                InputXML)
    select ShipToId, 'S' /* Ship To */, ShipToName, ShipToAddressLine1, ShipToAddressLine2, ShipToAddressLine3, ShipToCity,
           ShipToState, ShipToCountry, ShipToZip, ShipToPhoneNo, ShipToEmail, ShipToAddressReference1,
           ShipToAddressReference2, ShipToResidential, ShipToContactPerson, BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
           null --InputXML
    from #OrderHeadersImport
    where (RecordAction <> 'E') and
          (ShipToName is not null) -- Add/Update Ship To address only if ShipToName is passed in the XML
    order by RecordId   --Required to maintain order from the previous table

  insert into @ttOrderAddresses(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, City, State,
                                Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2,
                                BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
                                InputXML)
    select ReturnAddrId, 'R' /* Return Address */, ReturnAddressName, ReturnAddressLine1,
           ReturnAddressLine2, ReturnAddressCity, ReturnAddressState, ReturnAddressCountry,
           ReturnAddressZip, ReturnAddressPhoneNo, ReturnAddressEmail, ReturnAddressReference1,
           ReturnAddressReference2, BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
           null --InputXML
    from #OrderHeadersImport
    where (RecordAction <> 'E') and
          (ReturnAddressName is not null) -- Add/Update return address only if Name is passed in the XML
    order by RecordId  --Required to maintain order from the previous table

  insert into @ttOrderAddresses(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, City, State,
                                Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2,
                                BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
                                InputXML)
    select MarkForAddress, 'M' /* Mark For Address */, MarkForAddressName, MarkForAddressLine1,
           MarkForAddressLine2, MarkForAddressCity, MarkForAddressState, MarkForAddressCountry,
           MarkForAddressZip, MarkForAddressPhoneNo, MarkForAddressEmail, MarkForAddressReference1,
           MarkForAddressReference2, BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
           null --InputXML
    from #OrderHeadersImport
    where (RecordAction <> 'E') and
          (MarkForAddressName is not null) -- Add/Update Markfor address only if Name is passed in the XML
    order by RecordId   --Required to maintain order from the previous table

  insert into @ttOrderAddresses(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, City, State,
                                Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2,
                                BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
                                InputXML)
    select BillToAddress, 'B' /* Bill To Address */, BillToAddressName, BillToAddressLine1,
           BillToAddressLine2, BillToAddressCity, BillToAddressState, BillToAddressCountry,
           BillToAddressZip, BillToAddressPhoneNo, BillToAddressEmail, BillToAddressReference1,
           BillToAddressReference2, BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
           null --InputXML
    from #OrderHeadersImport
    where (RecordAction <> 'E') and
          (BillToAddressName is not null) -- Add/Update BillTo address only if Name is passed in the XML
    order by RecordId   --Required to maintain order from the previous table

  /* Logic to clear duplicates
     Returned the original table if not duplicates found
     else returns the table entries without the duplicates */
  if (exists (select ContactRefId, ContactType, count(ContactRefId)
                from @ttOrderAddresses
                group by ContactRefId, ContactType, BusinessUnit
                having count(ContactRefId) > 1))
    begin
      insert into @ttOrderAddressImport(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, AddressLine3, City, State,
                                        Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2, Residential, ContactPerson,
                                        BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
                                        InputXML)
        exec pr_Imports_ContactsClearDuplicates @ttOrderAddresses
    end
  else
    begin
      insert into @ttOrderAddressImport(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, AddressLine3, City, State,
                                        Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2, Residential, ContactPerson,
                                        BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
                                        InputXML)
        select ContactRefId, ContactType, Name, AddressLine1, AddressLine2, AddressLine3, City, State,
               Country, Zip, PhoneNo, Email, AddressReference1, AddressReference2, Residential, ContactPerson,
               BusinessUnit, CreatedBy, ModifiedBy, CreatedDate, ModifiedDate,
               InputXML
        from @ttOrderAddresses
    end

  /* Mark Records in AddressImport table as Insert/Update based on
     record existence in Contacts Table */
  update AI
  set AI.RecordAction = case when(coalesce(C.ContactRefId, '') = '') then 'I' /* Insert */
                        else
                          'U' /* Update */
                        end
  from @ttOrderAddressImport AI
    left outer join Contacts C on AI.ContactRefId = C.ContactRefId and
                                  AI.ContactType  = C.ContactType and
                                  AI.Businessunit = C.BusinessUnit;

  /* Insert or Update to Contacts and/or Customers tables */
  exec pr_Imports_AddOrUpdateAddresses @ttOrderAddressImport;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_OrderHeaders_Addresses */

Go
