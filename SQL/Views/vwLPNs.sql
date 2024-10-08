/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/27  SJ      Added PickedDate (HA-2704)
  2021/04/19  KBB     Corrected Field Positions & Added OH_UDF16 (HA-2656)
  2021/04/12  AY      Added SKUSortOrder (HA-2597)
  2021/02/20  PKK     Added PickTicketNo and UDF11-UDF20 (CIMSV3-1364)
  2021/02/10  SGK     Added NumLines, HostNumLines, SorterName, BoL, UniqueId, Visible, ModifiedOn (CIMSV3-1364)
  2020/11/05  MS      Added LPN_UDF11 to LPN_UDF20 (JL-294)
  2020/09/04  AY      Added OH.ShipToName (HA-1385)
  2020/07/28  AY      Use SKU.CoO when LPN.CoO is not available
  2020/05/19  MS      Added LPNStatusDesc (HA-604)
  2020/05/18  MS      Added WaveId & WaveNo (HA-593)
  2020/03/19  TK      Corrected ReceiverId mapping (S2GMI-140)
  2020/03/30  MS      Added InventoryClasses (HA-83)
  2020/03/06  MS      Added LPNWeight & LPNVolume (JL-123)
  2020/02/20  MS      Display SKU on LPN (MixedSKU), if LPN has MixedSKU (JL-102)
  2020/02/11  AY      Added LPN_UDF fields (JL-75)
  2019/08/09  NB      Added field LPNStatus (CIMSV3-138)
  2019/08/05  SPP     vwLPNs: added onhand status case (CID-136) (Ported from prod)
  2019/07/18  SPP     Modified Performance related OH UDF4 & 5 OH_ShipTo & OH_SoldTO (CID-136) (Ported from Prod)
  2019/07/09  SPP     Modified Location L to Loc (CID-136) (Ported from Prod)
  2019/01/23  TK      Added field Reference (S2GCA-461)
  2018/03/09  AY      Added field AllocableQty
  2018/02/27  MJ      Added DirectedQty and PackingGroup (S2G-291)
  2017/10/10  RA      Added field ReasonCode, Released vwLPN_UDF1,2,3,4(CIMS-1642)
  2017/10/11  RA      Removed field Tracking URL (HPI-1692)
  2017/07/19  AY      Mapped SKU_UDF1 to SKU.ProdCategory
  2016/11/11  NY      Changed ReasonCode length to varchar(10) (HPI-GoLive)
  2016/11/10  ??      Mapped ReasonCode to vwLPN_UDF4 (HPI-GoLive)
  2016/10/21  RA      Added new field Tracking URL (HPI-916)
  2016/10/21  RA      Mapped Tracking URL to vwLPN_UDF3 (HPI-909)
  2016/10/19  AY      Temp fix to filter out Name Badges LPNs (HPI-GoLive)
  2016/09/18  KL      Mapped TaskId to vwLPN_UDF2 (HPI-GoLive)
  2016/09/13  OK      Added TaskId (HPI-643)
  2016/07/12  KN      Added ReturnTrackingNo (NBD-634)
  2016/05/13  RV      Added OrderType (NBD-474)
  2016/05/05  TK      Changes to retrieve SKU15 values (FB-648)
  2015/09/29  RV      Added All SKUs descriptions (FB-421)
  2015/08/14  AY      Added ExportFlags & PrintFlags and temp mapped PrintFlags to vwUDF1 (SRI-385)
  2015/05/07  YJ      Added AlternateLPN
  2015/01/20  PKS     SKU Description is set to mutiple SKUs if LPN has mutiple details.
  2014/09/30  AK      Added CartonType.
  2014/05/06  PV      Calculating UnitsPerPackage instead of considering SKU configured value as it may change
                       after inventory is added to LPN.
  2014/04/21  SV      Added ReceiverId
  2014/04/03  TD      Added Picking Class.
  2014/03/27  AY      Added LastMovedDate, Orderfields and revamped sequence of the fields
  2014/03/26  TD      Added ExpiresInDays.
  2014/03/25  TD      Added PutawayClass.
  2014/03/15  AY      Added DestZone, DestLocation
                      Reverted calculation of InnerPacks
  2014/02/26  AY      Changed Description -> SKUDescription
  2014/02/25  TD      Added ExpiryDate and Lot.
  2013/12/16  TD      Added ReservedQty.
  2013/12/09  TD      Added PickBatchNo, PickBatchId.
  2013/11/11  AY      Recalculating Innerpacks
  2013/10/29  AY      Added Weight/Volume
  2013/09/25  NY      Changed vwUDFs to return varchar.
  2013/08/18  TD      Added SKU dimensions.
  2013/07/04  SP      Added vwUDF1...vwUDF5 fields - place holders for any new fields which needs to be added quickly
  2013/05/02  AY      Added TrackingNo & PackageSeqNo
  2103/04/25  TD      Added SKU.UnitPrice.
  2012/10/12  AY      Masked OH_UDF9 with CustPO and OH_UDF10 with ShipToStore - temporary.
  2012/10/09  AY      Masked UDF5 to be PickBatchNo - temporary.
  2012/09/05  SP      Added "UCCBarcode" field.
  2012/06/22  DP      Removed LookUp table join to bring BusinessUnitDescription.
  2012/06/18  TD      Added Load Number.
  2012/04/04  YA      Added SKU UoM.
  2011/11/04  SHR     Added new field Archived.
  2011/10/18  PK      Added PickingZone.
  2011/10/04  PK      Added UPC.
  2011/07/05  PK      Added ReceivedDate and DestWarehouse fileds from LPNs table,
                       and added SKU1 - SKU5 from SKUs table, changed the order of newly added fields.
  2011/01/31  VK      Added 'where' condition to to fetch LPNs of Status 'Putaway'.
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2011/01/27  VK      Added LPNTypeDescription.
  2011/01/21  VK      Added OnhandStatusDescription.
  2011/01/14  PK      Added StatusDescription, SKU UDF's, Pallet, BusinessUnitDescription,
                       ReceiptNumber, RH UDF's, PickTicket, SalesOrder, OH UDF's.
  2010/10/26  VM      vwLPN => vwLPNs
                      CoE => CoO
                      Added LocationType, StorageType
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLPNs') is not null
  drop View dbo.vwLPNs;
Go

Create View dbo.vwLPNs (
  LPNId,

  LPN,
  LPNType,
  LPNTypeDescription,
  Status,
  LPNStatus,
  StatusDescription, --Deprecated
  LPNStatusDesc,
  OnhandStatus,
  OnhandStatusDescription,
  LPNWeight,
  LPNVolume,

  /* SKU */
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  SKU1Desc,
  SKU2Desc,
  SKU3Desc,
  SKU4Desc,
  SKU5Desc,
  UPC,
  ProductCost,

  /* Qty */
  InnerPacks,
  Quantity,
  ReservedQty,
  DirectedQty,
  AllocableQty,
  UnitsPerInnerPack,
  InnerPacksPerLPN,

  DestWarehouse,
  DestZone,
  DestLocation,

  PalletId,
  Pallet,
  LocationId,
  Location,

  ReceiverId,
  ReceiverNumber,
  ReceiptId,
  ReceiptNumber,
  PutawayClass,
  PickingClass,
  ReceivedDate,
  ReasonCode,
  Reference,

  OrderId,
  PickTicket,
  PickTicketNo,
  SalesOrder,
  OrderType,

  PickBatchId,
  PickBatchNo,
  WaveId,
  WaveNo,
  SorterName,

  AlternateOrderId,
  AlternatePickTicket,

  TaskId,

  ShipmentId,
  LoadId,
  LoadNumber,
  BoL,
  ASNCase,
  UCCBarcode,
  TrackingNo,
  ReturnTrackingNo,
  PackageSeqNo,

  ExpiryDate,
  ExpiresInDays,
  LastMovedDate,
  PickedDate,

  ActualWeight,
  ActualVolume,
  EstimatedWeight,
  EstimatedVolume,

  InventoryStatus,
  Ownership,
  CoO,
  Lot,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,

  AlternateLPN,
  CartonType,
  PackingGroup,
  NumLines,
  HostNumLines,
  /* Flags */
  ExportFlags,
  PrintFlags,

  /* Other SKU fields */
  SKUDescription,
  UnitPrice,
  UnitCost,
  UnitWeight,
  UnitVolume,
  UnitLength,
  UnitHeight,
  UnitWidth,
  UoM,
  ProdCategory,
  SKUSortOrder,

  /* Other Location fields */
  LocationType,
  StorageType,
  PickingZone,

  /* Other Order Fields */
  SoldToId,
  SoldToName,
  ShipTo,
  ShipToName,
  CustAccount,
  CustAccountName,
  CustPO,
  ShipToStore,

  /* LPN UDFs */ -- these are depracated, do not use anymore. Use the LPN_UDF fields
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
  UDF11,
  UDF12,
  UDF13,
  UDF14,
  UDF15,
  UDF16,
  UDF17,
  UDF18,
  UDF19,
  UDF20,

  /* LPN UDFs */
  LPN_UDF1,
  LPN_UDF2,
  LPN_UDF3,
  LPN_UDF4,
  LPN_UDF5,
  LPN_UDF6,
  LPN_UDF7,
  LPN_UDF8,
  LPN_UDF9,
  LPN_UDF10,
  LPN_UDF11,
  LPN_UDF12,
  LPN_UDF13,
  LPN_UDF14,
  LPN_UDF15,
  LPN_UDF16,
  LPN_UDF17,
  LPN_UDF18,
  LPN_UDF19,
  LPN_UDF20,

  /* SKU UDFs */
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

  /* Order Hdr UDFs */
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
  OH_UDF16,

  /* Receipt Hdr UDFs */
  RH_UDF1,
  RH_UDF2,
  RH_UDF3,
  RH_UDF4,
  RH_UDF5,

  /* Place holders for any new fields which needs to be added quickly without
     changing data layer and install UI again. Change requires only in .aspx file */
  vwLPN_UDF1,
  vwLPN_UDF2,
  vwLPN_UDF3,
  vwLPN_UDF4,
  vwLPN_UDF5,

  UniqueId,
  Visible,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,
  ModifiedOn
) As
select
  L.LPNId,

  L.LPN,
  L.LPNType,
  LT.TypeDescription,
  L.Status,
  L.Status, /* Mapped to LPNStatus column */
  ST.StatusDescription,
  ST.StatusDescription, /* Mapped to LPNStatusDesc column */
  L.OnhandStatus,
  OST.StatusDescription,
  L.LPNWeight,
  L.LPNVolume,

  L.SKUId,
  coalesce(S.SKU,  L.SKU),
  coalesce(S.SKU1, L.SKU1),
  coalesce(S.SKU2, L.SKU2),
  coalesce(S.SKU3, L.SKU3),
  coalesce(S.SKU4, L.SKU4),
  coalesce(S.SKU5, L.SKU5),
  S.SKU1Description,
  S.SKU2Description,
  S.SKU3Description,
  S.SKU4Description,
  S.SKU5Description,
  S.UPC,
  S.UnitPrice,

  L.InnerPacks,
  L.Quantity,
  L.ReservedQty,
  L.DirectedQty,
  case when (L.OnhandStatus in ('A'/* Available */)) then L.Quantity + L.DirectedQty - L.ReservedQty else 0 end, /* Allocable Qty */
  L.Quantity/nullif(L.InnerPacks, 0),
  S.InnerPacksPerLPN,

  L.DestWarehouse,
  L.DestZone,
  L.DestLocation,

  L.PalletId,
  L.Pallet,
  L.LocationId,
  L.Location,

  L.ReceiverId,
  L.ReceiverNumber,
  L.ReceiptId,
  L.ReceiptNumber,
  L.PutawayClass,
  L.PickingClass,
  L.ReceivedDate,
  L.ReasonCode,
  L.Reference,

  L.OrderId,
  OH.PickTicket,
  L.PickTicketNo,
  OH.SalesOrder,
  OH.OrderType,

  L.PickBatchId,
  L.PickBatchNo,
  L.PickBatchId, /* Wave Id */
  L.PickBatchNo, /* Wave No */
  L.SorterName,

  L.AlternateOrderId,
  L.AlternatePickTicket,

  L.TaskId,

  L.ShipmentId,
  L.LoadId,
  L.LoadNumber,
  L.BoL,
  L.ASNCase,
  L.UCCBarcode,
  L.TrackingNo,
  L.ReturnTrackingNo,
  L.PackageSeqNo,

  L.ExpiryDate,
  L.ExpiresInDays,
  L.LastMovedDate,
  L.PickedDate,

  L.ActualWeight,
  L.ActualVolume,
  L.EstimatedWeight,
  L.EstimatedVolume,

  L.InventoryStatus,
  L.Ownership,
  coalesce(L.CoO, S.DefaultCoO),
  L.Lot,
  L.InventoryClass1,
  L.InventoryClass2,
  L.InventoryClass3,

  L.AlternateLPN,
  L.CartonType,
  L.PackingGroup,
  L.NumLines,
  L.HostNumLines,
  /* Flags */
  L.ExportFlags,
  L.PrintFlags,

  /* Related Fields of SKU, Loc, Order */
  case when L.SKUId is null and L.Quantity > 0 then 'Mixed SKUs' else S.Description end,
  S.UnitPrice,
  S.UnitCost,
  S.UnitWeight,
  S.UnitVolume,
  S.UnitLength,
  S.UnitHeight,
  S.UnitWidth,
  S.UoM,
  S.ProdCategory,
  S.SKUSortOrder,

  LOC.LocationType,
  LOC.StorageType,
  LOC.PickingZone,

  OH.SoldToId,
  OH.SoldToName,
  OH.ShipToId,
  OH.ShipToName,
  OH.Account,
  OH.AccountName,
  OH.CustPO,
  OH.ShipToStore,

  /* LPN UDFs */
  L.UDF1,
  L.UDF2,
  L.UDF3,
  L.UDF4,
  L.UDF5,
  L.UDF6,
  L.UDF7,
  L.UDF8,
  L.UDF9,
  L.UDF10,
  L.UDF11,
  L.UDF12,
  L.UDF13,
  L.UDF14,
  L.UDF15,
  L.UDF16,
  L.UDF17,
  L.UDF18,
  L.UDF19,
  L.UDF20,
  /* Duplicated as earlier ones are used in V2 and these are for V3 */
  L.UDF1,
  L.UDF2,
  L.UDF3,
  L.UDF4,
  L.UDF5,
  L.UDF6,
  L.UDF7,
  L.UDF8,
  L.UDF9,
  L.UDF10,
  L.UDF11,
  L.UDF12,
  L.UDF13,
  L.UDF14,
  L.UDF15,
  L.UDF16,
  L.UDF17,
  L.UDF18,
  L.UDF19,
  L.UDF20,

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
  OH.UDF16,

  /* For performance reasons we will comment out RH UDFs and uncomment as required */
  cast(' ' as varchar(50)), -- RH.UDF1,
  cast(' ' as varchar(50)), -- RH.UDF2,
  cast(' ' as varchar(50)), -- RH.UDF3,
  cast(' ' as varchar(50)), -- RH.UDF4,
  cast(' ' as varchar(50)), -- RH.UDF5,

  cast(' ' as varchar(50)), /* vwLPN_UDF1 */
  cast(' ' as varchar(50)), /* vwLPN_UDF2 */
  cast(' ' as varchar(50)), /* vwLPN_UDF3 */
  cast(' ' as varchar(50)), /* vwLPN_UDF4 */
  cast(' ' as varchar(50)), /* vwLPN_UDF5 */

  L.UniqueId,
  L.Visible,

  L.Archived,
  L.BusinessUnit,
  L.CreatedDate,
  L.ModifiedDate,
  L.CreatedBy,
  L.ModifiedBy,
  L.ModifiedOn
From
LPNs L
  left outer join EntityTypes       LT   on (LT.TypeCode      = L.LPNType      ) and
                                            (LT.Entity        = 'LPN'          ) and
                                            (LT.BusinessUnit  = L.BusinessUnit )
  left outer join SKUs              S    on (L.SKUId          = S.SKUId        )
  left outer join Locations         LOC  on (L.LocationId     = LOC.LocationId )
  left outer join Statuses          ST   on (ST.StatusCode    = L.Status       ) and
                                            (ST.Entity        = 'LPN'          ) and
                                            (ST.BusinessUnit  = L.BusinessUnit )
  left outer join Statuses          OST  on (OST.StatusCode   = L.OnhandStatus ) and
                                            (OST.Entity       = 'Onhand'       ) and
                                            (OST.BusinessUnit = L.BusinessUnit )
  left outer join OrderHeaders      OH   on (L.OrderId        = OH.OrderId     )
where L.Status <> 'I' /* Inactive/Deleted */
/* where (SKUId > 0) - Temporary as UI page loading very slowly  #TODO - Fix it in UI page or indices in DB */

Go
