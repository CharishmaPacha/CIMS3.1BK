/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/11/14  VM      pr_PickBatch_MarkAsShipped: Made several changes
  2012/11/01  NY      pr_PickBatch_MarkAsShipped: Created new procedure to ship manually picked batches.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_MarkAsShipped') is not null
  drop Procedure pr_PickBatch_MarkAsShipped;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_MarkAsShipped:
    Evaluates all Batches of certain statuses and updates their statuses.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_MarkAsShipped
  (@PickBatchNo TPickBatchNo = null)
as
  declare @vPickBatchId         TRecordId,
          @vPickBatchNo         TPickBatchNo,
          @vBatchStatus         TStatus,
          @vOrderId             TRecordId,
          @vLPNId               TRecordId,
          @vAuditActivity       TActivityType,
          @ActivityDateTime     TDateTime,
          @vBusinessUnit        TBusinessUnit,
          @UserId               TUserId;

  declare @ttPickBatches        TEntityKeysTable,
          @ttLPNs               TEntityKeysTable;
begin
  select @UserId           = System_User,
         @ActivityDateTime = current_timestamp;

  /* Retreving Batches which are manually picked. */
  insert into @ttPickBatches (EntityId, EntityKey)
    select RecordId, BatchNo
    from PickBatches
    where ((@PickBatchNo is null) or (BatchNo = @PickBatchNo)) and
          (UDF3 = 'Manual') and (Description = 'Shipped') and
          (datediff(day,getdate(),ShipDate) <= -2) and
          (Status not in ('S'/* Shipped */, 'D'/* Completed */, 'X'/* Cancelled */)) and
          (Archived = 'N' /* No */);

  select top 1 @vPickBatchId = EntityId,
               @vPickBatchNo = EntityKey
  from @ttPickBatches
  order by EntityId;

  /* Start the batch loop */
  while (@@rowcount > 0)
    begin

      /* Delete all the preexisting record from the previuos loop */
      delete from @ttLPNs;

      /* Get LPN, Order Details into temp table */
      insert into @ttLPNs(EntityId, EntityKey)
        select L.LPNId, L.LPN
        from OrderHeaders OH
          join LPNs L on (L.OrderId = OH.OrderId) and (L.Status <> 'S' /* Shipped */)
        where (OH.PickBatchNo =  @vPickBatchNo) and
              (OH.Status not in ('S'/* Shipped */,'D'/* Completed */,'X'/* Cancelled */))
        order by OH.OrderId;

      /* select the top 1 record from the temp table */
      select top 1 @vLPNId = EntityId
      from @ttLPNs
      order by EntityId;

      /* Start the LPNs Loop */
      while (@@rowcount > 0)
        begin
          /* Mark the LPN as Shipped */
          exec pr_LPNs_Ship @vLPNId, null /* LPN */, null /* BusinessUnit */, @UserId, 'N' /* No - Generate Exports */;

          select top 1 @vLPNId = EntityId
          from @ttLPNs
          where EntityId >  @vLPNId
          order by EntityId;
        end

      select @vBatchStatus = Status
      from PickBatches
      where (BatchNo = @vPickBatchNo);

      select @vAuditActivity = case when @vBatchStatus = 'S' then 'PickBatchShipped'
                                    --when @vBatchStatus = 'D' then 'PickBatchCompleted'
                                    --when @vBatchStatus = 'X' then 'PickBatchCanceled'
                                    else null
                               end;

      /* Audit trail */
      if (@vAuditActivity is not null)
        exec pr_AuditTrail_Insert @vAuditActivity, @UserId, @ActivityDateTime,
                                  @PickBatchId = @vPickBatchId;

      /* Reset the batch and status variables */
      select @vBatchStatus = null;

      /* select the top 1 record from the temp table */
      select top 1 @vPickBatchId = EntityId,
                   @vPickBatchNo = EntityKey
      from @ttPickBatches
      where EntityId > @vPickBatchId
      order by EntityId;
    end
end /* pr_PickBatch_MarkAsShipped */

Go
