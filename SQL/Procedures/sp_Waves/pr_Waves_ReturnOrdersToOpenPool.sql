/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/30  TK      pr_Waves_ReturnOrdersToOpenPool: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_ReturnOrdersToOpenPool') is not null
  drop Procedure pr_Waves_ReturnOrdersToOpenPool;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_ReturnOrdersToOpenPool: After waves are allocated, it is possible
    that some orders do not have any inventory allocated against them. Some clients
    would want to remove such orders from the Waves so that they can be added to
    future Waves and released again. This procedure, evaluates the Waves that are open
    and removes orders from waves if there are no units assigned to them. However,
    if the Wave is a BulkPull, then we cannot just go by the units assigned for
    the original orders (like an SLB as unitl packing, there wouldn't be units assigned),
    so in that case, we have to evaluate the order details to make sure none of
    the SKUs on the orders are allocated against the Bulk Order either.
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_ReturnOrdersToOpenPool
  (@Operation             TOperation = 'Wave_ReturnOrdersToOpenPool',
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId)
as
  declare @vReturnCode                   TInteger,
          @vMessageName                  TMessageName,

          @vCancelWaveIfEmpty            TFlag,
          @vValidWaveTypes               TControlValue,
          @vValidWaveStatuses            TControlValue;

  declare @ttOrdersToUnWave              TOrderDetails,
          @ttResultMessages              TResultMessagesTable;
begin /* pr_Waves_ReturnOrdersToOpenPool */

  /* Initialize variables */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Create required hash tables */
  if object_id('tempdb..#ResultMessages') is null
    select * into #ResultMessages from @ttResultMessages;
  select * into #OrdersToUnWave from @ttOrdersToUnWave;

  /* Get Controls */
  select @vValidWaveTypes    = dbo.fn_Controls_GetAsString('Wave_RemoveOrder', 'ValidWaveTypes', 'PTS,BPP,PTC', @BusinessUnit, @UserId),
         @vValidWaveStatuses = dbo.fn_Controls_GetAsString('Wave_RemoveOrder', 'ValidWaveStatuses', 'RPUKACGO', @BusinessUnit, @UserId),
         @vCancelWaveIfEmpty = dbo.fn_Controls_GetAsString('RemoveOrdersFromWave', 'CancelWaveIfEmpty', 'Y', @BusinessUnit, @UserId);

  /* Get all the waves that are to be evaluated */
  select WaveId, WaveNo, WaveType, WaveStatus, AllocateFlags, IsBulkPull, BulkOrderId
  into #Waves
  from Waves
  where (Archived = 'N' /* No */) and
        (dbo.fn_IsInList(WaveType, @vValidWaveTypes) > 0) and
        (dbo.fn_IsInList(WaveStatus, @vValidWaveStatuses) > 0) and
        (datediff(d, ReleaseDateTime, getdate()) >= 1); -- Consider Waves which are released 1 day earlier than current day

  /* For Bulk Wave, the original order may not be allocated, but the Bulk Order could be. In this context
     an Invalid Order is an Order which may not have units assigned but there is inventory allocated for
     atleast one of the SKUs on the Order against the bulk order. We disregard these orders */
  ;with InvalidOrders as
  (
    select OH.OrderId
    from #Waves W
      join OrderDetails BOD on (BOD.OrderId = W.BulkOrderId) and (BOD.UnitsAssigned > 0)
      join OrderHeaders OH  on (W.WaveId = OH.PickBatchId) and (OH.OrderType <> 'B' /* Bulk */) and (OH.UnitsAssigned = 0)
      join OrderDetails OD  on (OH.OrderId = OD.OrderId) and (BOD.SKUId = OD.SKUId)
    where (W.IsBulkPull = 'Y' /* Yes */)
  )
  insert into #OrdersToUnWave(OrderId, PickTicket, OrderType, OrderStatus, WaveId, WaveNo, WaveType, WaveStatus, WaveAllocateFlags)
    select distinct OH.OrderId, OH.PickTicket, OH.OrderType, OH.Status, W.WaveId, W.WaveNo, W.WaveType, W.WaveStatus, W.AllocateFlags
    from OrderHeaders OH
      join #Waves W on (OH.PickBatchId = W.WaveId) and (W.IsBulkPull = 'Y' /* Yes */)
      left outer join InvalidOrders IO on (OH.OrderId = IO.OrderId)
    where (OH.OrderType <> 'B' /* Bulk */) and
          (OH.UnitsAssigned = 0) and
          (OH.Status = 'W' /* Waved */) and
          (IO.OrderId is null); -- Ignore Invalid Orders

  /* For non bulk waves, all orders which have no units assigned are candidates for removal */
  insert into #OrdersToUnWave(OrderId, PickTicket, OrderType, OrderStatus, WaveId, WaveNo, WaveType, WaveStatus, WaveAllocateFlags)
    select distinct OH.OrderId, OH.PickTicket, OH.OrderType, OH.Status, W.WaveId, W.WaveNo, W.WaveType, W.WaveStatus, W.AllocateFlags
    from OrderHeaders OH
      join #Waves W on (OH.PickBatchId = W.WaveId) and (W.IsBulkPull = 'N' /* No */)
    where (OH.Status = 'W' /* Waved */) and
          (OH.UnitsAssigned = 0);

  /* If there are no orders to unwave then return */
  if not exists (select * from #OrdersToUnWave) return;

  /* Validations */
  exec pr_Waves_RemoveOrders_Validations @Operation, @BusinessUnit, @UserId;

  /* Invoke procedure to unwave Orders */
  exec pr_Waves_RemoveOrders @vCancelWaveIfEmpty, 'OH' /* WavingLevel */, @Businessunit, @UserId, @Operation;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_ReturnOrdersToOpenPool */

Go
