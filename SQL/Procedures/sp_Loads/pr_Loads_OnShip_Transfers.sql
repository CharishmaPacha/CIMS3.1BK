/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/15  TK      pr_Loads_OnShip_Transfers: Bug fix to retrieve proper order id to log exports (HA-2416)
  2021/04/12  TK      pr_Loads_OnShip_Transfers: Changes to copy Load.TrailerNumber to LPN.Refernce, clear ReceiptId & ReceiverId (HA-2601)
                      pr_Loads_OnShip_Transfers: Initial Revision (HA-1830)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_OnShip_Transfers') is not null
  drop Procedure pr_Loads_OnShip_Transfers;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_OnShip_Transfers: When a transfer order is shipped
    there may be some updates to be done on the LPNs like changing the status of the LPNs,
    moving LPNs to some Location of the Warehouse to which LPN is transferred and so on

  This procedure does all the required updates on LPNs and its corresponding Pallets and generates exports as required
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_OnShip_Transfers
  (@LoadId          TRecordId,
   @Operation       TOperation = null,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode                      TInteger,
          @vMessageName                     TMessageName,
          @vMessage                         TMessage,

          @vLoadId                          TRecordId,
          @vLoadNumber                      TLoadNumber,
          @vLoadType                        TTypeCode,
          @vFromWarehouse                   TWarehouse,
          @vShipToId                        TShipToId,
          @vLoadTrailer                     TTrailerNumber,
          @vLoadShipVia                     TShipVia,

          @vInTransitWH                     TWarehouse,
          @vToLocationId                    TRecordId,
          @vToLocation                      TLocation,
          @vToWarehouse                     TWarehouse,

          @vControlCategory                 TCategory,
          @vTransferLPNStatus               TControlValue,
          @vTransferLPNOnhandStatus         TControlValue,
          @vControlCodeIntransitLocation    TControlValue,
          @vExportWHXferAsInvChange         TControlValue,
          @vDefaultIntransitLocation        TLocation;

  declare @ttLPNsToProcess                  TRecountKeysTable,
          @ttPalletsUpdated                 TRecountKeysTable;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Create required hash tables */
  create table #LPNsToExport (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#LPNsToExport';

  /* Get Load info */
  select @vLoadId        = LoadId,
         @vLoadNumber    = LoadNumber,
         @vLoadType      = LoadType,
         @vFromWarehouse = FromWarehouse,
         @vShipToId      = ShipToId,
         @vLoadTrailer   = TrailerNumber,
         @vLoadShipVia   = ShipVia
  from Loads
  where (LoadId = @LoadId);

  /* Get the controls */
  select @vControlCategory              = 'Exports_' + coalesce(@Operation, ''),
         @vControlCodeIntransitLocation = 'InTransitLocation_' + @vFromWarehouse;

  select @vDefaultIntransitLocation = 'INTRANSIT-' + @vFromWarehouse + '-' + @vShipToId;

  /* Get the Control option whether to send relevant exports for Transfer Orders */
  select @vTransferLPNStatus       = dbo.fn_Controls_GetAsString(@vControlCategory, 'LPNStatusOnShip', 'T' /* InTransit */, @BusinessUnit, @UserId),
         @vTransferLPNOnhandStatus = dbo.fn_Controls_GetAsString(@vControlCategory, 'LPNOnhandStatusOnShip', 'A' /* Available */, @BusinessUnit, @UserId),
         @vInTransitWH             = dbo.fn_Controls_GetAsString(@vControlCategory, 'InTransitWH', @vShipToId /* WHCode --Will map any UDF*/, @BusinessUnit, @UserId),
         @vToLocation              = dbo.fn_Controls_GetAsString(@vControlCategory, @vControlCodeIntransitLocation , @vDefaultIntransitLocation /* InTransit Location */, @BusinessUnit, @UserId);

  /* Get all the LPNs to process */
  /* There will be two kinds of LPNs that needs to be processed
      1. LPNs that are associated to orders with Type as 'Transfer'
      2. This is specific to HA, LPNs that are being shipped from contractor Warehouse to main Warehouse. These LPNs will not
         be associated to any orders */
  insert into @ttLPNsToProcess (EntityId)
    select LPNId
    from LPNs L
      join Loads Load on (L.LoadId = Load.LoadId)
      left outer join OrderHeaders OH on (L.OrderId = OH.OrderId)
    where (L.LoadId = @vLoadId) and
          ((Load.LoadType = 'Transfer') or
           (OH.OrderType  = 'T' /* Transfer */));

  /* If there are no LPNs to be processed then exit */
  if not exists (select * from @ttLPNsToProcess) return;

  /* Get Location Info */
  if (@vToLocation is not null)
    select @vToLocationId = LocationId,
           @vToWarehouse  = Warehouse
    from Locations
    where (Location     = @vToLocation) and
          (BusinessUnit = @BusinessUnit);

  /* If LPNs status should be shipped then go to generate exports and send required exports */
  if (@vTransferLPNStatus = 'S' /* Shipped */)
    begin
      insert into #LPNsToExport (LPNId)
        select EntityId from @ttLPNsToProcess;

      goto GenerateExports;
    end

  /* When shipping a transfer order or load and LPN status not shipped then clear the order info on the LPNs */
  /* Clear info on LPNs */
  update L
  set Status        = @vTransferLPNStatus,
      OnhandStatus  = @vTransferLPNOnhandStatus,
      LocationId    = @vToLocationId,
      Location      = @vToLocation,
      DestWarehouse = @vInTransitWH,
      OrderId       = null,
      PickTicketNo  = null,
      SalesOrder    = null,
      PickBatchId   = null,
      PickBatchNo   = null,
      TaskId        = null,
      ReceiptId     = null,
      ReceiverId    = null,
      ReservedQty   = 0,
      PackageSeqNo  = null,
      ShipmentId    = null,
      LoadId        = null,
      LoadNumber    = null,
      BoL           = null,
      TrackingNo    = null,
      Reference     = concat_ws('-', @vLoadNumber, @vLoadTrailer)
  output inserted.LPNId, deleted.LocationId, inserted.LocationId, inserted.PalletId,
         deleted.OrderId, deleted.DestWarehouse, inserted.DestWarehouse, deleted.LoadId, deleted.ShipmentId,
         coalesce(OH.ShipToId, @vShipToId), coalesce(@vLoadShipVia, OH.ShipVia)
  into #LPNsToExport (LPNId, LocationId, ToLocationId, PalletId, OrderId, FromWarehouse, ToWarehouse, LoadId, ShipmentId, ShipToId, ShipVia)
  from LPNs L
    join @ttLPNsToProcess ttLP on (L.LPNId = ttLP.EntityId)
    left outer join OrderHeaders OH on (L.OrderId = OH.OrderId);

  /* Clear Order Info on the LPN Details */
  update LD
  set OnhandStatus  = @vTransferLPNOnhandStatus,
      OrderId       = null,
      OrderDetailId = null,
      ReservedQty   = 0
  from LPNDetails LD
    join @ttLPNsToProcess ttLP on (LD.LPNId = ttLP.EntityId);

  /* Update Location on Pallets as well */
  update P
  set LocationId = @vToLocationId,
      Warehouse  = @vInTransitWH,
      LoadId     = null
  from Pallets P
    join #LPNsToExport LTE on (P.PalletId = LTE.PalletId);

  /* Recalc pallets so that it updates status and clear the order info on Pallet */
  insert into @ttPalletsUpdated (EntityId)
    select distinct PalletId from #LPNsToExport;

  exec pr_Pallets_Recalculate @ttPalletsUpdated, 'CS' /* Counts & Status */, @BusinessUnit, @UserId;

  /* if the LPN and/or pallet is moved to new location then recount the location */
  if (@vToLocationId is not null)
    exec pr_Locations_UpdateCount @vToLocationId, @vToLocation, '*' /* Update Option */;

GenerateExports:
  /* Invoke procedure to generate Exports */
  exec pr_Exports_WarehouseTransferForMultipleLPNs 'WHXfer', 'LPN' /* TransEntity - LPN */, @Operation, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_OnShip_Transfers */

Go
