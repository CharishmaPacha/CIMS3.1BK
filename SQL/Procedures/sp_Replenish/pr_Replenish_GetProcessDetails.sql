/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/02/23  TK      pr_Replenish_GenerateOndemandOrders: Quantity to allocate on any line should exclude reserved qty on it
                      pr_Replenish_GetProcessDetails: Ignore UnitsPreAllocated as S2G don't use soft allocation (S2G-151)
  2016/08/04  TK      pr_Replenish_GetProcessDetails: Exclude details containing Lot while creating On-Demand Orders
                                                      Don't consider lines if they are not preallocated (HPI-443)
  2015/10/28  RV      pr_Replenish_GetProcessDetails: Migrated from GNC
  2014/05/18  PK      Added pr_Replenish_GenerateOndemandOrders, pr_Replenish_GetProcessDetails.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_GetProcessDetails') is not null
  drop Procedure pr_Replenish_GetProcessDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_GetProcessDetails: This can be optimized a lot
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_GetProcessDetails
  (@PickBatchId          TRecordId)
as
  declare  @ttBatchedOrderDetails  TBatchedOrderDetails,
           @vWaveType              TTypeCode,
           @vBPTOrderId            TRecordId;
begin
  select @vWaveType = BatchType
  from PickBatches
  where (RecordId = @PickBatchId);

  /* Check if the Wave has a BPT Order, if so then we should only allocate remaining units of BPT
     else, it would be regular orders */
  select @vBPTOrderId = OrderId
  from vwOrderHeaders
  where (PickBatchId = @PickBatchId) and
        (OrderType   = 'B'/* Bulk Pull */);

  /* insert all batched order details for the batch -
     need to create BPT for Discrete lines, becuase we do not include
     Discrete lines in BPT
     We need to create ondemand replenishments for ecom-s */
  insert into @ttBatchedOrderDetails
    select PickBatchId, OrderId, OrderDetailId, SKUId, UnitsOrdered,
           UnitsAuthorizedToShip, UnitsPerInnerPack, UnitsToAllocate,
           /* if the ecom order has only non-sortbales then we are changing destzone to
              Ecompack, but need to create ondemand for all the non-sortble units.
              so we need to remain the destzone as same for the non sortable items */
           case when DestZone = 'ECOMPACK' and IsSortable = 'N' then 'NON-SORT'
                else DestZone
           end, null
    from vwPickBatchDetails
    where (PickBatchId = @PickBatchId) and
          (UnitsToAllocate > 0) and
          (ODLot is null) and  -- If Lot No is present on OrderDetail then it would be expecting specific LPN Detail which matches with the OD.Lot so exclude while creating Replenish Orders
          ((@vBPTOrderId is null) or (OrderType = 'B' /* Bulk PT */));  -- if there is BPT order we only get details of that else all orders

  /* we need to seperate here cases and remaining units - cases here are shipdock cases */
  with ProcessedDetails(SKUId, DestZone, Lines, Cases, RemUnits, UnitsPerInnerpack, TotalUnitsToAllocate)
  as
  (
    select SKUId, DestZone, count(OrderDetailId), sum(UnitsToAllocate / UnitsPerInnerPack),
           sum(UnitsToAllocate % UnitsPerInnerPack), Min(UnitsPerInnerPack), sum(UnitsToAllocate)
    from @ttBatchedOrderDetails
    group by SKUId, DestZone
  ),
  /* Insert data into CTE by SKU and DestZone with cases and Units calculation */
  DetailsByZone(SKUId, DestZone, NumSKUs, NumLines, ShippingDockCases, BPTCases, NumUnits, BPTCaseUnits,
                SPDOCKUnits, TotalUnitsToAllocate, UnitsPerInnerPack)
  as
  (
      select SKUId, DestZone, count(distinct SKUId), sum(Lines), sum(Cases), sum(RemUnits / UnitsPerInnerPack),
      sum(RemUnits % UnitsPerInnerPack),  sum((RemUnits / UnitsPerInnerPack) * UnitsPerInnerPack),
      sum(Cases * UnitsPerInnerPack), sum(TotalUnitsToAllocate), Min(UnitsPerInnerPack)
      from ProcessedDetails
      group by SKUId, DestZone
  )
  select @PickBatchId, SKUId, DestZone, count(distinct SKUId), sum(NumLines), sum(ShippingDockCases + BPTCases),
         sum(BPTCaseUnits + SPDOCkUnits), sum(TotalUnitsToAllocate), sum(ShippingDockCases), Min(UnitsPerInnerPack)
  from DetailsByZone
  group by SKUId, DestZone
  having sum(TotalUnitsToAllocate) > 0
end  /* pr_Replenish_GetProcessDetails */

Go
