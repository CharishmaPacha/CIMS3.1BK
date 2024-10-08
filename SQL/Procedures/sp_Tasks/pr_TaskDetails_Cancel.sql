/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/09  TK      pr_TaskDetails_CancelMultiple: Initial Revision
  2021/03/13  TK      pr_TaskDetails_Cancel: Clear shipmentId and BoL on ship carton void (HA-2102)
  2021/02/04  VS      pr_TaskDetails_Cancel: Added parameter as default for temptable (BK-126)
  2020/09/03  RKC     pr_TaskDetails_Cancel: Commented the code updating the pallet info as null on Voided LPNs this
  2019/08/28  RKC     pr_TaskDetails_Cancel:Pass the UnitsToPick instead of Quantity to log Audittrails (CID-814)
              AY      pr_TaskDetails_Cancel: Code cleanup and changes to use TD.LPNDetailId which we did not have before.
  2019/05/01  MS      pr_TaskDetails_Cancel : Made changes the clear the pallet info on NewtempLPN if taskdetail is cancelled (S2GCA-673)
  2018/05/23  MJ      pr_TaskDetails_Cancel: Changed the callers based on the recent parameters (S2G-443)
  2018/05/18  RT      pr_TaskDetails_Cancel: Updating LoadId and LoadNumber as null to clear the voided LPNs in the LPNs sub grid on the Loads page(S2G-784)
  2018/03/09  RV      pr_TaskDetails_Cancel: Made changes to void the ship labels for cubed cartons if exists while cancel the Task Details (S2G-380)
  2017/07/28  RV      pr_TaskDetails_Cancel: BusinessUnit and UserId passed to activity log procedure
                        to log activities (HPI-1584)
  2017/07/07  RV      pr_TaskDetails_Cancel: Procedure id is passed to logging procedure to
                        determine this procedure required to logging or not from debug options (HPI-1584)
  2017/06/13  KL      pr_TaskDetails_Cancel: Added condition to select activity message (HPI-431)
  2016/09/17  RV      pr_TaskDetails_Cancel: Check validation before close the Task DetailID (HPI-694)
  2016/08/31  TK      pr_TaskDetails_Cancel: Bug Fix to retrieve TempLabel details (HPI-556)
  2015/08/30  NY      pr_TaskDetails_Cancel: Log AT on temp label when we cancel task detail (HPI-431)
  2016/08/11  TK      pr_TaskDetails_Cancel: Clear Temp label from Pallet if it is Voided (HPI-461)
                                             Clear alternate LPN on Cart position as well (HPI-463)
  2016/08/09  TK      pr_TaskDetails_Cancel: Clear Temp label from Pallet if it is Voided (HPI-461)
  2016/08/04  TK      pr_TaskDetails_Cancel: Bug fix to consider Passed in TaskDetailId instead of TaskdetailId from LPN Tasks (HPI-420)
  2015/11/25  RV      pr_TaskDetails_Cancel: After cancel the task detail, if there is no task detail is
                        available to pick then the LPN is marked as Picked (ACME-205)
  2015/10/29  TK      pr_TaskDetails_Cancel: Update PickBatchNo to null on cancelling the Task(ACME-340)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_Cancel') is not null
  drop Procedure pr_TaskDetails_Cancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_Cancel:
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_Cancel
  (@TaskId               TRecordId,
   @TaskDetailId         TRecordId,
   @UserId               TUserId)
As
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vTaskId             TRecordId,

          @vOrderId            TRecordId,
          @vOrderDetailId      TRecordId,
          @vSKUId              TRecordId,
          @vTDQuantity         TQuantity,
          @vTDUnitsToPick      TQuantity,
          @vTaskDetailId       TRecordId,
          @vTempLabelId        TRecordId,
          @vTempLabel          TLPN,
          @vTempLabelPalletId  TRecordId,
          @vTempLabelDetailId  TRecordId,
          @vTempLabelCartPosId TRecordId,
          @vTempLabelCartPos   TLPN,
          @vTaskDetailStatus   TStatus,
          @vAuditActivity      TActivityType,

          @vXmlData            TXML,
          @vTaskDetailsXml     TXML,
          @vLPNDetailsXml      TXML,
          @vBusinessUnit       TBusinessUnit;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* If the task detail already cancelled then exit */
  select @vTaskDetailStatus = Status
  from TaskDetails
  where TaskDetailId = @TaskDetailId;

  if (@vTaskDetailStatus in ('C', 'X')) -- already completed or cancelled, exit
    goto ExitHandler;

  /* Get the Temp Label Details */
  /* We need void TempLabel/delete its details, we will delete associated Temp Label details on Task Detail cancel
     on the other hand if a task detail is partially picked then we will be having two different details for one OrderDetailId
     one with OnhandStatus 'Reserved' & other with Unavailable then we need to delete the Unavailable detail line */
  select @vTempLabelId       = TD.TempLabelId,
         @vTempLabelDetailId = TD.TempLabelDetailId,
         @vTaskId            = TD.TaskId,
         @vTaskDetailId      = TD.TaskDetailId,
         @vTaskDetailStatus  = TD.Status,
         @vOrderId           = TD.OrderId,
         @vOrderDetailId     = TD.OrderDetailId,
         @vSKUId             = TD.SKUId,
         @vTDQuantity        = TD.Quantity,
         @vTDUnitsToPick     = TD.UnitsToPick,
         @vTempLabelCartPos  = L.AlternateLPN,
         @vTempLabel         = L.LPN,
         @vBusinessUnit      = TD.BusinessUnit
  from TaskDetails TD join LPNs L on TD.TempLabelId = L.LPNId
  where (TD.TaskDetailId = @TaskDetailId) and
        (TD.TaskId       = @TaskId      );

  /* Close the Task Detail */
  /* For some wave types we won't generate Temp Labels and hence cancel Task Detail directly */
  if (@TaskDetailId is not null) and (coalesce(@vTaskDetailStatus, '') not in ('C', 'X'))
    exec pr_TaskDetails_Close @TaskDetailId, null /* LPNDetailId */, @UserId, null /* Operation */;

  /* If there is no temp label associated with the task detail, no further updates are required */
  if (@vTempLabelId is null) goto ErrorHandler;

  /* Get LPNId of Cart Position log AT */
  if (@vTempLabelCartPos  is not null)
    select @vTempLabelCartPosId = LPNId
    from LPNs
    where (LPN          = @vTempLabelCartPos) and
          (BusinessUnit = @vBusinessUnit);

  /* Delete the Details of the TempLabel generated */
  exec pr_LPNDetails_Delete @vTempLabelDetailId;

  /* If there are no more task details available to pick into the TempLabel, then marked it as Picked */
  if (not exists (select * from LPNDetails where (LPNId = @vTempLabelId) and (OnhandStatus = 'U' /* Unavailable */)))
    update LPNs
    set status = 'K' /* Picked */
    where (LPNId = @vTempLabelId) and (Status = 'U' /* Picking */);

  /* If there are no LPN Details then Void Temp Label */
  if (not exists(select * from LPNDetails where LPNId = @vTempLabelId))
    begin
      update L
      set @vTempLabelPalletId
                       = PalletId,
          @vTempLabelCartPos
                       = AlternateLPN,
          Status       = 'V' /* void */,
          OrderId      = null,
          LoadId       = null,
          LoadNumber   = null,
          ShipmentId   = 0,
          BoL          = null,
          --PalletId     = null, /* RKC_ This can be handled by pr_LPNs_SetPallet,if you pass the NewPalletId as null updating the null as pallet */
          --Pallet       = null,
          PickBatchId  = null,
          PickBatchNo  = null,
          AlternateLPN = null
      from LPNs L
      where (LPNId = @vTempLabelId);

      /* We need to Void the ShipLabels for the LPNs whose labels already inserted into ShipLabels table.
         Here we can not call with MessageName as output parameter, why because success message also returned from the proc */
      if (exists(select EntityKey from ShipLabels where EntityKey = @vTempLabel and Status = 'A'))
        exec pr_Shipping_VoidShipLabels null /* OrderId */, @vTempLabelId, default, @vBusinessUnit, default /* RegenerateLabel - No */, @vMessageName;

      /* Clear alternate LPN on Cart Position */
      if (@vTempLabelCartPos is not null)
        update LPNs
        set AlternateLPN = null
        where (LPN = @vTempLabelCartPos);

      /* Remove LPN from Cart as the Temp Label is voided */
      if (@vTempLabelPalletId is not null)
        exec pr_LPNs_SetPallet @vTempLabelId, null, @UserId;
    end
  else
    /* Recount if there exists Details */
    exec pr_LPNs_Recount @vTempLabelId;

  /* Insert Audit Trail on templables */
  /* We dont need to log the audit information if it is other than pick to ship wave or if there is no templabel */
  if (coalesce(@vTempLabelId, 0) <> 0)
    begin
      if (coalesce(@vTempLabelCartPosId, 0) <> 0)
        select @vAuditActivity = 'TaskDetailCancel'
      else
        select @vAuditActivity = 'TaskDetailCancel_NoCartPosition'

      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @LPNId        = @vTempLabelId,
                                @SKUId        = @vSKUId,
                                @OrderId      = @vOrderId,
                                @ToLPNId      = @vTempLabelCartPosId,
                                @Quantity     = @vTDUnitsToPick, -- Units that are shorted
                                @BusinessUnit = @vBusinessUnit;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_TaskDetails_Cancel */

Go
