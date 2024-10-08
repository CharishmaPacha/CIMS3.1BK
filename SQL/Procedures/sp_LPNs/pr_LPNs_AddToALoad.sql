/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/10  TD      pr_LPNs_AddToALoad: Calling pr_BoL_Recount procedure to BoL Recalculate.
  2013/05/16  PK      pr_LPNs_AddToALoad: Fix to update LoadNumber and BoLNumber on LPN
  2012/10/15  VM      pr_LPNs_AddToALoad: Do not need to consider BusinessUnit in where condition as caller passing LPNId only.
  2012/09/06  VM      pr_LPNs_AddToALoad: Recount Load and Shipments based on flag (new param added)
  2012/08/30  YA      pr_LPNs_AddToALoad: Assign Loads to LPNs if the LPNs are picked after the Load is generated.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_AddToALoad') is not null
  drop Procedure pr_LPNs_AddToALoad;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_AddToALoad: This procedure updates LPNs with the Loads on an order
    it belongs to. This would be useful when a Load is already created without
    LPNs and the LPNs are picked later.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_AddToALoad
  (@LPNId          TRecordId,
   @BusinessUnit   TBusinessUnit,
   @LoadRecount    TFlag = 'N' /* No */,
   @UserId         TUserId = null)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vLPNId            TRecordId,
          @vOrderId          TRecordId,
          @vShipmentId       TRecordId,
          @vLoadId           TRecordId,
          @vLoadNumber       TLoadNumber,
          @vBoLNumber        TBoLNumber,
          @vBoLId            TBoLId,

          @vDynamicLoading   TFlags;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Dynamic Loading is where LPNs are not added to the Load in advance, but are directly Loaded into the truck using RF Loading
     at which time LPNs get added to the Loads */
  select @vDynamicLoading = dbo.fn_Controls_GetAsString('Shipping', 'DynamicLoading', 'N' /* No */, @BusinessUnit, @UserId);

  if (@vDynamicLoading = 'Y')
    return;

  /* fetch the OrderId on which the LPN is to be updated */
  select @vLPNId   = LPNId,
         @vOrderId = OrderId
  from LPNs
  where (LPNId        = @LPNId) and
        (LPNType not in ('A'/* Cart */)) and
        /* VM: As caller is directly passing LPNId, I think we do not need to verify BusinessUnit - hence, coalesce used. */
        (BusinessUnit = coalesce(@BusinessUnit, BusinessUnit));

  if (@vLPNId is null) or (@vOrderId is null)
     goto ExitHandler;

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

  if (@vShipmentId is null) and (@vLoadId is null)
    goto Exithandler;

  /* Update LPNs */
  update LPNs
  set LoadId     = @vLoadId,
      LoadNumber = @vLoadNumber,
      ShipmentId = @vShipmentId,
      BoL        = @vBoLNumber
  where (LPNId = @vLPNId);

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
end /* pr_LPNs_AddToALoad */

Go
