/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/02  MS      Added Container, CreatedOn (JL-287)
  2018/09/19  TK      Added CreatedBy as it is required while evaluating rules to find receiver (S2GCA-274)
  2018/06/14  VM      vwROReceivers => vwReceivedCounts (S2G-947)
  2018/06/11  AY      Revised to use ReceivedCounts (S2G-879)
  2018/03/06  AY/SV   Added ReceiverId, ReceiverStatus, CreatedDate of receiver (S2G-337)
  2015/19/05  KN/TK   Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwReceivedCounts') is not null
  drop View dbo.vwReceivedCounts;
Go

Create View dbo.vwReceivedCounts (
   ReceiptId,
   ReceiptNumber,

   ReceiverId,
   ReceiverNumber,
   ReceiverStatus,

   CustPO,
   SKU,

   QtyOrdered,
   QtyInTransit,
   QtyReceived,
   QtyLabelled,
   QtyToReceive, -- Remaining Qty to receive against the RO Line
   QtyToLabel,

   NumLPNs,

   LPNsInTransit,
   LPNsReceived,
   LPNsRemaining,

   CreatedOn,
   CreatedDate,
   CreatedBy,
   BoLNo,
   Container,
   Reference1,
   Reference2
) As
select
  RC.ReceiptId,
  min(RC.ReceiptNumber),

  RC.ReceiverId,
  min(RC.ReceiverNumber),
  min(R.Status), -- Receiver Status

  min(RD.CustPO),
  min(RC.SKU),

  min(RD.QtyOrdered),
  sum(case when L.Status = 'T' then RC.Quantity else 0 end), /* Qty In Transit */
  sum(case when L.Status not in ('T') then RC.Quantity else 0 end), /* Qty Received */
  sum(RC.Quantity), /* Qty Labelled */
  min(RD.QtyToReceive),
  min(RD.QtyToLabel),

  count(distinct RC.LPNId),
  count(distinct case when L.Status = 'T' then RC.LPNId else null end), /* LPNs In Transit */
  count(distinct case when L.Status not in ('T') then RC.LPNId else null end), /* LPNs Received */
  count(distinct RC.LPNId) - count(distinct case when L.Status not in ('T') then RC.LPNId else null end), /* LPNs Remaining */

  min(R.CreatedOn),
  min(R.CreatedDate),
  min(R.CreatedBy),
  min(R.BoLNumber),
  min(R.Container),
  min(R.Reference1),
  min(R.Reference2)
from
  ReceivedCounts RC
    join Receivers       R on (RC.ReceiverId = R.ReceiverId)
    join LPNs            L on (RC.LPNId = L.LPNId)
    join ReceiptDetails RD on (RC.ReceiptDetailId = RD.ReceiptDetailId)
where (RC.Status = 'A' /* Active */) and
      (RD.QtyOrdered > 0)
group by RC.ReceiptId, RC.ReceiverId, RC.ReceiptDetailId;

Go
