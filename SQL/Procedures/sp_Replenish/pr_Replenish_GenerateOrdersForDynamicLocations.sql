/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/17  TK      pr_Replenish_GenerateOrdersForDynamicLocations: Initial Revision (S2GCA-63)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_GenerateOrdersForDynamicLocations') is not null
  drop Procedure pr_Replenish_GenerateOrdersForDynamicLocations;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_GenerateOrdersForDynamicLocations:
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_GenerateOrdersForDynamicLocations
  (@WaveId            TRecordId,
   @Operation         TOperation    = null,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vRecordId              TRecordId,
          @vWaveId                TRecordId,
          @vReplenishWaveId       TRecordId,
          @vWaveNo                TWaveNo,
          @vReplenishWaveNo       TWaveNo,
          @vPriority              TInteger,
          @vWarehouse             TWarehouse,
          @vOwnership             TOwnership,

          @vOrderId               TRecordId,
          @vAuditRecordId         TRecordId;

  declare @ttOrdersToWave         TEntityKeysTable,
          @ttReplenishWaves       TEntityKeysTable;

  declare @ttInventoryToReplenish table (SKUId             TRecordId,
                                         UnitsToReplenish  TQuantity);
begin /* pr_Replenish_GenerateOndemandOrders */
begin try
begin transaction
  select @vReturnCode = 0,
         @vPriority   = 1;

  /* get wave info */
  select @vWaveId    = RecordId,
         @vWaveNo    = BatchNo,
         @vWarehouse = Warehouse,
         @vOwnership = Ownership
  from PickBatches
  where (RecordId = @WaveId);

  /* Get all the SKUs to be replenished */
  insert into @ttInventoryToReplenish(SKUId, UnitsToReplenish)
    select SKUId, sum(UnitsToAllocate)
    from OrderDetails OD
      join OrderHeaders OH on (OD.OrderId = OH.OrderId)
    where (OH.PickBatchId = @vWaveId) and
          (OD.UnitsToAllocate > 0)
    group by SKUId;

  /* Create Replenish order */
  exec pr_Replenish_CreateOrder 'RU'/* OrderType */, @vPriority, @vWaveNo /* ReplenishGroup */,
                                @vWarehouse, @vOwnership, @Operation,
                                @BusinessUnit, @UserId, @vOrderId output;

  /* Create order details */
  if (@vOrderId is null)
    begin
      set @vMessageName = 'UnableToCreateReplenishOrder'

      goto ErrorHandler;
    end

  /* Add Order details */
  insert into OrderDetails(OrderId, OrderLine, HostOrderLine, SKUId, UnitsOrdered,
                           UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, BusinessUnit)
    select @vOrderId, row_number() over (order by SKUId)/* OrderLine */,
           0/* HostOrderLine */, SKUId, UnitsToReplenish,
           UnitsToReplenish, UnitsToReplenish, @BusinessUnit
    from @ttInventoryToReplenish;

  insert into @ttOrdersToWave (EntityId) select @vOrderId;

  /* Recount the orders */
  exec pr_OrderHeaders_Recalculate @ttOrdersToWave, 'C' /* Counts */, @UserId;

  /* Logging AuditTrail for newly created Replenish Order */
  exec pr_AuditTrail_Insert 'GenerateReplenishOrder', @UserId, null /* audittimestamp */,
                            @OrderId       = @vOrderId,
                            @BusinessUnit  = @BusinessUnit,
                            @AuditRecordId = @vAuditRecordId output;

  /* If there are any new waves created then they should be waved */
  exec pr_Replenish_CreateReplenishWaves @ttOrdersToWave, @Operation, @BusinessUnit, @UserId,
                                         @vWaveNo, @vReplenishWaveId output, @vReplenishWaveNo output;

  /* Get the Replenish wave created and release it */
  insert into @ttReplenishWaves(EntityId, EntityKey)
    select @vReplenishWaveId, @vReplenishWaveNo;

  /* Release Replenish Wave */
  exec pr_PickBatch_ReleaseBatches @ttReplenishWaves, @UserId, @BusinessUnit;

  /* Return all the waves which needs to be re-allocated */
  delete from #ReplenishWavesToAllocate;

  insert into #ReplenishWavesToAllocate(WaveId, WaveNo, WaveType, WaveStatus, IsAllocated, Warehouse, AllocPriority)
    select PB.RecordId, PB.BatchNo, PB.BatchType, PB.Status, 'N'/* No */, PB.Warehouse, 1 /* Alloc Priority */
    from PickBatches PB
    where (RecordId = @vReplenishWaveId);

  /* If the wave is replenished then we would have update flag above, so if the flag is not
     updated above then ignore creating on-demand for that wave */
  update PB
  set PB.IsReplenished    = case when (@vReplenishWaveNo is not null) then 'Y'/* Yes */ else 'I'/* Ignore */ end,
      PB.ReplenishBatchNo = @vReplenishWaveNo
  from PickBatchAttributes PB
  where (PickBatchId = @vWaveId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction;
  exec pr_ReRaiseError;
  /* Generate error LOG here */
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_GenerateOrdersForDynamicLocations */

Go
