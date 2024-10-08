/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/26  TK      pr_Pallets_ClearCart: Do not clear cart if there is inventory picked into cart position (BK-532)
  2019/08/11  MS      pr_Pallets_ClearCart: Clear the empty Totes from the cart , if they are not used (CID-881)
  2016/11/18  RV/TK   pr_Pallets_ClearCart: Intial Revision
              TK      pr_Pallets_ClearCartPositionQty: Initial Revision
                      pr_Pallets_UnassignFromTask: Initial Revision (HPI-917)
  2016/10/12  KL      Added new procedure pr_Pallets_ClearCart.
                        pr_Pallets_Modify: Invoked pr_Pallets_ClearCart procedure (HPI-850)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_ClearCart') is not null
  drop Procedure pr_Pallets_ClearCart ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_ClearCart: This proc does the following

  a. If there is a task associated with the Pallet and the task is not started yet but task is built to cart then
     - remove the task, pallet association
     - remove all cartons of the built cart and clear cart position from the temp labels that are removed.
  b. If the task has been started, but nothing picked yet
     - does as in a.
     - reverts task back to Ready to Start
  c. If task has been completed and the Pallet is not empty
     - If there are temp labels, then remove them from the cart.
     - If there is inventory then do adjust out inventory using a new reason code.
  d. Final step if Pallet is empty
     - clears alternate LPN on cart positions.
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_ClearCart
  (@ttPallets       TEntityKeysTable ReadOnly,
   @UserId          TUserId,
   @BusinessUnit    TBusinessUnit,
   @Message         TMessage = null output)
as
  declare @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vLPNDetailId         TRecordId,
          @vCurrentSKUId        TRecordId,
          @vCurrentSKU          TSKU,
          @vLPNDetailInnerPacks TInnerPacks,
          @vLPNDetailQuantity   TQuantity,
          @vReasonCode          TReasonCode,

          @vTaskId              TRecordId,
          @vTaskStatus          TStatus,
          @vCompletedCount      TQuantity,
          @vPalletId            TRecordId,
          @vPallet              TPallet,
          @vPalletType          TTypeCode,
          @vPalletStatus        TStatus,
          @vPalletQuantity      TQuantity,
          @vCartsCount          TCount,
          @vCartsUpdated        TCount,
          @vEntity              TEntity,
          @vAuditActivity       TActivityType,
          @vAuditRecordId       TRecordId,
          @vRecordId            TRecordId,
          @vLPNRecordId         TInteger,
          @vReturnCode          TInteger,
          @vMessageName         TMessageName;
begin
  SET NOCOUNT ON;

  select @vReturnCode         = 0,
         @vMessageName        = null,
         @vRecordId           = 0, --For inner loop
         @vCartsUpdated       = 0,
         @vReasonCode         = '130' /* Clear Cart */,
         @vEntity             = 'Pallet',
         @vAuditActivity      = 'ClearedCart';

  select @vCartsCount = count(*)
  from @ttPallets;

  /* Loop through all the records to call UpdateCount Procedure */
  while exists(select * from @ttPallets where RecordId > @vRecordId)
    begin
      select top 1 @vPallet    = EntityKey,
                   @vRecordId  = RecordId,
                   @vTaskId    = null /* Initialize */
      from @ttPallets
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get the Pallet details */
      select @vPalletId       = PalletId,
             @vPalletStatus   = Status,
             @vPalletType     = PalletType,
             @vPalletQuantity = Quantity
      from Pallets
      where (Pallet       = @vPallet) and
            (BusinessUnit = @BusinessUnit);

      if (@vPalletType <> 'C' /* Cart */) --We can not process the Pallets other than Carts
        continue;

      /* If there is inventory that is picked into cart position then do not clear that cart */
      if exists (select * from LPNs where PalletId = @vPalletId and LPNType = 'A' /* Cart */ and Status = 'K' /* Picked */)
        begin
          insert into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
            select 'E', @vPalletId, @vPallet, 'ClearCart_CartPositionsHasPickedInventory';

          continue;
        end

      /* Try to identify the Task the pallet is associated with */
      select top 1 @vTaskId         = TaskId,
                   @vTaskStatus     = Status,
                   @vCompletedCount = CompletedCount
      from Tasks
      where (PalletId = @vPalletId) and
            (Status  <> 'X' /* Cancelled */) --Assume that Cart/Pallet should associate with only one Task
      order by case when Status in ('I', 'N') then 1
                    else /* Completed */ 2
               end,
               TaskId desc;  -- To make sure we get the latest task first

      /* There is a task associated with the Pallet and the task is NotStarted/Started but nothing picked */
      if (@vTaskStatus in ('N', 'I' /* ReadyToStart, InProgress */) and (@vCompletedCount = 0))
        begin
          /* Unassign Pallet form Task */
          exec pr_Pallets_UnassignFromTask @vPalletId, @vTaskId, @BusinessUnit, @UserId;

          /* Clear alternate LPN on Temp Labels and unassign them from Pallet */
          /* With the recent enhancements we shoudn't clear the alternate LPN on the Temp lpns */
          update LPNs
          set PalletId     = null,
              Pallet       = null
          where (PalletId = @vPalletId     ) and
                (LPNType  <> 'A' /* Cart */);

          /* Clear alternate LPN on Cart positions */
          update LPNs
          set AlternateLPN = null
          where (PalletId = @vPalletId) and
                (LPNType  = 'A' /* Cart */);
        end
      else
      /* If task has been completed and the Pallet is not empty then remove the templabels from the cart
         then adjust the LPNs with new reason code */
      if ((@vTaskStatus = 'C' /* Completed */) and (@vPalletStatus <> 'E' /* Empty */))
        begin
          /* clear Wave info on Pallet */
          update Pallets
          set PickBatchId = null,
              PickBatchNo = null
          where (PalletId   = @vPalletId) and
                (PalletType = 'C' /* Cart */);

          /* clear quantities on the cart positions */
          exec pr_Pallets_ClearCartPositionQty @vPalletId, null /* Options */, @vReasonCode, @BusinessUnit, @UserId;

          /* Clear alternate LPN on Temp Labels and unassign them from Pallet */
          update L1
          set L1.AlternateLPN = null,
              L1.PalletId     = null,
              L1.Pallet       = null
          from LPNs L1
            join LPNs L2 on (L1.LPN = L2.AlternateLPN)
          where (L2.PalletId = @vPalletId    ) and
                (L2.LPNType  = 'A' /* Cart */) and
                (L2.AlternateLPN is not null );

          /* Clear alternate LPN on Cart positions */
          update LPNs
          set AlternateLPN = null
          where (PalletId = @vPalletId) and
                (LPNType = 'A' /* Cart */);
        end
      else
      /* If pallet is not asociated with any task and had no inventory then clear alternate LPN on cart positions */
      if ((@vPalletStatus = 'E') and (@vTaskId is null))
        begin
          /* Clear Alternate LPN on the cart positions */
          update LPNs
          set AlternateLPN = null
          where (PalletId = @vPalletId) and
                (AlternateLPN is not null);

          /* Remove empty totes from the Cart */
          update LPNs
          set PalletId = null,
              Pallet   = null
          where (PalletId = @vPalletId) and
                (LPNType  = 'TO') and
                (Quantity = 0);
        end

      /* get the updated counts */
      set @vCartsUpdated = @vCartsUpdated + 1;

      /* Calling the procedure */
      exec pr_Pallets_UpdateCount @vPalletId, @vPallet, '*' /* UpdateOption */

      /* log Audit Trail */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @PalletId      = @vPalletId,
                                @BusinessUnit  = @BusinessUnit,
                                @AuditRecordId = @vAuditRecordId output;
    end /* While Loop */

  /* Based upon the number of Pallets that have been modified, give an appropriate message */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, 'ClearCart', @vCartsUpdated, @vCartsCount;

end/* pr_Pallets_ClearCart */

Go
