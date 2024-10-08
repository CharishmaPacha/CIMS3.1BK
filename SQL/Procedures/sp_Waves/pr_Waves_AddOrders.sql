/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/01  AY      pr_Waves_AddOrders: Initial revision (CIMSV3-1516)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_AddOrders') is not null
  drop Procedure pr_Waves_AddOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_AddOrders: Adds the list of Orders or OrderDetails (#AddOrdersToWave)
   to the given wave. Updates WaveDetails and recalculates Order/Wave statuses

  Assumption is that all validations have been done already.

  #AddOrdersToWave : @ttAddOrdersToWave (defined in pr_Waves_Action_AddOrdersToWave)
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_AddOrders
  (@WaveId           TRecordId,
   @WaveNo           TWaveNo,
   @WavingLevel      TDescription = 'OH',
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,
          @vWaveNo          TWaveNo,
          @vWaveGroup       TWaveGroup,
          @vSoldToCount     TCount,
          @vSoldToId        TCustomerId,
          @vShipToCount     TCount,
          @vShipToId        TShipToId,
          @vShipViaToCount  TCount,
          @vShipVia         TShipVia,
          @vPickZone        TLookUpCode,
          @vOrderPriority   TPriority,
          @NumLinesOnOrder  TCount,
          @NumSKUsOnOrder   TCount,
          @NumUnitsOnOrder  TCount,
          @vTimestamp       TDateTime,
          @vAuditEntity     TDescription,
          @vAuditRecordId   TRecordId,
          @vNote1           TDescription,
          @vRecordsUpdated  TCount,
          @vBusinessUnit    TBusinessUnit;

  declare @ttOrdersUpdated        TEntityKeysTable;
  declare @ttOrderDetailsUpdated table (OrderId        TRecordId,
                                        OrderDetailId  TRecordId,
                                        RecordId       TRecordId Identity (1,1));
begin
  SET NOCOUNT ON;

  /* Lock in the timee as we want to timestamp all records with exact date time i.e.
     OH.ModifiedDate as well as WaveDetails.CreatedDate */
  select @vTimestamp = current_timestamp,
         @UserId     = coalesce(@UserId, System_User);

  /* Get wave info */
  select @vWaveNo    = WaveNo,
         @vWaveGroup = PickBatchGroup
  from Waves
  where (WaveId = @WaveId);

  /* fill in the Order info */
  update OTW
  set PickTicket  = OH.PickTicket,
      OrderStatus = OH.Status,
      OrderType   = OH.OrderType,
      Warehouse   = OH.Warehouse,
      Ownership   = OH.Ownership,
      WaveGroup   = OH.PickBatchGroup
  from #AddOrdersToWave OTW join OrderHeaders OH on OTW.OrderId = OH.OrderId;

  /* If the Waving level is OrderHeaders level then consider #AddToWave as Orders and add
     update all the OrderHeaders */
  if (@WavingLevel = 'OH')
    begin
      /* Update OrderHeaders with BatchNo and Status To Batched */
      update OH
      set PickBatchId      = @WaveId,
          PickBatchNo      = @WaveNo,
          Status           = 'W'  /* Waved */,
          ModifiedDate     = @vTimestamp,
          ModifiedBy       = @UserId,
          @vAuditEntity    = 'WaveOrdersAdded'
      output (inserted.OrderId) into @ttOrdersUpdated (EntityId)
      from OrderHeaders OH join #AddOrdersToWave ATW on (OH.OrderId = ATW.OrderId)
      where (OH.Status = 'N' /* Sanity check */);

      select @vNote1 = @@rowcount; -- To let user know how many orders were added

      /* Add all details of all the Orders added to the Wave to WaveDetails table */
      insert into WaveDetails(PickBatchId, PickBatchNo, WaveId, WaveNo, OrderId, OrderDetailId, BusinessUnit, CreatedDate, CreatedBy)
        select @WaveId, @WaveNo, @WaveId, @WaveNo, OD.OrderId, OD.OrderDetailId, @BusinessUnit, @vTimestamp, @UserId
        from OrderDetails OD join @ttOrdersUpdated OU on OD.OrderId = OU.EntityId;

      /* Update the processStatus once records are updated above */
      update OTW
      set ProcessStatus = 'Done'
      from #AddOrdersToWave OTW join @ttOrdersUpdated OU on OTW.OrderId = OU.EntityId
    end
  else
    begin
      /* Update OrderDetails here */
      update OD
      set ModifiedDate   = @vTimestamp,
          ModifiedBy     = @UserId,
          @vAuditEntity  = 'WaveOrderDetailsAdded'
      output inserted.OrderId, inserted.OrderDetailId into @ttOrderDetailsUpdated (OrderId, OrderDetailId)
      from OrderDetails OD join #AddOrdersToWave ATW on (OD.OrderDetailId = ATW.OrderDetailId)

      select @vNote1 = @@rowcount;

      /* Add Order detail to WaveDetails table */
      insert into WaveDetails(PickBatchId, PickBatchNo, WaveId, WaveNo, OrderId, OrderDetailId, BusinessUnit, CreatedDate, CreatedBy)
        select @WaveId, @WaveNo, @WaveId, @WaveNo, OD.OrderId, OD.OrderDetailId, @BusinessUnit, @vTimestamp, @UserId
        from OrderDetails OD join #AddOrdersToWave ATW on OD.OrderDetailId = ATW.OrderDetailId;

      insert into @ttOrdersUpdated(EntityId) select distinct OrderId from @ttOrderDetailsUpdated;

      /* Update the processStatus once records are updated above */
      update OTW
      set ProcessStatus = 'Done'
      from #AddOrdersToWave OTW join @ttOrderDetailsUpdated OU on OTW.OrderDetailId = OU.OrderDetailId
    end

  /* Recalculate orders to set status */
  if exists (select * from @ttOrdersUpdated)
    exec pr_OrderHeaders_Recalculate @ttOrdersUpdated, 'S' /* Status */, @UserId, @BusinessUnit;

  /* If this is the first time orders are being added to batch, then
     set the Group on the wave, so that in future, only orders of that
     group are added */
  if (@vWaveGroup is null)
    select top 1 @vWaveGroup = WaveGroup from #AddOrdersToWave;

  /* Update the summary fields and counts on the batch */
  exec pr_PickBatch_UpdateCounts @vWaveNo, 'O' /* Options */, @vWaveGroup;

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vAuditEntity, @UserId, @vTimestamp,
                            @WaveId = @WaveId, @Note1 = @vNote1,
                            @AuditRecordId = @vAuditRecordId output;

  /* Link all the orders added to the AT */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Order', @ttOrdersUpdated, @BusinessUnit;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Waves_AddOrders */

Go
