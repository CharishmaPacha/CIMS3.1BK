/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/12  AY      Added OrderTypedesc, OrderStatus, OrderStatusDesc (HA-413)
  2015/07/03  TK      Changed UDFs -> OH_UDFs
  2014/05/08  TK      Added all the fields of vwOrderHeaders.
  2014/05/08  PK      Handling Replenish Cases/Units.
  2012/06/22  NB      Corrected to use vwOrderHeaders
  2012/06/19  PV      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwReplenishOrderHeaders') is not null
  drop View dbo.vwReplenishOrderHeaders;
Go

Create View dbo.vwReplenishOrderHeaders
 As
select
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription, -- deprecated
  OrderTypeDescription as OrderTypeDesc,
  OrderStatus,
  OrderStatusDesc,
  Status, -- deprecated
  ExchangeStatus,
  StatusDescription, -- deprecated

  OrderDate,
  CancelDate,
  DesiredShipDate,
  DateShipped,
  CancelDays,

  Priority,
  SoldToId,
  CustomerName,
  ShipToId,
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

  OH_UDF1,
  OH_UDF2,
  OH_UDF3,
  OH_UDF4,
  OH_UDF5,
  OH_UDF6,
  OH_UDF7,
  OH_UDF8,
  OH_UDF9,
  OH_UDF10,

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
from vwOrderHeaders
  where (OrderType in ('R', 'RP', 'RU' /* Replenishment Cases, Units */));

Go
