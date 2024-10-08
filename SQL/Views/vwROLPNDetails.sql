/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/03/03  AK      Added Lot and ExpiryDate fields.
  2014/03/19  SV      Added ReceiverNumber Field (Migrated from TDAX)
  2013/07/04  SP      Added TrackingNo field.
  2013/06/11  SP      Added PackageSeqNo field.
  2013/04/09  AY      Show LD.ReferenceLocation as UDF1
  2013/04/09  TD      Fix-We have issue while expanding the LPNs tab in Receipts.
                        Issue is with DBML(Expecting one char-So added space)
  2013/04/08  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwROLPNDetails') is not null
  drop View dbo.vwROLPNDetails;
Go

Create View dbo.vwROLPNDetails (
  LPNId,
  LPNDetailId,
  LPNLine,

  LPN,
  LPNType,
  LPNTypeDescription,
  Status,
  ReceivedDate,
  DestWarehouse,
  Lot,
  ExpiryDate,
  StatusDescription,
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UPC,
  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,
  SKU_UDF5,
  SKU_UDF6,
  SKU_UDF7,
  SKU_UDF8,
  SKU_UDF9,
  SKU_UDF10,
  UOM,

  Description,

  CoO,
  InnerPacks,
  Quantity,
  ReceivedUnits,

  PalletId,
  Pallet,
  LocationId,
  Location,
  LocationType,
  StorageType,
  PickingZone,
  InventoryStatus,
  OnhandStatus,
  OnhandStatusDescription,
  Ownership,

  ReceiverNumber,
  ReceiptId,
  ReceiptNumber,
  ReceiptDetailId,
  ReceiptCustPO,
  RH_UDF1,
  RH_UDF2,
  RH_UDF3,
  RH_UDF4,
  RH_UDF5,
  RD_UDF1,
  RD_UDF2,
  RD_UDF3,
  RD_UDF4,
  RD_UDF5,

  OrderId,
  PickTicket,
  SalesOrder,
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

  ShipmentId,
  LoadId,
  LoadNumber,
  ASNCase,
  TrackingNo,
  UCCBarcode,
  PackageSeqNo,

  LPN_UDF1,
  LPN_UDF2,
  LPN_UDF3,
  LPN_UDF4,
  LPN_UDF5,

  vwROLPNDetails_UDF1,
  vwROLPNDetails_UDF2,
  vwROLPNDetails_UDF3,
  vwROLPNDetails_UDF4,
  vwROLPNDetails_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  L.LPNId,
  LD.LPNDetailId,
  LD.LPNLine,

  L.LPN,
  L.LPNType,
  LT.TypeDescription,
  L.Status,

  L.ReceivedDate,
  L.DestWarehouse,
  L.Lot,
  L.ExpiryDate,
  ST.StatusDescription,
  LD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.UPC,
  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,
  S.UDF6,
  S.UDF7,
  S.UDF8,
  S.UDF9,
  S.UDF10,
  S.UOM,

  S.Description,

  LD.CoO,
  LD.InnerPacks,
  LD.Quantity,
  LD.ReceivedUnits,

  L.PalletId,
  P.Pallet,
  L.LocationId,
  LOC.Location,
  LOC.LocationType,
  LOC.StorageType,
  LOC.PickingZone,
  L.InventoryStatus,
  L.OnhandStatus,
  OST.StatusDescription,
  L.Ownership,

  L.ReceiverNumber,
  L.ReceiptId,
  RH.ReceiptNumber,
  LD.ReceiptDetailId,
  RD.CustPO,
  RH.UDF1,
  RH.UDF2,
  RH.UDF3,
  RH.UDF4,
  RH.UDF5,
  RD.UDF1,
  RD.UDF2,
  RD.UDF3,
  RD.UDF4,
  RD.UDF5,

  L.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.UDF1,
  OH.UDF2,
  OH.UDF3,
  OH.UDF4,
  OH.UDF5,
  OH.UDF6,
  OH.UDF7,
  OH.UDF8,
  OH.CustPO,
  OH.ShipToStore,

  L.ShipmentId,
  L.LoadId,
  L.LoadNumber,
  L.ASNCase,
  L.TrackingNo,
  L.UCCBarcode,
  L.PackageSeqNo,

  L.UDF1,
  L.UDF2,
  L.UDF3,
  L.UDF4,
  OH.PickBatchNo,

  cast(LD.ReferenceLocation as varchar(50)),    /* vwROLPNDetails_UDF1 */
  cast(' ' as varchar(50)), /* vwROLPNDetails_UDF2 */
  cast(' ' as varchar(50)), /* vwROLPNDetails_UDF3 */
  cast(' ' as varchar(50)), /* vwROLPNDetails_UDF4 */
  cast(' ' as varchar(50)), /* vwROLPNDetails_UDF5 */

  L.Archived,
  L.BusinessUnit,
  L.CreatedDate,
  L.ModifiedDate,
  L.CreatedBy,
  L.ModifiedBy
From
LPNs L
             join LPNDetails        LD   on (L.LPNId            = LD.LPNId          )
  left outer join ReceiptDetails    RD   on (L.ReceiptId        = RD.ReceiptId      ) and
                                            (LD.ReceiptDetailId = RD.ReceiptDetailId)
  left outer join EntityTypes       LT   on (LT.TypeCode        = L.LPNType         ) and
                                            (LT.Entity          = 'LPN'             )
  left outer join SKUs              S    on (LD.SKUId           = S.SKUId           )
  left outer join Locations         LOC  on (L.LocationId       = LOC.LocationId    )
  left outer join Statuses          ST   on (L.Status           = ST.StatusCode     ) and
                                            (ST.Entity          = 'LPN'             )
  left outer join Statuses          OST  on (L.OnhandStatus     = OST.StatusCode    ) and
                                            (OST.Entity         = 'OnHand'          )
  left outer join Pallets           P    on (L.PalletId         = P.PalletId        )
  left outer join ReceiptHeaders    RH   on (LD.ReceiptId       = RH.ReceiptId      )
  left outer join OrderHeaders      OH   on (L.OrderId          = OH.OrderId        )
where L.Status <> 'I' /* Inactive/Deleted */
/* where (SKUId > 0) - Temporary as UI page loading very slowly  #TODO - Fix it in UI page or indices in DB */

Go
