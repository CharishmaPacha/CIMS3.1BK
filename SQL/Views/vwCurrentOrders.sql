/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/18  MJ      Added WaveType, Carrier and ShipToCountry fields (S2G-1002)
  2017/10/26  SPP     Show ShipVia description from ShipVias table (CIMS-1646)
  2016/08/17  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2015/08/29  RV      Padding Zeroes to SortSeq for appropriate varchar sorting (ACME-237)
  2013/12/31  DK      Added OrderCategory's and vwUDF's
  2012/08/10  AA      Added columns CancelDate, SoldToName, OwnershipDesc,
                        Warehouse, NumLines, NumSKUs, NumUnits, UnitsAssigned,
                        NumLPNs, TotalSalesAmount
  2010/11/10  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwCurrentOrders') is not null
  drop View dbo.vwCurrentOrders;
Go

Create View dbo.vwCurrentOrders (
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  Status,
  StatusDescription,
  StatusSortSeq,

  OrderDate,
  DesiredShipDate,
  CancelDate,

  Priority,
  SoldToId,
  SoldToName,
  ShipToId,
  ShipToCountry,
  WaveNo,
  WaveType,
  Carrier,
  ShipVia,
  ShipViaDesc,
  ShipFrom,
  CustPO,
  Ownership,
  OwnershipDesc,
  Warehouse,

  NumLines,
  NumSKUs,
  NumUnits,
  UnitsAssigned,
  NumLPNs,

  TotalSalesAmount,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

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

  /* Place holders for any new fields, if required */
  vwUDF1,
  vwUDF2,
  vwUDF3,
  vwUDF4,
  vwUDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  ET.TypeDescription,
  OH.Status,
  S.StatusDescription,
  right('00' + cast(S.SortSeq as varchar), 2) + '-' + S.StatusDescription,

  cast(convert(varchar, OH.OrderDate,   101 /* mm/dd/yyyy */) as Date),
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as Date),
  convert(char(5), OH.CancelDate, 101 /* mm/dd */),

  OH.Priority,
  OH.SoldToId,
  C.CustomerName,
  OH.ShipToId,
  CS.Country,
  OH.PickBatchNo,
  PB.BatchType,
  SV.Carrier,
  OH.ShipVia,
  coalesce(SV.Description, OH.ShipVia),
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,
  OS.LookUpDescription,
  OH.Warehouse,

  OH.NumLines,
  OH.NumSKUs,
  OH.NumUnits,
  OH.UnitsAssigned,
  OH.LPNsAssigned,

  OH.TotalSalesAmount,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

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

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  OH.Archived,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy
from
  OrderHeaders OH
  left outer join EntityTypes  ET  on (ET.TypeCode        = OH.OrderType   ) and
                                      (ET.Entity          = 'Order'        ) and
                                      (ET.BusinessUnit    = OH.BusinessUnit)
  left outer join Statuses     S   on (S.StatusCode       = OH.Status      ) and
                                      (S.Entity           = 'Order'        ) and
                                      (S.BusinessUnit     = OH.BusinessUnit)
  left outer join ShipVias     SV  on (OH.ShipVia         = SV.ShipVia     ) and
                                      (OH.BusinessUnit    = SV.BusinessUnit)
  left outer join LookUps      OS  on (OH.Ownership       = OS.LookUpCode  ) and
                                      (OS.LookUpCategory  = 'Owner'        ) and
                                      (OS.BusinessUnit    = OH.BusinessUnit)
  left outer join PickBatches  PB  on (OH.PickBatchNo     = PB.BatchNo     ) and
                                      (OH.BusinessUnit    = PB.BusinessUnit)
  left outer join Contacts     CS  on (OH.ShipToId        = CS.ContactRefId) and
                                      (CS.ContactType     = 'S' /* Ship */ ) and
                                      (OH.BusinessUnit    = CS.BusinessUnit)
  left outer join Customers    C   on (OH.SoldToId        = C.CustomerId   )
where (OH.Archived = 'N') and
      (OH.OrderType not in ('B' /* Bulk */));

Go