/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/15  RKC     pr_LPNs_MarkAsLoaded: Pass the missed parameter to pr_Load_CreateNew (HA-942)
  2020/06/13  RV      pr_LPNs_MarkAsLoaded: Caller pr_Load_CreateNew changed by including Routing Instructions (HA-908)
  2014/07/14  TD      Added new procedure pr_LPNs_SetUCCBarcode, pr_LPNs_MarkAsLoaded.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_MarkAsLoaded') is not null
  drop Procedure pr_LPNs_MarkAsLoaded;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_MarkAsLoaded: This procedure will add the LPN to Load and
         will mark the LPN as Loaded.

  Case 1: If the order is not yet on any load then we will create a new load
          and will add the LPN to that Load.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_MarkAsLoaded
  (@LPNId          TRecordId,
   @BusinessUnit   TBusinessUnit,
   @LoadRecount    TFlag = 'N' /* No */,
   @UserId         TUserId = null)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vShipVia          TShipVia,
          @vShipToId         TShipToId,
          @vWeight           TWeight,
          @vVolume           TVolume,
          @vDesiredShipDate  TDateTime,
          @vCustPO           TCustPO,
          @vFromWarehouse    TWarehouseId,

          @vLPNId            TRecordId,
          @vOrderId          TRecordId,
          @vShipmentId       TRecordId,
          @vLoadId           TRecordId,
          @vLoadNumber       TLoadNumber,
          @vBoLNumber        TBoLNumber,
          @vBoLId            TBoLId,
          @vStatus           TStatus,

          @vDynamicLoading   TFlags,
          @Message           TMessageName;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* fetch the OrderId on which the LPN is to be updated */
  select @vLPNId   = LPNId,
         @vOrderId = OrderId,
         @vStatus  = Status
  from LPNs
  where (LPNId        = @LPNId) and
        (LPNType not in ('A'/* Cart */)) and
        /* VM: As caller is directly passing LPNId, I think we do not need to verify BusinessUnit - hence, coalesce used. */
        (BusinessUnit = coalesce(@BusinessUnit, BusinessUnit));

  if (@vLPNId is null) or (@vOrderId is null) or (@vStatus in ('L', 'S' /* Loaded or shipped */))
     goto ExitHandler;

  /* get load if there is exist for the Order */
  select @vLoadId = LoadId
  from vwOrderShipments
  where (OrderId = @vOrderId) and
        (ShipmentStatus not in ('X', 'S'/* Canceled, Shipped */))

  /* if there is no Load for the Order then we need to create a new load here
    and add that order to that Load */
  if (@vLoadId is null)
    begin
      /* Get order info here  to create Load */
      select @vShipVia         = ShipVia,
             @vShipToId        = ShipToId,
             @vWeight          = TotalWeight,
             @vVolume          = TotalVolume,
             @vDesiredShipDate = DesiredShipDate,
             @vCustPO          = CustPO,
             @vFromWarehouse   = Warehouse
      from OrderHeaders
      where (OrderId = @vOrderId);

      exec pr_Load_CreateNew @UserId           = @UserId,
                             @BusinessUnit     = @BusinessUnit,
                             @LoadType         = Default /* Load Type */,
                             @ShipVia          = @vShipVia,
                             @DesiredShipDate  = @vDesiredShipDate,
                             @FromWarehouse    = @vFromWarehouse,
                             @ShipToId         = @vShipToId,
                             @Weight           = @vWeight,
                             @Volume           = @vVolume,
                             @LoadId           = @vLoadId     output,
                             @LoadNumber       = @vLoadNumber output,
                             @Message          = @Message     output;

      /* if load number not null then we need to add the order to load */
      if (@vLoadNumber is not null)
        exec pr_Load_AddOrder @vLoadId, @vOrderId, @BusinessUnit, @UserId;
    end

  /* select the ShipmentId and LoadId which is to be updated on loads,
     fetching it from the Order on which the Load is assigned */
  select @vLoadId     = OS.LoadId,
         @vLoadNumber = OS.LoadNumber,
         @vShipmentId = OS.ShipmentId,
         @vBoLNumber  = OS.BoLNumber,
         @vBoLId      = OS.BoLId
  from vwOrderShipments OS
  where (OS.OrderId      = @vOrderId) and
        (OS.ShipmentStatus not in ('X', 'S'/* Canceled, Shipped */));

  /* Update LPNs */
  update LPNs
  set LoadId     = @vLoadId,
      LoadNumber = @vLoadNumber,
      ShipmentId = @vShipmentId,
      BoL        = @vBoLNumber,
      Status     = 'L' /* Loaded */
  where (LPNId = @vLPNId);

  exec pr_OrderHeaders_SetStatus @vOrderId, null /* Status */, @USerId;

  if (@LoadRecount = 'Y' /* Yes */)
    begin
      exec pr_Load_Recount      @vLoadId;
      exec pr_Shipment_Recount  @vShipmentId;

      /* Recalculate  if the order is already on the BoL*/
      if (coalesce(@vBoLId, 0) <> 0)
        exec pr_BoL_Recount @vBoLId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_MarkAsLoaded */

Go
