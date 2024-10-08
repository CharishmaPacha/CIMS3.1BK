/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/17  AY      pr_ReceiptHeaders_Recount: Corrections to handle multiSKU ASN LPNs (CIMSV3-743)
  2019/02/06  AY      pr_ReceiptHeaders_Recount: Revised to do counts from Received Counts table (CID-38)
  2017/05/01  PK      pr_ReceiptHeaders_Recount: Fixed updating the QtyReceived, LPNsReceived Counts.
  2015/05/12  AY      pr_ReceiptHeaders_Recount: Fixed issues with counts
  2014/07/03  NY      pr_ReceiptHeaders_Recount: Calculate QtyToReceive on ReceiptHeaders
  2013/04/09  PK      pr_ReceiptHeaders_Recount: Syntax fix
  2013/03/27  AY      pr_ReceiptHeaders_Recount: Update LPNs/Units Intransit/Received counts
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_Recount') is not null
  drop Procedure pr_ReceiptHeaders_Recount;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_Recount: Recount the Number of LPNs and UnitsReceived
    against the Receipt.
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_Recount
  (@ReceiptId  TRecordId)
as
  declare @vNumLPNs        TCount,
          @vLPNsIntransit  TCount,
          @vLPNsReceived   TCount,
          @vUnitsIntransit TCount,
          @vUnitsReceived  TCount;
begin
  /* Count LPNs and Units In transit and received for the Receipt */
  select ReceiptDetailId, L.LPNId, min(L.Status) as LPNStatus, sum(RC.Quantity) LDQuantity
  into #ReceiptStats
  from ReceivedCounts RC join LPNs L on (RC.LPNId = L.LPNId)
  where (RC.ReceiptId = @ReceiptId) and (RC.Status = 'A' /* Active */)
  group by ReceiptDetailId, L.LPNId;

  /* All LPNs that are not in InTransit are considered as Received */
  with RDSummary as
  (
    select ReceiptDetailId,
           sum(case when LPNStatus = 'T'  then LDQuantity else 0 end)          QtyInTransit,
           sum(case when LPNStatus <> 'T' then LDQuantity else 0 end)          QtyReceived,
           count(distinct case when LPNStatus =  'T' then LPNId else null end) LPNsInTransit,
           count(distinct case when LPNStatus <> 'T' then LPNId else null end) LPNsReceived,
           count(distinct LPNId)                                               NumLPNs
    from #ReceiptStats
    group by ReceiptDetailId
  )
  update ROD
  set ROD.QtyIntransit  = coalesce(RDS.QtyInTransit,  0),
      ROD.QtyReceived   = coalesce(RDS.QtyReceived,   0),
      ROD.LPNsInTransit = coalesce(RDS.LPNsInTransit, 0),
      ROD.LPNsReceived  = coalesce(RDS.LPNsReceived,  0)
  from ReceiptDetails ROD
    join RDSummary RDS on ROD.ReceiptDetailId = RDS.ReceiptDetailId
  where (ROD.ReceiptId = @ReceiptId);

  /* Summarize the LPN counts and update on receipt header */
  with LPNSummary as
  (
    select sum(case when LPNStatus = 'T'  then LDQuantity else 0 end)          QtyInTransit,
           sum(case when LPNStatus <> 'T' then LDQuantity else 0 end)          QtyReceived,
           count(distinct case when LPNStatus =  'T' then LPNId else null end) LPNsInTransit,
           count(distinct case when LPNStatus <> 'T' then LPNId else null end) LPNsReceived,
           count(distinct LPNId)                                               NumLPNs
    from #ReceiptStats
  )
  update ROH
  set UnitsIntransit = coalesce(LS.QtyInTransit,   0),
      UnitsReceived  = coalesce(LS.QtyReceived,    0),
      LPNsIntransit  = coalesce(LS.LPNsInTransit,  0),
      LPNsReceived   = coalesce(LS.LPNsReceived,   0),
      NumLPNs        = coalesce(LS.NumLPNs,        0),
      ModifiedDate   = current_timestamp
  from ReceiptHeaders ROH, LPNSummary LS
  where (ROH.ReceiptId = @ReceiptId);

  exec pr_ReceiptHeaders_SetStatus @ReceiptId;
end /* pr_ReceiptHeaders_Recount */

Go
