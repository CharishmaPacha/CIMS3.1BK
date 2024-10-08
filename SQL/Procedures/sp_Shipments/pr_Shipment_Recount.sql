/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_Recount') is not null
  drop Procedure pr_Shipment_Recount;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipment_Recount:
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_Recount
  (@ShipmentId  TShipmentId)
as
  declare @ReturnCode    TInteger,
          @MessageName   TMessageName,
          @Message       TDescription,

          @vTotalOrders   TCount,
          @vTotalPallets  TCount,
          @vTotalLPNs     TCount,
          @vTotalPackages TCount,
          @vTotalUnits    TCount,
          @vOrderId       TRecordId;
begin  /* pr_Shipment_Recount */
  SET NOCOUNT ON;

  select @ReturnCode     = 0,
         @MessageName    = null,
         @vTotalOrders   = 0,
         @vTotalPallets  = 0,
         @vTotalLPNs     = 0,
         @vTotalPackages = 0,
         @vTotalUnits    = 0;

  select @vTotalOrders   = count(*)
  from OrderShipments
  where (ShipmentId = @ShipmentId);

  /* Get the Counts from LPNs */
  select @vTotalPallets  = count(distinct PalletId),
         @vTotalLPNs     = count(LPNId),
         @vTotalPackages = coalesce(sum(InnerPacks), 0),
         @vTotalUnits    = coalesce(sum(Quantity), 0)
  from LPNs
  where (ShipmentId = @ShipmentId);

  /* Update Shipment with latest counts */
  update Shipments
  set NumOrders   = @vTotalOrders,
      NumPallets  = @vTotalPallets,
      NumLPNs     = @vTotalLPNs,
      NumPackages = @vTotalPackages,
      NumUnits    = @vTotalUnits
  where (ShipmentId = @ShipmentId);

  /* Update Shipment Status */
  exec @ReturnCode = pr_Shipment_SetStatus @ShipmentId;

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipment_Recount */

Go
