/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/30  TK      pr_Waves_ReturnOrdersToOpenPool: Initial Revision
                      pr_PickBatch_Cancel: #OrdersToUnWave changed to use TOrderDetails
                      pr_Waves_RemoveOrders_Validations: Skip some validations for ReturnOrdersToPool operation
                      pr_Waves_RemoveOrders: Bug fixes (BK-720)
  2021/12/14  SAK     pr_PickBatch_Cancel, pr_Waves_RemoveOrders: made changesto update the wave status to Cancel (BK-682)
  2021/12/08  MS      pr_Waves_RemoveOrders: Bug fix to cancel wave if no orders in it (FBV3-612)
  2021/11/26  RKC     pr_Waves_RemoveOrders_Validations: Don't allow users to remove orders if they selected bulk pull orders (CIMSV3-1725)
  2021/11/21  AY      pr_Waves_RemoveOrders: Mark Wave as canceled when empty (BK-682)
  2021/11/14  AJM/AY  pr_Waves_RemoveOrders: Revamped version of PickBatch_RemoveOrders & made changes to log AT(CIMSV3-1322)
  2021/08/18  VS      pr_PickBatch_Cancel, pr_PickBatch_Modify, pr_PickBatch_RemoveOrder, pr_PickBatch_RemoveOrders,
                      pr_Waves_Action_Cancel, pr_Waves_RemoveOrders: Pass the operation to remove the Orders from Wave (BK-475)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_RemoveOrders') is not null
  drop Procedure pr_Waves_RemoveOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_RemoveOrders: This is the complimentary procedure to pr_Waves_AddOrders
    and removes the order/orderdetails-wave association. This does not deal with
    any unallocations, cancellations etc. It is expected that the caller does all
    of that ahead of time and this procedure removes the association between Wave and
    Order/OrderDetail.

    The given orders could be all from one Wave or from multiple Waves.

  Validations;
    Do not allow to remove order unless the Order has no reserved units.
    Do not allow Orders/OrderDetails to be removed form Released Waves
      except with special permissions
    Do not allow removal if there are ship cartons which are not canceled

  #OrdersToUnwave  TOrderDetails
 ------------------------------------------------------------------------------*/
Create Procedure pr_Waves_RemoveOrders
  (@CancelWaveIfEmpty  TFlag,
   @WavingLevel        TDescription,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Operation          TOperation)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,

          @vOrderId                    TRecordId,
          @vOrderDetailId              TRecordId,
          @vQuantity                   TCount,
          @vNumOrders                  TCount,
          @vOrders                     XML,
          /* Wave info */
          @vWaveId                     TRecordId,
          @VWaveNo                     TWaveNo,
          @vWaveType                   TTypeCode,
          @vWaveStatus                 TStatus,
          @IsWaveAllocated             TFlag,
          @vWaveAllocateFlag           TFlags,
          @vNumOrdersRemoved           TCount,
          /* Audit info */
          @vAuditRecordId              TRecordId,
          @vModifiedDate               TDateTime,
          @vAuditActivity              TActivityType,
          @vWavingLevel                TDescription,
          @vEnforceWavingLevel         TDescription,
          @vControlCategory            TCategory,
          @vSorterIntegration          TControlValue,
          @vExportStatusOnUnWave       TControlValue,
          @vValue1                     TDescription,
          @vValue2                     TDescription,
          @vValue3                     TDescription;

  declare @ttOrders                    TEntityKeysTable,
          @ttOrdersUnWaved             TOrderDetails,
          @ttOrdersToUpdate            TEntityKeysTable,
          @ttDeletedWaveDetails        TRecountKeysTable,
          @ttWaves                     TEntityKeysTable,
          @ttAuditTrailInfo            TAuditTrailInfo;
begin /* pr_Waves_RemoveOrders */
  select @vWavingLevel   = @WavingLevel,
         @vAuditActivity = case when @vWavingLevel = 'OH' then 'AT_OrderUnWaved' else 'AT_OrderDetailUnWaved' end;

  /* Create required hash tables */
  select * into #OrdersUnWaved from @ttOrdersUnWaved;

  /* Get all Wave types we would be processing */
  insert into @ttWaves (EntityId, EntityKey) select distinct WaveId, WaveNo from #OrdersToUnWave;

  /* If caller does not provide any input then we need to get it from controls */
  if (coalesce(@WavingLevel, '') = '')
    begin
      /* Get batching level from controls here */
      select @WavingLevel         = dbo.fn_Controls_GetAsString('GenerateBatches', 'BatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */),
             @vEnforceWavingLevel = dbo.fn_Controls_GetAsString('GenerateBatches', 'EnforceBatchingLevel', 'OH' /* No */, @BusinessUnit, null /* UserId */);

      /* If EnforceWavingLevel is defined, it should be the final WavingLevel */
      if (coalesce(@vEnforceWavingLevel, '') <> '')
        select @vWavingLevel = @vEnforceWavingLevel;
    end

  /*------------------------- Validations -------------------------*/

  /* Exclude orders which have unitsassigned as we don't want to remove allocated orders
    unallocations should happen prior to this */
  delete from OTW
  output 'E', 'Wave_RemoveOrders_UnitsReserved', deleted.OrderId, deleted.PickTicket
  into #ResultMessages (MessageType, MessageName, EntityId, EntityKey)
  from #OrdersToUnWave OTW
    join OrderDetails OD on (OTW.OrderId = OD.OrderId) and (OD.UnitsAssigned > 0);

  /* Exclude orders which have outstanding pick tasks. All pick tasks should have been canceled by now */
  delete from OTW
  output 'E', 'Wave_RemoveOrders_TasksOutstanding', deleted.OrderId, deleted.PickTicket
  into #ResultMessages (MessageType, MessageName, EntityId, EntityKey)
  from #OrdersToUnWave OTW
    join TaskDetails TD on (OTW.OrderId = TD.OrderId) and (TD.Status not in ('X' /* Canceled */, 'C' /* Completed */));

  /*------------------------- Clear from Wave Details -------------------------*/

  /* Delete details from Wave Details based on waving Level */
  if (@vWavingLevel = 'OD' /* Order Details */)
    delete WD
    output 'OrderDetail', deleted.OrderId, deleted.WaveId
    into @ttDeletedWaveDetails(EntityType, EntityId, EntityKey)
    from WaveDetails WD join #OrdersToUnWave OTW on (OTW.OrderDetailId = WD.OrderDetailId) and (WD.WaveId = OTW.WaveId);
  else
    /* Delete the Orders from WaveDetails and capture the Orders */
    delete WD
    output 'Order', deleted.OrderId, deleted.WaveId
    into @ttDeletedWaveDetails(EntityType, EntityId, EntityKey)
    from WaveDetails WD join #OrdersToUnWave OTW on (WD.OrderId = OTW.OrderId) and (WD.WaveId = OTW.WaveId);

  /* Collect all distinct orders for processing */
  insert into #OrdersUnWaved (OrderId, WaveId) select EntityId, EntityKey from @ttDeletedWaveDetails;

  /*------------------------- Clear Order Headers -------------------------*/

  /* Remove Wave on the order */
  if (@vWavingLevel = 'OH')
    update OH
    set PrevWaveNo   = OH.PickBatchNo,
        PickBatchId  = null,
        PickBatchNo  = null,
        Status       = 'N',
        WaveFlag     = 'R', /* Removed from wave, so do not automatically wave again */
        ModifiedDate = @vModifiedDate,
        ModifiedBy   = @UserId
    from OrderHeaders OH join #OrdersToUnwave OU on OU.OrderId = OH.OrderId;
  else
  /* Clear Wave from Order if all order details are off waves */
  if (@vWavingLevel = 'OD')
    update OH
    set PrevWaveNo   = OH.PickBatchNo,
        PickBatchId  = null,
        PickBatchNo  = null,
        Status       = 'N',
        WaveFlag     = 'R', /* Removed from wave, so do not automatically wave again */
        ModifiedDate = @vModifiedDate,
        ModifiedBy   = @UserId
    from OrderHeaders OH
      join #OrdersToUnwave OU on (OU.OrderId = OH.OrderId)
      left outer join WaveDetails WD on (OH.OrderId = WD.OrderId)
    where (WD.OrderDetailId is null)

  /*--------- Audit Trail ---------------*/
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, UDF1, BusinessUnit, UserId)
    select 'PickTicket', OrderId, PickTicket, @vAuditActivity, RecordId, @BusinessUnit, @UserId from #OrdersToUnWave
    union all
    select 'Wave', WaveId, WaveNo, @vAuditActivity, RecordId, @BusinessUnit, @UserId from #OrdersToUnWave;

  /* Build comment */
  update ttAT
  set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'PickTicket', PickTicket, 'Wave', WaveNo, 'SKU', SKU, 'HostOrderLine', HostOrderLine, null, null, null, null)
  from @ttAuditTrailInfo ttAT
    join #OrdersToUnWave OTW on (ttAT.UDF1 = OTW.RecordId);

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /*------------------------- Post process - Sorter/Exports -------------------------*/

  /* Process each wave type and Wave */
  select @vRecordId = 0;
  while exists (select * from @ttWaves where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId = RecordId,
                   @vWaveId   = EntityId,
                   @vWaveNo   = EntityKey
      from @ttWaves
      where (RecordId > @vRecordId)
      order by RecordId;

      select @vWaveType = WaveType from Waves where (WaveId = @vWaveId);

      select @vControlCategory = 'PickBatch_' + @vWaveType;

      select @vSorterIntegration    = dbo.fn_Controls_GetAsString(@vControlCategory, 'SorterIntegration', 'N' /* No */, @BusinessUnit, null /* UserId */),
             @vExportStatusOnUnWave = dbo.fn_Controls_GetAsString(@vControlCategory, 'ExportStatusOnUnwave', 'N' /* No */, @BusinessUnit, null /* UserId */);

      /* If Sorter is used for Wave processing, then update the Order with #DeletedDetails */
      if (@vSorterIntegration = 'Y'/* Yes */)
        exec pr_Sorter_DeleteWaveDetails @vWaveId, @BusinessUnit, @UserId;

      /* Get all the orders of this wave to export */
      delete from #OrdersUnWaved;
      insert into #OrdersUnWaved (OrderId)
        select OrderId from #OrdersToUnwave where (WaveId = @vWaveId);

      /* Send PT Status update to Host that Order is unwaved */
      if (@vExportStatusOnUnWave = 'Y' /* Yes */)
        exec pr_OrderHeaders_ExportStatus null /* WaveId */, null /* OrderId */, Default /* ReasonCode */,
                                         '#OrdersUnWaved', @BusinessUnit, @UserId;

      /* Update counts on Wave */
      exec pr_PickBatch_UpdateCounts @vWaveNo, 'OTL'/* Orders, Tasks, LPNs */;

      /* On reallocation, the Wave status may change, so recompute after allocation */
      exec pr_PickBatch_SetStatus @vWaveNo, @ModifiedBy = @UserId;
    end

  /* Invoke proc to finalize unwave orders */
  exec pr_OrderHeaders_FinalizeUnWave @Businessunit, @UserId;

  /* Mark the wave as cancelled if there are no more orders */
  if (@CancelWaveIfEmpty = 'Y' /* Yes */)
    update W
    set Status       = 'X', /* Cancelled */
        WaveStatus   = 'X', /* Cancelled */
        ModifiedDate = current_timestamp,
        ModifiedBy   = coalesce(@UserId, System_User)
    from Waves W
      join @ttWaves ttW on (W.WaveId =  ttW.EntityId) and (W.NumOrders = 0) and (W.Status <> 'X' /* Cancelled */);

  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_RemoveOrders */

Go
