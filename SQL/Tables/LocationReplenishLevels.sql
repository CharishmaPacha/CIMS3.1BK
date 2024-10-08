/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/16  TD      LocationReplenishLevels:Added new table (BK-763)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: LocationReplenishLevels: Normally, we have replenishment levels specified
   at the Location level. For a multi SKU Picklane, the Location replenish levels
   would be applied to all SKUs in the picklane. However, some clients have the
   need to have replenish levels set at different levels for each SKU in the
   Location and this table is used to define the replenish levels for each
   SKU/InventoryKey in the Location.

 Velocity defines the speed of movement of the SKU.
 SKU Velocity refers to the velocity with which the SKU is shipped from the WH.
 Pick Velocity refers to the velcoity of the SKU i.e. Units Picked from the Location.

 To evaluate the Location Replenish Levels, we would like to get a general velocity of
 the SKU both for shipped units as well as picked units (from this specific location).
 Having these will help the user update the min/max of the Location-SKU so that they
 can have the inventory to satisfy a given period.

 SV: SKU Velocity
 SV_PrevWeek:  Units of the SKU shipped in the Prev Week
 SV_Prev2Week: Units of the SKU shipped in the Prev two Weeks
 SV_PrevMonth: Units of the SKU shipped in the Prev Month etc.

 PV: Pick Velocity
 PV_PrevWeek:  Total units of SKU picked from the Location in the Prev Week
 PV_Prev2Week: Total units of SKU picked from the Location in the Prev two Weeks
 PV_PrevMonth: Total units of SKU picked from the Location in the Prev Month etc.

 ------------------------------------------------------------------------------*/
Create Table LocationReplenishLevels (
    RecordId                 TRecordId      identity (1,1) not null,

    LocationId               TRecordId      not null,
    Location                 TLocation      not null,
    Warehouse                TWarehouse,

    SKUId                    TRecordId      not null,
    SKU                      TSKU           not null,
    InventoryKey             TInventoryKey,

    Status                   TStatus        not null default 'A' /* Active */,

    MinReplenishLevel        TQuantity,
    MaxReplenishLevel        TQuantity,
    ReplenishUoM             TUoM,
    IsReplenishable          TFlags,

    SV_PrevWeek              TInteger,
    SV_Prev2Week             TInteger,
    SV_PrevMonth             TInteger,
    SV_Prev2Month            TInteger,
    SV_PrevQuarter           TInteger,
    SV_Prev2Quarter          TInteger,

    PV_PrevWeek              TInteger,
    PV_Prev2Week             TInteger,
    PV_PrevMonth             TInteger,
    PV_Prev2Month            TInteger,
    PV_PrevQuarter           TInteger,
    PV_Prev2Quarter          TInteger,

    LOCRL_UDF1               TUDF,
    LOCRL_UDF2               TUDF,
    LOCRL_UDF3               TUDF,
    LOCRL_UDF4               TUDF,
    LOCRL_UDF5               TUDF,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    UniqueId                 as concat_ws('-', Location, SKU, BusinessUnit),

    constraint pkLocationReplenishLevels_RecordId PRIMARY KEY (RecordId),
    constraint ukLocationReplenishLevels_LocationId   UNIQUE (LocationId, SKUId)
);

create index ix_LocationReplenishLevels_LocationSKU on LocationReplenishLevels (LocationId, SKUId, Status) Include (MinReplenishLevel, MaxReplenishLevel, ReplenishUoM);

Go
