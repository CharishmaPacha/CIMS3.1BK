/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/04/23  SV      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwIntransitReceipts') is not null
  drop View dbo.vwIntransitReceipts;
Go

Create View dbo.vwIntransitReceipts (
  ReceiptId,
  ReceiptNumber,
  ReceiptType,

  Status,
  StatusDescription,

  LPNsInTransit,
  LPNsReceived,

  UnitsReceived,
  QtyToReceive,
  BusinessUnit

) As
select
 distinct RH.ReceiptId,
  RH.ReceiptNumber,
  RH.ReceiptType,

  RH.Status,
  ST.StatusDescription,


  RH.LPNsInTransit,
  RH.LPNsReceived,

  RH.UnitsReceived,
  /* QtyToReceive */
  case when (RH.NumUnits > RH.UnitsReceived) then RH.NumUnits - RH.UnitsReceived else 0 end,

  RH.BusinessUnit
from
ReceiptHeaders RH
 join LPNs                       L   on (L.ReceiptId = RH.ReceiptId         ) and
                                        (L.Status = 'T' /* Intrasit */      ) and
                                        (coalesce(L.ReceiverNumber, '') = '')
 left outer join Statuses        ST  on (RH.Status       = ST.StatusCode  ) and
                                        (ST.Entity       = 'Receipt'      ) and
                                        (ST.BusinessUnit = RH.BusinessUnit);
Go