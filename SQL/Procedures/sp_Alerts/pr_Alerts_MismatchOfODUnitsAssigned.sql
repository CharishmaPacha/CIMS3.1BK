/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/24  RKC     pr_Alerts_MismatchOfODUnitsAssigned: Made changes to resolve issue with partial shipments orders (BK-641)
  2021/07/05  PK/YJ   pr_Alerts_MismatchOfODUnitsAssigned: ported changes from prod onsite (HA-2964)
  2021/06/10  AY      pr_Alerts_MismatchOfODUnitsAssigned: Resolve issue with partial shipments (HA-2865)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_MismatchOfODUnitsAssigned') is not null
  drop Procedure pr_Alerts_MismatchOfODUnitsAssigned;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_MismatchOfODUnitsAssigned:
    Evaluates the OD units assigned v Task details created and LPN details assigned.
    Sends alert, if there are any discrepencies

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last X minutes
  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only
  @EntityId
    - If passed, ignores all other entities by considering the passed in EntityId
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_MismatchOfODUnitsAssigned
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
As
  declare  @vAlertCategory   TCategory;

  declare @ttAlertData table (WaveId         TRecordId,
                              WaveNo         TWaveNo,
                              WaveType       TTypeCode,
                              OrderId        TRecordId,
                              PickTicket     TPickTicket,
                              OrderStatus    TDescription,
                              OrderDetailid  TRecordId,
                              SKUId          TRecordId,
                              SKU            TSKU,
                              BusinessUnit   TBusinessUnit,
                              ToShip         TQuantity,
                              UnitsAssigned  TQuantity,
                              UnitsShipped   TQuantity,
                              TaskDtlQty     TQuantity,
                              FromLPNQty     TQuantity,
                              ToLPNResQty    TQuantity,
                              ToLPNUnResQty  TQuantity,
                              AlertDesc      TVarChar);
begin
  select @vAlertCategory = Object_Name(@@ProcId);  -- pr_ will be trimmed by pr_Email_SendDBAlert

  -- /* Temporary tables */
  -- select * into #MismatchOfODUnits from @ttAlertData;
  -- alter table #MismatchOfODUnits add Alert as case when AlertDesc is not null then 'Y' else 'N' end;

  /* Get Order Detail list */
  insert into @ttAlertData (WaveId, WaveNo, WaveType, OrderId, PickTicket, OrderStatus,
                            OrderDetailid, SKUId, SKU, BusinessUnit,
                            /* OD quantities */
                            ToShip, UnitsAssigned, UnitsShipped,
                            /* LPN quantities */
                            TaskDtlQty, FromLPNQty, ToLPNResQty, ToLPNUnResQty)
    select W.WaveId, W.WaveNo, W.WaveType, OH.OrderId, OH.PickTicket, OH.Status,
           OD.OrderDetailId, OD.SKUId, SK.SKU, @BusinessUnit,
           OD.UnitsAuthorizedToShip, OD.UnitsAssigned, OD.UnitsShipped,
           null, null, null, null
    from OrderHeaders OH   with (nolock)
      join OrderDetails OD with (nolock) on OD.OrderId = OH.OrderId
      join Waves W         with (nolock) on OH.PickBatchId = W.WaveId
      join SKUs SK         with (nolock) on OD.SKUId = SK.SKUId
    where (OH.PickBatchId = coalesce(@EntityId, OH.PickBatchId)) and
          (OH.OrderType not in ('RU', 'RP', 'B' /* Replenish, Bulk */))  and
          (OH.Status not in ('N', 'W', 'S', 'X' /* Shipped, Cancelled */)) and
          (OH.Archived = 'N' /* No */);

  /* Get LPN quantities grouped by Order Detail */
  ;with TaskQtybyOrderDetail (OrderDetailId, TaskDtlQty)
  as
  (
    select TT.OrderDetailId, sum(TD.Quantity)
    from @ttAlertData TT
      join TaskDetails TD with (nolock) on TT.OrderDetailId = TD.OrderDetailId and TD.Status not in ('X')
    group by TT.OrderDetailId
  ),
  LPNQtybyOrderDetail (OrderDetailId, FromLPNQty, ToLPNResQty, ToLPNUnResQty)
  as
  (
    select TT.OrderDetailId,
           sum(case when L.LPNType <> 'S' /* ShipCarton */ and L.Status <> 'S' /* Shipped */ and LD.OnhandStatus <> 'U' /* Unavailable */ then LD.Quantity else 0 end),
           sum(case when L.LPNType = 'S' /* ShipCarton */ and L.Status not in ('S', 'V' /* Shipped, Voided */) and LD.OnhandStatus <> 'U' /* Unavailable */ then LD.ReservedQty else 0 end),
           sum(case when L.LPNType = 'S' /* ShipCarton */ and L.Status <> 'V' /* Voided */ then LD.AllocableQty else 0 end)
    from @ttAlertData TT
      left join LPNDetails LD with (nolock) on TT.OrderId = LD.OrderId and TT.OrderDetailId = LD.OrderDetailId
      left join LPNs L        with (nolock) on LD.LPNId = L.LPNId
    group by TT.OrderDetailId
  )
  /* Update task or LPN quantities */
  update TT
  set TT.TaskDtlQty    = coalesce(TCTE.TaskDtlQty, 0),
      TT.FromLPNQty    = coalesce(LCTE.FromLPNQty, 0),
      TT.ToLPNResQty   = coalesce(LCTE.ToLPNResQty, 0),
      TT.ToLPNUnResQty = coalesce(LCTE.ToLPNUnResQty, 0)
  from @ttAlertData TT
    join TaskQtybyOrderDetail TCTE on TT.OrderDetailId = TCTE.OrderDetailId
    join LPNQtybyOrderDetail LCTE on TT.OrderDetailId = LCTE.OrderDetailId;

  /* Evaluate the data */
  update @ttAlertdata
  set AlertDesc = 'Task Dtl Qty and Order Detail Qty mismatch'
  where (TaskDtlQty < UnitsAssigned) and (TaskDtlQty > 0);

  update @ttAlertdata
  set AlertDesc = concat_ws(', ', AlertDesc, 'Units To Pick + Picked + Already Shipped <> OD Units Assigned')
  where (FromLPNQty + ToLPNResQty + UnitsShipped <> UnitsAssigned);

  /* Insert details of mismatched Units Assigned */
  select TT.WaveNo, TT.WaveType, TT.PickTicket, TT.OrderId, TT.OrderStatus,
         TT.OrderDetailid, TT.SKUId, TT.SKU, TT.ToShip, TT.UnitsAssigned,
         TT.TaskDtlQty, TT.FromLPNQty, TT.ToLPNResQty, TT.ToLPNUnResQty, TT.AlertDesc
  into #MismatchOfODUnits
  from @ttAlertData TT
  where (AlertDesc is not null)
  order by TT.OrderId, TT.SKUId;

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #MismatchOfODUnits;
      return(0);
    end

  /* Email the results */
  if (exists(select * from #MismatchOfODUnits))
    exec pr_Email_SendQueryResults @vAlertCategory, '#MismatchOfODUnits', null /* order by */, @BusinessUnit;
end /* pr_Alerts_MismatchOfODUnitsAssigned */

Go
