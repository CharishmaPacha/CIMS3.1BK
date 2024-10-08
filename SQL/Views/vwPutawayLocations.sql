/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/12  TD      Added LocatonClass and AvailableQuantities (CIMS-1750)
  2017/02/20  OK      Added AllowedOperations (GNC-1426)
  2016/01/04  TK      Added ReplenishUoM (NBD-84)
  2014/07/09  NY      Added coalesce expression to PutawayZone.
  2014/03/25  TD      Changed PutawayClass => SKUPutawayClass.
  2014/02/03  NB      Added MinReplenishLevel, MaxReplenishLevel, AllowMultipleSKUs
                        from Locations table
  2011/07/16  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPutawayLocations') is not null
  drop View dbo.vwPutawayLocations;
Go

Create View dbo.vwPutawayLocations (
  LocationId,

  Location,
  LocationType,
  StorageType,
  Status,
  NumPallets,
  NumLPNs,
  Innerpacks,
  Quantity,

  MinReplenishLevel,
  MaxReplenishLevel,
  ReplenishUoM,
  AllowMultipleSKUs,
  AllowedOperations,

  LocationBarcode,
  PutawayPath,
  PickPath,

  PickingZone,
  PutawayZone,
  Warehouse,

  LocationClass,

  AvailablePalletCapacity,
  AvailableLPNCapacity,
  AvailableIPCapacity,
  AvailableUnitCapacity,
  AvailableVolumeCapacity,
  AvailableWeightCapacity,

  PRRecordId,
  PRSequenceNo,

  PRPAType,
  PRLPNType,
  PRPutawayClass,

  PRLocationType,
  PRStorageType,
  PRLocationStatus,
  PRPutawayZone,
  PRLocation,
  PRSKUExists,

  PRLocationClass,

  PRStatus,

  BusinessUnit
) As
select
  L.LocationId,
  L.Location,
  L.LocationType,
  L.StorageType,
  L.Status,
  L.NumPallets,
  L.NumLPNs,
  L.Innerpacks,
  L.Quantity,

  L.MinReplenishLevel,
  L.MaxReplenishLevel,
  L.ReplenishUoM,
  L.AllowMultipleSKUs,
  L.AllowedOperations,

  L.Barcode,
  L.PutawayPath,
  L.PickPath,

  L.PickingZone,
  L.PutawayZone,
  L.Warehouse,

  L.LocationClass,

  /* if the difference between these two is less than 0 then return 0 or else return
     actual difference  */
  case
    when (coalesce(L.MaxPallets, 9999) - coalesce(L.NumPallets, 0)) <= 0 then 0
    else (coalesce(L.MaxPallets, 9999) - coalesce(L.NumPallets, 0))
  end,
  case
    when (coalesce(L.MaxLPNs, 9999) - coalesce(L.NumLPNs, 0)) <= 0 then 0
    else (coalesce(L.MaxLPNs, 9999) - coalesce(L.NumLPNs, 0))
  end,
  case
    when (coalesce(L.MaxInnerPacks, 9999) - coalesce(L.InnerPacks, 0)) <= 0 then 0
    else (coalesce(L.MaxInnerPacks, 9999) - coalesce(L.InnerPacks, 0))
  end,
  case
    when (coalesce(L.MaxUnits, 9999) - coalesce(L.Quantity, 0)) <= 0 then 0
    else (coalesce(L.MaxUnits, 9999) - coalesce(L.Quantity, 0))
  end,
  case
    when (coalesce(L.MaxVolume, 99999) - coalesce(L.Volume, 0.0)) <= 0 then 0
    else (coalesce(L.MaxVolume, 99999) - coalesce(L.Volume, 0.0))
  end,
  case
    when (coalesce(L.MaxWeight, 99999) - coalesce(L.Weight, 0.0)) <= 0 then 0
    else (coalesce(L.MaxWeight, 99999) - coalesce(L.Weight, 0.0))
  end,

  PR.RecordId,

  PR.SequenceNo,

  PR.PAType,
  PR.LPNType,
  PR.SKUPutawayClass,

  PR.LocationType,
  PR.StorageType,
  PR.LocationStatus,
  PR.PutawayZone,
  PR.Location,
  PR.SKUExists,

  PR.LocationClass,

  PR.Status,

  L.BusinessUnit

from
  Locations L join PutawayRules PR on
              (coalesce(L.PutawayZone, '')  = coalesce(PR.PutawayZone,  L.PutawayZone, '')) and
              (L.Location                   = coalesce(PR.Location,     L.Location    )) and
              (L.LocationType               = coalesce(PR.LocationType, L.LocationType)) and
              (L.StorageType                = coalesce(PR.StorageType,  L.StorageType )) and
              (L.BusinessUnit               = PR.BusinessUnit)
where
  (L.Status in ('E' /* Empty */, 'U' /* In use */))
;

Go
