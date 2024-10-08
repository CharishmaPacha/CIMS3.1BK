/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/16  TK      Locations: Included Warehouse for ukLocations_Barcode (HA-75)
  2017/12.03  TD      Locations:Added fields LocationClass,MaxPallets,MaxLPNs,MaxInnerPacks,
  2017/02/08  OK      Locations: Added AllowedOperations (GNC-1427)
  2017/10/29  PK      Locations: Added IsReplenishable (HPI-1730).
  2016/02/11  KL      Locations: Added Ownership, LocationVerified, LastVerified  LOC_UDF1..5(FB-608).
  2015/10/14  PK      Locations: Added LocationBay
  2014/03/21  TD      Locations: Added ReplenishUoM.
  2013/11/23  VP      Locations: Added Index ixLocationType
  Locations: Add BusinessUnit to Unique index.
  2012/02/09  VM      Locations: Added LocationRow, LocationLevel, LocationSection
  2012/02/07  YA      Locations: Added columns MinReplenishLevel, MaxReplenishLevel, LocationSubType.
  2011/12/19  PK      Locations: Added LastCycleCounted
  2011/02/03  VK      Added Warehouse field to Locations Table.
  Locations: Set Status default value to Empty
  2010/12/23  NB/AY   Added PutawayZone, PickZone for Locations, Corrected default for OnhandStatus
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Locations

 LocationClass - This field will categorize the location capacity i.e this will define
                 maximum limitation of the location. At present we have MaxPallet count,
                 MaxLPNs,MaxWeight and MaxVolume. Based on the Location class we will
                 have these limitations. The locations classes are A,B and C.

 MaxPallets   - The maximum number of pallets does the location can hold in it.
 MaxLPNs      - The maximum number of LPNs does the location can hold in it.
 MaxCases     - The maximum number of cases can hold by the location.
 MaxUnits     - The maximum number of units can hold by the location.
 MaxWeight    - The maximum weight of inventory can hold in it.
 MaxVolume    - The maximum voulme can allow by the location.

 AllowedOperations:  This field represents the Operations that should be allowed on this Location.
                     These operations would be defined at the time of Location creation/generation
                     and updated as needed from UI later. If it contains N, then it means Location
                     is on hold.
                     null: Allow all Operations on this Location,
                     P:    Putaway is allowed on this Location.
                     K:    Picking is allowed from this Location.
                     C:    Cycle Count is allowed on the Location.
                     R:    Replenishmnet is allowed
                     N:    None - No operations are allowed i.e Location will be onhold.
------------------------------------------------------------------------------*/
Create Table Locations (
    LocationId               TRecordId      identity (1,1) not null,

    Location                 TLocation      not null,
    LocationType             TLocationType  not null,
    LocationSubType          TTypeCode      not null default 'D' /* Dynamic */,
    StorageType              TStorageType   not null,
    Status                   TStatus        not null default 'E' /* Empty */,

    LocationRow              TRow,
    LocationBay              TBay,
    LocationLevel            TLevel,
    LocationSection          TSection,

    SKUId                    TRecordId,
    LocationClass            TCategory,

    NumPallets               TCount         not null default 0,
    NumLPNs                  TCount         not null default 0,
    InnerPacks               TInnerPacks    not null default 0,
    Quantity                 TQuantity      not null default 0,
    Volume                   TVolume        not null default 0.0,
    Weight                   TWeight        not null default 0.0,

    MinReplenishLevel        TQuantity,
    MaxReplenishLevel        TQuantity,
    ReplenishUoM             TUoM,
    AllowMultipleSKUs        TFlag          not null default 'N' /* No */,
    IsReplenishable          TFlags,
    AllowedOperations        TFlags,
    PrevAllowedOperations    TDescription,

    Barcode                  TBarcode,
    PutawayPath              TLocationPath,
    PickPath                 TLocationPath,

    PickingZone              TLookUpCode,
    PutawayZone              TLookUpCode,
    LastCycleCounted         TDateTime,
    LocationABCClass         TFlag,
    PolicyCompliant          TFlag          default 'N' /* No */,
    LocationVerified         TFlag,
    LastVerified             TDateTime,
    Ownership                TOwnership,

    MaxPallets               TCount,
    MaxLPNs                  TCount,
    MaxInnerpacks            TCount,
    MaxUnits                 TCount,
    MaxVolume                TVolume,
    MaxWeight                TWeight,

    Warehouse                TWarehouse     not null,

    LOC_UDF1                 TUDF,
    LOC_UDF2                 TUDF,
    LOC_UDF3                 TUDF,
    LOC_UDF4                 TUDF,
    LOC_UDF5                 TUDF,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkLocations_LocationId PRIMARY KEY (LocationId),
    constraint ukLocations_Location   UNIQUE (Location, BusinessUnit),
    constraint ukLocations_Barcode    UNIQUE (Barcode, Warehouse, BusinessUnit)
);

create index ix_Locations_Status                 on Locations (Status, BusinessUnit) Include (LocationId, Location,
                                                  LocationType, LocationRow, LocationSection, PickPath, PickingZone);
create index ix_Locations_Warehouse              on Locations (Warehouse, Status, BusinessUnit, StorageType, LocationType, LocationSubType);
create index ix_Locations_Type                   on Locations (LocationType, LocationSubType) Include (LocationId, Location, Warehouse, Status);
create index ix_Locations_PAZone                 on Locations (PutawayZone, LocationType, LocationSubType) Include (LocationId, Location, Warehouse, Status);
create index ix_Locations_PickZone               on Locations (PickingZone, LocationType, LocationSubType) Include (LocationId, Location, Warehouse, Status);

Go
