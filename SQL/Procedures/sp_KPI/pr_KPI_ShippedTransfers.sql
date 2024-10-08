/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_ShippedTransfers') is not null
  drop Procedure pr_KPI_ShippedTransfers;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_ShippedTransfers: Gather the daily statistics for Receiving
    based upon the Receivers closed for the given date.
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_ShippedTransfers
  (@ActivityDate       TDate,
   @ttActivity         TInputParams READONLY,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin /* pr_KPI_ShippedTransfers */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Log shipped details  */
  insert into KPIs (Operation, SubOperation1, SubOperation2, ActivityDate, Warehouse, Ownership,
                    NumWaves, NumOrders, NumPallets, NumLPNs, NumInnerpacks, NumUnits, NumSKUs,
                    BusinessUnit, CreatedBy)
    select 'Shipping', 'Transfer', OH.ShipToName, AT.ProductionDate, AD.Warehouse, AD.Ownership,
            count(distinct AD.WaveId), count(distinct AD.OrderId), count(distinct AD.PalletId), count(distinct AD.LPNId),
            sum(AD.Innerpacks), sum(AD.Quantity), count(distinct AD.SKUId), @BusinessUnit, @UserId
    from AuditTrail AT
      join @ttActivity ATC on (ATC.ParamValue = AT.ActivityType)
      left outer join AuditDetails AD on (AT.AuditId = AD.AuditId)
      left outer join OrderHeaders OH on (AD.OrderId = OH.OrderId)
    where (AT.ProductionDate = @ActivityDate) and
          (AT.BusinessUnit   = @BusinessUnit) and
          (AD.Warehouse not in ('60')) and  -- Transfers when shipped will be moved to Intransit Warehouse '60'
          (AD.ToWarehouse in ('60'))
    group by AT.ProductionDate, AD.Warehouse, AD.Ownership, OH.ShipToName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_ShippedTransfers */

Go
