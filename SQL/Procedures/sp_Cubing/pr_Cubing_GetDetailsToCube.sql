/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/01  TK      pr_Cubing_GetDetailsToCube: Changes to use carton group on orders (HA-2525)
  2021/03/17  TK      pr_Cubing_GetDetailsToCube: Populate ShipPack (HA-GoLive)
  2021/02/21  TK      pr_Cubing_GetDetailsToCube: Update SKUCartonGroup and PackingGroup as needed
                      pr_Cubing_CubeSingleCartonOrders: Ignore orders having to be cubed into standart boxes or units (BK-217)
  2021/02/16  TK      pr_Cubing_Execute & pr_Cubing_GetDetailsToCube:
                        Changes to use SKU dimensions based upon control variable (HA-1964)
  2020/10/13  TK      pr_Cubing_GetDetailsToCube: Compute weight only for the quantity to be cubed (HA-1582)
                      pr_Cubing_GetDetailsToCube: Changes to load SKUs dimensions into temp table (HA-1446)
  2020/06/05  TK      pr_Cubing_Execute & pr_Cubing_GetDetailsToCube:
                        Changes to update inventory class on Ship Cartons (HA-829)
  2020/04/25  TK      pr_Cubing_GetDetailsToCube: Initial Revision (HA-171)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_GetDetailsToCube') is not null
  drop Procedure pr_Cubing_GetDetailsToCube;
Go
/*------------------------------------------------------------------------------
  Proc pr_Cubing_GetDetailsToCube inserts all order details or task details to be cubed
    for the given wave into hash/temp table
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_GetDetailsToCube
  (@WaveId               TRecordId,
   @Operation            TOperation,
   @BusinessUnit         TBusinessUnit)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vUseSKUDimensions    TControlValue;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get controls */
  select @vUseSKUDimensions = dbo.fn_Controls_GetAsString('Cubing', 'UseSKUDimensions', 'Y' /* Yes */, @BusinessUnit, system_user);

  /* Insert Task Details into temp table to work */
  if (@Operation = 'CubeTaskDetails')
    insert into #DetailsToCube(WaveId, WaveNo, TaskId, TaskDetailId, SKUId, SKU, OrderId, OrderDetailId, PickTicket, SalesOrder, OrderCartonGroup,
                               AllocatedQty, SpacePerUnit, SpacePerIP, UnitWeight, InnerPackWeight, UnitsPerIP,
                               ProdCategory, ProdSubCategory, NestingFactor, ShipPack, Ownership, Warehouse, UniqueId, PickType,
                               InventoryClass1, InventoryClass2, InventoryClass3, PackingGroup, Status)
      select TD.WaveId, TD.PickBatchNo, TD.TaskId, TD.TaskDetailId, TD.SKUId, S.SKU, TD.OrderId, TD.OrderDetailId, OH.PickTicket, OH.SalesOrder, OH.CartonGroups,
             TD.Quantity, coalesce(nullif(S.UnitVolume, '0'), 1), S.InnerPackVolume, S.UnitWeight, S.InnerPackWeight,
             S.UnitsPerInnerPack, S.ProdCategory, S.ProdSubCategory, S.NestingFactor, S.ShipPack,
             OH.Ownership, OH.Warehouse, TD.TaskDetailId, TD.PickType,
             OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3, coalesce(TD.PackingGroup, ''), 'A' /* Active */
      from TaskDetails TD
        join SKUs         S   on (S.SKUId = TD.SKUId)
        join OrderHeaders OH  on (OH.OrderId = TD.OrderId)
        join OrderDetails OD  on (OD.OrderDetailId = TD.OrderDetailId)
        left outer join Locations    LOC on (TD.LocationId = LOC.LocationId)
      where (TD.WaveId = @WaveId) and
            (TD.TaskId      = 0            ) and
            (TD.Status not in ('X'/* Canceled */)) and    -- Due to some unexpected errors TDs are created but Tasks are not created, so when cancelled those TDs and tried to reallocate wave it is not allowing to ignore canceled TDs
            (TD.TempLabelId is null        ) and          -- Consider Task Details which are not cubed
            (TD.PackingGroup <> 'DoNotCube')
      order by TD.OrderId, TD.PackingGroup, LOC.PickingZone, LOC.PickPath, S.UnitVolume Desc;
  else
  /* Insert Order Details into temp table to work */
  if (@Operation = 'CubeOrderDetails')
    begin
       /* disregard the order details that are already cubed
          do not consider shipped orders */
      ;with CubedUnits as
       (
         select OD.OrderId, OD.OrderDetailId, sum(LD.Quantity) as QtyCubed
         from OrderHeaders OH
           join OrderDetails OD on (OD.OrderId = OH.OrderId)
           join LPNDetails   LD on (LD.OrderId = OD.OrderId) and (LD.OrderDetailId = OD.OrderDetailId) -- for performance
           join LPNs         L  on (L.LPNId = LD.LPNId)
         where (OH.PickBatchId = @WaveId) and
               (OH.Status not in ('S', 'X', 'D' /* Shipped, Canceled, Completed */)) and
               (LD.OnhandStatus = 'U') and
               (L.Status not in ('S' /* Shipped */))
         group by OD.OrderId, OD.OrderDetailId
       )
       insert into #DetailsToCube(WaveId, WaveNo, SKUId, SKU, OrderId, OrderDetailId, PickTicket, SalesOrder, OrderCartonGroup,
                                  AllocatedQty, SpacePerUnit, SpacePerIP, UnitWeight, InnerPackWeight, UnitsPerIP,
                                  ProdCategory, ProdSubCategory, NestingFactor, ShipPack, Ownership, Warehouse, UniqueId,
                                  InventoryClass1, InventoryClass2, InventoryClass3, PackingGroup, Status)
         select OH.PickBatchId, OH.PickBatchNo, OD.SKUId, S.SKU, OH.OrderId, OD.OrderDetailId, OH.PickTicket, OH.SalesOrder, OH.CartonGroups,
                (OD.UnitsToAllocate - coalesce(QtyCubed, 0)), coalesce(nullif(S.UnitVolume, '0'), 1), S.InnerPackVolume,
                S.UnitWeight, S.InnerPackWeight, S.UnitsPerInnerPack, S.ProdCategory, S.ProdSubCategory, S.NestingFactor, S.ShipPack,
                OH.Ownership, OH.Warehouse, OD.OrderDetailId, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3, coalesce(OD.PackingGroup, ''), 'A' /* Active */
         from OrderDetails OD
           left outer join CubedUnits CU on (OD.OrderDetailId = CU.OrderDetailId)
           join OrderHeaders OH  on (OD.OrderId = OH.OrderId)
           join SKUs         S   on (S.SKUId = OD.SKUId)
         where (OH.PickBatchId = @WaveId) and
               (OH.OrderType <> 'B'/* Bulk */) and
               (OD.PackingGroup <> 'DoNotCube') and
               (OD.UnitsToAllocate - coalesce(QtyCubed, 0) > 0)
         order by OD.OrderId, OD.PackingGroup, S.UnitVolume Desc;
    end

  /* Update SKU Dimensions */
  update DTC
  set FirstDimension  = case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.FirstNumber  else 0.1 end, /* If SKU dims cannot be used then update with least value */
      SecondDimension = case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.SecondNumber else 0.1 end,
      ThirdDimension  = case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.ThirdNumber  else 0.1 end,
      SKUCartonGroup  = S.CartonGroup,
      PackingGroup    = case when S.CartonGroup in ('STD_UNIT', 'STD_BOX') then S.CartonGroup else PackingGroup end  -- Standard boxes or units should go into separate cartons
  from #DetailsToCube DTC
    join SKUs S on (DTC.SKUId = S.SKUId)
    cross apply dbo.fn_SortValuesAscending(S.UnitLength, S.UnitWidth, S.UnitHeight) FN;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Cubing_GetDetailsToCube */

Go
