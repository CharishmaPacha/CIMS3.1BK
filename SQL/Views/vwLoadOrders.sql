/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/20  AY/YJ   Added ShipToCityState: Ported changes done by Pavan (HA-2366)
  2020/03/17  AY      Added TotalShipmentValue (HA GoLive)
  2020/06/29  RV/VM   Added PackingListFormat, ContentsLabelFormat (HA-1037)
  2020/06/13  AY      Added OrderType, OrderStatus (HA-921)
  2019/07/25  SV      Added Reference1, Reference2 (GNC-2316)
  2019/01/21  MJ      Added NB4Date & changed the fields order (S2G-1075)
  2018/08/10  SV      Added ColorCode which determined ForeColor in UI (OB2-520)
  2018/05/08  AY      Added ShipToName (S2G-805)
  2018/03/25  AJ/VM   Added ShipTo fields and OH_UDF11..OHUDF30 (S2G-478)
  2016/08/16  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2016/04/04  SV      Added ShipComplete, WaveFlag. (NBD-337)
  2015/10/08  AY      Changed UDFs
  2014/03/11  DK      Added HasNotes
  2013/12/31  DK      Added OrderCategory's and vwUDF's
  2013/08/09  PKS     Added BillToAccount, FreightTerms and TotalWeight.in sub grid gvOrderHeaders (OB- )
  2013/07/04  NY      Added CustomerName
  2012/10/23  NY      Corrected CancelDays formula
  2012/10/16  VM      Added Batch related fields and organized field places to make it some consistent with vwOrderHeaders
  2012/10/10  SP      Added more fields to be in sync with vwOrderHeaders fields and rearrnaged fields
  2012/08/28  TD      Added PickBatchGroup,CancelDate
  2011/06/22  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLoadOrders') is not null
  drop View dbo.vwLoadOrders;

Go

/*
This view is used to retrieve the List of Orders in a given Load
This is primarily used in Load Listing UI to display the Orders on the Load Id
of the selected record in the grid.
*/
Create View dbo.vwLoadOrders (
  OrderId,
  PickTicket,
  SalesOrder,

  OrderType,
  OrderTypeDescription, -- deprecated
  OrderTypeDesc,
  Status,               -- deprecated
  StatusDescription,    -- deprecated
  OrderStatus,
  OrderStatusDesc,

  OrderDate,
  NB4Date,
  DesiredShipDate,
  CancelDate,
  DeliveryStart,
  DeliveryEnd,
  PackedDate,
  DateShipped,
  CancelDays,

  Account,
  AccountName,

  Priority,
  SoldToId,
  CustomerName,
  ShipToId,
  ShipToName,
  ShipToCityState,
  ShipToCity,
  ShipToState,
  ShipToZip,
  ShipToCountry,
  Reference1,
  Reference2,
  ReturnAddress,
  MarkForAddress,
  ShipToStore,
  PickBatchId,
  PickBatchNo,

  FreightTerms,
  BillToAccount,
  ShipVia,
  ShipFrom,
  CustPO,
  Ownership,
  ShortPick,
  PickZone,
  PickBatchGroup,

  NumLines,
  NumLPNs,
  NumSKUs,
  NumUnits,
  EstimatedCartons,

  LPNsAssigned,
  UnitsAssigned,
  UnitsOrdered,
  Warehouse,

  TotalVolume,
  TotalWeight,
  TotalSalesAmount,
  TotalShipmentValue,
  TotalTax,
  TotalShippingCost,
  TotalDiscount,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

  WaveType,
  BatchType,
  BatchPickDate,
  BatchToShipDate,
  BatchDescription,

  ShipmentId,
  LoadId,
  LoadNumber,

  Comments,
  HasNotes,
  ShipComplete,
  WaveFlag,
  PackingListFormat,
  ContentsLabelFormat,
  ColorCode,

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

  PB_UDF1,
  PB_UDF2,
  PB_UDF3,
  PB_UDF4,
  PB_UDF5,
  PB_UDF6,
  PB_UDF7,
  PB_UDF8,
  PB_UDF9,
  PB_UDF10,

  /* Place holders for any new fields, if required */
  vwUDF1,
  vwUDF2,
  vwUDF3,
  vwUDF4,
  vwUDF5,

  /* Place holders for any new fields, if required */
  vwLDOH_UDF1,
  vwLDOH_UDF2,
  vwLDOH_UDF3,
  vwLDOH_UDF4,
  vwLDOH_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  distinct
  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  ET.TypeDescription,  -- deprecated
  ET.TypeDescription,
  OH.Status,           -- deprecated
  S.StatusDescription, -- deprecated
  OH.Status,
  S.StatusDescription,

  cast(convert(varchar, OH.OrderDate,       101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.NB4Date,         101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.CancelDate,      101 /* mm/dd/yyyy */) as DateTime),
  OH.DeliveryStart,
  OH.DeliveryEnd,
  OH.PackedDate,
  case when OH.Status in ('S' /* Shipped */, 'D' /* Completed */) then
    cast(convert(varchar, OH.ModifiedDate, 101 /* mm/dd/yyyy */) as DateTime)
  else
    null
  end /* Date Shipped */,
  datediff(Day, getdate(), OH.CancelDate), /* Cancel Days */

  OH.Account,
  OH.AccountName,
  OH.Priority,
  OH.SoldToId,
  OH.SoldToName,
  OH.ShipToId,
  CS.Name,
  CS.CityState,
  CS.City,
  CS.State,
  CS.Zip,
  CS.Country,
  CS.Reference1,
  CS.Reference2,
  OH.ReturnAddress,
  OH.MarkForAddress,
  OH.ShipToStore,
  PB.RecordId,
  PBD.PickBatchNo,

  OH.FreightTerms,
  OH.BillToAccount,
  OH.ShipVia,
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,
  OH.ShortPick,
  OH.PickZone,
  OH.PickBatchGroup,

  OH.NumLines,
  OH.NumLPNs,
  OH.NumSKUs,
  OH.NumUnits,
  OH.EstimatedCartons,

  OH.LPNsAssigned,
  OH.UnitsAssigned,
  0, --temp to be removed later
  OH.Warehouse,

  OH.TotalVolume,
  OH.TotalWeight,
  OH.TotalSalesAmount,
  OH.TotalShipmentValue,
  OH.TotalTax,
  OH.TotalShippingCost,
  OH.TotalDiscount,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

  PB.WaveType,
  PB.BatchType,
  PB.PickDate,
  PB.ShipDate,
  PB.Description,

  SH.ShipmentId,
  SH.LoadId,
  SH.LoadNumber,

  OH.Comments,
  OH.HasNotes,
  OH.ShipComplete,
  OH.WaveFlag,
  OH.PackingListFormat,
  OH.ContentsLabelFormat,
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
  CS.State,
  CS.Zip,

  PB.UDF1,
  PB.UDF2,
  PB.UDF3,
  PB.UDF4,
  PB.UDF5,
  PB.UDF6,
  PB.UDF7,
  PB.UDF8,
  PB.UDF9,
  PB.UDF10,

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  cast(' ' as varchar(50)), /* vwLDOH_UDF1 */
  cast(' ' as varchar(50)), /* vwLDOH_UDF2 */
  cast(' ' as varchar(50)), /* vwLDOH_UDF3 */
  cast(' ' as varchar(50)), /* vwLDOH_UDF4 */
  cast(' ' as varchar(50)), /* vwLDOH_UDF5 */

  OH.Archived,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy
from
  OrderHeaders OH
  left outer join EntityTypes    ET  on (ET.TypeCode     = OH.OrderType    ) and
                                        (ET.Entity       = 'Order'         ) and
                                        (ET.BusinessUnit = OH.BusinessUnit )
  left outer join Statuses       S   on (S.StatusCode    = OH.Status       ) and
                                        (S.Entity        = 'Order'         ) and
                                        (S.BusinessUnit  = OH.BusinessUnit )
  left outer join Contacts       CS  on (OH.ShipToId     = CS.ContactRefId ) and
                                        (CS.ContactType  = 'S' /* Ship */  ) and
                                        (OH.BusinessUnit = CS.BusinessUnit )
  left outer join PickBatchDetails
                                 PBD on (PBD.OrderId     = OH.OrderId      )
  left outer join PickBatches    PB  on (PBD.PickBatchNo = PB.BatchNo      )
  left outer join OrderShipments OS  on (OH.OrderId      = OS.OrderId      )
  left outer join Shipments      SH  on (OS.ShipmentId   = SH.ShipmentId   )
;

Go
