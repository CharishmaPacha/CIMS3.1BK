/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/26  TK      pr_Loading_LoadPalletOrLPN: Log Audit Details (HA-3019)
  2021/05/04  TK      pr_Loading_LoadPalletOrLPN: Contractor transfers use Loads ship via while creating shipments (HA-2591)
  2021/04/26  RIA     pr_Loading_LoadPalletOrLPN: Changes to update status based on operation
                      pr_Loading_ValidateLoadPalletOrLPN: Commented a validation temporarily (HA-2675)
  2021/04/19  TK      pr_Loading_LoadPalletOrLPN: If Load is shipping via LTL carrier then use LoadShipVia to create shipments (HA-2571)
  2021/04/06  RKC     pr_Loading_LoadPalletOrLPN: Made changes to update loadded status status based on the control category (HA-2552)
  2021/03/17  MS      pr_Loading_LoadPalletOrLPN: Bol & Shipment caller changes (HA-1935)
  2021/03/07  SK      pr_Loading_LoadPalletOrLPN: Updated LPN status as Loaded based on its initial status (HA-2152)
  2021/02/23  AY      pr_Loading_LoadPalletOrLPN: Do not change status of Temp Labels added to Loads (HA-Mock Go Live)
  2021/02/02  TK      pr_Loading_LoadPalletOrLPN: Changes to create shipments in bulk instead of creating each LPN (HA-1947)
  2021/01/23  AY      pr_Loading_LoadPalletOrLPN: Do not defer loading if Pallet already on Load (HA-1947)
  2020/07/15  VS      pr_Loading_LoadPalletOrLPN: Passed BusinessUnit to Recalcounts (S2GCA-1161)
  2020/06/30  TK      pr_Loading_LoadPalletOrLPN & pr_Loading_ValidateLoadPalletOrLPN: Changes to load LPNs that are not associated to any order (HA-830)
  2020/01/21  TK      pr_Loading_LoadPalletOrLPN & pr_Loading_ValidateLoadPalletOrLPN: Initial Revision
                      pr_Shipping_GetLoadInfo renamed to pr_Loading_GetLoadInfo and migrated from sp_Shipping (S2GCA-970)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loading_LoadPalletOrLPN') is not null
  drop Procedure pr_Loading_LoadPalletOrLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loading_LoadPalletOrLPN: Checks whether the scanned Entity should be loaded
    immediately or should be loaded in background and Loads the scanned Entity
------------------------------------------------------------------------------*/
Create Procedure pr_Loading_LoadPalletOrLPN
  (@LoadId               TRecordId,
   @PalletId             TRecordId,
   @LPNId                TRecordId,
   @Operation            TOperation,
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,

          @vRecordId             TRecordId,

          @vLoadId               TRecordId,
          @vLoadNumber           TLoadNumber,
          @vLoadType             TTypeCode,
          @vLoadStatus           TStatus,
          @vLoadShipToId         TShipToId,
          @vLoadDock             TLocation,
          @vLoadShipVia          TShipVia,
          @vLoadShipViaIsSPC     TFlags,

          @vLPNId                TRecordId,
          @vLPNLoadId            TRecordId,
          @vLPNShipToId          TShipToId,
          @vOrderId              TRecordId,
          @vLPNPalletId          TRecordId,
          @vPalletNumLPNs        TCount,
          @vPalletLoadId         TRecordId,

          @vShipmentId           TRecordId,

          @vEntityId             TRecordId,
          @vEntityKey            TEntityKey,
          @vEntityType           TEntity,
          @vEntityStatus         TStatus,

          @vLoadingOption        TControlValue,
          @vLoadingControlCategory
                                 TCategory,
          @vValidLPNStatus       TControlValue,
          @vAuditActivity        TActivityType,
          @ttAuditTrailInfo      TAuditTrailInfo,

          @xmlRulesData          TXML;

  declare @ttAuditDetails        TAuditDetails,
          @ttLPNsToLoad          TLPNsToLoad,
          @ttLPNsLoaded          TLPNsToLoad,
          @ttBoLsToRecount       TEntityKeysTable,
          @ttShipmentsToRecount  TEntityKeysTable,
          @ttOrdersToUpdate      TEntityKeysTable,
          @ttWavesToUpdate       TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vRecordId    = 0,
         @vMessageName = null;

  /* Get the Load Info */
  select @vLoadId       = LoadId,
         @vLoadNumber   = LoadNumber,
         @vLoadType     = LoadType,
         @vLoadStatus   = Status,
         @vLoadShipToId = ShipToId,
         @vLoadDock     = DockLocation,
         @vLoadShipVia  = ShipVia
  from Loads
  where (LoadId = @LoadId);

  if (@vLoadShipVia is not null)
    select @vLoadShipViaIsSPC = IsSmallPackageCarrier
    from ShipVias
    where (ShipVia = @vLoadShipVia) and (BusinessUnit = @BusinessUnit);

  /* Get the valid LPNs status for Loading based on the control category */
    /* Build Loading Control Category */
  select @vLoadingControlCategory = case when (@vLoadType = 'Transfer' /* Contractor Transfer */)
                                         then 'Loading_' + @vLoadType
                                         else 'Loading'
                                    end

  /* Get the valid LPNs statuses */
  select @vValidLPNStatus  = dbo.fn_Controls_GetAsString(@vLoadingControlCategory, 'ValidLPNStatus', 'KDE'/* Picked, Packed, Staged */, @BusinessUnit, @UserId)

  /* Identify Entity info */
  if (@PalletId is not null)
    select @vEntityId      = PalletId,
           @vEntityKey     = Pallet,
           @vEntityType    = 'Pallet',
           @vEntityStatus  = Status,
           @vPalletNumLPNs = NumLPNs,
           @vPalletLoadId  = LoadId,
           @vLoadId        = coalesce(@LoadId, LoadId),
           @vAuditActivity = 'ScanLoadPallet'
    from Pallets
    where (PalletId = @PalletId);
  else
  if (@LPNId is not null)
    select @vEntityId      = LPNId,
           @vEntityKey     = LPN,
           @vEntityType    = 'LPN',
           @vEntityStatus  = Status,
           @vLoadId        = coalesce(@LoadId, LoadId),
           @vLPNPalletId   = PalletId,
           @vAuditActivity = 'ScanLoadLPN'
    from LPNs
    where (LPNId = @LPNId);

  /* Build xml to evaluate rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('EntityId',       @vEntityId) +
                           dbo.fn_XMLNode('EntityKey',      @vEntityKey) +
                           dbo.fn_XMLNode('EntityType',     @vEntityType) +
                           dbo.fn_XMLNode('EntityStatus',   @vEntityStatus) +
                           dbo.fn_XMLNode('PalletNumLPNs',  @vPalletNumLPNs) +
                           dbo.fn_XMLNode('LoadId',         @vLoadId) +
                           dbo.fn_XMLNode('PalletLoadId',   @vPalletLoadId) +
                           dbo.fn_XMLNode('Operation',      @Operation));

  /* Evaluate Rules to determine if to be loaded right away or defer it for later */
  exec pr_RuleSets_Evaluate 'Loading_LoadPalletOrLPN', @xmlRulesData, @vLoadingOption output;

  /* If D-Defer then process loading in back ground */
  if (@vLoadingOption = 'D'/* Defer */)
    begin
      /* Call proc to execute in back ground */
      exec pr_Entities_ExecuteInBackGround @vEntityType, @vEntityId, @vEntityKey, 'LPL'/* ProcessCode - Load Pallet LPN */,
                                           @@ProcId, 'LoadPalletOrLPN'/* Operation */, @BusinessUnit, default;


      /* Update the pallet with Load. At this stage, the Pallet is assigned the Load
         but the LPNs are not, hence until the back ground task is complete, the Load
         cannot be shipped */
      if (@PalletId is not null)
        update Pallets
        set LoadId = @vLoadId,
            Status = case when @Operation <> 'BuildLoad' then 'L' /* Loaded */ else Status end
        where (PalletId = @PalletId);

      /* Return */
      goto ExitHandler;
    end

  /* If hash table doesn't exist then create one */
  if object_id('tempdb..#LPNsToLoad') is null
    select * into #LPNsToLoad from @ttLPNsToLoad;
  select * into #AuditDetails from @ttAuditDetails;

  /* if no LPNs were given, then identify then based upon the input params LPNId or PalletId */
  if not exists(select * from #LPNsToLoad)
    begin
      /* Get all the LPNs into hash table */
      if (@LPNId is not null)
        insert into #LPNsToLoad (LPNId, LPN, OrderId, WaveId, WaveNo, LoadId, ShipmentId)
          select L.LPNId, L.LPN, L.OrderId, L.PickBatchId, L.PickBatchNo, L.LoadId, coalesce(L.ShipmentId, 0)
          from LPNs L
          where (L.LPNId = @LPNId) and (L.Status <> 'S' /* Shipped */);
      else
      if (@PalletId is not null)
        insert into #LPNsToLoad (LPNId, LPN, OrderId, WaveId, WaveNo, LoadId, ShipmentId)
          select L.LPNId, L.LPN, L.OrderId, L.PickBatchId, L.PickBatchNo, L.LoadId, coalesce(L.ShipmentId, 0)
          from LPNs L
          where (L.PalletId = @PalletId) and (L.Status <> 'S' /* Shipped */);

      /* If there are no LPNs to load then exit */
      if not exists (select * from #LPNsToLoad) goto ExitHandler;
    end

  /* Update required info on temp tables */
  update LTL
  set PickTicket      = OH.PickTicket,
      OrderType       = OH.OrderType,
      DesiredShipDate = OH.DesiredShipDate,
      FreightTerms    = coalesce(OH.FreightTerms, 'PREPAID'),
      SoldToId        = coalesce(OH.SoldToId, Load.SoldToId, ''),        -- Contractor Transfer orders in HA will not be shipped against any order so use Load info
      ShipToId        = coalesce(OH.ShipToId, Load.ShipToId),            -- For Transfer Loads get the Load.ShipToId
      ShipVia         = case when @vLoadShipViaIsSPC = 'N' /* No */ then coalesce(Load.ShipVia, OH.ShipVia)
                             else coalesce(OH.ShipVia, Load.ShipVia)
                        end,
      ShipFrom        = coalesce(OH.ShipFrom, Load.FromWarehouse)
  from #LPNsToLoad LTL
    left outer join OrderHeaders OH on (LTL.OrderId = OH.OrderId)
    left outer join Loads Load on (Load.LoadId = coalesce(nullif(LTL.LoadId, 0), @vLoadId));

  /* If there are LPNs without any shipments then invoke procedure to create shipments */
  if exists (select * from #LPNsToLoad where ShipmentId = 0)
    exec pr_Shipment_CreateShipments @vLoadId, @Operation, @BusinessUnit, @UserId;

  /* All Orders should now have a corresponding shipment for the Load,
     so identify the BoL for all LPNs in #LPNsToLoad */
  update LTL
  set BoLId     = S.BoLId,
      BoLNumber = S.BoLNumber
  from #LPNsToLoad LTL join Shipments S on (S.ShipmentId = LTL.ShipmentId);

  /* Update status of all LPNs to Loaded */
  update L
  set LoadId       = @vLoadId,
      LoadNumber   = @vLoadNumber,
      ShipmentId   = LTL.ShipmentId,
      BoL          = LTL.BoLNumber,
      Status       = case when @Operation = 'BuildLoad' then Status
                          when (dbo.fn_IsInList(L.Status, @vValidLPNStatus) > 0) then 'L' /* Loaded */
                          else L.Status
                     end,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output inserted.LPNId, inserted.LPN, inserted.Pallet, inserted.PickTicketNo, LTL.BoLId, inserted.BoL, inserted.ShipmentId
  into @ttLPNsLoaded (LPNId, LPN, Pallet, PickTicket, BoLId, BoLNumber, ShipmentId)
  from LPNs L join #LPNsToLoad LTL on L.LPNId = LTL.LPNId
  where (L.Status <> 'L' /* Loaded */);

  /* Update counts on the Loaded Pallet or the Pallet the LPN was on */
  if (@PalletId is not null)
    exec pr_Pallets_UpdateCount @PalletId, @UpdateOption = '*';
  else
  if (@vLPNPalletId is not null)
    exec pr_Pallets_UpdateCount @vLPNPalletId, @UpdateOption = '*';

  /* Recount BoLs */
  insert into @ttBoLsToRecount(EntityId) select distinct BoLId from @ttLPNsLoaded;
  exec pr_BoL_Recalculate @ttBoLsToRecount;

  /* Recount Shipments */
  insert into @ttShipmentsToRecount(EntityId) select distinct ShipmentId from @ttLPNsLoaded;
  exec pr_Shipment_Recalculate @ttShipmentsToRecount, default, @BusinessUnit, @UserId;;

  /* Recount Load */
  exec pr_Load_Recount @vLoadId;

  /* Compute order statuses */
  insert into @ttOrdersToUpdate (EntityId, EntityKey) select distinct OrderId, PickTicket from #LPNsToLoad;
  exec pr_OrderHeaders_Recalculate @ttOrdersToUpdate, '$S', @UserId, @BusinessUnit;

  /* Compute Wave statuses */
  insert into @ttWavesToUpdate (EntityId, EntityKey) select distinct WaveId, WaveNo from #LPNsToLoad;
  exec pr_PickBatch_Recalculate @ttWavesToUpdate, '$S', @UserId, @BusinessUnit;

  /* Insert Audit Trail for all LPNs and Pallet if Pallet is being loaded */
  if (@vEntityType = 'LPN')
    insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
      select 'LPN', LPNId, LPN, @vAuditActivity, @BusinessUnit, @UserId,
             dbo.fn_Messages_Build('AT_' + @vAuditActivity, LPN, Pallet, PickTicket, @vLoadNumber, @vLoadDock) /* Comment */
      from @ttLPNsLoaded;
  else
  /* when entity type is pallet log one AT and link that with all LPNs */
  if (@vEntityType = 'Pallet')
    insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
      select 'Pallet', @vEntityId, @vEntityKey, @vAuditActivity, @BusinessUnit, @UserId,
             dbo.fn_Messages_Build('AT_' + @vAuditActivity, @vEntityKey, @vPalletNumLPNs, null, @vLoadNumber, @vLoadDock) /* Comment */
      union all
      select 'LPN', LPNId, LPN, @vAuditActivity, @BusinessUnit, @UserId,
             dbo.fn_Messages_Build('AT_' + @vAuditActivity, Pallet, @vPalletNumLPNs, null, @vLoadNumber, @vLoadDock) /* Comment */
      from @ttLPNsLoaded;

  /* Log audit details for the LPNs loaded */
  insert into #AuditDetails (ActivityType, BusinessUnit, UserId, LPNId, LPN, Quantity,
                             WaveId, WaveNo, LocationId, Location, PalletId, Pallet, OrderId, PickTicket, Ownership, Warehouse, Comment)
    select @vAuditActivity, @BusinessUnit, @UserId, L.LPNId, L.LPN, L.Quantity,
           L.PickBatchId, L.PickBatchNo, L.LocationId, L.Location, L.PalletId, L.Pallet, L.OrderId, L.PickTicketNo, L.Ownership, L.DestWarehouse, ttAT.Comment
    from @ttLPNsLoaded ttL
      join LPNs L on ttL.LPNId = L.LPNId
      join @ttAuditTrailInfo ttAT on ttL.LPNId = ttAT.EntityId and
                                     ttAT.EntityType = 'LPN';

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loading_LoadPalletOrLPN */

Go
