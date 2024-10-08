/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/22  VS      pr_LPNs_Ship: Pass the Bussiness Unit to process the Wave status (FBV3-1135)
  2021/08/06  VS      pr_LPNs_ShipMultiple: Made changes to generate the ShipTransaction for the Transfer Order (HA-3045)
  2021/07/31  TK      pr_LPNs_Action_BulkMove, pr_LPNs_BulkMove & pr_LPNs_ShipMultiple:
  2021/04/21  TK      pr_LPNs_ShipMultiple: Load missing values to exports table (HA-2641)
  2021/04/03  TK      pr_LPNs_ShipMultiple: Initial Revision
  2021/01/28  RKC     pr_LPNs_Ship: Made changes to initialize the New LPN status to send ship transactions (BK-137)
  2020/12/24  TK      pr_LPNs_Ship: Removed code related to Transfer order shipping (HA-1830)
  2020/11/17  RKC     pr_LPNs_Ship: Made changes to update the Location information on the LPNs (HA-1662)
  2020/07/29  TK      pr_LPNs_Move & pr_LPNs_Ship: Changes to generate exports properly on WH transfer (HA-1246)
  2020/07/07  TK      pr_LPNs_Ship: Set Pallet location to Intransit Warehouse for transfers (HA-1071)
                      pr_LPNs_Ship: Changes to ship LPN without any order info and clear load info
  2020/06/25  VS      pr_LPNs_Ship: Excluded Unallocated LPN from Background process (FB-2030)
  2020/06/10  VS      pr_LPNs_Ship: Generate the Exports for Transfer Orders (HA-110)
  2019/07/06  VS      pr_LPNs_Ship: Added @@Procid to Markers (CID-Golive)
  2018/12/03  AY      pr_LPNs_Ship: Performance improved for Packing/LPNs_Ship (FB-1202)
  2018/06/13  DK      pr_LPNs_Ship: Corrected the number of parameters to procedure pr_PickBatch_Recalculate (HPI-Support)
  2018/04/14  SV      pr_LPNs_Ship:Changes to pass reasoncode (HPI-1842)
  2017/08/29  TK      pr_LPNs_Ship: Changes to defer Location count updates(HPI-1644)
  2017/07/12  TK      pr_LPNs_Ship: Changes to improve performance in closing Loads (CIMS-1467)
  2017/02/08  VM      pr_LPNs_Ship: Take LPN out of cart when shipped and make other necessary updates (HPI-1280)
  2017/01/04  RV      pr_LPNs_Ship: Removed invalid LPN types to ship and added the control variable to validate (HPI-1234)
  2016/11/25  VM      pr_LPNs_Ship: Set Pallet status and Pallet count on Location too (HPI-1055)
  2014/12/31  TK      pr_LPNs_Ship: Updated to Export Weight and Volume of the LPN.
  2014/03/20  PK      pr_LPNs_Ship: If the LPN is the last one on the batch then update the batch status.
  2014/03/12  PK      pr_LPNs_Ship: Bug fix while updating Order status.
  2013/11/28  TD/AY   pr_LPNs_Ship: Prevent Picklane and Cart type LPNs from being shipped
  2013/10/25  PK      pr_LPNs_Ship: Updating Pallet Status.
  2012/11/15  VM/NY   pr_LPNs_Ship: Updating Orders to shipped when all LPNs are shipped (Manual picking)
                      pr_LPNs_Ship: Added Audit trial.
  2012/07/04  TD      pr_LPNs_Ship:validating LPN through control options.
  2011/10/27  AY      pr_LPNs_Ship: Bug fix - Order Details not updated correctly
  2011/10/22  NB      pr_LPNs_Ship: Minor fix - read @LPN from LPNs
  2011/10/12  AY      pr_LPNs_Ship: Moved exporting of LPNs and details to pr_Exports_LPNData
  2011/10/03  AY/NB   pr_LPNs_Ship - New Procedure to mark LPN as shipped and do exports and updates
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Ship') is not null
  drop Procedure pr_LPNs_Ship;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Ship:
    Marks an LPN as shipped or consumed (based upon whether it is on a transfer
    order or a regular customer order. Generates an appropriate Upload as well.

  UpdateOption: This will be used to check what update needs to be done while shipping LPNs
   - 'O': Update Order Status
   - 'W': Update Wave Status
   - 'L': Update Location Counts
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Ship
  (@LPNId             TRecordId,
   @LPN               TLPN,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @GenerateExports   TFlag  = 'Y' /* Yes */,
   @UpdateOption      TFlags = 'O$WL',
   @Operation         TOperation = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vLocationType     TLocationType,
          @vStorageType      TStorageType,
          @vLPNStatus        TStatus,
          @vOrderId          TRecordId,
          @vPickBatchId      TRecordId,
          @vPickBatchNo      TPickBatchNo,
          @vPalletId         TRecordId,
          @vPalletType       TTypeCode,
          @vPalletNewStatus  TStatus,
          @vNumPallets       TCount,
          @vOrderType        TOrderType,
          @vOrderStatus      TStatus,
          @vCurrentTrailerNo TInteger,
          @vCurrentTrailer   TBoL,
          @vControlCategory  TCategory,
          @vNewLPNStatus     TStatus,
          @vOldLocationId    TRecordId,
          @vOperation        TOperation,
          @vShipToId         TShipToId,
          @vLPNLocation      TLocation,
          @vToLocationId     TRecordId,
          @vToLocation       TLocation,
          @vLocWarehouse     TWarehouse,
          @vLPNDestWarehouse TWarehouse,
          @vFromWarehouse    TWarehouse,
          @vToWarehouse      TWarehouse,
          @vLPNType          TTypeCode,
          @vInnerPacks       TInnerPacks,
          @vQuantity         TQuantity,
          @vLoadId           TRecordId,
          @vLoadType         TTypeCode,
          @vCartPos          TLPN,
          @vLPNDetailId      TRecordId,
          @vLPNQuantity      TQuantity,
          @Weight            TWeight,
          @Volume            TVolume,
          @vValidLPNTypes    TControlValue,
          @vValidLPNStatus   TStatus,
          @vLocUpdateOption  TFlags,
          @vUpdateFlags      TFlags,
          @vInTransitWH      TControlValue,
          @vDebug            TFlags,
          @vMarkerXmlData    TXML,

          /* Controls */
          @vOrderTypesToShip           TFlags,
          @vOrderTypesToComplete       TFlags;

  declare @ttPickBatches     TEntityKeysTable,
          @ttMarkers         TMarkers;
begin
  SET NOCOUNT ON;

  select @vOrderTypesToShip     = 'CET',
         @vOrderTypesToComplete = 'O';

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  if (charindex('Y', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_LPNs_Ship';

  /* Code Optimization: Most often this proc is called with LPNId, so there is
     no need to do an OR condition in the next one so that it would be more
     efficient. In case caller only passed LPN and not LPNId then we take the
     extra hit and fetch the LPNId first */
  if (@LPNId is null) and (@LPN is not null)
    select @LPNId = LPNId
    from LPNs
    where (LPN = @LPN);

  /* Get LPN Info */
  select @LPNId             = LPNId,
         @LPN               = LPN,
         @vLPNDestWarehouse = DestWarehouse,
         @vLPNType          = LPNType,
         @vLPNStatus        = Status,
         @vPalletId         = PalletId,
         @Weight            = ActualWeight,
         @Volume            = ActualVolume,
         @vOrderId          = OrderId,
         @vPickBatchId      = PickBatchId,
         @vPickBatchNo      = PickBatchNo,
         @vOldLocationId    = LocationId,
         @vLPNLocation      = Location,
         @vInnerPacks       = InnerPacks,
         @vQuantity         = Quantity,
         @vCartPos          = AlternateLPN,
         @vLoadId           = LoadId,
         @BusinessUnit      = coalesce(@BusinessUnit, BusinessUnit) /* VM: Most often we send LPNId, so get BusinessUnit here only if not sent */
  from vwLPNs
  where (LPNId = @LPNId);

  select @vOrderType     = OrderType,
         @vFromWarehouse = Warehouse,
         @vShipToId      = ShipToId
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Get Load info */
  select @vLoadType      = LoadType,
         @vFromWarehouse = coalesce(@vFromWarehouse, FromWarehouse),
         @vShipToId      = coalesce(@vShipToId, ShipToId)
  from Loads
  where (LoadId = @vLoadId);

  /* Get the LPN Types to validate the given LPN is able to ship or not */
  select @vValidLPNTypes = dbo.fn_Controls_GetAsString('Shipping', 'ValidLPNTypes', 'SC' /* ShipCarton, 'Carton' */,  @BusinessUnit, @UserId);

  /* Get the LPN Status to validate the given LPN is able to ship or not */
  select @vValidLPNStatus = dbo.fn_Controls_GetAsString('Shipping', 'ValidLPNStatus', 'DEL' /* Packed, Staged, 'Loaded' */,  @BusinessUnit, @UserId);

  /* Set the New LPN status */
  set @vNewLPNStatus = 'S' /* Shipped */

  /* Set Operation Type */
  /* If the order type is transfer or if the LPNs that is being shipped is not associated to any order then
     consider that as Transfer order */
  if (@vOrderType = 'T') or
     ((@vLoadId > 0) and (@vLoadType = 'Transfer'))
    select @vOperation = 'ShipTransferOrder';

  /* Validations */
  /* Make sure LPN is Valid */
  if (@LPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (charindex(@vLPNType, @vValidLPNTypes) = 0)
    set @vMessageName = 'NotAShippableLPNType';
  else
  if (coalesce(@vOrderId, 0) = 0) and (@vOperation <> 'ShipTransferOrder')
    set @vMessageName = 'LPNNotOnAnyOrder';
  else
  if (@vLPNStatus = 'S' /* Shipped */)
    set @vMessageName = 'LPNAlreadyShipped';
  else
  if (charindex(@vLPNStatus, @vValidLPNStatus) = 0)
    set @vMessageName = 'LPNNotReadyToShip';

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_LPNs_Validations';

  /* Get Pallet Type of the Pallet of the LPN */
  if (@vPalletId is not null)
    select @vPalletType = PalletType
    from Pallets
    where PalletId = @vPalletId;

  /* Get Current Shipping Trailer from Control */
  select @vCurrentTrailerNo = dbo.fn_Controls_GetAsInteger('Shipping', 'TrailerNumber', '1', @BusinessUnit, @UserId);
  select @vCurrentTrailer = dbo.fn_Pad(@vCurrentTrailerNo, 10);

  /* Clear the Location of the LPN, Location will be updated later
     If LPN on Cart, then remove it and clear alternate LPN fields as well */
  update LPNs
  set @vNewLPNStatus  = coalesce(@vNewLPNStatus, Status),
      LocationId      = null,  /* Clear location */
      Location        = null,
      PalletId        = case when charindex(@vPalletType, 'CTHF' /* Carts */) > 0 then null else PalletId     end,
      Pallet          = case when charindex(@vPalletType, 'CTHF' /* Carts */) > 0 then null else Pallet       end,
      AlternateLPN    = case when charindex(@vPalletType, 'CTHF' /* Carts */) > 0 then null else AlternateLPN end,
      BoL             = @vCurrentTrailer,
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @UserId
  where (LPNId = @LPNId);

  if (@vPalletType = 'C' /* Cart */)
    begin
      /* Clear Alternate LPN on the cart position for reuse */
      update LPNs
      set AlternateLPN = null
      where (LPN = @vCartPos) and (AlternateLPN = @LPN);

      /* Update Pallet counts */
      exec pr_Pallets_UpdateCount @vPalletId, null, '*' /* UpdateOption */
   end

  /* Update Order Details */
  ;with LPNOrderDetails(OrderId, OrderDetailId, Quantity) as
  (
    select LD.OrderId, LD.OrderDetailId, sum(LD.Quantity)
    from LPNDetails LD
    where (LD.LPNId = @LPNId)
    group by LD.OrderId, LD.OrderDetailId
  )
  update OrderDetails
  set UnitsShipped = UnitsShipped + L.Quantity
  from OrderDetails OD
       join LPNOrderDetails L on (OD.OrderDetailId = L.OrderDetailId) and
                                 (OD.OrderId       = L.OrderId);

  /* If we think we are done, then update order status - it would return the
     new status */
  select @vOrderStatus = null; /* Allow the Stored Procedure to recalculate the status */

  if (charindex('O', @UpdateOption) > 0) and
     (not exists(select * from OrderDetails
                 where (OrderId      = @vOrderId) and
                       (UnitsShipped < UnitsAuthorizedToShip)))
    exec pr_OrderHeaders_SetStatus @vOrderId, @vOrderStatus output, @UserId;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_OrderHeaders_SetStatus';

  if (charindex('W', @UpdateOption) > 0)
    begin
      /* Insert the PickBatches which are assosiated with the LPNs into temp table */
      if (@vPickBatchId is null)
        insert into @ttPickBatches (EntityId, EntityKey)
          select distinct PBD.PickBatchId, PBD.PickBatchNo
          from PickBatchDetails PBD
            join OrderDetails OD on (PBD.OrderDetailId = OD.OrderDetailId)
            join LPNDetails   LD on (LD.OrderDetailId  = OD.OrderDetailId)
          where (LD.LPNId = @LPNId);
      else
        insert into @ttPickBatches (EntityId, EntityKey)
          select @vPickBatchId, @vPickBatchNo

      /* Do this only if the LPN is not associated with a single Wave i.e. it must
         be linked to multiple waves and we are not doing defered update */
      if (@vPickBatchId is null) and (charindex('$W', @UpdateOption) = 0)
          /* ignore the Waves for which all LPNs are not shipped */
          delete ttPB
          from @ttPickBatches ttPB
            join PickBatchDetails PBD on (ttPB.EntityId     = PBD.PickBatchId )
            join OrderDetails     OD  on (PBD.OrderDetailId = OD.OrderDetailId)
            join LPNDetails       LD  on (OD.OrderDetailId  = OD.OrderDetailId)
            join LPNs             L   on (LD.LPNId          = L.LPNId         )
          where (L.Status <> 'S' /* Shipped */);

      /* Defer updates if possible */
      select @vUpdateFlags = case when (charindex('$W', @UpdateOption) > 0) then '$S' else 'S' end;

      /* if there are no LPNs which are to be shipped on the batch then call pickbatch set status to update
         the batch status */
      if (exists(select * from @ttPickBatches))
        exec pr_PickBatch_Recalculate @ttPickBatches, @vUpdateFlags/* compute - Status only */, @UserId, @BusinessUnit;

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_PickBatch_Recalculate';
    end

  /* Update Pallet Status if the LPN is on a pallet */
  if (@vPalletId is not null)
    begin
      exec pr_Pallets_SetStatus @vPalletId, @vPalletNewStatus output;

      /* To update location counts when Pallet shipped */
      select @vNumPallets = case when @vPalletNewStatus = 'S' /* Shipped */ then 1 else 0 end;
    end

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_Pallets_SetStatus';

  /* if a New LPN has been putaway for the first time, then create an
     Inventory Change transaction. On the other hand, if a Received LPN has
     been putaway for the first time, create a Receipt Transaction */
  if (@vNewLPNStatus = 'C' /* Consumed */) and (@GenerateExports = 'Y' /* Yes */)
    begin
      exec @vReturnCode = pr_Exports_LPNData 'Xfer' /* Xfer completed */,
                                            @LPNId     = @LPNId,
                                            @TransQty  = @vQuantity,
                                            @CreatedBy = @UserId;
    end
  else
  if (@vNewLPNStatus = 'S' /* Shipped */) and (@GenerateExports = 'Y' /* Yes */) and
     (coalesce(@vOperation, '') <> 'ShipTransferOrder')
    begin
      exec @vReturnCode = pr_Exports_LPNData 'Ship' /* Ship */,
                                            @LPNId     = @LPNId,
                                            @Weight    = @Weight,
                                            @Volume    = @Volume,
                                            @OrderId   = @vOrderId,
                                            @TransQty  = @vQuantity,
                                            @CreatedBy = @UserId;
    end

 if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_Exports_Data';

  /* Mark LPN as shipped */
  set @vNewLPNStatus = 'S' /* Shipped */
  exec @vReturnCode = pr_LPNs_SetStatus @LPNId, @vNewLPNStatus output, 'U' /* OnhandStatus - Unavailable */;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'LPNShipped', @UserId, null /* ActivityTimestamp */,
                            @LPNId   = @LPNId,
                            @OrderId = @vOrderId;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_LPNs_SetStatus';

  /* If Order was just shipped, then export the data if this is not part of a Load */
  if (@vOrderStatus = 'S' /* Shipped */)
    exec pr_OrderHeaders_AfterClose @vOrderId, @vOrderType, @vOrderStatus, @vLoadId, default /* ReasonCode */,
                                    @BusinessUnit, @UserId, 'Y'/* GenerateExports */, 'LPNs_Ship'/* Operation */;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_OrderHeaders_AfterClose';

  /* If the LPN that has been shipped was in a Location, then update its' counts */
  if (@vOldLocationId is not null)
    begin
      /* If update Option = L then update now, else do a deferred update */
      select @vLocUpdateOption = case when (charindex('L', @UpdateOption) > 0) then '-' /* Subtract */ else '$' end;

      /* Update Old Location Counts (-NumPallets, -NumLPNs, -InnerPacks, -Quantity) */
      exec @vReturnCode = pr_Locations_UpdateCount @LocationId   = @vOldLocationId,
                                                  @NumLPNs      = 1,
                                                  @NumPallets   = @vNumPallets,
                                                  @InnerPacks   = @vInnerPacks,
                                                  @Quantity     = @vQuantity,
                                                  @UpdateOption = @vLocUpdateOption,
                                                  @ProcId       = @@ProcId,
                                                  @Operation    = 'LPNs_Ship';
    end

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'End_LPNs_Ship';
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'LPN', @LPNId, @LPN, 'LPNs_Ship', @@ProcId, 'Markers_LPNs_Ship';

ErrorHandler:
  /* This return code is handled back in pr_Entities_ExecuteProcess */
  if (@Operation = 'BackgroundProcess') and (@vMessageName in ('LPNNotOnAnyOrder', 'LPNAlreadyShipped'))
    set @vReturnCode = 2;
  else
  /* Error handling for any process calling this proc */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Ship */

Go
