/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/09  TK      pr_TaskDetails_CancelMultiple: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_CancelMultiple') is not null
  drop Procedure pr_TaskDetails_CancelMultiple;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_CancelMultiple cancel the given task details or task details of the given tasks

  This procedure does the following
  1. Unallocate all the LPN details
  2. Updates task and task detail statuses
  3. Void the ship cartons if all the ship carton details are removed
  4. Cancels print job if the corresponding task is cancelled

  #TaskDetailsToCancel    TTaskInfoTable
  #LPNDetails             TLPNDetails
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_CancelMultiple
  (@Operation          TOperation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @RecountEntities    TFlags     = 'Y' /* Yes */)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vProcName              TName;

  declare @ttLPNsVoided           TLPNsInfo,
          @ttAuditTrailInfo       TAuditTrailInfo,
          @ttShipLabelsToVoid     TEntityKeysTable,
          @ttLPNDetails           TLPNDetails;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vProcName    = object_name(@@ProcId);

  if (object_id('tempdb..#LPNDetails') is null) select * into #LPNDetails from @ttLPNDetails

  /* Create required hash tables */
  if (object_id('tempdb..#EntitiesToRecalc') is null)
    begin
      create table #EntitiesToRecalc (RecalcRecId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'RecalcCounts', '#EntitiesToRecalc';
    end

  /* Delete the task details that are already canceled or completed */
  delete from #TaskDetailsToCancel where TDStatus in ('C', 'X' /* Completed, Canceled */)

  /*--------------- Unallocate LPN Details ---------------*/
  /* Get the LPN details to unallocate
     If a pallet picks is being cancelled then load all the LPN details of LPNs that are on pallet */
  if exists (select * from #TaskDetailsToCancel where TaskSubType = 'P' /* Pallet Pick */)
    insert into #LPNDetails (LPNDetailId)
      select distinct LD.LPNDetailId
      from LPNDetails LD
        join LPNs L on (LD.LPNId = L.LPNId)
        join #TaskDetailsToCancel TDC on (L.PalletId = TDC.PalletId)
      where (TDC.TaskSubType = 'P' /* Pallet Pick */) and
            (TDC.PalletId is not null);

  if exists (select * from #TaskDetailsToCancel where LPNDetailId is not null)
    insert into #LPNDetails (LPNDetailId)
      select distinct LPNDetailId
      from #TaskDetailsToCancel
      where (LPNDetailId is not null) and
            (TaskSubType <> 'P' /* Pallet Pick */);

  /* Invoke procedure to unallocate LPN Details */
  if exists (select * from #LPNDetails)
    exec pr_UnAllocate_LPNDetails 'TaskCancel', @BusinessUnit, @UserId, 'N' /* No - Recount Entities */;

  /* Fetch all the related info of the Task Details */
  update TDC
  set LPN               = L.LPN,
      PalletId          = L.PalletId,
      Pallet            = L.Pallet,
      SKU               = S.SKU,
      PickTicket        = OH.PickTicket,
      TempLabelPalletId = TL.PalletId,
      TempLabelPallet   = TL.Pallet
  from #TaskDetailsToCancel TDC
    join LPNs L  on (TDC.LPNId = L.LPNId)
    join LPNs TL on (TDC.TempLabelId = TL.LPNId)
    join SKUs S  on (TDC.SKUId = S.SKUId)
    join OrderHeaders OH on (TDC.OrderId = OH.OrderId);

  /*--------------- Task Detail Updates ---------------*/
  /* Mark the task details as canceled and clear dependency flags. In some cases
     we are cancelling the TD even when LPNDetail has not been unallocated. So, this
     is a precautionary measure to make sure there are not R/PR LDs */
  update TD
  set Status          = case when UnitsCompleted > 0 then 'C' /* Completed */ else 'X' /* Canceled */ end,
      DependencyFlags = case when DependencyFlags in ('R', 'S' /* Replenish, Short */) then '-' end,
      DependentOn     = null,
      ModifiedDate    = getdate(),
      ModifiedBy      = @UserId
  from TaskDetails TD
    join #TaskDetailsToCancel TDC on (TD.TaskDetailId = TDC.TaskDetailId)
    left outer join LPNDetails LD on (TD.LPNDetailId = LD.LPNDetailId) and
                                     (LD.OnhandStatus in ('R', 'PR' /* Reserved, Pending Reservation */))
  where (LD.LPNDetailId is null);  -- Make sure there are no reseved LPN Details

  /*--------------- Ship Carton Updates ---------------*/
  /* Delete the Shipping LPNs details for the task details that are being cancelled */
  delete LD
  from #TaskDetailsToCancel TDC
    join LPNDetails LD on (LD.LPNDetailId = TDC.TempLabelDetailId)
    join LPNs        L on (L.LPNId = LD.LPNId) and (L.Status = 'F' /* New Temp */);

  /* If all the ship carton details are deleted then mark ship carton as voided */
  update L
  set Status       = 'V' /* void */,
      OrderId      = null,
      LoadId       = null,
      LoadNumber   = null,
      ShipmentId   = 0,
      BoL          = null,
      PalletId     = null,
      Pallet       = null,
      PickBatchId  = null,
      PickBatchNo  = null,
      AlternateLPN = null
  output inserted.LPNId, inserted.LPN, deleted.PalletId, deleted.Pallet
  into @ttLPNsVoided (LPNId, LPN, PalletId, Pallet)
  from LPNs L
    join #TaskDetailsToCancel TDC on (L.LPNId = TDC.TempLabelId)
    left outer join LPNDetails LD on (L.LPNId = LD.LPNId)
  where (LD.LPNDetailId is null); -- Only when all the details of ship carton are deleted above

  /* If there are details in the ship carton are Reserved and LPN status is picking then mark the LPN as picked */
  update L
  set Status = 'K' /* Picked */
  from LPNs L
    join #TaskDetailsToCancel TDC on (L.LPNId = TDC.TempLabelId)
    left outer join LPNDetails LD on (L.LPNId = LD.LPNId) and
                                     (LD.OnhandStatus = 'U' /* Unavailable */)
  where (LD.LPNDetailId is null) and -- Only when there are not un-avalilable lines
        (L.Status = 'U' /* Picking */);

  /* When ship cartons are voided then we need to void corresponding shiplabel as well */
  insert into @ttShipLabelsToVoid (EntityId)
    select LPNId
    from @ttLPNsVoided ttLV
      join ShipLabels SL on (ttLV.LPNId = SL.EntityId) and
                            (SL.Status = 'A'/* Active */);

  /* Invoke procedure to void ship lables */
  if exists (select * from @ttShipLabelsToVoid)
    exec pr_Shipping_VoidShipLabels null /* OrderId */, null /* LPNId */, @ttShipLabelsToVoid, @BusinessUnit, 'N' /* RegenerateLabel - No */;

  /*--------------- Recounts ---------------*/
  /* Recount required entities */
  insert into #EntitiesToRecalc (EntityType, EntityId, EntityKey, RecalcOption, Status, ProcedureName, BusinessUnit)
    select distinct 'Task', TaskId, null, 'S' /* Status */, 'N', @vProcName, @BusinessUnit from #TaskDetailsToCancel
    union all
    select distinct 'LPN', TempLabelId, TempLabel, 'C' /* Counts */, 'N', @vProcName, @BusinessUnit from #TaskDetailsToCancel TDC left outer join @ttLPNsVoided L on (TDC.TempLabelId = L.LPNId) where L.LPNId is null -- Recount only the LPNs that are not voided
    union all
    select distinct 'Pallet', PalletId, Pallet, 'C' /* Counts */, 'N', @vProcName, @BusinessUnit from @ttLPNsVoided
    union all
    select distinct 'Order', OrderId, PickTicket, 'C' /* Counts */, 'N', @vProcName, @BusinessUnit from #TaskDetailsToCancel
    union all
    select distinct 'Wave', WaveId, WaveNo, '$CS' /* defer Counts & Status */, 'N', @vProcName, @BusinessUnit from #TaskDetailsToCancel

  /* Recount Entities that are to be processed immediately */
  if (@RecountEntities = 'Y' /* Yes */)
    exec pr_Entities_RecalcCounts @BusinessUnit, @UserId;

  /*--------------- PrintJob Updates - This has to be done strictly after Tasks recount ---------------*/
  /* Cancel the Task PrintJobs */
  update P
  set PrintJobStatus = 'X' /* Canceled */
  from PrintJobs P
    join #TaskDetailsToCancel TDC on P.EntityId = TDC.TaskId
    join Tasks T on T.TaskId = TDC.TaskId
  where (P.EntityType = 'Task') and
        (T.Status = 'X' /* Canceled */) and
        (P.PrintJobStatus not in ('C'/* Completed */, 'X'/* Canceled */));

  /*--------------- Audit Trail ---------------*/
  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, BusinessUnit, UserId, UDF1, ActivityType)
    select 'LPN', TemplabelId, TempLabel, @BusinessUnit, @UserId, RecordId,
           case when PalletId is not null then 'AT_TaskDetailCancel_ShipCartonOnPallet'
                else 'AT_TaskDetailCancel_ShipCarton'
           end
    from #TaskDetailsToCancel TDC where (TempLabelId is not null)
    union all
    select 'Task', TaskId, cast(TaskId as varchar(max)), @BusinessUnit, @UserId, RecordId, 'AT_TaskDetailCancel' from #TaskDetailsToCancel;

  /* Build AT Comment */
  update ttAT
  set Comment = case when ActivityType = 'AT_TaskDetailCancel' then
                  dbo.fn_Messages_BuildDescription(ActivityType, 'LPN', LPN, 'PickTicket', PickTicket, 'DisplaySKU', SKU, 'Units', cast(TDQuantity as varchar) + ' Unit(s)', null, null, null, null)
                     when ActivityType like 'AT_TaskDetailCancel_ShipCarton%' then
                  dbo.fn_Messages_BuildDescription(ActivityType, 'LPN', TempLabel, 'PickTicket', PickTicket, 'DisplaySKU', SKU, 'Units', cast(TDQuantity as varchar) + ' Unit(s)', 'Pallet', TempLabelPallet, null, null)
                end
  from @ttAuditTrailInfo ttAT
    join #TaskDetailsToCancel TDC on (ttAT.UDF1 = TDC.RecordId);

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Process deferred entries */
  if (@RecountEntities = 'Y' /* Yes */)
    exec pr_Entities_RequestRecalcCounts null /* EntityType */, @BusinessUnit = @BusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_TaskDetails_CancelMultiple */

Go
