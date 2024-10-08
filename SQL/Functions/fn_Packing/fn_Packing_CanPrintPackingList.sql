/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/08/06  AY      fn_Packing_CanPrintPackingList: Revised to suppress
                        Packing list for Bulk/Replenish PTs.
  2012/07/23  AA      fn_Packing_CanPrintPackingList: Handle do not print
                        packing list for LPNs not associated with Order &
                        Bulk/Replenish Orders
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Packing_CanPrintPackingList') is not null
  drop Function fn_Packing_CanPrintPackingList;
Go
/*------------------------------------------------------------------------------
  fn_Packing_CanPrintPackingList
  Function return Packing List should need to be print or not based on given LPN
------------------------------------------------------------------------------*/
Create Function fn_Packing_CanPrintPackingList
  (@LPNId           TRecordId,
   @OrderId         TRecordId  = null,
   @PackingListType TTypeCode  = null)
  returns TBoolean
as
begin
  declare @vCanPrintPackingList  TBoolean,
          @vOrderId              TRecordId,
          @vPickBatchNo          TPickBatchNo,
          @vShipToId             TShipToId,
          @vShipVia              TShipVia,
          @vPallet               TPallet,
          @vOrderType            TTypeCode;

  select @vOrderId             = @OrderId,
         @vCanPrintPackingList = 1 /* Default to be Yes */;

  /* In TopsonDowns Can Print Packing List always true */
  if (@LPNId is not null) and (@vOrderId is null)
    select @vOrderId = OrderId
    from LPNs
    where (LPNId = @LPNId);


  /* Do not print Packing lists for Bulk/Replenish Orders */
  select @vOrderType = OrderType
  from OrderHeaders
  where (OrderId = @vOrderId);

  if (@vOrderId is null) or
     (@vOrderType in ('B' /* Bulk */, 'R' /* Replenish */))
    select @vCanPrintPackingList = 0;

  return (@vCanPrintPackingList);

  --- Fechheimer scenario
  select @vOrderId = OrderId
  from vwLPNDetails
  where LPNId = @LPNId

  select @vPickBatchNo = PickBatchNo,
         @vShipToId   = ShipToId,
         @vShipVia    = ShipVia
  from OrderHeaders
  where OrderId = @vOrderId

  select @vPallet = Pallet
  from PickBatches
  where BatchNo = @vPickBatchNo

  declare @Orders table
    (OrderId   TRecordId)

  insert into @Orders (OrderId)
    select * from dbo.fn_Packing_GetOrders(@vOrderId)

  /* If there is inventory to be packed on the cart for the group of orders being
     packed, then we should not print the packing list, else we print the packing
     list as this is the last LPN to be packed */
  if exists(select *
            from LPNs L
              inner join LPNDetails LD on (L.LPNId    = LD.LPNId )
              inner join @Orders O     on (LD.OrderId = O.OrderId)
            where L.Pallet = @vPallet and LD.Quantity > 0)
    select @vCanPrintPackingList = 0
  else
    select @vCanPrintPackingList = 1

-- return the result of the function
  return @vCanPrintPackingList
end /* fn_Packing_CanPrintPackingList */

Go
