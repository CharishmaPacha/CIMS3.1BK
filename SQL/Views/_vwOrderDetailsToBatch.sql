/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/21  MJ      Added NB4Date & changed the fields order (S2G-1075)
  2018/07/26  AY/PK   Mapped OH.OH_UDF30 with DeliveryRequirement: Migrated from Prod (S2G-727)
  2019/02/18  RV      Made changes to show only New order details (CIMS-2527)
  2018/11/22  AY      Added WaveFlag conditions (OB2-745)
  2018/06/09  YJ      UDF1 to 30 changed as OH_UDF1 to OH_UDF30 and fetching CustomerName from vwOrderHeaders
                      And also commented join with contacts : Migrated from staging (S2G-727)
  2018/06/07  MJ      Added fields to the OrderDetails tab in ManageWaves page (S2G-918)
  2017/10/05  VM      Include remaining order UDFs (OB-617)
  2016/09/25  VM      Added Account (HPI-838)
  2104/09/09  NY      To show details of orders that are processed.
  2103/10/28  TD      Order Details cannot be batched until order is preprocessed..
  2013/10/01  PK      Added OD_UDF1 - OD_UDF10.
  2013/09/12  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOrderDetailsToBatch') is not null
  drop View dbo.vwOrderDetailsToBatch;
Go

Create View dbo.vwOrderDetailsToBatch (
  OrderDetailId,

  OrderLine,
  LineType,

  HostOrderLine,
  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsToAllocate,

  OrderDetailWeight,
  OrderDetailVolume,

  CustSKU,
  PickZone,
  PickBatchNo,
  PickBatchGroup,
  PickBatchCategory,

  /* SKUs related */
  SKUId,
  SKU,
  SKUDescription,
  AlternateSKU,

  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,

  SKU1Description,
  SKU2Description,
  SKU3Description,
  SKU4Description,
  SKU5Description,

  ProdCategory,
  ProdSubCategory,
  PutawayClass,

  UnitWeight,
  UnitVolume,
  UnitsPerInnerPack,

  /* Order Headers related */
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
  DeliveryStart,
  DeliveryEnd,
  DownloadedDate,
  QualifiedDate,
  DateShipped,
  CancelDays,

  Priority,
  SoldToId,
  CustomerName,
  ShipToId,
  ShipToName,
  ShipToAddressLine1,
  ShipToCityStateZip,
  ShipToCity,
  ShipToState,
  ShipToCountry,
  ShipToZip,
  ReturnAddress,
  MarkForAddress,
  ShipToStore,
  PickBatchId,
  PrevWaveNo,
  ShipVia,
  Carrier,
  ShipFrom,
  CustPO,
  Ownership,
  Warehouse,
  Account,
  AccountName,
  ShortPick,

  OH_PickZone,
  OH_PickBatchNo,
  OH_PickBatchGroup,

  NumLines,
  NumSKUs,
  NumUnits,
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
  ReceiptNumber,
  Comments,
  HasNotes,
  ShipComplete,
  ProcessOperation,
  WaveFlag,
  PreprocessFlag,
  OrderAge,

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

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

  LoadId,
  LoadNumber,

  OD_UDF1,
  OD_UDF2,
  OD_UDF3,
  OD_UDF4,
  OD_UDF5,
  OD_UDF6,
  OD_UDF7,
  OD_UDF8,
  OD_UDF9,
  OD_UDF10,
  OD_UDF11,
  OD_UDF12,
  OD_UDF13,
  OD_UDF14,
  OD_UDF15,
  OD_UDF16,
  OD_UDF17,
  OD_UDF18,
  OD_UDF19,
  OD_UDF20,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  OD.OrderDetailId,

  OD.OrderLine,
  OD.LineType,

  OD.HostOrderLine,
  OD.UnitsOrdered,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  OD.UnitsToAllocate,

  OD.UnitsAuthorizedToShip * S.UnitWeight,
  OD.UnitsAuthorizedToShip * S.UnitVolume,

  OD.CustSKU,
  OD.PickZone,
  PBD.PickBatchNo,
  OD.PickBatchGroup,
  OD.PickBatchCategory,

   /* SKUs related */
  S.SKUId,
  S.SKU,
  S.Description,
  S.AlternateSKU,

  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,

  S.SKU1Description,
  S.SKU2Description,
  S.SKU3Description,
  S.SKU4Description,
  S.SKU5Description,

  S.ProdCategory,
  S.ProdSubCategory,
  S.PutawayClass,

  S.UnitWeight,
  S.UnitVolume,
  S.UnitsPerInnerPack,

  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  ET.TypeDescription,
  OH.Status,
  SU.StatusDescription,
  OH.ExchangeStatus,

  cast(convert(varchar, OH.OrderDate,   101 /* mm/dd/yyyy */) as DateTime), /* OrderDate */
  cast(convert(varchar, OH.NB4Date,         101 /* mm/dd/yyyy */) as DateTime), /* NB4Date */
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime), /* DesiredShipDate */
  cast(convert(varchar, OH.CancelDate,      101 /* mm/dd/yyyy */) as DateTime), /* CancelDate */
  OH.DeliveryStart,
  OH.DeliveryEnd,
  OH.DownloadedDate,
  OH.QualifiedDate,
  case when OH.Status in ('S' /* Shipped */, 'D' /* Completed */) then
    cast(convert(varchar, OH.ModifiedDate, 101 /* mm/dd/yyyy */) as DateTime)
  else
    null
  end, /* DateShipped */
  datediff(Day, getdate(), OH.CancelDate), /* Cancel Days */

  OH.Priority,
  OH.SoldToId,
  OH.CustomerName,
  OH.ShipToId,
  CS.Name,
  CS.AddressLine1,
  coalesce(CS.City+', ', '') + coalesce(CS.State+' ', '') + coalesce(CS.Zip, '') /* CityStateZip */,
  CS.City,
  CS.State,
  CS.Country,
  CS.Zip,
  OH.ReturnAddress,
  OH.MarkForAddress,
  OH.ShipToStore,
  0 /* PickBatchId */,
  OH.PrevWaveNo,
  OH.ShipVia,
  SV.Carrier,
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,
  OH.Warehouse,
  OH.Account,
  OH.AccountName,
  OH.ShortPick,

  OH.PickZone,
  OH.PickBatchNo,
  OH.PickBatchGroup,

  OH.NumLines,
  OH.NumSKUs,
  OH.NumUnits,
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
  OH.ReceiptNumber,
  OH.Comments,
  OH.HasNotes,
  OH.ShipComplete,
  OH.ProcessOperation,
  OH.WaveFlag,
  OH.PreprocessFlag,
  datediff(d, OH.OrderDate, getdate()), /* Order Age */

  OH.OH_UDF1,
  OH.OH_UDF2,
  OH.OH_UDF3,
  OH.OH_UDF4,
  OH.OH_UDF5,
  OH.OH_UDF6,
  OH.OH_UDF7,
  OH.OH_UDF8,
  OH.OH_UDF9,
  OH.OH_UDF10,
  OH.OH_UDF11,
  OH.OH_UDF12,
  OH.OH_UDF13,
  OH.OH_UDF14,
  OH.OH_UDF15,
  OH.OH_UDF16,
  OH.OH_UDF17,
  OH.OH_UDF18,
  OH.OH_UDF19,
  OH.OH_UDF20,
  OH.OH_UDF21,
  OH.OH_UDF22,
  OH.OH_UDF23,
  OH.OH_UDF24,
  OH.OH_UDF25,
  OH.OH_UDF26,
  OH.OH_UDF27,
  OH.OH_UDF28,
  OH.OH_UDF29,
  OH.OH_UDF30,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

  0 /* LoadID */,
  ' ' /* LoadNumber */,

  OD.UDF1,
  OD.UDF2,
  OD.UDF3,
  OD.UDF4,
  OD.UDF5,
  OD.UDF6,
  OD.UDF7,
  OD.UDF8,
  case when S.PutawayClass like '%F' then 'Floor' else S.UDF9 end,  /* OD_UDF9 */
  S.UDF9,  /* OD_UDF10 - what for? */
  OD.UDF11,
  OD.UDF12,
  OD.UDF13,
  OD.UDF14,
  OD.UDF15,
  OD.UDF16,
  OD.UDF17,
  OD.UDF18,
  OD.UDF19,
  OD.UDF20,

  OH.Archived,
  OH.BusinessUnit,
  OD.CreatedDate,
  OD.ModifiedDate,
  OD.CreatedBy,
  OD.ModifiedBy
from
  OrderDetails OD
             join vwOrderHeaders   OH  on (OD.OrderId       = OH.OrderId        )
             join SKUs             S   on (OD.SKUId         = S.SKUId           )
  left outer join PickBatchDetails PBD on (OD.OrderDetailId = PBD.OrderDetailId )
  left outer join EntityTypes      ET  on (ET.TypeCode     = OH.OrderType       ) and
                                          (ET.Entity       = 'Order'            ) and
                                          (ET.BusinessUnit = OH.BusinessUnit    )
  left outer join Statuses         SU  on (SU.StatusCode    = OH.Status         ) and
                                          (SU.Entity        = 'Order'           ) and
                                          (SU.BusinessUnit  = OH.BusinessUnit   )
  left outer join Contacts         CS  on (OH.ShipToId      = CS.ContactRefId   ) and
                                          (CS.ContactType   = 'S' /* Ship */    ) and
                                          (OH.BusinessUnit  = CS.BusinessUnit   )
  left outer join ShipVias         SV  on (OH.ShipVia       = SV.ShipVia        )
  --left outer join Contacts         C   on (C.ContactRefId   = OH.SoldToId       ) and
  --                                        (C.ContactType    = 'C' /* Customer */) and
  --                                        (C.BusinessUnit   = OH.BusinessUnit   )
where (PBD.PickBatchNo is null) and
      (OH.Status = 'N' /* New */) and
      (OH.NumUnits      > 0) and
      (coalesce(OD.LineType, '') <> 'F') and
      (OH.OrderType not in ('B')) and
      (coalesce(OH.WaveFlag, '') not in ('U', 'O', 'M', 'R', 'D' /* Unwaved, Onhold, Manual, Removed, Do not Wave*/))
;

Go
