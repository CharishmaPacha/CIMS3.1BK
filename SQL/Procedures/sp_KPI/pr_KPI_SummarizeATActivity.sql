/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_SummarizeATActivity') is not null
  drop Procedure pr_KPI_SummarizeATActivity;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_SummarizeATActivity: Summarizes info from AudiTrail-AuditDetails
    for the given activity by WaveType
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_SummarizeATActivity
  (@ActivityDate       TDate,
   @Operation          TOperation,
   @ttActivity         TInputParams READONLY,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin /* pr_KPI_SummarizeATActivity */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Log summarized details of LPN reservations done on requested date */
  insert into KPIs (Operation, ActivityDate, Warehouse, Ownership,
                    NumWaves, NumOrders, NumReceipts,
                    NumLocations, NumPallets, NumLPNs,
                    NumInnerPacks, NumUnits, NumSKUs, BusinessUnit, CreatedBy)
    select @Operation, AT.ProductionDate, AD.Warehouse, AD.Ownership,
            count(distinct AD.WaveId), count(distinct AD.OrderId), count(distinct AD.ReceiptId),
            count(distinct AD.Location), count(distinct AD.PalletId), count(distinct AD.LPNId),
            sum(AD.Innerpacks), sum(AD.Quantity), count(distinct AD.SKUId), @BusinessUnit, @UserId
    from AuditTrail AT
      join @ttActivity ATC on (ATC.ParamValue = AT.ActivityType)
      left outer join AuditDetails AD on (AT.AuditId = AD.AuditId)
    where (AT.ProductionDate = @ActivityDate) and
          (AT.BusinessUnit   = @BusinessUnit)
    group by AT.ProductionDate, AD.Warehouse, AD.Ownership;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_SummarizeATActivity */

Go
