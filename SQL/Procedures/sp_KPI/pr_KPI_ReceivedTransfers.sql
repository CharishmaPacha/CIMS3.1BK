/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_ReceivedTransfers') is not null
  drop Procedure pr_KPI_ReceivedTransfers;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_ReceivedTransfers: Gather the daily statistics for Transfers Receiving
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_ReceivedTransfers
  (@ActivityDate       TDate,
   @ttActivity         TInputParams READONLY,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin /* pr_KPI_ReceivedTransfers */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Log received details  */
  insert into KPIs (Operation, SubOperation1, SubOperation2, ActivityDate, Warehouse, Ownership,
                    NumOrders, NumPallets, NumLPNs, NumInnerpacks, NumUnits, NumSKUs,
                    BusinessUnit, CreatedBy)
     select 'Receiving', 'Transfer', OH.ShipToName, AT.ProductionDate, AD.Warehouse, AD.Ownership,
            count(distinct AD.OrderId), count(distinct AD.PalletId), count(distinct AD.LPNId),
            sum(AD.Innerpacks), sum(AD.Quantity), count(distinct AD.SKUId), @BusinessUnit, @UserId
    from AuditTrail AT
      join @ttActivity ATC on (ATC.ParamValue = AT.ActivityType)
      left outer join AuditDetails AD on (AT.AuditId = AD.AuditId)
      left outer join OrderHeaders OH on (AD.OrderId = OH.OrderId)
    where (AT.ProductionDate = @ActivityDate) and
          (AT.BusinessUnit   = @BusinessUnit) and
          (AD.Warehouse in ('60')) and
          (AD.ToWarehouse not in ('60'))
    group by AT.ProductionDate, AD.Warehouse, AD.Ownership, OH.ShipToName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_ReceivedTransfers */

Go
