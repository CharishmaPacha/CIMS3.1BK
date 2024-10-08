/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/19  SAK     pr_Imports_Contacts: Strip off 'ext' and '+1' from phone number (OBV3-452)
                      pr_Imports_Contacts:Added AddressLine3
                      pr_Imports_ContactsClearDuplicates :Added AddressLine3
  2017/04/11  DK      pr_Imports_OrderHeaders, pr_Imports_OrderHeaders_Addresses, pr_Imports_AddOrUpdateAddresses, pr_Imports_ContactsClearDuplicates,
                      pr_Imports_Contacts: Enahanced to insert Residential, ShipToResidential and DeliveryRequirement(CIMS-1289)
                      pr_Imports_ContactsClearDuplicates: Added to remove duplicates for Contacts. (LL-206)
  2012/07/30  SP      pr_Imports_Contacts: Moved the "Contact Person" parameter to the appropriate position for pr_Contacts_AddOrUpdateVendor.
  2012/07/29  VM      pr_Imports_Contacts: Pass the exact params for pr_Contacts_AddOrUpdateCustomer
  2012/06/27  NY      pr_Imports_Contacts: Made Changes to procedure by calling sub procedures based
                      & pr_Imports_Contacts: Revised import procedures to import
  2011/07/12  PK      Created pr_Imports_Contacts, pr_Imports_ValidateContact.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_Contacts') is not null
  drop Procedure pr_Imports_Contacts;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_Contacts
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_Contacts
  (@xmlData                    Xml,
   @Action                     TFlag           = null,
   @ContactRefId               TContactRefId   = null,
   @ContactType                TContactType    = null,
   @Name                       TName           = null,
   @AddressLine1               TAddressLine    = null,
   @AddressLine2               TAddressLine    = null,
   @AddressLine3               TAddressLine    = null,
   @City                       TCity           = null,
   @State                      TState          = null,
   @Country                    TCountry        = null,
   @Zip                        TZip            = null,
   @PhoneNo                    TPhoneNo        = null,
   @Email                      TEmailAddress   = null,
   @Reference1                 TDescription    = null,
   @Reference2                 TDescription    = null,
   @Residential                TFlag           = null,
   @ContactPerson              TName           = null,
   @PrimaryContactRefId        TContactRefId   = null,
   @OrganizationContactRefId   TContactRefId   = null,
   @ContactAddrId              TRecordId       = null,
   @OrgAddrId                  TRecordId       = null,
   @BusinessUnit               TBusinessUnit   = null,
   @CreatedDate                TDateTime       = null,
   @ModifiedDate               TDateTime       = null,
   @CreatedBy                  TUserId         = null,
   @ModifiedBy                 TUserId         = null,
   @HostRecId                  TRecordId       = null
  )
as
  declare @vReturnCode         TInteger,
          @vContactAddrId      TRecordId,
          @vOrgAddrId          TRecordId,
          @Status              TStatus,
          @ContactId           TRecordId;
begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  if (@xmlData is not null)
    begin
      select @PrimaryContactRefId      = Record.Col.value('PrimaryContactRefId[1]', 'TContactRefId'),
             @OrganizationContactRefId = Record.Col.value('OrganizationContactRefId[1]', 'TContactRefId')
      from @xmlData.nodes('/Record') as Record(Col);
    end

  select @vContactAddrId = ContactId
  from Contacts
  where (ContactRefId = @PrimaryContactRefId);

  select @vOrgAddrId = ContactId
  from Contacts
  where (ContactRefId = @OrganizationContactRefId);

  /* Create a temp table based on table Contacts into which to insert our xml values */
  select * into #Contacts from Contacts where 1 = 0;

  /* Populate the temp table */
  if (@xmlData is not null)
    begin
      select   @Action                    = Record.Col.value('Action[1]', 'TFlag'),
               @ContactRefId              = Record.Col.value('ContactRefId[1]', 'TContactRefId'),
               @ContactType               = Record.Col.value('ContactType[1]', 'TContactType'),
               @Name                      = Record.Col.value('Name[1]', 'TName'),
               @AddressLine1              = Record.Col.value('AddressLine1[1]', 'TAddressLine'),
               @AddressLine2              = Record.Col.value('AddressLine2[1]', 'TAddressLine'),
               @AddressLine3              = Record.Col.value('AddressLine3[1]', 'TAddressLine'),
               @City                      = Record.Col.value('City[1]', 'TCity'),
               @State                     = Record.Col.value('State[1]', 'TState'),
               @Country                   = Record.Col.value('Country[1]', 'TCountry'),
               @Zip                       = Record.Col.value('Zip[1]', 'TZip'),
               @PhoneNo                   = Record.Col.value('PhoneNo[1]', 'TPhoneNo'),
               @Email                     = Record.Col.value('Email[1]', 'TEmailAddress'),
               @Reference1                = Record.Col.value('Reference1[1]', 'TDescription'),
               @Reference2                = Record.Col.value('Reference2[1]', 'TDescription'),
               @Residential               = Record.Col.value('Residential[1]', 'TFlag'),
               @Status                    = 'A',/* As it cant be null we are updating it directly here with default value */
               @ContactPerson             = Record.Col.value('ContactPerson[1]', 'TName'),
               @PrimaryContactRefId       = Record.Col.value('PrimaryContactRefId[1]', 'TContactRefId'),
               @OrganizationContactRefId  = Record.Col.value('OrganizationContactRefId[1]', 'TContactRefId'),
               @BusinessUnit              = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
               @CreatedDate               = nullif(Record.Col.value('CreatedDate[1]', 'TDateTime'), ''),
               @ModifiedDate              = nullif(Record.Col.value('ModifiedDate[1]', 'TDateTime'), ''),
               @CreatedBy                 = Record.Col.value('CreatedBy[1]', 'TUserId'),
               @ModifiedBy                = Record.Col.value('ModifiedBy[1]', 'TUserId'),
               @HostRecId                 = Record.Col.value('RecordId[1]', 'TRecordId')
      from @xmlData.nodes('//msg/msgBody/Record') as Record(Col)

    end

  exec @vReturnCode = pr_Imports_ValidateContact @Action output,
                                                 @ContactRefId,
                                                 @ContactType,
                                                 @BusinessUnit;

  /* If the action is X then do nothing. */
  if (@Action = 'X' /* DoNothing */)
    return;

  /* If any errors then return to the caller */
  if (@vReturnCode > 0)
    return;

  /* Insert, Update or Delete based on Action */
  if (@Action = 'I' /* Insert */ or @Action = 'U') and (@ContactType = 'C')
    exec @vReturnCode = pr_Contacts_AddOrUpdateCustomer @ContactRefId ,
                                                        @Name,
                                                        @Status,

                                                        @ContactId             output,
                                                        @ContactRefId,
                                                        @AddressLine1,
                                                        @AddressLine2,
                                                        @AddressLine3,
                                                        @City,
                                                        @State,
                                                        @Zip,
                                                        @Country,
                                                        @PhoneNo,
                                                        @Email,
                                                        @Reference1,
                                                        @Reference2,

                                                        @ContactPerson,
                                                        @ContactAddrId,
                                                        @OrgAddrId ,

                                                        /* Bill To Address */
                                                        null, null, null, null, null, null,
                                                        null, null, null, null, null, null,
                                                        null, null, null, null, null, null,
                                                        null, null, null,

                                                        @BusinessUnit,
                                                        @ContactId             output,
                                                        @CreatedDate           output,
                                                        @ModifiedDate          output,
                                                        @CreatedBy             output,
                                                        @ModifiedBy            output;
  else
  if (@Action = 'I' /* Insert */ or @Action = 'U') and (@ContactType = 'V')
      exec @vReturnCode= pr_Contacts_AddOrUpdateVendor @ContactRefId ,
                                                       @Name,
                                                       @ContactPerson,
                                                       @Status,

                                                       @ContactId             output,
                                                       @ContactRefId,
                                                       @AddressLine1,
                                                       @AddressLine2,
                                                       @AddressLine3,
                                                       @City,
                                                       @State,
                                                       @Zip,
                                                       @Country,
                                                       @PhoneNo,
                                                       @Email,
                                                       @Reference1,
                                                       @Reference2,

                                                       @ContactAddrId,
                                                       @OrgAddrId ,

                                                       @BusinessUnit,
                                                       @ContactId             output,
                                                       @CreatedDate           output,
                                                       @ModifiedDate          output,
                                                       @CreatedBy             output,
                                                       @ModifiedBy            output;
  else
  if (@Action = 'I' /* Insert */ or @Action = 'U')
    exec @vReturnCode = pr_Contacts_AddOrUpdate @ContactRefId,
                                                @ContactType,
                                                @Name ,
                                                @ContactPerson,
                                                @AddressLine1,
                                                @AddressLine2,
                                                @AddressLine3,
                                                @City,
                                                @State,
                                                @Zip,
                                                @Country,
                                                @PhoneNo,
                                                @Email,
                                                @Reference1,
                                                @Reference2,
                                                @Residential,
                                                @ContactAddrId,
                                                @OrgAddrId,
                                                @BusinessUnit,

                                                @ContactId     output,
                                                @CreatedDate   output,
                                                @ModifiedDate  output,
                                                @CreatedBy     output,
                                                @ModifiedBy    output;
  else
  if (@Action = 'D' /* Delete */)
    begin
      if (@ContactType = 'C')
        exec pr_Contacts_DeleteCustomer @ContactRefId;
      else
      if (@ContactType = 'V')
        exec pr_Contacts_DeleteVendor @ContactRefId;
      else
        exec pr_Contacts_Delete @ContactRefId;
    end

end /* pr_Imports_Contact */

Go
