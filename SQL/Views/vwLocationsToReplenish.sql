/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/23  SJ      Added LocationStatus,LocationStatusDesc (HA-936)
  2020/06/18  SJ      Added LocationType,LocationSubType,StorageType & Status Descriptions (HA-936)
  2020/06/16  TK      Added UniqueId & InventoryClasses (HA-938)
  2018/03/28  YJ      Added AllowedOperations (S2G-327)
  2018/03/26  RV      Excluded the voided LPNs to do not get duplicate Locations (HPI-1838)
  2016/09/28  AY      pr_Replenish_GenerateOndemandOrders: Disable replenishment for some SKUs (HPI-810)
  2016/02/23  TK      Added Ownership field (NBD-175)
  2015/12/15  TK      Consider UnitsPerLPN for Unit Storage Locations and InnerPacksPerLPN for
                        Case Storage Location while ReplenishUoM is 'LPN' (ACME-419)
  2015/06/24  TK      Enhanced to control Negative values.
  2014/10/14  PKS     All changes migrated from Production Database
  2014/09/02  AY      Do not replenish inactive locations
  2014/05/09  PK      Added UnitsPerLPN and handling ReplenishUoM as LPN.
  2014/05/08  PK      Handling Cases and Units storage types.
  2012/02/07  YA/VM   Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLocationsToReplenish') is not null
  drop View dbo.vwLocationsToReplenish;
Go

Create View dbo.vwLocationsToReplenish (
  LocationId,
  Location,
  LocationType,
  LocationTypeDesc,
  LocationSubType,
  LocationSubTypeDesc,
  StorageType,
  StorageTypeDesc,
  LocationStatus,
  LocationStatusDesc,

  LocationRow,
  LocationLevel,
  LocationSection,

  PutawayZone,
  PickZone,

  LPNId,
  LPN,
  Ownership,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  ProdCategory,
  ProdSubCategory,

  Innerpacks,
  Quantity,
  UnitsPerInnerPack,
  InnerPacksPerLPN,
  UnitsPerLPN,
  MinReplenishLevel,
  MinReplenishLevelDesc,
  MinReplenishLevelUnits,
  MinReplenishLevelInnerPacks,
  MaxReplenishLevel,
  MaxReplenishLevelDesc,
  MaxReplenishLevelUnits,
  MaxReplenishLevelInnerPacks,
  ReplenishUoM,

  PercentFull,

  MinToReplenish,
  MinUnitsToReplenish,
  MinIPsToReplenish,
  MinToReplenishDesc,

  MaxToReplenish,
  MaxUnitsToReplenish,
  MaxIPsToReplenish,
  MaxToReplenishDesc,

  ReplenishType,
  AllowedOperations,

  Warehouse,
  BusinessUnit,

  UniqueId
) As
select
  LOC.LocationId,
  LOC.Location,
  LOC.LocationType,
  LT.TypeDescription, /* LocationTypeDesc */
  LOC.LocationSubType,
  case when LocationSubType = 'D' then 'Dynamic'
       when LocationSubType = 'S' then 'Static'
       else null
  end, /* LocationSubTypeDesc */
  LOC.StorageType,
  LST.TypeDescription, /* StorageTypeDesc */
  LOC.Status,
  ST.StatusDescription,

  /* TODO: For following 3 fields coalesce with substring should be used for Loehmanns only as
     these 3 fields are newly added. So until Loehmann's production is updated with values of these
     3 fields, we need keep it. For other clients GenerateLocations is needed to enhance to add
     these 3 fields */
  coalesce(Loc.LocationRow,     substring(LOC.Location, 0, 5)),
  coalesce(Loc.LocationLevel,   substring(LOC.Location, 10, 2)),
  coalesce(Loc.LocationSection, substring(LOC.Location, 6, 3)),

  LOC.PutawayZone,
  LOC.PickingZone,

  L.LPNId,
  L.LPN,
  L.Ownership,
  L.InventoryClass1,
  L.InventoryClass2,
  L.InventoryClass3,

  S.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.ProdCategory,
  S.ProdSubCategory,

  L.InnerPacks,
  L.Quantity - coalesce(L.ReservedQty, 0),
  S.UnitsPerInnerPack,
  S.InnerPacksPerLPN,
  S.UnitsPerLPN,
  LOC.MinReplenishLevel,
  convert(varchar(max), LOC.MinReplenishLevel) + ' ' + LOC.ReplenishUoM,

  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then LOC.MinReplenishLevel
    when (LOC.ReplenishUoM = 'CS'/* Cases */ ) then LOC.MinReplenishLevel * S.UnitsPerInnerPack
    when (LOC.ReplenishUoM = 'LPN' /* LPN */ ) then LOC.MinReplenishLevel * S.UnitsPerLPN
  end /* MinReplenishLevelUnits */,

  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then 0
    when (LOC.ReplenishUoM = 'CS'/* Cases */ ) then LOC.MinReplenishLevel
    when (LOC.ReplenishUoM = 'LPN' /* LPN */ ) then LOC.MinReplenishLevel * S.InnerPacksPerLPN
  end /* MinReplenishLevelInnerPacks */,

  LOC.MaxReplenishLevel,
  convert(varchar(max), LOC.MaxReplenishLevel) + ' ' + LOC.ReplenishUoM,

  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then LOC.MaxReplenishLevel
    when (LOC.ReplenishUoM = 'CS'/* Cases */)  then LOC.MaxReplenishLevel * S.UnitsPerInnerPack
    when (LOC.ReplenishUoM = 'LPN' /* LPN */)  then LOC.MaxReplenishLevel * S.UnitsPerLPN
  end /* MaxReplenishLevelUnits */,

  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then 0
    when (LOC.ReplenishUoM = 'CS'/* Cases */)  then LOC.MaxReplenishLevel
    when (LOC.ReplenishUoM = 'LPN' /* LPN */)  then LOC.MaxReplenishLevel * S.InnerPacksPerLPN
  end /* MaxReplensihLevelInnerPacks */,

  LOC.ReplenishUoM,

  /* PercentFull */
  ((L.Quantity * 100)/ (case when LOC.ReplenishUoM = 'EA' then LOC.MaxReplenishLevel
                             when LOC.ReplenishUoM = 'CS' then LOC.MaxReplenishLevel * S.UnitsPerInnerPack
                             when LOC.ReplenishUoM = 'LPN' then Loc.MaxReplenishLevel * S.UnitsPerLPN end)),

  /* MinToReplenish */
  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then
      dbo.fn_MaxInt((LOC.MinReplenishLevel - L.Quantity), 0)
    when (LOC.ReplenishUoM = 'CS'/* Cases */) then
      dbo.fn_MaxInt((LOC.MinReplenishLevel - L.InnerPacks), 0)
    when (LOC.ReplenishUoM = 'LPN'/* LPN */) then
      dbo.fn_MaxInt((LOC.MinReplenishLevel - (L.Quantity/S.UnitsPerLPN)), 0)
  end,

  /* MinUnitsToReplenish */
  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then
      dbo.fn_MaxInt((LOC.MinReplenishLevel - L.Quantity), 0)
    when (LOC.ReplenishUoM = 'CS'/* Cases */) then
      dbo.fn_MaxInt((LOC.MinReplenishLevel * S.UnitsPerInnerPack - L.Quantity) , 0)
    when (LOC.ReplenishUoM = 'LPN'/* LPN */) then
      dbo.fn_MaxInt((LOC.MinReplenishLevel * S.UnitsPerLPN - L.Quantity), 0)
  end,

  /* MinIPsToReplenish */
  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then
      0
    when (LOC.ReplenishUoM = 'CS'/* Cases */) and S.UnitsPerInnerPack > 0 then
      dbo.fn_MaxInt((LOC.MinReplenishLevel * S.UnitsPerInnerPack - L.Quantity) / S.UnitsPerInnerPack, 0)
    when (LOC.ReplenishUoM = 'LPN'/* LPN */) and S.UnitsPerLPN > 0 then
      dbo.fn_MaxInt((LOC.MinReplenishLevel * S.InnerPacksPerLPN - L.InnerPacks), 0)
  end,

  /* MinToReplenish Description */
  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then
      convert(varchar(max), dbo.fn_MaxInt((LOC.MinReplenishLevel - L.Quantity),0)) + ' ' + LOC.ReplenishUoM
    when (LOC.ReplenishUoM = 'CS'/* Cases */) then
      convert(varchar(max), dbo.fn_MaxInt((LOC.MinReplenishLevel - L.InnerPacks), 0)) + ' ' + LOC.ReplenishUoM
    when (LOC.ReplenishUoM = 'LPN'/* Cases */) then
      convert(varchar(max), dbo.fn_MaxInt((LOC.MinReplenishLevel - (L.Quantity/S.UnitsPerLPN)), 0)) + ' ' + LOC.ReplenishUoM
  end,

  /* MaxToReplenish */
  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then
      dbo.fn_MaxInt((LOC.MaxReplenishLevel - L.Quantity), 0)
    when (LOC.ReplenishUoM = 'CS'/* Cases */) then
      dbo.fn_MaxInt((LOC.MaxReplenishLevel - L.InnerPacks), 0)
    when (LOC.ReplenishUoM = 'LPN'/* LPN */) then
      dbo.fn_MaxInt((LOC.MaxReplenishLevel - (L.Quantity/S.UnitsPerLPN)), 0)
  end,

  /* MaxUnitsToReplenish */
  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then
      dbo.fn_MaxInt((LOC.MaxReplenishLevel - L.Quantity), 0)
    when (LOC.ReplenishUoM = 'CS'/* Cases */) then
      dbo.fn_MaxInt((LOC.MaxReplenishLevel * S.UnitsPerInnerPack - L.Quantity), 0)
    when (LOC.ReplenishUoM = 'LPN'/* LPN */) then
      dbo.fn_MaxInt((LOC.MaxReplenishLevel * S.UnitsPerLPN - L.Quantity), 0)
    else
      0
  end,

  /* MaxIPsToReplenish */
  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then
      0
    when (LOC.ReplenishUoM = 'CS'/* Cases */) and S.UnitsPerInnerPack > 0 then
      dbo.fn_MaxInt((LOC.MaxReplenishLevel * S.UnitsPerInnerPack - L.Quantity) / S.UnitsPerInnerPack, 0)
    when (LOC.ReplenishUoM = 'LPN'/* LPN */) and S.UnitsPerLPN > 0 then
      dbo.fn_MaxInt((LOC.MaxReplenishLevel * S.InnerPacksPerLPN - L.InnerPacks), 0)
    else
      0
  end,

  /* MaxToReplenish Description */
  case
    when (LOC.ReplenishUoM = 'EA'/* Eaches */) then
      convert(varchar(max), dbo.fn_MaxInt((LOC.MaxReplenishLevel - L.Quantity), 0)) + ' ' + LOC.ReplenishUoM
    when (LOC.ReplenishUoM = 'CS'/* Cases */) then
      convert(varchar(max), dbo.fn_MaxInt((LOC.MaxReplenishLevel - L.InnerPacks), 0)) + ' ' + LOC.ReplenishUoM
    when (LOC.ReplenishUoM = 'LPN'/* LPN */) then
      convert(varchar(max), dbo.fn_MaxInt((LOC.MaxReplenishLevel - (L.Quantity/S.UnitsPerLPN)), 0)) + ' ' + LOC.ReplenishUoM
  end,

  case  /* ReplenishType */
    when (((L.Quantity <= LOC.MinReplenishLevel) and (LOC.ReplenishUoM = 'EA')) or
          ((L.Quantity <= (LOC.MinReplenishLevel * S.UnitsPerInnerPack)) and (LOC.ReplenishUoM = 'CS'))  or
          ((charindex(LOC.StorageType, 'U' /* Units */) <> 0) and ((L.Quantity <= LOC.MinReplenishLevel * S.UnitsPerLPN) and (LOC.ReplenishUoM = 'LPN')))) or
          ((charindex(LOC.StorageType, 'P' /* Cases */) <> 0) and ((L.InnerPacks <= LOC.MinReplenishLevel * S.InnerPacksPerLPN) and (LOC.ReplenishUoM = 'LPN'))) then
      'R' /* Required */
    when (((L.Quantity <= LOC.MaxReplenishLevel) and (LOC.ReplenishUoM = 'EA')) or
          ((L.Quantity <= (LOC.MaxReplenishLevel * S.UnitsPerInnerPack)) and (LOC.ReplenishUoM = 'CS'))  or
          ((charindex(LOC.StorageType, 'U' /* Units */) <> 0) and ((L.Quantity <= LOC.MaxReplenishLevel * S.UnitsPerLPN) and (LOC.ReplenishUoM = 'LPN')))) or
          ((charindex(LOC.StorageType, 'P' /* Cases */) <> 0) and ((L.InnerPacks <= LOC.MaxReplenishLevel * S.InnerPacksPerLPN) and (LOC.ReplenishUoM = 'LPN'))) then
      'F' /* Fill Up */
  end,

  LOC.AllowedOperations,
  LOC.Warehouse,
  LOC.BusinessUnit,
  cast(LOC.LocationId as varchar(10)) + '-' + cast(S.SKUId as varchar(10)) /* UniqueId */
from Locations LOC
             join LPNs           L   on (LOC.LocationId   = L.LocationId) and (L.Status <> 'V' /* Voided */)
             join SKUs           S   on (S.SKUId          = L.SKUId)
  left outer join EntityTypes    LT  on (LT.TypeCode      = LOC.LocationType    ) and
                                        (LT.Entity        = 'Location'          ) and
                                        (LT.BusinessUnit  = LOC.BusinessUnit    )
  left outer join EntityTypes    LST on (LST.TypeCode     = LOC.StorageType     ) and
                                        (LST.Entity       = 'LocationStorage'   ) and
                                        (LST.BusinessUnit = LOC.BusinessUnit    )
  left outer join Statuses       ST  on (LOC.Status       = ST.StatusCode       ) and
                                        (ST.Entity        = 'Location'          ) and
                                        (ST.BusinessUnit  = LOC.BusinessUnit    )
where
  (LOC.LocationType    = 'K' /* Picklane */) and
  (LOC.LocationSubType = 'S' /* Static */) and
  (LOC.Status          <> 'I' /* Inactive */) and
  (coalesce(L.UDF5, '') <> 'DisableReplenish') and

  (((L.Quantity < LOC.MaxReplenishLevel) and
    (LOC.ReplenishUoM = 'EA')) or

   ((L.Quantity < (LOC.MaxReplenishLevel * S.UnitsPerInnerPack)) and
    (LOC.ReplenishUoM = 'CS')) or

   ((charindex(LOC.StorageType, 'P' /* Cases */) <> 0) and ((L.InnerPacks < LOC.MaxReplenishLevel * S.InnerPacksPerLPN) and
    (LOC.ReplenishUoM = 'LPN'))) or

   ((charindex(LOC.StorageType, 'U' /* Units */) <> 0) and ((L.Quantity < LOC.MaxReplenishLevel * S.UnitsPerLPN) and
    (LOC.ReplenishUoM = 'LPN'))));

Go
