/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/05  OK      pr_Packing_GetOrderInfo: Bugfix to exclude Totes to consider packed quantities (BK-428)
  2016/04/28  OK      pr_Packing_GetOrderInfo: Enhanced to return the ShipTo Address
  2015/03/03  DK      pr_Packing_GetOrderInfo: Introduced condition to validate BulkPullOrder.
  2015/03/03  DK      pr_Packing_GetOrderInfo: Fix to continue if Right values are null.
  2013/08/28  AY      pr_Packing_GetOrderInfo: Show Customer Name as well
  2013/08/03  PKS     pr_Packing_GetOrderInfo: Consider all LPNs/Units beyond packing as well for PackedLPNs, PackedUnits
  2013/07/26  PKS     Added pr_Packing_GetOrderInfo.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetOrderInfo') is not null
  drop Procedure pr_Packing_GetOrderInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_GetOrderInfo: This Procedure will return the information of the
    Order during Packing. This procedure will return the following information
    from the order.

    1. Total number of units in the Order.
    2. Total number of units packed
    3. Total number of units has to be packed (remaining units).
    4. Order's Ship Via
------------------------------------------------------------------------------*/
Go
Create Procedure pr_Packing_GetOrderInfo
  (@OrderId       TRecordId,
  -----------------------------------
  @LeftTitle      TDescription output,
  @CenterTitle    TDescription output,
  @RightTitle     TDescription output,
  @ShipToAddress  varchar(max) output,
  @UnitsToShip    TQuantity    output,
  @UnitsRemaining TQuantity    output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,

          @vPickTicket         TPickTicket,
          @vShipVia            TShipVia,
          @vShipViaDescription TDescription,
          @vCustomerName       TName,
          @vPickedPallets      TCount,
          @vPickedLPNs         TCount,
          @vPickedUnits        TCount,
          @vPackedLPNs         TCount,
          @vPackedUnits        TCount,
          @vShipToname         TName,
          @vShipToAddressLine1 TAddressLine,
          @vShipToCityStateZip TDescription,

          @vUnitsPacked TQuantity;
begin/* pr_Packing_GetOrderInfo */

  /* Right: To Pack: %1 Carts, %2 Units, Packed: %3 Cartons (%4 units) */
  select @LeftTitle   = dbo.fn_Messages_Build('Packing_LeftTitle',null,null,null,null,null),
         @CenterTitle = dbo.fn_Messages_Build('Packing_CenterTitle',null,null,null,null,null),
         @RightTitle  = dbo.fn_Messages_Build('Packing_RightTitle',null,null,null,null,null);

  select @vPickTicket         = PickTicket,
         @vShipVia            = ShipVia,
         @vCustomerName       = CustomerName,
         @vShipToname         = ShipToName,
         @vShipToAddressLine1 = ShipToAddressLine1,
         @vShipToCityStateZip = ShipToCityStateZip
  from vwOrderHeaders
  where (OrderId = @OrderId);

  /* Get the ShipVia description */
  select @vShipViaDescription = Description
  from ShipVias
  where (ShipVia = @vShipVia);

  select @UnitsToShip = sum(UnitsAuthorizedToShip)
  from OrderDetails
  where (OrderId = @OrderId);

  /* Temporarily making it not very generic */
  select @LeftTitle   = replace(@LeftTitle,   '<PickTicket>', @vPickTicket),
         @CenterTitle = replace(@CenterTitle, '<ShipVia>',    @vShipVia),
         @CenterTitle = replace(@CenterTitle, '<ShipViaDescription>', @vShipViaDescription),
         @ShipToAddress = '<tr><td>Ship To</td></tr><tr><td><h2>'+@vShipToname+ '</h2></td></tr><tr><td><h3>'+@vShipToAddressLine1+ '</br>' +@vShipToCityStateZip +'</h3></td></tr>';

  /* Get info of LPNs */
  select @vPickedPallets = count(distinct PalletId)
  from LPNs
  where (OrderId = @OrderId) and (LPNType = 'A' /* Cart */);

  select @vPickedLPNs    = sum(case when charindex(Status, 'K' /* Picked */) > 0 then 1 else 0 end),
         @vPickedUnits   = sum(Quantity),
         @vPackedLPNs    = sum(case when charindex(Status, 'GDES' /* Packing, Packed, Staged, Shipped */) > 0 and (LPNType not in ('A', 'TO' /* Cart, Tote */)) then 1 else 0 end),
         @vPackedUnits   = sum(case when charindex(Status, 'GDES' /* Packing, Packed, Staged, Shipped */) > 0 and (LPNType not in ('A', 'TO' /* Cart, Tote */)) then Quantity else 0 end)
  from LPNs
  where (OrderId = @OrderId);

 select @RightTitle = replace(@RightTitle, '<PickedPallets>',  coalesce(@vPickedPallets, 0)),
        @RightTitle = replace(@RightTitle, '<PickedLPNs>',     coalesce(@vPickedLPNs,    0)),
        @RightTitle = replace(@RightTitle, '<PickedUnits>',    coalesce(@vPickedUnits,   0)),
        @RightTitle = replace(@RightTitle, '<PackedLPNs>',     coalesce(@vPackedLPNs,    0)),
        @RightTitle = replace(@RightTitle, '<PackedUnits>',    coalesce(@vPackedUnits,   0));

  if (dbo.fn_OrderHeaders_IsBulkPullOrder(@OrderId) > 0)
    begin
      select @UnitsRemaining = sum(UnitsToAllocate)
      from OrderDetails
      where (OrderId = @OrderId);
    end
  else
    begin
      select @UnitsRemaining = @vPickedUnits - @vPackedUnits;
    end

end /* pr_Packing_GetOrderInfo */

Go
