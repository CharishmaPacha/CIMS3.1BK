/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/22  TK      pr_Allocation_GetOrderDetailsToAllocate: Changes to return new SKU, InventoryClass & SourceSystem (HA-834)
  2020/04/28  TK      pr_Allocation_GetAllocableLPNs, pr_Allocation_GetAllocationRules, pr_Allocation_PrepareAllocableLPNs &
                        pr_Allocation_GetOrderDetailsToAllocate & pr_Allocation_PrepareToAllocateInventory: Initial Revision
                      pr_Allocation_AllocateInventory: Code revamp - WIP Changes (HA-86)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GetOrderDetailsToAllocate') is not null
  drop Procedure pr_Allocation_GetOrderDetailsToAllocate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GetOrderDetailsToAllocate returns all order details to allocate
    for the given wave. If the wave has a Bulk Order, then we only allocate the
    Bulk Order and so it's details are returned, or else original orders' details
    are returned.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GetOrderDetailsToAllocate
  (@WaveId            TRecordId,
   @Operation         TOperation     = null, -- for future use
   @BusinessUnit      TBusinessUnit  = null,
   @UserId            TUserId        = null,
   @Debug             TFlags         = null,
   @AllocSKU          TSKU           = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Wave Info */


  /* Get all the Order Details to be allocated for a given wave
     If the wave has bulk order then allocations must be done against bulk order only
     If the wave doesn't have bulk order then allocations must be done for customer orders only */
  if exists(select * from OrderHeaders where PickBatchId = @WaveId and OrderType = 'B' /* BPT */) -- use fn_Wave_IsBulkWave
    insert into #OrderDetailsToAllocate (WaveId, WaveNo, OrderId, PickTicket, OrderType, OrderDetailId, HostOrderLine, UnitsAuthorizedToShip, UnitsToAllocate, UnitsPreAllocated,
                                         SKUId, SKU, SKUABCClass, DestZone, DestLocationId, DestLocation, Ownership, Lot, Account, SourceSystem,
                                         Warehouse, InventoryClass1, InventoryClass2, InventoryClass3,
                                         NewSKUId, NewSKU, NewInventoryClass1, NewInventoryClass2, NewInventoryClass3,
                                         UDF1, UDF2, UDF3, UDF4, UDF5)
      select WaveId, WaveNo, OrderId, PickTicket, OrderType, OrderDetailId, HostOrderLine, UnitsAuthorizedToShip, UnitsToAllocate, UnitsPreAllocated,
             SKUId, SKU, ABCClass, DestZone, DestLocationId, DestLocation, Ownership, Lot,  null /* Account */, SourceSystem,
             Warehouse, InventoryClass1, InventoryClass2, InventoryClass3,
             NewSKUId, NewSKU, NewInventoryClass1, NewInventoryClass2, NewInventoryClass3,
             ODUDF1, ODUDF2, ODUDF3, ODUDF4, ODUDF5 /* UDFs */
      from vwWaveDetailsToAllocate WD
      where (WaveId    = @WaveId) and
            (OrderType = 'B'/* Bulk */)
      order by SKUId, OrderId;
  else
    insert into #OrderDetailsToAllocate (WaveId, WaveNo, OrderId, PickTicket, OrderType, OrderDetailId, HostOrderLine, UnitsAuthorizedToShip, UnitsToAllocate, UnitsPreAllocated,
                                         SKUId, SKU, SKUABCClass, DestZone, DestLocationId, DestLocation, Ownership, Lot, Account, SourceSystem,
                                         Warehouse, InventoryClass1, InventoryClass2, InventoryClass3,
                                         NewSKUId, NewSKU, NewInventoryClass1, NewInventoryClass2, NewInventoryClass3,
                                         UDF1, UDF2, UDF3, UDF4, UDF5)
      select WaveId, WaveNo, OrderId, PickTicket, OrderType, OrderDetailId, HostOrderLine, UnitsAuthorizedToShip, UnitsToAllocate, UnitsPreAllocated,
             SKUId, SKU, ABCClass, DestZone, DestLocationId, DestLocation, Ownership, Lot, null /* Account */, SourceSystem,
             Warehouse, InventoryClass1, InventoryClass2, InventoryClass3,
             NewSKUId, NewSKU, NewInventoryClass1, NewInventoryClass2, NewInventoryClass3,
             ODUDF1, ODUDF2, ODUDF3, ODUDF4, ODUDF5 /* UDFs */
      from vwWaveDetailsToAllocate WD
      where (WaveId    = @WaveId) and
            (OrderType <> 'B' /* Bulk */)
      order by SKUId, OrderId;

  if (charindex('D' /* Display */, @Debug) > 0) and (@AllocSKU is not null) delete from #OrderDetailsToAllocate where SKU <> @AllocSKU;
  if (charindex('D' /* Display */, @Debug) > 0) select 'Allocate Inv: OrderDetailsToAllocate', * from #OrderDetailsToAllocate

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_GetOrderDetailsToAllocate */

Go
