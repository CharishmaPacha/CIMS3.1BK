/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/31  KBB     Added BoLStatus (HA-2467)
  2021/03/17  AY      Added TotalShipmentValue (HA GoLive)
  2021/03/05  SJ      Loads: Added CarrierCheckIn, CarrierCheckOut fields (HA-2137)
  2021/02/20  YJ      Added EstimatedCartons (CIMSV3-1364)
  2021/02/03  SGK     Added LPNVolume, LPNWeight, CreatedOn, ModifiedOn (CIMSV3-1334)
  2020/01/22  AY      Added LoadGroup (HA-1926)
  2020/07/15  SAK     Added ShipToName field (HA-1086)
  2020/07/10  RKC     Added StagingLocation, LoadingMethod, Palletized (HA-1106)
  2020/07/01  NB      Loads: Added ShipFrom (CIMSV3-996)
  2020/06/23  SAK     Added field ConsolidatorAddressId (Ha-1001)
  2020/06/17  RV      FreightCharges: Swaping field positions to return the correct data (HA-961)
  2020/06/05  AY      Added LoadTypeDesc, LoadStatus, LoadStatusDesc, RoutingStatusDesc
  2019/10/30  MJ      Added AppointmentConfirmation, AppointmentDate, AppointmentDateTime, DeliveryRequestType (S2GCA-1018)
  2019/07/23  AJ      Added field MasterTrackingNo (CID-843)
  2019/07/10  YJ      Added field FreightCharges (CID-749)
  2018/10/31  CK      Added SoldToId (OB2-683)
  2015/10/07  YJ/AY   Added PickBatchGroup, vwLD_UDFs (ACME-353)
  2015/06/19  YJ      Added Account,AccountName.ShipToDesc, FoB,BoLCID
  2013/09/13  NY      pr_Load_Update:Added FromWH,ClientLoad,MasterBoL,ShipTo and DockLocatin.
  2012/12/31  AY      ShipVias in Lookups are deprecated, use ShipVias table
  2012/06/28  TD      Added count related fields to load.
  2012/06/18  TD      Initial Revision.
------------------------------------------------------------------------------*/

Go

/* Please re-apply the vwLoadsToProcess when you add any fields to this view. */
if object_id('dbo.vwLoads') is not null
  drop View dbo.vwLoads;
Go

Create View dbo.vwLoads (
  LoadId,

  LoadNumber,
  LoadType,
  LoadTypeDescription,
  LoadTypeDesc,
  LoadStatus,
  LoadStatusDesc,
  Status,
  StatusDescription,

  RoutingStatus,
  RoutingStatusDesc,
  RoutingStatusDescription,

  ShipToId,
  ShipToName,
  ShipToDesc,
  SoldToId,
  ShipVia,
  ShipViaDescription,
  Priority,
  ConsolidatorAddressId,

  TrailerNumber,
  ProNumber,
  SealNumber,
  MasterTrackingNo,

  DesiredShipDate,
  ShippedDate,
  DeliveryDate,
  CarrierCheckIn,
  CarrierCheckOut,
  TransitDays,

  NumOrders,
  NumPallets,
  NumLPNs,
  NumPackages,
  NumUnits,
  EstimatedCartons,
  TotalShipmentValue,

  Volume,
  Weight,
  LPNVolume,
  LPNWeight,

  AppointmentConfirmation,
  AppointmentDate,
  AppointmentDateTime,
  DeliveryRequestType,

  FreightCharges,

  FromWarehouse,
  ShipFrom,
  Account,
  AccountName,
  PickBatchGroup,
  StagingLocation,
  DockLocation,
  LoadingMethod,
  Palletized,

  ClientLoad,
  MasterBoL,
  BoLStatus,
  FoB,
  BoLCID,
  LoadGroup,

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

  vwLD_UDF1,
  vwLD_UDF2,
  vwLD_UDF3,
  vwLD_UDF4,
  vwLD_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  CreatedBy,
  ModifiedDate,
  ModifiedBy,
  CreatedOn,
  ModifiedOn
) As
select
  L.LoadId,

  L.LoadNumber,
  L.LoadType,
  LT.TypeDescription,   /* LoadTypeDescription - deprecated */
  LT.TypeDescription,   /* LoadTypeDesc */
  L.Status,             /* LoadStatus */
  ST.StatusDescription, /* LoadStatusDesc */
  L.Status,             /* Status - deprecated */
  ST.StatusDescription, /* StatusDescription - deprecated */

  L.RoutingStatus,
  RST.StatusDescription, /* RoutintStatusDesc */
  RST.StatusDescription, /* RoutingStatusDescription - deprecated */

  L.ShipToId,
  L.ShipToDesc,
  L.ShipToDesc,
  L.SoldToId,
  L.ShipVia,
  SV.Description,
  L.Priority,
  L.ConsolidatorAddressId,

  L.TrailerNumber,
  L.ProNumber,
  L.SealNumber,
  L.MasterTrackingNo,

  L.DesiredShipDate,
  L.ShippedDate,
  L.DeliveryDate,
  L.CarrierCheckIn,
  L.CarrierCheckOut,
  L.TransitDays,

  L.NumOrders,
  L.NumPallets,
  L.NumLPNs,
  L.NumPackages,
  L.NumUnits,
  L.EstimatedCartons,
  L.TotalShipmentValue,

  L.Volume,
  L.Weight,
  L.LPNVolume,
  L.LPNWeight,

  L.AppointmentConfirmation,
  L.AppointmentDateTime,
  L.AppointmentDateTime,
  L.DeliveryRequestType,

  L.FreightCharges,

  L.FromWarehouse,
  L.ShipFrom,
  L.Account,
  L.AccountName,
  L.PickBatchGroup,
  L.StagingLocation,
  L.DockLocation,
  L.LoadingMethod,
  L.Palletized,

  L.ClientLoad,
  L.MasterBoL,
  L.BoLStatus,
  L.FoB,
  L.BoLCID,
  L.LoadGroup,

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

  cast(' ' as varchar(50)), /* vwLD_UDF1 */
  cast(' ' as varchar(50)), /* vwLD_UDF2 */
  cast(' ' as varchar(50)), /* vwLD_UDF3 */
  cast(' ' as varchar(50)), /* vwLD_UDF4 */
  cast(' ' as varchar(50)), /* vwLD_UDF5 */

  L.Archived,
  L.BusinessUnit,
  L.CreatedDate,
  L.CreatedBy,
  L.ModifiedDate,
  L.ModifiedBy,
  L.CreatedOn,
  L.ModifiedOn
From
Loads L
  left outer join EntityTypes  LT   on (LT.Entity         = 'Load'           ) and
                                       (LT.TypeCode       = L.LoadType       ) and
                                       (LT.BusinessUnit   = L.BusinessUnit   )
  left outer join Statuses     ST   on (ST.Entity         = 'Load'           ) and
                                       (ST.StatusCode     = L.Status         ) and
                                       (ST.BusinessUnit   = L.BusinessUnit   )
  left outer join Statuses     RST  on (RST.Entity        = 'LoadRouting'    ) and
                                       (RST.StatusCode    = L.RoutingStatus  ) and
                                       (RST.BusinessUnit  = L.BusinessUnit   )
  left outer join ShipVias     SV  on  (SV.ShipVia        = L.ShipVia        ) and
                                       (SV.BusinessUnit   = L.BusinessUnit   );

Go
