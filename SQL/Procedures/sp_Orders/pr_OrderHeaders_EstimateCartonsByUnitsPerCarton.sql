/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/09  RKC     pr_OrderHeaders_EstimateCartons, pr_OrderHeaders_EstimateCartonsByUnitsPerCarton,
                      pr_OrderHeaders_EstimateCartonsByUnitsPerCarton: Compute residual cartons for each carton group (HA-2446)
  2021/02/16  TK      pr_OrderHeaders_EstimateCartonsByUnitsPerCarton & pr_OrderHeaders_EstimateCartonsByVolume:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_EstimateCartonsByUnitsPerCarton') is not null
  drop Procedure pr_OrderHeaders_EstimateCartonsByUnitsPerCarton;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_EstimateCartonsByUnitsPerCarton: This procedure identifies how many cartons each
    order in the temp table #OrdersToPreProcess may take based upon UnitsPerCarton defined for each packing group

  #OrdersToPreProcess -> TEntityKeysTable
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_EstimateCartonsByUnitsPerCarton
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName;
  declare @ttOrderDetails           TOrderDetails,
          @ttInvaildOrders          TRecountKeysTable;
begin
  SET NOCOUNT ON;

  /* Create required hash tables */
  select * into #OrderDetailsToProcess from @ttOrderDetails;

  /* Validations */
  /* Find the orders with UnitsPerCarton not defined */
  insert into #Validations (MessageType, MessageName, EntityType, EntityId, EntityKey)
  output inserted.EntityId into @ttInvaildOrders (EntityId)
  select distinct 'W' /* Warning */, 'OrderEstimatedCartons_InvalidUnitsPerCarton', 'Order', OH.OrderId, OH.PickTicket
  from OrderHeaders OH
      join #OrdersToPreProcess OTP on OH.OrderId = OTP.EntityId
      join OrderDetails OD on OH.OrderId = OD.OrderId
  where OD.UnitsPerCarton = 0;

  /* Get all the orderd details to process */
  insert into #OrderDetailsToProcess(OrderId, PickTicket, OrderDetailId, PackingGroup, UnitsToShip, UnitsPerCarton, OD_UDF1)
    select OH.OrderId, OH.PickTicket, OD.OrderDetailId, OD.PackingGroup, OD.UnitsAuthorizedToShip, OD.UnitsPerCarton, coalesce(OH.UDF10, '')
    from OrderHeaders OH
      join #OrdersToPreProcess OTP on OH.OrderId = OTP.EntityId
      join OrderDetails OD on OH.OrderId = OD.OrderId
      left outer join @ttInvaildOrders IO on OH.OrderId = IO.EntityId
    where OD.UnitsAuthorizedToShip > 0 and
          IO.RecordId is null;   -- Exclude invalid orders

  /* If there are no records to process then return */
  if not exists (select * from #OrderDetailsToProcess) return;

  /* If Packing group is SOLID, then we have to pack each line separately */
  update #OrderDetailsToProcess
  set PackingGroup = OrderDetailId
  where (PackingGroup = 'SOLID')

  /* Compute possible number of cartons for each line and residual units */
  ;with KitsPossible as
  (
    select OrderId, PackingGroup, min(UnitsToShip / UnitsPerCarton) as KitsPossible
    from #OrderDetailsToProcess
    group by OrderId, PackingGroup
  )
  update OD
  set KitsPossible  = KP.KitsPossible, -- Possible number of cartons that can be created for each packing group
      ResidualUnits = UnitsToShip - (UnitsPerCarton * KP.KitsPossible)  -- Units that may be left out after cartons for each packing group
  from #OrderDetailsToProcess OD
    join KitsPossible KP on (OD.OrderId = KP.OrderId) and (OD.PackingGroup = KP.PackingGroup);

  /* Estimated cartons per GROUP is the minimum number of KitsPossible for that group and
     an additional carton for each group if there are any residual units */
  ;with EstimatedCartonsPerGroup as
  (
    select OrderId, PackingGroup, min(KitsPossible) + count(distinct(case when ResidualUnits > 0 and OD_UDF1 <> 'FULLCASE'
                                                                            then cast(OrderId as varchar(max)) + PackingGroup
                                                                     end
                                                                     )
                                                            ) as EstimatedCartonsPerGroup
    from #OrderDetailsToProcess
    group by OrderId, PackingGroup
  ),
  /* Estimated cartons per ORDER will the sum of Estimated cartons of all GROUPS */
  EstimatedCartonsPerOrder as
  (
    select OrderId, sum(EstimatedCartonsPerGroup) as EstimatedCartons
    from EstimatedCartonsPerGroup
      group by OrderId
  )
  update OH
  set EstimatedCartons = EC.EstimatedCartons
  from OrderHeaders OH
    join EstimatedCartonsPerOrder EC on OH.OrderId = EC.OrderId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_EstimateCartonsByUnitsPerCarton */

Go
