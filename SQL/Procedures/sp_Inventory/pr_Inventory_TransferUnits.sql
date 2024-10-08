/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/10  VS      pr_Inventory_TransferUnits: When Transfer LPN to LPN update Reserve Qty if From LPN is Reserved (CID-1859)
  2021/06/25  RKC     pr_Inventory_TransferUnits: Made changes to get the correct ToLPNDetailId value (HA-2926)
  2021/04/14  TK      pr_Inventory_TransferUnits: When transferring inventory to a new LPN then change the LPN Type (HA-GoLive)
  2020/03/03  RKC     pr_Inventory_TransferUnits: Changed the position of calling pr_Locations_UpdateCount to update the Location count
  2020/04/23  TK      pr_Inventory_TransferUnits: While transferring inventory from a received LPN then try to find an LPN detail with un-available onhandstatus (HA-290)
                      pr_Inventory_TransferUnits: Changes to update ReceivedCounts in regards to destination LPN when inventory
  2020/04/01  TK      pr_Inventory_TransferUnits: Changes to populate InventoryClass from source LPN to destination LPN
  2019/04/27  SV      pr_Inventory_TransferUnits: Resolved the issue with updating IPs over the LPN even if the InvUoM of the SKU is of EA (CA Go-Live Support)
  2018/12/05  OK      pr_Inventory_TransferUnits: Bug fix to transfer the inventory to new LPN (S2GCA-440)
  2018/11/21  TK      pr_Inventory_TransferUnits: Bug Fix to transfer inventory in cases to a LPN having units with different SKU (S2GCA-399)
  2018/07/03  YJ      pr_Inventory_TransferUnits: Changes to get the SKU DIMS and update LPNDetails Weight, Volume with TransferWeight, TransferVolume: Migrated from staging (S2G-727)
  2018/07/02  YJ      pr_Inventory_TransferUnits: Changes to update LPNDetails-Weight,Volume: Migrated from staging (S2G-727)
  2017/02/27  KL      pr_Inventory_TransferUnits: Add the quantity to the available line when no order is associated with the reserved detail line (FB-905)
  2016/12/22  KL      pr_Inventory_TransferUnits: Enhanced to update the PickTicket, LoadId, LoadNumber, PickBatchId, PickBatchNo and TrackingNo when
  2016/10/04  AY      pr_Inventory_TransferUnits: Bug fix: Lines with diff. Order details being merged (HPI-GoLive)
  2016/06/15  TK      pr_Inventory_TransferUnits: Changes made to update PickBatch details (NBD-606)
  2016/05/27  DK      pr_Inventory_TransferUnits: Bug fix to update the LPNs count on OrderHeader (FB-698).
  2015/06/19  RV      pr_Inventory_TransferUnits: Call pr_Pallets_UpdateCount for To LPN's and From LPN's Pallet
  2015/04/01  DK      pr_Inventory_TransferUnits: Update LocationId and Location on ToLPN.
  2015/02/27  TK      pr_Inventory_TransferUnits: Issue fix due to InnerPacks.
  2015/02/05  TK      pr_Inventory_TransferUnits: Update UCCBarcode and PackageSeqNo if From LPN is of Packed status.
  2014/09/16  PKS     pr_Inventory_TransferUnits: Expiry date updated on ToLPN.
  2014/08/14  PKS     pr_Inventory_TransferUnits: sum of Innerpacks updated on ToLPN.
  2014/08/12  AY      pr_Inventory_TransferUnits: Added ReceiptNumber and Source LPN on ToLPN
  2014/05/01  PV      pr_Inventory_TransferUnits: Bug fix to calculate UnitsPerPackage of destination
  2014/04/18  TD      pr_Inventory_TransferUnits: Issue fixed while transfering Units.
  2014/03/18  TD      pr_Inventory_TransferUnits, pr_Inventory_ValidateTransferInventory:Changes to
  2014/03/11  TD      pr_Inventory_TransferUnits:Bug Fix: Update Lcoations while doing transfering units from
  2014/01/21  TD      pr_Inventory_TransferUnits: bug fix:Changes to transfer inventory from LPN to
  2014/01/02  TD      pr_Inventory_TransferUnits: Changes to merge LPN lines if those are with same SKU.
  2103/11/25  TD      pr_Inventory_TransferUnits:Changes migrated from OB(To Eliminate unwanted exports.)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_TransferUnits') is not null
  drop Procedure pr_Inventory_TransferUnits;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_TransferUnits:

  This procedure will transfer the units and all related info from one LPN to another LPN.
  and this procedure will return the Units and Innerpacks Transfered.

  Based upon the scenario a new line may be created or an existing line updated and
  in both cases the create/Updated line id is returned back as @ToLPNDetailId
-------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_TransferUnits
  (@FromLPNId           TRecordId,
   @FromLPNDetailId     TRecordId,
   @SKUId               TRecordId,
   @TransferInnerPacks  TInnerPacks output,
   @TransferQuantity    TQuantity   output,
   @ToLPNId             TRecordId,
   @ExportOption        TFlag,
   @ReasonCode          TReasonCode,
   @Operation           TOperation = null,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @ToLPNDetailId       TRecordId  = null output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vFromLPNId              TRecordId,
          @vFromLPN                TLPN,
          @vFromLPNDetailId        TRecordId,
          @vFromLPNStatus          TStatus,
          @vFromLocationId         TRecordId,
          @vFromLPNOrderId         TRecordId,
          @vFromLPNTrackingNo      TTrackingNo,
          @vTransferSKUId          TRecordId,
          @vInventoryUoM           TUoM,
          @vReceiptId              TRecordId,
          @vReceiptDetailId        TRecordId,
          @vOrderDetailId          TRecordId,
          @vPickBatchId            TRecordId,
          @vPickBatchNo            TPickBatchNo,
          @vOnhandStatus           TStatus,
          @vLPNDetailQty           TQuantity,
          @vFromLPNUnitsPerPackage TQuantity,
          @vFromLPNInnerPacks      TQuantity,
          @vFromLPNReceiverId      TRecordId,
          @vToLPNId                TRecordId,
          @vToLPN                  TLPN,
          @vToLPNStatus            TStatus,
          @vToLocationId           TRecordId,
          @vToLPNUnitsPerPackage   TQuantity,
          @vToLPNInnerPacks        TQuantity,
          @vToLPNQuantity          TQuantity,
          @vTransQty               TQuantity,
          @vDestWarehouse          TWarehouse,
          @vWeight                 TWeight,
          @vVolume                 TVolume,
          @vCaseWeight             TWeight,
          @vCaseVolume             TVolume,
          @vUnitWeight             TWeight,
          @vUnitVolume             TVolume,
          @vTransferWeight         TWeight,
          @vTransferVolume         TVolume,
          @vMaxSeqNo               TInteger,
          @vUCCBarcode             TBarcode,
          @vFromLPNPalletId        TRecordId,
          @vToLPNPalletId          TRecordId,

          @vValidatePackages       TControlValue;
begin
begin try
  SET NOCOUNT ON;

  /* initialize */
  set @ToLPNDetailId = null;

  /* Get From LPN information */
  select @vFromLPNId         = LPNId,
         @vFromLPN           = LPN,
         @vFromLPNDetailId   = LPNDetailId,
         @vFromLPNStatus     = LPNStatus,
         @vTransferSKUId     = SKUId,
         @vReceiptId         = ReceiptId,
         @vReceiptDetailId   = ReceiptDetailId,
         @vOrderDetailId     = OrderDetailId,
         @vPickBatchId       = PickBatchId,
         @vPickBatchNo       = PickBatchNo,
         @vOnhandStatus      = OnhandStatus,
         @vFromLPNUnitsPerPackage
                             = UnitsPerPackage,
         @vFromLPNInnerPacks = InnerPacks,
         @vWeight            = Weight,
         @vVolume            = Volume,
         @vLPNDetailQty      = Quantity,
         @vFromLPNPalletId   = PalletId,
        -- @vFromLPNTrackingNo = TrackingNo,
         @vFromLocationId    = LocationId,
         @vFromLPNOrderId    = OrderId,
         @vFromLPNReceiverId = ReceiverId
  from vwLPNDetails
  where (LPNId       = @FromLPNId) and
        (LPNDetailId = @FromLPNDetailId);

  /* Get the SKU DIMS */
  select @vCaseWeight   = InnerPackWeight,
         @vCaseVolume   = InnerPackVolume,
         @vInventoryUoM = InventoryUoM,
         @vUnitWeight   = UnitWeight,
         @vUnitVolume   = UnitVolume
  from SKUs
  where (SKUId = @vTransferSKUId);

  /* Get To LPN information */
  select @vToLPNId         = LPNId,
         @vToLPN           = LPN,
         @vDestWarehouse   = DestWarehouse,
         @vToLPNStatus     = Status,
         @vToLPNInnerPacks = InnerPacks,
         @vToLocationId    = Locationid,
         @vToLPNPalletId   = PalletId
  from LPNs
  where (LPNId = @ToLPNId);

  /* Temp fix - if user tried to transfer cases to new lpn */
  if (((@vToLPNStatus <> 'N'/* New */) and (@vToLPNInnerPacks = 0)) or (charindex('CS', @vInventoryUoM) = 0))
    select @TransferInnerPacks = 0;

  /* If user is trying to transfer innerpacks then find out the line which has innerpacks and with
     units per package is same as from LPN detail units per package else create a new line */
  if (@TransferInnerPacks > 0)
    select @ToLPNDetailId         = LPNDetailId,
           @vToLPNUnitsPerPackage = UnitsPerPackage,
           @vToLPNInnerPacks      = InnerPacks,
           @vToLPNQuantity        = Quantity
    from LPNDetails
    where (LPNId = @ToLPNId) and
          (SKUId = @vTransferSKUId) and
          (InnerPacks > 0) and
          (UnitsPerPackage = @vFromLPNUnitsPerPackage) and
          /* Add the quantity to the available line when no order is associated with the reserved detail line */
          (OnhandStatus = case when (@vOrderDetailId is not null) and (OrderDetailId = @vOrderDetailId) then 'R' /* Reserved */
                               when @vFromLPNStatus = 'R' /* Received */ then 'U' /* Un-Available */
                               else 'A' /* Available */
                          end) and
           /* What is the necessity of validating with RDId (earlier) and ODId here */
           (coalesce(OrderDetailId, 0)   = coalesce(@vOrderDetailId, OrderDetailId, 0));
  else
    /* If user it trying to transfer units then find out a line where innerpacks is zero else create a new line */
    select @ToLPNDetailId         = LPNDetailId,
           @vToLPNUnitsPerPackage = UnitsPerPackage,
           @vToLPNInnerPacks      = InnerPacks,
           @vToLPNQuantity        = Quantity
    from LPNDetails
    where (LPNId = @ToLPNId) and
          (SKUId = @vTransferSKUId) and
          (InnerPacks = 0) and
          /* Add the quantity to the available line when no order is associated with the reserved detail line */
          (OnhandStatus = case when (@vOrderDetailId is not null) and (OrderDetailId = @vOrderDetailId) then 'R' /* Reserved */
                               when @vFromLPNStatus = 'R' /* Received */ then 'U' /* Un-Available */
                               else 'A' /* Available */
                          end) and
           /* What is the necessity of validating with RDId (earlier) and ODId here */
           (coalesce(OrderDetailId, 0)   = coalesce(@vOrderDetailId, OrderDetailId, 0));

  /* set value as 0 if the values are null */
  select @vToLPNUnitsPerPackage   = coalesce(@vToLPNUnitsPerPackage, 0),
         @vToLPNQuantity          = coalesce(@vToLPNQuantity, 0),
         @vToLPNInnerPacks        = coalesce(@vToLPNInnerPacks, 0),
         @vFromLPNUnitsPerPackage = coalesce(@vFromLPNUnitsPerPackage, 0),
         @vFromLPNInnerPacks      = coalesce(@vFromLPNInnerPacks, 0),
         @TransferInnerPacks      = coalesce(@TransferInnerPacks, 0),
         @TransferQuantity        = coalesce(@TransferQuantity, 0),
         @vTransferWeight         = case when @TransferInnerPacks > 0 then (@TransferInnerPacks * @vCaseWeight)
                                         when @TransferQuantity   > 0 then (@TransferQuantity   * @vUnitWeight)
                                    end,
         @vTransferVolume         = case when @TransferInnerPacks > 0 then (@TransferInnerPacks * @vCaseVolume)
                                         when @TransferQuantity   > 0 then (@TransferQuantity   * @vUnitVolume)
                                    end,
         @vValidatePackages       = dbo.fn_Controls_GetAsString('TransferInventory', 'ValidateUnitsPackage', 'Y' /* Yes */,
                                                                @BusinessUnit, @UserId);

  /* validate UnitsperPackage here-
    We need to allow users to transfer Quantity from one lPN to another LPN if the
    UnitsperInnerPacks are same on the both LPNs  */

  /* Calculate UnitsPerpackage here if not update on LPNs yet */
  if ((@vFromLPNUnitsPerPackage <= 0) and (@vFromLPNInnerPacks > 0))
    begin
       select @vFromLPNUnitsPerPackage = (@vLPNDetailQty / @vFromLPNInnerPacks);
    end

  if ((@TransferQuantity <= 0) and (@vToLPNInnerPacks > 0))
    begin
       select @vToLPNUnitsPerPackage = (@vToLPNQuantity / @vToLPNInnerPacks);
    end

  /* If the To LPN is New and empty then consider the FromLPN pack configuration */
  if ((@vToLPNStatus = 'N'/* New */) and (@vToLPNQuantity = 0 ))
    select @vToLPNUnitsPerPackage = @vFromLPNUnitsPerPackage;

  /* if the ToLPN has quantity then we need to validate InnerPacks here */
  if ((@vFromLPNUnitsPerPackage <> @vToLPNUnitsPerPackage) and
      (coalesce(@vToLPNQuantity, 0) > 0)  and
      (@vValidatePackages = 'Y' /* yes */))
    set @vMessageName = 'TransferInventory_UnitPackagesAredifferent';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* if every thing is okay, then we need to calclate Quantity/innerpacks based on the
     input */
  if (@TransferQuantity = 0) or (@TransferInnerPacks = 0)
    begin
      if (@TransferQuantity = 0)
        begin
          select @TransferQuantity = (@vToLPNUnitsPerPackage * @TransferInnerPacks);
        end

      /* Currently this proc is being called from pr_RFC_TransferInventory itself.
         @TransferInnerPacks is being evaluated with the same login in pr_RFC_TransferInventory
         and not sure why it re-evaluated here. Also, with the below lines of code, Innerpacks is updated
         incorrectly if the InvUoM of the SKU is "EA" */
      /* calculate Innerpacks here */
      --if (@TransferInnerPacks = 0) and (@vToLPNUnitsPerPackage > 0)
      --  select @TransferInnerPacks = (@TransferQuantity / @vToLPNUnitsPerPackage);
    end

  /* Update Destination LPN with the Source LPN (Owner and Warehouse) if the
     Destination LPN status is New */
  if (@vToLPNStatus = 'N'/* New */)
    begin
      if (@vFromLPNStatus = 'D' /* Packed */)
        begin
          /* Get the max value of PackageSeqNo */
          select @vMaxSeqNo = max(PackageSeqNo)
          from LPNs
          where OrderId = @vFromLPNOrderId;

          /* generate SSCC barcode for the LPN  */
          exec pr_ShipLabel_GetSSCCBarcode @UserId, @BusinessUnit, @vToLPN, Default /* Barcode Type */,
                                           @vUCCBarcode output;
        end

      update TL
      set LPNType         = FL.LPNType,
          PickTicketNo    = FL.PickTicketNo,
          SalesOrder      = FL.SalesOrder,
          TaskId          = FL.TaskId,
          ShipmentId      = FL.ShipmentId,
          LoadId          = FL.LoadId,
          LoadNumber      = FL.LoadNumber,
          Ownership       = FL.Ownership,
          LocationId      = FL.LocationId,
          Location        = FL.Location,
          DestWarehouse   = FL.DestWarehouse,
          Status          = FL.Status,
          OnhandStatus    = @vOnhandStatus,
          ReceiptId       = case when FL.Status = 'R' then FL.ReceiptId else TL.ReceiptId end,    -- ReceiptId is not updated on purpose as this LPN is not received against the RO
          ReceiptNumber   = FL.ReceiptNumber,
          ReceiverId      = case when FL.Status = 'R' then FL.ReceiverId else TL.ReceiverId end,   -- ReceiverId is not updated on purpose as this LPN is not received against the RO
          ReceiverNumber  = FL.ReceiverNumber,
          PickBatchId     = FL.PickBatchId,
          PickBatchNo     = FL.PickBatchNo,
          PackageSeqNo    = coalesce(TL.PackageSeqNo, (@vMaxSeqNo + 1)),
          UCCBarcode      = coalesce(TL.UCCBarcode, @vUCCBarcode),
          InventoryClass1 = FL.InventoryClass1,
          InventoryClass2 = FL.InventoryClass2,
          InventoryClass3 = FL.InventoryClass3,
          Reference       = FL.LPN,
          ExpiryDate      = FL.ExpiryDate
      from LPNs TL, LPNs FL
      where (TL.LPNId = @vToLPNId) and
            (FL.LPNId = @vFromLPNId);

      update LPNDetails
      set OnhandStatus = @vOnhandStatus
      where (LPNId = @vToLPNId);

      /* Should not generate exports if we are transferring to a New LPN */
      select @ExportOption = 'N'; /* No */
    end

  /* Update LPN Details if the SKU already exists in the LPN for the same Receipt or Order */
  if (@ToLPNDetailId is not null)
    begin
      update LPNDetails
      set Quantity        = Quantity + @TransferQuantity,
          InnerPacks      = InnerPacks + @TransferInnerPacks,
          ReservedQty     = case
                              when (coalesce(@vOrderDetailId ,0) > 0) then
                                (ReservedQty + @TransferQuantity)
                              else
                                ReservedQty
                             end,
          ReceivedUnits   = case
                              when (@vFromLPNStatus = 'R' /* Received */) then
                                (ReceivedUnits + @TransferQuantity)
                              else
                                ReceivedUnits
                            end,
          Weight          = Weight + coalesce(@vTransferWeight, 0),
          Volume          = Volume + coalesce(@vTransferVolume, 0)
      where (LPNDetailId = @ToLPNDetailId);
    end
  else
  /* If entire line is to be transferred, then just update it */
  if (@vLPNDetailQty = @TransferQuantity)
    begin
      update LPNDetails
      set LPNId   = @vToLPNId
      where (LPNDetailId = @vFromLPNDetailId);

      select @ToLPNDetailId = @vFromLPNDetailId,
             @vTransQty     = - @TransferQuantity;
    end
  else
    begin
      /* Copy the details of From LPN Line as ToLPNLine */
      insert into LPNDetails (LPNId, CoO, SKUId, OnhandStatus, InnerPacks,
                              Quantity, UnitsPerPackage, ReceivedUnits, ReceiptId,
                              ReceiptDetailId, OrderId, OrderDetailId, Weight,Volume,
                              Lot, SerialNo, LastPutawayDate, ReferenceLocation,
                              PickedBy, PickedDate, PackedBy, PackedDate, UDF1, UDF2,
                              UDF3, UDF4, UDF5, BusinessUnit, CreatedBy)
        select @vToLPNId, CoO, SKUId, OnhandStatus, coalesce(@TransferInnerPacks, 0),
               @TransferQuantity, UnitsPerPackage, @TransferQuantity, ReceiptId,
               ReceiptDetailId, OrderId, OrderDetailId, @vTransferWeight, @vTransferVolume,
               Lot, SerialNo, LastPutawayDate, ReferenceLocation, PickedBy,
               PickedDate, PackedBy, PackedDate, UDF1, UDF2, UDF3,
               UDF4, UDF5, BusinessUnit, @UserId
        from LPNDetails
        where (LPNDetailId = @FromLPNDetailId);

      /* Get the DetailId of the inserted value. We need to return the id of the new line
         created to the caller */
      select @ToLPNDetailId  = SCOPE_IDENTITY();
    end

  /* If user is transferring inventory from a received LPN then update ReceivedCounts table
     with destination LPN info, source LPN quantities from ReceivedCounts table will be decremented
     in LPNs_AdjustQty proc */
  if (@vFromLPNStatus = 'R'/* Received */)
    /* Update ReceivedCounts table also to reflect the change */
    exec pr_ReceivedCounts_AddOrUpdate  @vToLPNId, @ToLPNDetailId, @TransferInnerPacks, @TransferQuantity,
                                        @vReceiptId, @vFromLPNReceiverId, @vReceiptDetailId,
                                        @UpdateOption = '+' /* Increment */,
                                        @BusinessUnit = @BusinessUnit, @UserId = @UserId;

  /* Recount LPN after inserting/updating a detail line */
  exec @vReturnCode = pr_LPNs_Recount @vToLPNId, @UserId;

  /* Call here to update ToLocation Counts and status */
  exec pr_Locations_UpdateCount @vToLocationId, null /* Location */, '$' /* Defer update */;

  /* Generate exports for ToLPN if the export option is true - this is when transferring
     from one LPN to another LPN of a different Warehouse */
  if ((@ExportOption = 'Y' /* Yes */) and
      (@vOnhandStatus in ('A' /* Available */, 'R' /* Reserved */)))
    exec @vReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                           @LPNDetailId = @ToLPNDetailId,
                                           @TransQty    = @TransferQuantity,
                                           @ReasonCode  = @ReasonCode,
                                           @CreatedBy   = @UserId;

  if (@vReturnCode > 0)
    goto ErrorHandler;

  /* Adjust down the from LPN, if entire line was not moved. Exports are taken care of the procedure if required */
  if ((@vLPNDetailQty <> @TransferQuantity)  or
      ((@vLPNDetailQty = @TransferQuantity) and (coalesce(@ToLPNDetailId, 0) > 0) and
       (coalesce(@ToLPNDetailId, 0) <> coalesce(@vFromLPNDetailId, 0))))
    begin
      exec @vReturncode = pr_LPNs_AdjustQty @vFromLPNId,
                                            @vFromLPNDetailId,
                                            @SKUId,
                                            null /* @vSKU */,
                                            @TransferInnerPacks,
                                            @TransferQuantity,
                                            '-' /* Update Option - Subtract Qty */,
                                            @ExportOption,
                                            @ReasonCode,  /* Reason Code */
                                            null, /* Reference */
                                            @BusinessUnit,
                                            @UserId;
    end
  else
  if (@vLPNDetailQty = @TransferQuantity)
    begin
      /* Recount LPN */
      exec @vReturnCode = pr_LPNs_Recount @vFromLPNId, @UserId;


      /* Call here to update From LPN's Pallet Counts if pallet is present*/
      if (@vFromLPNPalletId is not null)
        exec @vReturnCode = pr_Pallets_UpdateCount @PalletId     = @vFromLPNPalletId,
                                                   @NumLPNs      = 1,
                                                   @InnerPacks   = @TransferInnerPacks,
                                                   @Quantity     = @TransferQuantity,
                                                   @UpdateOption = '-' /* Subtract */;

      /* Generate exports for FromLPN if the export option is true - this is when transferring
         from one LPN to another LPN of a different Warehouse */
      if ((@ExportOption = 'Y' /* Yes */) and
          (@vOnhandStatus in ('A' /* Available */, 'R' /* Reserved */)))
        exec @vReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                               @LPNId       = @vFromLPNId,
                                               @SKUId       = @vTransferSKUId,
                                               @LPNDetailId = @vFromLPNDetailId,
                                               @TransQty    = @vTransQty,
                                               @ReasonCode  = @ReasonCode,
                                               @CreatedBy   = @UserId;
    end

  /* Update From Location Counts and status */
  if (@vFromLocationId is not null)
    exec pr_Locations_UpdateCount @vFromLocationId, null /* Location */, '$' /* Defer update */;

  /* Update To LPN's Pallet Counts if pallet is present */
  if (@vToLPNPalletId is not null)
    exec @vReturnCode = pr_Pallets_UpdateCount @PalletId    = @vToLPNPalletId,
                                              @UpdateOption = '*' /* Re Compute */;

  /* Update Order Headers LPN count here */
  if (@vFromLPNOrderId is not null)
    exec pr_OrderHeaders_Recount @vFromLPNOrderId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_TransferUnits */

Go
