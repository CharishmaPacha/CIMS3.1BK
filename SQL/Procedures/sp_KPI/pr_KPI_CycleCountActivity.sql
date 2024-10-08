/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_CycleCountActivity') is not null
  drop Procedure pr_KPI_CycleCountActivity;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_CycleCountActivity: Gather the daily statistics for CycleCounting
    from the posted Cycle count results for the given date.
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_CycleCountActivity
  (@ActivityDate       TDate,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin /* pr_KPI_CycleCountActivity */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Add Cycle count summary */
  insert into KPIs (Operation, ActivityDate, Warehouse, Ownership,
                    NumLocations, NumPallets, NumLPNs, NumUnits,
                    NumSKUs, Count1, BusinessUnit, CreatedBy)
    select 'Cycle Counting',  TransactionDate, Warehouse, null,
           count(distinct LocationId), count(distinct PalletId), count(distinct LPNId), sum(FinalQuantity),
           count(distinct SKUId), sum(PrevQuantity), @BusinessUnit, @UserId
    from vwCycleCountResults
    where (TransactionDate = @ActivityDate) and
          (BusinessUnit = @BusinessUnit)
    group by TransactionDate, Warehouse;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_CycleCountActivity */

Go
