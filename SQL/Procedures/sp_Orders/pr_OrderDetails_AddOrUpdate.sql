/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/12/06  VM      pr_OrderDetails_AddOrUpdate, pr_OrderHeaders_Recount (HPI-692):
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_AddOrUpdate') is not null
  drop Procedure pr_OrderDetails_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderDetails_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_AddOrUpdate
  (@OrderId                TRecordId,
   @OrderLine              TDetailLine,
   @HostOrderLine          THostOrderLine,
   @SKU                    TSKU,
   @UnitsOrdered           TQuantity,
   @UnitsAuthorizedToShip  TQuantity,
   @UnitsAssigned          TQuantity,
   @RetailUnitPrice        TRetailUnitPrice,
   @Lot                    TLot,
   @CustSKU                TCustSKU,
   @LocationId             TRecordId,
   @Location               TLocation,
   @UDF1                   TUDF,
   @UDF2                   TUDF,
   @UDF3                   TUDF,
   @UDF4                   TUDF,
   @UDF5                   TUDF,
   @BusinessUnit           TBusinessUnit,
   --------------------------------------------
   @OrderDetailId          TRecordId output,
   @CreatedDate            TDateTime output,
   @ModifiedDate           TDateTime output,
   @CreatedBy              TUserId   output,
   @ModifiedBy             TUserId   output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription,

          @SKUId       TRecordId;

  declare @Inserted table (OrderDetailId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @ReturnCode = 0,
         @MessageName = null;

  /* Setting the SKUId of the SKU which has been entered and then inserting the
     SKUId into OrderDetails table */
  select @SKUId = SKUId
  from SKUs
  where SKU = @SKU

  /* Validate OrderId */
  if(@OrderId is null)
    set @MessageName = 'OrderIsInvalid'
  else
  if(@OrderLine is null)
    set @MessageName = 'OrderLineIsInvalid'
  else
  if(@HostOrderLine is null)
    set @MessageName = 'HostOrderLineIsInvalid'
  else
  /* Validates SKU */
  if(@SKU is null)
    set @MessageName = 'SKUIsInvalid';
  else
  if(@SKUId is null)
    set @MessageName = 'SKUDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (not exists(select *
                 from OrderDetails
                 where OrderDetailId = @OrderDetailId))
    begin
      insert into OrderDetails(OrderId,
                               OrderLine,
                               HostOrderLine,
                               SKUId,
                               UnitsOrdered,
                               UnitsAuthorizedToShip,
                               UnitsAssigned,
                               RetailUnitPrice,
                               Lot,
                               CustSKU,
                               LocationId,
                               Location,
                               UDF1,
                               UDF2,
                               UDF3,
                               UDF4,
                               UDF5,
                               BusinessUnit,
                               CreatedBy)
                        output inserted.OrderDetailId, inserted.CreatedDate, inserted.CreatedBy
                          into @Inserted
                        select @OrderId,
                               @OrderLine,
                               @HostOrderLine,
                               @SKUId,
                               @UnitsOrdered,
                               @UnitsAuthorizedToShip,
                               dbo.fn_MaxInt(@UnitsAssigned, 0),
                               @RetailUnitPrice,
                               @Lot,
                               @CustSKU,
                               @LocationId,
                               @Location,
                               @UDF1,
                               @UDF2,
                               @UDF3,
                               @UDF4,
                               @UDF5,
                               @BusinessUnit,
                               coalesce(@CreatedBy, system_user);

      select @OrderDetailId = OrderDetailId,
             @CreatedDate   = CreatedDate,
             @CreatedBy     = CreatedBy
      from @Inserted;
    end
  else
    begin
      update OrderDetails
      set
        SKUId                 = @SKUId,
        UnitsOrdered          = @UnitsOrdered,
        UnitsAuthorizedToShip = @UnitsAuthorizedToShip,
        UnitsAssigned         = dbo.fn_MaxInt(@UnitsAssigned, 0),
        RetailUnitPrice       = @RetailUnitPrice,
        Lot                   = @Lot,
        CustSKU               = @CustSKU,
        LocationId            = @LocationId,
        Location              = @Location,
        UDF1                  = @UDF1,
        UDF2                  = @UDF2,
        UDF3                  = @UDF3,
        UDF4                  = @UDF4,
        UDF5                  = @UDF5,
        @ModifiedDate         = ModifiedDate = current_timestamp,
        @ModifiedBy           = ModifiedBy   = coalesce(@ModifiedBy, system_user)
      where OrderDetailId = @OrderDetailId
    end

ErrorHandler:
  if (@MessageName is not null)
  begin
    select @Message    = dbo.fn_Messages_GetDescription(@MessageName),
           @ReturnCode = 1;
    raiserror(@Message, 16, 1);
  end

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_OrderDetails_AddOrUpdate */

Go
