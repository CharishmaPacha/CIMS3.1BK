/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/09  AJM     pr_OrderHeaders_Action_RemoveOrdersFromWave: Initial revision (CIMSV3-1322)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Action_RemoveOrdersFromWave') is not null
  drop Procedure pr_OrderHeaders_Action_RemoveOrdersFromWave;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Action_RemoveOrdersFromWave: This procedure used to remove
    the selected Orders from their corresponding Waves
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Action_RemoveOrdersFromWave
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vPickTicket                 TPickTicket,
          /* Process variables */
          @vWaveId                     TRecordId,
          @vWaveNo                     TPickBatchNo,
          @vOrdersXML                  TXML,
          @vCancelWaveIfEmpty          TFlag,
          @vWavingLevel                TDescription,
          @vOperation                  TOperation,
          @vValidStatusToUnWaveOrders  TControlValue;

  declare @ttOrdersToUnWave         TOrderDetails,
          @ttTaskDetails            TEntityKeysTable,
          @ttLPNDetailsToUnallocate TEntityKeysTable,
          @ttOrdersToUpdate         TEntityKeysTable;
begin /* pr_OrderHeaders_Action_RemoveOrdersFromWave */
  SET NOCOUNT ON;

  select @vReturnCode        = 0,
         @vRecordsUpdated    = 0,
         @vMessageName       = null,
         @vWaveNo            = '';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Create required hash tables */
  select * into #OrdersToUnWave from @ttOrdersToUnWave;

  /* Get Order and Wave info for selected entities for validation */
  insert into #OrdersToUnWave(OrderId, PickTicket, OrderType, OrderStatus, WaveId, WaveNo, WaveType, WaveStatus, WaveAllocateFlags)
    select OH.OrderId, OH.PickTicket, OH.OrderType, OH.Status, W.WaveId, W.WaveNo, W.WaveType, W.Status, W.AllocateFlags
    from #ttSelectedEntities ttSE
      join OrderHeaders OH on (ttSE.EntityId = OH.OrderId)
      left outer join Waves W on (OH.PickBatchId = W.WaveId);

  set @vTotalRecords = @@rowcount;

  /* Controls */
  select @vCancelWaveIfEmpty = dbo.fn_Controls_GetAsString('RemoveOrdersFromWave', 'CancelWaveIfEmpty', 'Y', @BusinessUnit, null/* UserId */);

  /* Validations */
  exec pr_Waves_RemoveOrders_Validations null, @BusinessUnit, @UserId;

  /* insert all task details to cancel for the selected orders */
  insert into @ttTaskDetails
    select TaskDetailId, 'TaskDetail'
    from TaskDetails TD join #OrdersToUnWave OTW on TD.OrderId = OTW.OrderId
    where (TD.Status in ('N' /* New */, 'O' /* Onhold */));

  /* Cancel all the task details for the corresponding orders. PickBatch_RemoveOrders would not remove
     orders if there are outstanding tasks */
  if (exists(select * from @ttTaskDetails))
    exec pr_Tasks_Cancel @ttTaskDetails, null /* TaskId */, null /* WaveNo */, @BusinessUnit, @UserId, @vMessage out;

  /* Get the list of qualified Orders for further updates */
  insert into @ttOrdersToUpdate (EntityId)
    select OrderId from #OrdersToUnWave;

  /* Void Temp labels  */
  exec pr_OrderHeaders_VoidTempLabels @ttOrdersToUpdate, 'UnwaveOrders', @BusinessUnit, @UserId;

  /* Note: We are not un-allocating the already picked LPN, which doesn't have picks, So need to un allocate them */
  insert into @ttLPNDetailsToUnallocate
    select LPNId, LPNDetailId
    from #OrdersToUnWave OTW
      join LPNDetails LD on (OTW.OrderId = LD.OrderId);

  exec pr_LPNDetails_UnallocateMultiple 'UnwaveOrders', @ttLPNDetailsToUnallocate,
                                        null /* @LPNId */, null /* @LPNDetailId */, @BusinessUnit, @UserId;

  exec pr_Waves_RemoveOrders @vCancelWaveIfEmpty, @vWavingLevel, @Businessunit, @UserId, @vOperation;

  /* Verify how many orders have actually been removed from the wave */
  select @vRecordsUpdated = count(*)
  from #OrdersToUnWave OTW join OrderHeaders OH on (OTW.OrderId = OH.OrderId) and (OH.PickBatchNo is null);

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Action_RemoveOrdersFromWave */

Go
