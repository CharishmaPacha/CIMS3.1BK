/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_Replenish_Status') is not null
  drop Procedure pr_DaB_Replenish_Status;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_Replenish_Status

------------------------------------------------------------------------------*/
Create Procedure pr_DaB_Replenish_Status
as
begin
  SET NOCOUNT ON;

  select case when ReplenishType = 'R' then 'Below Min' else 'Below Max' end as ReplenishType, StorageType, PutawayZone, PickZone, count(*) NumLocations,
    sum(MinUnitsToReplenish) MinUnits, sum(MinIPSToReplenish) MinIPS,
    sum(MaxUnitsToReplenish) MaxUnits, sum(MaxIPSToReplenish) MaxIPs
  from vwLocationsToReplenish
  group by ReplenishType, StorageType, PutawayZone, PickZone

end /* pr_DaB_Replenish_Status */

Go
