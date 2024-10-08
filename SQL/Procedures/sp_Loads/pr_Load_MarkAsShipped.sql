/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/15  RKC     pr_Load_MarkAsShipped: Passed the ReasonCode value to pr_OrderHeaders_Close (OB2-2028)
                      pr_Load_MarkAsShipped: Code Revamp (HA-1842)
  2021/03/18  TK      pr_Load_MarkAsShipped: Mark one shipment as shipped in a single transaction (HA-GoLive)
  2020/12/31  TK      pr_Load_MarkAsShipped: Invoke new proc to do the necessary updates when a transfer load or order is shipped
  2020/11/10  VS      pr_Load_MarkAsShipped: Clear the @vLoadNewStatus for each shippment loop (CID-1552)
                      pr_Load_MarkAsShipped: Changes to pr_Load_RemoveOrders proc signature (HA-1520)
  2020/09/24  VS      pr_Load_ValidateToShip, pr_Load_MarkAsShipped : Excluded Already ShippedLoad & Shipping-In Progress from Backgroundprocess (S2GCA-1183)
              RV      pr_Load_MarkAsShipped: Made changes to Manifest close based upon the rules (HA-950)
  2019/10/09  AY      pr_Load_MarkAsShipped: Ship Loads in incremental transactions (HPI-2714)
                      pr_Load_MarkAsShipped: Incremental transactions
  2018/05/22  PK      pr_Load_MarkAsShipped, pr_Load_Modify: Migrated the changes from HPI production to S2G (S2G-878)
  2016/08/30  AY      pr_Load_MarkAsShipped: Send LoadId in ShipOH/OD records when shipped against a Load. (HPI-546)
  2016/03/19  OK      pr_Load_MarkAsShipped: Use save transaction points to roll back only the particular Load
                      pr_Load_Cancel, pr_Load_MarkAsShipped: Enhancement to show the AT Log over the Load transactions (CIMS-730)
  2013/12/31  TD      pr_Load_MarkAsShipped: Changes to generate exports for all the Pallets on the Load.
                         signature of the procedure pr_Load_MarkAsShipped was changed.
  2012/10/26  PKS     Procedure pr_Load_MarkAsShipped1 was renamed as pr_Load_MarkLoadsAsShipped and fixed few issues.
  2012/10/25  VM      pr_Load_MarkAsShipped: Update ShippedDate on Load
  2012/10/05  PK      pr_Load_MarkAsShipped: Added a check to close the orders if not already shipped.
  2012/10/04  AY      pr_Load_MarkAsShipped: Ship orders as well when Load is shipped
                      pr_Load_MarkAsShipped: Passing UserId and BusinessUnit to pr_Shipment_MarkAsShipped.
  2012/08/27  PKS     pr_Load_MarkAsShipped: Corrected param for pr_Load_ValidateToShip
  2012/08/27  PKS     pr_Load_MarkAsShipped: Corrected params to pr_Load_ValidateToShip.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_MarkAsShipped') is not null
  drop Procedure pr_Load_MarkAsShipped;
Go
/*------------------------------------------------------------------------------
  Proc :This Procedure pr_Load_MarkAsShipped update the status
        with shipped, it internally validate the status by calling the proc
        pr_Load_ValidToShipped.
------------------------------------------------------------------------------*/
Create Procedure pr_Load_MarkAsShipped
  (@LoadId       TLoadId,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @Message      TMessage   = null output,
   @Operation    TOperation = null)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          /* Loads Related */
          @vLoadNumber               TLoadNumber,
          @vLoadType                 TTypeCode,
          @vLoadStatus               TStatus,
          @vLoadId                   TLoadId,
          @vLoadNewStatus            TStatus,
          /* Cursor variables...*/
          @vShipmentRecId            TRecordId,
          @vShipmentId               TShipmentId,
          @vOrderRecId               TRecordId,
          @vOrderId                  TRecordId,
          @vOrderType                TTypeCode,
          @vOrderCategory1           TOrderCategory,
          @vWaveType                 TTypeCode,
          @vExportPallets            TCategory,
          @vDebug                    TFlags,
          @vTime                     TDatetime,
          @vIsMultipleShipmentOrder  TFlags,
          @vRemoveDisqualifiedOrders TFlags,
          @vForceClose               TFlags,
          @vNumShipmentsToProcess    TCount,
          @vNumShipments             TCount,
          @vIteration                TCount,
          @vIsManifestCloseReq       TFlags,

          @vStartTranCount           TCount,
          @vUpdateOption             TFlags,
          @vMarkerXmlData            TXML,
          @vXMLData                  TXML,
          @xmlRulesData              TXML,
          /* ShipVia Info */
          @vShipVia                  TShipVia,
          @vCarrier                  TCarrier,
          @vIsSmallPackageCarrier    TFlag;

  /* Declare temp tables */
  declare @ttPalletsOnLoad  TEntityKeysTable,
          @ttOrdersToRemove TEntityKeysTable,
          @ttLoadShipments  TEntityKeysTable,
          @ttPickBatches    TEntityKeysTable,
          @ttMarkers        TMarkers;

  declare @ttOrdersOnLoad Table
           (RecordId         TRecordId Identity(1,1),
            OrderId          TRecordId,
            PickTicket       TPickTicket,
            OrderType        TTypeCode,
            OrderCategory1   TOrderCategory,
            WaveType         TTypeCode);

begin /* pr_Load_MarkAsShipped */
begin try
  /* If any validation failed then roll back upto that load only and process all other loads */
  select @vStartTranCount = @@trancount;

  /* Create hash table */
  create table #EntitiesToRecalc (RecalcRecId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'RecalcCounts', '#EntitiesToRecalc';

  /* If already in a transaction, then create save point so we can roll back only this load */
  if (@@trancount > 0)
    Save Transaction LoadMarkAsShipped;

  SET NOCOUNT ON;

  select @vReturnCode            = 0,
         @vMessageName           = null,
         @vDebug                 = 'Y' /* Yes */,
         @vUpdateOption          = '$W' /* Compute - Wave Status */,
          /* Get the control value to determine do we want to export Pallets or not */
         @vExportPallets            = dbo.fn_Controls_GetAsString ('ExportLoad', 'ExportPallets', 'N' /* No */, @BusinessUnit, @UserId),
         @vNumShipmentsToProcess    = dbo.fn_Controls_GetAsInteger('ExportLoad', 'NumShipmentsToProcess', 1, @BusinessUnit, @UserId),
         @vRemoveDisqualifiedOrders = dbo.fn_Controls_GetAsString ('LoadShip',   'RemoveDisqualifiedOrders', 'N', @BusinessUnit, @UserId);

  /* Get Load Info here..*/
  select @vLoadId      = LoadId,
         @vLoadType    = LoadType,
         @vLoadNumber  = LoadNumber,
         @vLoadStatus  = Status
  from Loads
  where (LoadId = @LoadId);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_Load_MarkAsShipped';

  if (@vRemoveDisqualifiedOrders = 'Y')
    begin
      /* Get the disqualified orders to remove from the Load */
      insert into @ttOrdersToRemove (EntityId)
        exec pr_Load_GetDisqualifiedOrdersToShip @vLoadId, @BusinessUnit, @UserId;

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_Load_GetDisqualifiedOrdersToShip';

      if (exists (select * from @ttOrdersToRemove))
        exec @vReturnCode = pr_Load_RemoveOrders @vLoadNumber, @ttOrdersToRemove, 'N' /* Cancel Load */, 'Load_Ship', @BusinessUnit, @UserId;

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_Load_RemoveOrders';
    end

  /* Build the xml to send to Rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('LoadId',            @vLoadId) +
                         dbo.fn_XMLNode('LoadNumber',        @vLoadNumber) +
                         dbo.fn_XMLNode('LoadType',          @vLoadType));

  /* Update Master tracking no on LPNs when Tracking no doesn't exist on LPNs */
  exec pr_RuleSets_ExecuteRules 'LoadShip_PreValidateUpdates' /* RuleSetType */, @xmlRulesData;

  /* Verify if the Load can be shipped */
  exec @vReturnCode = pr_Load_ValidateToShip @LoadId, @Operation;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_Load_ValidateToShip';

  if (@vReturnCode > 0) goto ExitHandler;

  /* Get count of Shipments on Load */
  select @vNumShipments = count(*) from Shipments where (LoadId = @LoadId) and (Status <> 'S');
  select @vIteration    = 0;

StartProcessing:

  /* Setup/Clean up for next set of shipments */
  delete from @ttLoadShipments;

  /* Get all the shipments on the load */
  insert into @ttLoadShipments (EntityId)
    select top (@vNumShipmentsToProcess) ShipmentId
    from Shipments
    where (LoadId = @LoadId) and
          (Status <> 'S' /* Shipped */)
    order by ShipmentId;

  set @vShipmentRecId = 0;

  /* If we are not running in the scope of the transaction, then start one */
  if (@@trancount = 0) begin transaction;

  /* If there are any updates to be done for Load (primarily for exports) then do them before we start
     processing the shipments */
  exec pr_RuleSets_ExecuteRules 'LoadShip_PostValidateUpdates' /* RuleSetType */, @xmlRulesData;

  /* Iterate thru the each Shipment on the Load */
  while exists (select * from @ttLoadShipments where RecordId > @vShipmentRecId)
    begin
      select top 1 @vShipmentRecId = RecordId,
                   @vShipmentId    = EntityId
      from @ttLoadShipments
      where (RecordId > @vShipmentRecId)
      order by RecordId;

      exec pr_Shipment_MarkAsShipped @vShipmentId, 'N' /* ValidateToShip */, @UserId, @BusinessUnit;
    end

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_Shipment_MarkAsShipped';

  /* if the exports are pallet level then export pallets and pallet details now */
  if (@vExportPallets = 'Y' /* Yes */)
    begin
      /* Get all pallets on the Load that belong to this set of shipments into temp table */
      insert into @ttPalletsOnLoad(EntityId)
        select PalletId
        from Pallets P join @ttLoadShipments LS on P.ShipmentId = LS.EntityId
        where (P.LoadId = @LoadId);

      /* Call procedure here to export data */
      exec pr_Exports_PalletData 'Ship' /* TransType */, @ttPalletsOnLoad, null /* PalletId */,
                                 @BusinessUnit, @UserId;

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_Exports_PalletData';
    end

  /* Once processing the records need to cleanup temp table */
  delete from @ttOrdersOnLoad;

  /* Get all the Orders for the selected shipments */
  insert into @ttOrdersOnLoad(OrderId, PickTicket, OrderType, OrderCategory1, WaveType)
    select OH.OrderId, OH.PickTicket, OH.OrderType, OH.OrderCategory1, W.WaveType
      from vwOrderShipments OS
        join @ttLoadShipments ttS on (OS.ShipmentId  = ttS.EntityId)
        join OrderHeaders      OH on (OS.OrderId     = OH.OrderId)
        join Waves              W on (OH.PickBatchId = W.RecordId)
      where (OS.LoadId = @LoadId) and
            (OH.Status <> 'S'/* Shipped */);

  set @vOrderRecId = 0;

  /* Iterate thru the each Order on the Load */
  while exists (select * from @ttOrdersOnLoad where RecordId > @vOrderRecId)
    begin
      select top 1 @vOrderRecId     = RecordId,
                   @vOrderId        = OrderId,
                   @vOrderType      = OrderType,
                   @vOrderCategory1 = OrderCategory1,
                   @vWaveType       = WaveType
      from @ttOrdersOnLoad
      where (RecordId > @vOrderRecId)
      order by RecordId;

      /* Build XML to see if order can ship in multiple shipments or not */
      select @vXMLData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('OrderType',      @vOrderType) +
                            dbo.fn_XMLNode('OrderCategory1', @vOrderCategory1) +
                            dbo.fn_XMLNode('WaveType',       @vWaveType) +
                            dbo.fn_XMLNode('Operation',      'Shipping_OrderClose'));

      /* Get whether order can ship in multiple shipments or not */
      exec pr_RuleSets_Evaluate 'IsMultiShipmentOrder', @vXMLData, @vIsMultipleShipmentOrder output;

      /* Get ForceClose option considering whether order can be shipped in multiple shipments or not */
      select @vForceClose = case when @vIsMultipleShipmentOrder = 'N' then 'Y' else 'N' end;

      exec pr_OrderHeaders_Close @vOrderId, null /* PickTicket */, @vForceClose, @LoadId,
                                 @BusinessUnit, @UserId;

      if (exists (select * from OrderHeaders where OrderId = @vOrderId and Status <> 'S')) and (@vIsMultipleShipmentOrder = 'N')
        select @vMessageName = 'Order '+ dbo.fn_Str(@vOrderId) + ' not shipped';

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After_OrderHeaders_Close';
    end

  /* Recount Entities that are to be processed immediately */
  exec pr_Entities_RecalcCounts @BusinessUnit, @UserId;

  /* Once processing the records need to clear the status */
  set @vLoadNewStatus = null

  /* Recount will calculate the counts afresh. Also calls SetStatus of Load
     to update the Load Status accordingly */
  exec pr_Load_Recount @vLoadId, @vLoadNewStatus output;

  /* If Load is not completely shipped, then process next set of shipments,
     prevent going into infinite loop in case there is error */
  select @vIteration += 1;
  if (@vLoadNewStatus <> 'S') and (@vIteration <= ceiling(@vNumShipments/@vNumShipmentsToProcess))
    begin
      commit; -- close the transaction
      goto StartProcessing;
    end

  /* When transfer load is shipped, there are subsequent updates to be done
     i.e. to move inventory to Intransit etc. */
  if (@vLoadType = 'Transfer') or
     exists (select *
             from vwOrderShipments
             where (LoadId = @vLoadId) and
                   (OrderType = 'T' /* Transfer */))
    exec pr_Loads_OnShip_Transfers @vLoadId, 'ShipTransferOrder'/* Operation */, @BusinessUnit, @UserId;

  /* Set the Shipped date */
  update Loads
  set ShippedDate = coalesce(ShippedDate, current_timestamp)
  where LoadId = @vLoadId;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Load Updated';

  /* Auditing */
  exec pr_AuditTrail_Insert 'LoadMarkAsShipped', @UserId, null /* ActivityDateTime - if null takes the Current TimeStamp */,
                            @LoadId = @LoadId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If we are creating transacitons in this proc and there is an open one, commit it */
  if (@vStartTranCount = 0) and (@@trancount > 0)
    commit transaction;

  /* Process deferred entries */
  exec pr_Entities_RequestRecalcCounts null /* EntityType */, @BusinessUnit = @BusinessUnit;

  exec pr_RuleSets_Evaluate 'LoadShip_ManifestCloseRequired', @xmlRulesData, @vIsManifestCloseReq output;

  /* If Manifest required then Process the manifest close, which are in hold on the shipped load */
  if (@vIsManifestCloseReq = 'Y' /* Yes */)
    exec pr_Load_ManifestClose @vLoadId, @BusinessUnit, @UserId, @Message output;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'End_Load_MarkAsShipped';

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'Load', @LoadId, @vLoadNumber, 'Loads_MarkAsShipped', 'Markers_Loads_MarkAsShipped';

end try
begin catch
  select @Message = ERROR_MESSAGE();
  /* If the calling procedure transaction is still valid,
     just roll back to the savepoint set at the start of the stored procedure. */
  if (XACT_STATE() <> -1) and (@vStartTranCount > 0)
    begin
      rollback transaction LoadMarkAsShipped;
    end
  else
  /* We have started transaction in this procedure, then roll it back */
  if (@vStartTranCount = 0) and (@@trancount > 0)
    rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Load_MarkAsShipped */

Go
