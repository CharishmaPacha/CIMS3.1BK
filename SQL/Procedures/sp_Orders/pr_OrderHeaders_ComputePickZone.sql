/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/29  MS      pr_OrderHeaders_ComputePickZone: Code Optimization (BK-287)
  2018/04/20  OK      pr_OrderHeaders_ComputePickZone: Added new procedure to update the PickZone on the OrderHeader based on the task details (S2G-697)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_ComputePickZone') is not null
  drop Procedure pr_OrderHeaders_ComputePickZone;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_ComputePickZone: This procedure calculates the PickZones
    the Orders are being picked from for the given set of Orders. If order allocated
    from multiple pick zone then we will update all the zones with comma
    seperated list of Zones.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_ComputePickZone
  (@OrdersToCompute  TEntityKeysTable readonly,
   @OrderId          TRecordId  = null,
   @WaveId           TRecordId  = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vRecordId        TRecordId,

          @vOrderId         TRecordId,
          @vOrderPickZones  TDescription; -- Need confirmation on Data type

  declare @ttOrdersCompute  TEntityKeysTable;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vRecordId    = 0,
         @vMessageName = null;

  /* Get all the Orders which needs to compute Pickzone */
  if exists(select * from @OrdersToCompute)
    insert into @ttOrdersCompute(EntityId)
      select EntityId
      from @ttOrdersCompute;
  else
  if (@OrderId is not null)
    insert into @ttOrdersCompute(EntityId)
      select @OrderId;
  else
  if (@WaveId is not null)
    insert into @ttOrdersCompute(EntityId)
      select OrderId
      from OrderHeaders
      where (PickBatchId = @WaveId);

  /* Get Pickzones info */
  ;with PickZonesInfo (OrderPickZones, OrderId) as
  (
   select LOC.PickingZone, TD.OrderId
   from TaskDetails TD
     join Locations        LOC on (Loc.LocationId = TD.LocationId)
     join @ttOrdersCompute OC  on (TD.OrderId     = OC.EntityId)
   where (LOC.PickingZone is not null)
   group by LOC.PickingZone, TD.OrderId
  )
  select OrderId, string_agg(OrderPickZones, ',') PickZones
  into #OrderZones
  from PickZonesInfo
  group by OrderId;

  /* Update PickZones on all Orders at once */
  update OH
  set OH.PickZone = OZ.PickZones
  from OrderHeaders OH
    join #OrderZones OZ on (OH.OrderId = OZ.OrderId)

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_ComputePickZone */

Go
