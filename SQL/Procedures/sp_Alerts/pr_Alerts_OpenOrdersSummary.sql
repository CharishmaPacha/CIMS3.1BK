/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/27  AY      pr_Alerts_OpenOrdersSummary: Changed to show Orders shipped today.
  2018/09/13  VM      pr_Alerts_OpenOrdersSummary: Enhanced to show $Value (SalesAmount) as well (OB2-634)
  2018/08/01  VM      Added pr_Alerts_OpenOrdersSummary (S2G-1066)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_OpenOrdersSummary') is not null
  drop Procedure pr_Alerts_OpenOrdersSummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_OpenOrdersSummary:
    This alert is pretty much used for an existing client
    when client is going live with an version upgrade/a new module introduced etc,
    to have the summary of open orders for us to anaylyse.

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last X minutes
  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only
  @EntityId
    - If passed, ignores all other entities by considering the passed in EntityId
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_OpenOrdersSummary
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
As
  declare @vAlertCategory   TCategory;

  declare @ttOpenOrdersSummary table (OrderCategory1   TCategory,
                                      OrderStatus      TStatus,
                                      OrderCount       TCount,

                                      Ordered          TCount,
                                      SalesAmount      TMoney,
                                      Assigned         TDescription,
                                      Picked           TDescription,
                                      Packed           TDescription,
                                      Loaded           TDescription,
                                      Staged           TDescription,
                                      Shipped          TDescription,

                                      RecordId         TRecordId identity (1,1));

begin
  select @vAlertCategory   = Object_Name(@@ProcId);  -- pr_ will be trimmed by pr_Email_SendDBAlert

  select * into #OpenOrdersSummary from @ttOpenOrdersSummary;

  /* Get the totals of all D Lines */
  insert into #OpenOrdersSummary(OrderCategory1, OrderStatus, OrderCount, Ordered, SalesAmount,
                                   Assigned, Picked, Packed, Loaded, Staged, Shipped)
    select min(OH.OrderCategory1), OS.StatusDescription, count(*), sum(OH.NumUnits),
           coalesce(nullif(sum(OH.TotalSalesAmount), 0), ''),
           coalesce(nullif(cast(sum(OH.LPNsAssigned) as varchar) + '/' + cast(sum(OH.UnitsAssigned) as varchar), '0/0'), ''),
           coalesce(nullif(cast(sum(OH.LPNsPicked)   as varchar) + '/' + cast(sum(OH.UnitsPicked)   as varchar), '0/0'), ''),
           coalesce(nullif(cast(sum(OH.LPNsPacked)   as varchar) + '/' + cast(sum(OH.UnitsPacked)   as varchar), '0/0'), ''),
           coalesce(nullif(cast(sum(OH.LPNsLoaded)   as varchar) + '/' + cast(sum(OH.UnitsLoaded)   as varchar), '0/0'), ''),
           coalesce(nullif(cast(sum(OH.LPNsStaged)   as varchar) + '/' + cast(sum(OH.UnitsStaged)   as varchar), '0/0'), ''),
           coalesce(nullif(cast(sum(OH.LPNsShipped)  as varchar) + '/' + cast(sum(OH.UnitsShipped)  as varchar), '0/0'), '')
    from OrderHeaders OH        with (nolock)
    left outer join Statuses OS with (nolock) on (OS.StatusCode    = OH.Status      ) and
                                                 (OS.Entity        = 'Order'        ) and
                                                 (OS.BusinessUnit  = OH.BusinessUnit)
    where (OH.Status not in ('S', 'D', 'X')) or
          (OH.Status = 'S' and cast(ShippedDate as date) = cast(getdate() as date))
    group by OH.OrderCategory1, OS.SortSeq, OS.StatusDescription
    order by OH.OrderCategory1, OS.SortSeq;

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #OpenOrdersSummary
      order by OrderCategory1;

      return(0);
    end

  /* Email the results */
  if (exists (select * from #OpenOrdersSummary))
    exec pr_Email_SendQueryResults @vAlertCategory, '#OpenOrdersSummary', null /* order by */, @BusinessUnit;
end /* pr_Alerts_OpenOrdersSummary */

Go
