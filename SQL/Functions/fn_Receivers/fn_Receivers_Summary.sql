/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/09/06  AY      fn_Receivers_Summary: Performance issues (CID-1022)
  2018/06/14  VM      fn_Receivers_Summary: Changed to use vwReceivedCounts (S2G-947)
  2018/05/22  PK      fn_Receivers_Summary: Mapping ReceivedQty from ReceiptDetails on client request (S2G-879).
  2018/03/06  AY/SV   fn_Receivers_Summary: Corrected the Receiver's Summary count (S2G-337)
  2014/07/11  DK      fn_Receivers_Summary: Included more fields.
  2014/04/24  DK      Modified fn_Receivers_Summary and Revisions made to all procedures
  2014/04/16  DK      Modified pr_Receivers_Create, fn_Receivers_Summary.
  2014/03/03  DK      Added function fn_Receivers_Summary
                      Initial revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Receivers_Summary') is not null
  drop Function fn_Receivers_Summary;
Go
/*------------------------------------------------------------------------------
  Function fn_Receivers_Summary:
------------------------------------------------------------------------------*/
Create Function fn_Receivers_Summary
  (@ReceiverNo    TReceiverNumber)
  -----------------------------------------------------------------
  /* temp table  to return data */
  returns @ReceiverSummary table (ReceiptNumber    TReceiptNumber,
                                  CustPO           TCustPO,
                                  SKU              TSKU,
                                  QtyOrdered       TQuantity,
                                  QtyInTransit     TQuantity,
                                  QtyReceived      TQuantity,
                                  QtyToReceive     TQuantity,
                                  NumLPNs          TCount,
                                  LPNsInTransit    TCount,
                                  LPNsReceived     TCount,
                                  LPNsRemaining    TCount)
as
begin
  declare @vReceiverId TRecordId;

  select @vReceiverId = ReceiverId
  from Receivers
  where (ReceiverNumber = @ReceiverNo);

  insert into @ReceiverSummary (ReceiptNumber, CustPO,
                                 SKU, QtyOrdered, QtyInTransit,
                                 QtyReceived, QtyToReceive,
                                 NumLPNs, LPNsInTransit,
                                 LPNsReceived, LPNsRemaining)
                          select ReceiptNumber, CustPO,
                                 SKU, QtyOrdered, QtyInTransit,
                                 QtyReceived, QtyToReceive,
                                 NumLPNs, LPNsInTransit,
                                 LPNsReceived, LPNsRemaining
                          from vwReceivedCounts
                          where (ReceiverId = @vReceiverId);

  return;
end /* fn_Receivers_Summary */

Go
