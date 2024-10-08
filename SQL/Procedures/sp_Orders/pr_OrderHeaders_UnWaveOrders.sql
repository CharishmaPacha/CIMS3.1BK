/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/24  VS      pr_OrderHeaders_UnWaveOrders: Removed order from wave Validate based on operation (BK-475)
  2021/08/18  VS      pr_OrderHeaders_DisQualifiedOrders, pr_OrderHeaders_Modify, pr_OrderHeaders_UnWaveOrders:
  2021/05/06  TK      pr_OrderHeaders_UnWaveOrders: Do not remove orders from wave if allocation is in progress (HA-2746)
  2021/04/22  RV      pr_OrderHeaders_UnWaveOrders: Bug fixed to unallocate the picked LPNs, which are not having picks (HA-2375)
  2021/03/22  RKC     pr_OrderHeaders_UnWaveOrders: Made changes to not allow user to Remove orders from the Wave if the
                      pr_OrderHeaders_UnWaveOrders: Enhanced to void the temp lpns on removing order from wave and return the result messages (HA-1306)
  2020/05/31  TK      pr_OrderHeaders_UnWaveOrders: Several corrections (HA-696)
                      pr_OrderHeaders_UnWaveOrders: Code optimization
  2017/06/21  KL      pr_OrderHeaders_UnWaveOrders: Exclude to insert downloaded, new and cancelled orders (HPI-833)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_UnWaveOrders') is not null
  drop Procedure pr_OrderHeaders_UnWaveOrders;
Go
/*------------------------------------------------------------------------------
  Proc  pr_OrderHeaders_UnWaveOrders: Orders on a wave that has been released
    cannot be removed from the Waves from Manage Waves. And like at HPI, an
    order cannot be updated once it is on a wave that is released. Therefore, we
    have an action to Unwave Orders.

  Things to do on Unwave (based upon user options)
  a. Cancel any pick tasks that are not yet picked.
  b. unallocate any picked inventory -- FUTURE, not being done now.
  c. Re-wave it (meaning reset the WaveFlag from R to '' so that it automatically waves again) - FUTURE, not being done now.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_UnWaveOrders
  (@OrdersToUnWave  TEntityKeysTable readonly,
   @UserId          TUserId,
   @BusinessUnit    TBusinessUnit,
   @Operation       TOperation = null,
   @Message         TMessage = null output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vRecordId                    TRecordId,

          @vEntity                      TEntity  = 'Order',
          @vOrderId                     TRecordId,
          @vOrdersXML                   TXML,
          @vOrdersCount                 TCount,
          @vOrdersUpdated               TCount,

          @vWaveNo                      TPickBatchNo,
          @vWavingLevel                 TVarchar,
          @vCancelWaveIfEmpty           TFlag,
          @vValidStatusToUnWaveOrders   TControlValue;

  declare @ttOrdersToUnWave table (OrderId             TRecordId,
                                   PickTicket          TPickTicket,
                                   OrderStatus         TStatus,
                                   WaveId              TRecordId,
                                   WaveNo              TWaveNo,
                                   WaveStatus          TStatus,
                                   WaveAllocateFlags   TFlags,
                                   RecordId            TRecordId  identity (1,1));

  declare @ttTaskDetails            TEntityKeysTable,
          @ttLPNDetailsToUnallocate TEntityKeysTable,
          @ttOrdersToUpdate         TEntityKeysTable,
          @ttResultMessages         TResultMessagesTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode         = 0,
         @vMessageName        = null,
         @vCancelWaveIfEmpty  = 'Y',
         @vWaveNo             = '';

  /* Create temporary table if do not exist from callers
     Since this is called from Allocation which does not use ResultMessages */
  if (object_id('tempdb..#ResultMessages') is null) select * into #ResultMessages from @ttResultMessages;

  select @vValidStatusToUnWaveOrders = dbo.fn_Controls_GetAsString('UnWaveOrders', 'InvalidStatuses', 'WA' /* Waved,Allocated */, @BusinessUnit, @UserId);

  insert into @ttOrdersToUnWave(OrderId, PickTicket, OrderStatus, WaveId, WaveNo, WaveStatus, WaveAllocateFlags)
    select OH.OrderId,  OH.PickTicket, OH.Status, OH.PickBatchId, OH.PickBatchNo, W.Status, W.AllocateFlags
    from @OrdersToUnWave OTW
      join OrderHeaders OH on (OTW.EntityKey = OH.PickTicket) and
                              (BusinessUnit  = @BusinessUnit)
      left outer join Waves W on (OH.PickBatchId = W.WaveId);

  set @vOrdersCount = @@rowcount;

  /* Remove all the Orders which are not on any wave */
  delete from OTW
  output 'E', 'Wave_RemoveOrders_NoWave', deleted.OrderId, deleted.PickTicket
  into #ResultMessages (MessageType, MessageName, EntityId, EntityKey)
  from @ttOrdersToUnWave OTW
  where (OTW.WaveId is null);

  /* Remove all the Orders with Invalid Statuses */
  delete from OTW
  output 'E', 'Wave_RemoveOrders_InvalidOrderStatus', deleted.OrderId, deleted.PickTicket, deleted.OrderStatus, deleted.WaveNo
    into #ResultMessages (MessageType, MessageName, EntityId, EntityKey, Value2, Value3)
  from @ttOrdersToUnWave OTW
  where (charindex(OTW.OrderStatus, @vValidStatusToUnWaveOrders) = 0);

  /* Get the status desc - more optimal way of doing rather than using vwOH above */
  update #ResultMessages
  set Value2 = dbo.fn_Status_GetDescription ('Order', Value2, @BusinessUnit)
  where (MessageName = 'Wave_RemoveOrders_InvalidOrderStatus');

  /* Do not allow user to remove orders from wave if allocation is in Progress */
  if (coalesce(@Operation, 'UnWaveOrders') <> 'UnWaveDisQualifiedOrders')
    delete from OTW
    output 'E', 'Wave_RemoveOrders_AllocationInProgress', deleted.OrderId, deleted.PickTicket, deleted.WaveNo
    into #ResultMessages (MessageType, MessageName, EntityId, EntityKey, Value2)
    from @ttOrdersToUnWave OTW
    where (WaveAllocateFlags = 'I' /* InProgress */);

  /* Do not allow user to remove orders from Released Wave unless they have permission to do so
     Note: If we are unwaving the orders as part of allocation as the Order was not completely allocated
           we should allow the order to be removed and hence this validation is not applicable when
           Operation is UnWaveDisQualifiedOrders */
  if (coalesce(@Operation, 'UnWaveOrders') <> 'UnWaveDisQualifiedOrders')
    delete from OTW
    output 'E', 'Wave_RemoveOrders_WaveAlreadyReleased', deleted.OrderId, deleted.PickTicket, deleted.WaveNo
    into #ResultMessages (MessageType, MessageName, EntityId, EntityKey, Value2)
    from @ttOrdersToUnWave OTW
    where (dbo.fn_Permissions_IsAllowed(@UserId, 'Waves.Pri.RemoveOrdersFromReleasedWave') = '0') and
          (OTW.WaveStatus not in ('N' /* New */));

  /* Even if user is trying to remove orders from a wave, no matter what the status of the wave is
     we have to ensure that the user has canceled the ship cartons first */
  delete from OTW
  output 'E', 'Wave_RemoveOrders_CancelShipCartons', deleted.OrderId, deleted.PickTicket, L.LPN, deleted.Waveno
    into #ResultMessages (MessageType, MessageName, EntityId, EntityKey, Value2, Value3)
  from @ttOrdersToUnWave OTW
    join LPNs L on (L.OrderId = OTW.OrderId)
  where (L.status = 'F' /* New Temp */);

  /* Exclude orders which are
     1. Allocated (UnitsAssigned > 0) and no tasks (LPN Reservation used)
     2. Allocated (UnitsAssigned > 0) and have picks (task detail) status in either InProgress or Completed */
  delete from OTW
  output 'E', 'Wave_RemoveOrders_OrderInReservationProcess', deleted.OrderId, deleted.PickTicket
  into #ResultMessages (MessageType, MessageName, EntityId, EntityKey)
  from @ttOrdersToUnWave OTW
    join OrderDetails OD on (OTW.OrderId = OD.OrderId)
    left outer join TaskDetails TD on (OD.OrderDetailId = TD.OrderDetailId)
  where (OD.UnitsAssigned > 0) and
        ((TD.Status is null) or (TD.Status in ('I' /* InProgress */, 'C' /* Completed */)));

  /* insert all task details to cancel for the selected orders */
  insert into @ttTaskDetails
    select TaskDetailId, 'TaskDetail'
    from TaskDetails TD join @ttOrdersToUnWave OH on TD.OrderId = OH.OrderId
    where (TD.Status in ('N' /* New */, 'O' /* Onhold */));

  /* Get the list of qualified Orders for further updates */
  insert into @ttOrdersToUpdate (EntityId)
    select OrderId from @ttOrdersToUnWave;

  /* Void Temp labels  */
  exec pr_OrderHeaders_VoidTempLabels @ttOrdersToUpdate, 'UnwaveOrders', @BusinessUnit, @UserId;

  /* Cancel all the task details for the corresponding orders. PickBatch_RemoveOrders would not remove
     orders if there are outstanding tasks */
  if (exists(select * from @ttTaskDetails))
    exec pr_Tasks_Cancel @ttTaskDetails, null /* TaskId */, null /* WaveNo */, @BusinessUnit, @UserId, @Message out;

  /* Note: We are not un-allocating the already picked LPN, which doesn't have picks, So need to un allocate them */
  insert into @ttLPNDetailsToUnallocate
    select LPNId, LPNDetailId
    from @ttOrdersToUnWave OH
      join LPNDetails LD on (OH.OrderId = LD.OrderId);

  exec pr_LPNDetails_UnallocateMultiple '' /* Operation */,
                                        @ttLPNDetailsToUnallocate,
                                        null /* @LPNId */,
                                        null /* @LPNDetailId */, @BusinessUnit, @UserId;

  /* Loop through all the waves and build the xml and call the remove orders procedure */
  while (exists(select * from @ttOrdersToUnWave where (WaveNo > @vWaveNo)))
    begin
      select top 1 @vRecordId = RecordId,
                   @vWaveNo   = WaveNo
      from @ttOrdersToUnWave
      where (WaveNo > @vWaveNo)
      order by WaveNo;

      /* Build XML of Orders to remove them from the current wave */
      select @vOrdersXML = (select OrderId
                            from @ttOrdersToUnWave
                            where (WaveNo = @vWaveNo)
                            for xml Path('OrderHeader'), root('Orders'));

      exec pr_PickBatch_RemoveOrders @vWaveNo, @vOrdersXML, @vCancelWaveIfEmpty, 'OH', @Businessunit, @UserId, @Operation;
    end

  /* Verify how many orders have actually been removed from the wave */
  select @vOrdersUpdated = count(*)
  from @ttOrdersToUnWave TOH join OrderHeaders OH on TOH.OrderId = OH.OrderId
  where (OH.PickBatchNo is null);

MessageHandler:
  /* Based upon the number of Orders that have been modified, give an appropriate message */
  if (@vOrdersCount > 0) -- when there are any Orders selected return a message to the caller
    exec pr_Messages_BuildActionResponse @vEntity, 'UnwaveOrdersFromWave', @vOrdersUpdated, @vOrdersCount;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_OrderHeaders_UnWaveOrders */

Go
