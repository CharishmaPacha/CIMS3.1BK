/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UnAllocate_LPNDetails') is not null
  drop Procedure pr_UnAllocate_LPNDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_UnAllocate_LPNDetails: Unallocates the LPNDetails given in #LPNDetails
    and updates the LPNDetails and corresponding OrderDetails and then recomputes
    all affected entities LPNs, Pallets, Orders & Wave. This is the core procedure
    that handles unallocation and would be called in various scenarions. This
    procedure does not do anything with the Tasks.

  Process to unallocate LPN Detail:
    a. If unallocating a reserved line then adds unallocated quantity to available line if there is one or
       converts the reserved line to available line, clears reserved quantity & order info on the converted line
    b. If unallocating a pending reserve line then reduces the reserved quantity on available line or directed line
    c. If unallocating a replenish order then cancels the replenish quantity

  #LPNDetails -> TLPNDetails
------------------------------------------------------------------------------*/
Create Procedure pr_UnAllocate_LPNDetails
  (@Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @RecountEntities    TFlags     = 'Y' /* Yes */)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vTranCount             TCount,
          @vProcName              TName,
          @vAuditActivity         TActivityType,
          @vInputParams           TXML,
          @vRecalcCounts          TFlags;

  declare @ttLPNDetails           TLPNDetails,
          @ttAuditTrailInfo       TAuditTrailInfo,
          @ttLPNDetailsUpdated    TEntityKeysTable,
          @ttTDsToRecompute       TRecountKeysTable;
begin /* pr_UnAllocate_LPNDetails */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vTranCount     = @@trancount,
         @vProcName      = object_name(@@ProcId),
         @vAuditActivity = 'AT_UnallocateLPNDetail';

begin try
  if (@vTranCount = 0) begin transaction;

  /* Create required hash tables */
  if (object_id('tempdb..#EntitiesToRecalc') is null)
    begin
      create table #EntitiesToRecalc (RecalcRecId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'RecalcCounts', '#EntitiesToRecalc';

      select @vRecalcCounts = 'Y';
    end

  if (object_id('tempdb..#TDsToRecomputeDependencies') is null)
    select * into #TDsToRecomputeDependencies from @ttTDsToRecompute;

  /* Populate the additional info for processing */
  update TLD
  set LPNId         = L.LPNId,
      LPN           = L.LPN,
      LPNType       = L.LPNType,
      PalletId      = L.PalletId,
      Pallet        = L.Pallet,
      OrderId       = OH.OrderId,
      PickTicket    = OH.PickTicket,
      OrderType     = OH.OrderType,
      WaveId        = OH.PickBatchId,
      WaveNo        = OH.PickBatchNo,
      SKUId         = S.SKUId,
      SKU           = S.SKU,
      OrderDetailId = LD.OrderDetailId,
      OnhandStatus  = LD.OnHandStatus,
      Quantity      = LD.Quantity,
      LoadId        = L.LoadId,
      LoadNumber    = L.LoadNumber,
      ShipmentId    = L.ShipmentId,
      KeyValue      = cast(LD.LPNId as varchar) + cast (LD.SKUId as varchar),
      ProcessedFlag = 'N' /* No */
  from #LPNDetails TLD
    join LPNDetails   LD on (TLD.LPNDetailId = LD.LPNDetailId)
    join LPNs         L  on (LD.LPNId   = L.LPNId)
    join OrderHeaders OH on (LD.OrderId = OH.OrderId)
    join SKUs         S  on (LD.SKUId   = S.SKUId);

  /* Invoke procedure to un-allocate Reserved lines */
  exec pr_UnAllocate_ReservedLines @Operation, @BusinessUnit, @UserId;

  /* Invoke procedure to un-allocate Pending Reserve lines */
  exec pr_UnAllocate_PendingReserveLines @Operation, @BusinessUnit, @UserId;

  /* Invoke proc to cancel replenish quantity */
  exec pr_UnAllocate_CancelReplenishQty @Operation, @BusinessUnit, @UserId;

  /*-------------- Update Order Details ---------------*/
  /* Reduce Units assigned on order detail */
  ;with LPNUnallocatedUnits as
  (
    select OrderId, OrderDetailId, sum(Quantity) as Quantity
    from #LPNDetails
    where (ProcessedFlag = 'Y' /* Yes */) -- $$ need index on #LPNDetails
    group by OrderId, OrderDetailId
  )
  update OD
  set UnitsAssigned = dbo.fn_MaxInt((UnitsAssigned - LUU.Quantity), 0)
  from OrderDetails OD
    join LPNUnallocatedUnits LUU on (OD.OrderDetailId = LUU.OrderDetailId);

  /*--------------- Recount LPNs ---------------*/
  /* Recount LPNs immediately as there are some updates to be done on them */
  insert into #EntitiesToRecalc (EntityType, EntityId, EntityKey, RecalcOption, Status, ProcedureName, BusinessUnit)
    select distinct 'LPN', LPNId, LPN, 'CS' /* Counts & Status */, 'N', @vProcName, @BusinessUnit from #LPNDetails

  /* Recount Entities that are to be processed immediately */
  exec pr_Entities_RecalcCounts @BusinessUnit, @UserId;

  /* Clear other info on LPNs when Status is back to putaway */
  /* This has to be done strictly after LPN is recounted */
  update L
  set LPNType      = case when L.ReservedQty = 0 and L.LPNType = 'S' then 'C' else L.LPNType end, /* If we unallocate the Picked ShipCarton LPN and ReservedQty is 0 after unallocate then we should change the LPNType to Carton */
      PackageSeqNo = null,
      UCCBarcode   = null,
      TrackingNo   = null,
      TaskId       = null,
      ShipmentId   = 0,
      LoadId       = 0,
      LoadNumber   = null,
      BoL          = null,
      PickBatchId  = null,
      PickBatchNo  = null,
      DestLocation = null,
      DestZone     = null
  from LPNs L
    join #LPNDetails LD on (L.LPNId = LD.LPNId)
  where (L.Status = 'P' /* Putaway */); -- clear this info only when LPN status is putaway

  /*-------------- Recompute Task/Wave dependencies ---------------*/
  /* When a line is un-allocated, dependencies on the task details from those LPNs may change
     so we need to recompute task & wave dependencies, capture all the tasks details that needs to be recomputed */
  insert into #TDsToRecomputeDependencies (EntityId)
    select TD.TaskDetailId
    from TaskDetails TD
      join Tasks       T  on (TD.TaskId = T.TaskId)
      join #LPNDetails LD on (TD.LPNId = LD.LPNId) and
                             (LD.LPNType = 'L' /* Picklane */) and
                             (ProcessedFlag = 'Y' /* Yes */)
    where (TD.Status in ('N', 'O')) and
          (charindex(TD.DependencyFlags, 'MRS') > 0) and  -- In case of un-allocation quantity will be increased so recompute only MRS dependencies
          (T.Archived = 'N') and -- for performance
          (T.Status in ('O', 'N' /* OnHold, ReadyToStart */)) and
          (T.IsTaskConfirmed = 'N'/* No */);

  /* If there are any task details to be computed then add a record to process in background */
  if exists (select * from #TDsToRecomputeDependencies)
    begin
      select @vInputParams = (select EntityId as TaskDetailId
                              from #TDsToRecomputeDependencies
                              for xml raw('Root'), elements );

      /* Invoke ExecuteInBackGround to defer Task dependencies computation */
      exec pr_Entities_ExecuteInBackGround @Entity = 'Task', @ProcessClass = 'CTD'/* ProcessCode - Compute Task Dependencies */,
                                           @ProcId = @@ProcId, @Operation = 'TaskDependencies',
                                           @BusinessUnit = @BusinessUnit, @InputParams = @vInputParams;

    end

  /*--------------- Recount all Entities ---------------*/
  /* Recount required entities */
  insert into #EntitiesToRecalc (EntityType, EntityId, EntityKey, RecalcOption, Status, ProcedureName, BusinessUnit)
    select distinct 'Pallet', PalletId, Pallet, 'CS' /* Counts & Status */, 'N', @vProcName, @BusinessUnit from #LPNDetails
    union all
    select distinct 'Order', OrderId, PickTicket, 'CS' /* Counts & Status */, 'N', @vProcName, @BusinessUnit from #LPNDetails
    union all
    select distinct 'Wave', WaveId, WaveNo, '$CS' /* defer Counts & Status */, 'N', @vProcName, @BusinessUnit from #LPNDetails
    union all
    select distinct 'Shipment', ShipmentId, null, '$C' /* defer Counts */, 'N', @vProcName, @BusinessUnit from #LPNDetails
    union all
    select distinct 'Load', LoadId, LoadNumber, '$C' /* defer Counts */, 'N', @vProcName, @BusinessUnit from #LPNDetails

  /* Recount Entities that are to be processed immediately */
  if (@RecountEntities = 'Y' /* Yes */)
    exec pr_Entities_RecalcCounts @BusinessUnit, @UserId;

  /*--------------- Audit Trail ---------------*/
  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, UDF1)
    select 'LPN', LPNId, LPN, @vAuditActivity, @BusinessUnit, @UserId, RecordId from #LPNDetails
    union all
    select 'Order', OrderId, PickTicket, @vAuditActivity, @BusinessUnit, @UserId, RecordId from #LPNDetails
    union all
    select 'Wave', WaveId, WaveNo, @vAuditActivity, @BusinessUnit, @UserId, RecordId from #LPNDetails;

  /* Build AT Comment */
  update ttAT
  set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'LPN', LPN, 'PickTicket', PickTicket, 'DisplaySKU', SKU, 'Units', cast(Quantity as varchar) + ' Unit(s)', null, null, null, null)
  from @ttAuditTrailInfo ttAT
    join #LPNDetails LD on (ttAT.UDF1 = LD.RecordId);

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If we have started the transaction then commit */
  if (@vTranCount = 0) commit transaction;

  /* Process recounts here itself if the hash table was created in this proc */
  if (@vRecalcCounts = 'Y')
    exec pr_Entities_RequestRecalcCounts null /* EntityType */, @ProcId = @@ProcId, @BusinessUnit = @BusinessUnit;

end try
begin catch
  /* If we have started the transaction then rollback, else let caller do it */
  if (@vTranCount = 0) rollback transaction;

  exec pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_UnAllocate_LPNDetails */

Go
