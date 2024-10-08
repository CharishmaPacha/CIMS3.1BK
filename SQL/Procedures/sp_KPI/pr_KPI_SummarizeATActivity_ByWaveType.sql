/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_SummarizeATActivity_ByWaveType') is not null
  drop Procedure pr_KPI_SummarizeATActivity_ByWaveType;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_SummarizeATActivity_ByWaveType: Summarizes info from AudiTrail-AuditDetails
    for the given activity by WaveType
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_SummarizeATActivity_ByWaveType
  (@ActivityDate       TDate,
   @Operation          TOperation,
   @ActivityType       TActivityType,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin /* pr_KPI_SummarizeATActivity_ByWaveType */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Log summarized details of LPN reservations done on requested date */
  insert into KPIs (Operation, SubOperation1, ActivityDate, Warehouse, Ownership,
                    NumWaves, NumOrders, NumLocations, NumPallets, NumLPNs,
                    NumInnerPacks, NumUnits, NumSKUs, BusinessUnit, CreatedBy)
    select @Operation, W.WaveType, AT.ProductionDate, AD.Warehouse, AD.Ownership,
            count(distinct AD.WaveId), count(distinct OrderId),
            count(distinct AD.Location), count(distinct AD.PalletId), count(distinct AD.LPNId),
            sum(AD.Innerpacks), sum(AD.Quantity), count(distinct AD.SKUId), @BusinessUnit, @UserId
    from AuditTrail AT
      join AuditDetails AD on (AT.AuditId = AD.AuditId)
      join Waves W on (AD.WaveId = W.WaveId)
    where (AT.ActivityType   = @ActivityType) and
          (AT.ProductionDate = @ActivityDate) and
          (AT.BusinessUnit   = @BusinessUnit)
    group by W.WaveType, AT.ProductionDate, AD.Warehouse, AD.Ownership;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_SummarizeATActivity_ByWaveType */

Go
