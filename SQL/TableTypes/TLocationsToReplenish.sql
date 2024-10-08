/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/16  TK      TLocationsToReplenish: Added UniqueId (HA-938)
  2020/06/08  TK      TWaveDetailsToReplenish & TLocationsToReplenish: Added InventoryClass (HA-871)
  2018/03/22  TK      TLocationsToReplenish: Added more required to generate replenish order (S2G-385)
  2018/03/07  TK      Added TWaveDetailsToReplenish & TLocationsToReplenish (S2G-364)
  Create Type TLocationsToReplenish as Table (
  Grant References on Type:: TLocationsToReplenish to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLocationsToReplenish as Table (
    LocationId               TRecordId,
    Location                 TLocation,
    StorageType              TStorageType,

    SKUId                    TRecordId,
    SKU                      TSKU,
    UnitsPerCase             TInteger,
    UnitsPerLPN              TInteger,

    ReplenishUoM             TUoM,
    QtyToReplenish           TQuantity,
    UnitsToReplenish         TQuantity,
    ReplenishGroup           TCategory,

    Priority                 TInteger,
    Ownership                TOwnership,
    Warehouse                TWarehouse,

    InventoryClass1          TInventoryClass    DEFAULT '',
    InventoryClass2          TInventoryClass    DEFAULT '',
    InventoryClass3          TInventoryClass    DEFAULT '',

    UniqueId                 as cast(LocationId as varchar(10)) + '-' + cast(SKUId as varchar(10)),
    RecordId                 TRecordId      identity(1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TLocationsToReplenish to public;

Go
