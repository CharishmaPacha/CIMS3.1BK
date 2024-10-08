/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/20  AY      Added LoadGroup, ShipmentRefNumber etc. (HA-1933)
  2021/01/13  MS      Enabled New Status Orders adding to Loads (HA-1902)
  2019/08/06  KBB     Added DeliveryStart & DeliveryEnd fields for Orders (S2GCA-891)
  2019/01/21  MJ      Added NB4Date & changed the fields order (S2G-1075)
  2018/08/10  SV      Added ColorCode which determined ForeColor in UI (OB2-520)
  2018/08/07  AJ      Added UnitsToAllocate, UnitsToPick, UnitsToPack, UnitsToLoad, UnitsToShip, LPNsToShip and LPNsToLoad
                      UnitsPicked,UnitsPacked,UnitsLoaded,UnitsShipped,LPNsLoaded,LPNsShipped (OB2-495)
  2018/05/04  MJ      Added WaveDropLocation, WaveShipDate and DeliveryRequirement (S2G-804)
  2018/04/26  AY      Temporarily exclude New Orders for performance (S2G-664)
  2018/03/25  AJ/VM   Added ShipTo fields and OH_UDF11..OHUDF30 (S2G-478)
  2017/05/04  LRA     Changes to resolve the truncate issue with data (CIMS-1326)
  2016/10/26  YJ      Added Account, AccountName (HPI-938)
  2016/04/04  SV      Added ShipComplete, WaveFlag. (NBD-337)
  2016/01/30  VM      Allow one order to be on one load only (FB-616)
  2015/09/21  AY      Code optimization - join with PBD was an overkill as PBD is by OrderId & OrderDetailId
  2015/07/21  OK      Mapped vwUDF1 to AccountName in OrderHeaders.
  2014/06/21  NY      cast vwUDF's as string, otherwise it would consider char in dbml.
  2014/06/21  NY      Cast vwUDF's as string, otherwise it would consider char in dbml.
  2014/03/11  DK      Added HasNotes
  2013/12/31  DK      Added OrderCategory's and vwUDF's
  2013/08/09  PKS     Added BillToAccount, FreightTerms and TotalWeight.
  2013/07/04  NY      Added CustomerName.
  2012/12/17  SP      Added fields 'MarkforAddress', 'Totaltax', 'Comments', 'LoadNumber'
                      'TotalShippingCost' and 'TotalDiscount'.
  2012/10/23  NY      Corrected CancelDays formula
  2012/10/15  AY      Added Batch related fields
  2012/10/10  SP      Added "Cancel Days" and "TotalSalesAmount" fields.
  2012/09/24  PKS     Added ShipToStore, LPNsAssigned.
  2012/08/28  NY      Added PickBatchGroup
  2012/08/14  AY      Added CancelDate, ShipToCity, ShipToState
  2012/06/21  TD      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwOrdersForLoads') is not null
  drop View dbo.vwOrdersForLoads;
Go

Create View dbo.vwOrdersForLoads (
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
  FreightTerms,
  BillToAccount,
  ShipFrom,
  CustPO,
  Ownership,
  Account,
  AccountName,
  ShortPick,
  Comments,
  HasNotes,
  ShipComplete,
  WaveFlag,
  PickZone,
  PickBatchGroup,
  DeliveryRequirement,

  NumLines,
  NumLPNs,
  NumSKUs,
  NumCases,
  NumUnits,

  LPNsAssigned,
  LPNsPicked,
  LPNsPacked,
  LPNsStaged,
  LPNsLoaded,
  LPNsToLoad,
  LPNsShipped,
  LPNsToShip,

  UnitsAssigned,
  UnitsToAllocate,
  UnitsPicked,
  UnitsToPick,
  UnitsPacked,
  UnitsToPack,
  UnitsStaged,
  UnitsLoaded,
  UnitsToLoad,
  UnitsShipped,
  UnitsToShip,

  Warehouse,

  TotalWeight,
  TotalSalesAmount,
  TotalTax,
  TotalShippingCost,
  TotalDiscount,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,
  ColorCode,

  BatchType,
  BatchPickDate,
  BatchToShipDate,
  BatchDescription,
  WaveDropLocation,
  WaveShipDate,

  LoadId,
  LoadNumber,
  LoadGroup,
  ShipperAccountName,
  AESNumber,
  ShipmentRefNumber,

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
  ET.TypeDescription,  -- OrderTypeDesc
  OH.Status,           -- deprecated
  S.StatusDescription, -- deprecated
  OH.Status,           -- OrderStatus
  S.StatusDescription, -- OrderStatusDesc

  cast(convert(varchar, OH.OrderDate,   101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.NB4Date,         101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.CancelDate,   101 /* mm/dd/yyyy */) as DateTime),
  OH.DeliveryStart,
  OH.DeliveryEnd,
  datediff(Day, getdate(), OH.CancelDate), /* Cancel Days */

  OH.Priority,
  OH.SoldToId,
  C.Name,
  OH.ShipToId,
  STA.City,
  STA.State,
  STA.Country,
  STA.Zip,
  OH.ReturnAddress,
  OH.MarkForAddress,
  OH.ShipToStore,
  OH.PickBatchNo,
  PB.RecordId,
  OH.ShipVia,
  OH.FreightTerms,
  OH.BillToAccount,
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,
  OH.Account,
  OH.AccountName,
  OH.ShortPick,
  OH.Comments,
  OH.HasNotes,
  OH.ShipComplete,
  OH.WaveFlag,
  OH.PickZone,
  OH.PickBatchGroup,
  OH.DeliveryRequirement,

  OH.NumLines,
  OH.NumLPNs,
  OH.NumSKUs,
  OH.NumCases,
  OH.NumUnits,
  OH.LPNsAssigned,
  OH.LPNsPicked,
  OH.LPNsPacked,
  OH.LPNsStaged,
  OH.LPNsLoaded,
  OH.LPNsAssigned - OH.LPNsLoaded, /* LPNsToLoad */
  OH.LPNSShipped,
  OH.LPNsAssigned - OH.LPNsShipped, /* LPNsToShip */

  OH.UnitsAssigned,
  OH.NumUnits - OH.UnitsAssigned, /* UnitsToAllocate */
  OH.UnitsPicked,
  OH.UnitsAssigned - OH.UnitsPicked, /* Units To Pick */
  OH.UnitsPacked,
  OH.UnitsAssigned - OH.UnitsPacked, /* Units To Pack */
  OH.UnitsStaged,
  OH.UnitsLoaded,
  OH.UnitsAssigned - OH.UnitsLoaded, /* UnitsToLoad */
  OH.UnitsShipped,
  OH.UnitsAssigned - OH.UnitsShipped, /* UnitsToShip */
  OH.Warehouse,

  OH.TotalWeight,

  OH.TotalSalesAmount,
  OH.TotalTax,
  OH.TotalShippingCost,
  OH.TotalDiscount,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,
  case
    when OH.Priority = 1
      then ';R' /* Red */
    else
      null
  end,

  PB.BatchType,
  PB.PickDate,
  PB.ShipDate,
  PB.Description,
  PB.DropLocation,
  PB.ShipDate,

  coalesce(SH.LoadId, 0),
  '' /* LoadNumber */,
  OH.LoadGroup,
  OH.ShipperAccountName,
  OH.AESNumber,
  OH.ShipmentRefNumber,

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

  OH.Archived,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy
from
  OrderHeaders OH
  left outer join EntityTypes    ET  on (ET.TypeCode      = OH.OrderType     ) and
                                        (ET.Entity        = 'Order'          ) and
                                        (ET.BusinessUnit  = OH.BusinessUnit  )
  left outer join Statuses       S   on (S.StatusCode     = OH.Status        ) and
                                        (S.Entity         = 'Order'          ) and
                                        (S.BusinessUnit   = OH.BusinessUnit  )
  left outer join (select distinct OrderId, PickBatchNo from PickBatchDetails where Status = 'A')
                                 PBD on (OH.OrderId       = PBD.OrderId      )
  left outer join PickBatches    PB  on (PBD.PickBatchNo  = PB.BatchNo       )
  left outer join OrderShipments OS  on (OH.OrderId       = OS.OrderId       )
  left outer join Shipments      SH  on (OS.ShipmentId    = SH.ShipmentId    )
  left outer join Contacts       STA on (STA.ContactRefId = OH.ShipToId      ) and
                                        (STA.ContactType  = 'S' /* Ship To */)
  left outer join Contacts       C   on (C.ContactRefId   = OH.SoldToId      ) and
                                        (C.ContactType    = 'C' /* Cust. */  )

where (OH.OrderType not in ('B' /* Bulk Pull */, 'R', 'RU', 'RP' /* Replenish, Replenish Units, Replenish Cases */)) and
      (OH.Status in ('N' /* New        */,
                     'I' /* Inprogress */,
                     'W' /* Batched    */,
                     'A' /* Allocated  */,
                     'C' /* Picking    */,
                     'P' /* Picked     */,
                     'K' /* Packed     */,
                     'G' /* Staged     */)) and
      /* Considering that one order would be on one load only for now _20160130: Still needs discussion */
      (nullif(SH.LoadId, '') is null)
;

Go
