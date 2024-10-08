/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/03  TK      pr_OrderHeaders_ShipMultiple: Initial Revision (HA-1842)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_ShipMultiple') is not null
  drop Procedure pr_OrderHeaders_ShipMultiple;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_ShipMultiple: This proc recomputes the Status of given set of orders and generates
    exports if they are shipped

  #OrdersToShip -> TEntityKeysTable
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_ShipMultiple
  (@Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vDefaultPalletWeight     TControlValue;

  declare @ttOrdersToShip           TEntityKeysTable,
          @ttOrdersShipped          TOrderDetails,
          @ttAuditTrailInfo         TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Create Required hash tables */
  select * into #OrdersShipped from @ttOrdersShipped;

  /* Get the Default Pallet Weight based on control value */
  select @vDefaultPalletWeight = dbo.fn_Controls_GetAsInteger('ExportData', 'DefaultPalletWeight', '1', @BusinessUnit, @UserId);

  /* By this time all the LPNs that can be shipped will be marked as shipped
     invoke set status on the orders that may mark the order as shipped */
  insert into @ttOrdersToShip (EntityId) select OrderId from #OrdersToShip;
  exec pr_OrderHeaders_Recalculate @ttOrdersToShip, 'S' /* Status only */, @UserId, @BusinessUnit;

  /* Get all the orders that are shipped */
  insert into #OrdersShipped (OrderId, PickTicket, WaveId, WaveNo, LoadId)
    select OH.OrderId, OH.PickTicket, OH.PickBatchId, OH.PickBatchNo, OH.LoadId
    from OrderHeaders OH
      join #OrdersToShip OTS on OH.OrderId = OTS.OrderId
    where OH.Status = 'S' /* Shipped */;

  /* Compute the volume & weight that is shipped for each order */
  ;with ShippedWeightAndVolume as
  (
   select OS.OrderId, sum(coalesce(nullif(ActualWeight, 0), EstimatedWeight, 0)) as TotalWeight,
          sum(coalesce(nullif(ActualVolume, 0), EstimatedVolume, 0)) as TotalVolume, count(distinct PalletId) as NumPallets
   from LPNs L
     join #OrdersShipped OS on (L.OrderId = OS.OrderId)
   group by OS.OrderId
  )
  update OS
  set OS.TotalWeight = SWV.TotalWeight + (NumPallets * @vDefaultPalletWeight),
      OS.TotalVolume = SWV.TotalVolume
  from #OrdersShipped OS
    join ShippedWeightAndVolume SWV on (OS.OrderId = SWV.OrderId);

  /*--------- Exports ---------------*/
  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Generate the Ship Transactions for Orders & Order Details */
  insert into #ExportRecords (TransType, TransEntity, TransQty, OrderId, OrderDetailId, LoadId, Weight, Volume, CreatedBy, SortOrder)
    /* Ship Transactions for Orders */
    select 'Ship', 'OH', OH.UnitsShipped, OH.OrderId, null, OH.LoadId, OS.TotalWeight, OS.TotalVolume, @UserId, 'Order-' + cast(OH.OrderId as varchar) + '-2'
    from #OrdersShipped OS
      join OrderHeaders OH on OS.OrderId = OH.OrderId
    union all
    /* Ship Transactions for Order Details */
    select 'Ship', 'OD', OD.UnitsShipped, OD.OrderId, OD.OrderDetailId, OS.LoadId, 0, 0, @UserId,
           'Order-' + cast(OD.OrderId as varchar) + '-1-' + cast(OD.OrderDetailId as varchar)
    from #OrdersShipped OS
      join OrderDetails OD on OS.OrderId = OD.OrderId

  /* Insert Records into Exports table */
  exec pr_Exports_InsertRecords 'Ship', null, @BusinessUnit;

  /*--------- Audit Trail ---------------*/
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId)
    select distinct 'Order', OrderId, PickTicket, 'OrderShipped', @BusinessUnit, @UserId
    from #OrdersShipped;

  /* Build comment */
  update ttAT
  set Comment = dbo.fn_Messages_Build('AT_' + ActivityType, null, null, null, null, null)
  from @ttAuditTrailInfo ttAT;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Recount required entities */
  insert into #EntitiesToRecalc (EntityType, EntityId, EntityKey, RecalcOption, Status, ProcedureName, BusinessUnit)
    select distinct 'Wave', WaveId, WaveNo, '$S' /* defer & Status */, 'N', object_name(@@ProcId), @BusinessUnit from #OrdersShipped;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_ShipMultiple */

Go
