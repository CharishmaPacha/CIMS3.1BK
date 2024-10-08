/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/29  PK/YJ   pr_OrderHeaders_RegenerateLoads: ported changes from prod onsite (HA-2729)
  2021/03/23  TK      pr_OrderHeaders_RegenerateLoads: Fix to create loads if Orders are not on load (HA-GoLive)
  2021/03/18  OK      pr_OrderHeaders_RegenerateLoads: bug fix to recount the pallet when LPNs are loaded to another loads (HA-2332)
  2021/03/17  TK      pr_OrderHeaders_RegenerateLoads: Bug fixes and performance optimization (HA-2303)
  2021/02/19  TK      pr_OrderHeaders_RegenerateLoads: Initial Revision (HA-1962)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_RegenerateLoads') is not null
  drop Procedure pr_OrderHeaders_RegenerateLoads;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_RegenerateLoads: Evaluates the Orders in #OrderRoutingInfo
    and generates the Loads based upon the given LoadGroup in the table. If the
    order is present on any load then it deletes the corresponding order shipment,
    removes order from the load and then create new shipment for new load,
    adds order to the shipment, adds order to new load

  #OrderRoutingInfo - TOrderRoutingInfo
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_RegenerateLoads
  (@Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vRecordId                TRecordId,

          @vLoadId                  TRecordId,
          @vLoadNumber              TLoadNumber,
          @vNewLoadGroup            TLoadGroup,
          @vNewLoadType             TTypeCode,
          @vDeliveryStart           TDateTime,
          @vDesiredShipDate         TDateTime;

  declare @ttLPNsToLoad             TLPNsToLoad,
          @ttShipments              TRecountKeysTable,
          @ttLoadsToRecount         TEntityKeysTable,
          @ttBoLsToRecount          TEntityKeysTable,
          @ttShipmentsToRecount     TEntityKeysTable,
          @ttPalletsToRecount       TRecountKeysTable,
          @ttAuditTrailInfo         TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vNewLoadGroup = '';

  /* Create required hash tables */
  select * into #LPNsToLoad from @ttLPNsToLoad;

  /* Get the current Load information for the given Orders */
  update ORI
  set PrevLoadId     = Load.LoadId,
      PrevLoadNumber = Load.LoadNumber,
      PrevLoadType   = Load.LoadType,
      PrevLoadGroup  = coalesce(Load.LoadGroup, ''),
      PrevShipmentId = S.ShipmentId,
      PrevBoLId      = S.BolId
  from #OrderRoutingInfo ORI
    join OrderShipments OS   on OS.OrderId   = ORI.OrderId
    join Shipments      S    on S.ShipmentId = OS.ShipmentId and S.Status <> 'S' /* Shipped */
    join Loads          Load on Load.LoadId  = S.LoadId;

  /* If order is not on a Load, set to zero */
  update #OrderRoutingInfo set PrevLoadId = coalesce(PrevLoadId, 0);

  /* delete the orders that are already on the same Load */
  delete from #OrderRoutingInfo where PrevLoadId > 0 and PrevLoadGroup = NewLoadGroup;

  /* Check if there is any load that already exists with same load group and update new load info on orders */
  update ORI
  set NewLoadId     = Load.LoadId,
      NewLoadNumber = Load.LoadNumber
  from #OrderRoutingInfo ORI
    join Loads Load on (Load.LoadGroup = ORI.NewLoadGroup) and
                       (Load.FromWarehouse = ORI.Warehouse) and
                       (Load.Status not in ('X', 'S' /* Canceled/Shipped */));

  /* Get the list of load groups to generate loads for */
  select NewLoadGroup, min(PrevLoadType) PrevLoadType, min(UDF1) DesiredShipDate, min(UDF2) DeliveryStart
  into #LoadsToGenerate
  from #OrderRoutingInfo
  where (NewLoadGroup <> coalesce(PrevLoadGroup, '')) and
        (NewLoadNumber is null)
  group by NewLoadGroup;

  /* Create loads for each load group */
  while exists (select * from #LoadsToGenerate where NewLoadGroup > @vNewLoadGroup)
    begin
      select top 1 @vNewLoadGroup    = NewLoadGroup,
                   @vNewLoadType     = coalesce(PrevLoadType, 'LTL'),
                   @vDesiredShipDate = cast(nullif(DesiredShipDate, '') as datetime),
                   @vDeliveryStart   = cast(nullif(DeliveryStart, '') as datetime)
      from #LoadsToGenerate
      where NewLoadGroup > @vNewLoadGroup
      order by NewLoadGroup;

      /* Get the new load seq number */
      exec pr_Load_GetNextSeqNo @BusinessUnit, null, @vLoadNumber output;

      /* Create Load */
      insert into Loads (LoadNumber, LoadType, LoadGroup, DesiredShipDate, AppointmentDateTime, BusinessUnit, CreatedBy)
        select @vLoadNumber, @vNewLoadType, @vNewLoadGroup, @vDesiredShipDate, @vDeliveryStart, @BusinessUnit, @UserId

      /* Identify LoadId */
      select @vLoadId = scope_identity();

      /* Update new load info on temp table to process */
      update #OrderRoutingInfo
      set NewLoadId     = @vLoadId,
          NewLoadNumber = @vLoadNumber
      where (NewLoadGroup = @vNewLoadGroup);

      /* Reset variables */
      select @vLoadId = null, @vLoadNumber = null;
    end

  /* Find the NewLoads and PrevLoads where all orders on the new loads are all from one PrevLoad only */
  select min(PrevLoadId) as PrevLoadId, NewLoadId
  into #MatchingLoads
  from #OrderRoutingInfo
  group by NewLoadId
  having (count(distinct PrevLoadId) = 1) and (min(PrevLoadId) > 0);

  /* Copy information from prev loads to new loads if all orders on NewLoads were from one PrevLoad only */
  update NewLoad
  set Status                = PrevLoad.Status,
      RoutingStatus         = PrevLoad.RoutingStatus,
      LoadingMethod         = PrevLoad.LoadingMethod,
      ShipVia               = PrevLoad.ShipVia,
      Priority              = PrevLoad.Priority,
      TrailerNumber         = PrevLoad.TrailerNumber,
      SealNumber            = PrevLoad.SealNumber,
      ProNumber             = PrevLoad.ProNumber,
      MasterTrackingNo      = PrevLoad.MasterTrackingNo,
      FromWarehouse         = PrevLoad.FromWarehouse,
      ShipFrom              = PrevLoad.ShipFrom,
      Account               = PrevLoad.Account,
      AccountName           = PrevLoad.AccountName,
      SoldToId              = PrevLoad.SoldToId,
      ShipToId              = PrevLoad.ShipToId,
      ShipToDesc            = PrevLoad.ShipToDesc,
      ConsolidatorAddressId = PrevLoad.ConsolidatorAddressId,
      DockLocation          = PrevLoad.DockLocation,
      StagingLocation       = PrevLoad.StagingLocation
  from #MatchingLoads ML
    join Loads NewLoad  on NewLoad.LoadId = ML.NewLoadId
    join Loads PrevLoad on PrevLoad.LoadId = ML.PrevLoadId;

  /********************  Remove orders from existing loads ********************/
  /* Delete existing order shipments, we would create new order shipments with new load info */
  delete OS
  output deleted.ShipmentId into @ttShipments (EntityId)
  from #OrderRoutingInfo ORI
    join OrderShipments OS on OS.OrderId   = ORI.OrderId
    join Shipments      S  on S.ShipmentId = OS.ShipmentId     and
                              S.LoadId     = ORI.PrevLoadId and
                              S.Status    <> 'S' /* Shipped */;

  /* If there are no orders associated with the shipments then delete them  */
  delete S
  from Shipments S
    join @ttShipments ttS on S.ShipmentId = ttS.EntityId
    left outer join OrderShipments OS on OS.ShipmentId = S.ShipmentId
  where OS.RecordId is null;

  /********************  Add orders to new Loads  *****************************/
  /* Get the required info that is needed to create new shipments */
  insert into #LPNsToLoad (LPNId, LPN, PalletId, Pallet, OrderId,  OrderType, DesiredShipDate, FreightTerms,
                           LoadId, LoadNumber, ShipmentId, SoldToId, ShipToId, ShipVia, ShipFrom)
    select L.LPNId, L.LPN, L.PalletId, L.Pallet, OH.OrderId, OH.OrderType, OH.DesiredShipDate, coalesce(OH.FreightTerms, 'PREPAID'),
           ORI.NewLoadId, ORI.NewLoadNumber, 0 /* ShipmentId */, OH.SoldToId, OH.ShipToId, OH.ShipVia, OH.ShipFrom
    from #OrderRoutingInfo ORI
      join OrderHeaders OH  on OH.OrderId = ORI.OrderId
      left outer join LPNs L on OH.OrderId = L.OrderId   -- by this time LPNs may or may not be associated with orders, so use order into to create new shipments

  /* Invoke procedure that creates shipments for the LPNs/Orders that is cleared above */
  if exists (select * from #LPNsToLoad where ShipmentId = 0)
    exec pr_Shipment_CreateShipments null, @Operation, @BusinessUnit, @UserId;

  /* Update latest ShipmentId on the LPNs */
  update L
  set LoadId     = ORI.NewLoadId,
      LoadNumber = ORI.NewLoadNumber,
      ShipmentId = LTL.ShipmentId,
      BoL        = null
  from LPNs L
    join #OrderRoutingInfo ORI on L.OrderId = ORI.OrderId
    join #LPNsToLoad       LTL on L.LPNId = LTL.LPNId;

  /* Recount Loads */
  insert into @ttLoadsToRecount (EntityId)
    select distinct PrevLoadId from #OrderRoutingInfo ORI join Loads Load on (ORI.PrevLoadId = Load.LoadId) and Status <> 'X'
    union
    select distinct NewLoadId from #OrderRoutingInfo;

  exec pr_Load_Recalculate @ttLoadsToRecount;

  /* If there are no shipments associated to previous load then cancel them
     This step has to be done after updating counts on the load */
  update Load
  set Status       = 'X' /* Canceled */,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  from Loads Load
    join #OrderRoutingInfo ORI on ORI.PrevLoadId = Load.LoadId
    left outer join Shipments S on S.LoadId = Load.LoadId
  where S.ShipmentId is null;

  /* Recount BoLs */
  insert into @ttBoLsToRecount (EntityId) select distinct PrevBoLId from #OrderRoutingInfo;
  exec pr_BoL_Recalculate @ttBoLsToRecount;

  /* Recount Shipments */
  insert into @ttShipmentsToRecount (EntityId)
    select distinct EntityId from @ttShipments
    union
    select distinct ShipmentId from #LPNsToLoad;

  exec pr_Shipment_Recalculate @ttShipmentsToRecount, default, @BusinessUnit, @UserId;;

  /* Recount Pallets */
  insert into @ttPalletsToRecount (EntityId) select distinct PalletId from #LPNsToLoad;
  exec pr_Pallets_Recalculate @ttPalletsToRecount, 'C' /* Counts Only */, @BusinessUnit, @UserId;

  /* Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, UDF1, UDF2, UDF3)
    /* Load Generate info */
    select distinct 'Load', NewLoadId, NewLoadNumber, 'LoadGenerated', @BusinessUnit, @UserId, null, NewLoadNumber, null
    from #OrderRoutingInfo
    union all
    /* Add Order to Load info */
    select distinct 'Load', LoadId, LoadNumber, 'OrderAddedToNewLoadFromDiffLoad', @BusinessUnit, @UserId, ORI.PickTicket, ORI.NewLoadNumber, ORI.PrevLoadNumber
    from #OrderRoutingInfo ORI join #LPNsToLoad LTL on ORI.OrderId = LTL.OrderId
    where PrevLoadNumber is not null
    union all
    select distinct 'Load', LoadId, LoadNumber, 'OrderAddedToNewLoad', @BusinessUnit, @UserId, ORI.PickTicket, ORI.NewLoadNumber, null
    from #OrderRoutingInfo  ORI join #LPNsToLoad LTL on ORI.OrderId = LTL.OrderId
    where PrevLoadNumber is null
    union all
    select distinct 'Order', OrderId, PickTicket, 'OrderAddedToNewLoadFromDiffLoad', @BusinessUnit, @UserId, PickTicket, NewLoadNumber, PrevLoadNumber
    from #OrderRoutingInfo
    where PrevLoadNumber is not null
    union all
    select distinct 'Order', OrderId, PickTicket, 'OrderAddedToNewLoad', @BusinessUnit, @UserId, PickTicket, NewLoadNumber, null
    from #OrderRoutingInfo
    where PrevLoadNumber is null
    union all
    select distinct 'LPN', LPNId, LPN, 'OrderAddedToNewLoadFromDiffLoad', @BusinessUnit, @UserId, ORI.PickTicket, ORI.NewLoadNumber, ORI.PrevLoadNumber
    from #OrderRoutingInfo ORI join #LPNsToLoad LTL on ORI.OrderId = LTL.OrderId
    where PrevLoadNumber is not null
    union all
    select distinct 'LPN', LPNId, LPN, 'OrderAddedToNewLoad', @BusinessUnit, @UserId, ORI.PickTicket, ORI.NewLoadNumber, null
    from #OrderRoutingInfo  ORI join #LPNsToLoad LTL on ORI.OrderId = LTL.OrderId
    where PrevLoadNumber is null;

  /* Build AT Comment */
  update ttAT
  set Comment = dbo.fn_Messages_Build('AT_'+ ActivityType, UDF1, UDF2, UDF3, null, null)
  from @ttAuditTrailInfo ttAT;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_RegenerateLoads */

Go
