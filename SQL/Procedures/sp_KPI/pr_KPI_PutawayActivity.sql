/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_PutawayActivity') is not null
  drop Procedure pr_KPI_PutawayActivity;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_PutawayActivity: Summarizes info from AudiTrail-AuditDetails
    for the putaway activity
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_PutawayActivity
  (@ActivityDate       TDate,
   @Operation          TOperation,
   @ttActivity         TInputParams READONLY,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin /* pr_KPI_PutawayActivity */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Log summarized details of Putaway transactions done on requested date */
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
          (AT.BusinessUnit   = @BusinessUnit) and
          (AD.OrderId is null)   -- Consider operation as putaway only when Entity that has been putaway doesn't have order info
    group by AT.ProductionDate, AD.Warehouse, AD.Ownership;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_PutawayActivity */

Go
