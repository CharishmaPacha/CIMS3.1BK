/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/24  VS/TD   pr_Replenish_MarkOrdersCompleted: Added condition for can't take Archive data (OB2-761, OB2-769)
  2018/07/11  AY      pr_Replenish_MarkOrdersCompleted: Changes to handle scenario where Order is completed by Wave isn't
  2017/10/17  TK      pr_Replenish_MarkOrdersCompleted: Enhanced to cancel the orders for which nothing is allocated (HPI-1651)
  2016/08/09  AY      pr_Replenish_MarkOrdersCompleted: Enhance to mark wave also as completed and log AT (HPI-469)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_MarkOrdersCompleted') is not null
  drop Procedure pr_Replenish_MarkOrdersCompleted;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_MarkOrdersCompleted: Procedure marks as completed once all
    Units are putaway against the replenish orders. We can schedule a job in SQL.
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_MarkOrdersCompleted
  (@BusinessUnit      TBusinessUnit,
   @UserId            TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessage,
          @vRecordId         TRecordId,

          @vOrderId          TRecordId,
          @vPickTicket       TPickTicket,
          @vOrderStatus      TStatus,
          @vPickBatchId      TRecordId,
          @vPickBatchNo      TPickBatchNo,
          @vNewOrderStatus   TStatus,
          @vNewWaveStatus    TStatus,
          @vDebug            TFlags;

  declare @ttReplenishOrders          TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  /* load all the Replenish Orders which are not yet completed to evaluate their status */
  insert into @ttReplenishOrders(EntityId, EntityKey)
    select OrderId, PickTicket
    from OrderHeaders
    where (OrderType in ('RU', 'RP', 'R' /* Replenish Orders */)) and
          (Status not in ('D' /* Completed */, 'X' /* Cancelled */)) and
          (Archived = 'N' /* No */) and
          (BusinessUnit = @BusinessUnit)
    union
    /* Replenish orders which are completed, but waves aren't */
    select OH.OrderId, OH.PickTicket
    from OrderHeaders OH
      left outer join Pickbatches PB on (PB.RecordId = OH.PickBatchId)
    where (OrderType   in ('RU' , 'RP' /* Replenish Orders */)) and
          (OH.Status in ('D' /* Completed */)) and
          (PB.Status not in ('D' /* Completed */, 'X' /* Cancelled */)) and
          (OH.Archived = 'N' /* No */) and
          (OH.BusinessUnit = @BusinessUnit)

  while (exists (select * from @ttReplenishOrders where RecordId > @vRecordId))
    begin
      begin try
        /* Reset vars */
        select @vNewOrderStatus = null, @vNewWaveStatus = null;

        select top 1 @vOrderId  = EntityId,
                     @vRecordId = RecordId
        from @ttReplenishOrders
        where RecordId > @vRecordId
        order by RecordId;

        select @vPickBatchNo = PickBatchNo,
               @vOrderStatus = Status
        from OrderHeaders
        where (OrderId = @vOrderId);

        /* Calc Order status */
        if (@vOrderStatus not in ('D', 'X' /* Completed or cancelled */))
          exec pr_OrderHeaders_SetStatus @vOrderId, @vNewOrderStatus output;

        /* If Order is completed, recalc Wave status as well */
        if (@vNewOrderStatus in ('D', 'X' /* Completed, Cancelled */)) or
           (@vOrderStatus in ('D', 'X' /* Completed, Cancelled */))
          exec pr_PickBatch_SetStatus @vPickBatchNo, @vNewWaveStatus output, @PickBatchId = @vPickBatchId output;

        if (coalesce(@vNewOrderStatus, @vOrderStatus) = 'D' /* Completed */) and (@vNewWaveStatus = 'D' /* Completed */)
          exec pr_AuditTrail_Insert 'ReplenishmentCompleted', @UserId, null /* ActivityDateTime - if null takes the Current TimeStamp */,
                                    @OrderId     = @vOrderId,
                                    @PickBatchId = @vPickBatchId;
      end try
      begin catch
        /* if there is any error then skip current order and continue with next order */
        continue;
      end catch
    end /* End of while loop */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_MarkOrdersCompleted */

Go
