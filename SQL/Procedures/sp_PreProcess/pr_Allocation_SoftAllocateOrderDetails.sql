/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/04/01  AY/TK   pr_Allocation_SoftAllocateOrderDetails: Initial revision (NBD-301)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_SoftAllocateOrderDetails') is not null
  drop Procedure pr_Allocation_SoftAllocateOrderDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_SoftAllocateOrderDetails:

  The objective of this procedure to  will take Allocation ruleId and all the available inventory for the
  SKU.

  This will gives us the LPN which we need to allocate for the order(s).

  If SearchType = 'F' (Full) we only need to allocate LPNs that can be fully allocated i.e.
  nothing is reserved in them. If SearchType = 'P' (Partial) then we can allocate Cases or Units
  from an LPN and hence even if the LPN is already partially allocated that is fine

------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_SoftAllocateOrderDetails
  (@OrderDetails        TSoftAllocationDetails readonly,
   @UserId              TUserId,
   @BusinessUnit        TBusinessUnit,
   @Warehouse           TWarehouse,
   @Debug               TFlag = 'N')
as
  declare @vRecordId              TRecordId,
          @vInvRecordId           TRecordId,
          @vReturnCode            TInteger,

          @vSKUId                 TRecordId,
          @vOrderDetailId         TRecordId,

          @vAvailableQty          TInteger,
          @vTotalUnitsToAllocate  TInteger,
          @vUnitsPreAllocated     TInteger,
          @vOwnership             TOwnership,
          @vWarehouse             TWarehouse;

  declare @ttResults              TSoftAllocationDetails,
          @ttOnhandInventory      TOnhandInventory;

begin /* pr_Allocation_SoftAllocateOrderDetails */
  /* Initialize variables */
  select @vRecordId    = 0,
         @vInvRecordId = 0;

  /* Change RecordId column as Identity column */
  select * into #OHIResults from @ttOnhandInventory;

  alter table #OHIResults drop column RecordId;
  alter table #OHIResults add RecordId int identity (1,1) not null;

  /* Insert input OrderDetails along with other SKU Info into @ttResults */
  insert into @ttResults (OrderId, OrderDetailId, SKUId, UnitsToShip, UnitsToAllocate, RecordId,
                          PickTicket, OrderType, OrderStatus, Warehouse, Ownership, ShipComplete,
                          OrderCategory1, SKU)
    select IOD.OrderId, IOD.OrderDetailId, IOD.SKUId, IOD.UnitsToShip, IOD.UnitsToAllocate, row_number() over (order by IOD.SortOrder, IOD.RecordId),
           OH.PickTicket, OH.OrderType, OH.Status, OH.Warehouse, OH.Ownership, OH.ShipComplete,
           OH.OrderCategory1, S.SKU
    from @OrderDetails IOD /* Input Order Details */
      join SKUs S on IOD.SKUId = S.SKUId
      join OrderHeaders OH on IOD.OrderId = OH.OrderId
    -- join with SKU, OH and fill in all details as sender may only send OrderId, OrderDetailId.. IOD (Input Order Details)

  /* Get all available inventory for all SKUs - this should be much better
     performance than getting for one SKU at a time */
  exec pr_Inventory_OnhandInventory @BusinessUnit = @BusinessUnit, @Warehouse = @Warehouse, @Mode = 'WH'/* Warehouse */;

  /* Delete the unwanted SKUs */
  delete from #OHIResults
  where (AvailableQty = 0) or
        (SKUId not in (select distinct SKUId from @OrderDetails));

  if (@Debug = 'Y') select 'Inventory' as Inventory, * from #OHIResults;
  if (@Debug = 'Y') select 'ToAlloc' as OrderDetails, * from @ttResults;

  /* Go thru each SKU and distribute the qty to the order details */
  while (exists (select * from #OHIResults where RecordId > @vInvRecordId))
    begin
      /* Get the next SKU */
      select top 1 @vInvRecordId  = RecordId,
                   @vSKUId        = SKUId,
                   @vAvailableQty = AvailableQty,
                   @vOwnership    = Ownership,
                   @vWarehouse    = Warehouse
      from #OHIResults
      where (RecordId > @vInvRecordId)
      order by RecordId;

      /* Check total Qty needed for the SKU */
      select @vTotalUnitsToAllocate = sum(UnitsToAllocate)
      from @ttResults
      where (SKUId     = @vSKUId    ) and
            (Ownership = @vOwnership) and
            (Warehouse = @vWarehouse);   -- have index on TSoftAllocationDetails by SKUId, OrderDetailId

      /* If there are more units available than are needed, then mark all
         order details as allocated and proceed to next SKU */
      if (@vTotalUnitsToAllocate <= @vAvailableQty)
        begin
          update @ttResults
          set UnitsPreAllocated = UnitsToAllocate
          where (SKUId     = @vSKUId    ) and
                (Ownership = @vOwnership) and
                (Warehouse = @vWarehouse);

          continue;
        end

      select @vRecordId = 0;

      /* Distribute the available qty to the order details in sequence of SortOrder */
      while exists (select *
                    from @ttResults
                    where (RecordId > @vRecordId) and
                          (SKUId = @vSKUId) and
                          (AllocatedStatus <> 'F'/* Fully Allocated */)) and
                   (@vAvailableQty > 0)
        begin
          /* Results are already sorted by caller given Sort Order above, so just using order by recordid is sufficient */
          select top 1 @vRecordId      = RecordId,
                       @vOrderDetailId = OrderDetailId
          from @ttResults
          where (RecordId  > @vRecordId ) and
                (SKUId     = @vSKUId    ) and
                (Ownership = @vOwnership) and
                (Warehouse = @vWarehouse)
          order by RecordId;

          if (@@rowcount = 0) break;

          /* Update the units that can be allocated */
          update @ttResults
          set @vUnitsPreAllocated = UnitsPreAllocated = dbo.fn_MinInt(UnitsToAllocate, @vAvailableQty)
          where (SKUId = @vSKUId) and
                (OrderDetailId = @vOrderDetailId);

          /* Reduce the available Qty */
          set @vAvailableQty = @vAvailableQty - @vUnitsPreAllocated;
        end /* distribution of available qty */
    end /* process sku */

  /* Return the result set in temp table if table exists */
  if object_id('tempdb..#SoftAllocationDetails') is not null
    begin
      insert into #SoftAllocationDetails
        select * from @ttResults;
    end
  else
    select @Debug = 'Y'; /* Assume we are in debug mode */

  if (@Debug = 'Y') select 'Results' as Results, SKU S, * from @ttResults;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_SoftAllocateOrderDetails */

Go
