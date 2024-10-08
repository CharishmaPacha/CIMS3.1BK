/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/30  PK/TK   pr_Putaway_LPNContentsToPicklane: Updating InventoryClass fields when moving inventory from LPNs to Picklanes &
  2020/04/29  RT      pr_Putaway_LPNContentsToPicklane: Changed the Parameters (HA-111)
  2020/01/03  TK      pr_Putaway_LPNContentsToPicklane: Changes to return LPNDetailId (HPI-2821)
  2018/09/14  TK      pr_Putaway_LPNContentsToPicklane: Changes to pr_Locations_AddSKUToPicklane signature (S2GCA-216)
  2018/05/16  DK      pr_Putaway_LPNContentsToPicklane: Made changes to call AdjustQty proc after sending exports as LPNs data is getting consumed after adjusting (HPI-1900).
  2018/05/08  RV      pr_Putaway_LPNContentsToPicklane: Caller changed as new parameter FromWarehouse added to the proc (S2G-714)
  2018/02/06  TK      pr_Putaway_LPNContentsToPicklane: Process Directed line only if it is Replenish Putaway (S2G-182)
  2017/12/05  SV      pr_Putaway_LPNContentsToPicklane: Need to export the transaction for the Inv when Putaway from WH1 to WH2 (HPI-1675)
  2017/09/14  SV      pr_Putaway_LPNContentsToPicklane: Enhanced code to generate correct exports when Receiving and Putaway are done at different WHs (HPI-1327)
  2016/10/05  AY      pr_Putaway_LPNContentsToPicklane: Changes to consider satisfy the replenish lines also for normal PA (HPI-GoLive)
  2016/08/09  AY      pr_Putaway_LPNContentsToPicklane: Return ToLPNId even when SKU is already in Loc - used for AT later. (HPI-458)
  2015/10/30  RV      pr_Putaway_LPNContentsToPicklane: Include new Replenish order type for validation (FB-474)
  2014/06/08  TD      pr_Putaway_LPNContentsToPicklane:Changes to call pr_Locations_SplitReplenishQuantity.
  2013/11/20  NY      pr_Putaway_LPNContentsToPicklane: Pass Export Type as 'Invch', if we PA Inventory LPN into Picklanes.
  2013/09/24  VM      pr_Putaway_LPNContentsToPicklane: Bug-fix: do not export transactions, if From inventory is already available.
  2013/04/19  AY      pr_Putaway_LPNContentsToPicklane: Changed to pass in appropriate reason
  2013/04/09  AY      pr_Putaway_LPNContentsToPicklane: Update Reference Location to be PA Location
  2011/10/21  PK      pr_Putaway_LPNContentsToPicklane: pr_Exports_LPNData - added parameters SKUId and Ownership.
  2011/10/20  AY      pr_Putaway_LPNContentsToPicklane: Change to upload From LPN Details
                      pr_Putaway_LPNContentsToPicklane: Update LastPutawayDate when putaway to picklane
  2011/07/20  VM      pr_Putaway_LPNContentsToPicklane: Include BusinessUnit also for Exports info.
                      pr_Putaway_LPNContentsToPicklane:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_LPNContentsToPicklane') is not null
  drop Procedure pr_Putaway_LPNContentsToPicklane;
Go
/*------------------------------------------------------------------------------
  Proc pr_Putaway_LPNContentsToPicklane:
    Assumes that all validations are done for
      FromLPN, InnerPacks, Quantity,
      ToLocation exists and is in valid status to putaway by the caller.
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_LPNContentsToPicklane
  (@FromLPNId      TRecordId,
   @PASKUId        TRecordId,
   @PAInnerPacks   TInnerPacks,
   @PAQuantity     TQuantity,
   @ToLocationId   TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   --------------------------------
   @ToLPNId        TRecordId output,
   @ToLPNDetailId  TRecordId output)
as
  declare @ReturnCode              TInteger,
          @MessageName             TMessageName,
          @Message                 TDescription,

          @vPASKUId                TRecordId,
          @vPASKU                  TSKU,
          @vPAReceiptId            TRecordId,
          @vReceiptNumber          TReceiptNumber,
          @vPAReceiptDetailid      TRecordId,
          @vLPNOrderId             TRecordId,
          @vOrderType              TTypeCode,

          @vFromLPNDetailId        TRecordId,
          @vFromLPNDtlOnhandStatus TStatus,
          @vFromLPNLocationId      TRecordId,
          @vFromWarehouse          TWarehouse,
          @vFromLPNLot             TLot,
          @vFromLPNOwnership       TOwnership,
          @vUnitsPerInnerPack      TInteger,

          @vToLocationType         TLocationType,
          @vToLocationStatus       TStatus,
          @vToLocation             TLocation,
          @vToLPNId                TRecordId,
          @vToLPNSKUId             TRecordId,
          @vToLPNDtlOnhandStatus   TStatus,
          @vOwnership              TOwnership,
          @vToWarehouse            TWarehouse,
          @vTransType              TTypeCode,

          @vInventoryClass1        TInventoryClass,
          @vInventoryClass2        TInventoryClass,
          @vInventoryClass3        TInventoryClass;
begin
  SET NOCOUNT ON;
  /*
       Get From LPN LPNDetailId of given @PASKUId or coalesce(@PASKUId, SKU)
       Get To Location LPN details
       Get the Logical LPN details of ToLocation (Picklane) - ToLPNId, ToLPNDetailId, SKUId, SKU
       Validations
         Error out, if given ToLocation is not Picklane
         Error out, if ToLocation is already associated with a different SKU when AllowMultipleSKUs is 'N'
       Reduce Units from FromLPN
       Increase Units in ToLPN
       ** Need to generate 'Recv' (Receipts) Uploads - needs to done separately here and
          not from pr_LPNs_AdjustQty as it creates 'InvCh' uploads. So send 'N' as Export flag to that proc
  */

  /* Get FromLPN Details */
  select @vFromLPNDetailId        = LPNDetailId,
         @vPAReceiptId            = ReceiptId,
         @vPAReceiptDetailId      = ReceiptDetailId,
         @vOwnership              = Ownership,
         @vFromLPNDtlOnhandStatus = OnhandStatus,
         @vLPNOrderId             = OrderId,
         @vOrderType              = OrderType,
         @vUnitsPerInnerPack      = UnitsPerPackage,
         @vFromLPNLocationId      = LocationId,
         @vFromWarehouse          = DestWarehouse,
         @vFromLPNLot             = LPNLot,
         @vFromLPNOwnership       = Ownership,
         @vInventoryClass1        = InventoryClass1,
         @vInventoryClass2        = InventoryClass2,
         @vInventoryClass3        = InventoryClass3
  from vwLPNDetails
  where (LPNId = @FromLPNId) and
        (SKUId = coalesce(@PASKUId, SKUId));

  /* For GNC we do not have Receipts in cims. so we need to get the
     ReceiptNumber from LPNs */
  if (@vPAReceiptId is null)
    select @vReceiptNumber = ReceiptNumber
    from LPNs
    where (LPNId = @FromLPNId);

  /* Get the SKU Details */
  select @vPASKUId = SKUId,
         @vPASKU   = SKU
  from SKUs
  where (SKUId = @PASKUId);

  /* Get ToLocation/ToLPN Details */
  /* Assumes the following
     . ToLocation is a Picklane, there is a Logical LPN associated with it
  */
  select @vToLocationType   = LocationType,
         @vToLocationStatus = Status,
         @vToLocation       = Location,
         @vToWarehouse      = Warehouse
  from Locations
  where (LocationId = @ToLocationId);

  /* If the putaway is doing for Replenishments and the ToLPN has directed reserved qty
     then we want to satisfy that as opposed to just adding a new line

     We wanted to do the same as above point in normal PA as well, hence commented a condition.
     That means, if any PA is done into location, it has to satisfy DR/D lines first. */
  if (@vOrderType in ('RU', 'RP', 'R' /* Replenishments */)) and
     (exists (select * from vwLPNDetails
              where (LocationId = @ToLocationId) and
                    (SKUId      = @vPASKUId) and
                    (OnhandStatus in ('D', 'DR' /* Directed/Directed Reserved */))))
    begin
      exec pr_Locations_SplitReplenishQuantity @vPASKUId, @ToLocationId, @PAInnerPacks, @PAQuantity, @vLPNOrderId,
                                               @BusinessUnit, @UserId;
    end
  else
    begin
      /* Add units to the Picklane - If the Picklane does not have the SKU, adds
         a new line with the SKU and Qty
         No need to upload against picklane as the receipt would be updated */
      exec @Returncode = pr_Locations_AddSKUToPicklane @vPASKUId,
                                                       @ToLocationId,
                                                       @PAInnerPacks,
                                                       @PAQuantity,
                                                       @vFromLPNLot,
                                                       @vFromLPNOwnership,
                                                       @vInventoryClass1,
                                                       @vInventoryClass2,
                                                       @vInventoryClass3,
                                                       '+' /* Update Option */,
                                                       'N' /* Export Option */,
                                                       @UserId,
                                                       0   /* Reason Code */,
                                                       @ToLPNId        output,
                                                       @ToLPNDetailId  output;
    end

  if (@ReturnCode = 1)
    goto ErrorHandler;

  /* Get OnhandStatus and update LastPutawayDate of LPNDetail */
  update LPNDetails
  set @ToLPNId               = LPNId,
      LastPutawayDate        = current_timestamp,
      @vToLPNDtlOnhandStatus = OnhandStatus,
      ReferenceLocation      = substring(coalesce(ReferenceLocation + ',' + rtrim(@vToLocation), rtrim(@vToLocation)), 1, 50)
  from LPNDetails
  where (LPNDetailId = @ToLPNDetailId);

  /* Generate Exports 'Recv' */
  /* If received inventory was putaway into an Picklane/Picklane LPN with OnhandStatus as available
     then the putaway inventory becomes available immediately, hence we need to export a receipt */
  if (@vFromLPNDtlOnhandStatus = 'U' /* Unavailable */) and (@vToLPNDtlOnhandStatus = 'A' /* Available */)
    begin
      if (coalesce(@PAQuantity, 0) = 0) and (@PAInnerPacks > 0)
        select @PAQuantity = (@PAInnerPacks * @vUnitsPerInnerPack);

      /* The following procedure initially will send the Recv transactions.
         If the LPN is moved to same/diff WH, then it evaluates to which type of
           trans(InvCh/WHXfer) to be sent. */
      exec pr_Exports_LPNReceiptConfirmation @ReceiptId    = @vPAReceiptId,
                                             @LPNId        = @FromLPNId,
                                             @LPNDetailId  = @vFromLPNDetailId,
                                             @PAQuantity   = @PAQuantity,
                                             @ToLocationId = @ToLocationId,
                                             @CreatedBy    = @UserId;
    end
  else
  if (@vFromLPNDtlOnhandStatus = 'A' /* Available */) and (@vToLPNDtlOnhandStatus = 'A' /* Available */) and
     (@vFromWarehouse <> @vToWarehouse)
    /* This code block is only for generating the exports during putaway of available LPN into a PickLane location
       across Warehouses. Rest all the updates are done in pr_Locations_AddSKUToPicklane and pr_LPNs_AdjustQty procedures */
    exec pr_Exports_WarehouseTransfer @TransQty        = @PAQuantity,
                                      @BusinessUnit    = @BusinessUnit,
                                      @LPNId           = @ToLPNId,
                                      @LPNDetailId     = @ToLPNDetailId,
                                      @FromLPNId       = @FromLPNId,
                                      @FromLPNDetailId = @vFromLPNDetailId,
                                      @LocationId      = @vFromLPNLocationId,
                                      @OldWarehouse    = @vFromWarehouse,
                                      @NewWarehouse    = @vToWarehouse,
                                      @CreatedBy       = @UserId;

  if (@ReturnCode = 1)
    goto ErrorHandler;

  /* Adjusting should be done after calling exports as LPN is consumed, info on it will be swiped off */
  exec @Returncode = pr_LPNs_AdjustQty @FromLPNId,
                                       @vFromLPNDetailId,
                                       @vPASKUId,
                                       @vPASKU,
                                       @PAInnerPacks,
                                       @PAQuantity,
                                       '-'  /* Update Option - Subtract Qty */,
                                       'N'  /* Export? No */,
                                       219  /* Reason Code: Putaway into Picklane */,
                                       null /* Reference */,
                                       @BusinessUnit,
                                       @UserId;

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Putaway_LPNContentsToPicklane */

Go
