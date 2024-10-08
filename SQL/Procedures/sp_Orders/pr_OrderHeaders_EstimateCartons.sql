/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/26  TK      pr_OrderHeaders_EstimateCartons: Initial Revision (HA-2445)
                      pr_OrderHeaders_EstimateCartonsByUnitsPerCarton: Compute residual cartons for each carton group (HA-2446)
  2021/02/23  VS      pr_OrderHeaders_EstimateCartonsByVolume: Added SKU and Style/Color/Size in Validation message (HA-2013)
  2021/02/16  TK      pr_OrderHeaders_EstimateCartonsByUnitsPerCarton & pr_OrderHeaders_EstimateCartonsByVolume:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_EstimateCartons') is not null
  drop Procedure pr_OrderHeaders_EstimateCartons;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_EstimateCartons: This procedure identifies the estimation criteria and
    invokes appropriate procedures to estimate cartons for order

  #OrdersToEstimateCartons -> TEntityKeysTable
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_EstimateCartons
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName;

  declare @ttOrdersToPreProcess     TEntityKeysTable,
          @ttValidations            TValidations;
begin
  SET NOCOUNT ON;

  /* Create #Validations if it doesn't exist */
  if object_id('tempdb..#Validations') is null
    select * into #Validations from @ttValidations;

  /* If hash table doesn't exist then create one */
  if object_id('tempdb..#OrdersToEstimateCartons') is null return;

  /* Create required hash tables and add necessary columns */
  select * into #OrdersToPreProcess from @ttOrdersToPreProcess;

  /* Determine the EstimationCriteria for the selected PickTickets */
  exec pr_RuleSets_ExecuteRules 'OH_EstimateCartons', '' /* RulesData XML */;

  /* Calculate the Estimated cartons on the Order Headers */
  insert into #OrdersToPreProcess (EntityId)
    select distinct EntityId
    from #OrdersToEstimateCartons
    where (EstimationMethod = 'ByPackConfig');

  exec pr_OrderHeaders_EstimateCartonsByUnitsPerCarton @BusinessUnit, @UserId;

  /* Calculate the Estimated cartons on the Order Headers by Volume */
  delete from #OrdersToPreProcess;
  insert into #OrdersToPreProcess (EntityId)
    select distinct EntityId
    from #OrdersToEstimateCartons
    where (EstimationMethod = 'ByVolume');

  exec pr_OrderHeaders_EstimateCartonsByVolume @BusinessUnit, @UserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_EstimateCartons */

Go
