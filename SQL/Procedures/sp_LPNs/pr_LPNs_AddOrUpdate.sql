/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/02/17  VK      Changed the code of pr_LPNs_AddOrUpdate.So,that it validates
  2011/01/27  VM      pr_LPNs_Generate, pr_LPNs_AddOrUpdate:
  2010/10/18  SHR     pr_LPNs_AddOrUpdate: Changed input and output parameters,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_AddOrUpdate') is not null
  drop Procedure pr_LPNs_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_AddOrUpdate
  (@LPN              TLPN,
   @LPNType          TTypeCode,
   @Status           TStatus,

   @SKUId            TRecordId,
   @SKU              TSKU,
   @CoO              TCoO,

   @InnerPacks       TInnerPacks,
   @Quantity         TQuantity,

   @PalletId         TRecordId,
   @Pallet           TPallet,

   @LocationId       TRecordId,
   @Location         TLocation,
   @InventoryStatus  TInventoryStatus,
   @OnhandStatus     TStatus,
   @Ownership        TOwnership,

   @ReceiptId        TRecordId,
   @ReceiptNumber    TReceiptNumber,

   @OrderId          TRecordId,
   @PickTicket       TPickTicket,

   @ShipmentId       TShipmentId,
   @LoadId           TLoadId,
   @ASNCase          TASNCase,

   @UDF1             TUDF,
   @UDF2             TUDF,
   @UDF3             TUDF,
   @UDF4             TUDF,
   @UDF5             TUDF,

   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   -----------------------------------
   @LPNId            TRecordId output,
   @CreatedDate      TDateTime output,
   @ModifiedDate     TDateTime output,
   @CreatedBy        TUserId   output,
   @ModifiedBy       TUserId   output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @vSKUId      TRecordId,
          @Message     TDescription;

  declare @Inserted table (LPNDId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null;

  /* Validate LPN */
  if (@LPN is null)
    set @MessageName = 'LPNIsNull';
  else
  if (@LPNId is null) and
     (exists(select *
             from LPNs
             where LPN = @LPN))
    set @MessageName = 'LPNAlreadyExists';  /* trying to add an existing LPN */

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Validates SKU */
  select @SKUId  = SKUId,
         @vSKUId = SKUId
  from SKUs
  where (SKUId = @SKUId) or
        (SKU   = @SKU);

  if (@vSKUId is null)
    begin
      set @MessageName = 'SKUDoesNotExist';
      goto ErrorHandler;
    end

  /* Validates LocationId */
  if ((@LocationId is not null) or
      (@Location   is not null))
    begin
      select @LocationId = LocationId
      from Locations
      where (LocationId = @LocationId) or
            (Location   = @Location);

      if (@LocationId is null)
        set @MessageName = 'LocationDoesNotExist';
    end

  /* Validates ReceiptId */
  if ((@ReceiptId     is not null) or
      (@ReceiptNumber is not null))
    begin
      select @ReceiptId = ReceiptId
      from Receipts
      where (ReceiptId     = @ReceiptId) or
            (ReceiptNumber = @ReceiptNumber);

      if (@ReceiptId is null)
        set @MessageName = 'ReceiptDoesNotExist';
    end

  /* Validates OrderId */
  if ((@OrderId    is not null) or
      (@PickTicket is not null))
    begin
      select @OrderId = OrderId
      from Orders
      where (OrderId    = @OrderId) or
            (PickTicket = @PickTicket);

      if (@OrderId is null)
        set @MessageName = 'OrderDoesNotExist';
    end

  if (@MessageName is not null)
    goto ErrorHandler;

  if (not exists(select *
                 from SKUs
                 where SKUId = @SKUId))
    begin
      /* Insert LPN - Future use */
      return(coalesce(@ReturnCode, 0)); --Temporary
    end
  else
    begin
      update LPNs
      set
        SKUId           = coalesce(@SKUId, SKUId),
        CoO             = coalesce(@CoO, CoO),
        Status          = coalesce(@Status, Status),
        InnerPacks      = coalesce(@InnerPacks, InnerPacks),
        Quantity        = coalesce(@Quantity, Quantity),
        PalletId        = coalesce(@PalletId, PalletId),
        LocationId      = coalesce(@LocationId, LocationId),
        InventoryStatus = coalesce(@InventoryStatus, InventoryStatus),
        OnHandStatus    = coalesce(@OnHandStatus, OnHandStatus),
        Ownership       = coalesce(@Ownership, Ownership),
        ReceiptId       = coalesce(@ReceiptId, ReceiptId),
        OrderId         = coalesce(@OrderId, OrderId),
        ShipmentId      = coalesce(@ShipmentId, ShipmentId),
        LoadId          = coalesce(@LoadId, LoadId),
        ASNCase         = coalesce(@ASNCase, ASNCase),
        UDF1            = coalesce(@UDF1, UDF1),
        UDF2            = coalesce(@UDF2, UDF2),
        UDF3            = coalesce(@UDF3, UDF3),
        UDF4            = coalesce(@UDF4, UDF4),
        UDF5            = coalesce(@UDF5, UDF5),
        @ModifiedDate   = ModifiedDate    = current_timestamp,
        @ModifiedBy     = ModifiedBy      = coalesce(@ModifiedBy, System_User)
      where LPNId = @LPNId;
    end

  /* Recount LPN */
  exec @ReturnCode = pr_LPNs_Recount @LPNId, @ModifiedBy;

  if (@ReturnCode > 0)
    begin
      goto ExitHandler;
    end

ErrorHandler:
  exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_AddOrUpdate */

Go
