/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/29  RKC     pr_Contacts_AddOrUpdateAddress: Pass the missed parameter to pr_Contacts_AddOrUpdateCustomer (BK-136)
  2019/08/29  RKC     pr_Contacts_AddOrUpdate, pr_Contacts_AddOrUpdateAddress, pr_Contacts_AddOrUpdateCustomer
                      pr_Contacts_AddOrUpdateCustomer: Enahanced to insert Residential (CIMS-1289)
                      pr_Contacts_AddOrUpdateCustomer: Made changes to remove special characters while importing.
  2014/11/07  SK      pr_Contacts_AddOrUpdateCustomer: Corrections to a validation
  2014/11/06  SK      pr_Contacts_AddOrUpdateCustomer: pr_Contacts_AddOrUpdateVendor:
  2013/04/19  AY      pr_Contacts_AddOrUpdateCustomer: Prevent duplicate addresses for Customers.
  2013/03/29  VM/AKP  pr_Contacts_AddOrUpdateCustomer: Bug-fix: Fetch customer by CustomerId
  2010/10/19  VM      pr_Contacts_AddOrUpdateCustomer,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_AddOrUpdateCustomer') is not null
  drop Procedure pr_Contacts_AddOrUpdateCustomer;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_AddOrUpdateCustomer:
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_AddOrUpdateCustomer
  (@CustomerId           TCustomerId,
   @CustomerName         TName,
   @Status               TStatus,


   @CustomerContactId    TRecordId output,
   @CustContactRefId     TContactRefId,
   @CustAddressLine1     TAddressLine,
   @CustAddressLine2     TAddressLine,
   @CustAddressLine3     TAddressLine,
   @CustCity             TCity,
   @CustState            TState,
   @CustZip              TZip,
   @CustCountry          TCountry,
   @CustPhoneNo          TPhoneNo,
   @CustEmail            TEmailAddress,
   @CustReference1       TDescription,
   @CustReference2       TDescription,
   @CustContactPerson    TName,
   @CustContactAddrId    TRecordId,
   @CustOrgAddrId        TRecordId,

   @BillToContactId      TRecordId output,
   @BillToContactRefId   TContactRefId,
   @BillToAddressLine1   TAddressLine,
   @BillToAddressLine2   TAddressLine,
   @BillToAddressLine3   TAddressLine,
   @BillToCity           TCity,
   @BillToState          TState,
   @BillToZip            TZip,
   @BillToCountry        TCountry,
   @BillToPhoneNo        TPhoneNo,
   @BillToEmail          TEmailAddress,
   @BillToReference1     TDescription,
   @BillToReference2     TDescription,

   @BillToContactPerson  TName,
   @BillToContactAddrId  TRecordId,
   @BillToOrgAddrId      TRecordId,

   @UDF1                 TUDF,
   @UDF2                 TUDF,
   @UDF3                 TUDF,
   @UDF4                 TUDF,
   @UDF5                 TUDF,

   @BusinessUnit         TBusinessUnit,
   ---------------------------------------
   @RecordId             TRecordId output,
   @CreatedDate          TDateTime output,
   @ModifiedDate         TDateTime output,
   @CreatedBy            TUserId   output,
   @ModifiedBy           TUserId   output)
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
  if (@CustomerId is null)
    set @MessageName = 'CustomerIdIsInvalid';
  else
  /*  Validate CustomerName */
  if (@CustomerName is null)
    set @MessageName = 'CustomerNameIsInvalid';
  else
  /*  Validate BusinessUnit */
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Check if the customer addressses already exists, if they exist, then we will update the same address
     else we will create a new address */
  select @CustomerContactId = CustomerContactId,
         @BillToContactId   = CustomerBillToId
  from Customers
  where (CustomerId = @CustomerId);

  /* Customer Address Info - always insert or Update */
  exec @ReturnCode = pr_Contacts_AddOrUpdate @CustContactRefId,
                                             'C' /* Customer */,
                                             @CustomerName,
                                             @CustContactPerson,
                                             @CustAddressLine1,
                                             @CustAddressLine2,
                                             @CustAddressLine3,
                                             @CustCity,
                                             @CustState,
                                             @CustZip,
                                             @CustCountry,
                                             @CustPhoneNo,
                                             @CustEmail,
                                             @CustReference1,
                                             @CustReference2,
                                             null /* Residential */,
                                             @CustContactAddrId,
                                             @CustOrgAddrId,
                                             @BusinessUnit,
                                             @CustomerContactId output,
                                             @CreatedDate       output,
                                             @ModifiedDate      output,
                                             @CreatedBy         output,
                                             @ModifiedBy        output;

  if (@ReturnCode > 0)
    goto ExitHandler;

  /* Bill To Address Info - always insert or Update  */
  if (coalesce(@BillToContactRefId,'') <> '')
    exec @ReturnCode = pr_Contacts_AddOrUpdate @BillToContactRefId,
                                               'B' /* Bill To */,
                                               @CustomerName,
                                               @BillToContactPerson,
                                               @BillToAddressLine1,
                                               @BillToAddressLine2,
                                               @BillToAddressLine3,
                                               @BillToCity,
                                               @BillToState,
                                               @BillToZip,
                                               @BillToCountry,
                                               @BillToPhoneNo,
                                               @BillToEmail,
                                               @BillToReference1,
                                               @BillToReference2,
                                               null /* Residential */,
                                               @BillToContactAddrId,
                                               @BillToOrgAddrId,
                                               @BusinessUnit,
                                               @BillToContactId output,
                                               @CreatedDate     output,
                                               @ModifiedDate    output,
                                               @CreatedBy       output,
                                               @ModifiedBy      output;

  if (@ReturnCode > 0)
    goto ExitHandler;

/* SK_20141106 : The unique key constraint ukCustomers_id is based on CustomerId and BusinessUnit.
     Therefore the record exsitence check should be based on either RecordId or on both
     CustomerId and BusinessUnit */
  if (not exists(select *
                 from Customers
                 where (RecordId = @RecordId) or
                       (CustomerId = @CustomerId and BusinessUnit = @BusinessUnit)))
    begin
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
                     select @CustomerId,
                            dbo.fn_RemoveSpecialChars(@CustomerName),
                            @CustomerContactId,
                            @BillToContactId,
                            @Status,
                            @UDF1,
                            @UDF2,
                            @UDF3,
                            @UDF4,
                            @UDF5,
                            @BusinessUnit,
                            @CreatedBy,
                            @CreatedDate;

      set @RecordId = Scope_Identity();
    end
  else
    begin
      update Customers
      set
        CustomerName       = dbo.fn_RemoveSpecialChars(@CustomerName),
        Status             = @Status,
        UDF1               = @UDF1,
        UDF2               = @UDF2,
        UDF3               = @UDF3,
        UDF4               = @UDF4,
        UDF5               = @UDF5,
        @ModifiedDate      = ModifiedDate = current_timestamp,
        @ModifiedBy        = ModifiedBy   = coalesce(@ModifiedBy, system_user)
      where (RecordId = @RecordId) or
            (CustomerId = @CustomerId and BusinessUnit = @BusinessUnit);
     /* SK_20141106 : The unique key constraint ukCustomers_id is based on CustomerId and BusinessUnit.
     Therefore the record exsitence should be based on either RecordId or on both
     CustomerId and BusinessUnit */
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Contacts_AddOrUpdateCustomer */

Go
