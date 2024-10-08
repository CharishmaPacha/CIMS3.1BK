/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_ValidateToShip') is not null
  drop Procedure pr_Shipment_ValidateToShip;
Go
/*------------------------------------------------------------------------------
  Proc :This Procedure pr_Shipment_ValidateToShip update the status
        with shipped
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_ValidateToShip
  (@ShipmentId    TShipmentId)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          /* shipment Related*/
          @vShipmentId          TShipmentId,
          @vShipmentStatus      TStatus,
          @vBusinessUnit        TBusinessUnit,

          @vLPNsOnShipments     TCount,
          @vValidShipmentStatus TStatus;
begin /* pr_Shipment_ValidateToShip */
  select @ReturnCode   = 0,
         @MessageName  = null;

  /* To be sure, let us recalculate the shipment status once again */
  exec pr_Shipment_SetStatus @ShipmentId;

 /* Get Shipment Info here..*/
  select @vShipmentId      = ShipmentId, -- Unused
         @vShipmentStatus  = Status,
         @vBusinessUnit    = BusinessUnit,
         @vLPNsOnShipments = NumLPNs
  from Shipments
  where (ShipmentId = @ShipmentId);

  /* Get the validshipment status to validate..*/
  select @vValidShipmentStatus = dbo.fn_Controls_GetAsString('Shipping', 'ValidShipmentStatus', 'G' /* Staged */,  @vBusinessUnit, System_User);

  if ((charindex(@vShipmentStatus, @vValidShipmentStatus) = 0))
    set @MessageName = 'InvalidShipmentStatus';
  else
  if (@vLPNsOnShipments = 0)
    set @MessageName = 'NoLPNsOnShipment';

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipment_ValidateToShip */

Go
