/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/27  SK      fn_Reservation_GetWaveInventoryInfo, pr_Reservation_GetOrderDetailsToReserve,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Reservation_GetWaveInventoryInfo') is not null
  drop Function fn_Reservation_GetWaveInventoryInfo;
Go
/*------------------------------------------------------------------------------
  Proc fn_Reservation_GetWaveInventoryInfo:  This function will return the inventory
    summary for all the SKUs of a given Wave or for particular SKU if provided
------------------------------------------------------------------------------*/
Create Function fn_Reservation_GetWaveInventoryInfo
  (@WaveId            TRecordId,
   @SKUId             TRecordId       = null,
   @InventoryClass1   TInventoryClass = null,
   @InventoryClass2   TInventoryClass = null,
   @InventoryClass3   TInventoryClass = null)
returns
/* temp table  to return data */
  @WaveInventoryInfo       table
    (RecordId                TRecordId Identity(1,1),
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
as
begin /* fn_Reservation_GetWaveInventoryInfo */
  declare @ttWaveCounts      TLPNDetails,
          @ttLPNCounts       TLPNDetails;

  /* When inventory is reserved for wave we will just mark the LPN as picked by updating wave info on the LPN but
     the actual inventory will be allocated for orders by a background process, so considering only UnitsToAllocate from
     order details isn't enough when reserving inventory against wave. Compute LPN quantities to know actual UnitsAllocate */

  /* Get the summarized counts of Wave */
  insert into @ttWaveCounts
    (WaveId, WaveNo, SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
     InnerPacks, Quantity, Ownership, Warehouse, BusinessUnit)
    select PBD.WaveId, PBD.WaveNo, PBD.SKUId, PBD.SKU, PBD.InventoryClass1, PBD.InventoryClass2, PBD.InventoryClass3,
           sum(PBD.InnerPacksToAllocate), sum(PBD.UnitsAuthorizedToShip), PBD.Ownership, PBD.Warehouse, PBD.BusinessUnit
    from vwPickBatchDetails PBD
    where (PBD.WaveId = @WaveId) and
          (PBD.SKUId  = coalesce(@SKUId, PBD.SKUId)) and
          (PBD.InventoryClass1 = coalesce(@InventoryClass1, PBD.InventoryClass1)) and
          (PBD.InventoryClass2 = coalesce(@InventoryClass2, PBD.InventoryClass2)) and
          (PBD.InventoryClass3 = coalesce(@InventoryClass3, PBD.InventoryClass3)) and
          (PBD.OrderType not in ('B' /* bulk order */))
    group by PBD.WaveId, PBD.WaveNo, PBD.SKUId, PBD.SKU, PBD.InventoryClass1, PBD.InventoryClass2, PBD.InventoryClass3,
            PBD.Ownership, PBD.Warehouse, PBD.BusinessUnit;

  /* Get the counts of reserved LPNs for wave */
  insert into @ttLPNCounts(WaveId, SKUId, InventoryClass1, InventoryClass2, InventoryClass3,
                           InnerPacks, Quantity, Ownership, Warehouse, BusinessUnit)
    select L.PickBatchId, LD.SKUId, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
           sum(LD.InnerPacks), sum(LD.Quantity), L.Ownership, L.DestWarehouse, L.BusinessUnit
    from LPNs L
      left outer join LPNDetails LD on (L.LPNId = LD.LPNId)
    where (L.PickBatchId = @WaveId) and
          (LD.SKUId  = coalesce(@SKUId, LD.SKUId)) and
          (LD.InventoryClass1 = coalesce(@InventoryClass1, LD.InventoryClass1)) and
          (LD.InventoryClass2 = coalesce(@InventoryClass2, LD.InventoryClass2)) and
          (LD.InventoryClass3 = coalesce(@InventoryClass3, LD.InventoryClass3)) and
          (LD.OnhandStatus = 'R' /* Reserved */)
    group by L.PickBatchId, LD.SKUId, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
             L.Ownership, L.DestWarehouse, L.BusinessUnit;

  /* Compute actual quantites from Wave & LPN counts */
  /* Some time we can't calculate the inner packs for pre generated cartons and this leads to negative inner packs,
     so if the inner packs is negative showing zero */
  insert into @WaveInventoryInfo
    (WaveId, WaveNo, SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3,
     IPsToReserve, QtyToReserve, QtyOrdered, QtyReserved, Ownership, Warehouse, BusinessUnit)
    select ttWC.WaveId, ttWC.WaveNo, ttWC.SKUId, ttWC.SKU, ttWC.InventoryClass1, ttWC.InventoryClass2, ttWC.InventoryClass3,
           case when (sum(ttWC.InnerPacks) - sum(coalesce(ttLC.InnerPacks, 0))) > 0 then sum(ttWC.InnerPacks) - sum(coalesce(ttLC.InnerPacks, 0)) else 0 end /* IPsToReserve */,
           sum(ttWC.Quantity) - sum(coalesce(ttLC.Quantity, 0)) /* QtyToReserve */,
           sum(ttWC.Quantity) /* QtyOrdered */,
           sum(coalesce(ttLC.Quantity, 0)) /* QtyReserved */,
           ttWC.Ownership, ttWC.Warehouse, ttWC.BusinessUnit
    from @ttWaveCounts ttWC
      left outer join @ttLPNCounts ttLC on (ttWC.WaveId          = ttLC.WaveId) and
                                           (ttWC.SKUId           = ttLC.SKUId) and
                                           (ttWC.InventoryClass1 = ttLC.InventoryClass1) and
                                           (ttWC.InventoryClass2 = ttLC.InventoryClass2) and
                                           (ttWC.InventoryClass3 = ttLC.InventoryClass3) and
                                           (ttWC.Ownership       = ttLC.Ownership) and
                                           (ttWC.Warehouse       = ttLC.Warehouse) and
                                           (ttWC.BusinessUnit    = ttLC.BusinessUnit)
    group by ttWC.WaveId, ttWC.WaveNo, ttWC.SKUId, ttWC.SKU, ttWC.InventoryClass1, ttWC.InventoryClass2, ttWC.InventoryClass3,
             ttWC.Ownership, ttWC.Warehouse, ttWC.BusinessUnit
    order by ttWC.WaveId, ttWC.WaveNo, ttWC.SKUId, ttWC.SKU, ttWC.InventoryClass1, ttWC.InventoryClass2, ttWC.InventoryClass3,
             ttWC.Ownership, ttWC.Warehouse, ttWC.BusinessUnit;

  return;
end /* fn_Reservation_GetWaveInventoryInfo */

Go
