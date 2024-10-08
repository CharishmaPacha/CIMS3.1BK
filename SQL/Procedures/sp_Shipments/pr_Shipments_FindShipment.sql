/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/10/11  PK      Added pr_Shipments_FindShipment.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipments_FindShipment') is not null
  drop Procedure pr_Shipments_FindShipment;
Go
/*------------------------------------------------------------------------------
  Proc :This Procedure pr_Shipments_FindShipment.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipments_FindShipment
  (@LoadId            TRecordId,
   @ShipToId          TShipToId,
   @OrderId           TRecordId,
   @BusinessUnit      TBusinessUnit,
   @ShipmentId        TShipmentId output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,

          /* Shipment Related*/
          @vShipToId           TShipToId,
          @vShipmentId         TShipmentId;

begin /* pr_Shipments_FindShipment */
  select @ReturnCode        = 0,
         @MessageName       = null,
         @ShipmentId        = 0;

  /* Check if there is a shipment associated for the given ShipTo on the Load */
  select @vShipmentId = ShipmentId,
         @vShipToId   = ShipTo
  from Shipments
  where (LoadId   = @LoadId) and
        (ShipTo   = @ShipToId) and
        (Status   not in ('X', 'S'/* Canceled, Shipped */)) and
        (BusinessUnit = @BusinessUnit);

  /* Create a new Shipment if there is no shipment */
  if (@vShipmentId is null)
    exec pr_Shipment_CreateNew @OrderId, @LoadId, 'N'/* Auto Assign LPNs */, null /* @UserId */, @vShipmentId output;
  else
  /* If order is not already on the Shipment, add it to the shipment */
  if (@vShipmentId is not null) and
     (@OrderId is not null) and
     (not exists(select * from vwOrderShipments
                 where (LoadId     = @LoadId) and
                       (ShipmentId = @vShipmentId) and
                       (OrderId    = @OrderId)))
    exec pr_Shipment_AddOrder @OrderId, @vShipmentId, 'N' /* AutoAssignLPNs */, @BusinessUnit, null /* @UserId */;

  /* Update the output param */
  select @ShipmentId = @vShipmentId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipments_FindShipment */

Go
