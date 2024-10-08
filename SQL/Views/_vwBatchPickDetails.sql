/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/12/09  TD      Changes to get all LPNs which have PickBatchNo.
  2013/11/14  NY      Displaying LPNs of Loaded status as well.
  2013/10/02  PK      Displaying PickBatchNo from PickBatchDetails.
  2013/06/05  SP      Added PackageSeqNo field.
  2011/12/20  PKS     LPNStatus Added (Database field name is 'Status').
  2011/11/16  TD      Fixed the duplication of data.Need to do show the Packed and shipped Batches data....
  2011/08/24  TD      Initial Revision.
                      Few fields are really not required, those are for future use...
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBatchPickDetails') is not null
  drop View dbo.vwBatchPickDetails;
Go
/* Used in Productivity */
Create View dbo.vwBatchPickDetails (
  LPNId,
  LPN,

  LPNDetailId,
  LPNLine,
  LPNType,
  LPNStatus,

  CoO,
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UOM,
  SKUDescription,

  PalletId,
  Pallet,

  OnhandStatus,
  OnhandStatusDescription,
  InnerPacks,
  Quantity,
  UnitsPerPackage,

  ShipmentId,
  LoadId,
  ASNCase,

  LocationId,
  Location,

  OrderId,
  PickTicket,
  SalesOrder,
  PickBatchNo,
  OrderDetailId,
  OrderLine,
  HostOrderLine,

  Weight,
  Volume,
  Lot,

  PickLocation,
  PickedBy,
  PickedDate,
  PackedBy,
  PackedDate,
  PackageSeqNo,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  LD.LPNId,
  L.LPN,

  LD.LPNDetailId,
  LD.LPNLine,
  L.LPNType,
  L.Status,

  LD.CoO,
  LD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.UOM,
  S.Description,

  L.PalletId,
  L.Pallet,

  LD.OnhandStatus,
  OST.StatusDescription,
  LD.InnerPacks,
  LD.Quantity,
  LD.UnitsPerPackage,

  L.ShipmentId,
  L.LoadId,
  L.ASNCase,

  L.LocationId,
  L.Location,

  LD.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  L.PickBatchNo,
  LD.OrderDetailId,
  OD.OrderLine,
  OD.HostOrderLine,

  LD.Weight,
  LD.Volume,
  LD.Lot,

  LD.ReferenceLocation,
  LD.PickedBy,
  LD.PickedDate,
  LD.PackedBy,
  LD.PackedDate,
  L.PackageSeqNo,

  LD.UDF1,
  LD.UDF2,
  LD.UDF3,
  LD.UDF4,
  LD.UDF5,

  LD.BusinessUnit,
  LD.CreatedDate,
  LD.ModifiedDate,
  LD.CreatedBy,
  LD.ModifiedBy
from
  OrderHeaders OH
             join vwLPNs           L   on (L.OrderId          = OH.OrderId         ) --and
                                         -- (L.Status in ('K'/* Picked */, 'U'/* Picking */, 'L'/* Loaded */))
             join LPNDetails       LD  on (LD.LPNId           = L.LPNId            )
  left outer join SKUs             S   on (LD.SKUId           = S.SKUId            )
  left outer join OrderDetails     OD  on (LD.OrderDetailId   = OD.OrderDetailId   ) and
                                          (LD.OrderId         = OD.OrderId         )
  left outer join Statuses         OST on (LD.OnhandStatus    = OST.StatusCode     ) and
                                          (OST.Entity         = 'OnHand'           ) and
                                          (OST.BusinessUnit   = OH.BusinessUnit    )
where L.PickBatchNo is not null
;

Go
