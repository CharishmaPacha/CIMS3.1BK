/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/20  PK/YJ   pr_Load_RemoveOrders: Bugfix: missing orderid in join - Ported changes done by Pavan (HA-2353)
  2021/03/17  MS      pr_Load_RemoveOrders: Shipment Recal caller changes (HA-1935)
  2021/03/07  TK      pr_Load_RemoveOrders: Code Refractoring and changes to delete shipments if no order is linked with the shipment (HA-2121)
  2021/02/04  AY      pr_Load_RemoveOrders: When orders are removed from Loads, LPN do not revert to staged unless they were in a loaded status to begin with (HA-1975)
  2020/10/08  TK      pr_Loads_Action_Cancel, pr_Load_RemoveOrders &  pr_Load_UI_RemoveOrders:
                      pr_Load_MarkAsShipped: Changes to pr_Load_RemoveOrders proc signature (HA-1520)
  2020/06/10  RV      pr_Load_RemoveOrders: Made changes to get selected entities from #table instead of temp table (HA-839)
  2016/01/05  SV      pr_Load_CreateNew, pr_Load_AddOrder, pr_Load_RemoveOrders,
  2015/12/08  AY      pr_Load_RemoveOrders: When Shipment is removed from Loads, clear Bols as well.
  2012/11/29  PKS     pr_Load_RemoveOrders: Added "Not Required" Status in validating RoutingStatus
  2012/09/05  AA      pr_Load_RemoveOrders:  If Shipment contains single order remove shipment and LPNs relation with load
              PKS     pr_Load_RemoveOrders: LoadRoutingStatus validation was added and made few changes.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_RemoveOrders') is not null
  drop Procedure pr_Load_RemoveOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_RemoveOrders:
       Removes the given Orders from the Loads by
       calling pr_Load_RemoveOrder proc for each order

  '<Orders xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <OrderHeader>
    <OrderId>19</OrderId>
    </OrderHeader>
  </Orders>'
------------------------------------------------------------------------------*/
Create Procedure pr_Load_RemoveOrders
  (@LoadNumber         TLoadNumber,
   @ttOrders           TEntityValuesTable ReadOnly,
   @CancelLoadIfEmpty  TFlag,
   @Operation          TOperation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   -----------------------------------------------
   @TotalOrders        TCount       = null output,
   @OrdersRemoved      TCount       = null output,
   @Message            TDescription = null output)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vTranCount                TCount,
          @vTotalOrders              TCount,
          /* Orders info */
          @vOrders                   XML,
          @vOrderId                  TRecordId,
          @vOrderShipmentId          TShipmentId,
          /* Load Info */
          @vLoadId                   TRecordId,
          @vStatus                   TStatus,
          @vOrderOnLoad              TCount,
          @vLoadRoutingStatus        TStatus,
          /* BoL Info */
          @vBoLId                    TRecordId,
          /* Audit Info */
          @vValidLoadStatusToRemove  TStatus,
          @vSelectedRecordsXML       TXML,
          @InputXMLToVoidCPLs        TXML;

  declare @ttPalletsToRecount        TRecountKeysTable,
          @ttOrdersToUpdate          TEntityKeysTable,
          @ttRemovedPallets          TEntityKeysTable,
          @ttBoLsToRecount           TEntityKeysTable,
          @ttShipments               TRecountKeysTable,
          @ttShipmentsToRecount      TEntityKeysTable,
          @ttAuditTrailInfo          TAuditTrailInfo;
begin  /* pr_Load_RemoveOrders */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vTranCount        = @@trancount,
         @CancelLoadIfEmpty = coalesce(@CancelLoadIfEmpty, 'N');

  /* If there is no transaction started yet then start one */
  if (@vTranCount = 0) begin transaction;

  /* Get Controls */
  select @vValidLoadStatusToRemove = dbo.fn_Controls_GetAsString('Load_RemoveOrder', 'ValidLoadStatuses', 'NIR' /* New, In progress, Ready to load */, @BusinessUnit, null/* UserId */);

  /* Get Load Info*/
  select @vLoadId            = LoadId,
         @vLoadRoutingStatus = RoutingStatus,
         @vStatus            = Status
  from Loads
  where ((LoadNumber   = @LoadNumber  ) and
         (BusinessUnit = @BusinessUnit));

  /* Validate Load */
  if (@vLoadId is null)
    set @vMessageName = 'InvalidLoad';
  else
  if ((charindex(@vStatus, @vValidLoadStatusToRemove) = 0))
    set @vMessageName = 'Load_RemoveOrders_ValidStatus';
  else
  if (@vLoadRoutingStatus not in ('P' /* Pending */,'N' /* Not Required */)) /* If Routing already done, do not allow adding more orders */
    set @vMessageName = 'Load_RemoveOrders_InvalidRoutingStatus';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* get the total Orders which user need to remove */
  select LoadId, LoadNumber, OrderId, PickTicket, ShipmentId, BoLId
  into #OrderShipments
  from vwOrderShipments OS
    join @ttOrders ttO on (ttO.EntityId = OS.OrderId)
  where (OS.LoadId = @vLoadId);

  select @vTotalOrders = @@rowcount;

  /* Clear the Load info on the LPNs associated with Orders */
  update L
  set Status     = case when Status = 'L' then 'E' /* Staged */ else Status end,
      LoadId     = null,
      LoadNumber = null,
      ShipmentId = 0,
      BoL        = null
  output inserted.PalletId, inserted.Pallet into @ttPalletsToRecount (EntityId, EntityKey)
  from LPNs L
    join #OrderShipments OS on (L.ShipmentId = OS.ShipmentId) and
                               (L.OrderId    = OS.OrderId);

  /* Delete order shipments as they are removed from Load */
  delete OS
  output deleted.ShipmentId into @ttShipments (EntityId)
  from OrderShipments OS
    join #OrderShipments ttOS on (ttOS.OrderId = OS.OrderId) and
                                 (ttOS.ShipmentId = OS.ShipmentId);

  /* If there are no orders associated with the shipments then delete them or they may be recounted later */
  delete S
  from Shipments S
    join @ttShipments ttS on S.ShipmentId = ttS.EntityId
    left outer join OrderShipments OS on OS.ShipmentId = S.ShipmentId
  where (OS.RecordId is null);

  /* If there is no shipments exists for BoL then delete them or they may be recounted later */
  delete B
  from BoLs B
    join #OrderShipments OS on (OS.BoLId = B.BoLId)
    left outer join Shipments S on (S.BolId  = B.BoLId) and
                                   (S.LoadId = B.LoadId)
  where (S.ShipmentId is null);

  /* Recount Pallets */
  exec pr_Pallets_Recalculate @ttPalletsToRecount, 'CS', @BusinessUnit, @UserId;

  /* Get all the orders updated */
  insert into @ttOrdersToUpdate (EntityId) select distinct OrderId from #OrderShipments;
  select * into #OrdersToUpdate from @ttOrdersToUpdate;

  /* If order has single shipment then update Load info on the Order */
  exec pr_OrderHeaders_UpdateLoadInfo @Operation, @BusinessUnit, @UserId;

  /* Recount Orders */
  exec pr_OrderHeaders_Recalculate @ttOrdersToUpdate, default, @UserId;

  /* Recount BoLs */
  insert into @ttBoLsToRecount (EntityId)
    select distinct OS.BoLId from #OrderShipments OS join BoLs B on (B.BoLId = OS.BoLId);  -- Reason for join BoLs is that some BoLs may be deleted above so recount the BoLs that are available

  exec pr_BoL_Recalculate @ttBoLsToRecount;

  /* Recount Shipments */
  insert into @ttShipmentsToRecount (EntityId)
    select distinct ShipmentId from @ttShipments ttS join Shipments S on (S.ShipmentId = ttS.EntityId);  -- Reason for join Shipments is that some Shipments may be deleted above so recount the Shipments that are available

  exec pr_Shipment_Recalculate @ttShipmentsToRecount, default, @BusinessUnit, @UserId;;

  /* Recount Load */
  exec pr_Load_Recount @vLoadId;

  /* Cancel Load if empty */
  if (@CancelLoadIfEmpty = 'Y') and
     (not exists (select ShipmentId from Shipments where LoadId = @vLoadId))
    exec pr_Load_SetStatus @vLoadId, 'X'/* Canceled */ ;

  /*----------------- Audit Trail ----------------*/
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    /* Load Entity */
    select 'Load', LoadId, LoadNumber, 'OrderRemovedFromLoad', @BusinessUnit, @UserId,
           dbo.fn_Messages_Build('AT_OrderRemovedFromLoad', PickTicket, LoadNumber, null, null, null) /* Comment */
    from #OrderShipments
    union
    /* Order Entity */
    select distinct 'PickTicket', OrderId, PickTicket, 'OrderRemovedFromLoad', @BusinessUnit, @UserId,
           dbo.fn_Messages_Build('AT_OrderRemovedFromLoad', PickTicket, LoadNumber, null, null, null) /* Comment */
    from #OrderShipments;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* For Load Cancel & Load Ship it will be a different message which will be built in proc pr_Loads_Action_Cancel &
     pr_Loads_MarkAsShipped respectively */
  if (@Operation not in ('Load_Cancel', 'Load_Ship'))
    /* Based upon the number of Loads that have been Canceled, give an appropriate message */
    exec pr_Messages_BuildActionResponse 'Load', 'RemoveOrders', @vTotalOrders, @vTotalOrders, @LoadNumber;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* if Transaction started in this proc then commit it */
  if (@vTranCount = 0) commit transaction ;

end try
begin catch
  /* if Transaction started in this proc then rollback it */
  if (@vTranCount = 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;

end catch;
ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Load_RemoveOrders */

Go
