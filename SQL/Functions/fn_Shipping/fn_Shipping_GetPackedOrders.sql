/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/07/23  AA      fn_Shipping_GetPackedOrders: Modified to return OrderId associated with LPN
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Shipping_GetPackedOrders') is not null
  drop Function fn_Shipping_GetPackedOrders;
Go
/*------------------------------------------------------------------------------
  fn_Shipping_GetPackedOrders
------------------------------------------------------------------------------*/
Create Function fn_Shipping_GetPackedOrders
  (@LPN TLPN)
returns
  @Orders table
    (OrderId            TRecordId)

as
begin
  declare @vPickBatchNo TPickBatchNo,
          @vShipToId    TShipToId,
          @vShipVia     TShipVia,
          @vOrderId     TRecordId;

  insert into @Orders (OrderId)
    select OrderId
    from LPNs
    where (LPN = @LPN);

  return

  --- Fechheimer scenario

  select @vPickBatchNo = PickBatchNo,
         @vShipToId   = ShipToId,
         @vShipVia    = ShipVia
  from OrderHeaders
  where OrderId = @vOrderId

  -- Add the T-SQL statements to compute the return value here
  insert into @Orders (OrderId)
    select OrderId
    from OrderHeaders
    where (PickBatchNo  = @vPickBatchNo) and
          (ShipToId     = @vShipToId   ) and
          (ShipVia      = @vShipVia    ) and
          (OrderType  not in ('B', 'R')) and -- Bulk/Replenishments
          (Status       = 'S' /* shipped */)
  return
end  /* fn_Shipping_GetPackedOrders */

Go
