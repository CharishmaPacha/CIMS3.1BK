/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/17  MS      pr_Alerts_LPNCountsMismatch: Bug fix to MismatchQtys (HA-1781)
  2020/07/10  VS      pr_Alerts_LPNCountsMismatch: Made Changes to get the Mismatch ReserveQty between LPN and LPNDetails (HA-1034)
  2018/04/04  VM      pr_Alerts_LPNCountsMismatch: Added more params and exclude LPNs which are in picking status (S2G-CRP)
                        Added pr_Alerts_LPNCountsMismatch (S2G-486)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_LPNCountsMismatch') is not null
  drop Procedure pr_Alerts_LPNCountsMismatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_LPNCountsMismatch:
    Evaluates the current counts on all LPNs and its lines.
    Sends alert, if there are any discrepencies

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last X minutes
  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only
  @EntityId
    - If passed, ignores all other entities by considering the passed in EntityId

   exec  pr_Alerts_LPNCountsMismatch 'BU', 'cIMSAgent', 43200, 'Y'
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_LPNCountsMismatch
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
As
  declare @vReturnCode      TInteger,
          @vMessageName     TMessage,
          @vRecordId        TRecordId;

  declare @vAlertCategory   TCategory;

  /* Temp table definition to capture the suspicious/bad data for building xml */
  declare @ttAlertData table (LPNId TRecordId, LPN TLPN, SKU TSKU, Status TDescription, OnhandStatus TDescription,
                              Mismatch1 TDescription, Mismatch2 TDescription, Mismatch3 TDescription,
                              Mismatch4 TDescription, Mismatch5 TDescription, Mismatch6 TDescription,
                              RecordId TRecordId Identity(1,1));
begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId)  -- pr_ will be trimmed by pr_Email_SendDBAlert

  select * into #LPNCountsMismatch from @ttAlertData;

  with LPNCounts(LPNId, LPN, SKU, Status, OnhandStatus, InnerPacks, Quantity, DirectedQty, ReservedQty, AllocableQty) as
  (
    /* select LPNs modified in the last @ShowModifiedInLastXMinutes mins as the alert is scheduled to run every 5 mins,
       we should get the LPNs only once and not repeatedly */
    select LPNId, LPN, SKU, StatusDescription, OnhandStatusDescription, InnerPacks, Quantity, DirectedQty, ReservedQty, AllocableQty
    from vwLPNs
    where (Status <> 'U' /* Picking */) and (LPNType <> 'L' /* Logical */) and (OnhandStatus <> 'U' /* Unavailable */) and
          (datediff(mi, ModifiedDate, getdate()) <= @ShowModifiedInLastXMinutes) and
          (LPNId = coalesce(@EntityId, LPNId))
  ),
  LPNDetailACounts(LPNId, OnhandStatus, AInnerPacks, AQuantity, AReservedQty, AAllocableQty) as
  (
    select LPNId, OnhandStatus, sum(InnerPacks), sum(Quantity), sum(ReservedQty), sum(AllocableQty)
    from LPNDetails with (nolock)
    where (OnhandStatus = 'A' /* Available */)
    group by LPNId, OnhandStatus
  ),
  LPNDetailRCounts(LPNId, OnhandStatus, RInnerPacks, RQuantity, RReservedQty, RAllocableQty) as
  (
    select LPNId, OnhandStatus, sum(InnerPacks), sum(Quantity), sum(ReservedQty), sum(AllocableQty)
    from LPNDetails with (nolock)
    where (OnhandStatus = 'R' /* Reserved */)
    group by LPNId, OnhandStatus
  ),
  LPNDetailDCounts(LPNId, OnhandStatus, RInnerPacks, DQuantity, RReservedQty, RAllocableQty) as
  (
    select LPNId, OnhandStatus, sum(InnerPacks), sum(Quantity), sum(ReservedQty), sum(AllocableQty)
    from LPNDetails with (nolock)
    where (OnhandStatus = 'D' /* Directed */)
    group by LPNId, OnhandStatus
  )
  insert into #LPNCountsMismatch (LPNId, LPN, SKU, Status, OnhandStatus, Mismatch1, MisMatch2, Mismatch3, Mismatch4, Mismatch5, Mismatch6)
    select /* Header Info */
           LC.LPNId, LC.LPN, LC.SKU, LC.Status, LC.OnhandStatus,
           /* Mismatches */
           case
             when (coalesce(LC.InnerPacks, 0) > (coalesce(LC.Quantity, 0))) then
               'IPs greater than Qty on header ' + '(L.IPs greater L.Qty) ' +
               '(' + cast(coalesce(LC.InnerPacks, 0) as varchar) + ' != ' + cast(coalesce(LC.Quantity, 0) as varchar) + ')'
           end,
           case
             when (coalesce(LC.InnerPacks, 0) <> (coalesce(AC.AInnerPacks, 0) + coalesce(RC.RInnerPacks, 0))) then
               'IPs between header and detail ' + '(L.IPs != LD.IPs) ' +
               '(' + cast(coalesce(LC.InnerPacks, 0) as varchar) + ' != ' + cast(coalesce(AC.AInnerPacks, 0) + coalesce(RC.RInnerPacks, 0) as varchar) + ')'
           end,
           case
             when (coalesce(LC.Quantity, 0) <> (coalesce(AC.AQuantity, 0) + coalesce(RC.RQuantity, 0))) then
               'Qty between header and detail ' + '(L.Qty != LD.Qty) ' +
               '(' + cast(coalesce(LC.Quantity, 0) as varchar) + ' != ' + cast(coalesce(AC.AQuantity, 0) + coalesce(RC.RQuantity, 0) as varchar) + ')'
           end,
           case
             when (coalesce(LC.AllocableQty, 0) <> (coalesce(AC.AAllocableQty, 0) + coalesce(RC.RAllocableQty, 0))) then
               'Allocable Qty between header and detail ' + '(L.AllocableQty != LD.AllocableQty) ' +
               '(' + cast(coalesce(LC.AllocableQty, 0) as varchar) + ' != ' + cast(coalesce(AC.AAllocableQty, 0) + coalesce(RC.RAllocableQty, 0) as varchar) + ')'
           end,
           case
             when (coalesce(LC.ReservedQty, 0) > (coalesce(AC.AQuantity, 0) + coalesce(RC.RQuantity, 0) + coalesce(DC.DQuantity, 0))) then
               'Reserved Qty between header and detail ' + '(L.RQuantity != LD.RQuantity)' +
               '(' + cast(coalesce(LC.ReservedQty, 0) as varchar) + ' != ' + cast(coalesce(AC.AQuantity, 0) + coalesce(RC.RQuantity, 0) + + coalesce(DC.DQuantity, 0) as varchar) + ')'
           end,
           null  /* Mismatch6  - future use */
    from LPNCounts LC
      left outer join LPNDetailACounts  AC   on (LC.LPNId = AC.LPNId)
      left outer join LPNDetailRCounts  RC   on (LC.LPNId = RC.LPNId)
      left outer join LPNDetailDCounts  DC   on (LC.LPNID = DC.LPNId )
    where /* Header v Detail counts */
          (coalesce(LC.InnerPacks,   0) <> (coalesce(AC.AInnerPacks,   0)  + coalesce(RC.RInnerPacks,   0))) or
          (coalesce(LC.ReservedQty,  0) <> (coalesce(AC.AReservedQty,  0)  + coalesce(RC.RReservedQty,  0))) or
          (coalesce(LC.AllocableQty, 0) <> (coalesce(AC.AAllocableQty, 0)  + coalesce(RC.RAllocableQty, 0))) or
          (coalesce(LC.ReservedQty,  0) >  (coalesce(AC.AQuantity,     0)  + coalesce(RC.RQuantity,  0) + coalesce(DC.DQuantity,  0)))
    order by LC.LPNId, LC.SKU

  /* If there is no data captured, then exit */
  if (@@rowcount = 0) return(0);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #LPNCountsMismatch;
      return(0);
    end

  /* Email the results */
  if (exists (select * from #LPNCountsMismatch))
    exec pr_Email_SendQueryResults @vAlertCategory, '#LPNCountsMismatch', null /* order by */, @BusinessUnit;

end /* pr_Alerts_LPNCountsMismatch */

Go
