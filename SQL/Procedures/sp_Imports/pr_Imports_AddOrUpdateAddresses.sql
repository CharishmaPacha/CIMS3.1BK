/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/04  LAC     pr_Imports_OrderHeaders_LoadData/Addresses, pr_Imports_AddOrUpdateAddresses: Added ShipToContactPerson field (BK-941)
  2017/04/11  DK      pr_Imports_OrderHeaders, pr_Imports_OrderHeaders_Addresses, pr_Imports_AddOrUpdateAddresses, pr_Imports_ContactsClearDuplicates,
  2016/07/07  TD      pr_Imports_AddOrUpdateAddresses:Changes to eliminate null values while considering Addressline1 and 2
  2015/03/29  SV      pr_Imports_AddOrUpdateAddresses: Made changes to update the AddressRegion based on the Country
  2015/01/08  SK      pr_Imports_OrderHeaders_Delete, pr_Imports_AddOrUpdateAddresses: Added procedures
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_AddOrUpdateAddresses') is not null
  drop Procedure pr_Imports_AddOrUpdateAddresses;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_AddOrUpdateAddresses
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_AddOrUpdateAddresses
 (@AddressImport  TContactImportType  READONLY)
as
begin
  /* insert into Contacts Table */
  if (exists (select * from @AddressImport where RecordAction = 'I' /* Insert */))
    insert into Contacts(ContactRefId,
                         ContactType,
                         Name,
                         AddressLine1,
                         AddressLine2,
                         AddressLine3,
                         City,
                         State,
                         Zip,
                         Country,
                         PhoneNo,
                         Email,
                         Reference1,
                         Reference2,
                         Residential,
                         ContactPerson,
                         ContactAddrId,
                         OrgAddrId,
                         AddressRegion,
                         BusinessUnit,
                         CreatedBy)
                  select ContactRefId,
                         ContactType,
                         Name,
                         AddressLine1,
                         AddressLine2,
                         AddressLine3,
                         City,
                         State,
                         Zip,
                         Country,
                         PhoneNo,
                         Email,
                         AddressReference1,
                         AddressReference2,
                         Residential,
                         ContactPerson,
                         ContactAddrId,
                         OrgAddrId,
                         case
                           when (Country in ('US', 'USA', 'UnitedStates', 'United States', 'US Of America')) then 'D' /* Domestic */
                           else 'I'  /* International */
                         end,
                         BusinessUnit,
                         coalesce(CreatedBy, system_user)
    from @AddressImport
    where (RecordAction = 'I' /* Insert */);

  /* Update Contacts Table */
  if (exists(select * from @AddressImport where RecordAction = 'U' /* Update */))
  begin
    update C
    set C.Name          = AI.Name,
        C.ContactType   = AI.ContactType,
        C.AddressLine1  = AI.AddressLine1,
        C.AddressLine2  = AI.AddressLine2,
        C.AddressLine3  = AI.AddressLine3,
        C.City          = AI.City,
        C.State         = AI.State,
        C.Zip           = AI.Zip,
        C.Country       = AI.Country,
        C.PhoneNo       = AI.PhoneNo,
        C.Email         = AI.Email,
        C.Reference1    = AI.AddressReference1,
        C.Reference2    = AI.AddressReference2,
        C.Residential   = AI.Residential,
        C.ContactPerson = AI.ContactPerson, /* These values are assigned the same */
        C.ContactAddrId = C.ContactAddrId,  /* since presently it is assumed that */
        C.OrgAddrId     = C.OrgAddrId,      /* new values are not sent */
        C.AddressRegion = C.AddressRegion,
        C.ModifiedDate  = current_timestamp,
        C.ModifiedBy    = case when (coalesce(C.ModifiedBy, '') <> '') then C.ModifiedBy else System_User end
    from @AddressImport AI
      join Contacts C on AI.ContactType  = C.ContactType and
                         AI.ContactRefId = C.ContactRefId and
                         AI.BusinessUnit = C.BusinessUnit and
                         AI.RecordAction = 'U' /* Update */
    where (coalesce(AI.Name, '')             <> coalesce(C.Name, ''))         or
          (coalesce(AI.AddressLine1, '')     <> coalesce(C.AddressLine1, '')) or
          (coalesce(AI.AddressLine2, '')     <> coalesce(C.AddressLine2, '')) or
          (coalesce(AI.AddressLine3, '')     <> coalesce(C.AddressLine3, '')) or
          (coalesce(AI.City, '')             <> coalesce(C.City, ''))         or
          (coalesce(AI.State, '')            <> coalesce(C.State, ''))        or
          (coalesce(AI.Zip, '')              <> coalesce(C.Zip, ''))          or
          (coalesce(AI.Country, '')          <> coalesce(C.Country, ''))      or
          (coalesce(AI.PhoneNo,'')           <> coalesce(C.PhoneNo,''))       or
          (coalesce(AI.Email,'')             <> coalesce(C.Email,''))         or
          (coalesce(AI.AddressReference1,'') <> coalesce(C.Reference1,''))    or
          (coalesce(AI.AddressReference2,'') <> coalesce(C.Reference2,''))    or
          (coalesce(AI.Residential,'')       <> coalesce(C.Residential,''))    or
          (coalesce(AI.ContactPerson,'')     <> coalesce(C.ContactPerson,'')) or
          (coalesce(AI.ContactAddrId,'')     <> coalesce(C.ContactAddrId,'')) or
          (coalesce(AI.OrgAddrId,'')         <> coalesce(C.OrgAddrId,''));
  end

  /* Check if Customer records exist which were either inserted or updated on Contacts table */
  if (exists(select *
            from @AddressImport AI
            where (AI.ContactType = 'C') and (AI.RecordAction in ('I','U'))))
  begin

    /* Update Customers Table if records exist */
    if (exists(select * from @AddressImport AI
                 join Customers C on AI.ContactRefId = C.CustomerId and
                                     AI.BusinessUnit = C.BusinessUnit
               where AI.ContactType  = 'C' /* Customer */))
    begin
      update C
      set
        C.CustomerName       = AI.Name,
        C.Status             = 'A' /* Active */,
        C.UDF1               = C.UDF1,  /* All UDF values are assigned the same */
        C.UDF2               = C.UDF2,  /* since presently */
        C.UDF3               = C.UDF3,  /* new values are not sent */
        C.UDF4               = C.UDF4,
        C.UDF5               = C.UDF5,
        C.ModifiedDate       = current_timestamp,
        C.ModifiedBy         = case when (coalesce(C.ModifiedBy, '') <> '') then C.ModifiedBy else System_User end
      from @AddressImport AI
        join Customers C on AI.ContactRefId = C.CustomerId and
                            AI.BusinessUnit = C.BusinessUnit
      where (AI.ContactType  = 'C' /* Customer */);
    end

    /* Insert Customers if exist */
    if (exists(select * from @AddressImport AI
                 left join Customers C on AI.ContactRefId = C.CustomerId and
                                          AI.BusinessUnit = C.BusinessUnit
               where coalesce(C.CustomerId, '') = '' and
                     AI.ContactType  = 'C' /* Customer */))
    begin

      /* CTE to fetch any records that exist for insert */
      with customersToInsert(ContactRefId, Name, ContactId,
                             BusinessUnit, CreatedBy, CreatedDate)
      as
      (
        select AI.ContactRefId, AI.Name, CN.ContactId,
               AI.BusinessUnit, CN.CreatedBy, CN.CreatedDate
        from @AddressImport AI
          left join Customers C on AI.ContactRefId = C.CustomerId and
                                   AI.BusinessUnit = C.BusinessUnit
          join Contacts CN on AI.ContactType  = CN.ContactType and
                              AI.ContactRefId = CN.ContactRefId and
                              AI.BusinessUnit = CN.BusinessUnit
        where (AI.ContactType  = 'C' /* Customer */) and
              (coalesce(C.CustomerId, '') = '')
      )

      insert into Customers(CustomerId,
                            CustomerName,
                            CustomerContactId,
                            CustomerBillToId,
                            Status,
                            UDF1,
                            UDF2,
                            UDF3,
                            UDF4,
                            UDF5,
                            BusinessUnit,
                            CreatedBy,
                            CreatedDate)
                    select  ContactRefId,
                            Name,
                            ContactId /* CustomerContactId */,
                            null /* BillToContactId */,
                            'A' /* Active */,
                            null /* UDF1 */,
                            null /* UDF2 */,
                            null /* UDF3 */,
                            null /* UDF4 */,
                            null /* UDF5 */,
                            BusinessUnit,
                            CreatedBy,
                            CreatedDate
      from customersToInsert;
    end

  end
end /* pr_Imports_AddOrUpdateAddresses */

Go
