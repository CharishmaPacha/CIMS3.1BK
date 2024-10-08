/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/16  VS      pr_Contacts_Copy: To copy contact from the another contacttype (OB2-638)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_Copy') is not null
  drop Procedure pr_Contacts_Copy;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_Copy: Copy the contact info from one contact to another. It copies
    the FromContactRefId-FromContactType to NewContactRefId-NewContactType.

  Used when an Order is only given ShipTo address or only given SoldTo address i.e.
    to copy from one to another
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_Copy
  (@FromContactRefId TContactRefId,
   @FromContactType  TContactType,
   @NewContactRefId  TContactRefId,
   @NewContactType   TContactType,
   @BusinessUnit     TBusinessUnit,
   @CreatedBy        TUserId = null)
as
begin
  SET NOCOUNT ON;

  /* If New contact does not exist, then create the new address with same info of FromContact */
  if not exists(select * from Contacts
                where (ContactRefId = coalesce(@NewContactRefId, @FromContactRefId)) and
                      (ContactType = coalesce(@NewContactType, @FromContactType)) and
                      (BusinessUnit = @BusinessUnit))
    insert into Contacts(ContactRefId, ContactType, Name, AddressLine1, AddressLine2, City, State, Country, Zip, PhoneNo, Email, Reference1, Reference2,
                         Residential, Status, ContactPerson, ContactAddrId, OrgAddrId, AddressRegion, UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit, CreatedBy)
      select coalesce(@NewContactRefId, @FromContactRefId), coalesce(@NewContactType, @FromContactType), Name, AddressLine1, AddressLine2, City, State, Country, Zip, PhoneNo, Email, Reference1, Reference2,
             Residential, Status, ContactPerson, ContactAddrId, OrgAddrId, AddressRegion, UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit, coalesce(@CreatedBy, System_User)
      from Contacts
      where (ContactType = @FromContactType) and (ContactRefId = @FromContactRefId) and (BusinessUnit = @BusinessUnit);
end /* pr_Contacts_Copy */

Go
