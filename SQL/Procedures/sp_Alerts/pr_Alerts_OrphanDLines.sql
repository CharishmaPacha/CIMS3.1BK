/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/18  TK      pr_Alerts_OrphanDLines: Fixed bug to consider data in hash table (HA-GoLive)
  2018/03/12  VM      Added pr_Alerts_OrphanDLines (S2G-391)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_OrphanDLines') is not null
  drop Procedure pr_Alerts_OrphanDLines;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_OrphanDLines:
    Identifies orphan D (Directed) lines on picklane Locations.
    Sends alert, if there are are orphan D lines.

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last X minutes
  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only
  @EntityId
    - If passed, ignores all other entities by considering the passed in EntityId
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_OrphanDLines
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
As
  declare @vAlertCategory   TCategory,
          @vEmailSubject    TDescription,
          @vEmailBody       varchar(max),
          @vFieldCaptions   varchar(max),
          @vFieldValuesXML  varchar(max);

  declare @ttDLines table (SKUId        TRecordId,
                           SKU          TSKU,
                           LPN          TLPN,
                           LPNID        TRecordId,
                           ReplOrderID  TRecordId,
                           OnhandStatus TStatus,
                           Quantity     TInteger,
                           DQty         TInteger,
                           RecordId     TRecordId identity (1,1));

  declare @ttReplenishments table (ROrderId    TRecordId,
                                   RPickTicket TPickTicket,
                                   SKUId       TRecordId,
                                   ReplenQty   Tinteger,
                                   RecordId    TRecordId identity (1,1));

  declare @ttOtherReplenishments table (DestLocation TLocation,
                                        SKUId        TRecordId,
                                        ReplenQty    Tinteger,
                                        RecordId     TRecordId identity (1,1));
begin
  select @vAlertCategory   = Object_Name(@@ProcId); -- pr_ will be trimmed by pr_Email_SendDBAlert

  select * into #DLines from @ttDLines;

  /* Get the totals of all D Lines */
  insert into #DLines(SKUId, SKU, LPN, LPNId, ReplOrderID, OnhandStatus, Quantity, DQty)
    select LD.SKUId, LD.SKU, L.LPN, LD.LPNId, Min(LD.ReplenishOrderId), LD.OnhandStatus, sum(LD.Quantity),
      sum(case when LD.OnhandStatus = 'D' then LD.Quantity else 0 end) DQty
    from vwLPNDetails LD with (nolock) join LPNs L with (nolock) on (LD.LPNId = L.LPNId)
    where (LD.OnhandStatus in ('D', 'R')) and (L.LPNType = 'L' /* Logical */) and
          (datediff(mi, L.ModifiedDate, getdate()) <= @ShowModifiedInLastXMinutes) and
          (L.LPNId = coalesce(@EntityId, L.LPNId))
    group by LD.SKUId, LD.SKU, L.LPN, LD.LPNId, LD.ReplenishOrderId, LD.OnhandStatus

  /* All LPNs coming to the Location */
  insert into @ttReplenishments
    select LD.OrderId, LD.PickTicket, LD.SKUId, sum(LD.Quantity)
    from vwLPNDetails LD with (nolock)
      join (select distinct ReplorderId, SKUId from #DLines) D on (LD.OrderId = D.ReplOrderId) and (LD.SKUId = D.SKUId)
    group by LD.OrderId, LD.PickTicket, LD.SKUId;

  /* All LPNs coming to the Location without Replenish Order on them */
  insert into @ttOtherReplenishments(DestLocation, SKUId, ReplenQty)
    select LD.DestLocation, LD.SKUId, sum(LD.Quantity)
    from vwLPNDetails LD with (nolock)
      join (select distinct LPN, SKUId from #DLines) D on (LD.DestLocation = D.LPN)
    and LD.SKUId = D.SKUId
    where LD.OrderId is null
    group by LD.DestLocation, LD.SKUId;

  /* Compile the data to be reported into a temp table */
  select D.SKUId, D.SKU, D.LPNId, D.LPN, D.ReplOrderId as ReplenishOrderId,
         sum(D.DQty) as DQty, Min(R.ReplenQty) as ReplenishQty, Min(RO.ReplenQty) as OtherReplenishQty
  into #OrphanDLines
  from #DLines D
    left outer join (select ROrderId, SKUId, sum(coalesce(ReplenQty, 0)) ReplenQty from @ttReplenishments group by SKUId, ROrderId) R on D.SKUId = R.SKUId and D.ReplOrderId = R.ROrderId
    left outer join (select DestLocation, SKUId, sum(coalesce(ReplenQty, 0)) ReplenQty from @ttOtherReplenishments group by DestLocation, SKUId) RO on D.SKUId = RO.SKUId and D.LPN = RO.DestLocation
  where D.OnhandStatus in ('D')
  group by D.SKUId, D.SKU, D.LPN, D.LPNId, D.ReplOrderId
  having sum(D.Quantity) > (Min(coalesce(R.ReplenQty, 0)) + Min(coalesce(RO.ReplenQty, 0)))
  order by D.SKUId

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #OrphanDLines;
      return(0);
    end

  /* Send DB email, if there are any values captured */
  if (exists (select * from #OrphanDLines))
    exec pr_Email_SendQueryResults @vAlertCategory, '#OrphanDLines', null /* order by */, @BusinessUnit;
end /* pr_Alerts_OrphanDLines */

Go
