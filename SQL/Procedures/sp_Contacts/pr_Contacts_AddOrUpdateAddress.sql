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
  2017/04/11  DK      pr_Contacts_AddOrUpdateVendor, pr_Contacts_AddOrUpdate, pr_Contacts_AddOrUpdateAddress
  2014/11/04  SK      pr_Contacts_AddOrUpdateAddress: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_AddOrUpdateAddress') is not null
  drop Procedure pr_Contacts_AddOrUpdateAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_AddOrUpdateAddress:
    Motivation: Some clients wants to send contact info (it could be SoldTo address, ShipTo address etc)
      directly from the OrderHeader/ReceiptHeader interface, hence they might send the Ids or not,
      this wrapper procedures handles all the below situations.

      -> if they do not provide Ids, this creates Ids (SoldToId, ShipToId etc) and insert into contacts
      -> if they provide Ids, if it does not exists, it creates a new contact
      -> if they provide Ids, if it exists, it finds the difference in fields and
             - Updates existing contacts info, if there is any change in their contact info
             - otherwise, it skips, if there are no change in contact info
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_AddOrUpdateAddress
  (@ContactType    TContactType,
   @ContactRefId   TContactRefId output,

   @UniqueId       TContactRefId, /* It would be PT in case of Orders, ReceiptNumber in case of Sales Order/Receipt - To be used to generate a unique ContactRefId if not given */

   @Name           TName,
   @AddressLine1   TAddressLine,
   @AddressLine2   TAddressLine,
   @AddressLine3   TAddressLine,
   @City           TCity,
   @State          TState,
   @Country        TCountry,
   @Zip            TZip,
   @PhoneNo        TPhoneNo,
   @Email          TEmailAddress,
   @Reference1     TDescription,
   @Reference2     TDescription,
   @Residential    TFlag,
   @ContactPerson  TName,
   @ContactAddrId  TRecordId,
   @OrgAddrId      TRecordId,

   @UDF1           TUDF,
   @UDF2           TUDF,
   @UDF3           TUDF,
   @UDF4           TUDF,
   @UDF5           TUDF,
   @BusinessUnit   TBusinessUnit,
   -------------------------------------
   @CreatedDate    TDateTime output,
   @ModifiedDate   TDateTime output,
   @CreatedBy      TUserId   output,
   @ModifiedBy     TUserId   output)
as

declare  @ReturnCode       TInteger,
         @MessageName      TMessageName,
         @Message          TDescription,

         @vContactRefId    TContactRefId,
         @vContactId       TRecordId,
         @vName            TName,
         @vAddressLine1    TAddressLine,
         @vAddressLine2    TAddressLine,
         @vAddressLine3    TAddressLine,
         @vCity            TCity,
         @vState           TState,
         @vZip             TZip,
         @vCountry         TCountry,
         @vPhoneNo         TPhoneNo,
         @vEmail           TEmailAddress,
         @vReference1      TDescription,
         @vReference2      TDescription,
         @vResidential     TFlag,

         @vStatus          TStatus,
         @vInsertOrUpdate  TFlag;
begin
  SET NOCOUNT ON;

  select @ReturnCode      = 0,
         @MessageName     = null,
         @vContactRefId   = @ContactRefId,
         @vStatus         = 'A' /* Active */,
         @vInsertOrUpdate = 'N' /* No */;


  /* Check for ContactType value */
  if (coalesce(@ContactType,'') = '')
    select @MessageName = 'ContactTypeIsInvalid';
  else
  /* Check for UniqueId value */
  if (coalesce(@ContactRefId,'') = '') and (coalesce(@UniqueId,'') = '')
    select @MessageName = 'UniqueIdIsRequired';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Check to see if ContactRefId is given or generate it */
  if  (coalesce(@ContactRefId,'') = '')
    select @vInsertOrUpdate = 'Y' /* Yes  - No Id provided */,
           @vContactRefId = @UniqueId + @ContactType; /* Prepare ContactRefId, if it is not provided */
  else /* Check if record exists with differences */
  if (exists(select * from Contacts
             where ContactRefId = coalesce(@vContactRefId, '') and
                   ContactType  = @ContactType and
                   BusinessUnit = @BusinessUnit))
        begin
          select @vContactId = ContactId, @vName = Name,
                 @vAddressLine1 = AddressLine1, @vAddressLine2 = AddressLine2,
                 @vCity = City, @vState = State, @vCountry = Country, @vZip = Zip,
                 @vPhoneNo = PhoneNo, @vEmail = Email,
                 @vReference1 = Reference1, @vReference2 = Reference2, @vResidential = Residential
          from Contacts
          where ContactRefId = @vContactRefId and
                ContactType  = @ContactType and
                BusinessUnit = @BusinessUnit

          if ((@vName <> @Name) or (@vContactRefId <> @ContactRefId) or
              (@vAddressLine1 <> @AddressLine1) or (@vAddressLine2 <> @AddressLine2) or
              (@vCity <> @City) or (@vState <> @State) or (@vCountry <> @Country) or
              (@vPhoneNo <> @PhoneNo) or (@vEmail <> @Email) or
              (@vReference1 <> @Reference1) or (@vReference2 <> @Reference2) or (@vResidential <> @Residential))

            select @vInsertOrUpdate = 'Y'; /* Yes - Difference found */
        end
  else
    select @vInsertOrUpdate = 'Y'; /* This means caller sent a ContactRefId but that does not exist in cIMS, so insert as new */

  if (@vInsertOrUpdate = 'Y' /* Yes */)
    begin
      if (@ContactType = 'C' /* Customer */)
        exec @ReturnCode = pr_Contacts_AddOrUpdateCustomer @vContactRefId, @Name, @vStatus,
                                                           @vContactId output, @vContactRefId, @AddressLine1,
                                                           @AddressLine2, @AddressLine3, @City, @State, @Zip,
                                                           @Country, @PhoneNo, @Email, @Reference1,
                                                           @Reference2, @ContactPerson, @ContactAddrId,
                                                           @OrgAddrId,
                                                           /* billing fields */
                                                           null, null, null, null, null,
                                                           null, null, null, null, null,
                                                           null, null, null, null, null, null,
                                                           @UDF1, @UDF2, @UDF3, @UDF4, @UDF5,
                                                           @BusinessUnit, @vContactId output,
                                                           @CreatedDate output, @ModifiedDate  output,
                                                           @CreatedBy output, @ModifiedBy output

      else
      if (@ContactType = 'V' /* Vendor */)
        exec @ReturnCode = pr_Contacts_AddOrUpdateVendor @vContactRefId, @Name, @ContactPerson,
                                                         @vStatus, @vContactId output, @vContactRefId,
                                                         @AddressLine1, @AddressLine2, @AddressLine3, @City, @State,
                                                         @Zip, @Country, @PhoneNo, @Email,
                                                         @Reference1, @Reference2,
                                                         @ContactAddrId, @OrgAddrId, @BusinessUnit,
                                                         @vContactId output, @CreatedDate output,
                                                         @ModifiedDate  output, @CreatedBy output,
                                                         @ModifiedBy output

      else
        exec @ReturnCode = pr_Contacts_AddOrUpdate @vContactRefId, @ContactType,
                                                   @Name, @ContactPerson, @AddressLine1,
                                                   @AddressLine2, @AddressLine3, @City, @State, @Zip,
                                                   @Country, @PhoneNo, @Email,
                                                   @Reference1, @Reference2, @Residential, @ContactAddrId,
                                                   @OrgAddrId, @BusinessUnit,
                                                   @vContactId output, @CreatedDate output,
                                                   @ModifiedDate  output, @CreatedBy output,
                                                   @ModifiedBy output
      end

  if (@ReturnCode = 0)
     goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));

end /* pr_Contacts_AddOrUpdateAddress */

Go
