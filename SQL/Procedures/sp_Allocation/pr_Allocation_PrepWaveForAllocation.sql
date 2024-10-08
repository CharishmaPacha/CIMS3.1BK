/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/07/28  RV      pr_Allocation_PrepWaveForAllocation: BusinessUnit and UserId passed to activity log procedure
                        to log activities (HPI-1584)
  2017/07/07  RV      pr_Allocation_PrepWaveForAllocation: Procedure id is passed to logging procedure to
                        determine this procedure required to logging or not from debug options (HPI-1584)
  2016/10/27  ??      pr_Allocation_FindAllocableLPN: Included missing case statement (HPI-GoLive)
              VM      pr_Allocation_PrepWaveForAllocation: Introduced activity log (HPI-935)
  2016/06/25  TK      pr_Allocation_PrepWaveForAllocation: Bug fix not to remove Orders whose ship complete flag is null
  2016/05/30  AY      pr_Allocation_PrepWaveForAllocation: Bug fix that is unwaving the order unnecessarily.
  2016/05/10  SV      pr_Allocation_PrepWaveForAllocation: Notifying the Unwaved OD line and logging AT over it (NBD-481)
  2016/04/03  SV      pr_Allocation_PrepWaveForAllocation : Initial Revision (NBD-321)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_PrepWaveForAllocation') is not null
  drop Procedure pr_Allocation_PrepWaveForAllocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_PrepWaveForAllocation: This procedure attempts to soft allocate
    all the Orderdetails on a wave and then if any of the ship complete orders
    are not completely allocated, removes them from the Wave.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_PrepWaveForAllocation
  (@PickBatchId  TRecordId,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @Options      TFlags = null,
   @Debug        TFlags = 'N')
as
  declare @vReturnCode      TInteger,
          @vRecordId        TRecordId,
          @vOrderId         TRecordId,
          @vPickTicket      TPickTicket,
          @vPickBatchNo     TPickBatchNo,
          @vWarehouse       TWarehouse,
          @vOrdersXML       TXML,
          @vMessageName     TMessageName;

  declare @ttBatchedOrderDetails  TSoftAllocationDetails,
          @SoftAllocationDetails  TSoftAllocationDetails;
  declare @ttOrders               TEntityKeysTable,
          @ttOrderDetails         TAuditTrailInfo,
          @vxmlData               TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vRecordId       = 0,
         @vMessageName    = null;

  /* Create temp table for other procedures to enter data */
  select * into #SoftAllocationDetails from @SoftAllocationDetails;

  select @vPickBatchNo = BatchNo,
         @vWarehouse   = Warehouse
  from PickBatches
  where (RecordId = @PickBatchId);

  if (coalesce(@PickBatchId, 0) = 0)
    select @vMessageName = 'PickBatchIsRequired';
  else
  if (@vPickBatchNo is null)
    select @vMessageName = 'PickBatchIsInvalid';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Log Orderheader info - before soft allocation */
  select @vxmlData = (select PickTicket, OrderType, Status, PickBatchNo,
                             WaveFlag, PreprocessFlag,
                             UDF1 OHUDF1, UDF2 OHUDF2, UDF3 OHUDF3, UDF4 OHUDF4, UDF5 OHUDF5,
                             UDF6 OHUDF6, UDF7 OHUDF7, UDF8 OHUDF8, UDF9 OHUDF9, UDF10 OHUDF10
                      from OrderHeaders
                      where (PickbatchId = @PickBatchId)
                      for XML raw('ORDERHEADERS'), elements );

  if (charindex('L', @Debug) > 0)   /* Log activity log */
    exec pr_ActivityLog_AddMessage 'Waves_SoftAllocation_Start', @PickBatchId, null, 'Wave',
                                   'Before_SoftAllocation' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;

  /* Inserting ODId as RecordId in the temp table as RecordId is not an identity column but only primary key. */
  insert into @ttBatchedOrderDetails (RecordId, OrderId, OrderDetailId, SKUId, UnitsToShip, UnitsToAllocate, ShipComplete)
    select OD.OrderDetailId, OD.OrderId, OD.OrderDetailId, OD.SKUId, OD.UnitsAuthorizedToShip, OD.UnitsToAllocate, OH.ShipComplete
    from OrderDetails OD
      join OrderHeaders OH on (OH.OrderId = OD.OrderId)
    where (OH.PickBatchId = @PickBatchId) and
          (OH.OrderType not in ('B', 'RU' /* Bulk, Replenish */));

  /* Soft allocate orders to see which orders may be short. Results are returned into the #table created above */
  exec pr_Allocation_SoftAllocateOrderDetails @ttBatchedOrderDetails, @UserId, @BusinessUnit, @vWarehouse, @Debug;

  /* Insert OrderIds which needs to be unwaved into a temp table so that it can converted into xml and pass to pr_PickBatch_RemoveOrders */
  /* Earlier UnitsPreallocated was compared with UnitsToShip and when it is a two pass allocation, it wouldn't be.
     For example UATS = 3 and 1 unit is in picklane and allocated. Now Ondemand is created and 2 units are needed.
     While soft allocation pre-allocates 2 units UATS <> UnitsPreallocated, so it would unwave the Order. Fixed
     by comparing with UnitsToAllocate */
  insert into @ttOrders(EntityId, EntityKey)
    select distinct OrderId, PickTicket
    from #SoftAllocationDetails
    where (UnitsToAllocate <> UnitsPreAllocated) and
          (UnitsToAllocate > 0) and
          ((ShipComplete is null) or (ShipComplete = 'Y'));

  /* Build the Audit Trail */
  insert into @ttOrderDetails (EntityType, EntityId, EntityKey, ActivityType,
                               Comment, BusinessUnit, UserId)
    select 'PickTicket', OrderId, PickTicket, 'AT_OrdersUnWaved' /* Audit Activity */,
             dbo.fn_Messages_BuildDescription('AT_OrdersUnWaved', 'SKU', SKU /* SKU */ , null, null , null, null , null, null, null, null, null, null) /* Comment */,
             @BusinessUnit,  @UserId
    from  #SoftAllocationDetails
    where (UnitsToAllocate <> UnitsPreAllocated) and
          (UnitsToAllocate > 0) and
          ((ShipComplete is null) or (ShipComplete = 'Y'));

  if (charindex('D', @Debug) > 0) select 'OrdersBeingRemoved' as UnwavedOrders, * from @ttOrders;

  /* Build XML of Orders to remove them from the wave */
  select @vOrdersXML = (select EntityId as OrderId
                        from @ttOrders
                        for xml raw('OrderHeader'), elements);

  select @vOrdersXML = dbo.fn_XMLNode('Orders', @vOrdersXML);

  /* Update the unwaved Orders with WaveFlag as 'U' - Unwaved so that users can see from front end */
  update OH
  set OH.WaveFlag = 'U' /* UnWaved */
  from OrderHeaders OH
  join @ttOrders ttO on (OH.OrderId = ttO.EntityId);

  /* Mark Order Details which are short so users know */
  update OD
  set OD.UDF10 = 'Y' /* Short */
  from OrderDetails OD
  join #SoftAllocationDetails SAD on (OD.OrderDetailId = SAD.OrderDetailId)
  where (SAD.UnitsToShip <> SAD.UnitsPreAllocated) and
        ((SAD.ShipComplete is null) or (SAD.ShipComplete = 'Y'));

  /* Log Orderheader info - before soft allocation */
  select @vxmlData = null;
  select @vxmlData = (select PickTicket, OrderType, Status, PickBatchNo,
                             WaveFlag, PreprocessFlag,
                             UDF1 OHUDF1, UDF2 OHUDF2, UDF3 OHUDF3, UDF4 OHUDF4, UDF5 OHUDF5,
                             UDF6 OHUDF6, UDF7 OHUDF7, UDF8 OHUDF8, UDF9 OHUDF9, UDF10 OHUDF10
                      from OrderHeaders
                      where (PickbatchId = @PickBatchId)
                      for XML raw('ORDERHEADERS'), elements );

  if (charindex('L', @Debug) > 0)   /* Log activity log */
    exec pr_ActivityLog_AddMessage 'Waves_SoftAllocation_End', @PickBatchId, null, 'Wave',
                                   'After_SoftAllocation_BeforeRemovedOrders' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;

  /* Unwave the orders */
  exec pr_PickBatch_RemoveOrders  @vPickBatchNo,
                                  @vOrdersXML,
                                  null /* CancelBatchIfEmpty - Y or N */,
                                  null /* BatchingLevel - OH from controls */,
                                  @BusinessUnit,
                                  'CIMS Allocation' /* UserId */;

  /* AT to log over the unwaved OrderDetails */
  exec pr_AuditTrail_InsertRecords  @ttOrderDetails

  /* Log Orderheader info - before soft allocation */
  select @vxmlData = null;
  select @vxmlData = (select PickTicket, OrderType, Status, PickBatchNo,
                             WaveFlag, PreprocessFlag,
                             UDF1 OHUDF1, UDF2 OHUDF2, UDF3 OHUDF3, UDF4 OHUDF4, UDF5 OHUDF5,
                             UDF6 OHUDF6, UDF7 OHUDF7, UDF8 OHUDF8, UDF9 OHUDF9, UDF10 OHUDF10
                      from OrderHeaders
                      where (PickbatchId = @PickBatchId)
                      for XML raw('ORDERHEADERS'), elements );

  if (charindex('L', @Debug) > 0)   /* Log activity log */
    exec pr_ActivityLog_AddMessage 'Waves_SoftAllocation_End', @PickBatchId, null, 'Wave',
                                   'After_SoftAllocation' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_PrepWaveForAllocation */

Go
