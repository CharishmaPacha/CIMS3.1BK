/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/07  RKC     pr_RFC_Shipping_UnLoad: Made changes to revert the LPNs status back to putaway for Contractor Transfer Loads (HA-2875)
  2021/04/14  SAK     pr_RFC_Shipping_UnLoad: Prot back from HA patches to 3.0 dev (HA-2617)
  2021/03/17  MS      pr_RFC_Shipping_UnLoad: Bol & Shipment recalculate caller changes (HA-1935)
  2021/03/13  TK      pr_RFC_Shipping_UnLoad: Fix order status issue (HA-2102)
  2021/03/06  VS      pr_RFC_Shipping_UnLoad: Remove the Orderfrom Load when we don't have any shipments (HA-2078)
  2021/03/02  AY      pr_RFC_Shipping_UnLoad: Remove Pallets from Load (HA MockGoLive)
  2021/02/16  AY/MS   pr_RFC_Shipping_Load, pr_RFC_Shipping_UnLoad: Renamed Status to LPNStatus (HA-2002)
  2020/12/11  RKC     pr_RFC_Shipping_ValidateLoad, pr_RFC_Shipping_UnLoad: Added validation to not allow to un-load the
  2020/08/26  TK      pr_RFC_Shipping_UnLoad: Changes to mark Pallet status as staged on unload (S2GCA-1248)
  2020/06/13  TK      pr_RFC_Shipping_UnLoad: Bug fix in pallets reclaculate (HA-914)
  2020/01/24  RIA     pr_RFC_Shipping_Load, pr_RFC_Shipping_UnLoad : Included AuditTrail (CIMSV3-689)
                      pr_RFC_Shipping_UnLoad & pr_RFC_Shipping_ValidateLoad:
  2018/08/07  TK      pr_RFC_Shipping_Load & pr_RFC_Shipping_UnLoad: Fixed several issues related to Loading (S2GCA-117 & S2GCA-118)
  2018/06/16  VS/VM   pr_RFC_Shipping_UnLoad: Validation is Added i.e LoadNumber contains that LPN or not (S2G-881)
  2018/05/16  RV      pr_RFC_Shipping_UnLoad: Bug fixed to un load all LPNs on Pallet while user gives input as Pallet and
  2013/11/14  TD      pr_RFC_Shipping_UnLoad:AuditLog while unloading.
  2013/10/11  PK      Added pr_RFC_Shipping_Load, pr_RFC_Shipping_UnLoad.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Shipping_UnLoad') is not null
  drop Procedure pr_RFC_Shipping_UnLoad;
Go
/*------------------------------------------------------------------------------
  pr_RFC_Shipping_UnLoad: Procedure to remove Pallets/LPNs from a Load. This doesn't
    necessarily mean that the Pallet/LPN was loaded onto the Truck. i.e. even a Pallet/LPN
    which is in Packed/Staged statuses could be unloaded as this procedure works like
    "Remove from Load"
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Shipping_UnLoad
  (@xmlInput   xml,
   @xmlResult  xml          output)
as
  declare @vMessageName         TMessageName,
          @vReturnCode          TInteger,
          @vRecordId            TRecordId,

          @vLoadId              TRecordId,
          @vLoadNumber          TLoadNumber,
          @vLoadType            TTypeCode,
          @vLoadStatus          TStatus,
          @vLoadFromWarehouse   TWarehouse,
          @vShipTo              TName,
          @vShipmentId          TShipmentId,
          @vBoLId               TBoLId,

          @vLPNOrPallet         TLPN,
          @vBusinessUnit        TBusinessUnit,
          @vDeviceId            TDeviceId,
          @vUserId              TUserId,

          @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vLPNStatus           TStatus,
          @vLPNLoadId           TRecordId,
          @vLPNWarehouse        TWarehouse,
          @vEntityId            TRecordId,
          @vValidLPNStatus      TStatus,

          @vPalletId            TRecordId,
          @vPallet              TPallet,
          @vPalletStatus        TStatus,
          @vPalletLoadId        TRecordId,
          @vPalletWarehouse     TWarehouse,
          @vValidPalletStatus   TStatus,

          @vOrderId             TRecordId,
          @vWaveNo              TWaveNo,

          @vRowCount            TCount,
          @vLPNsShippedCount    TCount,
          @vActivityLogId       TRecordId;

  declare @ttLPNsToUnLoad          TLPNsToLoad,
          @ttPalletsToRecount      TRecountKeysTable,
          @ttShipmentsToRecount    TEntityKeysTable,
          @ttBoLsToRecount         TEntityKeysTable,
          @ttOrdersToUpdate        TEntityKeysTable,
          @ttWavesToUpdate         TEntityKeysTable,
          @ttOrdersToRemove        TEntityValuesTable;

begin /* pr_RFC_Shipping_UnLoad */
begin try
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Get the Input params */
  select @vLoadNumber   = Record.Col.value('Load[1]', 'TLoadNumber'),
         @vShipTo       = Record.Col.value('ShipTo[1]', 'TName'),
         @vLPNOrPallet  = Record.Col.value('ScanLPNOrPallet[1]', 'TLPN'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TLPN'),
         @vDeviceId     = Record.Col.value('DeviceId[1]', 'TDeviceId'),
         @vUserId       = Record.Col.value('UserId[1]', 'TUserId')
  from @xmlInput.nodes('/ConfirmLoad') as Record(Col);

  /* Add to RF Log */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @vLPNOrPallet, 'LPN/Pallet', @Value1 = @vLoadNumber,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get the valid LPNs statuses */
  select @vValidLPNStatus    = dbo.fn_Controls_GetAsString('UnLoading', 'ValidLPNStatus',    'L'/* Loaded */, @vBusinessUnit, @vUserId),
         @vValidPalletStatus = dbo.fn_Controls_GetAsString('UnLoading', 'ValidPalletStatus', 'L'/* Loaded */, @vBusinessUnit, @vUserId);

  /* Get the load Info */
  select @vLoadId            = LoadId,
         @vLoadNumber        = LoadNumber,
         @vLoadStatus        = Status,
         @vLoadType          = LoadType,
         @vLoadFromWarehouse = FromWarehouse
  from Loads
  where (LoadNumber   = @vLoadNumber) and
        (BusinessUnit = @vBusinessUnit);

  /* Get the LPN info */
  select @vLPNId        = LPNId,
         @vLPN          = LPN,
         @vLPNStatus    = Status,
         @vLPNWarehouse = DestWarehouse,
         @vEntityId     = LPNId,
         @vLPNLoadId    = LoadId
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vLPNOrPallet, @vBusinessUnit, default));

  /* If it wasn't LPN that user scanned, check if it is a Pallet */
  if (@vLPNId is null)
    select @vPalletId        = PalletId,
           @vPallet          = Pallet,
           @vPalletStatus    = Status,
           @vPalletWarehouse = Warehouse,
           @vEntityId        = PalletId,
           @vPalletLoadId    = LoadId
    from Pallets
    where (Pallet       = @vLPNOrPallet) and
          (BusinessUnit = @vBusinessUnit);

  /* Get all the LPNs into hash table */
  if (@vLPNId is not null)
    insert into @ttLPNsToUnLoad (LPNId, LPN, LPNStatus, PalletId, OrderId, PickTicket,
                                 WaveId, WaveNo, LoadId, ShipmentId)
      select L.LPNId, L.LPN, L.Status, L.PalletId, L.OrderId, L.PickTicketNo,
             L.PickBatchId, L.PickBatchNo, L.LoadId, L.ShipmentId
      from LPNs L
      where (L.LPNId = @vLPNId) and (L.LoadId = @vLoadId);
  else
  if (@vPalletId is not null)
    insert into @ttLPNsToUnLoad (LPNId, LPN, LPNStatus, PalletId, OrderId, PickTicket,
                                 WaveId, WaveNo, LoadId, ShipmentId)
      select L.LPNId, L.LPN, L.Status, L.PalletId, L.OrderId, L.PickTicketNo,
             L.PickBatchId, L.PickBatchNo, L.LoadId, L.ShipmentId
      from LPNs L
      where (L.PalletId = @vPalletId) and (L.LoadId = @vLoadId);

  /* Get the LPNs Count which are inserted into temp table */
  select @vRowCount = @@rowcount;

  /* Check if there are any LPNs which are already shipped */
  select @vLPNsShippedCount = count(*)
  from @ttLPNsToUnLoad
  where (LPNStatus = 'S'/* Shipped */);

  /* Validations */
  if (@vLoadId is null)
    set @vMessageName = 'InvalidLoad';
  else
  if (@vLoadStatus = 'S' /* Shipped */)
    set @vMessageName = 'LoadAlreadyShipped'
  else
  if (@vLPNId is null) and (@vPalletId is null)
    set @vMessagename = 'InvalidLPNOrPallet';
  else
  if ((@vLPNId is not null) and (@vLoadId <> coalesce(@vLPNLoadId, 0))) or
     ((@vPalletId is not null) and (@vLoadId <> coalesce(@vPalletLoadId, 0)))
    set @vMessageName = 'UnLoad_ScannedLPNOrPalletNotOnLoad';
  else
  if (@vLPN is not null) and (charindex(@vLPNStatus, @vValidLPNStatus) = 0)
    set @vMessageName = 'UnLoad_InvalidLPNStatus';
  else
  if (@vPallet is not null) and (charindex(@vPalletStatus, @vValidPalletStatus) = 0)
    set @vMessageName = 'Unload_InvalidPalletStatus';
  else
  if (@vLPNsShippedCount > 0) and (@vLPNId is not null)
    set @vMessageName = 'Unload_LPNIsAlreadyShipped';
  else
  if (@vLPNsShippedCount > 0) and (@vPalletId is not null)
    set @vMessageName = 'Unload_PalletHasShippedLPNs';
  else
  /* LPNs need not be Loaded as this function is used to remove LPNs from Load as well */
  -- if exists (select * from @ttLPNsToUnLoad where LPNStatus <> 'L'/* Loaded */)
  --   set @vMessageName = 'UnLoad_LPNsNotOnLoad';
  -- else
  if ((@vLPNId is not null) and (@vLoadFromWarehouse <> @vLPNWarehouse)) or
     ((@vPalletId is not null) and (@vLoadFromWarehouse <> @vPalletWarehouse))
    set @vMessageName = 'UnLoad_ScannedLPNOrPalletWHMismatch';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Loop through each LPN and unload it */
  while exists (select * from @ttLPNsToUnLoad where RecordId > @vRecordId)
    begin
      /* Get each Record from temp table */
      select top 1 @vRecordId   = RecordId,
                   @vLPNId      = LPNId,
                   @vPalletId   = PalletId,
                   @vOrderId    = OrderId,
                   @vWaveNo     = WaveNo,
                   @vShipmentId = ShipmentId,
                   @vBoLId      = BoLId
      from @ttLPNsToUnLoad
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Remove the LPN from the Load, Revert LPN Status
         1)For Contractor Transfer Loads and No order associated to the LPNs then revert LPNstatus To putaway
         2)For Other then Contractor Transfer Load Revert LPNStatus to Staged if it was Loaded else Previous LPNStatus
      */
      update LPNs
      set Status     = case when (@vLoadType = 'Transfer') and (Status = 'L' /* Loaded */) and (coalesce(OrderId ,0) = 0) then 'P' /* Putaway */
                            when (Status = 'L' /* Loaded */) then 'E' /* Staged */
                        else
                            Status
                       end,
          LoadId     = 0,
          LoadNumber = null,
          ShipmentId = 0,
          BoL        = null
      where (LPNId = @vLPNId);

      /* When an LPN is unloaded then set pallet status as staged so that recount will reset the pallet
         status as intended
         Motive of this change is while loading a pallet we would just update Load info on pallet and set pallet status to loaded
         and LPNs will be loaded by a background job but in the mean time if pallet update count is called we are clearing load
         info on pallet so update count is changed not to clear load info when the pallet status is loaded so setting status to
         staged will recount pallet status */
      if (@vPalletId is not null)
        update Pallets
        set Status     = 'SG',
            LoadId     = 0,
            ShipmentId = 0
        where (PalletId = @vPalletId);

       /* Insert Audit Trail */
      exec pr_AuditTrail_Insert 'LPNRemovedFromLoad', @vUserId, null /* ActivityTimestamp */,
                                @LPNId         = @vLPNId,
                                @PalletId      = @vPalletId,
                                @OrderId       = @vOrderId,
                                @ShipmentId    = @vShipmentId,
                                @LoadId        = @vLoadId;

      /* Reset variables */
      select @vLPNId = null, @vShipmentId = null, @vBoLId = null;
    end

  /* Recount the Load */
  exec pr_Load_Recount @vLoadId;

  /* Recount Pallets */
  insert into @ttPalletsToRecount (EntityId) select distinct PalletId from @ttLPNsToUnLoad;
  exec pr_Pallets_Recalculate @ttPalletsToRecount, 'CS'/* Counts & Status */, @vBusinessUnit, @vUserId;

  /* Recount Shipments */
  insert into @ttShipmentsToRecount (EntityId) select distinct ShipmentId from @ttLPNsToUnLoad;
  exec pr_Shipment_Recalculate @ttShipmentsToRecount, default, @vBusinessUnit, @vUserId;

  /* Get the Orders which are don't have shipments */
  insert into @ttOrdersToRemove (RecordId, EntityId)
    select row_number() over (order by LU.OrderId), LU.OrderId
    from @ttLPNsToUnLoad LU
      join vwOrderShipments OS on OS.ShipmentId = LU.ShipmentId
    where OS.NumLPNs = 0
    group by LU.OrderId;

  /* Remove the Orders from Load */
  if (exists (select * from @ttOrdersToRemove))
    exec @vReturnCode = pr_Load_RemoveOrders @vLoadNumber, @ttOrdersToRemove, 'N' /* Cancel Load */, 'LPNRemovedFromLoad', @vBusinessUnit, @vUserId;

/* Recount BoLs */
  insert into @ttBoLsToRecount (EntityId)
    select distinct B.BoLId
    from BoLs B
      join LPNs    L   on (B.BoLNumber = L.BoL) and (B.BusinessUnit = L.BusinessUnit)
      join @ttLPNsToUnLoad ttL on (L.LPNId = ttL.LPNId);

  exec pr_BoL_Recalculate @ttBoLsToRecount;

  /* Compute order statuses */
  insert into @ttOrdersToUpdate (EntityId, EntityKey) select distinct OrderId, PickTicket from @ttLPNsToUnLoad;
  exec pr_OrderHeaders_Recalculate @ttOrdersToUpdate, '$S', @vUserId, @vBusinessUnit;

  /* Compute Wave statuses */
  insert into @ttWavesToUpdate (EntityId, EntityKey) select distinct WaveId, WaveNo from @ttLPNsToUnLoad;
  exec pr_PickBatch_Recalculate @ttWavesToUpdate, '$S', @vUserId, @vBusinessUnit;

  /* Get the Load Details of scanned Load */
  exec @xmlResult = pr_Loading_GetLoadInfo @vLoadId, @xmlResult output;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vEntityId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vEntityId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Shipping_UnLoad */

Go
