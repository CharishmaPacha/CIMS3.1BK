/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/27  RV      pr_Receipts_ReceiveInventory: Considered permission also to validate the max quantity override
  2020/05/07  MS      pr_Receipts_ReceiveInventory, pr_ReceiptHeaders_Recalculate: Changes to correct LPNsReceived count (HA-286)
  2020/04/22  RIA     pr_Receipts_ReceiveInventory: Changes to update LPNs Received count (HA-189)
  2020/04/18  TK      pr_Receipts_ReceiveInventory: Don't override status of picklane LPN when inventory is received
  2020/04/17  MS      pr_Receipts_ReceiveInventory: Bug fix to controls return controlcode (HA-215)
  2020/04/16  MS      pr_Receipts_ReceiveInventory,pr_Receipts_ReceiveSKUs: Changes to update WH &Location (HA-187)
  2020/04/05  AY      pr_ReceiptDetails_UpdateCount, pr_Receipts_ReceiveInventory: Bug fixes
  2020/04/01  TK      pr_Receipts_ReceiveInventory & pr_Receipts_UI_ReceiveToLPN:
                        Changes to populate InventoryClass from receipt detail to LPN (HA-84)
  2020/03/31  RIA     pr_Receipts_ReceiveInventory: Changes to generate LPN (CIMSV3-754)
  2020/03/19  TK      pr_Receipts_UI_ReceiveToLPN & pr_Receipts_ReceiveInventory:
                        Changes to update ReceiverId on LPNs (S2GMI-140)
  2018/07/14  VM      pr_Receipts_ReceiveSKUs: Do not send Location to pr_Receipts_ReceiveInventory if inventory to be received to picklane (OB2-294)
  2018/06/08  PK/AY/  Added pr_ReceivedCounts_AddOrUpdate.(S2G-879)
              SV      pr_Receipts_ReceiveInventory, pr_Receipts_UI_ReceiveToLPN:
                        Added Caller pr_ReceivedCounts_AddOrUpdate.
                      pr_Receipts_ReceiveInventory: Added new input param ReceiverId (S2G-879)
  2018/06/02  TK      pr_Receipts_ReceiveInventory: Fixed issue with updating Innerpacks on Received LPN (S2GCA-52)
  2018/03/06  SV      pr_ReceiptHeaders_GetToReceiveDetails, pr_Receipts_ReceiveInventory, pr_Receipts_ReceiveExternalLPN:
                        Changes to receive the LPN into default loc (S2G-337)
  2016/07/21  OK      pr_Receipts_ReceiveInventory: Bug fix - avoid the updating Received Quantity twice (CIMS-1004)
  2016/04/06  AY      pr_Receipts_UI_ReceiveToLPN, pr_Receipts_ReceiveInventory: Get CoO from RD to apply to LPNs created
  2015/10/01  SV      pr_Receipts_ReceiveInventory: Updating the Receipt# while receiving (CIMS-628)
  2015/08/06  AY      pr_Receipts_ReceiveInventory: Bug fix with update of location counts when receiving into same LPN again.
  2013/05/24  PK      pr_Receipts_ReceiveInventory: Passing Warehouse param for LPN generation procedure.
  2013/03/05  YA      pr_Receipts_ReceiveInventory: Validate 'Allow over receiving'
  2011/03/11  VM      pr_Receipts_ReceiveInventory: Consider receiving from InTransit LPN.
  2011/03/05  VM      pr_Receipts_ReceiveInventory:
  2011/01/28  VM      pr_Receipts_ReceiveInventory: Update ReceiptId on LPN.
  2011/01/21  VM      pr_Receipts_ReceiveInventory: Receive to default receiving location, if the LPN is not in Location.
                      pr_ReceiptHeaders_SetStatus: Correction in Case order
  2010/12/31  VM      pr_Receipts_ReceiveInventory: Sent value to newly added param in pr_LPNs_Move
  2010/12/03  PK      pr_Receipts_ReceiveInventory : Created Control Variable "fn_Controls_GetAsBoolean" and
                        Called pr_LPNs_Move changed the output values(wip) - Changes.
  2010/12/03  VM      pr_Receipts_ReceiveInventory: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_ReceiveInventory') is not null
  drop Procedure pr_Receipts_ReceiveInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_ReceiveInventory:
    .This procedures assumes that Receipt, ReceiptDetail, SKU, LPN (if given) and
     Quantity are validated
    .If LPN is given, inventory received in to the given LPN else it creates a new LPN
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_ReceiveInventory
  (@ReceiptId        TRecordId,
   @ReceiptDetailId  TRecordId,
   @ReceiverId       TRecordId,
   @SKUId            TRecordId,
   @InnerPacks       TInnerPacks,  /* Future use */
   @Quantity         TQuantity,
   @Warehouse        TWarehouse,
   @LocationId       TRecordId,
   @PackingSlip      TPackingSlip, /* Future use */
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   ----------------------------------
   @LPNId            TRecordId output,
   @LPNDetailId      TRecordId output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,

          @vLPNStatus                  TStatus,
          @vCreateLPN                  TFlag,
          @vLPNLocationId              TRecordId,
          @vReceivingLocation          TLocation,
          @vReceivingLocationId        TRecordId,
          @vDefaultLPNLocToRecv        TControlValue,
          @vFirstLPNId                 TRecordId,
          @vFirstLPN                   TLPN,
          @vLastLPNId                  TRecordId,
          @vLastLPN                    TLPN,
          @vROWarehouse                TWarehouse,
          @vLocWarehouse               TWarehouse,
          @vLPNDestWarehouse           TWarehouse,
          @vReceiveToWarehouse         TWarehouse,
          @vOwnership                  TOwnership,
          @vLPNOwnership               TOwnership,
          @vNumLPNsCreated             TCount,
          @vLPNNumLines                TCount,
          @vInnerPacks                 TInnerPacks,
          @vQuantity                   TQuantity,
          /* Receipt Header */
          @vReceiptId                  TRecordId,
          @vReceiptNumber              TReceiptNumber,
          @vReceiptType                TTypeCode,
          @vReceiptTypeDesc            TDescription,
          @vReceivedUnits              TQuantity,
          @vReceiverId                 TRecordId,
          @vReceiverNumber             TReceiverNumber,
          @vCurrentReceivedUnits       TQuantity,
          @vIsLPNMoved                 TFlag,
          @vControlCategory            TCategory,
          @vReceiveToWHOption          TControlValue,
          /* Receipt Detail Info */
          @vQtyOrdered                 TQuantity,
          @vQtyPrevReceived            TQuantity,
          @vMaxAllowedQtyToRecv        TQuantity,
          @vCoO                        TCoO,
          @vLot                        TLot,
          @vInventoryClass1            TInventoryClass,
          @vInventoryClass2            TInventoryClass,
          @vInventoryClass3            TInventoryClass;

  declare @ttReceiptsToRecalc          TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode           = 0,
         @vMessageName          = null,
         @vReceivedUnits        = @Quantity,
         @vCurrentReceivedUnits = @Quantity,
         @vInnerPacks           = @InnerPacks,
         @vQuantity             = @Quantity,
         @vIsLPNMoved           = 'N' /* Default No */

  /* Based on the control set, need to update the WH over the LPN
     It can be Loc/Receipt WH, Controls decides that. So fetching the LocWH */
  if (coalesce(@LocationId, '') <> '')
    select @vLocWarehouse = Warehouse
    from Locations
    where (LocationId = @LocationId);

  /* User may not identify the LPN, in which case we will create further below */
  if (@LPNId is not null)
    select @vLPNLocationId    = LocationId,
           @vLPNStatus        = Status,
           @vLPNDestWarehouse = DestWarehouse,
           @vLPNOwnership     = Ownership
    from LPNs
    where (LPNId = @LPNId);

  select @vReceiptId       = ReceiptId,
         @vReceiptNumber   = ReceiptNumber,
         @vReceiptType     = ReceiptType,
         @vOwnership       = Ownership,
         @vROWarehouse     = Warehouse,
         @vReceiptTypeDesc = dbo.fn_EntityTypes_GetDescription ('Receipt', ReceiptType, BusinessUnit)
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  /* Get Receipt Details info */
  select @vQtyOrdered          = QtyOrdered,
         @vQtyPrevReceived     = QtyReceived,
         @vMaxAllowedQtyToRecv = QtyOrdered + ExtraQtyAllowed,
         @vCoO                 = CoO,
         @vLot                 = Lot,
         @vInventoryClass1     = InventoryClass1,
         @vInventoryClass2     = InventoryClass2,
         @vInventoryClass3     = InventoryClass3
  from ReceiptDetails
  where (ReceiptId       = @ReceiptId      ) and
        (ReceiptDetailId = @ReceiptDetailId);

  select @vReceiverId     = ReceiverId,
         @vReceiverNumber = ReceiverNumber
  from Receivers
  where (ReceiverId = @ReceiverId);

  /* set the control category based on the receipt type */
  select @vControlCategory   = 'Receiving_' + @vReceiptType;
  select @vReceiveToWHOption = dbo.fn_Controls_GetAsString(@vControlCategory, 'ReceiveToWarehouse', 'LOC', @BusinessUnit, @UserId),
         @vCreateLPN         = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'CreateLPN', 'N', @BusinessUnit, @UserId);

  /* Determine the Warehouse for the LPN i.e. is it Locations' WH or RO WH?
     If it is LOC, then we use the Location WH. If there is no Location given, then LocWarehouse may be null
     then we use the user selected WH, if that is also not given by user, then we select the RH Warehouse.
     Note that the assumption is that this is validated already i.e. the Warehouse being received to is valid
     for the particular Receipt Order */
  select @vReceiveToWarehouse = case when @vReceiveToWHOption = 'LOC' then coalesce(@vLocWarehouse, @Warehouse, @vROWarehouse)
                                     else @vROWarehouse end;

  /* Validate not to accept when LPN is in a diff Location */
  if (coalesce(@vLPNLocationId, @LocationId) <> coalesce(@LocationId, @vLPNLocationId))
    set @vMessageName = 'LocOfLPNIsDiffThanTheCurrentRecLoc';
  else
  if ((@vLPNStatus <> 'N'/* New */) and (@vLPNDestWarehouse <> @vReceiveToWarehouse))
    set @vMessageName = 'ReceiptAndLPNWarehouseMismatch';
  else
  if ((@vLPNStatus <> 'N'/* New */) and (@vLPNOwnership <> @vOwnership))
    set @vMessageName = 'ReceiptAndLPNOwnershipMismatch';
  else
  if (@LPNId is null) and (@vCreateLPN = 'N')
    set @vMessageName = 'LPNisRequired';
  else
    set @vMessageName = dbo.fn_Receipts_ValidateOverReceiving(@ReceiptDetailId, @Quantity, @UserId);

  if (@vMessageName is not null)
    goto ErrorHandler;

  select @vDefaultLPNLocToRecv = 'LPNLocation_' + @vReceiveToWarehouse;

  /* Find the location for the new LPN or for an existing LPN, which is not on Location */
  set @vReceivingLocation = dbo.fn_Controls_GetAsString('Receipts', @vDefaultLPNLocToRecv, 'RECVDOCK', @BusinessUnit, @UserId);

  /* If LPN not already in a location and no Location is specified, then get the default
     receiving location which would be any location in the RecvStaging area */
  if (@vLPNLocationId is null) and (@LocationId is null)
    begin
       select top 1 @vReceivingLocationId = LocationId,
                    @vReceivingLocation   = Location
       from Locations
       where (Warehouse = @vReceiveToWarehouse) and
             (PutawayZone = 'RecvStaging') and
             (LocationType = 'S' /* Staging */)
       order by PutawayPath;

      if (@vReceivingLocation is null)
        begin
          set @vMessageName = 'ReceivingLocationNotSet';
          goto ErrorHandler;
        end
    end
  else
    begin
      set @vReceivingLocationId = coalesce(@vLPNLocationId, @LocationId);

      /* Get latest Location */
      select @vReceivingLocation = Location
      from Locations where (LocationId = @vReceivingLocationId);
    end

  /* Create a new LPN if one is not given */
  if (@LPNId is null)
    begin
      /* 1. Generate a new LPN
         2. Find a Location for it from Controls (done above)
         3. Move the LPN to that Location.
      */
      exec pr_LPNs_Generate Default /* @LPNType */,
                            1       /* @NumLPNsToCreate */,
                            null    /* @LPNFormat - will take default */,
                            @vReceiveToWarehouse,
                            @BusinessUnit,
                            @UserId,
                            @vFirstLPNId     output,
                            @vFirstLPN       output,
                            @vLastLPNId      output,
                            @vLastLPN        output,
                            @vNumLPNsCreated output;


      select @LPNId = @vFirstLPNId;
    end /* Create LPN */
  else
  /* If LPN is not generated but instead we are using a New LPN, increment the LPN Count */
  if (@vLPNStatus = 'N')
    select @vNumLPNsCreated = 1;
  else
  /* If we are receiving more inventory to an already Received LPN, then we don't
     want to increment the LPN again */
  if ((@vLPNStatus = 'R') and (@LPNDetailId is null))
    select @vNumLPNsCreated = 0;

    /* In case of updating existing LPN detail,
       add the current Quantity, InnerPacks, ReceivedQty to existing count

     But, in case of ASN Case receiving, we only update Received Qty */
  if (@LPNDetailId is not null)
    select @vInnerPacks      = case
                                 when (@vLPNStatus <> 'T'/* In Transit */) then
                                   InnerPacks + coalesce(@InnerPacks, 0)
                                 else
                                   @InnerPacks
                               end,
           @vQuantity        = case
                                 when (@vLPNStatus <> 'T'/* In Transit */) then
                                   Quantity + coalesce(@Quantity, 0)
                                 else
                                   @Quantity
                               end,
           @vReceivedUnits   = ReceivedUnits + coalesce(@vCurrentReceivedUnits, 0)
    from LPNDetails
    where (LPNDetailId = @LPNDetailId);

  /* Add/Update LPN Detail */
  exec @vReturnCode = pr_LPNDetails_AddOrUpdate @LPNId,
                                               null          /* @LPNLine */,
                                               @vCoO         /* @CoO */,
                                               @SKUId,
                                               null          /* SKU */,
                                               @vInnerPacks,
                                               @vQuantity      /* @Quantity */,
                                               @vReceivedUnits /* @ReceivedUnits */,
                                               @ReceiptId,
                                               @ReceiptDetailId,
                                               null          /* @OrderId */,
                                               null          /* @OrderDetailId */,
                                               null          /* OnhandStatus */,
                                               null          /* Operation */,
                                               null          /* @Weight */,
                                               null          /* @Volume */,
                                               @vLot         /* @Lot */,
                                               @BusinessUnit,
                                               @LPNDetailId  output,
                                               null          /* CreatedDate */,
                                               null          /* ModifiedDate */,
                                               @UserId       /* CreatedBy */,
                                               @UserId       /* ModifiedBy */;

  if (@vReturnCode > 0)
    goto ExitHandler;

  /* If given LPN is not in Location - Move it to given Location or default Location */
  /* See above, even we fetch Default Receiving Location and not Receiving Location Id,
     hence for new LPN also, the Move LPN works as well */
  if (@vLPNLocationId is null)
    begin
      exec pr_LPNs_Move @LPNId,
                        null /* LPN */,
                        null /* LPN Status */,
                        @vReceivingLocationId /* New LocationId */,
                        @vReceivingLocation,
                        @BusinessUnit,
                        @UserId;

      select @vIsLPNMoved = 'Y'; /* set @vIsLPNMoved to 'Y' as LPN Moved to location */
    end
  else
    /* Update Location Counts (NumLPNs, InnerPacks, Quantity), if LPN is on a Location */
    exec pr_Locations_UpdateCount @LocationId   = @vReceivingLocationId,
                                  @NumLPNs      = @vNumLPNsCreated,
                                  @InnerPacks   = @InnerPacks,
                                  @Quantity     = @Quantity,
                                  @UpdateOption = '+';

  /* Update LPN with ReceiptId, Ownership and DestWarehouse */
  update LPNs
  set ReceiptId      = @ReceiptId,
      ReceiptNumber  = @vReceiptNumber,
      ReceiverId     = @vReceiverId,
      ReceiverNumber = @vReceiverNumber,
      Status         = case when LPNType = 'L'/* Picklane */ then Status else 'R' /* Received */ end,
      DestWarehouse  = case
                         when (@vLPNStatus = 'N' /* New */) and
                               (coalesce(DestWarehouse, '') <> @vReceiveToWarehouse) then
                           @vReceiveToWarehouse
                         else
                           DestWarehouse
                       end,
      Ownership      = case
                         when ((@vLPNStatus = 'N' /* New */) and (Ownership <> @vOwnership)) then
                           @vOwnership
                         else
                           Ownership
                       end,
      Lot             = @vLot,
      InventoryClass1 = @vInventoryClass1,
      InventoryClass2 = @vInventoryClass2,
      InventoryClass3 = @vInventoryClass3
  where (LPNId = @LPNId);

  /* If we moved the InTransit LPN to any location then we are updating the ReceivedUnits on The Receipt in pr_LPNs_Move
     hence sending CurrentReceivedUnits as zero as we already updated */
  if (@vLPNStatus = 'T' /* InTransit */) and (@vIsLPNMoved = 'Y')
    set @vCurrentReceivedUnits = 0;

  /* Check for over received and max quantity override and insert as warning to show to the users */
  if (@vQtyPrevReceived + @Quantity > @vMaxAllowedQtyToRecv)
    insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
      select 'W' /* Warning */, 'RecvInv_ReceivedBeyondMaxQty', @vReceiptTypeDesc, @vReceiptNumber;
  else
  if (@vQtyPrevReceived + @Quantity > @vQtyOrdered)
    insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
      select 'W' /* Warning */, 'RecvInv_ReceivedExtraQty', @vReceiptTypeDesc, @vReceiptNumber;

  /* Add the Received Info to ReceivedCounts table */
  exec pr_ReceivedCounts_AddOrUpdate @LPNId, @LPNDetailId, @InnerPacks, @Quantity, -- Pass in the quantity being received at this iteration
                                     @ReceiptId, @ReceiverId, @ReceiptDetailId,
                                     null /* PalletId */, @vReceivingLocationId, @SKUId,
                                     '+' /* UpdateOption */, @BusinessUnit, @UserId;

  /* Updating ReceiptDetails Counts */
  exec pr_ReceiptDetails_UpdateCount @ReceiptId,
                                     @ReceiptdetailId,
                                     '+' /* Update Received Option */,
                                     @vCurrentReceivedUnits,
                                     @vNumLPNsCreated,
                                     default /* UpdateIntransitOption */,
                                     default /* QtyIntransit */,
                                     default /* LPNsIntransit */;

  /* Get the NumLines of LPN */
  select @vLPNNumLines = NumLines from LPNs where (LPNId = @LPNId);

  /* when we receive a multi-SKU LPN the RD.LPNsReceived would be wrong, so recount to fix it  */
  if (coalesce(@vNumLPNsCreated, '') = 0) and (@vLPNNumLines > 1)
    begin
      insert into @ttReceiptsToRecalc (EntityId) select @ReceiptId;
      exec pr_ReceiptHeaders_Recalculate @ttReceiptsToRecalc, '$C', @UserId, @BusinessUnit;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_ReceiveInventory */

Go
