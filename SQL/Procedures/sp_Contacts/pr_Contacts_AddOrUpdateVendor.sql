/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/29  RKC     pr_Contacts_AddOrUpdate, pr_Contacts_AddOrUpdateAddress, pr_Contacts_AddOrUpdateCustomer
                      fn_Contacts_GetShipToAddress, pr_Contacts_AddOrUpdateVendor:Pass the AddressLine3 (HPI-2711)
  2017/04/11  DK      pr_Contacts_AddOrUpdateVendor, pr_Contacts_AddOrUpdate, pr_Contacts_AddOrUpdateAddress
  2015/05/15  DK      pr_Contacts_AddOrUpdateVendor, pr_Contacts_AddOrUpdate
                      pr_Contacts_AddOrUpdateCustomer: Made changes to remove special characters while importing.
  2014/11/06  SK      pr_Contacts_AddOrUpdateCustomer: pr_Contacts_AddOrUpdateVendor:
                        Enhancement to include constraint pair check for record existence.
  2012/07/30  SP      pr_Contacts_AddOrUpdateVendor: Pass Reference1 and Reference2 as well for "pr_Contacts_AddOrUpdate".
                      pr_Contacts_AddOrUpdateVendor: Insert Contact details first
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_AddOrUpdateVendor') is not null
  drop Procedure pr_Contacts_AddOrUpdateVendor;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_AddOrUpdateVendor:
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_AddOrUpdateVendor
  (@VendorId               TCustomerId,
   @VendorName             TName,
   @ContactPerson          TName,
   @Status                 TStatus,

   @VendorContactId        TRecordId output,
   @VendorContactRefId     TContactRefId,
   @AddressLine1           TAddressLine,
   @AddressLine2           TAddressLine,
   @AddressLine3           TAddressLine,
   @City                   TCity,
   @State                  TState,
   @Zip                    TZip,
   @Country                TCountry,
   @PhoneNo                TPhoneNo,
   @Email                  TEmailAddress,
   @Reference1             TDescription,
   @Reference2             TDescription,
   @ContactAddrId          TRecordId,
   @OrgAddrId              TRecordId,

   @BusinessUnit           TBusinessUnit,
   ----------------------------------------
   @RecordId               TRecordId output,
   @CreatedDate            TDateTime output,
   @ModifiedDate           TDateTime output,
   @CreatedBy              TUserId   output,
   @ModifiedBy             TUserId   output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription;
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @Status      = coalesce(@Status, 'A' /* Active */);

  /*  Validate CustomerId */
  if (@VendorId is null)
    set @MessageName = 'VendorIdIsInvalid';
  else
  /*  Validate CustomerName */
  if (@VendorName is null)
    set @MessageName = 'VendorNameIsInvalid';
  else
  /*  Validate BusinessUnit */
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Vendor Details */
  exec @ReturnCode = pr_Contacts_AddOrUpdate @VendorContactRefId,
                                             'V' /* Vendor */,
                                             @VendorName,
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
                                             null /* Residential */,
                                             @ContactAddrId,
                                             @OrgAddrId,
                                             @BusinessUnit,
                                             @VendorContactId output,
                                             @CreatedDate     output,
                                             @ModifiedDate    output,
                                             @CreatedBy       output,
                                             @ModifiedBy      output;

  if (@ReturnCode > 0)
    goto ExitHandler;

  /* SK_20141106 : The unique key constraint ukVendors_Id is based on VendorId and BusinessUnit.
     Therefore the record exsitence check should be based on either RecordId or on both
     VendorId and BusinessUnit */
  if (not exists(select *
                 from Vendors
                 where (RecordId = @RecordId) or
                       (VendorId = @VendorContactRefId and BusinessUnit = @BusinessUnit)))
    begin
      insert into Vendors(VendorId,
                          VendorName,
                          VendorContactId,
                          Status,
                          BusinessUnit,
                          CreatedBy,
                          CreatedDate)
                   select @VendorId,
                          dbo.fn_RemoveSpecialChars(@VendorName),
                          @VendorContactId,
                          @Status,
                          @BusinessUnit,
                          @CreatedBy,
                          @CreatedDate;

      set @RecordId = Scope_Identity();
    end
  else
    begin
      update Vendors
      set
        VendorName    = dbo.fn_RemoveSpecialChars(@VendorName),
        Status        = @Status,
        @ModifiedDate = ModifiedDate = current_timestamp,
        @ModifiedBy   = ModifiedBy   = coalesce(@ModifiedBy, system_user)
      where (RecordId = @RecordId) or
            (VendorId = @VendorContactRefId and BusinessUnit = @BusinessUnit)
     /* SK_20141106 : The unique key constraint ukVendors_Id is based on VendorId and BusinessUnit.
     Therefore the record exsitence check should be based on either RecordId or on both
     VendorId and BusinessUnit */
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Contacts_AddOrUpdateVendor */

Go
