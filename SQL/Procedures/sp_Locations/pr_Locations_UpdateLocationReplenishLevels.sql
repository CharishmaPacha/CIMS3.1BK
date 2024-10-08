/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_UpdateLocationReplenishLevels') is not null
  drop Procedure pr_Locations_UpdateLocationReplenishLevels;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_UpdateLocationReplenishLevels:
  This procedure will get the data from SKUVelocity table and update the info on
    LocationReplenishLevels table. It is invoked from a job that typically runs
    once a week and updates the SKU velocity on the established Replenish levels.
    This would give an indication if the existing replenish levels are accurate
    or if they need to be adjusted based upon the velocity.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_UpdateLocationReplenishLevels
  (@BusinessUnit TBusinessUnit,
   @UserId       TName)
as
declare @vTodaysDate          TDate,
        @vPrevWeeksStartDate  TDate,
        @vPrevWeeksEndDate    TDate,
        @vPrevWeek2StartDate  TDate,
        @vPrevWeek2EndDate    TDate,
        @vPrevMonthStartDate  TDate,
        @vPrevMonthEndDate    TDate;
begin
  select @vTodaysDate         = current_timestamp,
         @vPrevWeeksStartDate = dateadd(day, -(datepart(weekday, getdate()) + 6),  getdate()), -- SUNDAY
         @vPrevWeeksEndDate   = dateadd(day, 1 - datepart(weekday, getdate()),     getdate()), -- SATURDAY
         @vPrevWeek2StartDate = dateadd(day, -(datepart(weekday, getdate()) + 13), getdate()),
         @vPrevWeek2EndDate   = dateadd(day, 1 - datepart(weekday, getdate()),     getdate()),
         @vPrevMonthStartDate = dateadd(month, datediff(month, 0,  getdate())-1, 0),    -- First day of previous month
         @vPrevMonthEndDate   = dateadd(month, datediff(month, -1, getdate())-1, -1);   -- Last day of previous month

  /* Previous week ShipInfo */
  ;with PrevWeekShipInfo as -- Prev week of SUN to SAT
  (
   select InventoryKey, min(SKUId) SKUId, sum(NumUnits) SV_PrevWeek, min(Warehouse) Warehouse, min(SKU) SKU
   from SKUVelocity
   where (TransDate >= @vPrevWeeksStartDate) and
         (TransDate <= @vPrevWeeksEndDate) and
         (VelocityType = 'SHIP')
   group by InventoryKey
  ),
  Prev2weekShipInfo as --Previous 2weeks ShipInfo
  (
   select InventoryKey, min(SKUId) SKUId, min(LocationId) LocationId, sum(NumUnits) SV_Prev2Week, min(Warehouse) Warehouse, min(SKU) SKU
   from SKUVelocity
   where (TransDate >= @vPrevWeek2StartDate) and
         (TransDate <= @vPrevWeek2EndDate) and
         (VelocityType = 'SHIP')
   group by InventoryKey
  ),
  PrevMonthShipInfo as --Previous month ShipInfo
  (
   select InventoryKey, min(SKUId) SKUId, min(LocationId) LocationId, sum(NumUnits) SV_PrevMonth, min(Warehouse) Warehouse, min(SKU) SKU
   from SKUVelocity
   where (TransDate >= @vPrevMonthStartDate) and
         (TransDate <= @vPrevMonthEndDate) and
         (VelocityType = 'SHIP')
   group by InventoryKey
  )
  select PW.SV_PrevWeek, P2W.SV_Prev2Week, PM.SV_PrevMonth,
         coalesce(PW.SKU, P2W.SKU, PM.SKU) as SKU, coalesce(PW.SKUId, P2W.SKUId, PM.SKUId) as SKUId,
         coalesce(PW.Warehouse, P2W.Warehouse, PM.Warehouse) as Warehouse,
         coalesce(PW.InventoryKey, P2W.InventoryKey, PM.InventoryKey) as InventoryKey
  into #LocationReplenishLevels
  from PrevweekShipInfo PW
    full outer join Prev2weekShipInfo P2W on (PW.InventoryKey  = P2W.InventoryKey)
    full outer join PrevMonthShipInfo PM  on (P2W.InventoryKey = PM.InventoryKey)

  /* If they are records not processed insert them into LocationReplenishLevels*/
  merge LocationReplenishLevels as LR1 using #LocationReplenishLevels as LR2 on (LR1.InventoryKey = LR2.InventoryKey)
  when matched
  then update set LR1.SV_PrevWeek  = LR2.SV_PrevWeek,
                  LR1.SV_Prev2Week = LR2.SV_Prev2Week,
                  LR1.SV_PrevMonth = LR2.SV_PrevMonth,
                  LR1.ModifiedDate = current_timestamp,
                  LR1.Modifiedby   = 'CIMSAgent'
  when not matched
  then
  insert (LocationId, Location, Warehouse, SKUId, SKU, InventoryKey, SV_PrevWeek, SV_Prev2Week, SV_PrevMonth,
          BusinessUnit, CreatedDate, Createdby)
  values (0, '', LR2.Warehouse, LR2.SKUId, LR2.SKU, LR2.InventoryKey, LR2.SV_PrevWeek, LR2.SV_Prev2Week, LR2.SV_PrevMonth,
          @BusinessUnit, current_timestamp, 'CIMSAgent');

end /* pr_Locations_UpdateLocationReplenishLevels */

Go
