/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/27  SK      fn_Reservation_GetWaveInventoryInfo, pr_Reservation_GetOrderDetailsToReserve,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_GetOrderDetailsToReserve') is not null
  drop Procedure pr_Reservation_GetOrderDetailsToReserve;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_GetOrderDetailsToReserve returns all order details to be reserved for
    for the given wave or pick ticket

  When reserving inventory for wave system would just update wave info on the LPN and marks the LPN
  as reserved since the LPN is not hard allocated to any order we need to deducted the inventroy that is
  reserved for the the wave.
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_GetOrderDetailsToReserve
  (@EntityToReserve   TEntity,
   @WaveId            TRecordId,
   @OrderId           TRecordId,
   @BusinessUnit      TBusinessUnit  = null,
   @UserId            TUserId        = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName;

  declare @ttOrderDetails     TOrderDetails;

  declare @ttWaveInvInfo table (RecordId                TRecordId Identity(1,1),
                                WaveId                  TRecordId,
                                WaveNo                  TWaveNo,
                                SKUId                   TRecordId,
                                SKU                     TSKU,
                                InventoryClass1         TInventoryClass,
                                InventoryClass2         TInventoryClass,
                                InventoryClass3         TInventoryClass,

                                IPsToReserve            TInnerPacks,
                                QtyToReserve            TInteger,
                                QtyOrdered              TInteger,
                                QtyReserved             TInteger,

                                Ownership               TOwnership,
                                Warehouse               TWarehouse,
                                BusinessUnit            TBusinessUnit)
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Delete if there are any existing records from hash tables */
  delete from #OrderDetails;
  delete from #DataTableSKUDetails;

  /* Get the order details to be reserved based on the Wave or PickTicket given with only the SKU(s) we have in FromLPN */
  if (@EntityToReserve = 'Wave')
    begin
      /* Get the required wave inventory join with LPN details of the LPN that is being reserved */
      insert into @ttWaveInvInfo
        (WaveId, WaveNo, SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
         IPsToReserve, QtyToReserve, QtyOrdered, QtyReserved, Ownership, Warehouse, BusinessUnit)
        select WI.WaveId, WI.WaveNo, WI.SKUId, WI.SKU, WI.InventoryClass1, WI.InventoryClass2, WI.InventoryClass3,
               WI.IPsToReserve, WI.QtyToReserve, WI.QtyOrdered, WI.QtyReserved, WI.Ownership, WI.Warehouse, WI.BusinessUnit
        from  dbo.fn_Reservation_GetWaveInventoryInfo(@WaveId, null, null, null, null) WI;

      /* WaveInvInfo has counts summarized by SKU, insert them into order details to process further */
      insert into #OrderDetails (WaveId, WaveNo, SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
                                 UnitsToAllocate, UnitsToShip, UnitsAssigned, Ownership, Warehouse, BusinessUnit)
        select WaveId, WaveNo, SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
               QtyToReserve, QtyOrdered, QtyReserved, Ownership, Warehouse, BusinessUnit
        from @ttWaveInvInfo;
    end
  else
  if (@EntityToReserve = 'PickTicket')
    insert into #OrderDetails
      (WaveId, WaveNo, PickTicket, OrderId, OrderDetailId, SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
       UnitsToShip, UnitsToAllocate, UnitsAssigned, UnitsPerCarton, Ownership, Warehouse, BusinessUnit)
      select WaveId, WaveNo, PickTicket, OrderId, OrderDetailId, SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
             UnitsAuthorizedToShip, UnitsToAllocate, UnitsAssigned, UnitsPerCarton, Ownership, Warehouse, BusinessUnit
      from vwWaveDetailsToAllocate WD
      where (OrderId = @OrderId)
      order by SKUId, OrderId;

  /* Get the Ordered quantities summarized by SKU & other required criteria */
  insert into #DataTableSKUDetails
    (SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, Quantity, Quantity1, Quantity2, Ownership, Warehouse, BusinessUnit)
    select SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
           sum(UnitsToShip), sum(UnitsAssigned), sum(UnitsToAllocate), Ownership, Warehouse, BusinessUnit
    from #OrderDetails
    group by SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse, BusinessUnit;

  /* Update Required information on SKUs */
  update DTSD
  set DisplaySKU     = S.DisplaySKU,
      DisplaySKUDesc = S.DisplaySKUDesc,
      SortOrder      = coalesce(S.SKUSortOrder, '') + S.SKU
  from #DataTableSKUDetails DTSD join SKUs S on DTSD.SKUId = S.SKUId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_GetOrderDetailsToReserve */

Go
