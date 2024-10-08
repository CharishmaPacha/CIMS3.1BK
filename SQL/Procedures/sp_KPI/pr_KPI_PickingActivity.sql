/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_PickingActivity') is not null
  drop Procedure pr_KPI_PickingActivity;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_PickingActivity: Gather the daily statistics for CycleCounting
    from Tasks and Task Details for the given date.
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_PickingActivity
  (@ActivityDate       TDate,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin /* pr_KPI_PickingActivity */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Insert picking summary into KPIs table */
  insert into KPIs (Operation, SubOperation1, ActivityDate, Warehouse, Ownership,
                    NumWaves, NumOrders, NumLocations, NumPallets, NumLPNs,
                    NumInnerPacks, NumUnits, NumTasks, NumPicks, BusinessUnit, CreatedBy)
    select 'Picking', W.WaveType, T.CompletedDate, T.Warehouse, T.Ownership,
           count(distinct T.WaveId), count(distinct TD.OrderId), count(distinct TD.LocationId),
           count(distinct TD.PalletId), count(distinct coalesce(TD.TemplabelId, TD.LPNId)), sum(TD.Innerpacks), sum(TD.Quantity),
           count(distinct T.TaskId), count(TD.TaskDetailId), @BusinessUnit, @UserId
    from TaskDetails TD
      join Tasks T on TD.TaskId = T.TaskId
      join Waves W on T.WaveId = W.WaveId
    where (T.CompletedDate = @ActivityDate) and
          (T.BusinessUnit = @BusinessUnit)
    group by W.WaveType, T.CompletedDate, T.Warehouse, T.Ownership;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_PickingActivity */

Go
