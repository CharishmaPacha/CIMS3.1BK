/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2010/10/26  VM      pr_ReceiptDetails_AddOrUpdate: CoE => CoO
  2010/10/08  PK      Validated Vendor in pr_POHeader_AddOrUpdate Procedure
                      Validated SKU in pr_ReceiptDetails_AddOrUpdate Procedure
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptDetails_AddOrUpdate') is not null
  drop Procedure pr_ReceiptDetails_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptDetails_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptDetails_AddOrUpdate
  (@ReceiptId         TRecordId,
   @ReceiptLine       TReceiptLine,
   @CoO               TCoO,
   @SKU               TSKU,
   @QtyOrdered        TQuantity,
   @QtyReceived       TQuantity,
   @LPNsReceived      TCount,
   @UnitCost          TCost,
   @UDF1              TUDF,
   @UDF2              TUDF,
   @UDF3              TUDF,
   @UDF4              TUDF,
   @UDF5              TUDF,
   @BusinessUnit      TBusinessUnit,
   -------------------------------
   @ReceiptDetailId   TRecordId output,
   @CreatedDate       TDateTime output,
   @ModifiedDate      TDateTime output,
   @CreatedBy         TUserId   output,
   @ModifiedBy        TUserId   output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription,

          @SKUId       TRecordId;

  declare @Inserted table (ReceiptDetailId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @ReturnCode = 0,
         @MessageName = null;

  /* Setting the SKUId of the SKU which has been entered and then inserting the
     SKUId into ReceiptDetails table */
  select @SKUId = SKUId
  from SKUs
  where SKU = @SKU

  /* Validate ReceiptId */
  if (@ReceiptId is null)
    set @MessageName = 'ReceiptIsInvalid';
  else
  /* Validate Receiptline */
  if (@ReceiptLine is null)
    set @MessageName = 'ReceiptLineIsInvalid';
  else
   /* Validate SKU */
  if (@SKU is null)
    set @MessageName = 'SKUIsInvalid';
  else
  if (@SKUId is null)
    set @MessageName = 'SKUDoesNotExist';
  else
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (not exists(select *
                 from ReceiptDetails
                 where ReceiptDetailId = @ReceiptDetailId))
    begin
      insert into ReceiptDetails(ReceiptId,
                                 ReceiptLine,
                                 CoO,
                                 SKUId,
                                 QtyOrdered,
                                 QtyReceived,
                                 LPNsReceived,
                                 UnitCost,
                                 UDF1,
                                 UDF2,
                                 UDF3,
                                 UDF4,
                                 UDF5,
                                 BusinessUnit,
                                 CreatedBy)
                          output inserted.ReceiptDetailId, inserted.CreatedDate, inserted.CreatedBy
                            into @Inserted
                          select @ReceiptId,
                                 @ReceiptLine,
                                 @CoO,
                                 @SKUId,
                                 @QtyOrdered,
                                 @QtyReceived,
                                 @LPNsReceived,
                                 @UnitCost,
                                 @UDF1,
                                 @UDF2,
                                 @UDF3,
                                 @UDF4,
                                 @UDF5,
                                 @BusinessUnit,
                                 coalesce(@CreatedBy, system_user);

      select @ReceiptDetailId = ReceiptDetailId,
             @CreatedDate     = CreatedDate,
             @CreatedBy       = CreatedBy
      from @Inserted;
    end
  else
    begin
      update ReceiptDetails
      set
        SKUId         = @SKUId,
        QtyOrdered    = @QtyOrdered,
        QtyReceived   = @QtyReceived,
        LPNsReceived  = @LPNsReceived,
        UnitCost      = @UnitCost,
        UDF1          = @UDF1,
        UDF2          = @UDF2,
        UDF3          = @UDF3,
        UDF4          = @UDF4,
        UDF5          = @UDF5,
        @ModifiedDate = ModifiedDate = current_timestamp,
        @ModifiedBy   = ModifiedBy   = coalesce(@ModifiedBy, System_User)
      where ReceiptDetailId = @ReceiptDetailId
    end

    exec @ReturnCode = pr_ReceiptHeaders_SetStatus @ReceiptId;

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_ReceiptDetails_AddOrUpdate */

Go
