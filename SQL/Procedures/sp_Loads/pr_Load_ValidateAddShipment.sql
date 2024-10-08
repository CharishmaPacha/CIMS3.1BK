/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_ValidateAddShipment') is not null
  drop Procedure pr_Load_ValidateAddShipment;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_ValidateAddShipment:
     Validate whether a given Shipment can be added to a given Load. The basic
     validations are the Load Type, Load Status, Shipment Type, Shipment Status,
     Ship Via, Ship To, Sold To, Carrier.

------------------------------------------------------------------------------*/
Create Procedure pr_Load_ValidateAddShipment
  (@LoadId       TLoadId,
   @ShipmentId   TLoadId)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          /* Shipment info */
          @vShipVia         TShipVia,
          @vShipTo          TShipToId,
          @vShipmentType    TTypeCode,
          @vShipmentStatus  TStatus,
          @vSoldTo          TCustomerId,
          /* Load Info */
          @vLoadType        TTypeCode,
          @vLoadStatus      TStatus,
          @vShipViaOnLoad   TShipVia,
           /* Carrier Info */
          @vCarrier         TCarrier;
begin /* pr_Load_ValidateAddShipment */
  select @ReturnCode   = 0,
         @Messagename = null;

    /* TODO LATER
       TODO LATER
       TODO LATER
         Load Type - Read Load Type, Ensure that Shipment can be based on Load Type
                   Example - if Load Type is Single drop, then the Load should be empty
                           OR the Shipment should be for the Same ShipTo as the existing ones
         Load Status - Load is in Inprogress Status
         Shipment Type - For Future
         Shipment Status - Shipment should be in Inprogress  status
         Ship Via - Ship Via should match for both Shipment and Load
         Ship To  - ???
         Sold To  - ???
         Carrier  - ShipVia on Shipment should match with the Carrier of the Load's ShipVia
                    This validation is most likely with Small Package Loads where the different
                    ShipVias for a Same Carrier are put on the Same Load
    */

   /*select @vShipVia = ShipVia,
          @vShipTo = ShipTo,
          @vSoldTo = SoldTo,
          @vShipmentType = ShipmentType,
          @vShipmentStatus = Status
   from Shipments
   where (ShipmentId = @ShipmentId);

   select @vLoadType      = LoadType,
          @vLoadStatus    = Status,
          @vShipViaOnLoad = ShipVia
   from Loads
   where (LoadId = @LoadId);

   select @vCarrier = Carrier
   from ShipVias
   where (ShipVia = @vShipVia); */

  if (@MessageName is not null)
    goto ErrorHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_ValidateAddShipment */

Go
