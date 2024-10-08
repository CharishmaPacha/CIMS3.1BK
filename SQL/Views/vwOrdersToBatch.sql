/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/13  TK      Added EstimatedCartons (HA-GoLive)
  2020/06/04  KBB     Added Missed Fields in vwOrdersToBatch (HA-804)
  2019/08/06  KBB     Added DeliveryStart & DeliveryEnd fields for Orders (S2GCA-891)
  2019/01/21  MJ      Added NB4Date & changed the fields order (S2G-1075)
  2019/05/10  SPP     mapped from vwUDF2 toOH.Cartongroup (CID-136) (Ported from Stag)
  2018/08/10  SV      Added ColorCode which determined ForeColor in UI (OB2-520)
  2018/04/05  TK      Performance Improvements (S2G-Support)
  2018/03/24  AJ/VM   Added several fields to match with vwOrderHeaders (S2G-478)
  2016/12/16  KL      Added PrevWaveNo (HPI-1189)
  2016/12/14  ??      Mapped vwOTW_UDF1 to ExchangeStatus (HPI-GoLive)
  2016/11/02  ??      Modified where clause to consider WaveFlag, UDF10 (HPI-GoLive)
  2016/10/15  AY      Corrected vwUDF setup. (HPI-GoLive)
  2016/10/08  AY      Exclude Bulk and Replenish Orders (HPI-GoLive)
                      Added Account, AccountName
  2016/08/09  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2016/04/04  SV      Added ShipComplete, WaveFlag. (NBD-337)
  2015/07/21  OK      Mapped vwUDF1 to AccountName in OrderHeaders.
  2014/03/11  DK      Added HasNotes
  2013/12/31  DK      Added vwUDF's
  2013/12/19  NY      Added OrderCategories.
  2013/10/19  TD      Changes to show valid orders.
  2013/10/08  TD      Allow users to generate batches for New and Inprogress orders.
  2013/09/16  PK      Changes related to the change of Order Status Code.
  2013/07/04  NY      Added CustomerName.
  2103/05/17  TD      Getting Carrier from ShipVias based on the ShipVia.
  2013/03/25  TD      Added new field TotalWeight, TotalVolume.
  2012/10/23  NY      Corrected CancelDays formula
  2012/10/03  PKS     Sync all columns with vwOrderHeaders.
  2012/07/13  AY      Added BatchGroup i.e. the Group that the orders are batched by.
  2012/06/20  PK      Added Warehouse.
  2012/03/17  AA      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOrdersToBatch') is not null
  drop View dbo.vwOrdersToBatch;
Go

Create View dbo.vwOrdersToBatch (
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  Status,
  StatusDescription,
  OrderStatus,
  OrderStatusDesc,
  StatusGroup,
  ExchangeStatus,

  OrderDate,
  NB4Date,
  DesiredShipDate,
  CancelDate,
  DeliveryStart,
  DeliveryEnd,
  DownloadedDate,
  QualifiedDate,
  PackedDate,
  DateShipped,
  CancelDays,

  DeliveryRequirement,
  CarrierOptions,
  Priority,
  SoldToId,
  CustomerName,
  ShipToId,
  ShipToName,
  ShipToAddressLine1,
  ShipToAddressLine2,
  ShipToCityStateZip,
  ShipToCity,
  ShipToState,
  ShipToCountry,
  ShipToZip,
  ReturnAddress,
  MarkForAddress,
  ShipToStore,

  PickBatchId,
  PickBatchNo,
  WaveId,
  WaveNo,
  PrevWaveNo,
  WaveType,
  WaveTypeDesc,

  Carrier,
  ShipVia,
  ShipViaDesc,
  ShipFrom,
  CustPO,
  Ownership,

  Account,
  AccountName,
  ShipperAccountName,
  AESNumber,
  ShipmentRefNumber,
  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

  Warehouse,
  PickZone,
  PickBatchGroup,
  WaveGroup,
  CartonGroups,

  NumLines,
  NumSKUs,
  NumLPNs,
  NumCases,
  NumUnits,
  EstimatedCartons,

  LPNsAssigned,
  LPNsPicked,
  LPNsPacked,
  LPNsStaged,
  LPNsLoaded,
  LPNsShipped,

  UnitsAssigned,
  UnitsPicked,
  UnitsPacked,
  UnitsStaged,
  UnitsLoaded,
  UnitsShipped,

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
  ReceiptNumber,

  ShortPick,
  Comments,
  HasNotes,
  ShipComplete,
  ShipCompletePercent,
  ProcessOperation,
  WaveFlag,
  PreprocessFlag,
  OrderAge,
  ColorCode,
  HostNumLines,

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
  vwUDF1, -- deprecated
  vwUDF2, -- deprecated
  vwUDF3, -- deprecated
  vwUDF4, -- deprecated
  vwUDF5, -- deprecated

  /* Place holders for any new fields, if required */
  vwOTW_UDF1,
  vwOTW_UDF2,
  vwOTW_UDF3,
  vwOTW_UDF4,
  vwOTW_UDF5,

  LoadId,
  LoadNumber,

  SourceSystem,
  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select distinct
  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OT.TypeDescription,
  OH.Status,
  OS.StatusDescription,
  OH.Status, /* OrderStatus */
  OS.StatusDescription, /* OrderStatusDesc */
  case
    when (OH.Status in ('O'/* Downloaded */,'N'/* New */,'W'/* Waved */))
      then 'To Process'
    when (OH.Status in ('S'/* Shipped */,'D'/* Completed */,'X'/* Cancelled */))
      then 'Closed'
    else
      'In Process'
  end, /* StatusGroup */
  OH.ExchangeStatus,

  cast(convert(varchar, OH.OrderDate,       101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.NB4Date,         101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.CancelDate,      101 /* mm/dd/yyyy */) as DateTime),
  OH.DeliveryStart,
  OH.DeliveryEnd,
  OH.DownloadedDate,
  OH.QualifiedDate,
  OH.PackedDate,
  OH.ShippedDate,
  datediff(Day, getdate(), OH.CancelDate), /* Cancel Days */

  OH.DeliveryRequirement,
  OH.CarrierOptions,
  OH.Priority,
  OH.SoldToId,
  OH.SoldToName,
  OH.ShipToId,
  CS.Name,
  CS.AddressLine1,
  CS.AddressLine2,
  CS.CityStateZip,
  CS.City,
  CS.State,
  CS.Country,
  CS.Zip,
  OH.ReturnAddress,
  OH.MarkForAddress,
  OH.ShipToStore,

  0 /* PickBatchId */,
  OH.PickBatchNo,
  0,  /* Wave Id */
  OH.PickBatchNo, /* Wave No */
  OH.PrevWaveNo,
  '', /* Batch Type */
  '', /* Batch Typedesc */
  /* if shipvia is invalid then carrier should display Invalid, They can process the
     orders as generic and update the carrier later */
  case when (SV.ShipVia is null) or (SV.Status = 'I' /* Inactive */)
       then 'Invalid'
       else SV.Carrier
  end, /* Carrier */
  OH.ShipVia,
  SV.Description, -- ShipViaDesc
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,

  OH.Account,
  OH.AccountName,
  OH.ShipperAccountName,
  OH.AESNumber,
  OH.ShipmentRefNumber,
  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,
  OH.Warehouse,
  OH.PickZone,
  OH.PickBatchGroup,
  OH.PickBatchGroup, /* Wave Group */
  OH.CartonGroups,

  OH.NumLines,
  OH.NumSKUs,
  OH.NumLPNs,
  OH.NumCases,
  case when OH.OrderType <> 'B' then OH.NumUnits else 0 end,
  OH.EstimatedCartons,

  OH.LPNsAssigned,
  OH.LPNsPicked,
  OH.LPNsPacked,
  OH.LPNsStaged,
  OH.LPNsLoaded,
  OH.LPNsShipped,

  OH.UnitsAssigned,
  OH.UnitsPicked,
  OH.UnitsPacked,
  OH.UnitsStaged,
  OH.UnitsLoaded,
  OH.UnitsShipped,

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
  OH.ReceiptNumber,

  OH.ShortPick,
  OH.Comments,
  OH.HasNotes,
  OH.ShipComplete,
  coalesce(OH.ShipCompletePercent, 0),
  OH.ProcessOperation,
  OH.WaveFlag,
  OH.PreprocessFlag,
  datediff(d, OH.OrderDate, getdate()), /* Order Age */
  case
    when OH.Priority = 1
      then ';R' /* Red */
    else
      null
  end,
  OH.HostNumLines,

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

  cast(' ' as varchar(50)), /* vwOTW_UDF1 */
  cast(' ' as varchar(50)), /* vwOTW_UDF2 */
  cast(' ' as varchar(50)), /* vwOTW_UDF3 */
  cast(' ' as varchar(50)), /* vwOTW_UDF4 */
  cast(' ' as varchar(50)), /* vwOTW_UDF5 */

  0 /* LoadId */,
  ' ' /* LoadNumber */,

  OH.SourceSystem,
  OH.Archived,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy
from
  OrderHeaders OH
  /* What's the purpose of joining with vwOrderDetailsToBatch? this only slows down the system */
  --join vwOrderDetailsToBatch   OTB  on (OTB.OrderId     = OH.OrderId)   /* Do we need join or we need to add where condition ???*/
    left outer join EntityTypes  OT  on (OT.TypeCode      = OH.OrderType   ) and
                                        (OT.Entity        = 'Order'        ) and
                                        (OT.BusinessUnit  = OH.BusinessUnit)
    left outer join Statuses     OS  on (OS.StatusCode    = OH.Status      ) and
                                        (OS.Entity        = 'Order'        ) and
                                        (OS.BusinessUnit  = OH.BusinessUnit)
    left outer join Contacts     CS  on (OH.ShipToId      = CS.ContactRefId) and
                                        (CS.ContactType   = 'S' /* Ship */ ) and
                                        (OH.BusinessUnit  = CS.BusinessUnit)
    left outer join ShipVias     SV  on (SV.ShipVia       = OH.ShipVia     )
where (OH.Status        in ('N' /* New */, 'I' /* InProgress */)) and
      (OH.OrderType not in ('B')) and
      (OH.NumUnits      > 0) and
      (coalesce(OH.WaveFlag, '') not in ('D', 'O' /* Do not wave, on hold */)) and
      (OH.PickBatchNo   is null)
;

Go
