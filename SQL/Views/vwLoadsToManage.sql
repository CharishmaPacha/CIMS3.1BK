/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/01  NB      Loads: Added ShipFrom (CIMSV3-996)
  2019/10/30  MJ      Added AppointmentConfirmation, AppointmentDate, AppointmentDateTime, DeliveryRequestType (S2GCA-1018)
  2018/06/06  MJ      Added fields to the Loads tab in ManageLoads page (S2G-917)
  2016/10/28  AY      Do not exclude ReadyToShip Loads (HPI-GoLive)
  2014/02/14  PKS     Added DockLocation.
  2012/10/30  PKS     View is modified to show Loads whose RoutingStatus is in Not Required.
  2012/06/18  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLoadsToManage') is not null
  drop View dbo.vwLoadsToManage;
Go

Create View dbo.vwLoadsToManage (
  LoadId,

  LoadNumber,
  LoadType,
  LoadTypeDescription,
  Status,
  StatusDescription,

  RoutingStatus,
  RoutingStatusDescription,

  ShipToId,
  ShipToDesc,
  ShipVia,
  ShipViaDescription,
  Priority,

  TrailerNumber,
  ProNumber,
  SealNumber,

  DesiredShipDate,
  ShippedDate,
  DeliveryDate,
  TransitDays,

  NumOrders,
  NumPallets,
  NumLPNs,
  NumPackages,
  NumUnits,

  Volume,
  Weight,

  AppointmentConfirmation,
  AppointmentDateTime,
  DeliveryRequestType,

  FromWarehouse,
  ShipFrom,
  Account,
  AccountName,
  PickBatchGroup,
  DockLocation,

  ClientLoad,
  MasterBoL,
  FoB,
  BoLCID,

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
  ModifiedBy
) As
select
  L.LoadId,

  L.LoadNumber,
  L.LoadType,
  LT.TypeDescription,
  L.Status,
  ST.StatusDescription,

  L.RoutingStatus,
  RST.StatusDescription,

  L.ShipToId,
  L.ShipToDesc,
  L.ShipVia,
  SV.Description,
  L.Priority,

  L.TrailerNumber,
  L.ProNumber,
  L.SealNumber,

  L.DesiredShipDate,
  L.ShippedDate,
  L.DeliveryDate,
  L.TransitDays,

  L.NumOrders,
  L.NumPallets,
  L.NumLPNs,
  L.NumPackages,
  L.NumUnits,

  L.Volume,
  L.Weight,

  L.AppointmentConfirmation,
  L.AppointmentDateTime,
  L.DeliveryRequestType,

  L.FromWarehouse,
  L.ShipFrom,
  L.Account,
  L.AccountName,
  L.PickBatchGroup,
  L.DockLocation,

  L.ClientLoad,
  L.MasterBoL,
  L.FoB,
  L.BoLCID,

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
  L.ModifiedBy
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
                                       (SV.BusinessUnit   = L.BusinessUnit   )
  where (L.RoutingStatus in ('P' /* Pending */, 'N' /* Not Required*/)) and
        (L.Status not in ('S'/* Shipped */,  'X'/* Canceled */));

Go
