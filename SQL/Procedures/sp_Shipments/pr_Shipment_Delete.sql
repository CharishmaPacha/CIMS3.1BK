/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/01/21  PKS     pr_Shipment_Delete: Deleted OrderShipment when its corresponding
                      pr_Shipment_Delete: Added to delete Orphan shipments.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_Delete') is not null
  drop Procedure pr_Shipment_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipment_Delete: Deletes a shipment and it's association with PT.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_Delete
  (@ShipmentId     TLoadId,
   @Criteria       TFlags = null, /* Future use */
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,

          /* LoadInfo on the Shipments */
          @vShipmentId         TShipmentId,
          @vShipmentLoadId     TLoadId,
          @vShipmentLPNs       TCount;

begin /* pr_Shipment_Delete */
  select @ReturnCode     = 0,
         @Messagename    = null;

  if (@ShipmentId is null)
    set @MessageName = 'ShipmentIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  exec pr_Shipment_Recount @ShipmentId;

  /* Get the recounted info for the shipment */
  select @vShipmentId     = ShipmentId,
         @vShipmentLoadId = LoadId,
         @vShipmentLPNs   = NumLPNs
  from Shipments
  where (ShipmentId = @ShipmentId);

  /* Delete the shipment and its OrderShipments if it is not associated with a Load and if there are no
     LPNs on it */
  if (coalesce(@vShipmentLoadId, 0) = 0) and
     (@vShipmentLPNs = 0)
    begin
      delete from OrderShipments
      where (ShipmentId = @vShipmentId);

      delete from Shipments
      where (ShipmentId = @vShipmentId);
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipment_Delete */

Go
