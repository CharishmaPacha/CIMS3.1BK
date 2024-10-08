/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/23  AY      pr_Shipment_AddOrder: Do not mark LPNs as loaded when added to Load (HA-2002)
  2020/01/19  VS      pr_Shipment_AddOrder: Assign LPNs to the Shipment (HA-1919)
  2018/05/05  TK      pr_Shipment_AddOrder: Mark LPNs as Loaded only when LPNs are in Picked, Packed, & Staged status (S2G-782)
              AY      pr_Shipment_AddOrder: Mark LPN as Loaded as determined by Load.LoadingMethod (S2G-825)
  2016/10/17  AY/TK   pr_Shipment_AddOrder: Mark LPNs as loaded when added to Load (HPI-GoLive)
  2016/10/13  OK      pr_Shipment_AddOrder: Restricted the updating Load and shipment on the carts (HPI-857)
  2016/10/10  OK      pr_Shipment_AddOrder: Enhanced to update the Load on pallet if LPNs are associated with any pallet (HPI-841)
  2013/05/16  PK      pr_Shipment_AddOrder: Fix to update BoL Number on LPN
  2013/01/20  AY      pr_Shipment_AddOrder: Bug fix - Reassign LPNs not
  2012/12/07  NY      pr_Shipment_AddOrder: Recount on shipment.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_AddOrder') is not null
  drop Procedure pr_Shipment_AddOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipment_AddOrder: Creates a relationship between an Order and a
    Shipment and assigns all unassigned LPNs on the order to the shipment
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_AddOrder
  (@OrderId        TRecordId,
   @ShipmentId     TLoadId,
   @AutoAssignLPNs TFlag,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          /* LoadInfo on the Shipments */
          @vShipmentId         TShipmentId,
          @vShipmentLoadId     TLoadId,
          @vShipmentLoadNumber TLoadNumber,
          @vShipmentBoL        TBoL,
          /* Load */
          @vLoadingMethod      TTypeCode,
          /* Controls */
          @vMarkLPNAsLoaded    TControlValue;

  declare @ttPalletsToUpdate   TEntityKeysTable;

begin /* pr_Shipment_AddOrder */
  select @ReturnCode     = 0,
         @AutoAssignLPNs = coalesce(@AutoAssignLPNs, 'N' /* No */),
         @Messagename    = null;

  if (@OrderId is null)
    set @MessageName = 'OrderIsInvalid';
  else
  if (@ShipmentId is null)
    set @MessageName = 'ShipmentIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get the LoadInfo for the given shipmentId */
  select @vShipmentId         = ShipmentId,
         @vShipmentLoadId     = LoadId,
         @vShipmentLoadNumber = LoadNumber,
         @vShipmentBoL        = BoLNumber
  from Shipments
  where (ShipmentId = @ShipmentId);

  select @vLoadingMethod = LoadingMethod
  from Loads
  where (LoadId = @vShipmentLoadId);

  /* Get the autoassignLPNs value from Controls */
  select @vMarkLPNAsLoaded = dbo.fn_Controls_GetAsString('Shipping', 'UpdateLPNStatusOnLoad', 'Y' /* Yes */,  @BusinessUnit, @UserId);

  /* Associate Order with Shipment, if not already done */
  if (not exists(select *
                 from OrderShipments
                 where((ShipmentId = @ShipmentId) and
                       (OrderId    = @OrderId))))
    begin
      insert into OrderShipments(ShipmentId,
                                 OrderId,
                                 BusinessUnit,
                                 CreatedBy)
                          select @ShipmentId,
                                 @OrderId,
                                 @BusinessUnit,
                                 coalesce(@UserId, system_user);
    end

  if (@AutoAssignLPNs = 'Y' /* Yes */)
    begin
       /* If the flag is true, and the LPNs associated with the Orders are not
          on any shipment then we need to update the ShipmentId and LoadId.
          LPNs are added to Load only if they are already Picked, Packing, Packed or Staged
          LPNs that are allocated or New Temp LPNs would be added after they are picked.
          LPNs may be added to Loads, but are only marked as Loaded based upon the LoadingMethod */
       update LPNs
       set ShipmentId = @ShipmentId,
           LoadId     = @vShipmentLoadId,
           LoadNumber = @vShipmentLoadNumber,
           BoL        = @vShipmentBoL,
           UDF4       = Status,
           Status     = case when @vLoadingMethod = 'Auto' and  (charindex(Status, 'KGDE') <> 0) then 'L' /* Loaded */ else Status end
       where (OrderId = @OrderId) and
             (coalesce(ShipmentId, 0) = 0) and
             (coalesce(LoadId, 0)     = 0) and
             (LPNType not in ('A', 'L' /* Cart, Logical */)) and
              /* K- Picked, G- Packing, D- Packed, E- Staging */
             ((charindex(Status, 'KGDE') <> 0) or (LPNType = 'S' /* Shipping Carton */));

       /* Get the distinct Pallets on updated LPNs */
       insert into @ttPalletsToUpdate (EntityId)
         select distinct PalletId
         from LPNs
         where ((OrderId = @OrderId) and
                (LPNType <> 'A' /* Cart */));

      /* Recount all Pallets are on LPN so that Pallets could also get updated with Load, Shipment details */
      exec pr_Pallets_Recount @ttPalletsToUpdate, @Businessunit, @UserId;
    end

  exec pr_Shipment_Recount @ShipmentId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipment_AddOrder */

Go
