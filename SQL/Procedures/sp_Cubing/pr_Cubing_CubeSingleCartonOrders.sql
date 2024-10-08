/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/25  TK      pr_Cubing_CubeSingleCartonOrders: Fixed issue with cubing single carton orders (HA-2838)
  2021/04/09  RKC/TK  pr_Cubing_CubeSingleCartonOrders: Bug fix in generating duplicate cartons for order having mutiple inventory class (HA-2582)
  2021/02/21  TK      pr_Cubing_CubeSingleCartonOrders: Ignore orders having to be cubed into standart boxes or units (BK-217)
  2020/10/06  TK      pr_Cubing_CubeSingleCartonOrders: Initial Revision (HA-1487)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_CubeSingleCartonOrders') is not null
  drop Procedure pr_Cubing_CubeSingleCartonOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Cubing_CubeSingleCartonOrders evaluates whether the order can be fit into a single carton
    and if they can be fit into a single carton then they will be cubed right away instead of
    cubing each order detail to a carton using while loop
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_CubeSingleCartonOrders
  (@WaveId           TRecordId,
   @Operation        TOperation   = null,
   @BusinessUnit     TBusinessUnit,
   @Debug            TFlags       = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Check if there are any orders that can be fit into a single carton, if they can be fit
     then update carton type on them */
  ;with CartonTypesToCube as
   (
     /* Get all the orders and the possible carton types for each order+packinggroup
        sorted by the carton size i.e. the smallest carton first. If all the lines
        of the Order+PackingGroup cannot fit into the largest carton those are excluded
        here and cubed later */
     select OTC.OrderId, OTC.PackingGroup, CT.CartonType,
            row_number() over (partition by OTC.OrderId, OTC.PackingGroup order by EmptyCartonSpace) as RecordId  -- Partitions the dataset by LPNId and orders the dataset by EmptyCartonSpace ascending
     from #OrdersToCube OTC
       join #CartonTypes CT on (OTC.OrderCartonGroup = CT.CartonGroup)
     where (CT.EmptyCartonSpace >= OTC.TotalSpaceRequired) and
           (CT.FirstDimension   >= OTC.MaxFirstDimension ) and
           (CT.SecondDimension  >= OTC.MaxSecondDimension) and
           (CT.ThirdDimension   >= OTC.MaxThirdDimension ) and
           (CT.MaxWeight        >= OTC.TotalWeight       ) and
           (CT.MaxUnits         >= OTC.TotalQtyToCube    )
   )
   update DTC
   set CartonType = CTC.CartonType,
       CubedQty   = QtyToCube,
       Status     = 'C' /* Cubed */
   from #DetailsToCube DTC
     join CartonTypesToCube CTC on (DTC.OrderId      = CTC.OrderId     ) and
                                   (DTC.PackingGroup = CTC.PackingGroup) and
                                   (CTC.RecordId = 1)  -- which means take the carton type of the first record as CartonTypesToCube will have all applicable carton types for each packing group on order
      -- If there are any SKUs with CartonGroup as 'STD_UNIT' or 'STD_BOX' then they may not go into a single carton so ignore them here and process as usual
     left outer join #OrdersToCube OTC on (DTC.OrderId = OTC.OrderId) and (DTC.SKUCartonGroup in ('STD_UNIT', 'STD_BOX'))
   where (OTC.OrderId is null);

  /* If the order can be cubed into any carton then they will have carton type updated on them
     so if there is a carton type then add then to create cartons */
  insert into #CubeCartonHdrs (CartonType, WaveId, WaveNo, OrderId, PickTicket, SalesOrder,
                               Status, Ownership, Warehouse, PackingGroup,
                               InventoryClass1, InventoryClass2, InventoryClass3)
    select CartonType, min(WaveId), min(WaveNo), OrderId, min(PickTicket), min(SalesOrder),
           'C' /* Closed */, min(Ownership), min(Warehouse), PackingGroup,
           min(InventoryClass1), min(InventoryClass2), min(InventoryClass3)
    from #DetailsToCube
    where (CartonType is not null) and
          (Status = 'C' /* Cubed */)
    group by OrderId, PackingGroup, CartonType;

  /* Add details to the cartons that are cubed above */
  insert into #CubeCartonDtls (CartonId, SKUId, SKU, SpacePerIP, SpacePerUnit, WeightPerIP, WeightPerUnit, UnitsPerIP, NestingFactor, UnitsCubed, UniqueId)
    select CH.CartonId, DTC.SKUId, DTC.SKU, DTC.SpacePerIP, DTC.SpacePerUnit, DTC.InnerPackWeight, DTC.UnitWeight, DTC.UnitsPerIP, DTC.NestingFactor, DTC.CubedQty, DTC.UniqueId
    from #DetailsToCube DTC
      join #CubeCartonHdrs CH on (DTC.OrderId = CH.OrderId) and
                                 (DTC.PackingGroup = CH.PackingGroup)
    where (DTC.CartonType is not null) and
          (DTC.Status = 'C' /* Cubed */);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Cubing_CubeSingleCartonOrders */

Go
