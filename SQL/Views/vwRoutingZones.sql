/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/31  VM      Setup Type into UDF1 (S2G-CRP)
  2018/03/26  VM      Initial Revision (S2G-496).
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwRoutingZones') is not null
  drop View dbo.vwRoutingZones;
Go

Create View dbo.vwRoutingZones (
  RecordId,
  SortSeq,

  ZoneName,

  SoldToId,
  SoldToName,
  ShipToId,
  ShipToName,

  ShipToCity,
  ShipToState,
  ShipToZipStart,
  ShipToZipEnd,
  ShipToCountry,

  TransitDays,
  DeliveryRequirement,

  RZ_UDF1,
  RZ_UDF2,
  RZ_UDF3,
  RZ_UDF4,
  RZ_UDF5,

  Status,
  StatusDesc,

  /* vwUDFs */
  vwRZ_UDF1,
  vwRZ_UDF2,
  vwRZ_UDF3,
  vwRZ_UDF4,
  vwRZ_UDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  TOP (100) PERCENT

  RZ.RecordId,
  RZ.SortSeq,

  RZ.ZoneName,

  RZ.SoldToId,
  C.Name,
  RZ.ShipToId,
  CS.Name,

  RZ.ShipToCity,
  RZ.ShipToState,
  RZ.ShipToZipStart,
  RZ.ShipToZipEnd,
  RZ.ShipToCountry,

  RZ.TransitDays,
  RZ.DeliveryRequirement,

  case
    when ((nullif(RZ.ShipToZipStart, '') is not null) or
          (nullif(RZ.ShipToZipEnd,   '') is not null)) then
      'ShipToZip'
    when (nullif(RZ.ShipToState, '') is not null) then
      'ShipToState'
    when (nullif(RZ.ShipToCountry, '') is not null) then
      'ShipToCountry'
    else
      'Default'
  end, /* Type */ --RZ.UDF1,

  RZ.UDF2,
  RZ.UDF3,
  RZ.UDF4,
  RZ.UDF5,

  RZ.Status,
  S.StatusDescription,

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  RZ.BusinessUnit,
  RZ.CreatedDate,
  RZ.ModifiedDate,
  RZ.CreatedBy,
  RZ.ModifiedBy
from
  RoutingZones RZ
  left outer join Contacts     C   on (C.ContactRefId     = RZ.SoldToId         ) and
                                      (C.ContactType      = 'C' /* Cust */      ) and
                                      (C.BusinessUnit     = RZ.BusinessUnit     )
  left outer join Contacts     CS  on (CS.ContactRefId    = RZ.ShipToId         ) and
                                      (CS.ContactType     = 'S' /* Ship */      ) and
                                      (CS.BusinessUnit    = RZ.BusinessUnit     )
  left outer join Statuses     S   on (S.StatusCode       = RZ.Status           ) and
                                      (S.Entity           = 'Status'            ) and
                                      (S.BusinessUnit     = RZ.BusinessUnit        )
order by RZ.SortSeq;

Go
