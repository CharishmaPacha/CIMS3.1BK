/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  SK      pr_LPNs_AddSKU: fix as the function returns table (HA-1841)
  2020/05/01  RIA     pr_LPNDetails_AddOrUpdate, pr_LPNs_AddSKU: Changes to update InnerPacks (CIMSV3-812)
  2019/11/12  TK      pr_LPNs_AddSKU: Bug Fix in updating Innerpacks on the LPN (S2G-1348)
  2015/03/31  DK      pr_LPNs_AddSKU: Updated the condition with additional reasoncode to restrict adding multiple SKUs.
  2013/04/29  AY      pr_LPNs_AddSKU: Allow Carts to have multiple SKUs
  2012/02/12  PKS     Pallet count updation done in pr_LPNs_AddSKU procedure
  2011/03/05  VM      pr_LPNs_AddSKU: Restrict adding multiple SKUs to same LPN
  2010/12/03  VM      pr_LPNs_AdjustQty, pr_LPNs_AddSKU, pr_LPNs_Move:
  2010/11/22  VM      pr_LPNs_AdjustQty, pr_LPNs_AddSKU, pr_LPNs_Generate, pr_LPNs_Recount: Procedures completed
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_AddSKU') is not null
  drop Procedure pr_LPNs_AddSKU;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_AddSKU:
  This procedure assumes that the LPN is validated with below validations
    before calling this proc.
    1. Valid LPN
    2. Valid LPN Status
    3. Valid LPN Location

  User might give a new SKU or an existing SKU
  - if an existing SKU is given, it will just update the Qty of it
  otherwise, it will raise an error. */
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_AddSKU
  (@LPNId            TRecordId,
   @LPN              TLPN,
   @SKUId            TRecordId,
   @SKU              TSKU,
   @InnerPacks       TInnerPacks, /* ##VM - if this is going to be used when called RFC,
                                            RFC has to be changed to pass this as well
                                          - Currently not doing it - Future Use */
   @Quantity         TQuantity,
   @ReasonCode       TReasonCode,

   @InventoryClass1  TInventoryClass,
   @InventoryClass2  TInventoryClass,
   @InventoryClass3  TInventoryClass,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @ReturnCode   TInteger,
          @MessageName  TMessageName,
          @Message      TDescription,

          @vLPNType      TTypeCode,
          @vLPNOwnership TOwnership,
          @vNumLines     TCount,
          @vSKUId        TRecordId,
          @vSKUOwnership TOwnership,
          @LPNLineCount  TCount,
          @vInnerPacks   TInnerPacks,
          @vQuantity     TQuantity,
          @vLPNDetailId  TRecordId,
          @vLocationId   TRecordId,
          @vPalletId     TRecordId,
          @vCreatedDate  TDateTime,
          @vModifiedDate TDateTime;
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @vSKUId      = @SKUId,
       /* we cannot coalesce Innerpacks to zero here, either we need to compute based on the quantity being added and
          its unitsperpackage. If we pass Innerpacks as 0 to LPNDetails_AddOrUpdate then it will update Innerpacks on the detail as 0 but,
          if we pass null then it will compute Innerpacks and updates will be done based on Quantity and UnitsPerPackage*/
       --  @InnerPacks  = coalesce(@InnerPacks, 0),
         @Quantity    = coalesce(@Quantity, 0);

  /* Get SKU Details */
  if (@vSKUId is null)
    select @vSKUId = SKUId from dbo.fn_SKUs_GetScannedSKUs(@SKU, @BusinessUnit);

  select @vSKUOwnership = Ownership
  from SKUs
  where (SKUId = @vSKUId);

  select @vLPNType      = LPNType,
         @vLPNOwnership = Ownership,
         @vNumLines     = NumLines
  from LPNs
  where (LPNId = @LPNId);

  /* Get LPN Line Count */
  select @LPNLineCount = count(*)
  from LPNDetails
  where LPNId = @LPNId;

  /* Get LPNDetailId */
  /* In case of updating existing LPN detail,
     add the current Quantity, InnerPacks, ReceivedQty to existing count */
  select @vLPNDetailId  = LPNDetailId,
         @vInnerPacks   = InnerPacks + @InnerPacks,
         @vQuantity     = Quantity   + @Quantity
  from LPNDetails
  where (LPNId = @LPNId) and
        (SKUId = @vSKUId);

  /* Validations */
  /* ##VM - Shall we use a Control Var (AllowAdjustToZero) and validate based on it??? */
  if (@vSKUId is null)
    set @MessageName = 'SKUDoesNotExist';
  else
  /* Do not allow Multiple SKUs - except during cycle counting.
     We allow during cycle count because when the SKU is being changed, we would need
     to add the new SKU and then delete the old SKU - so for a point in time, LPN
     could have muliple SKUs, but it should not end up like that

     Allow Carts to have multiple SKUs */
  if (@LPNLineCount > 0) and (@vLPNDetailId is null) and
     ((substring(cast(@ReasonCode as varchar(2)), 1, 2) != '10') and (@ReasonCode != '110')) and
     (@vLPNType <> 'A' /* Cart */) and
     (@ReasonCode <> '131' /* Explode Prepack */)
    set @MessageName = 'CannotAddMoreThanOneSKUToLPN';

  /* ##VM - Do we need to consider the following Ctrl var validations
       -> ???Location allows SKU or not - Currently LocationSKU not using???
       -> Lcoation Max Limit or NO Limit ???  */

  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  select @vInnerPacks = coalesce(@vInnerPacks, @InnerPacks),
         @vQuantity   = coalesce(@vQuantity, @Quantity);

  /* Update InventoryClass values on the LPNs */
  update LPNs
  set InventoryClass1 = coalesce(@InventoryClass1, InventoryClass1, ''),
      InventoryClass2 = coalesce(@InventoryClass2, InventoryClass2, ''),
      InventoryClass3 = coalesce(@InventoryClass3, InventoryClass3, ''),
      Ownership       = case when NumLines = 0 then @vSKUOwnership else Ownership end,
      @vPalletId      = PalletId,
      @vLocationId    = LocationId
  where (LPNId = @LPNId);

  /* Update LPN Details */
  exec @ReturnCode = pr_LPNDetails_AddOrUpdate @LPNId,
                                               null          /* @LPNLine */,
                                               null          /* @CoO */,
                                               null          /* @vSKUId */,
                                               @SKU,
                                               @vInnerPacks,
                                               @vQuantity    /* @Quantity */,
                                               null          /* @ReceivedUnits */,
                                               null          /* @ReceiptId */,
                                               null          /* @ReceiptDetailId */,
                                               null          /* @OrderId */,
                                               null          /* @OrderDetailId */,
                                               null          /* @OnHandStatus */,
                                               'AddSKU'      /* @Operation */,
                                               null          /* @Weight */,
                                               null          /* @Volume */,
                                               null          /* @Lot */,
                                               @BusinessUnit,
                                               @vLPNDetailId  output,
                                               @vCreatedDate  output,
                                               @vModifiedDate output,
                                               @UserId        output,
                                               @UserId        output;


  /* Update Pallet Counts (InnerPacks, Quantity) */
  if (@vPalletId is not null)
    exec pr_Pallets_UpdateCount @PalletId     = @vPalletId,
                                @InnerPacks   = @InnerPacks,
                                @Quantity     = @Quantity,
                                @UpdateOption = '+' /* Add */;

  /* Update Location Counts (InnerPacks, Quantity) */
  exec pr_Locations_UpdateCount @LocationId   = @vLocationId,
                                @InnerPacks   = @InnerPacks,
                                @Quantity     = @Quantity,
                                @UpdateOption = '+';

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_AddSKU */

Go
