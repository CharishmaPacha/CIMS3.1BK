/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/18  TK      pr_LPNs_SplitLPN: Use LPNType passed in to create new LPN or use FromLPNType (HA-2909)
  2020/06/08  TK      pr_LPNs_SplitLPN: Changes to return Split LPNId (HA-820)
  2020/05/31  TK      pr_LPNs_SplitLPN: Update LPN Status & OnhandStatus before adding details to it (HA-732)
  2020/05/30  RIA     pr_LPNs_SplitLPN: Migrated changes from FB (HA-521)
  2020/03/19  TK      pr_LPNs_CreateLPNs & pr_LPNs_SplitLPN: Changes to update ReceiverId on LPNs
  2018/04/25  OK      pr_LPNs_SplitLPN: Added new procedure to split the qty/innerpacks into another new LPN
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_SplitLPN') is not null
  drop Procedure pr_LPNs_SplitLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_SplitLPN: This procedure will split the given InnerPacks/Quantity into the new LPN.
        If ToLPN is passed then we will move that IPs/Qty into that LPN or we will create one and move the inventory.
  @Options: This parameter will determines which entities needs to recomputed after splitting
        P- Pallet, L- Load, LOC- Location, B- BoL, S- Shipment, OH- OrderHeaader
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_SplitLPN
  (@FromLPN           TLPN,
   @FromLPNDetailId   TRecordId   = null,
   @SplitInnerPacks   TInnerPacks = null,
   @SplitQuantity     TQuantity   = null,
   @Options           TFlags      = null,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @ToLPNId           TRecordId   = null output,
   @ToLPN             TLPN        = null output,
   @ToLPNType         TTypecode   = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          /* From LPN */
          @vFromLPNId         TRecordId,
          @vFromLPN           TLPN,
          @vFromLPNType       TTypeCode,
          @vFromLPNQuantity   TQuantity,
          @vFromLPNOwnership  TOwnership,
          @vFromLPNWarehouse  TWarehouse,
          @vFromLPNDetailId   TRecordId,
          @vFromLPNLines      TCount,

          /* To LPN */
          @vToLPNId           TRecordId,
          @vToLPN             TLPN,
          @vToLPNStatus       TStatus,
          @vToLPNDetailId     TRecordId,

          @vSKUId             TRecordId,
          @vOnhandStatus      TStatus,
          @vUnitsPerPackage   TUnitsPerPack,
          @vPalletId          TRecordId,
          @vLocationId        TRecordId,
          @vReceiptId         TRecordId,
          @vReceiptDetailId   TRecordId,
          @vOrderId           TRecordId,
          @vOrderDetailId     TRecordId,
          @vBolId             TRecordId,
          @vLoadId            TRecordId,
          @vShipmentId        TRecordId,
          @vLot               TLot,
          @vCoO               TCoO;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the required FromLPN details */
  select @vFromLPNId    = LPNId,
         @vFromLPN      = LPN,
         @vFromLPNType  = LPNType,
         @vFromLPNLines = NumLines
  from LPNs
  where (LPN          = @FromLPN) and
        (BusinessUnit = @BusinessUnit);

  /* Get To LPN info */
  if (@ToLPN is not null)
    select @vToLPNId     = LPNId,
           @vToLPN       = LPN,
           @vToLPNStatus = Status
    from LPNs
    where (LPN = @ToLPN) and
          (BusinessUnit = @BusinessUnit);

  /* If from LPNDetailId is not passed and FromLPN has only one line then fetch that line to adjust */
  if (@FromLPNDetailId is null) and (@vFromLPNLines = 1)
    select @FromLPNDetailId = LPNDetailId
    from LPNDetails
    where (LPNId = @vFromLPNId);

  /* Get all the required detail information */
  select @vSKUId           = SKUId,
         @vOnhandStatus    = OnhandStatus,
         @vReceiptId       = ReceiptId,
         @vReceiptDetailId = ReceiptDetailId,
         @vOrderId         = OrderId,
         @vOrderDetailId   = OrderDetailId,
         @vUnitsPerPackage = UnitsPerPackage,
         @vCoO             = CoO,
         @vPalletId        = PalletId,
         @vLocationId      = LocationId,
         @vLoadId          = LoadId,
         @vShipmentId      = ShipmentId
  from vwLPNdetails
  where (LPNDetailId = @FromLPNDetailId);

  /* Validations */
  /* If LPNDetailId is not passed and LPN has multiple lines then raise an error */
  if (@FromLPNDetailId is null)
    select @vMessageName = 'LPNSplit_FromLPNDetailIdRequired'
  else
  if (coalesce(@SplitInnerPacks, 0) = 0) and (coalesce(@SplitQuantity, 0) = 0)
    select @vMessageName = 'LPNSplit_IPsOrQuantityRequired'
  else
  /* If both IPs and Qty are given, make sure they are divisible */
  if (@SplitQuantity is not null) and (coalesce(@SplitInnerPacks, 0) > 0) and (@SplitQuantity % @SplitInnerPacks > 0)
    select @vMessageName = 'LPNSplit_InvalidInnerPacksQuantity'
  else
  /* If both IPs and Qty are given, make sure the UnitsPerPackage is same as in FromLPN */
  if (@SplitQuantity is not null) and (coalesce(@SplitInnerPacks, 0) > 0) and
     (@SplitQuantity / @SplitInnerPacks <> @vUnitsPerPackage)
    select @vMessageName = 'LPNSplit_InvalidUnitsPerPackage'
  else
  /* If only Qty is given and FromLPN has cases, then it shoudl be in multiples of UnitsPerPackage */
  if ((@SplitQuantity is not null) and (@vUnitsPerPackage > 0) and (@SplitQuantity % @vUnitsPerPackage > 0))
    select @vMessageName = 'LPNSplit_QtyShouldBeInMultiplesOfIPs'
  else
  if (@ToLPN is not null) and (@vToLPNId is null)
    select @vMessageName = 'LPNSplit_InvalidToLPN'
  else
  if (@ToLPN is not null) and (@vToLPNStatus <> 'N' /* New */)
    select @vMessageName = 'LPNSplit_InvalidToLPNStatus'

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If any of the Quantity and Innerpacks not passed then compute */
  if (@SplitInnerPacks is null) and (@SplitQuantity is not null) and (@vUnitsPerPackage > 0)
    set @SplitInnerPacks = @SplitQuantity/@vUnitsPerPackage;
  else
    set @SplitInnerPacks = coalesce(@SplitInnerPacks, 0);

  /* If SplitQuantity is not passed the compute the qty based on the UnitsPerPackage on the LD */
  if (@SplitQuantity is null) and (@SplitInnerPacks is not null) and (@vUnitsPerPackage > 0)
    select @SplitQuantity = @SplitInnerPacks * @vUnitsPerPackage;

  /* if toLPN is not passed then create the new LPN */
  if (@vToLPNId is null)
    begin
      /* If ToLPNType is given then use it or create new LPN as FromLPNType */
      select @ToLPNType = coalesce(@ToLPNType, @vFromLPNType);

      exec @vReturnCode = pr_LPNs_Generate @ToLPNType,  /* LPNType      */
                                           1,              /* LPNsToCreate */
                                           null,           /* @LPNFormat   */
                                           @vFromLPNWarehouse,
                                           @BusinessUnit,
                                           @UserId,
                                           @vToLPNId   output,
                                           @vToLPN     output;

      /* Assign new ToLPN to output param */
      select @ToLPNId = @vToLPNId,
             @ToLPN   = @vToLPN;
    end

  /* Update the To LPN */
  update TL
  set TL.Status          = FL.Status,
      TL.OnhandStatus    = FL.OnhandStatus,
      TL.PalletId        = FL.PalletId,
      TL.Pallet          = FL.Pallet,
      TL.LocationId      = FL.LocationId,
      TL.Location        = FL.Location,
      TL.ReceiverId      = FL.ReceiverId,
      TL.ReceiverNumber  = FL.ReceiverNumber,
      TL.ReceiptId       = FL.ReceiptId,
      TL.ReceiptNumber   = FL.ReceiptNumber,
      TL.OrderId         = FL.OrderId,
      TL.PickTicketNo    = FL.PickTicketNo,
      TL.SalesOrder      = FL.SalesOrder,
      --TL.PackageSeqNo   = FL.PackageSeqNo, /* We do not need to copy PackageSeqNo */
      TL.PickBatchId     = FL.PickBatchId,
      TL.PickBatchNo     = FL.PickBatchNo,
      TL.TaskId          = FL.TaskId,
      TL.ShipmentId      = FL.ShipmentId,
      TL.LoadId          = FL.LoadId,
      TL.LoadNumber      = FL.LoadNumber,
      TL.BoL             = FL.BoL,
      TL.Ownership       = FL.Ownership,
      TL.CartonType      = FL.CartonType,
      TL.CoO             = FL.CoO,
      TL.DestWarehouse   = FL.DestWarehouse,
      TL.AlternateLPN    = FL.LPN, --We will use AlternateLPN to identify which LPNs got created
      TL.InventoryClass1 = FL.InventoryClass1,
      TL.InventoryClass2 = FL.InventoryClass2,
      TL.InventoryClass3 = FL.InventoryClass3
  from LPNs TL
   join LPNs FL on (TL.LPNId = @vToLPNId) and (FL.LPNId = @vFromLPNId);

   /* Insert the new LPNDetail */
   exec @vReturnCode = pr_LPNDetails_AddOrUpdate @vToLPNId, null /* LPN Line */,
                                                 @vCoO /* Coo */, @vSKUId, null /* SKU */,
                                                 @SplitInnerPacks, @SplitQuantity, /* Quantity */
                                                 null /* rec units*/, @vReceiptId,
                                                 @vReceiptDetailId, /* Receiptid , receiptdetailid */
                                                 @vOrderId, @vOrderDetailId, @vOnhandStatus /* OnhandStatus */, null /* Operation */,
                                                 null, null, null, /* Weight, Volume , Lot */
                                                 @BusinessUnit, @vToLPNDetailId output;

  /* Adjust/reduce the Quantity from LPN */
  exec @vReturnCode = pr_LPNs_AdjustQty @vFromLPNId,
                                        @FromLPNDetailId,
                                        @vSKUId,
                                        null,             /* SKU */
                                        @SplitInnerPacks, /* InnerPacks */
                                        @SplitQuantity,   /* Quantity */
                                        '-',              /* Update Option - Reduce Qty */
                                        'N',              /* Export? Yes */
                                        null,             /* Reason Code - in future accept reason from User */
                                        null,             /* Reference */
                                        @BusinessUnit,
                                        @UserId;

  if (@vReturnCode > 0)
    goto ExitHandler;

  /* Set Status or Do Recount? */
  if (charindex('P' /* Pallet */, @Options) <> 0) and (@vPalletId is not null)
    exec pr_Pallets_UpdateCount @vPalletId;

  if (charindex('LD' /* Load */, @Options) <> 0) and (@vLoadId is not null)
    exec pr_Load_Recount @vLoadId;

  if (charindex('LOC' /* Location */, @Options) <> 0) and (@vLocationId is not null)
    exec pr_Locations_UpdateCount @vLocationId, null, '*' ;

  if (charindex('B' /* BoL */, @Options) <> 0) and (@vBoLId is not null)
    exec pr_BoL_Recount @vBoLId;

  if (charindex('S' /* Shipment */, @Options) <> 0) and (@vShipmentId is not null)
    exec pr_Shipment_Recount @vShipmentId;

  if (charindex('RH' /* Receipt */, @Options) <> 0) and (@vReceiptId is not null)
    exec pr_ReceiptHeaders_Recount @vReceiptId;

  if (charindex('OH' /* Order */, @Options) <> 0) and (@vOrderId is not null)
    exec pr_OrderHeaders_Recount @vOrderId;

  /* Insert Audit Trail */
  --Need to log AT

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_SplitLPN */

Go
