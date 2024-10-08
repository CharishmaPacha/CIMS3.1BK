/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/06/13  NY      Added VendorName.
  2013/06/12  NY      Displaying NumLPNs,NumUnits from ReceiptDetails.
  2013/06/11  NY      Displaying Receipt Order count based on ReceiptLines.
  2013/03/19  NY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwReceiptStats') is not null
  drop View dbo.vwReceiptStats;
Go
Create View dbo.vwReceiptStats (
  ReceiptNumber,
  ReceiptType,
  ReceiptTypeDesc,
  ROCount,

  VendorId,
  VendorName,
  Ownership,
  Vessel,
  NumLPNs,
  NumUnits,
  ContainerSize,
  Warehouse,

  DateOrdered,
  DateExpected,

  ETACountry,
  ETACity,
  ETAWarehouse,

  CoO,

  QtyOrdered,
  QtyInTransit,
  LPNsInTransit,
  ExtraQtyAllowed,

  UnitCost,

  CustPO,

  SKU,
  Season,
  Style

) As
select
  RH.ReceiptNumber,
  RH.ReceiptType,
  ET.TypeDescription,
  /* Here we are verifying whether receipt have the details and sum up and displaying in UI for #RO's */
  case
    when (ReceiptLine = (select min(ReceiptLine) from ReceiptDetails RDS where RH.ReceiptId = RDS.ReceiptId)) then
      1
    else
      0
  end,

  RH.VendorId,
  coalesce(V.VendorName, RH.VendorId),
  RH.Ownership,
  RH.Vessel,
  RD.LPNsReceived,
  RD.QtyReceived,
  RH.ContainerSize,
  RH.Warehouse,

  RH.DateOrdered,
  RH.DateExpected,

  RH.ETACountry,
  RH.ETACity,
  RH.ETAWarehouse,

  RD.CoO,

  RD.QtyOrdered,
  RD.QtyInTransit,
  RD.LPNsInTransit,
  RD.ExtraQtyAllowed,

  RD.UnitCost,

  RD.CustPO,

  S.SKU,
  S.SKU1,
  S.SKU2
from  ReceiptHeaders             RH
  left outer join ReceiptDetails RD   on (RH.ReceiptId = RD.Receiptid)
  left outer join SKUs           S    on (RD.SKUID     = S.SKUID)
  left outer join EntityTypes    ET   on (ET.Entity    = 'Receipt')  and
                                         (ET.TypeCode  = RH.ReceiptType)
  left outer join Vendors        V    on (RH.VendorId  = V.VendorId)
where RH.ReceiptId = RD.ReceiptId

Go
