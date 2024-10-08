/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/05  RIA     Considered Pickequence (OB2-796)
  2017/10/05  VM      Include remaining order UDFs (OB-617)
  2013/09/12  TD      Changes to get details from Orderdetails.
  2012/10/23  PK      Added UnitsPerCarton, UoM.
  2012/09/24  AY      Ownership match is optional, so do not do that here.
  2012/09/13  AY      Ensure Owner of OrderHeader and LPN matches.
  2012/05/15  YA      Included fields as it is required in pr_Picking_FindNextPickFromBatch after migrating from FH.
  2011/10/24  NB      UnitsToAllocate: Directly fetch the value from table.
  2011/10/13  AY      Changed to select only OnHand = Available LPNs and same Warehouse as Order
  2011/08/09  DP      Added Columns SKU, UnitsToAllocate.
  2011/08/05  DP      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPickDetails') is not null
  drop View dbo.vwPickDetails;
Go

Create View dbo.vwPickDetails (
  OrderId,
  OrderType,
  OrderStatus,
  PickBatchNo,
  Priority,
  PickZone,
  OrderOwner,
  OHUDF1,
  OHUDF2,
  OHUDF3,
  OHUDF4,
  OHUDF5,
  OHUDF6,
  OHUDF7,
  OHUDF8,
  OHUDF9,
  OHUDF10,
  OHUDF11,
  OHUDF12,
  OHUDF13,
  OHUDF14,
  OHUDF15,
  OHUDF16,
  OHUDF17,
  OHUDF18,
  OHUDF19,
  OHUDF20,
  OHUDF21,
  OHUDF22,
  OHUDF23,
  OHUDF24,
  OHUDF25,
  OHUDF26,
  OHUDF27,
  OHUDF28,
  OHUDF29,
  OHUDF30,

  OrderDetailId,
  OrderLine,
  HostOrderLine,
  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,
  UnitsShipped,
  UnitsToAllocate,
  UnitsPerCarton,
  CustSKU,
  ODUDF1,
  ODUDF2,
  ODUDF3,
  ODUDF4,
  ODUDF5,
  ODUDF6,
  ODUDF7,
  ODUDF8,
  ODUDF9,
  ODUDF10,
  ODUDF11,
  ODUDF12,
  ODUDF13,
  ODUDF14,
  ODUDF15,
  ODUDF16,
  ODUDF17,
  ODUDF18,
  ODUDF19,
  ODUDF20,

  LPNId,
  LPN,
  LPNType,
  LPNStatus,
  Quantity,
  ReservedQuantity,
  PalletId,
  LPNOwner,

  LPNDetailId,
  LPNLine,
  SKUId,

  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UoM,

  LocationId,
  Location,
  LocationRow,
  LocationSection,
  PickSequence,
  LocationType,
  StorageType,
  LocationStatus,
  PickPath,
  PickingZone,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
)As
select
  OH.OrderId,
  OH.OrderType,
  OH.Status,
  PBD.PickBatchNo,
  OH.Priority,
  OH.PickZone,
  OH.Ownership,
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

  OD.OrderDetailId,
  OD.OrderLine,
  OD.HostOrderLine,
  OD.UnitsOrdered,
  OD.UnitsAuthorizedToShip,
  OD.UnitsAssigned,
  OD.UnitsShipped,
  OD.UnitsToAllocate,
  OD.UnitsPerCarton,
  OD.CustSKU,
  OD.UDF1,
  OD.UDF2,
  OD.UDF3,
  OD.UDF4,
  OD.UDF5,
  OD.UDF6,
  OD.UDF7,
  OD.UDF8,
  OD.UDF9,
  OD.UDF10,
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

  L.LPNId,
  L.LPN,
  L.LPNType,
  L.Status,
  L.Quantity,
  L.Quantity,
  L.PalletId,
  L.Ownership,

  LD.LPNDetailId,
  LD.LPNLine,
  LD.SKUId,

  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.UoM,

  LOC.LocationId,
  LOC.Location,
  LOC.LocationRow,
  LOC.LocationSection,
  TD.PickSequence,
  LOC.LocationType,
  LOC.StorageType,
  LOC.Status,
  LOC.PickPath,
  LOC.PickingZone,

  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy
From
OrderDetails OD
  join OrderHeaders          OH   on (OD.OrderId       = OH.OrderId         )
  join PickBatchDetails      PBD  on (OD.OrderDetailId = PBD.OrderDetailId  )
  join LPNDetails            LD   on (LD.SKUId         = OD.SKUId           ) and
                                     (LD.OnhandStatus  = 'A' /* Available */) and
                                     (LD.BusinessUnit  = OH.BusinessUnit    )
  join LPNs                  L    on (LD.LPNId         = L.LPNId            ) and
                                     (L.OnhandStatus   = 'A' /* Available */) and
                                     (OH.Warehouse     = L.DestWarehouse    ) --and
                                   --(L.Ownership      = OH.Ownership       )
  left outer join Locations  LOC  on (L.LocationId     = LOC.LocationId     ) and
                                     (LOC.Status in ('U' /* in Use */, 'F' /* Full */))
  left outer join SKUs       S    on (OD.SKUId         = S.SKUId            )
  left outer join TaskDetails TD   on (TD.SKUId         = OD.SKUId           )
where
   (OH.Status not in ('E'/* Cancel in Progress */,'X'/* Cancelled */));

Go
