/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/01/07  TK      pr_OrderHeaders_FinalizeUnWave: Do not compute wave status or counts (BK-720)
  2021/03/27  TK      pr_OrderHeaders_FinalizeUnWave: Initial Revision (HA-2463)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_FinalizeUnWave') is not null
  drop Procedure pr_OrderHeaders_FinalizeUnWave;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_FinalizeUnWave: This proc does the updates that has to be done
    after removing the order from waves

  #OrdersUnWaved: TOrderDetails
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_FinalizeUnWave
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName;

  declare @ttOrdersToRecalc         TEntityKeysTable,
          @ttWavesToRecalc          TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Eliminate the unwaved orders that don't have a bulk order */
  delete OUW
  from #OrdersUnWaved OUW
  where (dbo.fn_Pickbatch_IsBulkBatch(OUW.WaveId) = 'N' /* No */);

  /* Identify corresponding bulk order for the customer orders that are unwaved */
  update OUW
  set BulkOrderId = OH.OrderId
  from #OrdersUnWaved OUW
    join OrderHeaders OH on (OUW.WaveId = OH.PickBatchId)
  where (OH.OrderType = 'B' /* Bulk */) and (OH.Status not in ('D', 'X' /* Completed/Canceled */));

  /* Get the total quantities of the customer orders that are unwaved and deduct then on the bulk order

     We will not disturb the inventory that is already to a bulk order that means, we can only deduct
     quantities upto bulk order UnitsToAllocate or customer order UnitsAuthorizedToShip which ever is the lowest */
  ;with CustOrderDetails as
  (
    select OUW.BulkOrderId, OD.SKUId, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3, sum(UnitsAuthorizedToShip) as UnitsToDeduct
    from OrderDetails OD
      join #OrdersUnWaved OUW on (OD.OrderId = OUW.OrderId)
    group by OUW.BulkOrderId, OD.SKUId, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3
  )
  update OD
  set --UnitsOrdered          -= dbo.fn_MinInt(OD.UnitsToAllocate, COD.UnitsToDeduct),
      UnitsAuthorizedToShip -= dbo.fn_MinInt(OD.UnitsToAllocate, COD.UnitsToDeduct)
  from OrderDetails OD
    join CustOrderDetails COD on (OD.OrderId = COD.BulkOrderId) and
                                 (OD.SKUId   = COD.SKUId) and
                                 (OD.InventoryClass1 = COD.InventoryClass1) and
                                 (OD.InventoryClass2 = COD.InventoryClass2) and
                                 (OD.InventoryClass3 = COD.InventoryClass3);

  /* Compute order statuses */
  insert into @ttOrdersToRecalc (EntityId) select distinct BulkOrderId from #OrdersUnWaved;
  exec pr_OrderHeaders_Recalculate @ttOrdersToRecalc, 'C' /* Counts only */, @UserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_FinalizeUnWave */

Go
