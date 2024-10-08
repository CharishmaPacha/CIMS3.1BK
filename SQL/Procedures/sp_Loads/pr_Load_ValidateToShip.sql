/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/25  OK      pr_Load_ValidateToShip: Changes to validate the Load LPN tracking number when shipment is associated with small package carriers (BK-497)
  2021/08/23  AY      pr_Load_GetDetails, pr_Load_ValidateToShip: Performance optimization (HA-3110)
  2021/05/19  SAK     pr_Load_ValidateToShip port back (HA-2805)
  2021/05/06  VS      pr_Load_ValidateAddOrder, pr_Load_ValidateToShip: Validate the ShipFrom based on LoadType (BK-275)
  2021/04/29  AY      pr_Load_ValidateToShip: Do not allow shipping with Generic carrier (HA GoLive)
  2021/04/22  SJ      pr_Load_ValidateToShip: Add validation that trailer number is required for transfer loads (HA-2618)
  2021/04/21  AY      pr_Load_ValidateToShip: Change validations for Transfer Orders (HA GoLive)
  2021/04/17  OK      pr_Load_ValidateToShip: Added validation to do not ship the load if any of the pallet is stuck in Packed status and Loading method is set to RF (HA-2418)
  2021/04/16  TK      pr_Load_ValidateToShip: Do not validate LPNs that are not on shipment, order can be shipped on multiple Loads (HA-2641)
  2021/04/15  TK      pr_Load_ValidateToShip: Bug fix in validating missing tracking numbers (HA-2608)
  2021/04/03  TK      pr_Load_ValidateToShip: Moved shipment related validations
  2021/03/19  SJ      pr_Load_ValidateToShip: Made changes to Shipping validation to give more detailed error (HA-2325)
  2021/03/04  VS      pr_Load_ValidateToShip: Added Shipping-in Progress validation based on operation (BK-249)
  2021/03/02  VS      pr_Load_ValidateToShip: Removed Shiping-In Progress validation as the same called from BackGroundProcess (BK-249)
  2020/09/24  VS      pr_Load_ValidateToShip, pr_Load_MarkAsShipped : Excluded Already ShippedLoad & Shipping-In Progress from Backgroundprocess (S2GCA-1183)
  2020/07/16  RKC     pr_Load_ValidateToShip: Migrated latest changes from CID
                      pr_Load_ValidateToShip: Do not validate for order info for transfer Load type
                      pr_Load_ValidateToShip: Considering estimated weight if actual weight is zero on LPNs (HA-838)
  2018/12/17  RIA     pr_Load_ValidateToShip: Considered SoldToId,DesiredShipdate and built xml to pass to rules for evaluation (OB2-781)
  2018/11/23  CK      pr_Load_ValidateToShip: Added rules for validation to make the client load ID for DICK02
  2018/08/27  PK      pr_Load_ValidateToShip: Added @vMissingWeights taken from port back change(OB2-190)
                      pr_Load_ValidateToShip: Defaulted the BoLRequired control variable to No.
  2016/06/30  AY      pr_Load_ValidateToShip: Added validation to prevent shipping of Load if any
  2016/04/28  AY      pr_Load_ValidateToShip: Validate empty load.
  2016/03/29  SV      pr_Load_ValidateToShip: Validating ShipComplete over Order of the Load to be shipped (NBD-293)
  2016/03/15  OK      pr_Load_ValidateToShip: Added the validation to ensure that BoL is on the Load before the Load can be shipped (NBD-281)
  2014/02/19  PK      pr_Load_ValidateToShip: Added validations LoadShip_SomeLPNsOnLoadWithOutOrderInfo,
  2014/01/09  TD      pr_Load_ValidateToShip: Validations to make sure all the LPNs and associated Pallets
  2012/09/05  AA      pr_Load_ValidateToShip: Added Routing Status validation
              AY      pr_Load_ValidateToShip: Allow Loads to ship when ready to load as client may not have Loading option,
  2012/08/27  PKS     pr_Load_MarkAsShipped: Corrected param for pr_Load_ValidateToShip
  2012/08/27  PKS     pr_Load_MarkAsShipped: Corrected params to pr_Load_ValidateToShip.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_ValidateToShip') is not null
  drop Procedure pr_Load_ValidateToShip;
Go
/*------------------------------------------------------------------------------
  pr_Load_ValidateToShip: This procedure validates the Load is ready to
    Ship or not. The failed validations will be saved with the relevant info
    so that the users can check and remove those Orders from the Load or fix
    the offending issues.
  It raises an error as well, so caller should not rollback the transaction if
   there is one, instead should suppress error and commit.
------------------------------------------------------------------------------*/
Create Procedure pr_Load_ValidateToShip
  (@LoadId    TLoadId,
   @Operation TOperation = null)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vValue1                TString,
          @vValue2                TString,

          /* Load related*/
          @vLoadNumber            TLoadNUmber,
          @vLoadStatus            TStatus,
          @vValidLoadStatusToShip TStatus,
          @vLoadId                TLoadId,
          @vLoadType              TTypeCode,
          @vShipToId              TShipToId,
          @vLoadShipVia           TShipVia,
          @vCarrier               TCarrier,
          @vRoutingStatus         TStatus,
          @vBoLStatus             TStatus,
          @vLoadingMethod         TTypeCode,
          @vLoadTrailerNumber     TTrailerNumber,
          @vBoLId                 TRecordId,
          @vControlCategory       TCategory,
          @vBoLRequired           TControlValue,
          @vClientLoad            TLoadNumber,

          /* LPN Related */
          @vLPNId                 TRecordId,
          @vLPNs                  XML,
          @vLPNStatus             TStatus,
          @vLPNsNotPacked         TCount,
          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId,

          /* Controls */
          @vValidShipmentStatus   TStatus,
          @vValidLPNStatus        TStatus,
          @vSingleLoadOrders      TControlValue,
          @vSmallPackageLoadTypes TControlValue,
          @vIsSmallPackageCarrier TFlag,

          @xmlRulesData           TXML,


          /* others */
          @vRulesDataXML   TXML;

 declare  @ttValidations   TValidations;
begin /* pr_Load_ValidateToShip */
   select @vReturnCode  = 0,
          @vMessageName = null,
          @vUserId      = System_User;

  /* Create #Validations if it doesn't exist */
  if object_id('tempdb..#Validations') is null
    select * into #Validations from @ttValidations;

 /* Get Load Info here..*/
  select @vLoadId             = LoadId,
         @vLoadNumber         = LoadNumber,
         @vLoadType           = LoadType,
         @vShipToId           = ShipToId,
         @vClientLoad         = ClientLoad,
         @vLoadShipVia        = ShipVia,
         @vLoadStatus         = Status,
         @vLoadTrailerNumber  = TrailerNumber,
         @vRoutingStatus      = RoutingStatus,
         @vBoLStatus          = BoLStatus,
         @vLoadingMethod      = LoadingMethod,
         @vBusinessUnit       = BusinessUnit
  from Loads
  where (LoadId = @LoadId);

  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vLoadShipVia) and (BusinessUnit = @vBusinessUnit);

  /* Get the BoL details on the Load */
  select @vBoLId = BolId
  from BoLs
  where (LoadId = @vLoadId);

  /* Build xml, execute rule... */
  select @vRulesDataXML  = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('LoadId',           @vLoadId)          +
                           dbo.fn_XMLNode('LoadNumber',       @vLoadNumber)      +
                           dbo.fn_XMLNode('LoadType',         @vLoadType)        +
                           dbo.fn_XMLNode('ShipToId',         @vShipToId)        +
                           dbo.fn_XMLNode('ClientLoad',       @vClientLoad)      +
                           dbo.fn_XMLNode('ShipVia',          @vLoadShipVia)     +
                           dbo.fn_XMLNode('LoadStatus',       @vLoadStatus)      +
                           dbo.fn_XMLNode('RoutingStatus',    @vRoutingStatus)   +
                           dbo.fn_XMLNode('BusinessUnit',     @vBusinessUnit));

  select @vControlCategory = 'Shipping_' + @vCarrier; /* With respect to Carrier we can setup the Control var for BOL required */

  /* Get the ValidLPNStatus from controls ?? */
  select @vValidLPNStatus        = dbo.fn_Controls_GetAsString('Shipping',  'ValidLPNStatus',   'DE' /* Packed/Staged */, @vBusinessUnit, @vUserId),
         @vSingleLoadOrders      = dbo.fn_Controls_GetAsBoolean('Shipping', 'SingleLoadOrders', 'Y'  /* Yes */,           @vBusinessUnit, @vUserId),
         /* Get the ValidShipmentStatus from controls */
         @vValidShipmentStatus   = dbo.fn_Controls_GetAsString('Shipping', 'ValidShipmentStatus', 'G' /* Staged */,  @vBusinessUnit, System_User),
         @vValidLoadStatusToShip = dbo.fn_Controls_GetAsString('Shipping', 'ValidLoadStatus', 'LR' /* ReadyToLoad/Ship */,  @vBusinessUnit, System_User),
         @vBoLRequired           = dbo.fn_Controls_GetAsString(@vControlCategory, 'BoLRequired', 'N' /* Yes */, @vBusinessUnit, System_User),
         @vSmallPackageLoadTypes = dbo.fn_Controls_GetAsString('Load', 'SmallPackageLoadTypes', 'FDEG,FDEN,UPSE,UPSN,USPS' /* Default: SPL Loads */, @vBusinessUnit, null /* UserId */);

  /* Get all the LPNs on the Load */
  select L.LPNId, L.LPN, L.OrderId, L.PickTicketNo, L.LPNType, L.Status, L.TrackingNo,
         L.EstimatedWeight, L.ActualWeight, L.LPNWeight, L.PalletId, L.Pallet, L.ShipmentId, L.BusinessUnit
  into #LoadLPNs
  from LPNs L
  where (L.LoadId = @vLoadId);

  /* Get Load Orders */
  select OH.OrderId, OH.PickTicket, OH.UnitsAssigned, OH.NumUnits, OH.ShipCompletePercent, OH.Status, OH.FreightTerms,
         S.Status ShipmentStatus, S.BoLId, OS.ShipmentId, OH.IsMultiShipmentOrder, OH.BusinessUnit
  into #LoadOrders
  from Shipments S
    join OrderShipments OS on (OS.ShipmentId = S.ShipmentId)
    join OrderHeaders   OH on (OH.OrderId = OS.OrderId)
  where (S.LoadId = @LoadId);

  /* Get the all the LPNs which are on the load has valid LPNTypes to ship */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_InvalidLPNType', L.LPN, L.PickTicketNo
    from #LoadLPNs L
    where (charindex(L.LPNType, 'FHCS' /* Flat/Hanging/Carton/ShipCarton */) = 0);

  /* Get the all the LPNs which are on the load has valid LPNstatus to ship */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_InvalidLPNStatus', L.LPN, L.PickTicketNo
    from #LoadLPNs L
    where (charindex (L.Status, @vValidLPNStatus) = 0);

  /* if RF Loading, ensure all Pallets/LPNs are loaded before Load is shipped */
  if (@vLoadingMethod = 'RF')
    begin
      /* Show all Pallets yet to be loaded */
      insert into #Validations (EntityType, EntityId, EntityKey, MessageName,
                                Value1, Value2, Value3)
        select 'Pallet', P.Palletid, P.Pallet, 'LoadShip_PalletNotLoaded',
               P.Pallet, P.NumLPNs, dbo.fn_Status_GetDescription ('Pallet', P.Status, P.BusinessUnit)
        from Pallets P
        where (P.Status <> 'L' /* Loaded */) and
              (P.LoadId = @vLoadId);

      /* Include all LPNs which are not on Pallets */
      insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
        select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNNotLoaded', L.LPN, dbo.fn_Status_GetDescription ('LPN', L.Status, L.BusinessUnit)
        from #LoadLPNs L
        where (L.Status <> 'L') and (L.PalletId is null);
    end

  /* Get the LPN that are associated with the Orders on the Load which are still on cart */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_UnitsStillOnCart', L.LPN, L.PickTicketNo
    from #LoadLPNs L
    where (L.LPNType = 'A');

  /* Check if all LPNs on the Load have a weight */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNMissingWeight', L.LPN, L.PickTicketNo
    from #LoadLPNs L
    where (L.LPNWeight = 0);

  /* Check if all the LPNs which are on the load had Order Info on it or not */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNNotAllocated', L.LPN
    from #LoadLPNs L
    where (L.OrderId is null) and
          (@vLoadType <> 'Transfer');

  /* Get all the Orders that do not meet the ShipCompletePercent requirement */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
    select 'Order', LO.OrderId, LO.PickTicket, 'LoadShip_ShortShippingOrder', LO.PickTicket, LO.ShipCompletePercent, cast((UnitsAssigned * 100.0) / NumUnits as decimal(6,2))
    from #LoadOrders LO
    where (LO.UnitsAssigned * 100.0 / LO.NumUnits < LO.ShipCompletePercent);

  /* Fetch Orders which have nothing allocated and are associated with Load */
  insert into #Validations (EntityType, EntityId, EntityKey,  MessageName, Value1)
    select 'Order', LO.OrderId, LO.PickTicket, 'LoadShip_OrdersOnLoadWithNoUnits', LO.PickTicket
    from #LoadOrders LO
    where (LO.NumUnits = 0);

  /* Get the LPN that are associated with the Orders on the Load which are not having Load information */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNsOnOrderWithoutLoadInfo', L.LPN, LO.PickTicket, L.Pallet
    from LPNs L
      join #LoadOrders LO on (L.OrderId = LO.OrderId)
    where (LO.IsMultiShipmentOrder = 'N') and
          (coalesce(L.LoadId, 0) = 0);

  /* Check if all LPNs are associated with a shipment */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNsOnOrderWithoutShipmentInfo', L.LPN, LO.PickTicket, L.Pallet
    from LPNs L
      join #LoadOrders LO on (L.OrderId = LO.OrderId)
    where (LO.IsMultiShipmentOrder = 'N') and
          (coalesce(L.ShipmentId, 0) = 0);

  /* Check if all the LPNs Completely packed or not */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNNotPacked', L.LPN, L.PickTicketNo
    from #LoadLPNs L
    where (charindex(L.Status, 'DELS') = 0);

  if (@vLoadId is null)
    select @vMessageName = 'LoadIsInvalid';
  else
  if (@vLoadStatus = 'S' /* Shipped */)
    select @vMessageName = 'LoadShip_AlreadyShipped';
  else
  if (@vLoadStatus = 'X' /* Canceled */)
    select @vMessageName = 'LoadShip_AlreadyCanceled';
  else
  /* Skip this validation if operation is BackgroundProcess */
  if (@vLoadStatus = 'SI' /* Shipping In-Progress */) and (coalesce(@Operation, '') <> 'BackgroundProcess')
    select @vMessageName = 'LoadShip_LoadBeingShippedInBackGround';
  else
  if ((@vBoLId is null) and (@vBoLRequired = 'Y'))
    select @vMessageName = 'BoLIsRequiredToShip';
  else
  if (coalesce(@vLoadTrailerNumber, '') = '') and (@vLoadType = 'Transfer')
    select @vMessageName = 'LoadShip_TrailerNumberIsRequired';
  else
  if (@vLoadStatus = 'N' /* New */)
    select @vMessageName = 'LoadShip_CannotShipEmptyLoad';
  else
  if (dbo.fn_IsInList(@vLoadStatus, @vValidLoadStatusToShip) = 0)
    select @vMessageName = 'LoadShip_LoadNotReadyToShip';
  else
  if (charindex(@vRoutingStatus, 'CN' /* Confirmed, Not Required */) = 0)
    select @vMessageName = 'LoadShip_InvalidRoutingStatus';
  else
  if (@vCarrier = 'Generic')
    select @vMessageName = 'LoadShip_InvalidCarrierForShipping';
  else
    /* Additional validations to be defined by rules */
    exec pr_RuleSets_Evaluate 'Load_ValidateToShip', @vRulesDataXML, @vMessageName output;

  /* Fetch the Orders having invalid status to ship */
  insert into #Validations (EntityType, EntityId, EntityKey,MessageName, Value1)
    select 'Order', LO.OrderId, LO.PickTicket, 'LoadShip_InvalidOrderStatus', LO.PickTicket
    from #LoadOrders LO
    where (charindex(LO.Status, 'ONW') > 0 /* Downloaded, New, Waved - Should be a control var or rule */);

  /* Need to check if the LPNs and associated Pallets are on the
     same Load or not, so we need to get the count if there are on diff loads */
  insert into #Validations (EntityType, EntityId, EntityKey,MessageName, Value1, Value2, Value3)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_PalletAndLPNsAreOnDiffLoads', L.LPN, P.Pallet, P.LoadId
    from #LoadLPNs L
      join Pallets P on (L.PalletId = P.PalletId)
    where (coalesce(P.LoadId, 0) <> @vLoadId);

  /* Check if all Pallets on the Loads have the LPNs which are on the same Load */
  insert into #Validations (EntityType, EntityId, EntityKey,MessageName, Value1, Value2, Value3)
    select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNsAreOnDiffLoadFromPallet', P.Pallet, L.LPN, L.LoadId
    from Pallets P
     join LPNs L with (index = ix_LPNs_PalletId) on (L.PalletId = P.PalletId)
    where (P.LoadId = @vLoadId) and
          (coalesce(L.LoadId, 0) <> @vLoadId);

  /* For LTL Load, check if all orders have a BoL */
  if (@vCarrier in ('LTL'))
    insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1)
      select 'Order', OrderId, PickTicket, 'LoadShip_MissingBoLInfoOnOrder', PickTicket
      from #LoadOrders LO
      where (BoLId is null);

  /* Get the Orders which are not having the valid shipments status to ship the load */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1)
    select 'Order', OrderId, PickTicket, 'LoadShip_ShipmentOnLoadNotReadyToShip', PickTicket
    from #LoadOrders LO
    where (dbo.fn_IsInList(ShipmentStatus, @vValidShipmentStatus) = 0);

  /* Check if there are Orphan Shipments i.e. shipments with no LPNs */
  insert into #Validations (EntityType, EntityId, MessageName, Value1)
    select 'Shipment', ShipmentId, 'LoadShip_NoLPNsOnShipment', ShipmentId
    from Shipments
    where (LoadId = @LoadId) and
          (NumLPNs = 0);

  /* Make sure LPNs have proper tracking number if Load is Small Package Carrier */
  if (dbo.fn_IsInList(@vLoadType, @vSmallPackageLoadTypes) > 0)
    insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
      select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNMissingTrackingNo', L.LPN, L.PickTicketNo
      from #LoadLPNs L
      where (coalesce(L.TrackingNo, '') = '');
  else
    /* If shipment is associated with small package carrier and LPNs doesn't has proper tracking numbers */
    insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
      select 'LPN', L.LPNId, L.LPN, 'LoadShip_LPNMissingTrackingNo', L.LPN, L.PickTicketNo
      from #LoadLPNs L
        join Shipments S  on (L.ShipmentId = S.ShipmentId)
        join Shipvias  SV on (SV.SHipvia   = S.Shipvia)
      where (coalesce(L.TrackingNo, '') = '') and
            (SV.IsSmallPackageCarrier = 'Y');

  /* Some orders can be shipped in multiple shipments and in that case there may be open
     tasks, else if it is not a multi shipment order and there are open tasks, raise an error */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
    select 'Order', LO.OrderId, LO.PickTicket,'LoadShip_OrderHasOutstandingPicks', LO.PickTicket, TD.TaskId
    from #LoadOrders LO
      join TaskDetails TD on (TD.OrderId = LO.OrderId)
    where (LO.IsMultiShipmentOrder = 'N') and
          (TD.Status not in ('C' /* Completed */, 'X' /* Cancelled */));

ErrorHandler:
  /* Save Validations to AuditTrail */
  exec pr_Notifications_SaveValidations 'Load', @vLoadId, @vLoadNumber, 'NO' /* Save To */, 'LoadShipValidations', @vBusinessUnit, @vUserId;

  /* Show the validations messages in UI */
  insert into #ResultMessages (MessageType, MessageText, Value1, Value2, Value3, Value4, Value5)
    select coalesce(MessageType, 'E' /* Error */), dbo.fn_messages_Build(MessageName, Value1, Value2, Value3, Value4, Value5),
           Value1, Value2, Value3, Value4, Value5
    from #Validations

  /* We don't need to raise exceptions becuase there are validations failed,
     just sending a return code is sufficient */
  -- if (@vMessageName is null) and  (exists (select * from #Validations))
  --   select @vMessageName = 'LoadShip_FailedValidations';

  /* This return code is handled back in pr_Entities_ExecuteProcess */
  if (@Operation = 'BackgroundProcess') and (@vMessageName = 'LoadShip_AlreadyShipped')
    set @vReturnCode = 2;
  /* Error handling for any process calling this proc */
  else
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2;
  else
  if (exists (select * from #Validations))
    set @vReturnCode = 1;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Load_ValidateToShip */

Go
