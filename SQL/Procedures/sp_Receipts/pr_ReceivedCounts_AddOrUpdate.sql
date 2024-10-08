/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/09  MS      pr_Receipts_Action_PrepareForSortation: Code optimized and cleanup (JL-286, JL-287)
                      pr_Receipts_Action_ActivateRouting: Changes to create receivers (JL-286, JL-287)
                      pr_Receipts_CreateReceivers: Added new proc to create receivers for given LPNs (JL-286, JL-287)
                      pr_Receipts_UnPalletize: Corrections to send RouteLPN aswell, to be in consistent with #RouterLPNs activated earlier
                      pr_ReceivedCounts_AddOrUpdate: Changes to update ReceiverNumber on existing ReceivedCounts (JL-286, JL-287)
  2020/06/30  SK      pr_ReceivedCounts_AddOrUpdate: Request for Receiver update count if Receiver has >1 receipts (HA-392)
  2020/04/18  TK      pr_Receipts_ReceiveInventory: Don't override status of picklane LPN when inventory is received
                      pr_ReceivedCounts_AddOrUpdate: Changes to update received counts properly when receiving inventoty to Location (HA-222)
  2018/06/21  SV      pr_Receipts_ReceiveSKUs, pr_ReceivedCounts_AddOrUpdate: In case of ReceiveInv action from UI, we are not passing Receiver# currently.
                        Hence using the AUTO create receiver to associate the receiver# while receiving the Inv (OB2-99)
  2018/06/11  TK      pr_ReceivedCounts_AddOrUpdate: If Receiver/Receipt info is not passed in, then get the information from LPN (S2GCA-52)
  2018/06/08  PK/AY/  Added pr_ReceivedCounts_AddOrUpdate.(S2G-879)
              SV      pr_Receipts_ReceiveInventory, pr_Receipts_UI_ReceiveToLPN:
                        Added Caller pr_ReceivedCounts_AddOrUpdate.
                      pr_Receipts_ReceiveInventory: Added new input param ReceiverId (S2G-879)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceivedCounts_AddOrUpdate') is not null
  drop Procedure pr_ReceivedCounts_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceivedCounts_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceivedCounts_AddOrUpdate
  (@LPNId             TRecordId,
   @LPNDetailId       TRecordId,
   @InnerPacks        TInnerPacks,
   @Quantity          TQuantity,
   @ReceiptId         TRecordId = null,
   @ReceiverId        TRecordId = null,
   @ReceiptDetailId   TRecordId = null,
   @PalletId          TRecordId = null,
   @LocationId        TRecordId = null,
   @SKUId             TRecordId = null,
   @UpdateOption      TFlag     = '=', /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty */
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @Status            TStatus   = 'A' /* Active */,
   -------------------------------------------
   @RecvCountRecordId TRecordId = null output)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,
          @vRecordId         TRecordId,
          /* Key entities */
          @vSKU              TSKU,
          @vLPN              TLPN,
          @vPallet           TPallet,
          @vLocation         TLocation,
          @vReceiptNumber    TReceiptNumber,
          @vReceiverNumber   TReceiverNumber,
          @vReceiptDetailId  TRecordId,
          @vReceiptLine      TReceiptLine,
          @vOwnership        TOwnership,
          @vWarehouse        TWarehouse,
          @vNewInnerPacks    TInnerPacks,
          @vNewQuantity      TQuantity,
          @vUnitsPerPackage  TInteger;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @Status       = coalesce(@Status, 'A' /* Active */),
         @InnerPacks   = coalesce(@InnerPacks, 0);

 /* Get the LPN info */
  select @vLPN       = LPN,
         @vWarehouse = DestWarehouse,
         @vOwnership = Ownership,
         @ReceiptId  = coalesce(@ReceiptId, ReceiptId),
         @ReceiverId = coalesce(@ReceiverId, ReceiverId)
  from LPNs
  where (LPNId = @LPNId);

  /* Get the UnitsPerPackage info from the LPNDetail line */
  select @vUnitsPerPackage = UnitsPerPackage,
         @SKUId            = coalesce(@SKUId, SKUId),
         @ReceiptDetailId  = coalesce(@ReceiptDetailId, ReceiptDetailId)
  from LPNDetails
  where (LPNDetailId  = @LPNDetailId) and
        (LPNId        = @LPNId);

  /* Get the Receipt info */
  select @vReceiptNumber = ReceiptNumber
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  /* Get Receipt Detail info */
  select @vReceiptDetailId = ReceiptDetailId,
         @vReceiptLine     = ReceiptLine
  from ReceiptDetails
  where (ReceiptDetailId = @ReceiptDetailId);

  /* Get the Pallet info */
  select @vPallet = Pallet
  from Pallets
  where (PalletId = @PalletId);

  /* Get the Location info */
  select @vLocation = Location
  from Locations
  where (LocationId = @LocationId);

  /* Get the SKU info */
  select @vSKU = SKU
  from SKUs
  where (SKUId = @SKUId);

  /* Get Receiver info */
  if (@ReceiverId is not null)
    select @vReceiverNumber = ReceiverNumber
    from Receivers
    where (ReceiverId = @ReceiverId);

  /* Identify if the record already exists for the LPN Detail Id */
  /* While receiving inventory to a picklane location but if there exists available inventory in the location
     which was received against other receipt then we will just update the quantity on the available line instead
     of creating a new line so we cannot update the received counts that was created for other receipt detail */
  select @RecvCountRecordId = RecordId
  from ReceivedCounts
  where (LPNDetailId     = @LPNDetailId) and
        (ReceiptDetailId = @ReceiptDetailId);

  /* Validations of input params. If given, make sure they are valid.
     For Updates, all inputs are not given, so we shouldn't validate.
     For insert, we ensure that required ones are given */
  if (@RecvCountRecordId is null) and
     (@vReceiptNumber is null or @vReceiptDetailId is null or @vSKU is null or @vLPN is null or
      @vReceiverNumber is null)
    set @vMessageName = 'RecvCount_MissingInputs';
  else
  if (@ReceiptId is not null) and (@vReceiptNumber is null)
    set @vMessageName = 'ReceiptIsInvalid';
  else
  if (@ReceiptDetailId is not null) and (@vReceiptDetailId is null)
    set @vMessageName = 'ReceiptLineIsInvalid';
  else
  if (@SKUId is not null) and (@vSKU is null)
    set @vMessageName = 'SKUIsInvalid';
  else
  if (@LPNId is not null) and (@vLPN is null)
    set @vMessageName = 'LPNIsInvalid';
  else
  if (@ReceiverId is not null) and (@vReceiverNumber is null)
    set @vMessageName = 'ReceiverIsInvalid';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If the record doesn't exist then insert one */
  if (@RecvCountRecordId is null)
    begin
      insert into ReceivedCounts(ReceiptId,  ReceiptNumber,
                                 ReceiverId, ReceiverNumber,
                                 ReceiptDetailId, ReceiptLine,
                                 Status,
                                 PalletId, Pallet,
                                 LocationId, Location,
                                 LPNId,LPN,LPNDetailId,
                                 SKUId, SKU,
                                 InnerPacks, Quantity,
                                 UnitsPerPackage,
                                 Ownership, Warehouse, BusinessUnit,
                                 CreatedBy)
                          select @ReceiptId, @vReceiptNumber,
                                 @ReceiverId, @vReceiverNumber,
                                 @ReceiptDetailId, @vReceiptLine,
                                 @Status,
                                 @PalletId, @vPallet,
                                 @LocationId, @vLocation,
                                 @LPNId, @vLPN,@LPNDetailId,
                                 @SKUId, @vSKU,
                                 @InnerPacks, @Quantity, @vUnitsPerPackage,
                                 @vOwnership, @vWarehouse, @BusinessUnit,
                                 coalesce(@UserId, system_user);

      select @RecvCountRecordId = Scope_identity();

      /* Update receiver related info when multiple receipts are linked with receivers */
      if ((select count (distinct ReceiptId) from ReceivedCounts where ReceiverId = @ReceiverId) > 1)
        exec pr_Receivers_Recalculate @ReceiverId, '$C' /* deferred count */, @BusinessUnit;
    end
  else
    begin
      update ReceivedCounts
      set
        @vNewInnerPacks =
        InnerPacks      = case @UpdateOption
                            when '=' /* Exact */ then
                              @InnerPacks
                            when '+' /* Add */ then
                              (InnerPacks + @InnerPacks)
                            when '-' /* Subtract */ then
                              (InnerPacks - @InnerPacks)
                          end,
        @vNewQuantity   =
        Quantity        = case @UpdateOption
                            when '=' /* Exact */ then
                              @Quantity
                            when '+' /* Add */ then
                              (Quantity + @Quantity)
                            when '-' /* Subtract */ then
                              (Quantity - @Quantity)
                          end,
       UnitsPerPackage  = @vUnitsPerPackage,
       ReceiverId       = @ReceiverId,
       ReceiverNumber   = @vReceiverNumber,
       ModifiedDate     = current_timestamp,
       ModifiedBy       = coalesce(@UserId, system_user)
      where (RecordId = @RecvCountRecordId);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ReceivedCounts_AddOrUpdate */

Go
