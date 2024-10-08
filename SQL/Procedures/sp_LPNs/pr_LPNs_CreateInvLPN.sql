/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/13  TK      pr_LPNs_CreateInvLPN: InventoryClass should be empty if nothing passed in (HA-86)
  2020/04/29  HYP     pr_LPNs_CreateInvLPNs & pr_LPNs_CreateInvLPN: Added InventoryClass1 (CIMSV3-861)
  2019/01/18  KSK     pr_LPNs_CreateInvLPNs, pr_LPNs_Void: Added Reference and Generating export while creating Inventory for LPNs (S2GCA-460&461)
  2018/07/26  NB      pr_LPNs_CreateInvLPNs: Added condition to check trancount before rollback call(CIMSV3-299)
  2018/05/07  CK      pr_LPNs_CreateInvLPNs: Restricted to not allow non standard cases (S2G-745)
  2016/05/04  TK      pr_LPNs_CreateInvLPNs: We can have more than one Prepack in LPN (FB-648)
  2014/12/09  TK      pr_LPNs_CreateInvLPN: Migrated Reason Code related changes from GNC
  2014/09/23  AK      pr_LPNs_CreateInvLPNs: Set to display error if Quantity not equal to UnitsPerCase * Innerpacks.
  2014/08/01  TD      pr_LPNs_CreateInvLPN, pr_LPNs_Move:Pre-Proces the Created inventory LPN.
  2014/06/03  PKS     pr_LPNs_CreateInvLPN: InnerPack values passed to AddOrUpdate procedure of LPNDetails to update Innerpack value.
  2014/05/23  PKS     pr_LPNs_CreateInvLPN, pr_LPNs_CreateInvLPNs: Added CreatedDate
  2014/02/25  TD      pr_LPNs_CreateInvLPNs, pr_LPNs_CreateInvLPN: Changes to update ExpiryDate and Lot to LPNs.
  2013/05/24  PK      pr_LPNs_CreateInvLPN: Passing Warehouse param for LPN generation procedure.
  2012/12/01  YA      pr_LPNs_CreateInvLPNs: Fix validations to not consider inactive SKUPrepacks.
  2012/10/11  AY      pr_LPNs_CreateInvLPNs: Pass reason code for creating Inventory
  2012/10/09  VM      pr_LPNs_CreateInvLPNs: Added valid messages when pallet is validated
  2012/09/28  AA      pr_LPNs_CreateInvLPNs: Added validation to not allow to create inventory for In active SKUs
  2012/06/30  SP      Placed the transaction controls in 'pr_LPNs_CreateInvLPNs' and 'pr_LPNs_Void'.
  2012/06/30  PKS     pr_LPNs_CreateInvLPNs: Success message added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_CreateInvLPN') is not null
  drop Procedure pr_LPNs_CreateInvLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_CreateLPN: Procedure to create an LPN and details with inventory.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_CreateInvLPN
  (@LPNType         TTypeCode    = 'C',
   @SKUId           TRecordId,
   @InnerPacks      TInnerPacks,
   @Quantity        TQuantity,
   @CoO             TCoO,
   @PalletId        TRecordId,
   @Lot             TLot,
   @ExpiryDate      TDate,
   @Ownership       TOwnership,
   @DestWarehouse   TWarehouse,
   @ReasonCode      TReasonCode,
   @InventoryClass1 TInventoryClass,
   @InventoryClass2 TInventoryClass = null,
   @InventoryClass3 TInventoryClass = null,
   @Reference       TReference,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @CreatedDate     TDateTime,
   @LPNId           TRecordId    = null output,
   @LPN             TLPN         = null output,
   @LPNDetailId     TRecordId    = null output,
   @Message         TDescription        output)
as
  /* Declare local variables */
  declare @vPallet         TPallet,
          @MessageName     TMessageName,
          @ReturnCode      TInteger,

          @ActivityType    TActivityType;
begin
  select @ReturnCode  = 0,
         @MessageName = null,
         @LPNDetailId = null;

  if (@PalletId is not null)
    begin
      select @ActivityType = 'CreateInvLPNOnPallet';

      /* Get Pallet information */
      select @vPallet = Pallet
      from Pallets
      where (PalletId = @PalletId);
    end
  else
    select @ActivityType = 'CreateInvLPN';


  /* Validations */
  if (@SKUId is null)
    set @MessageName = 'SKUIsRequired'
  else
  if (@Quantity < 1)
    set @MessageName = 'InvalidQuantity'
  else
  if (not exists(select *
                 from vwEntityTypes
                 where (TypeCode = @LPNType) and
                       (Entity   = 'LPN')))
    set @MessageName = 'LPNTypeDoesNotExist'
  else
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Create LPNs and LPNDetails */

  /* First, create an empty LPN */
  exec @ReturnCode = pr_LPNs_Generate @LPNType       /* LPNType */,
                                      1              /* NumLPNsToCreate */,
                                      null           /* LPNFormat - Use default format based upon LPNType */,
                                      @DestWarehouse,
                                      @BusinessUnit,
                                      @UserId,
                                      @LPNId   output,
                                      @LPN     output;

  if (@ReturnCode > 0)
    goto ExitHandler;

  /* After creating an empty LPN update that LPN with the values in i/p variables */
  update LPNs
  set @LPN            = LPN,
      CoO             = @CoO,
      PalletId        = @PalletId,
      Pallet          = @vPallet,
      Lot             = @Lot,
      ExpiryDate      = @ExpiryDate,
      Ownership       = @Ownership,
      DestWarehouse   = @DestWarehouse,
      ReasonCode      = @ReasonCode,
      InventoryClass1 = coalesce(rtrim(@InventoryClass1), ''),
      InventoryClass2 = coalesce(rtrim(@InventoryClass2), ''),
      InventoryClass3 = coalesce(rtrim(@InventoryClass3), ''),
      Reference       = @Reference,
      CreatedDate     = @CreatedDate,
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @UserId
  where (LPNId = @LPNId);

  /* Create LPNDetail for the above created LPN */
  exec @ReturnCode = pr_LPNDetails_AddOrUpdate @LPNId              /* LPNId */,
                                               null                /* LPNLine */,
                                               @CoO                /* CoO */,
                                               @SKUId              /* SKUId */,
                                               null                /* SKU */,
                                               @InnerPacks         /* InnerPacks */,
                                               @Quantity           /* Quantity */,
                                               0                   /* ReceivedUnits */,
                                               null                /* ReceiptId */,
                                               null                /* ReceiptDetailsId */,
                                               null                /* OrderId */,
                                               null                /* OrderDetailId */,
                                               null                /* OnhandStatus */,
                                               null                /* Operation */,
                                               null                /* Weight */,
                                               null                /* Volume */,
                                               null                /* Lot */,
                                               @BusinessUnit       /* BusinessUnit */,
                                               @LPNDetailId  output;

  if (@ReturnCode > 0)
    goto ExitHandler;

  /* Pre-process the newly created LPN to establish Putaway and Picking Class */
  exec pr_LPNs_PreProcess @LPNId, null, @BusinessUnit;

  /* Updating Pallets */
  if (@PalletId is not null)
    exec @ReturnCode = pr_Pallets_UpdateCount @PalletId   /* PalletId */,
                                              null        /* Pallet */,
                                              '+'         /* UpdateOption */,
                                              1           /* NumLPNs */,
                                              @InnerPacks /* InnerPacks */,
                                              @Quantity   /* Quantity */

  if (@ReturnCode > 0)
    goto ExitHandler;

  /* Audit Trail */
  exec pr_AuditTrail_Insert @ActivityType, @UserId, null /* ActivityTimestamp */,
                            @LPNId      = @LPNId,
                            @Quantity   = @Quantity,
                            @ReasonCode = @ReasonCode;

  set @Message = 'LPN Created successfully.';

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_CreateInvLPN */

Go
