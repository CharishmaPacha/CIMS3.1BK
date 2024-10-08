/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/29  DA      pr_Replenish_MarkOrdersCancelled: Added Log to the Procedure.
                      pr_Replenish_MarkOrdersCancelled: Moved code to another procedure as not all clients would need this (S2G-1015)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_MarkOrdersCancelled') is not null
  drop Procedure pr_Replenish_MarkOrdersCancelled;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_MarkOrdersCancelled: Procedure is to automatically cancel
    old replenish orders. We can schedule a job in SQL.
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_MarkOrdersCancelled
  (@BusinessUnit      TBusinessUnit,
   @UserId            TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessage,
          @vRecIdToCancel    TRecordId,

          @vOrderId          TRecordId,
          @vPickTicket       TPickTicket,
          @vOrderStatus      TStatus,
          @vPickBatchId      TRecordId,
          @vPickBatchNo      TPickBatchNo,
          @vNewOrderStatus   TStatus,
          @vNewWaveStatus    TStatus,
          @vActivityLogId    TRecordId;

  declare @ttReplenishOrdersToCancel  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecIdToCancel = 0;

  exec pr_ActivityLog_AddMessage 'ReplenishCancelOrder', null, null, 'PickTicket', 'Orders' /* Message */, @@ProcId, null /* xmlData */, @BusinessUnit, @UserId;

  /* Get the Orders which needs to be cancelled
     Get the New Orders whose CreatedDate greter than 5 days
     Get the Waved Orders whose Wave.AllocateFalgs is 'Done' and ReleaseDateTime is greater than 2 days */
  insert into @ttReplenishOrdersToCancel(EntityId, EntityKey)
    select OH.OrderId, OH.PickTicket
    from OrderHeaders OH
    where (OH.OrderType in ('RU' , 'RP', 'R' /* Replenish Orders */)) and
          (OH.Status = 'N'/* New */) and
          (OH.Archived = 'N' /* No */) and
          (OH.BusinessUnit = @BusinessUnit) and
          (datediff(day, OH.CreatedDate, current_timestamp) > 5)
    union
    select OH.OrderId, OH.PickTicket
    from OrderHeaders OH
      join PickBatches PB on (OH.PickBatchId = PB.RecordId)
      left outer join LPNs L on (OH.OrderId  = L.OrderId)
    where (OH.OrderType in ('RU' , 'RP', 'R' /* Replenish Orders */)) and
          (OH.Status = 'W'/* Waved */) and
          (OH.Archived = 'N' /* No */) and
          (OH.BusinessUnit = @BusinessUnit) and
          (L.LPNId is null) and
          (PB.AllocateFlags = 'D'/* Done */) and
          (datediff(day, PB.ReleaseDateTime, current_timestamp) > 2);

  /* Loop thru each order and cancel them */
  while exists (select * from @ttReplenishOrdersToCancel where RecordId > @vRecIdToCancel)
    begin
      begin try
        select top 1 @vRecIdToCancel = RecordId,
                     @vOrderId       = EntityId,
                     @vPickTicket    = EntityKey
        from @ttReplenishOrdersToCancel
        where (RecordId > @vRecIdToCancel)
        order by RecordId;

        /* Cancel each PickTicket */
        exec pr_OrderHeaders_CancelPickTicket @vOrderId, @vPickTicket, null /* reasoncode */, @BusinessUnit, @UserId;

        /* Reset variables */
        select @vOrderId = null, @vPickTicket = null;

      end try
      begin catch
        /* if there is any error then skip current order and continue with next order */
        continue;
      end catch
    end

  /* End of the Log */
  exec pr_ActivityLog_AddMessage 'ReplenishCancelOrder', null, null, 'PickTicket', 'Orders' /* Message */, @@ProcId, null /* xmlData */, @BusinessUnit, @UserId;
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_MarkOrdersCancelled */

Go
