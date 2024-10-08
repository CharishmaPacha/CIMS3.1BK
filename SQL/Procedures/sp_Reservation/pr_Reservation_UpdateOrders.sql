/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/05  VS      pr_Reservation_UpdateOrders: Defer the wave status after activate the shipcartons (BK-139)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_UpdateOrders') is not null
  drop Procedure pr_Reservation_UpdateOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_UpdateOrders: On activation, both the #FromLPNDetails and
   #ToLPNDetails would be updated. If those are associated with any order, then
   adjust the OrderDetails accordingly.
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_UpdateOrders
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vRecordId            TRecordId;

  declare @ttOrdersToRecounts   TEntityKeysTable,
          @ttWavesToRecalc      TEntityKeysTable;
begin
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Temp Table to recount */
  select * into #BulkOrdersToRecount from @ttOrdersToRecounts;

  /* Update customer Orders associated with Ship Cartons */
  update OD
  set OD.UnitsAssigned += TLL.Quantity
  from OrderDetails OD
    join (select OrderDetailId, sum(Quantity) as Quantity
          from #ToLPNDetails
          where ProcessedFlag = 'A' /* Activate */
          group by OrderDetailId) TLL on OD.OrderDetailId = TLL.OrderDetailId;

  /* Update order associated with FromLPNs if exists. If it is a Bulk Order,
     then reduce the UnitsAuthorizedToShip as well. For other order types
     just reduce the UnitsAssigned */
  with OrderDetailsToUpdate (OrderDetailId, OrderType, Quantity)
  as
  (
    select FLD.OrderDetailId, OH.OrderType, sum(FLD.ReservedQty)
    from #FromLPNDetails FLD
      join OrderHeaders OH on FLD.OrderId = OH.OrderId
    group by FLD.OrderDetailId, OH.OrderType
    having (sum(FLD.ReservedQty) > 0)
  )
  update OD
  set OD.UnitsAssigned         -= TOD.Quantity,
      OD.UnitsAuthorizedToShip -= case when TOD.OrderType = 'B' then TOD.Quantity else 0 end
  output Inserted.OrderId into #BulkOrdersToRecount(EntityId)
  from OrderDetailsToUpdate TOD
    join OrderDetails OD on (TOD.OrderDetailId = OD.OrderDetailId);

  /* Recount Orders */
  insert into @ttOrdersToRecounts(EntityId)
    select distinct OrderId from #ToLPNDetails
    union
    select distinct EntityId from #BulkOrdersToRecount

  exec pr_OrderHeaders_Recalculate @ttOrdersToRecounts, 'S' /* Status */, @UserId;

  /* Reclac Wave */
  insert into @ttWavesToRecalc (EntityId, EntityKey)
    select distinct W.WaveId, W.WaveNo from #ToLPNDetails TL join Waves W on TL.WaveId = W.WaveId;

  exec pr_PickBatch_Recalculate @ttWavesToRecalc, '$S' /* Defer & Compute Status only */, @UserId, @BusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_UpdateOrders */

Go
