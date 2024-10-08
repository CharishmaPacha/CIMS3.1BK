/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/17  VM      Build-fix: fn_PickBatches_GetOrderDetailsToAllocate: Temp table to return data has to match TOrderDetailsToAllocateTable
  2019/08/20  TK      fn_PickBatches_GetOrderDetailsToAllocate: Allocate bulk order for 'AllocateAvailableQtyToBulk' operation (S2GCA-906)
  fn_PickBatches_GetOrderDetailsToAllocate: Return Warehouse as well.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_PickBatches_GetOrderDetailsToAllocate') is not null
  drop Function fn_PickBatches_GetOrderDetailsToAllocate;
Go
/*------------------------------------------------------------------------------
  Proc fn_PickBatches_GetOrderDetailsToAllocate:
    This function returns all order details to allocate for the given wave.
------------------------------------------------------------------------------*/
Create Function fn_PickBatches_GetOrderDetailsToAllocate
  (@PickBatchId    TRecordId,
   @PickBatchType  TTypeCode,
   @OrderType      TTypeCode,
   @Operation      TOperation)
returns
  /* Temp table to return data has to match TOrderDetailsToAllocateTable as all
     callers insert into table variable of this type */
  @OrderDetailsToAllocate  table
    (WaveId               TRecordId,
     WaveNo               TWaveNo,

     OrderId              TRecordId,
     PickTicket           TPickTicket,
     OrderType            TTypeCode,
     OrderDetailId        TRecordId,
     HostOrderLine        THostOrderLine,

     UnitsAuthorizedToShip TQuantity,
     UnitsToAllocate       TQuantity,
     UnitsPreAllocated     TQuantity,

     SKUId                TRecordId,
     SKU                  TSKU,
     SKUABCClass          TFlag,
     NewSKUId             TRecordId,
     NewSKU               TSKU,

     DestZone             TZoneId,
     DestLocationId       TRecordId,
     DestLocation         TLocation,

     Ownership            TOwnership,
     Lot                  TLot,
     Account              TAccount,
     Warehouse            TWarehouse,
     SourceSystem         TName,

     InventoryClass1      TInventoryClass,
     InventoryClass2      TInventoryClass,
     InventoryClass3      TInventoryClass,
     NewInventoryClass1   TInventoryClass,
     NewInventoryClass2   TInventoryClass,
     NewInventoryClass3   TInventoryClass,

     CasesToReserve       TInnerPacks,
     UnitsToReserve       TQuantity,
     ReserveUoM           TDescription,

     ProcessFlag          TFlags,

     UDF1                 TUDF,
     UDF2                 TUDF,
     UDF3                 TUDF,
     UDF4                 TUDF,
     UDF5                 TUDF)
as
begin
  /* Set OrderType to allocate here -ie for which orders we need to allocate inventory */
  select @OrderType = case when @Ordertype is not null                    then @OrderType
                           when @Operation in ('BPTAllocation', 'AllocateAvailableQtyForBulk', 'AllocateDirectedQtyForBulk')
                                                                          then 'B' /* Bulk Pick Ticket */
                           when @Operation = 'Replenish'                  then 'R' /* Replenish */
                           else null
                      end;

  /* Get all OrderDetails to Allocate
     For the non-bulk PickTicket, we will allocate case picks only.
     For bulk PickTickets, we need to allocate all */
  if (@OrderType = 'R' /* Replenish */)
    begin
      insert into @OrderDetailsToAllocate (WaveId, WaveNo, OrderId, OrderType, OrderDetailId, HostOrderLine, UnitsToAllocate,
                                           SKUId, SKU, SKUABCClass, DestZone, Ownership, Lot, Account, Warehouse,
                                           InventoryClass1, InventoryClass2, InventoryClass3,
                                           UDF1, UDF2, UDF3, UDF4, UDF5)
        select distinct PB.PickBatchId, PB.PickBatchNo, PB.OrderId, PB.OrderType, PB.OrderDetailId, PB.HostOrderLine, PB.UnitsToAllocate,
                        PB.SKUId, PB.SKU, PB.ABCClass, PB.DestZone,
                        PB.Ownership, PB.Lot,  null /* Account */, Warehouse,
                        PB.InventoryClass1, PB.InventoryClass2, PB.InventoryClass3,
                        ODUDF1, ODUDF2, ODUDF3, ODUDF4, ODUDF5 /* UDFs */
        from vwPickBatchDetailsToAllocate PB
             join LPNs L on (L.LPNType = 'L' /* picklane */) and
                            (L.SKUId   = PB.SKUId)
        where (PB.PickBatchId  = @PickBatchId) and
              (L.Location is not null)
        order by PB.SKUId, PB.OrderId;
    end
  else
  if (@OrderType = 'B' /* BPT */)
    insert into @OrderDetailsToAllocate (WaveId, WaveNo, OrderId, OrderType, OrderDetailId, HostOrderLine, UnitsToAllocate,
                                         SKUId, SKU, SKUABCClass, DestZone, Ownership, Lot, Account, Warehouse,
                                         InventoryClass1, InventoryClass2, InventoryClass3,
                                         UDF1, UDF2, UDF3, UDF4, UDF5)
      select PB.PickBatchId, PB.PickBatchNo, PB.OrderId, PB.OrderType, PB.OrderDetailId, PB.HostOrderLine,PB.UnitsToAllocate,
             PB.SKUId, PB.SKU, PB.ABCClass, PB.DestZone,
             PB.Ownership, PB.Lot,  null /* Account */, Warehouse,
             InventoryClass1, InventoryClass2, InventoryClass3,
             ODUDF1, ODUDF2, ODUDF3, ODUDF4, ODUDF5 /* UDFs */
      from vwPickBatchDetailsToAllocate PB
      where (PickBatchId  = @PickBatchId) and
            (OrderType    = @OrderType)
      order by PB.SKUId, PB.OrderId;
  else
    insert into @OrderDetailsToAllocate (WaveId, WaveNo, OrderId, OrderType, OrderDetailId, HostOrderLine, UnitsToAllocate,
                                         SKUId, SKU, SKUABCClass, DestZone, Ownership, Lot, Account, Warehouse,
                                         InventoryClass1, InventoryClass2, InventoryClass3,
                                         UDF1, UDF2, UDF3, UDF4, UDF5)
      select PB.PickBatchId, PB.PickBatchNo, PB.OrderId, PB.OrderType, PB.OrderDetailId, PB.HostOrderLine,PB.UnitsToAllocate,
             PB.SKUId, PB.SKU, PB.ABCClass, PB.DestZone,
             PB.Ownership, PB.Lot, null /* Account */, Warehouse,
             InventoryClass1, InventoryClass2, InventoryClass3,
             ODUDF1, ODUDF2, ODUDF3, ODUDF4, ODUDF5 /* UDFs */
      from vwPickBatchDetailsToAllocate PB
      where (PickBatchId  = @PickBatchId) and
            (OrderType    <> 'B' /* BPT */)
      order by SKUId, OrderId;
  return;
end /* fn_PickBatches_GetOrderDetailsToAllocate */

Go
