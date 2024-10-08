/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/02  TK      pr_Allocation_GeneratePseudoPicks: Changes to defer cubing
                      pr_Allocation_AllocateFromDynamicPicklanes: Initial Revision
                      pr_Allocation_AllocateLPNToOrders: Changes to allocate only required cases and
                        allocate Units for Dynamic Replenishments (S2GCA-66)
                      pr_Allocation_AllocateWave: Changes to Replenish dynamic Locations (S2GCA-63)
  2015/06/29  TK      pr_Allocation_GeneratePseudoPicks: Updated to Log AuditTrail
  2015/05/09  TK      pr_Allocation_GeneratePseudoPicks: Added missing argument
  2015/04/30  TK      pr_Allocation_GeneratePseudoPicks: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GeneratePseudoPicks') is not null
  drop Procedure pr_Allocation_GeneratePseudoPicks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GeneratePseudoPicks:
    For certain Wave Types, we will not allocate inventory against the wave,
     but instead we will create the pick tasks as if the entire AuthorizedToShip
     Qty is allocated. i.e. The Pick tasks generated will only designate what needs
     to be picked but wouldn't have the locations to be picked from because we
     wouldn't be making any reservations.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GeneratePseudoPicks
  (@WaveId       TRecordId,
   @Operation    TOperation = null,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TDescription,
          @vWaveId             TRecordId,
          @vWaveNo             TPickBatchNo,
          @vWarehouse          TWarehouse,
          @vTDtlsFirst         TFlags;

  declare @ttTaskDetails      TTaskInfoTable,
          @ttCubedTaskDetails TTaskInfoTable;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vTDtlsFirst  = dbo.fn_Controls_GetAsString('Allocation', 'CreateTaskDetailsFirst', 'N' /* No */, @BusinessUnit, null /* UserId */);

  select @vWaveId = RecordId,
         @vWaveNo = BatchNo
  from PickBatches
  where (RecordId = @WaveId);

  /* Get the OrderDetails of the Orders on the given PickBatch for Cubing.
     We have to disregard the tasks already created */
  with TaskedUnits(OrderId, OrderDetailId, QtyTasked) as
  (
    select OrderId, OrderDetailId, sum(UnitsToPick)
    from TaskDetails
    where (WaveId = @vWaveId) and (Status not in ('X', 'C'))
    group by OrderId, OrderDetailId
  )
  insert into @ttTaskDetails(PickBatchId, PickBatchNo, OrderId, OrderDetailId, SKUId, UnitsToAllocate)
    select PBD.PickBatchId, PBD.PickBatchNo, PBD.OrderId, PBD.OrderDetailId, PBD.SKUId,
           PBD.UnitsToAllocate - coalesce(TU.QtyTasked, 0)
    from vwPickBatchDetails PBD left outer join TaskedUnits TU on PBD.OrderDetailId = TU.OrderDetailId
    where (PBD.PickBatchId  = @vWaveId) and
          (PBD.UnitsToAllocate > 0) and
          (PBD.OrderType <> 'B'/* Bulk */) and
          (PBD.OrderStatus not in ('S', 'X', 'D' /* Shipped, Canceled, Completed */)) and
          (PBD.UnitsToAllocate - coalesce(TU.QtyTasked, 0) > 0);

  if (@@rowcount = 0)
    goto ExitHandler;

    /* For all the LPNs allocated, create the pick tasks */
  if (@vTDtlsFirst = 'Y')
    exec pr_Allocation_CreateTaskDetails @vWaveId, @ttTaskDetails, @Operation, @vWarehouse, @BusinessUnit, @UserId;
  else
    begin
      /* I think we can drop this and only support the above as there are no clients using this now.*/
      /* insert the Cubed Task Details into a temp table to pass into PickBatch_CreatePickTasks */
      insert into @ttCubedTaskDetails(PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId,
                                      LocationId, UnitsToAllocate, SKUId, CartonType, TempLabelId, TempLabel, PickPath,
                                      PickZone, DestZone, DestLocation, PickType, LocationType, StorageType,
                                      LPNType, OrderType)
        exec pr_Cubing_Execute @vWaveId, @ttTaskDetails, @BusinessUnit, @UserId;

      /* For all the LPNs allocated, create the pick tasks */
      exec pr_PickBatch_CreatePickTasks @vWaveId, @ttCubedTaskDetails, 'PseudoPicks' /* Operation */,
                                        null /* Warehouse */, @BusinessUnit, @UserId;
    end

  /* Audit trail */
  exec pr_AuditTrail_Insert 'PseudoPicksCreated', @UserId, null /* ActivityTimestamp */,
                            @PickBatchId   = @vWaveId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_GeneratePseudoPicks */

Go
