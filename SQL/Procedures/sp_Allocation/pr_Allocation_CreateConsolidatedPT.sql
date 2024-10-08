/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/15  AY      pr_Allocation_CreateConsolidatedPT: Use Wave Priority for BPT Priority (HA-1988)
  2020/05/25  TK      pr_Allocation_CreateConsolidatedPT: Create BPT for Released status waves as well (HA-646)
                      pr_Allocation_GenerateShipCartons: Changes to generate cartons for each order line separately
                        when packing group is 'SOLID' (HA-648)
  2020/05/13  TK      pr_Allocation_CreateConsolidatedPT: Code Revamp
                      pr_Allocation_ProcessTaskDetails: Migrated from CID (HA-86)
  2019/03/12  TK      pr_Allocation_CreateConsolidatedPT: Preprocess the bulk order created (S2GCA-519)
  2019/02/19  TK      pr_Allocation_CreateConsolidatedPT: Do not check controls to create BPT (S2GCA-465)
  2017/09/20  YJ      pr_Allocation_CreateConsolidatedPT: call to pr_OrderHeaders_AddOrUpdate changed to use named params instead of passing all nulls
  2017/08/23  SV      pr_Allocation_CreateConsolidatedPT: Changes as per change in the signature of a procedure (OB-548)
  2015/12/06  DK      pr_Allocation_CreateConsolidatedPT: Made changes to insert OrigUnitsAuthorizedToShip in Orderdetails (FB-577).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_CreateConsolidatedPT') is not null
  drop Procedure pr_Allocation_CreateConsolidatedPT;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_CreateConsolidatedPT creates a bulk order by consolidating all the order details
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_CreateConsolidatedPT
  (@WaveId           TRecordId,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vWaveId             TRecordId,
          @vWaveNo             TWaveNo,
          @vWaveType           TTypeCode,
          @vWaveStatus         TStatus,
          @vWavePriority       TPriority,
          @vWaveBulkOrderId    TRecordId,

          @vBPTOrderId         TRecordId,
          @vBPTPriority        TPriority,

          @vOrderId            TRecordId,
          @vPickTicket         TPickTicket,
          @vOrderPriority      TPriority,
          @vOrderDate          TDateTime,
          @vDesiredShipDate    TDateTime,
          @vOwnership          TOwnership,
          @vWarehouse          TWarehouse,
          @vSoldToId           TCustomerId,
          @vShipToId           TShipToId,
          @vShipVia            TShipVia,
          @vShipFrom           TShipFrom,
          @vCustPO             TCustPO,

          @NumLinesOnOrder     TCount,
          @NumSKUsOnOrder      TCount,
          @NumUnitsOnOrder     TCount,
          @vWarehouseCount     TCount,
          @vOwnerCount         TCount;

  declare @ttWaveOrderDetails  TOrderDetails;
begin
  SET NOCOUNT ON;

  /* Get the Wave Info */
  select @vWaveId          = RecordId,
         @vWaveNo          = WaveNo,
         @vWaveStatus      = Status,
         @vWaveType        = WaveType,
         @vWavePriority    = Priority,
         @vWaveBulkOrderId = BulkOrderId
  from Waves
  where (WaveId = @WaveId);

  /* if BPT is already created for this wave, then exit */
  if (@vWaveBulkOrderId is not null) goto ExitHandler;

  /* select the counts of SoldTo, ShipTo, ShipVia from OrderHeaders
     to update the consolidated PickTicket */
  select @vSoldToId        = Case
                               when (count(distinct(SoldToId)) = 1) then
                                 min(SoldToId)
                               else
                                 null
                             end,
         @vShipToId        = Case
                               when (count(distinct(ShipToId)) = 1) then
                                 min(ShipToId)
                               else
                                 null
                             end,
         @vShipVia         = min(ShipVia),
         @vOrderPriority   = min(Priority),
         @vOwnership       = min(Ownership),
         @vWarehouse       = min(Warehouse),
         @vWarehouseCount  = count(distinct(Warehouse)),
         @vOwnerCount      = count(distinct(Ownership))
  from OrderHeaders
  where (PickBatchId = @vWaveId);

  /* Validations */
  if (@vWaveStatus not in ('E', 'R', 'L'/* Released, Ready to Pick,  Ready to Pull */))
    set @vMessageName = 'InvalidBatchStatus';
  else
  if (@vOwnerCount <> 1)
    set @vMessageName = 'MultipleOwnersOnBatch';
  else
  if (@vWarehouseCount <> 1)
    set @vMessageName = 'MultipleWarehousesOnBatch';

  if (@vMessageName is not null) exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @vBPTPriority = dbo.fn_MinInt(@vWavePriority, @vOrderPriority);

  /* Get the Order details of the Batch and insert the order details into temp table
     The UnitsToAllocate on the BPT is the remainder of the Case Picks
     $$ What if UnitsPerInnerPack = 0? */
  /* TODO item for TK: Use a control var to identify whether take Units or Cases */
  insert into @ttWaveOrderDetails (SKUId, DestZone, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
                                   UnitsOrdered, UnitsToShip, UnitsPreAllocated)
    select SKUId, DestZone, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
           sum(UnitsToAllocate), sum(UnitsToAllocate), sum(UnitsPreAllocated)
    from vwOrderDetails
    where (PickBatchId = @vWaveId) and
          (UnitsToAllocate > 0)
    group by SKUId, Warehouse, DestZone, Lot, InventoryClass1, InventoryClass2, InventoryClass3;

  /* Generating PickTicket for the Consolidated Order to bulk pull */
  exec @vReturnCode = pr_OrderHeaders_GetNextPickTicketNo 'B' /* Bulk Pull - OrderType */,
                                                         @vWaveNo,
                                                         @BusinessUnit,
                                                         @vPickTicket output;

  /* Insert Consolidated Order to bulk pull into Order Headers  */
  exec @vReturnCode = pr_OrderHeaders_AddOrUpdate @vPickTicket,
                                                  @vPickTicket,     /* Sales Order */
                                                  'B'               /* Bulk Pull - OrderType */,
                                                  'N'               /* New - Status */,
                                                  @vOrderDate       /* OrderDate */,
                                                  @vDesiredShipDate /* DesiredShipDate */,
                                                  @vBPTPriority     /* OrderPriority */,
                                                  @vSoldToId        /* Sold To */,
                                                  @vShipToId        /* Ship To */,
                                                  @vShipVia         /* Ship Via */,
                                                  @vShipFrom        /* @ShipFrom */,
                                                  @vCustPO          /* CustPO */,
                                                  @vOwnership,
                                                  @vWarehouse,
                                                  @BusinessUnit = @BusinessUnit,
                                                  @OrderId   = @vOrderId      output,
                                                  @CreatedBy = @UserId    output;

  /* Insert the OrderDetails for the created Consolidate PickTicket */
  insert into OrderDetails(OrderId, HostOrderLine, SKUId, UnitsOrdered, UnitsPreAllocated,
                           UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, DestZone, Lot,
                           InventoryClass1, InventoryClass2, InventoryClass3, BusinessUnit, CreatedBy)
    select @vOrderId, coalesce(HostOrderLine, ''), SKUId, UnitsOrdered, UnitsPreAllocated,
           UnitsToShip, UnitsToShip, DestZone, Lot,
           InventoryClass1, InventoryClass2, InventoryClass3, @BusinessUnit, @UserId
    from @ttWaveOrderDetails;

  /* Preprocess Bulk Order after OD's are inserted since we are doing some updates OD's in order preprocess */
  exec pr_OrderHeaders_PreProcess @vOrderId;

  /* Add the Created Consolidated Order to the Batch */
  exec @vReturnCode = pr_PickBatch_AddOrder @vWaveId, @vWaveNo, @vOrderId, null, /* order DetailId */ 'OH', /* batching Level */
                                            'N'/* Do not update counts */, null /* Pickbatchgroup */, @UserId;

  /* Update Bulk Order on wave and Flag wave as Bulk Pull */
  update Waves
  set BulkOrderId = @vOrderId,
      IsBulkPull  = 'Y' /* Yes */
  where (WaveId = @vWaveId);

  /* Recount Bulk Pull Order so that counts would be updated properly */
  exec pr_OrderHeaders_Recount @vOrderId;

  /* Auditing */
  exec pr_AuditTrail_Insert 'WaveConsolidated', @UserId, null /* Activity TimeStamp */,
                            @WaveId  = @vWaveId,
                            @OrderId = @vOrderId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_CreateConsolidatedPT */

Go
