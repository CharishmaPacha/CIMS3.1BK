/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  SGK     Added LocationClass, IsReplenishable, PolicyCompliant (CIMSV3-1334)
  2020/04/25  SAK     Added LocationSubTypeDesc (HA-263)
  2020/03/11  MS      Added LocationStatus, LocationStatusDesc (CIMSV3-749)
  2017/12/07  CK      Added MaxPallets,MaxLPNs,MaxInnerPacks,MaxVolume,MaxWeight,
                            Volume, Weight (CIMS-1749)
  2017/02/16  OK      Added AllowedOperations (GNC-1427)
  2016/05/12  OK      Added the where clause to filter Deleted locations (HPI-85)
  2016/04/18  PK      Added LocationBay
  2016/02/11  KL      Added Ownership,LocationVerified, LastVerified, UDF's fields (FB-608)
  2014/06/13  TD      Added join to get ReplenishUoM description.
  2014/03/27  AY      Added Replenish fields
  2013/08/12  NY      Added LocationRow, Level & Section.
  2013/07/08  YA      Added field LocationSubType.
  2013/04/17  PKS     Added field AllowMultipleSKUs
  2013/03/15  NY      Modified view to filter on Busimessunit.
  2011/12/20  PKS     Added LastCycleCounted
  2011/09/16  PK      Added WarehouseDesc Field
  2011/02/03  VK      Added Warehouse Field.
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2011/01/19  PK      Added PickingZone, PutawayZone.
  2011/01/14  VK      Added StatusDescription field.
  2010/10/26  VM      vwLocation => vwLocations
                      Added LocationTypeDesc, StorageTypeDesc
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLocations') is not null
  drop View dbo.vwLocations;
Go

Create View dbo.vwLocations (
  LocationId,

  Location,
  LocationType,
  LocationTypeDesc,
  LocationSubType,
  LocationSubTypeDesc,
  LocationStatus,
  LocationStatusDesc,

  StorageType,
  StorageTypeDesc,
  Status,
  LocationRow,
  LocationBay,
  LocationLevel,
  LocationSection,
  StatusDescription,

  SKUId,
  SKU,

  NumPallets,
  NumLPNs,
  Innerpacks,
  Quantity,
  Volume,
  Weight,

  MinReplenishLevel,
  MaxReplenishLevel,
  ReplenishUoM,
  ReplenishUoMDesc,
  AllowMultipleSKUs,
  IsReplenishable,
  AllowedOperations,
  PrevAllowedOperations,
  LocationClass,
  LocationABCClass,
  PolicyCompliant,

  Barcode,
  PutawayPath,
  PickPath,

  PickingZone,
  PutawayZone,
  PickingZoneDesc,
  PutawayZoneDesc,
  PickingZoneDisplayDesc,
  PutawayZoneDisplayDesc,

  LastCycleCounted,
  LocationVerified,
  LastVerified,
  Ownership,

  MaxPallets,
  MaxLPNs,
  MaxInnerpacks,
  MaxUnits,
  MaxVolume,
  MaxWeight,

  LOC_UDF1,
  LOC_UDF2,
  LOC_UDF3,
  LOC_UDF4,
  LOC_UDF5,

  vwLoc_UDF1,
  vwLoc_UDF2,
  vwLoc_UDF3,
  vwLoc_UDF4,
  vwLoc_UDF5,

  BusinessUnit,
  Warehouse,
  WarehouseDesc,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) as
select
  L.LocationId,
  L.Location,
  L.LocationType,
  LT.TypeDescription,
  L.LocationSubType,
  case when LocationSubType = 'D' then 'Dynamic'
       when LocationSubType = 'S' then 'Static'
       else null
  end, /* LocationSubTypeDesc */
  L.Status,
  S.StatusDescription,

  L.StorageType,
  LST.TypeDescription,
  L.Status,
  L.LocationRow,
  L.LocationBay,
  L.LocationLevel,
  L.LocationSection,

  S.StatusDescription,

  L.SKUId,
  SKU.SKU,

  L.NumPallets,
  L.NumLPNs,
  L.Innerpacks,
  L.Quantity,
  L.Volume,
  L.Weight,

  L.MinReplenishLevel,
  L.MaxReplenishLevel,
  L.ReplenishUoM,
  LU4.LookUpDisplayDescription,
  L.AllowMultipleSKUs,
  L.IsReplenishable,
  L.AllowedOperations,
  L.PrevAllowedOperations,
  L.LocationClass,
  L.LocationABCClass,
  L.PolicyCompliant,

  L.Barcode,
  L.PutawayPath,
  L.PickPath,

  L.PickingZone,
  L.PutawayZone,
  LU1.LookUpDescription,
  LU2.LookUpDescription,
  LU1.LookUpDisplayDescription,
  LU2.LookUpDisplayDescription,

  L.LastCycleCounted,
  L.LocationVerified,
  L.LastVerified,
  L.Ownership,

  L.MaxPallets,
  L.MaxLPNs,
  L.MaxInnerpacks,
  L.MaxUnits,
  L.MaxVolume,
  L.MaxWeight,

  L.LOC_UDF1,
  L.LOC_UDF2,
  L.LOC_UDF3,
  L.LOC_UDF4,
  L.LOC_UDF5,

  cast(' ' as varchar(50)), /* vwLoc_UDF1 */
  cast(' ' as varchar(50)), /* vwLoc_UDF2 */
  cast(' ' as varchar(50)), /* vwLoc_UDF3 */
  cast(' ' as varchar(50)), /* vwLoc_UDF4 */
  cast(' ' as varchar(50)), /* vwLoc_UDF5 */

  L.BusinessUnit,
  L.Warehouse,
  LU3.LookUpDescription,
  L.CreatedDate,
  L.ModifiedDate,
  L.CreatedBy,
  L.ModifiedBy
from
  Locations L
  left outer join EntityTypes LT  on (LT.TypeCode        = L.LocationType      ) and
                                     (LT.Entity          = 'Location'          ) and
                                     (LT.BusinessUnit    = L.BusinessUnit      )
  left outer join EntityTypes LST on (LST.TypeCode       = L.StorageType       ) and
                                     (LST.Entity         = 'LocationStorage'   ) and
                                     (LST.BusinessUnit   = L.BusinessUnit      )
  left outer join Statuses    S   on (L.Status           = S.StatusCode        ) and
                                     (S.Entity           = 'Location'          ) and
                                     (S.BusinessUnit     = L.BusinessUnit      )
  left outer join LookUps     LU1 on (LU1.LookUpCategory = 'PickZones'         ) and
                                     (LU1.LookUpCode     = L.PickingZone       ) and
                                     (LU1.BusinessUnit   = L.BusinessUnit      )
  left outer join LookUps     LU2 on (LU2.LookUpCategory = 'PutawayZones'      ) and
                                     (LU2.LookUpCode     = L.PutawayZone       ) and
                                     (LU2.BusinessUnit   = L.BusinessUnit      )
  left outer join LookUps     LU3 on (LU3.LookUpCategory = 'Warehouse'         ) and
                                     (LU3.LookUpCode     = L.Warehouse         ) and
                                     (LU3.BusinessUnit   = L.BusinessUnit      )
  left outer join LookUps     LU4 on (LU4.LookUpCategory = 'ReplenishUoM'      ) and
                                     (LU4.LookUpCode     = L.ReplenishUoM      ) and
                                     (LU4.BusinessUnit   = L.BusinessUnit      )
  left outer join SKUs        SKU on (L.SKUId            = SKU.SKUId)
where (L.Status   <> 'D' /* Deleted */);

Go
