/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/13  RKC     pr_Load_Generate, pr_Load_AddOrders: Moved the all validation messages to Rules
  pr_Loads_AutoBuild, pr_Load_UI_AddOrders: Pass the Operation parm to pr_Load_AddOrders
  pr_Load_AddOrders: Added new parms as Operation (HA-1610)
  2020/10/08  AY      pr_Load_AddOrder: Pregenerated LPNs not being added to Loads (HA-1538)
  2018/12/15  AY      pr_Load_AddOrder: Add orphan LPNs to the shipment when Order is re-added to new Load (S2G-Support)
  2018/08/12  RV      pr_Load_AddOrders: Made changes to do not allow order if the order have outstanding picks (OB2-554)
  2016/01/05  SV      pr_Load_CreateNew, pr_Load_AddOrder, pr_Load_RemoveOrders,
  2015/09/16  YJ      pr_Load_AddOrders: Added validation to avoid Orders which has ShipVia null. (ACME-336)
  2013/01/20  AY      pr_Load_AddOrder: Bug fix with retaining old Shipments for the Order/PT.
  PK      pr_Load_AddOrder: Modified to update Shipment Counts.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_AddOrder') is not null
  drop Procedure pr_Load_AddOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_AddOrder: Adds the given Order to the Load.
------------------------------------------------------------------------------*/
Create Procedure pr_Load_AddOrder
  (@LoadId        TLoadId,
   @OrderId       TRecordId,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @vOrderShipmentId  TShipmentId,
          @vLoadShipmentId   TShipmentId,
          @vAutoAssignLPNs   TFlag,
          @vUpdateOption     TFlag;

begin  /* pr_Load_AddOrder */
  select  @ReturnCode       = 0,
          @Messagename      = null,
          @vOrderShipmentId = null,
          @vLoadShipmentId  = null;

  /* Check if the Order is already associated with the Load */
  select @vOrderShipmentId = ShipmentId
  from vwOrderShipments
  where ((OrderId = @OrderId) and (LoadId = @LoadId));

  /* Order already associated with the Load, do nothing, just exit */
  if (@vOrderShipmentId is not null)
    goto ExitHandler;

  /* Verify if the Order can be added to this Load, if not exception is raised */
  exec @ReturnCode = pr_Load_ValidateAddOrder @LoadId, @OrderId;

  /* Get the autoassignLPNs value from Controls */
  select @vAutoAssignLPNs = dbo.fn_Controls_GetAsBoolean('Shipping', 'AutoAssignLPNs', 'Y' /* Yes */,  @BusinessUnit, @UserId);

  /* Check if the Order has a residual shipment not on any Load */
  select @vOrderShipmentId = ShipmentId
  from vwOrderShipments
  where ((OrderId = @OrderId) and (coalesce(LoadId, 0) = 0));

  /* The Order is not associated with the Load, check to see if there is an existing
     shipment on the Load that the Order could be associated with i.e. any if the
     Load already has a shipment for the same ShipTo as that of the Order we would
     add to that shipment instead of creating a new one */
  exec @ReturnCode = pr_Load_FindShipmentForOrder @LoadId, @OrderId, @vLoadShipmentId output;

  if (@vLoadShipmentId is not null)
    begin
      /* Add Order to the Shipment that is already on the Load - assign the LPNs
         not on any Load to this shipment as well */
      exec pr_Shipment_AddOrder @OrderId, @vLoadShipmentId, @vAutoAssignLPNs, @BusinessUnit, @UserId;

      /* Now if there is an old shipment on the order that is now empty i.e. has
         no LPNs then delete it */
      if (@vOrderShipmentId is not null)
        exec pr_Shipment_Delete @vOrderShipmentId, default /* Criteria */, @BusinessUnit, @UserId;
    end
  else
    begin
      /* Find if there is an existing Shipment associated with the Order, not on any Load,
         if OrderShipment is null then pass the update flag as Yes, because we need to update
         count/status of the shipments */
      select @vOrderShipmentId = ShipmentId,
             @vUpdateOption    = case
                                   when (ShipmentId is not null) then
                                     'Y' /* Yes */
                                   else
                                     'N' /* No */
                                  end
      from vwOrderShipments
      where ((OrderId = @OrderId) and (coalesce(LoadId, 0) = 0));

      /* If the Order has no shipment to associate with the current Load, then Create a New One
         Or Create new one if the shipment exists but is in Shipped Status */
      if (@vOrderShipmentId is null)
        begin
          exec @ReturnCode = pr_Shipment_CreateNew @OrderId, @LoadId, @vAutoAssignLPNs, @UserId, @vOrderShipmentId output;

          /* When new shipment is create then need to update counts and status of that Shipment.*/
          exec pr_Shipment_Recount @vOrderShipmentId;
        end
      else
      /* If there are any LPNs not on any Shipment, then add to the shipment which is going to be added to the Load */
      if (@vAutoAssignLPNs = 'Y' /* Yes */)
        update LPNs
        set ShipmentId = @vOrderShipmentId
        where (OrderId = @OrderId) and
              (coalesce(ShipmentId, 0) = 0) and
              (coalesce(LoadId, 0)     = 0) and
              (LPNType not in ('A', 'L' /* Cart, Logical */)) and
               /* K- Picked, G- Packing, D- Packed, E- Staging */
              ((charindex(Status, 'KGDE') <> 0) or
               (LPNType = 'S' /* Shipping Carton */));

      /* add the Order Shipment to Load */
      exec pr_Load_AddShipment @LoadId, @vOrderShipmentId, @vUpdateOption /*Do Recount */;
    end

  /* Update status of the order */
  exec pr_OrderHeaders_Recount @OrderId;

  /* Auditing */
  exec pr_AuditTrail_Insert 'OrderAddedToLoad', @UserId, null /* ActivityDateTime - if null takes the Current TimeStamp */,
                            @OrderId       = @OrderId,
                            @LoadId        = @LoadId;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_AddOrder */

Go
