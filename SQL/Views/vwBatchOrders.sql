/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/21  MJ      Added NB4Date & changed the fields order (S2G-1075)
  2018/08/10  SV      Added ColorCode which determined ForeColor in UI (OB2-520)
  2018/03/25  AJ/VM   Added ShipTo fields and OH_UDF11..OHUDF30 (S2G-478)
  2016/08/17  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2016/04/04  SV      Added ShipComplete, WaveFlag. (NBD-337)
  2014/05/05  PK      Excluding bulk order info
  2014/03/11  DK      Added HasNotes
  2013/09/17  NY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBatchOrders') is not null
  drop View dbo.vwBatchOrders;
Go

Create View dbo.vwBatchOrders (
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  Status,
  StatusDescription,
  ExchangeStatus,

  OrderDate,
  NB4Date,
  DesiredShipDate,
  CancelDate,
  DateShipped,
  CancelDays,

  Priority,
  SoldToId,
  CustomerName,
  ShipToId,
  ShipToCity,
  ShipToState,
  ShipToCountry,
  ShipToZip,
  ReturnAddress,
  MarkForAddress,
  ShipToStore,
  PickBatchNo,
  PickBatchId,

  ShipVia,
  ShipFrom,
  CustPO,
  Ownership,
  Account,
  AccountName,
  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,
  Warehouse,
  PickZone,
  PickBatchGroup,

  NumLines,
  NumSKUs,
  NumUnits,
  LPNsAssigned,
  UnitsAssigned,
  NumLPNs,

  TotalVolume,
  TotalWeight,
  TotalSalesAmount,
  TotalTax,
  TotalShippingCost,
  TotalDiscount,

  FreightCharges,
  FreightTerms,
  BillToAccount,
  BillToAddress,

  ShortPick,
  Comments,
  HasNotes,
  ShipComplete,
  WaveFlag,
  ColorCode,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,
  UDF6,
  UDF7,
  UDF8,
  UDF9,
  UDF10,
  OH_UDF11,
  OH_UDF12,
  OH_UDF13,
  OH_UDF14,
  OH_UDF15,
  OH_UDF16,
  OH_UDF17,
  OH_UDF18,
  OH_UDF19,
  OH_UDF20,
  OH_UDF21,
  OH_UDF22,
  OH_UDF23,
  OH_UDF24,
  OH_UDF25,
  OH_UDF26,
  OH_UDF27,
  OH_UDF28,
  OH_UDF29,
  OH_UDF30,

  /* Place holders for any new fields, if required */
  vwUDF1,
  vwUDF2,
  vwUDF3,
  vwUDF4,
  vwUDF5,

  LoadId,
  LoadNumber,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
)
As
  select distinct
  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OT.TypeDescription,
  OH.Status,
  OH.ExchangeStatus,
  OS.StatusDescription,

  cast(convert(varchar, OH.OrderDate,       101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.NB4Date,         101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.CancelDate,      101 /* mm/dd/yyyy */) as DateTime),
  case 
	  when OH.Status in ('S' /* Shipped */) then
      cast(convert(varchar, OH.ShippedDate,  101 /* mm/dd/yyyy */) as DateTime)
    when OH.Status in ('D' /* Completed */) then
      cast(convert(varchar, OH.ModifiedDate, 101 /* mm/dd/yyyy */) as DateTime)
  else
    null
  end /* Date Shipped */,
  datediff(Day, getdate(), OH.CancelDate), /* Cancel Days */

  OH.Priority,
  OH.SoldToId,
  C.Name,
  OH.ShipToId,
  CS.City,
  CS.State,
  CS.Country,
  CS.Zip,
  OH.ReturnAddress,
  OH.MarkForAddress,
  OH.ShipToStore,
  PBD.PickBatchNo,
  PB.RecordId,

  OH.ShipVia,
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,
  OH.Account,
  OH.AccountName,
  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,
  OH.Warehouse,
  OH.PickZone,
  OH.PickBatchGroup,

  OH.NumLines,
  OH.NumSKUs,
  case when OH.OrderType <> 'B' then OH.NumUnits else 0 end,
  OH.LPNsAssigned,
  OH.UnitsAssigned,
  OH.NumLPNs,

  OH.TotalVolume,
  OH.TotalWeight,
  OH.TotalSalesAmount,
  OH.TotalTax,
  OH.TotalShippingCost,
  OH.TotalDiscount,

  OH.FreightCharges,
  OH.FreightTerms,
  OH.BillToAccount,
  OH.BillToAddress,

  OH.ShortPick,
  OH.Comments,
  OH.HasNotes,
  OH.ShipComplete,
  OH.WaveFlag,
  case
    when OH.Priority = 1
      then ';R' /* Red */
    else
      null
  end,

  OH.UDF1,
  OH.UDF2,
  OH.UDF3,
  OH.UDF4,
  OH.UDF5,
  OH.UDF6,
  OH.UDF7,
  OH.UDF8,
  OH.UDF9,
  OH.UDF10,
  OH.UDF11,
  OH.UDF12,
  OH.UDF13,
  OH.UDF14,
  OH.UDF15,
  OH.UDF16,
  OH.UDF17,
  OH.UDF18,
  OH.UDF19,
  OH.UDF20,
  OH.UDF21,
  OH.UDF22,
  OH.UDF23,
  OH.UDF24,
  OH.UDF25,
  OH.UDF26,
  OH.UDF27,
  OH.UDF28,
  OH.UDF29,
  OH.UDF30,

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  0 /* LoadID */,
  '' /* LoadNumber */,

  OH.Archived,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy
from
  OrderHeaders OH
              join PickBatchDetails PBD  on (OH.OrderId  = PBD.OrderId)
  left outer join EntityTypes  OT  on (OT.TypeCode     = OH.OrderType   ) and
                                      (OT.Entity       = 'Order'        ) and
                                      (OT.BusinessUnit = OH.BusinessUnit)
  left outer join Statuses     OS  on (OS.StatusCode   = OH.Status      ) and
                                      (OS.Entity       = 'Order'        ) and
                                      (OS.BusinessUnit = OH.BusinessUnit)
  left outer join PickBatches  PB  on (PBD.PickBatchId = PB.RecordId    ) and
                                      (OH.BusinessUnit = PB.BusinessUnit)
  left outer join Contacts     C   on (OH.SoldToId     = C.ContactRefId ) and
                                      (C.ContactType   = 'C' /* Customer */)
  left outer join Contacts     CS  on (OH.ShipToId      = CS.ContactRefId) and
                                      (CS.ContactType   = 'S' /* Ship */ ) and
                                      (OH.BusinessUnit  = CS.BusinessUnit)

Go
