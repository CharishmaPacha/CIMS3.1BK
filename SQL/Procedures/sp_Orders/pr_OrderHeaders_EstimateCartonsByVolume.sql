/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/23  VS      pr_OrderHeaders_EstimateCartonsByVolume: Added SKU and Style/Color/Size in Validation message (HA-2013)
  2021/02/16  TK      pr_OrderHeaders_EstimateCartonsByUnitsPerCarton & pr_OrderHeaders_EstimateCartonsByVolume:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_EstimateCartonsByVolume') is not null
  drop Procedure pr_OrderHeaders_EstimateCartonsByVolume;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_EstimateCartonsByVolume: This procedure identifies how many cartons each
    order in the temp table #OrdersToPreProcess may take using the order volume & weight by grouping on packing group

  #OrdersToPreProcess -> TEntityKeysTable
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_EstimateCartonsByVolume
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vUseSKUDimensions        TControlValue;

  declare @ttOrdersToCube           TOrdersToCube,
          @ttCartonTypes            TCartonTypes,
          @ttInvalidOrders          TRecountKeysTable;
begin
  SET NOCOUNT ON;

  /* Create required hash tables */
  select * into #OrdersToCube from @ttOrdersToCube;
  select * into #CartonTypes  from @ttCartonTypes;

  /* Get controls */
  select @vUseSKUDimensions = dbo.fn_Controls_GetAsString('Cubing', 'UseSKUDimensions', 'Y' /* Yes */, @BusinessUnit, system_user);

  /* Validations */
  /* Find the orders with UnitVolume not defined */
  insert into #Validations (MessageType, MessageName, EntityType, EntityId, EntityKey, Value1, Value2, Value3, Value4)
  output inserted.EntityId into @ttInvalidOrders (EntityId)
  select distinct 'W' /* Warning */, 'OrderEstimatedCartons_InvalidUnitVolume', 'Order', OH.OrderId, OH.PickTicket, S.SKU, S.SKU1, S.SKU2, S.SKU3
  from OrderHeaders OH
      join #OrdersToPreProcess OTP on OH.OrderId = OTP.EntityId
      join OrderDetails OD  on OH.OrderId = OD.OrderId
      join SKUs S on OD.SKUId = S.SKUId
  where (S.UnitVolume = 0);

  /* Compute the total space required for each packing group on order */
  insert into #OrdersToCube (OrderId, PackingGroup, OrderCartonGroup, TotalSpaceRequired, TotalWeight,
                             MaxFirstDimension, MaxSecondDimension, MaxThirdDimension)
    select OH.OrderId, coalesce(OD.PackingGroup, cast(OH.OrderId as varchar)), min(coalesce(OH.CartonGroups, 'ALL')),
           sum(OD.UnitsAuthorizedToShip * S.UnitVolume) /* TotalSpaceRequired */,
           sum(OD.UnitsAuthorizedToShip * S.UnitWeight) /* TotalSpaceRequired */,
           case when @vUseSKUDimensions = 'Y' /* Yes */ then min(FN.FirstNumber)  else 0.1 end, /* If SKU dims cannot be used then insert with least value */
           case when @vUseSKUDimensions = 'Y' /* Yes */ then min(FN.SecondNumber) else 0.1 end,
           case when @vUseSKUDimensions = 'Y' /* Yes */ then min(FN.ThirdNumber)  else 0.1 end
    from OrderHeaders OH
      join #OrdersToPreProcess OTP on OH.OrderId = OTP.EntityId
      join OrderDetails OD  on OH.OrderId = OD.OrderId
      join SKUs S on OD.SKUId = S.SKUId
      cross apply dbo.fn_SortValuesAscending(S.UnitLength, S.UnitWidth, S.UnitHeight) FN
      left outer join @ttInvalidOrders IO on OH.OrderId = IO.EntityId
    where OD.UnitsAuthorizedToShip > 0 and
          IO.RecordId is null  -- Exclude invalid orders
    group by OH.OrderId, OD.PackingGroup;

  /* If there are no records to process then return */
  if not exists (select * from #OrdersToCube) return;

  /* Get all the carton types */
  insert into #CartonTypes (CartonGroup, CartonType, EmptyCartonSpace, EmptyWeight, MaxWeight, MaxUnits, MaxCartonDimension,
                            FirstDimension, SecondDimension, ThirdDimension)
    select CGT.CartonGroup, CGT.CartonType, CGT.AvailableSpace, CGT.EmptyWeight, CGT.MaxWeight, CGT.MaxUnits, CGT.MaxInnerDimension,
           CGT.FirstDimension, CGT.SecondDimension, CGT.ThirdDimension
    from vwCartonGroupsAndTypes CGT
      join (select distinct OrderCartonGroup from #OrdersToCube) OTC on (CGT.CartonGroup = OTC.OrderCartonGroup)
    where (CGT_Status   = 'A' /* Active */) and
          (CT_Status    = 'A' /* Active */) and
          (BusinessUnit = @BusinessUnit   );

  /* Check if there are any orders that can be fit into a single carton, if they can be fit
     then update ship cartons on them */
  ;with SingleCartonOrders as
   (
     select top 1 OTC.OrderId, OTC.PackingGroup, 1 as NumShipCartons
     from #OrdersToCube OTC
       join #CartonTypes CT on OTC.OrderCartonGroup = CT.CartonGroup
     where (CT.EmptyCartonSpace >= OTC.TotalSpaceRequired) and
           (CT.FirstDimension   >= OTC.MaxFirstDimension ) and
           (CT.SecondDimension  >= OTC.MaxSecondDimension) and
           (CT.ThirdDimension   >= OTC.MaxThirdDimension ) and
           (CT.MaxWeight        >= OTC.TotalWeight       ) and
           (CT.MaxUnits         >= OTC.TotalQtyToCube    )
     order by EmptyCartonSpace
   )
   update OTC
   set NumShipCartons = SCO.NumShipCartons
   from #OrdersToCube OTC
     join SingleCartonOrders SCO on OTC.OrderId = SCO.OrderId and
                                    OTC.PackingGroup = SCO.PackingGroup;

  /* if all the Orders have NumShipCartons defined then go to update orders and update Estimated ship cartons */
  if not exists (select * from #OrdersToCube where NumShipCartons is null)
    goto UpdateOrders;

  /* Compute number of possible cartons per order
     This can be obtained by taking the max value between TotalSpaceRequired is divided by MaxCartonSpace and
     TotalWeight is divided by MaxCartonWeight of that carton group */
  ;with CartonsMaxValues as
  (
    select CartonGroup, max(EmptyCartonSpace) as MaxCartonSpace, max(MaxWeight) as MaxCartonWeight
    from #CartonTypes
    group by CartonGroup
  ),
  EstimatedCartonsPerOrder as
  (
    select OTC.OrderId, OTC.PackingGroup, dbo.fn_MaxInt(sum(ceiling(TotalSpaceRequired * 1.0 / MaxCartonSpace)), sum(ceiling(TotalWeight * 1.0 / MaxCartonWeight))) as EstimatedCartons
    from #OrdersToCube OTC
      join CartonsMaxValues CM on OTC.OrderCartonGroup = CM.CartonGroup
    where NumShipCartons is null
    group by OTC.OrderId, OTC.PackingGroup
  )
  update OTC
  set NumShipCartons = EC.EstimatedCartons
  from #OrdersToCube OTC
    join EstimatedCartonsPerOrder EC on EC.OrderId = OTC.OrderId and
                                        EC.PackingGroup = OTC.PackingGroup;

UpdateOrders:
  /* By now we will have estimated cartons for each packing group of OrderId summarize them and
     update on the order header */
  ;with TotalEstimatedCartons as
  (
    select OrderId, sum(NumShipCartons) as TotalEstimatedCartons
    from #OrdersToCube
    group by OrderId
  )
  update OH
  set EstimatedCartons = TEC.TotalEstimatedCartons
  from OrderHeaders OH
    join TotalEstimatedCartons TEC on OH.OrderId = TEC.OrderId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_EstimatedCartonsByVolume */

Go
