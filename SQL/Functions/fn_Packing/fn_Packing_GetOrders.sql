/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Packing_GetOrders') is not null
  drop Function fn_Packing_GetOrders;
Go
/*------------------------------------------------------------------------------
  fn_Packing_GetOrders
  Function to return the associated orders in the group of this order. In general
  this is all orders in the same PickBatch, ShipTo and ShipVia
------------------------------------------------------------------------------*/
Create Function fn_Packing_GetOrders
  (@OrderId TRecordId)
returns
  /* temp table to return data */
  @Orders table (OrderId            TRecordId)

as
begin
  declare @vPickBatchNo TPickBatchNo,
          @vShipToId    TShipToId,
          @vShipVia     TShipVia;

  select @vPickBatchNo = PickBatchNo,
         @vShipToId    = ShipToId,
         @vShipVia     = ShipVia
  from OrderHeaders
  where (OrderId = @OrderId);

  -- Add the T-SQL statements to compute the return value here
  insert into @Orders (OrderId)
    select OrderId
    from OrderHeaders
    where (PickBatchNo  = @vPickBatchNo) and
          (ShipToId     = @vShipToId   ) and
          (ShipVia      = @vShipVia    )
  return
end /* fn_Packing_GetOrders */

Go
