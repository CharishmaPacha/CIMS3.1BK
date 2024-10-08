/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/25  VS      Packages mapped to LPNsAssigned (CID-857)
  2018/04/26  MJ      Changes to display ShippedDate instead of modified date in ShippedDate field (FB-1131)
  2017/10/26  SPP     Show ShipVia description from ShipVias table (CIMS-1646)
  2016/09/17  AY      Added Account, AccountName
  2016/09/14  AY      Corrected Replenish Order Types (HPI-GoLive)
  2013/12/31  DK      Added OrderCategory's and vwUDF's
  2012/08/16  AY      Added where clause to skip Bulk, Replenishment Orders
  2012/08/13  AA      Added columns SoldToId, ShipToId, ShipViaDesc, CustPO,
                        Ownership, Warehouse, NumLines, NumUnits, UnitsAssigned,
                        NumLPNs, TotalSalesAmount
  2012/02/02  PK      Modified to suit the report
  2012/01/30  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwShippedOrders') is not null
  drop View dbo.vwShippedOrders;
Go
Create View dbo.vwShippedOrders (
  Packages,
  ShippedDate,
  ActualWeight,

  OrderId,
  OrderShippedDate,
  OrderType,
  OrderTypeDescription,

  PickTicketNo,
  SalesOrder,

  SoldToId,
  CustomerName,
  ShipToId,
  ShipToName,
  Account,
  AccountName,

  Carrier,
  ShipVia,
  ShipViaDesc,
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

  /* Place holders for any new fields, if required */
  vwUDF1,
  vwUDF2,
  vwUDF3,
  vwUDF4,
  vwUDF5
) As
select
  OH.LPNsAssigned,
  OH.ShippedDate,
  0, /* Weight */

  OH.OrderId,
  OH.ShippedDate,
  OH.OrderType,
  ET.TypeDescription,

  OH.PickTicket,
  OH.SalesOrder,

  OH.SoldToId,
  C.CustomerName,
  OH.ShipToId,
  STA.Name,
  OH.Account,
  OH.AccountName,

  S.Carrier,
  OH.ShipVia,
  SV.Description,
  OH.CustPO,
  OH.Ownership,
  OS.LookUpDescription,
  OH.Warehouse,

  OH.NumLines,
  OH.NumSKUs,
  OH.NumUnits,
  OH.UnitsAssigned,
  OH.NumLPNs,

  OH.TotalSalesAmount,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

  ' ',/* vwUDF1 */
  ' ',/* vwUDF2 */
  ' ',/* vwUDF3 */
  ' ',/* vwUDF4 */
  ' ' /* vwUDF5 */
from OrderHeaders              OH
  left outer join ShipVias     S   on (OH.ShipVia          = S.ShipVia        ) and
                                      (OH.BusinessUnit     = S.BusinessUnit   )
  left outer join EntityTypes  ET  on (ET.TypeCode         = OH.OrderType     ) and
                                      (ET.Entity           = 'Order'          ) and
                                      (ET.BusinessUnit     = OH.BusinessUnit  )
  left outer join ShipVias     SV  on (OH.ShipVia          = SV.ShipVia       ) and
                                      (OH.BusinessUnit     = SV.BusinessUnit  )
  left outer join Customers    C   on (OH.SoldToId         = C.CustomerId     )
  left outer join Contacts     STA on (OH.ShipToId         = STA.ContactRefId ) and
                                      (STA.ContactType     = 'S' /* Ship To */)
  left outer join LookUps      OS  on (OH.Ownership        = OS.LookUpCode    ) and
                                      (OS.LookUpCategory   = 'Owner'          ) and
                                      (OS.BusinessUnit     = OH.BusinessUnit  )
where (OH.Status        in ('S' /* Shipped */, 'D' /* Completed */)) and
      (OH.OrderType not in ('B' /* Bulk */, 'RU', 'RP' /* Replenishments */));

Go