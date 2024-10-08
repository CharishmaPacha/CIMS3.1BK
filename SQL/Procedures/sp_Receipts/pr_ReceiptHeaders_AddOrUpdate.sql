/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/04/08  TD      pr_ReceiptHeaders_AddOrUpdate:Changes to validate vendor based on control variable.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_AddOrUpdate') is not null
  drop Procedure pr_ReceiptHeaders_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_AddOrUpdate
  (@ReceiptNumber TReceiptNumber,
   @ReceiptType   TReceiptType,
   @Status        TStatus,
   @VendorId      TVendorId,
   @Ownership     TOwnership,
   @DateOrdered   TDateTime,
   @DateExpected  TDateTime,
   @UDF1          TUDF,
   @UDF2          TUDF,
   @UDF3          TUDF,
   @UDF4          TUDF,
   @UDF5          TUDF,
   @BusinessUnit  TBusinessUnit,
   -------------------------------
   @ReceiptId     TRecordId output,
   @CreatedDate   TDateTime output,
   @ModifiedDate  TDateTime output,
   @CreatedBy     TUserId   output,
   @ModifiedBy    TUserId   output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,
          @vValidateVendor   TControlValue;

  declare @Inserted table (ReceiptId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @ReturnCode      = 0,
         @MessageName     = null,
         @Status          = coalesce(@Status, 'I' /* Initial */),
         @vValidateVendor = dbo.fn_Controls_GetAsString('IMPORT_ASNLH', 'validateVendor', 'N' /*  No */, @BusinessUnit, '' /* UserId */);

  /* Validate ReceiptNumber */
  if (@ReceiptNumber is null)
    set @MessageName = 'ReceiptNumberIsInvalid';
  else
  if (@ReceiptType is null)
    set @MessageName = 'ReceiptTypeIsInvalid';
  else
  if (not exists(select *
                 from EntityTypes
                 where (TypeCode = @ReceiptType) and
                       (Entity   = 'Receipt') and
                       (Status   = 'A' /* Active */)))
    set @MessageName = 'ReceiptTypeDoesNotExist';
  else
  /* Validating VendorId */
  if (@vValidateVendor = 'Y') and
     (not exists(select VendorId
                 from Vendors
                 where (VendorId = @VendorId) and
                       (Status = 'A' /* Active */)))
    set @MessageName = 'VendorDoesNotExist';
  else
  if (@BusinessUnit is null)
    set @BusinessUnit = 'BusinessUnitIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (not exists(select *
                 from ReceiptHeaders
                 where ReceiptId = @ReceiptId))
    begin
      insert into ReceiptHeaders(ReceiptNumber,
                                 ReceiptType,
                                 Status,
                                 VendorId,
                                 Ownership,
                                 DateOrdered,
                                 DateExpected,
                                 UDF1,
                                 UDF2,
                                 UDF3,
                                 UDF4,
                                 UDF5,
                                 BusinessUnit,
                                 CreatedBy)
                          output inserted.ReceiptId, inserted.CreatedDate, inserted.CreatedBy
                            into @Inserted
                          select @ReceiptNumber,
                                 @ReceiptType,
                                 @Status,
                                 @VendorId,
                                 @Ownership,
                                 @DateOrdered,
                                 @DateExpected,
                                 @UDF1,
                                 @UDF2,
                                 @UDF3,
                                 @UDF4,
                                 @UDF5,
                                 @BusinessUnit,
                                 coalesce(@CreatedBy, system_user);

      select @ReceiptId   = ReceiptId,
             @CreatedDate = CreatedDate,
             @CreatedBy   = CreatedBy
      from @Inserted;
    end
  else
    begin
      update ReceiptHeaders
      set
        Status        = @Status,
        VendorId      = @VendorId,
        Ownership     = @Ownership,
        DateOrdered   = @DateOrdered,
        DateExpected  = @DateExpected,
        UDF1          = @UDF1,
        UDF2          = @UDF2,
        UDF3          = @UDF3,
        UDF4          = @UDF4,
        UDF5          = @UDF5,
        @ModifiedDate = ModifiedDate = current_timestamp,
        @ModifiedBy   = ModifiedBy   = coalesce(@ModifiedBy, system_user)
      where ReceiptId = @ReceiptId
    end

ErrorHandler:
  if (@MessageName is not null)
  begin
    select @Message = Description,
           @ReturnCode = 1
    from Messages
    where MessageName = @MessageName;

    raiserror(@Message, 16, 1);
  end

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_ReceiptHeaders_AddOrUpdate */

Go
