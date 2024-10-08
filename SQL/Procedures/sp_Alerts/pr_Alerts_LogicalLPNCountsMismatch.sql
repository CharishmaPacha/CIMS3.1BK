/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/03  VM      pr_Alerts_LogicalLPNCountsMismatch: Added more params to handle different situations (S2G-489)
  2018/03/24  VM      Added pr_Alerts_LogicalLPNCountsMismatch (S2G-477)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_LogicalLPNCountsMismatch') is not null
  drop Procedure pr_Alerts_LogicalLPNCountsMismatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_LogicalLPNCountsMismatch:
    Evaluates the current counts on Logical LPNs and its lines.
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
Create Procedure pr_Alerts_LogicalLPNCountsMismatch
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
As
  declare @vReturnCode      TInteger,
          @vMessageName     TMessage,
          @vRecordId        TRecordId;

  declare @vAlertCategory   TCategory,
          @vEmailSubject    TDescription,
          @vEmailBody       TVarchar,
          @vFieldCaptions   TVarchar,
          @vFieldValuesXML  TVarchar;

  /* Temp table definition to capture the suspicious/bad data for building xml */
  declare @ttAlertData table (LPNId TRecordId, LPN TLPN, SKU TSKU, Status TDescription, OnhandStatus TDescription,
                              Mismatch1 TDescription, Mismatch2 TDescription, Mismatch3 TDescription,
                              Mismatch4 TDescription, Mismatch5 TDescription, Mismatch6 TDescription, Mismatch7 TDescription,
                              RecordId TRecordId Identity(1,1));
begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0;

  select * into #AlertData from @ttAlertData;

  with LogicalLPNCounts(LPNId, LPN, SKU, Status, OnhandStatus, InnerPacks, Quantity, DirectedQty, ReservedQty, AllocableQty) as
  (
    /* select LPNs modified in the last @ShowModifiedInLastXMinutes mins as the alert is scheduled to run every 5 mins,
       we should get the LPNs only once and not repeatedly */
    select LPNId, LPN, SKU, StatusDescription, OnhandStatusDescription, InnerPacks, Quantity, DirectedQty, ReservedQty, AllocableQty
    from vwLPNs with (nolock)
    where (LPNType = 'L' /* Logical */) and
          (datediff(mi, ModifiedDate, getdate()) <= @ShowModifiedInLastXMinutes) and
          (LPNId = coalesce(@EntityId, LPNId))
  ),
  LogicalLPNDetailACounts(LPNId, OnhandStatus, AInnerPacks, AQuantity, AReservedQty, AAllocableQty) as
  (
    select LPNId, OnhandStatusDescription, sum(InnerPacks), sum(Quantity), sum(ReservedQuantity), sum(AllocableQty)
    from vwLPNDetails with (nolock)
    where (LPNType = 'L' /* Logical */) and (OnhandStatus = 'A' /* Available */)
    group by LPNId, OnhandStatusDescription
  ),
  LogicalLPNDetailRCounts(LPNId, OnhandStatus, RInnerPacks, RQuantity, RReservedQty, RAllocableQty) as
  (
    select LPNId, OnhandStatusDescription, sum(InnerPacks), sum(Quantity), sum(ReservedQuantity), sum(AllocableQty)
    from vwLPNDetails with (nolock)
    where (LPNType = 'L' /* Logical */) and (OnhandStatus = 'R' /* Reserved */)
    group by LPNId, OnhandStatusDescription
  ),
  LogicalLPNDetailDCounts(LPNId, OnhandStatus, DInnerPacks, DQuantity, DReservedQty, DAllocableQty) as
  (
    select LPNId, OnhandStatusDescription, sum(InnerPacks), sum(Quantity), sum(ReservedQuantity), sum(AllocableQty)
    from vwLPNDetails with (nolock)
    where (LPNType = 'L' /* Logical */) and (OnhandStatus = 'D' /* Available */)
    group by LPNId, OnhandStatusDescription
  ),
  LogicalLPNDetailPRCounts(LPNId, OnhandStatus, PRInnerPacks, PRQuantity) as
  (
    select LPNId, OnhandStatusDescription, sum(InnerPacks), sum(Quantity)
    from vwLPNDetails with (nolock)
    where (LPNType = 'L' /* Logical */) and (OnhandStatus = 'PR' /* Pending Reservered */)
    group by LPNId, OnhandStatusDescription
  )
  insert into #AlertData (LPNId, LPN, SKU, Status, OnhandStatus, Mismatch1, MisMatch2, Mismatch3, Mismatch4, Mismatch5, Mismatch6, Mismatch7)
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
             when (coalesce(LC.DirectedQty, 0) <>  coalesce(DC.DQuantity, 0)) then
               'Directed Qty between header and detail ' + '(L.DirectedQty != LD.DirectedQty) ' +
               '(' + cast(coalesce(LC.DirectedQty, 0) as varchar) + ' != ' + cast(coalesce(DC.DQuantity, 0) as varchar) + ')'
           end,
           case
             when (coalesce(LC.ReservedQty, 0) <> (coalesce(AC.AReservedQty, 0) + coalesce(RC.RReservedQty, 0)  + coalesce(DC.DReservedQty, 0))) then
               'Reserved Qty between header and detail ' + '(L.ReservedQty != LD.ReservedQty) ' +
               '(' + cast(coalesce(LC.ReservedQty, 0) as varchar) + ' != ' + cast(coalesce(AC.AReservedQty, 0) + coalesce(RC.RReservedQty, 0)  + coalesce(DC.DReservedQty, 0) as varchar) + ')'
           end,
           case
             when (coalesce(LC.AllocableQty, 0) <> (coalesce(AC.AAllocableQty, 0) + coalesce(RC.RAllocableQty, 0) + coalesce(DC.DAllocableQty, 0))) then
               'Allocable Qty between header and detail ' + '(L.AllocableQty != LD.AllocableQty) ' +
               '(' + cast(coalesce(LC.AllocableQty, 0) as varchar) + ' != ' + cast(coalesce(AC.AAllocableQty, 0) + coalesce(RC.RAllocableQty, 0) + coalesce(DC.DAllocableQty, 0) as varchar) + ')'
           end,
           case
             when (coalesce(PRC.PRQuantity, 0) <> (coalesce(AC.AReservedQty, 0) + coalesce(DC.DReservedQty, 0))) then
               'Pending Reserved and Soft Reserved Qty between detail lines ' + '(LD.PRQty != LD.ReservedQty) ' +
               '(' + cast(coalesce(PRC.PRQuantity, 0) as varchar) + ' != ' + cast(coalesce(AC.AReservedQty, 0) + coalesce(DC.DReservedQty, 0) as varchar) + ')'
           end
    from LogicalLPNCounts LC
      left outer join LogicalLPNDetailACounts  AC   on (LC.LPNId = AC.LPNId)
      left outer join LogicalLPNDetailRCounts  RC   on (LC.LPNId = RC.LPNId)
      left outer join LogicalLPNDetailDCounts  DC   on (LC.LPNId = DC.LPNId)
      left outer join LogicalLPNDetailPRCounts PRC  on (LC.LPNId = PRC.LPNId)
    where /* Header v Detail counts */
          (coalesce(LC.InnerPacks,   0)  > (coalesce(LC.Quantity, 0))) or
          (coalesce(LC.InnerPacks,   0) <> (coalesce(AC.AInnerPacks,   0)  + coalesce(RC.RInnerPacks, 0))) or
          (coalesce(LC.DirectedQty,  0) <>  coalesce(DC.DQuantity,     0)) or
          (coalesce(LC.ReservedQty,  0) <> (coalesce(AC.AReservedQty,  0)  + coalesce(RC.RReservedQty, 0)  + coalesce(DC.DReservedQty, 0))) or
          (coalesce(LC.AllocableQty, 0) <> (coalesce(AC.AAllocableQty, 0)  + coalesce(RC.RAllocableQty, 0) + coalesce(DC.DAllocableQty, 0))) or
          /* Detail v Detail */
          (coalesce(PRC.PRQuantity,  0) <> (coalesce(AC.AReservedQty,  0)  + coalesce(DC.DReservedQty, 0)))
    order by LC.LPNId, LC.SKU

  /* If there is no data captured, then exit */
  if (@@rowcount = 0) return(0);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #AlertData;
      return(0);
    end

  /* Email the results */
  exec pr_Email_SendQueryResults @vAlertCategory, '#AlertData', null /* order by */, @BusinessUnit;
end /* pr_Alerts_LogicalLPNCountsMismatch */

Go
