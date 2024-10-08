/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/19  TK      pr_Shipment_MarkAsShipped: Ship only the LPNs that are loaded (HA-2641)
  2021/04/03  TK      pr_Shipment_SetStatus & pr_Shipment_MarkAsShipped: Code revamp (HA-1842)
  2017/06/21  TK      pr_Shipment_MarkAsShipped: Changes to improve performance in closing Loads (CIMS-1467)
  2013/12/28  TD      pr_Shipment_MarkAsShipped: Passing generate exports as no
  2012/10/25  VM      pr_Shipment_MarkAsShipped: Update ShippedDate on shipment
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_MarkAsShipped') is not null
  drop Procedure pr_Shipment_MarkAsShipped;
Go
/*------------------------------------------------------------------------------
  Proc :This Procedure pr_Shipment_MarkAsShipped update the status
        with shipped, and it also validates the shipment is allow to mark as
        shipped or not by calling the proc pr_Shipment_ValidateToShip.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_MarkAsShipped
  (@ShipmentId        TShipmentId,
   @ValidateShipment  TFlag = 'N',
   @UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName;

  declare @ttLPNsToShip        TLPNDetails,
          @ttOrdersToShip      TOrderDetails;
begin /* pr_Shipment_MarkAsShipped */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Create required hash tables */
  select * into #LPNsToShip   from @ttLPNsToShip;
  select * into #OrdersToShip from @ttOrdersToShip;

  /* If the caller needs to validate the shipment then the flag ValidateShipment is sent as a 'Y'-Yes */
  -- These validations are now moved to Load_ValidateToShip
  --if (@ValidateShipment = 'Y' /* Yes */)
  --  exec @vReturnCode = pr_Shipment_ValidateToShip @vShipmentId;

  /* If the above procedure gives any erro then need to show that.*/
  --if (@vReturnCode <> 0)
  --  goto ErrorHandler;

  /* Get all the LPNs that are to be shipped */
  insert into #LPNsToShip (EntityId)
    select LPNId
    from LPNs
    where (ShipmentId = @ShipmentId) and
          (Status not in ('V' /* Voided */, 'S'/* Shipped */));

  /* Mark the LPNs as shipped */
  exec pr_LPNs_ShipMultiple 'LPNsShip', @BusinessUnit, @UserId;

  /* Get all the Orders that are to be shipped */
  insert into #OrdersToShip (OrderId, LoadId, ShipmentId)
    select OrderId, LoadId, ShipmentId
    from vwOrderShipments
    where (ShipmentId = @ShipmentId) and
          (OrderStatus not in ('S'/* Shipped */));

  /* Mark Orders as shipped */
  exec pr_OrderHeaders_ShipMultiple 'OrdersShip', @BusinessUnit, @UserId;

  /* Recount Shipment */
  exec pr_Shipment_Recount @ShipmentId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipment_MarkAsShipped */

Go
