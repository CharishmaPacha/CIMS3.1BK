/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_FindShipmentForOrder') is not null
  drop Procedure pr_Load_FindShipmentForOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_FindShipmentForOrder: For the given Order, this procedure looks
    to find if there are any shipments on the specified Load that the Order
    can be added to instead of creating a new shipment. The criteria used are
    SoldTo, ShipTo & Carrier
------------------------------------------------------------------------------*/
Create Procedure pr_Load_FindShipmentForOrder
  (@LoadId     TLoadId,
   @OrderId    TRecordId,
   -------------------------------
   @ShipmentId TShipmentId output)
as
  declare @ReturnCode             TInteger,
          @MessageName            TMessageName,
          /* Order info */
          @vShipVia               TShipVia,
          @vShipToId              TShipToId,
          @vSoldToId              TCustomerId,
          @vOrderDesiredShipDate  TDateTime,
          @vOrderStatus           TStatus,
          /* Load Info */
          @vShipViaOnLoad         TShipVia,
          @vLoadDesiredShipDate   TDateTime,
          @vLoadRoutingStatus     TStatus,
          @vLoadType              TTypeCode,
          @vLoadStatus            TStatus,
          /* Shipment Info */
          @vShipmentStatus        TStatus,
           /* Carrier Info */
          @vCarrier               TCarrier;
begin /* pr_Load_FindShipmentForOrder */
  select @ReturnCode  = 0,
         @Messagename = null,
         @ShipmentId  = null;

  /* Get Order Info */
  select @vShipVia              = ShipVia,
         @vOrderStatus          = Status,
         @vOrderDesiredShipDate = DesiredShipDate,
         @vShipToId             = ShipToId,
         @vSoldToId             = SoldToId
  from OrderHeaders
  where (OrderId = @OrderId);

  select @vCarrier = Carrier
  from ShipVias
  where (ShipVia = @vShipVia);

  /* Check if there is already a Shipment on the Load for same ShipTo and Carrier */
  select @ShipmentId      = ShipmentId,
         @vShipmentStatus = Status
  from Shipments
  where (LoadId     = @LoadId   ) and
        (ShipTo     = @vShipToId) and
        (Status     <> 'S' /* Shipped */) and
        ((@vCarrier = 'Generic' ) or (ShipVia = @vShipVia));

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_FindShipmentForOrder */

Go
