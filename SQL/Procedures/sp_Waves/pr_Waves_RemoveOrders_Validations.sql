/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/30  TK      pr_Waves_ReturnOrdersToOpenPool: Initial Revision
                      pr_PickBatch_Cancel: #OrdersToUnWave changed to use TOrderDetails
                      pr_Waves_RemoveOrders_Validations: Skip some validations for ReturnOrdersToPool operation
                      pr_Waves_RemoveOrders: Bug fixes (BK-720)
  2021/11/26  RKC     pr_Waves_RemoveOrders_Validations: Don't allow users to remove orders if they selected bulk pull orders (CIMSV3-1725)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_RemoveOrders_Validations') is not null
  drop Procedure pr_Waves_RemoveOrders_Validations ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_RemoveOrders_Validations : Validates the orders given in #OrdersToUnWave
   to see if they can be removed from their corresponding Waves. Some of the
   validations are disregarded for some operations. Also some validations are to be done
   after the process has taken place before the final removal.

  #OrdersToUnWave : TOrderDetails
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_RemoveOrders_Validations
  (@Operation          TOperation = 'Wave_RemoveOrders',
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,

          @vValidWaveStatusesToRemove  TControlValue,
          @vValidOrderStatusToUnWave   TControlValue;

  declare @ttOrders                    TEntityKeysTable,
          @ttTasks                     TEntityKeysTable;

begin
  select @vValidOrderStatusToUnWave  = dbo.fn_Controls_GetAsString('Wave_RemoveOrder', 'ValidOrderStatuses', 'W' /* Waved */, @BusinessUnit, @UserId),
         @vValidWaveStatusesToRemove = dbo.fn_Controls_GetAsString('Wave_RemoveOrder', 'ValidWaveStatuses',  'NRPUKACS'/* New, ReadyToPick, Picking,Paused, Picked, Packing, Packed, Staged */, @BusinessUnit, null/* UserId */);

  select OrderId, PickTicket, OrderStatus, WaveNo, WaveStatus,
         case when (coalesce(OTW.WaveId, 0) = 0)                                       then 'Wave_RemoveOrders_NotOnWave'
              when (dbo.fn_IsInList(OTW.WaveStatus, @vValidWaveStatusesToRemove) = 0)  then 'Wave_RemoveOrders_InvalidWaveStatus'
              when (dbo.fn_IsInList(OTW.OrderStatus, @vValidOrderStatusToUnWave) = 0)  then 'Wave_RemoveOrders_InvalidOrderStatus'
              when (dbo.fn_IsInList(OTW.OrderType, 'B') > 0)                           then 'Wave_RemoveOrders_BulkOrderNotValid'
              when (dbo.fn_IsInList(OTW.OrderType, 'R,RU,RP') > 0)                     then 'Wave_RemoveOrders_ReplenishNotValid'
              -- this is typically used before Orders are actually removed and hence UnitsAssigned would still be greater than zero
              --when (OTW.UnitsAssgined > 0)                                       then 'Wave_RemoveOrders_UnitsReserved'
              when (@Operation in ('UnWaveDisQualifiedOrders', 'Wave_ReturnOrdersToOpenPool'))
                                                                                       then null -- the below validations are disregarded when removing orders during allocation
              when (OTW.WaveAllocateFlags = 'I' /* InProgress */)                      then 'Wave_RemoveOrders_AllocationInProgress'
              when (OTW.WaveStatus not in ('N' /* New */)) and
              (dbo.fn_Permissions_IsAllowed(@UserId, 'Waves.Pri.RemoveOrdersFromReleasedWave') = '0')
                                                                                       then 'Wave_RemoveOrders_WaveAlreadyReleased'
         end ErrorMessage
  into #InvalidOrders
  from #OrdersToUnWave OTW

  /* Get the status description for the error message */
  update #InvalidOrders
  set OrderStatus = dbo.fn_Status_GetDescription('Order', OrderStatus, @BusinessUnit),
      WaveStatus  = dbo.fn_Status_GetDescription('Wave', WaveStatus, @BusinessUnit);

  /* Exclude the orders that are determined to be invalid above */
  delete from OTW
  output 'E', IO.OrderId, IO.PickTicket, IO.ErrorMessage, IO.OrderStatus, IO.WaveNo, IO.WaveStatus
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2, value3, value4)
  from #InvalidOrders IO join #OrdersToUnWave OTW on IO.OrderId = OTW.OrderId
  where (IO.ErrorMessage is not null);

  /* Even if user is trying to remove orders from a wave, no matter what the status of the wave is
     we have to ensure that the user has canceled the ship cartons first of those Orders */
  delete from OTW
  output 'E', 'Wave_RemoveOrders_CancelShipCartons', deleted.OrderId, deleted.PickTicket, L.LPN, deleted.WaveNo
  into #ResultMessages (MessageType, MessageName, EntityId, EntityKey, Value2, Value3)
  from #OrdersToUnWave OTW
    join LPNs L on (L.OrderId = OTW.OrderId)
  where (L.Status = 'F' /* New Temp */);

  return(coalesce(@vReturnCode, 0));
end  /* pr_Waves_RemoveOrders_Validations */

Go
