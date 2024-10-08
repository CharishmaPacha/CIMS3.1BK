/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this procedure exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

  2021/01/29  RKC     pr_Contacts_AddOrUpdateAddress: Pass the missed parameter to pr_Contacts_AddOrUpdateCustomer (BK-136)
  2019/08/29  RKC     pr_Contacts_AddOrUpdate, pr_Contacts_AddOrUpdateAddress, pr_Contacts_AddOrUpdateCustomer
                      fn_Contacts_GetShipToAddress, pr_Contacts_AddOrUpdateVendor:Pass the AddressLine3 (HPI-2711)
  2019/06/06  VS      pr_Contacts_AddOrUpdate: Get the Country code from Mappings if they given wrong country code (CID-502)
  2017/04/14  NB      pr_Contacts_AddOrUpdate: Minor correction to pr_Contacts_AddOrUpdate (CIMS-1289)
  2017/04/11  DK      pr_Contacts_AddOrUpdateVendor, pr_Contacts_AddOrUpdate, pr_Contacts_AddOrUpdateAddress
                      pr_Contacts_AddOrUpdateCustomer: Enahanced to insert Residential (CIMS-1289)
  2015/05/15  DK      pr_Contacts_AddOrUpdateVendor, pr_Contacts_AddOrUpdate
                      pr_Contacts_AddOrUpdateCustomer: Made changes to remove special characters while importing.
  2014/11/07  SK      pr_Contacts_AddOrUpdateCustomer: Corrections to a validation
  2014/11/06  SK      pr_Contacts_AddOrUpdateCustomer: pr_Contacts_AddOrUpdateVendor:
  2014/11/04  SK      pr_Contacts_AddOrUpdateAddress: Added
  2013/04/20  AY      pr_Contacts_AddOrUpdate: Duplicate addresses resolved for other contacts.
  2013/04/19  AY      pr_Contacts_AddOrUpdateCustomer: Prevent duplicate addresses for Customers.
  2013/03/29  VM/AKP  pr_Contacts_AddOrUpdateCustomer: Bug-fix: Fetch customer by CustomerId
  2012/07/30  SP      pr_Contacts_AddOrUpdateVendor: Pass Reference1 and Reference2 as well for "pr_Contacts_AddOrUpdate".
  2010/10/19  VM      pr_Contacts_AddOrUpdateCustomer,
                      pr_Contacts_AddOrUpdateVendor: Insert Contact details first
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_AddOrUpdate') is not null
  drop Procedure pr_Contacts_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_AddOrUpdate
  (@ContactRefId  TContactRefId,
   @ContactType   TContactType,
   @Name          TName,
   @ContactPerson TName,
   @AddressLine1  TAddressLine,
   @AddressLine2  TAddressLine,
   @AddressLine3  TAddressLine,
   @City          TCity,
   @State         TState,
   @Zip           TZip,
   @Country       TCountry,
   @PhoneNo       TPhoneNo,
   @Email         TEmailAddress,
   @Reference1    TDescription,
   @Reference2    TDescription,
   @Residential   TFlag,
   @ContactAddrId TRecordId,
   @OrgAddrId     TRecordId,
   @BusinessUnit  TBusinessUnit,
   -------------------------------
   @ContactId     TRecordId output,
   @CreatedDate   TDateTime output,
   @ModifiedDate  TDateTime output,
   @CreatedBy     TUserId   output,
   @ModifiedBy    TUserId   output)
as
  declare @vReturnCode  TInteger,
          @vMessageName TMessageName,
          @vMessage     TDescription,

          @vStatus      TStatus;

  declare @Inserted table (ContactId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vStatus      = 'A' /* Active */;

  /* Validate ContactType */
  if (@ContactType is null)
    set @vMessageName = 'ContactTypeIsInvalid';
  else
  /* Validate Name */
  if (@Name is null)
    set @vMessageName = 'ContactNameIsRequired';
  else
  /* Validate BusinessUnit */
  if (@BusinessUnit is null)
    set @vMessageName = 'BusinessUnitIsInvalid';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If no contact Id is given, then get it based upon contacttype, contactRefId */
  if (@ContactId is null)
    select @ContactId = ContactId
    from Contacts
    where (ContactType  = @ContactType) and
          (ContactRefId = @ContactRefId) and
          (BusinessUnit = @BusinessUnit);

  /* If country code is wrong then get from correct value from Mappings */
  if (not exists(select * from vwLookups where LookUpCode = @Country and LookUpCategory = 'Country'))
    select @Country = dbo.fn_GetMappedValue('CIMS', @Country /* Source Value */, 'CIMS' /* Target System */, 'Country' /* Entity Type */, null /* Operation */, @BusinessUnit);

  if (not exists(select * from Contacts where ContactId = @ContactId))
    begin
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
                    output inserted.ContactId, inserted.CreatedDate, inserted.CreatedBy
                      into @Inserted
                    select @ContactRefId,
                           @ContactType,
                           dbo.fn_RemoveSpecialChars(@Name),
                           dbo.fn_RemoveSpecialChars(@AddressLine1),
                           dbo.fn_RemoveSpecialChars(@AddressLine2),
                           dbo.fn_RemoveSpecialChars(@AddressLine3),
                           @City,
                           @State,
                           @Zip,
                           @Country,
                           @PhoneNo,
                           @Email,
                           dbo.fn_RemoveSpecialChars(@Reference1),
                           dbo.fn_RemoveSpecialChars(@Reference2),
                           @Residential,
                           @ContactPerson,
                           @ContactAddrId,
                           @OrgAddrId,
                           dbo.fn_Contacts_GetAddressRegion(@Country),
                           @BusinessUnit,
                           coalesce(@CreatedBy, system_user);

      select @ContactId   = ContactId,
             @CreatedBy   = CreatedBy,
             @CreatedDate = CreatedDate
      from @Inserted;
    end
  else
    begin
      update Contacts
      set
        Name          = dbo.fn_RemoveSpecialChars(@Name),
        ContactType   = @ContactType,
        AddressLine1  = dbo.fn_RemoveSpecialChars(@AddressLine1),
        AddressLine2  = dbo.fn_RemoveSpecialChars(@AddressLine2),
        AddressLine3  = dbo.fn_RemoveSpecialChars(@AddressLine3),
        City          = @City,
        State         = @State,
        Zip           = @Zip,
        Country       = @Country,
        PhoneNo       = @PhoneNo,
        Email         = @Email,
        Reference1    = dbo.fn_RemoveSpecialChars(@Reference1),
        Reference2    = dbo.fn_RemoveSpecialChars(@Reference2),
        Residential   = @Residential,
        ContactPerson = @ContactPerson,
        ContactAddrId = @ContactAddrId,
        OrgAddrId     = @OrgAddrId,
        AddressRegion = dbo.fn_Contacts_GetAddressRegion(@Country),
        @ModifiedDate = ModifiedDate = current_timestamp,
        @ModifiedBy   = ModifiedBy   = coalesce(@ModifiedBy, system_user)
      where (ContactId = @ContactId);
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Contacts_AddOrUpdate */

Go
