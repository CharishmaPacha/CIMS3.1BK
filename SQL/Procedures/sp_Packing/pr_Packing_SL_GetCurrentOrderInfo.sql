/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_SL_GetCurrentOrderInfo') is not null
  drop Procedure pr_Packing_SL_GetCurrentOrderInfo;
Go
/*------------------------------------------------------------------------------
  pr_Packing_SL_GetCurrentOrderInfo: This procedure returns all the information
    relevant to the current order that needs to be displayed in UI packing screen.
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_SL_GetCurrentOrderInfo
  (@WaveNo       TPickBatchNo = null,
   @OrderId      TRecordId    = null,
   @SKUId        TRecordId    = null,
   @xmlResult    TXML = null output)
as
  declare @vReturnCode         TInteger,
          @xmlODToPack         TXML,

          @vPickTicket         TPickTicket,
          @vDisplayPickTicket  TDescription,
          @vSKU                TSKU,
          @vUnitsToShip        TQuantity,
          @vUnitsToAllocate    TQuantity,
          @vUnitsAssigned      TQuantity,
          @vShipToId           TShipToId,
          @vShipVia            TShipVia,
          @vShipViaDesc        TDescription,
          @vDisplayShipVia     TDescription,
          @ShipToId            TShipToId,

          @vShipToName         TName,
          @vShipToAddressLine1 TDescription,
          @vShipToAddressLine2 TDescription,
          @vShipToCity         TDescription,
          @vShipToState        TDescription,
          @vShipToZip          TDescription,
          @vShipToCityStateZip TDescription,
          @vMessageName        TMessage;
begin
  select @vMessageName = null;

  if (@OrderId is null) and (@WaveNo is null)
    return;

  /* get order info here. This is a single line order and so there will be only one SKU */
  select @vPickTicket      = min(PickTicket),
         @vSKU             = min(SKU),
         @vUnitsToShip     = sum(UnitsAuthorizedToShip),
         @vUnitsToAllocate = sum(UnitsToAllocate),
         @vUnitsAssigned   = sum(UnitsAssigned),
         @vShipVia         = min(ShipVia),
         @vShipToId        = min(ShipToId)
  from vwOrderDetails
  where (OrderId = @OrderId);
--        (PickBatchNo  = coalesce(@WaveNo, PickBatchNo)) and
--        (SKUId = coalesce(@SKUId, SKUId))
--        --(UnitsToAllocate > 0) and
--        (OrderType not in ('B', 'RU', 'RP'))
--  group by PickTicket, SKU

  select  @vShipToName         = Name,
          @vShipToAddressLine1 = AddressLine1,
          @vShipToAddressLine2 = AddressLine2,
          @vShipToCity         = City,
          @vShipToState        = State,
          @vShipToZip          = Zip,
          @vShipToCityStateZip = CityStateZip
  from fn_Contacts_GetShipToAddress(@OrderId, @vShipToId);

  /* Get shipvia description */
  select @vShipViaDesc = Description
  from ShipVias
  where (ShipVia = @vShipVia);

  /* build xml here to display PickTicket based on the packed units
     if the order is completely packed then we need to show this order is completed
     or need to show packing order ...*/
  select @vDisplayPickTicket = case
                                 when @vUnitsToAllocate > 0 then
                                   'Packing Order ' + @vPickTicket
                                 when @vUnitsToAllocate = 0 then
                                   'Order ' + @vPickTicket + ' completed'
                               end,
         @vDisplayShipVia    = @vShipVia + '/' + @vShipViaDesc;

  /* if user partailly packed the order and then we need to send the
     partially packed info with remaining qty to pack...
     We do not need to show replenishments and BPT  */
  select @xmlResult = (select @vDisplayPickTicket  as PickTicket, -- $$$ deceptive, should send as DisplayPickTicket to UI
                              @vSKU                as SKU,
                              @vUnitsToShip        as NumUnits,
                              @vUnitsAssigned      as NumUnitsPacked,
                              @vUnitsToAllocate    as UnitsToPack,
                              @vDisplayShipVia     as ShipVia,    -- $$$ should be DisplayShipVia
                              @vShipToName         as ShipToName,
                              @vShipToAddressLine1 as ShipToAddressLine1,
                              @vShipToAddressLine2 as ShipToAddressLine2,
                              @vShipToCityStateZip as ShipToCityStateZip
                       for xml raw('OrderDisplayInfo'), elements XSINIL)

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_SL_GetCurrentOrderInfo */

Go
